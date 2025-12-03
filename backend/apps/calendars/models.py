from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.shared.models.base import TimestampedModel

User = get_user_model()


class CalendarEvent(TimestampedModel):
    """Unified calendar event model for all event types"""
    
    EVENT_TYPES = [
        ('meeting', 'Meeting'),
        ('deadline', 'Deadline'),
        ('class', 'Class'),
        ('exam', 'Exam'),
        ('reminder', 'Reminder'),
        ('event', 'Event'),
        ('study_session', 'Study Session'),
        ('other', 'Other'),
    ]
    
    RECURRENCE_PATTERNS = [
        ('none', 'None'),
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('yearly', 'Yearly'),
    ]
    
    PRIVACY_LEVELS = [
        ('public', 'Public'),
        ('private', 'Private'),
        ('shared', 'Shared'),
    ]
    
    # Event basic information
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    event_type = models.CharField(max_length=20, choices=EVENT_TYPES, default='event')
    
    # Event timing
    start_time = models.DateTimeField()
    end_time = models.DateTimeField(blank=True, null=True)
    all_day = models.BooleanField(default=False)
    timezone = models.CharField(max_length=50, default='UTC')
    
    # Event location
    location = models.CharField(max_length=200, blank=True, null=True)
    meeting_link = models.URLField(blank=True, null=True)
    
    # Recurrence
    is_recurring = models.BooleanField(default=False)
    recurrence_pattern = models.CharField(max_length=20, choices=RECURRENCE_PATTERNS, default='none')
    recurrence_end_date = models.DateTimeField(blank=True, null=True)
    recurrence_count = models.IntegerField(blank=True, null=True)  # Number of occurrences
    
    # Event settings
    color = models.CharField(max_length=7, default='#3b82f6')  # Hex color code
    privacy = models.CharField(max_length=20, choices=PRIVACY_LEVELS, default='private')
    
    # Event creator and attendees
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_calendar_events')
    attendees = models.ManyToManyField(User, related_name='calendar_events', blank=True)
    external_attendees = models.JSONField(default=list, blank=True)  # List of email addresses
    
    # Event status
    is_cancelled = models.BooleanField(default=False)
    cancelled_at = models.DateTimeField(blank=True, null=True)
    cancelled_by = models.ForeignKey(User, on_delete=models.SET_NULL, blank=True, null=True, related_name='cancelled_events')
    
    # Related entities (optional)
    related_meeting = models.ForeignKey('meetings.Meeting', on_delete=models.SET_NULL, blank=True, null=True, related_name='calendar_events')
    related_study_group_event = models.ForeignKey('study_groups.UpcomingEvent', on_delete=models.SET_NULL, blank=True, null=True, related_name='calendar_events')
    
    class Meta:
        ordering = ['start_time']
        verbose_name = 'Calendar Event'
        verbose_name_plural = 'Calendar Events'
        indexes = [
            models.Index(fields=['start_time', 'end_time']),
            models.Index(fields=['event_type']),
            models.Index(fields=['created_by']),
            models.Index(fields=['is_cancelled']),
        ]
    
    def __str__(self):
        return f"{self.title} - {self.start_time}"
    
    @property
    def is_upcoming(self):
        """Check if event is in the future"""
        return self.start_time > timezone.now() and not self.is_cancelled
    
    @property
    def is_past(self):
        """Check if event is in the past"""
        end = self.end_time or self.start_time
        return end < timezone.now()
    
    @property
    def is_ongoing(self):
        """Check if event is currently ongoing"""
        now = timezone.now()
        end = self.end_time or self.start_time
        return self.start_time <= now <= end and not self.is_cancelled
    
    @property
    def duration_minutes(self):
        """Get event duration in minutes"""
        if not self.end_time:
            return None
        delta = self.end_time - self.start_time
        return int(delta.total_seconds() / 60)
    
    @property
    def event_type_display(self):
        """Get event type display name"""
        return dict(self.EVENT_TYPES).get(self.event_type, self.event_type)
    
    @property
    def privacy_display(self):
        """Get privacy level display name"""
        return dict(self.PRIVACY_LEVELS).get(self.privacy, self.privacy)


class EventReminder(TimestampedModel):
    """Reminders for calendar events"""
    
    REMINDER_TYPES = [
        ('notification', 'Notification'),
        ('email', 'Email'),
        ('sms', 'SMS'),
    ]
    
    REMINDER_TIMINGS = [
        (0, 'At event time'),
        (5, '5 minutes before'),
        (15, '15 minutes before'),
        (30, '30 minutes before'),
        (60, '1 hour before'),
        (120, '2 hours before'),
        (1440, '1 day before'),
        (2880, '2 days before'),
    ]
    
    event = models.ForeignKey(CalendarEvent, on_delete=models.CASCADE, related_name='reminders')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='event_reminders')
    reminder_type = models.CharField(max_length=20, choices=REMINDER_TYPES, default='notification')
    minutes_before = models.IntegerField(choices=REMINDER_TIMINGS, default=15)
    is_sent = models.BooleanField(default=False)
    sent_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        ordering = ['minutes_before']
        verbose_name = 'Event Reminder'
        verbose_name_plural = 'Event Reminders'
        unique_together = [['event', 'user', 'reminder_type', 'minutes_before']]
        indexes = [
            models.Index(fields=['event', 'user']),
            models.Index(fields=['is_sent']),
        ]
    
    def __str__(self):
        return f"{self.event.title} - {self.get_minutes_before_display()} before"
    
    @property
    def reminder_time(self):
        """Calculate when the reminder should be sent"""
        return self.event.start_time - timezone.timedelta(minutes=self.minutes_before)
    
    @property
    def should_send(self):
        """Check if reminder should be sent"""
        if self.is_sent:
            return False
        now = timezone.now()
        return now >= self.reminder_time and self.event.start_time > now


class GoogleCalendarSync(TimestampedModel):
    """Google Calendar synchronization settings"""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='google_calendar_sync')
    is_connected = models.BooleanField(default=False)
    access_token = models.TextField(blank=True, null=True)  # Encrypted
    refresh_token = models.TextField(blank=True, null=True)  # Encrypted
    token_expires_at = models.DateTimeField(blank=True, null=True)
    calendar_id = models.CharField(max_length=200, blank=True, null=True)
    last_sync_at = models.DateTimeField(blank=True, null=True)
    sync_enabled = models.BooleanField(default=True)
    sync_direction = models.CharField(
        max_length=20,
        choices=[
            ('bidirectional', 'Bidirectional'),
            ('to_google', 'To Google Calendar'),
            ('from_google', 'From Google Calendar'),
        ],
        default='bidirectional'
    )
    
    class Meta:
        verbose_name = 'Google Calendar Sync'
        verbose_name_plural = 'Google Calendar Syncs'
        indexes = [
            models.Index(fields=['user', 'is_connected']),
            models.Index(fields=['sync_enabled']),
        ]
    
    def __str__(self):
        return f"{self.user.email} - Google Calendar Sync"
    
    @property
    def is_token_expired(self):
        """Check if access token is expired"""
        if not self.token_expires_at:
            return True
        return timezone.now() >= self.token_expires_at
    
    @property
    def needs_sync(self):
        """Check if sync is needed"""
        if not self.sync_enabled or not self.is_connected:
            return False
        if not self.last_sync_at:
            return True
        # Sync if last sync was more than 15 minutes ago
        return (timezone.now() - self.last_sync_at).total_seconds() > 900


class CalendarEventSync(models.Model):
    """Track synchronization of events with external calendars"""
    
    event = models.ForeignKey(CalendarEvent, on_delete=models.CASCADE, related_name='sync_records')
    google_calendar_id = models.CharField(max_length=200, blank=True, null=True)
    ical_uid = models.CharField(max_length=200, blank=True, null=True)
    last_synced_at = models.DateTimeField(auto_now=True)
    sync_status = models.CharField(
        max_length=20,
        choices=[
            ('pending', 'Pending'),
            ('synced', 'Synced'),
            ('failed', 'Failed'),
        ],
        default='pending'
    )
    
    class Meta:
        verbose_name = 'Calendar Event Sync'
        verbose_name_plural = 'Calendar Event Syncs'
        unique_together = [['event', 'google_calendar_id'], ['event', 'ical_uid']]
        indexes = [
            models.Index(fields=['event']),
            models.Index(fields=['sync_status']),
        ]
    
    def __str__(self):
        return f"{self.event.title} - {self.sync_status}"
