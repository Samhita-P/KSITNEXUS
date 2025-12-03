#!/usr/bin/env python
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ksit_nexus.settings')
django.setup()

from apps.accounts.models import User
from apps.notices.models import Notice
from django.utils import timezone

# Get or create a faculty user
user, created = User.objects.get_or_create(
    email='test@faculty.com',
    defaults={
        'username': 'testfaculty',
        'first_name': 'Test',
        'last_name': 'Faculty',
        'user_type': 'faculty',
        'is_active': True,
    }
)

if created:
    user.set_password('testpass123')
    user.save()
    print(f"Created faculty user: {user.email}")
else:
    print(f"Using existing faculty user: {user.email}")

# Create a test notice
notice = Notice.objects.create(
    title='Test Notice - Welcome to KSIT Nexus',
    content='This is a test notice to verify that the notice system is working properly. All students and faculty should be able to see this notice.',
    summary='Test notice for system verification',
    priority='medium',
    status='published',
    visibility='all',
    author=user,
    publish_at=timezone.now(),
    published_at=timezone.now(),
)

print(f"Created notice: {notice.title}")
print(f"Notice ID: {notice.id}")
print(f"Status: {notice.status}")
print(f"Visibility: {notice.visibility}")
print(f"Published at: {notice.published_at}")

# Check total notices
total_notices = Notice.objects.count()
published_notices = Notice.objects.filter(status='published').count()
print(f"\nTotal notices in database: {total_notices}")
print(f"Published notices: {published_notices}")

