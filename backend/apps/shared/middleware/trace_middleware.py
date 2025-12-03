"""
Trace ID middleware for request tracing
"""
from django.utils.deprecation import MiddlewareMixin
from apps.shared.utils.trace import generate_trace_id, set_trace_id, get_trace_id


class TraceIDMiddleware(MiddlewareMixin):
    """
    Middleware to add trace ID to each request
    
    Adds a trace ID to the request context and response headers
    """
    
    def process_request(self, request):
        """Generate trace ID for request"""
        trace_id = generate_trace_id()
        set_trace_id(trace_id)
        request.trace_id = trace_id
        return None
    
    def process_response(self, request, response):
        """Add trace ID to response headers"""
        trace_id = get_trace_id()
        if trace_id:
            response['X-Trace-ID'] = trace_id
        return response

