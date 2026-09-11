import os
from fastapi import FastAPI

ROOT_PATH = os.getenv("ROOT_PATH", "")

app = FastAPI(
    title="Order Service",
    root_path=ROOT_PATH
)

@app.get("/orders")
def get_orders():
    return {
        "status": "success",
        "service": "order-service",
        "data": [
            {"id": "ord_101", "item": "Mechanical Keyboard", "price": 120.00},
            {"id": "ord_102", "item": "Wireless Mouse", "price": 45.50},
            {"id": "ord_103", "item": "UltraWide Monitor", "price": 450.00}
        ]
    }
