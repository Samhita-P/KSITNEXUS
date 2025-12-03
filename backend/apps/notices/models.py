"""
Notices and Announcements models for KSIT Nexus
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()


class Notice(models.Model):
    """Digital notice board model"""
    
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]
    
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('published', 'Published'),
        ('archived', 'Archived'),
    ]
    
    VISIBILITY_CHOICES = [
        ('all', 'All Users'),
        ('students', 'Students Only'),
        ('faculty', 'Faculty Only'),
        ('specific_branch', 'Specific Branch'),
        ('specific_year', 'Specific Year'),
    ]
    
    title = models.CharField(max_length=300)
    content = models.TextField()
    summary = models.TextField(blank=True, null=True)
    
    # Notice settings
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='draft')
    visibility = models.CharField(max_length=20, choices=VISIBILITY_CHOICES, default='all')
    
    # Targeting
    target_branches = models.JSONField(default=list, blank=True, null=False)  # List of branch names
    target_years = models.JSONField(default=list, blank=True, null=False)  # List of years
    
    # Author and approval
    author = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='authored_notices',
        limit_choices_to={'user_type': 'faculty'}
    )
    approved_by = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='approved_notices',
        limit_choices_to={'user_type': 'admin'}
    )
    
    # Attachments
    attachment = models.FileField(upload_to='notice_attachments/', blank=True, null=True)
    attachment_name = models.CharField(max_length=255, blank=True, null=True)
    
    # Scheduling
    publish_at = models.DateTimeField(blank=True, null=True)
    expires_at = models.DateTimeField(blank=True, null=True)
    
    # Metadata
    view_count = models.IntegerField(default=0, null=False, blank=False)
    is_pinned = models.BooleanField(default=False)
    tags = models.JSONField(default=list, blank=True, null=False)  # List of tags
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    published_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        ordering = ['-is_pinned', '-published_at', '-created_at']
    
    def __str__(self):
        return f"{self.title} - {self.get_status_display()}"
    
    @property
    def is_published(self):
        return self.status == 'published' and (
            not self.publish_at or self.publish_at <= timezone.now()
        )
    
    @property
    def is_expired(self):
        return self.expires_at and self.expires_at <= timezone.now()
    
    def save(self, *args, **kwargs):
        if self.status == 'published' and not self.published_at:
            self.published_at = timezone.now()
        
        # Ensure view_count is never None
        if self.view_count is None:
            self.view_count = 0
            
        super().save(*args, **kwargs)


class Announcement(models.Model):
    """Faculty-posted announcements with priority"""
    
    PRIORITY_CHOICES = [
        ('normal', 'Normal'),
        ('important', 'Important'),
        ('urgent', 'Urgent'),
        ('critical', 'Critical'),
    ]
    
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('active', 'Active'),
        ('inactive', 'Inactive'),
    ]
    
    title = models.CharField(max_length=300)
    message = models.TextField()
    priority = models.CharField(max_length=15, choices=PRIORITY_CHOICES, default='normal')
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='draft')
    
    # Author
    author = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='announcements',
        limit_choices_to={'user_type': 'faculty'}
    )
    
    # Targeting
    target_audience = models.CharField(max_length=50, default='all')  # all, students, faculty, specific
    target_details = models.JSONField(default=dict, blank=True, null=False)  # Additional targeting info
    
    # Display settings
    show_until = models.DateTimeField(blank=True, null=True)
    is_sticky = models.BooleanField(default=False)  # Always show at top
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    activated_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        ordering = ['-is_sticky', '-priority', '-created_at']
    
    def __str__(self):
        return f"{self.title} - {self.get_priority_display()}"
    
    @property
    def is_active(self):
        return (
            self.status == 'active' and 
            (not self.show_until or self.show_until > timezone.now())
        )
    
    def save(self, *args, **kwargs):
        if self.status == 'active' and not self.activated_at:
            self.activated_at = timezone.now()
        super().save(*args, **kwargs)


class NoticeView(models.Model):
    """Track notice views for analytics"""
    
    notice = models.ForeignKey(Notice, on_delete=models.CASCADE, related_name='views')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notice_views')
    viewed_at = models.DateTimeField(auto_now_add=True)
    ip_address = models.GenericIPAddressField(blank=True, null=True)
    
    class Meta:
        unique_together = ['notice', 'user']
        ordering = ['-viewed_at']
    
    def __str__(self):
        return f"{self.user.username} viewed {self.notice.title}"