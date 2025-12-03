"""
Shared services
"""
from .audit_service import AuditService, get_client_ip

__all__ = [
    'AuditService',
    'get_client_ip',
]

