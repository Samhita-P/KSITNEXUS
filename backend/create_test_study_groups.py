#!/usr/bin/env python
import os
import sys
import django

# Add the project directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ksit_nexus.settings')
django.setup()

from apps.study_groups.models import StudyGroup
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()

def create_test_study_groups():
    """Create test study groups for testing"""
    
    # Get or create a test user
    user, created = User.objects.get_or_create(
        username='testuser',
        defaults={
            'email': 'test@example.com',
            'first_name': 'Test',
            'last_name': 'User',
        }
    )
    
    if created:
        user.set_password('testpass123')
        user.save()
        print(f"Created test user: {user.username}")
    else:
        print(f"Using existing test user: {user.username}")
    
    # Create test study groups
    test_groups = [
        {
            'name': 'Mathematics Study Group',
            'description': 'A group for studying advanced mathematics topics',
            'subject': 'mathematics',
            'difficulty_level': 'intermediate',
            'max_members': 15,
            'is_public': True,
            'is_active': True,
            'status': 'active',
            'creator': user,
        },
        {
            'name': 'Physics Discussion Group',
            'description': 'Weekly physics problem solving sessions',
            'subject': 'physics',
            'difficulty_level': 'advanced',
            'max_members': 10,
            'is_public': True,
            'is_active': True,
            'status': 'active',
            'creator': user,
        },
        {
            'name': 'Computer Science Projects',
            'description': 'Collaborative coding and project development',
            'subject': 'computer_science',
            'difficulty_level': 'beginner',
            'max_members': 20,
            'is_public': True,
            'is_active': True,
            'status': 'reported',
            'is_reported': True,
            'creator': user,
        },
        {
            'name': 'Chemistry Lab Group',
            'description': 'Study group for chemistry laboratory work',
            'subject': 'chemistry',
            'difficulty_level': 'intermediate',
            'max_members': 12,
            'is_public': False,
            'is_active': False,
            'status': 'closed',
            'creator': user,
        },
    ]
    
    created_count = 0
    for group_data in test_groups:
        group, created = StudyGroup.objects.get_or_create(
            name=group_data['name'],
            defaults=group_data
        )
        if created:
            created_count += 1
            print(f"Created study group: {group.name}")
        else:
            print(f"Study group already exists: {group.name}")
    
    print(f"\nTotal study groups created: {created_count}")
    print(f"Total study groups in database: {StudyGroup.objects.count()}")
    
    # Print all groups with their status
    print("\nAll study groups:")
    for group in StudyGroup.objects.all():
        print(f"- {group.name} (Status: {group.status}, Public: {group.is_public}, Active: {group.is_active})")

if __name__ == '__main__':
    create_test_study_groups()

