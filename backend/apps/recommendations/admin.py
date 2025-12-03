"""
Admin configuration for recommendations app
"""
from django.contrib import admin
from .models import (
    Recommendation, UserPreference, ContentInteraction,
    UserSimilarity, ItemSimilarity
)


@admin.register(Recommendation)
class RecommendationAdmin(admin.ModelAdmin):
    """Admin for Recommendation model"""
    list_display = [
        'id', 'user', 'content_type', 'content_id', 'recommendation_type',
        'score', 'is_dismissed', 'is_viewed', 'is_interacted', 'created_at'
    ]
    list_filter = [
        'content_type', 'recommendation_type', 'is_dismissed',
        'is_viewed', 'is_interacted', 'created_at'
    ]
    search_fields = ['user__username', 'user__email', 'reason']
    readonly_fields = ['created_at', 'updated_at']
    ordering = ['-score', '-created_at']


@admin.register(UserPreference)
class UserPreferenceAdmin(admin.ModelAdmin):
    """Admin for UserPreference model"""
    list_display = [
        'id', 'user', 'content_type', 'created_at', 'updated_at'
    ]
    list_filter = ['content_type', 'created_at', 'updated_at']
    search_fields = ['user__username', 'user__email']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(ContentInteraction)
class ContentInteractionAdmin(admin.ModelAdmin):
    """Admin for ContentInteraction model"""
    list_display = [
        'id', 'user', 'content_type', 'content_id', 'interaction_type',
        'rating', 'duration', 'created_at'
    ]
    list_filter = [
        'content_type', 'interaction_type', 'rating', 'created_at'
    ]
    search_fields = ['user__username', 'user__email']
    readonly_fields = ['created_at', 'updated_at']
    ordering = ['-created_at']


@admin.register(UserSimilarity)
class UserSimilarityAdmin(admin.ModelAdmin):
    """Admin for UserSimilarity model"""
    list_display = [
        'id', 'user1', 'user2', 'similarity_type', 'similarity_score',
        'last_calculated', 'created_at'
    ]
    list_filter = ['similarity_type', 'last_calculated', 'created_at']
    search_fields = ['user1__username', 'user2__username']
    readonly_fields = ['created_at', 'updated_at', 'last_calculated']
    ordering = ['-similarity_score']


@admin.register(ItemSimilarity)
class ItemSimilarityAdmin(admin.ModelAdmin):
    """Admin for ItemSimilarity model"""
    list_display = [
        'id', 'content_type', 'item1_id', 'item2_id', 'similarity_type',
        'similarity_score', 'last_calculated', 'created_at'
    ]
    list_filter = [
        'content_type', 'similarity_type', 'last_calculated', 'created_at'
    ]
    readonly_fields = ['created_at', 'updated_at', 'last_calculated']
    ordering = ['-similarity_score']
