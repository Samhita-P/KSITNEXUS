"""
Enhanced chatbot views with NLP capabilities
"""
from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from .models import ChatbotSession, ChatbotMessage
from .models_nlp import (
    ConversationContext, ChatbotUserProfile, ChatbotAction, ChatbotActionExecution
)
from .services import (
    NLPService, KnowledgeBaseService, PersonalizationService, IntegrationService
)
from .serializers import ChatbotQuestionSerializer
from .serializers_nlp import (
    ConversationContextSerializer, ChatbotUserProfileSerializer,
    ChatbotActionSerializer, ChatbotActionExecutionSerializer,
    UpdateUserProfileSerializer,
)

User = get_user_model()


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_conversation_context(request, session_id):
    """Get conversation context for a session"""
    try:
        session = ChatbotSession.objects.get(session_id=session_id)
    except ChatbotSession.DoesNotExist:
        return Response(
            {'error': 'Session not found'},
            status=status.HTTP_404_NOT_FOUND,
        )
    
    context = NLPService.get_conversation_context(session)
    
    if not context:
        return Response({
            'session_id': session_id,
            'context_variables': {},
            'current_intent': None,
            'conversation_state': 'idle',
            'conversation_history': [],
        })
    
    return Response({
        'session_id': session_id,
        'context_variables': context.context_variables,
        'current_intent': context.current_intent,
        'conversation_state': context.conversation_state,
        'detected_entities': context.detected_entities,
        'sentiment_score': context.sentiment_score,
        'sentiment_label': context.sentiment_label,
        'conversation_history': context.conversation_history,
    })


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def clear_conversation_context(request, session_id):
    """Clear conversation context"""
    try:
        session = ChatbotSession.objects.get(session_id=session_id)
    except ChatbotSession.DoesNotExist:
        return Response(
            {'error': 'Session not found'},
            status=status.HTTP_404_NOT_FOUND,
        )
    
    NLPService.clear_conversation_context(session)
    
    return Response({'message': 'Conversation context cleared successfully'})


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_user_profile(request):
    """Get user chatbot profile"""
    profile = PersonalizationService.get_or_create_user_profile(request.user)
    preferences = PersonalizationService.get_user_preferences(request.user)
    statistics = PersonalizationService.get_user_statistics(request.user)
    
    return Response({
        'profile': {
            'id': profile.id,
            'user_id': profile.user.id,
            'preferred_language': profile.preferred_language,
            'response_style': profile.response_style,
            'preferences': profile.preferences,
            'common_topics': profile.common_topics,
            'preferred_categories': profile.preferred_categories,
            'is_personalized': profile.is_personalized,
            'total_interactions': profile.total_interactions,
            'total_sessions': profile.total_sessions,
            'average_rating': profile.average_rating,
            'last_interaction_at': profile.last_interaction_at.isoformat() if profile.last_interaction_at else None,
        },
        'preferences': preferences,
        'statistics': statistics,
    })


@api_view(['PUT', 'PATCH'])
@permission_classes([permissions.IsAuthenticated])
def update_user_profile(request):
    """Update user chatbot profile"""
    serializer = UpdateUserProfileSerializer(data=request.data)
    if serializer.is_valid():
        preferences = serializer.validated_data
        PersonalizationService.update_user_preferences(request.user, preferences)
        return Response({'message': 'User profile updated successfully'})
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_personalized_recommendations(request):
    """Get personalized question recommendations"""
    limit = int(request.query_params.get('limit', 5))
    recommendations = PersonalizationService.get_personalized_recommendations(
        request.user,
        limit=limit,
    )
    
    serializer = ChatbotQuestionSerializer(recommendations, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_user_interaction_history(request):
    """Get user's interaction history"""
    limit = int(request.query_params.get('limit', 10))
    history = PersonalizationService.get_user_interaction_history(
        request.user,
        limit=limit,
    )
    
    return Response(history)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_user_statistics(request):
    """Get user statistics"""
    statistics = PersonalizationService.get_user_statistics(request.user)
    return Response(statistics)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_available_actions(request):
    """Get available actions"""
    actions = IntegrationService.get_available_actions(user=request.user)
    serializer = ChatbotActionSerializer(actions, many=True)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def execute_action(request, action_id):
    """Execute a chatbot action"""
    action = get_object_or_404(ChatbotAction, id=action_id, is_active=True)
    
    session_id = request.data.get('session_id')
    if not session_id:
        return Response(
            {'error': 'session_id is required'},
            status=status.HTTP_400_BAD_REQUEST,
        )
    
    try:
        session = ChatbotSession.objects.get(session_id=session_id)
    except ChatbotSession.DoesNotExist:
        return Response(
            {'error': 'Session not found'},
            status=status.HTTP_404_NOT_FOUND,
        )
    
    parameters = request.data.get('parameters', {})
    
    result = IntegrationService.execute_action(
        action,
        session,
        request.user,
        parameters,
    )
    
    # Get execution record
    execution = ChatbotActionExecution.objects.filter(
        action=action,
        session=session,
    ).order_by('-created_at').first()
    
    if execution:
        serializer = ChatbotActionExecutionSerializer(execution)
        return Response(serializer.data)
    
    return Response(result)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_answer_quality_metrics(request, question_id):
    """Get answer quality metrics for a question"""
    from .models import ChatbotQuestion
    
    question = get_object_or_404(ChatbotQuestion, id=question_id)
    metrics = KnowledgeBaseService.get_answer_quality_metrics(question)
    
    return Response(metrics)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_suggested_improvements(request, question_id):
    """Get suggested improvements for a question"""
    from .models import ChatbotQuestion
    
    question = get_object_or_404(ChatbotQuestion, id=question_id)
    suggestions = KnowledgeBaseService.suggest_improvements(question)
    
    return Response({'suggestions': suggestions})


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def cluster_questions(request):
    """Cluster similar questions"""
    threshold = float(request.data.get('threshold', 0.7))
    
    clusters = KnowledgeBaseService.cluster_similar_questions(threshold=threshold)
    
    return Response({'clusters': clusters})


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_unanswered_questions(request):
    """Get unanswered questions"""
    limit = int(request.query_params.get('limit', 10))
    unanswered = KnowledgeBaseService.get_unanswered_questions(limit=limit)
    
    return Response(unanswered)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_popular_topics(request):
    """Get popular topics"""
    limit = int(request.query_params.get('limit', 10))
    topics = KnowledgeBaseService.get_popular_topics(limit=limit)
    
    return Response(topics)

