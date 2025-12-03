"""
Admin configuration for accounts app
"""
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth import get_user_model
from .models import Student, Faculty, OTPVerification, AllowedUSN

User = get_user_model()


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Custom User admin"""
    list_display = ['username', 'email', 'first_name', 'last_name', 'user_type', 'is_verified', 'date_joined']
    list_filter = ['user_type', 'is_verified', 'is_staff', 'is_active', 'date_joined']
    search_fields = ['username', 'email', 'first_name', 'last_name']
    ordering = ['-date_joined']
    
    fieldsets = BaseUserAdmin.fieldsets + (
        ('KSIT Nexus Info', {'fields': ('user_type', 'phone_number', 'is_verified')}),
    )


@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    """Student admin"""
    list_display = ['user', 'student_id', 'usn', 'year_of_study', 'branch', 'is_active', 'created_at']
    list_filter = ['year_of_study', 'branch', 'is_active', 'created_at']
    search_fields = ['user__username', 'user__email', 'student_id', 'usn', 'branch']
    ordering = ['-created_at']


@admin.register(AllowedUSN)
class AllowedUSNAdmin(admin.ModelAdmin):
    """Allowed USN admin"""
    list_display = ['usn', 'name', 'branch', 'created_at', 'updated_at']
    list_filter = ['branch', 'created_at']
    search_fields = ['usn', 'name', 'branch']
    ordering = ['usn']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(Faculty)
class FacultyAdmin(admin.ModelAdmin):
    """Faculty admin"""
    list_display = ['user', 'employee_id', 'designation', 'department', 'is_active', 'created_at']
    list_filter = ['designation', 'department', 'is_active', 'created_at']
    search_fields = ['user__username', 'user__email', 'employee_id', 'designation', 'department']
    ordering = ['-created_at']


@admin.register(OTPVerification)
class OTPVerificationAdmin(admin.ModelAdmin):
    """OTP Verification admin"""
    list_display = ['user', 'phone_number', 'is_verified', 'created_at', 'expires_at']
    list_filter = ['is_verified', 'created_at']
    search_fields = ['user__username', 'phone_number']
    ordering = ['-created_at']
    readonly_fields = ['created_at', 'expires_at']