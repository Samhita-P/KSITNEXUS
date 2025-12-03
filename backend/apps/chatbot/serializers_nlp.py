"""
Serializers for NLP-enhanced chatbot models
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models_nlp import (
    ConversationContext, ChatbotUserProfile, ChatbotAction, ChatbotActionExecution
)

User = get_user_model()


class ConversationContextSerializer(serializers.ModelSerializer):
    """Serializer for ConversationContext"""
    session_id = serializers.CharField(source='session.session_id', read_only=True)
    
    class Meta:
        model = ConversationContext
        fields = [
            'id', 'session', 'session_id', 'context_variables', 'current_intent',
            'conversation_state', 'detected_entities', 'sentiment_score',
            'sentiment_label', 'conversation_history', 'max_history_length',
            'is_active', 'last_updated', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'last_updated', 'created_at', 'updated_at',
        ]


class ChatbotUserProfileSerializer(serializers.ModelSerializer):
    """Serializer for ChatbotUserProfile"""
    user_email = serializers.CharField(source='user.email', read_only=True)
    user_username = serializers.CharField(source='user.username', read_only=True)
    
    class Meta:
        model = ChatbotUserProfile
        fields = [
            'id', 'user', 'user_email', 'user_username',
            'preferred_language', 'response_style', 'preferences',
            'total_interactions', 'total_sessions', 'average_rating',
            'common_topics', 'preferred_categories', 'is_personalized',
            'last_interaction_at', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'user', 'total_interactions', 'total_sessions',
            'average_rating', 'common_topics', 'preferred_categories',
            'last_interaction_at', 'created_at', 'updated_at',
        ]


class ChatbotActionSerializer(serializers.ModelSerializer):
    """Serializer for ChatbotAction"""
    success_rate = serializers.FloatField(read_only=True)
    
    class Meta:
        model = ChatbotAction
        fields = [
            'id', 'name', 'action_type', 'description', 'action_config',
            'required_params', 'optional_params', 'execution_function',
            'is_active', 'usage_count', 'success_count', 'failure_count',
            'success_rate', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'usage_count', 'success_count', 'failure_count',
            'success_rate', 'created_at', 'updated_at',
        ]


class ChatbotActionExecutionSerializer(serializers.ModelSerializer):
    """Serializer for ChatbotActionExecution"""
    action_name = serializers.CharField(source='action.name', read_only=True)
    action_type = serializers.CharField(source='action.action_type', read_only=True)
    session_id = serializers.CharField(source='session.session_id', read_only=True)
    user_email = serializers.CharField(source='user.email', read_only=True, allow_null=True)
    
    class Meta:
        model = ChatbotActionExecution
        fields = [
            'id', 'action', 'action_name', 'action_type', 'session', 'session_id',
            'user', 'user_email', 'parameters', 'result', 'status',
            'error_message', 'execution_time', 'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'result', 'status', 'error_message', 'execution_time',
            'created_at', 'updated_at',
        ]


class UpdateUserProfileSerializer(serializers.Serializer):
    """Serializer for updating user profile"""
    preferred_language = serializers.CharField(required=False, max_length=10)
    response_style = serializers.ChoiceField(
        choices=['formal', 'casual', 'friendly', 'professional'],
        required=False,
    )
    preferences = serializers.JSONField(required=False, default=dict)

