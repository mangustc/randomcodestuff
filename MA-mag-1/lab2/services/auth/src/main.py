import contextvars
import logging
import os
import uuid
from contextlib import asynccontextmanager
from datetime import datetime, timezone, timedelta

import jwt
import psycopg2
from fastapi import Depends, FastAPI, Request, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field
from pythonjsonlogger import jsonlogger

from src.db import init_db, get_connection

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
JWT_SECRET = os.environ["JWT_SECRET"]
JWT_ALGORITHM = os.environ["JWT_ALGORITHM"]
JWT_ISSUER = os.environ["JWT_ISSUER"]
JWT_AUDIENCE = os.environ["JWT_AUDIENCE"]
JWT_EXPIRE_MINUTES = int(os.environ["JWT_EXPIRE_MINUTES"])

@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    yield


app = FastAPI(
    title="Auth Service",
    root_path=ROOT_PATH,
    lifespan=lifespan,
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


@app.get("/auth")
def get_auth():
    logger.info("Authentication check performed")
    return {
        "status": "success",
        "service": "auth-service",
        "data": {"username": "HELP", "email": "helpme@gmail.com"},
    }


bearer_scheme = HTTPBearer(
    auto_error=False, description="Access token from the /token endpoint"
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
        "service": "auth-service",
        "data": claims,
    }


class UserRegisterRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: str = Field(..., max_length=255)
    password: str = Field(..., min_length=1, max_length=255)


class UserCreateResponse(BaseModel):
    id: int
    username: str
    email: str


class TokenRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int


def create_access_token(claims: dict, expires_in: int) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        **claims,
        "iss": JWT_ISSUER,
        "aud": JWT_AUDIENCE,
        "iat": now,
        "exp": now + timedelta(seconds=expires_in),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


@app.post(
    "/register",
    status_code=status.HTTP_201_CREATED,
    response_model=UserCreateResponse,
)
def register_user(payload: UserRegisterRequest):
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO users (username, email, password) "
                    "VALUES (%s, %s, %s) RETURNING id, username, email",
                    (payload.username, payload.email, payload.password),
                )
                user = cur.fetchone()
    except psycopg2.errors.UniqueViolation:
        logger.warning("Rejected registration for a taken username or email")
        raise HTTPException(
            status.HTTP_409_CONFLICT, "Username or email already registered"
        )

    logger.info(f"Registered user {payload.username}")
    return user


@app.post("/token", response_model=TokenResponse)
def issue_token(payload: TokenRequest):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, username, email, password FROM users WHERE username = %s",
                (payload.username,),
            )
            user = cur.fetchone()

    if user is None or user["password"] != payload.password:
        logger.warning(f"Failed login attempt for {payload.username}")
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED, "Invalid username or password"
        )

    expires_in = JWT_EXPIRE_MINUTES * 60
    token = create_access_token(
        {"sub": str(user["id"]), "username": user["username"], "email": user["email"]},
        expires_in,
    )
    return TokenResponse(access_token=token, expires_in=expires_in)
