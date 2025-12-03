"""
Celery Beat schedule for notification tasks
"""
from celery.schedules import crontab

# Celery Beat Schedule
CELERY_BEAT_SCHEDULE = {
    # Generate daily digests at 9:00 AM every day
    'generate-daily-digests': {
        'task': 'apps.notifications.tasks.generate_daily_digests',
        'schedule': crontab(hour=9, minute=0),
    },
    
    # Generate weekly digests on Monday at 9:00 AM
    'generate-weekly-digests': {
        'task': 'apps.notifications.tasks.generate_weekly_digests',
        'schedule': crontab(hour=9, minute=0, day_of_week=1),  # Monday
    },
    
    # Escalate notifications every 30 minutes
    'escalate-notifications': {
        'task': 'apps.notifications.tasks.escalate_notifications',
        'schedule': crontab(minute='*/30'),  # Every 30 minutes
    },
    
    # Send digest notifications every 5 minutes
    'send-digest-notifications': {
        'task': 'apps.notifications.tasks.send_digest_notifications',
        'schedule': crontab(minute='*/5'),  # Every 5 minutes
    },
    
    # Generate notification summaries every hour
    'generate-notification-summaries': {
        'task': 'apps.notifications.tasks.generate_notification_summaries',
        'schedule': crontab(minute=0),  # Every hour
    },
    
    # Send event reminders every minute
    'send-event-reminders': {
        'task': 'apps.calendars.tasks.send_event_reminders',
        'schedule': crontab(minute='*'),  # Every minute
    },
    
    # Generate operational alerts every 15 minutes
    'generate-operational-alerts': {
        'task': 'apps.faculty_admin.tasks.generate_operational_alerts_task',
        'schedule': crontab(minute='*/15'),  # Every 15 minutes
    },
    
    # Calculate predictive metrics every hour
    'calculate-predictive-metrics': {
        'task': 'apps.faculty_admin.tasks.calculate_predictive_metrics_task',
        'schedule': crontab(minute=0),  # Every hour at minute 0
    },
}

