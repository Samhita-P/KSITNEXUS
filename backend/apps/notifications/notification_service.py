"""
Notification service for creating and sending notifications
"""
from django.contrib.auth import get_user_model
from django.db import transaction
from django.utils import timezone
from datetime import timedelta
from typing import Optional, List, Dict, Any

from .models import Notification, NotificationPreference
from .services.quiet_hours_service import QuietHoursService
from .services.digest_service import TierService
from .services.priority_service import PriorityService
from .services.summary_service import SummaryService
from django.conf import settings

User = get_user_model()


class NotificationService:
    """Service for creating and managing notifications"""
    
    @staticmethod
    def create_notification(
        user: User,
        notification_type: str,
        title: str,
        message: str,
        priority: str = 'medium',
        data: Optional[Dict[str, Any]] = None,
        related_object_type: Optional[str] = None,
        related_object_id: Optional[int] = None,
        expires_at: Optional[timezone.datetime] = None
    ) -> Notification:
        """
        Create a new notification for a user
        
        Args:
            user: The user to send the notification to
            notification_type: Type of notification (study_group, complaint, etc.)
            title: Notification title
            message: Notification message
            priority: Notification priority (low, medium, high, urgent)
            data: Additional data as JSON
            related_object_type: Type of related object (e.g., 'study_group', 'complaint')
            related_object_id: ID of related object
            expires_at: When notification expires
            
        Returns:
            Created Notification instance
        """
        # Check if notifications are enabled for this user and type
        pref = NotificationPreference.objects.filter(user=user).first()
        if pref and not pref.in_app_enabled:
            return None
            
        # Check category preferences
        if not NotificationService._should_send_notification(user, notification_type):
            return None
        
        # Calculate priority using PriorityService
        calculated_priority = PriorityService.calculate_priority(
            notification_type=notification_type,
            title=title,
            message=message,
            data=data or {},
            user=user,
            default_priority=priority
        )
        priority = calculated_priority
        
        # Check tier settings
        # Create a temporary notification object for tier checking
        class TempNotification:
            def __init__(self, notification_type, title, message):
                self.notification_type = notification_type
                self.title = title
                self.message = message
        
        temp_notification = TempNotification(notification_type, title, message)
        if not TierService.should_send_notification(user, temp_notification):
            return None
        
        # Check quiet hours (unless urgent)
        if not QuietHoursService.should_send_notification(user, priority):
            # Schedule notification for after quiet hours
            next_send_time = QuietHoursService.get_next_send_time(user)
            if next_send_time:
                # Create notification but don't send immediately
                notification = Notification.objects.create(
                    user=user,
                    notification_type=notification_type,
                    priority=priority,
                    title=title,
                    message=message,
                    data=data or {},
                    related_object_type=related_object_type,
                    related_object_id=related_object_id,
                    expires_at=expires_at,
                    is_sent=False,
                )
                # Schedule for later (can be handled by Celery task)
                return notification
            else:
                # Quiet hours not enabled or invalid, send immediately
                pass
        
        notification = Notification.objects.create(
            user=user,
            notification_type=notification_type,
            priority=priority,
            title=title,
            message=message,
            data=data or {},
            related_object_type=related_object_type,
            related_object_id=related_object_id,
            expires_at=expires_at
        )
        
        # Generate summary for notification (async, don't block)
        try:
            SummaryService.generate_summary(notification, 'short')
        except Exception as e:
            print(f"Error generating summary: {e}")
        
        # Try to send push notification if enabled
        try:
            from .fcm_service import FCMService
            FCMService.send_notification(notification)
        except Exception as e:
            print(f"Error sending push notification: {e}")
        
        return notification
    
    @staticmethod
    def _should_send_notification(user: User, notification_type: str) -> bool:
        """Check if notification should be sent based on user preferences"""
        pref = NotificationPreference.objects.filter(user=user).first()
        if not pref:
            return True
        
        # Map notification types to preferences
        type_map = {
            'complaint': 'complaint_updates',
            'study_group': 'study_group_messages',
            'notice': 'new_notices',
            'reservation': 'reservation_reminders',
            'feedback': 'feedback_requests',
            'announcement': 'general_announcements',
        }
        
        preference_field = type_map.get(notification_type, 'general_announcements')
        return getattr(pref, preference_field, True)
    
    @staticmethod
    def notify_study_group_created(group):
        """Notify all students when a new study group is created"""
        # Get all students
        students = User.objects.filter(studentprofile__isnull=False)
        
        for student in students:
            NotificationService.create_notification(
                user=student,
                notification_type='study_group',
                title='New Study Group Created',
                message=f'A new study group "{group.name}" has been created. Check it out!',
                priority='medium',
                data={'group_id': group.id},
                related_object_type='study_group',
                related_object_id=group.id
            )
    
    @staticmethod
    def notify_user_joined_group(group, user):
        """Notify group members when a user joins"""
        group_members = group.members.filter(is_active=True).exclude(user=user)
        
        for membership in group_members:
            NotificationService.create_notification(
                user=membership.user,
                notification_type='study_group',
                title='New Member Joined',
                message=f'{user.get_full_name() or user.username} joined {group.name}',
                priority='low',
                data={'group_id': group.id, 'new_member_id': user.id},
                related_object_type='study_group',
                related_object_id=group.id
            )
    
    @staticmethod
    def notify_user_left_group(group, user):
        """Notify group members when a user leaves"""
        group_members = group.members.filter(is_active=True)
        
        for membership in group_members:
            NotificationService.create_notification(
                user=membership.user,
                notification_type='study_group',
                title='Member Left Group',
                message=f'{user.get_full_name() or user.username} left {group.name}',
                priority='low',
                data={'group_id': group.id, 'left_member_id': user.id},
                related_object_type='study_group',
                related_object_id=group.id
            )
    
    @staticmethod
    def notify_complaint_submitted(complaint):
        """Notify student when complaint is submitted"""
        # For anonymous complaints, we need to find the user by contact_email
        user = None
        if complaint.contact_email:
            user = User.objects.filter(email=complaint.contact_email).first()
        
        if user:
            NotificationService.create_notification(
                user=user,
                notification_type='complaint',
                title='Complaint Submitted',
                message=f'Your complaint "{complaint.title}" has been submitted successfully.',
                priority='medium',
                data={'complaint_id': complaint.id, 'status': complaint.status},
                related_object_type='complaint',
                related_object_id=complaint.id
            )
    
    @staticmethod
    def notify_complaint_status_changed(complaint, old_status, new_status):
        """Notify student when complaint status changes"""
        # Find user by contact_email
        user = None
        if complaint.contact_email:
            user = User.objects.filter(email=complaint.contact_email).first()
        
        if not user:
            return
        
        status_messages = {
            'in_progress': 'is now being reviewed by faculty',
            'resolved': 'has been resolved',
            'closed': 'has been closed',
            'cancelled': 'has been cancelled'
        }
        
        message = status_messages.get(new_status, f'status has changed from {old_status} to {new_status}')
        
        NotificationService.create_notification(
            user=user,
            notification_type='complaint',
            title='Complaint Update',
            message=f'Your complaint "{complaint.title}" {message}.',
            priority='high' if new_status == 'resolved' else 'medium',
            data={
                'complaint_id': complaint.id,
                'old_status': old_status,
                'new_status': new_status
            },
            related_object_type='complaint',
            related_object_id=complaint.id
        )
    
    @staticmethod
    def notify_reservation_confirmed(reservation):
        """Notify user when reservation is confirmed"""
        NotificationService.create_notification(
            user=reservation.user,
            notification_type='reservation',
            title='Reservation Confirmed',
            message=f'Your {reservation.resource_type} reservation is confirmed.',
            priority='medium',
            data={
                'reservation_id': reservation.id,
                'resource_type': reservation.resource_type,
                'start_time': reservation.start_time.isoformat(),
                'end_time': reservation.end_time.isoformat() if reservation.end_time else None
            },
            related_object_type='reservation',
            related_object_id=reservation.id
        )
        
        # Schedule reminder notification
        if reservation.start_time:
            reminder_time = reservation.start_time - timedelta(hours=1)
            if reminder_time > timezone.now():
                NotificationService.create_reservation_reminder(reservation, reminder_time)
    
    @staticmethod
    def create_reservation_reminder(reservation, reminder_time):
        """Create a reminder notification for a reservation"""
        Notification.objects.create(
            user=reservation.user,
            notification_type='reservation',
            priority='high',
            title='Upcoming Reservation',
            message=f'Your {reservation.resource_type} reservation starts in 1 hour.',
            data={'reservation_id': reservation.id},
            created_at=timezone.now(),
            # Note: This would need a task scheduler to actually send at reminder_time
            # For now, we just create the notification
        )
    
    @staticmethod
    def notify_reservation_cancelled(reservation):
        """Notify user when reservation is cancelled"""
        NotificationService.create_notification(
            user=reservation.user,
            notification_type='reservation',
            title='Reservation Cancelled',
            message=f'Your {reservation.resource_type} reservation has been cancelled.',
            priority='medium',
            data={'reservation_id': reservation.id},
            related_object_type='reservation',
            related_object_id=reservation.id
        )
    
    @staticmethod
    def notify_new_notice(notice):
        """Notify all users when a new notice is created"""
        # Notify students
        students = User.objects.filter(studentprofile__isnull=False)
        for student in students:
            NotificationService.create_notification(
                user=student,
                notification_type='notice',
                title='New Notice',
                message=notice.title,
                priority='high',
                data={'notice_id': notice.id},
                related_object_type='notice',
                related_object_id=notice.id
            )
        
        # Also notify faculty (optional)
        faculty = User.objects.filter(facultyprofile__isnull=False)
        for fac in faculty:
            NotificationService.create_notification(
                user=fac,
                notification_type='notice',
                title='New Notice Published',
                message=f'A new notice "{notice.title}" has been published.',
                priority='medium',
                data={'notice_id': notice.id},
                related_object_type='notice',
                related_object_id=notice.id
            )
    
    @staticmethod
    def bulk_notify_users(users, notification_type, title, message, data=None):
        """Send the same notification to multiple users"""
        notifications = []
        for user in users:
            notif = NotificationService.create_notification(
                user=user,
                notification_type=notification_type,
                title=title,
                message=message,
                data=data,
                priority='medium'
            )
            if notif:
                notifications.append(notif)
        return notifications
    
    @staticmethod
    def mark_as_read(notification_id, user):
        """Mark a notification as read"""
        try:
            notification = Notification.objects.get(id=notification_id, user=user)
            notification.mark_as_read()
            return True
        except Notification.DoesNotExist:
            return False
    
    @staticmethod
    def mark_all_as_read(user):
        """Mark all notifications as read for a user"""
        Notification.objects.filter(user=user, is_read=False).update(
            is_read=True,
            read_at=timezone.now()
        )
        return True
    
    @staticmethod
    def get_unread_count(user):
        """Get count of unread notifications for a user"""
        return Notification.objects.filter(user=user, is_read=False).count()
    
    @staticmethod
    def delete_old_notifications(days=30):
        """Delete notifications older than specified days"""
        cutoff_date = timezone.now() - timedelta(days=days)
        deleted_count = Notification.objects.filter(
            created_at__lt=cutoff_date,
            is_read=True
        ).delete()
        return deleted_count[0]

