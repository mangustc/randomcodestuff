import contextvars
import logging
import os
import uuid
from datetime import datetime, timezone

from fastapi import FastAPI, Request
from pythonjsonlogger import jsonlogger

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

ROOT_PATH = os.getenv("ROOT_PATH", "")
app = FastAPI(title="Auth Service", root_path=ROOT_PATH)


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
