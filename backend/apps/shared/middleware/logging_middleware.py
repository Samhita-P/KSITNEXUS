"""
Logging middleware for request/response logging
"""
from django.utils.deprecation import MiddlewareMixin
from apps.shared.utils.logging import log_request, log_response
from apps.shared.utils.trace import get_trace_id


class LoggingMiddleware(MiddlewareMixin):
    """
    Middleware to log requests and responses
    
    Logs structured information about each request and response
    """
    
    def process_request(self, request):
        """Log request"""
        trace_id = get_trace_id()
        log_request(request, trace_id=trace_id)
        return None
    
    def process_response(self, request, response):
        """Log response"""
        trace_id = get_trace_id()
        log_response(request, response, trace_id=trace_id)
        return response

