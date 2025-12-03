from rest_framework import generics, status, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.conf import settings
from datetime import datetime, timedelta
from django.http import HttpResponse
from apps.calendars.models import CalendarEvent, EventReminder, GoogleCalendarSync
from apps.calendars.serializers import (
    CalendarEventSerializer,
    CreateCalendarEventSerializer,
    UpdateCalendarEventSerializer,
    EventReminderSerializer,
    GoogleCalendarSyncSerializer,
)
from apps.calendars.services import CalendarService, ICalService, GoogleCalendarService
from apps.shared.utils.cache import cache_result


class CalendarEventListCreateView(generics.ListCreateAPIView):
    """List and create calendar events"""
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.OrderingFilter, filters.SearchFilter]
    ordering_fields = ['start_time', 'created_at', 'event_type']
    ordering = ['start_time']
    search_fields = ['title', 'description', 'location']
    
    def get_queryset(self):
        try:
            # Parse date filters if provided
            start_date = self.request.query_params.get('start_date', None)
            end_date = self.request.query_params.get('end_date', None)
            
            start_dt = None
            end_dt = None
            
            if start_date:
                try:
                    # Parse ISO 8601 format date string
                    start_dt = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
                    if timezone.is_naive(start_dt):
                        start_dt = timezone.make_aware(start_dt)
                    print(f"📅 Parsed start_date: {start_dt}")
                except (ValueError, AttributeError) as e:
                    print(f"📅 Error parsing start_date '{start_date}': {e}")
            
            if end_date:
                try:
                    # Parse ISO 8601 format date string
                    end_dt = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
                    if timezone.is_naive(end_dt):
                        end_dt = timezone.make_aware(end_dt)
                    print(f"📅 Parsed end_date: {end_dt}")
                except (ValueError, AttributeError) as e:
                    print(f"📅 Error parsing end_date '{end_date}': {e}")
            
            # Get queryset with date filters
            queryset = CalendarService.get_events(
                user=self.request.user,
                start_date=start_dt,
                end_date=end_dt,
            )
            
            # Filter by event type
            event_type = self.request.query_params.get('event_type', None)
            if event_type:
                queryset = queryset.filter(event_type=event_type)
            
            # Filter by cancelled status
            is_cancelled = self.request.query_params.get('is_cancelled', None)
            if is_cancelled is not None:
                queryset = queryset.filter(is_cancelled=is_cancelled.lower() == 'true')
            else:
                # By default, exclude cancelled events
                queryset = queryset.filter(is_cancelled=False)
            
            # Filter by privacy
            privacy = self.request.query_params.get('privacy', None)
            if privacy:
                queryset = queryset.filter(privacy=privacy)
            
            print(f"📅 Final queryset count: {queryset.count()}")
            return queryset.distinct()
        except Exception as e:
            import traceback
            print(f"Error in CalendarEventListCreateView.get_queryset: {e}")
            traceback.print_exc()
            return CalendarEvent.objects.none()
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return CreateCalendarEventSerializer
        return CalendarEventSerializer
    
    def list(self, request, *args, **kwargs):
        """List calendar events with error handling and direct list (no pagination)"""
        try:
            queryset = self.filter_queryset(self.get_queryset())
            print(f"📅 CalendarEventListCreateView.list - User: {request.user.username}")
            print(f"📅 Total events in queryset: {queryset.count()}")
            for event in queryset[:10]:  # Print first 10 events
                print(f"   - Event {event.id}: {event.title} - {event.start_time} (allDay: {event.all_day}, privacy: {event.privacy})")
            serializer = self.get_serializer(queryset, many=True)
            print(f"📅 Serialized {len(serializer.data)} events")
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            import traceback
            print(f"Error in CalendarEventListCreateView.list: {e}")
            traceback.print_exc()
            return Response([], status=status.HTTP_200_OK)
    
    def create(self, request, *args, **kwargs):
        """Override create to handle errors gracefully"""
        try:
            print(f"📅 CREATE REQUEST - User: {request.user.username}")
            print(f"📅 Request data: {request.data}")
            print(f"📅 Request data type: {type(request.data)}")
            
            serializer = self.get_serializer(data=request.data)
            
            # Check validation before raising exception
            if not serializer.is_valid():
                print(f"📅 VALIDATION ERRORS: {serializer.errors}")
                print(f"📅 Validated data: {serializer.validated_data if hasattr(serializer, 'validated_data') else 'N/A'}")
                return Response(
                    {'error': 'Validation failed', 'details': serializer.errors},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            self.perform_create(serializer)
            headers = self.get_success_headers(serializer.data)
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
        except Exception as e:
            import traceback
            error_trace = traceback.format_exc()
            print(f"📅 ERROR in CalendarEventListCreateView.create: {e}")
            print(f"📅 Request data: {request.data}")
            print(f"📅 Full traceback:\n{error_trace}")
            
            # Return 500 for server errors, 400 for validation errors
            error_status = status.HTTP_500_INTERNAL_SERVER_ERROR
            if isinstance(e, (ValueError, TypeError, KeyError)):
                error_status = status.HTTP_400_BAD_REQUEST
            
            return Response(
                {
                    'error': f'Failed to create event: {str(e)}',
                    'details': error_trace if settings.DEBUG else None
                },
                status=error_status
            )
    
    def perform_create(self, serializer):
        """Create a new calendar event"""
        try:
            user = self.request.user
            data = serializer.validated_data.copy()
            
            print(f"📅 Creating event for user: {user.username}")
            print(f"📅 Event data: {data}")
            
            # Extract reminders
            reminders = data.pop('reminders', [])
            attendees = data.pop('attendees', [])
            external_attendees = data.pop('external_attendees', [])
            
            # Ensure required fields have defaults
            if 'title' not in data or not data.get('title'):
                raise ValueError('Event title is required')
            if 'event_type' not in data or not data.get('event_type'):
                data['event_type'] = 'event'
            if 'timezone' not in data or not data.get('timezone'):
                data['timezone'] = 'UTC'
            if 'recurrence_pattern' not in data or not data.get('recurrence_pattern'):
                data['recurrence_pattern'] = 'none'
            if 'color' not in data or not data.get('color'):
                data['color'] = '#3b82f6'
            if 'privacy' not in data or not data.get('privacy'):
                data['privacy'] = 'private'
            
            print(f"📅 Creating event with final data: title={data.get('title')}, start_time={data.get('start_time')}, all_day={data.get('all_day')}")
            
            # Rename timezone to timezone_name for the service method
            if 'timezone' in data:
                data['timezone_name'] = data.pop('timezone')
            
            # Create event using service
            event = CalendarService.create_event(
                user=user,
                reminders=reminders,
                attendees=attendees,
                external_attendees=external_attendees,
                **data,
            )
            
            print(f"📅 Event created successfully: ID={event.id}, Title={event.title}, Start={event.start_time}, AllDay={event.all_day}")
            
            # Sync with Google Calendar if connected
            try:
                sync_record = GoogleCalendarSync.objects.filter(
                    user=user,
                    is_connected=True,
                    sync_enabled=True,
                ).first()
                
                if sync_record and sync_record.sync_direction in ['bidirectional', 'to_google']:
                    GoogleCalendarService.create_event_in_google_calendar(user, event)
            except Exception:
                pass  # Silently fail if Google Calendar sync fails
            
            serializer.instance = event
        except Exception as e:
            import traceback
            print(f"Error in CalendarEventListCreateView.perform_create: {e}")
            print(f"Request data: {self.request.data}")
            print(f"Validated data: {serializer.validated_data if hasattr(serializer, 'validated_data') else 'N/A'}")
            traceback.print_exc()
            raise


class CalendarEventRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, and delete calendar events"""
    permission_classes = [IsAuthenticated]
    queryset = CalendarEvent.objects.all()
    
    def get_queryset(self):
        try:
            return CalendarService.get_events(user=self.request.user)
        except Exception as e:
            import traceback
            print(f"Error in CalendarEventRetrieveUpdateDestroyView.get_queryset: {e}")
            traceback.print_exc()
            return CalendarEvent.objects.none()
    
    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return UpdateCalendarEventSerializer
        return CalendarEventSerializer
    
    def perform_update(self, serializer):
        """Update a calendar event"""
        user = self.request.user
        event = self.get_object()
        
        # Check permissions
        if event.created_by != user and user not in event.attendees.all():
            raise PermissionError('You do not have permission to update this event.')
        
        data = serializer.validated_data.copy()
        
        # Extract attendees
        attendees = data.pop('attendees', None)
        if attendees is not None:
            event.attendees.set(attendees)
        
        # Update event using service
        updated_event = CalendarService.update_event(event, user, **data)
        
        # Sync with Google Calendar if connected
        try:
            sync_record = GoogleCalendarSync.objects.filter(
                user=user,
                is_connected=True,
                sync_enabled=True,
            ).first()
            
            if sync_record and sync_record.sync_direction in ['bidirectional', 'to_google']:
                GoogleCalendarService.update_event_in_google_calendar(user, updated_event)
        except Exception:
            pass  # Silently fail if Google Calendar sync fails
        
        serializer.instance = updated_event
    
    def perform_destroy(self, instance):
        """Delete a calendar event"""
        user = self.request.user
        event = instance
        
        # Check permissions
        if event.created_by != user:
            raise PermissionError('You do not have permission to delete this event.')
        
        # Sync with Google Calendar if connected
        try:
            sync_record = GoogleCalendarSync.objects.filter(
                user=user,
                is_connected=True,
                sync_enabled=True,
            ).first()
            
            if sync_record and sync_record.sync_direction in ['bidirectional', 'to_google']:
                GoogleCalendarService.delete_event_from_google_calendar(user, event)
        except Exception:
            pass  # Silently fail if Google Calendar sync fails
        
        # Delete event using service
        CalendarService.delete_event(event, user)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def upcoming_events(request):
    """Get upcoming events for the current user"""
    try:
        days = int(request.query_params.get('days', 7))
        events = CalendarService.get_upcoming_events(request.user, days=days)
        serializer = CalendarEventSerializer(events, many=True)
        return Response(serializer.data)
    except Exception as e:
        import traceback
        print(f"Error in upcoming_events: {e}")
        traceback.print_exc()
        return Response([], status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def events_by_date_range(request):
    """Get events within a date range"""
    try:
        start_date = request.query_params.get('start_date', None)
        end_date = request.query_params.get('end_date', None)
        
        if not start_date or not end_date:
            return Response(
                {'error': 'start_date and end_date are required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        
        try:
            start_dt = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
            end_dt = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
            
            # Make timezone-aware if not already
            if timezone.is_naive(start_dt):
                start_dt = timezone.make_aware(start_dt)
            if timezone.is_naive(end_dt):
                end_dt = timezone.make_aware(end_dt)
        except ValueError:
            return Response(
                {'error': 'Invalid date format. Use ISO 8601 format (YYYY-MM-DDTHH:MM:SS).'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        
        events = CalendarService.get_events_by_date_range(
            request.user,
            start_date=start_dt,
            end_date=end_dt,
        )
        serializer = CalendarEventSerializer(events, many=True)
        return Response(serializer.data)
    except Exception as e:
        import traceback
        print(f"Error in events_by_date_range: {e}")
        traceback.print_exc()
        return Response([], status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def events_by_type(request, event_type):
    """Get events by type"""
    try:
        events = CalendarService.get_events_by_type(request.user, event_type)
        serializer = CalendarEventSerializer(events, many=True)
        return Response(serializer.data)
    except Exception as e:
        import traceback
        print(f"Error in events_by_type: {e}")
        traceback.print_exc()
        return Response([], status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def cancel_event(request, pk):
    """Cancel a calendar event"""
    event = get_object_or_404(CalendarEvent, pk=pk)
    
    # Check permissions
    if event.created_by != request.user:
        return Response(
            {'error': 'You do not have permission to cancel this event.'},
            status=status.HTTP_403_FORBIDDEN,
        )
    
    # Cancel event using service
    cancelled_event = CalendarService.cancel_event(event, request.user)
    
    # Sync with Google Calendar if connected
    try:
        sync_record = GoogleCalendarSync.objects.filter(
            user=request.user,
            is_connected=True,
            sync_enabled=True,
        ).first()
        
        if sync_record and sync_record.sync_direction in ['bidirectional', 'to_google']:
            GoogleCalendarService.update_event_in_google_calendar(request.user, cancelled_event)
    except Exception:
        pass  # Silently fail if Google Calendar sync fails
    
    serializer = CalendarEventSerializer(cancelled_event)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_reminder(request, pk):
    """Add a reminder to an event"""
    event = get_object_or_404(CalendarEvent, pk=pk)
    
    reminder_type = request.data.get('reminder_type', 'notification')
    minutes_before = request.data.get('minutes_before', 15)
    
    reminder = CalendarService.add_reminder(
        event,
        request.user,
        reminder_type=reminder_type,
        minutes_before=minutes_before,
    )
    
    serializer = EventReminderSerializer(reminder)
    return Response(serializer.data, status=status.HTTP_201_CREATED)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def remove_reminder(request, pk):
    """Remove a reminder from an event"""
    event = get_object_or_404(CalendarEvent, pk=pk)
    
    reminder_type = request.data.get('reminder_type', None)
    minutes_before = request.data.get('minutes_before', None)
    
    CalendarService.remove_reminder(
        event,
        request.user,
        reminder_type=reminder_type,
        minutes_before=minutes_before,
    )
    
    return Response(status=status.HTTP_204_NO_CONTENT)


# iCal export/import views
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def export_ical(request):
    """Export events as iCal file"""
    # Get events for the current user
    events = CalendarService.get_events(user=request.user, is_cancelled=False)
    
    # Generate iCal file
    calendar_name = f"{request.user.get_full_name() or request.user.username}'s Calendar"
    filename = f"calendar-{request.user.id}.ics"
    
    response = ICalService.export_events_as_ical(events, calendar_name, filename)
    return response


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def import_ical(request):
    """Import events from iCal file"""
    ical_file = request.FILES.get('ical_file', None)
    
    if not ical_file:
        return Response(
            {'error': 'ical_file is required.'},
            status=status.HTTP_400_BAD_REQUEST,
        )
    
    try:
        # Read iCal file content
        ical_content = ical_file.read()
        
        # Import events
        imported_events = ICalService.import_ical_file(request.user, ical_content)
        
        serializer = CalendarEventSerializer(imported_events, many=True)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response(
            {'error': f'Error importing iCal file: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST,
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def ical_feed(request, user_id):
    """Generate iCal feed URL for a user"""
    # In production, this would generate a feed URL
    # For now, return a placeholder
    feed_url = ICalService.generate_ical_feed_url(request.user)
    return Response({'feed_url': feed_url})


# Google Calendar integration views
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def google_calendar_authorize(request):
    """Get Google Calendar authorization URL"""
    try:
        authorization_url, state = GoogleCalendarService.get_authorization_url(request.user)
        return Response({
            'authorization_url': authorization_url,
            'state': state,
        })
    except Exception as e:
        return Response(
            {'error': f'Error generating authorization URL: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST,
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def google_calendar_callback(request):
    """Handle Google Calendar OAuth callback"""
    authorization_code = request.data.get('authorization_code', None)
    state = request.data.get('state', None)
    
    if not authorization_code:
        return Response(
            {'error': 'authorization_code is required.'},
            status=status.HTTP_400_BAD_REQUEST,
        )
    
    try:
        sync_record = GoogleCalendarService.handle_oauth_callback(
            request.user,
            authorization_code,
            state,
        )
        
        serializer = GoogleCalendarSyncSerializer(sync_record)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response(
            {'error': f'Error handling OAuth callback: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST,
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def google_calendar_disconnect(request):
    """Disconnect Google Calendar"""
    try:
        sync_record = GoogleCalendarService.disconnect_google_calendar(request.user)
        return Response({'message': 'Google Calendar disconnected successfully.'})
    except Exception as e:
        return Response(
            {'error': f'Error disconnecting Google Calendar: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST,
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def google_calendar_sync_status(request):
    """Get Google Calendar sync status"""
    sync_record = GoogleCalendarSync.objects.filter(user=request.user).first()
    
    if not sync_record:
        return Response({
            'is_connected': False,
            'sync_enabled': False,
        })
    
    serializer = GoogleCalendarSyncSerializer(sync_record)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def google_calendar_sync(request):
    """Sync events with Google Calendar"""
    sync_direction = request.data.get('sync_direction', 'bidirectional')
    
    try:
        if sync_direction == 'from_google':
            # Sync from Google Calendar
            imported_events = GoogleCalendarService.sync_events_from_google_calendar(request.user)
            serializer = CalendarEventSerializer(imported_events, many=True)
            return Response(serializer.data)
        elif sync_direction == 'to_google':
            # Sync to Google Calendar
            synced_events = GoogleCalendarService.sync_events_to_google_calendar(request.user)
            serializer = CalendarEventSerializer(synced_events, many=True)
            return Response(serializer.data)
        else:
            # Bidirectional sync
            imported_events = GoogleCalendarService.sync_events_from_google_calendar(request.user)
            synced_events = GoogleCalendarService.sync_events_to_google_calendar(request.user)
            serializer = CalendarEventSerializer(synced_events, many=True)
            return Response(serializer.data)
    except Exception as e:
        return Response(
            {'error': f'Error syncing with Google Calendar: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST,
        )
