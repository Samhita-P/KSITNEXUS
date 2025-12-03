import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ConflictResolutionStrategy {
  serverWins,
  clientWins,
  merge,
  userChoice,
}

class ConflictData {
  final String id;
  final String type;
  final Map<String, dynamic> serverData;
  final Map<String, dynamic> clientData;
  final DateTime serverTimestamp;
  final DateTime clientTimestamp;
  final String? conflictReason;

  ConflictData({
    required this.id,
    required this.type,
    required this.serverData,
    required this.clientData,
    required this.serverTimestamp,
    required this.clientTimestamp,
    this.conflictReason,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'serverData': serverData,
    'clientData': clientData,
    'serverTimestamp': serverTimestamp.toIso8601String(),
    'clientTimestamp': clientTimestamp.toIso8601String(),
    'conflictReason': conflictReason,
  };

  factory ConflictData.fromJson(Map<String, dynamic> json) => ConflictData(
    id: json['id'],
    type: json['type'],
    serverData: json['serverData'],
    clientData: json['clientData'],
    serverTimestamp: DateTime.parse(json['serverTimestamp']),
    clientTimestamp: DateTime.parse(json['clientTimestamp']),
    conflictReason: json['conflictReason'],
  );
}

class ConflictResolutionService {
  static const String _conflictsKey = 'conflict_resolutions';
  static const String _resolutionHistoryKey = 'resolution_history';
  
  final SharedPreferences _prefs;

  ConflictResolutionService(this._prefs);

  /// Detect conflicts between server and client data
  Future<List<ConflictData>> detectConflicts(
    String dataType,
    List<Map<String, dynamic>> serverData,
    List<Map<String, dynamic>> clientData,
  ) async {
    final conflicts = <ConflictData>[];
    
    // Create maps for easier lookup
    final serverMap = {for (var item in serverData) item['id'].toString(): item};
    final clientMap = {for (var item in clientData) item['id'].toString(): item};
    
    // Find conflicts
    for (final serverItem in serverData) {
      final id = serverItem['id'].toString();
      final clientItem = clientMap[id];
      
      if (clientItem != null) {
        final conflict = _compareData(serverItem, clientItem, dataType);
        if (conflict != null) {
          conflicts.add(ConflictData(
            id: id,
            type: dataType,
            serverData: serverItem,
            clientData: clientItem,
            serverTimestamp: DateTime.parse(serverItem['updated_at'] ?? serverItem['created_at']),
            clientTimestamp: DateTime.parse(clientItem['updated_at'] ?? clientItem['created_at']),
            conflictReason: conflict,
          ));
        }
      }
    }
    
    return conflicts;
  }

  /// Compare two data items and return conflict reason if any
  String? _compareData(
    Map<String, dynamic> serverData,
    Map<String, dynamic> clientData,
    String dataType,
  ) {
    // Check for different updated timestamps
    final serverUpdated = serverData['updated_at'] ?? serverData['created_at'];
    final clientUpdated = clientData['updated_at'] ?? clientData['created_at'];
    
    if (serverUpdated != clientUpdated) {
      return 'Data was modified on both server and client';
    }
    
    // Check for different content
    final serverContent = _extractContent(serverData, dataType);
    final clientContent = _extractContent(clientData, dataType);
    
    if (serverContent != clientContent) {
      return 'Content differs between server and client';
    }
    
    return null;
  }

  /// Extract relevant content for comparison based on data type
  Map<String, dynamic> _extractContent(Map<String, dynamic> data, String dataType) {
    switch (dataType) {
      case 'complaints':
        return {
          'title': data['title'],
          'description': data['description'],
          'category': data['category'],
          'priority': data['priority'],
          'status': data['status'],
        };
      case 'reservations':
        return {
          'room_id': data['room_id'],
          'seat_id': data['seat_id'],
          'start_time': data['start_time'],
          'end_time': data['end_time'],
          'status': data['status'],
        };
      case 'study_groups':
        return {
          'name': data['name'],
          'description': data['description'],
          'subject': data['subject'],
          'is_private': data['is_private'],
        };
      case 'notices':
        return {
          'title': data['title'],
          'content': data['content'],
          'category': data['category'],
          'priority': data['priority'],
        };
      case 'feedback':
        return {
          'faculty_id': data['faculty_id'],
          'rating': data['rating'],
          'comment': data['comment'],
          'categories': data['categories'],
        };
      default:
        return data;
    }
  }

  /// Save conflict for user resolution
  Future<void> saveConflict(ConflictData conflict) async {
    try {
      final conflicts = await getPendingConflicts();
      conflicts.add(conflict);
      await _prefs.setString(_conflictsKey, jsonEncode(conflicts.map((c) => c.toJson()).toList()));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving conflict: $e');
      }
    }
  }

  /// Get pending conflicts
  Future<List<ConflictData>> getPendingConflicts() async {
    try {
      final jsonData = _prefs.getString(_conflictsKey);
      if (jsonData != null) {
        final List<dynamic> conflictsJson = jsonDecode(jsonData);
        return conflictsJson.map((json) => ConflictData.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pending conflicts: $e');
      }
    }
    return [];
  }

  /// Resolve conflict with user choice
  Future<Map<String, dynamic>> resolveConflict(
    String conflictId,
    ConflictResolutionStrategy strategy, {
    Map<String, dynamic>? mergedData,
  }) async {
    try {
      final conflicts = await getPendingConflicts();
      final conflictIndex = conflicts.indexWhere((c) => c.id == conflictId);
      
      if (conflictIndex == -1) {
        throw Exception('Conflict not found');
      }
      
      final conflict = conflicts[conflictIndex];
      Map<String, dynamic> resolvedData;
      
      switch (strategy) {
        case ConflictResolutionStrategy.serverWins:
          resolvedData = conflict.serverData;
          break;
        case ConflictResolutionStrategy.clientWins:
          resolvedData = conflict.clientData;
          break;
        case ConflictResolutionStrategy.merge:
          if (mergedData == null) {
            throw Exception('Merged data required for merge strategy');
          }
          resolvedData = mergedData;
          break;
        case ConflictResolutionStrategy.userChoice:
          // This should be handled by the UI
          throw Exception('User choice strategy should be handled by UI');
      }
      
      // Remove conflict from pending list
      conflicts.removeAt(conflictIndex);
      await _prefs.setString(_conflictsKey, jsonEncode(conflicts.map((c) => c.toJson()).toList()));
      
      // Save resolution to history
      await _saveResolutionHistory(conflict, strategy, resolvedData);
      
      return resolvedData;
    } catch (e) {
      if (kDebugMode) {
        print('Error resolving conflict: $e');
      }
      rethrow;
    }
  }

  /// Save resolution to history
  Future<void> _saveResolutionHistory(
    ConflictData conflict,
    ConflictResolutionStrategy strategy,
    Map<String, dynamic> resolvedData,
  ) async {
    try {
      final history = await getResolutionHistory();
      history.add({
        'conflictId': conflict.id,
        'type': conflict.type,
        'strategy': strategy.toString(),
        'resolvedData': resolvedData,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      await _prefs.setString(_resolutionHistoryKey, jsonEncode(history));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving resolution history: $e');
      }
    }
  }

  /// Get resolution history
  Future<List<Map<String, dynamic>>> getResolutionHistory() async {
    try {
      final jsonData = _prefs.getString(_resolutionHistoryKey);
      if (jsonData != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(jsonData));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting resolution history: $e');
      }
    }
    return [];
  }

  /// Auto-resolve conflicts based on rules
  Future<List<Map<String, dynamic>>> autoResolveConflicts(
    List<ConflictData> conflicts,
  ) async {
    final resolvedData = <Map<String, dynamic>>[];
    
    for (final conflict in conflicts) {
      ConflictResolutionStrategy strategy;
      
      // Auto-resolution rules
      switch (conflict.type) {
        case 'notifications':
          // For notifications, server always wins
          strategy = ConflictResolutionStrategy.serverWins;
          break;
        case 'reservations':
          // For reservations, check if client has more recent changes
          if (conflict.clientTimestamp.isAfter(conflict.serverTimestamp)) {
            strategy = ConflictResolutionStrategy.clientWins;
          } else {
            strategy = ConflictResolutionStrategy.serverWins;
          }
          break;
        case 'study_groups':
          // For study groups, try to merge if possible
          strategy = ConflictResolutionStrategy.merge;
          break;
        default:
          // Default to server wins
          strategy = ConflictResolutionStrategy.serverWins;
      }
      
      try {
        final resolved = await resolveConflict(conflict.id, strategy);
        resolvedData.add(resolved);
      } catch (e) {
        if (kDebugMode) {
          print('Error auto-resolving conflict ${conflict.id}: $e');
        }
      }
    }
    
    return resolvedData;
  }

  /// Clear all conflicts
  Future<void> clearAllConflicts() async {
    await _prefs.remove(_conflictsKey);
  }

  /// Clear resolution history
  Future<void> clearResolutionHistory() async {
    await _prefs.remove(_resolutionHistoryKey);
  }

  /// Get conflict statistics
  Future<Map<String, dynamic>> getConflictStats() async {
    final conflicts = await getPendingConflicts();
    final history = await getResolutionHistory();
    
    final stats = <String, int>{};
    for (final conflict in conflicts) {
      stats[conflict.type] = (stats[conflict.type] ?? 0) + 1;
    }
    
    return {
      'pendingConflicts': conflicts.length,
      'conflictsByType': stats,
      'totalResolved': history.length,
    };
  }
}
