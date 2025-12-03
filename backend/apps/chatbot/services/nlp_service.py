"""
NLP Service for advanced chatbot capabilities
"""
import re
from typing import Dict, List, Optional, Tuple
from django.utils import timezone
from apps.chatbot.models import ChatbotSession, ChatbotMessage, ChatbotQuestion
from apps.chatbot.models_nlp import ConversationContext
from apps.shared.utils.logging import get_logger

logger = get_logger(__name__)


class NLPService:
    """Service for NLP processing including intent recognition, context awareness, and sentiment analysis"""
    
    # Common intents
    INTENTS = [
        'greeting',
        'question',
        'complaint',
        'feedback',
        'reservation',
        'meeting',
        'study_group',
        'calendar',
        'notification',
        'profile',
        'help',
        'goodbye',
        'other',
    ]
    
    # Intent patterns (simple keyword-based for now, can be enhanced with ML models)
    INTENT_PATTERNS = {
        'greeting': ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening'],
        'question': ['what', 'how', 'when', 'where', 'why', 'who', 'which', 'can', 'could', 'would'],
        'complaint': ['complaint', 'issue', 'problem', 'error', 'bug', 'broken'],
        'feedback': ['feedback', 'suggest', 'improve', 'opinion', 'review'],
        'reservation': ['reserve', 'booking', 'book', 'room', 'seat'],
        'meeting': ['meeting', 'schedule', 'appointment'],
        'study_group': ['study group', 'study', 'group'],
        'calendar': ['calendar', 'event', 'schedule'],
        'notification': ['notification', 'alert', 'reminder'],
        'profile': ['profile', 'account', 'settings'],
        'help': ['help', 'support', 'assistance'],
        'goodbye': ['bye', 'goodbye', 'see you', 'thanks', 'thank you'],
    }
    
    @staticmethod
    def get_or_create_conversation_context(session: ChatbotSession) -> ConversationContext:
        """Get or create conversation context for a session"""
        context, created = ConversationContext.objects.get_or_create(
            session=session,
            defaults={
                'conversation_state': 'idle',
                'context_variables': {},
                'conversation_history': [],
            }
        )
        return context
    
    @staticmethod
    def recognize_intent(message: str, context: Optional[ConversationContext] = None) -> Tuple[str, float]:
        """Recognize intent from user message"""
        message_lower = message.lower()
        best_intent = 'other'
        best_score = 0.0
        
        # Check intent patterns
        for intent, patterns in NLPService.INTENT_PATTERNS.items():
            score = 0.0
            matches = 0
            
            for pattern in patterns:
                if pattern in message_lower:
                    matches += 1
                    score += 0.3
            
            # Normalize score
            if len(patterns) > 0:
                score = min(score / len(patterns), 1.0)
            
            if score > best_score:
                best_score = score
                best_intent = intent
        
        # Use context to refine intent
        if context and context.current_intent:
            # If context suggests a continuing conversation, use that intent
            if best_score < 0.5:
                best_intent = context.current_intent
                best_score = 0.5
        
        # Minimum confidence threshold
        if best_score < 0.2:
            best_intent = 'question'  # Default to question if no clear intent
        
        return best_intent, min(best_score, 1.0)
    
    @staticmethod
    def extract_entities(message: str) -> List[Dict[str, str]]:
        """Extract entities from user message (simplified implementation)"""
        entities = []
        message_lower = message.lower()
        
        # Extract dates (simple pattern matching)
        date_patterns = [
            r'\d{4}-\d{2}-\d{2}',  # YYYY-MM-DD
            r'\d{2}/\d{2}/\d{4}',  # MM/DD/YYYY
            r'today', r'tomorrow', r'yesterday',
            r'next week', r'next month', r'next year',
        ]
        
        for pattern in date_patterns:
            matches = re.findall(pattern, message_lower)
            for match in matches:
                entities.append({
                    'type': 'date',
                    'value': match,
                    'confidence': 0.8,
                })
        
        # Extract numbers
        number_pattern = r'\d+'
        numbers = re.findall(number_pattern, message)
        for number in numbers:
            entities.append({
                'type': 'number',
                'value': number,
                'confidence': 0.9,
            })
        
        # Extract email addresses
        email_pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
        emails = re.findall(email_pattern, message)
        for email in emails:
            entities.append({
                'type': 'email',
                'value': email,
                'confidence': 0.95,
            })
        
        # Extract URLs
        url_pattern = r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+'
        urls = re.findall(url_pattern, message)
        for url in urls:
            entities.append({
                'type': 'url',
                'value': url,
                'confidence': 0.9,
            })
        
        return entities
    
    @staticmethod
    def analyze_sentiment(message: str) -> Tuple[float, str]:
        """Analyze sentiment of user message (simplified implementation)"""
        message_lower = message.lower()
        
        # Positive words
        positive_words = [
            'good', 'great', 'excellent', 'awesome', 'fantastic', 'wonderful',
            'happy', 'pleased', 'satisfied', 'thank', 'thanks', 'appreciate',
            'love', 'like', 'enjoy', 'perfect', 'amazing', 'brilliant',
        ]
        
        # Negative words
        negative_words = [
            'bad', 'terrible', 'awful', 'horrible', 'worst', 'hate', 'dislike',
            'angry', 'frustrated', 'disappointed', 'upset', 'sad', 'unhappy',
            'problem', 'issue', 'error', 'broken', 'wrong', 'fail', 'failed',
        ]
        
        positive_count = sum(1 for word in positive_words if word in message_lower)
        negative_count = sum(1 for word in negative_words if word in message_lower)
        
        # Calculate sentiment score (-1 to 1)
        total_words = len(message_lower.split())
        if total_words == 0:
            return 0.0, 'neutral'
        
        sentiment_score = (positive_count - negative_count) / max(total_words, 1)
        sentiment_score = max(-1.0, min(1.0, sentiment_score))
        
        # Determine sentiment label
        if sentiment_score > 0.1:
            sentiment_label = 'positive'
        elif sentiment_score < -0.1:
            sentiment_label = 'negative'
        else:
            sentiment_label = 'neutral'
        
        return sentiment_score, sentiment_label
    
    @staticmethod
    def process_message(
        session: ChatbotSession,
        message: str,
        update_context: bool = True,
    ) -> Dict:
        """Process a user message with NLP"""
        # Get or create conversation context
        context = NLPService.get_or_create_conversation_context(session)
        
        # Recognize intent
        intent, intent_confidence = NLPService.recognize_intent(message, context)
        
        # Extract entities
        entities = NLPService.extract_entities(message)
        
        # Analyze sentiment
        sentiment_score, sentiment_label = NLPService.analyze_sentiment(message)
        
        # Update context if requested
        if update_context:
            context.current_intent = intent
            context.detected_entities = entities
            context.sentiment_score = sentiment_score
            context.sentiment_label = sentiment_label
            context.add_message_to_history('user', message, {
                'intent': intent,
                'intent_confidence': intent_confidence,
                'entities': entities,
                'sentiment': sentiment_label,
            })
            context.save()
        
        return {
            'intent': intent,
            'intent_confidence': intent_confidence,
            'entities': entities,
            'sentiment_score': sentiment_score,
            'sentiment_label': sentiment_label,
            'context': context,
        }
    
    @staticmethod
    def get_conversation_context(session: ChatbotSession) -> Optional[ConversationContext]:
        """Get conversation context for a session"""
        try:
            return ConversationContext.objects.get(session=session, is_active=True)
        except ConversationContext.DoesNotExist:
            return None
    
    @staticmethod
    def update_conversation_state(
        session: ChatbotSession,
        state: str,
        context_variables: Optional[Dict] = None,
    ):
        """Update conversation state"""
        context = NLPService.get_or_create_conversation_context(session)
        context.conversation_state = state
        
        if context_variables:
            for key, value in context_variables.items():
                context.update_context_variable(key, value)
        
        context.save()
    
    @staticmethod
    def clear_conversation_context(session: ChatbotSession):
        """Clear conversation context"""
        try:
            context = ConversationContext.objects.get(session=session)
            context.clear_context()
        except ConversationContext.DoesNotExist:
            pass
    
    @staticmethod
    def get_conversation_history(session: ChatbotSession, limit: int = 10) -> List[Dict]:
        """Get conversation history"""
        context = NLPService.get_or_create_conversation_context(session)
        return context.conversation_history[-limit:] if context.conversation_history else []
    
    @staticmethod
    def enhance_message_with_context(
        message: str,
        session: ChatbotSession,
    ) -> str:
        """Enhance message with conversation context"""
        context = NLPService.get_or_create_conversation_context(session)
        
        # If context has variables, try to fill in missing information
        if context.context_variables:
            # Simple template replacement (can be enhanced)
            enhanced_message = message
            for key, value in context.context_variables.items():
                if f'[{key}]' in enhanced_message:
                    enhanced_message = enhanced_message.replace(f'[{key}]', str(value))
            
            return enhanced_message
        
        return message

