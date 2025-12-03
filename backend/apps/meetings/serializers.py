from rest_framework import serializers
from .models import Meeting
from django.contrib.auth import get_user_model

User = get_user_model()

class MeetingSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True, allow_null=True)
    created_by_email = serializers.CharField(source='created_by.email', read_only=True, allow_null=True)
    status_display_name = serializers.CharField(source='get_status_display_name', read_only=True)
    type_display_name = serializers.CharField(source='get_type_display_name', read_only=True)
    audience_display_name = serializers.CharField(source='get_audience_display_name', read_only=True)
    is_upcoming = serializers.BooleanField(read_only=True)
    is_past = serializers.BooleanField(read_only=True)
    is_today = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = Meeting
        fields = [
            'id', 'title', 'description', 'type', 'location', 'scheduled_date',
            'duration', 'audience', 'notes', 'status', 'created_by', 'created_at',
            'updated_at', 'created_by_name', 'created_by_email', 'status_display_name',
            'type_display_name', 'audience_display_name', 'is_upcoming', 'is_past', 'is_today'
        ]
        read_only_fields = ['id', 'created_by', 'created_at', 'updated_at']
    
    def to_representation(self, instance):
        data = super().to_representation(instance)
        # Ensure created_by is never null
        if data.get('created_by') is None:
            data['created_by'] = 0  # Default value for null created_by
        return data

class MeetingCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Meeting
        fields = [
            'title', 'description', 'type', 'location', 'scheduled_date',
            'duration', 'audience', 'notes'
        ]
    
    def validate_scheduled_date(self, value):
        from django.utils import timezone
        if value < timezone.now():
            raise serializers.ValidationError("Meeting cannot be scheduled in the past.")
        return value

class MeetingUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Meeting
        fields = [
            'title', 'description', 'type', 'location', 'scheduled_date',
            'duration', 'audience', 'notes', 'status'
        ]
        extra_kwargs = {
            'title': {'required': False},
            'description': {'required': False},
            'type': {'required': False},
            'location': {'required': False},
            'scheduled_date': {'required': False},
            'duration': {'required': False},
            'audience': {'required': False},
            'notes': {'required': False},
            'status': {'required': False},
        }
    
    def validate_scheduled_date(self, value):
        from django.utils import timezone
        if value and value < timezone.now():
            raise serializers.ValidationError("Meeting cannot be scheduled in the past.")
        return value
