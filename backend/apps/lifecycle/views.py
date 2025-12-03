"""
Views for lifecycle app
"""
from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.db.models import Q, Count
from django.utils import timezone
from .models import (
    OnboardingStep, UserOnboardingProgress,
    AlumniProfile, MentorshipRequest, AlumniEvent,
    PlacementOpportunity, PlacementApplication, PlacementStatistic
)
from .serializers import (
    OnboardingStepSerializer, UserOnboardingProgressSerializer,
    AlumniProfileSerializer, MentorshipRequestSerializer, AlumniEventSerializer,
    PlacementOpportunitySerializer, PlacementApplicationSerializer, PlacementStatisticSerializer
)

User = get_user_model()


# Onboarding
class OnboardingStepListView(generics.ListAPIView):
    """List onboarding steps"""
    queryset = OnboardingStep.objects.filter(is_active=True)
    serializer_class = OnboardingStepSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = super().get_queryset()
        user_type = self.request.user.user_type
        
        # Filter by target user types
        queryset = queryset.filter(
            Q(target_user_types__contains=[user_type]) | Q(target_user_types=[])
        )
        
        return queryset.order_by('order')


class UserOnboardingProgressView(generics.RetrieveUpdateAPIView):
    """Get or update user onboarding progress"""
    serializer_class = UserOnboardingProgressSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        progress, created = UserOnboardingProgress.objects.get_or_create(
            user=self.request.user
        )
        return progress


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def complete_onboarding_step(request):
    """Mark an onboarding step as completed"""
    step_id = request.data.get('step_id')
    step_data = request.data.get('step_data', {})
    
    if not step_id:
        return Response(
            {'error': 'step_id is required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        step = OnboardingStep.objects.get(id=step_id, is_active=True)
    except OnboardingStep.DoesNotExist:
        return Response(
            {'error': 'Step not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    progress, created = UserOnboardingProgress.objects.get_or_create(
        user=request.user
    )
    
    # Add to completed steps
    if step_id not in progress.completed_steps:
        progress.completed_steps.append(step_id)
    
    # Save step data
    progress.progress_data[str(step_id)] = step_data
    
    # Update current step
    next_step = OnboardingStep.objects.filter(
        is_active=True,
        order__gt=step.order
    ).order_by('order').first()
    
    if next_step:
        progress.current_step = next_step
    else:
        progress.current_step = None
        progress.is_completed = True
        progress.completed_at = timezone.now()
    
    progress.save()
    
    serializer = UserOnboardingProgressSerializer(progress)
    return Response(serializer.data)


# Alumni
class AlumniProfileListView(generics.ListAPIView):
    """List alumni profiles"""
    queryset = AlumniProfile.objects.all()
    serializer_class = AlumniProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        graduation_year = self.request.query_params.get('graduation_year')
        industry = self.request.query_params.get('industry')
        is_mentor = self.request.query_params.get('is_mentor')
        
        if graduation_year:
            queryset = queryset.filter(graduation_year=graduation_year)
        if industry:
            queryset = queryset.filter(industry=industry)
        if is_mentor == 'true':
            queryset = queryset.filter(is_mentor=True, is_available_for_mentorship=True)
        
        return queryset.select_related('user')


class AlumniProfileDetailView(generics.RetrieveUpdateAPIView):
    """Alumni profile detail view"""
    queryset = AlumniProfile.objects.all()
    serializer_class = AlumniProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        if self.request.user.user_type == 'student':
            # Students can only view their own profile
            profile, created = AlumniProfile.objects.get_or_create(user=self.request.user)
            return profile
        return super().get_object()


class MentorshipRequestListView(generics.ListCreateAPIView):
    """List and create mentorship requests"""
    serializer_class = MentorshipRequestSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        queryset = MentorshipRequest.objects.all().select_related('mentee', 'mentor')
        
        if user.user_type == 'student':
            # Students see their sent requests
            queryset = queryset.filter(mentee=user)
        else:
            # Alumni see their received requests
            queryset = queryset.filter(mentor=user)
        
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        return queryset.order_by('-created_at')
    
    def perform_create(self, serializer):
        serializer.save(mentee=self.request.user)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def respond_to_mentorship_request(request, request_id):
    """Respond to a mentorship request"""
    try:
        mentorship_request = MentorshipRequest.objects.get(
            id=request_id,
            mentor=request.user
        )
    except MentorshipRequest.DoesNotExist:
        return Response(
            {'error': 'Mentorship request not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    action = request.data.get('action')  # 'accept' or 'reject'
    response_message = request.data.get('response_message', '')
    
    if action == 'accept':
        mentorship_request.status = 'accepted'
        mentorship_request.mentor_response = response_message
        mentorship_request.started_at = timezone.now()
    elif action == 'reject':
        mentorship_request.status = 'rejected'
        mentorship_request.mentor_response = response_message
    else:
        return Response(
            {'error': 'Invalid action. Use "accept" or "reject"'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    mentorship_request.save()
    
    serializer = MentorshipRequestSerializer(mentorship_request)
    return Response(serializer.data)


class AlumniEventListView(generics.ListCreateAPIView):
    """List and create alumni events"""
    queryset = AlumniEvent.objects.filter(is_active=True)
    serializer_class = AlumniEventSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)


# Placement
class PlacementOpportunityListView(generics.ListCreateAPIView):
    """List and create placement opportunities"""
    serializer_class = PlacementOpportunitySerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = PlacementOpportunity.objects.filter(status='active')
        
        opportunity_type = self.request.query_params.get('type')
        if opportunity_type:
            queryset = queryset.filter(opportunity_type=opportunity_type)
        
        return queryset.order_by('-created_at')
    
    def perform_create(self, serializer):
        serializer.save(posted_by=self.request.user)


class PlacementOpportunityDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Placement opportunity detail view"""
    queryset = PlacementOpportunity.objects.all()
    serializer_class = PlacementOpportunitySerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.views_count += 1
        instance.save(update_fields=['views_count'])
        serializer = self.get_serializer(instance)
        return Response(serializer.data)


class PlacementApplicationListView(generics.ListCreateAPIView):
    """List and create placement applications"""
    serializer_class = PlacementApplicationSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        queryset = PlacementApplication.objects.all().select_related('opportunity', 'applicant')
        
        if user.user_type == 'student':
            queryset = queryset.filter(applicant=user)
        else:
            # Admin/faculty can see all applications
            opportunity_id = self.request.query_params.get('opportunity_id')
            if opportunity_id:
                queryset = queryset.filter(opportunity_id=opportunity_id)
        
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        return queryset.order_by('-created_at')
    
    def perform_create(self, serializer):
        application = serializer.save(applicant=self.request.user)
        # Update opportunity applications count
        application.opportunity.applications_count += 1
        application.opportunity.save(update_fields=['applications_count'])


class PlacementApplicationDetailView(generics.RetrieveUpdateAPIView):
    """Placement application detail view"""
    queryset = PlacementApplication.objects.all()
    serializer_class = PlacementApplicationSerializer
    permission_classes = [permissions.IsAuthenticated]


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def placement_statistics(request):
    """Get placement statistics"""
    stat_type = request.query_params.get('stat_type')
    queryset = PlacementStatistic.objects.all()
    
    if stat_type:
        queryset = queryset.filter(stat_type=stat_type)
    
    serializer = PlacementStatisticSerializer(queryset.order_by('-period_end')[:10], many=True)
    return Response(serializer.data)

















