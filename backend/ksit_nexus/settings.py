"""
Django settings for ksit_nexus project.
"""

import os
from pathlib import Path
import environ

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# Environment variables
env = environ.Env(
    DEBUG=(bool, False)
)

# Read .env file if it exists (for local development)
env_file = os.path.join(BASE_DIR, '.env')
if os.path.exists(env_file):
    environ.Env.read_env(env_file)

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = env('SECRET_KEY', default='django-insecure-change-this-in-production')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = env('DEBUG', default=False)

# Get Render URL from environment (for production)
RENDER_EXTERNAL_HOSTNAME = env('RENDER_EXTERNAL_HOSTNAME', default=None)

# Allow all hosts for college LAN deployment
# For production on Render, use the Render URL
if RENDER_EXTERNAL_HOSTNAME:
    ALLOWED_HOSTS = [RENDER_EXTERNAL_HOSTNAME, 'localhost', '127.0.0.1']
else:
    # Development/LAN: Allow all hosts
    ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=['*'])

# Application definition
DJANGO_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

THIRD_PARTY_APPS = [
    'rest_framework',
    'rest_framework.authtoken',
    'rest_framework_simplejwt',
    'corsheaders',
    'drf_spectacular',
    # 'channels',  # Temporarily disabled until channels is installed
]

LOCAL_APPS = [
    'apps.shared',  # Shared utilities (must be first)
    'apps.accounts',
    'apps.complaints',
    'apps.feedback',
    'apps.study_groups',
    'apps.notices',
    'apps.meetings',
    'apps.reservations',
    'apps.notifications',
    'apps.chatbot',
    'apps.calendars',
    'apps.recommendations',
    'apps.gamification',
    'apps.academic_planner',
    'apps.marketplace',
    'apps.faculty_admin',
    'apps.safety_wellbeing',
    'apps.lifecycle',
    'apps.local_integrations',
    'apps.awards',
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'apps.shared.middleware.trace_middleware.TraceIDMiddleware',  # Trace ID middleware (first)
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'apps.shared.middleware.logging_middleware.LoggingMiddleware',  # Logging middleware
    'apps.notifications.performance.image_optimization_middleware',
]

ROOT_URLCONF = 'ksit_nexus.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'ksit_nexus.wsgi.application'
ASGI_APPLICATION = 'ksit_nexus.asgi.application'

# Database Configuration
# Use PostgreSQL on Render, SQLite for local development
DATABASE_URL = env('DATABASE_URL', default=None)

if DATABASE_URL:
    # Production: Use PostgreSQL from Render
    try:
        import dj_database_url
        DATABASES = {
            'default': dj_database_url.parse(DATABASE_URL, conn_max_age=600)
        }
    except ImportError:
        # Fallback to SQLite if dj-database-url not installed (local dev)
        DATABASES = {
            'default': {
                'ENGINE': 'django.db.backends.sqlite3',
                'NAME': BASE_DIR / 'db.sqlite3',
            }
        }
else:
    # Development: Use SQLite
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

# Redis Configuration
REDIS_URL = env('REDIS_URL', default='redis://localhost:6379/0')

# Cache Configuration
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': REDIS_URL,
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        }
    },
    'api_cache': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': REDIS_URL,
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'KEY_PREFIX': 'api_cache',
        }
    }
}

# Channels Configuration - Temporarily disabled
# CHANNEL_LAYERS = {
#     'default': {
#         'BACKEND': 'channels_redis.core.RedisChannelLayer',
#         'CONFIG': {
#             'hosts': [('localhost', 6379)],
#         },
#     },
# }

# Session Configuration
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Asia/Kolkata'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# For production on Render, media files should be served via a storage service
# For now, we'll use local storage (consider upgrading to S3/Cloudinary later)
# In production, ensure MEDIA_ROOT is writable
if not DEBUG:
    # Ensure media directory exists
    MEDIA_ROOT.mkdir(parents=True, exist_ok=True)

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Custom User Model
AUTH_USER_MODEL = 'accounts.User'  # apps.accounts.User

# REST Framework Configuration
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'apps.accounts.jwt_authentication.CookieJWTAuthentication',
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
    'EXCEPTION_HANDLER': 'apps.shared.exceptions.base.handle_exception',  # Custom exception handler
}

# CORS Configuration
# In production, allow specific origins; in development, allow all
if DEBUG:
    CORS_ALLOW_ALL_ORIGINS = True  # Development: Allow all origins
else:
    # Production: Allow specific origins
    CORS_ALLOW_ALL_ORIGINS = False
    CORS_ALLOWED_ORIGINS = env.list(
        'CORS_ALLOWED_ORIGINS',
        default=[
            'https://ksit-nexus.onrender.com',
            'https://ksit-nexus-app.web.app',
            'https://ksit-nexus-app.firebaseapp.com',
        ]
    )

CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]
CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]

# CSRF Configuration
# For Flutter mobile apps, CSRF is typically handled via tokens
if RENDER_EXTERNAL_HOSTNAME:
    # Production: Use Render URL
    CSRF_TRUSTED_ORIGINS = [
        f'https://{RENDER_EXTERNAL_HOSTNAME}',
        'https://ksit-nexus.onrender.com',
    ]
    CSRF_COOKIE_SECURE = True  # HTTPS required in production
else:
    # Development/LAN: Allow localhost and common IPs
    CSRF_TRUSTED_ORIGINS = env.list(
        'CSRF_TRUSTED_ORIGINS',
        default=[
            'http://localhost:8002',
            'http://127.0.0.1:8002',
            'http://0.0.0.0:8002',
            'http://100.87.200.4:8002',
            'http://10.0.0.0:8002',
            'http://10.222.10.6:8002',
        ]
    )
    CSRF_COOKIE_SECURE = False  # HTTP allowed in development

CSRF_COOKIE_HTTPONLY = False  # Allow JavaScript access for Flutter

# Spectacular Configuration
SPECTACULAR_SETTINGS = {
    'TITLE': 'KSIT Nexus API',
    'DESCRIPTION': 'Digital Campus App API for KSIT',
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
    'COMPONENT_SPLIT_REQUEST': True,
    'SCHEMA_PATH_PREFIX': '/api/',
}

# JWT Configuration
from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=24),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'VERIFYING_KEY': None,
    'AUDIENCE': None,
    'ISSUER': None,
    'JWK_URL': None,
    'LEEWAY': 0,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'AUTH_HEADER_NAME': 'HTTP_AUTHORIZATION',
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
    'USER_AUTHENTICATION_RULE': 'rest_framework_simplejwt.authentication.default_user_authentication_rule',
    'AUTH_TOKEN_CLASSES': ('rest_framework_simplejwt.tokens.AccessToken',),
    'TOKEN_TYPE_CLAIM': 'token_type',
    'TOKEN_USER_CLASS': 'rest_framework_simplejwt.models.TokenUser',
    'JTI_CLAIM': 'jti',
    'SLIDING_TOKEN_REFRESH_EXP_CLAIM': 'refresh_exp',
    'SLIDING_TOKEN_LIFETIME': timedelta(hours=24),
    'SLIDING_TOKEN_REFRESH_LIFETIME': timedelta(days=7),
}

# Keycloak Configuration
KEYCLOAK_SERVER_URL = env('KEYCLOAK_SERVER_URL', default='http://keycloak:8080')
KEYCLOAK_REALM = env('KEYCLOAK_REALM', default='ksit-nexus')
KEYCLOAK_CLIENT_ID = env('KEYCLOAK_CLIENT_ID', default='ksit-nexus-client')
KEYCLOAK_CLIENT_SECRET = env('KEYCLOAK_CLIENT_SECRET', default='your-client-secret')

# OTP Configuration (simplified for development)
# OTP_TOTP_ISSUER = 'KSIT Nexus'

# Email Configuration (for production)
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'

# API Rate Limiting Configuration
REST_FRAMEWORK['DEFAULT_THROTTLE_CLASSES'] = [
    'rest_framework.throttling.AnonRateThrottle',
    'rest_framework.throttling.UserRateThrottle'
]
REST_FRAMEWORK['DEFAULT_THROTTLE_RATES'] = {
    'anon': '100/hour',
    'user': '1000/hour'
}

# Performance Configuration
PERFORMANCE_SETTINGS = {
    'API_CACHE_TIMEOUT': 300,  # 5 minutes
    'IMAGE_CACHE_TIMEOUT': 31536000,  # 1 year
    'RATE_LIMIT_REQUESTS': 100,
    'RATE_LIMIT_WINDOW': 3600,  # 1 hour
    'PAGINATION_SIZE': 20,
    'MAX_PAGINATION_SIZE': 100,
}

# Firebase Cloud Messaging Configuration
FCM_SERVER_KEY = env('FCM_SERVER_KEY', default='your-fcm-server-key')
FCM_PROJECT_ID = env('FCM_PROJECT_ID', default='your-fcm-project-id')
FCM_SERVICE_ACCOUNT_PATH = env('FCM_SERVICE_ACCOUNT_PATH', default='')

# Celery Configuration
CELERY_BROKER_URL = REDIS_URL
CELERY_RESULT_BACKEND = REDIS_URL
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = TIME_ZONE
CELERY_ENABLE_UTC = True
CELERY_TASK_TRACK_STARTED = True
CELERY_TASK_TIME_LIMIT = 30 * 60  # 30 minutes
CELERY_TASK_SOFT_TIME_LIMIT = 25 * 60  # 25 minutes
CELERY_WORKER_SEND_TASK_EVENTS = True
CELERY_TASK_SEND_SENT_EVENT = True

# Celery Beat Configuration (for scheduled tasks)
CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'

# Note: Celery Beat schedule is managed via django-celery-beat database scheduler
# Tasks can be added via admin interface or programmatically
# For reference, notification tasks are:
# - apps.notifications.tasks.generate_daily_digests (daily at 9:00 AM)
# - apps.notifications.tasks.generate_weekly_digests (Monday at 9:00 AM)
# - apps.notifications.tasks.escalate_notifications (every 30 minutes)
# - apps.notifications.tasks.send_digest_notifications (every 5 minutes)
# - apps.notifications.tasks.generate_notification_summaries (every hour)

# Celery Task Routes
CELERY_TASK_ROUTES = {
    'apps.notifications.tasks.*': {'queue': 'notifications'},
    'apps.accounts.tasks.*': {'queue': 'accounts'},
    'apps.complaints.tasks.*': {'queue': 'complaints'},
    # Add more task routes as needed
}

# Celery Task Priorities
CELERY_TASK_DEFAULT_PRIORITY = 5
CELERY_TASK_MAX_PRIORITY = 10

# Logging Configuration
# Use simple formatter for now, structured formatter will be used via middleware
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {asctime} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
        'file': {
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs' / 'django.log',
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['console', 'file'] if not DEBUG else ['console'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file'] if not DEBUG else ['console'],
            'level': 'INFO',
            'propagate': False,
        },
        'apps': {
            'handlers': ['console', 'file'] if not DEBUG else ['console'],
            'level': 'INFO',
            'propagate': False,
        },
        'celery': {
            'handlers': ['console', 'file'] if not DEBUG else ['console'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}

# Create logs directory if it doesn't exist
LOGS_DIR = BASE_DIR / 'logs'
LOGS_DIR.mkdir(exist_ok=True)