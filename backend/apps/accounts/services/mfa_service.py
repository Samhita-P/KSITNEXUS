"""
Enhanced MFA Service
"""
import secrets
import pyotp
import qrcode
import io
import base64
from datetime import timedelta
from django.conf import settings
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.core.cache import cache
from apps.accounts.models_mfa import MFAMethod, TrustedDevice, MFAAttempt, MFARecoveryCode
from apps.accounts.otp_service import OTPService
from apps.shared.services.audit_service import AuditService

User = get_user_model()


class MFAService:
    """Enhanced MFA Service"""
    
    MAX_ATTEMPTS = 5
    ATTEMPT_WINDOW = 300  # 5 minutes
    TRUSTED_DEVICE_DURATION = timedelta(days=30)
    RECOVERY_CODE_COUNT = 10
    
    @staticmethod
    def setup_totp(user: User):
        """Setup TOTP (Authenticator App) method"""
        secret_key = pyotp.random_base32()
        
        mfa_method, created = MFAMethod.objects.get_or_create(
            user=user,
            method_type='totp',
            defaults={
                'secret_key': secret_key,
                'is_enabled': False,
                'is_primary': False,
            }
        )
        
        if not created:
            mfa_method.secret_key = secret_key
            mfa_method.is_enabled = False
            mfa_method.save()
        
        # Generate QR code
        qr_code = MFAService.generate_qr_code(user, secret_key)
        
        return {
            'method': mfa_method,
            'secret_key': secret_key,
            'qr_code': qr_code,
        }
    
    @staticmethod
    def setup_sms(user: User, phone_number: str):
        """Setup SMS method"""
        mfa_method, created = MFAMethod.objects.get_or_create(
            user=user,
            method_type='sms',
            defaults={
                'phone_number': phone_number,
                'is_enabled': False,
                'is_primary': False,
            }
        )
        
        if not created:
            mfa_method.phone_number = phone_number
            mfa_method.is_enabled = False
            mfa_method.save()
        
        return mfa_method
    
    @staticmethod
    def setup_email(user: User, email: str = None):
        """Setup Email method"""
        email = email or user.email
        
        mfa_method, created = MFAMethod.objects.get_or_create(
            user=user,
            method_type='email',
            defaults={
                'email': email,
                'is_enabled': False,
                'is_primary': False,
            }
        )
        
        if not created:
            mfa_method.email = email
            mfa_method.is_enabled = False
            mfa_method.save()
        
        return mfa_method
    
    @staticmethod
    def generate_qr_code(user: User, secret_key: str) -> str:
        """Generate QR code for TOTP setup"""
        totp_uri = pyotp.totp.TOTP(secret_key).provisioning_uri(
            name=user.email or user.username,
            issuer_name=getattr(settings, 'OTP_TOTP_ISSUER', 'KSIT Nexus')
        )
        
        qr = qrcode.QRCode(version=1, box_size=10, border=5)
        qr.add_data(totp_uri)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        img_str = base64.b64encode(buffer.getvalue()).decode()
        
        return f"data:image/png;base64,{img_str}"
    
    @staticmethod
    def generate_backup_codes(count: int = None) -> list:
        """Generate backup codes"""
        count = count or MFAService.RECOVERY_CODE_COUNT
        return [secrets.token_hex(4).upper() for _ in range(count)]
    
    @staticmethod
    def verify_totp(user: User, code: str, request=None) -> tuple:
        """Verify TOTP code"""
        try:
            mfa_method = MFAMethod.objects.get(user=user, method_type='totp', is_enabled=True)
            
            # Check rate limiting
            if not MFAService._check_rate_limit(user, 'totp', request):
                return False, "Too many attempts. Please try again later."
            
            totp = pyotp.TOTP(mfa_method.secret_key)
            is_valid = totp.verify(code, valid_window=1)
            
            # Log attempt
            MFAService._log_attempt(user, 'totp', is_valid, request)
            
            if is_valid:
                mfa_method.last_used_at = timezone.now()
                mfa_method.save()
                return True, "Code verified successfully"
            else:
                return False, "Invalid code"
                
        except MFAMethod.DoesNotExist:
            return False, "TOTP method not enabled"
        except Exception as e:
            return False, f"Verification failed: {str(e)}"
    
    @staticmethod
    def verify_sms(user: User, code: str, request=None) -> tuple:
        """Verify SMS code"""
        try:
            mfa_method = MFAMethod.objects.get(user=user, method_type='sms', is_enabled=True)
            
            # Check rate limiting
            if not MFAService._check_rate_limit(user, 'sms', request):
                return False, "Too many attempts. Please try again later."
            
            # Verify OTP
            is_valid, message = OTPService.verify_otp(mfa_method.phone_number, code, user)
            
            # Log attempt
            MFAService._log_attempt(user, 'sms', is_valid, request)
            
            if is_valid:
                mfa_method.last_used_at = timezone.now()
                mfa_method.save()
                return True, "Code verified successfully"
            else:
                return False, "Invalid code"
                
        except MFAMethod.DoesNotExist:
            return False, "SMS method not enabled"
        except Exception as e:
            return False, f"Verification failed: {str(e)}"
    
    @staticmethod
    def send_sms_code(user: User, request=None) -> tuple:
        """Send SMS code"""
        try:
            mfa_method = MFAMethod.objects.get(user=user, method_type='sms', is_enabled=True)
            
            # Check rate limiting
            cache_key = f'mfa_sms_sent_{user.id}'
            if cache.get(cache_key):
                return False, "SMS code already sent. Please wait before requesting a new one."
            
            # Send OTP
            otp_code = OTPService.send_otp(mfa_method.phone_number, user, 'login')
            
            # Cache to prevent spam
            cache.set(cache_key, True, 60)  # 1 minute
            
            return True, "SMS code sent successfully"
            
        except MFAMethod.DoesNotExist:
            return False, "SMS method not enabled"
        except Exception as e:
            return False, f"Failed to send SMS: {str(e)}"
    
    @staticmethod
    def verify_email(user: User, code: str, request=None) -> tuple:
        """Verify Email code"""
        try:
            mfa_method = MFAMethod.objects.get(user=user, method_type='email', is_enabled=True)
            
            # Check rate limiting
            if not MFAService._check_rate_limit(user, 'email', request):
                return False, "Too many attempts. Please try again later."
            
            # Verify OTP
            email = mfa_method.email or user.email
            is_valid, message = OTPService.verify_otp(email, code, user)
            
            # Log attempt
            MFAService._log_attempt(user, 'email', is_valid, request)
            
            if is_valid:
                mfa_method.last_used_at = timezone.now()
                mfa_method.save()
                return True, "Code verified successfully"
            else:
                return False, "Invalid code"
                
        except MFAMethod.DoesNotExist:
            return False, "Email method not enabled"
        except Exception as e:
            return False, f"Verification failed: {str(e)}"
    
    @staticmethod
    def send_email_code(user: User, request=None) -> tuple:
        """Send Email code"""
        try:
            mfa_method = MFAMethod.objects.get(user=user, method_type='email', is_enabled=True)
            
            # Check rate limiting
            cache_key = f'mfa_email_sent_{user.id}'
            if cache.get(cache_key):
                return False, "Email code already sent. Please wait before requesting a new one."
            
            # Send OTP
            email = mfa_method.email or user.email
            otp_code = OTPService.send_otp(email, user, 'login')
            
            # Cache to prevent spam
            cache.set(cache_key, True, 60)  # 1 minute
            
            return True, "Email code sent successfully"
            
        except MFAMethod.DoesNotExist:
            return False, "Email method not enabled"
        except Exception as e:
            return False, f"Failed to send email: {str(e)}"
    
    @staticmethod
    def verify_backup_code(user: User, code: str, request=None) -> tuple:
        """Verify backup code"""
        try:
            mfa_method = MFAMethod.objects.get(user=user, method_type='backup', is_enabled=True)
            
            # Check rate limiting
            if not MFAService._check_rate_limit(user, 'backup', request):
                return False, "Too many attempts. Please try again later."
            
            backup_codes = mfa_method.backup_codes or []
            code_upper = code.upper()
            
            if code_upper in backup_codes:
                # Remove used backup code
                backup_codes.remove(code_upper)
                mfa_method.backup_codes = backup_codes
                mfa_method.save()
                
                # Log attempt
                MFAService._log_attempt(user, 'backup', True, request)
                
                return True, "Backup code verified successfully"
            else:
                # Log attempt
                MFAService._log_attempt(user, 'backup', False, request, "Invalid backup code")
                
                return False, "Invalid backup code"
                
        except MFAMethod.DoesNotExist:
            return False, "Backup codes not enabled"
        except Exception as e:
            return False, f"Verification failed: {str(e)}"
    
    @staticmethod
    def verify_recovery_code(user: User, code: str, request=None) -> tuple:
        """Verify recovery code"""
        try:
            recovery_code = MFARecoveryCode.objects.get(
                user=user,
                code=code.upper(),
                is_used=False
            )
            
            if not recovery_code.is_valid():
                return False, "Recovery code has expired"
            
            # Mark as used
            recovery_code.is_used = True
            recovery_code.used_at = timezone.now()
            recovery_code.save()
            
            # Log attempt
            MFAService._log_attempt(user, 'recovery', True, request)
            
            # Log to audit
            if request:
                AuditService.log_action(
                    user=user,
                    action='password_reset',
                    resource_type='User',
                    resource_id=user.id,
                    request=request,
                    description=f"Recovery code used: {code[:8]}...",
                    severity='high',
                    is_success=True
                )
            
            return True, "Recovery code verified successfully"
            
        except MFARecoveryCode.DoesNotExist:
            # Log attempt
            MFAService._log_attempt(user, 'recovery', False, request, "Invalid recovery code")
            
            return False, "Invalid recovery code"
        except Exception as e:
            return False, f"Verification failed: {str(e)}"
    
    @staticmethod
    def generate_recovery_codes(user: User, count: int = None) -> list:
        """Generate recovery codes"""
        count = count or MFAService.RECOVERY_CODE_COUNT
        
        # Generate codes
        codes = [secrets.token_hex(8).upper() for _ in range(count)]
        
        # Create recovery code records
        recovery_codes = []
        for code in codes:
            recovery_code = MFARecoveryCode.objects.create(
                user=user,
                code=code,
                expires_at=timezone.now() + timedelta(days=90)  # 90 days validity
            )
            recovery_codes.append(recovery_code)
        
        return codes
    
    @staticmethod
    def enable_method(user: User, method_type: str, verification_code: str = None) -> tuple:
        """Enable MFA method"""
        try:
            mfa_method = MFAMethod.objects.get(user=user, method_type=method_type)
            
            # Verify code if provided
            if verification_code:
                if method_type == 'totp':
                    is_valid, message = MFAService.verify_totp(user, verification_code)
                elif method_type == 'sms':
                    is_valid, message = MFAService.verify_sms(user, verification_code)
                elif method_type == 'email':
                    is_valid, message = MFAService.verify_email(user, verification_code)
                else:
                    is_valid = True
                    message = "No verification required"
                
                if not is_valid:
                    return False, message
            
            # Enable method
            mfa_method.is_enabled = True
            
            # Set as primary if no primary method exists
            if not MFAMethod.objects.filter(user=user, is_primary=True, is_enabled=True).exists():
                mfa_method.is_primary = True
            
            mfa_method.save()
            
            return True, f"{method_type.upper()} method enabled successfully"
            
        except MFAMethod.DoesNotExist:
            return False, f"{method_type.upper()} method not set up"
        except Exception as e:
            return False, f"Failed to enable method: {str(e)}"
    
    @staticmethod
    def disable_method(user: User, method_type: str, password: str = None) -> tuple:
        """Disable MFA method"""
        try:
            # Verify password if provided
            if password and not user.check_password(password):
                return False, "Invalid password"
            
            mfa_method = MFAMethod.objects.get(user=user, method_type=method_type)
            mfa_method.is_enabled = False
            mfa_method.is_primary = False
            mfa_method.save()
            
            # If this was the primary method, set another as primary
            if not MFAMethod.objects.filter(user=user, is_primary=True, is_enabled=True).exists():
                # Set first enabled method as primary
                first_enabled = MFAMethod.objects.filter(user=user, is_enabled=True).first()
                if first_enabled:
                    first_enabled.is_primary = True
                    first_enabled.save()
            
            return True, f"{method_type.upper()} method disabled successfully"
            
        except MFAMethod.DoesNotExist:
            return False, f"{method_type.upper()} method not found"
        except Exception as e:
            return False, f"Failed to disable method: {str(e)}"
    
    @staticmethod
    def set_primary_method(user: User, method_type: str) -> tuple:
        """Set primary MFA method"""
        try:
            mfa_method = MFAMethod.objects.get(user=user, method_type=method_type, is_enabled=True)
            
            # Unset other primary methods
            MFAMethod.objects.filter(user=user, is_primary=True).update(is_primary=False)
            
            # Set this as primary
            mfa_method.is_primary = True
            mfa_method.save()
            
            return True, f"{method_type.upper()} method set as primary"
            
        except MFAMethod.DoesNotExist:
            return False, f"{method_type.upper()} method not found or not enabled"
        except Exception as e:
            return False, f"Failed to set primary method: {str(e)}"
    
    @staticmethod
    def get_enabled_methods(user: User) -> list:
        """Get all enabled MFA methods for user"""
        return list(MFAMethod.objects.filter(user=user, is_enabled=True).order_by('-is_primary'))
    
    @staticmethod
    def get_primary_method(user: User) -> MFAMethod:
        """Get primary MFA method for user"""
        return MFAMethod.objects.filter(user=user, is_primary=True, is_enabled=True).first()
    
    @staticmethod
    def is_device_trusted(user: User, device_id: str) -> bool:
        """Check if device is trusted"""
        try:
            trusted_device = TrustedDevice.objects.get(user=user, device_id=device_id)
            return trusted_device.is_valid()
        except TrustedDevice.DoesNotExist:
            return False
    
    @staticmethod
    def trust_device(user: User, device_id: str, device_name: str, device_type: str, 
                     ip_address: str = None, user_agent: str = '', request=None) -> TrustedDevice:
        """Trust a device"""
        trusted_device, created = TrustedDevice.objects.get_or_create(
            user=user,
            device_id=device_id,
            defaults={
                'device_name': device_name,
                'device_type': device_type,
                'ip_address': ip_address,
                'user_agent': user_agent,
                'is_trusted': True,
                'trusted_until': timezone.now() + MFAService.TRUSTED_DEVICE_DURATION,
            }
        )
        
        if not created:
            trusted_device.is_trusted = True
            trusted_device.trusted_until = timezone.now() + MFAService.TRUSTED_DEVICE_DURATION
            trusted_device.last_used_at = timezone.now()
            trusted_device.save()
        
        # Log to audit
        if request:
            AuditService.log_action(
                user=user,
                action='login',
                resource_type='Device',
                request=request,
                description=f"Device trusted: {device_name}",
                severity='medium',
                is_success=True
            )
        
        return trusted_device
    
    @staticmethod
    def untrust_device(user: User, device_id: str) -> bool:
        """Untrust a device"""
        try:
            trusted_device = TrustedDevice.objects.get(user=user, device_id=device_id)
            trusted_device.is_trusted = False
            trusted_device.trusted_until = None
            trusted_device.save()
            return True
        except TrustedDevice.DoesNotExist:
            return False
    
    @staticmethod
    def get_trusted_devices(user: User) -> list:
        """Get all trusted devices for user"""
        return list(TrustedDevice.objects.filter(user=user, is_trusted=True).order_by('-last_used_at'))
    
    @staticmethod
    def _check_rate_limit(user: User, method_type: str, request=None) -> bool:
        """Check rate limiting for MFA attempts"""
        ip_address = None
        if request:
            ip_address = request.META.get('REMOTE_ADDR')
        
        # Check attempts in last window
        window_start = timezone.now() - timedelta(seconds=MFAService.ATTEMPT_WINDOW)
        recent_attempts = MFAAttempt.objects.filter(
            user=user,
            method_type=method_type,
            created_at__gte=window_start,
            is_successful=False
        )
        
        if ip_address:
            recent_attempts = recent_attempts.filter(ip_address=ip_address)
        
        if recent_attempts.count() >= MFAService.MAX_ATTEMPTS:
            return False
        
        return True
    
    @staticmethod
    def _log_attempt(user: User, method_type: str, is_successful: bool, request=None, 
                     failure_reason: str = ''):
        """Log MFA attempt"""
        ip_address = None
        user_agent = ''
        
        if request:
            ip_address = request.META.get('REMOTE_ADDR')
            user_agent = request.META.get('HTTP_USER_AGENT', '')
        
        MFAAttempt.objects.create(
            user=user,
            method_type=method_type,
            ip_address=ip_address,
            user_agent=user_agent,
            is_successful=is_successful,
            failure_reason=failure_reason
        )

