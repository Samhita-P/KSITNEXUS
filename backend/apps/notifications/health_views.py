"""
Health check views for monitoring
"""

from django.http import JsonResponse
from django.db import connection
from django.core.cache import cache
from django.conf import settings
import redis
import psutil
import os
from datetime import datetime


def health_check(request):
    """Basic health check endpoint"""
    return JsonResponse({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'ksit-nexus-backend'
    })


def detailed_health_check(request):
    """Detailed health check with system metrics"""
    health_data = {
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'ksit-nexus-backend',
        'checks': {}
    }
    
    # Database check
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            health_data['checks']['database'] = {
                'status': 'healthy',
                'response_time': 0
            }
    except Exception as e:
        health_data['checks']['database'] = {
            'status': 'unhealthy',
            'error': str(e)
        }
        health_data['status'] = 'unhealthy'
    
    # Cache check
    try:
        cache.set('health_check', 'ok', 10)
        cache_result = cache.get('health_check')
        health_data['checks']['cache'] = {
            'status': 'healthy' if cache_result == 'ok' else 'unhealthy'
        }
    except Exception as e:
        health_data['checks']['cache'] = {
            'status': 'unhealthy',
            'error': str(e)
        }
        health_data['status'] = 'unhealthy'
    
    # Redis check
    try:
        redis_client = redis.from_url(settings.REDIS_URL)
        redis_client.ping()
        health_data['checks']['redis'] = {
            'status': 'healthy'
        }
    except Exception as e:
        health_data['checks']['redis'] = {
            'status': 'unhealthy',
            'error': str(e)
        }
        health_data['status'] = 'unhealthy'
    
    # System metrics
    try:
        health_data['system'] = {
            'cpu_percent': psutil.cpu_percent(),
            'memory_percent': psutil.virtual_memory().percent,
            'disk_percent': psutil.disk_usage('/').percent,
            'load_average': os.getloadavg() if hasattr(os, 'getloadavg') else None
        }
    except Exception as e:
        health_data['system'] = {
            'error': str(e)
        }
    
    return JsonResponse(health_data)


def metrics(request):
    """Prometheus metrics endpoint"""
    try:
        # Basic metrics
        metrics_data = []
        
        # Database connections
        with connection.cursor() as cursor:
            cursor.execute("SELECT count(*) FROM pg_stat_activity")
            db_connections = cursor.fetchone()[0]
            metrics_data.append(f'django_db_connections {db_connections}')
        
        # Cache metrics
        try:
            cache_info = cache._cache.get_stats()
            if cache_info:
                for key, value in cache_info[0].items():
                    metrics_data.append(f'django_cache_{key} {value}')
        except:
            pass
        
        # System metrics
        metrics_data.append(f'django_cpu_percent {psutil.cpu_percent()}')
        metrics_data.append(f'django_memory_percent {psutil.virtual_memory().percent}')
        metrics_data.append(f'django_disk_percent {psutil.disk_usage("/").percent}')
        
        # Application metrics
        from django.contrib.auth import get_user_model
        User = get_user_model()
        metrics_data.append(f'django_users_total {User.objects.count()}')
        
        from .models import Notification
        metrics_data.append(f'django_notifications_total {Notification.objects.count()}')
        
        from apps.study_groups.models import StudyGroup
        metrics_data.append(f'django_study_groups_total {StudyGroup.objects.count()}')
        
        from apps.reservations.models import Reservation
        metrics_data.append(f'django_reservations_total {Reservation.objects.count()}')
        
        return JsonResponse({
            'metrics': '\n'.join(metrics_data)
        }, content_type='text/plain')
        
    except Exception as e:
        return JsonResponse({
            'error': str(e)
        }, status=500)
