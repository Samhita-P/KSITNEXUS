#!/usr/bin/env python3
import os
import sys
import django

# Add the backend directory to the Python path
sys.path.append('backend')

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ksit_nexus.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

# Create a test user
try:
    user = User.objects.create_user(
        username='test',
        email='test@example.com',
        password='test123',
        first_name='Test',
        last_name='User'
    )
    print(f"User created successfully: {user.username}")
    print(f"User is active: {user.is_active}")
    print(f"Password check: {user.check_password('test123')}")
except Exception as e:
    print(f"Error creating user: {e}")
    # Check if user already exists
    try:
        user = User.objects.get(username='test')
        print(f"User already exists: {user.username}")
        print(f"User is active: {user.is_active}")
        print(f"Password check: {user.check_password('test123')}")
    except User.DoesNotExist:
        print("User does not exist")






