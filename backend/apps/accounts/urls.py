"""
URLs for accounts app
"""
from django.urls import path
from . import views

urlpatterns = [
    # Profile management
    path('profile/', views.UserProfileView.as_view(), name='user-profile'),
    path('profile/picture/', views.upload_profile_picture, name='upload-profile-picture'),
    path('profile/summary/', views.profile_summary, name='profile-summary'),
    path('profile/update/', views.update_profile, name='update-profile'),
    path('password/change/', views.change_password, name='change-password'),
    
    # Student profile
    path('student/', views.StudentProfileView.as_view(), name='student-profile'),
    path('student/create/', views.StudentCreateView.as_view(), name='student-create'),
    
    # Faculty profile
    path('faculty/', views.FacultyProfileView.as_view(), name='faculty-profile'),
    path('faculty/create/', views.FacultyCreateView.as_view(), name='faculty-create'),
    path('faculty/list/', views.faculty_list, name='faculty-list'),
    
    # Student list (for faculty/admin)
    path('students/', views.student_list, name='student-list'),
    path('branches/', views.branches_list, name='branches-list'),
    
    # OTP verification
    path('otp/request/', views.request_otp, name='request-otp'),
    path('otp/verify/', views.verify_otp, name='verify-otp'),
    path('otp/test/', views.test_otp, name='test-otp'),
    
    # Two-Factor Authentication
    path('2fa/setup/', views.setup_2fa, name='setup-2fa'),
    path('2fa/verify/', views.verify_2fa, name='verify-2fa'),
    path('2fa/disable/', views.disable_2fa, name='disable-2fa'),
    path('2fa/status/', views.get_2fa_status, name='2fa-status'),
    path('2fa/backup-codes/', views.generate_backup_codes, name='generate-backup-codes'),
    
    # Device Session Management
    path('sessions/', views.get_active_sessions, name='active-sessions'),
    path('create-session/', views.create_device_session, name='create-device-session'),
    path('sessions/<int:session_id>/deactivate/', views.deactivate_session, name='deactivate-session'),
    path('sessions/logout-all/', views.logout_all_devices, name='logout-all-devices'),
    
    # Enhanced Login
    path('login-2fa/', views.login_with_2fa, name='login-with-2fa'),
    
    # Simple Login for Flutter App
    path('login/', views.login, name='login'),
    path('logout/', views.logout, name='logout'),
    path('refresh/', views.refresh_token, name='refresh-token'),
    path('profile/', views.get_current_user, name='get-current-user'),
    
    # Registration with OTP
    path('register/', views.register, name='register'),
    path('verify-registration/', views.verify_registration_otp, name='verify-registration'),
    path('verify-usn/', views.verify_and_update_usn, name='verify-usn'),
    
    # Forgot Password Flow
    path('forgot-password/', views.forgot_password_request, name='forgot-password-request'),
    path('forgot-password/verify-otp/', views.forgot_password_verify_otp, name='forgot-password-verify-otp'),
    path('reset-password/', views.reset_password, name='reset-password'),
    
    # SSO Endpoints
    path('sso/login-url/', views.sso_login_url, name='sso-login-url'),
    path('sso/callback/', views.sso_callback, name='sso-callback'),
    path('sso/refresh-token/', views.sso_refresh_token, name='sso-refresh-token'),
    path('sso/logout/', views.sso_logout, name='sso-logout'),
]
