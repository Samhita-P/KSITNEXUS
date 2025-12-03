/// Request tracing utilities for Flutter
import 'package:flutter/foundation.dart';

class TraceId {
  static final TraceId _instance = TraceId._internal();
  factory TraceId() => _instance;
  TraceId._internal();

  String? _currentTraceId;

  /// Generate a new trace ID
  String generate() {
    _currentTraceId = _generateTraceId();
    return _currentTraceId!;
  }

  /// Get the current trace ID
  String? get current => _currentTraceId;

  /// Set the trace ID (e.g., from response headers)
  void set(String traceId) {
    _currentTraceId = traceId;
  }

  /// Clear the current trace ID
  void clear() {
    _currentTraceId = null;
  }

  String _generateTraceId() {
    // Generate a UUID-like trace ID
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    return 'trace-$random-${DateTime.now().toIso8601String()}';
  }
}

/// Global trace ID instance
final traceId = TraceId();

