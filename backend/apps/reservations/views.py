"""
Views for reservations app
"""
from rest_framework import generics, status, permissions, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.db.models import Q, Count
from django.shortcuts import get_object_or_404
from django.utils import timezone
from .models import ReadingRoom, Seat, Reservation, ReservationHistory, SeatAvailability
from .serializers import (
    ReadingRoomSerializer, SeatSerializer, ReservationSerializer,
    ReservationCreateSerializer, ReservationListSerializer,
    ReservationHistorySerializer, SeatAvailabilitySerializer,
    CheckInSerializer, CheckOutSerializer, CancelReservationSerializer
)

User = get_user_model()


class ReadingRoomListView(generics.ListAPIView):
    """List reading rooms"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ReadingRoomSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'description', 'location']
    ordering_fields = ['name', 'capacity']
    ordering = ['name']
    
    def get_queryset(self):
        return ReadingRoom.objects.filter(is_active=True)


class SeatListView(generics.ListAPIView):
    """List seats in a room"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = SeatSerializer
    pagination_class = None  # Disable pagination - return all seats
    
    def get_queryset(self):
        room_id = self.kwargs['room_id']
        # Return all seats ordered by table_number, then row_number, then column_number
        return Seat.objects.filter(
            room_id=room_id, 
            is_active=True
        ).order_by('table_number', 'row_number', 'column_number', 'seat_number')


class SeatAvailabilityView(generics.ListAPIView):
    """Get seat availability for a room"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = SeatAvailabilitySerializer
    
    def get_queryset(self):
        room_id = self.kwargs['room_id']
        date = self.request.query_params.get('date', timezone.now().date())
        return SeatAvailability.objects.filter(
            seat__room_id=room_id,
            date=date
        ).select_related('seat')


class ReservationListCreateView(generics.ListCreateAPIView):
    """List and create reservations"""
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['purpose', 'notes']
    ordering_fields = ['created_at', 'start_time', 'end_time']
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ReservationCreateSerializer
        return ReservationListSerializer
    
    def get_queryset(self):
        return Reservation.objects.filter(user=self.request.user).select_related('seat', 'seat__room')


class ReservationDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Reservation detail view"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ReservationSerializer
    
    def get_queryset(self):
        return Reservation.objects.filter(user=self.request.user).select_related('seat', 'seat__room')


class CheckInView(generics.UpdateAPIView):
    """Check in to reservation"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = CheckInSerializer
    
    def get_object(self):
        reservation_id = self.kwargs['pk']
        return get_object_or_404(
            Reservation, 
            id=reservation_id, 
            user=self.request.user
        )
    
    def update(self, request, *args, **kwargs):
        reservation = self.get_object()
        
        if reservation.status != 'confirmed':
            return Response(
                {'error': 'Only confirmed reservations can be checked in'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        now = timezone.now()
        if now < reservation.start_time:
            return Response(
                {'error': 'Cannot check in before reservation start time'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if now > reservation.end_time:
            return Response(
                {'error': 'Reservation has expired'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        reservation.status = 'active'
        reservation.checked_in_at = now
        reservation.save()
        
        # Create history entry
        ReservationHistory.objects.create(
            reservation=reservation,
            action='checked_in',
            performed_by=request.user,
            notes=request.data.get('notes', '')
        )
        
        return Response({'message': 'Checked in successfully'})


class CheckOutView(generics.UpdateAPIView):
    """Check out of reservation"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = CheckOutSerializer
    
    def get_object(self):
        reservation_id = self.kwargs['pk']
        return get_object_or_404(
            Reservation, 
            id=reservation_id, 
            user=self.request.user
        )
    
    def update(self, request, *args, **kwargs):
        reservation = self.get_object()
        
        if reservation.status != 'active':
            return Response(
                {'error': 'Only active reservations can be checked out'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        now = timezone.now()
        reservation.status = 'completed'
        reservation.checked_out_at = now
        reservation.save()
        
        # Create history entry
        ReservationHistory.objects.create(
            reservation=reservation,
            action='checked_out',
            performed_by=request.user,
            notes=request.data.get('notes', '')
        )
        
        return Response({'message': 'Checked out successfully'})


class CancelReservationView(generics.DestroyAPIView):
    """Cancel reservation"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = CancelReservationSerializer
    
    def get_object(self):
        reservation_id = self.kwargs['pk']
        return get_object_or_404(
            Reservation, 
            id=reservation_id, 
            user=self.request.user
        )
    
    def destroy(self, request, *args, **kwargs):
        reservation = self.get_object()
        
        if reservation.status in ['completed', 'cancelled']:
            return Response(
                {'error': 'Cannot cancel completed or already cancelled reservation'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        reservation.status = 'cancelled'
        reservation.save()
        
        # Create history entry
        ReservationHistory.objects.create(
            reservation=reservation,
            action='cancelled',
            performed_by=request.user,
            notes=request.data.get('reason', '')
        )
        
        return Response({'message': 'Reservation cancelled successfully'})


class MyReservationsView(generics.ListAPIView):
    """User's reservations"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ReservationListSerializer
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['created_at', 'start_time', 'end_time']
    ordering = ['-created_at']
    
    def get_queryset(self):
        status_filter = self.request.query_params.get('status')
        queryset = Reservation.objects.filter(user=self.request.user).select_related('seat', 'seat__room')
        
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        return queryset


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def available_seats(request, room_id):
    """Get available seats for a specific time period"""
    start_time = request.query_params.get('start_time')
    end_time = request.query_params.get('end_time')
    
    if not start_time or not end_time:
        return Response(
            {'error': 'start_time and end_time parameters are required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        start_time = timezone.datetime.fromisoformat(start_time.replace('Z', '+00:00'))
        end_time = timezone.datetime.fromisoformat(end_time.replace('Z', '+00:00'))
    except ValueError:
        return Response(
            {'error': 'Invalid datetime format'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Get all seats in the room
    all_seats = Seat.objects.filter(room_id=room_id, is_active=True)
    
    # Get seats with overlapping reservations
    overlapping_reservations = Reservation.objects.filter(
        seat__room_id=room_id,
        status__in=['confirmed', 'active'],
        start_time__lt=end_time,
        end_time__gt=start_time
    ).values_list('seat_id', flat=True)
    
    # Filter available seats
    available_seats = all_seats.exclude(id__in=overlapping_reservations)
    
    serializer = SeatSerializer(available_seats, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def reservation_stats(request):
    """Get reservation statistics"""
    if request.user.user_type not in ['admin', 'faculty']:
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    stats = {
        'total_reservations': Reservation.objects.count(),
        'active_reservations': Reservation.objects.filter(status='active').count(),
        'completed_reservations': Reservation.objects.filter(status='completed').count(),
        'cancelled_reservations': Reservation.objects.filter(status='cancelled').count(),
        'total_rooms': ReadingRoom.objects.filter(is_active=True).count(),
        'total_seats': Seat.objects.filter(is_active=True).count(),
        'reservations_by_status': {},
        'popular_rooms': [],
    }
    
    # Status breakdown
    for status_choice, _ in Reservation.STATUS_CHOICES:
        stats['reservations_by_status'][status_choice] = Reservation.objects.filter(status=status_choice).count()
    
    # Popular rooms
    popular_rooms = ReadingRoom.objects.annotate(
        reservation_count=Count('seat__reservations')
    ).order_by('-reservation_count')[:5]
    
    stats['popular_rooms'] = ReadingRoomSerializer(popular_rooms, many=True).data
    
    return Response(stats)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def user_reservations(request):
    """Get user's reservations"""
    reservations = Reservation.objects.filter(user=request.user).order_by('-start_time')
    serializer = ReservationListSerializer(reservations, many=True)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def create_seat_availability(request):
    """Create seat availability data for a room"""
    if request.user.user_type not in ['admin', 'faculty']:
        return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
    
    room_id = request.data.get('room_id')
    date = request.data.get('date')
    
    if not room_id or not date:
        return Response(
            {'error': 'room_id and date are required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        date = timezone.datetime.fromisoformat(date).date()
    except ValueError:
        return Response(
            {'error': 'Invalid date format'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Get all seats in the room
    seats = Seat.objects.filter(room_id=room_id, is_active=True)
    
    # Create availability data for each hour
    availability_data = []
    for seat in seats:
        for hour in range(24):
            availability, created = SeatAvailability.objects.get_or_create(
                seat=seat,
                date=date,
                hour=hour,
                defaults={'is_available': True, 'reservation_count': 0}
            )
            availability_data.append(availability)
    
    serializer = SeatAvailabilitySerializer(availability_data, many=True)
    return Response(serializer.data)