"""
AI Chatbot models for KSIT Nexus
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()


class ChatbotCategory(models.Model):
    """Categories for chatbot questions"""
    
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True, null=True)
    icon = models.CharField(max_length=50, blank=True, null=True)  # Icon class or emoji
    is_active = models.BooleanField(default=True)
    order = models.IntegerField(default=0)
    
    class Meta:
        ordering = ['order', 'name']
        verbose_name_plural = 'Chatbot Categories'
    
    def __str__(self):
        return self.name


class ChatbotQuestion(models.Model):
    """Predefined Q&A for chatbot"""
    
    category = models.ForeignKey(ChatbotCategory, on_delete=models.CASCADE, related_name='questions')
    question = models.TextField()
    answer = models.TextField()
    
    # Keywords for fuzzy matching
    keywords = models.JSONField(default=list, blank=True)  # List of keywords
    tags = models.JSONField(default=list, blank=True)  # Additional tags
    
    # Settings
    is_active = models.BooleanField(default=True)
    priority = models.IntegerField(default=0)  # Higher priority questions shown first
    usage_count = models.IntegerField(default=0)  # Track how often this Q&A is used
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-priority', '-usage_count', 'question']
    
    def __str__(self):
        return f"{self.question[:50]}..."
    
    def increment_usage(self):
        """Increment usage count"""
        self.usage_count += 1
        self.save(update_fields=['usage_count'])


class ChatbotSession(models.Model):
    """Chatbot conversation sessions"""
    
    user = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='chatbot_sessions',
        blank=True,
        null=True
    )
    session_id = models.CharField(max_length=100, unique=True)
    
    # Session metadata
    ip_address = models.GenericIPAddressField(blank=True, null=True)
    user_agent = models.TextField(blank=True, null=True)
    
    # Session status
    is_active = models.BooleanField(default=True)
    ended_at = models.DateTimeField(blank=True, null=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Session {self.session_id} - {self.user.username if self.user else 'Anonymous'}"
    
    def end_session(self):
        """End the chat session"""
        self.is_active = False
        self.ended_at = timezone.now()
        self.save()


class ChatbotMessage(models.Model):
    """Individual messages in chatbot conversations"""
    
    MESSAGE_TYPES = [
        ('user', 'User Message'),
        ('bot', 'Bot Response'),
        ('system', 'System Message'),
    ]
    
    session = models.ForeignKey(ChatbotSession, on_delete=models.CASCADE, related_name='messages')
    message_type = models.CharField(max_length=10, choices=MESSAGE_TYPES)
    content = models.TextField()
    
    # For bot messages
    related_question = models.ForeignKey(
        ChatbotQuestion, 
        on_delete=models.SET_NULL, 
        blank=True, 
        null=True,
        related_name='messages'
    )
    confidence_score = models.FloatField(blank=True, null=True)  # AI confidence in the answer
    
    # Message metadata
    is_helpful = models.BooleanField(blank=True, null=True)  # User feedback
    feedback_comment = models.TextField(blank=True, null=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        return f"{self.get_message_type_display()} - {self.content[:50]}..."


class ChatbotFeedback(models.Model):
    """User feedback on chatbot responses"""
    
    RATING_CHOICES = [
        (1, '1 - Not Helpful'),
        (2, '2 - Slightly Helpful'),
        (3, '3 - Moderately Helpful'),
        (4, '4 - Very Helpful'),
        (5, '5 - Extremely Helpful'),
    ]
    
    message = models.ForeignKey(ChatbotMessage, on_delete=models.CASCADE, related_name='feedback')
    rating = models.IntegerField(choices=RATING_CHOICES)
    comment = models.TextField(blank=True, null=True)
    
    # User info (optional for anonymous feedback)
    user = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        blank=True, 
        null=True,
        related_name='chatbot_feedback'
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Feedback for message {self.message.id} - Rating: {self.rating}"


class ChatbotAnalytics(models.Model):
    """Analytics data for chatbot performance"""
    
    date = models.DateField()
    
    # Usage statistics
    total_sessions = models.IntegerField(default=0)
    total_messages = models.IntegerField(default=0)
    unique_users = models.IntegerField(default=0)
    
    # Question statistics
    most_asked_questions = models.JSONField(default=list, blank=True)
    unanswered_questions = models.JSONField(default=list, blank=True)
    
    # Performance metrics
    average_response_time = models.FloatField(default=0.0)  # in seconds
    average_rating = models.FloatField(default=0.0)
    resolution_rate = models.FloatField(default=0.0)  # Percentage of resolved queries
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['date']
        ordering = ['-date']
    
    def __str__(self):
        return f"Analytics for {self.date}"
