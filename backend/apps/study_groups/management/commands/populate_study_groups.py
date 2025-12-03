"""
Management command to populate study groups with sample data
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from apps.study_groups.models import StudyGroup, GroupMembership
from apps.accounts.models import User

User = get_user_model()


class Command(BaseCommand):
    help = 'Populate study groups with sample data'

    def handle(self, *args, **options):
        # Create a default user if none exists
        user, created = User.objects.get_or_create(
            email='admin@ksit.com',
            defaults={
                'first_name': 'Admin',
                'last_name': 'User',
                'is_active': True,
                'is_staff': True,
            }
        )
        if created:
            user.set_password('admin123')
            user.save()
            self.stdout.write(self.style.SUCCESS('Created admin user'))

        # Sample study groups
        study_groups_data = [
            {
                'name': 'Computer Science Study Group',
                'description': 'A group for CS students to collaborate on assignments and projects. We meet every Tuesday and Thursday at 3 PM in the library.',
                'subject': 'Computer Science',
                'tags': ['programming', 'algorithms', 'data-structures'],
                'is_public': True,
                'max_members': 20,
                'meeting_schedule': 'Tuesday, Thursday at 3:00 PM',
                'location': 'Library Study Room 1',
            },
            {
                'name': 'Mathematics Study Circle',
                'description': 'Advanced mathematics study group focusing on calculus, linear algebra, and statistics. Perfect for engineering students.',
                'subject': 'Mathematics',
                'tags': ['calculus', 'linear-algebra', 'statistics'],
                'is_public': True,
                'max_members': 15,
                'meeting_schedule': 'Monday, Wednesday at 2:00 PM',
                'location': 'Math Department Room 205',
            },
            {
                'name': 'Physics Lab Partners',
                'description': 'Physics laboratory study group for practical experiments and theory discussions. All physics students welcome!',
                'subject': 'Physics',
                'tags': ['laboratory', 'experiments', 'mechanics'],
                'is_public': True,
                'max_members': 12,
                'meeting_schedule': 'Friday at 4:00 PM',
                'location': 'Physics Lab 3',
            },
            {
                'name': 'Data Science Enthusiasts',
                'description': 'Exploring data science, machine learning, and AI. We work on real-world projects and share resources.',
                'subject': 'Data Science',
                'tags': ['machine-learning', 'python', 'data-analysis'],
                'is_public': True,
                'max_members': 25,
                'meeting_schedule': 'Saturday at 10:00 AM',
                'location': 'Computer Lab 2',
            },
            {
                'name': 'Exam Preparation Group',
                'description': 'Intensive exam preparation for all subjects. We share study materials, practice tests, and study strategies.',
                'subject': 'General',
                'tags': ['exams', 'study-tips', 'preparation'],
                'is_public': True,
                'max_members': 30,
                'meeting_schedule': 'Daily at 6:00 PM',
                'location': 'Main Library',
            },
            {
                'name': 'Web Development Club',
                'description': 'Learn web development technologies including HTML, CSS, JavaScript, React, and Node.js. Build projects together!',
                'subject': 'Web Development',
                'tags': ['html', 'css', 'javascript', 'react'],
                'is_public': True,
                'max_members': 18,
                'meeting_schedule': 'Sunday at 2:00 PM',
                'location': 'IT Lab 1',
            },
        ]

        created_count = 0
        for group_data in study_groups_data:
            group, created = StudyGroup.objects.get_or_create(
                name=group_data['name'],
                defaults={
                    'description': group_data['description'],
                    'subject': group_data['subject'],
                    'tags': group_data['tags'],
                    'is_public': group_data['is_public'],
                    'max_members': group_data['max_members'],
                    'meeting_schedule': group_data['meeting_schedule'],
                    'location': group_data['location'],
                    'creator': user,
                }
            )
            if created:
                created_count += 1
                self.stdout.write(f'Created study group: {group.name}')

        self.stdout.write(
            self.style.SUCCESS(f'Successfully created {created_count} study groups')
        )
