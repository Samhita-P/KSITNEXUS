"""
FCM Token models for push notifications
"""

from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class FCMToken(models.Model):
    """FCM Token model for push notifications"""
    
    PLATFORM_CHOICES = [
        ('android', 'Android'),
        ('ios', 'iOS'),
        ('web', 'Web'),
        ('flutter', 'Flutter'),
    ]
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='fcm_tokens'
    )
    token = models.CharField(max_length=255, unique=True)
    platform = models.CharField(max_length=20, choices=PLATFORM_CHOICES)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_used = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'fcm_tokens'
        unique_together = ['user', 'token']
        indexes = [
            models.Index(fields=['user', 'is_active']),
            models.Index(fields=['platform', 'is_active']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.platform} - {self.token[:20]}..."


class PushNotification(models.Model):
    """Push notification model for tracking sent notifications"""
    
    NOTIFICATION_TYPES = [
        ('info', 'Information'),
        ('warning', 'Warning'),
        ('error', 'Error'),
        ('success', 'Success'),
        ('complaint', 'Complaint'),
        ('reservation', 'Reservation'),
        ('study_group', 'Study Group'),
        ('notice', 'Notice'),
        ('system', 'System'),
    ]
    
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('normal', 'Normal'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]
    
    title = models.CharField(max_length=255)
    body = models.TextField()
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='normal')
    
    # Target information
    target_users = models.ManyToManyField(User, blank=True)
    target_topic = models.CharField(max_length=100, blank=True, null=True)
    
    # FCM specific fields
    fcm_tokens = models.ManyToManyField(FCMToken, blank=True)
    data = models.JSONField(default=dict, blank=True)
    
    # Status tracking
    status = models.CharField(
        max_length=20,
        choices=[
            ('pending', 'Pending'),
            ('sending', 'Sending'),
            ('sent', 'Sent'),
            ('failed', 'Failed'),
            ('cancelled', 'Cancelled'),
        ],
        default='pending'
    )
    
    # Timestamps
    scheduled_at = models.DateTimeField(null=True, blank=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Error tracking
    error_message = models.TextField(blank=True, null=True)
    retry_count = models.PositiveIntegerField(default=0)
    max_retries = models.PositiveIntegerField(default=3)
    
    class Meta:
        db_table = 'push_notifications'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'scheduled_at']),
            models.Index(fields=['notification_type', 'status']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.title} - {self.get_status_display()}"
    
    def can_retry(self):
        """Check if notification can be retried"""
        return self.retry_count < self.max_retries and self.status in ['failed', 'pending']
    
    def mark_as_sent(self):
        """Mark notification as sent"""
        from django.utils import timezone
        self.status = 'sent'
        self.sent_at = timezone.now()
        self.save(update_fields=['status', 'sent_at'])
    
    def mark_as_failed(self, error_message=None):
        """Mark notification as failed"""
        self.status = 'failed'
        self.retry_count += 1
        if error_message:
            self.error_message = error_message
        self.save(update_fields=['status', 'retry_count', 'error_message'])


class FCMNotificationTemplate(models.Model):
    """Template for push notifications"""
    
    name = models.CharField(max_length=100, unique=True)
    title_template = models.CharField(max_length=255)
    body_template = models.TextField()
    notification_type = models.CharField(max_length=20, choices=PushNotification.NOTIFICATION_TYPES)
    priority = models.CharField(max_length=10, choices=PushNotification.PRIORITY_CHOICES, default='normal')
    
    # Template variables
    variables = models.JSONField(default=list, blank=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'notification_templates'
        ordering = ['name']
    
    def __str__(self):
        return self.name
    
    def render(self, context=None):
        """Render template with context"""
        if context is None:
            context = {}
        
        title = self.title_template
        body = self.body_template
        
        for key, value in context.items():
            title = title.replace(f'{{{key}}}', str(value))
            body = body.replace(f'{{{key}}}', str(value))
        
        return {
            'title': title,
            'body': body,
            'notification_type': self.notification_type,
            'priority': self.priority,
        }
