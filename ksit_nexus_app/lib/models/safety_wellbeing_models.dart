/// Models for Safety & Wellbeing

class EmergencyAlert {
  final int id;
  final String alertId;
  final String alertType;
  final String severity;
  final String status;
  final String title;
  final String description;
  final String? location;
  final double? latitude;
  final double? longitude;
  final int? createdBy;
  final String? createdByName;
  final int? respondedBy;
  final String? respondedByName;
  final String? responseNotes;
  final DateTime? resolvedAt;
  final bool broadcastToAll;
  final List<String> targetDepartments;
  final List<String> targetBuildings;
  final int viewsCount;
  final int acknowledgmentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyAlert({
    required this.id,
    required this.alertId,
    required this.alertType,
    required this.severity,
    required this.status,
    required this.title,
    required this.description,
    this.location,
    this.latitude,
    this.longitude,
    this.createdBy,
    this.createdByName,
    this.respondedBy,
    this.respondedByName,
    this.responseNotes,
    this.resolvedAt,
    required this.broadcastToAll,
    required this.targetDepartments,
    required this.targetBuildings,
    required this.viewsCount,
    required this.acknowledgmentsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'],
      alertId: json['alert_id'],
      alertType: json['alert_type'],
      severity: json['severity'],
      status: json['status'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      respondedBy: json['responded_by'],
      respondedByName: json['responded_by_name'],
      responseNotes: json['response_notes'],
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      broadcastToAll: json['broadcast_to_all'],
      targetDepartments: List<String>.from(json['target_departments'] ?? []),
      targetBuildings: List<String>.from(json['target_buildings'] ?? []),
      viewsCount: json['views_count'],
      acknowledgmentsCount: json['acknowledgments_count'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class EmergencyContact {
  final int id;
  final String name;
  final String contactType;
  final String phoneNumber;
  final String? alternatePhone;
  final String? email;
  final String? location;
  final String? description;
  final bool isActive;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.contactType,
    required this.phoneNumber,
    this.alternatePhone,
    this.email,
    this.location,
    this.description,
    required this.isActive,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      contactType: json['contact_type'],
      phoneNumber: json['phone_number'],
      alternatePhone: json['alternate_phone'],
      email: json['email'],
      location: json['location'],
      description: json['description'],
      isActive: json['is_active'],
      priority: json['priority'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class UserPersonalEmergencyContact {
  final int id;
  final String name;
  final String contactType;
  final String phoneNumber;
  final String? alternatePhone;
  final String? email;
  final String? relationship;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPersonalEmergencyContact({
    required this.id,
    required this.name,
    required this.contactType,
    required this.phoneNumber,
    this.alternatePhone,
    this.email,
    this.relationship,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPersonalEmergencyContact.fromJson(Map<String, dynamic> json) {
    return UserPersonalEmergencyContact(
      id: json['id'],
      name: json['name'],
      contactType: json['contact_type'],
      phoneNumber: json['phone_number'],
      alternatePhone: json['alternate_phone'],
      email: json['email'],
      relationship: json['relationship'],
      isPrimary: json['is_primary'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'contact_type': contactType,
      'phone_number': phoneNumber,
      'alternate_phone': alternatePhone,
      'email': email,
      'relationship': relationship,
      'is_primary': isPrimary,
    };
  }
}

class CounselingService {
  final int id;
  final String name;
  final String serviceType;
  final String description;
  final String? counselorName;
  final String? counselorEmail;
  final String? counselorPhone;
  final String? location;
  final Map<String, dynamic> availableHours;
  final bool isActive;
  final bool isAnonymous;
  final int? appointmentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  CounselingService({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.description,
    this.counselorName,
    this.counselorEmail,
    this.counselorPhone,
    this.location,
    required this.availableHours,
    required this.isActive,
    required this.isAnonymous,
    this.appointmentsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CounselingService.fromJson(Map<String, dynamic> json) {
    return CounselingService(
      id: json['id'],
      name: json['name'],
      serviceType: json['service_type'],
      description: json['description'],
      counselorName: json['counselor_name'],
      counselorEmail: json['counselor_email'],
      counselorPhone: json['counselor_phone'],
      location: json['location'],
      availableHours: Map<String, dynamic>.from(json['available_hours'] ?? {}),
      isActive: json['is_active'],
      isAnonymous: json['is_anonymous'],
      appointmentsCount: json['appointments_count'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class CounselingAppointment {
  final int id;
  final String appointmentId;
  final int serviceId;
  final String? serviceName;
  final int? userId;
  final String? userName;
  final bool isAnonymous;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status;
  final String urgency;
  final String? contactEmail;
  final String? contactPhone;
  final String? preferredName;
  final String reason;
  final String? notes;
  final String? counselorNotes;
  final DateTime? completedAt;
  final bool followUpRequired;
  final DateTime? followUpDate;
  final int? rating;
  final String? feedback;
  final DateTime createdAt;
  final DateTime updatedAt;

  CounselingAppointment({
    required this.id,
    required this.appointmentId,
    required this.serviceId,
    this.serviceName,
    this.userId,
    this.userName,
    required this.isAnonymous,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    required this.urgency,
    this.contactEmail,
    this.contactPhone,
    this.preferredName,
    required this.reason,
    this.notes,
    this.counselorNotes,
    this.completedAt,
    required this.followUpRequired,
    this.followUpDate,
    this.rating,
    this.feedback,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CounselingAppointment.fromJson(Map<String, dynamic> json) {
    return CounselingAppointment(
      id: json['id'],
      appointmentId: json['appointment_id'],
      serviceId: json['service'],
      serviceName: json['service_name'],
      userId: json['user'],
      userName: json['user_name'],
      isAnonymous: json['is_anonymous'],
      scheduledAt: DateTime.parse(json['scheduled_at']),
      durationMinutes: json['duration_minutes'],
      status: json['status'],
      urgency: json['urgency'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      preferredName: json['preferred_name'],
      reason: json['reason'],
      notes: json['notes'],
      counselorNotes: json['counselor_notes'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      followUpRequired: json['follow_up_required'],
      followUpDate: json['follow_up_date'] != null
          ? DateTime.parse(json['follow_up_date'])
          : null,
      rating: json['rating'],
      feedback: json['feedback'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class AnonymousCheckIn {
  final int id;
  final String checkInId;
  final String checkInType;
  final int moodLevel;
  final String? message;
  final String? contactEmail;
  final String? contactPhone;
  final bool allowFollowUp;
  final int? respondedBy;
  final String? respondedByName;
  final String? responseNotes;
  final DateTime? responseSentAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnonymousCheckIn({
    required this.id,
    required this.checkInId,
    required this.checkInType,
    required this.moodLevel,
    this.message,
    this.contactEmail,
    this.contactPhone,
    required this.allowFollowUp,
    this.respondedBy,
    this.respondedByName,
    this.responseNotes,
    this.responseSentAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnonymousCheckIn.fromJson(Map<String, dynamic> json) {
    return AnonymousCheckIn(
      id: json['id'],
      checkInId: json['check_in_id'],
      checkInType: json['check_in_type'],
      moodLevel: json['mood_level'],
      message: json['message'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      allowFollowUp: json['allow_follow_up'],
      respondedBy: json['responded_by'],
      respondedByName: json['responded_by_name'],
      responseNotes: json['response_notes'],
      responseSentAt: json['response_sent_at'] != null
          ? DateTime.parse(json['response_sent_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class SafetyResource {
  final int id;
  final String title;
  final String resourceType;
  final String description;
  final String? content;
  final String? url;
  final String? file;
  final List<String> tags;
  final bool isFeatured;
  final bool isActive;
  final int viewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  SafetyResource({
    required this.id,
    required this.title,
    required this.resourceType,
    required this.description,
    this.content,
    this.url,
    this.file,
    required this.tags,
    required this.isFeatured,
    required this.isActive,
    required this.viewsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SafetyResource.fromJson(Map<String, dynamic> json) {
    return SafetyResource(
      id: json['id'],
      title: json['title'],
      resourceType: json['resource_type'],
      description: json['description'],
      content: json['content'],
      url: json['url'],
      file: json['file'],
      tags: List<String>.from(json['tags'] ?? []),
      isFeatured: json['is_featured'],
      isActive: json['is_active'],
      viewsCount: json['views_count'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}


