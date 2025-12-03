import 'package:ksit_nexus_app/config/api_config.dart';

/// App-wide constants
class AppConstants {
  // API Configuration
  static String get baseUrl => ApiConfig.baseUrl;
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);

  // Cache Configuration
  static const int defaultCacheTtl = 300; // 5 minutes
  static const int longCacheTtl = 3600; // 1 hour
  static const int shortCacheTtl = 60; // 1 minute

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Retry Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Storage Keys
  static const String tokenKey = 'ksit_nexus_token';
  static const String refreshTokenKey = 'ksit_nexus_refresh_token';
  static const String userKey = 'ksit_nexus_user';
  static const String settingsKey = 'ksit_nexus_settings';

  // Notification Configuration
  static const Duration notificationTimeout = Duration(seconds: 5);
  static const int maxNotificationHistory = 100;

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx', 'txt'];

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // Error Messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'An unknown error occurred.';
  static const String timeoutError = 'Request timed out. Please try again.';

  // Success Messages
  static const String successMessage = 'Operation completed successfully.';
  static const String savedMessage = 'Changes saved successfully.';
  static const String deletedMessage = 'Item deleted successfully.';
}

