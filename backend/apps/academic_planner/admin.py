from django.contrib import admin
from .models import Course, CourseEnrollment, Assignment, Grade, AcademicReminder


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ['course_code', 'course_name', 'course_type', 'semester', 'academic_year', 'instructor', 'is_active']
    list_filter = ['course_type', 'semester', 'academic_year', 'is_active']
    search_fields = ['course_code', 'course_name', 'instructor__username']
    ordering = ['semester', 'course_code']


@admin.register(CourseEnrollment)
class CourseEnrollmentAdmin(admin.ModelAdmin):
    list_display = ['student', 'course', 'status', 'enrollment_date', 'final_grade', 'grade_points']
    list_filter = ['status', 'enrollment_date', 'course__semester']
    search_fields = ['student__username', 'course__course_code']
    ordering = ['-enrollment_date']


@admin.register(Assignment)
class AssignmentAdmin(admin.ModelAdmin):
    list_display = ['title', 'course', 'student', 'assignment_type', 'due_date', 'status', 'score']
    list_filter = ['assignment_type', 'status', 'due_date', 'course__semester']
    search_fields = ['title', 'course__course_code', 'student__username']
    ordering = ['due_date']
    readonly_fields = ['submitted_at', 'graded_at']


@admin.register(Grade)
class GradeAdmin(admin.ModelAdmin):
    list_display = ['student', 'course', 'grade', 'grade_points', 'percentage', 'semester', 'academic_year', 'is_final']
    list_filter = ['grade', 'semester', 'academic_year', 'is_final']
    search_fields = ['student__username', 'course__course_code']
    ordering = ['-semester', '-academic_year']


@admin.register(AcademicReminder)
class AcademicReminderAdmin(admin.ModelAdmin):
    list_display = ['user', 'title', 'reminder_type', 'reminder_date', 'is_completed', 'priority']
    list_filter = ['reminder_type', 'is_completed', 'priority', 'reminder_date']
    search_fields = ['user__username', 'title', 'course__course_code']
    ordering = ['reminder_date']
    readonly_fields = ['completed_at', 'notification_sent_at']

















