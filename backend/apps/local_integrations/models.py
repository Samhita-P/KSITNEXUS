"""
Local Integrations models for KSIT Nexus
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator
from apps.shared.models.base import TimestampedModel

User = get_user_model()


# Hostel Management
class Hostel(TimestampedModel):
    """Hostel building model"""
    
    name = models.CharField(max_length=200)
    code = models.CharField(max_length=20, unique=True)
    address = models.CharField(max_length=500, blank=True, null=True)
    total_rooms = models.IntegerField(default=0)
    total_capacity = models.IntegerField(default=0)
    current_occupancy = models.IntegerField(default=0)
    amenities = models.JSONField(
        default=list,
        blank=True,
        help_text='List of amenities (WiFi, Laundry, etc.)'
    )
    is_active = models.BooleanField(default=True)
    
    class Meta:
        verbose_name = 'Hostel'
        verbose_name_plural = 'Hostels'
        ordering = ['name']
    
    def __str__(self):
        return f"{self.name} ({self.code})"


class HostelRoom(TimestampedModel):
    """Hostel room model"""
    
    ROOM_TYPES = [
        ('single', 'Single'),
        ('double', 'Double'),
        ('triple', 'Triple'),
        ('quad', 'Quad'),
    ]
    
    hostel = models.ForeignKey(Hostel, on_delete=models.CASCADE, related_name='rooms')
    room_number = models.CharField(max_length=20)
    room_type = models.CharField(max_length=20, choices=ROOM_TYPES, default='double')
    capacity = models.IntegerField(default=2)
    current_occupancy = models.IntegerField(default=0)
    floor = models.IntegerField(blank=True, null=True)
    amenities = models.JSONField(
        default=list,
        blank=True,
        help_text='Room-specific amenities'
    )
    is_available = models.BooleanField(default=True)
    is_occupied = models.BooleanField(default=False)
    
    class Meta:
        verbose_name = 'Hostel Room'
        verbose_name_plural = 'Hostel Rooms'
        unique_together = [['hostel', 'room_number']]
        ordering = ['hostel', 'floor', 'room_number']
    
    def __str__(self):
        return f"{self.hostel.name} - Room {self.room_number}"


class HostelBooking(TimestampedModel):
    """Hostel room booking"""
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('active', 'Active'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    booking_id = models.CharField(max_length=20, unique=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='hostel_bookings')
    hostel = models.ForeignKey(Hostel, on_delete=models.CASCADE, related_name='bookings')
    room = models.ForeignKey(HostelRoom, on_delete=models.SET_NULL, null=True, blank=True, related_name='bookings')
    check_in_date = models.DateField()
    check_out_date = models.DateField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    special_requests = models.TextField(blank=True, null=True)
    confirmed_at = models.DateTimeField(blank=True, null=True)
    cancelled_at = models.DateTimeField(blank=True, null=True)
    cancellation_reason = models.TextField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Hostel Booking'
        verbose_name_plural = 'Hostel Bookings'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['booking_id', 'status']),
            models.Index(fields=['user', 'status']),
            models.Index(fields=['hostel', 'check_in_date']),
        ]
    
    def __str__(self):
        return f"{self.booking_id} - {self.user.username}"
    
    def save(self, *args, **kwargs):
        if not self.booking_id:
            import uuid
            self.booking_id = f"HOST-{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)


# Cafeteria Management
class Cafeteria(TimestampedModel):
    """Cafeteria model"""
    
    name = models.CharField(max_length=200)
    code = models.CharField(max_length=20, unique=True)
    location = models.CharField(max_length=200)
    capacity = models.IntegerField(default=0)
    current_occupancy = models.IntegerField(default=0)
    operating_hours = models.JSONField(
        default=dict,
        blank=True,
        help_text='Operating hours by day (e.g., {"monday": "7:00-22:00"})'
    )
    is_active = models.BooleanField(default=True)
    
    class Meta:
        verbose_name = 'Cafeteria'
        verbose_name_plural = 'Cafeterias'
        ordering = ['name']
    
    def __str__(self):
        return self.name


class CafeteriaMenu(TimestampedModel):
    """Cafeteria menu item"""
    
    MEAL_TYPES = [
        ('breakfast', 'Breakfast'),
        ('lunch', 'Lunch'),
        ('dinner', 'Dinner'),
        ('snacks', 'Snacks'),
        ('beverages', 'Beverages'),
    ]
    
    cafeteria = models.ForeignKey(Cafeteria, on_delete=models.CASCADE, related_name='menu_items')
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    meal_type = models.CharField(max_length=20, choices=MEAL_TYPES)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    image_url = models.URLField(blank=True, null=True)
    is_available = models.BooleanField(default=True)
    is_vegetarian = models.BooleanField(default=False)
    is_vegan = models.BooleanField(default=False)
    allergens = models.JSONField(
        default=list,
        blank=True,
        help_text='List of allergens'
    )
    nutritional_info = models.JSONField(
        default=dict,
        blank=True,
        help_text='Nutritional information'
    )
    
    class Meta:
        verbose_name = 'Cafeteria Menu Item'
        verbose_name_plural = 'Cafeteria Menu Items'
        ordering = ['cafeteria', 'meal_type', 'name']
    
    def __str__(self):
        return f"{self.cafeteria.name} - {self.name}"


class CafeteriaBooking(TimestampedModel):
    """Cafeteria table/seat booking"""
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('active', 'Active'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
        ('no_show', 'No Show'),
    ]
    
    booking_id = models.CharField(max_length=20, unique=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='cafeteria_bookings')
    cafeteria = models.ForeignKey(Cafeteria, on_delete=models.CASCADE, related_name='bookings')
    booking_date = models.DateField()
    booking_time = models.TimeField()
    number_of_guests = models.IntegerField(default=1, validators=[MinValueValidator(1)])
    special_requests = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    confirmed_at = models.DateTimeField(blank=True, null=True)
    cancelled_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Cafeteria Booking'
        verbose_name_plural = 'Cafeteria Bookings'
        ordering = ['-booking_date', '-booking_time']
        indexes = [
            models.Index(fields=['booking_id', 'status']),
            models.Index(fields=['user', 'booking_date']),
            models.Index(fields=['cafeteria', 'booking_date', 'booking_time']),
        ]
    
    def __str__(self):
        return f"{self.booking_id} - {self.user.username}"
    
    def save(self, *args, **kwargs):
        if not self.booking_id:
            import uuid
            self.booking_id = f"CAFE-{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)


class CafeteriaOrder(TimestampedModel):
    """Cafeteria food order"""
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('preparing', 'Preparing'),
        ('ready', 'Ready'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    order_id = models.CharField(max_length=20, unique=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='cafeteria_orders')
    cafeteria = models.ForeignKey(Cafeteria, on_delete=models.CASCADE, related_name='orders')
    items = models.JSONField(
        default=list,
        help_text='List of menu items with quantities'
    )
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    special_instructions = models.TextField(blank=True, null=True)
    pickup_time = models.DateTimeField(blank=True, null=True)
    completed_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Cafeteria Order'
        verbose_name_plural = 'Cafeteria Orders'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['order_id', 'status']),
            models.Index(fields=['user', 'status']),
            models.Index(fields=['cafeteria', 'status']),
        ]
    
    def __str__(self):
        return f"{self.order_id} - {self.user.username}"
    
    def save(self, *args, **kwargs):
        if not self.order_id:
            import uuid
            self.order_id = f"ORD-{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)


# Campus Transport
class TransportRoute(TimestampedModel):
    """Campus transport route"""
    
    ROUTE_TYPES = [
        ('shuttle', 'Shuttle'),
        ('bus', 'Bus'),
        ('van', 'Van'),
        ('other', 'Other'),
    ]
    
    name = models.CharField(max_length=200)
    route_code = models.CharField(max_length=20, unique=True)
    route_type = models.CharField(max_length=20, choices=ROUTE_TYPES, default='shuttle')
    start_location = models.CharField(max_length=200)
    end_location = models.CharField(max_length=200)
    stops = models.JSONField(
        default=list,
        blank=True,
        help_text='List of stops with coordinates'
    )
    distance_km = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    estimated_duration_minutes = models.IntegerField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    
    class Meta:
        verbose_name = 'Transport Route'
        verbose_name_plural = 'Transport Routes'
        ordering = ['name']
    
    def __str__(self):
        return f"{self.name} ({self.route_code})"


class TransportSchedule(TimestampedModel):
    """Transport schedule"""
    
    route = models.ForeignKey(TransportRoute, on_delete=models.CASCADE, related_name='schedules')
    departure_time = models.TimeField()
    arrival_time = models.TimeField(blank=True, null=True)
    day_of_week = models.IntegerField(
        validators=[MinValueValidator(0), MaxValueValidator(6)],
        help_text='0=Monday, 6=Sunday'
    )
    is_active = models.BooleanField(default=True)
    
    class Meta:
        verbose_name = 'Transport Schedule'
        verbose_name_plural = 'Transport Schedules'
        ordering = ['route', 'day_of_week', 'departure_time']
        unique_together = [['route', 'day_of_week', 'departure_time']]
    
    def __str__(self):
        return f"{self.route.name} - {self.get_day_display()} {self.departure_time}"


class TransportVehicle(TimestampedModel):
    """Transport vehicle"""
    
    VEHICLE_TYPES = [
        ('bus', 'Bus'),
        ('shuttle', 'Shuttle'),
        ('van', 'Van'),
        ('car', 'Car'),
    ]
    
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('maintenance', 'Maintenance'),
        ('inactive', 'Inactive'),
    ]
    
    vehicle_number = models.CharField(max_length=50, unique=True)
    vehicle_type = models.CharField(max_length=20, choices=VEHICLE_TYPES)
    capacity = models.IntegerField()
    current_route = models.ForeignKey(
        TransportRoute,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='vehicles'
    )
    current_location = models.CharField(max_length=200, blank=True, null=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    last_updated = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Transport Vehicle'
        verbose_name_plural = 'Transport Vehicles'
        ordering = ['vehicle_number']
        indexes = [
            models.Index(fields=['status', 'current_route']),
            models.Index(fields=['last_updated']),
        ]
    
    def __str__(self):
        return f"{self.vehicle_number} - {self.get_vehicle_type_display()}"


class TransportLiveInfo(TimestampedModel):
    """Live transport information"""
    
    vehicle = models.ForeignKey(TransportVehicle, on_delete=models.CASCADE, related_name='live_info')
    route = models.ForeignKey(TransportRoute, on_delete=models.CASCADE, related_name='live_info')
    current_stop = models.CharField(max_length=200, blank=True, null=True)
    next_stop = models.CharField(max_length=200, blank=True, null=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    speed_kmh = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    estimated_arrival_minutes = models.IntegerField(blank=True, null=True)
    current_passengers = models.IntegerField(default=0)
    is_on_time = models.BooleanField(default=True)
    
    class Meta:
        verbose_name = 'Transport Live Info'
        verbose_name_plural = 'Transport Live Info'
        ordering = ['-updated_at']
        indexes = [
            models.Index(fields=['vehicle', 'route']),
            models.Index(fields=['updated_at']),
        ]
    
    def __str__(self):
        return f"{self.vehicle.vehicle_number} - {self.route.name}"

