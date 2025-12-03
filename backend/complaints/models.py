"""
Complaint models for KSIT Nexus
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()


class Complaint(models.Model):
    """Anonymous complaint system model"""
    
    URGENCY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]
    
    STATUS_CHOICES = [
        ('submitted', 'Submitted'),
        ('under_review', 'Under Review'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
        ('rejected', 'Rejected'),
        ('closed', 'Closed'),
    ]
    
    CATEGORY_CHOICES = [
        ('academic', 'Academic'),
        ('infrastructure', 'Infrastructure'),
        ('hostel', 'Hostel'),
        ('cafeteria', 'Cafeteria'),
        ('transport', 'Transport'),
        ('library', 'Library'),
        ('sports', 'Sports'),
        ('other', 'Other'),
    ]
    
    # Anonymous submission - no direct user reference
    complaint_id = models.CharField(max_length=20, unique=True)
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    title = models.CharField(max_length=200)
    description = models.TextField()
    urgency = models.CharField(max_length=10, choices=URGENCY_CHOICES, default='medium')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='submitted')
    
    # Optional contact info for follow-up
    contact_email = models.EmailField(blank=True, null=True)
    contact_phone = models.CharField(max_length=15, blank=True, null=True)
    
    # Location details
    location = models.CharField(max_length=200, blank=True, null=True)
    
    # Admin assignment
    assigned_to = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        limit_choices_to={'user_type': 'faculty'}
    )
    
    # Timestamps
    submitted_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    resolved_at = models.DateTimeField(blank=True, null=True)
    
    # Priority and internal notes
    priority_score = models.IntegerField(default=0)
    internal_notes = models.TextField(blank=True, null=True)
    
    class Meta:
        ordering = ['-submitted_at']
    
    def __str__(self):
        return f"Complaint #{self.complaint_id} - {self.title}"
    
    def save(self, *args, **kwargs):
        if not self.complaint_id:
            # Generate complaint ID
            import uuid
            self.complaint_id = f"COMP-{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)


class ComplaintAttachment(models.Model):
    """File attachments for complaints"""
    
    complaint = models.ForeignKey(Complaint, on_delete=models.CASCADE, related_name='attachments')
    file = models.FileField(upload_to='complaint_attachments/')
    file_name = models.CharField(max_length=255)
    file_size = models.IntegerField()
    uploaded_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Attachment for {self.complaint.complaint_id}"


class ComplaintUpdate(models.Model):
    """Status updates and comments for complaints"""
    
    complaint = models.ForeignKey(Complaint, on_delete=models.CASCADE, related_name='updates')
    updated_by = models.ForeignKey(User, on_delete=models.CASCADE)
    status = models.CharField(max_length=20, choices=Complaint.STATUS_CHOICES)
    comment = models.TextField()
    is_internal = models.BooleanField(default=False)  # Internal notes vs public updates
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Update for {self.complaint.complaint_id} by {self.updated_by.username}"