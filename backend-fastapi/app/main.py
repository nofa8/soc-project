import uuid
from fastapi import FastAPI, Request, HTTPException
from .logger import logger

app = FastAPI(title="SafePay API", version="1.0.0", description="SafePay API")

# --- REPLACEMENT MIDDLEWARE ---
@app.middleware("http")
async def security_logging_middleware(request: Request, call_next):
    # 1. Generate and attach request ID
    request_id = str(uuid.uuid4())
    request.state.request_id = request_id

    # 2. Process the request
    response = await call_next(request)

    # 3. Log the final telemetry
    logger.info(
        "HTTP request processed",
        extra={
            "component": "http-gateway",
            "soc_event": "http_request",
            "src_ip": request.client.host,
            "request_id": request_id,
            "path": request.url.path,
            "method": request.method,
            "status_code": response.status_code
        }
    )
    return response

@app.post("/login")
async def login(request: Request):
    try:
        data = await request.json()
    except Exception:
        # Prevents 500 errors if the body is empty or invalid
        raise HTTPException(status_code=400, detail="Invalid or missing JSON body")

    username = data.get("username", "unknown")
    password = data.get("password", "")
    client_ip = request.client.host
    request_id = request.state.request_id

    if username == "admin" and password != "secret":
        logger.warning(
            "Authentication failed",
            extra={
                "component": "auth-engine",
                "soc_event": "login_failed",
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
            "soc_event": "login_success",
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
            "soc_event": "access_resource",
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
                "soc_event": "possible_sqli",
                "src_ip": request.client.host,
                "request_id": request.state.request_id,
                "payload": item_id
            }
        )

    return {"item_id": item_id}
