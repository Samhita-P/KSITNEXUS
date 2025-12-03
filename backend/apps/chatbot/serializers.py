"""
Serializers for chatbot app
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import ChatbotCategory, ChatbotQuestion, ChatbotSession, ChatbotMessage, ChatbotFeedback, ChatbotAnalytics

User = get_user_model()


class ChatbotCategorySerializer(serializers.ModelSerializer):
    """Chatbot category serializer"""
    
    class Meta:
        model = ChatbotCategory
        fields = [
            'id', 'name', 'description', 'icon', 'is_active', 'order'
        ]
        read_only_fields = ['id']


class ChatbotQuestionSerializer(serializers.ModelSerializer):
    """Chatbot question serializer"""
    category = serializers.StringRelatedField(read_only=True)
    
    class Meta:
        model = ChatbotQuestion
        fields = [
            'id', 'category', 'question', 'answer', 'keywords', 'tags',
            'is_active', 'priority', 'usage_count', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'usage_count', 'created_at', 'updated_at']


class ChatbotQuestionCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating chatbot questions"""
    
    class Meta:
        model = ChatbotQuestion
        fields = [
            'category', 'question', 'answer', 'keywords', 'tags',
            'is_active', 'priority'
        ]
    
    def create(self, validated_data):
        return ChatbotQuestion.objects.create(**validated_data)


class ChatbotSessionSerializer(serializers.ModelSerializer):
    """Chatbot session serializer"""
    user = serializers.StringRelatedField(read_only=True)
    
    class Meta:
        model = ChatbotSession
        fields = [
            'id', 'user', 'session_id', 'ip_address', 'user_agent',
            'is_active', 'created_at', 'updated_at', 'ended_at'
        ]
        read_only_fields = [
            'id', 'session_id', 'created_at', 'updated_at', 'ended_at'
        ]


class ChatbotMessageSerializer(serializers.ModelSerializer):
    """Chatbot message serializer"""
    related_question = ChatbotQuestionSerializer(read_only=True)
    session_id = serializers.CharField(source='session.session_id', read_only=True)
    
    class Meta:
        model = ChatbotMessage
        fields = [
            'id', 'session', 'session_id', 'message_type', 'content',
            'related_question', 'confidence_score', 'is_helpful',
            'feedback_comment', 'created_at'
        ]
        read_only_fields = [
            'id', 'created_at'
        ]


class ChatbotMessageCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating chatbot messages"""
    
    class Meta:
        model = ChatbotMessage
        fields = [
            'message_type', 'content'
        ]
    
    def create(self, validated_data):
        validated_data['session'] = self.context['session']
        return ChatbotMessage.objects.create(**validated_data)


class ChatbotFeedbackSerializer(serializers.ModelSerializer):
    """Chatbot feedback serializer"""
    user = serializers.StringRelatedField(read_only=True)
    
    class Meta:
        model = ChatbotFeedback
        fields = [
            'id', 'message', 'rating', 'comment', 'user', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user if self.context['request'].user.is_authenticated else None
        return ChatbotFeedback.objects.create(**validated_data)


class ChatbotAnalyticsSerializer(serializers.ModelSerializer):
    """Chatbot analytics serializer"""
    
    class Meta:
        model = ChatbotAnalytics
        fields = [
            'id', 'date', 'total_sessions', 'total_messages', 'unique_users',
            'most_asked_questions', 'unanswered_questions', 'average_response_time',
            'average_rating', 'resolution_rate', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class ChatbotQuerySerializer(serializers.Serializer):
    """Serializer for chatbot queries"""
    message = serializers.CharField(max_length=1000)
    session_id = serializers.CharField(required=False, allow_blank=True)
    category_id = serializers.IntegerField(required=False, allow_null=True)


class ChatbotResponseSerializer(serializers.Serializer):
    """Serializer for chatbot responses"""
    response = serializers.CharField()
    confidence_score = serializers.FloatField()
    related_questions = serializers.ListField()
    category = serializers.CharField()
    is_helpful = serializers.BooleanField(default=False)
