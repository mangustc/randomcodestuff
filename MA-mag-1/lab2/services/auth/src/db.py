import os
from contextlib import contextmanager

import psycopg2
from psycopg2.extras import RealDictCursor

POSTGRES_HOST = os.getenv("POSTGRES_HOST", "auth-db")
POSTGRES_PORT = int(os.getenv("POSTGRES_PORT", 5432))
POSTGRES_USER = os.environ["POSTGRES_USER"]
POSTGRES_PASSWORD = os.environ["POSTGRES_PASSWORD"]
POSTGRES_DB = os.environ["POSTGRES_DB"]


@contextmanager
def get_connection():
    conn = psycopg2.connect(
        host=POSTGRES_HOST,
        port=POSTGRES_PORT,
        user=POSTGRES_USER,
        password=POSTGRES_PASSWORD,
        dbname=POSTGRES_DB,
        cursor_factory=RealDictCursor,
    )
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

def init_db() -> None:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id         SERIAL PRIMARY KEY,
                    username   VARCHAR(50)  NOT NULL UNIQUE,
                    email      VARCHAR(255) NOT NULL UNIQUE,
                    password   VARCHAR(255) NOT NULL,
                    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
                );
            """)
