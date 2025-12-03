from django.conf import settings
from django.utils import timezone
from datetime import datetime, timedelta
from apps.calendars.models import CalendarEvent, GoogleCalendarSync, CalendarEventSync
from apps.calendars.services.calendar_service import CalendarService

try:
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import Flow
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
    GOOGLE_API_AVAILABLE = True
except ImportError:
    GOOGLE_API_AVAILABLE = False
    # Stub classes for when google API packages are not available
    class Request:
        pass
    class Credentials:
        pass
    class Flow:
        pass
    class build:
        pass
    class HttpError(Exception):
        pass


class GoogleCalendarService:
    """Service for Google Calendar integration"""
    
    # Google Calendar API scopes
    SCOPES = ['https://www.googleapis.com/auth/calendar']
    
    # OAuth 2.0 client configuration (should be in settings)
    CLIENT_ID = getattr(settings, 'GOOGLE_CALENDAR_CLIENT_ID', None)
    CLIENT_SECRET = getattr(settings, 'GOOGLE_CALENDAR_CLIENT_SECRET', None)
    REDIRECT_URI = getattr(settings, 'GOOGLE_CALENDAR_REDIRECT_URI', 'https://ksitnexus.onrender.com/api/calendars/google/callback/')
    
    @staticmethod
    def get_authorization_url(user):
        """Get Google OAuth authorization URL"""
        if not GOOGLE_API_AVAILABLE:
            raise ImportError("Google API packages are not installed. Please install them with: pip install google-api-python-client google-auth google-auth-httplib2 google-auth-oauthlib")
        
        if not GoogleCalendarService.CLIENT_ID or not GoogleCalendarService.CLIENT_SECRET:
            raise ValueError("Google Calendar OAuth credentials not configured")
        
        flow = Flow.from_client_config(
            {
                'web': {
                    'client_id': GoogleCalendarService.CLIENT_ID,
                    'client_secret': GoogleCalendarService.CLIENT_SECRET,
                    'auth_uri': 'https://accounts.google.com/o/oauth2/auth',
                    'token_uri': 'https://oauth2.googleapis.com/token',
                    'redirect_uris': [GoogleCalendarService.REDIRECT_URI],
                }
            },
            scopes=GoogleCalendarService.SCOPES,
        )
        flow.redirect_uri = GoogleCalendarService.REDIRECT_URI
        
        authorization_url, state = flow.authorization_url(
            access_type='offline',
            include_granted_scopes='true',
            prompt='consent',
        )
        
        # Store state in session or database (simplified here)
        # In production, use a proper session store or cache
        return authorization_url, state
    
    @staticmethod
    def handle_oauth_callback(user, authorization_code, state):
        """Handle Google OAuth callback and store credentials"""
        if not GoogleCalendarService.CLIENT_ID or not GoogleCalendarService.CLIENT_SECRET:
            raise ValueError("Google Calendar OAuth credentials not configured")
        
        flow = Flow.from_client_config(
            {
                'web': {
                    'client_id': GoogleCalendarService.CLIENT_ID,
                    'client_secret': GoogleCalendarService.CLIENT_SECRET,
                    'auth_uri': 'https://accounts.google.com/o/oauth2/auth',
                    'token_uri': 'https://oauth2.googleapis.com/token',
                    'redirect_uris': [GoogleCalendarService.REDIRECT_URI],
                }
            },
            scopes=GoogleCalendarService.SCOPES,
        )
        flow.redirect_uri = GoogleCalendarService.REDIRECT_URI
        
        flow.fetch_token(code=authorization_code)
        credentials = flow.credentials
        
        # Store credentials in database
        sync_record, created = GoogleCalendarSync.objects.get_or_create(
            user=user,
            defaults={
                'is_connected': True,
                'access_token': credentials.token,
                'refresh_token': credentials.refresh_token,
                'token_expires_at': credentials.expiry,
            },
        )
        
        if not created:
            sync_record.is_connected = True
            sync_record.access_token = credentials.token
            sync_record.refresh_token = credentials.refresh_token
            sync_record.token_expires_at = credentials.expiry
            sync_record.save()
        
        # Get primary calendar ID
        calendar_id = GoogleCalendarService._get_primary_calendar_id(user)
        if calendar_id:
            sync_record.calendar_id = calendar_id
            sync_record.save()
        
        return sync_record
    
    @staticmethod
    def _get_credentials(user):
        """Get Google Calendar credentials for a user"""
        sync_record = GoogleCalendarSync.objects.filter(user=user, is_connected=True).first()
        if not sync_record:
            return None
        
        credentials = Credentials(
            token=sync_record.access_token,
            refresh_token=sync_record.refresh_token,
            token_uri='https://oauth2.googleapis.com/token',
            client_id=GoogleCalendarService.CLIENT_ID,
            client_secret=GoogleCalendarService.CLIENT_SECRET,
            scopes=GoogleCalendarService.SCOPES,
        )
        
        # Refresh token if expired
        if sync_record.is_token_expired:
            credentials.refresh(Request())
            sync_record.access_token = credentials.token
            sync_record.token_expires_at = credentials.expiry
            sync_record.save()
        
        return credentials
    
    @staticmethod
    def _get_primary_calendar_id(user):
        """Get primary calendar ID for a user"""
        try:
            credentials = GoogleCalendarService._get_credentials(user)
            if not credentials:
                return None
            
            service = build('calendar', 'v3', credentials=credentials)
            calendar_list = service.calendarList().list().execute()
            
            for calendar in calendar_list.get('items', []):
                if calendar.get('primary'):
                    return calendar.get('id')
            
            return 'primary'  # Default to primary calendar
        except Exception:
            return None
    
    @staticmethod
    def disconnect_google_calendar(user):
        """Disconnect Google Calendar for a user"""
        sync_record = GoogleCalendarSync.objects.filter(user=user).first()
        if sync_record:
            sync_record.is_connected = False
            sync_record.access_token = None
            sync_record.refresh_token = None
            sync_record.token_expires_at = None
            sync_record.save()
        
        return sync_record
    
    @staticmethod
    def create_event_in_google_calendar(user, event):
        """Create an event in Google Calendar"""
        try:
            credentials = GoogleCalendarService._get_credentials(user)
            if not credentials:
                raise ValueError("Google Calendar not connected")
            
            service = build('calendar', 'v3', credentials=credentials)
            sync_record = GoogleCalendarSync.objects.get(user=user, is_connected=True)
            calendar_id = sync_record.calendar_id or 'primary'
            
            # Convert event to Google Calendar format
            google_event = GoogleCalendarService._convert_to_google_event(event)
            
            # Create event in Google Calendar
            created_event = service.events().insert(
                calendarId=calendar_id,
                body=google_event,
            ).execute()
            
            # Store Google Calendar event ID
            CalendarEventSync.objects.create(
                event=event,
                google_calendar_id=created_event.get('id'),
                sync_status='synced',
            )
            
            return created_event
        except HttpError as error:
            raise Exception(f"Error creating event in Google Calendar: {error}")
    
    @staticmethod
    def update_event_in_google_calendar(user, event):
        """Update an event in Google Calendar"""
        try:
            credentials = GoogleCalendarService._get_credentials(user)
            if not credentials:
                raise ValueError("Google Calendar not connected")
            
            service = build('calendar', 'v3', credentials=credentials)
            sync_record = GoogleCalendarSync.objects.get(user=user, is_connected=True)
            calendar_id = sync_record.calendar_id or 'primary'
            
            # Get Google Calendar event ID
            sync = CalendarEventSync.objects.filter(
                event=event,
                google_calendar_id__isnull=False,
            ).first()
            
            if not sync:
                # Create event if it doesn't exist
                return GoogleCalendarService.create_event_in_google_calendar(user, event)
            
            # Convert event to Google Calendar format
            google_event = GoogleCalendarService._convert_to_google_event(event)
            
            # Update event in Google Calendar
            updated_event = service.events().update(
                calendarId=calendar_id,
                eventId=sync.google_calendar_id,
                body=google_event,
            ).execute()
            
            sync.sync_status = 'synced'
            sync.save()
            
            return updated_event
        except HttpError as error:
            raise Exception(f"Error updating event in Google Calendar: {error}")
    
    @staticmethod
    def delete_event_from_google_calendar(user, event):
        """Delete an event from Google Calendar"""
        try:
            credentials = GoogleCalendarService._get_credentials(user)
            if not credentials:
                raise ValueError("Google Calendar not connected")
            
            service = build('calendar', 'v3', credentials=credentials)
            sync_record = GoogleCalendarSync.objects.get(user=user, is_connected=True)
            calendar_id = sync_record.calendar_id or 'primary'
            
            # Get Google Calendar event ID
            sync = CalendarEventSync.objects.filter(
                event=event,
                google_calendar_id__isnull=False,
            ).first()
            
            if sync:
                # Delete event from Google Calendar
                service.events().delete(
                    calendarId=calendar_id,
                    eventId=sync.google_calendar_id,
                ).execute()
                
                sync.delete()
        except HttpError as error:
            raise Exception(f"Error deleting event from Google Calendar: {error}")
    
    @staticmethod
    def sync_events_from_google_calendar(user, start_date=None, end_date=None):
        """Sync events from Google Calendar to KSIT Nexus"""
        try:
            credentials = GoogleCalendarService._get_credentials(user)
            if not credentials:
                raise ValueError("Google Calendar not connected")
            
            service = build('calendar', 'v3', credentials=credentials)
            sync_record = GoogleCalendarSync.objects.get(user=user, is_connected=True)
            calendar_id = sync_record.calendar_id or 'primary'
            
            # Set time range
            if not start_date:
                start_date = timezone.now()
            if not end_date:
                end_date = start_date + timedelta(days=30)
            
            # Get events from Google Calendar
            events_result = service.events().list(
                calendarId=calendar_id,
                timeMin=start_date.isoformat(),
                timeMax=end_date.isoformat(),
                singleEvents=True,
                orderBy='startTime',
            ).execute()
            
            events = events_result.get('items', [])
            imported_events = []
            
            for google_event in events:
                # Check if event already exists
                sync = CalendarEventSync.objects.filter(
                    google_calendar_id=google_event.get('id'),
                ).first()
                
                if sync:
                    # Update existing event
                    event = sync.event
                    GoogleCalendarService._update_event_from_google(event, google_event)
                    imported_events.append(event)
                else:
                    # Create new event
                    event = GoogleCalendarService._create_event_from_google(user, google_event)
                    imported_events.append(event)
            
            # Update last sync time
            sync_record.last_sync_at = timezone.now()
            sync_record.save()
            
            return imported_events
        except HttpError as error:
            raise Exception(f"Error syncing events from Google Calendar: {error}")
    
    @staticmethod
    def sync_events_to_google_calendar(user, events=None):
        """Sync events from KSIT Nexus to Google Calendar"""
        try:
            if not events:
                # Get all user events
                events = CalendarService.get_events(user=user, is_cancelled=False)
            
            synced_events = []
            
            for event in events:
                # Check if event already exists in Google Calendar
                sync = CalendarEventSync.objects.filter(
                    event=event,
                    google_calendar_id__isnull=False,
                ).first()
                
                if sync:
                    # Update existing event
                    GoogleCalendarService.update_event_in_google_calendar(user, event)
                else:
                    # Create new event
                    GoogleCalendarService.create_event_in_google_calendar(user, event)
                
                synced_events.append(event)
            
            # Update last sync time
            sync_record = GoogleCalendarSync.objects.get(user=user, is_connected=True)
            sync_record.last_sync_at = timezone.now()
            sync_record.save()
            
            return synced_events
        except Exception as error:
            raise Exception(f"Error syncing events to Google Calendar: {error}")
    
    @staticmethod
    def _convert_to_google_event(event):
        """Convert CalendarEvent to Google Calendar event format"""
        google_event = {
            'summary': event.title,
            'description': event.description or '',
            'location': event.location or '',
        }
        
        # Set start and end times
        if event.all_day:
            google_event['start'] = {'date': event.start_time.date().isoformat()}
            if event.end_time:
                google_event['end'] = {'date': event.end_time.date().isoformat()}
            else:
                google_event['end'] = {'date': event.start_time.date().isoformat()}
        else:
            google_event['start'] = {'dateTime': event.start_time.isoformat(), 'timeZone': event.timezone}
            if event.end_time:
                google_event['end'] = {'dateTime': event.end_time.isoformat(), 'timeZone': event.timezone}
            else:
                # Default to 1 hour duration
                end_time = event.start_time + timedelta(hours=1)
                google_event['end'] = {'dateTime': end_time.isoformat(), 'timeZone': event.timezone}
        
        # Add attendees
        attendees = []
        if event.attendees.exists():
            for attendee in event.attendees.all():
                attendees.append({'email': attendee.email})
        if event.external_attendees:
            for email in event.external_attendees:
                attendees.append({'email': email})
        
        if attendees:
            google_event['attendees'] = attendees
        
        # Add recurrence rule if applicable
        if event.is_recurring and event.recurrence_pattern != 'none':
            rrule = GoogleCalendarService._generate_google_rrule(event)
            if rrule:
                google_event['recurrence'] = [rrule]
        
        return google_event
    
    @staticmethod
    def _generate_google_rrule(event):
        """Generate Google Calendar recurrence rule"""
        if event.recurrence_pattern == 'none':
            return None
        
        freq_map = {
            'daily': 'DAILY',
            'weekly': 'WEEKLY',
            'monthly': 'MONTHLY',
            'yearly': 'YEARLY',
        }
        
        freq = freq_map.get(event.recurrence_pattern, 'WEEKLY')
        rrule = f"RRULE:FREQ={freq}"
        
        if event.recurrence_count:
            rrule += f";COUNT={event.recurrence_count}"
        elif event.recurrence_end_date:
            rrule += f";UNTIL={event.recurrence_end_date.strftime('%Y%m%dT%H%M%SZ')}"
        
        return rrule
    
    @staticmethod
    def _create_event_from_google(user, google_event):
        """Create CalendarEvent from Google Calendar event"""
        # Extract event data
        start = google_event.get('start', {})
        end = google_event.get('end', {})
        
        start_time = datetime.fromisoformat(
            start.get('dateTime', start.get('date'))
        ).replace(tzinfo=timezone.utc)
        
        end_time = None
        if end:
            end_time = datetime.fromisoformat(
                end.get('dateTime', end.get('date'))
            ).replace(tzinfo=timezone.utc)
        
        all_day = 'date' in start
        
        # Create event
        event = CalendarService.create_event(
            user=user,
            title=google_event.get('summary', 'Imported Event'),
            description=google_event.get('description'),
            start_time=start_time,
            end_time=end_time,
            location=google_event.get('location'),
            all_day=all_day,
            event_type='event',
            privacy='private',
        )
        
        # Store Google Calendar event ID
        CalendarEventSync.objects.create(
            event=event,
            google_calendar_id=google_event.get('id'),
            sync_status='synced',
        )
        
        return event
    
    @staticmethod
    def _update_event_from_google(event, google_event):
        """Update CalendarEvent from Google Calendar event"""
        # Extract event data
        start = google_event.get('start', {})
        end = google_event.get('end', {})
        
        start_time = datetime.fromisoformat(
            start.get('dateTime', start.get('date'))
        ).replace(tzinfo=timezone.utc)
        
        end_time = None
        if end:
            end_time = datetime.fromisoformat(
                end.get('dateTime', end.get('date'))
            ).replace(tzinfo=timezone.utc)
        
        all_day = 'date' in start
        
        # Update event
        event.title = google_event.get('summary', event.title)
        event.description = google_event.get('description', event.description)
        event.location = google_event.get('location', event.location)
        event.start_time = start_time
        event.end_time = end_time
        event.all_day = all_day
        event.save()
        
        return event

