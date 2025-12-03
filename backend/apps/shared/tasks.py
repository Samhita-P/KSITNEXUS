"""
Example Celery tasks for shared utilities
"""
from celery import shared_task
from apps.shared.utils.logging import get_logger

logger = get_logger(__name__)


@shared_task(bind=True, max_retries=3)
def example_task(self, message: str):
    """
    Example Celery task
    
    Args:
        message: Message to log
        
    Returns:
        Success message
    """
    try:
        logger.info(f"Processing task: {message}")
        # Do some work here
        result = f"Task completed: {message}"
        logger.info(f"Task completed: {result}")
        return result
    except Exception as exc:
        logger.error(f"Task failed: {exc}", exc_info=True)
        # Retry the task
        raise self.retry(exc=exc, countdown=60)


@shared_task
def send_email_task(to_email: str, subject: str, message: str):
    """
    Example email sending task
    
    Args:
        to_email: Recipient email
        subject: Email subject
        message: Email message
        
    Returns:
        Success message
    """
    try:
        logger.info(f"Sending email to {to_email}: {subject}")
        # Send email here
        # For now, just log it
        logger.info(f"Email sent to {to_email}")
        return f"Email sent to {to_email}"
    except Exception as exc:
        logger.error(f"Failed to send email: {exc}", exc_info=True)
        raise


@shared_task
def cleanup_old_logs_task(days: int = 30):
    """
    Cleanup old audit logs
    
    Args:
        days: Number of days to keep logs
        
    Returns:
        Number of logs deleted
    """
    try:
        from django.utils import timezone
        from datetime import timedelta
        from apps.shared.models.audit import AuditLog
        
        cutoff_date = timezone.now() - timedelta(days=days)
        deleted_count = AuditLog.objects.filter(
            created_at__lt=cutoff_date,
            severity__in=['low', 'medium']  # Only delete low and medium severity logs
        ).delete()[0]
        
        logger.info(f"Cleaned up {deleted_count} old audit logs")
        return deleted_count
    except Exception as exc:
        logger.error(f"Failed to cleanup logs: {exc}", exc_info=True)
        raise

