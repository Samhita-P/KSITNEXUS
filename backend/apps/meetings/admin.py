from django.contrib import admin
from .models import Meeting

@admin.register(Meeting)
class MeetingAdmin(admin.ModelAdmin):
    list_display = ['title', 'type', 'scheduled_date', 'status', 'created_by', 'created_at']
    list_filter = ['type', 'status', 'audience', 'created_at']
    search_fields = ['title', 'description', 'location']
    readonly_fields = ['created_at', 'updated_at']
    ordering = ['-scheduled_date']
    
    fieldsets = (
        ('Meeting Details', {
            'fields': ('title', 'description', 'type', 'location')
        }),
        ('Schedule', {
            'fields': ('scheduled_date', 'duration')
        }),
        ('Participants', {
            'fields': ('audience', 'notes')
        }),
        ('Status', {
            'fields': ('status',)
        }),
        ('Metadata', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

