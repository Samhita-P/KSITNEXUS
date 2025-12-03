/// Timezone utility for handling IST (Indian Standard Time) conversions
class TimezoneUtils {
  /// IST timezone offset: UTC+5:30
  static const Duration istOffset = Duration(hours: 5, minutes: 30);

  /// Convert a DateTime to IST (Indian Standard Time)
  /// If the DateTime is in UTC, converts it to IST by adding the offset
  static DateTime toIST(DateTime dateTime) {
    if (dateTime.isUtc) {
      // Convert UTC to IST by adding 5:30 hours
      // Add the offset to get IST time values
      final utcTime = dateTime.toUtc();
      final istTime = utcTime.add(istOffset);
      // Create a new local DateTime with the IST values
      return DateTime(
        istTime.year,
        istTime.month,
        istTime.day,
        istTime.hour,
        istTime.minute,
        istTime.second,
        istTime.millisecond,
        istTime.microsecond,
      );
    }
    // If already local, return as is (assuming device is set to IST)
    return dateTime;
  }

  /// Format time in IST (HH:mm format)
  /// Ensures the time is displayed in Indian Standard Time
  static String formatTimeIST(DateTime dateTime) {
    final istTime = toIST(dateTime);
    return '${istTime.hour.toString().padLeft(2, '0')}:${istTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format date in IST (dd/MM/yyyy format)
  /// Ensures the date is displayed correctly for IST timezone
  static String formatDateIST(DateTime dateTime) {
    final istTime = toIST(dateTime);
    return '${istTime.day}/${istTime.month}/${istTime.year}';
  }

  /// Format date and time in IST
  static String formatDateTimeIST(DateTime dateTime) {
    return '${formatDateIST(dateTime)} ${formatTimeIST(dateTime)}';
  }
}

