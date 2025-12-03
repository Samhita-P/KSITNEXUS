"""
Shared utility functions
"""
from .logging import get_logger, log_request, log_response
from .trace import generate_trace_id, get_trace_id, set_trace_id
from .cache import cache_result, invalidate_cache
from .permissions import (
    user_has_permission,
    user_has_permissions,
    user_has_role,
    get_user_permissions,
    get_user_roles,
)

__all__ = [
    'get_logger',
    'log_request',
    'log_response',
    'generate_trace_id',
    'get_trace_id',
    'set_trace_id',
    'cache_result',
    'invalidate_cache',
    'user_has_permission',
    'user_has_permissions',
    'user_has_role',
    'get_user_permissions',
    'get_user_roles',
]

