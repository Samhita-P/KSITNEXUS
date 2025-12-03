from django.contrib import admin
from .models import (
    Hostel, HostelRoom, HostelBooking,
    Cafeteria, CafeteriaMenu, CafeteriaBooking, CafeteriaOrder,
    TransportRoute, TransportSchedule, TransportVehicle, TransportLiveInfo
)


@admin.register(Hostel)
class HostelAdmin(admin.ModelAdmin):
    list_display = ['name', 'code', 'total_rooms', 'total_capacity', 'current_occupancy', 'is_active']
    list_filter = ['is_active']
    search_fields = ['name', 'code']


@admin.register(HostelRoom)
class HostelRoomAdmin(admin.ModelAdmin):
    list_display = ['hostel', 'room_number', 'room_type', 'capacity', 'current_occupancy', 'is_available']
    list_filter = ['hostel', 'room_type', 'is_available', 'is_occupied']
    search_fields = ['room_number', 'hostel__name']


@admin.register(HostelBooking)
class HostelBookingAdmin(admin.ModelAdmin):
    list_display = ['booking_id', 'user', 'hostel', 'room', 'check_in_date', 'status']
    list_filter = ['status', 'check_in_date', 'hostel']
    search_fields = ['booking_id', 'user__username']
    readonly_fields = ['booking_id']


@admin.register(Cafeteria)
class CafeteriaAdmin(admin.ModelAdmin):
    list_display = ['name', 'code', 'location', 'capacity', 'current_occupancy', 'is_active']
    list_filter = ['is_active']
    search_fields = ['name', 'code']


@admin.register(CafeteriaMenu)
class CafeteriaMenuAdmin(admin.ModelAdmin):
    list_display = ['cafeteria', 'name', 'meal_type', 'price', 'is_available']
    list_filter = ['cafeteria', 'meal_type', 'is_available', 'is_vegetarian', 'is_vegan']
    search_fields = ['name', 'cafeteria__name']


@admin.register(CafeteriaBooking)
class CafeteriaBookingAdmin(admin.ModelAdmin):
    list_display = ['booking_id', 'user', 'cafeteria', 'booking_date', 'booking_time', 'status']
    list_filter = ['status', 'booking_date', 'cafeteria']
    search_fields = ['booking_id', 'user__username']
    readonly_fields = ['booking_id']


@admin.register(CafeteriaOrder)
class CafeteriaOrderAdmin(admin.ModelAdmin):
    list_display = ['order_id', 'user', 'cafeteria', 'total_amount', 'status', 'created_at']
    list_filter = ['status', 'cafeteria', 'created_at']
    search_fields = ['order_id', 'user__username']
    readonly_fields = ['order_id']


@admin.register(TransportRoute)
class TransportRouteAdmin(admin.ModelAdmin):
    list_display = ['name', 'route_code', 'route_type', 'start_location', 'end_location', 'is_active']
    list_filter = ['route_type', 'is_active']
    search_fields = ['name', 'route_code']


@admin.register(TransportSchedule)
class TransportScheduleAdmin(admin.ModelAdmin):
    list_display = ['route', 'departure_time', 'day_of_week', 'is_active']
    list_filter = ['route', 'day_of_week', 'is_active']
    search_fields = ['route__name']


@admin.register(TransportVehicle)
class TransportVehicleAdmin(admin.ModelAdmin):
    list_display = ['vehicle_number', 'vehicle_type', 'current_route', 'status', 'last_updated']
    list_filter = ['vehicle_type', 'status', 'current_route']
    search_fields = ['vehicle_number']


@admin.register(TransportLiveInfo)
class TransportLiveInfoAdmin(admin.ModelAdmin):
    list_display = ['vehicle', 'route', 'current_stop', 'next_stop', 'updated_at']
    list_filter = ['route', 'is_on_time']
    search_fields = ['vehicle__vehicle_number', 'route__name']
    readonly_fields = ['updated_at']

