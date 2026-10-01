import contextvars
import logging
import os
import uuid
from datetime import datetime, timezone
from enum import StrEnum

import jwt
import pika
from fastapi import Depends, FastAPI, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field
from pythonjsonlogger import jsonlogger

correlation_id_ctx = contextvars.ContextVar("correlation_id", default="")
SERVICE_NAME = os.environ["SERVICE_NAME"]


class ECSJsonFormatter(jsonlogger.JsonFormatter):
    def add_fields(self, log_record, record, message_dict):
        super().add_fields(log_record, record, message_dict)
        log_record["@timestamp"] = datetime.now(timezone.utc).isoformat()
        log_record["service.name"] = SERVICE_NAME
        log_record["log.level"] = record.levelname
        log_record["trace.id"] = correlation_id_ctx.get()


log_handler = logging.StreamHandler()
log_handler.setFormatter(ECSJsonFormatter())
logger = logging.getLogger(SERVICE_NAME)
logger.setLevel(logging.INFO)
logger.addHandler(log_handler)
logger.propagate = False

ROOT_PATH = os.environ["ROOT_PATH"]
RABBITMQ_HOST = os.environ["RABBITMQ_HOST"]
RABBITMQ_PORT = int(os.environ["RABBITMQ_PORT"])
RABBITMQ_USER = os.environ["RABBITMQ_USER"]
RABBITMQ_PASS = os.environ["RABBITMQ_PASS"]
JWT_SECRET = os.environ["JWT_SECRET"]
JWT_ALGORITHM = os.environ["JWT_ALGORITHM"]
JWT_ISSUER = os.environ["JWT_ISSUER"]
JWT_AUDIENCE = os.environ["JWT_AUDIENCE"]

app = FastAPI(
    title="Order Service",
    root_path=ROOT_PATH,
)


@app.middleware("http")
async def trace_id_middleware(request: Request, call_next):
    trace_id = (
        request.headers.get("X-Correlation-ID")
        or request.headers.get("X-Request-ID")
        or str(uuid.uuid4())
    )
    token = correlation_id_ctx.set(trace_id)
    try:
        response = await call_next(request)
        response.headers["X-Correlation-ID"] = trace_id
        return response
    finally:
        correlation_id_ctx.reset(token)


class Exchange(StrEnum):
    ORDERS = "orders.exchange"


class OrderRoutingKey(StrEnum):
    CREATED = "orders.order.created"


class OrderCreateRequest(BaseModel):
    item: str = Field(..., min_length=1, example="Mechanical Keyboard")
    price: float = Field(..., gt=0, example=120.00)


class OrderCreatedMessage(BaseModel):
    event_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    event_type: str = OrderRoutingKey.CREATED
    occurred_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
    order_id: str
    item: str
    price: float


def publish_event(
    exchange: Exchange, routing_key: OrderRoutingKey, event: BaseModel
) -> None:
    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
    parameters = pika.ConnectionParameters(
        host=RABBITMQ_HOST,
        port=RABBITMQ_PORT,
        credentials=credentials,
        connection_attempts=3,
        retry_delay=2,
    )

    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()
    channel.exchange_declare(exchange=exchange, exchange_type="topic", durable=True)

    channel.basic_publish(
        exchange=exchange,
        routing_key=routing_key,
        body=event.model_dump_json(),
        properties=pika.BasicProperties(
            delivery_mode=pika.DeliveryMode.Persistent,
            content_type="application/json",
            correlation_id=correlation_id_ctx.get(),
        ),
    )
    connection.close()


@app.get("/orders")
def get_orders():
    logger.info("Fetched all orders")
    return {
        "status": "success",
        "service": "order-service",
        "data": [
            {"id": "ord_101", "item": "Mechanical Keyboard", "price": 120.00},
            {"id": "ord_102", "item": "Wireless Mouse", "price": 45.50},
            {"id": "ord_103", "item": "UltraWide Monitor", "price": 450.00},
        ],
    }


@app.get("/order_error")
def order_error():
    logger.exception("Fetched all orders")
    exit(1)


bearer_scheme = HTTPBearer(
    auto_error=False, description="Access token from the auth service /token endpoint"
)


class TokenClaims(BaseModel):
    sub: str
    username: str
    email: str
    iss: str
    aud: str | list[str]
    iat: int
    exp: int


class AuthCheckResponse(BaseModel):
    status: str
    service: str
    data: TokenClaims


def decode_access_token(credentials: HTTPAuthorizationCredentials) -> dict:
    try:
        return jwt.decode(
            credentials.credentials,
            JWT_SECRET,
            algorithms=[JWT_ALGORITHM],
            issuer=JWT_ISSUER,
            audience=JWT_AUDIENCE,
        )
    except jwt.ExpiredSignatureError:
        logger.warning("Rejected expired access token")
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Access token has expired")
    except jwt.InvalidTokenError:
        logger.warning("Rejected invalid access token")
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid access token")


@app.get(
    "/auth-check",
    response_model=AuthCheckResponse,
    responses={401: {"description": "Missing, expired or invalid access token"}},
    summary="Test endpoint that validates a JWT access token",
)
def check_auth(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
):
    if credentials is None:
        logger.warning("Rejected auth check without a bearer token")
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED, "Missing bearer access token"
        )

    claims = decode_access_token(credentials)
    logger.info(f"Accepted access token issued for {claims.get('username')}")
    return {
        "status": "success",
        "service": "order-service",
        "data": claims,
    }


@app.post("/order", status_code=status.HTTP_201_CREATED)
def create_order(payload: OrderCreateRequest):
    generated_order_id = f"ord_{uuid.uuid4().hex[:6]}"

    event = OrderCreatedMessage(
        order_id=generated_order_id, item=payload.item, price=payload.price
    )

    try:
        publish_event(
            exchange=Exchange.ORDERS, routing_key=OrderRoutingKey.CREATED, event=event
        )
        logger.info(
            f"Created order {generated_order_id} and published to RabbitMQ",
            extra={"order_id": generated_order_id, "price": payload.price},
        )
    except Exception as e:
        logger.error(f"Failed to publish order creation event: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to publish event to message broker: {e!s}",
        )

    return {
        "status": "success",
        "service": "order-service",
        "message": "Order successfully created and event published",
        "data": event.model_dump(),
    }
