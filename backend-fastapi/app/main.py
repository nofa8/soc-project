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
    # Phase 3.2: Neutral Logging for SOC Detection (SQL Injection Experiment)
    # Log the RAW parameter for the SOC to analyze
    logger.info(
        "API Request processed",
        extra={
            "component": "api-engine",
            "soc_event": "api_request",
            "endpoint": "/items",
            "raw_parameter": item_id,
            "src_ip": request.client.host,
            "request_id": request.state.request_id,
            "method": request.method
        }
    )
    
    # Vulnerable logic (simulated for demonstration)
    return {"item_id": item_id, "simulated_query": f"SELECT * FROM items WHERE id = {item_id}"}

@app.get("/error")
async def simulate_error(request: Request):
    logger.error(
        "Internal server error",
        extra={
            "component": "api-engine",
            "soc_event": "internal_error",
            "src_ip": request.client.host,
            "request_id": request.state.request_id
        }
    )
    raise HTTPException(status_code=500, detail="Internal server error")

# --- PHASE 3.1: BROKEN AUTHENTICATION VULNERABILITY ---
@app.get("/admin/system_status")
async def admin_status(request: Request):
    # Vulnerable Logic: Check header OR role (dummy check)
    override_header = request.headers.get("X-Admin-Override")
    
    # In a real app, we'd check JWT role here. 
    # For this lab, we assume any request without the header is "unauthorized" unless mocked otherwise.
    
    if override_header == "true":
        # Log the specific SOC event for detection
        logger.warning(
            "Privilege escalation attempt successful",
            extra={
                "component": "auth-engine",
                "soc_event": "admin_override_access",
                "auth_decision": "override_granted",
                "username": "guest", # Simulated
                "role": "user",      # Simulated role mismatch
                "endpoint": "/admin/system_status",
                "src_ip": request.client.host,
                "request_id": request.state.request_id
            }
        )
        return {"status": "system_active", "mode": "admin_privileged"}
    
    raise HTTPException(status_code=403, detail="Admin access required")
