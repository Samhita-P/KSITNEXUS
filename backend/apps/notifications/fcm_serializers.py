"""
FCM Serializers for push notifications
"""

from rest_framework import serializers
from .fcm_models import FCMToken, PushNotification, FCMNotificationTemplate


class FCMTokenSerializer(serializers.ModelSerializer):
    """Serializer for FCM Token"""
    
    class Meta:
        model = FCMToken
        fields = [
            'id', 'token', 'platform', 'is_active', 
            'created_at', 'updated_at', 'last_used'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'last_used']


class PushNotificationSerializer(serializers.ModelSerializer):
    """Serializer for Push Notification"""
    
    target_user_count = serializers.SerializerMethodField()
    fcm_token_count = serializers.SerializerMethodField()
    
    class Meta:
        model = PushNotification
        fields = [
            'id', 'title', 'body', 'notification_type', 'priority',
            'target_users', 'target_topic', 'fcm_tokens', 'data',
            'status', 'scheduled_at', 'sent_at', 'created_at', 'updated_at',
            'error_message', 'retry_count', 'max_retries',
            'target_user_count', 'fcm_token_count'
        ]
        read_only_fields = [
            'id', 'fcm_tokens', 'status', 'sent_at', 'created_at', 
            'updated_at', 'error_message', 'retry_count'
        ]
    
    def get_target_user_count(self, obj):
        return obj.target_users.count()
    
    def get_fcm_token_count(self, obj):
        return obj.fcm_tokens.count()


class NotificationTemplateSerializer(serializers.ModelSerializer):
    """Serializer for Notification Template"""
    
    class Meta:
        model = FCMNotificationTemplate
        fields = [
            'id', 'name', 'title_template', 'body_template',
            'notification_type', 'priority', 'variables',
            'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class SendNotificationSerializer(serializers.Serializer):
    """Serializer for sending notifications"""
    
    title = serializers.CharField(max_length=255)
    body = serializers.CharField()
    notification_type = serializers.ChoiceField(
        choices=PushNotification.NOTIFICATION_TYPES,
        default='info'
    )
    priority = serializers.ChoiceField(
        choices=PushNotification.PRIORITY_CHOICES,
        default='normal'
    )
    target_user_ids = serializers.ListField(
        child=serializers.IntegerField(),
        required=False,
        allow_empty=True
    )
    target_topic = serializers.CharField(
        max_length=100,
        required=False,
        allow_blank=True
    )
    data = serializers.JSONField(required=False, default=dict)
    
    def validate(self, data):
        """Validate notification data"""
        if not data.get('target_user_ids') and not data.get('target_topic'):
            raise serializers.ValidationError(
                'Either target_user_ids or target_topic must be provided'
            )
        return data


class SendTopicNotificationSerializer(serializers.Serializer):
    """Serializer for sending topic notifications"""
    
    topic = serializers.CharField(max_length=100)
    title = serializers.CharField(max_length=255)
    body = serializers.CharField()
    data = serializers.JSONField(required=False, default=dict)


class SubscribeTopicSerializer(serializers.Serializer):
    """Serializer for topic subscription"""
    
    topic = serializers.CharField(max_length=100)


class UnsubscribeTopicSerializer(serializers.Serializer):
    """Serializer for topic unsubscription"""
    
    topic = serializers.CharField(max_length=100)


class SendTemplateNotificationSerializer(serializers.Serializer):
    """Serializer for sending template notifications"""
    
    template_id = serializers.IntegerField()
    context = serializers.JSONField(required=False, default=dict)
    target_user_ids = serializers.ListField(
        child=serializers.IntegerField(),
        required=False,
        allow_empty=True
    )
    target_topic = serializers.CharField(
        max_length=100,
        required=False,
        allow_blank=True
    )
    
    def validate(self, data):
        """Validate template notification data"""
        if not data.get('target_user_ids') and not data.get('target_topic'):
            raise serializers.ValidationError(
                'Either target_user_ids or target_topic must be provided'
            )
        return data


class NotificationStatsSerializer(serializers.Serializer):
    """Serializer for notification statistics"""
    
    total_sent = serializers.IntegerField()
    total_failed = serializers.IntegerField()
    total_pending = serializers.IntegerField()
    active_tokens = serializers.IntegerField()
    success_rate = serializers.SerializerMethodField()
    
    def get_success_rate(self, obj):
        total = obj['total_sent'] + obj['total_failed']
        if total == 0:
            return 0.0
        return round((obj['total_sent'] / total) * 100, 2)
