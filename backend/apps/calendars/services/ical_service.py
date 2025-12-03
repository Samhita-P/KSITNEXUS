from datetime import datetime
import uuid
from django.http import HttpResponse
from django.utils import timezone
from apps.calendars.models import CalendarEvent, CalendarEventSync
from apps.calendars.services.calendar_service import CalendarService

try:
    from icalendar import Calendar, Event as ICalEvent
    ICALENDAR_AVAILABLE = True
except ImportError:
    ICALENDAR_AVAILABLE = False
    # Stub classes for when icalendar is not available
    class Calendar:
        pass
    class ICalEvent:
        pass


class ICalService:
    """Service for iCal file generation and import"""
    
    @staticmethod
    def generate_ical_file(events, calendar_name='KSIT Nexus Calendar'):
        """Generate an iCal file from a list of events"""
        if not ICALENDAR_AVAILABLE:
            raise ImportError("icalendar package is not installed. Please install it with: pip install icalendar")
        
        cal = Calendar()
        cal.add('prodid', f'-//{calendar_name}//EN')
        cal.add('version', '2.0')
        cal.add('X-WR-CALNAME', calendar_name)
        cal.add('X-WR-TIMEZONE', 'UTC')
        
        for event in events:
            ical_event = ICalEvent()
            # Get or generate iCal UID
            sync_record = CalendarEventSync.objects.filter(event=event, ical_uid__isnull=False).first()
            ical_uid = sync_record.ical_uid if sync_record else f"event-{event.id}@ksit-nexus"
            ical_event.add('uid', ical_uid)
            ical_event.add('dtstamp', timezone.now())
            ical_event.add('dtstart', event.start_time)
            
            if event.end_time:
                ical_event.add('dtend', event.end_time)
            elif event.all_day:
                # For all-day events, end time is next day
                from datetime import timedelta
                ical_event.add('dtend', event.start_time + timedelta(days=1))
            
            ical_event.add('summary', event.title)
            
            if event.description:
                ical_event.add('description', event.description)
            
            if event.location:
                ical_event.add('location', event.location)
            
            if event.meeting_link:
                ical_event.add('url', event.meeting_link)
            
            # Add recurrence rule if applicable
            if event.is_recurring and event.recurrence_pattern != 'none':
                rrule = ICalService._generate_rrule(event)
                if rrule:
                    ical_event.add('rrule', rrule)
            
            # Add attendees
            if event.attendees.exists():
                for attendee in event.attendees.all():
                    ical_event.add('attendee', f"mailto:{attendee.email}")
            
            if event.external_attendees:
                for email in event.external_attendees:
                    ical_event.add('attendee', f"mailto:{email}")
            
            cal.add_component(ical_event)
        
        return cal.to_ical()
    
    @staticmethod
    def _generate_rrule(event):
        """Generate recurrence rule for iCal"""
        if not ICALENDAR_AVAILABLE:
            raise ImportError("icalendar package is not installed. Please install it with: pip install icalendar")
        
        from icalendar import vRecur
        
        if event.recurrence_pattern == 'none':
            return None
        
        rrule = vRecur()
        
        if event.recurrence_pattern == 'daily':
            rrule['freq'] = 'daily'
        elif event.recurrence_pattern == 'weekly':
            rrule['freq'] = 'weekly'
        elif event.recurrence_pattern == 'monthly':
            rrule['freq'] = 'monthly'
        elif event.recurrence_pattern == 'yearly':
            rrule['freq'] = 'yearly'
        
        if event.recurrence_count:
            rrule['count'] = event.recurrence_count
        elif event.recurrence_end_date:
            rrule['until'] = event.recurrence_end_date
        
        return rrule
    
    @staticmethod
    def export_events_as_ical(events, calendar_name='KSIT Nexus Calendar', filename='calendar.ics'):
        """Export events as iCal file"""
        ical_content = ICalService.generate_ical_file(events, calendar_name)
        response = HttpResponse(ical_content, content_type='text/calendar')
        response['Content-Disposition'] = f'attachment; filename="{filename}"'
        return response
    
    @staticmethod
    def import_ical_file(user, ical_content):
        """Import events from an iCal file"""
        if not ICALENDAR_AVAILABLE:
            raise ImportError("icalendar package is not installed. Please install it with: pip install icalendar")
        
        cal = Calendar.from_ical(ical_content)
        imported_events = []
        
        for component in cal.walk():
            if component.name == 'VEVENT':
                event_data = ICalService._parse_ical_event(component)
                event = CalendarService.create_event(
                    user=user,
                    title=event_data.get('title', 'Imported Event'),
                    description=event_data.get('description'),
                    start_time=event_data.get('start_time'),
                    end_time=event_data.get('end_time'),
                    location=event_data.get('location'),
                    meeting_link=event_data.get('url'),
                    all_day=event_data.get('all_day', False),
                    event_type='event',
                    privacy='private',
                )
                
                # Store iCal UID for sync
                ical_uid = event_data.get('uid')
                if ical_uid:
                    CalendarEventSync.objects.create(
                        event=event,
                        ical_uid=ical_uid,
                        sync_status='synced',
                    )
                
                imported_events.append(event)
        
        return imported_events
    
    @staticmethod
    def _parse_ical_event(component):
        """Parse an iCal event component"""
        event_data = {}
        
        # Extract basic information
        if 'summary' in component:
            event_data['title'] = str(component.get('summary'))
        if 'description' in component:
            event_data['description'] = str(component.get('description'))
        if 'location' in component:
            event_data['location'] = str(component.get('location'))
        if 'url' in component:
            event_data['url'] = str(component.get('url'))
        if 'uid' in component:
            event_data['uid'] = str(component.get('uid'))
        
        # Extract start and end times
        if 'dtstart' in component:
            dtstart = component.get('dtstart').dt
            event_data['start_time'] = dtstart
            if isinstance(dtstart, datetime) and dtstart.hour == 0 and dtstart.minute == 0:
                event_data['all_day'] = True
        
        if 'dtend' in component:
            dtend = component.get('dtend').dt
            event_data['end_time'] = dtend
        
        # Extract recurrence rule
        if 'rrule' in component:
            rrule = component.get('rrule')
            event_data['rrule'] = rrule
        
        return event_data
    
    @staticmethod
    def generate_ical_feed_url(user):
        """Generate iCal feed URL for a user"""
        # In production, this would return a URL to a view that generates the iCal file
        # For now, return a placeholder
        return f"/api/calendars/feed/{user.id}/calendar.ics"
    
    @staticmethod
    def update_event_ical_uid(event, ical_uid):
        """Update or create iCal UID for an event"""
        sync_record, created = CalendarEventSync.objects.get_or_create(
            event=event,
            defaults={'ical_uid': ical_uid, 'sync_status': 'synced'},
        )
        if not created:
            sync_record.ical_uid = ical_uid
            sync_record.sync_status = 'synced'
            sync_record.save()
        
        return sync_record

