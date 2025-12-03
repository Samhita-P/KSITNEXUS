"""
Structured logging utilities
"""
import logging
import json
from datetime import datetime
from typing import Optional, Dict, Any
from django.conf import settings
from django.utils import timezone


class StructuredFormatter(logging.Formatter):
    """JSON formatter for structured logging"""
    
    def format(self, record: logging.LogRecord) -> str:
        """Format log record as JSON"""
        log_data = {
            'timestamp': timezone.now().isoformat(),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno,
        }
        
        # Add trace ID if available
        if hasattr(record, 'trace_id'):
            log_data['trace_id'] = record.trace_id
        
        # Add user information if available
        if hasattr(record, 'user_id'):
            log_data['user_id'] = record.user_id
        
        # Add request information if available
        if hasattr(record, 'request_path'):
            log_data['request_path'] = record.request_path
            log_data['request_method'] = getattr(record, 'request_method', None)
            log_data['status_code'] = getattr(record, 'status_code', None)
        
        # Add exception information if available
        if record.exc_info:
            log_data['exception'] = self.formatException(record.exc_info)
        
        # Add extra fields
        if hasattr(record, 'extra_data'):
            log_data.update(record.extra_data)
        
        return json.dumps(log_data)


def get_logger(name: str) -> logging.Logger:
    """
    Get a logger with structured formatting
    
    Args:
        name: Logger name (typically __name__)
        
    Returns:
        Configured logger instance
    """
    logger = logging.getLogger(name)
    
    # Only configure if not already configured
    if not logger.handlers:
        handler = logging.StreamHandler()
        handler.setFormatter(StructuredFormatter())
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)
    
    return logger


def log_request(request, trace_id: Optional[str] = None, extra_data: Optional[Dict[str, Any]] = None):
    """
    Log HTTP request
    
    Args:
        request: Django request object
        trace_id: Optional trace ID
        extra_data: Optional extra data to include
    """
    logger = get_logger('request')
    log_record = logging.LogRecord(
        name='request',
        level=logging.INFO,
        pathname='',
        lineno=0,
        msg=f"{request.method} {request.path}",
        args=(),
        exc_info=None,
    )
    log_record.request_path = request.path
    log_record.request_method = request.method
    if trace_id:
        log_record.trace_id = trace_id
    if hasattr(request, 'user') and request.user.is_authenticated:
        log_record.user_id = request.user.id
    if extra_data:
        log_record.extra_data = extra_data
    
    logger.handle(log_record)


def log_response(request, response, trace_id: Optional[str] = None, extra_data: Optional[Dict[str, Any]] = None):
    """
    Log HTTP response
    
    Args:
        request: Django request object
        response: Django response object
        trace_id: Optional trace ID
        extra_data: Optional extra data to include
    """
    logger = get_logger('response')
    log_record = logging.LogRecord(
        name='response',
        level=logging.INFO,
        pathname='',
        lineno=0,
        msg=f"{request.method} {request.path} - {response.status_code}",
        args=(),
        exc_info=None,
    )
    log_record.request_path = request.path
    log_record.request_method = request.method
    log_record.status_code = response.status_code
    if trace_id:
        log_record.trace_id = trace_id
    if hasattr(request, 'user') and request.user.is_authenticated:
        log_record.user_id = request.user.id
    if extra_data:
        log_record.extra_data = extra_data
    
    logger.handle(log_record)

