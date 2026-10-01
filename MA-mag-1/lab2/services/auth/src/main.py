import contextvars
import logging
import os
import uuid
from contextlib import asynccontextmanager
from datetime import datetime, timezone, timedelta

import jwt
import psycopg2
from fastapi import FastAPI, Request, HTTPException, status
from pydantic import BaseModel, Field
from pythonjsonlogger import jsonlogger

from src.db import init_db, get_connection

correlation_id_ctx = contextvars.ContextVar("correlation_id", default="")
SERVICE_NAME = os.getenv("SERVICE_NAME", "auth-service")


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


app = FastAPI(title="Auth Service", root_path=ROOT_PATH, lifespan=lifespan)

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