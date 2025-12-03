"""
Script to create test notifications for debugging
"""
import os
import sys
import django

# Setup Django
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ksit_nexus.settings')
django.setup()

from apps.notifications.models import Notification
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()

def create_test_notifications():
    """Create test notifications for all users"""
    
    # Get first user
    user = User.objects.first()
    if not user:
        print("No users found. Please create a user first.")
        return
    
    print(f"Creating test notifications for user: {user.email}")
    
    # Create various test notifications
    notifications = [
        {
            'user': user,
            'notification_type': 'study_group',
            'title': 'New Study Group Created',
            'message': 'A new study group "Advanced Mathematics Study Group" has been created. Check it out!',
            'priority': 'medium',
            'is_read': False,
        },
        {
            'user': user,
            'notification_type': 'complaint',
            'title': 'Complaint Update',
            'message': 'Your complaint "Library Issue" has been resolved.',
            'priority': 'high',
            'is_read': False,
        },
        {
            'user': user,
            'notification_type': 'reservation',
            'title': 'Reservation Confirmed',
            'message': 'Your library seat reservation is confirmed for tomorrow at 10:00 AM.',
            'priority': 'medium',
            'is_read': False,
        },
        {
            'user': user,
            'notification_type': 'notice',
            'title': 'New Notice',
            'message': 'Important: Mid-term exam schedule has been announced. Please check your dashboard.',
            'priority': 'high',
            'is_read': False,
        },
        {
            'user': user,
            'notification_type': 'general',
            'title': 'System Update',
            'message': 'The KSIT Nexus app has been updated with new features. Please update your app.',
            'priority': 'low',
            'is_read': False,
        },
    ]
    
    created = []
    for notif_data in notifications:
        notification = Notification.objects.create(**notif_data)
        created.append(notification)
        print(f"Created notification: {notification.title}")
    
    print(f"\nTotal notifications created: {len(created)}")
    
    # Also create some read notifications
    read_notifications = [
        {
            'user': user,
            'notification_type': 'study_group',
            'title': 'Member Joined',
            'message': 'John Doe joined "Advanced Mathematics Study Group"',
            'priority': 'low',
            'is_read': True,
            'read_at': timezone.now(),
        },
        {
            'user': user,
            'notification_type': 'complaint',
            'title': 'Complaint Submitted',
            'message': 'Your complaint "Bus facility needed" has been submitted successfully.',
            'priority': 'medium',
            'is_read': True,
            'read_at': timezone.now(),
        },
    ]
    
    for notif_data in read_notifications:
        notification = Notification.objects.create(**notif_data)
        created.append(notification)
        print(f"Created read notification: {notification.title}")
    
    print(f"\nTotal notifications created: {len(created)}")
    print("\nTest notifications created successfully!")

if __name__ == '__main__':
    create_test_notifications()






