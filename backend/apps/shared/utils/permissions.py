"""
Permission checking utilities
"""
from typing import List, Optional
from django.contrib.auth import get_user_model
from apps.shared.models.rbac import Role, UserRole, Permission, ResourcePermission

User = get_user_model()


def user_has_permission(user: User, permission_codename: str) -> bool:
    """
    Check if user has a specific permission
    
    Args:
        user: User instance
        permission_codename: Permission codename
        
    Returns:
        True if user has permission, False otherwise
    """
    if not user or not user.is_authenticated:
        return False
    
    # Check if user is superuser
    if user.is_superuser:
        return True
    
    # Check user roles
    user_roles = UserRole.objects.filter(
        user=user,
        is_active=True,
        role__is_active=True
    ).select_related('role').prefetch_related('role__permissions')
    
    for user_role in user_roles:
        if user_role.is_valid() and user_role.role.has_permission(permission_codename):
            return True
    
    # Check direct permissions
    direct_permissions = ResourcePermission.objects.filter(
        user=user,
        permission__codename=permission_codename,
        is_active=True
    )
    
    for perm in direct_permissions:
        if perm.is_valid():
            return True
    
    return False


def user_has_permissions(user: User, permission_codenames: List[str]) -> bool:
    """
    Check if user has all specified permissions
    
    Args:
        user: User instance
        permission_codenames: List of permission codenames
        
    Returns:
        True if user has all permissions, False otherwise
    """
    if not user or not user.is_authenticated:
        return False
    
    # Check if user is superuser
    if user.is_superuser:
        return True
    
    for codename in permission_codenames:
        if not user_has_permission(user, codename):
            return False
    
    return True


def user_has_role(user: User, role_codename: str) -> bool:
    """
    Check if user has a specific role
    
    Args:
        user: User instance
        role_codename: Role codename
        
    Returns:
        True if user has role, False otherwise
    """
    if not user or not user.is_authenticated:
        return False
    
    # Check if user is superuser
    if user.is_superuser:
        return True
    
    return UserRole.objects.filter(
        user=user,
        role__codename=role_codename,
        is_active=True,
        role__is_active=True
    ).exists()


def get_user_permissions(user: User) -> List[str]:
    """
    Get all permissions for a user
    
    Args:
        user: User instance
        
    Returns:
        List of permission codenames
    """
    if not user or not user.is_authenticated:
        return []
    
    # Superuser has all permissions
    if user.is_superuser:
        return Permission.objects.filter(is_active=True).values_list('codename', flat=True)
    
    permissions = set()
    
    # Get permissions from roles
    user_roles = UserRole.objects.filter(
        user=user,
        is_active=True,
        role__is_active=True
    ).select_related('role').prefetch_related('role__permissions')
    
    for user_role in user_roles:
        if user_role.is_valid():
            role_permissions = user_role.role.permissions.filter(is_active=True)
            permissions.update(role_permissions.values_list('codename', flat=True))
    
    # Get direct permissions
    direct_permissions = ResourcePermission.objects.filter(
        user=user,
        is_active=True
    ).select_related('permission')
    
    for perm in direct_permissions:
        if perm.is_valid():
            permissions.add(perm.permission.codename)
    
    return list(permissions)


def get_user_roles(user: User) -> List[str]:
    """
    Get all roles for a user
    
    Args:
        user: User instance
        
    Returns:
        List of role codenames
    """
    if not user or not user.is_authenticated:
        return []
    
    # Superuser has all roles
    if user.is_superuser:
        return Role.objects.filter(is_active=True).values_list('codename', flat=True)
    
    user_roles = UserRole.objects.filter(
        user=user,
        is_active=True,
        role__is_active=True
    ).select_related('role')
    
    return [ur.role.codename for ur in user_roles if ur.is_valid()]

