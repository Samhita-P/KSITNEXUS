"""
Study Groups models for KSIT Nexus
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()


class StudyGroup(models.Model):
    """Study group model"""
    
    SUBJECT_CHOICES = [
        ('mathematics', 'Mathematics'),
        ('physics', 'Physics'),
        ('chemistry', 'Chemistry'),
        ('computer_science', 'Computer Science'),
        ('electronics', 'Electronics'),
        ('mechanical', 'Mechanical'),
        ('civil', 'Civil'),
        ('electrical', 'Electrical'),
        ('other', 'Other'),
    ]
    
    DIFFICULTY_CHOICES = [
        ('beginner', 'Beginner'),
        ('intermediate', 'Intermediate'),
        ('advanced', 'Advanced'),
    ]
    
    name = models.CharField(max_length=200)
    description = models.TextField()
    subject = models.CharField(max_length=20, choices=SUBJECT_CHOICES)
    difficulty_level = models.CharField(max_length=15, choices=DIFFICULTY_CHOICES)
    
    # Group settings
    max_members = models.IntegerField(default=10)
    is_public = models.BooleanField(default=True)
    is_active = models.BooleanField(default=True)
    
    # Moderation fields
    is_reported = models.BooleanField(default=False)
    reported_by = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='reported_study_groups'
    )
    reported_at = models.DateTimeField(null=True, blank=True)
    report_reason = models.TextField(blank=True, null=True)
    status = models.CharField(
        max_length=20, 
        choices=[
            ('active', 'Active'),
            ('reported', 'Reported'),
            ('closed', 'Closed'),
            ('suspended', 'Suspended'),
        ],
        default='active'
    )
    
    # Creator and admin
    creator = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='created_study_groups'
    )
    
    # Group metadata
    tags = models.JSONField(default=list, blank=True)  # List of tags
    meeting_schedule = models.CharField(max_length=200, blank=True, null=True)
    meeting_location = models.CharField(max_length=200, blank=True, null=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.name} - {self.get_subject_display()}"
    
    @property
    def current_member_count(self):
        return self.members.filter(is_active=True).count()
    
    @property
    def is_full(self):
        return self.current_member_count >= self.max_members


class GroupMembership(models.Model):
    """Study group membership model"""
    
    ROLE_CHOICES = [
        ('member', 'Member'),
        ('admin', 'Admin'),
        ('moderator', 'Moderator'),
    ]
    
    group = models.ForeignKey(StudyGroup, on_delete=models.CASCADE, related_name='members')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='study_group_memberships')
    role = models.CharField(max_length=15, choices=ROLE_CHOICES, default='member')
    is_active = models.BooleanField(default=True)
    joined_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['group', 'user']
        ordering = ['-joined_at']
    
    def __str__(self):
        return f"{self.user.username} in {self.group.name}"


class GroupReport(models.Model):
    """Study group report model for faculty moderation"""
    
    group = models.ForeignKey(StudyGroup, on_delete=models.CASCADE, related_name='reports')
    reported_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='group_reports')
    issue_description = models.TextField()
    content_to_remove = models.TextField(blank=True, null=True)
    warning_message = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    is_resolved = models.BooleanField(default=False)
    resolved_by = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='resolved_group_reports'
    )
    resolved_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Report for {self.group.name} by {self.reported_by.username}"


class GroupJoinRequest(models.Model):
    """Group join request model for private groups"""
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]
    
    group = models.ForeignKey(StudyGroup, on_delete=models.CASCADE, related_name='join_requests')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='group_join_requests')
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    message = models.TextField(blank=True, null=True)  # Optional message from user
    requested_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    reviewed_by = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='reviewed_join_requests'
    )
    
    class Meta:
        unique_together = ['group', 'user']
        ordering = ['-requested_at']
    
    def __str__(self):
        return f"{self.user.username} wants to join {self.group.name}"


class GroupMessage(models.Model):
    """WhatsApp-style group messages"""
    
    MESSAGE_TYPES = [
        ('text', 'Text'),
        ('image', 'Image'),
        ('file', 'File'),
        ('link', 'Link'),
    ]
    
    group = models.ForeignKey(StudyGroup, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='group_messages')
    message_type = models.CharField(max_length=10, choices=MESSAGE_TYPES, default='text')
    content = models.TextField()
    
    # File attachments
    attachment = models.FileField(upload_to='group_attachments/', blank=True, null=True)
    attachment_name = models.CharField(max_length=255, blank=True, null=True)
    
    # Message metadata
    is_edited = models.BooleanField(default=False)
    edited_at = models.DateTimeField(blank=True, null=True)
    reply_to = models.ForeignKey('self', on_delete=models.CASCADE, blank=True, null=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        return f"Message in {self.group.name} by {self.sender.username}"


class Resource(models.Model):
    """Study resources shared in groups"""
    
    RESOURCE_TYPES = [
        ('document', 'Document'),
        ('video', 'Video'),
        ('link', 'Link'),
        ('image', 'Image'),
        ('other', 'Other'),
    ]
    
    CATEGORY_CHOICES = [
        ('lecture_notes', 'Lecture Notes'),
        ('assignment', 'Assignment'),
        ('exam_material', 'Exam Material'),
        ('reference', 'Reference'),
        ('other', 'Other'),
    ]
    
    group = models.ForeignKey(StudyGroup, on_delete=models.CASCADE, related_name='resources')
    uploaded_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='uploaded_resources')
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    resource_type = models.CharField(max_length=15, choices=RESOURCE_TYPES)
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, blank=True, null=True)
    
    # File or link
    file = models.FileField(upload_to='group_resources/', blank=True, null=True)
    external_url = models.URLField(blank=True, null=True)
    
    # Metadata
    file_size = models.IntegerField(blank=True, null=True)
    download_count = models.IntegerField(default=0)
    is_pinned = models.BooleanField(default=False)
    
    # Timestamps
    uploaded_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-uploaded_at']
    
    def __str__(self):
        return f"{self.title} in {self.group.name}"


class UpcomingEvent(models.Model):
    """Events created by group members"""
    
    EVENT_TYPES = [
        ('study_session', 'Study Session'),
        ('exam_prep', 'Exam Preparation'),
        ('project_meeting', 'Project Meeting'),
        ('discussion', 'Discussion'),
        ('other', 'Other'),
    ]
    
    group = models.ForeignKey(StudyGroup, on_delete=models.CASCADE, related_name='events')
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_events')
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    event_type = models.CharField(max_length=20, choices=EVENT_TYPES)
    
    # Event details
    start_time = models.DateTimeField()
    end_time = models.DateTimeField(blank=True, null=True)
    location = models.CharField(max_length=200, blank=True, null=True)
    meeting_link = models.URLField(blank=True, null=True)
    
    # Event settings
    max_attendees = models.IntegerField(blank=True, null=True)
    is_recurring = models.BooleanField(default=False)
    recurring_pattern = models.CharField(max_length=50, blank=True, null=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['start_time']
    
    def __str__(self):
        return f"{self.title} - {self.group.name}"
    
    @property
    def is_upcoming(self):
        return self.start_time > timezone.now()
    
    @property
    def is_ongoing(self):
        now = timezone.now()
        return self.start_time <= now <= self.end_time