"""
Django management command to create test notifications
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from apps.notifications.models import Notification
from django.utils import timezone

User = get_user_model()


class Command(BaseCommand):
    help = 'Create test notifications for debugging'

    def add_arguments(self, parser):
        parser.add_argument(
            '--user',
            type=str,
            help='Email of the user to create notifications for',
        )
        parser.add_argument(
            '--all-users',
            action='store_true',
            help='Create notifications for all users',
        )

    def handle(self, *args, **options):
        user_email = options.get('user')
        all_users = options.get('all_users', False)
        
        # Get users to create notifications for
        if all_users:
            users = User.objects.all()
            self.stdout.write(f"Creating test notifications for ALL users ({users.count()} users)")
        elif user_email:
            users = User.objects.filter(email=user_email)
            if not users.exists():
                self.stdout.write(self.style.ERROR(f"User with email {user_email} not found."))
                return
            self.stdout.write(f"Creating test notifications for user: {user_email}")
        else:
            # Get all users
            users = User.objects.all()
            if users.count() > 5:  # Limit if too many users
                self.stdout.write(f"Creating test notifications for first 5 users")
                users = users[:5]
            else:
                self.stdout.write(f"Creating test notifications for all {users.count()} users")
        
        if not users.exists():
            self.stdout.write(self.style.ERROR("No users found."))
            return
        
        # Create various test notifications
        notifications_data = [
            {
                'notification_type': 'study_group',
                'title': 'New Study Group Created',
                'message': 'A new study group "Advanced Mathematics Study Group" has been created. Check it out!',
                'priority': 'medium',
                'is_read': False,
            },
            {
                'notification_type': 'complaint',
                'title': 'Complaint Update',
                'message': 'Your complaint "Library Issue" has been resolved.',
                'priority': 'high',
                'is_read': False,
            },
            {
                'notification_type': 'reservation',
                'title': 'Reservation Confirmed',
                'message': 'Your library seat reservation is confirmed for tomorrow at 10:00 AM.',
                'priority': 'medium',
                'is_read': False,
            },
            {
                'notification_type': 'notice',
                'title': 'New Notice',
                'message': 'Important: Mid-term exam schedule has been announced. Please check your dashboard.',
                'priority': 'high',
                'is_read': False,
            },
            {
                'notification_type': 'general',
                'title': 'System Update',
                'message': 'The KSIT Nexus app has been updated with new features. Please update your app.',
                'priority': 'low',
                'is_read': False,
            },
        ]
        
        total_created = 0
        
        for user in users:
            self.stdout.write(f"\nCreating notifications for {user.email}...")
            
            # Create notifications for this user
            for notif_data in notifications_data:
                notification = Notification.objects.create(user=user, **notif_data)
                total_created += 1
                self.stdout.write(self.style.SUCCESS(f"  ✓ {notification.title}"))
            
            # Also create some read notifications
            read_notifications_data = [
                {
                    'notification_type': 'study_group',
                    'title': 'Member Joined',
                    'message': 'John Doe joined "Advanced Mathematics Study Group"',
                    'priority': 'low',
                    'is_read': True,
                    'read_at': timezone.now(),
                },
            ]
            
            for notif_data in read_notifications_data:
                notification = Notification.objects.create(user=user, **notif_data)
                total_created += 1
                self.stdout.write(self.style.SUCCESS(f"  ✓ {notification.title} (read)"))
        
        self.stdout.write(self.style.SUCCESS(f"\n\nTotal notifications created: {total_created}"))
        self.stdout.write(self.style.SUCCESS("Test notifications created successfully!"))

