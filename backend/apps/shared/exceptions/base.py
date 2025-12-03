"""
Base exception classes
"""
import logging
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
from typing import Any, Dict
from apps.shared.utils.logging import get_logger
from apps.shared.services.audit_service import AuditService

logger = get_logger(__name__)


class BaseAPIException(Exception):
    """Base exception class for API errors"""
    
    status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
    default_detail = 'A server error occurred.'
    default_code = 'error'
    
    def __init__(self, detail: str = None, code: str = None, status_code: int = None):
        """
        Initialize exception
        
        Args:
            detail: Error detail message
            code: Error code
            status_code: HTTP status code
        """
        if detail is None:
            detail = self.default_detail
        if code is None:
            code = self.default_code
        if status_code is not None:
            self.status_code = status_code
        
        self.detail = detail
        self.code = code
        super().__init__(detail)


def handle_exception(exc: Exception, context: Dict[str, Any]) -> Response:
    """
    Custom exception handler
    
    Args:
        exc: Exception instance
        context: Request context
        
    Returns:
        Response object
    """
    request = context.get('request')
    
    # Call DRF's default exception handler first
    response = exception_handler(exc, context)
    
    # Log the exception
    try:
        extra_data = {}
        if request:
            extra_data['request_path'] = request.path
            extra_data['request_method'] = request.method
            if request.user.is_authenticated:
                extra_data['user_id'] = request.user.id
        
        # Use standard logging for exceptions
        import logging as std_logging
        std_logging.getLogger(__name__).error(
            f"Exception: {exc.__class__.__name__} - {str(exc)}",
            exc_info=True,
            extra=extra_data
        )
    except Exception:
        # Fallback to simple logging
        import logging as std_logging
        std_logging.error(f"Exception: {exc.__class__.__name__} - {str(exc)}", exc_info=True)
    
    # Log to audit log if request is available
    if request:
        try:
            AuditService.log_action(
                user=request.user if request.user.is_authenticated else None,
                action='other',
                resource_type='Exception',
                request=request,
                description=f"Exception: {exc.__class__.__name__} - {str(exc)}",
                severity='high',
                is_success=False,
                error_message=str(exc)
            )
        except Exception:
            # Don't fail if audit logging fails
            pass
    
    # Customize the response if needed
    if response is not None:
        custom_response_data = {
            'error': {
                'code': response.data.get('code', 'error'),
                'message': response.data.get('detail', str(exc)),
                'status_code': response.status_code,
            }
        }
        
        # Add field errors if present
        if isinstance(response.data, dict) and 'detail' not in response.data:
            custom_response_data['error']['fields'] = response.data
        
        response.data = custom_response_data
    
    return response

