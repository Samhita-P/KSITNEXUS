"""
Views for notices app
"""
from rest_framework import generics, status, permissions, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.contrib.auth import get_user_model
from django.db.models import Q
from django.utils import timezone
from django.shortcuts import get_object_or_404
from .models import Notice, Announcement, NoticeView
from .serializers import (
    NoticeSerializer, NoticeCreateSerializer, NoticeListSerializer,
    NoticeDraftSerializer, AnnouncementSerializer, AnnouncementCreateSerializer,
    NoticeViewSerializer, NoticeViewCreateSerializer
)

User = get_user_model()


class NoticeListCreateView(generics.ListCreateAPIView):
    """List and create notices"""
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'content', 'summary']
    ordering_fields = ['created_at', 'published_at', 'priority', 'view_count']
    ordering = ['-is_pinned', '-published_at', '-created_at']
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return NoticeCreateSerializer
        return NoticeListSerializer
    
    def create(self, request, *args, **kwargs):
        """Override create to return full notice data with camelCase fields"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        # Return the created notice using the full serializer with camelCase fields
        notice = serializer.instance
        response_serializer = NoticeSerializer(notice, context={'request': request})
        headers = self.get_success_headers(response_serializer.data)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED, headers=headers)
    
    def perform_create(self, serializer):
        """Restrict notice creation to faculty and admin only"""
        user = self.request.user
        if user.user_type == 'student':
            raise permissions.PermissionDenied("Students are not allowed to create notices")
        serializer.save(author=user)
    
    def get_queryset(self):
        user = self.request.user
        now = timezone.now()
        
        # Filter based on user type and visibility
        base_queryset = Notice.objects.filter(
            Q(status='published') & 
            Q(publish_at__lte=now) & 
            (Q(expires_at__isnull=True) | Q(expires_at__gt=now))
        ).select_related('author').prefetch_related('views')
        
        # Apply visibility filters
        if user.user_type == 'student':
            # Get all notices that are visible to students
            student_notices = base_queryset.filter(
                Q(visibility='all') | 
                Q(visibility='students')
            )
            
            # For specific branch/year targeting, we'll filter in Python
            # since SQLite doesn't support JSONField contains lookup
            specific_branch_notices = base_queryset.filter(visibility='specific_branch')
            specific_year_notices = base_queryset.filter(visibility='specific_year')
            
            # Get user's branch and year info
            user_branch = ''
            user_year = ''
            if hasattr(user, 'student_profile'):
                user_branch = getattr(user.student_profile, 'branch', '')
                user_year = getattr(user.student_profile, 'year_of_study', '')
            
            # Filter specific branch notices in Python
            filtered_branch_notices = []
            for notice in specific_branch_notices:
                if user_branch in (notice.target_branches or []):
                    filtered_branch_notices.append(notice.id)
            
            # Filter specific year notices in Python
            filtered_year_notices = []
            for notice in specific_year_notices:
                if user_year in (notice.target_years or []):
                    filtered_year_notices.append(notice.id)
            
            # Get all notice IDs that should be visible
            visible_notice_ids = set()
            
            # Add student notices
            visible_notice_ids.update(student_notices.values_list('id', flat=True))
            
            # Add filtered branch notices
            visible_notice_ids.update(filtered_branch_notices)
            
            # Add filtered year notices
            visible_notice_ids.update(filtered_year_notices)
            
            # Return the final queryset with all visible notices
            return base_queryset.filter(id__in=visible_notice_ids)
            
        elif user.user_type == 'faculty':
            return base_queryset.filter(
                Q(visibility='all') | 
                Q(visibility='faculty')
            )
        
        return base_queryset


class NoticeDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Notice detail view"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NoticeSerializer
    
    def get_queryset(self):
        user = self.request.user
        now = timezone.now()
        
        # Show published notices and user's own notices
        return Notice.objects.filter(
            Q(status='published', publish_at__lte=now) | Q(author=user)
        ).select_related('author', 'approved_by').prefetch_related('views')


class NoticeViewView(generics.CreateAPIView):
    """Track notice view"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NoticeViewCreateSerializer
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            notice_view = serializer.save()
            return Response({
                'message': 'View recorded successfully',
                'view': NoticeViewSerializer(notice_view).data
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class AnnouncementListCreateView(generics.ListCreateAPIView):
    """List and create announcements"""
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'message']
    ordering_fields = ['created_at', 'priority']
    ordering = ['-is_sticky', '-priority', '-created_at']
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return AnnouncementCreateSerializer
        return AnnouncementSerializer
    
    def perform_create(self, serializer):
        """Restrict announcement creation to faculty and admin only"""
        user = self.request.user
        if user.user_type == 'student':
            raise permissions.PermissionDenied("Students are not allowed to create announcements")
        serializer.save(author=user)
    
    def get_queryset(self):
        user = self.request.user
        now = timezone.now()
        
        # Show active announcements
        queryset = Announcement.objects.filter(
            status='active'
        ).filter(
            Q(show_until__isnull=True) | Q(show_until__gt=now)
        )
        
        # Filter by target audience
        if user.user_type == 'student':
            queryset = queryset.filter(
                Q(target_audience='all') | Q(target_audience='students')
            )
        elif user.user_type == 'faculty':
            queryset = queryset.filter(
                Q(target_audience='all') | Q(target_audience='faculty')
            )
        
        return queryset.select_related('author')


class AnnouncementDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Announcement detail view"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = AnnouncementSerializer
    
    def get_queryset(self):
        user = self.request.user
        now = timezone.now()
        
        # Show active announcements and user's own announcements
        return Announcement.objects.filter(
            (Q(status='active') & (Q(show_until__isnull=True) | Q(show_until__gt=now))) | 
            Q(author=user)
        ).select_related('author')


class MyNoticesView(generics.ListAPIView):
    """User's notices"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NoticeListSerializer
    
    def get_queryset(self):
        return Notice.objects.filter(author=self.request.user).select_related('author')


class DraftNoticesView(generics.ListCreateAPIView):
    """Draft notices - list and create/update drafts"""
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return NoticeDraftSerializer
        return NoticeDraftSerializer
    
    def get_queryset(self):
        return Notice.objects.filter(
            author=self.request.user,
            status='draft'
        ).select_related('author')
    
    def perform_create(self, serializer):
        """Create or update draft notice"""
        user = self.request.user
        if user.user_type == 'student':
            raise permissions.PermissionDenied("Students are not allowed to create notices")
        
        # Set status to draft if not specified
        if 'status' not in serializer.validated_data:
            serializer.validated_data['status'] = 'draft'
        
        serializer.save(author=user)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def save_draft(request, pk=None):
    """Save notice as draft"""
    user = request.user
    if user.user_type == 'student':
        return Response(
            {'error': 'Students are not allowed to create notices'}, 
            status=status.HTTP_403_FORBIDDEN
        )
    
    serializer = NoticeDraftSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        # If pk is provided, update existing draft
        if pk:
            notice = get_object_or_404(Notice, pk=pk, author=user, status='draft')
            serializer = NoticeDraftSerializer(notice, data=request.data, context={'request': request})
            if serializer.is_valid():
                serializer.save()
                return Response({'message': 'Draft updated successfully', 'notice': serializer.data})
        else:
            # Create new draft
            serializer.save(author=user, status='draft')
            return Response({'message': 'Draft saved successfully', 'notice': serializer.data})
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def publish_notice(request, pk):
    """Publish a notice"""
    notice = get_object_or_404(Notice, pk=pk, author=request.user)
    
    if notice.status != 'draft':
        return Response(
            {'error': 'Only draft notices can be published'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    notice.status = 'published'
    notice.published_at = timezone.now()
    notice.publish_at = timezone.now()  # Set publish_at to now
    notice.save()
    
    return Response({'message': 'Notice published successfully'})


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def pin_notice(request, pk):
    """Pin/unpin a notice"""
    notice = get_object_or_404(Notice, pk=pk, author=request.user)
    notice.is_pinned = not notice.is_pinned
    notice.save()
    
    action = 'pinned' if notice.is_pinned else 'unpinned'
    return Response({'message': f'Notice {action} successfully'})


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def notice_stats(request):
    """Get notice statistics"""
    if request.user.user_type not in ['admin', 'faculty']:
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    stats = {
        'total_notices': Notice.objects.count(),
        'published_notices': Notice.objects.filter(status='published').count(),
        'draft_notices': Notice.objects.filter(status='draft').count(),
        'pinned_notices': Notice.objects.filter(is_pinned=True).count(),
        'total_announcements': Announcement.objects.count(),
        'active_announcements': Announcement.objects.filter(status='active').count(),
        'notices_by_priority': {},
        'notices_by_visibility': {},
    }
    
    # Priority breakdown
    for priority, _ in Notice.PRIORITY_CHOICES:
        stats['notices_by_priority'][priority] = Notice.objects.filter(priority=priority).count()
    
    # Visibility breakdown
    for visibility, _ in Notice.VISIBILITY_CHOICES:
        stats['notices_by_visibility'][visibility] = Notice.objects.filter(visibility=visibility).count()
    
    return Response(stats)