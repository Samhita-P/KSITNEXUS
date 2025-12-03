import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/calendar_event_model.dart';
import '../utils/logger.dart';

final appLogger = Logger('NotificationService');

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      // Initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions for Android 13+
      if (androidSettings != null) {
        await _requestAndroidPermissions();
      }

      _initialized = true;
      appLogger.info('Notification service initialized successfully');
    } catch (e) {
      appLogger.error('Error initializing notification service: $e');
      rethrow;
    }
  }

  /// Request Android notification permissions (Android 13+)
  static Future<void> _requestAndroidPermissions() async {
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    appLogger.info('Notification tapped: ${response.payload}');
    // Handle navigation or action when notification is tapped
  }

  /// Schedule a notification for a calendar event
  static Future<void> scheduleEventReminder(
    CalendarEvent event, {
    DateTime? reminderTime,
    int minutesBefore = 15,
  }) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      if (event.id == null) {
        appLogger.warning('Cannot schedule reminder: event has no ID');
        return;
      }

      // Calculate reminder time
      final reminder = reminderTime ?? 
          event.startTime.subtract(Duration(minutes: minutesBefore));

      // Don't schedule if reminder time is in the past
      if (reminder.isBefore(DateTime.now())) {
        appLogger.warning('Reminder time is in the past: $reminder');
        return;
      }

      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'calendar_events',
        'Calendar Events',
        channelDescription: 'Notifications for calendar events and reminders',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Notification details
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Convert reminder time to local timezone for scheduling
      final reminderLocal = reminder.toLocal();
      final scheduledTime = tz.TZDateTime.from(reminderLocal, tz.local);
      
      // Schedule the notification
      await _notifications.zonedSchedule(
        event.id!, // Use event ID as notification ID
        event.title,
        _getNotificationBody(event),
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'event_${event.id}',
      );

      appLogger.info(
        'Scheduled reminder for event "${event.title}" at $reminder',
      );
    } catch (e) {
      appLogger.error('Error scheduling event reminder: $e');
      rethrow;
    }
  }

  /// Cancel a scheduled reminder for an event
  static Future<void> cancelEventReminder(int eventId) async {
    try {
      await _notifications.cancel(eventId);
      appLogger.info('Cancelled reminder for event ID: $eventId');
    } catch (e) {
      appLogger.error('Error cancelling event reminder: $e');
      rethrow;
    }
  }

  /// Cancel all reminders for a list of events
  static Future<void> cancelAllEventReminders(List<int> eventIds) async {
    try {
      for (final eventId in eventIds) {
        await cancelEventReminder(eventId);
      }
      appLogger.info('Cancelled reminders for ${eventIds.length} events');
    } catch (e) {
      appLogger.error('Error cancelling event reminders: $e');
    }
  }

  /// Reschedule all reminders for a list of events
  static Future<void> rescheduleEventReminders(
    List<CalendarEvent> events,
  ) async {
    try {
      // Cancel all existing reminders first
      final eventIds = events.where((e) => e.id != null).map((e) => e.id!).toList();
      await cancelAllEventReminders(eventIds);

      // Schedule new reminders for events with reminders enabled
      for (final event in events) {
        if (event.hasReminder ?? false) {
          await scheduleEventReminder(event);
        }
      }

      appLogger.info('Rescheduled reminders for ${events.length} events');
    } catch (e) {
      appLogger.error('Error rescheduling event reminders: $e');
      rethrow;
    }
  }

  /// Get notification body text
  static String _getNotificationBody(CalendarEvent event) {
    if (event.allDay) {
      return 'Event: ${event.title}\nDate: ${_formatDate(event.startTime)}';
    }
    
    final timeStr = _formatTime(event.startTime);
    final dateStr = _formatDate(event.startTime);
    
    if (event.endTime != null) {
      final endTimeStr = _formatTime(event.endTime!);
      return 'Event: ${event.title}\n$dateStr from $timeStr to $endTimeStr';
    }
    
    return 'Event: ${event.title}\n$dateStr at $timeStr';
  }

  /// Format date for notification
  static String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  /// Format time for notification
  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Show immediate notification (for testing)
  static Future<void> showTestNotification() async {
    try {
      if (!_initialized) {
        await initialize();
      }

      const androidDetails = AndroidNotificationDetails(
        'calendar_events',
        'Calendar Events',
        channelDescription: 'Notifications for calendar events and reminders',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        999999,
        'Test Notification',
        'Notification service is working!',
        details,
      );

      appLogger.info('Test notification shown');
    } catch (e) {
      appLogger.error('Error showing test notification: $e');
      rethrow;
    }
  }

  /// Get pending notifications count
  static Future<int> getPendingNotificationsCount() async {
    try {
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      return pendingNotifications.length;
    } catch (e) {
      appLogger.error('Error getting pending notifications count: $e');
      return 0;
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      appLogger.info('Cancelled all notifications');
    } catch (e) {
      appLogger.error('Error cancelling all notifications: $e');
    }
  }
}

