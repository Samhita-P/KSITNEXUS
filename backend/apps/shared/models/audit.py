"""
Audit logging models
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey
from django.utils import timezone
from .base import TimestampedModel

User = get_user_model()


class AuditLog(TimestampedModel):
    """Audit log model for tracking system events"""
    
    ACTION_CHOICES = [
        ('create', 'Create'),
        ('read', 'Read'),
        ('update', 'Update'),
        ('delete', 'Delete'),
        ('login', 'Login'),
        ('logout', 'Logout'),
        ('password_change', 'Password Change'),
        ('password_reset', 'Password Reset'),
        ('permission_granted', 'Permission Granted'),
        ('permission_revoked', 'Permission Revoked'),
        ('role_assigned', 'Role Assigned'),
        ('role_revoked', 'Role Revoked'),
        ('data_access', 'Data Access'),
        ('data_export', 'Data Export'),
        ('config_change', 'Configuration Change'),
        ('other', 'Other'),
    ]
    
    user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='audit_logs'
    )
    action = models.CharField(max_length=50, choices=ACTION_CHOICES)
    resource_type = models.CharField(max_length=100, blank=True)  # e.g., 'User', 'Notice', 'Complaint'
    resource_id = models.PositiveIntegerField(null=True, blank=True)
    content_type = models.ForeignKey(
        ContentType,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='audit_logs'
    )
    object_id = models.PositiveIntegerField(null=True, blank=True)
    content_object = GenericForeignKey('content_type', 'object_id')
    
    # Request information
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    request_path = models.CharField(max_length=500, blank=True)
    request_method = models.CharField(max_length=10, blank=True)
    trace_id = models.CharField(max_length=100, blank=True)
    
    # Changes
    old_values = models.JSONField(default=dict, blank=True)
    new_values = models.JSONField(default=dict, blank=True)
    changes = models.JSONField(default=dict, blank=True)  # Diff between old and new
    
    # Additional information
    description = models.TextField(blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    severity = models.CharField(
        max_length=20,
        choices=[
            ('low', 'Low'),
            ('medium', 'Medium'),
            ('high', 'High'),
            ('critical', 'Critical'),
        ],
        default='medium'
    )
    is_success = models.BooleanField(default=True)
    error_message = models.TextField(blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['action', '-created_at']),
            models.Index(fields=['resource_type', '-created_at']),
            models.Index(fields=['trace_id']),
            models.Index(fields=['ip_address', '-created_at']),
        ]
        verbose_name = 'Audit Log'
        verbose_name_plural = 'Audit Logs'
    
    def __str__(self):
        user_str = self.user.username if self.user else 'Anonymous'
        return f"{user_str} - {self.get_action_display()} - {self.resource_type} - {self.created_at}"
    
    @classmethod
    def log_action(
        cls,
        user=None,
        action='other',
        resource_type='',
        resource_id=None,
        content_object=None,
        ip_address=None,
        user_agent='',
        request_path='',
        request_method='',
        trace_id='',
        old_values=None,
        new_values=None,
        description='',
        metadata=None,
        severity='medium',
        is_success=True,
        error_message=''
    ):
        """
        Create an audit log entry
        
        Args:
            user: User who performed the action
            action: Action type
            resource_type: Type of resource
            resource_id: ID of resource
            content_object: Related object
            ip_address: IP address of request
            user_agent: User agent string
            request_path: Request path
            request_method: HTTP method
            trace_id: Trace ID
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
        # Determine content type and object ID
        content_type = None
        object_id = None
        if content_object:
            content_type = ContentType.objects.get_for_model(content_object)
            object_id = content_object.pk
        elif resource_id:
            object_id = resource_id
        
        # Calculate changes
        changes = {}
        if old_values and new_values:
            for key in set(old_values.keys()) | set(new_values.keys()):
                old_val = old_values.get(key)
                new_val = new_values.get(key)
                if old_val != new_val:
                    changes[key] = {
                        'old': old_val,
                        'new': new_val
                    }
        
        return cls.objects.create(
            user=user,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            content_type=content_type,
            object_id=object_id,
            ip_address=ip_address,
            user_agent=user_agent,
            request_path=request_path,
            request_method=request_method,
            trace_id=trace_id,
            old_values=old_values or {},
            new_values=new_values or {},
            changes=changes,
            description=description,
            metadata=metadata or {},
            severity=severity,
            is_success=is_success,
            error_message=error_message
        )

