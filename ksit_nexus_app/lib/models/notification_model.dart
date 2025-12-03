import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class Notification {
  final int id;
  final String title;
  final String message;
  final String type;
  final String category;
  final String notificationType; // Add this property
  final String priority; // Add priority field
  final Map<String, dynamic>? data;
  final int? userId;
  final String? userName;
  final bool isRead;
  final bool isSent;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? sentAt;
  final String? imageUrl;
  final String? actionUrl;
  final String? actionText;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.notificationType,
    required this.priority,
    this.data,
    this.userId,
    this.userName,
    required this.isRead,
    required this.isSent,
    required this.createdAt,
    this.readAt,
    this.sentAt,
    this.imageUrl,
    this.actionUrl,
    this.actionText,
  });

  // Add missing properties
  bool get isArchived => false;
  int? get relatedId => null;
  String? get relatedType => null;
  DateTime? get scheduledAt => null;
  DateTime get updatedAt => createdAt;

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      category: json['category'] as String? ?? 'general',
      notificationType: json['notification_type'] as String? ?? json['type'] as String,
      priority: json['priority'] as String? ?? 'normal',
      data: json['data'] as Map<String, dynamic>?,
      userId: json['user_id'] as int?,
      userName: json['user_name'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      isSent: json['is_sent'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : null,
      imageUrl: json['image_url'] as String?,
      actionUrl: json['action_url'] as String?,
      actionText: json['action_text'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'is_read': isRead,
      'is_archived': isArchived,
      'user_id': userId,
      'related_id': relatedId,
      'related_type': relatedType,
      'action_url': actionUrl,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get typeDisplayName {
    switch (type) {
      case 'info': return 'Information';
      case 'success': return 'Success';
      case 'warning': return 'Warning';
      case 'error': return 'Error';
      case 'reminder': return 'Reminder';
      case 'announcement': return 'Announcement';
      case 'update': return 'Update';
      default: return type;
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case 'general': return 'General';
      case 'academic': return 'Academic';
      case 'exam': return 'Exam';
      case 'event': return 'Event';
      case 'complaint': return 'Complaint';
      case 'feedback': return 'Feedback';
      case 'study_group': return 'Study Group';
      case 'reservation': return 'Reservation';
      case 'notice': return 'Notice';
      case 'system': return 'System';
      default: return category;
    }
  }

  bool get isUnread => !isRead;
  bool get hasAction => actionUrl != null && actionUrl!.isNotEmpty;
  bool get isRecent => DateTime.now().difference(createdAt).inDays <= 7;
  bool get isToday => DateTime.now().difference(createdAt).inDays == 0;
}

@JsonSerializable()
class NotificationPreference {
  final int id;
  final int userId;
  final String category;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool inAppEnabled;
  final bool quietHoursEnabled;
  final String? quietStartTime;
  final String? quietEndTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreference({
    required this.id,
    required this.userId,
    required this.category,
    required this.pushEnabled,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.inAppEnabled,
    required this.quietHoursEnabled,
    this.quietStartTime,
    this.quietEndTime,
    required this.createdAt,
    required this.updatedAt,
  });

  // Add missing properties
  String get type => category;
  bool get isEnabled => pushEnabled || emailEnabled || smsEnabled || inAppEnabled;
  String? get quietHoursStart => quietStartTime;
  String? get quietHoursEnd => quietEndTime;

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      category: json['category'] as String? ?? json['type'] as String? ?? 'general',
      pushEnabled: json['push_enabled'] as bool? ?? false,
      emailEnabled: json['email_enabled'] as bool? ?? false,
      smsEnabled: json['sms_enabled'] as bool? ?? false,
      inAppEnabled: json['in_app_enabled'] as bool? ?? true,
      quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? false,
      quietStartTime: json['quiet_hours_start'] as String?,
      quietEndTime: json['quiet_hours_end'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'is_enabled': isEnabled,
      'email_enabled': emailEnabled,
      'push_enabled': pushEnabled,
      'sms_enabled': smsEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get categoryDisplayName {
    switch (category) {
      case 'general': return 'General';
      case 'academic': return 'Academic';
      case 'exam': return 'Exam';
      case 'event': return 'Event';
      case 'complaint': return 'Complaint';
      case 'feedback': return 'Feedback';
      case 'study_group': return 'Study Group';
      case 'reservation': return 'Reservation';
      case 'notice': return 'Notice';
      case 'system': return 'System';
      default: return category;
    }
  }

  bool get isQuietHours {
    if (!quietHoursEnabled || quietStartTime == null || quietEndTime == null) {
      return false;
    }
    
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    return currentTime.compareTo(quietStartTime!) >= 0 && currentTime.compareTo(quietEndTime!) <= 0;
  }
}

@JsonSerializable()
class NotificationCreateRequest {
  final String title;
  final String message;
  final String type;
  final String category;
  final String? data;
  final int? userId;
  final String? imageUrl;
  final String? actionUrl;
  final String? actionText;

  NotificationCreateRequest({
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    this.data,
    this.userId,
    this.imageUrl,
    this.actionUrl,
    this.actionText,
  });

  // Add missing properties
  String get priority => 'normal';
  int? get relatedId => null;
  String? get relatedType => null;
  DateTime? get scheduledAt => null;

  factory NotificationCreateRequest.fromJson(Map<String, dynamic> json) {
    return NotificationCreateRequest(
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      category: json['category'] as String? ?? 'general',
      data: json['data'] as String?,
      userId: json['user_id'] as int?,
      imageUrl: json['image_url'] as String?,
      actionUrl: json['action_url'] as String?,
      actionText: json['action_text'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'user_id': userId,
      'related_id': relatedId,
      'related_type': relatedType,
      'action_url': actionUrl,
      'scheduled_at': scheduledAt?.toIso8601String(),
    };
  }
}

@JsonSerializable()
class NotificationUpdateRequest {
  final bool? isRead;
  final bool? isSent;

  NotificationUpdateRequest({
    this.isRead,
    this.isSent,
  });

  // Add missing property
  bool? get isArchived => null;

  factory NotificationUpdateRequest.fromJson(Map<String, dynamic> json) {
    return NotificationUpdateRequest(
      isRead: json['is_read'] as bool?,
      isSent: json['is_sent'] as bool?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'is_read': isRead,
      'is_archived': isArchived,
    };
  }
}

@JsonSerializable()
class NotificationPreferenceUpdateRequest {
  final bool? pushEnabled;
  final bool? emailEnabled;
  final bool? smsEnabled;
  final bool? inAppEnabled;
  final bool? quietHoursEnabled;
  final String? quietStartTime;
  final String? quietEndTime;

  NotificationPreferenceUpdateRequest({
    this.pushEnabled,
    this.emailEnabled,
    this.smsEnabled,
    this.inAppEnabled,
    this.quietHoursEnabled,
    this.quietStartTime,
    this.quietEndTime,
  });

  // Add missing properties
  bool? get isEnabled => null;
  String? get quietHoursStart => quietStartTime;
  String? get quietHoursEnd => quietEndTime;

  factory NotificationPreferenceUpdateRequest.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceUpdateRequest(
      pushEnabled: json['push_enabled'] as bool?,
      emailEnabled: json['email_enabled'] as bool?,
      smsEnabled: json['sms_enabled'] as bool?,
      inAppEnabled: json['in_app_enabled'] as bool?,
      quietHoursEnabled: json['quiet_hours_enabled'] as bool?,
      quietStartTime: json['quiet_hours_start'] as String?,
      quietEndTime: json['quiet_hours_end'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'is_enabled': isEnabled,
      'email_enabled': emailEnabled,
      'push_enabled': pushEnabled,
      'sms_enabled': smsEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
    };
  }
}

@JsonSerializable()
class NotificationStats {
  final int totalNotifications;
  final int unreadNotifications;
  final int readNotifications;
  final Map<String, int> notificationsByType;
  final Map<String, int> notificationsByCategory;
  final List<Notification> recentNotifications;
  final double averageReadTime;

  NotificationStats({
    required this.totalNotifications,
    required this.unreadNotifications,
    required this.readNotifications,
    required this.notificationsByType,
    required this.notificationsByCategory,
    required this.recentNotifications,
    required this.averageReadTime,
  });

  // Add missing properties
  int get archivedNotifications => 0;
  Map<String, int> get notificationsByPriority => {};

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      totalNotifications: json['total_notifications'] as int,
      unreadNotifications: json['unread_notifications'] as int,
      readNotifications: json['read_notifications'] as int,
      notificationsByType: Map<String, int>.from(json['notifications_by_type'] as Map? ?? {}),
      notificationsByCategory: Map<String, int>.from(json['notifications_by_category'] as Map? ?? {}),
      recentNotifications: (json['recent_notifications'] as List?)?.map((e) => Notification.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      averageReadTime: (json['average_read_time'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'total_notifications': totalNotifications,
      'unread_notifications': unreadNotifications,
      'read_notifications': readNotifications,
      'archived_notifications': archivedNotifications,
      'notifications_by_type': notificationsByType,
      'notifications_by_priority': notificationsByPriority,
      'average_read_time': averageReadTime,
    };
  }
}

@JsonSerializable()
class NotificationFilter {
  final String? type;
  final String? category;
  final bool? isRead;
  final bool? isSent;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  NotificationFilter({
    this.type,
    this.category,
    this.isRead,
    this.isSent,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });

  // Add missing properties
  String? get priority => null;
  bool? get isArchived => null;

  factory NotificationFilter.fromJson(Map<String, dynamic> json) {
    return NotificationFilter(
      type: json['type'] as String?,
      category: json['category'] as String?,
      isRead: json['is_read'] as bool?,
      isSent: json['is_sent'] as bool?,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      searchQuery: json['search_query'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'priority': priority,
      'is_read': isRead,
      'is_archived': isArchived,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  bool get hasFilters => 
    type != null ||
    category != null ||
    isRead != null ||
    isSent != null ||
    startDate != null ||
    endDate != null ||
    (searchQuery != null && searchQuery!.isNotEmpty);
}
