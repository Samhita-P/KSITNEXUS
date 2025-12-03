import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calendar_event_model.dart';
import 'api_service.dart';
import 'notification_service.dart';
import '../utils/logger.dart';
import '../providers/data_providers.dart';

final appLogger = Logger('CalendarService');

// Calendar Events State Providers
final calendarEventsProvider = StateNotifierProvider<CalendarEventsNotifier, AsyncValue<List<CalendarEvent>>>(
  (ref) => CalendarEventsNotifier(ref.read(apiServiceProvider)),
);

class CalendarEventsNotifier extends StateNotifier<AsyncValue<List<CalendarEvent>>> {
  final ApiService _apiService;

  CalendarEventsNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
    bool? isCancelled,
    String? privacy,
    String? search,
  }) async {
    try {
      state = const AsyncValue.loading();
      final events = await _apiService.getCalendarEvents(
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
        eventType: eventType,
        isCancelled: isCancelled,
        privacy: privacy,
        search: search,
      );
      state = AsyncValue.data(events);
      
      // Reschedule reminders for all events with reminders enabled
      try {
        await NotificationService.rescheduleEventReminders(events);
        print('📅 Rescheduled reminders for ${events.length} events');
      } catch (e) {
        print('📅 Error rescheduling reminders: $e');
        // Don't fail event loading if reminder scheduling fails
      }
    } catch (e, stackTrace) {
      appLogger.error('Error loading calendar events', error: e, stackTrace: stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshEvents() async {
    await loadEvents();
  }

  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    try {
      print('📅 Creating event: ${event.title} for ${event.startTime}');
      print('📅 Event allDay: ${event.allDay}');
      print('📅 Event timezone: ${event.timezone}');
      
      final createdEvent = await _apiService.createCalendarEvent(event);
      print('📅 Event created successfully:');
      print('   ID: ${createdEvent.id}');
      print('   Title: ${createdEvent.title}');
      print('   Start Time: ${createdEvent.startTime}');
      print('   Start Time UTC: ${createdEvent.startTime.toUtc()}');
      print('   All Day: ${createdEvent.allDay}');
      
      // Always reload events from backend to ensure we have the latest data
      print('📅 Reloading events from backend...');
      // Don't call loadEvents() here as it's called in createEvent screen after scheduling notification
      
      // Verify the event is in the loaded list
      state.whenData((currentEvents) {
        final found = currentEvents.any((e) => e.id == createdEvent.id);
        print('📅 Event ${createdEvent.id} found in loaded events: $found');
        if (!found) {
          print('📅 WARNING: Created event not found in loaded events!');
          print('📅 Total events loaded: ${currentEvents.length}');
          for (final e in currentEvents) {
            print('   - Event ${e.id}: ${e.title} - ${e.startTime}');
          }
        }
      });
      
      print('📅 Events reloaded successfully');
      return createdEvent;
    } catch (e, stackTrace) {
      appLogger.error('Error creating calendar event', error: e, stackTrace: stackTrace);
      print('📅 Error creating event: $e');
      print('📅 Stack trace: $stackTrace');
      // Reload events on error to ensure consistency
      await loadEvents();
      rethrow;
    }
  }

  Future<CalendarEvent> updateEvent(int id, CalendarEvent event) async {
    try {
      // Cancel existing reminder before updating
      try {
        await NotificationService.cancelEventReminder(id);
      } catch (e) {
        print('📅 Error cancelling old reminder: $e');
      }
      
      final updatedEvent = await _apiService.updateCalendarEvent(id, event);
      
      // Reschedule reminder if event has reminders enabled
      if (updatedEvent.hasReminder == true && updatedEvent.id != null) {
        try {
          // Get reminder minutes from the event's reminders
          int reminderMinutes = 15;
          if (updatedEvent.reminders != null && updatedEvent.reminders!.isNotEmpty) {
            reminderMinutes = updatedEvent.reminders!.first.minutesBefore;
          }
          await NotificationService.scheduleEventReminder(
            updatedEvent,
            minutesBefore: reminderMinutes,
          );
        } catch (e) {
          print('📅 Error rescheduling reminder for updated event: $e');
        }
      }
      
      // Reload events to include the updated event
      await loadEvents();
      return updatedEvent;
    } catch (e, stackTrace) {
      appLogger.error('Error updating calendar event', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteEvent(int id) async {
    try {
      // Cancel reminder before deleting event
      try {
        await NotificationService.cancelEventReminder(id);
      } catch (e) {
        print('📅 Error cancelling reminder for deleted event: $e');
      }
      
      await _apiService.deleteCalendarEvent(id);
      // Reload events to exclude the deleted event
      await loadEvents();
    } catch (e, stackTrace) {
      appLogger.error('Error deleting calendar event', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<CalendarEvent> cancelEvent(int id) async {
    try {
      final cancelledEvent = await _apiService.cancelCalendarEvent(id);
      
      // Cancel reminder for cancelled event
      try {
        await NotificationService.cancelEventReminder(id);
      } catch (e) {
        print('📅 Error cancelling reminder for cancelled event: $e');
      }
      
      // Reload events to include the cancelled event
      await loadEvents();
      return cancelledEvent;
    } catch (e, stackTrace) {
      appLogger.error('Error cancelling calendar event', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

// Upcoming Events Provider
final upcomingEventsProvider = FutureProvider.family<List<CalendarEvent>, int>(
  (ref, days) async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getUpcomingEvents(days: days);
  },
);

// Events by Date Range Provider
final eventsByDateRangeProvider = FutureProvider.family<List<CalendarEvent>, Map<String, DateTime>>(
  (ref, dateRange) async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getEventsByDateRange(
      startDate: dateRange['start']!,
      endDate: dateRange['end']!,
    );
  },
);

// Events by Type Provider
final eventsByTypeProvider = FutureProvider.family<List<CalendarEvent>, String>(
  (ref, eventType) async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getEventsByType(eventType);
  },
);

// Calendar Event Detail Provider
final calendarEventDetailProvider = FutureProvider.family<CalendarEvent, int>(
  (ref, eventId) async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getCalendarEvent(eventId);
  },
);

// Google Calendar Sync Provider
final googleCalendarSyncProvider = StateNotifierProvider<GoogleCalendarSyncNotifier, AsyncValue<GoogleCalendarSync?>>(
  (ref) => GoogleCalendarSyncNotifier(ref.read(apiServiceProvider)),
);

class GoogleCalendarSyncNotifier extends StateNotifier<AsyncValue<GoogleCalendarSync?>> {
  final ApiService _apiService;

  GoogleCalendarSyncNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadSyncStatus();
  }

  Future<void> loadSyncStatus() async {
    try {
      state = const AsyncValue.loading();
      final syncStatus = await _apiService.getGoogleCalendarSyncStatus();
      state = AsyncValue.data(syncStatus);
    } catch (e, stackTrace) {
      appLogger.error('Error loading Google Calendar sync status', error: e, stackTrace: stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<Map<String, dynamic>> getAuthorizationUrl() async {
    try {
      return await _apiService.getGoogleCalendarAuthorizationUrl();
    } catch (e, stackTrace) {
      appLogger.error('Error getting Google Calendar authorization URL', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<GoogleCalendarSync> connect(String authorizationCode, {String? state}) async {
    try {
      final sync = await _apiService.connectGoogleCalendar(
        authorizationCode: authorizationCode,
        state: state,
      );
      await loadSyncStatus();
      return sync;
    } catch (e, stackTrace) {
      appLogger.error('Error connecting Google Calendar', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      await _apiService.disconnectGoogleCalendar();
      await loadSyncStatus();
    } catch (e, stackTrace) {
      appLogger.error('Error disconnecting Google Calendar', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<CalendarEvent>> sync({String syncDirection = 'bidirectional'}) async {
    try {
      final events = await _apiService.syncGoogleCalendar(syncDirection: syncDirection);
      await loadSyncStatus();
      return events;
    } catch (e, stackTrace) {
      appLogger.error('Error syncing Google Calendar', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

