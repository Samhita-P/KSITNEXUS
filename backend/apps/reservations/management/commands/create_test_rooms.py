"""
Management command to create test reading rooms and seats with realistic data
"""
from django.core.management.base import BaseCommand
from apps.reservations.models import ReadingRoom, Seat, Reservation
from django.contrib.auth import get_user_model
from datetime import time, datetime, timedelta
import random

User = get_user_model()


class Command(BaseCommand):
    help = 'Creates test reading rooms and seats with realistic data'

    def handle(self, *args, **options):
        # Create test reading rooms with different configurations
        rooms_data = [
            {
                'name': 'Study Hall - Room 101',
                'description': 'Quiet study area with individual desks',
                'location': 'First Floor, Building A',
                'capacity': 20,
                'is_active': True,
                'has_wifi': True,
                'has_charging_points': True,
                'has_air_conditioning': True,
                'opening_time': time(8, 0),
                'closing_time': time(22, 0),
                'max_reservation_hours': 4,
                'advance_booking_hours': 24,
            },
            {
                'name': 'Group Study Room 201',
                'description': 'Collaborative workspace for group projects',
                'location': 'Second Floor, Building A',
                'capacity': 8,
                'is_active': True,
                'has_wifi': True,
                'has_charging_points': True,
                'has_air_conditioning': True,
                'opening_time': time(9, 0),
                'closing_time': time(21, 0),
                'max_reservation_hours': 6,
                'advance_booking_hours': 48,
            },
            {
                'name': 'Silent Reading Room 301',
                'description': 'Absolute silence required - perfect for focused study',
                'location': 'Third Floor, Building A',
                'capacity': 15,
                'is_active': True,
                'has_wifi': False,
                'has_charging_points': False,
                'has_air_conditioning': True,
                'opening_time': time(7, 0),
                'closing_time': time(23, 0),
                'max_reservation_hours': 8,
                'advance_booking_hours': 72,
            },
            {
                'name': 'Computer Lab 401',
                'description': 'Computer workstations for digital projects',
                'location': 'Fourth Floor, Building A',
                'capacity': 12,
                'is_active': True,
                'has_wifi': True,
                'has_charging_points': True,
                'has_air_conditioning': True,
                'opening_time': time(8, 30),
                'closing_time': time(20, 30),
                'max_reservation_hours': 3,
                'advance_booking_hours': 12,
            },
            {
                'name': 'Main Library Hall',
                'description': 'Large open space with flexible seating',
                'location': 'Ground Floor, Main Building',
                'capacity': 50,
                'is_active': True,
                'has_wifi': True,
                'has_charging_points': True,
                'has_air_conditioning': True,
                'opening_time': time(6, 0),
                'closing_time': time(24, 0),
                'max_reservation_hours': 2,
                'advance_booking_hours': 6,
            },
            {
                'name': 'Closed Room 501',
                'description': 'This room is temporarily closed for maintenance',
                'location': 'Fifth Floor, Building A',
                'capacity': 10,
                'is_active': False,  # Closed room
                'has_wifi': True,
                'has_charging_points': True,
                'has_air_conditioning': True,
                'opening_time': time(8, 0),
                'closing_time': time(22, 0),
                'max_reservation_hours': 4,
                'advance_booking_hours': 24,
            },
        ]

        created_rooms = []
        for room_data in rooms_data:
            room, created = ReadingRoom.objects.get_or_create(
                name=room_data['name'],
                defaults=room_data
            )
            created_rooms.append(room)
            if created:
                self.stdout.write(
                    self.style.SUCCESS(f'Created room: {room.name}')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'Room already exists: {room.name}')
                )

        # Create seats for each room with realistic layouts
        for room in created_rooms:
            if not room.is_active:
                continue  # Skip creating seats for closed rooms
                
            # Create seats based on room capacity with realistic layouts
            seats_per_row = 5 if room.capacity <= 20 else 10
            rows = (room.capacity + seats_per_row - 1) // seats_per_row
            
            for i in range(1, room.capacity + 1):
                seat_type = self._get_seat_type(room, i)
                seat_number = f'{room.name.split()[-1]}-{i:02d}'
                row = (i - 1) // seats_per_row
                col = (i - 1) % seats_per_row
                
                seat, created = Seat.objects.get_or_create(
                    room=room,
                    seat_number=seat_number,
                    defaults={
                        'seat_type': seat_type,
                        'is_active': True,
                        'has_power_outlet': room.has_charging_points and random.choice([True, False, True]),  # 66% chance
                        'has_light': True,
                        'row_number': row,
                        'column_number': col,
                    }
                )
                
                if created:
                    self.stdout.write(
                        self.style.SUCCESS(f'Created seat: {seat.seat_number}')
                    )

        # Create some test reservations to show occupied seats
        self._create_test_reservations(created_rooms)

        self.stdout.write(
            self.style.SUCCESS('Successfully created test reading rooms and seats with reservations.')
        )

    def _get_seat_type(self, room, seat_number):
        """Determine seat type based on room and position"""
        if 'Computer Lab' in room.name:
            return 'computer'
        elif 'Group Study' in room.name:
            return 'group'
        elif seat_number % 3 == 0:  # Every 3rd seat is double
            return 'double'
        else:
            return 'single'

    def _create_test_reservations(self, rooms):
        """Create some test reservations to show occupied seats"""
        # Get or create a test user
        user, created = User.objects.get_or_create(
            username='testuser',
            defaults={
                'email': 'test@example.com',
                'first_name': 'Test',
                'last_name': 'User',
                'user_type': 'student',
            }
        )
        
        if created:
            user.set_password('testpass123')
            user.save()
            self.stdout.write(self.style.SUCCESS('Created test user: testuser'))

        # Create some current reservations (active now)
        now = datetime.now()
        for room in rooms:
            if not room.is_active or room.capacity < 5:
                continue
                
            # Get some seats from this room
            seats = list(room.seats.filter(is_active=True)[:3])  # Take first 3 seats
            
            for i, seat in enumerate(seats):
                if i == 0:  # First seat - currently active reservation
                    start_time = now - timedelta(hours=1)  # Started 1 hour ago
                    end_time = now + timedelta(hours=2)    # Ends in 2 hours
                    status = 'active'
                elif i == 1:  # Second seat - confirmed reservation starting soon
                    start_time = now + timedelta(hours=1)  # Starts in 1 hour
                    end_time = now + timedelta(hours=3)    # Ends in 3 hours
                    status = 'confirmed'
                else:  # Third seat - past reservation
                    start_time = now - timedelta(hours=4)  # Started 4 hours ago
                    end_time = now - timedelta(hours=2)    # Ended 2 hours ago
                    status = 'completed'
                
                reservation, created = Reservation.objects.get_or_create(
                    user=user,
                    seat=seat,
                    start_time=start_time,
                    end_time=end_time,
                    defaults={
                        'status': status,
                        'purpose': f'Study session in {room.name}',
                        'notes': f'Reservation for seat {seat.seat_number}',
                    }
                )
                
                if created:
                    self.stdout.write(
                        self.style.SUCCESS(f'Created reservation: {reservation.id} for seat {seat.seat_number}')
                    )