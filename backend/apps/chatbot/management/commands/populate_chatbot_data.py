"""
Management command to populate chatbot with FAQ data
"""
from django.core.management.base import BaseCommand
from apps.chatbot.models import ChatbotCategory, ChatbotQuestion


class Command(BaseCommand):
    help = 'Populate chatbot with comprehensive FAQ data'

    def handle(self, *args, **options):
        self.stdout.write('Starting to populate chatbot data...')
        
        # Create categories
        categories_data = [
            {
                'name': 'Academic',
                'description': 'Questions about courses, exams, and academic policies',
                'icon': 'school',
                'order': 1
            },
            {
                'name': 'Campus Life',
                'description': 'Information about campus facilities and student life',
                'icon': 'home',
                'order': 2
            },
            {
                'name': 'Admissions',
                'description': 'Admission procedures, requirements, and deadlines',
                'icon': 'assignment',
                'order': 3
            },
            {
                'name': 'Library',
                'description': 'Library services, resources, and policies',
                'icon': 'local_library',
                'order': 4
            },
            {
                'name': 'Hostel',
                'description': 'Hostel facilities, rules, and accommodation',
                'icon': 'hotel',
                'order': 5
            },
            {
                'name': 'Transportation',
                'description': 'Bus routes, parking, and transportation services',
                'icon': 'directions_bus',
                'order': 6
            },
            {
                'name': 'Examinations',
                'description': 'Exam schedules, results, and procedures',
                'icon': 'quiz',
                'order': 7
            },
            {
                'name': 'Financial',
                'description': 'Fees, scholarships, and financial aid',
                'icon': 'account_balance',
                'order': 8
            }
        ]

        # Create categories
        categories = {}
        for cat_data in categories_data:
            category, created = ChatbotCategory.objects.get_or_create(
                name=cat_data['name'],
                defaults=cat_data
            )
            categories[cat_data['name']] = category
            if created:
                self.stdout.write(f'Created category: {category.name}')
            else:
                self.stdout.write(f'Category already exists: {category.name}')

        # General FAQ questions (25+)
        general_faqs = [
            {
                'question': 'What are the college timings?',
                'answer': 'College timings are from 9:00 AM to 4:30 PM, Monday to Friday. The library is open from 8:00 AM to 8:00 PM on weekdays and 9:00 AM to 5:00 PM on weekends.',
                'keywords': ['timings', 'hours', 'time', 'open', 'close', 'schedule']
            },
            {
                'question': 'How can I contact the administration office?',
                'answer': 'You can contact the administration office at +91-80-1234-5678 or email admin@ksit.edu.in. The office is located on the ground floor of the main building and is open from 9:00 AM to 5:00 PM.',
                'keywords': ['contact', 'admin', 'office', 'phone', 'email', 'administration']
            },
            {
                'question': 'What is the dress code for students?',
                'answer': 'Students are required to wear formal attire. Boys should wear shirts with trousers and shoes. Girls should wear salwar kameez, sarees, or formal western wear. Casual wear like jeans and t-shirts are not allowed.',
                'keywords': ['dress', 'code', 'uniform', 'clothes', 'attire', 'formal']
            },
            {
                'question': 'How do I get my student ID card?',
                'answer': 'Student ID cards are issued by the administration office after admission. You need to submit a passport-size photograph and pay the required fee. The card is usually ready within 3-5 working days.',
                'keywords': ['id', 'card', 'student', 'identity', 'photo', 'issue']
            },
            {
                'question': 'What are the library timings?',
                'answer': 'The library is open from 8:00 AM to 8:00 PM on weekdays and 9:00 AM to 5:00 PM on weekends. During exam periods, the library may extend its hours.',
                'keywords': ['library', 'timings', 'hours', 'open', 'books']
            },
            {
                'question': 'How can I access the college Wi-Fi?',
                'answer': 'College Wi-Fi is available throughout the campus. Connect to "KSIT-Student" network using your student ID and password. For technical support, contact the IT department.',
                'keywords': ['wifi', 'internet', 'network', 'connect', 'password', 'student']
            },
            {
                'question': 'What are the canteen timings?',
                'answer': 'The college canteen is open from 8:00 AM to 6:00 PM on weekdays. It serves breakfast, lunch, and snacks. Payment can be made in cash or through the college card.',
                'keywords': ['canteen', 'food', 'lunch', 'breakfast', 'timings', 'eat']
            },
            {
                'question': 'How do I apply for leave?',
                'answer': 'Submit a leave application to your class teacher or HOD at least 2 days in advance. For medical leave, attach a medical certificate. Emergency leaves can be applied for on the same day.',
                'keywords': ['leave', 'absent', 'application', 'medical', 'emergency']
            },
            {
                'question': 'What is the attendance requirement?',
                'answer': 'Students must maintain a minimum of 75% attendance in each subject to be eligible for examinations. Attendance below 75% may result in debarment from exams.',
                'keywords': ['attendance', '75%', 'minimum', 'exam', 'debarment']
            },
            {
                'question': 'How can I get my exam results?',
                'answer': 'Exam results are published on the college website and notice boards. You can also check your results by logging into the student portal using your credentials.',
                'keywords': ['results', 'exam', 'marks', 'grades', 'website', 'portal']
            },
            {
                'question': 'What are the parking facilities?',
                'answer': 'The college provides parking facilities for students and staff. Two-wheeler parking is free, while four-wheeler parking requires a monthly pass. Follow the designated parking areas.',
                'keywords': ['parking', 'vehicle', 'bike', 'car', 'two-wheeler', 'four-wheeler']
            },
            {
                'question': 'How do I get a bonafide certificate?',
                'answer': 'Apply for a bonafide certificate at the administration office. Submit the application form with required documents and pay the prescribed fee. The certificate is usually issued within 2-3 working days.',
                'keywords': ['bonafide', 'certificate', 'proof', 'student', 'administration']
            },
            {
                'question': 'What are the sports facilities available?',
                'answer': 'The college has a sports complex with facilities for cricket, football, basketball, volleyball, badminton, and table tennis. There is also a gymnasium and outdoor courts.',
                'keywords': ['sports', 'gym', 'cricket', 'football', 'basketball', 'facilities']
            },
            {
                'question': 'How can I join clubs and societies?',
                'answer': 'Various clubs and societies are available for students. You can join during the club fair held at the beginning of each academic year or contact the respective club coordinators.',
                'keywords': ['clubs', 'societies', 'join', 'activities', 'extracurricular']
            },
            {
                'question': 'What is the procedure for revaluation of answer scripts?',
                'answer': 'Apply for revaluation within 15 days of result declaration. Submit the application form with the prescribed fee to the examination cell. The revaluation results will be published within 30 days.',
                'keywords': ['revaluation', 'answer', 'script', 'marks', 'examination', 'apply']
            },
            {
                'question': 'How do I get a duplicate mark sheet?',
                'answer': 'Apply for a duplicate mark sheet at the examination cell. Submit the application form with an affidavit and pay the prescribed fee. The duplicate will be issued within 15-20 working days.',
                'keywords': ['duplicate', 'marksheet', 'certificate', 'lost', 'examination']
            },
            {
                'question': 'What are the computer lab timings?',
                'answer': 'Computer labs are open from 9:00 AM to 5:00 PM on weekdays. Students can use the labs for academic purposes. Internet access is available for research and project work.',
                'keywords': ['computer', 'lab', 'timings', 'internet', 'project', 'research']
            },
            {
                'question': 'How can I get a character certificate?',
                'answer': 'Apply for a character certificate at the administration office. Submit the application form with required documents. The certificate is issued by the principal and usually takes 3-5 working days.',
                'keywords': ['character', 'certificate', 'good', 'conduct', 'principal']
            },
            {
                'question': 'What are the hostel rules and regulations?',
                'answer': 'Hostel residents must follow the prescribed timings, maintain discipline, and keep the premises clean. Visitors are allowed only during specified hours. Smoking and alcohol are strictly prohibited.',
                'keywords': ['hostel', 'rules', 'regulations', 'timings', 'discipline', 'visitors']
            },
            {
                'question': 'How do I apply for a scholarship?',
                'answer': 'Scholarship applications are available at the financial aid office. Submit the completed form with required documents before the deadline. Various merit and need-based scholarships are available.',
                'keywords': ['scholarship', 'financial', 'aid', 'merit', 'need-based', 'apply']
            },
            {
                'question': 'What are the medical facilities available?',
                'answer': 'The college has a medical room with a qualified nurse. A doctor visits twice a week. Emergency medical services are available. Students can also access nearby hospitals for serious medical issues.',
                'keywords': ['medical', 'doctor', 'nurse', 'health', 'emergency', 'hospital']
            },
            {
                'question': 'How can I get a transcript?',
                'answer': 'Apply for a transcript at the examination cell. Submit the application form with required documents and pay the prescribed fee. The transcript is usually ready within 10-15 working days.',
                'keywords': ['transcript', 'academic', 'record', 'examination', 'apply']
            },
            {
                'question': 'What are the placement opportunities?',
                'answer': 'The college has a dedicated placement cell that organizes campus recruitment drives. Various companies visit for placements. Students are provided with training and guidance for interviews.',
                'keywords': ['placement', 'job', 'recruitment', 'companies', 'career', 'training']
            },
            {
                'question': 'How do I report a grievance?',
                'answer': 'Submit your grievance in writing to the grievance cell or use the online complaint system. All grievances are treated confidentially and addressed within 15 working days.',
                'keywords': ['grievance', 'complaint', 'report', 'issue', 'problem', 'help']
            },
            {
                'question': 'What are the research opportunities for students?',
                'answer': 'Students can participate in research projects under faculty guidance. The college encourages research through various programs and provides necessary resources and funding.',
                'keywords': ['research', 'project', 'faculty', 'opportunities', 'funding', 'academic']
            }
        ]

        # Create general FAQ category if it doesn't exist
        general_category, created = ChatbotCategory.objects.get_or_create(
            name='General FAQ',
            defaults={
                'description': 'General frequently asked questions about college',
                'icon': 'help',
                'order': 0
            }
        )

        # Add general FAQ questions
        for faq_data in general_faqs:
            question, created = ChatbotQuestion.objects.get_or_create(
                category=general_category,
                question=faq_data['question'],
                defaults={
                    'answer': faq_data['answer'],
                    'keywords': faq_data['keywords'],
                    'priority': 10,
                    'is_active': True
                }
            )
            if created:
                self.stdout.write(f'Created general FAQ: {question.question[:50]}...')

        self.stdout.write(self.style.SUCCESS('Successfully populated general FAQ data!'))

