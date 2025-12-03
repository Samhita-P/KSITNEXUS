"""
Serializers for accounts app
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Student, Faculty, OTPVerification, TwoFactorAuth, DeviceSession
from .otp_service import OTPService

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    """User serializer"""
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'user_type', 'phone_number', 'is_verified', 'date_joined']
        read_only_fields = ['id', 'date_joined']


class StudentProfileNestedSerializer(serializers.ModelSerializer):
    """Nested student profile serializer (without user field to avoid circular reference)"""
    profile_picture = serializers.SerializerMethodField()
    
    class Meta:
        model = Student
        fields = [
            'id', 'student_id', 'usn', 'year_of_study', 'branch', 'section',
            'profile_picture', 'bio', 'interests', 'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_profile_picture(self, obj):
        """Return absolute URL for profile picture"""
        if obj.profile_picture:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.profile_picture.url)
            return obj.profile_picture.url
        return None


class StudentSerializer(serializers.ModelSerializer):
    """Student profile serializer"""
    user = UserSerializer(read_only=True)
    profile_picture = serializers.SerializerMethodField()
    
    class Meta:
        model = Student
        fields = [
            'id', 'user', 'student_id', 'usn', 'year_of_study', 'branch', 'section',
            'profile_picture', 'bio', 'interests', 'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_profile_picture(self, obj):
        """Return absolute URL for profile picture"""
        if obj.profile_picture:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.profile_picture.url)
            return obj.profile_picture.url
        return None
    
    def validate_student_id(self, value):
        """Validate student ID if provided"""
        if value and Student.objects.filter(student_id=value).exclude(pk=self.instance.pk if self.instance else None).exists():
            raise serializers.ValidationError("Student ID already exists")
        return value
    
    def validate_year_of_study(self, value):
        """Validate year of study if provided"""
        if value and (value < 1 or value > 5):
            raise serializers.ValidationError("Year of study must be between 1 and 5")
        return value


class FacultyProfileNestedSerializer(serializers.ModelSerializer):
    """Nested faculty profile serializer (without user field to avoid circular reference)"""
    profile_picture = serializers.SerializerMethodField()
    
    class Meta:
        model = Faculty
        fields = [
            'id', 'employee_id', 'designation', 'department',
            'subjects_taught', 'research_areas', 'profile_picture', 'bio',
            'is_mentor_available', 'office_hours', 'office_location',
            'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_profile_picture(self, obj):
        """Return absolute URL for profile picture"""
        if obj.profile_picture:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.profile_picture.url)
            return obj.profile_picture.url
        return None


class FacultySerializer(serializers.ModelSerializer):
    """Faculty profile serializer"""
    user = UserSerializer(read_only=True)
    profile_picture = serializers.SerializerMethodField()
    
    class Meta:
        model = Faculty
        fields = [
            'id', 'user', 'employee_id', 'designation', 'department',
            'subjects_taught', 'research_areas', 'profile_picture', 'bio',
            'is_mentor_available', 'office_hours', 'office_location',
            'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_profile_picture(self, obj):
        """Return absolute URL for profile picture"""
        if obj.profile_picture:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.profile_picture.url)
            return obj.profile_picture.url
        return None


class UserProfileSerializer(serializers.ModelSerializer):
    """User profile serializer with student/faculty profile data"""
    student_profile = StudentProfileNestedSerializer(read_only=True)
    faculty_profile = FacultyProfileNestedSerializer(read_only=True)
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'user_type', 'phone_number', 'is_verified', 'date_joined', 'student_profile', 'faculty_profile']
        read_only_fields = ['id', 'date_joined', 'student_profile', 'faculty_profile']


class StudentCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating student profile"""
    
    class Meta:
        model = Student
        fields = [
            'student_id', 'usn', 'year_of_study', 'branch', 'section',
            'profile_picture', 'bio', 'interests'
        ]
    
    def validate_student_id(self, value):
        """Validate student ID uniqueness if provided"""
        if value and Student.objects.filter(student_id=value).exists():
            raise serializers.ValidationError("Student ID already exists")
        return value
    
    def validate_year_of_study(self, value):
        """Validate year of study if provided"""
        if value and (value < 1 or value > 5):
            raise serializers.ValidationError("Year of study must be between 1 and 5")
        return value
    
    def validate_usn(self, value):
        """Validate USN exists in AllowedUSN table"""
        if value:
            from .models import AllowedUSN
            usn_upper = value.upper().strip()
            
            # Check if USN exists in AllowedUSN table
            if not AllowedUSN.objects.filter(usn=usn_upper).exists():
                raise serializers.ValidationError("Invalid USN. You are not eligible to register.")
            
            # Check if USN is already registered by another student
            from .models import Student
            existing_student = Student.objects.filter(usn=usn_upper).exclude(
                pk=self.instance.pk if self.instance else None
            ).first()
            if existing_student:
                raise serializers.ValidationError("This USN is already registered. Please contact support if you believe this is an error.")
            
            return usn_upper
        return value
    
    def validate(self, attrs):
        """Provide default values for required fields"""
        from django.utils import timezone
        
        # Provide default student_id if not provided
        if not attrs.get('student_id'):
            attrs['student_id'] = f"STU_{timezone.now().strftime('%Y%m%d%H%M%S')}"
        
        # Provide default year_of_study if not provided
        if not attrs.get('year_of_study'):
            attrs['year_of_study'] = 1
            
        # Provide default branch if not provided
        if not attrs.get('branch'):
            attrs['branch'] = 'General'
            
        return attrs


class FacultyCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating faculty profile"""
    
    class Meta:
        model = Faculty
        fields = [
            'employee_id', 'designation', 'department', 'subjects_taught',
            'research_areas', 'profile_picture', 'bio', 'is_mentor_available',
            'office_hours', 'office_location'
        ]
    
    def validate_employee_id(self, value):
        """Validate employee ID uniqueness"""
        if Faculty.objects.filter(employee_id=value).exists():
            raise serializers.ValidationError("Employee ID already exists")
        return value


class OTPRequestSerializer(serializers.Serializer):
    """Serializer for OTP request"""
    phone_number = serializers.CharField(max_length=15)
    
    def validate_phone_number(self, value):
        """Validate phone number format"""
        if not value.startswith('+') and not value.isdigit():
            raise serializers.ValidationError("Invalid phone number format")
        return value


class OTPVerifySerializer(serializers.Serializer):
    """Serializer for OTP verification"""
    phone_number = serializers.CharField(max_length=15)
    otp_code = serializers.CharField(max_length=6, min_length=6)
    
    def validate_otp_code(self, value):
        """Validate OTP code format"""
        if not value.isdigit():
            raise serializers.ValidationError("OTP code must contain only digits")
        return value


class ProfileUpdateSerializer(serializers.Serializer):
    """Serializer for updating user profile"""
    first_name = serializers.CharField(max_length=30, required=False)
    last_name = serializers.CharField(max_length=30, required=False)
    phone_number = serializers.CharField(max_length=15, required=False)
    bio = serializers.CharField(required=False, allow_blank=True)
    interests = serializers.ListField(
        child=serializers.CharField(max_length=100),
        required=False
    )
    
    def validate_phone_number(self, value):
        """Validate phone number format"""
        if value and not (value.startswith('+') or value.isdigit()):
            raise serializers.ValidationError("Invalid phone number format")
        return value


class PasswordChangeSerializer(serializers.Serializer):
    """Serializer for password change"""
    old_password = serializers.CharField()
    new_password = serializers.CharField(min_length=8)
    confirm_password = serializers.CharField()
    
    def validate(self, attrs):
        """Validate password confirmation"""
        if attrs['new_password'] != attrs['confirm_password']:
            raise serializers.ValidationError("Passwords do not match")
        return attrs


# Two-Factor Authentication Serializers
class TwoFactorSetupSerializer(serializers.Serializer):
    """Serializer for 2FA setup"""
    pass


class TwoFactorVerifySerializer(serializers.Serializer):
    """Serializer for 2FA verification"""
    code = serializers.CharField(max_length=6, min_length=6)
    
    def validate_code(self, value):
        """Validate verification code format"""
        if not value.isdigit():
            raise serializers.ValidationError("Code must contain only digits")
        return value


class TwoFactorDisableSerializer(serializers.Serializer):
    """Serializer for disabling 2FA"""
    password = serializers.CharField()
    code = serializers.CharField(max_length=6, min_length=6)


class BackupCodeSerializer(serializers.Serializer):
    """Serializer for backup code verification"""
    code = serializers.CharField(max_length=8, min_length=8)
    
    def validate_code(self, value):
        """Validate backup code format"""
        if not value.isalnum():
            raise serializers.ValidationError("Backup code must be alphanumeric")
        return value.upper()


class TwoFactorAuthSerializer(serializers.ModelSerializer):
    """Serializer for TwoFactorAuth model"""
    
    class Meta:
        model = TwoFactorAuth
        fields = ['is_enabled', 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at']


class DeviceSessionSerializer(serializers.ModelSerializer):
    """Serializer for DeviceSession model"""
    
    class Meta:
        model = DeviceSession
        fields = [
            'id', 'device_name', 'device_type', 'ip_address', 
            'last_activity', 'created_at', 'is_active'
        ]
        read_only_fields = ['id', 'created_at']


class LoginWith2FASerializer(serializers.Serializer):
    """Serializer for login with 2FA"""
    username = serializers.CharField()
    password = serializers.CharField()
    code = serializers.CharField(max_length=6, min_length=6, required=False)
    backup_code = serializers.CharField(max_length=8, min_length=8, required=False)
    device_id = serializers.CharField(max_length=255)
    device_name = serializers.CharField(max_length=255)
    device_type = serializers.CharField(max_length=50)
    
    def validate(self, attrs):
        """Validate that either code or backup_code is provided"""
        if not attrs.get('code') and not attrs.get('backup_code'):
            raise serializers.ValidationError("Either verification code or backup code is required")
        return attrs