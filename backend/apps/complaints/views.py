"""
Views for complaints app
"""
from rest_framework import generics, status, permissions, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.contrib.auth import get_user_model
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from .models import Complaint, ComplaintAttachment, ComplaintUpdate
from .serializers import (
    ComplaintSerializer, ComplaintCreateSerializer, ComplaintUpdateStatusSerializer,
    ComplaintListSerializer, ComplaintAttachmentSerializer, ComplaintUpdateSerializer,
    ComplaintResponseSerializer, MarkResolvedSerializer
)

User = get_user_model()


class ComplaintListCreateView(generics.ListCreateAPIView):
    """List and create complaints"""
    permission_classes = [permissions.AllowAny]  # Allow anonymous complaint submission
    parser_classes = [MultiPartParser, FormParser]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'description', 'complaint_id']
    ordering_fields = ['submitted_at', 'urgency', 'status']
    ordering = ['-submitted_at']
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ComplaintCreateSerializer
        return ComplaintListSerializer
    
    def get_queryset(self):
        # Only show complaints to authenticated users
        if not self.request.user.is_authenticated:
            return Complaint.objects.none()
        
        # Students can only see complaints they submitted (if they provided contact info)
        if self.request.user.user_type == 'student':
            return Complaint.objects.filter(
                contact_email=self.request.user.email
            ).prefetch_related('attachments', 'updates')
        
        # Faculty and admin can see all complaints
        elif self.request.user.user_type in ['faculty', 'admin']:
            return Complaint.objects.all().prefetch_related('attachments', 'updates')
        
        return Complaint.objects.none()
    
    def perform_create(self, serializer):
        # Create complaint (anonymous submission)
        complaint = serializer.save()
        
        # Log the creation
        ComplaintUpdate.objects.create(
            complaint=complaint,
            updated_by=None,  # Anonymous
            status=complaint.status,
            comment=f"Complaint submitted: {complaint.title}",
            is_internal=False
        )
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context


class ComplaintDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Complaint detail view"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ComplaintSerializer
    
    def get_queryset(self):
        # Only show complaints to authenticated users
        if not self.request.user.is_authenticated:
            return Complaint.objects.none()
        
        # Students can only see complaints they submitted (if they provided contact info)
        if self.request.user.user_type == 'student':
            return Complaint.objects.filter(
                contact_email=self.request.user.email
            ).prefetch_related('attachments', 'updates')
        
        # Faculty and admin can see all complaints
        elif self.request.user.user_type in ['faculty', 'admin']:
            return Complaint.objects.all().prefetch_related('attachments', 'updates')
        
        return Complaint.objects.none()
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context


class ComplaintUpdateView(generics.UpdateAPIView):
    """Update complaint status and details"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ComplaintUpdateStatusSerializer
    
    def get_queryset(self):
        # Only faculty and admin can update complaints
        if self.request.user.user_type in ['faculty', 'admin']:
            return Complaint.objects.all()
        return Complaint.objects.none()
    
    def perform_update(self, serializer):
        serializer.save()


class ComplaintAttachmentView(generics.ListCreateAPIView):
    """Complaint attachments view"""
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    serializer_class = ComplaintAttachmentSerializer
    
    def get_queryset(self):
        complaint_id = self.kwargs['complaint_id']
        return ComplaintAttachment.objects.filter(complaint_id=complaint_id)
    
    def perform_create(self, serializer):
        complaint_id = self.kwargs['complaint_id']
        complaint = get_object_or_404(Complaint, id=complaint_id)
        serializer.save(complaint=complaint)


class MyComplaintsView(generics.ListAPIView):
    """User's submitted complaints (if not anonymous)"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ComplaintListSerializer
    
    def get_queryset(self):
        # Show complaints submitted by the authenticated user
        if self.request.user.user_type == 'student':
            return Complaint.objects.filter(
                contact_email=self.request.user.email
            ).prefetch_related('attachments', 'updates')
        return Complaint.objects.none()


class AdminComplaintsView(generics.ListAPIView):
    """Admin view of all complaints"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ComplaintListSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'description', 'complaint_id', 'contact_email']
    ordering_fields = ['submitted_at', 'urgency', 'status']
    ordering = ['-submitted_at']
    
    def get_queryset(self):
        # Only admin and faculty can see all complaints
        if self.request.user.user_type in ['admin', 'faculty']:
            return Complaint.objects.all().prefetch_related('attachments', 'updates')
        return Complaint.objects.none()
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def complaint_stats(request):
    """Get complaint statistics"""
    if request.user.user_type not in ['admin', 'faculty']:
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    stats = {
        'total_complaints': Complaint.objects.count(),
        'pending_complaints': Complaint.objects.filter(status='submitted').count(),
        'in_progress_complaints': Complaint.objects.filter(status='in_progress').count(),
        'resolved_complaints': Complaint.objects.filter(status='resolved').count(),
        'urgent_complaints': Complaint.objects.filter(urgency='urgent').count(),
        'complaints_by_category': {},
        'complaints_by_status': {},
    }
    
    # Category breakdown
    for category, _ in Complaint.CATEGORY_CHOICES:
        stats['complaints_by_category'][category] = Complaint.objects.filter(category=category).count()
    
    # Status breakdown
    for status_choice, _ in Complaint.STATUS_CHOICES:
        stats['complaints_by_status'][status_choice] = Complaint.objects.filter(status=status_choice).count()
    
    return Response(stats)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def assign_complaint(request, pk):
    """Assign complaint to faculty member"""
    if request.user.user_type not in ['admin', 'faculty']:
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    complaint = get_object_or_404(Complaint, pk=pk)
    assigned_to_id = request.data.get('assigned_to')
    
    if assigned_to_id:
        try:
            assigned_to = User.objects.get(id=assigned_to_id, user_type='faculty')
            complaint.assigned_to = assigned_to
            complaint.status = 'under_review'  # Update status when assigned
            complaint.save()
            
            # Create update log
            ComplaintUpdate.objects.create(
                complaint=complaint,
                updated_by=request.user,
                status=complaint.status,
                comment=f"Complaint assigned to {assigned_to.get_full_name()}",
                is_internal=True
            )
            
            # Note: Case will be automatically created via signal in signals.py
            
            return Response({'message': 'Complaint assigned successfully'})
        except User.DoesNotExist:
            return Response({'error': 'Faculty member not found'}, status=status.HTTP_400_BAD_REQUEST)
    
    return Response({'error': 'assigned_to field is required'}, status=status.HTTP_400_BAD_REQUEST)


class FacultyComplaintsDashboardView(generics.ListAPIView):
    """Faculty dashboard for reviewing student complaints"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ComplaintListSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'description', 'complaint_id', 'contact_email']
    ordering_fields = ['submitted_at', 'urgency', 'status']
    ordering = ['-submitted_at']
    
    def get_queryset(self):
        # Only faculty can access this view
        if self.request.user.user_type != 'faculty':
            return Complaint.objects.none()
        
        # Get filter parameter
        status_filter = self.request.query_params.get('status', 'pending')
        
        if status_filter == 'pending':
            # Show all complaints that are not resolved and have no action taken
            # "No action taken" means:
            # - Status is 'submitted' (initial state, not yet reviewed)
            # - Not assigned to anyone
            # - No updates from faculty members
            from apps.complaints.models import ComplaintUpdate
            from django.db.models import Q, Exists, OuterRef
            
            # Get all complaints with status 'submitted' that are not assigned
            base_queryset = Complaint.objects.filter(
                status='submitted',
                assigned_to__isnull=True
            )
            
            # Exclude complaints that have any updates from faculty members
            # We need to check if there are any ComplaintUpdate records where updated_by is faculty
            # Note: updated_by can be None for anonymous submissions, so we check for non-None faculty users
            faculty_updates = ComplaintUpdate.objects.filter(
                complaint=OuterRef('pk'),
                updated_by__isnull=False,
                updated_by__user_type='faculty'
            )
            
            queryset = base_queryset.exclude(
                Exists(faculty_updates)
            ).prefetch_related('attachments', 'updates').distinct()
            
            return queryset
        elif status_filter == 'resolved':
            return Complaint.objects.filter(status='resolved').prefetch_related('attachments', 'updates')
        else:  # 'all'
            return Complaint.objects.all().prefetch_related('attachments', 'updates')
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def respond_to_complaint(request, pk):
    """Faculty responds to a complaint"""
    if request.user.user_type != 'faculty':
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    complaint = get_object_or_404(Complaint, pk=pk)
    
    # Use serializer for validation
    serializer = ComplaintResponseSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    message = serializer.validated_data['message']
    attachments = request.FILES.getlist('attachments', [])
    
    # Create complaint update with response
    update = ComplaintUpdate.objects.create(
        complaint=complaint,
        updated_by=request.user,
        status=complaint.status,
        comment=message,
        is_internal=False  # This is a public response to the student
    )
    
    # Create attachments for the response
    for attachment_file in attachments:
        if attachment_file:
            ComplaintAttachment.objects.create(
                complaint=complaint,
                file=attachment_file,
                file_name=attachment_file.name,
                file_size=attachment_file.size
            )
    
    # Send notification to the student (if they have contact info)
    if complaint.contact_email:
        try:
            # Find student by email
            student = User.objects.get(email=complaint.contact_email, user_type='student')
            
            # Create notification
            from apps.notifications.models import Notification
            Notification.objects.create(
                user=student,
                notification_type='complaint',
                priority='medium',
                title=f'Response to your complaint #{complaint.complaint_id}',
                message=f'Faculty {request.user.get_full_name()} has responded to your complaint: "{complaint.title}". Response: {message[:100]}...',
                data={
                    'complaint_id': complaint.id,
                    'complaint_title': complaint.title,
                    'faculty_name': request.user.get_full_name(),
                    'response_message': message
                }
            )
        except User.DoesNotExist:
            pass  # Student not found, skip notification
    
    return Response({
        'message': 'Response sent successfully',
        'update': {
            'id': update.id,
            'comment': update.comment,
            'created_at': update.created_at,
            'updated_by': request.user.get_full_name()
        }
    })


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def mark_complaint_resolved(request, pk):
    """Mark complaint as resolved"""
    if request.user.user_type != 'faculty':
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    complaint = get_object_or_404(Complaint, pk=pk)
    
    # Use serializer for validation
    serializer = MarkResolvedSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    comment = serializer.validated_data.get('comment', 'Complaint marked as resolved')
    
    # Update complaint status
    complaint.status = 'resolved'
    complaint.resolved_at = timezone.now()
    complaint.save()
    
    # Create update log
    ComplaintUpdate.objects.create(
        complaint=complaint,
        updated_by=request.user,
        status='resolved',
        comment=comment,
        is_internal=False
    )
    
    # Send notification to the student
    if complaint.contact_email:
        try:
            student = User.objects.get(email=complaint.contact_email, user_type='student')
            
            from apps.notifications.models import Notification
            Notification.objects.create(
                user=student,
                notification_type='complaint',
                priority='medium',
                title=f'Your complaint #{complaint.complaint_id} has been resolved',
                message=f'Your complaint "{complaint.title}" has been marked as resolved by {request.user.get_full_name()}. {comment}',
                data={
                    'complaint_id': complaint.id,
                    'complaint_title': complaint.title,
                    'faculty_name': request.user.get_full_name(),
                    'resolution_comment': comment
                }
            )
        except User.DoesNotExist:
            pass
    
    return Response({'message': 'Complaint marked as resolved successfully'})


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def faculty_complaint_stats(request):
    """Get complaint statistics for faculty dashboard"""
    if request.user.user_type != 'faculty':
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    stats = {
        'total_complaints': Complaint.objects.count(),
        'pending_complaints': Complaint.objects.filter(
            status__in=['submitted', 'under_review', 'in_progress']
        ).count(),
        'resolved_complaints': Complaint.objects.filter(status='resolved').count(),
        'urgent_complaints': Complaint.objects.filter(urgency='urgent').count(),
        'complaints_by_category': {},
        'complaints_by_status': {},
    }
    
    # Category breakdown
    for category, _ in Complaint.CATEGORY_CHOICES:
        stats['complaints_by_category'][category] = Complaint.objects.filter(category=category).count()
    
    # Status breakdown
    for status_choice, _ in Complaint.STATUS_CHOICES:
        stats['complaints_by_status'][status_choice] = Complaint.objects.filter(status=status_choice).count()
    
    return Response(stats)