"""
Views for recommendations app
"""
from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from .models import (
    Recommendation, UserPreference, ContentInteraction,
    UserSimilarity, ItemSimilarity
)
from .serializers import (
    RecommendationSerializer, RecommendationCreateSerializer,
    RecommendationFeedbackSerializer, UserPreferenceSerializer,
    UserPreferenceUpdateSerializer, ContentInteractionSerializer,
    ContentInteractionCreateSerializer, UserSimilaritySerializer,
    ItemSimilaritySerializer,
)
from .services import RecommendationService

User = get_user_model()


class RecommendationListView(generics.ListAPIView):
    """List recommendations for the current user"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = RecommendationSerializer
    
    def get_queryset(self):
        user = self.request.user
        content_type = self.request.query_params.get('content_type')
        recommendation_type = self.request.query_params.get('recommendation_type', 'content_based')
        exclude_dismissed = self.request.query_params.get('exclude_dismissed', 'true').lower() == 'true'
        exclude_viewed = self.request.query_params.get('exclude_viewed', 'false').lower() == 'true'
        limit = int(self.request.query_params.get('limit', 10))
        
        # Get recommendations using the service
        recommendations = RecommendationService.get_recommendations(
            user=user,
            content_type=content_type or 'notice',  # Default to notice
            limit=limit,
            recommendation_type=recommendation_type,
            exclude_dismissed=exclude_dismissed,
            exclude_viewed=exclude_viewed,
        )
        
        return recommendations


class RecommendationCreateView(generics.CreateAPIView):
    """Create recommendations for the current user"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = RecommendationCreateSerializer
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = request.user
        content_type = serializer.validated_data['content_type']
        content_id = serializer.validated_data['content_id']
        recommendation_type = serializer.validated_data.get('recommendation_type', 'content_based')
        limit = serializer.validated_data.get('limit', 10)
        
        # Get recommendations using the service
        recommendations = RecommendationService.get_recommendations(
            user=user,
            content_type=content_type,
            limit=limit,
            recommendation_type=recommendation_type,
        )
        
        # Filter by content_id if specified
        if content_id:
            recommendations = [
                rec for rec in recommendations
                if rec.content_id == content_id
            ]
        
        response_serializer = RecommendationSerializer(recommendations, many=True)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_notice_recommendations(request):
    """Get notice recommendations for the current user"""
    limit = int(request.query_params.get('limit', 10))
    recommendation_type = request.query_params.get('recommendation_type', 'content_based')
    
    recommendations = RecommendationService.get_recommendations(
        user=request.user,
        content_type='notice',
        limit=limit,
        recommendation_type=recommendation_type,
    )
    
    serializer = RecommendationSerializer(recommendations, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_study_group_recommendations(request):
    """Get study group recommendations for the current user"""
    limit = int(request.query_params.get('limit', 10))
    recommendation_type = request.query_params.get('recommendation_type', 'content_based')
    
    recommendations = RecommendationService.get_recommendations(
        user=request.user,
        content_type='study_group',
        limit=limit,
        recommendation_type=recommendation_type,
    )
    
    serializer = RecommendationSerializer(recommendations, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_resource_recommendations(request):
    """Get resource recommendations for the current user"""
    limit = int(request.query_params.get('limit', 10))
    recommendation_type = request.query_params.get('recommendation_type', 'content_based')
    
    recommendations = RecommendationService.get_recommendations(
        user=request.user,
        content_type='resource',
        limit=limit,
        recommendation_type=recommendation_type,
    )
    
    serializer = RecommendationSerializer(recommendations, many=True)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def submit_recommendation_feedback(request):
    """Submit feedback on a recommendation"""
    serializer = RecommendationFeedbackSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    
    content_type = request.data.get('content_type')
    content_id = request.data.get('content_id')
    recommendation_type = request.data.get('recommendation_type')
    feedback_type = serializer.validated_data['feedback_type']
    feedback_data = serializer.validated_data['feedback_data']
    
    recommendation = RecommendationService.submit_feedback(
        user=request.user,
        content_type=content_type,
        content_id=content_id,
        feedback_type=feedback_type,
        feedback_data=feedback_data,
        recommendation_type=recommendation_type,
    )
    
    if recommendation:
        response_serializer = RecommendationSerializer(recommendation)
        return Response(response_serializer.data, status=status.HTTP_200_OK)
    else:
        return Response(
            {'error': 'Recommendation not found'},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def dismiss_recommendation(request, recommendation_id):
    """Dismiss a recommendation"""
    recommendation = get_object_or_404(
        Recommendation,
        id=recommendation_id,
        user=request.user
    )
    
    dismissed_rec = RecommendationService.dismiss_recommendation(
        user=request.user,
        content_type=recommendation.content_type,
        content_id=recommendation.content_id,
        recommendation_type=recommendation.recommendation_type,
    )
    
    if dismissed_rec:
        serializer = RecommendationSerializer(dismissed_rec)
        return Response(serializer.data, status=status.HTTP_200_OK)
    else:
        return Response(
            {'error': 'Recommendation not found'},
            status=status.HTTP_404_NOT_FOUND
        )


class UserPreferenceView(generics.RetrieveUpdateAPIView):
    """Get and update user preferences"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserPreferenceSerializer
    
    def get_object(self):
        content_type = self.request.query_params.get('content_type', 'notice')
        preference, created = UserPreference.objects.get_or_create(
            user=self.request.user,
            content_type=content_type,
        )
        return preference
    
    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return UserPreferenceUpdateSerializer
        return UserPreferenceSerializer
    
    def update(self, request, *args, **kwargs):
        preference = self.get_object()
        serializer = UserPreferenceUpdateSerializer(
            preference,
            data=request.data,
            partial=True
        )
        serializer.is_valid(raise_exception=True)
        
        # Update preference fields
        if 'preferences' in serializer.validated_data:
            preference.preferences = serializer.validated_data['preferences']
        if 'interests' in serializer.validated_data:
            preference.interests = serializer.validated_data['interests']
        if 'behavior_patterns' in serializer.validated_data:
            preference.behavior_patterns = serializer.validated_data['behavior_patterns']
        if 'weight_preferences' in serializer.validated_data:
            preference.weight_preferences = serializer.validated_data['weight_preferences']
        
        preference.save()
        
        response_serializer = UserPreferenceSerializer(preference)
        return Response(response_serializer.data, status=status.HTTP_200_OK)


class ContentInteractionListView(generics.ListCreateAPIView):
    """List and create content interactions"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ContentInteractionSerializer
    
    def get_queryset(self):
        return ContentInteraction.objects.filter(
            user=self.request.user
        ).order_by('-created_at')
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ContentInteractionCreateSerializer
        return ContentInteractionSerializer
    
    def create(self, request, *args, **kwargs):
        serializer = ContentInteractionCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        interaction = RecommendationService.track_interaction(
            user=request.user,
            content_type=serializer.validated_data['content_type'],
            content_id=serializer.validated_data['content_id'],
            interaction_type=serializer.validated_data['interaction_type'],
            rating=serializer.validated_data.get('rating'),
            duration=serializer.validated_data.get('duration'),
            metadata=serializer.validated_data.get('metadata', {}),
        )
        
        response_serializer = ContentInteractionSerializer(interaction)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_popular_items(request):
    """Get popular items"""
    content_type = request.query_params.get('content_type', 'notice')
    limit = int(request.query_params.get('limit', 10))
    
    # Get popular content using the service
    popular_items = RecommendationService._get_popular_content(
        content_type,
        exclude_ids=[],
        limit=limit,
    )
    
    return Response(popular_items, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_trending_items(request):
    """Get trending items"""
    from django.utils import timezone
    from datetime import timedelta
    
    content_type = request.query_params.get('content_type', 'notice')
    limit = int(request.query_params.get('limit', 10))
    days = int(request.query_params.get('days', 7))
    
    time_window = timezone.now() - timedelta(days=days)
    
    # Get trending content using the service
    trending_items = RecommendationService._get_trending_content(
        content_type,
        time_window,
        exclude_ids=[],
        limit=limit,
    )
    
    return Response(trending_items, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def refresh_recommendations(request):
    """Refresh recommendations for the current user"""
    content_type = request.data.get('content_type', 'notice')
    recommendation_type = request.data.get('recommendation_type', 'content_based')
    limit = int(request.data.get('limit', 10))
    
    # Clear existing recommendations (optional)
    if request.data.get('clear_existing', False):
        Recommendation.objects.filter(
            user=request.user,
            content_type=content_type,
            recommendation_type=recommendation_type,
        ).delete()
    
    # Generate new recommendations
    recommendations = RecommendationService.get_recommendations(
        user=request.user,
        content_type=content_type,
        limit=limit,
        recommendation_type=recommendation_type,
    )
    
    serializer = RecommendationSerializer(recommendations, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)
