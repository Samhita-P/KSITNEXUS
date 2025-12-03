"""
Academic Planner models for KSIT Nexus
"""
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator
from apps.shared.models.base import TimestampedModel

User = get_user_model()


class Course(TimestampedModel):
    """Course model for academic planning"""
    
    COURSE_TYPES = [
        ('core', 'Core'),
        ('elective', 'Elective'),
        ('lab', 'Laboratory'),
        ('project', 'Project'),
        ('seminar', 'Seminar'),
        ('workshop', 'Workshop'),
    ]
    
    SEMESTER_CHOICES = [
        (1, 'Semester 1'),
        (2, 'Semester 2'),
        (3, 'Semester 3'),
        (4, 'Semester 4'),
        (5, 'Semester 5'),
        (6, 'Semester 6'),
        (7, 'Semester 7'),
        (8, 'Semester 8'),
    ]
    
    # Course identification
    course_code = models.CharField(max_length=20, unique=True)
    course_name = models.CharField(max_length=200)
    course_type = models.CharField(max_length=20, choices=COURSE_TYPES, default='core')
    
    # Academic details
    credits = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(10)], default=3)
    semester = models.IntegerField(choices=SEMESTER_CHOICES)
    academic_year = models.CharField(max_length=20, help_text='e.g., 2024-2025')
    
    # Course information
    description = models.TextField(blank=True, null=True)
    syllabus = models.TextField(blank=True, null=True)
    
    # Faculty
    instructor = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='taught_courses',
        limit_choices_to={'user_type': 'faculty'}
    )
    
    # Schedule (can be linked to calendar events)
    schedule = models.JSONField(
        default=dict,
        blank=True,
        help_text='Course schedule (days, times, location)'
    )
    
    # Course settings
    is_active = models.BooleanField(default=True)
    color = models.CharField(max_length=7, default='#3b82f6', help_text='Hex color for UI')
    
    class Meta:
        verbose_name = 'Course'
        verbose_name_plural = 'Courses'
        ordering = ['semester', 'course_code']
        indexes = [
            models.Index(fields=['course_code']),
            models.Index(fields=['semester', 'academic_year']),
            models.Index(fields=['instructor']),
        ]
    
    def __str__(self):
        return f"{self.course_code} - {self.course_name}"


class CourseEnrollment(TimestampedModel):
    """Student enrollment in courses"""
    
    STATUS_CHOICES = [
        ('enrolled', 'Enrolled'),
        ('dropped', 'Dropped'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
    ]
    
    student = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='course_enrollments',
        limit_choices_to={'user_type': 'student'}
    )
    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        related_name='enrollments'
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='enrolled')
    enrollment_date = models.DateField(default=timezone.now)
    completion_date = models.DateField(blank=True, null=True)
    
    # Grade tracking
    final_grade = models.CharField(max_length=5, blank=True, null=True)
    grade_points = models.DecimalField(
        max_digits=4,
        decimal_places=2,
        blank=True,
        null=True,
        validators=[MinValueValidator(0), MaxValueValidator(10)]
    )
    
    class Meta:
        verbose_name = 'Course Enrollment'
        verbose_name_plural = 'Course Enrollments'
        unique_together = [['student', 'course']]
        indexes = [
            models.Index(fields=['student', 'status']),
            models.Index(fields=['course', 'status']),
        ]
    
    def __str__(self):
        return f"{self.student.username} - {self.course.course_code}"


class Assignment(TimestampedModel):
    """Assignment model"""
    
    ASSIGNMENT_TYPES = [
        ('homework', 'Homework'),
        ('project', 'Project'),
        ('lab_report', 'Lab Report'),
        ('essay', 'Essay'),
        ('presentation', 'Presentation'),
        ('quiz', 'Quiz'),
        ('midterm', 'Midterm'),
        ('final', 'Final Exam'),
        ('other', 'Other'),
    ]
    
    STATUS_CHOICES = [
        ('not_started', 'Not Started'),
        ('in_progress', 'In Progress'),
        ('submitted', 'Submitted'),
        ('graded', 'Graded'),
        ('late', 'Late'),
        ('missed', 'Missed'),
    ]
    
    # Assignment details
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    assignment_type = models.CharField(max_length=20, choices=ASSIGNMENT_TYPES, default='homework')
    
    # Course relationship
    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        related_name='assignments'
    )
    
    # Student (null if for all enrolled students)
    student = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='assignments',
        null=True,
        blank=True,
        limit_choices_to={'user_type': 'student'}
    )
    
    # Due dates
    assigned_date = models.DateTimeField(default=timezone.now)
    due_date = models.DateTimeField()
    late_submission_allowed = models.BooleanField(default=False)
    late_penalty_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    
    # Submission
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='not_started')
    submitted_at = models.DateTimeField(blank=True, null=True)
    submission_link = models.URLField(blank=True, null=True)
    submission_file = models.FileField(upload_to='assignments/', blank=True, null=True)
    
    # Grading
    max_score = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        default=100,
        validators=[MinValueValidator(0)]
    )
    score = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        blank=True,
        null=True,
        validators=[MinValueValidator(0)]
    )
    weight = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text='Weight percentage in final grade'
    )
    feedback = models.TextField(blank=True, null=True)
    graded_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='graded_assignments',
        limit_choices_to={'user_type': 'faculty'}
    )
    graded_at = models.DateTimeField(blank=True, null=True)
    
    # Reminders
    reminder_sent = models.BooleanField(default=False)
    
    class Meta:
        verbose_name = 'Assignment'
        verbose_name_plural = 'Assignments'
        ordering = ['due_date']
        indexes = [
            models.Index(fields=['course', 'due_date']),
            models.Index(fields=['student', 'status']),
            models.Index(fields=['due_date', 'status']),
        ]
    
    def __str__(self):
        return f"{self.course.course_code} - {self.title}"
    
    @property
    def is_overdue(self):
        return timezone.now() > self.due_date and self.status not in ['submitted', 'graded', 'missed']
    
    @property
    def days_until_due(self):
        delta = self.due_date - timezone.now()
        return delta.days
    
    @property
    def percentage_score(self):
        if self.score is None or self.max_score == 0:
            return None
        return (self.score / self.max_score) * 100


class Grade(TimestampedModel):
    """Grade model for tracking course grades"""
    
    GRADE_CHOICES = [
        ('S', 'S (Outstanding)'),
        ('A', 'A (Excellent)'),
        ('B', 'B (Very Good)'),
        ('C', 'C (Good)'),
        ('D', 'D (Satisfactory)'),
        ('E', 'E (Pass)'),
        ('F', 'F (Fail)'),
        ('I', 'I (Incomplete)'),
        ('W', 'W (Withdrawn)'),
    ]
    
    # Relationships
    student = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='grades',
        limit_choices_to={'user_type': 'student'}
    )
    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        related_name='grades'
    )
    
    # Grade information
    grade = models.CharField(max_length=2, choices=GRADE_CHOICES, blank=True, null=True)
    grade_points = models.DecimalField(
        max_digits=4,
        decimal_places=2,
        blank=True,
        null=True,
        validators=[MinValueValidator(0), MaxValueValidator(10)]
    )
    percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        blank=True,
        null=True,
        validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    
    # Grade components
    assignment_scores = models.JSONField(
        default=dict,
        blank=True,
        help_text='Breakdown of scores by assignment type'
    )
    
    # Metadata
    semester = models.IntegerField(blank=True, null=True)
    academic_year = models.CharField(max_length=20, blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    
    # Calculated fields
    is_final = models.BooleanField(default=False)
    calculated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Grade'
        verbose_name_plural = 'Grades'
        unique_together = [['student', 'course', 'semester', 'academic_year']]
        indexes = [
            models.Index(fields=['student', 'semester']),
            models.Index(fields=['course', 'semester']),
            models.Index(fields=['grade']),
        ]
        ordering = ['-semester', '-academic_year']
    
    def __str__(self):
        return f"{self.student.username} - {self.course.course_code} - {self.grade or 'N/A'}"


class AcademicReminder(TimestampedModel):
    """Academic reminders for assignments, exams, etc."""
    
    REMINDER_TYPES = [
        ('assignment_due', 'Assignment Due'),
        ('exam', 'Exam'),
        ('class', 'Class'),
        ('deadline', 'Deadline'),
        ('grade_release', 'Grade Release'),
        ('course_registration', 'Course Registration'),
        ('other', 'Other'),
    ]
    
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]
    
    # Reminder details
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    reminder_type = models.CharField(max_length=30, choices=REMINDER_TYPES, default='other')
    
    # User
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='academic_reminders'
    )
    
    # Related objects
    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        related_name='reminders',
        null=True,
        blank=True
    )
    assignment = models.ForeignKey(
        Assignment,
        on_delete=models.CASCADE,
        related_name='reminders',
        null=True,
        blank=True
    )
    
    # Timing
    reminder_date = models.DateTimeField()
    is_recurring = models.BooleanField(default=False)
    recurrence_pattern = models.CharField(max_length=20, blank=True, null=True)
    
    # Status
    is_completed = models.BooleanField(default=False)
    completed_at = models.DateTimeField(blank=True, null=True)
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    
    # Notification
    notification_sent = models.BooleanField(default=False)
    notification_sent_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        verbose_name = 'Academic Reminder'
        verbose_name_plural = 'Academic Reminders'
        ordering = ['reminder_date']
        indexes = [
            models.Index(fields=['user', 'reminder_date']),
            models.Index(fields=['course', 'reminder_date']),
            models.Index(fields=['is_completed', 'reminder_date']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.title}"
    
    @property
    def is_overdue(self):
        return timezone.now() > self.reminder_date and not self.is_completed
    
    @property
    def days_until_reminder(self):
        delta = self.reminder_date - timezone.now()
        return delta.days

















