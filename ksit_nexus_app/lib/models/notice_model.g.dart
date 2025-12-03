// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notice_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notice _$NoticeFromJson(Map<String, dynamic> json) => Notice(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  content: json['content'] as String,
  category: json['category'] as String,
  priority: json['priority'] as String,
  targetAudience: json['targetAudience'] as String?,
  targetBranch: json['targetBranch'] as String?,
  targetYear: json['targetYear'] as String?,
  attachmentUrl: json['attachmentUrl'] as String?,
  attachmentName: json['attachmentName'] as String?,
  createdById: (json['createdById'] as num).toInt(),
  createdByName: json['createdByName'] as String,
  createdByRole: json['createdByRole'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  expiresAt:
      json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
  isActive: json['isActive'] as bool,
  isPinned: json['isPinned'] as bool,
  viewCount: (json['viewCount'] as num).toInt(),
  views:
      (json['views'] as List<dynamic>)
          .map((e) => NoticeView.fromJson(e as Map<String, dynamic>))
          .toList(),
  status: json['status'] as String,
);

Map<String, dynamic> _$NoticeToJson(Notice instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'content': instance.content,
  'category': instance.category,
  'priority': instance.priority,
  'targetAudience': instance.targetAudience,
  'targetBranch': instance.targetBranch,
  'targetYear': instance.targetYear,
  'attachmentUrl': instance.attachmentUrl,
  'attachmentName': instance.attachmentName,
  'createdById': instance.createdById,
  'createdByName': instance.createdByName,
  'createdByRole': instance.createdByRole,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'expiresAt': instance.expiresAt?.toIso8601String(),
  'isActive': instance.isActive,
  'isPinned': instance.isPinned,
  'viewCount': instance.viewCount,
  'views': instance.views,
  'status': instance.status,
};

NoticeView _$NoticeViewFromJson(Map<String, dynamic> json) => NoticeView(
  id: (json['id'] as num).toInt(),
  noticeId: (json['noticeId'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  userName: json['userName'] as String,
  viewedAt: DateTime.parse(json['viewedAt'] as String),
);

Map<String, dynamic> _$NoticeViewToJson(NoticeView instance) =>
    <String, dynamic>{
      'id': instance.id,
      'noticeId': instance.noticeId,
      'userId': instance.userId,
      'userName': instance.userName,
      'viewedAt': instance.viewedAt.toIso8601String(),
    };

NoticeCreateRequest _$NoticeCreateRequestFromJson(Map<String, dynamic> json) =>
    NoticeCreateRequest(
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String,
      targetAudience: json['targetAudience'] as String?,
      targetBranch: json['targetBranch'] as String?,
      targetYear: json['targetYear'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
      attachmentName: json['attachmentName'] as String?,
      expiresAt:
          json['expiresAt'] == null
              ? null
              : DateTime.parse(json['expiresAt'] as String),
      isPinned: json['isPinned'] as bool,
      status: json['status'] as String,
    );

Map<String, dynamic> _$NoticeCreateRequestToJson(
  NoticeCreateRequest instance,
) => <String, dynamic>{
  'title': instance.title,
  'content': instance.content,
  'category': instance.category,
  'priority': instance.priority,
  'targetAudience': instance.targetAudience,
  'targetBranch': instance.targetBranch,
  'targetYear': instance.targetYear,
  'attachmentUrl': instance.attachmentUrl,
  'attachmentName': instance.attachmentName,
  'expiresAt': instance.expiresAt?.toIso8601String(),
  'isPinned': instance.isPinned,
  'status': instance.status,
};

NoticeUpdateRequest _$NoticeUpdateRequestFromJson(Map<String, dynamic> json) =>
    NoticeUpdateRequest(
      title: json['title'] as String?,
      content: json['content'] as String?,
      category: json['category'] as String?,
      priority: json['priority'] as String?,
      targetAudience: json['targetAudience'] as String?,
      targetBranch: json['targetBranch'] as String?,
      targetYear: json['targetYear'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
      attachmentName: json['attachmentName'] as String?,
      expiresAt:
          json['expiresAt'] == null
              ? null
              : DateTime.parse(json['expiresAt'] as String),
      isActive: json['isActive'] as bool?,
      isPinned: json['isPinned'] as bool?,
    );

Map<String, dynamic> _$NoticeUpdateRequestToJson(
  NoticeUpdateRequest instance,
) => <String, dynamic>{
  'title': instance.title,
  'content': instance.content,
  'category': instance.category,
  'priority': instance.priority,
  'targetAudience': instance.targetAudience,
  'targetBranch': instance.targetBranch,
  'targetYear': instance.targetYear,
  'attachmentUrl': instance.attachmentUrl,
  'attachmentName': instance.attachmentName,
  'expiresAt': instance.expiresAt?.toIso8601String(),
  'isActive': instance.isActive,
  'isPinned': instance.isPinned,
};

NoticeStats _$NoticeStatsFromJson(Map<String, dynamic> json) => NoticeStats(
  totalNotices: (json['totalNotices'] as num).toInt(),
  activeNotices: (json['activeNotices'] as num).toInt(),
  pinnedNotices: (json['pinnedNotices'] as num).toInt(),
  expiredNotices: (json['expiredNotices'] as num).toInt(),
  noticesByCategory: Map<String, int>.from(json['noticesByCategory'] as Map),
  noticesByPriority: Map<String, int>.from(json['noticesByPriority'] as Map),
  recentNotices:
      (json['recentNotices'] as List<dynamic>)
          .map((e) => Notice.fromJson(e as Map<String, dynamic>))
          .toList(),
  pinnedNoticesList:
      (json['pinnedNoticesList'] as List<dynamic>)
          .map((e) => Notice.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$NoticeStatsToJson(NoticeStats instance) =>
    <String, dynamic>{
      'totalNotices': instance.totalNotices,
      'activeNotices': instance.activeNotices,
      'pinnedNotices': instance.pinnedNotices,
      'expiredNotices': instance.expiredNotices,
      'noticesByCategory': instance.noticesByCategory,
      'noticesByPriority': instance.noticesByPriority,
      'recentNotices': instance.recentNotices,
      'pinnedNoticesList': instance.pinnedNoticesList,
    };

NoticeFilter _$NoticeFilterFromJson(Map<String, dynamic> json) => NoticeFilter(
  category: json['category'] as String?,
  priority: json['priority'] as String?,
  targetAudience: json['targetAudience'] as String?,
  targetBranch: json['targetBranch'] as String?,
  targetYear: json['targetYear'] as String?,
  isActive: json['isActive'] as bool?,
  isPinned: json['isPinned'] as bool?,
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

Map<String, dynamic> _$NoticeFilterToJson(NoticeFilter instance) =>
    <String, dynamic>{
      'category': instance.category,
      'priority': instance.priority,
      'targetAudience': instance.targetAudience,
      'targetBranch': instance.targetBranch,
      'targetYear': instance.targetYear,
      'isActive': instance.isActive,
      'isPinned': instance.isPinned,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'searchQuery': instance.searchQuery,
    };
