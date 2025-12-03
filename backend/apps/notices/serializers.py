"""
Serializers for notices app
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Notice, Announcement, NoticeView

User = get_user_model()


class NoticeSerializer(serializers.ModelSerializer):
    """Notice serializer"""
    author = serializers.StringRelatedField(read_only=True)
    approved_by = serializers.StringRelatedField(read_only=True)
    
    class Meta:
        model = Notice
        fields = [
            'id', 'title', 'content', 'summary', 'priority', 'status',
            'visibility', 'target_branches', 'target_years', 'author',
            'approved_by', 'attachment', 'attachment_name', 'publish_at',
            'expires_at', 'view_count', 'is_pinned', 'tags', 'created_at',
            'updated_at', 'published_at'
        ]
        read_only_fields = [
            'id', 'author', 'approved_by', 'view_count', 'created_at',
            'updated_at', 'published_at'
        ]


class NoticeCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating notices"""
    
    class Meta:
        model = Notice
        fields = [
            'title', 'content', 'summary', 'priority', 'visibility',
            'target_branches', 'target_years', 'attachment', 'expires_at',
            'is_pinned', 'tags', 'status'
        ]
    
    def create(self, validated_data):
        validated_data['author'] = self.context['request'].user
        # Set publish_at to now if status is published, otherwise leave as null
        if validated_data.get('status') == 'published':
            from django.utils import timezone
            validated_data['publish_at'] = timezone.now()
        return Notice.objects.create(**validated_data)


class NoticeListSerializer(serializers.ModelSerializer):
    """Simplified notice serializer for list views"""
    author = serializers.StringRelatedField(read_only=True)
    
    class Meta:
        model = Notice
        fields = [
            'id', 'title', 'summary', 'priority', 'status', 'visibility',
            'author', 'publish_at', 'expires_at', 'view_count', 'is_pinned',
            'created_at'
        ]


class AnnouncementSerializer(serializers.ModelSerializer):
    """Announcement serializer"""
    author = serializers.StringRelatedField(read_only=True)
    
    class Meta:
        model = Announcement
        fields = [
            'id', 'title', 'message', 'priority', 'status', 'author',
            'target_audience', 'target_details', 'show_until', 'is_sticky',
            'created_at', 'updated_at', 'activated_at'
        ]
        read_only_fields = ['id', 'author', 'created_at', 'updated_at', 'activated_at']


class AnnouncementCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating announcements"""
    
    class Meta:
        model = Announcement
        fields = [
            'title', 'message', 'priority', 'target_audience', 'target_details',
            'show_until', 'is_sticky'
        ]
    
    def create(self, validated_data):
        validated_data['author'] = self.context['request'].user
        return Announcement.objects.create(**validated_data)


class NoticeViewSerializer(serializers.ModelSerializer):
    """Notice view serializer"""
    user = serializers.StringRelatedField(read_only=True)
    
    class Meta:
        model = NoticeView
        fields = ['id', 'user', 'viewed_at', 'ip_address']
        read_only_fields = ['id', 'viewed_at']


class NoticeDraftSerializer(serializers.ModelSerializer):
    """Serializer for saving draft notices"""
    author = serializers.StringRelatedField(read_only=True)
    
    class Meta:
        model = Notice
        fields = [
            'id', 'title', 'content', 'summary', 'priority', 'visibility',
            'target_branches', 'target_years', 'attachment', 'expires_at',
            'is_pinned', 'tags', 'status', 'author', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'author', 'created_at', 'updated_at']


class NoticeViewCreateSerializer(serializers.Serializer):
    """Serializer for creating notice views"""
    notice_id = serializers.IntegerField()
    
    def create(self, validated_data):
        notice_id = validated_data['notice_id']
        user = self.context['request'].user
        ip_address = self.context['request'].META.get('REMOTE_ADDR')
        
        notice_view, created = NoticeView.objects.get_or_create(
            notice_id=notice_id,
            user=user,
            defaults={'ip_address': ip_address}
        )
        
        if created:
            # Increment view count
            notice = notice_view.notice
            notice.view_count += 1
            notice.save()
        
        return notice_view
