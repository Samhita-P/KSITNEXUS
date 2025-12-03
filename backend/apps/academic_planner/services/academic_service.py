"""
Academic Service for managing courses, assignments, and grades
"""
from typing import List, Optional, Dict
from django.contrib.auth import get_user_model
from django.db.models import Q, Avg, Count, Sum
from django.utils import timezone
from datetime import timedelta
from apps.academic_planner.models import (
    Course, CourseEnrollment, Assignment, Grade, AcademicReminder
)
from apps.shared.utils.logging import get_logger

User = get_user_model()
logger = get_logger(__name__)


class AcademicService:
    """Main service for academic planning features"""
    
    @staticmethod
    def get_student_courses(user, semester: Optional[int] = None, academic_year: Optional[str] = None):
        """Get all courses for a student"""
        enrollments = CourseEnrollment.objects.filter(
            student=user,
            status='enrolled'
        ).select_related('course', 'course__instructor')
        
        if semester:
            enrollments = enrollments.filter(course__semester=semester)
        if academic_year:
            enrollments = enrollments.filter(course__academic_year=academic_year)
        
        return [enrollment.course for enrollment in enrollments]
    
    @staticmethod
    def get_student_assignments(
        user,
        course_id: Optional[int] = None,
        status: Optional[str] = None,
        upcoming_only: bool = False
    ):
        """Get assignments for a student"""
        assignments = Assignment.objects.filter(
            Q(student=user) | Q(student__isnull=True, course__enrollments__student=user)
        ).select_related('course', 'student', 'graded_by').distinct()
        
        if course_id:
            assignments = assignments.filter(course_id=course_id)
        if status:
            assignments = assignments.filter(status=status)
        if upcoming_only:
            assignments = assignments.filter(
                due_date__gte=timezone.now(),
                status__in=['not_started', 'in_progress']
            )
        
        return assignments.order_by('due_date')
    
    @staticmethod
    def get_upcoming_deadlines(user, days: int = 7):
        """Get upcoming deadlines for a student"""
        cutoff_date = timezone.now() + timedelta(days=days)
        
        assignments = Assignment.objects.filter(
            Q(student=user) | Q(student__isnull=True, course__enrollments__student=user),
            due_date__lte=cutoff_date,
            due_date__gte=timezone.now(),
            status__in=['not_started', 'in_progress']
        ).select_related('course').distinct()
        
        reminders = AcademicReminder.objects.filter(
            user=user,
            reminder_date__lte=cutoff_date,
            reminder_date__gte=timezone.now(),
            is_completed=False
        ).select_related('course', 'assignment')
        
        return {
            'assignments': assignments,
            'reminders': reminders,
        }
    
    @staticmethod
    def calculate_course_grade(student, course, semester: Optional[int] = None, academic_year: Optional[str] = None):
        """Calculate final grade for a course based on assignments"""
        assignments = Assignment.objects.filter(
            Q(course=course) & (Q(student=student) | Q(student__isnull=True))
        )
        
        if semester:
            assignments = assignments.filter(course__semester=semester)
        if academic_year:
            assignments = assignments.filter(course__academic_year=academic_year)
        
        graded_assignments = assignments.filter(status='graded', score__isnull=False)
        
        if not graded_assignments.exists():
            return None
        
        total_weighted_score = 0
        total_weight = 0
        
        for assignment in graded_assignments:
            if assignment.max_score > 0:
                percentage = (assignment.score / assignment.max_score) * 100
                weight = assignment.weight or 0
                total_weighted_score += percentage * weight
                total_weight += weight
        
        if total_weight == 0:
            return None
        
        final_percentage = total_weighted_score / total_weight
        
        # Convert percentage to grade
        grade, grade_points = AcademicService._percentage_to_grade(final_percentage)
        
        return {
            'percentage': final_percentage,
            'grade': grade,
            'grade_points': grade_points,
            'assignment_count': graded_assignments.count(),
        }
    
    @staticmethod
    def _percentage_to_grade(percentage):
        """Convert percentage to letter grade and grade points"""
        if percentage >= 90:
            return ('S', 10.0)
        elif percentage >= 80:
            return ('A', 9.0)
        elif percentage >= 70:
            return ('B', 8.0)
        elif percentage >= 60:
            return ('C', 7.0)
        elif percentage >= 50:
            return ('D', 6.0)
        elif percentage >= 40:
            return ('E', 5.0)
        else:
            return ('F', 0.0)
    
    @staticmethod
    def calculate_gpa(user, semester: Optional[int] = None, academic_year: Optional[str] = None):
        """Calculate GPA for a student"""
        enrollments = CourseEnrollment.objects.filter(
            student=user,
            status__in=['enrolled', 'completed']
        ).select_related('course')
        
        if semester:
            enrollments = enrollments.filter(course__semester=semester)
        if academic_year:
            enrollments = enrollments.filter(course__academic_year=academic_year)
        
        total_points = 0
        total_credits = 0
        
        for enrollment in enrollments:
            if enrollment.grade_points is not None:
                credits = enrollment.course.credits
                total_points += float(enrollment.grade_points) * credits
                total_credits += credits
        
        if total_credits == 0:
            return None
        
        return total_points / total_credits
    
    @staticmethod
    def get_academic_dashboard(user):
        """Get comprehensive academic dashboard data"""
        enrollments = CourseEnrollment.objects.filter(
            student=user,
            status='enrolled'
        )
        
        assignments = Assignment.objects.filter(
            Q(student=user) | Q(student__isnull=True, course__enrollments__student=user)
        ).distinct()
        
        now = timezone.now()
        upcoming_cutoff = now + timedelta(days=7)
        
        try:
            total_credits_result = enrollments.aggregate(total=Sum('course__credits'))
            total_credits = int(total_credits_result['total'] or 0)
        except Exception:
            total_credits = 0
        
        try:
            completed_credits_result = CourseEnrollment.objects.filter(
                student=user,
                status='completed'
            ).aggregate(total=Sum('course__credits'))
            completed_credits = int(completed_credits_result['total'] or 0)
        except Exception:
            completed_credits = 0
        
        return {
            'enrolled_courses': enrollments.count() or 0,
            'active_assignments': assignments.filter(
                status__in=['not_started', 'in_progress']
            ).count() or 0,
            'overdue_assignments': assignments.filter(
                due_date__lt=now,
                status__in=['not_started', 'in_progress']
            ).count() or 0,
            'upcoming_deadlines': assignments.filter(
                due_date__gte=now,
                due_date__lte=upcoming_cutoff,
                status__in=['not_started', 'in_progress']
            ).count() or 0,
            'current_gpa': AcademicService.calculate_gpa(user),
            'total_credits': total_credits,
            'completed_credits': completed_credits,
        }
    
    @staticmethod
    def create_assignment_reminders(assignment, days_before: List[int] = [7, 3, 1]):
        """Create reminders for an assignment"""
        reminders = []
        for days in days_before:
            reminder_date = assignment.due_date - timedelta(days=days)
            if reminder_date > timezone.now():
                reminder, created = AcademicReminder.objects.get_or_create(
                    user=assignment.student,
                    assignment=assignment,
                    reminder_date=reminder_date,
                    defaults={
                        'title': f"Reminder: {assignment.title} due in {days} days",
                        'description': f"Assignment '{assignment.title}' for {assignment.course.course_code} is due in {days} days.",
                        'reminder_type': 'assignment_due',
                        'course': assignment.course,
                        'priority': 'high' if days <= 1 else 'medium',
                    }
                )
                if created:
                    reminders.append(reminder)
        return reminders

