/// Structured logging utilities for Flutter
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class Logger {
  final String name;
  final LogLevel minLevel;

  Logger(this.name, {this.minLevel = LogLevel.info});

  void _log(LogLevel level, String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    if (level.index < minLevel.index) {
      return;
    }

    final levelName = level.name.toUpperCase();
    final timestamp = DateTime.now().toIso8601String();
    final logData = {
      'timestamp': timestamp,
      'level': levelName,
      'logger': name,
      'message': message,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      if (extra != null) ...extra,
    };

    if (kDebugMode) {
      developer.log(
        message,
        name: name,
        level: level.index,
        error: error,
        stackTrace: stackTrace,
      );
    }

    // In production, you can send logs to a logging service
    if (kReleaseMode && level.index >= LogLevel.error.index) {
      // Send to crash reporting service (Sentry, Firebase Crashlytics, etc.)
      _sendToLoggingService(logData);
    }
  }

  void debug(String message, {Map<String, dynamic>? extra}) {
    _log(LogLevel.debug, message, extra: extra);
  }

  void info(String message, {Map<String, dynamic>? extra}) {
    _log(LogLevel.info, message, extra: extra);
  }

  void warning(String message, {
    Object? error,
    Map<String, dynamic>? extra,
  }) {
    _log(LogLevel.warning, message, error: error, extra: extra);
  }

  void error(String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace, extra: extra);
  }

  void critical(String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _log(LogLevel.critical, message, error: error, stackTrace: stackTrace, extra: extra);
  }

  void _sendToLoggingService(Map<String, dynamic> logData) {
    // Implement logging service integration here
    // Example: Sentry, Firebase Crashlytics, etc.
  }
}

/// Global logger instance
final appLogger = Logger('KSITNexus');

/// Get a logger for a specific module
Logger getLogger(String name) => Logger(name);

