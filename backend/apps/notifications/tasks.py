"""
Celery tasks for notifications app
"""
from celery import shared_task
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import datetime, timedelta
from .services.digest_service import DigestService
from .services.priority_service import PriorityService
from .models import Notification, NotificationPreference
from .models_digest import NotificationDigest

User = get_user_model()


@shared_task(bind=True, max_retries=3)
def generate_daily_digests(self):
    """
    Generate daily digests for all users with digest frequency set to 'daily'
    """
    try:
        # Get all users with daily digest enabled
        users = User.objects.filter(
            notification_preferences__digest_frequency='daily'
        ).distinct()
        
        success_count = 0
        error_count = 0
        
        for user in users:
            try:
                digest = DigestService.generate_daily_digest(user)
                if digest:
                    success_count += 1
                    # Send digest notification (can be implemented later)
            except Exception as e:
                error_count += 1
                print(f"Error generating digest for user {user.id}: {e}")
        
        return {
            'success_count': success_count,
            'error_count': error_count,
            'total_users': users.count()
        }
    except Exception as e:
        print(f"Error in generate_daily_digests task: {e}")
        # Don't retry if it's a configuration issue
        return {
            'success_count': 0,
            'error_count': 1,
            'total_users': 0,
            'error': str(e)
        }


@shared_task(bind=True, max_retries=3)
def generate_weekly_digests(self):
    """
    Generate weekly digests for all users with digest frequency set to 'weekly'
    """
    try:
        # Get all users with weekly digest enabled
        users = User.objects.filter(
            notification_preferences__digest_frequency='weekly'
        ).distinct()
        
        success_count = 0
        error_count = 0
        
        for user in users:
            try:
                digest = DigestService.generate_weekly_digest(user)
                if digest:
                    success_count += 1
                    # Send digest notification (can be implemented later)
            except Exception as e:
                error_count += 1
                print(f"Error generating digest for user {user.id}: {e}")
        
        return {
            'success_count': success_count,
            'error_count': error_count,
            'total_users': users.count()
        }
    except Exception as e:
        print(f"Error in generate_weekly_digests task: {e}")
        # Don't retry if it's a configuration issue
        return {
            'success_count': 0,
            'error_count': 1,
            'total_users': 0,
            'error': str(e)
        }


@shared_task(bind=True, max_retries=3)
def escalate_notifications(self):
    """
    Escalate notifications that meet escalation criteria
    """
    try:
        # Get all unread notifications
        notifications = Notification.objects.filter(
            is_read=False,
            created_at__lte=timezone.now() - timedelta(minutes=30)  # At least 30 minutes old
        )
        
        escalated_count = 0
        
        for notification in notifications:
            try:
                if PriorityService.should_escalate(notification, notification.user):
                    PriorityService.escalate_notification(notification)
                    escalated_count += 1
            except Exception as e:
                print(f"Error escalating notification {notification.id}: {e}")
        
        return {
            'escalated_count': escalated_count,
            'total_checked': notifications.count()
        }
    except Exception as e:
        print(f"Error in escalate_notifications task: {e}")
        # Don't retry if it's a configuration issue
        return {
            'escalated_count': 0,
            'total_checked': 0,
            'error': str(e)
        }


@shared_task(bind=True, max_retries=3)
def send_digest_notifications(self):
    """
    Send digest notifications to users
    """
    try:
        # Get all unsent digests
        digests = NotificationDigest.objects.filter(
            is_sent=False,
            created_at__lte=timezone.now() - timedelta(minutes=5)  # Wait 5 minutes before sending
        )
        
        sent_count = 0
        error_count = 0
        
        for digest in digests:
            try:
                # Mark digest as sent
                digest.mark_as_sent()
                sent_count += 1
                
                # Send push notification for digest (can be implemented later)
                # For now, just mark as sent
            except Exception as e:
                error_count += 1
                print(f"Error sending digest {digest.id}: {e}")
        
        return {
            'sent_count': sent_count,
            'error_count': error_count,
            'total_digests': digests.count()
        }
    except Exception as e:
        print(f"Error in send_digest_notifications task: {e}")
        # Don't retry if it's a configuration issue
        return {
            'sent_count': 0,
            'error_count': 1,
            'total_digests': 0,
            'error': str(e)
        }


@shared_task(bind=True, max_retries=3)
def generate_notification_summaries(self, notification_ids=None):
    """
    Generate summaries for notifications
    
    Args:
        notification_ids: List of notification IDs (optional, generates for all if None)
    """
    try:
        from .services.summary_service import SummaryService
        
        if notification_ids:
            notifications = Notification.objects.filter(id__in=notification_ids)
        else:
            # Get notifications without summaries
            notifications = Notification.objects.filter(
                summary__isnull=True,
                created_at__gte=timezone.now() - timedelta(days=7)  # Only recent notifications
            )[:100]  # Limit to 100 at a time
        
        generated_count = 0
        error_count = 0
        
        for notification in notifications:
            try:
                summary = SummaryService.generate_summary(notification, 'short')
                if summary:
                    generated_count += 1
            except Exception as e:
                error_count += 1
                print(f"Error generating summary for notification {notification.id}: {e}")
        
        return {
            'generated_count': generated_count,
            'error_count': error_count,
            'total_notifications': notifications.count()
        }
    except Exception as e:
        print(f"Error in generate_notification_summaries task: {e}")
        # Don't retry if it's a configuration issue
        return {
            'generated_count': 0,
            'error_count': 1,
            'total_notifications': 0,
            'error': str(e)
        }

