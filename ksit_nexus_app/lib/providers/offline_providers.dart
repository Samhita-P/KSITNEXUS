import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ksit_nexus_app/services/offline_service.dart';
import 'package:ksit_nexus_app/services/api_service.dart';
import 'package:ksit_nexus_app/models/notification_model.dart';
import 'package:ksit_nexus_app/models/study_group_model.dart';
import 'package:ksit_nexus_app/models/reservation_model.dart';
import 'package:ksit_nexus_app/models/notice_model.dart';
import 'package:ksit_nexus_app/models/complaint_model.dart';
import 'package:ksit_nexus_app/models/feedback_model.dart';

// Offline notifications provider
final offlineNotificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final isOnline = ref.watch(connectionStatusProvider).value ?? true;
  
  if (isOnline) {
    // Try to get fresh data from API
    try {
      final apiService = ref.watch(apiServiceProvider);
      final notifications = await apiService.getNotifications();
      
      // Save to offline storage
      await offlineService.saveOfflineData('notifications', 
          notifications.map((n) => n.toJson()).toList());
      
      return notifications;
    } catch (e) {
      // Fall back to offline data
      final offlineData = await offlineService.getOfflineData<List<Map<String, dynamic>>>('notifications');
      if (offlineData != null) {
        return offlineData.map((data) => NotificationModel.fromJson(data)).toList();
      }
      return [];
    }
  } else {
    // Use offline data
    final offlineData = await offlineService.getOfflineData<List<Map<String, dynamic>>>('notifications');
    if (offlineData != null) {
      return offlineData.map((data) => NotificationModel.fromJson(data)).toList();
    }
    return [];
  }
});

// Offline study groups provider
final offlineStudyGroupsProvider = FutureProvider<List<StudyGroup>>((ref) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final isOnline = ref.watch(connectionStatusProvider).value ?? true;
  
  if (isOnline) {
    try {
      final apiService = ref.watch(apiServiceProvider);
      final studyGroups = await apiService.getStudyGroups();
      
      // Save to offline storage
      await offlineService.saveOfflineData('study_groups', 
          studyGroups.map((g) => g.toJson()).toList());
      
      return studyGroups;
    } catch (e) {
      // Fall back to offline data
      final offlineData = await offlineService.getOfflineData<List<Map<String, dynamic>>>('study_groups');
      if (offlineData != null) {
        return offlineData.map((data) => StudyGroup.fromJson(data)).toList();
      }
      return [];
    }
  } else {
    // Use offline data
    final offlineData = await offlineService.getOfflineData<List<Map<String, dynamic>>>('study_groups');
    if (offlineData != null) {
      return offlineData.map((data) => StudyGroup.fromJson(data)).toList();
    }
    return [];
  }
});

// Offline reservations provider
final offlineReservationsProvider = FutureProvider.family<List<ReservationModel>, String>((ref, resourceType) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final isOnline = ref.watch(connectionStatusProvider).value ?? true;
  
  if (isOnline) {
    try {
      final apiService = ref.watch(apiServiceProvider);
      final reservations = await apiService.getReservations(resourceType);
      
      // Save to offline storage
      await offlineService.saveOfflineData('reservations_$resourceType', 
          reservations.map((r) => r.toJson()).toList());
      
      return reservations;
    } catch (e) {
      // Fall back to offline data
      final offlineData = await offlineService.getOfflineData<List<Map<String, dynamic>>>('reservations_$resourceType');
      if (offlineData != null) {
        return offlineData.map((data) => ReservationModel.fromJson(data)).toList();
      }
      return [];
    }
  } else {
    // Use offline data
    final offlineData = await offlineService.getOfflineData<List<Map<String, dynamic>>>('reservations_$resourceType');
    if (offlineData != null) {
      return offlineData.map((data) => ReservationModel.fromJson(data)).toList();
    }
    return [];
  }
});

// Offline notices provider
final offlineNoticesProvider = FutureProvider<List<NoticeModel>>((ref) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final isOnline = ref.watch(connectionStatusProvider).value ?? true;
  
  if (isOnline) {
    try {
      final apiService = ref.watch(apiServiceProvider);
      final notices = await apiService.getNotices();
      
      // Save to offline storage
      await offlineService.saveOfflineData('notices', 
          notices.map((n) => n.toJson()).toList());
      
      return notices;
    } catch (e) {
      // Fall back to offline data
      final offlineData = await offlineService.getOfflineData<List<Map<String, dynamic>>>('notices');
      if (offlineData != null) {
        return offlineData.map((data) => NoticeModel.fromJson(data)).toList();
      }
      return [];
    }
  } else {
    // Use offline data
    final offlineData = await offlineService.getOfflineData<List<Map<String, dynamic>>>('notices');
    if (offlineData != null) {
      return offlineData.map((data) => NoticeModel.fromJson(data)).toList();
    }
    return [];
  }
});

// Offline complaints provider
final offlineComplaintsProvider = FutureProvider<List<ComplaintModel>>((ref) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final isOnline = ref.watch(connectionStatusProvider).value ?? true;
  
  if (isOnline) {
    try {
      final apiService = ref.watch(apiServiceProvider);
      final complaints = await apiService.getComplaints();
      
      // Save to offline storage
      await offlineService.saveOfflineData('complaints', 
          complaints.map((c) => c.toJson()).toList());
      
      return complaints;
    } catch (e) {
      // Fall back to offline data
      final offlineData = await offlineService.getOfflineData<List<Map<String, dynamic>>>('complaints');
      if (offlineData != null) {
        return offlineData.map((data) => ComplaintModel.fromJson(data)).toList();
      }
      return [];
    }
  } else {
    // Use offline data
    final offlineData = await offlineService.getOfflineData<List<Map<String, dynamic>>>('complaints');
    if (offlineData != null) {
      return offlineData.map((data) => ComplaintModel.fromJson(data)).toList();
    }
    return [];
  }
});

// Offline feedback provider
final offlineFeedbackProvider = FutureProvider<List<FeedbackModel>>((ref) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final isOnline = ref.watch(connectionStatusProvider).value ?? true;
  
  if (isOnline) {
    try {
      final apiService = ref.watch(apiServiceProvider);
      final feedback = await apiService.getFeedback();
      
      // Save to offline storage
      await offlineService.saveOfflineData('feedback', 
          feedback.map((f) => f.toJson()).toList());
      
      return feedback;
    } catch (e) {
      // Fall back to offline data
      final offlineData = await offlineService.getOfflineData<List<Map<String, dynamic>>>('feedback');
      if (offlineData != null) {
        return offlineData.map((data) => FeedbackModel.fromJson(data)).toList();
      }
      return [];
    }
  } else {
    // Use offline data
    final offlineData = await offlineService.getOfflineData<List<Map<String, dynamic>>>('feedback');
    if (offlineData != null) {
      return offlineData.map((data) => FeedbackModel.fromJson(data)).toList();
    }
    return [];
  }
});

// Offline action providers for creating/updating data
final offlineCreateComplaintProvider = FutureProvider.family<void, ComplaintModel>((ref, complaint) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final isOnline = ref.watch(connectionStatusProvider).value ?? true;
  
  if (isOnline) {
    try {
      final apiService = ref.watch(apiServiceProvider);
      await apiService.createComplaint(complaint);
    } catch (e) {
      // Add to sync queue for later
      await offlineService.addToSyncQueue('create_complaint', complaint.toJson());
    }
  } else {
    // Add to sync queue
    await offlineService.addToSyncQueue('create_complaint', complaint.toJson());
  }
});

final offlineCreateFeedbackProvider = FutureProvider.family<void, FeedbackModel>((ref, feedback) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final isOnline = ref.watch(connectionStatusProvider).value ?? true;
  
  if (isOnline) {
    try {
      final apiService = ref.watch(apiServiceProvider);
      await apiService.createFeedback(feedback);
    } catch (e) {
      // Add to sync queue for later
      await offlineService.addToSyncQueue('create_feedback', feedback.toJson());
    }
  } else {
    // Add to sync queue
    await offlineService.addToSyncQueue('create_feedback', feedback.toJson());
  }
});

final offlineCreateReservationProvider = FutureProvider.family<void, ReservationModel>((ref, reservation) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final isOnline = ref.watch(connectionStatusProvider).value ?? true;
  
  if (isOnline) {
    try {
      final apiService = ref.watch(apiServiceProvider);
      await apiService.createReservation(reservation);
    } catch (e) {
      // Add to sync queue for later
      await offlineService.addToSyncQueue('create_reservation', reservation.toJson());
    }
  } else {
    // Add to sync queue
    await offlineService.addToSyncQueue('create_reservation', reservation.toJson());
  }
});

final offlineJoinStudyGroupProvider = FutureProvider.family<void, String>((ref, groupId) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final isOnline = ref.watch(connectionStatusProvider).value ?? true;
  
  if (isOnline) {
    try {
      final apiService = ref.watch(apiServiceProvider);
      await apiService.joinStudyGroup(groupId);
    } catch (e) {
      // Add to sync queue for later
      await offlineService.addToSyncQueue('join_study_group', {'groupId': groupId});
    }
  } else {
    // Add to sync queue
    await offlineService.addToSyncQueue('join_study_group', {'groupId': groupId});
  }
});

final offlineLeaveStudyGroupProvider = FutureProvider.family<void, String>((ref, groupId) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final isOnline = ref.watch(connectionStatusProvider).value ?? true;
  
  if (isOnline) {
    try {
      final apiService = ref.watch(apiServiceProvider);
      await apiService.leaveStudyGroup(groupId);
    } catch (e) {
      // Add to sync queue for later
      await offlineService.addToSyncQueue('leave_study_group', {'groupId': groupId});
    }
  } else {
    // Add to sync queue
    await offlineService.addToSyncQueue('leave_study_group', {'groupId': groupId});
  }
});

final offlineSendChatMessageProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, messageData) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final isOnline = ref.watch(connectionStatusProvider).value ?? true;
  
  if (isOnline) {
    try {
      final apiService = ref.watch(apiServiceProvider);
      await apiService.sendStudyGroupMessage(messageData['groupId'], messageData['content']);
    } catch (e) {
      // Add to sync queue for later
      await offlineService.addToSyncQueue('send_chat_message', messageData);
    }
  } else {
    // Add to sync queue
    await offlineService.addToSyncQueue('send_chat_message', messageData);
  }
});

// Sync status provider
final syncStatusProvider = StateProvider<String>((ref) => 'idle');

// Sync progress provider
final syncProgressProvider = StateProvider<double>((ref) => 0.0);

// Manual sync provider
final manualSyncProvider = FutureProvider<void>((ref) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final syncStatus = ref.read(syncStatusProvider.notifier);
  final syncProgress = ref.read(syncProgressProvider.notifier);
  
  try {
    syncStatus.state = 'syncing';
    syncProgress.state = 0.0;
    
    await offlineService._syncPendingData();
    
    syncProgress.state = 1.0;
    syncStatus.state = 'completed';
    
    // Reset after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      syncStatus.state = 'idle';
      syncProgress.state = 0.0;
    });
  } catch (e) {
    syncStatus.state = 'error';
    syncProgress.state = 0.0;
    
    // Reset after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      syncStatus.state = 'idle';
      syncProgress.state = 0.0;
    });
  }
});
