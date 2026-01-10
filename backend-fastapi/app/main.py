from fastapi import FastAPI, Request, HTTPException
from .logger import logger
from .middleware import SecurityLoggingMiddleware

app = FastAPI(title="SafePay API", version="1.0.0", description="SafePay API")
app.add_middleware(SecurityLoggingMiddleware)

@app.post("/login")
async def login(request: Request):
    data = await request.json()
    username = data.get("username", "unknown")
    password = data.get("password", "")
    client_ip = request.client.host
    request_id = request.state.request_id

    if username == "admin" and password != "secret":
        logger.warning(
            "Authentication failed",
            extra={
                "component": "auth-engine",
                "event": "login_failed",
                "src_ip": client_ip,
                "username": username,
                "request_id": request_id,
                "reason": "invalid_credentials"
            }
        )
        raise HTTPException(status_code=401, detail="Unauthorized")

    logger.info(
        "Authentication success",
        extra={
            "component": "auth-engine",
            "event": "login_success",
            "src_ip": client_ip,
            "username": username,
            "request_id": request_id
        }
    )

    return {"status": "success"}

@app.get("/items/{item_id}")
async def read_item(item_id: str, request: Request):
    logger.info(
        "Resource access",
        extra={
            "component": "api-engine",
            "event": "access_resource",
            "src_ip": request.client.host,
            "request_id": request.state.request_id,
            "resource_id": item_id
        }
    )

    # Intentional unsafe behavior (documented vulnerability)
    if any(keyword in item_id.upper() for keyword in ["SELECT", "UNION", "OR"]):
        logger.warning(
            "Suspicious query pattern detected",
            extra={
                "component": "api-engine",
                "event": "possible_sqli",
                "src_ip": request.client.host,
                "request_id": request.state.request_id,
                "payload": item_id
            }
        )

    return {"item_id": item_id}
