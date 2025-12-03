"""
Serializers for lifecycle app
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    OnboardingStep, UserOnboardingProgress,
    AlumniProfile, MentorshipRequest, AlumniEvent,
    PlacementOpportunity, PlacementApplication, PlacementStatistic
)

User = get_user_model()


class OnboardingStepSerializer(serializers.ModelSerializer):
    """Serializer for OnboardingStep"""
    
    class Meta:
        model = OnboardingStep
        fields = [
            'id', 'name', 'step_type', 'title', 'description', 'content',
            'order', 'is_required', 'is_active', 'target_user_types',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class UserOnboardingProgressSerializer(serializers.ModelSerializer):
    """Serializer for UserOnboardingProgress"""
    current_step_data = OnboardingStepSerializer(source='current_step', read_only=True)
    user_name = serializers.SerializerMethodField()
    
    class Meta:
        model = UserOnboardingProgress
        fields = [
            'id', 'user', 'user_name', 'current_step', 'current_step_data',
            'completed_steps', 'skipped_steps', 'progress_data',
            'is_completed', 'completed_at', 'created_at', 'updated_at',
        ]
        read_only_fields = ['user', 'created_at', 'updated_at']
    
    def get_user_name(self, obj):
        return f"{obj.user.first_name} {obj.user.last_name}".strip() or obj.user.username


class AlumniProfileSerializer(serializers.ModelSerializer):
    """Serializer for AlumniProfile"""
    user_name = serializers.SerializerMethodField()
    user_email = serializers.SerializerMethodField()
    
    class Meta:
        model = AlumniProfile
        fields = [
            'id', 'user', 'user_name', 'user_email',
            'graduation_year', 'degree', 'major', 'current_position',
            'current_company', 'industry', 'location', 'bio',
            'linkedin_url', 'website_url', 'is_mentor',
            'is_available_for_mentorship', 'mentorship_areas',
            'is_verified', 'verified_at', 'created_at', 'updated_at',
        ]
        read_only_fields = ['user', 'is_verified', 'verified_at', 'created_at', 'updated_at']
    
    def get_user_name(self, obj):
        return f"{obj.user.first_name} {obj.user.last_name}".strip() or obj.user.username
    
    def get_user_email(self, obj):
        return obj.user.email


class MentorshipRequestSerializer(serializers.ModelSerializer):
    """Serializer for MentorshipRequest"""
    mentee_name = serializers.SerializerMethodField()
    mentor_name = serializers.SerializerMethodField()
    
    class Meta:
        model = MentorshipRequest
        fields = [
            'id', 'request_id', 'mentee', 'mentee_name', 'mentor', 'mentor_name',
            'status', 'message', 'mentorship_areas', 'mentor_response',
            'started_at', 'completed_at', 'created_at', 'updated_at',
        ]
        read_only_fields = ['mentee', 'created_at', 'updated_at']
    
    def get_mentee_name(self, obj):
        return f"{obj.mentee.first_name} {obj.mentee.last_name}".strip() or obj.mentee.username
    
    def get_mentor_name(self, obj):
        return f"{obj.mentor.first_name} {obj.mentor.last_name}".strip() or obj.mentor.username


class AlumniEventSerializer(serializers.ModelSerializer):
    """Serializer for AlumniEvent"""
    created_by_name = serializers.SerializerMethodField()
    attendees_count = serializers.SerializerMethodField()
    
    class Meta:
        model = AlumniEvent
        fields = [
            'id', 'title', 'event_type', 'description', 'location',
            'start_date', 'end_date', 'registration_deadline', 'max_attendees',
            'registration_url', 'is_active', 'created_by', 'created_by_name',
            'attendees_count', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_by', 'created_at', 'updated_at']
    
    def get_created_by_name(self, obj):
        if obj.created_by:
            return f"{obj.created_by.first_name} {obj.created_by.last_name}".strip() or obj.created_by.username
        return None
    
    def get_attendees_count(self, obj):
        # TODO: Implement attendees count
        return 0


class PlacementOpportunitySerializer(serializers.ModelSerializer):
    """Serializer for PlacementOpportunity"""
    posted_by_name = serializers.SerializerMethodField()
    
    class Meta:
        model = PlacementOpportunity
        fields = [
            'id', 'opportunity_id', 'title', 'company_name', 'opportunity_type',
            'description', 'requirements', 'location', 'is_remote',
            'salary_range_min', 'salary_range_max', 'application_deadline',
            'status', 'posted_by', 'posted_by_name', 'application_url',
            'contact_email', 'tags', 'views_count', 'applications_count',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'posted_by', 'views_count', 'applications_count',
            'created_at', 'updated_at',
        ]
    
    def get_posted_by_name(self, obj):
        if obj.posted_by:
            return f"{obj.posted_by.first_name} {obj.posted_by.last_name}".strip() or obj.posted_by.username
        return None


class PlacementApplicationSerializer(serializers.ModelSerializer):
    """Serializer for PlacementApplication"""
    applicant_name = serializers.SerializerMethodField()
    opportunity_title = serializers.SerializerMethodField()
    company_name = serializers.SerializerMethodField()
    
    class Meta:
        model = PlacementApplication
        fields = [
            'id', 'application_id', 'opportunity', 'opportunity_title',
            'company_name', 'applicant', 'applicant_name', 'status',
            'cover_letter', 'resume_url', 'portfolio_url', 'additional_documents',
            'notes', 'interview_date', 'interview_location', 'offer_details',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['applicant', 'created_at', 'updated_at']
    
    def get_applicant_name(self, obj):
        return f"{obj.applicant.first_name} {obj.applicant.last_name}".strip() or obj.applicant.username
    
    def get_opportunity_title(self, obj):
        return obj.opportunity.title
    
    def get_company_name(self, obj):
        return obj.opportunity.company_name


class PlacementStatisticSerializer(serializers.ModelSerializer):
    """Serializer for PlacementStatistic"""
    
    class Meta:
        model = PlacementStatistic
        fields = [
            'id', 'stat_type', 'period_start', 'period_end',
            'value', 'metadata', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']

















