from django.contrib import admin
from .models import Notification, NotificationPreference, NotificationTemplate, NotificationLog
from .models_digest import NotificationDigest, NotificationTier, NotificationSummary, NotificationPriorityRule
from .fcm_models import FCMToken, PushNotification, FCMNotificationTemplate

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['title', 'user', 'notification_type', 'is_read', 'created_at']
    list_filter = ['notification_type', 'is_read', 'created_at']
    search_fields = ['title', 'message', 'user__username']
    readonly_fields = ['created_at', 'updated_at']

@admin.register(FCMToken)
class FCMTokenAdmin(admin.ModelAdmin):
    list_display = ['user', 'platform', 'is_active', 'created_at', 'last_used']
    list_filter = ['platform', 'is_active', 'created_at']
    search_fields = ['user__username', 'token']
    readonly_fields = ['created_at', 'updated_at', 'last_used']

@admin.register(PushNotification)
class PushNotificationAdmin(admin.ModelAdmin):
    list_display = ['title', 'notification_type', 'status', 'created_at', 'sent_at']
    list_filter = ['notification_type', 'status', 'priority', 'created_at']
    search_fields = ['title', 'body']
    readonly_fields = ['created_at', 'updated_at', 'sent_at', 'error_message', 'retry_count']
    filter_horizontal = ['target_users', 'fcm_tokens']

@admin.register(FCMNotificationTemplate)
class FCMNotificationTemplateAdmin(admin.ModelAdmin):
    list_display = ['name', 'notification_type', 'priority', 'is_active', 'created_at']
    list_filter = ['notification_type', 'priority', 'is_active', 'created_at']
    search_fields = ['name', 'title_template', 'body_template']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(NotificationPreference)
class NotificationPreferenceAdmin(admin.ModelAdmin):
    list_display = ['user', 'push_enabled', 'email_enabled', 'digest_frequency', 'created_at']
    list_filter = ['push_enabled', 'email_enabled', 'digest_frequency', 'created_at']
    search_fields = ['user__username']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(NotificationTemplate)
class NotificationTemplateAdmin(admin.ModelAdmin):
    list_display = ['name', 'notification_type', 'priority', 'is_active', 'created_at']
    list_filter = ['notification_type', 'priority', 'is_active', 'created_at']
    search_fields = ['name', 'title_template', 'message_template']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(NotificationLog)
class NotificationLogAdmin(admin.ModelAdmin):
    list_display = ['notification', 'channel', 'status', 'attempted_at']
    list_filter = ['channel', 'status', 'attempted_at']
    search_fields = ['notification__title']
    readonly_fields = ['attempted_at']


@admin.register(NotificationDigest)
class NotificationDigestAdmin(admin.ModelAdmin):
    list_display = ['user', 'title', 'frequency', 'notification_count', 'is_sent', 'is_read', 'created_at']
    list_filter = ['frequency', 'is_sent', 'is_read', 'created_at']
    search_fields = ['user__username', 'title']
    readonly_fields = ['created_at', 'updated_at', 'sent_at', 'read_at']
    filter_horizontal = ['notifications']
    date_hierarchy = 'created_at'


@admin.register(NotificationTier)
class NotificationTierAdmin(admin.ModelAdmin):
    list_display = ['user', 'tier', 'push_enabled', 'email_enabled', 'escalation_enabled', 'created_at']
    list_filter = ['tier', 'push_enabled', 'email_enabled', 'escalation_enabled', 'created_at']
    search_fields = ['user__username']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(NotificationSummary)
class NotificationSummaryAdmin(admin.ModelAdmin):
    list_display = ['notification', 'summary_type', 'confidence_score', 'word_count', 'generated_at']
    list_filter = ['summary_type', 'generated_at']
    search_fields = ['notification__title', 'summary_text']
    readonly_fields = ['generated_at', 'created_at', 'updated_at']


@admin.register(NotificationPriorityRule)
class NotificationPriorityRuleAdmin(admin.ModelAdmin):
    list_display = ['user', 'is_global', 'notification_type', 'priority', 'is_active', 'created_at']
    list_filter = ['is_global', 'notification_type', 'priority', 'is_active', 'created_at']
    search_fields = ['user__username', 'keyword', 'sender']
    readonly_fields = ['created_at', 'updated_at']
