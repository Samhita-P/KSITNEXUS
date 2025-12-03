import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PerformanceService {
  static const String _cachePrefix = 'ksit_nexus_cache_';
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration _cacheExpiry = Duration(days: 7);
  
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  Timer? _cacheCleanupTimer;

  PerformanceService() {
    _startCacheCleanup();
  }

  // Memory cache management
  void setMemoryCache(String key, dynamic value) {
    _memoryCache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  T? getMemoryCache<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null && 
        DateTime.now().difference(timestamp) < _cacheExpiry) {
      return _memoryCache[key] as T?;
    }
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    return null;
  }

  void clearMemoryCache() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
  }

  // Persistent cache management
  Future<void> setPersistentCache(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final jsonValue = jsonEncode(value);
      await prefs.setString(cacheKey, jsonValue);
      await prefs.setString('${cacheKey}_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      if (kDebugMode) {
        print('Error setting persistent cache: $e');
      }
    }
  }

  Future<T?> getPersistentCache<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '${cacheKey}_timestamp';
      
      final jsonValue = prefs.getString(cacheKey);
      final timestampString = prefs.getString(timestampKey);
      
      if (jsonValue != null && timestampString != null) {
        final timestamp = DateTime.parse(timestampString);
        if (DateTime.now().difference(timestamp) < _cacheExpiry) {
          return jsonDecode(jsonValue) as T?;
        } else {
          // Remove expired cache
          await prefs.remove(cacheKey);
          await prefs.remove(timestampKey);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting persistent cache: $e');
      }
    }
    return null;
  }

  Future<void> clearPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing persistent cache: $e');
      }
    }
  }

  // Image cache management
  Future<void> preloadImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        await CachedNetworkImage.evictFromCache(url);
        // Preload the image
        await CachedNetworkImage.getImageFromCache(url);
      } catch (e) {
        if (kDebugMode) {
          print('Error preloading image $url: $e');
        }
      }
    }
  }

  Future<void> clearImageCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final imageCacheDir = Directory('${cacheDir.path}/imageCache');
      if (await imageCacheDir.exists()) {
        await imageCacheDir.delete(recursive: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing image cache: $e');
      }
    }
  }

  // Data optimization
  Map<String, dynamic> optimizeApiResponse(Map<String, dynamic> data) {
    // Remove unnecessary fields
    final optimized = Map<String, dynamic>.from(data);
    
    // Remove null values
    optimized.removeWhere((key, value) => value == null);
    
    // Optimize nested objects
    for (final key in optimized.keys) {
      if (optimized[key] is Map<String, dynamic>) {
        optimized[key] = optimizeApiResponse(optimized[key] as Map<String, dynamic>);
      } else if (optimized[key] is List) {
        optimized[key] = _optimizeList(optimized[key] as List);
      }
    }
    
    return optimized;
  }

  List<dynamic> _optimizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return optimizeApiResponse(item);
      } else if (item is List) {
        return _optimizeList(item);
      }
      return item;
    }).toList();
  }

  // Pagination optimization
  Map<String, dynamic> optimizePagination({
    required List<dynamic> items,
    required int currentPage,
    required int totalPages,
    required int totalItems,
    int pageSize = 20,
  }) {
    return {
      'items': items,
      'pagination': {
        'current_page': currentPage,
        'total_pages': totalPages,
        'total_items': totalItems,
        'page_size': pageSize,
        'has_next': currentPage < totalPages,
        'has_previous': currentPage > 1,
      }
    };
  }

  // Performance monitoring
  void startPerformanceTimer(String operation) {
    if (kDebugMode) {
      print('Starting performance timer for: $operation');
    }
  }

  void endPerformanceTimer(String operation, {String? additionalInfo}) {
    if (kDebugMode) {
      print('Ending performance timer for: $operation${additionalInfo != null ? ' - $additionalInfo' : ''}');
    }
  }

  // Cache cleanup
  void _startCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _cleanupExpiredCache();
    });
  }

  void _cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (kDebugMode && expiredKeys.isNotEmpty) {
      print('Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }

  // Dispose
  void dispose() {
    _cacheCleanupTimer?.cancel();
    clearMemoryCache();
  }
}

// Provider for Performance Service
final performanceServiceProvider = Provider<PerformanceService>((ref) {
  final service = PerformanceService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Cached data providers
final cachedNotificationsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final performanceService = ref.watch(performanceServiceProvider);
  return performanceService.getPersistentCache<List<Map<String, dynamic>>>('notifications_$userId') ?? [];
});

final cachedStudyGroupsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final performanceService = ref.watch(performanceServiceProvider);
  return performanceService.getPersistentCache<List<Map<String, dynamic>>>('study_groups') ?? [];
});

final cachedReservationsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, resourceType) async {
  final performanceService = ref.watch(performanceServiceProvider);
  return performanceService.getPersistentCache<List<Map<String, dynamic>>>('reservations_$resourceType') ?? [];
});
