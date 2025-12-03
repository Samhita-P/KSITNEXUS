"""
Views for study_groups app
"""
from rest_framework import generics, status, permissions, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.contrib.auth import get_user_model
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.http import HttpResponse, Http404
from django.conf import settings
import os
import mimetypes
from .models import StudyGroup, GroupMembership, GroupMessage, Resource, UpcomingEvent, GroupJoinRequest, GroupReport
from .serializers import (
    StudyGroupSerializer, StudyGroupCreateSerializer, StudyGroupListSerializer,
    GroupMembershipSerializer, GroupMessageSerializer, GroupMessageCreateSerializer,
    ResourceSerializer, ResourceCreateSerializer, UpcomingEventSerializer,
    EventCreateSerializer, GroupJoinRequestSerializer, GroupJoinRequestCreateSerializer,
    GroupJoinRequestUpdateSerializer
)

User = get_user_model()


def check_group_membership(group_id, user):
    """Helper function to check if user is a member of the group and return appropriate error if not"""
    group = get_object_or_404(StudyGroup, id=group_id)
    
    if not user.is_authenticated:
        return None, Response(
            {'error': 'Authentication required'},
            status=status.HTTP_401_UNAUTHORIZED
        )
    
    if not GroupMembership.objects.filter(group=group, user=user).exists():
        return None, Response(
            {'error': 'You are not a member of this group. Please join the group to access these features.'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    return group, None


class StudyGroupListCreateView(generics.ListCreateAPIView):
    """List and create study groups"""
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description', 'subject', 'tags']
    ordering_fields = ['created_at', 'name']
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return StudyGroupCreateSerializer
        return StudyGroupListSerializer
    
    def create(self, request, *args, **kwargs):
        """Override create to return user's groups after creation"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        group = serializer.save()
        
        # Get all groups user is a member of (for My Groups tab)
        user_groups = StudyGroup.objects.filter(
            Q(creator=request.user) | Q(members__user=request.user, members__is_active=True)
        ).distinct().prefetch_related('members', 'creator')
        
        # Return the created group and all user's groups
        group_serializer = StudyGroupSerializer(group, context={'request': request})
        user_groups_serializer = StudyGroupListSerializer(user_groups, many=True, context={'request': request})
        
        return Response({
            'group': group_serializer.data,
            'user_groups': user_groups_serializer.data,
            'message': 'Study group created successfully'
        }, status=status.HTTP_201_CREATED)
    
    def get_queryset(self):
        # Only authenticated users can access study groups
        if not self.request.user.is_authenticated:
            return StudyGroup.objects.none()
        
        # Check if user is faculty
        is_faculty = hasattr(self.request.user, 'facultyprofile')
        
        if is_faculty:
            # Faculty can see all groups including closed ones
            return StudyGroup.objects.all().prefetch_related('members', 'creator')
        else:
            # Students can only see active groups (not closed or suspended)
            return StudyGroup.objects.filter(
                Q(is_public=True) | Q(creator=self.request.user) | Q(members__user=self.request.user),
                Q(status='active') | Q(status='reported')  # Students can see active and reported groups
            ).distinct().prefetch_related('members', 'creator')


class StudyGroupDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Study group detail view"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = StudyGroupSerializer
    
    def get_queryset(self):
        # Only authenticated users can access study groups
        if not self.request.user.is_authenticated:
            return StudyGroup.objects.none()
        
        # Check if user is faculty
        is_faculty = hasattr(self.request.user, 'facultyprofile')
        
        if is_faculty:
            # Faculty can see all groups including closed ones
            return StudyGroup.objects.all().prefetch_related('members', 'creator')
        else:
            # Students can only see active groups (not closed or suspended)
            return StudyGroup.objects.filter(
                Q(is_public=True) | Q(creator=self.request.user) | Q(members__user=self.request.user),
                Q(status='active') | Q(status='reported')  # Students can see active and reported groups
            ).distinct().prefetch_related('members', 'creator')




class GroupMessageListCreateView(generics.ListCreateAPIView):
    """Group messages list and create"""
    permission_classes = [permissions.IsAuthenticated]
    # Remove parser_classes to use default JSON parser
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return GroupMessageCreateSerializer
        return GroupMessageSerializer
    
    def get_queryset(self):
        group_id = self.kwargs['pk']
        # Only authenticated users can see messages
        if not self.request.user.is_authenticated:
            return GroupMessage.objects.none()
        
        # Check if user is member of the group
        if not GroupMembership.objects.filter(group_id=group_id, user=self.request.user).exists():
            return GroupMessage.objects.none()
        
        # Use select_related to optimize database queries and ensure sender is loaded
        return GroupMessage.objects.filter(group_id=group_id).select_related('sender', 'reply_to').order_by('created_at')
    
    def get_serializer_context(self):
        """Add request to serializer context"""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    def create(self, request, *args, **kwargs):
        group_id = self.kwargs['pk']
        group = get_object_or_404(StudyGroup, id=group_id)
        
        # Only authenticated users can send messages
        if not request.user.is_authenticated:
            return Response(
                {'error': 'Authentication required to send messages'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        # Check if user is member of the group
        if not GroupMembership.objects.filter(group=group, user=request.user).exists():
            return Response(
                {'error': 'You are not a member of this group. Please join the group to send messages.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Create a mutable copy of request.data if needed
        mutable_data = request.data.copy() if hasattr(request.data, 'copy') else request.data
        
        # Get serializer with context
        serializer = self.get_serializer(data=mutable_data, context={
            'request': request,
            'sender': request.user,
            'group': group
        })
        serializer.is_valid(raise_exception=True)
        message = serializer.save()
        
        # Return the full message using GroupMessageSerializer
        response_serializer = GroupMessageSerializer(message, context={'request': request})
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class ResourceListCreateView(generics.ListCreateAPIView):
    """Group resources list and create"""
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ResourceCreateSerializer
        return ResourceSerializer
    
    def create(self, request, *args, **kwargs):
        group_id = self.kwargs['pk']
        group = get_object_or_404(StudyGroup, id=group_id)
        
        # Only authenticated users can upload resources
        if not request.user.is_authenticated:
            return Response(
                {'error': 'Authentication required to upload resources'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        # Check if user is member of the group
        if not GroupMembership.objects.filter(group=group, user=request.user).exists():
            return Response(
                {'error': 'You are not a member of this group. Please join the group to upload resources.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Create a mutable copy of request.data for MultiPartParser
        mutable_data = request.data.copy()
        
        # Get serializer with context
        serializer = self.get_serializer(data=mutable_data, context={
            'request': request,
            'uploaded_by': request.user,
            'group': group
        })
        serializer.is_valid(raise_exception=True)
        resource = serializer.save()
        
        # Return the full resource using ResourceSerializer
        response_serializer = ResourceSerializer(resource, context={'request': request})
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)
    
    def get_serializer(self, *args, **kwargs):
        serializer = super().get_serializer(*args, **kwargs)
        
        # Add context for GET requests
        if self.request.method == 'GET':
            group_id = self.kwargs['pk']
            group = get_object_or_404(StudyGroup, id=group_id)
            
            # Check if user is member of the group
            if not GroupMembership.objects.filter(group_id=group_id, user=self.request.user).exists():
                return serializer
        
        return serializer
    
    def get_queryset(self):
        group_id = self.kwargs['pk']
        # Only authenticated users can see resources
        if not self.request.user.is_authenticated:
            return Resource.objects.none()
        
        # Check if user is member of the group
        if not GroupMembership.objects.filter(group_id=group_id, user=self.request.user).exists():
            return Resource.objects.none()
        
        return Resource.objects.filter(group_id=group_id).select_related('uploaded_by')
    
    def perform_create(self, serializer):
        # Context is already set in get_serializer method
        serializer.save()


class EventListCreateView(generics.ListCreateAPIView):
    """Group events list and create"""
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return EventCreateSerializer
        return UpcomingEventSerializer
    
    def get_queryset(self):
        group_id = self.kwargs['pk']
        # Only authenticated users can see events
        if not self.request.user.is_authenticated:
            return UpcomingEvent.objects.none()
        
        # Check if user is member of the group
        if not GroupMembership.objects.filter(group_id=group_id, user=self.request.user).exists():
            return UpcomingEvent.objects.none()
        
        return UpcomingEvent.objects.filter(group_id=group_id).select_related('created_by')
    
    def create(self, request, *args, **kwargs):
        group_id = self.kwargs['pk']
        group = get_object_or_404(StudyGroup, id=group_id)
        
        # Only authenticated users can create events
        if not request.user.is_authenticated:
            return Response(
                {'error': 'Authentication required to create events'},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        # Check if user is member of the group
        if not GroupMembership.objects.filter(group=group, user=request.user).exists():
            return Response(
                {'error': 'You are not a member of this group. Please join the group to create events.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Create a mutable copy of request.data if needed
        mutable_data = request.data.copy() if hasattr(request.data, 'copy') else request.data
        
        # Get serializer with context
        serializer = self.get_serializer(data=mutable_data, context={
            'request': request,
            'created_by': request.user,
            'group': group
        })
        serializer.is_valid(raise_exception=True)
        instance = serializer.save()
        
        # Return the full object using UpcomingEventSerializer
        response_serializer = UpcomingEventSerializer(instance, context={'request': request})
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class MyStudyGroupsView(generics.ListAPIView):
    """User's study groups"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = StudyGroupListSerializer
    
    def get_queryset(self):
        # Only authenticated users can see their study groups
        if not self.request.user.is_authenticated:
            return StudyGroup.objects.none()
        
        return StudyGroup.objects.filter(
            Q(creator=self.request.user) | Q(members__user=self.request.user, members__is_active=True)
        ).distinct().prefetch_related('members', 'creator')


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def group_members(request, pk):
    """Get group members"""
    group = get_object_or_404(StudyGroup, id=pk)
    
    # Check if user is member
    if not GroupMembership.objects.filter(group=group, user=request.user).exists():
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    memberships = GroupMembership.objects.filter(group=group, is_active=True).select_related('user')
    serializer = GroupMembershipSerializer(memberships, many=True)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def update_member_role(request, pk, user_id):
    """Update member role (admin only)"""
    group = get_object_or_404(StudyGroup, id=pk)
    
    # Check if user is admin
    membership = GroupMembership.objects.get(group=group, user=request.user)
    if membership.role != 'admin':
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    target_membership = get_object_or_404(GroupMembership, group=group, user_id=user_id)
    new_role = request.data.get('role')
    
    if new_role in ['member', 'moderator']:
        target_membership.role = new_role
        target_membership.save()
        
        return Response({'message': 'Member role updated successfully'})
    
    return Response({'error': 'Invalid role'}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def group_stats(request, pk):
    """Get group statistics"""
    group = get_object_or_404(StudyGroup, id=pk)
    
    # Check if user is member
    if not GroupMembership.objects.filter(group=group, user=request.user).exists():
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    stats = {
        'total_members': group.current_member_count,
        'total_messages': GroupMessage.objects.filter(group=group).count(),
        'total_resources': Resource.objects.filter(group=group).count(),
        'total_events': UpcomingEvent.objects.filter(group=group).count(),
        'recent_activity': GroupMessage.objects.filter(group=group).order_by('-created_at')[:5].values(
            'content', 'created_at', 'sender__first_name', 'sender__last_name'
        )
    }
    
    return Response(stats)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def join_group(request, pk):
    """Join a study group (direct for public, request for private)"""
    group = get_object_or_404(StudyGroup, pk=pk)
    
    # Only authenticated users can join groups
    if not request.user.is_authenticated:
        return Response({'error': 'Authentication required'}, status=status.HTTP_401_UNAUTHORIZED)
    
    user = request.user
    
    # Check if user is already a member
    if GroupMembership.objects.filter(group=group, user=user, is_active=True).exists():
        return Response(
            {'error': 'You are already a member of this group'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Check if group is full
    if group.is_full:
        return Response(
            {'error': 'This group is full'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    if group.is_public:
        # Direct join for public groups
        GroupMembership.objects.create(
            group=group,
            user=user,
            role='member',
            is_active=True
        )
        
        # Get all groups user is a member of (for My Groups tab)
        user_groups = StudyGroup.objects.filter(
            Q(creator=user) | Q(members__user=user, members__is_active=True)
        ).distinct().prefetch_related('members', 'creator')
        
        # Return updated group data along with success message
        from .serializers import StudyGroupSerializer, StudyGroupListSerializer
        joined_group_serializer = StudyGroupSerializer(group, context={'request': request})
        user_groups_serializer = StudyGroupListSerializer(user_groups, many=True, context={'request': request})
        
        return Response(
            {
                'message': 'Successfully joined the group',
                'group': joined_group_serializer.data,
                'user_groups': user_groups_serializer.data  # Return all user's groups
            }, 
            status=status.HTTP_201_CREATED
        )
    else:
        # Create join request for private groups
        message = request.data.get('message', '')
        
        # Check if there's already a pending request
        existing_request = GroupJoinRequest.objects.filter(
            group=group, 
            user=user, 
            status='pending'
        ).first()
        
        if existing_request:
            return Response(
                {'error': 'You already have a pending join request'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create new join request
        join_request = GroupJoinRequest.objects.create(
            group=group,
            user=user,
            message=message
        )
        
        # TODO: Send notification to group admin
        # This would integrate with your notification system
        
        return Response(
            {'message': 'Join request sent to group admin'}, 
            status=status.HTTP_201_CREATED
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def leave_group(request, pk):
    """Leave a study group"""
    group = get_object_or_404(StudyGroup, pk=pk)
    
    # Only authenticated users can leave groups
    if not request.user.is_authenticated:
        return Response({'error': 'Authentication required'}, status=status.HTTP_401_UNAUTHORIZED)
    
    user = request.user
    
    try:
        membership = GroupMembership.objects.get(group=group, user=user, is_active=True)
        membership.is_active = False
        membership.save()
        
        # Return updated group data along with success message
        from .serializers import StudyGroupSerializer
        serializer = StudyGroupSerializer(group, context={'request': request})
        
        return Response({
            'message': 'Successfully left the group',
            'group': serializer.data
        })
    except GroupMembership.DoesNotExist:
        return Response(
            {'error': 'You are not a member of this group'}, 
            status=status.HTTP_400_BAD_REQUEST
        )


class GroupJoinRequestListView(generics.ListAPIView):
    """List join requests for a group (admin only)"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = GroupJoinRequestSerializer
    
    def get_queryset(self):
        group_id = self.kwargs['pk']
        group = get_object_or_404(StudyGroup, id=group_id)
        
        # Check if user is admin of the group
        if not GroupMembership.objects.filter(
            group=group, 
            user=self.request.user, 
            role='admin', 
            is_active=True
        ).exists():
            return GroupJoinRequest.objects.none()
        
        return GroupJoinRequest.objects.filter(group=group, status='pending')


class GroupJoinRequestUpdateView(generics.UpdateAPIView):
    """Update join request status (approve/reject)"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = GroupJoinRequestUpdateSerializer
    
    def get_queryset(self):
        group_id = self.kwargs['pk']
        group = get_object_or_404(StudyGroup, id=group_id)
        
        # Check if user is admin of the group
        if not GroupMembership.objects.filter(
            group=group, 
            user=self.request.user, 
            role='admin', 
            is_active=True
        ).exists():
            return GroupJoinRequest.objects.none()
        
        return GroupJoinRequest.objects.filter(group=group)
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['reviewer'] = self.request.user
        return context


# Study Group Moderation Endpoints
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def report_study_group(request, group_id):
    """Report a study group for moderation"""
    try:
        group = get_object_or_404(StudyGroup, id=group_id)
        
        # Check if user is faculty
        if not hasattr(request.user, 'facultyprofile'):
            return Response(
                {'error': 'Only faculty members can report study groups'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        issue_description = request.data.get('issue_description', '')
        content_to_remove = request.data.get('content_to_remove', '')
        warning_message = request.data.get('warning_message', '')
        
        if not issue_description:
            return Response(
                {'error': 'Issue description is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create group report
        report = GroupReport.objects.create(
            group=group,
            reported_by=request.user,
            issue_description=issue_description,
            content_to_remove=content_to_remove,
            warning_message=warning_message
        )
        
        # Update group status
        group.is_reported = True
        group.reported_by = request.user
        group.reported_at = timezone.now()
        group.report_reason = issue_description
        group.status = 'reported'
        group.save()
        
        # TODO: Send notification to group admin
        # This would typically involve creating a notification
        # and sending it via WebSocket or push notification
        
        return Response({
            'message': 'Group reported successfully',
            'report_id': report.id
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response(
            {'error': str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def close_study_group(request, group_id):
    """Close a study group (faculty only)"""
    try:
        group = get_object_or_404(StudyGroup, id=group_id)
        
        # Check if user is faculty (temporarily allow any authenticated user for testing)
        # if not hasattr(request.user, 'facultyprofile'):
        #     return Response(
        #         {'error': 'Only faculty members can close study groups'}, 
        #         status=status.HTTP_403_FORBIDDEN
        #     )
        
        # Close the group
        group.status = 'closed'
        group.is_active = False
        group.is_public = False  # Make it private so students can't see it
        group.save()
        
        return Response({
            'message': 'Group closed successfully'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def mute_study_group(request, group_id):
    """Mute notifications for a study group (faculty only)"""
    try:
        group = get_object_or_404(StudyGroup, id=group_id)
        
        # Check if user is faculty
        if not hasattr(request.user, 'facultyprofile'):
            return Response(
                {'error': 'Only faculty members can mute study groups'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # TODO: Implement muting logic
        # This would typically involve creating a mute record
        # or updating user preferences to not receive notifications
        
        return Response({
            'message': 'Group muted successfully'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# Faculty-specific endpoints for study group management
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def faculty_study_groups(request):
    """Get study groups for faculty management dashboard"""
    # Allow both faculty and admin to access this endpoint
    is_faculty = hasattr(request.user, 'facultyprofile')
    is_admin = getattr(request.user, 'is_staff', False) or getattr(request.user, 'is_superuser', False)
    user_type = getattr(request.user, 'user_type', None)
    
    if not (is_faculty or is_admin or user_type in ['faculty', 'admin']):
        # If not faculty/admin, still allow but log it
        print(f"Warning: Non-faculty user {request.user.email} accessing faculty endpoint")
    
    # Get filter parameter
    filter_type = request.query_params.get('filter', 'all')
    print(f"Study groups requested with filter: {filter_type} by user: {request.user.email}")
    
    # Base queryset - get ALL study groups
    queryset = StudyGroup.objects.all().prefetch_related('members', 'creator')
    print(f"Total study groups in database: {queryset.count()}")
    
    # Apply filters
    if filter_type == 'active':
        queryset = queryset.filter(status='active')
    elif filter_type == 'reported':
        queryset = queryset.filter(is_reported=True)
    elif filter_type == 'closed':
        queryset = queryset.filter(status='closed')
    # 'all' shows all groups
    
    # Order by creation date
    queryset = queryset.order_by('-created_at')
    print(f"Filtered study groups count: {queryset.count()}")
    
    serializer = StudyGroupListSerializer(queryset, many=True, context={'request': request})
    print(f"Serialized data count: {len(serializer.data)}")
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def report_study_group(request, group_id):
    """Report a study group for faculty review"""
    try:
        group = get_object_or_404(StudyGroup, id=group_id)
        
        # Check if user is faculty (temporarily allow any authenticated user for testing)
        # if not hasattr(request.user, 'facultyprofile'):
        #     return Response(
        #         {'error': 'Only faculty members can report study groups'}, 
        #         status=status.HTTP_403_FORBIDDEN
        #     )
        
        # Get report details
        issue_description = request.data.get('issue_description', '')
        content_to_remove = request.data.get('content_to_remove', '')
        warning_message = request.data.get('warning_message', '')
        
        # Mark group as reported
        group.is_reported = True
        group.reported_by = request.user
        group.reported_at = timezone.now()
        group.report_reason = issue_description  # Store the main issue description
        group.status = 'reported'
        group.save()
        
        # Create a detailed report record
        from .models import GroupReport
        GroupReport.objects.create(
            group=group,
            reported_by=request.user,
            issue_description=issue_description,
            content_to_remove=content_to_remove,
            warning_message=warning_message,
        )
        
        return Response({
            'message': 'Group reported successfully',
            'report_id': GroupReport.objects.filter(group=group).latest('created_at').id
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def approve_study_group(request, group_id):
    """Approve a reported study group"""
    try:
        group = get_object_or_404(StudyGroup, id=group_id)
        
        # Check if user is faculty (temporarily allow any authenticated user for testing)
        # if not hasattr(request.user, 'facultyprofile'):
        #     return Response(
        #         {'error': 'Only faculty members can approve study groups'}, 
        #         status=status.HTTP_403_FORBIDDEN
        #     )
        
        # Approve the group
        group.is_reported = False
        group.reported_by = None
        group.reported_at = None
        group.report_reason = ''
        group.status = 'active'
        group.save()
        
        return Response({
            'message': 'Group approved successfully'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def reject_study_group(request, group_id):
    """Reject a reported study group (closes it)"""
    try:
        group = get_object_or_404(StudyGroup, id=group_id)
        
        # Check if user is faculty (temporarily allow any authenticated user for testing)
        # if not hasattr(request.user, 'facultyprofile'):
        #     return Response(
        #         {'error': 'Only faculty members can reject study groups'}, 
        #         status=status.HTTP_403_FORBIDDEN
        #     )
        
        # Reject and close the group
        group.is_reported = False
        group.reported_by = None
        group.reported_at = None
        group.report_reason = ''
        group.status = 'closed'
        group.is_active = False
        group.is_public = False
        group.save()
        
        return Response({
            'message': 'Group rejected and closed successfully'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def reopen_study_group(request, group_id):
    """Reopen a closed study group"""
    try:
        group = get_object_or_404(StudyGroup, id=group_id)
        
        # Check if user is faculty (temporarily allow any authenticated user for testing)
        # if not hasattr(request.user, 'facultyprofile'):
        #     return Response(
        #         {'error': 'Only faculty members can reopen study groups'}, 
        #         status=status.HTTP_403_FORBIDDEN
        #     )
        
        # Reopen the group
        group.status = 'active'
        group.is_active = True
        group.is_public = True
        group.save()
        
        return Response({
            'message': 'Group reopened successfully'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["GET"])
@permission_classes([permissions.IsAuthenticated])
def download_resource(request, group_id, resource_id):
    """Download a study group resource with proper MIME type"""
    try:
        # Only authenticated users can download resources
        if not request.user.is_authenticated:
            return Response({'error': 'Authentication required'}, status=status.HTTP_401_UNAUTHORIZED)
        
        # Check if user is member of the group
        if not GroupMembership.objects.filter(group_id=group_id, user=request.user).exists():
            return Response({'error': 'You are not a member of this group'}, status=status.HTTP_403_FORBIDDEN)
        
        # Get the resource
        resource = get_object_or_404(Resource, id=resource_id, group_id=group_id)
        
        if not resource.file:
            raise Http404("File not found")
        
        # Get the file path
        file_path = resource.file.path
        
        # Check if file exists
        if not os.path.exists(file_path):
            raise Http404("File not found on server")
        
        # Get MIME type from file extension
        mime_type, _ = mimetypes.guess_type(file_path)
        if not mime_type:
            mime_type = "application/octet-stream"
        
        # Read file content
        with open(file_path, "rb") as f:
            file_content = f.read()
        
        # Increment download count
        resource.download_count += 1
        resource.save(update_fields=["download_count"])
        
        # Create response with proper headers
        response = HttpResponse(file_content, content_type=mime_type)
        response["Content-Disposition"] = f'attachment; filename="{resource.file.name.split("/")[-1]}"'
        response["Content-Length"] = len(file_content)
        
        return response
        
    except Http404:
        raise
    except Exception as e:
        return Response(
            {"error": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
