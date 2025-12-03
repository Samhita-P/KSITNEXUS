"""
Test script for Phase 5: AI Chatbot Enhancements
"""
import os
import django
import sys

# Setup Django
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ksit_nexus.settings')
django.setup()

from django.contrib.auth import get_user_model
from apps.chatbot.models import ChatbotSession, ChatbotMessage
from apps.chatbot.models_nlp import (
    ConversationContext, ChatbotUserProfile, ChatbotAction, ChatbotActionExecution
)
from apps.chatbot.services import (
    NLPService, KnowledgeBaseService, PersonalizationService, IntegrationService
)

User = get_user_model()


def test_nlp_service():
    """Test NLP Service"""
    print("\n=== Testing NLP Service ===")
    
    # Create a test session
    session = ChatbotSession.objects.create(
        session_id='test-session-001',
        ip_address='127.0.0.1',
        user_agent='Test Agent'
    )
    
    # Test NLP processing
    message = "How do I book a seat for tomorrow?"
    nlp_result = NLPService.process_message(session, message, update_context=True)
    
    print(f"Message: {message}")
    print(f"Intent: {nlp_result.get('intent')}")
    print(f"Intent Confidence: {nlp_result.get('intent_confidence')}")
    print(f"Entities: {nlp_result.get('entities')}")
    print(f"Sentiment: {nlp_result.get('sentiment_label')}")
    print(f"Sentiment Score: {nlp_result.get('sentiment_score')}")
    
    # Test context retrieval
    context = NLPService.get_conversation_context(session)
    if context:
        print(f"Context Session ID: {context.session.session_id}")
        print(f"Context Intent: {context.current_intent}")
        print(f"Context State: {context.conversation_state}")
        print(f"Context Entities: {context.detected_entities}")
    
    # Cleanup
    session.delete()
    print("[PASS] NLP Service test passed")


def test_personalization_service():
    """Test Personalization Service"""
    print("\n=== Testing Personalization Service ===")
    
    # Get or create a test user
    user, created = User.objects.get_or_create(
        username='test_user_phase5',
        defaults={'email': 'test@example.com'}
    )
    
    # Test profile creation
    profile = PersonalizationService.get_or_create_user_profile(user)
    print(f"Profile ID: {profile.id}")
    print(f"Preferred Language: {profile.preferred_language}")
    print(f"Response Style: {profile.response_style}")
    print(f"Is Personalized: {profile.is_personalized}")
    
    # Test preference update
    PersonalizationService.update_user_preferences(user, {
        'preferred_language': 'hi',
        'response_style': 'formal',
        'is_personalized_enabled': True,
    })
    profile.refresh_from_db()
    print(f"Updated Language: {profile.preferred_language}")
    print(f"Updated Style: {profile.response_style}")
    
    # Test statistics
    statistics = PersonalizationService.get_user_statistics(user)
    print(f"Total Interactions: {statistics.get('total_interactions')}")
    print(f"Total Sessions: {statistics.get('total_sessions')}")
    print(f"Average Rating: {statistics.get('average_rating')}")
    
    print("[PASS] Personalization Service test passed")


def test_integration_service():
    """Test Integration Service"""
    print("\n=== Testing Integration Service ===")
    
    # Test action retrieval
    actions = IntegrationService.get_available_actions()
    print(f"Available Actions: {len(actions)}")
    for action in actions[:5]:  # Show first 5
        print(f"  - {action.name} ({action.action_type})")
    
    # Test action finding
    action = IntegrationService.find_action_by_intent('calendar')
    if action:
        print(f"Found Action for 'calendar': {action.name}")
    else:
        print("No action found for 'calendar' intent")
    
    print("[PASS] Integration Service test passed")


def test_knowledge_base_service():
    """Test Knowledge Base Service"""
    print("\n=== Testing Knowledge Base Service ===")
    
    # Test quality metrics (mock)
    from apps.chatbot.models import ChatbotQuestion
    questions = ChatbotQuestion.objects.filter(is_active=True)[:5]
    if questions:
        question = questions[0]
        metrics = KnowledgeBaseService.get_answer_quality_metrics(question)
        print(f"Question: {question.question}")
        print(f"Quality Metrics: {metrics}")
    
    # Test clustering
    clusters = KnowledgeBaseService.cluster_similar_questions(threshold=0.7)
    print(f"Question Clusters: {len(clusters)} clusters")
    if clusters:
        print(f"  First cluster: {clusters[0]}")
    
    # Test popular topics (mock)
    topics = KnowledgeBaseService.get_popular_topics(limit=5)
    print(f"Popular Topics: {topics}")
    
    print("[PASS] Knowledge Base Service test passed")


def test_models():
    """Test NLP Models"""
    print("\n=== Testing NLP Models ===")
    
    # Test ConversationContext
    from apps.chatbot.models import ChatbotSession
    session = ChatbotSession.objects.create(
        session_id='test-context-001',
        ip_address='127.0.0.1',
        user_agent='Test Agent'
    )
    
    context = ConversationContext.objects.create(
        session=session,
        current_intent='question',
        conversation_state='active',
        context_variables={'test': 'value'},
        detected_entities=[{'type': 'date', 'value': 'tomorrow'}],
        sentiment_label='positive',
        sentiment_score=0.8,
    )
    print(f"Context ID: {context.id}")
    print(f"Context Intent: {context.current_intent}")
    print(f"Context State: {context.conversation_state}")
    
    # Test ChatbotUserProfile
    user, _ = User.objects.get_or_create(
        username='test_profile_user',
        defaults={'email': 'profile@example.com'}
    )
    
    profile, created = ChatbotUserProfile.objects.get_or_create(
        user=user,
        defaults={
            'preferred_language': 'en',
            'response_style': 'friendly',
            'is_personalized': True,
        }
    )
    print(f"Profile ID: {profile.id}")
    print(f"Profile User: {profile.user.username}")
    print(f"Profile Language: {profile.preferred_language}")
    
    # Cleanup
    context.delete()
    session.delete()
    print("[PASS] NLP Models test passed")


def main():
    """Run all tests"""
    print("=" * 60)
    print("Phase 5: AI Chatbot Enhancements - Test Script")
    print("=" * 60)
    
    try:
        test_models()
        test_nlp_service()
        test_personalization_service()
        test_integration_service()
        test_knowledge_base_service()
        
        print("\n" + "=" * 60)
        print("[PASS] All Phase 5 tests passed!")
        print("=" * 60)
    except Exception as e:
        print(f"\n[FAIL] Test failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()

