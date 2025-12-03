/// Cache utilities for Flutter
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  SharedPreferences? _prefs;
  final Map<String, CacheEntry> _memoryCache = {};
  static const int defaultTtl = 300; // 5 minutes

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get cached value
  Future<T?> get<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(key)) {
        final entry = _memoryCache[key]!;
        if (!entry.isExpired) {
          return fromJson(entry.data);
        }
        _memoryCache.remove(key);
      }

      // Check persistent cache
      if (_prefs != null && _prefs!.containsKey(key)) {
        final cacheData = _prefs!.getString(key);
        if (cacheData != null) {
          final entry = CacheEntry.fromJson(jsonDecode(cacheData));
          if (!entry.isExpired) {
            // Load into memory cache
            _memoryCache[key] = entry;
            return fromJson(entry.data);
          }
          // Remove expired entry
          await _prefs!.remove(key);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Cache get error: $e');
      return null;
    }
  }

  /// Set cached value
  Future<void> set<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T) toJson, {
    int? ttl,
  }) async {
    try {
      final ttlSeconds = ttl ?? defaultTtl;
      final entry = CacheEntry(
        data: toJson(value),
        expiresAt: DateTime.now().add(Duration(seconds: ttlSeconds)),
      );

      // Store in memory cache
      _memoryCache[key] = entry;

      // Store in persistent cache
      if (_prefs != null) {
        await _prefs!.setString(key, jsonEncode(entry.toJson()));
      }
    } catch (e) {
      debugPrint('Cache set error: $e');
    }
  }

  /// Remove cached value
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _prefs?.remove(key);
  }

  /// Clear all cache
  Future<void> clear() async {
    _memoryCache.clear();
    await _prefs?.clear();
  }

  /// Clear expired entries
  Future<void> clearExpired() async {
    final now = DateTime.now();
    
    // Clear memory cache
    _memoryCache.removeWhere((key, entry) => entry.isExpired);

    // Clear persistent cache
    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        try {
          final cacheData = _prefs!.getString(key);
          if (cacheData != null) {
            final entry = CacheEntry.fromJson(jsonDecode(cacheData));
            if (entry.isExpired) {
              await _prefs!.remove(key);
            }
          }
        } catch (e) {
          // Invalid cache entry, remove it
          await _prefs!.remove(key);
        }
      }
    }
  }

  /// Generate cache key from parameters
  static String generateKey(String prefix, Map<String, dynamic> params) {
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final paramsJson = jsonEncode(sortedParams);
    final bytes = utf8.encode('$prefix:$paramsJson');
    final digest = sha256.convert(bytes);
    return '$prefix:${digest.toString().substring(0, 16)}';
  }
}

class CacheEntry {
  final Map<String, dynamic> data;
  final DateTime expiresAt;

  CacheEntry({
    required this.data,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'data': data,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
        data: json['data'] as Map<String, dynamic>,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
}

/// Global cache manager instance
final cacheManager = CacheManager();

