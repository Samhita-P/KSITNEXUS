"""
Celery tasks for calendars app
"""
from celery import shared_task
from django.utils import timezone
from .services.calendar_service import CalendarService
import logging

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3)
def send_event_reminders(self):
    """
    Check for event reminders that need to be sent and send them as notifications.
    This task should run periodically (every minute) via Celery Beat.
    """
    try:
        # Get all reminders that need to be sent
        reminders_to_send = CalendarService.get_reminders_to_send()
        
        sent_count = 0
        error_count = 0
        
        for reminder in reminders_to_send:
            try:
                # Mark reminder as sent and create notification
                CalendarService.mark_reminder_as_sent(reminder)
                sent_count += 1
                logger.info(
                    f"Sent reminder for event '{reminder.event.title}' "
                    f"to user {reminder.user.username} "
                    f"({reminder.get_minutes_before_display()} before event)"
                )
            except Exception as e:
                error_count += 1
                logger.error(f"Error sending reminder {reminder.id}: {e}")
        
        result = {
            'sent_count': sent_count,
            'error_count': error_count,
            'total_reminders': len(reminders_to_send),
            'timestamp': timezone.now().isoformat(),
        }
        
        if sent_count > 0 or error_count > 0:
            logger.info(f"Event reminders task completed: {result}")
        
        return result
        
    except Exception as e:
        logger.error(f"Error in send_event_reminders task: {e}")
        # Retry the task if it fails
        raise self.retry(exc=e, countdown=60)  # Retry after 60 seconds
















