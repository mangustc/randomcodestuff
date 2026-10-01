import contextvars
import logging
import os
import time
import uuid
from datetime import datetime, timezone
from enum import StrEnum

import pika
from pydantic import BaseModel, ValidationError
from pythonjsonlogger import jsonlogger

correlation_id_ctx = contextvars.ContextVar("correlation_id", default="")
SERVICE_NAME = os.getenv("SERVICE_NAME", "notification-service")


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

RABBITMQ_HOST = os.environ["RABBITMQ_HOST"]
RABBITMQ_PORT = int(os.environ["RABBITMQ_PORT"])
RABBITMQ_USER = os.environ["RABBITMQ_USER"]
RABBITMQ_PASS = os.environ["RABBITMQ_PASS"]


class Exchange(StrEnum):
    ORDERS = "orders.exchange"


class OrderRoutingKey(StrEnum):
    ORDER_ALL = "orders.order.*"
    ORDER_CREATED = "orders.order.created"


class Queue(StrEnum):
    ORDER_NOTIFICATIONS = "notification-service.orders.v1"


class OrderCreatedMessage(BaseModel):
    event_id: str
    event_type: str
    occurred_at: str
    order_id: str
    item: str
    price: float


def process_message(ch, method, properties, body):
    # Retrieve tracing ID propagated across RabbitMQ
    trace_id = properties.correlation_id or str(uuid.uuid4())
    token = correlation_id_ctx.set(trace_id)

    try:
        message: OrderCreatedMessage = OrderCreatedMessage.model_validate_json(body)

        logger.info(
            f"Event received for routing_key '{method.routing_key}'",
            extra={"event_id": message.event_id, "order_id": message.order_id},
        )
        logger.info(
            f"Notification sent for order {message.order_id}",
            extra={"price": message.price, "item": message.item},
        )

        ch.basic_ack(delivery_tag=method.delivery_tag)

    except ValidationError as val_err:
        logger.error(f"SCHEMA VALIDATION FAILED: {val_err}")
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)

    except Exception as err:
        logger.error(f"UNEXPECTED ERROR: {err}")
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
    finally:
        correlation_id_ctx.reset(token)


def start_consumer():
    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
    parameters = pika.ConnectionParameters(
        host=RABBITMQ_HOST,
        port=RABBITMQ_PORT,
        credentials=credentials,
        heartbeat=600,
        blocked_connection_timeout=300,
    )

    while True:
        try:
            logger.info(f"Connecting to RabbitMQ at {RABBITMQ_HOST}:{RABBITMQ_PORT}...")
            connection = pika.BlockingConnection(parameters)
            channel = connection.channel()

            channel.exchange_declare(
                exchange=Exchange.ORDERS, exchange_type="topic", durable=True
            )
            channel.queue_declare(queue=Queue.ORDER_NOTIFICATIONS, durable=True)
            channel.queue_bind(
                exchange=Exchange.ORDERS,
                queue=Queue.ORDER_NOTIFICATIONS,
                routing_key=OrderRoutingKey.ORDER_ALL,
            )

            channel.basic_qos(prefetch_count=1)
            channel.basic_consume(
                queue=Queue.ORDER_NOTIFICATIONS, on_message_callback=process_message
            )

            logger.info("Connected to RabbitMQ! Consumer started successfully.")
            channel.start_consuming()

        except pika.exceptions.AMQPConnectionError as err:
            logger.warning(f"RabbitMQ unavailable ({err}). Retrying in 5 seconds...")
            time.sleep(5)
        except KeyboardInterrupt:
            logger.info("Consumer stopped by user.")
            break
        except Exception as err:
            logger.error(f"Unexpected connection failure: {err}. Retrying in 5s...")
            time.sleep(5)


if __name__ == "__main__":
    start_consumer()
