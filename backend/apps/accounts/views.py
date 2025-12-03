"""
Views for accounts app
"""
from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model, authenticate
from django.shortcuts import get_object_or_404
from .models import Student, Faculty, OTPVerification
from .serializers import (
    UserSerializer, UserProfileSerializer, StudentSerializer, FacultySerializer,
    StudentCreateSerializer, FacultyCreateSerializer,
    OTPRequestSerializer, OTPVerifySerializer,
    ProfileUpdateSerializer, PasswordChangeSerializer,
    TwoFactorSetupSerializer, TwoFactorVerifySerializer, TwoFactorDisableSerializer,
    BackupCodeSerializer, TwoFactorAuthSerializer, DeviceSessionSerializer,
    LoginWith2FASerializer
)
from .otp_service import OTPService
from .two_factor_service import TwoFactorService, DeviceSessionService
from .jwt_authentication import set_jwt_cookies, clear_jwt_cookies, get_tokens_for_user
from .services.sso_service import SSOService
from django.core.cache import cache

User = get_user_model()


class UserProfileView(generics.RetrieveUpdateAPIView):
    """User profile view"""
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    queryset = User.objects.select_related('student_profile', 'faculty_profile').all()
    
    def get_object(self):
        cache_key = f'user_profile:{self.request.user.pk}'
        
        # Try to get from cache
        user = cache.get(cache_key)
        if user is None:
            user = User.objects.select_related('student_profile', 'faculty_profile').get(pk=self.request.user.pk)
            cache.set(cache_key, user, 300)  # Cache for 5 minutes
        
        return user
    
    def update(self, request, *args, **kwargs):
        # Invalidate cache when updating profile
        cache_key = f'user_profile:{request.user.pk}'
        cache.delete(cache_key)
        # Also invalidate student/faculty profile cache
        if hasattr(request.user, 'student_profile'):
            cache.delete(f'student_profile:{request.user.student_profile.id}')
        if hasattr(request.user, 'faculty_profile'):
            cache.delete(f'faculty_profile:{request.user.faculty_profile.id}')
        response = super().update(request, *args, **kwargs)
        # Invalidate cache again after update to ensure fresh data
        cache.delete(cache_key)
        return response


class StudentProfileView(generics.RetrieveUpdateAPIView):
    """Student profile view"""
    serializer_class = StudentSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def get_object(self):
        try:
            return self.request.user.student_profile
        except Student.DoesNotExist:
            return None
    
    def get(self, request, *args, **kwargs):
        if not hasattr(request.user, 'student_profile'):
            return Response(
                {'detail': 'Student profile not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        return super().get(request, *args, **kwargs)
    
    def patch(self, request, *args, **kwargs):
        try:
            # Check if student profile exists
            if not hasattr(request.user, 'student_profile'):
                # If no student profile exists, create one with the provided data
                create_serializer = StudentCreateSerializer(data=request.data)
                if create_serializer.is_valid():
                    student = create_serializer.save(user=request.user)
                    return Response(StudentSerializer(student).data, status=status.HTTP_201_CREATED)
                else:
                    return Response(create_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
            # Handle partial updates with optional fields
            instance = self.get_object()
            print(f"Updating student profile {instance.id} with data: {request.data}")  # Debug logging
            
            # Invalidate user profile cache to ensure fresh data
            cache_key = f'user_profile:{request.user.pk}'
            cache.delete(cache_key)
            if instance:
                cache.delete(f'student_profile:{instance.id}')
            
            serializer = self.get_serializer(instance=instance, data=request.data, partial=True)
            if serializer.is_valid():
                updated_student = serializer.save()
                print(f"Student profile updated successfully: {updated_student.id}")  # Debug logging
                
                # Invalidate cache again after update
                cache.delete(cache_key)
                cache.delete(f'student_profile:{updated_student.id}')
                
                # Return full student data with user
                response_data = StudentSerializer(updated_student).data
                return Response(response_data, status=status.HTTP_200_OK)
            print(f"Serializer errors: {serializer.errors}")  # Debug logging
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            print(f"Error in StudentProfileView.patch: {e}")  # Debug logging
            return Response(
                {'detail': f'An error occurred: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class FacultyProfileView(generics.RetrieveUpdateAPIView):
    """Faculty profile view"""
    serializer_class = FacultySerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def get_object(self):
        try:
            return self.request.user.faculty_profile
        except Faculty.DoesNotExist:
            return None
    
    def get(self, request, *args, **kwargs):
        if not hasattr(request.user, 'faculty_profile'):
            return Response(
                {'detail': 'Faculty profile not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        return super().get(request, *args, **kwargs)


class StudentCreateView(generics.CreateAPIView):
    """Create student profile"""
    serializer_class = StudentCreateSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def perform_create(self, serializer):
        # Provide default values for required fields if not provided
        print(f"Creating student profile with data: {serializer.validated_data}")  # Debug logging
        
        # Save with user and any default values
        student = serializer.save(user=self.request.user)
        print(f"Student profile created successfully: {student.id}")  # Debug logging


class FacultyCreateView(generics.CreateAPIView):
    """Create faculty profile"""
    serializer_class = FacultyCreateSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def request_otp(request):
    """Request OTP for phone verification"""
    serializer = OTPRequestSerializer(data=request.data)
    if serializer.is_valid():
        phone_number = serializer.validated_data['phone_number']
        
        # Send OTP
        otp_verification = OTPService.send_otp(phone_number, request.user if request.user.is_authenticated else None)
        
        return Response({
            'message': 'OTP sent successfully',
            'phone_number': phone_number,
            'expires_at': otp_verification.expires_at
        })
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def verify_otp(request):
    """Verify OTP"""
    serializer = OTPVerifySerializer(data=request.data)
    if serializer.is_valid():
        phone_number = serializer.validated_data['phone_number']
        otp_code = serializer.validated_data['otp_code']
        
        # Verify OTP
        is_valid, message = OTPService.verify_otp(phone_number, otp_code, request.user if request.user.is_authenticated else None)
        
        if is_valid:
            return Response({
                'message': message,
                'verified': True
            })
        else:
            return Response({
                'message': message,
                'verified': False
            }, status=status.HTTP_400_BAD_REQUEST)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def test_otp(request):
    """Test OTP generation - for debugging"""
    import sys
    phone_number = request.query_params.get('phone', '1234567890')
    print(f"\n{'='*80}")
    print(f"TEST OTP GENERATION")
    print(f"{'='*80}")
    print(f"Phone: {phone_number}")
    sys.stdout.flush()
    
    try:
        otp_verification = OTPService.send_otp(phone_number, None, purpose='test')
        return Response({
            'message': 'OTP generated and printed to terminal',
            'phone_number': phone_number,
            'otp_id': otp_verification.id if hasattr(otp_verification, 'id') else 'N/A'
        })
    except Exception as e:
        import traceback
        print(f"Error in test_otp: {e}")
        traceback.print_exc()
        sys.stdout.flush()
        return Response({
            'error': str(e),
            'message': 'Check terminal for OTP even if error occurred'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def update_profile(request):
    """Update user profile"""
    serializer = ProfileUpdateSerializer(data=request.data)
    if serializer.is_valid():
        user = request.user
        
        # Update user fields
        if 'first_name' in serializer.validated_data:
            user.first_name = serializer.validated_data['first_name']
        if 'last_name' in serializer.validated_data:
            user.last_name = serializer.validated_data['last_name']
        if 'phone_number' in serializer.validated_data:
            user.phone_number = serializer.validated_data['phone_number']
        
        user.save()
        
        # Update profile-specific fields
        if hasattr(user, 'student_profile'):
            student = user.student_profile
            if 'bio' in serializer.validated_data:
                student.bio = serializer.validated_data['bio']
            if 'interests' in serializer.validated_data:
                student.interests = serializer.validated_data['interests']
            student.save()
        
        return Response({
            'message': 'Profile updated successfully',
            'user': UserSerializer(user).data
        })
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def change_password(request):
    """Change user password"""
    serializer = PasswordChangeSerializer(data=request.data)
    if serializer.is_valid():
        user = request.user
        old_password = serializer.validated_data['old_password']
        new_password = serializer.validated_data['new_password']
        
        # Check old password
        if not user.check_password(old_password):
            return Response({
                'message': 'Current password is incorrect'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Set new password
        user.set_password(new_password)
        user.save()
        
        return Response({
            'message': 'Password changed successfully'
        })
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def upload_profile_picture(request):
    """Upload profile picture"""
    try:
        profile_picture = request.FILES.get('profile_picture')
        if not profile_picture:
            return Response({
                'error': 'No profile picture provided'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        user = request.user
        
        # Update profile picture based on user type
        if user.user_type == 'student':
            if hasattr(user, 'student_profile'):
                user.student_profile.profile_picture = profile_picture
                user.student_profile.save()
                return Response({
                    'profile_picture_url': user.student_profile.profile_picture.url if user.student_profile.profile_picture else None,
                    'message': 'Profile picture updated successfully'
                })
        elif user.user_type == 'faculty':
            if hasattr(user, 'faculty_profile'):
                user.faculty_profile.profile_picture = profile_picture
                user.faculty_profile.save()
                return Response({
                    'profile_picture_url': user.faculty_profile.profile_picture.url if user.faculty_profile.profile_picture else None,
                    'message': 'Profile picture updated successfully'
                })
        
        return Response({
            'error': 'User profile not found'
        }, status=status.HTTP_404_NOT_FOUND)
        
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def profile_summary(request):
    """Get user profile summary"""
    user = request.user
    
    data = {
        'user': UserSerializer(user).data,
        'profile_type': None,
        'profile_data': None
    }
    
    if hasattr(user, 'student_profile'):
        data['profile_type'] = 'student'
        data['profile_data'] = StudentSerializer(user.student_profile).data
    elif hasattr(user, 'faculty_profile'):
        data['profile_type'] = 'faculty'
        data['profile_data'] = FacultySerializer(user.faculty_profile).data
    
    return Response(data)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def faculty_list(request):
    """Get list of faculty members"""
    faculty = Faculty.objects.filter(is_active=True).select_related('user')
    serializer = FacultySerializer(faculty, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def student_list(request):
    """Get list of students"""
    students = Student.objects.filter(is_active=True).select_related('user')
    serializer = StudentSerializer(students, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def branches_list(request):
    """Get list of all unique branches from AllowedUSN model (from Excel import)"""
    from apps.accounts.models import AllowedUSN
    from django.db.models import Count
    
    # Get all unique branches from AllowedUSN model (where Excel data is stored)
    branches = AllowedUSN.objects.filter(
        branch__isnull=False
    ).exclude(
        branch=''
    ).values('branch').annotate(
        usn_count=Count('id')
    ).order_by('branch')
    
    branch_list = [item['branch'] for item in branches]
    return Response({
        'branches': branch_list,
        'total': len(branch_list)
    })


# Two-Factor Authentication Views - Now enabled
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def setup_2fa(request):
    """Setup Two-Factor Authentication for user"""
    try:
        user = request.user
        
        # Setup 2FA for user
        two_factor_auth = TwoFactorService.setup_2fa(user)
        
        # Generate QR code
        qr_code = TwoFactorService.generate_qr_code(user, two_factor_auth.secret_key)
        
        return Response({
            'message': '2FA setup initiated successfully',
            'secret_key': two_factor_auth.secret_key,
            'qr_code': qr_code,
            'backup_codes': two_factor_auth.backup_codes
        })
        
    except Exception as e:
        return Response({
            'error': f'Failed to setup 2FA: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def verify_2fa(request):
    """Verify 2FA setup with code"""
    serializer = TwoFactorVerifySerializer(data=request.data)
    if serializer.is_valid():
        user = request.user
        code = serializer.validated_data['code']
        
        # Enable 2FA
        is_success, message = TwoFactorService.enable_2fa(user, code)
        
        if is_success:
            return Response({
                'message': message,
                'enabled': True
            })
        else:
            return Response({
                'message': message,
                'enabled': False
            }, status=status.HTTP_400_BAD_REQUEST)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def disable_2fa(request):
    """Disable Two-Factor Authentication"""
    serializer = TwoFactorDisableSerializer(data=request.data)
    if serializer.is_valid():
        user = request.user
        password = serializer.validated_data['password']
        
        # Disable 2FA
        is_success, message = TwoFactorService.disable_2fa(user, password)
        
        if is_success:
            return Response({
                'message': message,
                'disabled': True
            })
        else:
            return Response({
                'message': message,
                'disabled': False
            }, status=status.HTTP_400_BAD_REQUEST)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_2fa_status(request):
    """Get 2FA status for user"""
    user = request.user
    try:
        two_factor_auth = user.two_factor_auth
        serializer = TwoFactorAuthSerializer(two_factor_auth)
        return Response(serializer.data)
    except:
        return Response({
            'is_enabled': False,
            'created_at': None,
            'updated_at': None
        })


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def generate_backup_codes(request):
    """Generate new backup codes"""
    password = request.data.get('password')
    if not password:
        return Response({
            'message': 'Password is required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    user = request.user
    is_success, message, backup_codes = TwoFactorService.generate_new_backup_codes(user, password)
    
    if is_success:
        return Response({
            'message': message,
            'backup_codes': backup_codes
        })
    else:
        return Response({
            'message': message
        }, status=status.HTTP_400_BAD_REQUEST)


# Device Session Management Views
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_active_sessions(request):
    """Get active device sessions for user"""
    user = request.user
    sessions = DeviceSessionService.get_active_sessions(user)
    serializer = DeviceSessionSerializer(sessions, many=True)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def create_device_session(request):
    """Create a device session for current user"""
    user = request.user
    device_id = request.data.get('device_id')
    device_name = request.data.get('device_name', 'Unknown Device')
    device_type = request.data.get('device_type', 'unknown')
    ip_address = request.META.get('REMOTE_ADDR', '127.0.0.1')
    user_agent = request.META.get('HTTP_USER_AGENT', 'Unknown')
    
    if not device_id:
        return Response({
            'error': 'Device ID is required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    session = DeviceSessionService.create_device_session(
        user, device_id, device_name, device_type, ip_address, user_agent
    )
    
    if session:
        serializer = DeviceSessionSerializer(session)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    else:
        return Response({
            'error': 'Failed to create device session'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def deactivate_session(request, session_id):
    """Deactivate a specific device session"""
    user = request.user
    is_success = DeviceSessionService.deactivate_session(user, session_id)
    
    if is_success:
        return Response({
            'message': 'Session deactivated successfully'
        })
    else:
        return Response({
            'message': 'Session not found or already deactivated'
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def logout_all_devices(request):
    """Logout from all devices except current"""
    user = request.user
    current_session_id = request.data.get('current_session_id')
    deactivated_count = DeviceSessionService.deactivate_all_sessions(user, current_session_id)
    
    return Response({
        'message': f'Logged out from {deactivated_count} devices',
        'deactivated_count': deactivated_count
    })


# Enhanced Login with 2FA
@api_view(['POST'])
@authentication_classes([])  # Disable authentication for login endpoint
@permission_classes([permissions.AllowAny])
def login_with_2fa(request):
    """Login with Two-Factor Authentication"""
    serializer = LoginWith2FASerializer(data=request.data)
    if serializer.is_valid():
        username = serializer.validated_data['username']
        password = serializer.validated_data['password']
        code = serializer.validated_data.get('code')
        backup_code = serializer.validated_data.get('backup_code')
        device_id = serializer.validated_data['device_id']
        device_name = serializer.validated_data['device_name']
        device_type = serializer.validated_data['device_type']
        
        # Authenticate user
        user = authenticate(username=username, password=password)
        if not user:
            return Response({
                'message': 'Invalid credentials'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # For students, validate USN exists in AllowedUSN table
        if user.user_type == 'student':
            from apps.accounts.models import AllowedUSN
            try:
                student_profile = user.student_profile
                if student_profile.usn:
                    # Check if USN exists in AllowedUSN table
                    if not AllowedUSN.objects.filter(usn=student_profile.usn.upper()).exists():
                        return Response(
                            {'message': 'Invalid USN. You are not eligible to login.'}, 
                            status=status.HTTP_403_FORBIDDEN
                        )
                else:
                    # Student profile exists but no USN - reject login
                    return Response(
                        {'message': 'Invalid USN. You are not eligible to login.'}, 
                        status=status.HTTP_403_FORBIDDEN
                    )
            except Student.DoesNotExist:
                # Student user without profile - reject login
                return Response(
                    {'message': 'Student profile not found. Please contact support.'}, 
                    status=status.HTTP_403_FORBIDDEN
                )
        
        # Update login streak (gamification)
        try:
            from apps.gamification.models import UserStreak
            streak, created = UserStreak.objects.get_or_create(user=user)
            streak.update_streak()
        except Exception as e:
            # Don't fail login if streak update fails
            print(f"Warning: Failed to update login streak for user {user.username}: {e}")
        
        # Check if 2FA is enabled
        try:
            two_factor_auth = user.two_factor_auth
            if two_factor_auth and two_factor_auth.is_enabled:
                # Verify 2FA code
                if code:
                    is_valid, message = TwoFactorService.verify_totp_code(user, code)
                    if not is_valid:
                        return Response({
                            'message': message
                        }, status=status.HTTP_400_BAD_REQUEST)
                elif backup_code:
                    is_valid, message = TwoFactorService.verify_backup_code(user, backup_code)
                    if not is_valid:
                        return Response({
                            'message': message
                        }, status=status.HTTP_400_BAD_REQUEST)
                else:
                    return Response({
                        'message': '2FA code or backup code required'
                    }, status=status.HTTP_400_BAD_REQUEST)
        
        except:
            pass  # 2FA not set up
        
        # Create device session
        ip_address = request.META.get('REMOTE_ADDR', '')
        user_agent = request.META.get('HTTP_USER_AGENT', '')
        
        session = DeviceSessionService.create_device_session(
            user, device_id, device_name, device_type, ip_address, user_agent
        )
        
        if not session:
            return Response({
                'message': 'Failed to create device session'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        # Generate JWT token (you'll need to implement this based on your auth system)
        # For now, return success
        return Response({
            'message': 'Login successful',
            'user': UserSerializer(user).data,
            'session_id': session.id
        })
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# Simple Login Endpoint for Flutter App
@api_view(['POST'])
@authentication_classes([])  # Disable authentication for login endpoint
@permission_classes([permissions.AllowAny])
def login(request):
    """Simple login endpoint for Flutter app with JWT and cookies"""
    username = request.data.get('username')
    password = request.data.get('password')
    
    if not username or not password:
        return Response(
            {'error': 'Username and password are required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Authenticate user
    user = authenticate(username=username, password=password)
    
    if not user:
        return Response(
            {'error': 'Invalid credentials'}, 
            status=status.HTTP_401_UNAUTHORIZED
        )
    
    if not user.is_active:
        return Response(
            {'error': 'Account is inactive. Please contact support.'}, 
            status=status.HTTP_403_FORBIDDEN
        )
    
    # For students, validate USN exists in AllowedUSN table
    if user.user_type == 'student':
        from apps.accounts.models import AllowedUSN
        try:
            student_profile = user.student_profile
            if student_profile.usn:
                usn_upper = student_profile.usn.upper()
                # Check if USN exists in AllowedUSN table
                if not AllowedUSN.objects.filter(usn=usn_upper).exists():
                    print(f"Login rejected: USN {usn_upper} not found in AllowedUSN table for user {username}")
                    return Response(
                        {'error': f'Invalid USN ({usn_upper}). You are not eligible to login. Please contact support.'}, 
                        status=status.HTTP_403_FORBIDDEN
                    )
            else:
                # Student profile exists but no USN - reject login
                print(f"Login rejected: Student profile exists but no USN for user {username}")
                return Response(
                    {'error': 'Student profile missing USN. Please contact support.'}, 
                    status=status.HTTP_403_FORBIDDEN
                )
        except Student.DoesNotExist:
            # Student user without profile - reject login
            print(f"Login rejected: Student profile not found for user {username}")
            return Response(
                {'error': 'Student profile not found. Please contact support.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Update login streak (gamification)
        try:
            from apps.gamification.models import UserStreak
            streak, created = UserStreak.objects.get_or_create(user=user)
            streak.update_streak()
        except Exception as e:
            # Don't fail login if streak update fails
            print(f"Warning: Failed to update login streak for user {user.username}: {e}")
        
        # Generate JWT tokens
        tokens = get_tokens_for_user(user)
        
        # Get device information from request
        device_id = request.data.get('device_id', 'web-browser')
        device_name = request.data.get('device_name', 'Web Browser')
        device_type = request.data.get('device_type', 'web')
        ip_address = request.META.get('REMOTE_ADDR', '127.0.0.1')
        user_agent = request.META.get('HTTP_USER_AGENT', 'Unknown')
        
        # Create device session
        session = DeviceSessionService.create_device_session(
            user, device_id, device_name, device_type, ip_address, user_agent
        )
        
        # Use UserProfileSerializer to include student/faculty profile data
        # This helps frontend determine user type even if user_type field is missing
        from .serializers import UserProfileSerializer
        
        # Create response with user data
        response_data = {
            'access_token': tokens['access'],
            'refresh_token': tokens['refresh'],
            'user': UserProfileSerializer(user).data,  # Changed from UserSerializer to UserProfileSerializer
            'message': 'Login successful',
            'session_id': session.id if session else None
        }
        
        # Debug: Log user type to help diagnose routing issues
        print(f'Login successful for user: {user.email}, user_type: {user.user_type}')
        
        # Create response
        response = Response(response_data)
        
        # Set JWT cookies
        response = set_jwt_cookies(response, user)
        
        return response
    else:
        return Response(
            {'error': 'Invalid credentials'}, 
            status=status.HTTP_401_UNAUTHORIZED
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def logout(request):
    """Logout endpoint with cookie clearing"""
    try:
        # Delete the user's token if it exists
        try:
            request.user.auth_token.delete()
        except:
            pass  # Token might not exist
        
        # Create response
        response = Response({'message': 'Logout successful'})
        
        # Clear JWT cookies
        response = clear_jwt_cookies(response)
        
        return response
    except:
        response = Response({'message': 'Logout successful'})
        response = clear_jwt_cookies(response)
        return response


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def get_current_user(request):
    """Get current user profile"""
    # Use UserProfileSerializer to include student/faculty profile data
    from .serializers import UserProfileSerializer
    return Response(UserProfileSerializer(request.user).data)


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def refresh_token(request):
    """Refresh JWT token using refresh token"""
    refresh_token = request.data.get('refresh_token')
    
    if not refresh_token:
        return Response(
            {'error': 'Refresh token is required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        from rest_framework_simplejwt.tokens import RefreshToken
        from rest_framework_simplejwt.exceptions import TokenError
        
        # Validate refresh token
        refresh = RefreshToken(refresh_token)
        
        # Generate new access token
        new_access_token = refresh.access_token
        
        # Get user
        user = refresh.payload.get('user_id')
        user = User.objects.get(id=user)
        
        # Create response
        response_data = {
            'access_token': str(new_access_token),
            'refresh_token': str(refresh),
            'user': UserSerializer(user).data,
            'message': 'Token refreshed successfully'
        }
        
        response = Response(response_data)
        
        # Set new JWT cookies
        response = set_jwt_cookies(response, user)
        
        return response
        
    except TokenError:
        return Response(
            {'error': 'Invalid refresh token'}, 
            status=status.HTTP_401_UNAUTHORIZED
        )
    except User.DoesNotExist:
        return Response(
            {'error': 'User not found'}, 
            status=status.HTTP_401_UNAUTHORIZED
        )
    except Exception as e:
        return Response(
            {'error': 'Token refresh failed'}, 
            status=status.HTTP_400_BAD_REQUEST
        )


# Registration with OTP Flow
@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def register(request):
    """Register new user with OTP verification"""
    import sys
    import traceback
    
    try:
        print(f"\n{'='*80}")
        print(f"REGISTRATION REQUEST RECEIVED")
        print(f"{'='*80}")
        print(f"Request method: {request.method}")
        print(f"Request path: {request.path}")
        print(f"Request data type: {type(request.data)}")
        print(f"Request data: {request.data}")
        sys.stdout.flush()
        
        email = request.data.get('email')
        username = request.data.get('username')
        password = request.data.get('password')
        first_name = request.data.get('first_name')
        last_name = request.data.get('last_name')
        user_type = request.data.get('user_type', 'student')
        phone_number = request.data.get('phone_number')
        usn = request.data.get('usn')  # USN for student validation
        
        print(f"\n{'='*80}")
        print(f"PARSED REGISTRATION FIELDS")
        print(f"{'='*80}")
        print(f"Email: {email}")
        print(f"Username: {username}")
        print(f"First Name: {first_name}")
        print(f"Last Name: {last_name}")
        print(f"User Type: {user_type}")
        print(f"Phone Number: {phone_number}")
        print(f"USN: {usn}")
        print(f"{'='*80}\n")
        sys.stdout.flush()
        
        # Validate required fields (USN is now optional - will be collected after OTP verification)
        required_fields = ['email', 'username', 'password', 'first_name', 'last_name']
        
        missing_fields = []
        if not email: missing_fields.append('email')
        if not username: missing_fields.append('username')
        if not password: missing_fields.append('password')
        if not first_name: missing_fields.append('first_name')
        if not last_name: missing_fields.append('last_name')
        
        if missing_fields:
            print(f"\n{'!'*80}")
            print(f"REGISTRATION ERROR: Missing required fields")
            print(f"Missing: {missing_fields}")
            print(f"{'!'*80}\n")
            sys.stdout.flush()
            return Response(
                {'error': f'Missing required fields: {", ".join(missing_fields)}'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate USN for students - check if it exists in AllowedUSN table
        if user_type == 'student' and usn:
            from apps.accounts.models import AllowedUSN
            
            usn_upper = usn.upper().strip()
            
            # Check if USN exists in AllowedUSN table
            if not AllowedUSN.objects.filter(usn=usn_upper).exists():
                print(f"Registration failed: Invalid USN {usn_upper}")
                sys.stdout.flush()
                return Response(
                    {'error': 'Invalid USN. You are not eligible to register.'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if USN is already registered by another student
            existing_student = Student.objects.filter(usn=usn_upper).first()
            if existing_student:
                print(f"Registration failed: USN {usn_upper} already registered")
                sys.stdout.flush()
                return Response(
                    {'error': 'This USN is already registered. Please contact support if you believe this is an error.'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # Check if user already exists
        if User.objects.filter(email=email).exists():
            print(f"Registration failed: Email {email} already exists")
            sys.stdout.flush()
            return Response(
                {'error': 'User with this email already exists'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if User.objects.filter(username=username).exists():
            print(f"Registration failed: Username {username} already exists")
            sys.stdout.flush()
            return Response(
                {'error': 'User with this username already exists'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create user but don't activate yet
        user = None
        try:
            user = User.objects.create_user(
                username=username,
                email=email,
                password=password,
                first_name=first_name,
                last_name=last_name,
                user_type=user_type,
                phone_number=phone_number,
                is_active=False,  # Don't activate until OTP is verified
                is_verified=False
            )
            print(f"User created successfully: {user.username} (ID: {user.id})")
            sys.stdout.flush()
            
            # Create profile based on user type
            if user_type == 'student':
                # Create student profile without USN initially (will be added after OTP verification)
                Student.objects.create(
                    user=user,
                    student_id=f'STU_{user.id}',
                    usn=None,  # USN will be set after OTP verification
                    year_of_study=1,
                    branch='General'  # Will be updated when USN is verified
                )
                print(f"Student profile created for user {user.username} (USN will be added after OTP verification)")
            elif user_type == 'faculty':
                Faculty.objects.create(
                    user=user,
                    employee_id=f'FAC_{user.id}',
                    designation='Faculty',
                    department='General'
                )
                print(f"Faculty profile created for user {user.username}")
            sys.stdout.flush()
        except Exception as e:
            print(f"\n{'!'*80}")
            print(f"ERROR CREATING USER: {str(e)}")
            print(f"Traceback:")
            traceback.print_exc()
            print(f"{'!'*80}\n")
            sys.stdout.flush()
            return Response(
                {'error': f'Failed to create user: {str(e)}'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Send OTP for phone verification
        print(f"\n{'='*80}")
        print(f"CHECKING PHONE NUMBER FOR OTP")
        print(f"{'='*80}")
        print(f"Phone number value: {phone_number}")
        print(f"Phone number type: {type(phone_number)}")
        print(f"Phone number is None: {phone_number is None}")
        print(f"Phone number is empty string: {phone_number == ''}")
        print(f"Phone number bool: {bool(phone_number)}")
        sys.stdout.flush()
        
        if phone_number:
            try:
                print(f"\n{'='*60}")
                print(f"REGISTRATION: Attempting to send OTP to {phone_number}")
                print(f"User: {user.username} (ID: {user.id})")
                print(f"{'='*60}\n")
                sys.stdout.flush()
                
                otp_verification = OTPService.send_otp(phone_number, user, purpose='registration')
                
                print(f"\n{'='*60}")
                print(f"REGISTRATION: OTP successfully sent to {phone_number} for user {user.username}")
                print(f"OTP Verification ID: {otp_verification.id if hasattr(otp_verification, 'id') else 'N/A'}")
                print(f"{'='*60}\n")
                sys.stdout.flush()
            except Exception as e:
                print(f"\n{'!'*60}")
                print(f"REGISTRATION ERROR: Failed to send OTP")
                print(f"Error: {str(e)}")
                print(f"Error type: {type(e)}")
                print(f"Traceback:")
                traceback.print_exc()
                print(f"User: {user.username} (ID: {user.id})")
                print(f"Phone: {phone_number}")
                print(f"{'!'*60}\n")
                sys.stdout.flush()
                # Check if OTP was at least printed (even if DB record failed)
                if "OTP generated and printed" in str(e):
                    # OTP was printed, so don't delete user - they can still use it
                    print(f"WARNING: OTP was printed but DB record creation failed.")
                    print(f"User will remain but verification may not work properly.")
                    sys.stdout.flush()
                else:
                    # Real error - delete user
                    print(f"Deleting user due to OTP sending failure...")
                    sys.stdout.flush()
                    try:
                        user.delete()
                    except:
                        pass
                    return Response(
                        {'error': f'Failed to send OTP: {str(e)}'}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )
        else:
            # If no phone number, activate user directly
            user.is_active = True
            user.is_verified = True
            user.save()
            otp_verification = None
            print(f"User activated directly without OTP: {user.username}")
            sys.stdout.flush()
        
        # Generate JWT tokens
        try:
            tokens = get_tokens_for_user(user)
        except Exception as e:
            print(f"\n{'!'*80}")
            print(f"ERROR GENERATING TOKENS: {str(e)}")
            print(f"Traceback:")
            traceback.print_exc()
            print(f"{'!'*80}\n")
            sys.stdout.flush()
            return Response(
                {'error': f'Failed to generate tokens: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        # Create response data
        try:
            response_data = {
                'message': 'Registration successful. Please verify your phone number with the OTP sent.',
                'access_token': tokens['access'],
                'refresh_token': tokens['refresh'],
                'user': UserSerializer(user).data,
                'user_id': user.id,
                'requires_verification': bool(phone_number),
                'otp_sent_to': phone_number if phone_number else None
            }
            
            # Create response
            response = Response(response_data)
            
            # Set JWT cookies
            try:
                response = set_jwt_cookies(response, user)
            except Exception as e:
                print(f"Warning: Failed to set JWT cookies: {e}")
                sys.stdout.flush()
            
            print(f"\n{'='*80}")
            print(f"REGISTRATION SUCCESSFUL")
            print(f"User: {user.username} (ID: {user.id})")
            print(f"Requires verification: {bool(phone_number)}")
            print(f"{'='*80}\n")
            sys.stdout.flush()
            
            return response
        except Exception as e:
            print(f"\n{'!'*80}")
            print(f"ERROR CREATING RESPONSE: {str(e)}")
            print(f"Traceback:")
            traceback.print_exc()
            print(f"{'!'*80}\n")
            sys.stdout.flush()
            return Response(
                {'error': f'Failed to create response: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            
    except Exception as e:
        print(f"\n{'!'*80}")
        print(f"UNEXPECTED ERROR IN REGISTRATION: {str(e)}")
        print(f"Error type: {type(e)}")
        print(f"Traceback:")
        traceback.print_exc()
        print(f"{'!'*80}\n")
        sys.stdout.flush()
        return Response(
            {'error': f'Registration failed: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([])
@authentication_classes([])
def verify_registration_otp(request):
    """Verify OTP and activate user account with JWT"""
    print(f"OTP verification request data: {request.data}")
    user_id = request.data.get('user_id')
    otp_code = request.data.get('otp')
    
    print(f"Parsed user_id: {user_id}, otp_code: {otp_code}")
    
    if not user_id or not otp_code:
        print("Missing required fields")
        return Response(
            {'error': 'User ID and OTP code are required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        user = User.objects.get(id=user_id, is_active=False)
        print(f"Found user: {user.username} (ID: {user.id})")
    except User.DoesNotExist:
        print(f"User not found or already activated: user_id={user_id}")
        return Response(
            {'error': 'User not found or already activated'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Verify OTP
    from .otp_service import OTPService
    print(f"Verifying OTP: {otp_code} for user: {user.username}")
    is_valid, message = OTPService.verify_otp_for_user(user, otp_code, purpose='registration')
    print(f"OTP verification result: is_valid={is_valid}, message={message}")
    
    if is_valid:
        # Activate user
        user.is_active = True
        user.is_verified = True
        user.save()
        
        # Check if student needs USN entry
        requires_usn_entry = False
        if user.user_type == 'student':
            # Check if student profile exists and has USN
            # Refresh user from DB to ensure we have the latest student_profile
            user.refresh_from_db()
            
            # Check if student profile exists using the related manager
            student_profile_exists = Student.objects.filter(user=user).exists()
            
            if student_profile_exists:
                student_profile = Student.objects.get(user=user)
                # Check if USN is None, empty string, or just whitespace
                usn_value = student_profile.usn
                print(f"🔵 Student {user.username} profile found. USN value: {repr(usn_value)}")
                
                if usn_value is None or (isinstance(usn_value, str) and usn_value.strip() == ''):
                    requires_usn_entry = True
                    print(f"🔵 Student {user.username} needs USN entry (USN is empty or None)")
                else:
                    print(f"🔵 Student {user.username} already has USN: {usn_value}")
                    requires_usn_entry = False
            else:
                # Student profile doesn't exist yet
                requires_usn_entry = True
                print(f"🔵 Student {user.username} needs USN entry (profile doesn't exist)")
        
        print(f"🔵 OTP Verification - User: {user.username}, Type: {user.user_type}, requires_usn_entry: {requires_usn_entry}")
        
        # Generate JWT tokens
        tokens = get_tokens_for_user(user)
        
        # Create response data
        response_data = {
            'message': 'Account verified successfully',
            'access_token': tokens['access'],
            'refresh_token': tokens['refresh'],
            'user': UserProfileSerializer(user).data,  # Use UserProfileSerializer to include profile data
            'requires_usn_entry': requires_usn_entry,  # Indicate if student needs to enter USN
        }
        
        # Create response
        response = Response(response_data)
        
        # Set JWT cookies
        response = set_jwt_cookies(response, user)
        
        return response
    else:
        return Response(
            {'error': message}, 
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def verify_and_update_usn(request):
    """Verify USN against AllowedUSN table and update student profile"""
    user_id = request.data.get('user_id')
    usn = request.data.get('usn')
    
    if not user_id or not usn:
        return Response(
            {'error': 'User ID and USN are required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        user = User.objects.get(id=user_id)
        
        # Only students can verify USN
        if user.user_type != 'student':
            return Response(
                {'error': 'USN verification is only for students'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if student profile exists
        try:
            student_profile = user.student_profile
        except Student.DoesNotExist:
            return Response(
                {'error': 'Student profile not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Check if USN is already set
        if student_profile.usn:
            return Response(
                {'error': 'USN is already set for this account'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        usn_upper = usn.upper().strip()
        
        print(f"🔵 USN Verification Request - User: {user.username}, USN: {usn_upper}")
        
        # Validate USN format
        if len(usn_upper) < 5:
            print(f"❌ USN validation failed: USN too short ({len(usn_upper)} characters)")
            return Response(
                {'error': 'USN must be at least 5 characters'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if USN exists in AllowedUSN table
        from apps.accounts.models import AllowedUSN
        
        # First, check if AllowedUSN table has any records
        total_allowed_usns = AllowedUSN.objects.count()
        print(f"🔵 Total USNs in AllowedUSN table: {total_allowed_usns}")
        
        if total_allowed_usns == 0:
            print("❌ ERROR: AllowedUSN table is empty! No USNs can be verified.")
            return Response(
                {'error': 'USN verification system is not configured. Please contact support.'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        # Check if USN exists in AllowedUSN table
        try:
            allowed_usn = AllowedUSN.objects.get(usn=usn_upper)
            print(f"✅ USN {usn_upper} found in AllowedUSN table (Branch: {allowed_usn.branch}, Name: {allowed_usn.name})")
        except AllowedUSN.DoesNotExist:
            print(f"❌ USN {usn_upper} NOT found in AllowedUSN table")
            # Show some sample USNs for debugging (first 5)
            sample_usns = AllowedUSN.objects.values_list('usn', flat=True)[:5]
            print(f"   Sample USNs in database: {list(sample_usns)}")
            return Response(
                {'error': 'Invalid USN. Your USN is not found in the university database. Please enter a valid USN or contact support.'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            print(f"❌ Error checking AllowedUSN: {e}")
            import traceback
            traceback.print_exc()
            return Response(
                {'error': f'Error verifying USN: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        # Check if USN is already registered by another student
        existing_student = Student.objects.filter(usn=usn_upper).exclude(id=student_profile.id).first()
        if existing_student:
            return Response(
                {'error': 'This USN is already registered by another student. Please contact support if you believe this is an error.'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Update student profile with USN and branch
        student_profile.usn = usn_upper
        if allowed_usn.branch:
            student_profile.branch = allowed_usn.branch
        student_profile.save()
        
        print(f"✅ USN {usn_upper} verified and updated for user {user.username} (Branch: {student_profile.branch})")
        
        # Generate new JWT tokens with updated user data
        tokens = get_tokens_for_user(user)
        
        # Create response
        response_data = {
            'message': 'USN verified and updated successfully',
            'access_token': tokens['access'],
            'refresh_token': tokens['refresh'],
            'user': UserProfileSerializer(user).data
        }
        
        response = Response(response_data)
        response = set_jwt_cookies(response, user)
        
        return response
        
    except User.DoesNotExist:
        return Response(
            {'error': 'User not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        print(f"Error verifying USN: {e}")
        import traceback
        traceback.print_exc()
        return Response(
            {'error': f'Failed to verify USN: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# Forgot Password Flow
@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def forgot_password_request(request):
    """Send OTP for password reset"""
    phone_number = request.data.get('phone_number')
    
    if not phone_number:
        return Response(
            {'error': 'Phone number is required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Find user by phone number
    try:
        user = User.objects.get(phone_number=phone_number, is_active=True)
    except User.DoesNotExist:
        return Response(
            {'error': 'No user found with this phone number'}, 
            status=status.HTTP_404_NOT_FOUND
        )
    
    # Send OTP for password reset
    from .otp_service import OTPService
    otp_verification = OTPService.send_otp(phone_number, user, purpose='password_reset')
    
    return Response({
        'message': 'OTP sent successfully for password reset',
        'phone_number': phone_number,
        'expires_at': otp_verification.expires_at
    })


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def forgot_password_verify_otp(request):
    """Verify OTP for password reset"""
    phone_number = request.data.get('phone_number')
    otp_code = request.data.get('otp')
    
    if not phone_number or not otp_code:
        return Response(
            {'error': 'Phone number and OTP code are required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Find user
    try:
        user = User.objects.get(phone_number=phone_number, is_active=True)
    except User.DoesNotExist:
        return Response(
            {'error': 'User not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )
    
    # Verify OTP
    from .otp_service import OTPService
    is_valid, message = OTPService.verify_otp_for_user(user, otp_code, purpose='password_reset')
    
    if is_valid:
        # Generate a temporary token for password reset (valid for 10 minutes)
        from rest_framework_simplejwt.tokens import AccessToken
        from datetime import datetime, timedelta
        
        # Create a custom token with user ID and purpose
        token = AccessToken.for_user(user)
        token['purpose'] = 'password_reset'
        token.set_exp(from_time=datetime.utcnow() + timedelta(minutes=10))
        
        return Response({
            'message': 'OTP verified successfully',
            'reset_token': str(token),
            'user_id': user.id
        })
    else:
        return Response(
            {'error': 'Invalid OTP'}, 
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def reset_password(request):
    """Reset password using reset token"""
    reset_token = request.data.get('reset_token')
    new_password = request.data.get('new_password')
    confirm_password = request.data.get('confirm_password')
    
    if not reset_token or not new_password or not confirm_password:
        return Response(
            {'error': 'Reset token, new password and confirm password are required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    if new_password != confirm_password:
        return Response(
            {'error': 'Passwords do not match'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        # Verify reset token
        from rest_framework_simplejwt.tokens import AccessToken
        from rest_framework_simplejwt.exceptions import TokenError
        
        token = AccessToken(reset_token)
        
        # Check if token is for password reset
        if token.get('purpose') != 'password_reset':
            return Response(
                {'error': 'Invalid reset token'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get user from token
        user_id = token['user_id']
        user = User.objects.get(id=user_id)
        
        # Set new password
        user.set_password(new_password)
        user.save()
        
        # Generate new JWT tokens for the user
        tokens = get_tokens_for_user(user)
        
        # Create response data
        response_data = {
            'message': 'Password reset successfully',
            'access_token': tokens['access'],
            'refresh_token': tokens['refresh'],
            'user': UserSerializer(user).data
        }
        
        # Create response
        response = Response(response_data)
        
        # Set JWT cookies
        response = set_jwt_cookies(response, user)
        
        return response
        
    except TokenError:
        return Response(
            {'error': 'Invalid or expired reset token'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    except User.DoesNotExist:
        return Response(
            {'error': 'User not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )


# SSO Endpoints
@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def sso_login_url(request):
    """Get SSO login URL from Keycloak"""
    try:
        redirect_uri = request.query_params.get('redirect_uri', request.build_absolute_uri('/api/accounts/sso/callback/'))
        state = request.query_params.get('state')
        
        result = SSOService.get_authorization_url(redirect_uri, state)
        
        return Response(result)
    except Exception as e:
        return Response(
            {'error': f'Failed to generate SSO URL: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def sso_callback(request):
    """Handle SSO callback from Keycloak"""
    try:
        authorization_code = request.data.get('code')
        state = request.data.get('state')
        redirect_uri = request.data.get('redirect_uri', request.build_absolute_uri('/api/accounts/sso/callback/'))
        
        if not authorization_code:
            return Response(
                {'error': 'Authorization code is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate state if provided
        if state and not SSOService.validate_state(state):
            return Response(
                {'error': 'Invalid state parameter'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Exchange code for tokens
        token_data = SSOService.exchange_code_for_tokens(authorization_code, redirect_uri)
        user_info = token_data['user_info']
        
        # Get or create user
        user = SSOService.get_or_create_user_from_keycloak(user_info)
        
        # Generate JWT tokens for our API
        jwt_tokens = get_tokens_for_user(user)
        
        # Create device session
        device_id = request.data.get('device_id', 'sso-web')
        device_name = request.data.get('device_name', 'SSO Login')
        device_type = request.data.get('device_type', 'web')
        ip_address = request.META.get('REMOTE_ADDR', '127.0.0.1')
        user_agent = request.META.get('HTTP_USER_AGENT', 'Unknown')
        
        session = DeviceSessionService.create_device_session(
            user, device_id, device_name, device_type, ip_address, user_agent
        )
        
        response_data = {
            'access_token': jwt_tokens['access'],
            'refresh_token': jwt_tokens['refresh'],
            'keycloak_access_token': token_data['access_token'],
            'keycloak_refresh_token': token_data.get('refresh_token'),
            'user': UserSerializer(user).data,
            'message': 'SSO login successful',
            'session_id': session.id if session else None
        }
        
        response = Response(response_data)
        response = set_jwt_cookies(response, user)
        
        return response
        
    except Exception as e:
        return Response(
            {'error': f'SSO callback failed: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def sso_refresh_token(request):
    """Refresh Keycloak access token"""
    try:
        refresh_token = request.data.get('refresh_token')
        
        if not refresh_token:
            return Response(
                {'error': 'Refresh token is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        token_data = SSOService.refresh_access_token(refresh_token)
        
        return Response({
            'access_token': token_data.get('access_token'),
            'refresh_token': token_data.get('refresh_token'),
            'expires_in': token_data.get('expires_in', 3600)
        })
        
    except Exception as e:
        return Response(
            {'error': f'Token refresh failed: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def sso_logout(request):
    """Logout from Keycloak SSO"""
    try:
        refresh_token = request.data.get('refresh_token')
        
        if refresh_token:
            SSOService.logout(refresh_token)
        
        # Also logout from Django session
        response = Response({'message': 'Logged out successfully'})
        response = clear_jwt_cookies(response)
        
        return response
        
    except Exception as e:
        return Response(
            {'error': f'Logout failed: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )