"""
Management command to add more questions to each category
"""
from django.core.management.base import BaseCommand
from apps.chatbot.models import ChatbotCategory, ChatbotQuestion


class Command(BaseCommand):
    help = 'Add more questions to each chatbot category'

    def handle(self, *args, **options):
        self.stdout.write('Adding more questions to each category...')

        # Additional questions for each category
        category_questions = {
            'General FAQ': [
                {
                    'question': 'What is the college code for KSIT?',
                    'answer': 'The college code for KSIT is [COLLEGE_CODE]. This code is used for various official purposes including exam registrations and university communications.',
                    'keywords': ['college', 'code', 'KSIT', 'registration', 'university']
                },
                {
                    'question': 'How do I get a migration certificate?',
                    'answer': 'Apply for a migration certificate at the administration office. Submit the application form with required documents and pay the prescribed fee. The certificate is usually issued within 5-7 working days.',
                    'keywords': ['migration', 'certificate', 'administration', 'office', 'apply']
                },
                {
                    'question': 'What are the college holidays?',
                    'answer': 'College holidays include national holidays, festivals, and semester breaks. The academic calendar is published at the beginning of each academic year and is available on the college website.',
                    'keywords': ['holidays', 'national', 'festivals', 'semester', 'breaks', 'calendar']
                },
                {
                    'question': 'How do I get a no-dues certificate?',
                    'answer': 'Apply for a no-dues certificate at the accounts office. Clear all pending fees and library dues before applying. The certificate is issued after verification of all dues.',
                    'keywords': ['no-dues', 'certificate', 'accounts', 'office', 'fees', 'library']
                },
                {
                    'question': 'What are the college contact details?',
                    'answer': 'College can be contacted at +91-80-1234-5678 or email info@ksit.edu.in. The address is [COLLEGE_ADDRESS]. Office hours are 9:00 AM to 5:00 PM on weekdays.',
                    'keywords': ['contact', 'phone', 'email', 'address', 'office', 'hours']
                },
                {
                    'question': 'How do I get a study certificate?',
                    'answer': 'Apply for a study certificate at the administration office. Submit the application form with required documents. The certificate is usually issued within 2-3 working days.',
                    'keywords': ['study', 'certificate', 'administration', 'office', 'apply']
                },
                {
                    'question': 'What are the college rules and regulations?',
                    'answer': 'College rules include maintaining discipline, following dress code, regular attendance, and respecting faculty and staff. Detailed rules are available in the student handbook.',
                    'keywords': ['rules', 'regulations', 'discipline', 'dress', 'code', 'attendance']
                },
                {
                    'question': 'How do I get a provisional certificate?',
                    'answer': 'Apply for a provisional certificate at the examination cell. Submit the application form with required documents and pay the prescribed fee. The certificate is issued for temporary purposes.',
                    'keywords': ['provisional', 'certificate', 'examination', 'cell', 'temporary']
                },
                {
                    'question': 'What are the college facilities?',
                    'answer': 'College facilities include library, computer labs, sports complex, canteen, hostel, transportation, and medical facilities. All facilities are maintained for student welfare.',
                    'keywords': ['facilities', 'library', 'labs', 'sports', 'canteen', 'hostel']
                },
                {
                    'question': 'How do I get a course completion certificate?',
                    'answer': 'Apply for a course completion certificate at the academic office after completing all course requirements. Submit the application form with required documents and pay the prescribed fee.',
                    'keywords': ['course', 'completion', 'certificate', 'academic', 'office', 'requirements']
                }
            ],
            'Academic': [
                {
                    'question': 'What is the academic calendar?',
                    'answer': 'The academic calendar is published at the beginning of each academic year and includes important dates for exams, holidays, and academic activities. It is available on the college website and notice boards.',
                    'keywords': ['academic', 'calendar', 'dates', 'exams', 'holidays', 'activities']
                },
                {
                    'question': 'How do I apply for course correction?',
                    'answer': 'Submit a course correction application to the academic office within the specified deadline. Include valid reasons and supporting documents. Approval is subject to verification and availability.',
                    'keywords': ['course', 'correction', 'application', 'academic', 'office', 'deadline']
                },
                {
                    'question': 'What are the project guidelines?',
                    'answer': 'Project guidelines include proper formatting, documentation, and submission procedures. Detailed guidelines are available in the project handbook and from faculty advisors.',
                    'keywords': ['project', 'guidelines', 'formatting', 'documentation', 'submission', 'handbook']
                },
                {
                    'question': 'How do I get academic transcripts?',
                    'answer': 'Apply for academic transcripts at the examination cell. Submit the application form with required documents and pay the prescribed fee. Transcripts are usually ready within 10-15 working days.',
                    'keywords': ['academic', 'transcripts', 'examination', 'cell', 'apply', 'documents']
                },
                {
                    'question': 'What is the credit transfer policy?',
                    'answer': 'Credit transfer is allowed for equivalent courses from recognized institutions. Submit the application with course details and transcripts. Approval is subject to evaluation by the academic committee.',
                    'keywords': ['credit', 'transfer', 'policy', 'equivalent', 'courses', 'institutions']
                },
                {
                    'question': 'How do I get academic counseling?',
                    'answer': 'Academic counseling is available through faculty advisors and the academic counseling cell. Students can schedule appointments for guidance on course selection and academic planning.',
                    'keywords': ['academic', 'counseling', 'faculty', 'advisors', 'guidance', 'planning']
                },
                {
                    'question': 'What are the laboratory safety rules?',
                    'answer': 'Laboratory safety rules include wearing protective equipment, following procedures, and maintaining cleanliness. All students must attend safety orientation before using lab facilities.',
                    'keywords': ['laboratory', 'safety', 'rules', 'protective', 'equipment', 'procedures']
                },
                {
                    'question': 'How do I apply for academic leave?',
                    'answer': 'Submit an academic leave application to the academic office with valid reasons and supporting documents. Leave applications must be submitted in advance for approval.',
                    'keywords': ['academic', 'leave', 'application', 'office', 'reasons', 'documents']
                },
                {
                    'question': 'What is the plagiarism policy?',
                    'answer': 'Plagiarism is strictly prohibited. All assignments and projects must be original work. Plagiarism detection software is used to check submissions. Violations result in disciplinary action.',
                    'keywords': ['plagiarism', 'policy', 'original', 'work', 'detection', 'software']
                },
                {
                    'question': 'How do I get course materials?',
                    'answer': 'Course materials are available through the library, online portal, and faculty. Students can access digital resources and borrow physical materials as per library rules.',
                    'keywords': ['course', 'materials', 'library', 'online', 'portal', 'faculty']
                }
            ],
            'Campus Life': [
                {
                    'question': 'What are the campus events?',
                    'answer': 'Campus events include cultural festivals, technical symposiums, sports meets, and social activities. Event schedules are published on notice boards and college website.',
                    'keywords': ['campus', 'events', 'cultural', 'festivals', 'technical', 'sports']
                },
                {
                    'question': 'How do I join student clubs?',
                    'answer': 'Student clubs are open for membership during the club fair held at the beginning of each academic year. You can also contact club coordinators directly for membership.',
                    'keywords': ['student', 'clubs', 'membership', 'fair', 'coordinators', 'academic']
                },
                {
                    'question': 'What are the campus dining options?',
                    'answer': 'Campus has a main canteen, food court, and coffee shop. Various cuisines are available including South Indian, North Indian, and continental. Meal plans and cash payments are accepted.',
                    'keywords': ['campus', 'dining', 'canteen', 'food', 'court', 'cuisines']
                },
                {
                    'question': 'How do I access the gymnasium?',
                    'answer': 'The gymnasium is open to all students during specified hours. Students must register and follow safety guidelines. Gym equipment is available for use with proper supervision.',
                    'keywords': ['gymnasium', 'gym', 'students', 'hours', 'register', 'equipment']
                },
                {
                    'question': 'What are the campus security measures?',
                    'answer': 'Campus security includes 24/7 surveillance, security personnel, and controlled access points. Students must carry ID cards at all times. Emergency contact numbers are displayed throughout the campus.',
                    'keywords': ['campus', 'security', 'surveillance', 'personnel', 'access', 'emergency']
                },
                {
                    'question': 'How do I book event venues?',
                    'answer': 'Event venues can be booked through the student affairs office. Submit a booking request with event details, date, and expected attendance. Approval is required for large events.',
                    'keywords': ['book', 'venue', 'event', 'student', 'affairs', 'booking']
                },
                {
                    'question': 'What are the campus transportation options?',
                    'answer': 'Campus has internal shuttle services connecting different blocks. Bicycles are available for rent. Walking paths and covered walkways provide easy access to all areas.',
                    'keywords': ['campus', 'transportation', 'shuttle', 'bicycles', 'rent', 'walking']
                },
                {
                    'question': 'How do I access the prayer room?',
                    'answer': 'The prayer room is located on the ground floor and is open 24/7. Students of all faiths can use the facility. Maintain silence and respect for others using the space.',
                    'keywords': ['prayer', 'room', 'faith', 'religion', 'silence', 'respect']
                },
                {
                    'question': 'What are the campus Wi-Fi zones?',
                    'answer': 'Wi-Fi is available throughout the campus including classrooms, library, labs, and common areas. Connect to "KSIT-Student" network using your credentials. Signal strength varies by location.',
                    'keywords': ['campus', 'wifi', 'zones', 'network', 'connect', 'credentials']
                },
                {
                    'question': 'How do I report maintenance issues?',
                    'answer': 'Report maintenance issues through the online portal or contact the maintenance office. Provide details about the location and nature of the problem. Issues are typically resolved within 24-48 hours.',
                    'keywords': ['maintenance', 'issues', 'report', 'portal', 'office', 'resolve']
                }
            ],
            'Admissions': [
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
            ],
            'Library': [
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
            ],
            'Hostel': [
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
            ],
            'Transportation': [
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
            ],
            'Examinations': [
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
            ],
            'Financial': [
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
                    'answer': 'Refund policy varies based on withdrawal timing. Full refund is available before classes start, partial refund during the first month, and no refund after that. Processing time is 15-30 working days.',
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
        }

        # Add questions to each category
        for category_name, questions in category_questions.items():
            try:
                category = ChatbotCategory.objects.get(name=category_name)
                added_count = 0
                
                for question_data in questions:
                    # Check if question already exists
                    if not ChatbotQuestion.objects.filter(
                        category=category,
                        question=question_data['question']
                    ).exists():
                        ChatbotQuestion.objects.create(
                            category=category,
                            question=question_data['question'],
                            answer=question_data['answer'],
                            keywords=question_data['keywords'],
                            priority=5,
                            is_active=True
                        )
                        added_count += 1
                
                self.stdout.write(f'Added {added_count} new questions to {category_name}')
                
            except ChatbotCategory.DoesNotExist:
                self.stdout.write(f'Category {category_name} not found. Skipping...')

        self.stdout.write(self.style.SUCCESS('Successfully added questions to all categories!'))

