import logging
import time
import uuid
from pythonjsonlogger import jsonlogger

LOG_FILE = "/app/logs/security.json"

class SecurityJsonFormatter(jsonlogger.JsonFormatter):
    def add_fields(self, log_record, record, message_dict):
        super().add_fields(log_record, record, message_dict)

        log_record.setdefault(
            "timestamp",
            time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
        )
        log_record.setdefault("level", record.levelname)
        log_record.setdefault("component", "unknown")
        log_record.setdefault("soc_event", "generic_event")
        log_record.setdefault("src_ip", "unknown")
        log_record.setdefault("username", "anonymous")
        log_record.setdefault("request_id", "undefined")

def get_logger():
    logger = logging.getLogger("soc_logger")
    logger.setLevel(logging.INFO)
    logger.propagate = False

    if not logger.handlers:
        handler = logging.FileHandler(LOG_FILE)
        formatter = SecurityJsonFormatter()
        handler.setFormatter(formatter)
        logger.addHandler(handler)

    return logger

logger = get_logger()
