"""
OTP service for KSIT Nexus - Terminal only for development
"""
import os
import random
import string
import sys
from django.conf import settings
from django.utils import timezone
from .models import OTPVerification, User


class OTPService:
    """
    OTP service that prints OTP to terminal during development
    """
    
    @staticmethod
    def generate_otp(length=6):
        """
        Generate OTP:
        - In Render production → always returns "123456"
        - In local development → random 6-digit OTP
        """
        # Detect production on Render
        if os.environ.get("RENDER") == "true" and not settings.DEBUG:
            return "123456"
        
        # Local development fallback
        return ''.join(random.choices(string.digits, k=length))
    
    @staticmethod
    def send_otp(phone_number, user=None, purpose='registration'):
        """
        Send OTP to phone number (prints to terminal in development)
        For testing mode in Render production, this is a no-op placeholder
        """
        # Validate phone number
        if not phone_number:
            error_msg = "ERROR: Phone number is required to send OTP"
            print(f"\n{'!'*50}")
            print(error_msg)
            print(f"{'!'*50}\n")
            sys.stdout.flush()
            raise ValueError(error_msg)
        
        # Generate OTP FIRST - before any database operations
        otp_code = OTPService.generate_otp()
        expires_at = timezone.now() + timezone.timedelta(minutes=10)
        
        # For testing mode, do nothing in production (no SMS/Email sending)
        # Just print for debugging
        print(f"OTP for debugging: {otp_code}")
        sys.stdout.flush()
        
        print(f"\n{'='*60}")
        print(f"OTPService.send_otp CALLED")
        print(f"Phone Number: {phone_number}")
        print(f"User: {user.username if user else 'None'}")
        print(f"Purpose: {purpose}")
        print(f"{'='*60}")
        sys.stdout.flush()
        
        # PRINT OTP IMMEDIATELY - before any database operations that might fail
        purpose_text = purpose.replace('_', ' ').title()
        print(f"\n{'='*60}")
        print(f"  KSIT NEXUS - OTP VERIFICATION ({purpose_text})")
        print(f"{'='*60}")
        print(f"  Phone Number: {phone_number}")
        print(f"  User: {user.username if user else 'N/A'}")
        print(f"  OTP Code: {otp_code}")
        print(f"  Expires at: {expires_at}")
        print(f"{'='*60}")
        print(f"  ⚠️  COPY THIS OTP CODE: {otp_code}")
        print(f"{'='*60}\n")
        sys.stdout.flush()  # Force immediate output - OTP is NOW VISIBLE
        
        # Create or update OTP verification record
        otp_verification = None
        created = False
        
        # Handle case where purpose field doesn't exist yet (before migration)
        try:
            otp_verification, created = OTPVerification.objects.get_or_create(
                phone_number=phone_number,
                user=user,
                purpose=purpose,
                defaults={
                    'otp_code': otp_code,
                    'expires_at': expires_at
                }
            )
            print(f"OTPVerification created/updated: {created}, ID: {otp_verification.id}")
            sys.stdout.flush()
        except Exception as e:
            print(f"Error with purpose field, trying fallback: {e}")
            sys.stdout.flush()
            # Fallback for when purpose field doesn't exist yet
            try:
                otp_verification, created = OTPVerification.objects.get_or_create(
                    phone_number=phone_number,
                    user=user,
                    defaults={
                        'otp_code': otp_code,
                        'expires_at': expires_at
                    }
                )
                print(f"OTPVerification created/updated (fallback): {created}, ID: {otp_verification.id}")
                sys.stdout.flush()
            except Exception as e2:
                print(f"CRITICAL ERROR: Failed to create OTP record: {e2}")
                print(f"OTP will still be printed below, but verification may fail!")
                sys.stdout.flush()
                # Create a temporary object for display purposes
                class TempOTP:
                    def __init__(self):
                        self.otp_code = otp_code
                        self.expires_at = expires_at
                        self.created_at = timezone.now()
                otp_verification = TempOTP()
        
        if otp_verification and not created:
            try:
                otp_verification.otp_code = otp_code
                otp_verification.is_verified = False
                otp_verification.expires_at = expires_at
                otp_verification.save()
            except Exception as e:
                print(f"Warning: Could not update OTP record: {e}")
                sys.stdout.flush()
        
        # Also save OTP to a file for easy access (development only)
        try:
            import os
            file_path = os.path.join(settings.BASE_DIR, 'otp_codes.txt')
            with open(file_path, 'a', encoding='utf-8') as f:
                f.write(f"{timezone.now()} - {purpose_text} - {phone_number} - User: {user.username if user else 'N/A'} - OTP: {otp_code}\n")
            print(f"OTP also saved to: {file_path}")
            sys.stdout.flush()
        except Exception as e:
            print(f"Warning: Could not save OTP to file: {e}")
            sys.stdout.flush()
        
        # Return the OTP verification object if we have one
        if otp_verification and hasattr(otp_verification, 'id'):
            return otp_verification
        else:
            # If we couldn't create the DB record, still return something
            # The OTP was printed, so at least the user can see it
            raise Exception(f"OTP generated and printed, but database record creation failed. OTP Code: {otp_code}")
    
    @staticmethod
    def verify_otp(phone_number, otp_code, user=None):
        """
        Verify OTP code
        """
        try:
            otp_verification = OTPVerification.objects.get(
                phone_number=phone_number,
                otp_code=otp_code,
                is_verified=False
            )
            
            # Check if OTP is expired
            if otp_verification.is_expired():
                return False, "OTP has expired"
            
            # Mark as verified
            otp_verification.is_verified = True
            otp_verification.save()
            
            return True, "OTP verified successfully"
            
        except OTPVerification.DoesNotExist:
            return False, "Invalid OTP code"
    
    @staticmethod
    def verify_otp_for_user(user, otp_code, purpose='registration'):
        """
        Verify OTP code for a specific user
        """
        print(f"OTPService.verify_otp_for_user called with user={user.username}, otp_code={otp_code}, purpose={purpose}")
        
        try:
            # Find the most recent unverified OTP for this user with the specified purpose
            # Handle case where purpose field doesn't exist yet (before migration)
            try:
                otp_verification = OTPVerification.objects.filter(
                    user=user,
                    purpose=purpose,
                    is_verified=False
                ).order_by('-created_at').first()
                print(f"Found OTP verification with purpose: {otp_verification}")
            except Exception as e:
                print(f"Error with purpose field, trying fallback: {e}")
                # Fallback for when purpose field doesn't exist yet
                otp_verification = OTPVerification.objects.filter(
                    user=user,
                    is_verified=False
                ).order_by('-created_at').first()
                print(f"Found OTP verification without purpose: {otp_verification}")
            
            if not otp_verification:
                print(f"No OTP verification found for user {user.username}")
                return False, "No OTP found for this user"
            
            print(f"Found OTP verification: phone_number={otp_verification.phone_number}, otp_code={otp_verification.otp_code}, expires_at={otp_verification.expires_at}")
            
            # Check if OTP matches
            if otp_verification.otp_code != otp_code:
                print(f"OTP mismatch: expected={otp_verification.otp_code}, received={otp_code}")
                return False, "Invalid OTP code"
            
            # Check if OTP is expired
            if otp_verification.is_expired():
                print(f"OTP has expired: expires_at={otp_verification.expires_at}")
                return False, "OTP has expired"
            
            # Mark as verified
            otp_verification.is_verified = True
            otp_verification.save()
            
            return True, "OTP verified successfully"
            
        except Exception as e:
            return False, f"OTP verification failed: {str(e)}"
    
    @staticmethod
    def is_phone_verified(phone_number, user=None):
        """
        Check if phone number is verified
        """
        return OTPVerification.objects.filter(
            phone_number=phone_number,
            is_verified=True,
            user=user
        ).exists()
    
    @staticmethod
    def cleanup_expired_otps():
        """
        Clean up expired OTP records
        """
        expired_count = OTPVerification.objects.filter(
            expires_at__lt=timezone.now()
        ).delete()[0]
        
        return expired_count
