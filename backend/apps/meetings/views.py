from rest_framework import generics, status, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.utils import timezone
from .models import Meeting
from .serializers import MeetingSerializer, MeetingCreateSerializer, MeetingUpdateSerializer

class MeetingListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['scheduled_date', 'created_at']
    ordering = ['-scheduled_date']
    
    def get_queryset(self):
        queryset = Meeting.objects.all()
        
        # Filter by status if provided
        status_filter = self.request.query_params.get('status', None)
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # For 'upcoming' or 'scheduled', only show future meetings
        if status_filter in ['upcoming', 'scheduled']:
            queryset = queryset.filter(scheduled_date__gte=timezone.now())
        
        return queryset
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return MeetingCreateSerializer
        return MeetingSerializer
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        # Return the full meeting data using MeetingSerializer
        meeting = serializer.instance
        response_serializer = MeetingSerializer(meeting)
        print(f"Created meeting: {meeting.id}, {meeting.title}")
        print(f"Response data: {response_serializer.data}")
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)

class MeetingRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated]
    queryset = Meeting.objects.all()
    
    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return MeetingUpdateSerializer
        return MeetingSerializer

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_meetings(request):
    """Get meetings created by the current user"""
    meetings = Meeting.objects.filter(created_by=request.user).order_by('-scheduled_date')
    serializer = MeetingSerializer(meetings, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def cancel_meeting(request, pk):
    """Cancel a meeting"""
    meeting = get_object_or_404(Meeting, pk=pk, created_by=request.user)
    meeting.status = 'cancelled'
    meeting.save()
    serializer = MeetingSerializer(meeting)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def complete_meeting(request, pk):
    """Mark a meeting as completed"""
    meeting = get_object_or_404(Meeting, pk=pk, created_by=request.user)
    meeting.status = 'completed'
    meeting.save()
    serializer = MeetingSerializer(meeting)
    return Response(serializer.data)
