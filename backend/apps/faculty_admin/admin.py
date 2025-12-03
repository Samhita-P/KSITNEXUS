from django.contrib import admin
from .models import (
    Case, CaseTag, CaseUpdate, Broadcast, BroadcastEngagement,
    PredictiveMetric, OperationalAlert
)


@admin.register(Case)
class CaseAdmin(admin.ModelAdmin):
    list_display = ['case_id', 'title', 'status', 'priority', 'assigned_to', 'sla_status', 'created_at']
    list_filter = ['status', 'priority', 'sla_status', 'case_type', 'created_at']
    search_fields = ['case_id', 'title', 'description']
    ordering = ['-created_at']
    readonly_fields = ['case_id', 'sla_breach_time', 'sla_status', 'views_count', 'updates_count']


@admin.register(CaseTag)
class CaseTagAdmin(admin.ModelAdmin):
    list_display = ['name', 'color', 'is_active']
    list_filter = ['is_active']
    search_fields = ['name']


@admin.register(CaseUpdate)
class CaseUpdateAdmin(admin.ModelAdmin):
    list_display = ['case', 'updated_by', 'is_internal', 'created_at']
    list_filter = ['is_internal', 'created_at']
    search_fields = ['case__case_id', 'comment']


@admin.register(Broadcast)
class BroadcastAdmin(admin.ModelAdmin):
    list_display = ['title', 'broadcast_type', 'priority', 'is_published', 'created_by', 'created_at']
    list_filter = ['broadcast_type', 'priority', 'is_published', 'created_at']
    search_fields = ['title', 'content']
    ordering = ['-created_at']


@admin.register(BroadcastEngagement)
class BroadcastEngagementAdmin(admin.ModelAdmin):
    list_display = ['broadcast', 'user', 'viewed_at', 'shared']
    list_filter = ['viewed_at', 'shared']
    search_fields = ['broadcast__title', 'user__username']


@admin.register(PredictiveMetric)
class PredictiveMetricAdmin(admin.ModelAdmin):
    list_display = ['metric_type', 'value', 'predicted_value', 'confidence', 'period_end']
    list_filter = ['metric_type', 'period_end']
    ordering = ['-period_end']


@admin.register(OperationalAlert)
class OperationalAlertAdmin(admin.ModelAdmin):
    list_display = ['alert_type', 'severity', 'title', 'is_acknowledged', 'is_resolved', 'created_at']
    list_filter = ['alert_type', 'severity', 'is_acknowledged', 'is_resolved', 'created_at']
    search_fields = ['title', 'message']
    ordering = ['-created_at']
    readonly_fields = ['acknowledged_at', 'resolved_at']

















