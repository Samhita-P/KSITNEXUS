"""
Safety & Wellbeing models for KSIT Nexus
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator
from apps.shared.models.base import TimestampedModel

User = get_user_model()


# Emergency Mode
class EmergencyAlert(TimestampedModel):
    """Emergency alert model"""
    
    ALERT_TYPES = [
        ('medical', 'Medical Emergency'),
        ('security', 'Security Threat'),
        ('fire', 'Fire'),
        ('natural_disaster', 'Natural Disaster'),
        ('other', 'Other'),
    ]
    
    SEVERITY_LEVELS = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    ]
    
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('resolved', 'Resolved'),
        ('cancelled', 'Cancelled'),
    ]
    
    # Alert identification
    alert_id = models.CharField(max_length=20, unique=True)
    alert_type = models.CharField(max_length=20, choices=ALERT_TYPES)
    severity = models.CharField(max_length=20, choices=SEVERITY_LEVELS, default='high')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    
    # Alert details
    title = models.CharField(max_length=200)
    description = models.TextField()
    location = models.CharField(max_length=200, blank=True, null=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    
    # Creator
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_emergency_alerts'
    )
    
    # Response
    responded_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='responded_emergency_alerts',
        limit_choices_to={'user_type__in': ['faculty', 'admin', 'staff']}
    )
    response_notes = models.TextField(blank=True, null=True)
    resolved_at = models.DateTimeField(blank=True, null=True)
    
    # Broadcasting
    broadcast_to_all = models.BooleanField(default=True)
    target_departments = models.JSONField(default=list, blank=True)
    target_buildings = models.JSONField(default=list, blank=True)
    
    # Personal emergency contacts to notify
    notify_contacts = models.ManyToManyField(
        'UserPersonalEmergencyContact',
        related_name='alerts',
        blank=True,
        help_text='Personal emergency contacts to notify about this alert'
    )
    
    # Tracking
    views_count = models.IntegerField(default=0)
    acknowledgments_count = models.IntegerField(default=0)
    
    class Meta:
        verbose_name = 'Emergency Alert'
        verbose_name_plural = 'Emergency Alerts'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['alert_id', 'status']),
            models.Index(fields=['status', 'severity']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.alert_id} - {self.title}"
    
    def save(self, *args, **kwargs):
        if not self.alert_id:
            import uuid
            self.alert_id = f"EMRG-{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)


class EmergencyAcknowledgment(TimestampedModel):
    """User acknowledgment of emergency alerts"""
    
    alert = models.ForeignKey(EmergencyAlert, on_delete=models.CASCADE, related_name='acknowledgments')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='emergency_acknowledgments')
    acknowledged_at = models.DateTimeField(auto_now_add=True)
    location_latitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    location_longitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    is_safe = models.BooleanField(default=True)
    notes = models.TextField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Emergency Acknowledgment'
        verbose_name_plural = 'Emergency Acknowledgments'
        unique_together = [['alert', 'user']]
        indexes = [
            models.Index(fields=['alert', 'user']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.alert.alert_id}"


class EmergencyContact(TimestampedModel):
    """Emergency contact information"""
    
    CONTACT_TYPES = [
        ('security', 'Security'),
        ('medical', 'Medical'),
        ('fire', 'Fire Department'),
        ('police', 'Police'),
        ('campus_admin', 'Campus Administration'),
        ('other', 'Other'),
    ]
    
    name = models.CharField(max_length=200)
    contact_type = models.CharField(max_length=20, choices=CONTACT_TYPES)
    phone_number = models.CharField(max_length=20)
    alternate_phone = models.CharField(max_length=20, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    location = models.CharField(max_length=200, blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    priority = models.IntegerField(default=0, help_text='Display priority (higher = shown first)')
    
    class Meta:
        verbose_name = 'Emergency Contact'
        verbose_name_plural = 'Emergency Contacts'
        ordering = ['-priority', 'name']
    
    def __str__(self):
        return f"{self.name} - {self.get_contact_type_display()}"


class UserPersonalEmergencyContact(TimestampedModel):
    """User's personal emergency contacts"""
    
    CONTACT_TYPES = [
        ('family', 'Family'),
        ('friend', 'Friend'),
        ('guardian', 'Guardian'),
        ('colleague', 'Colleague'),
        ('other', 'Other'),
    ]
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='personal_emergency_contacts'
    )
    name = models.CharField(max_length=200)
    contact_type = models.CharField(max_length=20, choices=CONTACT_TYPES, default='other')
    phone_number = models.CharField(max_length=20)
    alternate_phone = models.CharField(max_length=20, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    relationship = models.CharField(max_length=100, blank=True, null=True, help_text='e.g., Mother, Father, Friend')
    is_primary = models.BooleanField(default=False, help_text='Primary contact to notify first')
    
    class Meta:
        verbose_name = 'Personal Emergency Contact'
        verbose_name_plural = 'Personal Emergency Contacts'
        ordering = ['-is_primary', 'name']
        unique_together = ['user', 'phone_number']
    
    def __str__(self):
        return f"{self.user.username} - {self.name} ({self.get_contact_type_display()})"


# Counseling Services
class CounselingService(TimestampedModel):
    """Counseling service model"""
    
    SERVICE_TYPES = [
        ('academic', 'Academic Counseling'),
        ('career', 'Career Counseling'),
        ('mental_health', 'Mental Health'),
        ('personal', 'Personal Counseling'),
        ('crisis', 'Crisis Support'),
        ('peer', 'Peer Support'),
    ]
    
    name = models.CharField(max_length=200)
    service_type = models.CharField(max_length=20, choices=SERVICE_TYPES)
    description = models.TextField()
    counselor_name = models.CharField(max_length=200, blank=True, null=True)
    counselor_email = models.EmailField(blank=True, null=True)
    counselor_phone = models.CharField(max_length=20, blank=True, null=True)
    location = models.CharField(max_length=200, blank=True, null=True)
    available_hours = models.JSONField(
        default=dict,
        blank=True,
        help_text='Available hours (e.g., {"monday": "9:00-17:00"})'
    )
    is_active = models.BooleanField(default=True)
    is_anonymous = models.BooleanField(
        default=False,
        help_text='Allow anonymous appointments'
    )
    
    class Meta:
        verbose_name = 'Counseling Service'
        verbose_name_plural = 'Counseling Services'
        ordering = ['service_type', 'name']
    
    def __str__(self):
        return f"{self.name} - {self.get_service_type_display()}"


class CounselingAppointment(TimestampedModel):
    """Counseling appointment model"""
    
    STATUS_CHOICES = [
        ('scheduled', 'Scheduled'),
        ('confirmed', 'Confirmed'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
        ('no_show', 'No Show'),
    ]
    
    URGENCY_LEVELS = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]
    
    # Appointment details
    appointment_id = models.CharField(max_length=20, unique=True)
    service = models.ForeignKey(CounselingService, on_delete=models.CASCADE, related_name='appointments')
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='counseling_appointments',
        null=True,
        blank=True
    )
    is_anonymous = models.BooleanField(default=False)
    
    # Scheduling
    scheduled_at = models.DateTimeField()
    duration_minutes = models.IntegerField(default=60, validators=[MinValueValidator(15)])
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='scheduled')
    urgency = models.CharField(max_length=20, choices=URGENCY_LEVELS, default='medium')
    
    # Contact information (for anonymous appointments)
    contact_email = models.EmailField(blank=True, null=True)
    contact_phone = models.CharField(max_length=20, blank=True, null=True)
    preferred_name = models.CharField(max_length=100, blank=True, null=True)
    
    # Appointment details
    reason = models.TextField(help_text='Reason for appointment')
    notes = models.TextField(blank=True, null=True, help_text='Additional notes')
    counselor_notes = models.TextField(
        blank=True,
        null=True,
        help_text='Counselor notes (not visible to user)'
    )
    
    # Completion
    completed_at = models.DateTimeField(blank=True, null=True)
    follow_up_required = models.BooleanField(default=False)
    follow_up_date = models.DateTimeField(blank=True, null=True)
    
    # Feedback
    rating = models.IntegerField(
        blank=True,
        null=True,
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text='User rating (1-5)'
    )
    feedback = models.TextField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Counseling Appointment'
        verbose_name_plural = 'Counseling Appointments'
        ordering = ['-scheduled_at']
        indexes = [
            models.Index(fields=['appointment_id', 'status']),
            models.Index(fields=['service', 'scheduled_at']),
            models.Index(fields=['user', 'scheduled_at']),
            models.Index(fields=['status', 'scheduled_at']),
        ]
    
    def __str__(self):
        return f"{self.appointment_id} - {self.service.name}"
    
    def save(self, *args, **kwargs):
        if not self.appointment_id:
            import uuid
            self.appointment_id = f"APT-{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)


class AnonymousCheckIn(TimestampedModel):
    """Anonymous check-in for mental health support"""
    
    CHECK_IN_TYPES = [
        ('wellness', 'Wellness Check'),
        ('stress', 'Stress Management'),
        ('anxiety', 'Anxiety Support'),
        ('depression', 'Depression Support'),
        ('crisis', 'Crisis Support'),
        ('other', 'Other'),
    ]
    
    MOOD_LEVELS = [
        (1, 'Very Low'),
        (2, 'Low'),
        (3, 'Neutral'),
        (4, 'Good'),
        (5, 'Very Good'),
    ]
    
    check_in_id = models.CharField(max_length=20, unique=True)
    check_in_type = models.CharField(max_length=20, choices=CHECK_IN_TYPES)
    mood_level = models.IntegerField(choices=MOOD_LEVELS, default=3)
    message = models.TextField(blank=True, null=True)
    
    # Optional contact (for follow-up)
    contact_email = models.EmailField(blank=True, null=True)
    contact_phone = models.CharField(max_length=20, blank=True, null=True)
    allow_follow_up = models.BooleanField(default=False)
    
    # Response
    responded_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='responded_check_ins',
        limit_choices_to={'user_type__in': ['faculty', 'admin', 'staff']}
    )
    response_notes = models.TextField(blank=True, null=True)
    response_sent_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Anonymous Check-In'
        verbose_name_plural = 'Anonymous Check-Ins'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['check_in_id']),
            models.Index(fields=['check_in_type', 'mood_level']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.check_in_id} - {self.get_check_in_type_display()}"
    
    def save(self, *args, **kwargs):
        if not self.check_in_id:
            import uuid
            self.check_in_id = f"CHK-{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)


class SafetyResource(TimestampedModel):
    """Safety and wellbeing resources"""
    
    RESOURCE_TYPES = [
        ('guide', 'Safety Guide'),
        ('video', 'Video Resource'),
        ('article', 'Article'),
        ('contact', 'Contact Information'),
        ('tool', 'Tool/App'),
        ('other', 'Other'),
    ]
    
    title = models.CharField(max_length=200)
    resource_type = models.CharField(max_length=20, choices=RESOURCE_TYPES)
    description = models.TextField()
    content = models.TextField(blank=True, null=True)
    url = models.URLField(blank=True, null=True)
    file = models.FileField(upload_to='safety_resources/', blank=True, null=True)
    tags = models.JSONField(default=list, blank=True)
    is_featured = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    views_count = models.IntegerField(default=0)
    
    class Meta:
        verbose_name = 'Safety Resource'
        verbose_name_plural = 'Safety Resources'
        ordering = ['-is_featured', 'title']
    
    def __str__(self):
        return self.title


