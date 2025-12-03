"""
Performance optimization utilities for KSIT Nexus
"""

from functools import wraps
from django.core.cache import cache
from django.core.cache.utils import make_template_fragment_key
from django.http import JsonResponse
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page
from django.views.decorators.vary import vary_on_headers
from django.core.paginator import Paginator
from django.db.models import Prefetch
import hashlib
import json
import time


def api_cache(timeout=300, key_prefix='api'):
    """
    Decorator for caching API responses
    """
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            # Create cache key based on request parameters
            cache_key = f"{key_prefix}_{request.path}_{hashlib.md5(request.GET.urlencode().encode()).hexdigest()}"
            
            # Try to get from cache
            cached_response = cache.get(cache_key)
            if cached_response:
                return JsonResponse(cached_response)
            
            # Execute view function
            response = view_func(request, *args, **kwargs)
            
            # Cache the response if it's successful
            if hasattr(response, 'data') and response.status_code == 200:
                cache.set(cache_key, response.data, timeout)
            
            return response
        return wrapper
    return decorator


def rate_limit(max_requests=100, window=3600):
    """
    Rate limiting decorator
    """
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            # Get client IP
            client_ip = request.META.get('REMOTE_ADDR', 'unknown')
            
            # Create rate limit key
            rate_key = f"rate_limit_{client_ip}_{view_func.__name__}"
            
            # Get current request count
            current_requests = cache.get(rate_key, 0)
            
            if current_requests >= max_requests:
                return JsonResponse({
                    'error': 'Rate limit exceeded',
                    'retry_after': window
                }, status=429)
            
            # Increment request count
            cache.set(rate_key, current_requests + 1, window)
            
            return view_func(request, *args, **kwargs)
        return wrapper
    return decorator


def optimize_queryset(queryset, select_related=None, prefetch_related=None):
    """
    Optimize queryset with select_related and prefetch_related
    """
    if select_related:
        queryset = queryset.select_related(*select_related)
    
    if prefetch_related:
        queryset = queryset.prefetch_related(*prefetch_related)
    
    return queryset


def paginate_queryset(queryset, page_size=20, page=1):
    """
    Paginate queryset efficiently
    """
    paginator = Paginator(queryset, page_size)
    page_obj = paginator.get_page(page)
    
    return {
        'results': list(page_obj),
        'count': paginator.count,
        'num_pages': paginator.num_pages,
        'current_page': page_obj.number,
        'has_next': page_obj.has_next(),
        'has_previous': page_obj.has_previous(),
    }


class PerformanceMixin:
    """
    Mixin for performance optimization in views
    """
    
    def get_optimized_queryset(self):
        """
        Override this method to return optimized queryset
        """
        return self.get_queryset()
    
    def get_cache_key(self):
        """
        Generate cache key for the view
        """
        return f"{self.__class__.__name__}_{self.request.path}_{hashlib.md5(self.request.GET.urlencode().encode()).hexdigest()}"
    
    def get_cached_data(self, timeout=300):
        """
        Get cached data if available
        """
        cache_key = self.get_cache_key()
        return cache.get(cache_key)
    
    def set_cached_data(self, data, timeout=300):
        """
        Cache the data
        """
        cache_key = self.get_cache_key()
        cache.set(cache_key, data, timeout)


def image_optimization_middleware(get_response):
    """
    Middleware for image optimization
    """
    def middleware(request):
        response = get_response(request)
        
        # Add image optimization headers
        if request.path.startswith('/media/') and request.path.lower().endswith(('.jpg', '.jpeg', '.png', '.gif', '.webp')):
            response['Cache-Control'] = 'public, max-age=31536000'  # 1 year
            response['Expires'] = 'Thu, 31 Dec 2025 23:59:59 GMT'
        
        return response
    
    return middleware


def database_query_optimization():
    """
    Database query optimization utilities
    """
    return {
        'select_related': [
            'user', 'group', 'sender', 'receiver'
        ],
        'prefetch_related': [
            'members', 'notifications', 'messages'
        ],
        'only': [
            'id', 'name', 'title', 'content', 'created_at', 'updated_at'
        ]
    }


def api_response_optimization(data, include_metadata=True):
    """
    Optimize API response data
    """
    if not include_metadata:
        return data
    
    return {
        'data': data,
        'metadata': {
            'timestamp': time.time(),
            'version': '1.0.0',
            'optimized': True
        }
    }
