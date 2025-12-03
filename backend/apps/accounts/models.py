"""
User models for KSIT Nexus
"""
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.validators import RegexValidator
from django.utils import timezone


class User(AbstractUser):
    """Custom User model extending Django's AbstractUser"""
    
    USER_TYPE_CHOICES = [
        ('student', 'Student'),
        ('faculty', 'Faculty'),
        ('admin', 'Admin'),
    ]
    
    user_type = models.CharField(max_length=10, choices=USER_TYPE_CHOICES, default='student')
    phone_number = models.CharField(
        max_length=15,
        validators=[RegexValidator(regex=r'^\+?\d{10,15}$', message="Phone number must be 10-15 digits, optionally starting with +.")],
        blank=True,
        null=True
    )
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.username} ({self.get_user_type_display()})"


class Student(models.Model):
    """Student profile model"""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='student_profile')
    student_id = models.CharField(max_length=20, unique=True)
    usn = models.CharField(max_length=20, blank=True, null=True, help_text="University Seat Number")
    year_of_study = models.IntegerField(choices=[(i, f'Year {i}') for i in range(1, 6)])
    branch = models.CharField(max_length=100)
    section = models.CharField(max_length=10, blank=True, null=True)
    profile_picture = models.ImageField(upload_to='student_profiles/', blank=True, null=True)
    bio = models.TextField(blank=True, null=True)
    interests = models.JSONField(default=list, blank=True)  # List of interest tags
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.get_full_name()} - {self.student_id}"


class Faculty(models.Model):
    """Faculty profile model"""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='faculty_profile')
    employee_id = models.CharField(max_length=20, unique=True)
    designation = models.CharField(max_length=100)
    department = models.CharField(max_length=100)
    subjects_taught = models.JSONField(default=list, blank=True)  # List of subjects
    research_areas = models.JSONField(default=list, blank=True)  # List of research areas
    profile_picture = models.ImageField(upload_to='faculty_profiles/', blank=True, null=True)
    bio = models.TextField(blank=True, null=True)
    is_mentor_available = models.BooleanField(default=True)
    office_hours = models.CharField(max_length=200, blank=True, null=True)
    office_location = models.CharField(max_length=100, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.get_full_name()} - {self.employee_id}"


class OTPVerification(models.Model):
    """OTP verification model for phone/email verification"""
    
    PURPOSE_CHOICES = [
        ('registration', 'Registration'),
        ('password_reset', 'Password Reset'),
        ('login', 'Login'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='otp_verifications')
    phone_number = models.CharField(max_length=15)
    otp_code = models.CharField(max_length=6)
    purpose = models.CharField(max_length=20, choices=PURPOSE_CHOICES, default='registration')
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"OTP for {self.phone_number} - {self.user.username}"
    
    def is_expired(self):
        return timezone.now() > self.expires_at
    
    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + timezone.timedelta(minutes=10)
        super().save(*args, **kwargs)


class TwoFactorAuth(models.Model):
    """Two-Factor Authentication model"""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='two_factor_auth')
    is_enabled = models.BooleanField(default=False)
    secret_key = models.CharField(max_length=32, blank=True, null=True)
    backup_codes = models.JSONField(default=list, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"2FA for {self.user.username} - {'Enabled' if self.is_enabled else 'Disabled'}"


class DeviceSession(models.Model):
    """Device session tracking for security"""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='device_sessions')
    device_id = models.CharField(max_length=255, unique=True)
    device_name = models.CharField(max_length=255)
    device_type = models.CharField(max_length=50)  # mobile, tablet, desktop, web
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField()
    is_active = models.BooleanField(default=True)
    last_activity = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-last_activity']
    
    def __str__(self):
        return f"{self.user.username} - {self.device_name} ({self.device_type})"
    
    def is_expired(self, hours=24):
        """Check if session is expired (default 24 hours)"""
        from django.utils import timezone
        return timezone.now() > self.last_activity + timezone.timedelta(hours=hours)


class AllowedUSN(models.Model):
    """Model to store allowed 7th semester student USNs"""
    
    usn = models.CharField(max_length=20, unique=True, help_text="University Seat Number")
    name = models.CharField(max_length=200, blank=True, null=True, help_text="Student Name")
    branch = models.CharField(max_length=100, blank=True, null=True, help_text="Branch/Department")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Allowed USN"
        verbose_name_plural = "Allowed USNs"
        ordering = ['usn']
        indexes = [
            models.Index(fields=['usn']),
        ]
    
    def __str__(self):
        name_str = f" - {self.name}" if self.name else ""
        return f"{self.usn}{name_str} - {self.branch or 'N/A'}"