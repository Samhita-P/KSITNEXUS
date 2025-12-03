"""
Serializers for reservations app
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import ReadingRoom, Seat, Reservation, ReservationHistory, SeatAvailability

User = get_user_model()


class ReadingRoomSerializer(serializers.ModelSerializer):
    """Reading room serializer"""
    
    # Map snake_case fields to camelCase for frontend compatibility with null handling
    isActive = serializers.SerializerMethodField()
    hasWifi = serializers.SerializerMethodField()
    hasChargingPoints = serializers.SerializerMethodField()
    hasAirConditioning = serializers.SerializerMethodField()
    openingTime = serializers.SerializerMethodField()
    closingTime = serializers.SerializerMethodField()
    maxReservationHours = serializers.SerializerMethodField()
    advanceBookingHours = serializers.SerializerMethodField()
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)
    updatedAt = serializers.DateTimeField(source='updated_at', read_only=True)
    
    def get_isActive(self, obj):
        return bool(obj.is_active) if obj.is_active is not None else False
    
    def get_hasWifi(self, obj):
        return bool(obj.has_wifi) if obj.has_wifi is not None else False
    
    def get_hasChargingPoints(self, obj):
        return bool(obj.has_charging_points) if obj.has_charging_points is not None else False
    
    def get_hasAirConditioning(self, obj):
        return bool(obj.has_air_conditioning) if obj.has_air_conditioning is not None else False
    
    def get_openingTime(self, obj):
        return obj.opening_time.strftime('%H:%M') if obj.opening_time else '08:00'
    
    def get_closingTime(self, obj):
        return obj.closing_time.strftime('%H:%M') if obj.closing_time else '22:00'
    
    def get_maxReservationHours(self, obj):
        return obj.max_reservation_hours if obj.max_reservation_hours is not None else 4
    
    def get_advanceBookingHours(self, obj):
        return obj.advance_booking_hours if obj.advance_booking_hours is not None else 24
    
    # Add seat availability information
    totalSeats = serializers.SerializerMethodField()
    availableSeats = serializers.SerializerMethodField()
    occupiedSeats = serializers.SerializerMethodField()
    seats = serializers.SerializerMethodField()
    
    class Meta:
        model = ReadingRoom
        fields = [
            'id', 'name', 'description', 'location', 'capacity',
            'isActive', 'hasWifi', 'hasChargingPoints', 'hasAirConditioning',
            'openingTime', 'closingTime', 'maxReservationHours',
            'advanceBookingHours', 'createdAt', 'updatedAt',
            'totalSeats', 'availableSeats', 'occupiedSeats', 'seats'
        ]
        read_only_fields = ['id', 'createdAt', 'updatedAt']
    
    def to_representation(self, instance):
        """Override to ensure all string fields are non-null"""
        data = super().to_representation(instance)
        
        # Ensure string fields are never null
        data['name'] = data.get('name') or ''
        data['description'] = data.get('description') or ''
        data['location'] = data.get('location') or ''
        
        # Ensure integer fields are never null
        data['id'] = data.get('id') or 0
        data['capacity'] = data.get('capacity') or 0
        data['totalSeats'] = data.get('totalSeats') or 0
        data['availableSeats'] = data.get('availableSeats') or 0
        data['occupiedSeats'] = data.get('occupiedSeats') or 0
        data['maxReservationHours'] = data.get('maxReservationHours') or 4
        data['advanceBookingHours'] = data.get('advanceBookingHours') or 24
        
        return data
    
    def get_totalSeats(self, obj):
        """Get total number of seats in the room"""
        return obj.seats.filter(is_active=True).count()
    
    def get_availableSeats(self, obj):
        """Get number of available seats"""
        from django.utils import timezone
        now = timezone.now()
        
        # Get seats that are not currently reserved
        occupied_seat_ids = Reservation.objects.filter(
            seat__room=obj,
            status__in=['confirmed', 'active'],
            start_time__lte=now,
            end_time__gte=now
        ).values_list('seat_id', flat=True)
        
        return obj.seats.filter(
            is_active=True
        ).exclude(id__in=occupied_seat_ids).count()
    
    def get_occupiedSeats(self, obj):
        """Get number of occupied seats"""
        from django.utils import timezone
        now = timezone.now()
        
        return Reservation.objects.filter(
            seat__room=obj,
            status__in=['confirmed', 'active'],
            start_time__lte=now,
            end_time__gte=now
        ).count()
    
    def get_seats(self, obj):
        """Get detailed seat information with status"""
        from django.utils import timezone
        now = timezone.now()
        
        # Get all active seats
        seats = obj.seats.filter(is_active=True).order_by('row_number', 'column_number')
        
        # Get occupied seat IDs
        occupied_seat_ids = Reservation.objects.filter(
            seat__room=obj,
            status__in=['confirmed', 'active'],
            start_time__lte=now,
            end_time__gte=now
        ).values_list('seat_id', flat=True)
        
        # Create seat data with status
        seat_data = []
        for seat in seats:
            seat_info = {
                'id': seat.id,
                'seatNumber': seat.seat_number,
                'seatType': seat.seat_type,
                'rowNumber': seat.row_number or 0,
                'columnNumber': seat.column_number or 0,
                'tableNumber': seat.table_number,
                'hasPowerOutlet': bool(seat.has_power_outlet) if seat.has_power_outlet is not None else False,
                'hasLight': bool(seat.has_light) if seat.has_light is not None else True,
                'status': 'occupied' if seat.id in occupied_seat_ids else 'free',
                'isAvailable': seat.id not in occupied_seat_ids,
            }
            seat_data.append(seat_info)
        
        return seat_data


class SeatSerializer(serializers.ModelSerializer):
    """Seat serializer"""
    # Map snake_case fields to camelCase for frontend compatibility
    seatNumber = serializers.CharField(source='seat_number', read_only=True)
    seatType = serializers.CharField(source='seat_type', read_only=True)
    isActive = serializers.BooleanField(source='is_active', read_only=True)
    hasPowerOutlet = serializers.SerializerMethodField()
    hasLight = serializers.SerializerMethodField()
    rowNumber = serializers.SerializerMethodField()
    columnNumber = serializers.SerializerMethodField()
    tableNumber = serializers.SerializerMethodField()
    isAvailableNow = serializers.ReadOnlyField(source='is_available_now')
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)
    updatedAt = serializers.DateTimeField(source='updated_at', read_only=True)
    
    def get_hasPowerOutlet(self, obj):
        return bool(obj.has_power_outlet) if obj.has_power_outlet is not None else False
    
    def get_hasLight(self, obj):
        return bool(obj.has_light) if obj.has_light is not None else True
    
    def get_rowNumber(self, obj):
        return obj.row_number or 0
    
    def get_columnNumber(self, obj):
        return obj.column_number or 0
    
    def get_tableNumber(self, obj):
        return obj.table_number
    
    class Meta:
        model = Seat
        fields = [
            'id', 'seatNumber', 'seatType', 'isActive',
            'hasPowerOutlet', 'hasLight', 'rowNumber',
            'columnNumber', 'tableNumber', 'isAvailableNow', 'createdAt', 'updatedAt'
        ]
        read_only_fields = ['id', 'createdAt', 'updatedAt', 'isAvailableNow']
    
    def to_representation(self, instance):
        """Override to ensure all string fields are non-null"""
        data = super().to_representation(instance)
        
        # Ensure string fields are never null
        data['seatNumber'] = data.get('seatNumber') or ''
        data['seatType'] = data.get('seatType') or 'standard'
        
        # Ensure integer fields are never null
        data['id'] = data.get('id') or 0
        data['rowNumber'] = data.get('rowNumber') or 0
        data['columnNumber'] = data.get('columnNumber') or 0
        data['tableNumber'] = data.get('tableNumber')
        
        return data


class ReservationSerializer(serializers.ModelSerializer):
    """Reservation serializer"""
    user = serializers.StringRelatedField(read_only=True)
    seat = SeatSerializer(read_only=True)
    duration_hours = serializers.ReadOnlyField()
    is_active = serializers.ReadOnlyField()
    is_upcoming = serializers.ReadOnlyField()
    
    # Add fields that the frontend expects
    userId = serializers.IntegerField(source='user.id', read_only=True)
    userName = serializers.CharField(source='user.username', read_only=True)
    roomId = serializers.IntegerField(source='seat.room.id', read_only=True)
    roomName = serializers.CharField(source='seat.room.name', read_only=True)
    seatId = serializers.IntegerField(source='seat.id', read_only=True)
    seatNumber = serializers.CharField(source='seat.seat_number', read_only=True)
    startTime = serializers.DateTimeField(source='start_time', read_only=True)
    endTime = serializers.DateTimeField(source='end_time', read_only=True)
    checkedInAt = serializers.DateTimeField(source='checked_in_at', read_only=True)
    checkedOutAt = serializers.DateTimeField(source='checked_out_at', read_only=True)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)
    updatedAt = serializers.DateTimeField(source='updated_at', read_only=True)
    durationHours = serializers.ReadOnlyField(source='duration_hours')
    isActive = serializers.ReadOnlyField(source='is_active')
    isUpcoming = serializers.ReadOnlyField(source='is_upcoming')
    
    class Meta:
        model = Reservation
        fields = [
            'id', 'userId', 'userName', 'roomId', 'roomName', 'seatId', 'seatNumber',
            'seat', 'startTime', 'endTime', 'status', 'purpose', 'notes', 
            'checkedInAt', 'checkedOutAt', 'createdAt', 'updatedAt', 
            'durationHours', 'isActive', 'isUpcoming'
        ]
        read_only_fields = [
            'id', 'userId', 'userName', 'roomId', 'roomName', 'seatId', 'seatNumber',
            'createdAt', 'updatedAt', 'durationHours', 'isActive', 'isUpcoming'
        ]


class ReservationCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating reservations"""
    seatId = serializers.IntegerField(write_only=True, required=False)
    seatIds = serializers.ListField(
        child=serializers.IntegerField(),
        write_only=True,
        required=False,
        help_text='List of seat IDs for multiple seat reservations'
    )
    roomId = serializers.IntegerField(write_only=True, required=False)
    startTime = serializers.DateTimeField(write_only=True, source='start_time')
    endTime = serializers.DateTimeField(write_only=True, source='end_time')
    
    class Meta:
        model = Reservation
        fields = ['seatId', 'seatIds', 'roomId', 'startTime', 'endTime', 'purpose', 'notes']
    
    def validate_seatId(self, value):
        """Validate seat exists and is available"""
        try:
            seat = Seat.objects.get(id=value)
        except Seat.DoesNotExist:
            raise serializers.ValidationError("Seat not found")
        
        if not seat.is_active:
            raise serializers.ValidationError("Seat is not active")
        
        return value
    
    def validate(self, attrs):
        """Validate reservation"""
        print(f"DEBUG: validate called with attrs: {attrs}")
        seat_id = attrs.get('seatId')  # Get from the camelCase field
        seat_ids = attrs.get('seatIds', [])  # Get list of seat IDs
        start_time = attrs.get('start_time')  # This will be populated by source mapping
        end_time = attrs.get('end_time')  # This will be populated by source mapping
        
        print(f"DEBUG: seat_id: {seat_id}")
        print(f"DEBUG: seat_ids: {seat_ids}")
        print(f"DEBUG: start_time: {start_time}")
        print(f"DEBUG: end_time: {end_time}")
        
        # Support both single seat and multiple seats
        if not seat_id and not seat_ids:
            raise serializers.ValidationError("Either seatId or seatIds is required")
        
        # Normalize to list for easier processing
        if seat_id and not seat_ids:
            seat_ids = [seat_id]
        elif seat_id and seat_ids:
            # If both provided, combine them
            seat_ids = list(set([seat_id] + seat_ids))
        
        if not start_time:
            raise serializers.ValidationError("Start time is required")
            
        if not end_time:
            raise serializers.ValidationError("End time is required")
        
        # Validate all seats
        seats = []
        room = None
        for sid in seat_ids:
            try:
                seat = Seat.objects.get(id=sid)
            except Seat.DoesNotExist:
                raise serializers.ValidationError(f"Seat with ID {sid} not found")
            
            if not seat.is_active:
                raise serializers.ValidationError(f"Seat {seat.seat_number} is not active")
            
            # Check if seat is available for the time period
            overlapping = Reservation.objects.filter(
                seat=seat,
                status__in=['confirmed', 'active'],
                start_time__lt=end_time,
                end_time__gt=start_time
            )
            
            if overlapping.exists():
                raise serializers.ValidationError(f"Seat {seat.seat_number} is already reserved for this time period")
            
            seats.append(seat)
            if room is None:
                room = seat.room
            elif room.id != seat.room.id:
                raise serializers.ValidationError("All seats must be in the same room")
        
        # Check if room is open
        start_hour = start_time.hour
        end_hour = end_time.hour
        
        if start_hour < room.opening_time.hour or end_hour > room.closing_time.hour:
            raise serializers.ValidationError("Reservation time is outside room operating hours")
        
        # Check maximum reservation hours
        duration_hours = (end_time - start_time).total_seconds() / 3600
        if duration_hours > room.max_reservation_hours:
            raise serializers.ValidationError(f"Reservation cannot exceed {room.max_reservation_hours} hours")
        
        # Store seat_ids for use in create method
        attrs['seat_ids'] = seat_ids
        
        return attrs
    
    def create(self, validated_data):
        """Create a new reservation (or multiple reservations for multiple seats)"""
        print(f"DEBUG: create called with validated_data: {validated_data}")
        seat_ids = validated_data.pop('seat_ids', [])  # Get list of seat IDs
        validated_data.pop('seatId', None)  # Remove single seatId if present
        validated_data.pop('seatIds', None)  # Remove seatIds list if present
        validated_data.pop('roomId', None)  # Remove roomId if present
        
        print(f"DEBUG: seat_ids after pop: {seat_ids}")
        print(f"DEBUG: remaining validated_data: {validated_data}")
        
        # Create reservations for all seats
        reservations = []
        for seat_id in seat_ids:
            seat = Seat.objects.get(id=seat_id)
            reservation = Reservation.objects.create(
                user=self.context['request'].user,
                seat=seat,
                **validated_data
            )
            reservations.append(reservation)
            print(f"DEBUG: reservation created with id: {reservation.id} for seat {seat.seat_number}")
        
        # Return the first reservation (for backward compatibility)
        # In the future, we might want to return a list or a grouped reservation
        return reservations[0] if reservations else None
    
    def to_representation(self, instance):
        """Return the created reservation in the format expected by frontend"""
        if isinstance(instance, Reservation):
            return {
                'id': instance.id,
                'userId': instance.user.id,
                'userName': instance.user.username,
                'roomId': instance.seat.room.id,
                'roomName': instance.seat.room.name,
                'seatId': instance.seat.id,
                'seatNumber': instance.seat.seat_number,
                'startTime': instance.start_time.isoformat(),
                'endTime': instance.end_time.isoformat(),
                'status': instance.status,
                'purpose': instance.purpose or '',
                'notes': instance.notes or '',
                'checkedInAt': instance.checked_in_at.isoformat() if instance.checked_in_at else None,
                'checkedOutAt': instance.checked_out_at.isoformat() if instance.checked_out_at else None,
                'createdAt': instance.created_at.isoformat(),
                'updatedAt': instance.updated_at.isoformat(),
                'durationHours': instance.duration_hours,
                'isActive': instance.is_active,
                'isUpcoming': instance.is_upcoming,
            }
        return super().to_representation(instance)


class ReservationHistorySerializer(serializers.ModelSerializer):
    """Reservation history serializer"""
    performed_by = serializers.StringRelatedField(read_only=True)
    
    class Meta:
        model = ReservationHistory
        fields = [
            'id', 'action', 'performed_by', 'notes', 'timestamp'
        ]
        read_only_fields = ['id', 'timestamp']


class SeatAvailabilitySerializer(serializers.ModelSerializer):
    """Seat availability serializer"""
    
    class Meta:
        model = SeatAvailability
        fields = [
            'id', 'seat', 'date', 'hour', 'is_available', 'reservation_count'
        ]
        read_only_fields = ['id']


class ReservationListSerializer(serializers.ModelSerializer):
    """Reservation serializer for list views with all frontend fields"""
    seat = SeatSerializer(read_only=True)
    userId = serializers.IntegerField(source='user.id', read_only=True)
    userName = serializers.CharField(source='user.username', read_only=True)
    roomId = serializers.IntegerField(source='seat.room.id', read_only=True)
    roomName = serializers.CharField(source='seat.room.name', read_only=True)
    seatId = serializers.IntegerField(source='seat.id', read_only=True)
    seatNumber = serializers.CharField(source='seat.seat_number', read_only=True)
    startTime = serializers.DateTimeField(source='start_time', read_only=True)
    endTime = serializers.DateTimeField(source='end_time', read_only=True)
    checkedInAt = serializers.DateTimeField(source='checked_in_at', read_only=True)
    checkedOutAt = serializers.DateTimeField(source='checked_out_at', read_only=True)
    createdAt = serializers.DateTimeField(source='created_at', read_only=True)
    updatedAt = serializers.DateTimeField(source='updated_at', read_only=True)
    durationHours = serializers.ReadOnlyField(source='duration_hours')
    isActive = serializers.ReadOnlyField(source='is_active')
    isUpcoming = serializers.ReadOnlyField(source='is_upcoming')
    
    class Meta:
        model = Reservation
        fields = [
            'id', 'userId', 'userName', 'roomId', 'roomName', 'seatId', 'seatNumber',
            'seat', 'startTime', 'endTime', 'status', 'purpose', 'notes',
            'checkedInAt', 'checkedOutAt', 'createdAt', 'updatedAt',
            'durationHours', 'isActive', 'isUpcoming'
        ]
    
    def to_representation(self, instance):
        """Override to ensure all fields are non-null"""
        data = super().to_representation(instance)
        
        # Ensure integer fields are never null
        data['id'] = data.get('id') or 0
        data['userId'] = data.get('userId') or 0
        data['roomId'] = data.get('roomId') or 0
        data['seatId'] = data.get('seatId') or 0
        
        # Ensure string fields are never null
        data['userName'] = data.get('userName') or ''
        data['roomName'] = data.get('roomName') or ''
        data['seatNumber'] = data.get('seatNumber') or ''
        data['status'] = data.get('status') or 'unknown'
        data['purpose'] = data.get('purpose') or ''
        data['notes'] = data.get('notes') or ''
        
        # Ensure numeric fields are never null
        data['durationHours'] = data.get('durationHours') or 0.0
        
        # Ensure boolean fields are never null
        data['isActive'] = data.get('isActive') or False
        data['isUpcoming'] = data.get('isUpcoming') or False
        
        return data


class CheckInSerializer(serializers.Serializer):
    """Check-in serializer"""
    notes = serializers.CharField(required=False, allow_blank=True)


class CheckOutSerializer(serializers.Serializer):
    """Check-out serializer"""
    notes = serializers.CharField(required=False, allow_blank=True)


class CancelReservationSerializer(serializers.Serializer):
    """Cancel reservation serializer"""
    reason = serializers.CharField(required=False, allow_blank=True)
