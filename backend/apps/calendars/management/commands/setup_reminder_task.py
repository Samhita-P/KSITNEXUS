"""
Management command to set up the periodic task for sending event reminders.
This should be run once to register the task with django-celery-beat.
"""
from django.core.management.base import BaseCommand
from django_celery_beat.models import PeriodicTask, IntervalSchedule
from django.utils import timezone


class Command(BaseCommand):
    help = 'Set up the periodic task for sending event reminders'

    def handle(self, *args, **options):
        # Create or get an interval schedule for every minute
        schedule, created = IntervalSchedule.objects.get_or_create(
            every=1,
            period=IntervalSchedule.MINUTES,
        )
        
        if created:
            self.stdout.write(
                self.style.SUCCESS(f'Created interval schedule: every {schedule.every} {schedule.period}')
            )
        else:
            self.stdout.write(
                self.style.SUCCESS(f'Using existing interval schedule: every {schedule.every} {schedule.period}')
            )
        
        # Create or update the periodic task
        task, created = PeriodicTask.objects.get_or_create(
            name='Send Event Reminders',
            defaults={
                'task': 'apps.calendars.tasks.send_event_reminders',
                'interval': schedule,
                'enabled': True,
                'description': 'Sends notifications for calendar event reminders based on user settings',
            }
        )
        
        if created:
            self.stdout.write(
                self.style.SUCCESS('Successfully created periodic task: Send Event Reminders')
            )
        else:
            # Update existing task
            task.task = 'apps.calendars.tasks.send_event_reminders'
            task.interval = schedule
            task.enabled = True
            task.save()
            self.stdout.write(
                self.style.SUCCESS('Successfully updated periodic task: Send Event Reminders')
            )
        
        self.stdout.write(
            self.style.SUCCESS(
                '\n✅ Event reminder task is now set up!\n'
                'The task will run every minute to check for reminders that need to be sent.\n'
                'Make sure Celery Beat is running: celery -A ksit_nexus beat -l info'
            )
        )
















