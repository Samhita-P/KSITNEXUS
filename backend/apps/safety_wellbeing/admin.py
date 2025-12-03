from django.contrib import admin
from .models import (
    EmergencyAlert, EmergencyAcknowledgment, EmergencyContact,
    UserPersonalEmergencyContact,
    CounselingService, CounselingAppointment, AnonymousCheckIn, SafetyResource
)


@admin.register(EmergencyAlert)
class EmergencyAlertAdmin(admin.ModelAdmin):
    list_display = ['alert_id', 'title', 'alert_type', 'severity', 'status', 'created_by', 'created_at']
    list_filter = ['alert_type', 'severity', 'status', 'created_at']
    search_fields = ['alert_id', 'title', 'description']
    ordering = ['-created_at']
    readonly_fields = ['alert_id', 'views_count', 'acknowledgments_count']


@admin.register(EmergencyAcknowledgment)
class EmergencyAcknowledgmentAdmin(admin.ModelAdmin):
    list_display = ['alert', 'user', 'is_safe', 'acknowledged_at']
    list_filter = ['is_safe', 'acknowledged_at']
    search_fields = ['alert__alert_id', 'user__username']


@admin.register(EmergencyContact)
class EmergencyContactAdmin(admin.ModelAdmin):
    list_display = ['name', 'contact_type', 'phone_number', 'is_active', 'priority']
    list_filter = ['contact_type', 'is_active']
    search_fields = ['name', 'phone_number']


@admin.register(UserPersonalEmergencyContact)
class UserPersonalEmergencyContactAdmin(admin.ModelAdmin):
    list_display = ['user', 'name', 'contact_type', 'phone_number', 'is_primary', 'created_at']
    list_filter = ['contact_type', 'is_primary', 'created_at']
    search_fields = ['user__username', 'name', 'phone_number', 'email']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(CounselingService)
class CounselingServiceAdmin(admin.ModelAdmin):
    list_display = ['name', 'service_type', 'counselor_name', 'is_active', 'is_anonymous']
    list_filter = ['service_type', 'is_active', 'is_anonymous']
    search_fields = ['name', 'counselor_name']


@admin.register(CounselingAppointment)
class CounselingAppointmentAdmin(admin.ModelAdmin):
    list_display = ['appointment_id', 'service', 'user', 'scheduled_at', 'status', 'urgency']
    list_filter = ['status', 'urgency', 'service', 'scheduled_at']
    search_fields = ['appointment_id', 'user__username', 'contact_email']
    ordering = ['-scheduled_at']
    readonly_fields = ['appointment_id']


@admin.register(AnonymousCheckIn)
class AnonymousCheckInAdmin(admin.ModelAdmin):
    list_display = ['check_in_id', 'check_in_type', 'mood_level', 'responded_by', 'created_at']
    list_filter = ['check_in_type', 'mood_level', 'created_at']
    search_fields = ['check_in_id', 'contact_email']
    ordering = ['-created_at']
    readonly_fields = ['check_in_id']


@admin.register(SafetyResource)
class SafetyResourceAdmin(admin.ModelAdmin):
    list_display = ['title', 'resource_type', 'is_featured', 'is_active', 'views_count']
    list_filter = ['resource_type', 'is_featured', 'is_active']
    search_fields = ['title', 'description']
    ordering = ['-is_featured', 'title']


