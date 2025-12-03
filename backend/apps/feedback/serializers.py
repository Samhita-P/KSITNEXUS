"""
Serializers for feedback app
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import FacultyFeedback, FacultyFeedbackSummary

User = get_user_model()


class FacultyFeedbackSerializer(serializers.ModelSerializer):
    """Faculty feedback serializer"""
    faculty_id = serializers.IntegerField(source='faculty.id', read_only=True)
    faculty_name = serializers.CharField(source='faculty.get_full_name', read_only=True)
    faculty_department = serializers.CharField(source='faculty.faculty_profile.department', read_only=True)
    student_id = serializers.SerializerMethodField()
    student_name = serializers.SerializerMethodField()
    teaching_rating = serializers.FloatField(source='teaching_quality')
    communication_rating = serializers.FloatField(source='communication')
    punctuality_rating = serializers.FloatField(source='punctuality')
    helpfulness_rating = serializers.FloatField(source='helpfulness')
    comment = serializers.CharField(source='additional_comments')
    submitted_at = serializers.DateTimeField(read_only=True)
    updated_at = serializers.DateTimeField(read_only=True)
    
    def get_student_id(self, obj):
        return obj.submitted_by.id if obj.submitted_by else 0
    
    def get_student_name(self, obj):
        if obj.submitted_by and not obj.is_anonymous:
            return obj.submitted_by.get_full_name()
        return 'Anonymous'
    
    class Meta:
        model = FacultyFeedback
        fields = [
            'id', 'faculty_id', 'faculty_name', 'faculty_department', 'student_id', 'student_name',
            'semester', 'teaching_rating', 'communication_rating', 'punctuality_rating', 
            'helpfulness_rating', 'overall_rating', 'comment', 'course_name', 'is_anonymous', 
            'submitted_at', 'updated_at'
        ]
        read_only_fields = ['id', 'overall_rating', 'submitted_at', 'updated_at']


class FacultyFeedbackCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating faculty feedback"""
    faculty_id = serializers.IntegerField(write_only=True)
    teaching_rating = serializers.IntegerField(source='teaching_quality')
    communication_rating = serializers.IntegerField(source='communication')
    punctuality_rating = serializers.IntegerField(source='punctuality')
    subject_knowledge_rating = serializers.IntegerField(source='subject_knowledge')
    helpfulness_rating = serializers.IntegerField(source='helpfulness')
    comment = serializers.CharField(source='additional_comments', required=False, allow_blank=True)
    
    class Meta:
        model = FacultyFeedback
        fields = [
            'faculty_id', 'teaching_rating', 'communication_rating', 'punctuality_rating',
            'subject_knowledge_rating', 'helpfulness_rating', 'comment', 'course_name', 'semester', 'is_anonymous'
        ]
    
    def validate_faculty_id(self, value):
        """Validate faculty exists and is active"""
        try:
            faculty = User.objects.get(id=value, user_type='faculty')
            if not hasattr(faculty, 'faculty_profile') or not faculty.faculty_profile.is_active:
                raise serializers.ValidationError("Selected faculty is not active")
            return value
        except User.DoesNotExist:
            raise serializers.ValidationError("Selected faculty does not exist")
    
    def validate(self, attrs):
        """Validate rating values"""
        rating_fields = [
            'teaching_quality', 'communication', 'punctuality', 'subject_knowledge', 'helpfulness'
        ]
        
        for field in rating_fields:
            if field in attrs and (attrs[field] < 1 or attrs[field] > 5):
                raise serializers.ValidationError(f"{field} rating must be between 1 and 5")
        
        return attrs
    
    def create(self, validated_data):
        """Create feedback with faculty from faculty_id"""
        faculty_id = validated_data.pop('faculty_id')
        faculty = User.objects.get(id=faculty_id)
        validated_data['faculty'] = faculty
        
        # Always set submitted_by to the current user if they are a student
        # This allows tracking feedback in "My Feedback" even if anonymous
        # The is_anonymous flag only controls whether the student's name is shown
        request = self.context.get('request')
        if request and request.user.is_authenticated and request.user.user_type == 'student':
            validated_data['submitted_by'] = request.user
        
        return super().create(validated_data)


class FacultyFeedbackSummarySerializer(serializers.ModelSerializer):
    """Faculty feedback summary serializer"""
    faculty_id = serializers.IntegerField(source='faculty.id', read_only=True)
    faculty_name = serializers.SerializerMethodField()
    faculty_department = serializers.SerializerMethodField()
    average_teaching_rating = serializers.FloatField(source='avg_teaching_quality', read_only=True)
    average_communication_rating = serializers.FloatField(source='avg_communication', read_only=True)
    average_punctuality_rating = serializers.FloatField(source='avg_punctuality', read_only=True)
    average_helpfulness_rating = serializers.FloatField(source='avg_helpfulness', read_only=True)
    average_overall_rating = serializers.FloatField(source='avg_overall_rating', read_only=True)
    total_feedbacks = serializers.IntegerField(source='total_feedback_count', read_only=True)
    semester_feedbacks = serializers.SerializerMethodField()
    recent_feedbacks = serializers.SerializerMethodField()
    ratings_by_semester = serializers.SerializerMethodField()
    
    def get_faculty_name(self, obj):
        try:
            if hasattr(obj.faculty, 'get_full_name'):
                name = obj.faculty.get_full_name()
                return name if name else obj.faculty.username
            return obj.faculty.username
        except Exception as e:
            print(f"Error getting faculty name: {e}")
            return obj.faculty.username if hasattr(obj, 'faculty') else ''
    
    def get_faculty_department(self, obj):
        try:
            if hasattr(obj.faculty, 'faculty_profile') and obj.faculty.faculty_profile:
                return obj.faculty.faculty_profile.department or ''
            return ''
        except Exception as e:
            print(f"Error getting faculty department: {e}")
            return ''
    
    def get_semester_feedbacks(self, obj):
        try:
            # Count feedbacks from current semester (assuming semester is stored as string)
            from django.utils import timezone
            from .models import FacultyFeedback
            current_year = timezone.now().year
            # This is a simplified version - you may need to adjust based on your semester logic
            return FacultyFeedback.objects.filter(
                faculty=obj.faculty,
                submitted_at__year=current_year
            ).count()
        except Exception as e:
            print(f"Error getting semester feedbacks: {e}")
            return 0
    
    def get_recent_feedbacks(self, obj):
        try:
            # Get recent feedbacks (last 5)
            from .models import FacultyFeedback
            recent = FacultyFeedback.objects.filter(
                faculty=obj.faculty
            ).order_by('-submitted_at')[:5]
            return FacultyFeedbackSerializer(recent, many=True).data
        except Exception as e:
            print(f"Error getting recent feedbacks: {e}")
            import traceback
            traceback.print_exc()
            return []
    
    def get_ratings_by_semester(self, obj):
        try:
            # Group ratings by semester
            from django.db.models import Avg
            from .models import FacultyFeedback
            feedbacks = FacultyFeedback.objects.filter(faculty=obj.faculty)
            ratings = {}
            for feedback in feedbacks:
                semester = feedback.semester or 'Unknown'
                if semester not in ratings:
                    ratings[semester] = {
                        'count': 0,
                        'total': 0.0,
                    }
                ratings[semester]['count'] += 1
                ratings[semester]['total'] += feedback.overall_rating
            
            # Calculate averages
            result = {}
            for semester, data in ratings.items():
                result[semester] = data['total'] / data['count'] if data['count'] > 0 else 0.0
            
            return result
        except Exception as e:
            print(f"Error getting ratings by semester: {e}")
            import traceback
            traceback.print_exc()
            return {}
    
    class Meta:
        model = FacultyFeedbackSummary
        fields = [
            'faculty_id', 'faculty_name', 'faculty_department',
            'average_teaching_rating', 'average_communication_rating',
            'average_punctuality_rating', 'average_helpfulness_rating',
            'average_overall_rating', 'total_feedbacks', 'semester_feedbacks',
            'recent_feedbacks', 'ratings_by_semester', 'last_updated'
        ]


class FacultyListSerializer(serializers.ModelSerializer):
    """Simplified faculty serializer for feedback form"""
    name = serializers.SerializerMethodField()
    designation = serializers.SerializerMethodField()
    department = serializers.SerializerMethodField()
    email = serializers.SerializerMethodField()
    profile_picture = serializers.SerializerMethodField()
    subjects = serializers.SerializerMethodField()
    average_rating = serializers.SerializerMethodField()
    total_feedbacks = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'name', 'designation', 'department', 'email', 'profile_picture', 'subjects', 'average_rating', 'total_feedbacks']
    
    def get_name(self, obj):
        return obj.get_full_name()
    
    def get_designation(self, obj):
        if hasattr(obj, 'faculty_profile'):
            return obj.faculty_profile.designation
        return ''
    
    def get_department(self, obj):
        if hasattr(obj, 'faculty_profile'):
            return obj.faculty_profile.department
        return ''
    
    def get_email(self, obj):
        return obj.email
    
    def get_profile_picture(self, obj):
        """Return absolute URL for profile picture"""
        if hasattr(obj, 'faculty_profile') and obj.faculty_profile.profile_picture:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.faculty_profile.profile_picture.url)
            return obj.faculty_profile.profile_picture.url
        return None
    
    def get_subjects(self, obj):
        if hasattr(obj, 'faculty_profile'):
            return obj.faculty_profile.subjects_taught
        return []
    
    def get_average_rating(self, obj):
        if hasattr(obj, 'feedback_summary'):
            return obj.feedback_summary.avg_overall_rating
        return None
    
    def get_total_feedbacks(self, obj):
        if hasattr(obj, 'feedback_summary'):
            return obj.feedback_summary.total_feedback_count
        return 0


class FeedbackStatsSerializer(serializers.Serializer):
    """Feedback statistics serializer"""
    total_feedback = serializers.IntegerField()
    average_rating = serializers.FloatField()
    feedback_by_rating = serializers.DictField()
    top_rated_faculty = serializers.ListField()
    recent_feedback = serializers.ListField()
