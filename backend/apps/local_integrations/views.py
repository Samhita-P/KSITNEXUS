"""
Views for local_integrations app
"""
from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.db.models import Q, Count
from django.utils import timezone
from datetime import date, time
from .models import (
    Hostel, HostelRoom, HostelBooking,
    Cafeteria, CafeteriaMenu, CafeteriaBooking, CafeteriaOrder,
    TransportRoute, TransportSchedule, TransportVehicle, TransportLiveInfo
)
from .serializers import (
    HostelSerializer, HostelRoomSerializer, HostelBookingSerializer,
    CafeteriaSerializer, CafeteriaMenuSerializer, CafeteriaBookingSerializer, CafeteriaOrderSerializer,
    TransportRouteSerializer, TransportScheduleSerializer, TransportVehicleSerializer, TransportLiveInfoSerializer
)

User = get_user_model()


# Hostel
class HostelListView(generics.ListAPIView):
    """List hostels"""
    queryset = Hostel.objects.filter(is_active=True)
    serializer_class = HostelSerializer
    permission_classes = [permissions.IsAuthenticated]


class HostelDetailView(generics.RetrieveAPIView):
    """Hostel detail view"""
    queryset = Hostel.objects.all()
    serializer_class = HostelSerializer
    permission_classes = [permissions.IsAuthenticated]


class HostelRoomListView(generics.ListAPIView):
    """List hostel rooms"""
    serializer_class = HostelRoomSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = HostelRoom.objects.all().select_related('hostel')
        hostel_id = self.request.query_params.get('hostel_id')
        is_available = self.request.query_params.get('is_available')
        
        if hostel_id:
            queryset = queryset.filter(hostel_id=hostel_id)
        if is_available == 'true':
            queryset = queryset.filter(is_available=True, is_occupied=False)
        
        return queryset


class HostelBookingListView(generics.ListCreateAPIView):
    """List and create hostel bookings"""
    serializer_class = HostelBookingSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        queryset = HostelBooking.objects.all().select_related('user', 'hostel', 'room')
        
        if user.user_type == 'student':
            queryset = queryset.filter(user=user)
        
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        return queryset.order_by('-created_at')
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class HostelBookingDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Hostel booking detail view"""
    queryset = HostelBooking.objects.all()
    serializer_class = HostelBookingSerializer
    permission_classes = [permissions.IsAuthenticated]


# Cafeteria
class CafeteriaListView(generics.ListAPIView):
    """List cafeterias"""
    queryset = Cafeteria.objects.filter(is_active=True)
    serializer_class = CafeteriaSerializer
    permission_classes = [permissions.IsAuthenticated]


class CafeteriaDetailView(generics.RetrieveAPIView):
    """Cafeteria detail view"""
    queryset = Cafeteria.objects.all()
    serializer_class = CafeteriaSerializer
    permission_classes = [permissions.IsAuthenticated]


class CafeteriaMenuListView(generics.ListAPIView):
    """List cafeteria menu items"""
    serializer_class = CafeteriaMenuSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = CafeteriaMenu.objects.filter(is_available=True).select_related('cafeteria')
        cafeteria_id = self.request.query_params.get('cafeteria_id')
        meal_type = self.request.query_params.get('meal_type')
        
        if cafeteria_id:
            queryset = queryset.filter(cafeteria_id=cafeteria_id)
        if meal_type:
            queryset = queryset.filter(meal_type=meal_type)
        
        return queryset


class CafeteriaBookingListView(generics.ListCreateAPIView):
    """List and create cafeteria bookings"""
    serializer_class = CafeteriaBookingSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        queryset = CafeteriaBooking.objects.all().select_related('user', 'cafeteria')
        
        if user.user_type == 'student':
            queryset = queryset.filter(user=user)
        
        return queryset.order_by('-booking_date', '-booking_time')
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class CafeteriaOrderListView(generics.ListCreateAPIView):
    """List and create cafeteria orders"""
    serializer_class = CafeteriaOrderSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        queryset = CafeteriaOrder.objects.all().select_related('user', 'cafeteria')
        
        if user.user_type == 'student':
            queryset = queryset.filter(user=user)
        
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        return queryset.order_by('-created_at')
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class CafeteriaOrderDetailView(generics.RetrieveUpdateAPIView):
    """Cafeteria order detail view"""
    queryset = CafeteriaOrder.objects.all()
    serializer_class = CafeteriaOrderSerializer
    permission_classes = [permissions.IsAuthenticated]


# Transport
class TransportRouteListView(generics.ListAPIView):
    """List transport routes"""
    queryset = TransportRoute.objects.filter(is_active=True)
    serializer_class = TransportRouteSerializer
    permission_classes = [permissions.IsAuthenticated]


class TransportRouteDetailView(generics.RetrieveAPIView):
    """Transport route detail view"""
    queryset = TransportRoute.objects.all()
    serializer_class = TransportRouteSerializer
    permission_classes = [permissions.IsAuthenticated]


class TransportScheduleListView(generics.ListAPIView):
    """List transport schedules"""
    serializer_class = TransportScheduleSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = TransportSchedule.objects.filter(is_active=True).select_related('route')
        route_id = self.request.query_params.get('route_id')
        day_of_week = self.request.query_params.get('day_of_week')
        
        if route_id:
            queryset = queryset.filter(route_id=route_id)
        if day_of_week:
            queryset = queryset.filter(day_of_week=day_of_week)
        
        return queryset


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def transport_live_info(request):
    """Get live transport information"""
    route_id = request.query_params.get('route_id')
    vehicle_id = request.query_params.get('vehicle_id')
    
    queryset = TransportLiveInfo.objects.all().select_related('vehicle', 'route')
    
    if route_id:
        queryset = queryset.filter(route_id=route_id)
    if vehicle_id:
        queryset = queryset.filter(vehicle_id=vehicle_id)
    
    # Get most recent info for each vehicle
    live_info = queryset.order_by('vehicle', '-last_updated').distinct('vehicle')
    
    serializer = TransportLiveInfoSerializer(live_info, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def transport_vehicles(request):
    """Get all transport vehicles"""
    route_id = request.query_params.get('route_id')
    status_filter = request.query_params.get('status')
    
    queryset = TransportVehicle.objects.all().select_related('current_route')
    
    if route_id:
        queryset = queryset.filter(current_route_id=route_id)
    if status_filter:
        queryset = queryset.filter(status=status_filter)
    
    serializer = TransportVehicleSerializer(queryset, many=True)
    return Response(serializer.data)

















