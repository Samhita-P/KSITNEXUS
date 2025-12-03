from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()

class Meeting(models.Model):
    MEETING_TYPES = [
        ('faculty', 'Faculty Meeting'),
        ('department', 'Department Meeting'),
        ('committee', 'Committee Meeting'),
        ('student', 'Student Meeting'),
        ('other', 'Other'),
    ]
    
    AUDIENCE_TYPES = [
        ('all_faculty', 'All Faculty'),
        ('department', 'Department Only'),
        ('committee', 'Committee Members'),
        ('specific', 'Specific People'),
    ]
    
    STATUS_CHOICES = [
        ('scheduled', 'Scheduled'),
        ('ongoing', 'Ongoing'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    title = models.CharField(max_length=200)
    description = models.TextField()
    type = models.CharField(max_length=20, choices=MEETING_TYPES)
    location = models.CharField(max_length=200)
    scheduled_date = models.DateTimeField()
    duration = models.CharField(max_length=10)  # Duration in minutes as string
    audience = models.CharField(max_length=20, choices=AUDIENCE_TYPES)
    notes = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='scheduled')
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_meetings')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-scheduled_date']
        verbose_name = 'Meeting'
        verbose_name_plural = 'Meetings'
    
    def __str__(self):
        return self.title
    
    @property
    def is_upcoming(self):
        return self.scheduled_date > timezone.now()
    
    @property
    def is_past(self):
        return self.scheduled_date < timezone.now()
    
    @property
    def is_today(self):
        now = timezone.now()
        return (self.scheduled_date.year == now.year and
                self.scheduled_date.month == now.month and
                self.scheduled_date.day == now.day)
    
    @property
    def status_display_name(self):
        return dict(self.STATUS_CHOICES).get(self.status, self.status)
    
    @property
    def type_display_name(self):
        return dict(self.MEETING_TYPES).get(self.type, self.type)
    
    @property
    def audience_display_name(self):
        return dict(self.AUDIENCE_TYPES).get(self.audience, self.audience)

