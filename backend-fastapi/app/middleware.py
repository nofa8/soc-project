from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
import uuid
from .logger import logger

class SecurityLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id

        response = await call_next(request)

        logger.info(
            "HTTP request processed",
            extra={
                "component": "http-gateway",
                "event": "http_request",
                "src_ip": request.client.host,
                "request_id": request_id,
                "path": request.url.path,
                "method": request.method,
                "status_code": response.status_code
            }
        )

        return response
