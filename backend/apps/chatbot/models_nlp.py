"""
Advanced NLP models for chatbot enhancements
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.shared.models.base import TimestampedModel

User = get_user_model()

# Forward references to avoid circular imports
# These will be resolved when models are loaded


class ConversationContext(TimestampedModel):
    """Track conversation context for multi-turn conversations"""
    
    session = models.OneToOneField(
        'chatbot.ChatbotSession',
        on_delete=models.CASCADE,
        related_name='conversation_context',
        db_constraint=True,
    )
    
    # Context variables
    context_variables = models.JSONField(default=dict, blank=True)  # Store context variables
    current_intent = models.CharField(max_length=100, blank=True, null=True)  # Current user intent
    conversation_state = models.CharField(max_length=50, default='idle')  # Conversation state
    
    # NLP metadata
    detected_entities = models.JSONField(default=list, blank=True)  # Extracted entities
    sentiment_score = models.FloatField(blank=True, null=True)  # Sentiment score (-1 to 1)
    sentiment_label = models.CharField(max_length=20, blank=True, null=True)  # positive, negative, neutral
    
    # Conversation history (last N messages for context)
    conversation_history = models.JSONField(default=list, blank=True)  # Store recent messages
    max_history_length = models.IntegerField(default=10)  # Maximum history length
    
    # Context metadata
    last_updated = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    
    class Meta:
        verbose_name = 'Conversation Context'
        verbose_name_plural = 'Conversation Contexts'
        indexes = [
            models.Index(fields=['session', 'is_active']),
            models.Index(fields=['current_intent']),
            models.Index(fields=['conversation_state']),
        ]
    
    def __str__(self):
        return f"Context for {self.session.session_id} - {self.current_intent}"
    
    def add_message_to_history(self, message_type, content, metadata=None):
        """Add a message to conversation history"""
        if not self.conversation_history:
            self.conversation_history = []
        
        message_entry = {
            'type': message_type,
            'content': content,
            'timestamp': timezone.now().isoformat(),
            'metadata': metadata or {},
        }
        
        self.conversation_history.append(message_entry)
        
        # Keep only the last N messages
        if len(self.conversation_history) > self.max_history_length:
            self.conversation_history = self.conversation_history[-self.max_history_length:]
        
        self.save()
    
    def update_context_variable(self, key, value):
        """Update a context variable"""
        if not self.context_variables:
            self.context_variables = {}
        
        self.context_variables[key] = value
        self.save()
    
    def get_context_variable(self, key, default=None):
        """Get a context variable"""
        if not self.context_variables:
            return default
        return self.context_variables.get(key, default)
    
    def clear_context(self):
        """Clear conversation context"""
        self.context_variables = {}
        self.current_intent = None
        self.conversation_state = 'idle'
        self.detected_entities = []
        self.sentiment_score = None
        self.sentiment_label = None
        self.conversation_history = []
        self.save()


class ChatbotUserProfile(TimestampedModel):
    """User profile for chatbot personalization"""
    
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='chatbot_profile',
    )
    
    # User preferences
    preferred_language = models.CharField(max_length=10, default='en')
    response_style = models.CharField(
        max_length=20,
        choices=[
            ('formal', 'Formal'),
            ('casual', 'Casual'),
            ('friendly', 'Friendly'),
            ('professional', 'Professional'),
        ],
        default='friendly',
    )
    
    # Interaction history
    total_interactions = models.IntegerField(default=0)
    total_sessions = models.IntegerField(default=0)
    average_rating = models.FloatField(default=0.0)
    
    # User preferences for chatbot behavior
    preferences = models.JSONField(default=dict, blank=True)  # Store user preferences
    
    # Learning data
    common_topics = models.JSONField(default=list, blank=True)  # Topics user frequently asks about
    preferred_categories = models.JSONField(default=list, blank=True)  # Preferred categories
    
    # Personalization metadata
    last_interaction_at = models.DateTimeField(blank=True, null=True)
    is_personalized = models.BooleanField(default=True)
    
    class Meta:
        verbose_name = 'Chatbot User Profile'
        verbose_name_plural = 'Chatbot User Profiles'
        indexes = [
            models.Index(fields=['user']),
            models.Index(fields=['is_personalized']),
        ]
    
    def __str__(self):
        return f"Chatbot Profile for {self.user.username}"
    
    def update_preference(self, key, value):
        """Update a user preference"""
        if not self.preferences:
            self.preferences = {}
        
        self.preferences[key] = value
        self.save()
    
    def get_preference(self, key, default=None):
        """Get a user preference"""
        if not self.preferences:
            return default
        return self.preferences.get(key, default)
    
    def increment_interaction(self):
        """Increment interaction count"""
        self.total_interactions += 1
        self.last_interaction_at = timezone.now()
        self.save(update_fields=['total_interactions', 'last_interaction_at'])
    
    def increment_session(self):
        """Increment session count"""
        self.total_sessions += 1
        self.save(update_fields=['total_sessions'])
    
    def update_average_rating(self, new_rating):
        """Update average rating"""
        # Simple moving average calculation
        if self.total_interactions == 0:
            self.average_rating = new_rating
        else:
            self.average_rating = (
                (self.average_rating * (self.total_interactions - 1) + new_rating) /
                self.total_interactions
            )
        self.save(update_fields=['average_rating'])


class ChatbotAction(TimestampedModel):
    """Actions that the chatbot can execute"""
    
    ACTION_TYPES = [
        ('api_call', 'API Call'),
        ('database_query', 'Database Query'),
        ('notification', 'Send Notification'),
        ('calendar', 'Calendar Action'),
        ('reservation', 'Reservation Action'),
        ('study_group', 'Study Group Action'),
        ('other', 'Other'),
    ]
    
    name = models.CharField(max_length=100, unique=True)
    action_type = models.CharField(max_length=20, choices=ACTION_TYPES)
    description = models.TextField(blank=True, null=True)
    
    # Action configuration
    action_config = models.JSONField(default=dict, blank=True)  # Store action configuration
    required_params = models.JSONField(default=list, blank=True)  # Required parameters
    optional_params = models.JSONField(default=list, blank=True)  # Optional parameters
    
    # Action execution
    execution_function = models.CharField(max_length=200, blank=True, null=True)  # Function name or URL
    is_active = models.BooleanField(default=True)
    
    # Action metadata
    usage_count = models.IntegerField(default=0)
    success_count = models.IntegerField(default=0)
    failure_count = models.IntegerField(default=0)
    
    class Meta:
        verbose_name = 'Chatbot Action'
        verbose_name_plural = 'Chatbot Actions'
        indexes = [
            models.Index(fields=['action_type', 'is_active']),
            models.Index(fields=['name']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.action_type})"
    
    def increment_usage(self):
        """Increment usage count"""
        self.usage_count += 1
        self.save(update_fields=['usage_count'])
    
    def increment_success(self):
        """Increment success count"""
        self.success_count += 1
        self.save(update_fields=['success_count'])
    
    def increment_failure(self):
        """Increment failure count"""
        self.failure_count += 1
        self.save(update_fields=['failure_count'])
    
    @property
    def success_rate(self):
        """Calculate success rate"""
        if self.usage_count == 0:
            return 0.0
        return (self.success_count / self.usage_count) * 100


class ChatbotActionExecution(TimestampedModel):
    """Track execution of chatbot actions"""
    
    action = models.ForeignKey(
        'ChatbotAction',
        on_delete=models.CASCADE,
        related_name='executions',
    )
    session = models.ForeignKey(
        'chatbot.ChatbotSession',
        on_delete=models.CASCADE,
        related_name='action_executions',
    )
    user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        related_name='chatbot_action_executions',
    )
    
    # Execution details
    parameters = models.JSONField(default=dict, blank=True)  # Parameters used
    result = models.JSONField(default=dict, blank=True)  # Execution result
    status = models.CharField(
        max_length=20,
        choices=[
            ('pending', 'Pending'),
            ('success', 'Success'),
            ('failed', 'Failed'),
            ('cancelled', 'Cancelled'),
        ],
        default='pending',
    )
    
    # Error handling
    error_message = models.TextField(blank=True, null=True)
    execution_time = models.FloatField(blank=True, null=True)  # Execution time in seconds
    
    class Meta:
        verbose_name = 'Chatbot Action Execution'
        verbose_name_plural = 'Chatbot Action Executions'
        indexes = [
            models.Index(fields=['action', 'status']),
            models.Index(fields=['session']),
            models.Index(fields=['user']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"Execution of {self.action.name} - {self.status}"

