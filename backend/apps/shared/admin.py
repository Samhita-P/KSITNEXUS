"""
Admin interface for shared models
"""
from django.contrib import admin
from django.utils.html import format_html
from .models.rbac import Permission, Role, UserRole, ResourcePermission
from .models.audit import AuditLog


@admin.register(Permission)
class PermissionAdmin(admin.ModelAdmin):
    """Admin interface for Permission model"""
    list_display = ['name', 'codename', 'resource', 'action', 'is_active', 'created_at']
    list_filter = ['is_active', 'resource', 'action']
    search_fields = ['name', 'codename', 'description']
    readonly_fields = ['created_at', 'updated_at']
    ordering = ['resource', 'action']


@admin.register(Role)
class RoleAdmin(admin.ModelAdmin):
    """Admin interface for Role model"""
    list_display = ['name', 'codename', 'permission_count', 'is_active', 'is_system', 'created_at']
    list_filter = ['is_active', 'is_system']
    search_fields = ['name', 'codename', 'description']
    filter_horizontal = ['permissions']
    readonly_fields = ['created_at', 'updated_at', 'is_system']
    ordering = ['name']
    
    def permission_count(self, obj):
        """Count of permissions for this role"""
        return obj.permissions.count()
    permission_count.short_description = 'Permissions'


@admin.register(UserRole)
class UserRoleAdmin(admin.ModelAdmin):
    """Admin interface for UserRole model"""
    list_display = ['user', 'role', 'is_active', 'assigned_by', 'assigned_at', 'expires_at', 'is_expired']
    list_filter = ['is_active', 'role', 'assigned_at']
    search_fields = ['user__username', 'user__email', 'role__name']
    readonly_fields = ['assigned_at', 'created_at', 'updated_at']
    ordering = ['-assigned_at']
    
    def is_expired(self, obj):
        """Check if role assignment is expired"""
        if obj.is_expired():
            return format_html('<span style="color: red;">Yes</span>')
        return format_html('<span style="color: green;">No</span>')
    is_expired.short_description = 'Expired'
    is_expired.boolean = True


@admin.register(ResourcePermission)
class ResourcePermissionAdmin(admin.ModelAdmin):
    """Admin interface for ResourcePermission model"""
    list_display = ['user', 'permission', 'content_type', 'object_id', 'is_active', 'granted_by', 'granted_at', 'expires_at']
    list_filter = ['is_active', 'permission', 'content_type', 'granted_at']
    search_fields = ['user__username', 'user__email', 'permission__name']
    readonly_fields = ['granted_at', 'created_at', 'updated_at']
    ordering = ['-granted_at']


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    """Admin interface for AuditLog model"""
    list_display = ['user', 'action', 'resource_type', 'resource_id', 'severity', 'is_success', 'ip_address', 'created_at']
    list_filter = ['action', 'severity', 'is_success', 'resource_type', 'created_at']
    search_fields = ['user__username', 'user__email', 'resource_type', 'description', 'trace_id', 'ip_address']
    readonly_fields = ['created_at', 'updated_at', 'trace_id']
    ordering = ['-created_at']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('user', 'action', 'resource_type', 'resource_id', 'content_type', 'object_id')
        }),
        ('Request Information', {
            'fields': ('ip_address', 'user_agent', 'request_path', 'request_method', 'trace_id')
        }),
        ('Changes', {
            'fields': ('old_values', 'new_values', 'changes')
        }),
        ('Additional Information', {
            'fields': ('description', 'metadata', 'severity', 'is_success', 'error_message')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )
    
    def has_add_permission(self, request):
        """Disable adding audit logs manually"""
        return False
    
    def has_change_permission(self, request, obj=None):
        """Disable editing audit logs"""
        return False
    
    def has_delete_permission(self, request, obj=None):
        """Allow deleting audit logs only for superusers"""
        return request.user.is_superuser

