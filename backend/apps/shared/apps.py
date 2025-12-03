"""
Shared app configuration
"""
from django.apps import AppConfig


class SharedConfig(AppConfig):
    """Configuration for shared app"""
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.shared'
    verbose_name = 'Shared Utilities'

