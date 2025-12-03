"""
Faculty feedback models for KSIT Nexus
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone

User = get_user_model()


class FacultyFeedback(models.Model):
    """Faculty feedback system with optional user tracking"""
    
    RATING_CHOICES = [
        (1, '1 - Poor'),
        (2, '2 - Fair'),
        (3, '3 - Good'),
        (4, '4 - Very Good'),
        (5, '5 - Excellent'),
    ]
    
    # Optional student reference for tracking submissions
    feedback_id = models.CharField(max_length=20, unique=True)
    faculty = models.ForeignKey(
        User, 
        on_delete=models.CASCADE,
        limit_choices_to={'user_type': 'faculty'},
        related_name='received_feedback'
    )
    # Optional student who submitted the feedback (null for anonymous)
    submitted_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        limit_choices_to={'user_type': 'student'},
        related_name='submitted_feedback'
    )
    
    # Rating categories
    teaching_quality = models.IntegerField(
        choices=RATING_CHOICES,
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    communication = models.IntegerField(
        choices=RATING_CHOICES,
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    punctuality = models.IntegerField(
        choices=RATING_CHOICES,
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    subject_knowledge = models.IntegerField(
        choices=RATING_CHOICES,
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    helpfulness = models.IntegerField(
        choices=RATING_CHOICES,
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    
    # Overall rating
    overall_rating = models.FloatField(
        validators=[MinValueValidator(1.0), MaxValueValidator(5.0)]
    )
    
    # Comments
    positive_comments = models.TextField(blank=True, null=True)
    improvement_suggestions = models.TextField(blank=True, null=True)
    additional_comments = models.TextField(blank=True, null=True)
    
    # Course/Subject context
    course_name = models.CharField(max_length=200, blank=True, null=True)
    semester = models.CharField(max_length=20, blank=True, null=True)
    
    # Anonymity settings
    is_anonymous = models.BooleanField(default=True)
    
    # Timestamps
    submitted_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-submitted_at']
    
    def __str__(self):
        return f"Feedback for {self.faculty.get_full_name()} - {self.feedback_id}"
    
    def save(self, *args, **kwargs):
        if not self.feedback_id:
            # Generate feedback ID
            import uuid
            self.feedback_id = f"FB-{uuid.uuid4().hex[:8].upper()}"
        
        # Calculate overall rating
        ratings = [
            self.teaching_quality,
            self.communication,
            self.punctuality,
            self.subject_knowledge,
            self.helpfulness
        ]
        self.overall_rating = sum(ratings) / len(ratings)
        
        super().save(*args, **kwargs)


class FacultyFeedbackSummary(models.Model):
    """Aggregated feedback summary for faculty"""
    
    faculty = models.OneToOneField(
        User, 
        on_delete=models.CASCADE,
        limit_choices_to={'user_type': 'faculty'},
        related_name='feedback_summary'
    )
    
    # Aggregated ratings
    avg_teaching_quality = models.FloatField(default=0.0)
    avg_communication = models.FloatField(default=0.0)
    avg_punctuality = models.FloatField(default=0.0)
    avg_subject_knowledge = models.FloatField(default=0.0)
    avg_helpfulness = models.FloatField(default=0.0)
    avg_overall_rating = models.FloatField(default=0.0)
    
    # Counts
    total_feedback_count = models.IntegerField(default=0)
    
    # Last updated
    last_updated = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Feedback Summary for {self.faculty.get_full_name()}"
    
    def update_summary(self):
        """Update aggregated feedback data"""
        try:
            feedbacks = FacultyFeedback.objects.filter(faculty=self.faculty)
            
            if feedbacks.exists():
                count = feedbacks.count()
                self.avg_teaching_quality = sum(f.teaching_quality for f in feedbacks) / count if count > 0 else 0.0
                self.avg_communication = sum(f.communication for f in feedbacks) / count if count > 0 else 0.0
                self.avg_punctuality = sum(f.punctuality for f in feedbacks) / count if count > 0 else 0.0
                self.avg_subject_knowledge = sum(f.subject_knowledge for f in feedbacks) / count if count > 0 else 0.0
                self.avg_helpfulness = sum(f.helpfulness for f in feedbacks) / count if count > 0 else 0.0
                self.avg_overall_rating = sum(f.overall_rating for f in feedbacks) / count if count > 0 else 0.0
                self.total_feedback_count = count
            else:
                self.avg_teaching_quality = 0.0
                self.avg_communication = 0.0
                self.avg_punctuality = 0.0
                self.avg_subject_knowledge = 0.0
                self.avg_helpfulness = 0.0
                self.avg_overall_rating = 0.0
                self.total_feedback_count = 0
            
            self.save()
        except Exception as e:
            print(f"Error updating feedback summary for faculty {self.faculty.id}: {e}")
            import traceback
            traceback.print_exc()
            # Set default values on error
            self.avg_teaching_quality = 0.0
            self.avg_communication = 0.0
            self.avg_punctuality = 0.0
            self.avg_subject_knowledge = 0.0
            self.avg_helpfulness = 0.0
            self.avg_overall_rating = 0.0
            self.total_feedback_count = 0
            self.save()