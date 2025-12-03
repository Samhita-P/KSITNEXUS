from django.contrib import admin
from .models import (
    ChatbotCategory, ChatbotQuestion, ChatbotSession,
    ChatbotMessage, ChatbotFeedback, ChatbotAnalytics
)
from .models_nlp import (
    ConversationContext, ChatbotUserProfile, ChatbotAction, ChatbotActionExecution
)


@admin.register(ChatbotCategory)
class ChatbotCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'description', 'icon', 'is_active', 'order']
    list_filter = ['is_active', 'order']
    search_fields = ['name', 'description']
    ordering = ['order', 'name']


@admin.register(ChatbotQuestion)
class ChatbotQuestionAdmin(admin.ModelAdmin):
    list_display = [
        'question', 'category', 'is_active', 'priority',
        'usage_count', 'created_at', 'updated_at',
    ]
    list_filter = ['category', 'is_active', 'priority', 'created_at']
    search_fields = ['question', 'answer', 'keywords']
    ordering = ['-priority', '-usage_count']
    readonly_fields = ['usage_count', 'created_at', 'updated_at']
    
    fieldsets = (
        ('Question Information', {
            'fields': ('category', 'question', 'answer')
        }),
        ('Matching', {
            'fields': ('keywords', 'tags')
        }),
        ('Settings', {
            'fields': ('is_active', 'priority', 'usage_count')
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(ChatbotSession)
class ChatbotSessionAdmin(admin.ModelAdmin):
    list_display = [
        'session_id', 'user', 'is_active', 'ip_address',
        'created_at', 'updated_at', 'ended_at',
    ]
    list_filter = ['is_active', 'created_at']
    search_fields = ['session_id', 'user__username', 'user__email', 'ip_address']
    readonly_fields = ['session_id', 'created_at', 'updated_at', 'ended_at']
    ordering = ['-created_at']


@admin.register(ChatbotMessage)
class ChatbotMessageAdmin(admin.ModelAdmin):
    list_display = [
        'session', 'message_type', 'content', 'related_question',
        'confidence_score', 'is_helpful', 'created_at',
    ]
    list_filter = ['message_type', 'is_helpful', 'created_at']
    search_fields = ['content', 'session__session_id']
    readonly_fields = ['created_at']
    ordering = ['-created_at']


@admin.register(ChatbotFeedback)
class ChatbotFeedbackAdmin(admin.ModelAdmin):
    list_display = ['message', 'rating', 'user', 'comment', 'created_at']
    list_filter = ['rating', 'created_at']
    search_fields = ['message__content', 'user__username', 'comment']
    readonly_fields = ['created_at']
    ordering = ['-created_at']


@admin.register(ChatbotAnalytics)
class ChatbotAnalyticsAdmin(admin.ModelAdmin):
    list_display = [
        'date', 'total_sessions', 'total_messages', 'unique_users',
        'average_rating', 'resolution_rate', 'created_at',
    ]
    list_filter = ['date', 'created_at']
    readonly_fields = [
        'total_sessions', 'total_messages', 'unique_users',
        'most_asked_questions', 'unanswered_questions',
        'average_response_time', 'average_rating', 'resolution_rate',
        'created_at', 'updated_at',
    ]
    ordering = ['-date']


@admin.register(ConversationContext)
class ConversationContextAdmin(admin.ModelAdmin):
    list_display = [
        'session', 'current_intent', 'conversation_state',
        'sentiment_label', 'is_active', 'last_updated',
    ]
    list_filter = ['conversation_state', 'sentiment_label', 'is_active', 'last_updated']
    search_fields = ['session__session_id', 'current_intent']
    readonly_fields = [
        'context_variables', 'detected_entities', 'conversation_history',
        'last_updated', 'created_at', 'updated_at',
    ]
    ordering = ['-last_updated']


@admin.register(ChatbotUserProfile)
class ChatbotUserProfileAdmin(admin.ModelAdmin):
    list_display = [
        'user', 'preferred_language', 'response_style',
        'total_interactions', 'total_sessions', 'average_rating',
        'is_personalized', 'last_interaction_at',
    ]
    list_filter = [
        'preferred_language', 'response_style', 'is_personalized',
        'last_interaction_at',
    ]
    search_fields = ['user__username', 'user__email']
    readonly_fields = [
        'total_interactions', 'total_sessions', 'average_rating',
        'common_topics', 'preferred_categories', 'preferences',
        'last_interaction_at', 'created_at', 'updated_at',
    ]
    ordering = ['-last_interaction_at']


@admin.register(ChatbotAction)
class ChatbotActionAdmin(admin.ModelAdmin):
    list_display = [
        'name', 'action_type', 'is_active',
        'usage_count', 'success_count', 'failure_count',
        'success_rate',
    ]
    list_filter = ['action_type', 'is_active']
    search_fields = ['name', 'description']
    readonly_fields = [
        'usage_count', 'success_count', 'failure_count',
        'created_at', 'updated_at',
    ]
    ordering = ['-usage_count']
    
    fieldsets = (
        ('Action Information', {
            'fields': ('name', 'action_type', 'description')
        }),
        ('Configuration', {
            'fields': ('action_config', 'required_params', 'optional_params', 'execution_function')
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Statistics', {
            'fields': ('usage_count', 'success_count', 'failure_count'),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(ChatbotActionExecution)
class ChatbotActionExecutionAdmin(admin.ModelAdmin):
    list_display = [
        'action', 'session', 'user', 'status',
        'execution_time', 'created_at',
    ]
    list_filter = ['status', 'action__action_type', 'created_at']
    search_fields = ['action__name', 'session__session_id', 'user__username']
    readonly_fields = [
        'parameters', 'result', 'error_message',
        'execution_time', 'created_at', 'updated_at',
    ]
    ordering = ['-created_at']

