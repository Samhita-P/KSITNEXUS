from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
from apps.calendars.models import CalendarEvent, EventReminder, GoogleCalendarSync, CalendarEventSync

User = get_user_model()


class EventReminderSerializer(serializers.ModelSerializer):
    """Serializer for EventReminder"""
    reminder_time = serializers.DateTimeField(read_only=True)
    should_send = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = EventReminder
        fields = [
            'id', 'event', 'user', 'reminder_type', 'minutes_before',
            'is_sent', 'sent_at', 'reminder_time', 'should_send',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'is_sent', 'sent_at', 'created_at', 'updated_at']


class CalendarEventSerializer(serializers.ModelSerializer):
    """Serializer for CalendarEvent"""
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True, allow_null=True)
    created_by_email = serializers.CharField(source='created_by.email', read_only=True, allow_null=True)
    attendees_details = serializers.SerializerMethodField()
    external_attendees = serializers.JSONField(default=list)
    reminders = EventReminderSerializer(many=True, read_only=True)
    is_upcoming = serializers.BooleanField(read_only=True)
    is_past = serializers.BooleanField(read_only=True)
    is_ongoing = serializers.BooleanField(read_only=True)
    duration_minutes = serializers.IntegerField(read_only=True)
    event_type_display = serializers.CharField(read_only=True)
    privacy_display = serializers.CharField(read_only=True)
    
    class Meta:
        model = CalendarEvent
        fields = [
            'id', 'title', 'description', 'event_type', 'event_type_display',
            'start_time', 'end_time', 'all_day', 'timezone',
            'location', 'meeting_link',
            'is_recurring', 'recurrence_pattern', 'recurrence_end_date', 'recurrence_count',
            'color', 'privacy', 'privacy_display',
            'created_by', 'created_by_name', 'created_by_email',
            'attendees', 'attendees_details', 'external_attendees',
            'is_cancelled', 'cancelled_at', 'cancelled_by',
            'related_meeting', 'related_study_group_event',
            'reminders',
            'is_upcoming', 'is_past', 'is_ongoing', 'duration_minutes',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_by', 'cancelled_at', 'cancelled_by', 'created_at', 'updated_at']
    
    def get_attendees_details(self, obj):
        """Get detailed information about attendees"""
        attendees = obj.attendees.all()
        return [
            {
                'id': attendee.id,
                'email': attendee.email,
                'name': attendee.get_full_name() or attendee.username,
            }
            for attendee in attendees
        ]


class CreateCalendarEventSerializer(serializers.ModelSerializer):
    """Serializer for creating calendar events"""
    attendees = serializers.PrimaryKeyRelatedField(
        many=True,
        queryset=User.objects.all(),
        required=False,
        allow_empty=True,
    )
    external_attendees = serializers.JSONField(default=list, required=False)
    reminders = serializers.JSONField(default=list, required=False)
    
    class Meta:
        model = CalendarEvent
        fields = [
            'title', 'description', 'event_type',
            'start_time', 'end_time', 'all_day', 'timezone',
            'location', 'meeting_link',
            'is_recurring', 'recurrence_pattern', 'recurrence_end_date', 'recurrence_count',
            'color', 'privacy',
            'attendees', 'external_attendees', 'reminders',
            'related_meeting', 'related_study_group_event',
        ]
        extra_kwargs = {
            'location': {'required': False, 'allow_blank': True, 'allow_null': True},
            'meeting_link': {'required': False, 'allow_blank': True, 'allow_null': True},
            'description': {'required': False, 'allow_blank': True, 'allow_null': True},
            'end_time': {'required': False, 'allow_null': True},
            'timezone': {'required': False, 'default': 'UTC'},
            'event_type': {'required': False, 'default': 'event'},
            'recurrence_pattern': {'required': False, 'default': 'none'},
            'color': {'required': False, 'default': '#3b82f6'},
            'privacy': {'required': False, 'default': 'private'},
        }
    
    def validate_start_time(self, value):
        """Validate start time"""
        # Make sure value is timezone-aware
        if timezone.is_naive(value):
            value = timezone.make_aware(value)
        
        # For all-day events, only check if date is in the past
        # For regular events, allow some flexibility (events can be created close to current time)
        all_day = self.initial_data.get('all_day', False)
        if all_day:
            # For all-day events, compare dates only
            if value.date() < timezone.now().date():
                raise serializers.ValidationError("Event date cannot be in the past.")
        else:
            # For regular events, allow events up to 1 hour in the past (for timezone issues)
            # But allow all future events
            now = timezone.now()
            if value < now - timedelta(hours=1):
                raise serializers.ValidationError("Event cannot be scheduled more than 1 hour in the past.")
        return value
    
    def validate_end_time(self, value):
        """Validate end time"""
        start_time = self.initial_data.get('start_time')
        if start_time and value and value < start_time:
            raise serializers.ValidationError("End time must be after start time.")
        return value
    
    def validate_reminders(self, value):
        """Validate reminders"""
        if value is None:
            return []
        if not isinstance(value, list):
            return []  # Return empty list instead of raising error
        validated_reminders = []
        for reminder in value:
            if isinstance(reminder, dict):
                # Ensure required fields have defaults
                validated_reminders.append({
                    'type': reminder.get('type', 'notification'),
                    'minutes_before': reminder.get('minutes_before', 15),
                })
        return validated_reminders


class UpdateCalendarEventSerializer(serializers.ModelSerializer):
    """Serializer for updating calendar events"""
    attendees = serializers.PrimaryKeyRelatedField(
        many=True,
        queryset=User.objects.all(),
        required=False,
        allow_empty=True,
    )
    external_attendees = serializers.JSONField(default=list, required=False)
    
    class Meta:
        model = CalendarEvent
        fields = [
            'title', 'description', 'event_type',
            'start_time', 'end_time', 'all_day', 'timezone',
            'location', 'meeting_link',
            'is_recurring', 'recurrence_pattern', 'recurrence_end_date', 'recurrence_count',
            'color', 'privacy',
            'attendees', 'external_attendees',
            'related_meeting', 'related_study_group_event',
        ]
        extra_kwargs = {
            'title': {'required': False},
            'description': {'required': False},
            'event_type': {'required': False},
            'start_time': {'required': False},
            'end_time': {'required': False},
            'all_day': {'required': False},
            'timezone': {'required': False},
            'location': {'required': False},
            'meeting_link': {'required': False},
            'is_recurring': {'required': False},
            'recurrence_pattern': {'required': False},
            'recurrence_end_date': {'required': False},
            'recurrence_count': {'required': False},
            'color': {'required': False},
            'privacy': {'required': False},
            'external_attendees': {'required': False},
        }
    
    def validate_start_time(self, value):
        """Validate start time"""
        if value and value < timezone.now():
            raise serializers.ValidationError("Event cannot be scheduled in the past.")
        return value
    
    def validate_end_time(self, value):
        """Validate end time"""
        start_time = self.validated_data.get('start_time') or self.instance.start_time
        if start_time and value and value < start_time:
            raise serializers.ValidationError("End time must be after start time.")
        return value


class GoogleCalendarSyncSerializer(serializers.ModelSerializer):
    """Serializer for GoogleCalendarSync"""
    is_token_expired = serializers.BooleanField(read_only=True)
    needs_sync = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = GoogleCalendarSync
        fields = [
            'id', 'user', 'is_connected', 'calendar_id',
            'last_sync_at', 'sync_enabled', 'sync_direction',
            'is_token_expired', 'needs_sync',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'user', 'is_connected', 'calendar_id',
            'last_sync_at', 'created_at', 'updated_at',
        ]


class CalendarEventSyncSerializer(serializers.ModelSerializer):
    """Serializer for CalendarEventSync"""
    event = CalendarEventSerializer(read_only=True)
    
    class Meta:
        model = CalendarEventSync
        fields = [
            'id', 'event', 'google_calendar_id', 'ical_uid',
            'last_synced_at', 'sync_status',
        ]
        read_only_fields = ['id', 'last_synced_at']

