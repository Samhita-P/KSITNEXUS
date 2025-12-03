"""
Views for feedback app
"""
from rest_framework import generics, status, permissions, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.db.models import Avg, Count, Q
from .models import FacultyFeedback, FacultyFeedbackSummary
from .serializers import (
    FacultyFeedbackSerializer, FacultyFeedbackCreateSerializer,
    FacultyFeedbackSummarySerializer, FacultyListSerializer, FeedbackStatsSerializer
)

User = get_user_model()


class FeedbackListCreateView(generics.ListCreateAPIView):
    """List and create feedback"""
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['faculty__user__first_name', 'faculty__user__last_name', 'course_name']
    ordering_fields = ['submitted_at', 'overall_rating']
    ordering = ['-submitted_at']
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return FacultyFeedbackCreateSerializer
        return FacultyFeedbackSerializer
    
    def get_queryset(self):
        # Only show feedback for faculty members
        if self.request.user.user_type == 'faculty':
            return FacultyFeedback.objects.filter(faculty=self.request.user)
        return FacultyFeedback.objects.none()
    
    def perform_create(self, serializer):
        # Debug: Print incoming request data
        print("Incoming feedback request:", self.request.data)
        print("Request user:", self.request.user)
        print("Request user type:", getattr(self.request.user, 'user_type', 'unknown'))
        
        # Create feedback (anonymous by default)
        feedback = serializer.save()
        
        # Update faculty feedback summary
        self._update_feedback_summary(feedback.faculty)
    
    def create(self, request, *args, **kwargs):
        """Override create to return full feedback object"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        # Get the created feedback object
        feedback = serializer.instance
        
        # Return the full feedback object using the read serializer
        read_serializer = FacultyFeedbackSerializer(feedback)
        return Response(read_serializer.data, status=status.HTTP_201_CREATED)
    
    def _update_feedback_summary(self, faculty):
        """Update faculty feedback summary"""
        summary, created = FacultyFeedbackSummary.objects.get_or_create(faculty=faculty)
        summary.update_summary()


class FeedbackDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Feedback detail view"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = FacultyFeedbackSerializer
    
    def get_queryset(self):
        # Only faculty can see their own feedback
        if self.request.user.user_type == 'faculty':
            return FacultyFeedback.objects.filter(faculty=self.request.user)
        return FacultyFeedback.objects.none()


class FacultyFeedbackView(generics.ListAPIView):
    """Get feedback for specific faculty"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = FacultyFeedbackSerializer
    
    def get_queryset(self):
        try:
            faculty_id = self.kwargs['faculty_id']
            faculty = User.objects.get(id=faculty_id, user_type='faculty')
            
            # Only faculty can see their own feedback
            if self.request.user == faculty:
                return FacultyFeedback.objects.filter(faculty=faculty)
            return FacultyFeedback.objects.none()
        except User.DoesNotExist:
            return FacultyFeedback.objects.none()
        except Exception as e:
            print(f"Error in FacultyFeedbackView.get_queryset: {e}")
            import traceback
            traceback.print_exc()
            return FacultyFeedback.objects.none()


class FeedbackSummaryView(generics.RetrieveAPIView):
    """Get feedback summary for faculty"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = FacultyFeedbackSummarySerializer
    
    def get_object(self):
        # Only faculty can see their own summary
        if self.request.user.user_type != 'faculty':
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Only faculty members can view feedback summaries")
        
        try:
            summary, created = FacultyFeedbackSummary.objects.get_or_create(faculty=self.request.user)
            if created:
                summary.update_summary()
            return summary
        except Exception as e:
            print(f"Error in FeedbackSummaryView.get_object: {e}")
            import traceback
            traceback.print_exc()
            from rest_framework.exceptions import NotFound
            raise NotFound("Feedback summary not found")


class MyFeedbackView(generics.ListAPIView):
    """User's submitted feedback"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = FacultyFeedbackSerializer
    
    def get_queryset(self):
        # Only show feedback submitted by the authenticated user
        if self.request.user.user_type == 'student':
            return FacultyFeedback.objects.filter(submitted_by=self.request.user).order_by('-submitted_at')
        return FacultyFeedback.objects.none()


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def faculty_list_for_feedback(request):
    """Get list of faculty members for feedback form"""
    if request.user.user_type not in ['student', 'admin']:
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    faculty = User.objects.filter(
        user_type='faculty',
        faculty_profile__is_active=True
    ).select_related('faculty_profile')
    
    serializer = FacultyListSerializer(faculty, many=True)
    return Response(serializer.data)


class FacultyListView(generics.ListAPIView):
    """Get list of faculty members for feedback form"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = FacultyListSerializer
    
    def get_queryset(self):
        if self.request.user.user_type not in ['student', 'admin']:
            return User.objects.none()
        
        return User.objects.filter(
            user_type='faculty',
            faculty_profile__is_active=True
        ).select_related('faculty_profile', 'feedback_summary')


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def feedback_stats(request):
    """Get feedback statistics"""
    if request.user.user_type not in ['admin', 'faculty']:
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    # Calculate statistics
    total_feedback = FacultyFeedback.objects.count()
    average_rating = FacultyFeedback.objects.aggregate(
        avg_rating=Avg('overall_rating')
    )['avg_rating'] or 0
    
    # Rating distribution
    feedback_by_rating = {}
    for rating in range(1, 6):
        count = FacultyFeedback.objects.filter(overall_rating=rating).count()
        feedback_by_rating[f'rating_{rating}'] = count
    
    # Top rated faculty
    top_rated_faculty = FacultyFeedbackSummary.objects.filter(
        total_feedback_count__gt=0
    ).order_by('-avg_overall_rating')[:5]
    
    top_rated_data = FacultyFeedbackSummarySerializer(top_rated_faculty, many=True).data
    
    # Recent feedback
    recent_feedback = FacultyFeedback.objects.select_related('faculty').order_by('-submitted_at')[:10]
    recent_data = FacultyFeedbackSerializer(recent_feedback, many=True).data
    
    stats = {
        'total_feedback': total_feedback,
        'average_rating': round(average_rating, 2),
        'feedback_by_rating': feedback_by_rating,
        'top_rated_faculty': top_rated_data,
        'recent_feedback': recent_data
    }
    
    return Response(stats)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def submit_feedback(request):
    """Submit faculty feedback"""
    print("Incoming feedback request:", request.data)
    print("Request user:", request.user)
    print("Request user type:", getattr(request.user, 'user_type', 'unknown'))
    
    if request.user.user_type not in ['student', 'admin']:
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    serializer = FacultyFeedbackCreateSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        feedback = serializer.save()
        
        # Update faculty feedback summary
        summary, created = FacultyFeedbackSummary.objects.get_or_create(faculty=feedback.faculty)
        summary.update_summary()
        
        # Return the full feedback object using the read serializer
        read_serializer = FacultyFeedbackSerializer(feedback)
        return Response(read_serializer.data, status=status.HTTP_201_CREATED)
    
    print("Serializer errors:", serializer.errors)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)