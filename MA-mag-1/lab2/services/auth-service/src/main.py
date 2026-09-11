import os
from fastapi import FastAPI

ROOT_PATH = os.getenv("ROOT_PATH", "")

app = FastAPI(
    title="Auth Service",
    root_path=ROOT_PATH
)

@app.get("/auth")
def get_auth():
    return {
        "status": "success",
        "service": "auth-service",
        "data": { "username": "HELP", "email": "helpme@gmail.com" }
    }
