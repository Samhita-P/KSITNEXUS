import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class StudyGroup {
  final int id;
  final String? name;
  final String? description;
  final String? subject;
  final String? difficultyLevel;
  final int? maxMembers;
  final bool? isPublic;
  final bool? isActive;
  final int? creatorId;
  final String? creatorName;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GroupMember> members;
  final List<GroupMessage> recentMessages;
  final List<GroupResource> resources;
  final List<GroupEvent> events;
  final int? currentMemberCount;
  final bool? isFull;
  final bool? isMember;
  final String? joinStatus;
  final String? status;
  final bool? isReported;
  final String? reportReason;
  final DateTime? reportedAt;
  final int? memberCount;
  final String? level;
  final String? visibility;

  StudyGroup({
    required this.id,
    this.name,
    this.description,
    this.subject,
    this.difficultyLevel,
    this.maxMembers,
    this.isPublic,
    this.isActive,
    this.creatorId,
    this.creatorName,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.members,
    required this.recentMessages,
    required this.resources,
    required this.events,
    this.currentMemberCount,
    this.isFull,
    this.isMember,
    this.joinStatus,
    this.status,
    this.isReported,
    this.reportReason,
    this.reportedAt,
    this.memberCount,
    this.level,
    this.visibility,
  });

  factory StudyGroup.fromJson(Map<String, dynamic> json) {
    return StudyGroup(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      description: json['description'] as String?,
      subject: json['subject'] as String?,
      difficultyLevel: json['difficulty_level'] as String?,
      maxMembers: json['max_members'] as int?,
      isPublic: json['is_public'] as bool?,
      isActive: json['is_active'] as bool?,
      creatorId: json['creator_id'] as int?,
      creatorName: json['creator_name'] as String?,
      tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
      members: (json['members'] as List?)?.map((e) => GroupMember.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      recentMessages: (json['recent_messages'] as List?)?.map((e) => GroupMessage.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      resources: (json['resources'] as List?)?.map((e) => GroupResource.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      events: (json['events'] as List?)?.map((e) => GroupEvent.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      currentMemberCount: json['current_member_count'] as int?,
      isFull: json['is_full'] as bool?,
      isMember: json['is_member'] as bool?,
      joinStatus: json['join_status'] as String?,
      status: json['status'] as String? ?? 'active',
      isReported: json['is_reported'] as bool? ?? false,
      reportReason: json['report_reason'] as String?,
      reportedAt: json['reported_at'] != null ? DateTime.parse(json['reported_at'] as String) : null,
      memberCount: json['member_count'] as int? ?? 0,
      level: json['level'] as String? ?? 'beginner',
      visibility: json['visibility'] as String? ?? 'public',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subject': subject,
      'difficulty_level': difficultyLevel,
      'max_members': maxMembers,
      'is_public': isPublic,
      'is_active': isActive,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'members': members.map((e) => e.toJson()).toList(),
      'recent_messages': recentMessages.map((e) => e.toJson()).toList(),
      'resources': resources.map((e) => e.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      'status': status,
      'is_reported': isReported,
      'report_reason': reportReason,
      'reported_at': reportedAt?.toIso8601String(),
      'member_count': memberCount,
      'level': level,
      'visibility': visibility,
    };
  }

  bool get canJoin => (isActive ?? false) && !(isFull ?? false) && (isPublic ?? false);

  String get subjectDisplayName {
    switch (subject) {
      case 'mathematics': return 'Mathematics';
      case 'physics': return 'Physics';
      case 'chemistry': return 'Chemistry';
      case 'computer_science': return 'Computer Science';
      case 'electronics': return 'Electronics';
      case 'mechanical': return 'Mechanical';
      case 'civil': return 'Civil';
      case 'electrical': return 'Electrical';
      case 'other': return 'Other';
      default: return subject ?? 'Unknown';
    }
  }

  String get difficultyDisplayName {
    switch (difficultyLevel) {
      case 'beginner': return 'Beginner';
      case 'intermediate': return 'Intermediate';
      case 'advanced': return 'Advanced';
      default: return difficultyLevel ?? 'Unknown';
    }
  }
}

@JsonSerializable()
class GroupMember {
  final int id;
  final int? userId;
  final String? userName;
  final String? userEmail;
  final String? role;
  final DateTime joinedAt;
  final bool? isActive;

  GroupMember({
    required this.id,
    this.userId,
    this.userName,
    this.userEmail,
    this.role,
    required this.joinedAt,
    this.isActive,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int?,
      userName: json['user_name'] as String?,
      userEmail: json['user_email'] as String?,
      role: json['role'] as String?,
      joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at'] as String) : DateTime.now(),
      isActive: json['is_active'] as bool?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isModerator => role == 'moderator';
  bool get isMember => role == 'member';
}

@JsonSerializable()
class GroupMessage {
  final int id;
  final int? groupId;
  final int? senderId;
  final String? senderName;
  final String? message;
  final String? messageType;
  final String? attachmentUrl;
  final String? attachmentName;
  final DateTime sentAt;
  final DateTime? editedAt;
  final bool? isEdited;
  final bool? isDeleted;

  GroupMessage({
    required this.id,
    this.groupId,
    this.senderId,
    this.senderName,
    this.message,
    this.messageType,
    this.attachmentUrl,
    this.attachmentName,
    required this.sentAt,
    this.editedAt,
    this.isEdited,
    this.isDeleted,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    // Get sender name from JSON - backend returns 'sender' as a string
    String? senderNameValue;
    if (json['sender'] != null) {
      senderNameValue = json['sender'].toString().trim();
      // Only use if it's not empty and not 'null' string
      if (senderNameValue.isEmpty || senderNameValue == 'null' || senderNameValue == 'None') {
        senderNameValue = null;
      }
    }
    
    // If sender name is still null, try to construct from sender_id
    if (senderNameValue == null || senderNameValue.isEmpty) {
      final senderId = json['sender_id'] as int?;
      if (senderId != null) {
        senderNameValue = 'User $senderId';
      } else {
        senderNameValue = 'Unknown User';
      }
    }
    
    return GroupMessage(
      id: json['id'] as int? ?? 0,
      groupId: json['group_id'] as int?,
      senderId: json['sender_id'] as int?,
      senderName: senderNameValue,
      message: json['content']?.toString() ?? '', // Backend returns 'content' field
      messageType: json['message_type'] as String? ?? 'text',
      attachmentUrl: json['attachment']?.toString(),
      attachmentName: json['attachment_name'] as String?,
      sentAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(), // Backend returns 'created_at'
      editedAt: json['edited_at'] != null ? DateTime.parse(json['edited_at'] as String) : null,
      isEdited: json['is_edited'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'sender_id': senderId,
      'sender_name': senderName,
      'message': message,
      'message_type': messageType,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'sent_at': sentAt.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
      'is_edited': isEdited,
      'is_deleted': isDeleted,
    };
  }

  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;
  bool get isTextMessage => messageType == 'text';
  bool get isFileMessage => messageType == 'file';
  bool get isImageMessage => messageType == 'image';
  bool get isUser => senderId == 1; // This should be compared with current user ID
}

@JsonSerializable()
class GroupResource {
  final int id;
  final int? groupId;
  final int? uploadedById;
  final String? uploadedByName;
  final String? fileName;
  final String? fileUrl;
  final String? fileType;
  final int? fileSize;
  final String? description;
  final String? category;
  final DateTime uploadedAt;
  final DateTime updatedAt;

  GroupResource({
    required this.id,
    this.groupId,
    this.uploadedById,
    this.uploadedByName,
    this.fileName,
    this.fileUrl,
    this.fileType,
    this.fileSize,
    this.description,
    this.category,
    required this.uploadedAt,
    required this.updatedAt,
  });

  factory GroupResource.fromJson(Map<String, dynamic> json) {
    return GroupResource(
      id: json['id'] as int? ?? 0,
      groupId: json['group_id'] as int?,
      uploadedById: json['uploaded_by_id'] as int?,
      uploadedByName: json['uploaded_by'] as String?, // Backend returns 'uploaded_by' as string
      fileName: json['file_name'] as String?, // Backend returns computed 'file_name'
      fileUrl: json['file_url'] as String?, // Backend returns computed 'file_url'
      fileType: json['resource_type'] as String?, // Backend uses 'resource_type'
      fileSize: json['file_size'] as int?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      uploadedAt: json['uploaded_at'] != null ? DateTime.parse(json['uploaded_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'uploaded_by_id': uploadedById,
      'uploaded_by_name': uploadedByName,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'description': description,
      'category': category,
      'uploaded_at': uploadedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get fileSizeFormatted {
    final size = fileSize ?? 0;
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

@JsonSerializable()
class GroupEvent {
  final int id;
  final int? groupId;
  final int? createdById;
  final String? createdBy;
  final String? title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final String? eventType;
  final String? meetingLink;
  final int? maxAttendees;
  final bool? isRecurring;
  final String? recurrencePattern;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<EventParticipant> participants;

  GroupEvent({
    required this.id,
    this.groupId,
    this.createdById,
    this.createdBy,
    this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.location,
    this.eventType,
    this.meetingLink,
    this.maxAttendees,
    this.isRecurring,
    this.recurrencePattern,
    required this.createdAt,
    required this.updatedAt,
    this.participants = const [],
  });

  factory GroupEvent.fromJson(Map<String, dynamic> json) {
    return GroupEvent(
      id: json['id'] as int? ?? 0,
      groupId: json['group_id'] as int?,
      createdById: json['created_by_id'] as int?,
      createdBy: json['created_by']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time'] as String) : DateTime.now(),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      location: json['location']?.toString(),
      eventType: json['event_type']?.toString(),
      meetingLink: json['meeting_link']?.toString(),
      maxAttendees: json['max_attendees'] as int?,
      isRecurring: json['is_recurring'] as bool?,
      recurrencePattern: json['recurrence_pattern']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
      participants: [], // Backend doesn't return participants yet
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'created_by_id': createdById,
      'created_by': createdBy,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'location': location,
      'event_type': eventType,
      'meeting_link': meetingLink,
      'max_attendees': maxAttendees,
      'is_recurring': isRecurring,
      'recurrence_pattern': recurrencePattern,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'participants': participants.map((e) => e.toJson()).toList(),
    };
  }

  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isOngoing => endTime != null && DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime!);
  bool get isPast => endTime != null && endTime!.isBefore(DateTime.now());
}

@JsonSerializable()
class EventParticipant {
  final int id;
  final int userId;
  final String? userName;
  final String? status;
  final DateTime joinedAt;

  EventParticipant({
    required this.id,
    required this.userId,
    this.userName,
    this.status,
    required this.joinedAt,
  });

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    return EventParticipant(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      userName: json['user_name'] as String?,
      status: json['status'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'status': status,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  bool get isAttending => status == 'attending';
  bool get isMaybe => status == 'maybe';
  bool get isNotAttending => status == 'not_attending';
}

@JsonSerializable()
class StudyGroupCreateRequest {
  final String name;
  final String description;
  final String subject;
  final String difficultyLevel;
  final int maxMembers;
  final bool isPublic;
  final List<String> tags;

  StudyGroupCreateRequest({
    required this.name,
    required this.description,
    required this.subject,
    required this.difficultyLevel,
    required this.maxMembers,
    required this.isPublic,
    required this.tags,
  });

  factory StudyGroupCreateRequest.fromJson(Map<String, dynamic> json) {
    return StudyGroupCreateRequest(
      name: json['name'] as String,
      description: json['description'] as String,
      subject: json['subject'] as String,
      difficultyLevel: json['difficulty_level'] as String,
      maxMembers: json['max_members'] as int,
      isPublic: json['is_public'] as bool,
      tags: (json['tags'] as List).map((e) => e as String).toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'subject': subject,
      'difficulty_level': difficultyLevel,
      'max_members': maxMembers,
      'is_public': isPublic,
      'tags': tags,
    };
  }
}

@JsonSerializable()
class GroupMessageCreateRequest {
  final String message;
  final String messageType;
  final String? attachmentUrl;
  final String? attachmentName;

  GroupMessageCreateRequest({
    required this.message,
    required this.messageType,
    this.attachmentUrl,
    this.attachmentName,
  });

  factory GroupMessageCreateRequest.fromJson(Map<String, dynamic> json) {
    return GroupMessageCreateRequest(
      message: json['message'] as String,
      messageType: json['message_type'] as String,
      attachmentUrl: json['attachment_url'] as String?,
      attachmentName: json['attachment_name'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'content': message,  // Backend expects 'content' field
      'message_type': messageType,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
    };
  }
}

@JsonSerializable()
class GroupResourceCreateRequest {
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final String? description;
  final String? category;

  GroupResourceCreateRequest({
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    this.description,
    this.category,
  });

  factory GroupResourceCreateRequest.fromJson(Map<String, dynamic> json) {
    return GroupResourceCreateRequest(
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int,
      description: json['description'] as String?,
      category: json['category'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'description': description,
      'category': category,
    };
  }
}

@JsonSerializable()
class GroupEventCreateRequest {
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final String? eventType;
  final String? meetingLink;
  final int? maxAttendees;
  final bool isRecurring;
  final String? recurrencePattern;

  GroupEventCreateRequest({
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.location,
    this.eventType,
    this.meetingLink,
    this.maxAttendees,
    this.isRecurring = false,
    this.recurrencePattern,
  });

  factory GroupEventCreateRequest.fromJson(Map<String, dynamic> json) {
    return GroupEventCreateRequest(
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      location: json['location'] as String?,
      eventType: json['event_type'] as String?,
      meetingLink: json['meeting_link'] as String?,
      maxAttendees: json['max_attendees'] as int?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrencePattern: json['recurrence_pattern'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description ?? '',
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'location': location,
      'event_type': eventType,
      'meeting_link': meetingLink,
      'max_attendees': maxAttendees,
      'is_recurring': isRecurring,
      'recurrence_pattern': recurrencePattern,
    };
  }
}

@JsonSerializable()
class StudyGroupUpdateRequest {
  final String? name;
  final String? description;
  final String? subject;
  final String? difficultyLevel;
  final int? maxMembers;
  final bool? isPublic;
  final bool? isActive;
  final List<String>? tags;

  StudyGroupUpdateRequest({
    this.name,
    this.description,
    this.subject,
    this.difficultyLevel,
    this.maxMembers,
    this.isPublic,
    this.isActive,
    this.tags,
  });

  factory StudyGroupUpdateRequest.fromJson(Map<String, dynamic> json) {
    return StudyGroupUpdateRequest(
      name: json['name'] as String?,
      description: json['description'] as String?,
      subject: json['subject'] as String?,
      difficultyLevel: json['difficulty_level'] as String?,
      maxMembers: json['max_members'] as int?,
      isPublic: json['is_public'] as bool?,
      isActive: json['is_active'] as bool?,
      tags: (json['tags'] as List?)?.map((e) => e as String).toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'subject': subject,
      'difficulty_level': difficultyLevel,
      'max_members': maxMembers,
      'is_public': isPublic,
      'is_active': isActive,
      'tags': tags,
    };
  }
}

@JsonSerializable()
class StudyGroupStats {
  final int totalGroups;
  final int activeGroups;
  final int totalMembers;
  final Map<String, int> groupsBySubject;
  final Map<String, int> groupsByDifficulty;
  final double averageGroupSize;

  StudyGroupStats({
    required this.totalGroups,
    required this.activeGroups,
    required this.totalMembers,
    required this.groupsBySubject,
    required this.groupsByDifficulty,
    required this.averageGroupSize,
  });

  factory StudyGroupStats.fromJson(Map<String, dynamic> json) {
    return StudyGroupStats(
      totalGroups: json['total_groups'] as int,
      activeGroups: json['active_groups'] as int,
      totalMembers: json['total_members'] as int,
      groupsBySubject: Map<String, int>.from(json['groups_by_subject'] as Map),
      groupsByDifficulty: Map<String, int>.from(json['groups_by_difficulty'] as Map),
      averageGroupSize: (json['average_group_size'] as num).toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'total_groups': totalGroups,
      'active_groups': activeGroups,
      'total_members': totalMembers,
      'groups_by_subject': groupsBySubject,
      'groups_by_difficulty': groupsByDifficulty,
      'average_group_size': averageGroupSize,
    };
  }
}