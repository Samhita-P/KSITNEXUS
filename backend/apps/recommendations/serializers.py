"""
Serializers for recommendations app
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    Recommendation, UserPreference, ContentInteraction,
    UserSimilarity, ItemSimilarity
)

User = get_user_model()


class RecommendationSerializer(serializers.ModelSerializer):
    """Serializer for Recommendation model"""
    user = serializers.StringRelatedField(read_only=True)
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    content_type_display = serializers.CharField(
        source='get_content_type_display',
        read_only=True
    )
    recommendation_type_display = serializers.CharField(
        source='get_recommendation_type_display',
        read_only=True
    )
    content_title = serializers.SerializerMethodField()
    
    def get_content_title(self, obj):
        """Get the title of the recommended content"""
        try:
            if obj.content_type == 'notice':
                from apps.notices.models import Notice
                notice = Notice.objects.filter(id=obj.content_id).first()
                if notice:
                    return notice.title
                return None
            elif obj.content_type == 'study_group':
                from apps.study_groups.models import StudyGroup
                study_group = StudyGroup.objects.filter(id=obj.content_id).first()
                if study_group:
                    return study_group.name
                return None
            elif obj.content_type == 'resource':
                # Add resource model import when available
                return None
            return None
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.warning(f"Error getting content title for {obj.content_type} {obj.content_id}: {e}")
            return None
    
    class Meta:
        model = Recommendation
        fields = [
            'id', 'user', 'user_id', 'content_type', 'content_type_display',
            'content_id', 'content_title', 'recommendation_type', 'recommendation_type_display',
            'score', 'reason', 'is_dismissed', 'is_viewed', 'is_interacted',
            'feedback', 'expires_at', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'user', 'user_id', 'created_at', 'updated_at',
            'content_type_display', 'recommendation_type_display', 'content_title',
        ]


class RecommendationCreateSerializer(serializers.Serializer):
    """Serializer for creating recommendations"""
    content_type = serializers.ChoiceField(choices=Recommendation.CONTENT_TYPES)
    content_id = serializers.IntegerField()
    recommendation_type = serializers.ChoiceField(
        choices=Recommendation.RECOMMENDATION_TYPES,
        default='content_based',
        required=False
    )
    limit = serializers.IntegerField(default=10, min_value=1, max_value=50, required=False)


class RecommendationFeedbackSerializer(serializers.Serializer):
    """Serializer for recommendation feedback"""
    feedback_type = serializers.CharField(max_length=50)
    feedback_data = serializers.DictField()


class UserPreferenceSerializer(serializers.ModelSerializer):
    """Serializer for UserPreference model"""
    user = serializers.StringRelatedField(read_only=True)
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    content_type_display = serializers.CharField(
        source='get_content_type_display',
        read_only=True
    )
    
    class Meta:
        model = UserPreference
        fields = [
            'id', 'user', 'user_id', 'content_type', 'content_type_display',
            'preferences', 'interests', 'behavior_patterns', 'weight_preferences',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'user', 'user_id', 'created_at', 'updated_at', 'content_type_display']


class UserPreferenceUpdateSerializer(serializers.Serializer):
    """Serializer for updating user preferences"""
    preferences = serializers.DictField(required=False)
    interests = serializers.ListField(
        child=serializers.CharField(),
        required=False
    )
    behavior_patterns = serializers.DictField(required=False)
    weight_preferences = serializers.DictField(required=False)


class ContentInteractionSerializer(serializers.ModelSerializer):
    """Serializer for ContentInteraction model"""
    user = serializers.StringRelatedField(read_only=True)
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    content_type_display = serializers.CharField(
        source='get_content_type_display',
        read_only=True
    )
    interaction_type_display = serializers.CharField(
        source='get_interaction_type_display',
        read_only=True
    )
    
    class Meta:
        model = ContentInteraction
        fields = [
            'id', 'user', 'user_id', 'content_type', 'content_type_display',
            'content_id', 'interaction_type', 'interaction_type_display',
            'rating', 'duration', 'metadata', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'user', 'user_id', 'created_at', 'updated_at',
            'content_type_display', 'interaction_type_display',
        ]


class ContentInteractionCreateSerializer(serializers.Serializer):
    """Serializer for creating content interactions"""
    content_type = serializers.ChoiceField(choices=ContentInteraction.CONTENT_TYPES)
    content_id = serializers.IntegerField()
    interaction_type = serializers.ChoiceField(choices=ContentInteraction.INTERACTION_TYPES)
    rating = serializers.IntegerField(
        min_value=1,
        max_value=5,
        required=False,
        allow_null=True
    )
    duration = serializers.IntegerField(
        min_value=0,
        required=False,
        allow_null=True
    )
    metadata = serializers.DictField(required=False, default=dict)


class UserSimilaritySerializer(serializers.ModelSerializer):
    """Serializer for UserSimilarity model"""
    user1 = serializers.StringRelatedField(read_only=True)
    user1_id = serializers.IntegerField(source='user1.id', read_only=True)
    user2 = serializers.StringRelatedField(read_only=True)
    user2_id = serializers.IntegerField(source='user2.id', read_only=True)
    similarity_type_display = serializers.CharField(
        source='get_similarity_type_display',
        read_only=True
    )
    
    class Meta:
        model = UserSimilarity
        fields = [
            'id', 'user1', 'user1_id', 'user2', 'user2_id',
            'similarity_score', 'similarity_type', 'similarity_type_display',
            'last_calculated', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'user1', 'user1_id', 'user2', 'user2_id',
            'created_at', 'updated_at', 'similarity_type_display',
        ]


class ItemSimilaritySerializer(serializers.ModelSerializer):
    """Serializer for ItemSimilarity model"""
    content_type_display = serializers.CharField(
        source='get_content_type_display',
        read_only=True
    )
    similarity_type_display = serializers.CharField(
        source='get_similarity_type_display',
        read_only=True
    )
    
    class Meta:
        model = ItemSimilarity
        fields = [
            'id', 'content_type', 'content_type_display',
            'item1_id', 'item2_id', 'similarity_score',
            'similarity_type', 'similarity_type_display',
            'last_calculated', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'created_at', 'updated_at',
            'content_type_display', 'similarity_type_display',
        ]

