"""
Management command to seed faculty data
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from apps.accounts.models import Faculty

User = get_user_model()


class Command(BaseCommand):
    help = 'Seed faculty data for testing'

    def handle(self, *args, **options):
        faculty_data = [
            {
                'first_name': 'Krishna',
                'last_name': 'Gudi',
                'username': 'krishna.gudi',
                'email': 'krishna.gudi@ksit.edu.in',
                'employee_id': 'EMP001',
                'designation': 'Professor',
                'department': 'Computer Science',
                'subjects_taught': ['Data Structures', 'Algorithms', 'Database Systems'],
                'research_areas': ['Machine Learning', 'Data Mining'],
            },
            {
                'first_name': 'Prashanth',
                'last_name': 'HS',
                'username': 'prashanth.hs',
                'email': 'prashanth.hs@ksit.edu.in',
                'employee_id': 'EMP002',
                'designation': 'Associate Professor',
                'department': 'Computer Science',
                'subjects_taught': ['Software Engineering', 'Web Technologies'],
                'research_areas': ['Software Architecture', 'Web Development'],
            },
            {
                'first_name': 'Roopesh',
                'last_name': 'Kumar',
                'username': 'roopesh.kumar',
                'email': 'roopesh.kumar@ksit.edu.in',
                'employee_id': 'EMP003',
                'designation': 'Assistant Professor',
                'department': 'Computer Science',
                'subjects_taught': ['Operating Systems', 'Computer Networks'],
                'research_areas': ['Network Security', 'Distributed Systems'],
            },
            {
                'first_name': 'Raghavendra',
                'last_name': 'Kumar',
                'username': 'raghavendra.kumar',
                'email': 'raghavendra.kumar@ksit.edu.in',
                'employee_id': 'EMP004',
                'designation': 'Professor',
                'department': 'Information Science',
                'subjects_taught': ['Database Management', 'Data Analytics'],
                'research_areas': ['Big Data', 'Business Intelligence'],
            },
            {
                'first_name': 'Kumar',
                'last_name': 'Raj',
                'username': 'kumar.raj',
                'email': 'kumar.raj@ksit.edu.in',
                'employee_id': 'EMP005',
                'designation': 'Assistant Professor',
                'department': 'Computer Science',
                'subjects_taught': ['Programming Languages', 'Compiler Design'],
                'research_areas': ['Programming Language Theory', 'Compiler Optimization'],
            },
            {
                'first_name': 'Ramya',
                'last_name': 'Sharma',
                'username': 'ramya.sharma',
                'email': 'ramya.sharma@ksit.edu.in',
                'employee_id': 'EMP006',
                'designation': 'Associate Professor',
                'department': 'Information Science',
                'subjects_taught': ['Human Computer Interaction', 'User Experience Design'],
                'research_areas': ['UX Research', 'Accessibility'],
            },
            {
                'first_name': 'Namya',
                'last_name': 'Patel',
                'username': 'namya.patel',
                'email': 'namya.patel@ksit.edu.in',
                'employee_id': 'EMP007',
                'designation': 'Assistant Professor',
                'department': 'Computer Science',
                'subjects_taught': ['Artificial Intelligence', 'Machine Learning'],
                'research_areas': ['Deep Learning', 'Computer Vision'],
            },
            {
                'first_name': 'Shruthi',
                'last_name': 'Reddy',
                'username': 'shruthi.reddy',
                'email': 'shruthi.reddy@ksit.edu.in',
                'employee_id': 'EMP008',
                'designation': 'Assistant Professor',
                'department': 'Information Science',
                'subjects_taught': ['Information Security', 'Cryptography'],
                'research_areas': ['Cybersecurity', 'Cryptographic Protocols'],
            },
            {
                'first_name': 'Vikram',
                'last_name': 'Singh',
                'username': 'vikram.singh',
                'email': 'vikram.singh@ksit.edu.in',
                'employee_id': 'EMP009',
                'designation': 'Professor',
                'department': 'Computer Science',
                'subjects_taught': ['Computer Graphics', 'Game Development'],
                'research_areas': ['Computer Graphics', 'Virtual Reality'],
            },
            {
                'first_name': 'Priya',
                'last_name': 'Nair',
                'username': 'priya.nair',
                'email': 'priya.nair@ksit.edu.in',
                'employee_id': 'EMP010',
                'designation': 'Associate Professor',
                'department': 'Information Science',
                'subjects_taught': ['Data Science', 'Statistics'],
                'research_areas': ['Statistical Learning', 'Data Visualization'],
            },
        ]

        created_count = 0
        for faculty_info in faculty_data:
            # Create or get user
            user, created = User.objects.get_or_create(
                username=faculty_info['username'],
                defaults={
                    'first_name': faculty_info['first_name'],
                    'last_name': faculty_info['last_name'],
                    'email': faculty_info['email'],
                    'user_type': 'faculty',
                    'is_active': True,
                }
            )
            
            if created:
                # Set a default password for faculty
                user.set_password('faculty123')
                user.save()
                
                # Create faculty profile
                Faculty.objects.create(
                    user=user,
                    employee_id=faculty_info['employee_id'],
                    designation=faculty_info['designation'],
                    department=faculty_info['department'],
                    subjects_taught=faculty_info['subjects_taught'],
                    research_areas=faculty_info['research_areas'],
                    is_active=True,
                )
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'Created faculty: {faculty_info["first_name"]} {faculty_info["last_name"]}')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'Faculty already exists: {faculty_info["first_name"]} {faculty_info["last_name"]}')
                )

        self.stdout.write(
            self.style.SUCCESS(f'Successfully created {created_count} faculty members')
        )

