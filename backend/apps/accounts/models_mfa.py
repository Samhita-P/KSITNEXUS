"""
Enhanced MFA models
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from .models import User

User = get_user_model()


class MFAMethod(models.Model):
    """MFA Method model for different authentication methods"""
    
    METHOD_CHOICES = [
        ('totp', 'TOTP (Authenticator App)'),
        ('sms', 'SMS'),
        ('email', 'Email'),
        ('backup', 'Backup Code'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='mfa_methods')
    method_type = models.CharField(max_length=20, choices=METHOD_CHOICES)
    is_enabled = models.BooleanField(default=False)
    is_primary = models.BooleanField(default=False)
    phone_number = models.CharField(max_length=15, blank=True, null=True)  # For SMS
    email = models.EmailField(blank=True, null=True)  # For email (usually same as user email)
    secret_key = models.CharField(max_length=32, blank=True, null=True)  # For TOTP
    backup_codes = models.JSONField(default=list, blank=True)  # For backup codes
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_used_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        unique_together = ['user', 'method_type']
        ordering = ['-is_primary', '-created_at']
    
    def __str__(self):
        return f"{self.user.username} - {self.get_method_type_display()}"


class TrustedDevice(models.Model):
    """Trusted device model for remembering devices"""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='trusted_devices')
    device_id = models.CharField(max_length=255, unique=True)
    device_name = models.CharField(max_length=255)
    device_type = models.CharField(max_length=50)  # mobile, tablet, desktop, web
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    is_trusted = models.BooleanField(default=False)
    trusted_until = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_used_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['user', 'device_id']
        ordering = ['-last_used_at']
    
    def __str__(self):
        return f"{self.user.username} - {self.device_name} ({self.device_type})"
    
    def is_expired(self) -> bool:
        """Check if trusted device is expired"""
        if self.trusted_until:
            return timezone.now() > self.trusted_until
        return False
    
    def is_valid(self) -> bool:
        """Check if trusted device is valid"""
        return self.is_trusted and not self.is_expired()


class MFAAttempt(models.Model):
    """MFA attempt tracking for rate limiting and security"""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='mfa_attempts')
    method_type = models.CharField(max_length=20)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    is_successful = models.BooleanField(default=False)
    failure_reason = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['ip_address', '-created_at']),
            models.Index(fields=['method_type', '-created_at']),
        ]
    
    def __str__(self):
        status = 'Success' if self.is_successful else 'Failed'
        return f"{self.user.username} - {self.method_type} - {status} - {self.created_at}"


class MFARecoveryCode(models.Model):
    """MFA recovery codes for account recovery"""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='mfa_recovery_codes')
    code = models.CharField(max_length=32, unique=True)
    is_used = models.BooleanField(default=False)
    used_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'is_used']),
            models.Index(fields=['code']),
        ]
    
    def __str__(self):
        status = 'Used' if self.is_used else 'Active'
        return f"{self.user.username} - {status} - {self.code[:8]}..."
    
    def is_expired(self) -> bool:
        """Check if recovery code is expired"""
        if self.expires_at:
            return timezone.now() > self.expires_at
        return False
    
    def is_valid(self) -> bool:
        """Check if recovery code is valid"""
        return not self.is_used and not self.is_expired()

