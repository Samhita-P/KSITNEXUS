#!/usr/bin/env python3
"""
KSIT Nexus - Test Users Seeder
Creates superuser, 5 students, and 5 faculty members
"""
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ksit_nexus.settings')
django.setup()

from django.contrib.auth import get_user_model
from apps.accounts.models import User
from django.db import IntegrityError

PASSWORD = 'Sam@123'

students = [
    ('samhita', 'Samhita P'),
    ('umesh', 'Umesh Bhatta'),
    ('vignesh', 'Vignesh S'),
    ('shreya', 'Shreya Murthy'),
    ('sangeetha', 'Sangeetha S'),
]

faculty = [
    ('prashanth', 'Prashanth HS'),
    ('krishna', 'Krishna Gudi'),
    ('roopesh', 'Roopesh Kumar'),
    ('kumar', 'Kumar K'),
    ('raghavendra', 'Raghavendrachar S'),
]

# Superuser
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser(
        username='admin',
        email='admin@example.com',
        password='Admin@123'
    )
    print('✔ Superuser created')
else:
    print('✔ Superuser already exists')

# Create students
for uname, fullname in students:
    if not User.objects.filter(username=uname).exists():
        name_parts = fullname.split(' ', 1)
        first = name_parts[0]
        last = name_parts[1] if len(name_parts) > 1 else ''
        User.objects.create_user(
            username=uname,
            password=PASSWORD,
            first_name=first,
            last_name=last,
            user_type='student'
        )
        print('✔ Student created:', uname)
    else:
        print('✔ Student already exists:', uname)

# Create faculty
for uname, fullname in faculty:
    if not User.objects.filter(username=uname).exists():
        name_parts = fullname.split(' ', 1)
        first = name_parts[0]
        last = name_parts[1] if len(name_parts) > 1 else ''
        User.objects.create_user(
            username=uname,
            password=PASSWORD,
            first_name=first,
            last_name=last,
            user_type='faculty'
        )
        print('✔ Faculty created:', uname)
    else:
        print('✔ Faculty already exists:', uname)

print('🎉 USER CREATION COMPLETE!')

