"""
Serializers for academic planner app
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Course, CourseEnrollment, Assignment, Grade, AcademicReminder

User = get_user_model()


class CourseSerializer(serializers.ModelSerializer):
    """Serializer for Course"""
    instructor_name = serializers.SerializerMethodField()
    enrollment_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Course
        fields = [
            'id', 'course_code', 'course_name', 'course_type',
            'credits', 'semester', 'academic_year', 'description',
            'syllabus', 'instructor', 'instructor_name', 'schedule',
            'is_active', 'color', 'enrollment_count',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']
    
    def get_instructor_name(self, obj):
        if obj.instructor:
            return f"{obj.instructor.first_name} {obj.instructor.last_name}".strip() or obj.instructor.username
        return None
    
    def get_enrollment_count(self, obj):
        return obj.enrollments.filter(status='enrolled').count()


class CourseEnrollmentSerializer(serializers.ModelSerializer):
    """Serializer for CourseEnrollment"""
    course = CourseSerializer(read_only=True)
    course_id = serializers.IntegerField(write_only=True)
    student_name = serializers.SerializerMethodField()
    
    class Meta:
        model = CourseEnrollment
        fields = [
            'id', 'student', 'student_name', 'course', 'course_id',
            'status', 'enrollment_date', 'completion_date',
            'final_grade', 'grade_points', 'created_at', 'updated_at',
        ]
        read_only_fields = ['student', 'created_at', 'updated_at']
    
    def get_student_name(self, obj):
        return f"{obj.student.first_name} {obj.student.last_name}".strip() or obj.student.username
    
    def validate_course_id(self, value):
        """Validate that the course exists"""
        from .models import Course
        try:
            course = Course.objects.get(id=value, is_active=True)
        except Course.DoesNotExist:
            raise serializers.ValidationError(f"Course with id {value} does not exist or is not active.")
        return value
    
    def create(self, validated_data):
        """Create enrollment with proper course mapping"""
        course_id = validated_data.pop('course_id')
        from .models import Course
        try:
            course = Course.objects.get(id=course_id)
        except Course.DoesNotExist:
            raise serializers.ValidationError(f"Course with id {course_id} does not exist.")
        
        # Check if enrollment already exists
        student = validated_data.get('student') or self.context['request'].user
        if CourseEnrollment.objects.filter(student=student, course=course).exists():
            raise serializers.ValidationError("You are already enrolled in this course.")
        
        validated_data['course'] = course
        return super().create(validated_data)


class AssignmentSerializer(serializers.ModelSerializer):
    """Serializer for Assignment"""
    course = CourseSerializer(read_only=True)
    course_id = serializers.IntegerField(write_only=True)
    student_name = serializers.SerializerMethodField()
    is_overdue = serializers.BooleanField(read_only=True)
    days_until_due = serializers.IntegerField(read_only=True)
    percentage_score = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    
    class Meta:
        model = Assignment
        fields = [
            'id', 'title', 'description', 'assignment_type',
            'course', 'course_id', 'student', 'student_name',
            'assigned_date', 'due_date', 'late_submission_allowed',
            'late_penalty_percentage', 'status', 'submitted_at',
            'submission_link', 'submission_file', 'max_score',
            'score', 'weight', 'feedback', 'graded_by', 'graded_at',
            'reminder_sent', 'is_overdue', 'days_until_due',
            'percentage_score', 'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at', 'submitted_at', 'graded_at']
    
    def get_student_name(self, obj):
        if obj.student:
            return f"{obj.student.first_name} {obj.student.last_name}".strip() or obj.student.username
        return None
    
    def validate_course_id(self, value):
        """Validate that the course exists"""
        from .models import Course
        try:
            course = Course.objects.get(id=value, is_active=True)
        except Course.DoesNotExist:
            raise serializers.ValidationError(f"Course with id {value} does not exist or is not active.")
        return value
    
    def create(self, validated_data):
        """Create assignment with proper course mapping"""
        course_id = validated_data.pop('course_id')
        from .models import Course
        try:
            course = Course.objects.get(id=course_id)
        except Course.DoesNotExist:
            raise serializers.ValidationError(f"Course with id {course_id} does not exist.")
        
        validated_data['course'] = course
        return super().create(validated_data)


class GradeSerializer(serializers.ModelSerializer):
    """Serializer for Grade"""
    course = CourseSerializer(read_only=True)
    course_id = serializers.IntegerField(write_only=True)
    student_name = serializers.SerializerMethodField()
    
    class Meta:
        model = Grade
        fields = [
            'id', 'student', 'student_name', 'course', 'course_id',
            'grade', 'grade_points', 'percentage', 'assignment_scores',
            'semester', 'academic_year', 'notes', 'is_final',
            'calculated_at', 'created_at', 'updated_at',
        ]
        read_only_fields = ['student', 'calculated_at', 'created_at', 'updated_at']
    
    def get_student_name(self, obj):
        return f"{obj.student.first_name} {obj.student.last_name}".strip() or obj.student.username


class AcademicReminderSerializer(serializers.ModelSerializer):
    """Serializer for AcademicReminder"""
    course = CourseSerializer(read_only=True)
    course_id = serializers.IntegerField(write_only=True, required=False, allow_null=True)
    assignment = AssignmentSerializer(read_only=True)
    assignment_id = serializers.IntegerField(write_only=True, required=False, allow_null=True)
    is_overdue = serializers.BooleanField(read_only=True)
    days_until_reminder = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = AcademicReminder
        fields = [
            'id', 'title', 'description', 'reminder_type',
            'user', 'course', 'course_id', 'assignment', 'assignment_id',
            'reminder_date', 'is_recurring', 'recurrence_pattern',
            'is_completed', 'completed_at', 'priority',
            'notification_sent', 'notification_sent_at',
            'is_overdue', 'days_until_reminder',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['user', 'created_at', 'updated_at', 'completed_at', 'notification_sent_at']


class CourseSummarySerializer(serializers.Serializer):
    """Serializer for course summary statistics"""
    course = CourseSerializer()
    enrollment_count = serializers.IntegerField()
    assignment_count = serializers.IntegerField()
    upcoming_assignments = serializers.IntegerField()
    average_grade = serializers.DecimalField(max_digits=5, decimal_places=2, allow_null=True)


class AcademicDashboardSerializer(serializers.Serializer):
    """Serializer for academic dashboard data"""
    enrolled_courses = serializers.IntegerField()
    active_assignments = serializers.IntegerField()
    overdue_assignments = serializers.IntegerField()
    upcoming_deadlines = serializers.IntegerField()
    current_gpa = serializers.DecimalField(max_digits=4, decimal_places=2, allow_null=True)
    total_credits = serializers.IntegerField()
    completed_credits = serializers.IntegerField()














