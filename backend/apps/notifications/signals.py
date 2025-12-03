"""
Signal handlers for real-time notifications
"""

from django.db.models.signals import post_save, post_delete, pre_save
from django.dispatch import receiver
from django.utils import timezone
from .models import Notification
from .notification_service import NotificationService
from django.contrib.auth import get_user_model

User = get_user_model()

# Try to import channels, but don't fail if not available
try:
    from channels.layers import get_channel_layer
    from asgiref.sync import async_to_sync
    CHANNELS_AVAILABLE = True
except ImportError:
    CHANNELS_AVAILABLE = False


# Lazy import of models to avoid circular imports
def get_models():
    """Lazy import all models needed for signals"""
    from apps.study_groups.models import StudyGroup, GroupMessage, GroupMembership
    from apps.reservations.models import Reservation
    from apps.complaints.models import Complaint
    from apps.notices.models import Notice
    
    return {
        'StudyGroup': StudyGroup,
        'GroupMessage': GroupMessage,
        'GroupMembership': GroupMembership,
        'Reservation': Reservation,
        'Complaint': Complaint,
        'Notice': Notice,
    }


@receiver(post_save, sender=Notification)
def send_realtime_notification(sender, instance, created, **kwargs):
    """Send real-time notification via WebSocket when notification is created"""
    if created and CHANNELS_AVAILABLE:
        try:
            channel_layer = get_channel_layer()
            
            # Prepare notification data
            notification_data = {
                'id': str(instance.id),
                'title': instance.title,
                'message': instance.message,
                'type': instance.notification_type,
                'priority': instance.priority,
                'is_read': instance.is_read,
                'created_at': instance.created_at.isoformat(),
                'data': instance.data,
            }
            
            # Send to user's notification channel
            room_group_name = f'notifications_{instance.user.id}'
            
            async_to_sync(channel_layer.group_send)(
                room_group_name,
                {
                    'type': 'send_notification',
                    'notification': notification_data
                }
            )
        except Exception as e:
            # Silently fail if channels is not properly configured
            pass


def register_signals():
    """Register all notification signals - called from apps.py"""
    models = get_models()
    
    StudyGroup = models['StudyGroup']
    GroupMembership = models['GroupMembership']
    Reservation = models['Reservation']
    Complaint = models['Complaint']
    Notice = models['Notice']
    
    # Study group signals
    @receiver(post_save, sender=StudyGroup)
    def handle_study_group_created(sender, instance, created, **kwargs):
        """Notify all students when a new study group is created"""
        if created and instance.is_public:
            try:
                NotificationService.notify_study_group_created(instance)
            except Exception as e:
                print(f"Error sending study group notification: {e}")
    
    # Group membership signals
    @receiver(post_save, sender=GroupMembership)
    def handle_group_membership_created(sender, instance, created, **kwargs):
        """Notify when user joins a group"""
        if created and instance.is_active:
            try:
                NotificationService.notify_user_joined_group(instance.group, instance.user)
            except Exception as e:
                print(f"Error sending join notification: {e}")
    
    @receiver(pre_save, sender=GroupMembership)
    def check_group_membership_left(sender, instance, **kwargs):
        """Track if user is leaving a group"""
        if instance.pk:
            try:
                old_instance = GroupMembership.objects.get(pk=instance.pk)
                # If was active and now is not active
                if old_instance.is_active and not instance.is_active:
                    try:
                        NotificationService.notify_user_left_group(old_instance.group, old_instance.user)
                    except Exception as e:
                        print(f"Error sending leave notification: {e}")
            except GroupMembership.DoesNotExist:
                pass
    
    # Complaint signals
    @receiver(post_save, sender=Complaint)
    def handle_complaint_created(sender, instance, created, **kwargs):
        """Notify when complaint is submitted"""
        if created:
            try:
                NotificationService.notify_complaint_submitted(instance)
            except Exception as e:
                print(f"Error sending complaint submission notification: {e}")
    
    @receiver(pre_save, sender=Complaint)
    def cache_complaint_status(sender, instance, **kwargs):
        """Store old status for comparison"""
        if instance.pk:
            try:
                instance._old_status = Complaint.objects.get(pk=instance.pk).status
            except Complaint.DoesNotExist:
                instance._old_status = None
    
    @receiver(post_save, sender=Complaint)
    def handle_complaint_status_changed(sender, instance, created, **kwargs):
        """Notify when complaint status changes"""
        if not created and hasattr(instance, '_old_status') and instance._old_status and instance._old_status != instance.status:
            try:
                NotificationService.notify_complaint_status_changed(
                    instance, instance._old_status, instance.status
                )
            except Exception as e:
                print(f"Error sending complaint status notification: {e}")
    
    # Reservation signals
    @receiver(post_save, sender=Reservation)
    def handle_reservation_created(sender, instance, created, **kwargs):
        """Notify when reservation is confirmed"""
        if created and instance.status == 'confirmed':
            try:
                NotificationService.notify_reservation_confirmed(instance)
            except Exception as e:
                print(f"Error sending reservation confirmation: {e}")
    
    # Notice signals
    @receiver(pre_save, sender=Notice)
    def cache_notice_status(sender, instance, **kwargs):
        """Store old status for comparison"""
        if instance.pk:
            try:
                instance._old_status = Notice.objects.get(pk=instance.pk).status
            except Notice.DoesNotExist:
                instance._old_status = None
    
    @receiver(post_save, sender=Notice)
    def handle_new_notice(sender, instance, created, **kwargs):
        """Notify all users when a new notice is published"""
        should_notify = False
        if created and instance.status == 'published':
            should_notify = True
        elif not created and hasattr(instance, '_old_status') and instance._old_status != 'published' and instance.status == 'published':
            should_notify = True
        
        if should_notify:
            try:
                NotificationService.notify_new_notice(instance)
            except Exception as e:
                print(f"Error sending notice notification: {e}")
    
    print("Notification signals registered successfully")
