"""
Grade Calculator Service
"""
from typing import Dict, Optional
from decimal import Decimal
from django.db.models import Q
from apps.academic_planner.models import Assignment, CourseEnrollment, Grade
from apps.shared.utils.logging import get_logger

logger = get_logger(__name__)


class GradeCalculator:
    """Service for calculating grades"""
    
    @staticmethod
    def calculate_final_grade(enrollment: CourseEnrollment) -> Optional[Dict]:
        """Calculate final grade for a course enrollment"""
        assignments = Assignment.objects.filter(
            Q(course=enrollment.course) & 
            (Q(student=enrollment.student) | Q(student__isnull=True)) &
            Q(status='graded') &
            Q(score__isnull=False)
        )
        
        if not assignments.exists():
            return None
        
        total_weighted_score = Decimal('0')
        total_weight = Decimal('0')
        
        for assignment in assignments:
            if assignment.max_score > 0 and assignment.weight:
                percentage = (assignment.score / assignment.max_score) * 100
                weight = Decimal(str(assignment.weight))
                total_weighted_score += Decimal(str(percentage)) * weight
                total_weight += weight
        
        if total_weight == 0:
            return None
        
        final_percentage = float(total_weighted_score / total_weight)
        grade, grade_points = GradeCalculator._percentage_to_grade(final_percentage)
        
        # Update enrollment
        enrollment.final_grade = grade
        enrollment.grade_points = Decimal(str(grade_points))
        enrollment.save()
        
        return {
            'percentage': final_percentage,
            'grade': grade,
            'grade_points': float(grade_points),
        }
    
    @staticmethod
    def _percentage_to_grade(percentage: float) -> tuple:
        """Convert percentage to letter grade and grade points"""
        if percentage >= 90:
            return ('S', Decimal('10.0'))
        elif percentage >= 80:
            return ('A', Decimal('9.0'))
        elif percentage >= 70:
            return ('B', Decimal('8.0'))
        elif percentage >= 60:
            return ('C', Decimal('7.0'))
        elif percentage >= 50:
            return ('D', Decimal('6.0'))
        elif percentage >= 40:
            return ('E', Decimal('5.0'))
        else:
            return ('F', Decimal('0.0'))
    
    @staticmethod
    def update_grade_record(student, course, semester: Optional[int] = None, academic_year: Optional[str] = None):
        """Create or update grade record"""
        enrollment = CourseEnrollment.objects.filter(
            student=student,
            course=course,
            status__in=['enrolled', 'completed']
        ).first()
        
        if not enrollment:
            return None
        
        grade_data = GradeCalculator.calculate_final_grade(enrollment)
        
        if not grade_data:
            return None
        
        grade, created = Grade.objects.update_or_create(
            student=student,
            course=course,
            semester=semester or course.semester,
            academic_year=academic_year or course.academic_year,
            defaults={
                'grade': grade_data['grade'],
                'grade_points': Decimal(str(grade_data['grade_points'])),
                'percentage': Decimal(str(grade_data['percentage'])),
                'is_final': True,
            }
        )
        
        return grade

