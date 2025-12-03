"""
Audit logging service
"""
from typing import Optional, Dict, Any
from django.contrib.auth import get_user_model
from apps.shared.models.audit import AuditLog
from apps.shared.utils.trace import get_trace_id

User = get_user_model()


class AuditService:
    """Service for audit logging"""
    
    @staticmethod
    def log_action(
        user=None,
        action='other',
        resource_type='',
        resource_id=None,
        content_object=None,
        request=None,
        old_values=None,
        new_values=None,
        description='',
        metadata=None,
        severity='medium',
        is_success=True,
        error_message=''
    ) -> AuditLog:
        """
        Log an action to the audit log
        
        Args:
            user: User who performed the action
            action: Action type
            resource_type: Type of resource
            resource_id: ID of resource
            content_object: Related object
            request: Django request object
            old_values: Old values (for updates)
            new_values: New values (for updates)
            description: Description of action
            metadata: Additional metadata
            severity: Severity level
            is_success: Whether action was successful
            error_message: Error message if failed
            
        Returns:
            AuditLog instance
        """
        # Extract request information
        ip_address = None
        user_agent = ''
        request_path = ''
        request_method = ''
        trace_id = ''
        
        if request:
            ip_address = get_client_ip(request)
            user_agent = request.META.get('HTTP_USER_AGENT', '')
            request_path = request.path
            request_method = request.method
            trace_id = get_trace_id() or ''
        
        # Determine resource type from content object
        if content_object and not resource_type:
            resource_type = content_object.__class__.__name__
            resource_id = content_object.pk
        
        return AuditLog.log_action(
            user=user,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            content_object=content_object,
            ip_address=ip_address,
            user_agent=user_agent,
            request_path=request_path,
            request_method=request_method,
            trace_id=trace_id,
            old_values=old_values,
            new_values=new_values,
            description=description,
            metadata=metadata,
            severity=severity,
            is_success=is_success,
            error_message=error_message
        )
    
    @staticmethod
    def log_login(user: User, request, is_success: bool = True, error_message: str = ''):
        """Log user login"""
        return AuditService.log_action(
            user=user,
            action='login',
            resource_type='User',
            resource_id=user.id if user else None,
            request=request,
            description=f"User login: {user.username if user else 'Unknown'}",
            severity='high' if not is_success else 'medium',
            is_success=is_success,
            error_message=error_message
        )
    
    @staticmethod
    def log_logout(user: User, request):
        """Log user logout"""
        return AuditService.log_action(
            user=user,
            action='logout',
            resource_type='User',
            resource_id=user.id if user else None,
            request=request,
            description=f"User logout: {user.username if user else 'Unknown'}",
            severity='medium',
            is_success=True
        )
    
    @staticmethod
    def log_data_access(user: User, resource_type: str, resource_id: int, request):
        """Log data access"""
        return AuditService.log_action(
            user=user,
            action='data_access',
            resource_type=resource_type,
            resource_id=resource_id,
            request=request,
            description=f"Data access: {resource_type} #{resource_id}",
            severity='low',
            is_success=True
        )
    
    @staticmethod
    def log_permission_change(
        user: User,
        target_user: User,
        permission: str,
        granted: bool,
        request
    ):
        """Log permission change"""
        action = 'permission_granted' if granted else 'permission_revoked'
        return AuditService.log_action(
            user=user,
            action=action,
            resource_type='User',
            resource_id=target_user.id,
            request=request,
            description=f"Permission {action}: {permission} for {target_user.username}",
            metadata={'permission': permission, 'target_user_id': target_user.id},
            severity='high',
            is_success=True
        )


def get_client_ip(request) -> Optional[str]:
    """
    Get client IP address from request
    
    Args:
        request: Django request object
        
    Returns:
        IP address string
    """
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip

