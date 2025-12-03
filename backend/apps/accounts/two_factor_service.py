"""
Two-Factor Authentication service for KSIT Nexus
"""
import secrets
import pyotp
import qrcode
import io
import base64
from django.conf import settings
from django.utils import timezone
from django.core.files.base import ContentFile
from .models import TwoFactorAuth, DeviceSession, User
from .otp_service import OTPService


class TwoFactorService:
    """Service for Two-Factor Authentication operations"""
    
    @staticmethod
    def generate_secret_key():
        """Generate a random secret key for TOTP"""
        return pyotp.random_base32()
    
    @staticmethod
    def generate_backup_codes(count=10):
        """Generate backup codes for 2FA"""
        return [secrets.token_hex(4).upper() for _ in range(count)]
    
    @staticmethod
    def setup_2fa(user):
        """Setup 2FA for a user"""
        # Generate secret key and backup codes
        secret_key = TwoFactorService.generate_secret_key()
        backup_codes = TwoFactorService.generate_backup_codes()
        
        # Create or update 2FA record
        two_factor_auth, created = TwoFactorAuth.objects.get_or_create(
            user=user,
            defaults={
                'secret_key': secret_key,
                'backup_codes': backup_codes,
                'is_enabled': False
            }
        )
        
        if not created:
            two_factor_auth.secret_key = secret_key
            two_factor_auth.backup_codes = backup_codes
            two_factor_auth.is_enabled = False
            two_factor_auth.save()
        
        return two_factor_auth
    
    @staticmethod
    def generate_qr_code(user, secret_key):
        """Generate QR code for authenticator app setup"""
        # Create TOTP URI
        totp_uri = pyotp.totp.TOTP(secret_key).provisioning_uri(
            name=user.email,
            issuer_name="KSIT Nexus"
        )
        
        # Generate QR code
        qr = qrcode.QRCode(version=1, box_size=10, border=5)
        qr.add_data(totp_uri)
        qr.make(fit=True)
        
        # Create image
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Convert to base64
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        img_str = base64.b64encode(buffer.getvalue()).decode()
        
        return f"data:image/png;base64,{img_str}"
    
    @staticmethod
    def verify_totp_code(user, code):
        """Verify TOTP code from authenticator app"""
        try:
            two_factor_auth = user.two_factor_auth
            if not two_factor_auth or not two_factor_auth.is_enabled:
                return False, "2FA not enabled"
            
            totp = pyotp.TOTP(two_factor_auth.secret_key)
            is_valid = totp.verify(code, valid_window=1)
            
            if is_valid:
                return True, "Code verified successfully"
            else:
                return False, "Invalid code"
                
        except Exception as e:
            return False, f"Verification failed: {str(e)}"
    
    @staticmethod
    def verify_backup_code(user, code):
        """Verify backup code"""
        try:
            two_factor_auth = user.two_factor_auth
            if not two_factor_auth or not two_factor_auth.is_enabled:
                return False, "2FA not enabled"
            
            backup_codes = two_factor_auth.backup_codes
            if code.upper() in backup_codes:
                # Remove used backup code
                backup_codes.remove(code.upper())
                two_factor_auth.backup_codes = backup_codes
                two_factor_auth.save()
                return True, "Backup code verified successfully"
            else:
                return False, "Invalid backup code"
                
        except Exception as e:
            return False, f"Backup code verification failed: {str(e)}"
    
    @staticmethod
    def enable_2fa(user, verification_code):
        """Enable 2FA after verification"""
        try:
            two_factor_auth = user.two_factor_auth
            if not two_factor_auth:
                return False, "2FA not set up"
            
            # Verify the code
            is_valid, message = TwoFactorService.verify_totp_code(user, verification_code)
            if not is_valid:
                return False, message
            
            # Enable 2FA
            two_factor_auth.is_enabled = True
            two_factor_auth.save()
            
            return True, "2FA enabled successfully"
            
        except Exception as e:
            return False, f"Failed to enable 2FA: {str(e)}"
    
    @staticmethod
    def disable_2fa(user, password):
        """Disable 2FA"""
        try:
            # Verify password
            if not user.check_password(password):
                return False, "Invalid password"
            
            two_factor_auth = user.two_factor_auth
            if two_factor_auth:
                two_factor_auth.is_enabled = False
                two_factor_auth.secret_key = None
                two_factor_auth.backup_codes = []
                two_factor_auth.save()
            
            return True, "2FA disabled successfully"
            
        except Exception as e:
            return False, f"Failed to disable 2FA: {str(e)}"
    
    @staticmethod
    def generate_new_backup_codes(user, password):
        """Generate new backup codes"""
        try:
            # Verify password
            if not user.check_password(password):
                return False, "Invalid password", []
            
            two_factor_auth = user.two_factor_auth
            if not two_factor_auth or not two_factor_auth.is_enabled:
                return False, "2FA not enabled", []
            
            # Generate new backup codes
            new_backup_codes = TwoFactorService.generate_backup_codes()
            two_factor_auth.backup_codes = new_backup_codes
            two_factor_auth.save()
            
            return True, "New backup codes generated", new_backup_codes
            
        except Exception as e:
            return False, f"Failed to generate backup codes: {str(e)}", []


class DeviceSessionService:
    """Service for device session management"""
    
    @staticmethod
    def create_device_session(user, device_id, device_name, device_type, ip_address, user_agent):
        """Create a new device session"""
        try:
            # Deactivate existing session for this device
            DeviceSession.objects.filter(
                device_id=device_id,
                user=user
            ).update(is_active=False)
            
            # Create new session
            session = DeviceSession.objects.create(
                user=user,
                device_id=device_id,
                device_name=device_name,
                device_type=device_type,
                ip_address=ip_address,
                user_agent=user_agent,
                is_active=True
            )
            
            return session
            
        except Exception as e:
            return None
    
    @staticmethod
    def get_active_sessions(user):
        """Get all active sessions for a user"""
        return DeviceSession.objects.filter(
            user=user,
            is_active=True
        ).order_by('-last_activity')
    
    @staticmethod
    def deactivate_session(user, session_id):
        """Deactivate a specific session"""
        try:
            session = DeviceSession.objects.get(
                id=session_id,
                user=user,
                is_active=True
            )
            session.is_active = False
            session.save()
            return True
        except DeviceSession.DoesNotExist:
            return False
    
    @staticmethod
    def deactivate_all_sessions(user, current_session_id=None):
        """Deactivate all sessions except current one"""
        sessions = DeviceSession.objects.filter(
            user=user,
            is_active=True
        )
        
        if current_session_id:
            sessions = sessions.exclude(id=current_session_id)
        
        sessions.update(is_active=False)
        return sessions.count()
    
    @staticmethod
    def cleanup_expired_sessions():
        """Clean up expired sessions"""
        expired_sessions = DeviceSession.objects.filter(
            is_active=True
        ).exclude(
            last_activity__gte=timezone.now() - timezone.timedelta(hours=24)
        )
        
        count = expired_sessions.count()
        expired_sessions.update(is_active=False)
        return count
