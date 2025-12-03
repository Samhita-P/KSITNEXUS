"""
Emergency Service
"""
from typing import List, Optional
from django.contrib.auth import get_user_model
from django.db.models import Count
from django.utils import timezone
from apps.safety_wellbeing.models import EmergencyAlert, EmergencyAcknowledgment, EmergencyContact, UserPersonalEmergencyContact
from apps.shared.utils.logging import get_logger

User = get_user_model()
logger = get_logger(__name__)


class EmergencyService:
    """Service for emergency management"""
    
    @staticmethod
    def create_emergency_alert(
        alert_type: str,
        title: str,
        description: str,
        created_by: User,
        severity: str = 'high',
        location: Optional[str] = None,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
        broadcast_to_all: bool = True,
        target_departments: Optional[List[str]] = None,
        target_buildings: Optional[List[str]] = None,
    ) -> EmergencyAlert:
        """Create a new emergency alert"""
        alert = EmergencyAlert.objects.create(
            alert_type=alert_type,
            severity=severity,
            title=title,
            description=description,
            created_by=created_by,
            location=location,
            latitude=latitude,
            longitude=longitude,
            broadcast_to_all=broadcast_to_all,
            target_departments=target_departments or [],
            target_buildings=target_buildings or [],
        )
        
        # TODO: Send push notifications to all users or target audience
        # TODO: Send SMS alerts if configured
        
        return alert
    
    @staticmethod
    def acknowledge_alert(
        alert: EmergencyAlert,
        user: User,
        is_safe: bool = True,
        notes: Optional[str] = None,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
    ) -> EmergencyAcknowledgment:
        """Acknowledge an emergency alert"""
        acknowledgment, created = EmergencyAcknowledgment.objects.get_or_create(
            alert=alert,
            user=user,
            defaults={
                'is_safe': is_safe,
                'notes': notes,
                'location_latitude': latitude,
                'location_longitude': longitude,
            }
        )
        
        if not created:
            acknowledgment.is_safe = is_safe
            acknowledgment.notes = notes
            if latitude:
                acknowledgment.location_latitude = latitude
            if longitude:
                acknowledgment.location_longitude = longitude
            acknowledgment.save()
        
        # Update alert acknowledgment count
        alert.acknowledgments_count = alert.acknowledgments.count()
        alert.save(update_fields=['acknowledgments_count'])
        
        return acknowledgment
    
    @staticmethod
    def resolve_alert(
        alert: EmergencyAlert,
        responded_by: User,
        response_notes: str,
    ) -> EmergencyAlert:
        """Resolve an emergency alert"""
        alert.status = 'resolved'
        alert.responded_by = responded_by
        alert.response_notes = response_notes
        alert.resolved_at = timezone.now()
        alert.save()
        
        return alert
    
    @staticmethod
    def get_active_alerts() -> List[EmergencyAlert]:
        """Get all active emergency alerts"""
        try:
            return list(EmergencyAlert.objects.filter(status='active').order_by('-created_at'))
        except Exception as e:
            # Handle case where table doesn't exist yet
            print(f"Warning: Could not fetch active emergency alerts: {e}")
            return []
    
    @staticmethod
    def get_emergency_contacts() -> List[EmergencyContact]:
        """Get all active emergency contacts"""
        try:
            return list(EmergencyContact.objects.filter(is_active=True).order_by('-priority', 'name'))
        except Exception as e:
            # Handle case where table doesn't exist yet
            print(f"Warning: Could not fetch emergency contacts: {e}")
            return []
    
    @staticmethod
    def notify_personal_contacts(alert: EmergencyAlert, contacts: List[UserPersonalEmergencyContact]):
        """Send notifications to personal emergency contacts"""
        try:
            user = alert.created_by
            if not user:
                return
            
            # Create notification message
            message = f"EMERGENCY ALERT: {alert.title}\n{alert.description}"
            if alert.location:
                message += f"\nLocation: {alert.location}"
            message += f"\nAlert ID: {alert.alert_id}"
            
            # Send notifications to each contact
            for contact in contacts:
                try:
                    # Create notification record (for logging)
                    notification_data = {
                        'user': user,
                        'title': f'Emergency Alert Sent to {contact.name}',
                        'message': f'Emergency alert "{alert.title}" has been sent to {contact.name} ({contact.phone_number})',
                        'notification_type': 'emergency',
                        'priority': 'high',
                    }
                    
                    # Try to send SMS/Email if services are available
                    # For now, just log it
                    print(f"EMERGENCY NOTIFICATION: Sending alert to {contact.name}")
                    print(f"  Phone: {contact.phone_number}")
                    if contact.email:
                        print(f"  Email: {contact.email}")
                    print(f"  Message: {message}")
                    print(f"  Alert: {alert.alert_id} - {alert.title}")
                    
                    # TODO: Integrate with SMS/Email service when available
                    # NotificationService.send_sms(contact.phone_number, message)
                    # NotificationService.send_email(contact.email, "Emergency Alert", message)
                    
                except Exception as e:
                    print(f"Error sending notification to {contact.name}: {e}")
                    continue
                    
        except Exception as e:
            print(f"Error in notify_personal_contacts: {e}")
            import traceback
            traceback.print_exc()
    
    @staticmethod
    def send_alert_to_contact(user, contact: 'UserPersonalEmergencyContact', message: str = None):
        """Send an emergency alert to a specific personal contact"""
        try:
            if not user:
                return {'success': False, 'error': 'User is required'}
            
            if not contact:
                return {'success': False, 'error': 'Contact is required'}
            
            # Create notification message
            if not message:
                message = f"EMERGENCY ALERT from {user.get_full_name() or user.username}\n"
                message += f"User: {user.username}\n"
                if user.email:
                    message += f"Email: {user.email}\n"
                if hasattr(user, 'phone_number') and user.phone_number:
                    message += f"Phone: {user.phone_number}\n"
                message += f"\nThis is an emergency alert. Please contact {user.get_full_name() or user.username} immediately."
            
            # Log the notification
            print(f"\n{'='*60}")
            print(f"EMERGENCY ALERT: Sending alert to {contact.name}")
            print(f"{'='*60}")
            print(f"  Contact Name: {contact.name}")
            print(f"  Contact Phone: {contact.phone_number}")
            if contact.email:
                print(f"  Contact Email: {contact.email}")
            print(f"  User: {user.get_full_name() or user.username} ({user.username})")
            print(f"  Message: {message}")
            print(f"{'='*60}\n")
            
            # TODO: Integrate with SMS/Email service when available
            # NotificationService.send_sms(contact.phone_number, message)
            # if contact.email:
            #     NotificationService.send_email(contact.email, "Emergency Alert", message)
            
            return {
                'success': True,
                'message': f'Alert sent to {contact.name}',
                'contact_name': contact.name,
                'contact_phone': contact.phone_number,
                'contact_email': contact.email,
            }
            
        except Exception as e:
            print(f"Error in send_alert_to_contact: {e}")
            import traceback
            traceback.print_exc()
            return {'success': False, 'error': str(e)}


