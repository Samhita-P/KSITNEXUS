from django.utils import timezone
from django.db.models import Q
from datetime import timedelta
from apps.calendars.models import CalendarEvent, EventReminder
from apps.notifications.notification_service import NotificationService


class CalendarService:
    """Service for managing calendar events"""
    
    @staticmethod
    def create_event(
        user,
        title,
        start_time,
        end_time=None,
        description=None,
        event_type='event',
        location=None,
        meeting_link=None,
        all_day=False,
        timezone_name='UTC',
        is_recurring=False,
        recurrence_pattern='none',
        recurrence_end_date=None,
        recurrence_count=None,
        color='#3b82f6',
        privacy='private',
        attendees=None,
        external_attendees=None,
        reminders=None,
        related_meeting=None,
        related_study_group_event=None,
    ):
        """Create a new calendar event"""
        try:
            # Ensure all required fields have valid values
            if not title or not isinstance(title, str) or title.strip() == '':
                raise ValueError('Event title is required and must be a non-empty string')
            if not event_type or not isinstance(event_type, str):
                event_type = 'event'
            if not timezone_name or not isinstance(timezone_name, str):
                timezone_name = 'UTC'
            if not recurrence_pattern or not isinstance(recurrence_pattern, str):
                recurrence_pattern = 'none'
            if not color or not isinstance(color, str):
                color = '#3b82f6'
            if not privacy or not isinstance(privacy, str):
                privacy = 'private'
            
            # Ensure external_attendees is a list
            if external_attendees is None:
                external_attendees = []
            elif not isinstance(external_attendees, list):
                external_attendees = []
            
            # Safely strip string fields
            safe_title = title.strip() if title else 'Untitled Event'
            safe_description = description.strip() if description and isinstance(description, str) else None
            safe_location = location.strip() if location and isinstance(location, str) else None
            safe_meeting_link = meeting_link.strip() if meeting_link and isinstance(meeting_link, str) else None
            
            print(f"📅 Creating event in database:")
            print(f"   Title: {safe_title}")
            print(f"   Start Time (original): {start_time}")
            print(f"   Start Time (type): {type(start_time)}")
            print(f"   Start Time (naive?): {timezone.is_naive(start_time) if hasattr(start_time, 'tzinfo') else 'N/A'}")
            print(f"   All Day: {all_day}")
            print(f"   Timezone: {timezone_name}")
            
            event = CalendarEvent.objects.create(
                created_by=user,
                title=safe_title,
                description=safe_description,
                event_type=event_type,
                start_time=start_time,
                end_time=end_time,
                all_day=all_day,
                timezone=timezone_name,
                location=safe_location,
                meeting_link=safe_meeting_link,
                is_recurring=is_recurring,
                recurrence_pattern=recurrence_pattern,
                recurrence_end_date=recurrence_end_date,
                recurrence_count=recurrence_count,
                color=color,
                privacy=privacy,
                external_attendees=external_attendees,
                related_meeting=related_meeting,
                related_study_group_event=related_study_group_event,
            )
            
            print(f"📅 Event created successfully:")
            print(f"   ID: {event.id}")
            print(f"   Start Time (saved): {event.start_time}")
            print(f"   Start Time (saved UTC): {event.start_time.astimezone(timezone.utc) if timezone.is_aware(event.start_time) else event.start_time}")
            print(f"   Is Cancelled: {event.is_cancelled}")
            
            # Add attendees
            if attendees:
                try:
                    event.attendees.set(attendees)
                except Exception as e:
                    print(f"Warning: Failed to set attendees: {e}")
            
            # Create reminders
            if reminders:
                try:
                    for reminder_data in reminders:
                        if isinstance(reminder_data, dict):
                            EventReminder.objects.create(
                                event=event,
                                user=user,
                                reminder_type=reminder_data.get('type', 'notification'),
                                minutes_before=reminder_data.get('minutes_before', 15),
                            )
                except Exception as e:
                    print(f"Warning: Failed to create reminders: {e}")
            
            # Create notification for event creation
            try:
                NotificationService.create_notification(
                    user=user,
                    notification_type='event_created',
                    title=f"Event Created: {title}",
                    message=f"Your event '{title}' has been created.",
                    priority='normal',
                )
            except Exception as e:
                print(f"Warning: Failed to create notification: {e}")
                pass  # Silently fail if notification service is not available
            
            return event
        except Exception as e:
            import traceback
            print(f"Error in CalendarService.create_event: {e}")
            print(f"Title: {title}")
            print(f"Event type: {event_type}")
            print(f"Start time: {start_time}")
            traceback.print_exc()
            raise
    
    @staticmethod
    def update_event(event, user, **kwargs):
        """Update an existing calendar event"""
        allowed_fields = [
            'title', 'description', 'event_type', 'start_time', 'end_time',
            'all_day', 'timezone', 'location', 'meeting_link', 'is_recurring',
            'recurrence_pattern', 'recurrence_end_date', 'recurrence_count',
            'color', 'privacy', 'external_attendees',
        ]
        
        for field in allowed_fields:
            if field in kwargs:
                setattr(event, field, kwargs[field])
        
        # Handle attendees
        if 'attendees' in kwargs:
            event.attendees.set(kwargs['attendees'])
        
        event.save()
        
        # Create notification for event update
        try:
            NotificationService.create_notification(
                user=user,
                notification_type='event_updated',
                title=f"Event Updated: {event.title}",
                message=f"Your event '{event.title}' has been updated.",
                priority='normal',
            )
        except Exception as e:
            print(f"Warning: Failed to create notification: {e}")
            pass
        
        return event
    
    @staticmethod
    def delete_event(event, user):
        """Delete a calendar event"""
        event_title = event.title
        event.delete()
        
        # Create notification for event deletion
        try:
            NotificationService.create_notification(
                user=user,
                notification_type='event_deleted',
                title=f"Event Deleted: {event_title}",
                message=f"Your event '{event_title}' has been deleted.",
                priority='normal',
            )
        except Exception as e:
            print(f"Warning: Failed to create notification: {e}")
            pass
    
    @staticmethod
    def cancel_event(event, user):
        """Cancel a calendar event"""
        event.is_cancelled = True
        event.cancelled_at = timezone.now()
        event.cancelled_by = user
        event.save()
        
        # Create notification for event cancellation
        try:
            NotificationService.create_notification(
                user=user,
                notification_type='event_cancelled',
                title=f"Event Cancelled: {event.title}",
                message=f"Your event '{event.title}' has been cancelled.",
                priority='normal',
            )
        except Exception as e:
            print(f"Warning: Failed to create notification: {e}")
            pass
        
        return event
    
    @staticmethod
    def get_events(
        user=None,
        start_date=None,
        end_date=None,
        event_type=None,
        is_cancelled=None,
        privacy=None,
    ):
        """Get calendar events with optional filters"""
        queryset = CalendarEvent.objects.all()
        
        if user:
            # Get events created by user, events user is attending, or public events
            queryset = queryset.filter(
                Q(created_by=user) |
                Q(attendees=user) |
                Q(privacy='public')
            ).distinct()
        
        if start_date:
            queryset = queryset.filter(start_time__gte=start_date)
            print(f"📅 Filtered by start_date >= {start_date}")
        
        if end_date:
            # For end_date, we want events that start on or before the end_date
            # This includes multi-day events that might span beyond end_date
            queryset = queryset.filter(start_time__lte=end_date)
            print(f"📅 Filtered by start_time <= {end_date}")
        
        if event_type:
            queryset = queryset.filter(event_type=event_type)
        
        if is_cancelled is not None:
            queryset = queryset.filter(is_cancelled=is_cancelled)
        
        if privacy:
            queryset = queryset.filter(privacy=privacy)
        
        return queryset.order_by('start_time')
    
    @staticmethod
    def get_upcoming_events(user, days=7):
        """Get upcoming events for a user"""
        now = timezone.now()
        end_date = now + timedelta(days=days)
        return CalendarService.get_events(
            user=user,
            start_date=now,
            end_date=end_date,
            is_cancelled=False,
        )
    
    @staticmethod
    def get_events_by_date_range(user, start_date, end_date):
        """Get events within a date range"""
        return CalendarService.get_events(
            user=user,
            start_date=start_date,
            end_date=end_date,
            is_cancelled=False,
        )
    
    @staticmethod
    def get_events_by_type(user, event_type):
        """Get events by type"""
        return CalendarService.get_events(
            user=user,
            event_type=event_type,
            is_cancelled=False,
        )
    
    @staticmethod
    def add_reminder(event, user, reminder_type='notification', minutes_before=15):
        """Add a reminder to an event"""
        reminder, created = EventReminder.objects.get_or_create(
            event=event,
            user=user,
            reminder_type=reminder_type,
            minutes_before=minutes_before,
        )
        return reminder
    
    @staticmethod
    def remove_reminder(event, user, reminder_type=None, minutes_before=None):
        """Remove a reminder from an event"""
        filters = {'event': event, 'user': user}
        if reminder_type:
            filters['reminder_type'] = reminder_type
        if minutes_before is not None:
            filters['minutes_before'] = minutes_before
        
        EventReminder.objects.filter(**filters).delete()
    
    @staticmethod
    def get_reminders_to_send():
        """Get reminders that need to be sent"""
        now = timezone.now()
        reminders = EventReminder.objects.filter(
            is_sent=False,
            event__is_cancelled=False,
        ).select_related('event', 'user')
        
        reminders_to_send = []
        for reminder in reminders:
            if reminder.should_send:
                reminders_to_send.append(reminder)
        
        return reminders_to_send
    
    @staticmethod
    def mark_reminder_as_sent(reminder):
        """Mark a reminder as sent"""
        reminder.is_sent = True
        reminder.sent_at = timezone.now()
        reminder.save()
        
        # Create notification for event reminder
        try:
            # Calculate time until event
            time_until = reminder.event.start_time - timezone.now()
            minutes_until = int(time_until.total_seconds() / 60)
            
            # Format time message
            if minutes_until < 60:
                time_message = f"in {minutes_until} minute{'s' if minutes_until != 1 else ''}"
            elif minutes_until < 1440:
                hours = minutes_until // 60
                time_message = f"in {hours} hour{'s' if hours != 1 else ''}"
            else:
                days = minutes_until // 1440
                time_message = f"in {days} day{'s' if days != 1 else ''}"
            
            # Build message
            message = f"Your event '{reminder.event.title}' starts {time_message}."
            if reminder.event.location:
                message += f" Location: {reminder.event.location}"
            if reminder.event.all_day:
                message += " (All Day)"
            else:
                from django.utils import dateformat
                message += f" at {dateformat.format(reminder.event.start_time, 'g:i A')}"
            
            NotificationService.create_notification(
                user=reminder.user,
                notification_type='event_reminder',
                title=f"Event Reminder: {reminder.event.title}",
                message=message,
                priority='high',
                data={
                    'event_id': reminder.event.id,
                    'event_title': reminder.event.title,
                    'start_time': reminder.event.start_time.isoformat(),
                    'minutes_before': reminder.minutes_before,
                },
                related_object_type='calendar_event',
                related_object_id=reminder.event.id,
            )
        except Exception as e:
            import traceback
            print(f"Error creating reminder notification: {e}")
            traceback.print_exc()

