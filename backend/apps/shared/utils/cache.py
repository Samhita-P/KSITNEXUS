"""
Cache utilities
"""
from functools import wraps
from typing import Callable, Any, Optional
from django.core.cache import cache as django_cache
from django.conf import settings
import hashlib
import json


def cache_result(timeout: Optional[int] = None, key_prefix: str = 'cache'):
    """
    Decorator to cache function results
    
    Args:
        timeout: Cache timeout in seconds (default from settings)
        key_prefix: Prefix for cache key
        
    Example:
        @cache_result(timeout=300, key_prefix='user_profile')
        def get_user_profile(user_id):
            # Expensive operation
            return profile
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key from function name and arguments
            cache_key = _generate_cache_key(key_prefix, func.__name__, *args, **kwargs)
            
            # Try to get from cache
            result = django_cache.get(cache_key)
            if result is not None:
                return result
            
            # Execute function
            result = func(*args, **kwargs)
            
            # Store in cache
            cache_timeout = timeout or getattr(settings, 'CACHE_TIMEOUT', 300)
            django_cache.set(cache_key, result, cache_timeout)
            
            return result
        
        return wrapper
    return decorator


def _generate_cache_key(prefix: str, func_name: str, *args, **kwargs) -> str:
    """
    Generate a cache key from prefix, function name, and arguments
    
    Args:
        prefix: Cache key prefix
        func_name: Function name
        *args: Function arguments
        **kwargs: Function keyword arguments
        
    Returns:
        Cache key string
    """
    # Create a hash of arguments
    args_str = json.dumps(args, sort_keys=True, default=str)
    kwargs_str = json.dumps(kwargs, sort_keys=True, default=str)
    key_data = f"{prefix}:{func_name}:{args_str}:{kwargs_str}"
    key_hash = hashlib.md5(key_data.encode()).hexdigest()
    return f"{prefix}:{func_name}:{key_hash}"


def invalidate_cache(key_pattern: str):
    """
    Invalidate cache entries matching a pattern
    
    Args:
        key_pattern: Cache key pattern to match
        
    Note:
        This is a simple implementation. For production,
        consider using cache versioning or a more sophisticated
        invalidation strategy.
    """
    # Note: This is a simplified implementation
    # For production, you might want to use cache versioning
    # or maintain a registry of cache keys
    try:
        django_cache.delete_pattern(key_pattern)
    except AttributeError:
        # Redis cache backend supports delete_pattern
        # For other backends, you might need a different approach
        pass

