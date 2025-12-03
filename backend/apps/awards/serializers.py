"""
Serializers for awards app
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    AwardCategory, Award, UserAward, RecognitionPost,
    RecognitionLike, AwardNomination, AwardCeremony
)

User = get_user_model()


class AwardCategorySerializer(serializers.ModelSerializer):
    """Serializer for AwardCategory"""
    awards_count = serializers.SerializerMethodField()
    
    class Meta:
        model = AwardCategory
        fields = [
            'id', 'name', 'description', 'icon', 'color', 'is_active',
            'order', 'awards_count', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']
    
    def get_awards_count(self, obj):
        return obj.awards.filter(is_active=True).count()


class AwardSerializer(serializers.ModelSerializer):
    """Serializer for Award"""
    category_name = serializers.SerializerMethodField()
    user_awards_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Award
        fields = [
            'id', 'name', 'award_type', 'category', 'category_name',
            'description', 'criteria', 'icon', 'badge_image_url',
            'points_value', 'is_active', 'is_featured',
            'user_awards_count', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']
    
    def get_category_name(self, obj):
        return obj.category.name if obj.category else None
    
    def get_user_awards_count(self, obj):
        return obj.user_awards.count()


class UserAwardSerializer(serializers.ModelSerializer):
    """Serializer for UserAward"""
    award_name = serializers.SerializerMethodField()
    award_type = serializers.SerializerMethodField()
    user_name = serializers.SerializerMethodField()
    awarded_by_name = serializers.SerializerMethodField()
    
    class Meta:
        model = UserAward
        fields = [
            'id', 'award', 'award_name', 'award_type', 'user', 'user_name',
            'awarded_by', 'awarded_by_name', 'awarded_at', 'reason',
            'certificate_url', 'is_public', 'is_featured',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['awarded_at', 'created_at', 'updated_at']
    
    def get_award_name(self, obj):
        return obj.award.name
    
    def get_award_type(self, obj):
        return obj.award.award_type
    
    def get_user_name(self, obj):
        return f"{obj.user.first_name} {obj.user.last_name}".strip() or obj.user.username
    
    def get_awarded_by_name(self, obj):
        if obj.awarded_by:
            return f"{obj.awarded_by.first_name} {obj.awarded_by.last_name}".strip() or obj.awarded_by.username
        return None


class RecognitionPostSerializer(serializers.ModelSerializer):
    """Serializer for RecognitionPost"""
    created_by_name = serializers.SerializerMethodField()
    recognized_users_names = serializers.SerializerMethodField()
    related_award_name = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()
    
    class Meta:
        model = RecognitionPost
        fields = [
            'id', 'title', 'post_type', 'content', 'featured_image_url',
            'recognized_users', 'recognized_users_names', 'related_award',
            'related_award_name', 'created_by', 'created_by_name',
            'is_published', 'published_at', 'views_count', 'likes_count',
            'is_liked', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'created_by', 'published_at', 'views_count', 'likes_count',
            'created_at', 'updated_at',
        ]
    
    def get_created_by_name(self, obj):
        if obj.created_by:
            return f"{obj.created_by.first_name} {obj.created_by.last_name}".strip() or obj.created_by.username
        return None
    
    def get_recognized_users_names(self, obj):
        return [
            f"{user.first_name} {user.last_name}".strip() or user.username
            for user in obj.recognized_users.all()
        ]
    
    def get_related_award_name(self, obj):
        return obj.related_award.name if obj.related_award else None
    
    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.likes.filter(user=request.user).exists()
        return False


class AwardNominationSerializer(serializers.ModelSerializer):
    """Serializer for AwardNomination"""
    award_name = serializers.SerializerMethodField()
    nominee_name = serializers.SerializerMethodField()
    nominated_by_name = serializers.SerializerMethodField()
    reviewed_by_name = serializers.SerializerMethodField()
    
    class Meta:
        model = AwardNomination
        fields = [
            'id', 'nomination_id', 'award', 'award_name', 'nominee', 'nominee_name',
            'nominated_by', 'nominated_by_name', 'status', 'nomination_reason',
            'supporting_evidence', 'reviewed_by', 'reviewed_by_name',
            'review_notes', 'reviewed_at', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'nominated_by', 'reviewed_by', 'reviewed_at',
            'created_at', 'updated_at',
        ]
    
    def get_award_name(self, obj):
        return obj.award.name
    
    def get_nominee_name(self, obj):
        return f"{obj.nominee.first_name} {obj.nominee.last_name}".strip() or obj.nominee.username
    
    def get_nominated_by_name(self, obj):
        return f"{obj.nominated_by.first_name} {obj.nominated_by.last_name}".strip() or obj.nominated_by.username
    
    def get_reviewed_by_name(self, obj):
        if obj.reviewed_by:
            return f"{obj.reviewed_by.first_name} {obj.reviewed_by.last_name}".strip() or obj.reviewed_by.username
        return None


class AwardCeremonySerializer(serializers.ModelSerializer):
    """Serializer for AwardCeremony"""
    created_by_name = serializers.SerializerMethodField()
    awards_list = serializers.SerializerMethodField()
    
    class Meta:
        model = AwardCeremony
        fields = [
            'id', 'title', 'description', 'event_date', 'location',
            'is_virtual', 'virtual_link', 'awards', 'awards_list',
            'created_by', 'created_by_name', 'is_published', 'published_at',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'created_by', 'published_at', 'created_at', 'updated_at',
        ]
    
    def get_created_by_name(self, obj):
        if obj.created_by:
            return f"{obj.created_by.first_name} {obj.created_by.last_name}".strip() or obj.created_by.username
        return None
    
    def get_awards_list(self, obj):
        return [award.name for award in obj.awards.all()]

















