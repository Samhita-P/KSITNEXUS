import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Complaint {
  final int id;
  final String complaintId;
  final String category;
  final String title;
  final String? description;
  final String urgency;
  final String status;
  final String? contactEmail;
  @JsonKey(name: 'contact_phone')
  final String? contactPhone;
  final String? location;
  @JsonKey(name: 'assigned_to')
  final String? assignedTo;
  @JsonKey(name: 'assigned_to_name')
  final String? assignedToName;
  final DateTime submittedAt;
  final DateTime updatedAt;
  final List<ComplaintAttachment>? attachments;
  final List<ComplaintUpdate>? updates;

  Complaint({
    required this.id,
    required this.complaintId,
    required this.category,
    required this.title,
    this.description,
    required this.urgency,
    required this.status,
    this.contactEmail,
    this.contactPhone,
    this.location,
    this.assignedTo,
    this.assignedToName,
    required this.submittedAt,
    required this.updatedAt,
    this.attachments,
    this.updates,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as int,
      complaintId: json['complaint_id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      urgency: json['urgency'] as String,
      status: json['status'] as String,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      location: json['location'] as String?,
      assignedTo: json['assigned_to'] as String?,
      assignedToName: json['assigned_to_name'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      attachments: json['attachments'] != null 
          ? (json['attachments'] as List).map((e) => ComplaintAttachment.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      updates: json['updates'] != null 
          ? (json['updates'] as List).map((e) => ComplaintUpdate.fromJson(e as Map<String, dynamic>)).toList()
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaint_id': complaintId,
      'category': category,
      'title': title,
      'description': description,
      'urgency': urgency,
      'status': status,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'location': location,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'submitted_at': submittedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'attachments': attachments?.map((e) => e.toJson()).toList(),
      'updates': updates?.map((e) => e.toJson()).toList(),
    };
  }

  String get categoryDisplayName {
    switch (category) {
      case 'academic': return 'Academic';
      case 'infrastructure': return 'Infrastructure';
      case 'hostel': return 'Hostel';
      case 'cafeteria': return 'Cafeteria';
      case 'transport': return 'Transport';
      case 'library': return 'Library';
      case 'sports': return 'Sports';
      case 'other': return 'Other';
      default: return category;
    }
  }

  String get urgencyDisplayName {
    switch (urgency) {
      case 'low': return 'Low';
      case 'medium': return 'Medium';
      case 'high': return 'High';
      case 'urgent': return 'Urgent';
      default: return urgency;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'submitted': return 'Submitted';
      case 'under_review': return 'Under Review';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'rejected': return 'Rejected';
      case 'closed': return 'Closed';
      default: return status;
    }
  }

  bool get isResolved => status == 'resolved' || status == 'closed';
  bool get isInProgress => status == 'under_review' || status == 'in_progress';
}

@JsonSerializable()
class ComplaintAttachment {
  final int id;
  final String fileName;
  final String? fileUrl;
  final String? fileType;
  final int fileSize;
  final DateTime uploadedAt;

  ComplaintAttachment({
    required this.id,
    required this.fileName,
    this.fileUrl,
    this.fileType,
    required this.fileSize,
    required this.uploadedAt,
  });

  factory ComplaintAttachment.fromJson(Map<String, dynamic> json) {
    return ComplaintAttachment(
      id: json['id'] as int,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String?,
      fileType: json['file_type'] as String?,
      fileSize: json['file_size'] as int,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}

@JsonSerializable()
class ComplaintUpdate {
  final int id;
  final String status;
  final String? comment;
  final String? updatedBy;
  final DateTime updatedAt;

  ComplaintUpdate({
    required this.id,
    required this.status,
    this.comment,
    this.updatedBy,
    required this.updatedAt,
  });

  factory ComplaintUpdate.fromJson(Map<String, dynamic> json) {
    return ComplaintUpdate(
      id: json['id'] as int,
      status: json['status'] as String,
      comment: json['comment'] as String?,
      updatedBy: json['updated_by'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'comment': comment,
      'updated_by': updatedBy,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get statusDisplayName {
    switch (status) {
      case 'submitted': return 'Submitted';
      case 'under_review': return 'Under Review';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'rejected': return 'Rejected';
      case 'closed': return 'Closed';
      default: return status;
    }
  }
}

@JsonSerializable()
class ComplaintCreateRequest {
  final String category;
  final String title;
  final String? description;
  final String urgency;
  final String? contactEmail;
  final String? contactPhone;
  final String? location;
  final List<String>? attachments;

  ComplaintCreateRequest({
    required this.category,
    required this.title,
    this.description,
    required this.urgency,
    this.contactEmail,
    this.contactPhone,
    this.location,
    this.attachments,
  });

  factory ComplaintCreateRequest.fromJson(Map<String, dynamic> json) {
    return ComplaintCreateRequest(
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      urgency: json['urgency'] as String,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      location: json['location'] as String?,
      attachments: json['attachments'] != null 
          ? (json['attachments'] as List).map((e) => e as String).toList()
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'title': title,
      'description': description,
      'urgency': urgency,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'location': location,
      'attachments': attachments,
    };
  }
}

@JsonSerializable()
class ComplaintUpdateRequest {
  final String? status;
  final String? comment;
  final String? assignedTo;

  ComplaintUpdateRequest({
    this.status,
    this.comment,
    this.assignedTo,
  });

  factory ComplaintUpdateRequest.fromJson(Map<String, dynamic> json) {
    return ComplaintUpdateRequest(
      status: json['status'] as String?,
      comment: json['comment'] as String?,
      assignedTo: json['assigned_to'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'comment': comment,
      'assigned_to': assignedTo,
    };
  }
}

@JsonSerializable()
class ComplaintStats {
  final int totalComplaints;
  final int pendingComplaints;
  final int resolvedComplaints;
  final int urgentComplaints;
  final Map<String, int> complaintsByCategory;
  final Map<String, int> complaintsByStatus;

  ComplaintStats({
    required this.totalComplaints,
    required this.pendingComplaints,
    required this.resolvedComplaints,
    required this.urgentComplaints,
    required this.complaintsByCategory,
    required this.complaintsByStatus,
  });

  factory ComplaintStats.fromJson(Map<String, dynamic> json) {
    return ComplaintStats(
      totalComplaints: json['total_complaints'] as int,
      pendingComplaints: json['pending_complaints'] as int,
      resolvedComplaints: json['resolved_complaints'] as int,
      urgentComplaints: json['urgent_complaints'] as int,
      complaintsByCategory: Map<String, int>.from(json['complaints_by_category'] as Map),
      complaintsByStatus: Map<String, int>.from(json['complaints_by_status'] as Map),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'total_complaints': totalComplaints,
      'pending_complaints': pendingComplaints,
      'resolved_complaints': resolvedComplaints,
      'urgent_complaints': urgentComplaints,
      'complaints_by_category': complaintsByCategory,
      'complaints_by_status': complaintsByStatus,
    };
  }
}