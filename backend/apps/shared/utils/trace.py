"""
Request tracing utilities
"""
import uuid
from typing import Optional
from contextvars import ContextVar

# Context variable for trace ID
_trace_id: ContextVar[Optional[str]] = ContextVar('trace_id', default=None)


def generate_trace_id() -> str:
    """
    Generate a unique trace ID
    
    Returns:
        Unique trace ID string
    """
    return str(uuid.uuid4())


def set_trace_id(trace_id: str):
    """
    Set trace ID in context
    
    Args:
        trace_id: Trace ID to set
    """
    _trace_id.set(trace_id)


def get_trace_id() -> Optional[str]:
    """
    Get trace ID from context
    
    Returns:
        Trace ID if set, None otherwise
    """
    return _trace_id.get()

