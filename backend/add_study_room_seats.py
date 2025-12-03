#!/usr/bin/env python
"""
Script to add missing seats for Study Room (Room ID 3)
Study Room needs: 50 seats total
- 10 tables with 4 seats each (40 seats) - A1 to A40
- 5 tables with 2 seats each (10 seats) - A41 to A50
"""

import os
import sys
import django

# Setup Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ksit_nexus.settings')
django.setup()

from apps.reservations.models import ReadingRoom, Seat

def add_study_room_seats():
    """Add missing seats for Study Room"""
    try:
        # Get Study Room (assuming room_id=3 based on the API call)
        study_room = ReadingRoom.objects.get(id=3)
        print(f"Found Study Room: {study_room.name} (ID: {study_room.id})")
        
        # Get existing seats
        existing_seats = Seat.objects.filter(room=study_room, is_active=True)
        existing_seat_numbers = set(existing_seats.values_list('seat_number', flat=True))
        print(f"Existing seats: {len(existing_seats)} - {sorted(existing_seat_numbers)}")
        
        # Create seats for 10 tables with 4 seats each (A1-A40)
        seats_created = 0
        table_num = 1
        seat_num = 1
        
        for table in range(1, 11):  # Tables 1-10
            for seat_in_table in range(1, 5):  # 4 seats per table
                seat_number = f"A{seat_num}"
                
                if seat_number not in existing_seat_numbers:
                    Seat.objects.create(
                        room=study_room,
                        seat_number=seat_number,
                        seat_type='standard',
                        table_number=table,
                        row_number=1 if seat_in_table <= 2 else 2,  # Top row: seats 1-2, Bottom row: seats 3-4
                        column_number=1 if seat_in_table % 2 == 1 else 2,  # Left: 1,3 Right: 2,4
                        is_active=True,
                        has_power_outlet=False,
                        has_light=True,
                    )
                    seats_created += 1
                    print(f"Created seat {seat_number} for Table {table}")
                else:
                    # Update existing seat with table number if missing
                    existing_seat = existing_seats.get(seat_number=seat_number)
                    if existing_seat.table_number != table:
                        existing_seat.table_number = table
                        existing_seat.row_number = 1 if seat_in_table <= 2 else 2
                        existing_seat.column_number = 1 if seat_in_table % 2 == 1 else 2
                        existing_seat.save()
                        print(f"Updated seat {seat_number} to Table {table}")
                
                seat_num += 1
        
        # Create seats for 5 tables with 2 seats each (A41-A50)
        for table in range(11, 16):  # Tables 11-15
            for seat_in_table in range(1, 3):  # 2 seats per table
                seat_number = f"A{seat_num}"
                
                if seat_number not in existing_seat_numbers:
                    Seat.objects.create(
                        room=study_room,
                        seat_number=seat_number,
                        seat_type='standard',
                        table_number=table,
                        row_number=1,
                        column_number=seat_in_table,  # Left: 1, Right: 2
                        is_active=True,
                        has_power_outlet=False,
                        has_light=True,
                    )
                    seats_created += 1
                    print(f"Created seat {seat_number} for Table {table}")
                else:
                    # Update existing seat with table number if missing
                    existing_seat = existing_seats.get(seat_number=seat_number)
                    if existing_seat.table_number != table:
                        existing_seat.table_number = table
                        existing_seat.row_number = 1
                        existing_seat.column_number = seat_in_table
                        existing_seat.save()
                        print(f"Updated seat {seat_number} to Table {table}")
                
                seat_num += 1
        
        # Verify total seats
        total_seats = Seat.objects.filter(room=study_room, is_active=True).count()
        print(f"\n✅ Complete! Total seats in Study Room: {total_seats}")
        print(f"   Created {seats_created} new seats")
        print(f"   Expected: 50 seats (A1-A50)")
        
        if total_seats < 50:
            print(f"   ⚠️  WARNING: Still missing {50 - total_seats} seats!")
        elif total_seats == 50:
            print(f"   ✅ All 50 seats are present!")
        else:
            print(f"   ⚠️  WARNING: More than 50 seats found ({total_seats})")
        
    except ReadingRoom.DoesNotExist:
        print(f"❌ Error: Study Room with ID 3 not found!")
        print("Available rooms:")
        for room in ReadingRoom.objects.filter(is_active=True):
            print(f"  - {room.name} (ID: {room.id})")
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    add_study_room_seats()


