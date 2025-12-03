"""
Views for academic planner app
"""
from rest_framework import generics, status, permissions, serializers
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.db.models import Q
from django.utils import timezone
from .models import Course, CourseEnrollment, Assignment, Grade, AcademicReminder
from .serializers import (
    CourseSerializer, CourseEnrollmentSerializer, AssignmentSerializer,
    GradeSerializer, AcademicReminderSerializer, CourseSummarySerializer,
    AcademicDashboardSerializer
)
from .services.academic_service import AcademicService
from .services.grade_calculator import GradeCalculator

User = get_user_model()


# Courses
class CourseListView(generics.ListCreateAPIView):
    """List and create courses"""
    queryset = Course.objects.filter(is_active=True)
    serializer_class = CourseSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            queryset = super().get_queryset()
            semester = self.request.query_params.get('semester')
            academic_year = self.request.query_params.get('academic_year')
            
            if semester:
                queryset = queryset.filter(semester=semester)
            if academic_year:
                queryset = queryset.filter(academic_year=academic_year)
            
            return queryset
        except Exception as e:
            import traceback
            print(f"Error in CourseListView.get_queryset: {e}")
            traceback.print_exc()
            return Course.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to handle errors gracefully and return direct list (no pagination)"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            import traceback
            print(f"Error in CourseListView.list: {e}")
            traceback.print_exc()
            return Response([], status=status.HTTP_200_OK)


class CourseDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Course detail view"""
    queryset = Course.objects.all()
    serializer_class = CourseSerializer
    permission_classes = [permissions.IsAuthenticated]


# Course Enrollments
class CourseEnrollmentListView(generics.ListCreateAPIView):
    """List and create course enrollments"""
    serializer_class = CourseEnrollmentSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            user = self.request.user
            if user.user_type == 'student':
                return CourseEnrollment.objects.filter(student=user).select_related('course', 'course__instructor')
            elif user.user_type == 'faculty':
                return CourseEnrollment.objects.filter(course__instructor=user).select_related('student', 'course')
            return CourseEnrollment.objects.none()
        except Exception as e:
            import traceback
            print(f"Error in CourseEnrollmentListView.get_queryset: {e}")
            traceback.print_exc()
            return CourseEnrollment.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to handle errors gracefully and return direct list (no pagination)"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            import traceback
            print(f"Error in CourseEnrollmentListView.list: {e}")
            traceback.print_exc()
            return Response([], status=status.HTTP_200_OK)
    
    def create(self, request, *args, **kwargs):
        """Override create to handle errors gracefully"""
        try:
            serializer = self.get_serializer(data=request.data, context={'request': request})
            serializer.is_valid(raise_exception=True)
            self.perform_create(serializer)
            headers = self.get_success_headers(serializer.data)
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
        except serializers.ValidationError as e:
            return Response(
                {'error': str(e.detail) if hasattr(e, 'detail') else str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            import traceback
            print(f"Error in CourseEnrollmentListView.create: {e}")
            traceback.print_exc()
            return Response(
                {'error': f'Error creating enrollment: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def perform_create(self, serializer):
        serializer.save(student=self.request.user)


class CourseEnrollmentDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Course enrollment detail view"""
    queryset = CourseEnrollment.objects.all()
    serializer_class = CourseEnrollmentSerializer
    permission_classes = [permissions.IsAuthenticated]


# Assignments
class AssignmentListView(generics.ListCreateAPIView):
    """List and create assignments"""
    serializer_class = AssignmentSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            user = self.request.user
            queryset = Assignment.objects.all().select_related('course', 'student', 'graded_by')
            
            if user.user_type == 'student':
                queryset = queryset.filter(
                    Q(student=user) | Q(student__isnull=True, course__enrollments__student=user)
                ).distinct()
            elif user.user_type == 'faculty':
                queryset = queryset.filter(course__instructor=user)
            
            course_id = self.request.query_params.get('course_id')
            status_filter = self.request.query_params.get('status')
            
            if course_id:
                queryset = queryset.filter(course_id=course_id)
            if status_filter:
                queryset = queryset.filter(status=status_filter)
            
            return queryset.order_by('due_date')
        except Exception as e:
            import traceback
            print(f"Error in AssignmentListView.get_queryset: {e}")
            traceback.print_exc()
            return Assignment.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to handle errors gracefully and return direct list (no pagination)"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            import traceback
            print(f"Error in AssignmentListView.list: {e}")
            traceback.print_exc()
            return Response([], status=status.HTTP_200_OK)
    
    def create(self, request, *args, **kwargs):
        """Override create to handle errors gracefully"""
        try:
            serializer = self.get_serializer(data=request.data, context={'request': request})
            serializer.is_valid(raise_exception=True)
            self.perform_create(serializer)
            headers = self.get_success_headers(serializer.data)
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
        except serializers.ValidationError as e:
            return Response(
                {'error': str(e.detail) if hasattr(e, 'detail') else str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            import traceback
            print(f"Error in AssignmentListView.create: {e}")
            traceback.print_exc()
            return Response(
                {'error': f'Error creating assignment: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def perform_create(self, serializer):
        serializer.save()


class AssignmentDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Assignment detail view"""
    queryset = Assignment.objects.all()
    serializer_class = AssignmentSerializer
    permission_classes = [permissions.IsAuthenticated]


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def submit_assignment(request, assignment_id):
    """Submit an assignment"""
    try:
        assignment = Assignment.objects.get(id=assignment_id)
        
        if assignment.student and assignment.student != request.user:
            return Response(
                {'error': 'You do not have permission to submit this assignment'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        assignment.submission_link = request.data.get('submission_link')
        assignment.status = 'submitted'
        assignment.submitted_at = timezone.now()
        assignment.save()
        
        serializer = AssignmentSerializer(assignment)
        return Response(serializer.data)
    except Assignment.DoesNotExist:
        return Response(
            {'error': 'Assignment not found'},
            status=status.HTTP_404_NOT_FOUND
        )


# Grades
class GradeListView(generics.ListCreateAPIView):
    """List and create grades"""
    serializer_class = GradeSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            user = self.request.user
            queryset = Grade.objects.all().select_related('student', 'course')
            
            if user.user_type == 'student':
                queryset = queryset.filter(student=user)
            elif user.user_type == 'faculty':
                queryset = queryset.filter(course__instructor=user)
            
            semester = self.request.query_params.get('semester')
            academic_year = self.request.query_params.get('academic_year')
            
            if semester:
                queryset = queryset.filter(semester=semester)
            if academic_year:
                queryset = queryset.filter(academic_year=academic_year)
            
            return queryset
        except Exception as e:
            import traceback
            print(f"Error in GradeListView.get_queryset: {e}")
            traceback.print_exc()
            return Grade.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to handle errors gracefully and return direct list (no pagination)"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            import traceback
            print(f"Error in GradeListView.list: {e}")
            traceback.print_exc()
            return Response([], status=status.HTTP_200_OK)


class GradeDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Grade detail view"""
    queryset = Grade.objects.all()
    serializer_class = GradeSerializer
    permission_classes = [permissions.IsAuthenticated]


# Academic Reminders
class AcademicReminderListView(generics.ListCreateAPIView):
    """List and create academic reminders"""
    serializer_class = AcademicReminderSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        try:
            return AcademicReminder.objects.filter(
                user=self.request.user
            ).select_related('course', 'assignment').order_by('reminder_date')
        except Exception as e:
            import traceback
            print(f"Error in AcademicReminderListView.get_queryset: {e}")
            traceback.print_exc()
            return AcademicReminder.objects.none()
    
    def list(self, request, *args, **kwargs):
        """Override list to handle errors gracefully and return direct list (no pagination)"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            import traceback
            print(f"Error in AcademicReminderListView.list: {e}")
            traceback.print_exc()
            return Response([], status=status.HTTP_200_OK)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class AcademicReminderDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Academic reminder detail view"""
    queryset = AcademicReminder.objects.all()
    serializer_class = AcademicReminderSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return AcademicReminder.objects.filter(user=self.request.user)


# Dashboard and Statistics
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def academic_dashboard(request):
    """Get academic dashboard data"""
    try:
        dashboard_data = AcademicService.get_academic_dashboard(request.user)
        serializer = AcademicDashboardSerializer(dashboard_data)
        return Response(serializer.data)
    except Exception as e:
        import traceback
        print(f"Error in academic_dashboard: {e}")
        traceback.print_exc()
        return Response(
            {
                'enrolled_courses': 0,
                'active_assignments': 0,
                'overdue_assignments': 0,
                'upcoming_deadlines': 0,
                'current_gpa': None,
                'total_credits': 0,
                'completed_credits': 0,
            },
            status=status.HTTP_200_OK
        )


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def upcoming_deadlines(request):
    """Get upcoming deadlines"""
    try:
        days = int(request.query_params.get('days', 7))
        deadlines = AcademicService.get_upcoming_deadlines(request.user, days)
        
        return Response({
            'assignments': AssignmentSerializer(deadlines['assignments'], many=True).data,
            'reminders': AcademicReminderSerializer(deadlines['reminders'], many=True).data,
        })
    except Exception as e:
        import traceback
        print(f"Error in upcoming_deadlines: {e}")
        traceback.print_exc()
        return Response({
            'assignments': [],
            'reminders': [],
        }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def calculate_gpa(request):
    """Calculate student GPA"""
    semester = request.query_params.get('semester', type=int)
    academic_year = request.query_params.get('academic_year')
    
    gpa = AcademicService.calculate_gpa(request.user, semester, academic_year)
    
    return Response({
        'gpa': gpa,
        'semester': semester,
        'academic_year': academic_year,
    })


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def calculate_course_grade(request, course_id):
    """Calculate grade for a specific course"""
    try:
        course = Course.objects.get(id=course_id)
        semester = request.data.get('semester', type=int)
        academic_year = request.data.get('academic_year')
        
        grade_data = AcademicService.calculate_course_grade(
            request.user,
            course,
            semester,
            academic_year
        )
        
        if grade_data:
            return Response(grade_data)
        else:
            return Response(
                {'error': 'No graded assignments found for this course'},
                status=status.HTTP_400_BAD_REQUEST
            )
    except Course.DoesNotExist:
        return Response(
            {'error': 'Course not found'},
            status=status.HTTP_404_NOT_FOUND
        )

