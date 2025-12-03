"""
Serializers for notifications app
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Notification, NotificationPreference, NotificationTemplate, NotificationLog

User = get_user_model()


class NotificationSerializer(serializers.ModelSerializer):
    """Notification serializer"""
    user = serializers.StringRelatedField(read_only=True)
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    type = serializers.CharField(source='notification_type', read_only=True)
    category = serializers.CharField(source='notification_type', read_only=True)
    notification_type = serializers.CharField(read_only=True)
    read_at = serializers.DateTimeField(read_only=True)
    image_url = serializers.SerializerMethodField()
    action_url = serializers.SerializerMethodField()
    action_text = serializers.SerializerMethodField()
    
    class Meta:
        model = Notification
        fields = [
            'id', 'user', 'user_id', 'user_name', 'notification_type', 'type', 'category',
            'priority', 'title', 'message', 'data', 'is_read', 'is_sent', 'sent_at',
            'read_at', 'push_sent', 'email_sent', 'sms_sent', 'related_object_type',
            'related_object_id', 'created_at', 'updated_at', 'expires_at',
            'image_url', 'action_url', 'action_text'
        ]
        read_only_fields = [
            'id', 'user', 'user_id', 'user_name', 'is_sent', 'sent_at', 'read_at',
            'push_sent', 'email_sent', 'sms_sent', 'created_at', 'updated_at',
            'image_url', 'action_url', 'action_text'
        ]
    
    def get_image_url(self, obj):
        """Get image URL from data field"""
        return obj.data.get('image_url') if obj.data else None
    
    def get_action_url(self, obj):
        """Get action URL from data field"""
        return obj.data.get('action_url') if obj.data else None
    
    def get_action_text(self, obj):
        """Get action text from data field"""
        return obj.data.get('action_text') if obj.data else None


class NotificationPreferenceSerializer(serializers.ModelSerializer):
    """Notification preference serializer"""
    user = serializers.StringRelatedField(read_only=True)
    
    class Meta:
        model = NotificationPreference
        fields = [
            'id', 'user', 'push_enabled', 'email_enabled', 'sms_enabled',
            'in_app_enabled', 'complaint_updates', 'study_group_messages',
            'new_notices', 'reservation_reminders', 'feedback_requests',
            'general_announcements', 'quiet_hours_start', 'quiet_hours_end',
            'timezone', 'digest_frequency', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']


class NotificationTemplateSerializer(serializers.ModelSerializer):
    """Notification template serializer"""
    
    class Meta:
        model = NotificationTemplate
        fields = [
            'id', 'name', 'notification_type', 'title_template', 'message_template',
            'variables', 'is_active', 'priority', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class NotificationLogSerializer(serializers.ModelSerializer):
    """Notification log serializer"""
    notification = serializers.StringRelatedField(read_only=True)
    performed_by = serializers.StringRelatedField(read_only=True)
    
    class Meta:
        model = NotificationLog
        fields = [
            'id', 'notification', 'channel', 'status', 'error_message',
            'response_data', 'attempted_at'
        ]
        read_only_fields = ['id', 'attempted_at']


class NotificationCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating notifications"""
    
    class Meta:
        model = Notification
        fields = [
            'user', 'notification_type', 'priority', 'title', 'message',
            'data', 'related_object_type', 'related_object_id', 'expires_at'
        ]
    
    def create(self, validated_data):
        return Notification.objects.create(**validated_data)


class MarkAsReadSerializer(serializers.Serializer):
    """Serializer for marking notifications as read"""
    is_read = serializers.BooleanField(default=True)


class NotificationStatsSerializer(serializers.Serializer):
    """Notification statistics serializer"""
    total_notifications = serializers.IntegerField()
    unread_notifications = serializers.IntegerField()
    notifications_by_type = serializers.DictField()
    notifications_by_priority = serializers.DictField()
    recent_notifications = serializers.ListField()
