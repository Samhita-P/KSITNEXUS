"""
Notification models for KSIT Nexus
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()


class NotificationPreference(models.Model):
    """User notification preferences"""
    
    NOTIFICATION_TYPES = [
        ('push', 'Push Notification'),
        ('email', 'Email'),
        ('sms', 'SMS'),
        ('in_app', 'In-App'),
    ]
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='notification_preferences')
    
    # Notification channels
    push_enabled = models.BooleanField(default=True)
    email_enabled = models.BooleanField(default=True)
    sms_enabled = models.BooleanField(default=False)
    in_app_enabled = models.BooleanField(default=True)
    
    # Notification categories
    complaint_updates = models.BooleanField(default=True)
    study_group_messages = models.BooleanField(default=True)
    new_notices = models.BooleanField(default=True)
    reservation_reminders = models.BooleanField(default=True)
    feedback_requests = models.BooleanField(default=True)
    general_announcements = models.BooleanField(default=True)
    
    # Timing preferences
    quiet_hours_start = models.TimeField(blank=True, null=True)
    quiet_hours_end = models.TimeField(blank=True, null=True)
    timezone = models.CharField(max_length=50, default='Asia/Kolkata')
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Notification preferences for {self.user.username}"


class Notification(models.Model):
    """Notification model"""
    
    NOTIFICATION_TYPES = [
        ('complaint', 'Complaint Update'),
        ('study_group', 'Study Group'),
        ('notice', 'Notice'),
        ('reservation', 'Reservation'),
        ('feedback', 'Feedback'),
        ('announcement', 'Announcement'),
        ('general', 'General'),
    ]
    
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    
    # Content
    title = models.CharField(max_length=200)
    message = models.TextField()
    data = models.JSONField(default=dict, blank=True)  # Additional data for the notification
    
    # Delivery status
    is_read = models.BooleanField(default=False)
    is_sent = models.BooleanField(default=False)
    sent_at = models.DateTimeField(blank=True, null=True)
    
    # Delivery channels
    push_sent = models.BooleanField(default=False)
    email_sent = models.BooleanField(default=False)
    sms_sent = models.BooleanField(default=False)
    
    # Related objects (optional)
    related_object_type = models.CharField(max_length=50, blank=True, null=True)
    related_object_id = models.PositiveIntegerField(blank=True, null=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    expires_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.title} - {self.user.username}"
    
    @property
    def is_expired(self):
        return self.expires_at and self.expires_at <= timezone.now()
    
    def mark_as_read(self):
        """Mark notification as read"""
        self.is_read = True
        self.save(update_fields=['is_read', 'updated_at'])
    
    def mark_as_sent(self, channel=None):
        """Mark notification as sent for specific channel"""
        if channel == 'push':
            self.push_sent = True
        elif channel == 'email':
            self.email_sent = True
        elif channel == 'sms':
            self.sms_sent = True
        
        if not self.is_sent and (self.push_sent or self.email_sent or self.sms_sent):
            self.is_sent = True
            self.sent_at = timezone.now()
        
        self.save()


class NotificationTemplate(models.Model):
    """Notification templates for different types"""
    
    name = models.CharField(max_length=100, unique=True)
    notification_type = models.CharField(max_length=20, choices=Notification.NOTIFICATION_TYPES)
    title_template = models.CharField(max_length=200)
    message_template = models.TextField()
    
    # Template variables
    variables = models.JSONField(default=list, blank=True)  # List of available variables
    
    # Settings
    is_active = models.BooleanField(default=True)
    priority = models.CharField(max_length=10, choices=Notification.PRIORITY_CHOICES, default='medium')
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.name} - {self.get_notification_type_display()}"
    
    def render(self, context):
        """Render template with context variables"""
        title = self.title_template
        message = self.message_template
        
        for key, value in context.items():
            title = title.replace(f'{{{key}}}', str(value))
            message = message.replace(f'{{{key}}}', str(value))
        
        return title, message


class NotificationLog(models.Model):
    """Log notification delivery attempts"""
    
    notification = models.ForeignKey(Notification, on_delete=models.CASCADE, related_name='logs')
    channel = models.CharField(max_length=20, choices=NotificationPreference.NOTIFICATION_TYPES)
    status = models.CharField(max_length=20)  # sent, failed, pending
    error_message = models.TextField(blank=True, null=True)
    response_data = models.JSONField(default=dict, blank=True)
    attempted_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-attempted_at']
    
    def __str__(self):
        return f"{self.notification.title} - {self.channel} - {self.status}"
