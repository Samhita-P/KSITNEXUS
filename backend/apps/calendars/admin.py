from django.contrib import admin
from .models import CalendarEvent, EventReminder, GoogleCalendarSync, CalendarEventSync


@admin.register(CalendarEvent)
class CalendarEventAdmin(admin.ModelAdmin):
    list_display = [
        'title', 'event_type', 'start_time', 'end_time', 'created_by',
        'is_cancelled', 'privacy', 'created_at',
    ]
    list_filter = [
        'event_type', 'is_cancelled', 'privacy', 'is_recurring',
        'recurrence_pattern', 'created_at',
    ]
    search_fields = ['title', 'description', 'location']
    readonly_fields = ['created_at', 'updated_at', 'cancelled_at']
    ordering = ['-start_time']
    
    fieldsets = (
        ('Event Information', {
            'fields': ('title', 'description', 'event_type', 'color', 'privacy')
        }),
        ('Event Timing', {
            'fields': ('start_time', 'end_time', 'all_day', 'timezone')
        }),
        ('Event Location', {
            'fields': ('location', 'meeting_link')
        }),
        ('Recurrence', {
            'fields': (
                'is_recurring', 'recurrence_pattern',
                'recurrence_end_date', 'recurrence_count'
            )
        }),
        ('Participants', {
            'fields': ('created_by', 'attendees', 'external_attendees')
        }),
        ('Related Entities', {
            'fields': ('related_meeting', 'related_study_group_event')
        }),
        ('Status', {
            'fields': ('is_cancelled', 'cancelled_at', 'cancelled_by')
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    filter_horizontal = ['attendees']


@admin.register(EventReminder)
class EventReminderAdmin(admin.ModelAdmin):
    list_display = [
        'event', 'user', 'reminder_type', 'minutes_before',
        'is_sent', 'sent_at', 'created_at',
    ]
    list_filter = ['reminder_type', 'is_sent', 'minutes_before', 'created_at']
    search_fields = ['event__title', 'user__email', 'user__username']
    readonly_fields = ['sent_at', 'created_at', 'updated_at']
    ordering = ['-created_at']
    
    fieldsets = (
        ('Reminder Information', {
            'fields': ('event', 'user', 'reminder_type', 'minutes_before')
        }),
        ('Status', {
            'fields': ('is_sent', 'sent_at')
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(GoogleCalendarSync)
class GoogleCalendarSyncAdmin(admin.ModelAdmin):
    list_display = [
        'user', 'is_connected', 'calendar_id', 'sync_enabled',
        'sync_direction', 'last_sync_at', 'created_at',
    ]
    list_filter = [
        'is_connected', 'sync_enabled', 'sync_direction', 'created_at',
    ]
    search_fields = ['user__email', 'user__username', 'calendar_id']
    readonly_fields = [
        'access_token', 'refresh_token', 'token_expires_at',
        'last_sync_at', 'created_at', 'updated_at',
    ]
    ordering = ['-created_at']
    
    fieldsets = (
        ('User Information', {
            'fields': ('user',)
        }),
        ('Connection Status', {
            'fields': ('is_connected', 'calendar_id')
        }),
        ('Sync Settings', {
            'fields': ('sync_enabled', 'sync_direction', 'last_sync_at')
        }),
        ('OAuth Tokens', {
            'fields': ('access_token', 'refresh_token', 'token_expires_at'),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(CalendarEventSync)
class CalendarEventSyncAdmin(admin.ModelAdmin):
    list_display = [
        'event', 'google_calendar_id', 'ical_uid',
        'sync_status', 'last_synced_at',
    ]
    list_filter = ['sync_status', 'last_synced_at']
    search_fields = [
        'event__title', 'google_calendar_id', 'ical_uid',
    ]
    readonly_fields = ['last_synced_at']
    ordering = ['-last_synced_at']
    
    fieldsets = (
        ('Event Information', {
            'fields': ('event',)
        }),
        ('Sync Information', {
            'fields': ('google_calendar_id', 'ical_uid', 'sync_status')
        }),
        ('Metadata', {
            'fields': ('last_synced_at',)
        }),
    )
