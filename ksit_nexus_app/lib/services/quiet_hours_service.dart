/// Quiet hours service for managing notification quiet hours
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

final appLogger = Logger('QuietHoursService');

class QuietHoursService {
  static final QuietHoursService _instance = QuietHoursService._internal();
  factory QuietHoursService() => _instance;
  QuietHoursService._internal();

  SharedPreferences? _prefs;
  static const String _enabledKey = 'quiet_hours_enabled';
  static const String _startHourKey = 'quiet_hours_start_hour';
  static const String _startMinuteKey = 'quiet_hours_start_minute';
  static const String _endHourKey = 'quiet_hours_end_hour';
  static const String _endMinuteKey = 'quiet_hours_end_minute';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Check if quiet hours are enabled
  Future<bool> isEnabled() async {
    try {
      return _prefs?.getBool(_enabledKey) ?? false;
    } catch (e) {
      appLogger.error('Error checking quiet hours enabled: $e');
      return false;
    }
  }

  /// Enable quiet hours
  Future<bool> enable() async {
    try {
      return await _prefs?.setBool(_enabledKey, true) ?? false;
    } catch (e) {
      appLogger.error('Error enabling quiet hours: $e');
      return false;
    }
  }

  /// Disable quiet hours
  Future<bool> disable() async {
    try {
      return await _prefs?.setBool(_enabledKey, false) ?? false;
    } catch (e) {
      appLogger.error('Error disabling quiet hours: $e');
      return false;
    }
  }

  /// Set quiet hours
  Future<bool> setQuietHours({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    try {
      await _prefs?.setInt(_startHourKey, startHour);
      await _prefs?.setInt(_startMinuteKey, startMinute);
      await _prefs?.setInt(_endHourKey, endHour);
      await _prefs?.setInt(_endMinuteKey, endMinute);
      return true;
    } catch (e) {
      appLogger.error('Error setting quiet hours: $e');
      return false;
    }
  }

  /// Get quiet hours
  Future<Map<String, int>?> getQuietHours() async {
    try {
      final startHour = _prefs?.getInt(_startHourKey);
      final startMinute = _prefs?.getInt(_startMinuteKey);
      final endHour = _prefs?.getInt(_endHourKey);
      final endMinute = _prefs?.getInt(_endMinuteKey);

      if (startHour == null ||
          startMinute == null ||
          endHour == null ||
          endMinute == null) {
        return null;
      }

      return {
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      };
    } catch (e) {
      appLogger.error('Error getting quiet hours: $e');
      return null;
    }
  }

  /// Check if current time is within quiet hours
  Future<bool> isQuietHours() async {
    try {
      final enabled = await isEnabled();
      if (!enabled) {
        return false;
      }

      final hours = await getQuietHours();
      if (hours == null) {
        return false;
      }

      final now = DateTime.now();
      final currentTime = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
      );

      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        hours['startHour']!,
        hours['startMinute']!,
      );

      final endTime = DateTime(
        now.year,
        now.month,
        now.day,
        hours['endHour']!,
        hours['endMinute']!,
      );

      // Handle quiet hours that span midnight
      if (startTime.isBefore(endTime) || startTime.isAtSameMomentAs(endTime)) {
        // Normal case: quiet hours within same day
        return currentTime.isAfter(startTime) && currentTime.isBefore(endTime);
      } else {
        // Quiet hours span midnight
        return currentTime.isAfter(startTime) || currentTime.isBefore(endTime);
      }
    } catch (e) {
      appLogger.error('Error checking quiet hours: $e');
      return false;
    }
  }

  /// Check if notification should be sent based on quiet hours
  Future<bool> shouldSendNotification(String priority) async {
    // Urgent and high priority notifications bypass quiet hours
    if (priority == 'urgent' || priority == 'high') {
      return true;
    }

    // Check quiet hours for medium and low priority
    final inQuietHours = await isQuietHours();
    return !inQuietHours;
  }

  /// Get next time when notifications can be sent
  Future<DateTime?> getNextSendTime() async {
    try {
      final enabled = await isEnabled();
      if (!enabled) {
        return null;
      }

      final inQuietHours = await isQuietHours();
      if (!inQuietHours) {
        return null;
      }

      final hours = await getQuietHours();
      if (hours == null) {
        return null;
      }

      final now = DateTime.now();
      final endTime = DateTime(
        now.year,
        now.month,
        now.day,
        hours['endHour']!,
        hours['endMinute']!,
      );

      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        hours['startHour']!,
        hours['startMinute']!,
      );

      // If end time is before start time, quiet hours span midnight
      if (endTime.isBefore(startTime)) {
        // End time is next day
        if (now.isAfter(startTime)) {
          // After start, end is next day
          return DateTime(
            now.year,
            now.month,
            now.day + 1,
            hours['endHour']!,
            hours['endMinute']!,
          );
        } else {
          // Before start, end is today
          return endTime;
        }
      } else {
        // Same day
        return endTime;
      }
    } catch (e) {
      appLogger.error('Error getting next send time: $e');
      return null;
    }
  }
}

/// Global quiet hours service instance
final quietHoursService = QuietHoursService();

