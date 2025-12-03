import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ksit_nexus_app/services/api_service.dart';
import 'package:ksit_nexus_app/services/conflict_resolution_service.dart';
import 'package:ksit_nexus_app/models/user_model.dart';
import 'package:ksit_nexus_app/models/notification_model.dart';
import 'package:ksit_nexus_app/models/study_group_model.dart';
import 'package:ksit_nexus_app/models/reservation_model.dart';
import 'package:ksit_nexus_app/models/notice_model.dart';
import 'package:ksit_nexus_app/models/complaint_model.dart';
import 'package:ksit_nexus_app/models/feedback_model.dart';

class OfflineService {
  static const String _offlinePrefix = 'offline_';
  static const String _syncQueueKey = 'sync_queue';
  static const String _lastSyncKey = 'last_sync';
  static const String _selectiveSyncKey = 'selective_sync_settings';
  
  final ApiService _apiService;
  final Connectivity _connectivity;
  final ConflictResolutionService _conflictService;
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  bool _isOnline = true;
  Timer? _syncTimer;
  final List<Map<String, dynamic>> _syncQueue = [];
  Map<String, bool> _selectiveSyncSettings = {
    'notifications': true,
    'complaints': true,
    'reservations': true,
    'study_groups': true,
    'notices': true,
    'feedback': true,
    'chat_messages': true,
    'user_profile': true,
  };

  OfflineService(this._apiService, this._connectivity) : _conflictService = ConflictResolutionService(SharedPreferences.getInstance() as SharedPreferences) {
    _initializeConnectivity();
    _startSyncTimer();
    _loadSelectiveSyncSettings();
  }

  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isOnline => _isOnline;

  // Initialize connectivity monitoring
  void _initializeConnectivity() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline) {
        // Came back online, sync pending data
        _syncPendingData();
      }
      
      _connectionController.add(_isOnline);
    });
  }

  // Start periodic sync timer
  void _startSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isOnline) {
        _syncPendingData();
      }
    });
  }

  // Save data offline
  Future<void> saveOfflineData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(data);
      await prefs.setString('$_offlinePrefix$key', jsonData);
      
      if (kDebugMode) {
        print('Saved offline data for key: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving offline data: $e');
      }
    }
  }

  // Get offline data
  Future<T?> getOfflineData<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('$_offlinePrefix$key');
      
      if (jsonData != null) {
        return jsonDecode(jsonData) as T?;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting offline data: $e');
      }
    }
    return null;
  }

  // Clear offline data
  Future<void> clearOfflineData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_offlinePrefix$key');
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing offline data: $e');
      }
    }
  }

  // Add to sync queue
  Future<void> addToSyncQueue(String action, Map<String, dynamic> data) async {
    try {
      final syncItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'action': action,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'retry_count': 0,
      };
      
      _syncQueue.add(syncItem);
      await _saveSyncQueue();
      
      if (_isOnline) {
        _processSyncQueue();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding to sync queue: $e');
      }
    }
  }

  // Save sync queue to storage
  Future<void> _saveSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_syncQueueKey, jsonEncode(_syncQueue));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving sync queue: $e');
      }
    }
  }

  // Load sync queue from storage
  Future<void> _loadSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_syncQueueKey);
      
      if (jsonData != null) {
        final List<dynamic> queueData = jsonDecode(jsonData);
        _syncQueue.clear();
        _syncQueue.addAll(queueData.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading sync queue: $e');
      }
    }
  }

  // Process sync queue
  Future<void> _processSyncQueue() async {
    if (_syncQueue.isEmpty) return;
    
    final itemsToProcess = List<Map<String, dynamic>>.from(_syncQueue);
    
    for (final item in itemsToProcess) {
      try {
        final success = await _processSyncItem(item);
        
        if (success) {
          _syncQueue.removeWhere((syncItem) => syncItem['id'] == item['id']);
        } else {
          item['retry_count'] = (item['retry_count'] ?? 0) + 1;
          
          // Remove item if max retries exceeded
          if (item['retry_count'] > 3) {
            _syncQueue.removeWhere((syncItem) => syncItem['id'] == item['id']);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing sync item: $e');
        }
      }
    }
    
    await _saveSyncQueue();
  }

  // Process individual sync item
  Future<bool> _processSyncItem(Map<String, dynamic> item) async {
    try {
      final action = item['action'] as String;
      final data = item['data'] as Map<String, dynamic>;
      
      switch (action) {
        case 'create_complaint':
          await _apiService.createComplaint(ComplaintModel.fromJson(data));
          break;
        case 'update_complaint':
          await _apiService.updateComplaint(data['id'], ComplaintModel.fromJson(data));
          break;
        case 'create_feedback':
          await _apiService.createFeedback(FeedbackModel.fromJson(data));
          break;
        case 'create_reservation':
          await _apiService.createReservation(ReservationModel.fromJson(data));
          break;
        case 'update_reservation':
          await _apiService.updateReservation(data['id'], ReservationModel.fromJson(data));
          break;
        case 'join_study_group':
          await _apiService.joinStudyGroup(data['groupId']);
          break;
        case 'leave_study_group':
          await _apiService.leaveStudyGroup(data['groupId']);
          break;
        case 'send_chat_message':
          await _apiService.sendStudyGroupMessage(data['groupId'], data['content']);
          break;
        default:
          if (kDebugMode) {
            print('Unknown sync action: $action');
          }
          return false;
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error processing sync item $item: $e');
      }
      return false;
    }
  }

  // Sync pending data when coming back online
  Future<void> _syncPendingData() async {
    await _loadSyncQueue();
    await _processSyncQueue();
    await _syncOfflineDataWithConflicts();
  }

  // Sync offline data with server
  Future<void> _syncOfflineData() async {
    try {
      // Sync user profile
      await _syncUserProfile();
      
      // Sync notifications
      await _syncNotifications();
      
      // Sync study groups
      await _syncStudyGroups();
      
      // Sync reservations
      await _syncReservations();
      
      // Sync notices
      await _syncNotices();
      
      // Update last sync timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing offline data: $e');
      }
    }
  }

  // Sync user profile
  Future<void> _syncUserProfile() async {
    try {
      final profileData = await getOfflineData<Map<String, dynamic>>('user_profile');
      if (profileData != null) {
        // Update profile on server
        await _apiService.updateProfile(UserModel.fromJson(profileData));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing user profile: $e');
      }
    }
  }

  // Sync notifications
  Future<void> _syncNotifications() async {
    try {
      final notifications = await getOfflineData<List<Map<String, dynamic>>>('notifications');
      if (notifications != null) {
        // Mark notifications as read on server
        for (final notification in notifications) {
          if (notification['is_read'] == true) {
            await _apiService.markNotificationAsRead(notification['id']);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing notifications: $e');
      }
    }
  }

  // Sync study groups
  Future<void> _syncStudyGroups() async {
    try {
      final studyGroups = await getOfflineData<List<Map<String, dynamic>>>('study_groups');
      if (studyGroups != null) {
        // Update study group data on server
        for (final group in studyGroups) {
          if (group['is_modified'] == true) {
            await _apiService.updateStudyGroup(group['id'], StudyGroup.fromJson(group));
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing study groups: $e');
      }
    }
  }

  // Sync reservations
  Future<void> _syncReservations() async {
    try {
      final reservations = await getOfflineData<List<Map<String, dynamic>>>('reservations');
      if (reservations != null) {
        // Update reservation data on server
        for (final reservation in reservations) {
          if (reservation['is_modified'] == true) {
            await _apiService.updateReservation(reservation['id'], ReservationModel.fromJson(reservation));
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing reservations: $e');
      }
    }
  }

  // Sync notices
  Future<void> _syncNotices() async {
    try {
      final notices = await getOfflineData<List<Map<String, dynamic>>>('notices');
      if (notices != null) {
        // Update notice data on server
        for (final notice in notices) {
          if (notice['is_modified'] == true) {
            await _apiService.updateNotice(notice['id'], NoticeModel.fromJson(notice));
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing notices: $e');
      }
    }
  }

  // Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastSyncKey);
      
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting last sync time: $e');
      }
    }
    return null;
  }

  // Clear all offline data
  Future<void> clearAllOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_offlinePrefix) || key == _syncQueueKey || key == _lastSyncKey) {
          await prefs.remove(key);
        }
      }
      
      _syncQueue.clear();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing offline data: $e');
      }
    }
  }

  // Load selective sync settings
  Future<void> _loadSelectiveSyncSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_selectiveSyncKey);
      
      if (settingsJson != null) {
        final settings = Map<String, dynamic>.from(jsonDecode(settingsJson));
        _selectiveSyncSettings.updateAll((key, value) => settings[key] ?? value);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading selective sync settings: $e');
      }
    }
  }

  // Save selective sync settings
  Future<void> saveSelectiveSyncSettings(Map<String, bool> settings) async {
    try {
      _selectiveSyncSettings = settings;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectiveSyncKey, jsonEncode(settings));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving selective sync settings: $e');
      }
    }
  }

  // Get selective sync settings
  Map<String, bool> getSelectiveSyncSettings() => Map.from(_selectiveSyncSettings);

  // Check if module should sync
  bool shouldSyncModule(String module) {
    return _selectiveSyncSettings[module] ?? true;
  }

  // Enhanced sync with conflict resolution
  Future<void> _syncOfflineDataWithConflicts() async {
    try {
      // Sync user profile
      if (shouldSyncModule('user_profile')) {
        await _syncUserProfileWithConflicts();
      }
      
      // Sync notifications
      if (shouldSyncModule('notifications')) {
        await _syncNotificationsWithConflicts();
      }
      
      // Sync study groups
      if (shouldSyncModule('study_groups')) {
        await _syncStudyGroupsWithConflicts();
      }
      
      // Sync reservations
      if (shouldSyncModule('reservations')) {
        await _syncReservationsWithConflicts();
      }
      
      // Sync notices
      if (shouldSyncModule('notices')) {
        await _syncNoticesWithConflicts();
      }
      
      // Update last sync timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing offline data with conflicts: $e');
      }
    }
  }

  // Sync user profile with conflict resolution
  Future<void> _syncUserProfileWithConflicts() async {
    try {
      final profileData = await getOfflineData<Map<String, dynamic>>('user_profile');
      if (profileData != null) {
        // Get server data
        final serverProfile = await _apiService.getCurrentUser();
        final serverData = [serverProfile.toJson()];
        final clientData = [profileData];
        
        // Detect conflicts
        final conflicts = await _conflictService.detectConflicts(
          'user_profile',
          serverData,
          clientData,
        );
        
        if (conflicts.isNotEmpty) {
          // Save conflicts for user resolution
          for (final conflict in conflicts) {
            await _conflictService.saveConflict(conflict);
          }
        } else {
          // No conflicts, proceed with sync
          await _apiService.updateProfile(UserModel.fromJson(profileData));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing user profile with conflicts: $e');
      }
    }
  }

  // Sync notifications with conflict resolution
  Future<void> _syncNotificationsWithConflicts() async {
    try {
      final notifications = await getOfflineData<List<Map<String, dynamic>>>('notifications');
      if (notifications != null) {
        // Get server notifications
        final serverNotifications = await _apiService.getNotifications();
        final serverData = serverNotifications.map((n) => n.toJson()).toList();
        
        // Detect conflicts
        final conflicts = await _conflictService.detectConflicts(
          'notifications',
          serverData,
          notifications,
        );
        
        if (conflicts.isNotEmpty) {
          // Auto-resolve notification conflicts (server wins)
          await _conflictService.autoResolveConflicts(conflicts);
        }
        
        // Mark notifications as read on server
        for (final notification in notifications) {
          if (notification['is_read'] == true) {
            await _apiService.markNotificationAsRead(notification['id']);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing notifications with conflicts: $e');
      }
    }
  }

  // Sync study groups with conflict resolution
  Future<void> _syncStudyGroupsWithConflicts() async {
    try {
      final studyGroups = await getOfflineData<List<Map<String, dynamic>>>('study_groups');
      if (studyGroups != null) {
        // Get server study groups
        final serverStudyGroups = await _apiService.getStudyGroups();
        final serverData = serverStudyGroups.map((g) => g.toJson()).toList();
        
        // Detect conflicts
        final conflicts = await _conflictService.detectConflicts(
          'study_groups',
          serverData,
          studyGroups,
        );
        
        if (conflicts.isNotEmpty) {
          // Save conflicts for user resolution
          for (final conflict in conflicts) {
            await _conflictService.saveConflict(conflict);
          }
        } else {
          // No conflicts, proceed with sync
          for (final group in studyGroups) {
            if (group['is_modified'] == true) {
              await _apiService.updateStudyGroup(group['id'], StudyGroup.fromJson(group));
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing study groups with conflicts: $e');
      }
    }
  }

  // Sync reservations with conflict resolution
  Future<void> _syncReservationsWithConflicts() async {
    try {
      final reservations = await getOfflineData<List<Map<String, dynamic>>>('reservations');
      if (reservations != null) {
        // Get server reservations
        final serverReservations = await _apiService.getReservations();
        final serverData = serverReservations.map((r) => r.toJson()).toList();
        
        // Detect conflicts
        final conflicts = await _conflictService.detectConflicts(
          'reservations',
          serverData,
          reservations,
        );
        
        if (conflicts.isNotEmpty) {
          // Auto-resolve reservation conflicts (client wins if more recent)
          await _conflictService.autoResolveConflicts(conflicts);
        } else {
          // No conflicts, proceed with sync
          for (final reservation in reservations) {
            if (reservation['is_modified'] == true) {
              await _apiService.updateReservation(reservation['id'], ReservationModel.fromJson(reservation));
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing reservations with conflicts: $e');
      }
    }
  }

  // Sync notices with conflict resolution
  Future<void> _syncNoticesWithConflicts() async {
    try {
      final notices = await getOfflineData<List<Map<String, dynamic>>>('notices');
      if (notices != null) {
        // Get server notices
        final serverNotices = await _apiService.getNotices();
        final serverData = serverNotices.map((n) => n.toJson()).toList();
        
        // Detect conflicts
        final conflicts = await _conflictService.detectConflicts(
          'notices',
          serverData,
          notices,
        );
        
        if (conflicts.isNotEmpty) {
          // Auto-resolve notice conflicts (server wins)
          await _conflictService.autoResolveConflicts(conflicts);
        } else {
          // No conflicts, proceed with sync
          for (final notice in notices) {
            if (notice['is_modified'] == true) {
              await _apiService.updateNotice(notice['id'], NoticeModel.fromJson(notice));
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing notices with conflicts: $e');
      }
    }
  }

  // Get pending conflicts
  Future<List<ConflictData>> getPendingConflicts() async {
    return await _conflictService.getPendingConflicts();
  }

  // Resolve conflict
  Future<Map<String, dynamic>> resolveConflict(
    String conflictId,
    ConflictResolutionStrategy strategy, {
    Map<String, dynamic>? mergedData,
  }) async {
    return await _conflictService.resolveConflict(conflictId, strategy, mergedData: mergedData);
  }

  // Get conflict statistics
  Future<Map<String, dynamic>> getConflictStats() async {
    return await _conflictService.getConflictStats();
  }

  // Dispose
  void dispose() {
    _syncTimer?.cancel();
    _connectionController.close();
  }
}

// Provider for Offline Service
final offlineServiceProvider = Provider<OfflineService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final connectivity = Connectivity();
  final service = OfflineService(apiService, connectivity);
  ref.onDispose(() => service.dispose());
  return service;
});

// Provider for connection status
final connectionStatusProvider = StreamProvider<bool>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.connectionStream;
});

// Provider for last sync time
final lastSyncTimeProvider = FutureProvider<DateTime?>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.getLastSyncTime();
});
