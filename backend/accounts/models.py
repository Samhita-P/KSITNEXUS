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
        validators=[RegexValidator(regex=r'^\+?1?\d{9,15}$', message="Phone number must be entered in the format: '+999999999'. Up to 15 digits allowed.")],
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
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='otp_verifications')
    phone_number = models.CharField(max_length=15)
    otp_code = models.CharField(max_length=6)
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