from django.contrib import admin
from .models import (
    OnboardingStep, UserOnboardingProgress,
    AlumniProfile, MentorshipRequest, AlumniEvent,
    PlacementOpportunity, PlacementApplication, PlacementStatistic
)


@admin.register(OnboardingStep)
class OnboardingStepAdmin(admin.ModelAdmin):
    list_display = ['name', 'step_type', 'order', 'is_required', 'is_active']
    list_filter = ['step_type', 'is_active', 'is_required']
    search_fields = ['name', 'title']
    ordering = ['order']


@admin.register(UserOnboardingProgress)
class UserOnboardingProgressAdmin(admin.ModelAdmin):
    list_display = ['user', 'current_step', 'is_completed', 'completed_at']
    list_filter = ['is_completed', 'completed_at']
    search_fields = ['user__username', 'user__email']
    readonly_fields = ['completed_at']


@admin.register(AlumniProfile)
class AlumniProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'graduation_year', 'current_company', 'is_mentor', 'is_verified']
    list_filter = ['graduation_year', 'is_mentor', 'is_verified', 'industry']
    search_fields = ['user__username', 'user__email', 'current_company']
    readonly_fields = ['verified_at']


@admin.register(MentorshipRequest)
class MentorshipRequestAdmin(admin.ModelAdmin):
    list_display = ['request_id', 'mentee', 'mentor', 'status', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['request_id', 'mentee__username', 'mentor__username']
    ordering = ['-created_at']
    readonly_fields = ['request_id']


@admin.register(AlumniEvent)
class AlumniEventAdmin(admin.ModelAdmin):
    list_display = ['title', 'event_type', 'start_date', 'is_active']
    list_filter = ['event_type', 'is_active', 'start_date']
    search_fields = ['title', 'description']
    ordering = ['-start_date']


@admin.register(PlacementOpportunity)
class PlacementOpportunityAdmin(admin.ModelAdmin):
    list_display = ['opportunity_id', 'title', 'company_name', 'opportunity_type', 'status', 'created_at']
    list_filter = ['opportunity_type', 'status', 'created_at']
    search_fields = ['opportunity_id', 'title', 'company_name']
    ordering = ['-created_at']
    readonly_fields = ['opportunity_id', 'views_count', 'applications_count']


@admin.register(PlacementApplication)
class PlacementApplicationAdmin(admin.ModelAdmin):
    list_display = ['application_id', 'applicant', 'opportunity', 'status', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['application_id', 'applicant__username', 'opportunity__title']
    ordering = ['-created_at']
    readonly_fields = ['application_id']


@admin.register(PlacementStatistic)
class PlacementStatisticAdmin(admin.ModelAdmin):
    list_display = ['stat_type', 'period_start', 'period_end']
    list_filter = ['stat_type', 'period_end']
    ordering = ['-period_end']

















