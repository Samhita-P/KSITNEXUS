"""
Test cases for authentication functionality
"""
import json
from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from unittest.mock import patch, MagicMock
from ..models import TwoFactorAuth, DeviceSession, OTPVerification
from ..two_factor_service import TwoFactorService
from ..otp_service import OTPService

User = get_user_model()


class AuthenticationTestCase(APITestCase):
    """Test cases for authentication endpoints"""
    
    def setUp(self):
        """Set up test data"""
        self.client = Client()
        self.user_data = {
            'username': 'testuser',
            'email': 'test@example.com',
            'password': 'testpass123',
            'first_name': 'Test',
            'last_name': 'User',
            'user_type': 'student'
        }
        self.user = User.objects.create_user(**self.user_data)
        
    def test_user_registration(self):
        """Test user registration endpoint"""
        url = reverse('register')
        data = {
            'username': 'newuser',
            'email': 'newuser@example.com',
            'password': 'newpass123',
            'first_name': 'New',
            'last_name': 'User',
            'user_type': 'student'
        }
        
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(User.objects.filter(username='newuser').exists())
        
    def test_user_login(self):
        """Test user login endpoint"""
        url = reverse('login')
        data = {
            'username': 'testuser',
            'password': 'testpass123'
        }
        
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
        
    def test_invalid_login(self):
        """Test login with invalid credentials"""
        url = reverse('login')
        data = {
            'username': 'testuser',
            'password': 'wrongpassword'
        }
        
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        
    def test_token_refresh(self):
        """Test token refresh endpoint"""
        # First login to get tokens
        login_url = reverse('login')
        login_data = {
            'username': 'testuser',
            'password': 'testpass123'
        }
        login_response = self.client.post(login_url, login_data, format='json')
        refresh_token = login_response.data['refresh']
        
        # Test refresh
        refresh_url = reverse('token_refresh')
        refresh_data = {'refresh': refresh_token}
        response = self.client.post(refresh_url, refresh_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)


class TwoFactorAuthenticationTestCase(APITestCase):
    """Test cases for Two-Factor Authentication"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.client.force_authenticate(user=self.user)
        
    def test_setup_2fa(self):
        """Test 2FA setup endpoint"""
        url = reverse('setup-2fa')
        response = self.client.post(url, {}, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('secret_key', response.data)
        self.assertIn('qr_code', response.data)
        self.assertIn('backup_codes', response.data)
        
        # Verify 2FA record was created
        self.assertTrue(TwoFactorAuth.objects.filter(user=self.user).exists())
        
    def test_verify_2fa(self):
        """Test 2FA verification endpoint"""
        # Setup 2FA first
        two_factor_auth = TwoFactorAuth.objects.create(
            user=self.user,
            secret_key='TEST123456789',
            is_enabled=False
        )
        
        # Mock TOTP verification
        with patch('apps.accounts.two_factor_service.pyotp.TOTP.verify') as mock_verify:
            mock_verify.return_value = True
            
            url = reverse('verify-2fa')
            data = {'code': '123456'}
            response = self.client.post(url, data, format='json')
            
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertTrue(response.data['enabled'])
            
            # Verify 2FA is enabled
            two_factor_auth.refresh_from_db()
            self.assertTrue(two_factor_auth.is_enabled)
            
    def test_disable_2fa(self):
        """Test 2FA disable endpoint"""
        # Setup enabled 2FA
        two_factor_auth = TwoFactorAuth.objects.create(
            user=self.user,
            secret_key='TEST123456789',
            is_enabled=True
        )
        
        url = reverse('disable-2fa')
        data = {
            'password': 'testpass123',
            'code': '123456'
        }
        
        with patch('apps.accounts.two_factor_service.pyotp.TOTP.verify') as mock_verify:
            mock_verify.return_value = True
            
            response = self.client.post(url, data, format='json')
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertTrue(response.data['disabled'])
            
            # Verify 2FA is disabled
            two_factor_auth.refresh_from_db()
            self.assertFalse(two_factor_auth.is_enabled)
            
    def test_get_2fa_status(self):
        """Test get 2FA status endpoint"""
        TwoFactorAuth.objects.create(
            user=self.user,
            secret_key='TEST123456789',
            is_enabled=True
        )
        
        url = reverse('2fa-status')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['is_enabled'])


class DeviceSessionTestCase(APITestCase):
    """Test cases for device session management"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.client.force_authenticate(user=self.user)
        
    def test_create_device_session(self):
        """Test device session creation"""
        url = reverse('login-2fa')
        data = {
            'username': 'testuser',
            'password': 'testpass123',
            'device_id': 'test-device-123',
            'device_name': 'Test Device',
            'device_type': 'mobile'
        }
        
        with patch('apps.accounts.views.authenticate') as mock_auth:
            mock_auth.return_value = self.user
            
            response = self.client.post(url, data, format='json')
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertIn('session_id', response.data)
            
            # Verify session was created
            self.assertTrue(DeviceSession.objects.filter(
                user=self.user,
                device_id='test-device-123'
            ).exists())
            
    def test_get_active_sessions(self):
        """Test get active sessions endpoint"""
        # Create test sessions
        DeviceSession.objects.create(
            user=self.user,
            device_id='device1',
            device_name='Device 1',
            device_type='mobile',
            ip_address='192.168.1.1',
            user_agent='Test Agent'
        )
        DeviceSession.objects.create(
            user=self.user,
            device_id='device2',
            device_name='Device 2',
            device_type='desktop',
            ip_address='192.168.1.2',
            user_agent='Test Agent 2'
        )
        
        url = reverse('active-sessions')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)
        
    def test_deactivate_session(self):
        """Test deactivate session endpoint"""
        session = DeviceSession.objects.create(
            user=self.user,
            device_id='test-device',
            device_name='Test Device',
            device_type='mobile',
            ip_address='192.168.1.1',
            user_agent='Test Agent'
        )
        
        url = reverse('deactivate-session', kwargs={'session_id': session.id})
        response = self.client.post(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify session is deactivated
        session.refresh_from_db()
        self.assertFalse(session.is_active)
        
    def test_logout_all_devices(self):
        """Test logout all devices endpoint"""
        # Create multiple sessions
        DeviceSession.objects.create(
            user=self.user,
            device_id='device1',
            device_name='Device 1',
            device_type='mobile',
            ip_address='192.168.1.1',
            user_agent='Test Agent'
        )
        DeviceSession.objects.create(
            user=self.user,
            device_id='device2',
            device_name='Device 2',
            device_type='desktop',
            ip_address='192.168.1.2',
            user_agent='Test Agent 2'
        )
        
        url = reverse('logout-all-devices')
        data = {'current_session_id': 1}
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('deactivated_count', response.data)


class OTPVerificationTestCase(APITestCase):
    """Test cases for OTP verification"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
    def test_request_otp(self):
        """Test OTP request endpoint"""
        url = reverse('request-otp')
        data = {'phone_number': '+1234567890'}
        
        with patch('apps.accounts.otp_service.OTPService.send_otp') as mock_send:
            mock_send.return_value = MagicMock()
            
            response = self.client.post(url, data, format='json')
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertIn('message', response.data)
            
    def test_verify_otp(self):
        """Test OTP verification endpoint"""
        # Create OTP record
        OTPVerification.objects.create(
            user=self.user,
            phone_number='+1234567890',
            otp_code='123456',
            is_verified=False
        )
        
        url = reverse('verify-otp')
        data = {
            'phone_number': '+1234567890',
            'otp_code': '123456'
        }
        
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['verified'])
        
    def test_invalid_otp(self):
        """Test OTP verification with invalid code"""
        url = reverse('verify-otp')
        data = {
            'phone_number': '+1234567890',
            'otp_code': '999999'
        }
        
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(response.data['verified'])


class OTPServiceTestCase(TestCase):
    """Test cases for OTP service"""
    
    def setUp(self):
        """Set up test data"""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
    def test_generate_otp(self):
        """Test OTP generation"""
        service = OTPService()
        otp = service.generate_otp()
        
        self.assertEqual(len(otp), 6)
        self.assertTrue(otp.isdigit())
        
    def test_verify_otp(self):
        """Test OTP verification"""
        service = OTPService()
        otp = service.generate_otp()
        
        # Test valid OTP
        result = service.verify_otp(otp, otp)
        self.assertTrue(result)
        
        # Test invalid OTP
        result = service.verify_otp(otp, '000000')
        self.assertFalse(result)
