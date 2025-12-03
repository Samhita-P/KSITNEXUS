"""
Serializers for safety_wellbeing app
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    EmergencyAlert, EmergencyAcknowledgment, EmergencyContact,
    UserPersonalEmergencyContact,
    CounselingService, CounselingAppointment, AnonymousCheckIn, SafetyResource
)

User = get_user_model()


class EmergencyContactSerializer(serializers.ModelSerializer):
    """Serializer for EmergencyContact"""
    
    class Meta:
        model = EmergencyContact
        fields = [
            'id', 'name', 'contact_type', 'phone_number', 'alternate_phone',
            'email', 'location', 'description', 'is_active', 'priority',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class UserPersonalEmergencyContactSerializer(serializers.ModelSerializer):
    """Serializer for UserPersonalEmergencyContact"""
    
    class Meta:
        model = UserPersonalEmergencyContact
        fields = [
            'id', 'name', 'contact_type', 'phone_number', 'alternate_phone',
            'email', 'relationship', 'is_primary', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class UserPersonalEmergencyContactCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating personal emergency contacts"""
    
    class Meta:
        model = UserPersonalEmergencyContact
        fields = [
            'name', 'contact_type', 'phone_number', 'alternate_phone',
            'email', 'relationship', 'is_primary',
        ]


class EmergencyAcknowledgmentSerializer(serializers.ModelSerializer):
    """Serializer for EmergencyAcknowledgment"""
    user_name = serializers.SerializerMethodField()
    
    class Meta:
        model = EmergencyAcknowledgment
        fields = [
            'id', 'alert', 'user', 'user_name', 'acknowledged_at',
            'location_latitude', 'location_longitude', 'is_safe', 'notes',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['user', 'acknowledged_at', 'created_at', 'updated_at']
    
    def get_user_name(self, obj):
        if obj.user:
            return f"{obj.user.first_name} {obj.user.last_name}".strip() or obj.user.username
        return None


class EmergencyAlertSerializer(serializers.ModelSerializer):
    """Serializer for EmergencyAlert"""
    created_by_name = serializers.SerializerMethodField()
    responded_by_name = serializers.SerializerMethodField()
    acknowledgments_count = serializers.IntegerField(read_only=True)
    notify_contact_ids = serializers.PrimaryKeyRelatedField(
        many=True,
        queryset=UserPersonalEmergencyContact.objects.all(),
        source='notify_contacts',
        required=False,
        write_only=True
    )
    
    class Meta:
        model = EmergencyAlert
        fields = [
            'id', 'alert_id', 'alert_type', 'severity', 'status',
            'title', 'description', 'location', 'latitude', 'longitude',
            'created_by', 'created_by_name', 'responded_by', 'responded_by_name',
            'response_notes', 'resolved_at',
            'broadcast_to_all', 'target_departments', 'target_buildings',
            'notify_contact_ids', 'views_count', 'acknowledgments_count',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'created_by', 'responded_by', 'resolved_at', 'views_count',
            'acknowledgments_count', 'created_at', 'updated_at',
        ]
    
    def get_created_by_name(self, obj):
        if obj.created_by:
            return f"{obj.created_by.first_name} {obj.created_by.last_name}".strip() or obj.created_by.username
        return None
    
    def get_responded_by_name(self, obj):
        if obj.responded_by:
            return f"{obj.responded_by.first_name} {obj.responded_by.last_name}".strip() or obj.responded_by.username
        return None


class CounselingServiceSerializer(serializers.ModelSerializer):
    """Serializer for CounselingService"""
    appointments_count = serializers.SerializerMethodField()
    
    class Meta:
        model = CounselingService
        fields = [
            'id', 'name', 'service_type', 'description',
            'counselor_name', 'counselor_email', 'counselor_phone', 'location',
            'available_hours', 'is_active', 'is_anonymous',
            'appointments_count', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']
    
    def get_appointments_count(self, obj):
        return obj.appointments.filter(status__in=['scheduled', 'confirmed', 'in_progress']).count()


class CounselingAppointmentSerializer(serializers.ModelSerializer):
    """Serializer for CounselingAppointment"""
    service_name = serializers.SerializerMethodField()
    user_name = serializers.SerializerMethodField()
    
    class Meta:
        model = CounselingAppointment
        fields = [
            'id', 'appointment_id', 'service', 'service_name',
            'user', 'user_name', 'is_anonymous',
            'scheduled_at', 'duration_minutes', 'status', 'urgency',
            'contact_email', 'contact_phone', 'preferred_name',
            'reason', 'notes', 'counselor_notes',
            'completed_at', 'follow_up_required', 'follow_up_date',
            'rating', 'feedback',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'user', 'completed_at', 'created_at', 'updated_at',
        ]
    
    def get_service_name(self, obj):
        return obj.service.name
    
    def get_user_name(self, obj):
        if obj.user:
            return f"{obj.user.first_name} {obj.user.last_name}".strip() or obj.user.username
        return obj.preferred_name


class AnonymousCheckInSerializer(serializers.ModelSerializer):
    """Serializer for AnonymousCheckIn"""
    responded_by_name = serializers.SerializerMethodField()
    
    class Meta:
        model = AnonymousCheckIn
        fields = [
            'id', 'check_in_id', 'check_in_type', 'mood_level', 'message',
            'contact_email', 'contact_phone', 'allow_follow_up',
            'responded_by', 'responded_by_name', 'response_notes', 'response_sent_at',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'responded_by', 'response_sent_at', 'created_at', 'updated_at',
        ]
    
    def get_responded_by_name(self, obj):
        if obj.responded_by:
            return f"{obj.responded_by.first_name} {obj.responded_by.last_name}".strip() or obj.responded_by.username
        return None


class SafetyResourceSerializer(serializers.ModelSerializer):
    """Serializer for SafetyResource"""
    
    class Meta:
        model = SafetyResource
        fields = [
            'id', 'title', 'resource_type', 'description', 'content',
            'url', 'file', 'tags', 'is_featured', 'is_active',
            'views_count', 'created_at', 'updated_at',
        ]
        read_only_fields = ['views_count', 'created_at', 'updated_at']


