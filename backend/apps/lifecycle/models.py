"""
Lifecycle Extensions models for KSIT Nexus
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator
from apps.shared.models.base import TimestampedModel

User = get_user_model()


# Onboarding Wizard
class OnboardingStep(TimestampedModel):
    """Onboarding step definition"""
    
    STEP_TYPES = [
        ('welcome', 'Welcome'),
        ('profile', 'Profile Setup'),
        ('preferences', 'Preferences'),
        ('tutorial', 'Tutorial'),
        ('verification', 'Verification'),
        ('completion', 'Completion'),
    ]
    
    name = models.CharField(max_length=100)
    step_type = models.CharField(max_length=20, choices=STEP_TYPES)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    content = models.JSONField(
        default=dict,
        blank=True,
        help_text='Step content (instructions, fields, etc.)'
    )
    order = models.IntegerField(default=0, help_text='Display order')
    is_required = models.BooleanField(default=True)
    is_active = models.BooleanField(default=True)
    target_user_types = models.JSONField(
        default=list,
        blank=True,
        help_text='User types this step applies to (empty = all)'
    )
    
    class Meta:
        verbose_name = 'Onboarding Step'
        verbose_name_plural = 'Onboarding Steps'
        ordering = ['order', 'name']
    
    def __str__(self):
        return f"{self.name} - {self.get_step_type_display()}"


class UserOnboardingProgress(TimestampedModel):
    """User onboarding progress tracking"""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='onboarding_progress')
    current_step = models.ForeignKey(
        OnboardingStep,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='user_progresses'
    )
    completed_steps = models.JSONField(
        default=list,
        blank=True,
        help_text='List of completed step IDs'
    )
    skipped_steps = models.JSONField(
        default=list,
        blank=True,
        help_text='List of skipped step IDs'
    )
    progress_data = models.JSONField(
        default=dict,
        blank=True,
        help_text='User responses/data for each step'
    )
    is_completed = models.BooleanField(default=False)
    completed_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'User Onboarding Progress'
        verbose_name_plural = 'User Onboarding Progresses'
    
    def __str__(self):
        return f"{self.user.username} - Onboarding Progress"


# Alumni Network
class AlumniProfile(TimestampedModel):
    """Alumni profile extension"""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='alumni_profile')
    graduation_year = models.IntegerField()
    degree = models.CharField(max_length=200)
    major = models.CharField(max_length=200, blank=True, null=True)
    current_position = models.CharField(max_length=200, blank=True, null=True)
    current_company = models.CharField(max_length=200, blank=True, null=True)
    industry = models.CharField(max_length=100, blank=True, null=True)
    location = models.CharField(max_length=200, blank=True, null=True)
    bio = models.TextField(blank=True, null=True)
    linkedin_url = models.URLField(blank=True, null=True)
    website_url = models.URLField(blank=True, null=True)
    is_mentor = models.BooleanField(default=False)
    is_available_for_mentorship = models.BooleanField(default=False)
    mentorship_areas = models.JSONField(
        default=list,
        blank=True,
        help_text='Areas of expertise for mentorship'
    )
    is_verified = models.BooleanField(default=False)
    verified_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Alumni Profile'
        verbose_name_plural = 'Alumni Profiles'
    
    def __str__(self):
        return f"{self.user.username} - Alumni ({self.graduation_year})"


class MentorshipRequest(TimestampedModel):
    """Mentorship request model"""
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    request_id = models.CharField(max_length=20, unique=True)
    mentee = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='mentorship_requests_sent'
    )
    mentor = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='mentorship_requests_received',
        limit_choices_to={'alumni_profile__is_available_for_mentorship': True}
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    message = models.TextField()
    mentorship_areas = models.JSONField(
        default=list,
        blank=True,
        help_text='Areas of mentorship requested'
    )
    mentor_response = models.TextField(blank=True, null=True)
    started_at = models.DateTimeField(blank=True, null=True)
    completed_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Mentorship Request'
        verbose_name_plural = 'Mentorship Requests'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['request_id', 'status']),
            models.Index(fields=['mentee', 'status']),
            models.Index(fields=['mentor', 'status']),
        ]
    
    def __str__(self):
        return f"{self.request_id} - {self.mentee.username} to {self.mentor.username}"
    
    def save(self, *args, **kwargs):
        if not self.request_id:
            import uuid
            self.request_id = f"MENT-{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)


class AlumniEvent(TimestampedModel):
    """Alumni events and reunions"""
    
    EVENT_TYPES = [
        ('reunion', 'Reunion'),
        ('networking', 'Networking Event'),
        ('workshop', 'Workshop'),
        ('seminar', 'Seminar'),
        ('social', 'Social Gathering'),
        ('other', 'Other'),
    ]
    
    title = models.CharField(max_length=200)
    event_type = models.CharField(max_length=20, choices=EVENT_TYPES, default='networking')
    description = models.TextField()
    location = models.CharField(max_length=200, blank=True, null=True)
    start_date = models.DateTimeField()
    end_date = models.DateTimeField(blank=True, null=True)
    registration_deadline = models.DateTimeField(blank=True, null=True)
    max_attendees = models.IntegerField(blank=True, null=True)
    registration_url = models.URLField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_alumni_events'
    )
    
    class Meta:
        verbose_name = 'Alumni Event'
        verbose_name_plural = 'Alumni Events'
        ordering = ['-start_date']
    
    def __str__(self):
        return f"{self.title} - {self.start_date}"


# Placement Module
class PlacementOpportunity(TimestampedModel):
    """Job/internship placement opportunity"""
    
    OPPORTUNITY_TYPES = [
        ('full_time', 'Full Time'),
        ('part_time', 'Part Time'),
        ('internship', 'Internship'),
        ('contract', 'Contract'),
        ('freelance', 'Freelance'),
    ]
    
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('active', 'Active'),
        ('closed', 'Closed'),
        ('expired', 'Expired'),
    ]
    
    opportunity_id = models.CharField(max_length=20, unique=True)
    title = models.CharField(max_length=200)
    company_name = models.CharField(max_length=200)
    opportunity_type = models.CharField(max_length=20, choices=OPPORTUNITY_TYPES, default='full_time')
    description = models.TextField()
    requirements = models.TextField(blank=True, null=True)
    location = models.CharField(max_length=200, blank=True, null=True)
    is_remote = models.BooleanField(default=False)
    salary_range_min = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    salary_range_max = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    application_deadline = models.DateTimeField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    posted_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='posted_opportunities',
        limit_choices_to={'user_type__in': ['admin', 'faculty', 'staff']}
    )
    application_url = models.URLField(blank=True, null=True)
    contact_email = models.EmailField(blank=True, null=True)
    tags = models.JSONField(default=list, blank=True)
    views_count = models.IntegerField(default=0)
    applications_count = models.IntegerField(default=0)
    
    class Meta:
        verbose_name = 'Placement Opportunity'
        verbose_name_plural = 'Placement Opportunities'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['opportunity_id', 'status']),
            models.Index(fields=['opportunity_type', 'status']),
            models.Index(fields=['status', 'application_deadline']),
        ]
    
    def __str__(self):
        return f"{self.opportunity_id} - {self.title} at {self.company_name}"
    
    def save(self, *args, **kwargs):
        if not self.opportunity_id:
            import uuid
            self.opportunity_id = f"JOB-{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)


class PlacementApplication(TimestampedModel):
    """Job/internship application"""
    
    STATUS_CHOICES = [
        ('submitted', 'Submitted'),
        ('under_review', 'Under Review'),
        ('shortlisted', 'Shortlisted'),
        ('interview', 'Interview Scheduled'),
        ('offer', 'Offer Extended'),
        ('rejected', 'Rejected'),
        ('withdrawn', 'Withdrawn'),
    ]
    
    application_id = models.CharField(max_length=20, unique=True)
    opportunity = models.ForeignKey(PlacementOpportunity, on_delete=models.CASCADE, related_name='applications')
    applicant = models.ForeignKey(User, on_delete=models.CASCADE, related_name='placement_applications')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='submitted')
    cover_letter = models.TextField(blank=True, null=True)
    resume_url = models.URLField(blank=True, null=True)
    portfolio_url = models.URLField(blank=True, null=True)
    additional_documents = models.JSONField(
        default=list,
        blank=True,
        help_text='List of document URLs'
    )
    notes = models.TextField(blank=True, null=True)
    interview_date = models.DateTimeField(blank=True, null=True)
    interview_location = models.CharField(max_length=200, blank=True, null=True)
    offer_details = models.JSONField(
        default=dict,
        blank=True,
        help_text='Offer details if status is offer'
    )
    
    class Meta:
        verbose_name = 'Placement Application'
        verbose_name_plural = 'Placement Applications'
        unique_together = [['opportunity', 'applicant']]
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['application_id', 'status']),
            models.Index(fields=['applicant', 'status']),
            models.Index(fields=['opportunity', 'status']),
        ]
    
    def __str__(self):
        return f"{self.application_id} - {self.applicant.username} for {self.opportunity.title}"
    
    def save(self, *args, **kwargs):
        if not self.application_id:
            import uuid
            self.application_id = f"APP-{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)


class PlacementStatistic(TimestampedModel):
    """Placement statistics and analytics"""
    
    STAT_TYPES = [
        ('placement_rate', 'Placement Rate'),
        ('average_salary', 'Average Salary'),
        ('top_companies', 'Top Companies'),
        ('by_department', 'By Department'),
        ('by_degree', 'By Degree'),
    ]
    
    stat_type = models.CharField(max_length=50, choices=STAT_TYPES)
    period_start = models.DateTimeField()
    period_end = models.DateTimeField()
    value = models.JSONField(
        default=dict,
        help_text='Statistic value/data'
    )
    metadata = models.JSONField(
        default=dict,
        blank=True
    )
    
    class Meta:
        verbose_name = 'Placement Statistic'
        verbose_name_plural = 'Placement Statistics'
        ordering = ['-period_end']
    
    def __str__(self):
        return f"{self.get_stat_type_display()} - {self.period_end}"

















