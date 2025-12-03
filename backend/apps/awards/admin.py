from django.contrib import admin
from .models import (
    AwardCategory, Award, UserAward, RecognitionPost,
    RecognitionLike, AwardNomination, AwardCeremony
)


@admin.register(AwardCategory)
class AwardCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'order', 'is_active']
    list_filter = ['is_active']
    search_fields = ['name']
    ordering = ['order']


@admin.register(Award)
class AwardAdmin(admin.ModelAdmin):
    list_display = ['name', 'award_type', 'category', 'points_value', 'is_featured', 'is_active']
    list_filter = ['award_type', 'category', 'is_featured', 'is_active']
    search_fields = ['name', 'description']
    ordering = ['-is_featured', 'name']


@admin.register(UserAward)
class UserAwardAdmin(admin.ModelAdmin):
    list_display = ['user', 'award', 'awarded_by', 'awarded_at', 'is_featured', 'is_public']
    list_filter = ['award', 'awarded_at', 'is_featured', 'is_public']
    search_fields = ['user__username', 'award__name']
    ordering = ['-awarded_at']


@admin.register(RecognitionPost)
class RecognitionPostAdmin(admin.ModelAdmin):
    list_display = ['title', 'post_type', 'is_published', 'published_at', 'views_count', 'likes_count']
    list_filter = ['post_type', 'is_published', 'published_at']
    search_fields = ['title', 'content']
    ordering = ['-published_at', '-created_at']
    readonly_fields = ['published_at', 'views_count', 'likes_count']


@admin.register(RecognitionLike)
class RecognitionLikeAdmin(admin.ModelAdmin):
    list_display = ['post', 'user', 'created_at']
    list_filter = ['created_at']
    search_fields = ['post__title', 'user__username']


@admin.register(AwardNomination)
class AwardNominationAdmin(admin.ModelAdmin):
    list_display = ['nomination_id', 'award', 'nominee', 'nominated_by', 'status', 'created_at']
    list_filter = ['status', 'award', 'created_at']
    search_fields = ['nomination_id', 'nominee__username', 'nominated_by__username']
    ordering = ['-created_at']
    readonly_fields = ['nomination_id']


@admin.register(AwardCeremony)
class AwardCeremonyAdmin(admin.ModelAdmin):
    list_display = ['title', 'event_date', 'location', 'is_published', 'published_at']
    list_filter = ['is_published', 'event_date']
    search_fields = ['title', 'description']
    ordering = ['-event_date']
    readonly_fields = ['published_at']

















