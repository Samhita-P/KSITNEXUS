"""
Views for chatbot app
"""
from rest_framework import generics, status, permissions, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.db.models import Q, Count, Avg
from django.utils import timezone
from django.shortcuts import get_object_or_404
import uuid
import re
from .models import (
    ChatbotCategory, ChatbotQuestion, ChatbotSession, 
    ChatbotMessage, ChatbotFeedback, ChatbotAnalytics
)
from .models_nlp import (
    ConversationContext, ChatbotUserProfile, ChatbotAction, ChatbotActionExecution
)
from .serializers import (
    ChatbotCategorySerializer, ChatbotQuestionSerializer, ChatbotQuestionCreateSerializer,
    ChatbotSessionSerializer, ChatbotMessageSerializer, ChatbotMessageCreateSerializer,
    ChatbotFeedbackSerializer, ChatbotAnalyticsSerializer, ChatbotQuerySerializer,
    ChatbotResponseSerializer
)
from .services import (
    NLPService, KnowledgeBaseService, PersonalizationService, IntegrationService
)

User = get_user_model()


class ChatbotView(generics.CreateAPIView):
    """Main chatbot view"""
    permission_classes = [permissions.AllowAny]
    serializer_class = ChatbotQuerySerializer
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            message = serializer.validated_data['message']
            session_id = serializer.validated_data.get('session_id')
            category_id = serializer.validated_data.get('category_id')
            
            # Get or create session
            if session_id:
                try:
                    session = ChatbotSession.objects.get(session_id=session_id)
                except ChatbotSession.DoesNotExist:
                    session = None
            else:
                session = None
            
            if not session:
                session = ChatbotSession.objects.create(
                    user=request.user if request.user.is_authenticated else None,
                    session_id=str(uuid.uuid4()),
                    ip_address=request.META.get('REMOTE_ADDR'),
                    user_agent=request.META.get('HTTP_USER_AGENT', '')
                )
            
            # Process message with NLP
            nlp_result = NLPService.process_message(session, message, update_context=True)
            
            # Process the message (enhanced with NLP)
            response = self._process_message(message, session, category_id, nlp_result)
            
            # Personalize response if user is authenticated
            if request.user.is_authenticated:
                response['response'] = PersonalizationService.personalize_response(
                    response['response'],
                    user=request.user,
                )
            
            # Create message records
            user_message = ChatbotMessage.objects.create(
                session=session,
                message_type='user',
                content=message
            )
            
            bot_message = ChatbotMessage.objects.create(
                session=session,
                message_type='bot',
                content=response['response'],
                related_question=response.get('related_question'),
                confidence_score=response.get('confidence_score', 0.0)
            )
            
            # Learn from interaction
            if response.get('related_question'):
                KnowledgeBaseService.learn_from_interaction(
                    response['related_question'],
                    message,
                    response['response'],
                    response.get('confidence_score', 0.0),
                )
                
                # Learn from user interaction for personalization
                if request.user.is_authenticated:
                    PersonalizationService.learn_from_user_interaction(
                        request.user,
                        response['related_question'],
                    )
            
            # Check if action should be executed
            action_result = None
            if nlp_result['intent'] in ['calendar', 'reservation', 'study_group', 'notification']:
                action = IntegrationService.find_action_by_intent(
                    nlp_result['intent'],
                    user=request.user if request.user.is_authenticated else None,
                )
                if action:
                    # Extract parameters from entities
                    parameters = {
                        'intent': nlp_result['intent'],
                        'entities': nlp_result['entities'],
                    }
                    action_result = IntegrationService.execute_action(
                        action,
                        session,
                        request.user if request.user.is_authenticated else None,
                        parameters,
                    )
            
            return Response({
                'response': response['response'],
                'confidence_score': response.get('confidence_score', 0.0),
                'related_questions': response.get('related_questions', []),
                'category': response.get('category', ''),
                'session_id': session.session_id,
                'message_id': bot_message.id,
                'intent': nlp_result.get('intent'),
                'intent_confidence': nlp_result.get('intent_confidence'),
                'entities': nlp_result.get('entities', []),
                'sentiment': nlp_result.get('sentiment_label'),
                'sentiment_score': nlp_result.get('sentiment_score'),
                'action_result': action_result,
            })
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def _process_message(self, message, session, category_id=None, nlp_result=None):
        """Process user message and generate response (enhanced with NLP)"""
        # Simple keyword matching (in production, use more sophisticated NLP)
        message_lower = message.lower()
        
        # Use NLP result to improve matching
        intent = nlp_result.get('intent', 'question') if nlp_result else 'question'
        entities = nlp_result.get('entities', []) if nlp_result else []
        
        # Get questions based on category if specified
        if category_id:
            questions = ChatbotQuestion.objects.filter(
                category_id=category_id, 
                is_active=True
            ).order_by('-priority', '-usage_count')
        else:
            questions = ChatbotQuestion.objects.filter(
                is_active=True
            ).order_by('-priority', '-usage_count')
        
        best_match = None
        best_score = 0
        
        for question in questions:
            score = self._calculate_match_score(message_lower, question)
            
            # Boost score if intent matches category
            if intent == 'question' and question.category.name.lower() in message_lower:
                score += 0.2
            
            # Boost score based on entities
            if entities:
                for entity in entities:
                    if entity.get('value', '').lower() in message_lower:
                        score += 0.1
            
            if score > best_score:
                best_score = score
                best_match = question
        
        if best_match and best_score > 0.3:  # Threshold for matching
            # Increment usage count
            best_match.usage_count += 1
            best_match.save()
            
            return {
                'response': best_match.answer,
                'confidence_score': best_score,
                'related_question': best_match,
                'related_questions': self._get_related_questions(best_match),
                'category': best_match.category.name
            }
        else:
            # Default response for no match
            return {
                'response': "I'm sorry, I couldn't find a relevant answer to your question. Please try rephrasing your question or contact support for assistance.",
                'confidence_score': 0.0,
                'related_questions': [],
                'category': 'General'
            }
    
    def _calculate_match_score(self, message, question):
        """Calculate match score between message and question"""
        score = 0
        
        # Check keywords
        for keyword in question.keywords:
            if keyword.lower() in message:
                score += 0.3
        
        # Check question text
        question_words = set(question.question.lower().split())
        message_words = set(message.split())
        common_words = question_words.intersection(message_words)
        
        if question_words:
            score += (len(common_words) / len(question_words)) * 0.7
        
        return min(score, 1.0)
    
    def _get_related_questions(self, question):
        """Get related questions"""
        related = ChatbotQuestion.objects.filter(
            category=question.category,
            is_active=True
        ).exclude(id=question.id)[:3]
        
        return [{'id': q.id, 'question': q.question} for q in related]


class ChatbotSessionView(generics.ListCreateAPIView):
    """Chatbot session view"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ChatbotSessionSerializer
    
    def get_queryset(self):
        return ChatbotSession.objects.filter(user=self.request.user)


class ChatbotMessageView(generics.ListCreateAPIView):
    """Chatbot messages view"""
    permission_classes = [permissions.AllowAny]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ChatbotMessageCreateSerializer
        return ChatbotMessageSerializer
    
    def get_queryset(self):
        session_id = self.kwargs['session_id']
        try:
            session = ChatbotSession.objects.get(session_id=session_id)
            return ChatbotMessage.objects.filter(session=session).order_by('created_at')
        except ChatbotSession.DoesNotExist:
            return ChatbotMessage.objects.none()
    
    def perform_create(self, serializer):
        session_id = self.kwargs['session_id']
        session = get_object_or_404(ChatbotSession, session_id=session_id)
        serializer.save(session=session)


class CategoryListView(generics.ListAPIView):
    """Chatbot categories view"""
    permission_classes = [permissions.AllowAny]
    serializer_class = ChatbotCategorySerializer
    
    def get_queryset(self):
        return ChatbotCategory.objects.filter(is_active=True).order_by('order', 'name')


class QuestionListView(generics.ListAPIView):
    """Chatbot questions view"""
    permission_classes = [permissions.AllowAny]  # Temporarily allow unauthenticated access for testing
    serializer_class = ChatbotQuestionSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['question', 'answer', 'keywords']
    ordering_fields = ['priority', 'usage_count', 'created_at']
    ordering = ['-priority', '-usage_count']
    
    def get_queryset(self):
        queryset = ChatbotQuestion.objects.filter(is_active=True)
        # Filter by category if category_id is provided
        category_id = self.request.query_params.get('category_id')
        if category_id:
            queryset = queryset.filter(category_id=category_id)
        return queryset


class ChatbotFeedbackView(generics.CreateAPIView):
    """Chatbot feedback view"""
    permission_classes = [permissions.AllowAny]
    serializer_class = ChatbotFeedbackSerializer
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            feedback = serializer.save()
            return Response({
                'message': 'Feedback submitted successfully',
                'feedback': ChatbotFeedbackSerializer(feedback).data
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ChatbotAnalyticsView(generics.RetrieveAPIView):
    """Chatbot analytics view"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ChatbotAnalyticsSerializer
    
    def get_object(self):
        if self.request.user.user_type not in ['admin', 'faculty']:
            return None
        
        # Get or create analytics for today
        today = timezone.now().date()
        analytics, created = ChatbotAnalytics.objects.get_or_create(date=today)
        
        if created:
            # Calculate analytics
            self._calculate_analytics(analytics)
        
        return analytics
    
    def _calculate_analytics(self, analytics):
        """Calculate analytics data"""
        today = analytics.date
        
        # Basic counts
        analytics.total_sessions = ChatbotSession.objects.filter(created_at__date=today).count()
        analytics.total_messages = ChatbotMessage.objects.filter(created_at__date=today).count()
        analytics.unique_users = ChatbotSession.objects.filter(
            created_at__date=today,
            user__isnull=False
        ).values('user').distinct().count()
        
        # Most asked questions
        most_asked = ChatbotQuestion.objects.filter(
            messages__created_at__date=today
        ).annotate(
            message_count=Count('messages')
        ).order_by('-message_count')[:5]
        
        analytics.most_asked_questions = [
            {'question': q.question, 'count': q.message_count} 
            for q in most_asked
        ]
        
        # Average response time (simplified)
        analytics.average_response_time = 2.5  # Placeholder
        
        # Average rating
        ratings = ChatbotFeedback.objects.filter(created_at__date=today).values_list('rating', flat=True)
        analytics.average_rating = sum(ratings) / len(ratings) if ratings else 0
        
        # Resolution rate (simplified)
        total_queries = ChatbotMessage.objects.filter(
            created_at__date=today,
            message_type='user'
        ).count()
        resolved_queries = ChatbotMessage.objects.filter(
            created_at__date=today,
            message_type='bot',
            confidence_score__gt=0.3
        ).count()
        
        analytics.resolution_rate = (resolved_queries / total_queries * 100) if total_queries > 0 else 0
        
        analytics.save()


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def submit_feedback(request):
    """Submit feedback for a chatbot message"""
    message_id = request.data.get('message_id')
    rating = request.data.get('rating')
    comment = request.data.get('comment', '')
    
    if not message_id or not rating:
        return Response(
            {'error': 'message_id and rating are required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        message = ChatbotMessage.objects.get(id=message_id)
    except ChatbotMessage.DoesNotExist:
        return Response(
            {'error': 'Message not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )
    
    feedback = ChatbotFeedback.objects.create(
        message=message,
        rating=rating,
        comment=comment,
        user=request.user if request.user.is_authenticated else None
    )
    
    return Response({
        'message': 'Feedback submitted successfully',
        'feedback': ChatbotFeedbackSerializer(feedback).data
    })


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def chatbot_stats(request):
    """Get chatbot statistics"""
    if request.user.user_type not in ['admin', 'faculty']:
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    stats = {
        'total_questions': ChatbotQuestion.objects.count(),
        'active_questions': ChatbotQuestion.objects.filter(is_active=True).count(),
        'total_sessions': ChatbotSession.objects.count(),
        'total_messages': ChatbotMessage.objects.count(),
        'total_feedback': ChatbotFeedback.objects.count(),
        'average_rating': ChatbotFeedback.objects.aggregate(
            avg_rating=Avg('rating')
        )['avg_rating'] or 0,
        'questions_by_category': {},
        'recent_questions': []
    }
    
    # Questions by category
    for category in ChatbotCategory.objects.all():
        count = ChatbotQuestion.objects.filter(category=category).count()
        stats['questions_by_category'][category.name] = count
    
    # Recent questions
    recent = ChatbotQuestion.objects.order_by('-created_at')[:10]
    stats['recent_questions'] = ChatbotQuestionSerializer(recent, many=True).data
    
    return Response(stats)


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def question_suggestions(request):
    """Get question suggestions based on query"""
    query = request.GET.get('query', '').strip()
    category_id = request.GET.get('category_id')
    limit = int(request.GET.get('limit', 5))
    
    if not query or len(query) < 2:
        return Response([])
    
    # Build queryset
    queryset = ChatbotQuestion.objects.filter(is_active=True)
    
    if category_id:
        queryset = queryset.filter(category_id=category_id)
    
    # Search in question text and keywords
    queryset = queryset.filter(
        Q(question__icontains=query) | 
        Q(keywords__icontains=query) |
        Q(answer__icontains=query)
    ).order_by('-priority', '-usage_count')[:limit]
    
    serializer = ChatbotQuestionSerializer(queryset, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def search_faq(request):
    """Search FAQ questions"""
    query = request.GET.get('query', '').strip()
    category_id = request.GET.get('category_id')
    limit = int(request.GET.get('limit', 10))
    
    if not query:
        return Response([])
    
    # Build queryset
    queryset = ChatbotQuestion.objects.filter(is_active=True)
    
    if category_id:
        queryset = queryset.filter(category_id=category_id)
    
    # Search in question text, answer, and keywords
    queryset = queryset.filter(
        Q(question__icontains=query) | 
        Q(answer__icontains=query) |
        Q(keywords__icontains=query)
    ).order_by('-priority', '-usage_count')[:limit]
    
    serializer = ChatbotQuestionSerializer(queryset, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def popular_questions(request):
    """Get popular questions"""
    category_id = request.GET.get('category_id')
    limit = int(request.GET.get('limit', 10))
    
    # Build queryset
    queryset = ChatbotQuestion.objects.filter(is_active=True)
    
    if category_id:
        queryset = queryset.filter(category_id=category_id)
    
    # Order by usage count and priority
    queryset = queryset.order_by('-usage_count', '-priority')[:limit]
    
    serializer = ChatbotQuestionSerializer(queryset, many=True)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def chat_endpoint(request):
    """Enhanced chat endpoint that returns FAQ answers"""
    message = request.data.get('message', '').strip()
    session_id = request.data.get('session_id')
    category_id = request.data.get('category_id')
    
    if not message:
        return Response(
            {'error': 'Message is required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Get or create session
    if session_id:
        try:
            session = ChatbotSession.objects.get(session_id=session_id)
        except ChatbotSession.DoesNotExist:
            session = None
    else:
        session = None
    
    if not session:
        session = ChatbotSession.objects.create(
            user=request.user if request.user.is_authenticated else None,
            session_id=str(uuid.uuid4()),
            ip_address=request.META.get('REMOTE_ADDR'),
            user_agent=request.META.get('HTTP_USER_AGENT', '')
        )
    
    # Process message with NLP
    nlp_result = NLPService.process_message(session, message, update_context=True)
    
    # Process the message using the existing logic (enhanced with NLP)
    chatbot_view = ChatbotView()
    response = chatbot_view._process_message(message, session, category_id, nlp_result)
    
    # Personalize response if user is authenticated
    if request.user.is_authenticated:
        response['response'] = PersonalizationService.personalize_response(
            response['response'],
            user=request.user,
        )
    
    # Create message records
    user_message = ChatbotMessage.objects.create(
        session=session,
        message_type='user',
        content=message
    )
    
    bot_message = ChatbotMessage.objects.create(
        session=session,
        message_type='bot',
        content=response['response'],
        related_question=response.get('related_question'),
        confidence_score=response.get('confidence_score', 0.0)
    )
    
    # Learn from interaction
    if response.get('related_question'):
        KnowledgeBaseService.learn_from_interaction(
            response['related_question'],
            message,
            response['response'],
            response.get('confidence_score', 0.0),
        )
        
        # Learn from user interaction for personalization
        if request.user.is_authenticated:
            PersonalizationService.learn_from_user_interaction(
                request.user,
                response['related_question'],
            )
    
    # Serialize related questions
    related_questions = []
    if response.get('related_questions'):
        for q in response['related_questions']:
            if isinstance(q, dict):
                related_questions.append(q)
            else:
                related_questions.append({
                    'id': q.id,
                    'question': q.question,
                    'answer': q.answer,
                    'category': q.category.name if hasattr(q, 'category') else 'General'
                })
    
    # Check if action should be executed
    action_result = None
    if nlp_result['intent'] in ['calendar', 'reservation', 'study_group', 'notification']:
        action = IntegrationService.find_action_by_intent(
            nlp_result['intent'],
            user=request.user if request.user.is_authenticated else None,
        )
        if action:
            # Extract parameters from entities
            parameters = {
                'intent': nlp_result['intent'],
                'entities': nlp_result['entities'],
            }
            action_result = IntegrationService.execute_action(
                action,
                session,
                request.user if request.user.is_authenticated else None,
                parameters,
            )
    
    return Response({
        'response': response.get('response', 'I apologize, but I could not process your request. Please try again.'),
        'confidence': response.get('confidence_score', 0.0),
        'category': response.get('category', 'General'),
        'related_questions': related_questions,
        'session_id': session.session_id,
        'message_id': bot_message.id,
        'is_fallback': response.get('confidence_score', 0.0) < 0.3,
        'intent': nlp_result.get('intent'),
        'intent_confidence': nlp_result.get('intent_confidence'),
        'entities': nlp_result.get('entities', []),
        'sentiment': nlp_result.get('sentiment_label'),
        'sentiment_score': nlp_result.get('sentiment_score'),
        'action_result': action_result,
    })