"""
Reading Room and Seat Reservation models for KSIT Nexus
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone

User = get_user_model()


class ReadingRoom(models.Model):
    """Reading room/study area model"""
    
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    location = models.CharField(max_length=200)
    capacity = models.IntegerField(validators=[MinValueValidator(1)])
    
    # Room settings
    is_active = models.BooleanField(default=True)
    has_wifi = models.BooleanField(default=True)
    has_charging_points = models.BooleanField(default=True)
    has_air_conditioning = models.BooleanField(default=False)
    
    # Operating hours
    opening_time = models.TimeField()
    closing_time = models.TimeField()
    
    # Rules and restrictions
    max_reservation_hours = models.IntegerField(default=4)
    advance_booking_hours = models.IntegerField(default=24)  # Can book 24 hours in advance
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['name']
    
    def __str__(self):
        return f"{self.name} - {self.location}"


class Seat(models.Model):
    """Individual seat model"""
    
    SEAT_TYPES = [
        ('single', 'Single Seat'),
        ('double', 'Double Seat'),
        ('group', 'Group Table'),
        ('computer', 'Computer Station'),
    ]
    
    room = models.ForeignKey(ReadingRoom, on_delete=models.CASCADE, related_name='seats')
    seat_number = models.CharField(max_length=20)
    seat_type = models.CharField(max_length=15, choices=SEAT_TYPES, default='single')
    
    # Seat properties
    is_active = models.BooleanField(default=True)
    has_power_outlet = models.BooleanField(default=False)
    has_light = models.BooleanField(default=True)
    
    # Location within room
    row_number = models.IntegerField(blank=True, null=True)
    column_number = models.IntegerField(blank=True, null=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['room', 'seat_number']
        ordering = ['room', 'seat_number']
    
    def __str__(self):
        return f"{self.room.name} - Seat {self.seat_number}"
    
    @property
    def is_available_now(self):
        """Check if seat is currently available"""
        now = timezone.now()
        return not self.reservations.filter(
            start_time__lte=now,
            end_time__gte=now,
            status__in=['confirmed', 'active']
        ).exists()


class Reservation(models.Model):
    """Seat reservation model"""
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('active', 'Active'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
        ('no_show', 'No Show'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reservations')
    seat = models.ForeignKey(Seat, on_delete=models.CASCADE, related_name='reservations')
    
    # Reservation details
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='pending')
    
    # Purpose and notes
    purpose = models.CharField(max_length=200, blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    
    # Check-in/out
    checked_in_at = models.DateTimeField(blank=True, null=True)
    checked_out_at = models.DateTimeField(blank=True, null=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.username} - {self.seat} ({self.start_time.date()})"
    
    @property
    def duration_hours(self):
        """Calculate reservation duration in hours"""
        if self.start_time and self.end_time:
            delta = self.end_time - self.start_time
            return delta.total_seconds() / 3600
        return 0
    
    @property
    def is_active(self):
        """Check if reservation is currently active"""
        now = timezone.now()
        return (
            self.status == 'active' and 
            self.start_time <= now <= self.end_time
        )
    
    @property
    def is_upcoming(self):
        """Check if reservation is upcoming"""
        return self.start_time > timezone.now() and self.status == 'confirmed'
    
    def clean(self):
        """Validate reservation"""
        from django.core.exceptions import ValidationError
        
        if self.start_time >= self.end_time:
            raise ValidationError("End time must be after start time")
        
        if self.start_time < timezone.now():
            raise ValidationError("Cannot create reservation in the past")
        
        # Check for overlapping reservations
        overlapping = Reservation.objects.filter(
            seat=self.seat,
            status__in=['confirmed', 'active'],
            start_time__lt=self.end_time,
            end_time__gt=self.start_time
        ).exclude(pk=self.pk)
        
        if overlapping.exists():
            raise ValidationError("Seat is already reserved for this time period")


class ReservationHistory(models.Model):
    """Track reservation history for analytics"""
    
    reservation = models.ForeignKey(Reservation, on_delete=models.CASCADE, related_name='history')
    action = models.CharField(max_length=50)  # created, confirmed, checked_in, checked_out, cancelled
    performed_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reservation_actions')
    notes = models.TextField(blank=True, null=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-timestamp']
    
    def __str__(self):
        return f"{self.action} - {self.reservation} by {self.performed_by.username}"


class SeatAvailability(models.Model):
    """Track seat availability patterns"""
    
    seat = models.ForeignKey(Seat, on_delete=models.CASCADE, related_name='availability')
    date = models.DateField()
    hour = models.IntegerField(validators=[MinValueValidator(0), MaxValueValidator(23)])
    is_available = models.BooleanField(default=True)
    reservation_count = models.IntegerField(default=0)
    
    class Meta:
        unique_together = ['seat', 'date', 'hour']
        ordering = ['date', 'hour']
    
    def __str__(self):
        return f"{self.seat} - {self.date} {self.hour}:00"
