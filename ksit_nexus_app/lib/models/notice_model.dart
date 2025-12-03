import 'package:json_annotation/json_annotation.dart';

part 'notice_model.g.dart';

@JsonSerializable()
class Notice {
  final int id;
  final String title;
  final String content;
  final String category;
  final String priority;
  final String? targetAudience;
  final String? targetBranch;
  final String? targetYear;
  final String? attachmentUrl;
  final String? attachmentName;
  final int createdById;
  final String createdByName;
  final String createdByRole;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final bool isPinned;
  final int viewCount;
  final List<NoticeView> views;
  final String status;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    this.targetAudience,
    this.targetBranch,
    this.targetYear,
    this.attachmentUrl,
    this.attachmentName,
    required this.createdById,
    required this.createdByName,
    required this.createdByRole,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    required this.isActive,
    required this.isPinned,
    required this.viewCount,
    required this.views,
    required this.status,
  });

  factory Notice.fromJson(Map<String, dynamic> json) => _$NoticeFromJson(json);
  Map<String, dynamic> toJson() => _$NoticeToJson(this);

  String get categoryDisplayName {
    switch (category) {
      case 'academic': return 'Academic';
      case 'administrative': return 'Administrative';
      case 'event': return 'Event';
      case 'exam': return 'Exam';
      case 'holiday': return 'Holiday';
      case 'sports': return 'Sports';
      case 'cultural': return 'Cultural';
      case 'placement': return 'Placement';
      case 'library': return 'Library';
      case 'hostel': return 'Hostel';
      case 'transport': return 'Transport';
      case 'other': return 'Other';
      default: return category;
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 'low': return 'Low';
      case 'medium': return 'Medium';
      case 'high': return 'High';
      case 'urgent': return 'Urgent';
      default: return priority;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'draft': return 'Draft';
      case 'published': return 'Published';
      case 'archived': return 'Archived';
      default: return status;
    }
  }

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;
  bool get isRecent => DateTime.now().difference(createdAt).inDays <= 7;
  bool get isToday => DateTime.now().difference(createdAt).inDays == 0;
}

@JsonSerializable()
class NoticeView {
  final int id;
  final int noticeId;
  final int userId;
  final String userName;
  final DateTime viewedAt;

  NoticeView({
    required this.id,
    required this.noticeId,
    required this.userId,
    required this.userName,
    required this.viewedAt,
  });

  factory NoticeView.fromJson(Map<String, dynamic> json) => _$NoticeViewFromJson(json);
  Map<String, dynamic> toJson() => _$NoticeViewToJson(this);
}

@JsonSerializable()
class NoticeCreateRequest {
  final String title;
  final String content;
  final String category;
  final String priority;
  final String? targetAudience;
  final String? targetBranch;
  final String? targetYear;
  final String? attachmentUrl;
  final String? attachmentName;
  final DateTime? expiresAt;
  final bool isPinned;
  final String status;

  NoticeCreateRequest({
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    this.targetAudience,
    this.targetBranch,
    this.targetYear,
    this.attachmentUrl,
    this.attachmentName,
    this.expiresAt,
    required this.isPinned,
    required this.status,
  });

  factory NoticeCreateRequest.fromJson(Map<String, dynamic> json) => _$NoticeCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$NoticeCreateRequestToJson(this);
}

@JsonSerializable()
class NoticeUpdateRequest {
  final String? title;
  final String? content;
  final String? category;
  final String? priority;
  final String? targetAudience;
  final String? targetBranch;
  final String? targetYear;
  final String? attachmentUrl;
  final String? attachmentName;
  final DateTime? expiresAt;
  final bool? isActive;
  final bool? isPinned;

  NoticeUpdateRequest({
    this.title,
    this.content,
    this.category,
    this.priority,
    this.targetAudience,
    this.targetBranch,
    this.targetYear,
    this.attachmentUrl,
    this.attachmentName,
    this.expiresAt,
    this.isActive,
    this.isPinned,
  });

  factory NoticeUpdateRequest.fromJson(Map<String, dynamic> json) => _$NoticeUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$NoticeUpdateRequestToJson(this);
}

@JsonSerializable()
class NoticeStats {
  final int totalNotices;
  final int activeNotices;
  final int pinnedNotices;
  final int expiredNotices;
  final Map<String, int> noticesByCategory;
  final Map<String, int> noticesByPriority;
  final List<Notice> recentNotices;
  final List<Notice> pinnedNoticesList;

  NoticeStats({
    required this.totalNotices,
    required this.activeNotices,
    required this.pinnedNotices,
    required this.expiredNotices,
    required this.noticesByCategory,
    required this.noticesByPriority,
    required this.recentNotices,
    required this.pinnedNoticesList,
  });

  factory NoticeStats.fromJson(Map<String, dynamic> json) => _$NoticeStatsFromJson(json);
  Map<String, dynamic> toJson() => _$NoticeStatsToJson(this);
}

@JsonSerializable()
class NoticeFilter {
  final String? category;
  final String? priority;
  final String? targetAudience;
  final String? targetBranch;
  final String? targetYear;
  final bool? isActive;
  final bool? isPinned;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  NoticeFilter({
    this.category,
    this.priority,
    this.targetAudience,
    this.targetBranch,
    this.targetYear,
    this.isActive,
    this.isPinned,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });

  factory NoticeFilter.fromJson(Map<String, dynamic> json) => _$NoticeFilterFromJson(json);
  Map<String, dynamic> toJson() => _$NoticeFilterToJson(this);

  bool get hasFilters => 
    category != null ||
    priority != null ||
    targetAudience != null ||
    targetBranch != null ||
    targetYear != null ||
    isActive != null ||
    isPinned != null ||
    startDate != null ||
    endDate != null ||
    (searchQuery != null && searchQuery!.isNotEmpty);
}