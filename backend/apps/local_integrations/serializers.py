"""
Serializers for local_integrations app
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    Hostel, HostelRoom, HostelBooking,
    Cafeteria, CafeteriaMenu, CafeteriaBooking, CafeteriaOrder,
    TransportRoute, TransportSchedule, TransportVehicle, TransportLiveInfo
)

User = get_user_model()


class HostelSerializer(serializers.ModelSerializer):
    """Serializer for Hostel"""
    availability_rate = serializers.SerializerMethodField()
    
    class Meta:
        model = Hostel
        fields = [
            'id', 'name', 'code', 'address', 'total_rooms', 'total_capacity',
            'current_occupancy', 'amenities', 'is_active', 'availability_rate',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['current_occupancy', 'created_at', 'updated_at']
    
    def get_availability_rate(self, obj):
        if obj.total_capacity > 0:
            return ((obj.total_capacity - obj.current_occupancy) / obj.total_capacity) * 100
        return 0.0


class HostelRoomSerializer(serializers.ModelSerializer):
    """Serializer for HostelRoom"""
    hostel_name = serializers.SerializerMethodField()
    
    class Meta:
        model = HostelRoom
        fields = [
            'id', 'hostel', 'hostel_name', 'room_number', 'room_type', 'capacity',
            'current_occupancy', 'floor', 'amenities', 'is_available', 'is_occupied',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['current_occupancy', 'is_occupied', 'created_at', 'updated_at']
    
    def get_hostel_name(self, obj):
        return obj.hostel.name


class HostelBookingSerializer(serializers.ModelSerializer):
    """Serializer for HostelBooking"""
    user_name = serializers.SerializerMethodField()
    hostel_name = serializers.SerializerMethodField()
    room_number = serializers.SerializerMethodField()
    
    class Meta:
        model = HostelBooking
        fields = [
            'id', 'booking_id', 'user', 'user_name', 'hostel', 'hostel_name',
            'room', 'room_number', 'check_in_date', 'check_out_date', 'status',
            'special_requests', 'confirmed_at', 'cancelled_at', 'cancellation_reason',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['user', 'confirmed_at', 'cancelled_at', 'created_at', 'updated_at']
    
    def get_user_name(self, obj):
        return f"{obj.user.first_name} {obj.user.last_name}".strip() or obj.user.username
    
    def get_hostel_name(self, obj):
        return obj.hostel.name
    
    def get_room_number(self, obj):
        return obj.room.room_number if obj.room else None


class CafeteriaSerializer(serializers.ModelSerializer):
    """Serializer for Cafeteria"""
    occupancy_rate = serializers.SerializerMethodField()
    
    class Meta:
        model = Cafeteria
        fields = [
            'id', 'name', 'code', 'location', 'capacity', 'current_occupancy',
            'operating_hours', 'is_active', 'occupancy_rate',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['current_occupancy', 'created_at', 'updated_at']
    
    def get_occupancy_rate(self, obj):
        if obj.capacity > 0:
            return (obj.current_occupancy / obj.capacity) * 100
        return 0.0


class CafeteriaMenuSerializer(serializers.ModelSerializer):
    """Serializer for CafeteriaMenu"""
    cafeteria_name = serializers.SerializerMethodField()
    
    class Meta:
        model = CafeteriaMenu
        fields = [
            'id', 'cafeteria', 'cafeteria_name', 'name', 'description', 'meal_type',
            'price', 'image_url', 'is_available', 'is_vegetarian', 'is_vegan',
            'allergens', 'nutritional_info', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']
    
    def get_cafeteria_name(self, obj):
        return obj.cafeteria.name


class CafeteriaBookingSerializer(serializers.ModelSerializer):
    """Serializer for CafeteriaBooking"""
    user_name = serializers.SerializerMethodField()
    cafeteria_name = serializers.SerializerMethodField()
    
    class Meta:
        model = CafeteriaBooking
        fields = [
            'id', 'booking_id', 'user', 'user_name', 'cafeteria', 'cafeteria_name',
            'booking_date', 'booking_time', 'number_of_guests', 'special_requests',
            'status', 'confirmed_at', 'cancelled_at', 'created_at', 'updated_at',
        ]
        read_only_fields = ['user', 'confirmed_at', 'cancelled_at', 'created_at', 'updated_at']
    
    def get_user_name(self, obj):
        return f"{obj.user.first_name} {obj.user.last_name}".strip() or obj.user.username
    
    def get_cafeteria_name(self, obj):
        return obj.cafeteria.name


class CafeteriaOrderSerializer(serializers.ModelSerializer):
    """Serializer for CafeteriaOrder"""
    user_name = serializers.SerializerMethodField()
    cafeteria_name = serializers.SerializerMethodField()
    
    class Meta:
        model = CafeteriaOrder
        fields = [
            'id', 'order_id', 'user', 'user_name', 'cafeteria', 'cafeteria_name',
            'items', 'total_amount', 'status', 'special_instructions',
            'pickup_time', 'completed_at', 'created_at', 'updated_at',
        ]
        read_only_fields = ['user', 'completed_at', 'created_at', 'updated_at']
    
    def get_user_name(self, obj):
        return f"{obj.user.first_name} {obj.user.last_name}".strip() or obj.user.username
    
    def get_cafeteria_name(self, obj):
        return obj.cafeteria.name


class TransportRouteSerializer(serializers.ModelSerializer):
    """Serializer for TransportRoute"""
    active_vehicles_count = serializers.SerializerMethodField()
    
    class Meta:
        model = TransportRoute
        fields = [
            'id', 'name', 'route_code', 'route_type', 'start_location', 'end_location',
            'stops', 'distance_km', 'estimated_duration_minutes', 'is_active',
            'active_vehicles_count', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']
    
    def get_active_vehicles_count(self, obj):
        return obj.vehicles.filter(status='active').count()


class TransportScheduleSerializer(serializers.ModelSerializer):
    """Serializer for TransportSchedule"""
    route_name = serializers.SerializerMethodField()
    
    class Meta:
        model = TransportSchedule
        fields = [
            'id', 'route', 'route_name', 'departure_time', 'arrival_time',
            'day_of_week', 'is_active', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']
    
    def get_route_name(self, obj):
        return obj.route.name


class TransportVehicleSerializer(serializers.ModelSerializer):
    """Serializer for TransportVehicle"""
    route_name = serializers.SerializerMethodField()
    
    class Meta:
        model = TransportVehicle
        fields = [
            'id', 'vehicle_number', 'vehicle_type', 'capacity', 'current_route',
            'route_name', 'current_location', 'latitude', 'longitude', 'status',
            'last_updated', 'created_at', 'updated_at',
        ]
        read_only_fields = ['last_updated', 'created_at', 'updated_at']
    
    def get_route_name(self, obj):
        return obj.current_route.name if obj.current_route else None


class TransportLiveInfoSerializer(serializers.ModelSerializer):
    """Serializer for TransportLiveInfo"""
    vehicle_number = serializers.SerializerMethodField()
    route_name = serializers.SerializerMethodField()
    
    class Meta:
        model = TransportLiveInfo
        fields = [
            'id', 'vehicle', 'vehicle_number', 'route', 'route_name',
            'current_stop', 'next_stop', 'latitude', 'longitude', 'speed_kmh',
            'estimated_arrival_minutes', 'current_passengers', 'is_on_time',
            'created_at', 'updated_at', 'last_updated',
        ]
        read_only_fields = ['created_at', 'updated_at', 'last_updated']
    
    def get_vehicle_number(self, obj):
        return obj.vehicle.vehicle_number
    
    def get_route_name(self, obj):
        return obj.route.name

















