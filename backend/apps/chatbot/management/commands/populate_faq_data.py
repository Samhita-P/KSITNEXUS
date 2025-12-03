"""
Management command to populate sample FAQ data
"""
from django.core.management.base import BaseCommand
from apps.chatbot.models import ChatbotCategory, ChatbotQuestion


class Command(BaseCommand):
    help = 'Populate sample FAQ data for testing'

    def handle(self, *args, **options):
        self.stdout.write('Creating sample FAQ data...')
        
        # Create categories
        categories_data = [
            {
                'name': 'Library',
                'description': 'Questions about library services, booking, and facilities',
                'icon': 'library',
                'is_active': True,
                'order': 1
            },
            {
                'name': 'Reservations',
                'description': 'Questions about room and seat reservations',
                'icon': 'reservation',
                'is_active': True,
                'order': 2
            },
            {
                'name': 'Academic',
                'description': 'Questions about academics, exams, and courses',
                'icon': 'academic',
                'is_active': True,
                'order': 3
            },
            {
                'name': 'Campus Life',
                'description': 'Questions about campus facilities and student life',
                'icon': 'campus',
                'is_active': True,
                'order': 4
            },
            {
                'name': 'General',
                'description': 'General questions and support',
                'icon': 'general',
                'is_active': True,
                'order': 5
            }
        ]
        
        categories = {}
        for cat_data in categories_data:
            category, created = ChatbotCategory.objects.get_or_create(
                name=cat_data['name'],
                defaults=cat_data
            )
            categories[cat_data['name']] = category
            if created:
                self.stdout.write(f'Created category: {category.name}')
        
        # Create questions
        questions_data = [
            # Library questions
            {
                'category': 'Library',
                'question': 'How do I book a seat in the library?',
                'answer': 'To book a seat in the library, go to the Reservations section in the app, select "Library" from the room types, choose your preferred time slot, and confirm your booking. You can book up to 4 hours in advance.',
                'keywords': ['book', 'seat', 'library', 'reservation', 'study'],
                'priority': 10,
                'usage_count': 25
            },
            {
                'category': 'Library',
                'question': 'What are the library hours?',
                'answer': 'The library is open from 8:00 AM to 10:00 PM on weekdays and 9:00 AM to 6:00 PM on weekends. During exam periods, extended hours may apply.',
                'keywords': ['hours', 'library', 'time', 'open', 'closed'],
                'priority': 9,
                'usage_count': 18
            },
            {
                'category': 'Library',
                'question': 'Can I bring food and drinks to the library?',
                'answer': 'Only water bottles are allowed in the library. Food and other drinks are not permitted to maintain a clean study environment.',
                'keywords': ['food', 'drinks', 'water', 'library', 'rules'],
                'priority': 7,
                'usage_count': 12
            },
            
            # Reservation questions
            {
                'category': 'Reservations',
                'question': 'How far in advance can I book a room?',
                'answer': 'You can book rooms up to 7 days in advance. Same-day bookings are also available if slots are open.',
                'keywords': ['book', 'room', 'advance', 'days', 'reservation'],
                'priority': 10,
                'usage_count': 22
            },
            {
                'category': 'Reservations',
                'question': 'Can I cancel my reservation?',
                'answer': 'Yes, you can cancel your reservation up to 2 hours before the scheduled time. Go to the Reservations section and click on your booking to cancel it.',
                'keywords': ['cancel', 'reservation', 'booking', 'time'],
                'priority': 8,
                'usage_count': 15
            },
            {
                'category': 'Reservations',
                'question': 'What happens if I miss my reservation?',
                'answer': 'If you miss your reservation without canceling, it will be marked as a no-show. Multiple no-shows may result in temporary booking restrictions.',
                'keywords': ['miss', 'reservation', 'no-show', 'penalty'],
                'priority': 6,
                'usage_count': 8
            },
            
            # Academic questions
            {
                'category': 'Academic',
                'question': 'When are the exam dates announced?',
                'answer': 'Exam dates are typically announced 2-3 weeks before the exam period. Check the Notices section for the latest exam schedule updates.',
                'keywords': ['exam', 'dates', 'schedule', 'announced', 'academic'],
                'priority': 9,
                'usage_count': 20
            },
            {
                'category': 'Academic',
                'question': 'How do I access my grades?',
                'answer': 'You can view your grades in the Academic section of the app. Grades are usually posted within 2 weeks after exam completion.',
                'keywords': ['grades', 'marks', 'results', 'academic', 'access'],
                'priority': 8,
                'usage_count': 16
            },
            {
                'category': 'Academic',
                'question': 'What is the attendance policy?',
                'answer': 'Students must maintain a minimum of 75% attendance in each subject. Attendance below 75% may result in being barred from exams.',
                'keywords': ['attendance', 'policy', 'percentage', 'minimum', 'exams'],
                'priority': 7,
                'usage_count': 14
            },
            
            # Campus Life questions
            {
                'category': 'Campus Life',
                'question': 'Where is the cafeteria located?',
                'answer': 'The main cafeteria is located on the ground floor of the main building. There are also smaller food courts on the 2nd and 3rd floors.',
                'keywords': ['cafeteria', 'food', 'location', 'campus', 'building'],
                'priority': 8,
                'usage_count': 19
            },
            {
                'category': 'Campus Life',
                'question': 'How do I join a study group?',
                'answer': 'Go to the Study Groups section in the app, browse available groups, and click "Join Group" on any group you\'re interested in. You can also create your own group.',
                'keywords': ['study', 'group', 'join', 'create', 'academic'],
                'priority': 9,
                'usage_count': 17
            },
            {
                'category': 'Campus Life',
                'question': 'What sports facilities are available?',
                'answer': 'The campus has a gym, basketball court, football field, and badminton courts. All facilities are available for student use during designated hours.',
                'keywords': ['sports', 'gym', 'facilities', 'campus', 'exercise'],
                'priority': 6,
                'usage_count': 11
            },
            
            # General questions
            {
                'category': 'General',
                'question': 'How do I contact support?',
                'answer': 'You can contact support through the app\'s help section, email support@ksit.edu, or visit the admin office during office hours (9 AM - 5 PM).',
                'keywords': ['support', 'contact', 'help', 'email', 'office'],
                'priority': 10,
                'usage_count': 30
            },
            {
                'category': 'General',
                'question': 'How do I reset my password?',
                'answer': 'Go to the login screen, click "Forgot Password", enter your email, and follow the instructions sent to your email to reset your password.',
                'keywords': ['password', 'reset', 'forgot', 'login', 'email'],
                'priority': 9,
                'usage_count': 24
            },
            {
                'category': 'General',
                'question': 'What are the app\'s main features?',
                'answer': 'The app includes library seat booking, room reservations, study groups, notices, complaints, feedback, and an AI assistant for help with campus-related questions.',
                'keywords': ['features', 'app', 'booking', 'reservations', 'study'],
                'priority': 8,
                'usage_count': 13
            }
        ]
        
        for q_data in questions_data:
            category = categories[q_data['category']]
            question, created = ChatbotQuestion.objects.get_or_create(
                question=q_data['question'],
                defaults={
                    'category': category,
                    'answer': q_data['answer'],
                    'keywords': q_data['keywords'],
                    'tags': [],
                    'is_active': True,
                    'priority': q_data['priority'],
                    'usage_count': q_data['usage_count']
                }
            )
            if created:
                self.stdout.write(f'Created question: {question.question[:50]}...')
        
        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully created {len(categories)} categories and {len(questions_data)} questions!'
            )
        )
