"""
Django settings for ksit_nexus project.
"""

import os
from pathlib import Path
import environ

BASE_DIR = Path(__file__).resolve().parent.parent

# Detect Render environment
ON_RENDER = "RENDER" in os.environ

# Environment variables
env = environ.Env(DEBUG=(bool, False))
env_file = os.path.join(BASE_DIR, ".env")
if os.path.exists(env_file):
    environ.Env.read_env(env_file)

SECRET_KEY = env("SECRET_KEY", default="django-insecure-change-this-in-production")
DEBUG = env("DEBUG", default=False)

# Render hostname
RENDER_EXTERNAL_HOSTNAME = env("RENDER_EXTERNAL_HOSTNAME", default=None)

if RENDER_EXTERNAL_HOSTNAME:
    ALLOWED_HOSTS = [RENDER_EXTERNAL_HOSTNAME, "localhost", "127.0.0.1"]
else:
    ALLOWED_HOSTS = env.list("ALLOWED_HOSTS", default=["*"])

# ---------------------------------------------------------
# APPLICATIONS
# ---------------------------------------------------------

DJANGO_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
]

THIRD_PARTY_APPS = [
    "rest_framework",
    "rest_framework.authtoken",
    "rest_framework_simplejwt",
    "corsheaders",
    "drf_spectacular",
]

LOCAL_APPS = [
    "apps.shared",
    "apps.accounts",
    "apps.complaints",
    "apps.feedback",
    "apps.study_groups",
    "apps.notices",
    "apps.meetings",
    "apps.reservations",
    "apps.notifications",
    "apps.chatbot",
    "apps.calendars",
    "apps.recommendations",
    "apps.gamification",
    "apps.academic_planner",
    "apps.marketplace",
    "apps.faculty_admin",
    "apps.safety_wellbeing",
    "apps.lifecycle",
    "apps.local_integrations",
    "apps.awards",
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

# ---------------------------------------------------------
# MIDDLEWARE
# ---------------------------------------------------------

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "apps.shared.middleware.trace_middleware.TraceIDMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "apps.shared.middleware.logging_middleware.LoggingMiddleware",
]

ROOT_URLCONF = "ksit_nexus.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

# ON RENDER — ONLY WSGI WORKS
WSGI_APPLICATION = "ksit_nexus.wsgi.application"
# Disable ASGI (Channels requires Redis)
ASGI_APPLICATION = None

# ---------------------------------------------------------
# DATABASE
# ---------------------------------------------------------

DATABASE_URL = env("DATABASE_URL", default=None)

if DATABASE_URL:
    import dj_database_url

    DATABASES = {
        "default": dj_database_url.parse(DATABASE_URL, conn_max_age=600)
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }

# ---------------------------------------------------------
# CACHE / REDIS (DISABLED ON RENDER)
# ---------------------------------------------------------

if ON_RENDER:
    # Use Django memory cache
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.locmem.LocMemCache"
        }
    }
else:
    REDIS_URL = env("REDIS_URL", default="redis://localhost:6379/0")
    CACHES = {
        "default": {
            "BACKEND": "django_redis.cache.RedisCache",
            "LOCATION": REDIS_URL,
            "OPTIONS": {"CLIENT_CLASS": "django_redis.client.DefaultClient"},
        }
    }

SESSION_ENGINE = "django.contrib.sessions.backends.cache"
SESSION_CACHE_ALIAS = "default"

# ---------------------------------------------------------
# STATIC & MEDIA
# ---------------------------------------------------------

STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"

MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"

if ON_RENDER:
    # Render has ephemeral storage but directory must exist
    MEDIA_ROOT.mkdir(exist_ok=True)

# ---------------------------------------------------------
# AUTH
# ---------------------------------------------------------

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
AUTH_USER_MODEL = "accounts.User"

# ---------------------------------------------------------
# REST FRAMEWORK
# ---------------------------------------------------------

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "apps.accounts.jwt_authentication.CookieJWTAuthentication",
        "rest_framework_simplejwt.authentication.JWTAuthentication",
        "rest_framework.authentication.TokenAuthentication",
        "rest_framework.authentication.SessionAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": ["rest_framework.permissions.IsAuthenticated"],
    "DEFAULT_RENDERER_CLASSES": ["rest_framework.renderers.JSONRenderer"],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
}

# ---------------------------------------------------------
# CORS / CSRF
# ---------------------------------------------------------

# Allow all origins for mobile apps (APK/React Native)
# Mobile apps don't have a fixed origin, so we need to allow all
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True

# Additional allowed origins for web apps (optional, since ALLOW_ALL is True)
CORS_ALLOWED_ORIGINS = [
    "https://ksitnexus.onrender.com",
    "https://ksit-nexus-app.firebaseapp.com",
    "https://ksit-nexus-app.web.app",
]

if RENDER_EXTERNAL_HOSTNAME:
    CSRF_TRUSTED_ORIGINS = [f"https://{RENDER_EXTERNAL_HOSTNAME}"]
else:
    CSRF_TRUSTED_ORIGINS = ["https://ksitnexus.onrender.com"]

# ---------------------------------------------------------
# JWT
# ---------------------------------------------------------

from datetime import timedelta

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(hours=24),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "ALGORITHM": "HS256",
    "SIGNING_KEY": SECRET_KEY,
}

# ---------------------------------------------------------
# CELERY — DISABLED ON RENDER
# ---------------------------------------------------------

if ON_RENDER:
    CELERY_BROKER_URL = None
    CELERY_RESULT_BACKEND = None
else:
    CELERY_BROKER_URL = env("REDIS_URL", default="redis://localhost:6379/0")
    CELERY_RESULT_BACKEND = CELERY_BROKER_URL

# ---------------------------------------------------------
# LOGGING — DO NOT WRITE TO FILES ON RENDER
# ---------------------------------------------------------

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "console": {"class": "logging.StreamHandler"},
    },
    "root": {
        "handlers": ["console"],
        "level": "INFO",
    },
}

