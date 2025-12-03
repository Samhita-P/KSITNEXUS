"""
Management command to populate chatbot with category-specific questions
"""
from django.core.management.base import BaseCommand
from apps.chatbot.models import ChatbotCategory, ChatbotQuestion


class Command(BaseCommand):
    help = 'Populate chatbot with category-specific questions'

    def handle(self, *args, **options):
        self.stdout.write('Starting to populate category-specific questions...')

        # Academic questions (10+)
        academic_questions = [
            {
                'question': 'What is the course curriculum structure?',
                'answer': 'The curriculum follows a semester-based system with 8 semesters for undergraduate programs. Each semester includes core subjects, electives, and practical components. The curriculum is regularly updated to meet industry standards.',
                'keywords': ['curriculum', 'course', 'structure', 'semester', 'subjects', 'electives']
            },
            {
                'question': 'How are internal assessments conducted?',
                'answer': 'Internal assessments include unit tests, assignments, projects, and presentations. The weightage is typically 40% for internal assessments and 60% for semester-end examinations.',
                'keywords': ['internal', 'assessment', 'unit', 'test', 'assignment', 'project', 'weightage']
            },
            {
                'question': 'What are the credit requirements for graduation?',
                'answer': 'Students need to complete a minimum of 160 credits for undergraduate programs. This includes core subjects, electives, laboratory work, and project credits as per the curriculum.',
                'keywords': ['credits', 'graduation', 'minimum', 'core', 'electives', 'laboratory']
            },
            {
                'question': 'How do I choose elective subjects?',
                'answer': 'Elective subjects are chosen during the registration period. Students can select from available electives based on their interests and career goals. Consult with faculty advisors for guidance.',
                'keywords': ['elective', 'choose', 'select', 'registration', 'interests', 'career']
            },
            {
                'question': 'What is the grading system?',
                'answer': 'The college follows a 10-point grading system. Grades range from O (Outstanding) to F (Fail). The minimum passing grade is D (4.0 points). CGPA is calculated based on credit-weighted grades.',
                'keywords': ['grading', 'system', 'points', 'grade', 'CGPA', 'passing']
            },
            {
                'question': 'How do I apply for course withdrawal?',
                'answer': 'Submit a course withdrawal application to the academic office within the specified deadline. A fee may be applicable. Withdrawal after the deadline may result in an F grade.',
                'keywords': ['withdrawal', 'course', 'drop', 'application', 'deadline', 'grade']
            },
            {
                'question': 'What are the prerequisites for advanced courses?',
                'answer': 'Advanced courses have specific prerequisites listed in the course catalog. Students must complete prerequisite courses with minimum grades before enrolling in advanced courses.',
                'keywords': ['prerequisites', 'advanced', 'courses', 'requirements', 'enrollment']
            },
            {
                'question': 'How do I get academic counseling?',
                'answer': 'Academic counseling is available through faculty advisors and the academic counseling cell. Students can schedule appointments for guidance on course selection, career planning, and academic issues.',
                'keywords': ['counseling', 'academic', 'advisor', 'guidance', 'career', 'planning']
            },
            {
                'question': 'What is the project submission process?',
                'answer': 'Projects must be submitted according to the prescribed format and deadline. Include all required documentation, code, and reports. Late submissions may incur penalties.',
                'keywords': ['project', 'submission', 'format', 'deadline', 'documentation', 'penalty']
            },
            {
                'question': 'How are laboratory sessions conducted?',
                'answer': 'Laboratory sessions are conducted in batches with proper safety protocols. Students must attend all lab sessions and complete experiments as per the schedule. Lab reports are evaluated for grades.',
                'keywords': ['laboratory', 'lab', 'sessions', 'safety', 'experiments', 'reports']
            }
        ]

        # Campus Life questions (10+)
        campus_life_questions = [
            {
                'question': 'What recreational facilities are available?',
                'answer': 'The campus has a sports complex, gymnasium, music room, art studio, and common areas for relaxation. Various recreational activities and events are organized throughout the year.',
                'keywords': ['recreational', 'facilities', 'sports', 'gym', 'music', 'art', 'activities']
            },
            {
                'question': 'How do I participate in cultural events?',
                'answer': 'Cultural events are organized by various clubs and societies. Students can participate by joining relevant clubs or volunteering for event committees. Information is available on notice boards and college website.',
                'keywords': ['cultural', 'events', 'participate', 'clubs', 'societies', 'volunteer']
            },
            {
                'question': 'What are the dining options on campus?',
                'answer': 'The campus has a main canteen, food court, and coffee shop. Various cuisines are available including South Indian, North Indian, and continental. Meal plans and cash payments are accepted.',
                'keywords': ['dining', 'food', 'canteen', 'cuisine', 'meal', 'plans']
            },
            {
                'question': 'How do I access the student lounge?',
                'answer': 'The student lounge is open 24/7 for students. Access is granted using student ID cards. The lounge has comfortable seating, charging stations, and study areas.',
                'keywords': ['lounge', 'student', 'access', 'ID', 'card', 'study', 'seating']
            },
            {
                'question': 'What are the campus security measures?',
                'answer': 'Campus security includes 24/7 surveillance, security personnel, and controlled access points. Students must carry ID cards at all times. Emergency contact numbers are displayed throughout the campus.',
                'keywords': ['security', 'surveillance', 'personnel', 'ID', 'card', 'emergency']
            },
            {
                'question': 'How do I book event venues?',
                'answer': 'Event venues can be booked through the student affairs office. Submit a booking request with event details, date, and expected attendance. Approval is required for large events.',
                'keywords': ['book', 'venue', 'event', 'student', 'affairs', 'approval']
            },
            {
                'question': 'What are the campus transportation options?',
                'answer': 'Campus has internal shuttle services connecting different blocks. Bicycles are available for rent. Walking paths and covered walkways provide easy access to all areas.',
                'keywords': ['transportation', 'shuttle', 'bicycle', 'rent', 'walking', 'paths']
            },
            {
                'question': 'How do I access the prayer room?',
                'answer': 'The prayer room is located on the ground floor and is open 24/7. Students of all faiths can use the facility. Maintain silence and respect for others using the space.',
                'keywords': ['prayer', 'room', 'faith', 'religion', 'silence', 'respect']
            },
            {
                'question': 'What are the campus Wi-Fi zones?',
                'answer': 'Wi-Fi is available throughout the campus including classrooms, library, labs, and common areas. Connect to "KSIT-Student" network using your credentials. Signal strength varies by location.',
                'keywords': ['wifi', 'zones', 'network', 'signal', 'connect', 'credentials']
            },
            {
                'question': 'How do I report maintenance issues?',
                'answer': 'Report maintenance issues through the online portal or contact the maintenance office. Provide details about the location and nature of the problem. Issues are typically resolved within 24-48 hours.',
                'keywords': ['maintenance', 'report', 'issue', 'portal', 'office', 'resolve']
            }
        ]

        # Admissions questions (10+)
        admissions_questions = [
            {
                'question': 'What are the admission requirements?',
                'answer': 'Admission requirements include 10+2 with minimum 50% marks, valid entrance exam scores, and required documents. Specific requirements vary by program. Check the admission brochure for detailed information.',
                'keywords': ['admission', 'requirements', 'marks', 'entrance', 'exam', 'documents']
            },
            {
                'question': 'How do I apply for admission?',
                'answer': 'Apply online through the college website or obtain application forms from the admission office. Fill the form completely, attach required documents, and submit before the deadline.',
                'keywords': ['apply', 'online', 'website', 'form', 'documents', 'deadline']
            },
            {
                'question': 'What is the admission process timeline?',
                'answer': 'The admission process typically starts in March and continues until July. Key dates include application deadline, entrance exam, counseling, and fee payment. Check the official calendar for specific dates.',
                'keywords': ['timeline', 'process', 'deadline', 'exam', 'counseling', 'payment']
            },
            {
                'question': 'What documents are required for admission?',
                'answer': 'Required documents include 10th and 12th mark sheets, transfer certificate, migration certificate, passport size photographs, and identity proof. Additional documents may be required for specific programs.',
                'keywords': ['documents', 'mark', 'sheet', 'certificate', 'photograph', 'identity']
            },
            {
                'question': 'How do I check my admission status?',
                'answer': 'Check admission status online using your application number and date of birth. Status updates are also sent via SMS and email. Contact the admission office for assistance.',
                'keywords': ['status', 'check', 'online', 'application', 'number', 'SMS']
            },
            {
                'question': 'What is the fee structure?',
                'answer': 'Fee structure varies by program and includes tuition fees, development fees, and other charges. Fee payment can be made in installments. Check the fee structure brochure for detailed information.',
                'keywords': ['fee', 'structure', 'tuition', 'development', 'payment', 'installments']
            },
            {
                'question': 'How do I apply for fee waiver?',
                'answer': 'Fee waiver applications are available for economically disadvantaged students. Submit the application with supporting documents to the financial aid office. Approval is based on merit and need.',
                'keywords': ['fee', 'waiver', 'economically', 'disadvantaged', 'financial', 'aid']
            },
            {
                'question': 'What are the reservation policies?',
                'answer': 'The college follows government reservation policies for SC, ST, OBC, and other categories. Specific percentages and eligibility criteria are mentioned in the admission brochure.',
                'keywords': ['reservation', 'SC', 'ST', 'OBC', 'categories', 'eligibility']
            },
            {
                'question': 'How do I get admission counseling?',
                'answer': 'Admission counseling is available through the counseling cell. Students can schedule appointments for guidance on program selection, career prospects, and admission procedures.',
                'keywords': ['counseling', 'admission', 'guidance', 'program', 'selection', 'career']
            },
            {
                'question': 'What is the refund policy?',
                'answer': 'Refund policy varies based on the timing of withdrawal. Full refund is available before classes start, partial refund during the first month, and no refund after that. Check the policy for specific details.',
                'keywords': ['refund', 'policy', 'withdrawal', 'timing', 'partial', 'full']
            }
        ]

        # Library questions (10+)
        library_questions = [
            {
                'question': 'How do I get a library membership?',
                'answer': 'Library membership is automatically activated for all enrolled students. Use your student ID card to access library services. No separate registration is required.',
                'keywords': ['membership', 'library', 'student', 'ID', 'card', 'access']
            },
            {
                'question': 'What are the book borrowing rules?',
                'answer': 'Students can borrow up to 5 books for 15 days. Renewal is allowed if no other student has reserved the book. Overdue books incur a fine of Rs. 5 per day.',
                'keywords': ['borrow', 'books', 'rules', 'days', 'renewal', 'fine']
            },
            {
                'question': 'How do I search for books in the library?',
                'answer': 'Use the online catalog system available on library computers or the college website. Search by title, author, subject, or ISBN. Library staff can assist with searches.',
                'keywords': ['search', 'books', 'catalog', 'online', 'title', 'author']
            },
            {
                'question': 'What digital resources are available?',
                'answer': 'The library provides access to e-books, e-journals, databases, and online resources. Access is available through the library website using your student credentials.',
                'keywords': ['digital', 'resources', 'e-books', 'e-journals', 'databases', 'online']
            },
            {
                'question': 'How do I reserve a book?',
                'answer': 'Reserve books through the online system or at the circulation desk. You will be notified when the book is available. Reserved books are held for 3 days.',
                'keywords': ['reserve', 'book', 'online', 'system', 'notified', 'available']
            },
            {
                'question': 'What are the photocopying facilities?',
                'answer': 'Photocopying facilities are available at Rs. 1 per page. Students can make copies of library materials for academic purposes. Copyright restrictions apply.',
                'keywords': ['photocopy', 'facilities', 'page', 'academic', 'copyright', 'restrictions']
            },
            {
                'question': 'How do I access the reading room?',
                'answer': 'The reading room is open during library hours. Students can use it for quiet study. Laptops and mobile phones are allowed but must be kept silent.',
                'keywords': ['reading', 'room', 'study', 'quiet', 'laptop', 'mobile']
            },
            {
                'question': 'What are the library fines and penalties?',
                'answer': 'Overdue books incur a fine of Rs. 5 per day. Lost books must be replaced or paid for at current market price. Damaged books may incur additional charges.',
                'keywords': ['fines', 'penalties', 'overdue', 'lost', 'damaged', 'charges']
            },
            {
                'question': 'How do I get research assistance?',
                'answer': 'Research assistance is available from library staff and subject librarians. Students can schedule appointments for help with research projects and literature reviews.',
                'keywords': ['research', 'assistance', 'staff', 'librarian', 'projects', 'literature']
            },
            {
                'question': 'What are the library timings during exams?',
                'answer': 'During examination periods, the library extends its hours and may remain open 24/7. Check the notice board or website for specific timings during exam season.',
                'keywords': ['timings', 'exams', 'extended', 'hours', '24/7', 'notice']
            }
        ]

        # Hostel questions (10+)
        hostel_questions = [
            {
                'question': 'How do I apply for hostel accommodation?',
                'answer': 'Submit a hostel application form along with required documents to the hostel office. Allocation is based on availability and merit. Priority is given to outstation students.',
                'keywords': ['hostel', 'accommodation', 'apply', 'form', 'allocation', 'outstation']
            },
            {
                'question': 'What are the hostel fees?',
                'answer': 'Hostel fees include room rent, mess charges, and other facilities. Fees vary by room type and facilities. Payment can be made semester-wise or annually.',
                'keywords': ['fees', 'hostel', 'rent', 'mess', 'charges', 'room']
            },
            {
                'question': 'What facilities are available in the hostel?',
                'answer': 'Hostel facilities include furnished rooms, common areas, study rooms, laundry, Wi-Fi, and 24/7 security. Mess provides breakfast, lunch, and dinner.',
                'keywords': ['facilities', 'furnished', 'rooms', 'common', 'study', 'laundry']
            },
            {
                'question': 'What are the hostel rules and regulations?',
                'answer': 'Hostel rules include maintaining discipline, following timings, keeping rooms clean, and respecting other residents. Visitors are allowed only during specified hours.',
                'keywords': ['rules', 'regulations', 'discipline', 'timings', 'clean', 'visitors']
            },
            {
                'question': 'How do I get a room change?',
                'answer': 'Submit a room change application to the hostel warden with valid reasons. Changes are approved based on availability and circumstances. A fee may be applicable.',
                'keywords': ['room', 'change', 'application', 'warden', 'reasons', 'availability']
            },
            {
                'question': 'What are the mess timings?',
                'answer': 'Mess serves breakfast from 7:00-9:00 AM, lunch from 12:00-2:00 PM, and dinner from 7:00-9:00 PM. Special arrangements are made during exams.',
                'keywords': ['mess', 'timings', 'breakfast', 'lunch', 'dinner', 'exams']
            },
            {
                'question': 'How do I report maintenance issues in the hostel?',
                'answer': 'Report maintenance issues to the hostel office or use the online complaint system. Issues are typically resolved within 24-48 hours depending on the nature of the problem.',
                'keywords': ['maintenance', 'issues', 'report', 'office', 'complaint', 'resolve']
            },
            {
                'question': 'What are the guest accommodation facilities?',
                'answer': 'Limited guest accommodation is available for parents and relatives. Advance booking is required. Charges apply for guest accommodation. Maximum stay is 3 days.',
                'keywords': ['guest', 'accommodation', 'parents', 'relatives', 'booking', 'charges']
            },
            {
                'question': 'How do I get a hostel leave?',
                'answer': 'Apply for hostel leave through the warden with proper justification. Leave applications must be submitted in advance. Emergency leaves can be applied for on the same day.',
                'keywords': ['leave', 'hostel', 'warden', 'justification', 'advance', 'emergency']
            },
            {
                'question': 'What are the security measures in the hostel?',
                'answer': 'Hostel security includes 24/7 security personnel, CCTV surveillance, and controlled access. Students must carry ID cards and follow security protocols.',
                'keywords': ['security', 'personnel', 'CCTV', 'surveillance', 'access', 'protocols']
            }
        ]

        # Transportation questions (10+)
        transportation_questions = [
            {
                'question': 'What are the bus routes available?',
                'answer': 'College buses operate on multiple routes covering major areas of the city. Routes include downtown, residential areas, and railway stations. Timetables are available at the transport office.',
                'keywords': ['bus', 'routes', 'operate', 'downtown', 'residential', 'timetables']
            },
            {
                'question': 'How do I get a bus pass?',
                'answer': 'Apply for a bus pass at the transport office with required documents and fees. Passes are valid for the academic year and must be renewed annually.',
                'keywords': ['bus', 'pass', 'apply', 'transport', 'office', 'documents']
            },
            {
                'question': 'What are the bus timings?',
                'answer': 'Buses operate from 7:00 AM to 6:00 PM on weekdays. Morning buses start at 7:00 AM and evening buses leave campus at 5:30 PM. Timings may vary during holidays.',
                'keywords': ['timings', 'bus', 'morning', 'evening', 'weekdays', 'holidays']
            },
            {
                'question': 'How do I track bus locations?',
                'answer': 'Bus locations can be tracked through the college mobile app or website. Real-time updates are provided for convenience. Contact transport office for assistance.',
                'keywords': ['track', 'bus', 'location', 'app', 'website', 'real-time']
            },
            {
                'question': 'What are the parking facilities for students?',
                'answer': 'Two-wheeler parking is free for students. Four-wheeler parking requires a monthly pass. Designated parking areas are available near each building. Follow parking rules and regulations.',
                'keywords': ['parking', 'two-wheeler', 'four-wheeler', 'pass', 'designated', 'rules']
            },
            {
                'question': 'How do I report bus-related issues?',
                'answer': 'Report bus issues to the transport office or use the online complaint system. Include bus number, route, and description of the problem. Issues are addressed promptly.',
                'keywords': ['report', 'bus', 'issues', 'transport', 'office', 'complaint']
            },
            {
                'question': 'What are the charges for bus services?',
                'answer': 'Bus charges vary by route and distance. Monthly passes are available at discounted rates. One-way tickets are also available for occasional users.',
                'keywords': ['charges', 'bus', 'services', 'route', 'distance', 'passes']
            },
            {
                'question': 'How do I get a parking permit?',
                'answer': 'Apply for a parking permit at the transport office with vehicle registration documents and fees. Permits are issued based on availability and student status.',
                'keywords': ['parking', 'permit', 'apply', 'vehicle', 'registration', 'availability']
            },
            {
                'question': 'What are the emergency transportation services?',
                'answer': 'Emergency transportation is available for medical emergencies and urgent situations. Contact the transport office or security for assistance. Services are available 24/7.',
                'keywords': ['emergency', 'transportation', 'medical', 'urgent', 'security', '24/7']
            },
            {
                'question': 'How do I get information about route changes?',
                'answer': 'Route changes are communicated through notice boards, college website, and SMS alerts. Students are advised to check for updates regularly and contact transport office for clarifications.',
                'keywords': ['route', 'changes', 'notice', 'website', 'SMS', 'alerts']
            }
        ]

        # Examinations questions (10+)
        examinations_questions = [
            {
                'question': 'What is the examination schedule?',
                'answer': 'Examination schedules are published on the college website and notice boards. Mid-semester exams are held in October and March, while semester-end exams are in December and May.',
                'keywords': ['examination', 'schedule', 'website', 'notice', 'mid-semester', 'semester-end']
            },
            {
                'question': 'How do I get my hall ticket?',
                'answer': 'Hall tickets are available online through the student portal. Download and print your hall ticket before the exam. Contact the examination cell if you face any issues.',
                'keywords': ['hall', 'ticket', 'online', 'portal', 'download', 'print']
            },
            {
                'question': 'What are the examination rules?',
                'answer': 'Students must carry hall ticket and ID card to the exam hall. Electronic devices are not allowed. Follow all instructions given by invigilators. Any malpractice will result in disciplinary action.',
                'keywords': ['rules', 'examination', 'hall', 'ticket', 'ID', 'card']
            },
            {
                'question': 'How do I apply for exam revaluation?',
                'answer': 'Apply for revaluation within 15 days of result declaration. Submit the application form with prescribed fees to the examination cell. Revaluation results are published within 30 days.',
                'keywords': ['revaluation', 'exam', 'apply', 'result', 'declaration', 'fees']
            },
            {
                'question': 'What is the grading system for exams?',
                'answer': 'The college follows a 10-point grading system. Grades range from O (Outstanding) to F (Fail). The minimum passing grade is D (4.0 points). CGPA is calculated based on credit-weighted grades.',
                'keywords': ['grading', 'system', 'points', 'grade', 'CGPA', 'passing']
            },
            {
                'question': 'How do I get a duplicate mark sheet?',
                'answer': 'Apply for a duplicate mark sheet at the examination cell. Submit the application form with an affidavit and prescribed fees. The duplicate will be issued within 15-20 working days.',
                'keywords': ['duplicate', 'marksheet', 'examination', 'cell', 'affidavit', 'fees']
            },
            {
                'question': 'What are the exam center details?',
                'answer': 'Exam centers are assigned based on the course and student roll number. Details are mentioned on the hall ticket. Students must report to the assigned center 30 minutes before the exam.',
                'keywords': ['exam', 'center', 'assigned', 'course', 'roll', 'number']
            },
            {
                'question': 'How do I apply for exam postponement?',
                'answer': 'Apply for exam postponement with valid medical or emergency reasons. Submit supporting documents to the examination cell. Approval is subject to verification and availability.',
                'keywords': ['postponement', 'exam', 'medical', 'emergency', 'documents', 'approval']
            },
            {
                'question': 'What are the supplementary exam procedures?',
                'answer': 'Supplementary exams are conducted for students who fail in one or two subjects. Apply within the specified deadline with prescribed fees. Supplementary results are published separately.',
                'keywords': ['supplementary', 'exam', 'fail', 'subjects', 'deadline', 'fees']
            },
            {
                'question': 'How do I get exam results?',
                'answer': 'Exam results are published on the college website and notice boards. Students can check results using their roll number and date of birth. Results are also sent via SMS.',
                'keywords': ['results', 'exam', 'website', 'notice', 'roll', 'number']
            }
        ]

        # Financial questions (10+)
        financial_questions = [
            {
                'question': 'What are the fee payment methods?',
                'answer': 'Fees can be paid through online banking, credit/debit cards, demand draft, or cash at the finance office. Installment payments are available for eligible students.',
                'keywords': ['fee', 'payment', 'methods', 'online', 'banking', 'installment']
            },
            {
                'question': 'How do I get a fee receipt?',
                'answer': 'Fee receipts are generated automatically after payment. Download from the student portal or collect from the finance office. Receipts are required for various official purposes.',
                'keywords': ['receipt', 'fee', 'payment', 'portal', 'finance', 'office']
            },
            {
                'question': 'What are the scholarship opportunities?',
                'answer': 'Various scholarships are available based on merit, need, and category. Apply through the financial aid office with required documents. Deadlines and eligibility criteria vary by scholarship.',
                'keywords': ['scholarship', 'opportunities', 'merit', 'need', 'category', 'financial']
            },
            {
                'question': 'How do I apply for financial aid?',
                'answer': 'Submit a financial aid application with supporting documents to the financial aid office. Applications are reviewed based on family income and academic performance. Assistance is provided as per policy.',
                'keywords': ['financial', 'aid', 'apply', 'documents', 'income', 'academic']
            },
            {
                'question': 'What is the refund policy for fees?',
                'answer': 'Refund policy varies based on withdrawal timing. Full refund before classes start, partial refund during the first month, and no refund after that. Processing time is 15-30 working days.',
                'keywords': ['refund', 'policy', 'withdrawal', 'timing', 'partial', 'processing']
            },
            {
                'question': 'How do I get a fee structure breakdown?',
                'answer': 'Fee structure breakdown is available in the admission brochure and on the college website. Contact the finance office for detailed information about specific fees and charges.',
                'keywords': ['fee', 'structure', 'breakdown', 'brochure', 'website', 'charges']
            },
            {
                'question': 'What are the late fee charges?',
                'answer': 'Late fee charges are applicable for payments made after the due date. Charges vary by the number of days delayed. Students are advised to pay fees on time to avoid penalties.',
                'keywords': ['late', 'fee', 'charges', 'due', 'date', 'penalties']
            },
            {
                'question': 'How do I get a fee waiver?',
                'answer': 'Fee waiver applications are available for economically disadvantaged students. Submit the application with supporting documents to the financial aid office. Approval is based on merit and need.',
                'keywords': ['fee', 'waiver', 'economically', 'disadvantaged', 'documents', 'approval']
            },
            {
                'question': 'What are the payment deadlines?',
                'answer': 'Payment deadlines are communicated through notice boards and college website. First installment is due at admission, second at mid-semester, and third before semester-end exams.',
                'keywords': ['payment', 'deadlines', 'installment', 'admission', 'mid-semester', 'exams']
            },
            {
                'question': 'How do I get a fee certificate?',
                'answer': 'Apply for a fee certificate at the finance office with required documents. The certificate is issued within 3-5 working days and is required for various official purposes.',
                'keywords': ['fee', 'certificate', 'finance', 'office', 'documents', 'official']
            }
        ]

        # Create questions for each category
        categories_data = {
            'Academic': academic_questions,
            'Campus Life': campus_life_questions,
            'Admissions': admissions_questions,
            'Library': library_questions,
            'Hostel': hostel_questions,
            'Transportation': transportation_questions,
            'Examinations': examinations_questions,
            'Financial': financial_questions
        }

        for category_name, questions in categories_data.items():
            try:
                category = ChatbotCategory.objects.get(name=category_name)
                for question_data in questions:
                    question, created = ChatbotQuestion.objects.get_or_create(
                        category=category,
                        question=question_data['question'],
                        defaults={
                            'answer': question_data['answer'],
                            'keywords': question_data['keywords'],
                            'priority': 5,
                            'is_active': True
                        }
                    )
                    if created:
                        self.stdout.write(f'Created {category_name} question: {question.question[:50]}...')
            except ChatbotCategory.DoesNotExist:
                self.stdout.write(f'Category {category_name} not found. Please run populate_chatbot_data.py first.')

        self.stdout.write(self.style.SUCCESS('Successfully populated category-specific questions!'))

