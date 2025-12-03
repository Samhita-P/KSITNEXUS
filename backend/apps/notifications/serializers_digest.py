"""
Serializers for notification digests, tiers, and summaries
"""
from rest_framework import serializers
from .models_digest import NotificationDigest, NotificationTier, NotificationSummary, NotificationPriorityRule
from .models import Notification


class NotificationDigestSerializer(serializers.ModelSerializer):
    """Notification digest serializer"""
    notifications = serializers.SerializerMethodField()
    user = serializers.StringRelatedField(read_only=True)
    
    class Meta:
        model = NotificationDigest
        fields = [
            'id', 'user', 'frequency', 'period_start', 'period_end',
            'title', 'summary', 'notifications', 'is_sent', 'sent_at',
            'is_read', 'read_at', 'notification_count', 'unread_count',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'user', 'is_sent', 'sent_at', 'read_at',
            'notification_count', 'unread_count', 'created_at', 'updated_at'
        ]
    
    def get_notifications(self, obj):
        """Get notifications in digest"""
        # Import here to avoid circular import
        from .serializers import NotificationSerializer
        notifications = obj.notifications.all()
        serializer = NotificationSerializer(notifications, many=True, context=self.context)
        return serializer.data


class NotificationTierSerializer(serializers.ModelSerializer):
    """Notification tier serializer"""
    user = serializers.StringRelatedField(read_only=True)
    tier_display = serializers.CharField(source='get_tier_display', read_only=True)
    
    class Meta:
        model = NotificationTier
        fields = [
            'id', 'user', 'tier', 'tier_display', 'notification_types',
            'push_enabled', 'email_enabled', 'sms_enabled', 'in_app_enabled',
            'escalation_enabled', 'escalation_delay_minutes', 'escalate_to_tier',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']


class NotificationSummarySerializer(serializers.ModelSerializer):
    """Notification summary serializer"""
    notification = serializers.StringRelatedField(read_only=True)
    notification_id = serializers.IntegerField(source='notification.id', read_only=True)
    
    class Meta:
        model = NotificationSummary
        fields = [
            'id', 'notification', 'notification_id', 'summary_text', 'summary_type',
            'model_used', 'confidence_score', 'word_count', 'key_points',
            'generated_at', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'notification', 'notification_id', 'model_used',
            'confidence_score', 'word_count', 'generated_at', 'created_at', 'updated_at'
        ]


class NotificationPriorityRuleSerializer(serializers.ModelSerializer):
    """Notification priority rule serializer"""
    user = serializers.StringRelatedField(read_only=True)
    priority_display = serializers.CharField(source='get_priority_display', read_only=True)
    
    class Meta:
        model = NotificationPriorityRule
        fields = [
            'id', 'user', 'is_global', 'notification_type', 'keyword', 'sender',
            'priority', 'priority_display', 'auto_escalate', 'escalation_minutes',
            'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']


class CreateNotificationTierSerializer(serializers.Serializer):
    """Serializer for creating notification tier"""
    tier = serializers.ChoiceField(choices=[('essential', 'Essential'), ('important', 'Important'), ('optional', 'Optional')])
    notification_types = serializers.ListField(
        child=serializers.ChoiceField(choices=[
            ('complaint', 'Complaint Update'),
            ('study_group', 'Study Group'),
            ('notice', 'Notice'),
            ('reservation', 'Reservation'),
            ('feedback', 'Feedback'),
            ('announcement', 'Announcement'),
            ('general', 'General'),
        ])
    )
    push_enabled = serializers.BooleanField(default=True)
    email_enabled = serializers.BooleanField(default=True)
    sms_enabled = serializers.BooleanField(default=False)
    in_app_enabled = serializers.BooleanField(default=True)
    escalation_enabled = serializers.BooleanField(default=False)
    escalation_delay_minutes = serializers.IntegerField(default=60, required=False)
    escalate_to_tier = serializers.ChoiceField(
        choices=[('essential', 'Essential'), ('important', 'Important'), ('optional', 'Optional')],
        required=False,
        allow_null=True
    )


class CreatePriorityRuleSerializer(serializers.Serializer):
    """Serializer for creating priority rule"""
    notification_type = serializers.ChoiceField(
        choices=Notification.NOTIFICATION_TYPES,
        required=False,
        allow_null=True
    )
    keyword = serializers.CharField(max_length=100, required=False, allow_null=True)
    sender = serializers.CharField(max_length=100, required=False, allow_null=True)
    priority = serializers.ChoiceField(choices=Notification.PRIORITY_CHOICES)
    auto_escalate = serializers.BooleanField(default=False)
    escalation_minutes = serializers.IntegerField(default=30, required=False)
    is_global = serializers.BooleanField(default=False)

