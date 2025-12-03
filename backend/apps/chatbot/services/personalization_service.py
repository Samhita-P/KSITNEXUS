"""
Personalization Service for chatbot personalization
"""
from typing import Dict, Optional, List
from django.contrib.auth import get_user_model
from django.db.models import Count, Q
from apps.chatbot.models import ChatbotQuestion, ChatbotCategory, ChatbotMessage, ChatbotSession
from apps.chatbot.models_nlp import ChatbotUserProfile
from apps.shared.utils.logging import get_logger

User = get_user_model()
logger = get_logger(__name__)


class PersonalizationService:
    """Service for personalizing chatbot responses"""
    
    @staticmethod
    def get_or_create_user_profile(user: User) -> ChatbotUserProfile:
        """Get or create user profile for personalization"""
        profile, created = ChatbotUserProfile.objects.get_or_create(
            user=user,
            defaults={
                'preferred_language': 'en',
                'response_style': 'friendly',
                'is_personalized': True,
            }
        )
        return profile
    
    @staticmethod
    def personalize_response(
        response: str,
        user: Optional[User] = None,
        profile: Optional[ChatbotUserProfile] = None,
    ) -> str:
        """Personalize response based on user profile"""
        if not user:
            return response
        
        if not profile:
            profile = PersonalizationService.get_or_create_user_profile(user)
        
        # Adjust response style based on user preference
        response_style = profile.response_style
        
        if response_style == 'formal':
            # Make response more formal
            response = response.replace("I'm", "I am")
            response = response.replace("you're", "you are")
            response = response.replace("don't", "do not")
            response = response.replace("can't", "cannot")
        elif response_style == 'casual':
            # Make response more casual
            response = response.replace("I am", "I'm")
            response = response.replace("you are", "you're")
            response = response.replace("do not", "don't")
            response = response.replace("cannot", "can't")
        
        return response
    
    @staticmethod
    def get_user_preferences(user: User) -> Dict:
        """Get user preferences"""
        profile = PersonalizationService.get_or_create_user_profile(user)
        
        return {
            'preferred_language': profile.preferred_language,
            'response_style': profile.response_style,
            'preferences': profile.preferences,
            'common_topics': profile.common_topics,
            'preferred_categories': profile.preferred_categories,
        }
    
    @staticmethod
    def update_user_preferences(user: User, preferences: Dict):
        """Update user preferences"""
        profile = PersonalizationService.get_or_create_user_profile(user)
        
        if 'preferred_language' in preferences:
            profile.preferred_language = preferences['preferred_language']
        if 'response_style' in preferences:
            profile.response_style = preferences['response_style']
        if 'preferences' in preferences:
            profile.preferences.update(preferences['preferences'])
        if 'is_personalized_enabled' in preferences:
            profile.is_personalized = preferences['is_personalized_enabled']
        
        profile.save()
    
    @staticmethod
    def learn_from_user_interaction(
        user: User,
        question: ChatbotQuestion,
        rating: Optional[int] = None,
    ):
        """Learn from user interaction"""
        profile = PersonalizationService.get_or_create_user_profile(user)
        profile.increment_interaction()
        
        # Update average rating
        if rating:
            profile.update_average_rating(rating)
        
        # Track common topics
        if question.category.name not in (profile.common_topics or []):
            if not profile.common_topics:
                profile.common_topics = []
            profile.common_topics.append(question.category.name)
            # Keep only last 10 topics
            profile.common_topics = profile.common_topics[-10:]
        
        # Track preferred categories
        category_name = question.category.name
        if category_name not in (profile.preferred_categories or []):
            if not profile.preferred_categories:
                profile.preferred_categories = []
            profile.preferred_categories.append(category_name)
            # Keep only last 5 categories
            profile.preferred_categories = profile.preferred_categories[-5:]
        
        profile.save()
    
    @staticmethod
    def get_personalized_recommendations(user: User, limit: int = 5) -> List[ChatbotQuestion]:
        """Get personalized question recommendations"""
        profile = PersonalizationService.get_or_create_user_profile(user)
        
        # Get questions from preferred categories
        preferred_categories = profile.preferred_categories or []
        
        if preferred_categories:
            questions = ChatbotQuestion.objects.filter(
                category__name__in=preferred_categories,
                is_active=True,
            ).order_by('-priority', '-usage_count')[:limit]
        else:
            # Fallback to popular questions
            questions = ChatbotQuestion.objects.filter(
                is_active=True,
            ).order_by('-usage_count', '-priority')[:limit]
        
        return list(questions)
    
    @staticmethod
    def get_user_interaction_history(user: User, limit: int = 10) -> List[Dict]:
        """Get user's interaction history"""
        sessions = ChatbotSession.objects.filter(
            user=user,
        ).order_by('-created_at')[:limit]
        
        history = []
        for session in sessions:
            messages = ChatbotMessage.objects.filter(
                session=session,
            ).order_by('created_at')[:10]
            
            history.append({
                'session_id': session.session_id,
                'created_at': session.created_at.isoformat(),
                'message_count': messages.count(),
                'messages': [
                    {
                        'type': msg.message_type,
                        'content': msg.content[:100],  # Truncate for display
                        'created_at': msg.created_at.isoformat(),
                    }
                    for msg in messages
                ],
            })
        
        return history
    
    @staticmethod
    def get_user_statistics(user: User) -> Dict:
        """Get user statistics"""
        profile = PersonalizationService.get_or_create_user_profile(user)
        
        sessions = ChatbotSession.objects.filter(user=user)
        messages = ChatbotMessage.objects.filter(session__user=user)
        
        return {
            'total_interactions': profile.total_interactions,
            'total_sessions': profile.total_sessions,
            'average_rating': profile.average_rating,
            'common_topics': profile.common_topics,
            'preferred_categories': profile.preferred_categories,
            'total_sessions_count': sessions.count(),
            'total_messages_count': messages.count(),
            'last_interaction_at': profile.last_interaction_at.isoformat() if profile.last_interaction_at else None,
        }

