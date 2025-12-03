"""
Serializers for faculty_admin app
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    Case, CaseTag, CaseUpdate, Broadcast, BroadcastEngagement,
    PredictiveMetric, OperationalAlert
)

User = get_user_model()


class CaseTagSerializer(serializers.ModelSerializer):
    """Serializer for CaseTag"""
    
    class Meta:
        model = CaseTag
        fields = ['id', 'name', 'color', 'description', 'is_active', 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at']


class CaseUpdateSerializer(serializers.ModelSerializer):
    """Serializer for CaseUpdate"""
    updated_by_name = serializers.SerializerMethodField()
    
    class Meta:
        model = CaseUpdate
        fields = [
            'id', 'case', 'updated_by', 'updated_by_name', 'comment',
            'is_internal', 'status_change', 'priority_change',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['updated_by', 'created_at', 'updated_at']
    
    def get_updated_by_name(self, obj):
        if obj.updated_by:
            return f"{obj.updated_by.first_name} {obj.updated_by.last_name}".strip() or obj.updated_by.username
        return None


class CaseSerializer(serializers.ModelSerializer):
    """Serializer for Case"""
    assigned_to_name = serializers.SerializerMethodField()
    created_by_name = serializers.SerializerMethodField()
    updates = CaseUpdateSerializer(many=True, read_only=True)
    tags_display = serializers.SerializerMethodField()
    
    class Meta:
        model = Case
        fields = [
            'id', 'case_id', 'case_type', 'title', 'description',
            'assigned_to', 'assigned_to_name', 'created_by', 'created_by_name',
            'status', 'priority', 'priority_score',
            'sla_target_hours', 'sla_start_time', 'sla_breach_time', 'sla_status',
            'tags', 'tags_display', 'category', 'department',
            'resolved_at', 'resolution_notes', 'resolution_time_hours',
            'views_count', 'updates_count', 'response_time_minutes',
            'updates', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'created_at', 'updated_at', 'sla_breach_time', 'sla_status',
            'resolution_time_hours', 'views_count', 'updates_count',
        ]
    
    def get_assigned_to_name(self, obj):
        if obj.assigned_to:
            return f"{obj.assigned_to.first_name} {obj.assigned_to.last_name}".strip() or obj.assigned_to.username
        return None
    
    def get_created_by_name(self, obj):
        if obj.created_by:
            return f"{obj.created_by.first_name} {obj.created_by.last_name}".strip() or obj.created_by.username
        return None
    
    def get_tags_display(self, obj):
        return obj.tags if isinstance(obj.tags, list) else []


class BroadcastSerializer(serializers.ModelSerializer):
    """Serializer for Broadcast"""
    created_by_name = serializers.SerializerMethodField()
    target_users_count = serializers.SerializerMethodField()
    engagement_rate = serializers.SerializerMethodField()
    
    class Meta:
        model = Broadcast
        fields = [
            'id', 'title', 'content', 'broadcast_type', 'priority',
            'rich_content', 'attachments',
            'target_audience', 'target_users', 'target_departments', 'target_courses',
            'scheduled_at', 'expires_at', 'is_published', 'published_at',
            'created_by', 'created_by_name', 'views_count', 'engagement_count',
            'target_users_count', 'engagement_rate', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'created_by', 'published_at', 'views_count', 'engagement_count',
            'created_at', 'updated_at', 'target_users_count', 'engagement_rate', 'created_by_name',
        ]
    
    def validate_target_departments(self, value):
        """Ensure target_departments is a list"""
        if value is None:
            return []
        if isinstance(value, str):
            return [d.strip() for d in value.split(',') if d.strip()]
        if isinstance(value, list):
            return [str(d).strip() for d in value if d]
        return []
    
    def validate_target_courses(self, value):
        """Ensure target_courses is a list"""
        if value is None:
            return []
        if isinstance(value, str):
            return [c.strip() for c in value.split(',') if c.strip()]
        if isinstance(value, list):
            return [str(c).strip() for c in value if c]
        return []
    
    def validate_rich_content(self, value):
        """Ensure rich_content is a dict"""
        if value is None:
            return {}
        if isinstance(value, dict):
            return value
        return {}
    
    def validate_attachments(self, value):
        """Ensure attachments is a list"""
        if value is None:
            return []
        if isinstance(value, list):
            return value
        return []
    
    def get_created_by_name(self, obj):
        if obj.created_by:
            return f"{obj.created_by.first_name} {obj.created_by.last_name}".strip() or obj.created_by.username
        return None
    
    def get_target_users_count(self, obj):
        if obj.pk:  # Only count if object is saved
            try:
                return obj.target_users.count()
            except Exception:
                return 0
        return 0
    
    def get_engagement_rate(self, obj):
        if not obj.pk:  # New object, no engagement yet
            return 0.0
        try:
            target_count = obj.target_users.count()
            if target_count > 0 and obj.engagement_count > 0:
                return (obj.engagement_count / target_count) * 100
        except Exception:
            pass
        return 0.0
    
    def create(self, validated_data):
        # Extract ManyToMany field data before creating instance
        # Note: target_users is handled in the view's create method
        # This method just creates the instance
        broadcast = Broadcast.objects.create(**validated_data)
        return broadcast


class BroadcastEngagementSerializer(serializers.ModelSerializer):
    """Serializer for BroadcastEngagement"""
    
    class Meta:
        model = BroadcastEngagement
        fields = [
            'id', 'broadcast', 'user', 'viewed_at', 'clicked_at',
            'shared', 'created_at', 'updated_at',
        ]
        read_only_fields = ['user', 'created_at', 'updated_at']


class PredictiveMetricSerializer(serializers.ModelSerializer):
    """Serializer for PredictiveMetric"""
    
    class Meta:
        model = PredictiveMetric
        fields = [
            'id', 'metric_type', 'value', 'predicted_value', 'confidence',
            'period_start', 'period_end', 'metadata',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class OperationalAlertSerializer(serializers.ModelSerializer):
    """Serializer for OperationalAlert"""
    acknowledged_by_name = serializers.SerializerMethodField()
    
    class Meta:
        model = OperationalAlert
        fields = [
            'id', 'alert_type', 'severity', 'title', 'message',
            'related_metric', 'related_case',
            'is_acknowledged', 'acknowledged_by', 'acknowledged_by_name', 'acknowledged_at',
            'is_resolved', 'resolved_at', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'acknowledged_at', 'resolved_at', 'created_at', 'updated_at',
        ]
    
    def get_acknowledged_by_name(self, obj):
        if obj.acknowledged_by:
            return f"{obj.acknowledged_by.first_name} {obj.acknowledged_by.last_name}".strip() or obj.acknowledged_by.username
        return None









