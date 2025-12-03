"""
Faculty & Admin Tools models for KSIT Nexus
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator
from apps.shared.models.base import TimestampedModel

User = get_user_model()


# Enhanced Case Management
class Case(TimestampedModel):
    """Enhanced case management model (extends complaints)"""
    
    CASE_TYPES = [
        ('complaint', 'Complaint'),
        ('support', 'Support Request'),
        ('incident', 'Incident Report'),
        ('request', 'General Request'),
        ('feedback', 'Feedback Case'),
    ]
    
    PRIORITY_LEVELS = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
        ('critical', 'Critical'),
    ]
    
    STATUS_CHOICES = [
        ('new', 'New'),
        ('assigned', 'Assigned'),
        ('in_progress', 'In Progress'),
        ('pending', 'Pending'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
        ('escalated', 'Escalated'),
    ]
    
    # Case identification
    case_id = models.CharField(max_length=20, unique=True)
    case_type = models.CharField(max_length=20, choices=CASE_TYPES, default='complaint')
    title = models.CharField(max_length=200)
    description = models.TextField()
    
    # Assignment
    assigned_to = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_cases',
        limit_choices_to={'user_type__in': ['faculty', 'admin']}
    )
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_cases'
    )
    
    # Status and priority
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='new')
    priority = models.CharField(max_length=20, choices=PRIORITY_LEVELS, default='medium')
    priority_score = models.IntegerField(default=0, help_text='Calculated priority score')
    
    # SLA tracking
    sla_target_hours = models.IntegerField(
        default=48,
        help_text='Target resolution time in hours'
    )
    sla_start_time = models.DateTimeField(auto_now_add=True)
    sla_breach_time = models.DateTimeField(blank=True, null=True)
    sla_status = models.CharField(
        max_length=20,
        choices=[('on_time', 'On Time'), ('at_risk', 'At Risk'), ('breached', 'Breached')],
        default='on_time'
    )
    
    # Tags and categorization
    tags = models.JSONField(
        default=list,
        blank=True,
        help_text='List of tags for categorization'
    )
    category = models.CharField(max_length=50, blank=True, null=True)
    department = models.CharField(max_length=100, blank=True, null=True)
    
    # Resolution
    resolved_at = models.DateTimeField(blank=True, null=True)
    resolution_notes = models.TextField(blank=True, null=True)
    resolution_time_hours = models.FloatField(blank=True, null=True)
    
    # Analytics
    views_count = models.IntegerField(default=0)
    updates_count = models.IntegerField(default=0)
    response_time_minutes = models.IntegerField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Case'
        verbose_name_plural = 'Cases'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['case_id']),
            models.Index(fields=['status', 'priority']),
            models.Index(fields=['assigned_to', 'status']),
            models.Index(fields=['sla_status', 'sla_breach_time']),
        ]
    
    def __str__(self):
        return f"{self.case_id} - {self.title}"
    
    def save(self, *args, **kwargs):
        if not self.case_id:
            import uuid
            self.case_id = f"CASE-{uuid.uuid4().hex[:8].upper()}"
        
        # Calculate SLA breach time
        if self.sla_start_time and self.sla_target_hours:
            from datetime import timedelta
            self.sla_breach_time = self.sla_start_time + timedelta(hours=self.sla_target_hours)
        
        # Update SLA status
        if self.sla_breach_time:
            now = timezone.now()
            if now > self.sla_breach_time and self.status not in ['resolved', 'closed']:
                self.sla_status = 'breached'
            elif (self.sla_breach_time - now).total_seconds() < 3600 * 4:  # 4 hours before breach
                self.sla_status = 'at_risk'
            else:
                self.sla_status = 'on_time'
        
        super().save(*args, **kwargs)


class CaseTag(TimestampedModel):
    """Predefined tags for case management"""
    
    name = models.CharField(max_length=50, unique=True)
    color = models.CharField(max_length=7, default='#3b82f6')
    description = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    
    class Meta:
        verbose_name = 'Case Tag'
        verbose_name_plural = 'Case Tags'
        ordering = ['name']
    
    def __str__(self):
        return self.name


class CaseUpdate(TimestampedModel):
    """Case update/comment model"""
    
    case = models.ForeignKey(Case, on_delete=models.CASCADE, related_name='updates')
    updated_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='case_updates')
    comment = models.TextField()
    is_internal = models.BooleanField(
        default=False,
        help_text='Internal notes not visible to case creator'
    )
    status_change = models.CharField(max_length=20, blank=True, null=True)
    priority_change = models.CharField(max_length=20, blank=True, null=True)
    
    class Meta:
        verbose_name = 'Case Update'
        verbose_name_plural = 'Case Updates'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Update for {self.case.case_id}"


# Broadcast Studio
class Broadcast(TimestampedModel):
    """Rich announcement/broadcast model"""
    
    BROADCAST_TYPES = [
        ('announcement', 'Announcement'),
        ('event', 'Event'),
        ('alert', 'Alert'),
        ('news', 'News'),
        ('maintenance', 'Maintenance'),
    ]
    
    PRIORITY_LEVELS = [
        ('normal', 'Normal'),
        ('important', 'Important'),
        ('urgent', 'Urgent'),
        ('critical', 'Critical'),
    ]
    
    TARGET_AUDIENCES = [
        ('all', 'All Users'),
        ('students', 'Students Only'),
        ('faculty', 'Faculty Only'),
        ('staff', 'Staff Only'),
        ('specific', 'Specific Users/Groups'),
    ]
    
    # Basic information
    title = models.CharField(max_length=200)
    content = models.TextField()
    broadcast_type = models.CharField(max_length=20, choices=BROADCAST_TYPES, default='announcement')
    priority = models.CharField(max_length=20, choices=PRIORITY_LEVELS, default='normal')
    
    # Rich content
    rich_content = models.JSONField(
        default=dict,
        blank=True,
        help_text='Rich content (images, videos, links, formatting)'
    )
    attachments = models.JSONField(
        default=list,
        blank=True,
        help_text='List of attachment URLs'
    )
    
    # Targeting
    target_audience = models.CharField(max_length=20, choices=TARGET_AUDIENCES, default='all')
    target_users = models.ManyToManyField(
        User,
        blank=True,
        related_name='targeted_broadcasts',
        help_text='Specific users for targeted broadcasts'
    )
    target_departments = models.JSONField(
        default=list,
        blank=True,
        help_text='List of department names'
    )
    target_courses = models.JSONField(
        default=list,
        blank=True,
        help_text='List of course codes'
    )
    
    # Scheduling
    scheduled_at = models.DateTimeField(blank=True, null=True)
    expires_at = models.DateTimeField(blank=True, null=True)
    is_published = models.BooleanField(default=False)
    published_at = models.DateTimeField(blank=True, null=True)
    
    # Creator
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_broadcasts',
        limit_choices_to={'user_type__in': ['faculty', 'admin']}
    )
    
    # Analytics
    views_count = models.IntegerField(default=0)
    engagement_count = models.IntegerField(default=0)
    
    class Meta:
        verbose_name = 'Broadcast'
        verbose_name_plural = 'Broadcasts'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['broadcast_type', 'is_published']),
            models.Index(fields=['scheduled_at', 'is_published']),
            models.Index(fields=['created_by']),
        ]
    
    def __str__(self):
        return self.title


class BroadcastEngagement(TimestampedModel):
    """Track user engagement with broadcasts"""
    
    broadcast = models.ForeignKey(Broadcast, on_delete=models.CASCADE, related_name='engagements')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='broadcast_engagements')
    viewed_at = models.DateTimeField(blank=True, null=True)
    clicked_at = models.DateTimeField(blank=True, null=True)
    shared = models.BooleanField(default=False)
    
    class Meta:
        verbose_name = 'Broadcast Engagement'
        verbose_name_plural = 'Broadcast Engagements'
        unique_together = [['broadcast', 'user']]
        indexes = [
            models.Index(fields=['broadcast', 'user']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.broadcast.title}"


# Predictive Operations
class PredictiveMetric(TimestampedModel):
    """Predictive analytics metrics"""
    
    METRIC_TYPES = [
        ('complaint_volume', 'Complaint Volume'),
        ('response_time', 'Response Time'),
        ('resolution_rate', 'Resolution Rate'),
        ('sla_breach', 'SLA Breach'),
        ('engagement', 'Engagement'),
        ('resource_utilization', 'Resource Utilization'),
    ]
    
    metric_type = models.CharField(max_length=50, choices=METRIC_TYPES)
    value = models.FloatField()
    predicted_value = models.FloatField(blank=True, null=True)
    confidence = models.FloatField(
        blank=True,
        null=True,
        validators=[MinValueValidator(0), MaxValueValidator(1)],
        help_text='Prediction confidence (0-1)'
    )
    
    # Time period
    period_start = models.DateTimeField()
    period_end = models.DateTimeField()
    
    # Metadata
    metadata = models.JSONField(default=dict, blank=True)
    
    class Meta:
        verbose_name = 'Predictive Metric'
        verbose_name_plural = 'Predictive Metrics'
        ordering = ['-period_end']
        indexes = [
            models.Index(fields=['metric_type', 'period_end']),
        ]
    
    def __str__(self):
        return f"{self.get_metric_type_display()} - {self.period_end}"


class OperationalAlert(TimestampedModel):
    """Operational alerts based on predictions"""
    
    ALERT_TYPES = [
        ('sla_risk', 'SLA Risk'),
        ('high_volume', 'High Volume'),
        ('resource_shortage', 'Resource Shortage'),
        ('trend_anomaly', 'Trend Anomaly'),
        ('performance_degradation', 'Performance Degradation'),
    ]
    
    SEVERITY_LEVELS = [
        ('info', 'Info'),
        ('warning', 'Warning'),
        ('critical', 'Critical'),
    ]
    
    alert_type = models.CharField(max_length=50, choices=ALERT_TYPES)
    severity = models.CharField(max_length=20, choices=SEVERITY_LEVELS, default='info')
    title = models.CharField(max_length=200)
    message = models.TextField()
    
    # Related data
    related_metric = models.ForeignKey(
        PredictiveMetric,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='alerts'
    )
    related_case = models.ForeignKey(
        Case,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='alerts'
    )
    
    # Status
    is_acknowledged = models.BooleanField(default=False)
    acknowledged_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='acknowledged_alerts'
    )
    acknowledged_at = models.DateTimeField(blank=True, null=True)
    is_resolved = models.BooleanField(default=False)
    resolved_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Operational Alert'
        verbose_name_plural = 'Operational Alerts'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['alert_type', 'severity', 'is_acknowledged']),
            models.Index(fields=['is_acknowledged', 'is_resolved']),
        ]
    
    def __str__(self):
        return f"{self.get_alert_type_display()} - {self.title}"

