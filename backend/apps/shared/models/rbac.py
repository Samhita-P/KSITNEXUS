"""
Role-Based Access Control (RBAC) models
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey
from .base import TimestampedModel

User = get_user_model()


class Permission(TimestampedModel):
    """Permission model for RBAC"""
    
    name = models.CharField(max_length=100, unique=True)
    codename = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    resource = models.CharField(max_length=100, blank=True)  # e.g., 'notice', 'complaint'
    action = models.CharField(max_length=50, blank=True)  # e.g., 'create', 'read', 'update', 'delete'
    is_active = models.BooleanField(default=True)
    
    class Meta:
        ordering = ['resource', 'action']
        verbose_name = 'Permission'
        verbose_name_plural = 'Permissions'
    
    def __str__(self):
        return f"{self.name} ({self.codename})"


class Role(TimestampedModel):
    """Role model for RBAC"""
    
    name = models.CharField(max_length=100, unique=True)
    codename = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    permissions = models.ManyToManyField(Permission, related_name='roles', blank=True)
    is_active = models.BooleanField(default=True)
    is_system = models.BooleanField(default=False)  # System roles cannot be deleted
    
    class Meta:
        ordering = ['name']
        verbose_name = 'Role'
        verbose_name_plural = 'Roles'
    
    def __str__(self):
        return self.name
    
    def has_permission(self, permission_codename: str) -> bool:
        """Check if role has a specific permission"""
        return self.permissions.filter(codename=permission_codename, is_active=True).exists()
    
    def has_permissions(self, permission_codenames: list) -> bool:
        """Check if role has all specified permissions"""
        return self.permissions.filter(
            codename__in=permission_codenames,
            is_active=True
        ).count() == len(permission_codenames)


class UserRole(TimestampedModel):
    """User-Role relationship model"""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='user_roles')
    role = models.ForeignKey(Role, on_delete=models.CASCADE, related_name='user_roles')
    is_active = models.BooleanField(default=True)
    assigned_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_roles'
    )
    assigned_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        unique_together = ['user', 'role']
        ordering = ['-assigned_at']
        verbose_name = 'User Role'
        verbose_name_plural = 'User Roles'
    
    def __str__(self):
        return f"{self.user.username} - {self.role.name}"
    
    def is_expired(self) -> bool:
        """Check if role assignment is expired"""
        if self.expires_at:
            return timezone.now() > self.expires_at
        return False
    
    def is_valid(self) -> bool:
        """Check if role assignment is valid"""
        return self.is_active and not self.is_expired()


class ResourcePermission(TimestampedModel):
    """Resource-specific permission model"""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='resource_permissions')
    permission = models.ForeignKey(Permission, on_delete=models.CASCADE, related_name='resource_permissions')
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.PositiveIntegerField()
    content_object = GenericForeignKey('content_type', 'object_id')
    is_active = models.BooleanField(default=True)
    granted_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='granted_permissions'
    )
    granted_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        unique_together = ['user', 'permission', 'content_type', 'object_id']
        ordering = ['-granted_at']
        verbose_name = 'Resource Permission'
        verbose_name_plural = 'Resource Permissions'
    
    def __str__(self):
        return f"{self.user.username} - {self.permission.name} - {self.content_object}"
    
    def is_expired(self) -> bool:
        """Check if permission is expired"""
        if self.expires_at:
            return timezone.now() > self.expires_at
        return False
    
    def is_valid(self) -> bool:
        """Check if permission is valid"""
        return self.is_active and not self.is_expired()

