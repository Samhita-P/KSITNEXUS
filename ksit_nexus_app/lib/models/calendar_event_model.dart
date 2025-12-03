class CalendarEvent {
  final int? id;
  final String title;
  final String? description;
  final String eventType;
  final DateTime startTime;
  final DateTime? endTime;
  final bool allDay;
  final String timezone;
  final String? location;
  final String? meetingLink;
  final bool isRecurring;
  final String recurrencePattern;
  final DateTime? recurrenceEndDate;
  final int? recurrenceCount;
  final String color;
  final String privacy;
  final int createdBy;
  final String? createdByName;
  final String? createdByEmail;
  final List<int>? attendeeIds;
  final List<Map<String, dynamic>>? attendeesDetails;
  final List<String>? externalAttendees;
  final bool isCancelled;
  final DateTime? cancelledAt;
  final int? cancelledBy;
  final int? relatedMeeting;
  final int? relatedStudyGroupEvent;
  final List<EventReminder>? reminders;
  final bool isUpcoming;
  final bool isPast;
  final bool isOngoing;
  final int? durationMinutes;
  final String? eventTypeDisplay;
  final String? privacyDisplay;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CalendarEvent({
    this.id,
    required this.title,
    this.description,
    required this.eventType,
    required this.startTime,
    this.endTime,
    this.allDay = false,
    this.timezone = 'UTC',
    this.location,
    this.meetingLink,
    this.isRecurring = false,
    this.recurrencePattern = 'none',
    this.recurrenceEndDate,
    this.recurrenceCount,
    this.color = '#3b82f6',
    this.privacy = 'private',
    required this.createdBy,
    this.createdByName,
    this.createdByEmail,
    this.attendeeIds,
    this.attendeesDetails,
    this.externalAttendees,
    this.isCancelled = false,
    this.cancelledAt,
    this.cancelledBy,
    this.relatedMeeting,
    this.relatedStudyGroupEvent,
    this.reminders,
    this.isUpcoming = false,
    this.isPast = false,
    this.isOngoing = false,
    this.durationMinutes,
    this.eventTypeDisplay,
    this.privacyDisplay,
    this.createdAt,
    this.updatedAt,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is List) return value.length;
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }
    
    // Handle created_by field - it might be an object with an 'id' field or a direct int
    int createdById;
    if (json['created_by'] is Map<String, dynamic>) {
      createdById = safeInt(json['created_by']?['id']);
    } else {
      createdById = safeInt(json['created_by']);
    }
    
    // Helper to safely get String values
    String safeString(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value.isEmpty ? defaultValue : value;
      return value.toString().isEmpty ? defaultValue : value.toString();
    }
    
    // Safely parse DateTime
    DateTime? safeParseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        if (value is String) {
          return DateTime.parse(value);
        }
        if (value is DateTime) {
          return value;
        }
        return null;
      } catch (e) {
        print('Error parsing DateTime: $value, error: $e');
        return null;
      }
    }
    
    return CalendarEvent(
      id: json['id'] as int?,
      title: safeString(json['title'], 'Untitled Event'),
      description: json['description'] != null && json['description'].toString().isNotEmpty 
          ? safeString(json['description'], '') 
          : null,
      eventType: safeString(json['event_type'], 'event'),
      startTime: safeParseDateTime(json['start_time']) ?? DateTime.now(),
      endTime: safeParseDateTime(json['end_time']),
      allDay: json['all_day'] as bool? ?? false,
      timezone: safeString(json['timezone'], 'UTC'),
      location: json['location'] != null && json['location'].toString().isNotEmpty
          ? safeString(json['location'], '')
          : null,
      meetingLink: json['meeting_link'] != null && json['meeting_link'].toString().isNotEmpty
          ? safeString(json['meeting_link'], '')
          : null,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrencePattern: safeString(json['recurrence_pattern'], 'none'),
      recurrenceEndDate: safeParseDateTime(json['recurrence_end_date']),
      recurrenceCount: json['recurrence_count'] != null ? safeInt(json['recurrence_count']) : null,
      color: safeString(json['color'], '#3b82f6'),
      privacy: safeString(json['privacy'], 'private'),
      createdBy: createdById,
      createdByName: json['created_by_name'] != null && json['created_by_name'].toString().isNotEmpty
          ? safeString(json['created_by_name'], '')
          : null,
      createdByEmail: json['created_by_email'] != null && json['created_by_email'].toString().isNotEmpty
          ? safeString(json['created_by_email'], '')
          : null,
      attendeeIds: json['attendees'] != null && json['attendees'] is List
          ? List<int>.from((json['attendees'] as List).map((e) => safeInt(e)))
          : null,
      attendeesDetails: json['attendees_details'] != null && json['attendees_details'] is List
          ? List<Map<String, dynamic>>.from(json['attendees_details'] as List)
          : null,
      externalAttendees: json['external_attendees'] != null && json['external_attendees'] is List
          ? List<String>.from((json['external_attendees'] as List).map((e) => e.toString()))
          : null,
      isCancelled: json['is_cancelled'] as bool? ?? false,
      cancelledAt: safeParseDateTime(json['cancelled_at']),
      cancelledBy: json['cancelled_by'] != null ? safeInt(json['cancelled_by']) : null,
      relatedMeeting: json['related_meeting'] != null ? safeInt(json['related_meeting']) : null,
      relatedStudyGroupEvent: json['related_study_group_event'] != null ? safeInt(json['related_study_group_event']) : null,
      reminders: json['reminders'] != null && json['reminders'] is List
          ? (json['reminders'] as List)
              .where((e) => e is Map<String, dynamic>)
              .map((e) => EventReminder.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      isUpcoming: json['is_upcoming'] as bool? ?? false,
      isPast: json['is_past'] as bool? ?? false,
      isOngoing: json['is_ongoing'] as bool? ?? false,
      durationMinutes: json['duration_minutes'] != null ? safeInt(json['duration_minutes']) : null,
      eventTypeDisplay: json['event_type_display'] != null && json['event_type_display'].toString().isNotEmpty
          ? safeString(json['event_type_display'], '')
          : null,
      privacyDisplay: json['privacy_display'] != null && json['privacy_display'].toString().isNotEmpty
          ? safeString(json['privacy_display'], '')
          : null,
      createdAt: safeParseDateTime(json['created_at']),
      updatedAt: safeParseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    // Helper to safely get String value (handle empty/null case)
    String safeStringValue(String value, String defaultValue) {
      try {
        if (value.isEmpty) return defaultValue;
        return value;
      } catch (e) {
        // If value is somehow null or invalid, return default
        return defaultValue;
      }
    }
    
    // Ensure all required String fields have values (they're non-nullable but add safety)
    // Use try-catch to handle any edge cases
    String safeTitle;
    String safeEventType;
    String safeTimezone;
    String safeRecurrencePattern;
    String safeColor;
    String safePrivacy;
    
    try {
      safeTitle = safeStringValue(title, 'Untitled Event');
    } catch (e) {
      safeTitle = 'Untitled Event';
    }
    
    try {
      safeEventType = safeStringValue(eventType, 'event');
    } catch (e) {
      safeEventType = 'event';
    }
    
    try {
      safeTimezone = safeStringValue(timezone, 'UTC');
    } catch (e) {
      safeTimezone = 'UTC';
    }
    
    try {
      safeRecurrencePattern = safeStringValue(recurrencePattern, 'none');
    } catch (e) {
      safeRecurrencePattern = 'none';
    }
    
    try {
      safeColor = safeStringValue(color, '#3b82f6');
    } catch (e) {
      safeColor = '#3b82f6';
    }
    
    try {
      safePrivacy = safeStringValue(privacy, 'private');
    } catch (e) {
      safePrivacy = 'private';
    }
    
    return {
      if (id != null) 'id': id,
      'title': safeTitle,
      if (description != null && description!.isNotEmpty) 'description': description,
      'event_type': safeEventType,
      'start_time': startTime.toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toIso8601String(),
      'all_day': allDay,
      'timezone': safeTimezone,
      if (location != null && location!.isNotEmpty) 'location': location,
      if (meetingLink != null && meetingLink!.isNotEmpty) 'meeting_link': meetingLink,
      'is_recurring': isRecurring,
      'recurrence_pattern': safeRecurrencePattern,
      if (recurrenceEndDate != null)
        'recurrence_end_date': recurrenceEndDate!.toIso8601String(),
      if (recurrenceCount != null) 'recurrence_count': recurrenceCount,
      'color': safeColor,
      'privacy': safePrivacy,
      if (attendeeIds != null && attendeeIds!.isNotEmpty) 'attendees': attendeeIds,
      if (externalAttendees != null && externalAttendees!.isNotEmpty) 'external_attendees': externalAttendees,
      if (relatedMeeting != null) 'related_meeting': relatedMeeting,
      if (relatedStudyGroupEvent != null)
        'related_study_group_event': relatedStudyGroupEvent,
      if (reminders != null && reminders!.isNotEmpty)
        'reminders': reminders!.map((e) => e.toJson()).toList(),
    };
  }

  CalendarEvent copyWith({
    int? id,
    String? title,
    String? description,
    String? eventType,
    DateTime? startTime,
    DateTime? endTime,
    bool? allDay,
    String? timezone,
    String? location,
    String? meetingLink,
    bool? isRecurring,
    String? recurrencePattern,
    DateTime? recurrenceEndDate,
    int? recurrenceCount,
    String? color,
    String? privacy,
    int? createdBy,
    String? createdByName,
    String? createdByEmail,
    List<int>? attendeeIds,
    List<Map<String, dynamic>>? attendeesDetails,
    List<String>? externalAttendees,
    bool? isCancelled,
    DateTime? cancelledAt,
    int? cancelledBy,
    int? relatedMeeting,
    int? relatedStudyGroupEvent,
    List<EventReminder>? reminders,
    bool? isUpcoming,
    bool? isPast,
    bool? isOngoing,
    int? durationMinutes,
    String? eventTypeDisplay,
    String? privacyDisplay,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      allDay: allDay ?? this.allDay,
      timezone: timezone ?? this.timezone,
      location: location ?? this.location,
      meetingLink: meetingLink ?? this.meetingLink,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      recurrenceCount: recurrenceCount ?? this.recurrenceCount,
      color: color ?? this.color,
      privacy: privacy ?? this.privacy,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      attendeesDetails: attendeesDetails ?? this.attendeesDetails,
      externalAttendees: externalAttendees ?? this.externalAttendees,
      isCancelled: isCancelled ?? this.isCancelled,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      relatedMeeting: relatedMeeting ?? this.relatedMeeting,
      relatedStudyGroupEvent: relatedStudyGroupEvent ?? this.relatedStudyGroupEvent,
      reminders: reminders ?? this.reminders,
      isUpcoming: isUpcoming ?? this.isUpcoming,
      isPast: isPast ?? this.isPast,
      isOngoing: isOngoing ?? this.isOngoing,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      eventTypeDisplay: eventTypeDisplay ?? this.eventTypeDisplay,
      privacyDisplay: privacyDisplay ?? this.privacyDisplay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const List<String> eventTypes = [
    'meeting',
    'deadline',
    'class',
    'exam',
    'reminder',
    'event',
    'study_session',
    'other',
  ];

  static const List<String> recurrencePatterns = [
    'none',
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  static const List<String> privacyLevels = [
    'public',
    'private',
    'shared',
  ];

  /// Check if event has reminders enabled
  bool? get hasReminder {
    if (reminders == null || reminders!.isEmpty) return false;
    return reminders!.any((r) => !r.isSent);
  }
}

class EventReminder {
  final int? id;
  final int event;
  final int user;
  final String reminderType;
  final int minutesBefore;
  final bool isSent;
  final DateTime? sentAt;
  final DateTime? reminderTime;
  final bool shouldSend;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EventReminder({
    this.id,
    required this.event,
    required this.user,
    required this.reminderType,
    required this.minutesBefore,
    this.isSent = false,
    this.sentAt,
    this.reminderTime,
    this.shouldSend = false,
    this.createdAt,
    this.updatedAt,
  });

  factory EventReminder.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is List) return value.length;
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }
    
    // Handle event and user fields - they might be objects with an 'id' field or direct ints
    int eventId;
    if (json['event'] is Map<String, dynamic>) {
      eventId = safeInt(json['event']?['id']);
    } else {
      eventId = safeInt(json['event']);
    }
    
    int userId;
    if (json['user'] is Map<String, dynamic>) {
      userId = safeInt(json['user']?['id']);
    } else {
      userId = safeInt(json['user']);
    }
    
    return EventReminder(
      id: json['id'] as int?,
      event: eventId,
      user: userId,
      reminderType: json['reminder_type'] as String? ?? 'notification',
      minutesBefore: safeInt(json['minutes_before']),
      isSent: json['is_sent'] as bool? ?? false,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      reminderTime: json['reminder_time'] != null
          ? DateTime.parse(json['reminder_time'] as String)
          : null,
      shouldSend: json['should_send'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    // Ensure all required String fields have non-null values
    final safeReminderType = reminderType.isNotEmpty ? reminderType : 'notification';
    
    // Backend expects 'type' and 'minutes_before' keys for reminders (not 'reminder_type')
    return {
      'type': safeReminderType,
      'minutes_before': minutesBefore,
    };
  }

  static const List<String> reminderTypes = [
    'notification',
    'email',
    'sms',
  ];

  static const List<int> reminderTimings = [
    0, 5, 15, 30, 60, 120, 1440, 2880,
  ];
}

class GoogleCalendarSync {
  final int? id;
  final int user;
  final bool isConnected;
  final String? calendarId;
  final DateTime? lastSyncAt;
  final bool syncEnabled;
  final String syncDirection;
  final bool isTokenExpired;
  final bool needsSync;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GoogleCalendarSync({
    this.id,
    required this.user,
    this.isConnected = false,
    this.calendarId,
    this.lastSyncAt,
    this.syncEnabled = true,
    this.syncDirection = 'bidirectional',
    this.isTokenExpired = false,
    this.needsSync = false,
    this.createdAt,
    this.updatedAt,
  });

  factory GoogleCalendarSync.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is List) return value.length;
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }
    
    // Handle user field - it might be an object with an 'id' field or a direct int
    int userId;
    if (json['user'] is Map<String, dynamic>) {
      userId = safeInt(json['user']?['id']);
    } else {
      userId = safeInt(json['user']);
    }
    
    return GoogleCalendarSync(
      id: json['id'] as int?,
      user: userId,
      isConnected: json['is_connected'] as bool? ?? false,
      calendarId: json['calendar_id'] as String?,
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'] as String)
          : null,
      syncEnabled: json['sync_enabled'] as bool? ?? true,
      syncDirection: json['sync_direction'] as String? ?? 'bidirectional',
      isTokenExpired: json['is_token_expired'] as bool? ?? false,
      needsSync: json['needs_sync'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user': user,
      'is_connected': isConnected,
      if (calendarId != null) 'calendar_id': calendarId,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt!.toIso8601String(),
      'sync_enabled': syncEnabled,
      'sync_direction': syncDirection,
    };
  }

  static const List<String> syncDirections = [
    'bidirectional',
    'to_google',
    'from_google',
  ];
}

