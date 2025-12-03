"""
Recommendation models for content recommendations
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from apps.shared.models.base import TimestampedModel

User = get_user_model()


class Recommendation(TimestampedModel):
    """Recommendation for a user"""
    
    CONTENT_TYPES = [
        ('notice', 'Notice'),
        ('study_group', 'Study Group'),
        ('resource', 'Resource'),
        ('meeting', 'Meeting'),
        ('event', 'Event'),
    ]
    
    RECOMMENDATION_TYPES = [
        ('content_based', 'Content Based'),
        ('collaborative', 'Collaborative Filtering'),
        ('ml', 'Machine Learning'),
        ('popular', 'Popular'),
        ('trending', 'Trending'),
        ('hybrid', 'Hybrid'),
    ]
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='recommendations',
    )
    content_type = models.CharField(max_length=20, choices=CONTENT_TYPES)
    content_id = models.IntegerField()
    recommendation_type = models.CharField(max_length=20, choices=RECOMMENDATION_TYPES)
    score = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(1.0)],
        help_text='Recommendation score (0.0 to 1.0)'
    )
    reason = models.TextField(
        blank=True,
        null=True,
        help_text='Explanation for why this item was recommended'
    )
    is_dismissed = models.BooleanField(default=False)
    is_viewed = models.BooleanField(default=False)
    is_interacted = models.BooleanField(default=False)
    feedback = models.JSONField(
        default=dict,
        blank=True,
        help_text='User feedback on the recommendation'
    )
    expires_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text='When this recommendation expires'
    )
    
    class Meta:
        verbose_name = 'Recommendation'
        verbose_name_plural = 'Recommendations'
        unique_together = [['user', 'content_type', 'content_id', 'recommendation_type']]
        indexes = [
            models.Index(fields=['user', 'is_dismissed', 'is_viewed']),
            models.Index(fields=['content_type', 'content_id']),
            models.Index(fields=['recommendation_type', 'score']),
            models.Index(fields=['expires_at']),
        ]
        ordering = ['-score', '-created_at']
    
    def __str__(self):
        return f"Recommendation for {self.user.username}: {self.content_type} #{self.content_id} ({self.recommendation_type})"


class UserPreference(TimestampedModel):
    """User preferences for recommendations"""
    
    CONTENT_TYPES = [
        ('notice', 'Notice'),
        ('study_group', 'Study Group'),
        ('resource', 'Resource'),
        ('meeting', 'Meeting'),
        ('event', 'Event'),
    ]
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='recommendation_preferences',
    )
    content_type = models.CharField(max_length=20, choices=CONTENT_TYPES)
    preferences = models.JSONField(
        default=dict,
        blank=True,
        help_text='User preferences (categories, tags, etc.)'
    )
    interests = models.JSONField(
        default=list,
        blank=True,
        help_text='User interests (topics, subjects, etc.)'
    )
    behavior_patterns = models.JSONField(
        default=dict,
        blank=True,
        help_text='User behavior patterns (viewing times, interaction types, etc.)'
    )
    weight_preferences = models.JSONField(
        default=dict,
        blank=True,
        help_text='Weights for different recommendation factors'
    )
    
    class Meta:
        verbose_name = 'User Preference'
        verbose_name_plural = 'User Preferences'
        unique_together = [['user', 'content_type']]
        indexes = [
            models.Index(fields=['user', 'content_type']),
        ]
    
    def __str__(self):
        return f"Preferences for {self.user.username}: {self.content_type}"


class ContentInteraction(TimestampedModel):
    """User interactions with content"""
    
    INTERACTION_TYPES = [
        ('view', 'View'),
        ('like', 'Like'),
        ('share', 'Share'),
        ('join', 'Join'),
        ('bookmark', 'Bookmark'),
        ('comment', 'Comment'),
        ('rate', 'Rate'),
    ]
    
    CONTENT_TYPES = [
        ('notice', 'Notice'),
        ('study_group', 'Study Group'),
        ('resource', 'Resource'),
        ('meeting', 'Meeting'),
        ('event', 'Event'),
    ]
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='content_interactions',
    )
    content_type = models.CharField(max_length=20, choices=CONTENT_TYPES)
    content_id = models.IntegerField()
    interaction_type = models.CharField(max_length=20, choices=INTERACTION_TYPES)
    rating = models.IntegerField(
        null=True,
        blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text='Rating (1-5) if applicable'
    )
    duration = models.IntegerField(
        null=True,
        blank=True,
        help_text='Time spent in seconds (for views)'
    )
    metadata = models.JSONField(
        default=dict,
        blank=True,
        help_text='Additional metadata about the interaction'
    )
    
    class Meta:
        verbose_name = 'Content Interaction'
        verbose_name_plural = 'Content Interactions'
        indexes = [
            models.Index(fields=['user', 'content_type', 'interaction_type']),
            models.Index(fields=['content_type', 'content_id']),
            models.Index(fields=['created_at']),
        ]
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.username} {self.interaction_type} {self.content_type} #{self.content_id}"


class UserSimilarity(TimestampedModel):
    """Similarity scores between users"""
    
    SIMILARITY_TYPES = [
        ('cosine', 'Cosine Similarity'),
        ('jaccard', 'Jaccard Similarity'),
        ('pearson', 'Pearson Correlation'),
        ('euclidean', 'Euclidean Distance'),
    ]
    
    user1 = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='similarities_as_user1',
    )
    user2 = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='similarities_as_user2',
    )
    similarity_score = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(1.0)],
        help_text='Similarity score (0.0 to 1.0)'
    )
    similarity_type = models.CharField(max_length=20, choices=SIMILARITY_TYPES)
    last_calculated = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'User Similarity'
        verbose_name_plural = 'User Similarities'
        unique_together = [['user1', 'user2', 'similarity_type']]
        indexes = [
            models.Index(fields=['user1', 'similarity_type', 'similarity_score']),
            models.Index(fields=['user2', 'similarity_type', 'similarity_score']),
            models.Index(fields=['last_calculated']),
        ]
    
    def __str__(self):
        return f"Similarity between {self.user1.username} and {self.user2.username}: {self.similarity_score:.2f}"


class ItemSimilarity(TimestampedModel):
    """Similarity scores between items"""
    
    CONTENT_TYPES = [
        ('notice', 'Notice'),
        ('study_group', 'Study Group'),
        ('resource', 'Resource'),
        ('meeting', 'Meeting'),
        ('event', 'Event'),
    ]
    
    SIMILARITY_TYPES = [
        ('cosine', 'Cosine Similarity'),
        ('jaccard', 'Jaccard Similarity'),
        ('pearson', 'Pearson Correlation'),
        ('euclidean', 'Euclidean Distance'),
    ]
    
    content_type = models.CharField(max_length=20, choices=CONTENT_TYPES)
    item1_id = models.IntegerField()
    item2_id = models.IntegerField()
    similarity_score = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(1.0)],
        help_text='Similarity score (0.0 to 1.0)'
    )
    similarity_type = models.CharField(max_length=20, choices=SIMILARITY_TYPES)
    last_calculated = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Item Similarity'
        verbose_name_plural = 'Item Similarities'
        unique_together = [['content_type', 'item1_id', 'item2_id', 'similarity_type']]
        indexes = [
            models.Index(fields=['content_type', 'item1_id', 'similarity_type', 'similarity_score']),
            models.Index(fields=['content_type', 'item2_id', 'similarity_type', 'similarity_score']),
            models.Index(fields=['last_calculated']),
        ]
    
    def __str__(self):
        return f"Similarity between {self.content_type} #{self.item1_id} and #{self.item2_id}: {self.similarity_score:.2f}"
