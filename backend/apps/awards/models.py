"""
Awards & Recognition models for KSIT Nexus
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator
from apps.shared.models.base import TimestampedModel

User = get_user_model()


class AwardCategory(TimestampedModel):
    """Award category model"""
    
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    icon = models.CharField(max_length=100, blank=True, null=True)
    color = models.CharField(max_length=7, default='#3b82f6')
    is_active = models.BooleanField(default=True)
    order = models.IntegerField(default=0, help_text='Display order')
    
    class Meta:
        verbose_name = 'Award Category'
        verbose_name_plural = 'Award Categories'
        ordering = ['order', 'name']
    
    def __str__(self):
        return self.name


class Award(TimestampedModel):
    """Award model"""
    
    AWARD_TYPES = [
        ('achievement', 'Achievement'),
        ('excellence', 'Excellence'),
        ('service', 'Service'),
        ('leadership', 'Leadership'),
        ('academic', 'Academic'),
        ('sports', 'Sports'),
        ('cultural', 'Cultural'),
        ('volunteer', 'Volunteer'),
        ('other', 'Other'),
    ]
    
    name = models.CharField(max_length=200)
    award_type = models.CharField(max_length=20, choices=AWARD_TYPES, default='achievement')
    category = models.ForeignKey(
        AwardCategory,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='awards'
    )
    description = models.TextField()
    criteria = models.TextField(blank=True, null=True, help_text='Criteria for earning this award')
    icon = models.CharField(max_length=100, blank=True, null=True)
    badge_image_url = models.URLField(blank=True, null=True)
    points_value = models.IntegerField(default=0, help_text='Points awarded for this award')
    is_active = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False)
    
    class Meta:
        verbose_name = 'Award'
        verbose_name_plural = 'Awards'
        ordering = ['-is_featured', 'name']
    
    def __str__(self):
        return self.name


class UserAward(TimestampedModel):
    """User award recognition"""
    
    award = models.ForeignKey(Award, on_delete=models.CASCADE, related_name='user_awards')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='awards')
    awarded_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='awards_given',
        limit_choices_to={'user_type__in': ['faculty', 'admin']}
    )
    awarded_at = models.DateTimeField(auto_now_add=True)
    reason = models.TextField(blank=True, null=True, help_text='Reason for awarding')
    certificate_url = models.URLField(blank=True, null=True)
    is_public = models.BooleanField(default=True, help_text='Show in public profile')
    is_featured = models.BooleanField(default=False)
    
    class Meta:
        verbose_name = 'User Award'
        verbose_name_plural = 'User Awards'
        ordering = ['-awarded_at']
        indexes = [
            models.Index(fields=['user', 'awarded_at']),
            models.Index(fields=['award', 'awarded_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.award.name}"


class RecognitionPost(TimestampedModel):
    """Recognition post/announcement"""
    
    POST_TYPES = [
        ('award', 'Award Announcement'),
        ('achievement', 'Achievement Highlight'),
        ('milestone', 'Milestone'),
        ('appreciation', 'Appreciation'),
        ('spotlight', 'Spotlight'),
    ]
    
    title = models.CharField(max_length=200)
    post_type = models.CharField(max_length=20, choices=POST_TYPES, default='award')
    content = models.TextField()
    featured_image_url = models.URLField(blank=True, null=True)
    recognized_users = models.ManyToManyField(
        User,
        related_name='recognition_posts',
        help_text='Users being recognized'
    )
    related_award = models.ForeignKey(
        Award,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='recognition_posts'
    )
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_recognition_posts',
        limit_choices_to={'user_type__in': ['faculty', 'admin']}
    )
    is_published = models.BooleanField(default=False)
    published_at = models.DateTimeField(blank=True, null=True)
    views_count = models.IntegerField(default=0)
    likes_count = models.IntegerField(default=0)
    
    class Meta:
        verbose_name = 'Recognition Post'
        verbose_name_plural = 'Recognition Posts'
        ordering = ['-published_at', '-created_at']
        indexes = [
            models.Index(fields=['post_type', 'is_published']),
            models.Index(fields=['is_published', 'published_at']),
        ]
    
    def __str__(self):
        return self.title


class RecognitionLike(TimestampedModel):
    """Like for recognition posts"""
    
    post = models.ForeignKey(RecognitionPost, on_delete=models.CASCADE, related_name='likes')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='recognition_likes')
    
    class Meta:
        verbose_name = 'Recognition Like'
        verbose_name_plural = 'Recognition Likes'
        unique_together = [['post', 'user']]
    
    def __str__(self):
        return f"{self.user.username} likes {self.post.title}"


class AwardNomination(TimestampedModel):
    """Award nomination"""
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('under_review', 'Under Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]
    
    nomination_id = models.CharField(max_length=20, unique=True)
    award = models.ForeignKey(Award, on_delete=models.CASCADE, related_name='nominations')
    nominee = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='award_nominations_received'
    )
    nominated_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='award_nominations_sent'
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    nomination_reason = models.TextField()
    supporting_evidence = models.JSONField(
        default=list,
        blank=True,
        help_text='List of evidence URLs or descriptions'
    )
    reviewed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_nominations',
        limit_choices_to={'user_type__in': ['faculty', 'admin']}
    )
    review_notes = models.TextField(blank=True, null=True)
    reviewed_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Award Nomination'
        verbose_name_plural = 'Award Nominations'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['nomination_id', 'status']),
            models.Index(fields=['award', 'status']),
            models.Index(fields=['nominee', 'status']),
        ]
    
    def __str__(self):
        return f"{self.nomination_id} - {self.nominee.username} for {self.award.name}"
    
    def save(self, *args, **kwargs):
        if not self.nomination_id:
            import uuid
            self.nomination_id = f"NOM-{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)


class AwardCeremony(TimestampedModel):
    """Award ceremony event"""
    
    title = models.CharField(max_length=200)
    description = models.TextField()
    event_date = models.DateTimeField()
    location = models.CharField(max_length=200, blank=True, null=True)
    is_virtual = models.BooleanField(default=False)
    virtual_link = models.URLField(blank=True, null=True)
    awards = models.ManyToManyField(
        Award,
        related_name='ceremonies',
        help_text='Awards to be presented'
    )
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_award_ceremonies',
        limit_choices_to={'user_type__in': ['faculty', 'admin']}
    )
    is_published = models.BooleanField(default=False)
    published_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Award Ceremony'
        verbose_name_plural = 'Award Ceremonies'
        ordering = ['-event_date']
    
    def __str__(self):
        return f"{self.title} - {self.event_date}"

















