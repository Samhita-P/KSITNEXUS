"""
Notification digest models for KSIT Nexus
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import datetime, timedelta

User = get_user_model()


# Forward reference to avoid circular import
def get_notification_model():
    from .models import Notification
    return Notification


class NotificationDigest(models.Model):
    """Notification digest for grouping notifications"""
    
    FREQUENCY_CHOICES = [
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('never', 'Never'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notification_digests')
    frequency = models.CharField(max_length=20, choices=FREQUENCY_CHOICES, default='daily')
    
    # Digest period
    period_start = models.DateTimeField()
    period_end = models.DateTimeField()
    
    # Digest content
    title = models.CharField(max_length=200)
    summary = models.TextField(blank=True)  # AI-generated summary
    notifications = models.ManyToManyField('Notification', related_name='digests')
    
    # Digest status
    is_sent = models.BooleanField(default=False)
    sent_at = models.DateTimeField(blank=True, null=True)
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(blank=True, null=True)
    
    # Statistics
    notification_count = models.PositiveIntegerField(default=0)
    unread_count = models.PositiveIntegerField(default=0)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['user', 'is_sent', '-created_at']),
        ]
    
    def __str__(self):
        return f"Digest for {self.user.username} - {self.period_start.date()} to {self.period_end.date()}"
    
    def mark_as_read(self):
        """Mark digest as read"""
        self.is_read = True
        self.read_at = timezone.now()
        self.save(update_fields=['is_read', 'read_at', 'updated_at'])
    
    def mark_as_sent(self):
        """Mark digest as sent"""
        self.is_sent = True
        self.sent_at = timezone.now()
        self.save(update_fields=['is_sent', 'sent_at', 'updated_at'])
    
    @property
    def notification_list(self):
        """Get list of notifications in this digest"""
        return self.notifications.all()


class NotificationTier(models.Model):
    """Notification tier for categorizing notifications"""
    
    TIER_CHOICES = [
        ('essential', 'Essential'),
        ('important', 'Important'),
        ('optional', 'Optional'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notification_tiers')
    tier = models.CharField(max_length=20, choices=TIER_CHOICES, default='important')
    
    # Notification type mapping
    notification_types = models.JSONField(default=list, blank=True)  # List of notification types for this tier
    
    # Tier settings
    push_enabled = models.BooleanField(default=True)
    email_enabled = models.BooleanField(default=True)
    sms_enabled = models.BooleanField(default=False)
    in_app_enabled = models.BooleanField(default=True)
    
    # Escalation rules
    escalation_enabled = models.BooleanField(default=False)
    escalation_delay_minutes = models.PositiveIntegerField(default=60)  # Escalate after X minutes if not read
    escalate_to_tier = models.CharField(max_length=20, choices=TIER_CHOICES, blank=True, null=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = [['user', 'tier']]
        ordering = ['user', 'tier']
    
    def __str__(self):
        return f"{self.user.username} - {self.get_tier_display()}"


class NotificationSummary(models.Model):
    """AI-generated summary for notifications"""
    
    notification = models.OneToOneField('Notification', on_delete=models.CASCADE, related_name='summary')
    summary_text = models.TextField()
    summary_type = models.CharField(max_length=20, default='short')  # short, medium, long
    
    # AI metadata
    model_used = models.CharField(max_length=100, blank=True)
    confidence_score = models.FloatField(default=0.0)
    generated_at = models.DateTimeField(auto_now_add=True)
    
    # Quality metrics
    word_count = models.PositiveIntegerField(default=0)
    key_points = models.JSONField(default=list, blank=True)  # List of key points extracted
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Summary for {self.notification.title}"


class NotificationPriorityRule(models.Model):
    """Priority rules for notifications"""
    
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='priority_rules', blank=True, null=True)
    is_global = models.BooleanField(default=False)  # Global rule applies to all users
    
    # Rule conditions
    notification_type = models.CharField(max_length=20, blank=True, null=True)
    keyword = models.CharField(max_length=100, blank=True, null=True)
    sender = models.CharField(max_length=100, blank=True, null=True)  # For user-to-user notifications
    
    # Rule action
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    auto_escalate = models.BooleanField(default=False)
    escalation_minutes = models.PositiveIntegerField(default=30)
    
    # Rule status
    is_active = models.BooleanField(default=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-is_active', 'priority', '-created_at']
    
    def __str__(self):
        rule_type = "Global" if self.is_global else f"User: {self.user.username}"
        return f"{rule_type} - {self.notification_type or 'All'} -> {self.priority}"

