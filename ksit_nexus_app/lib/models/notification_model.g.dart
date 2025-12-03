// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notification _$NotificationFromJson(Map<String, dynamic> json) => Notification(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  message: json['message'] as String,
  type: json['type'] as String,
  category: json['category'] as String,
  notificationType: json['notificationType'] as String,
  priority: json['priority'] as String,
  data: json['data'] as Map<String, dynamic>?,
  userId: (json['userId'] as num?)?.toInt(),
  userName: json['userName'] as String?,
  isRead: json['isRead'] as bool,
  isSent: json['isSent'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  readAt:
      json['readAt'] == null ? null : DateTime.parse(json['readAt'] as String),
  sentAt:
      json['sentAt'] == null ? null : DateTime.parse(json['sentAt'] as String),
  imageUrl: json['imageUrl'] as String?,
  actionUrl: json['actionUrl'] as String?,
  actionText: json['actionText'] as String?,
);

Map<String, dynamic> _$NotificationToJson(Notification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'message': instance.message,
      'type': instance.type,
      'category': instance.category,
      'notificationType': instance.notificationType,
      'priority': instance.priority,
      'data': instance.data,
      'userId': instance.userId,
      'userName': instance.userName,
      'isRead': instance.isRead,
      'isSent': instance.isSent,
      'createdAt': instance.createdAt.toIso8601String(),
      'readAt': instance.readAt?.toIso8601String(),
      'sentAt': instance.sentAt?.toIso8601String(),
      'imageUrl': instance.imageUrl,
      'actionUrl': instance.actionUrl,
      'actionText': instance.actionText,
    };

NotificationPreference _$NotificationPreferenceFromJson(
  Map<String, dynamic> json,
) => NotificationPreference(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  category: json['category'] as String,
  pushEnabled: json['pushEnabled'] as bool,
  emailEnabled: json['emailEnabled'] as bool,
  smsEnabled: json['smsEnabled'] as bool,
  inAppEnabled: json['inAppEnabled'] as bool,
  quietHoursEnabled: json['quietHoursEnabled'] as bool,
  quietStartTime: json['quietStartTime'] as String?,
  quietEndTime: json['quietEndTime'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$NotificationPreferenceToJson(
  NotificationPreference instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'category': instance.category,
  'pushEnabled': instance.pushEnabled,
  'emailEnabled': instance.emailEnabled,
  'smsEnabled': instance.smsEnabled,
  'inAppEnabled': instance.inAppEnabled,
  'quietHoursEnabled': instance.quietHoursEnabled,
  'quietStartTime': instance.quietStartTime,
  'quietEndTime': instance.quietEndTime,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

NotificationCreateRequest _$NotificationCreateRequestFromJson(
  Map<String, dynamic> json,
) => NotificationCreateRequest(
  title: json['title'] as String,
  message: json['message'] as String,
  type: json['type'] as String,
  category: json['category'] as String,
  data: json['data'] as String?,
  userId: (json['userId'] as num?)?.toInt(),
  imageUrl: json['imageUrl'] as String?,
  actionUrl: json['actionUrl'] as String?,
  actionText: json['actionText'] as String?,
);

Map<String, dynamic> _$NotificationCreateRequestToJson(
  NotificationCreateRequest instance,
) => <String, dynamic>{
  'title': instance.title,
  'message': instance.message,
  'type': instance.type,
  'category': instance.category,
  'data': instance.data,
  'userId': instance.userId,
  'imageUrl': instance.imageUrl,
  'actionUrl': instance.actionUrl,
  'actionText': instance.actionText,
};

NotificationUpdateRequest _$NotificationUpdateRequestFromJson(
  Map<String, dynamic> json,
) => NotificationUpdateRequest(
  isRead: json['isRead'] as bool?,
  isSent: json['isSent'] as bool?,
);

Map<String, dynamic> _$NotificationUpdateRequestToJson(
  NotificationUpdateRequest instance,
) => <String, dynamic>{'isRead': instance.isRead, 'isSent': instance.isSent};

NotificationPreferenceUpdateRequest
_$NotificationPreferenceUpdateRequestFromJson(Map<String, dynamic> json) =>
    NotificationPreferenceUpdateRequest(
      pushEnabled: json['pushEnabled'] as bool?,
      emailEnabled: json['emailEnabled'] as bool?,
      smsEnabled: json['smsEnabled'] as bool?,
      inAppEnabled: json['inAppEnabled'] as bool?,
      quietHoursEnabled: json['quietHoursEnabled'] as bool?,
      quietStartTime: json['quietStartTime'] as String?,
      quietEndTime: json['quietEndTime'] as String?,
    );

Map<String, dynamic> _$NotificationPreferenceUpdateRequestToJson(
  NotificationPreferenceUpdateRequest instance,
) => <String, dynamic>{
  'pushEnabled': instance.pushEnabled,
  'emailEnabled': instance.emailEnabled,
  'smsEnabled': instance.smsEnabled,
  'inAppEnabled': instance.inAppEnabled,
  'quietHoursEnabled': instance.quietHoursEnabled,
  'quietStartTime': instance.quietStartTime,
  'quietEndTime': instance.quietEndTime,
};

NotificationStats _$NotificationStatsFromJson(Map<String, dynamic> json) =>
    NotificationStats(
      totalNotifications: (json['totalNotifications'] as num).toInt(),
      unreadNotifications: (json['unreadNotifications'] as num).toInt(),
      readNotifications: (json['readNotifications'] as num).toInt(),
      notificationsByType: Map<String, int>.from(
        json['notificationsByType'] as Map,
      ),
      notificationsByCategory: Map<String, int>.from(
        json['notificationsByCategory'] as Map,
      ),
      recentNotifications:
          (json['recentNotifications'] as List<dynamic>)
              .map((e) => Notification.fromJson(e as Map<String, dynamic>))
              .toList(),
      averageReadTime: (json['averageReadTime'] as num).toDouble(),
    );

Map<String, dynamic> _$NotificationStatsToJson(NotificationStats instance) =>
    <String, dynamic>{
      'totalNotifications': instance.totalNotifications,
      'unreadNotifications': instance.unreadNotifications,
      'readNotifications': instance.readNotifications,
      'notificationsByType': instance.notificationsByType,
      'notificationsByCategory': instance.notificationsByCategory,
      'recentNotifications': instance.recentNotifications,
      'averageReadTime': instance.averageReadTime,
    };

NotificationFilter _$NotificationFilterFromJson(Map<String, dynamic> json) =>
    NotificationFilter(
      type: json['type'] as String?,
      category: json['category'] as String?,
      isRead: json['isRead'] as bool?,
      isSent: json['isSent'] as bool?,
      startDate:
          json['startDate'] == null
              ? null
              : DateTime.parse(json['startDate'] as String),
      endDate:
          json['endDate'] == null
              ? null
              : DateTime.parse(json['endDate'] as String),
      searchQuery: json['searchQuery'] as String?,
    );

Map<String, dynamic> _$NotificationFilterToJson(NotificationFilter instance) =>
    <String, dynamic>{
      'type': instance.type,
      'category': instance.category,
      'isRead': instance.isRead,
      'isSent': instance.isSent,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'searchQuery': instance.searchQuery,
    };
