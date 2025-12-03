/// Models for Faculty & Admin Tools

class Case {
  final int id;
  final String caseId;
  final String caseType;
  final String title;
  final String description;
  final int? assignedTo;
  final String? assignedToName;
  final int? createdBy;
  final String? createdByName;
  final String status;
  final String priority;
  final int priorityScore;
  final int slaTargetHours;
  final DateTime slaStartTime;
  final DateTime? slaBreachTime;
  final String slaStatus;
  final List<String> tags;
  final String? category;
  final String? department;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final double? resolutionTimeHours;
  final int viewsCount;
  final int updatesCount;
  final int? responseTimeMinutes;
  final List<CaseUpdate>? updates;
  final DateTime createdAt;
  final DateTime updatedAt;

  Case({
    required this.id,
    required this.caseId,
    required this.caseType,
    required this.title,
    required this.description,
    this.assignedTo,
    this.assignedToName,
    this.createdBy,
    this.createdByName,
    required this.status,
    required this.priority,
    required this.priorityScore,
    required this.slaTargetHours,
    required this.slaStartTime,
    this.slaBreachTime,
    required this.slaStatus,
    required this.tags,
    this.category,
    this.department,
    this.resolvedAt,
    this.resolutionNotes,
    this.resolutionTimeHours,
    required this.viewsCount,
    required this.updatesCount,
    this.responseTimeMinutes,
    this.updates,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Case.fromJson(Map<String, dynamic> json) {
    return Case(
      id: json['id'],
      caseId: json['case_id'],
      caseType: json['case_type'],
      title: json['title'],
      description: json['description'],
      assignedTo: json['assigned_to'],
      assignedToName: json['assigned_to_name'],
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      status: json['status'],
      priority: json['priority'],
      priorityScore: json['priority_score'],
      slaTargetHours: json['sla_target_hours'],
      slaStartTime: DateTime.parse(json['sla_start_time']),
      slaBreachTime: json['sla_breach_time'] != null
          ? DateTime.parse(json['sla_breach_time'])
          : null,
      slaStatus: json['sla_status'],
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'],
      department: json['department'],
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      resolutionNotes: json['resolution_notes'],
      resolutionTimeHours: json['resolution_time_hours']?.toDouble(),
      viewsCount: json['views_count'],
      updatesCount: json['updates_count'],
      responseTimeMinutes: json['response_time_minutes'],
      updates: json['updates'] != null
          ? (json['updates'] as List)
              .map((e) => CaseUpdate.fromJson(e))
              .toList()
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_id': caseId,
      'case_type': caseType,
      'title': title,
      'description': description,
      'assigned_to': assignedTo,
      'status': status,
      'priority': priority,
      'tags': tags,
      'category': category,
      'department': department,
    };
  }
}

class CaseUpdate {
  final int id;
  final int caseId;
  final int? updatedBy;
  final String? updatedByName;
  final String comment;
  final bool isInternal;
  final String? statusChange;
  final String? priorityChange;
  final DateTime createdAt;
  final DateTime updatedAt;

  CaseUpdate({
    required this.id,
    required this.caseId,
    this.updatedBy,
    this.updatedByName,
    required this.comment,
    required this.isInternal,
    this.statusChange,
    this.priorityChange,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CaseUpdate.fromJson(Map<String, dynamic> json) {
    return CaseUpdate(
      id: json['id'],
      caseId: json['case'],
      updatedBy: json['updated_by'],
      updatedByName: json['updated_by_name'],
      comment: json['comment'],
      isInternal: json['is_internal'],
      statusChange: json['status_change'],
      priorityChange: json['priority_change'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class Broadcast {
  final int id;
  final String title;
  final String content;
  final String broadcastType;
  final String priority;
  final Map<String, dynamic> richContent;
  final List<String> attachments;
  final String targetAudience;
  final List<int>? targetUsers;
  final List<String> targetDepartments;
  final List<String> targetCourses;
  final DateTime? scheduledAt;
  final DateTime? expiresAt;
  final bool isPublished;
  final DateTime? publishedAt;
  final int? createdBy;
  final String? createdByName;
  final int viewsCount;
  final int engagementCount;
  final int? targetUsersCount;
  final double? engagementRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Broadcast({
    required this.id,
    required this.title,
    required this.content,
    required this.broadcastType,
    required this.priority,
    required this.richContent,
    required this.attachments,
    required this.targetAudience,
    this.targetUsers,
    required this.targetDepartments,
    required this.targetCourses,
    this.scheduledAt,
    this.expiresAt,
    required this.isPublished,
    this.publishedAt,
    this.createdBy,
    this.createdByName,
    required this.viewsCount,
    required this.engagementCount,
    this.targetUsersCount,
    this.engagementRate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Broadcast.fromJson(Map<String, dynamic> json) {
    return Broadcast(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      broadcastType: json['broadcast_type'],
      priority: json['priority'],
      richContent: Map<String, dynamic>.from(json['rich_content'] ?? {}),
      attachments: List<String>.from(json['attachments'] ?? []),
      targetAudience: json['target_audience'],
      targetUsers: json['target_users'] != null
          ? List<int>.from(json['target_users'])
          : null,
      targetDepartments: List<String>.from(json['target_departments'] ?? []),
      targetCourses: List<String>.from(json['target_courses'] ?? []),
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      isPublished: json['is_published'],
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      viewsCount: json['views_count'],
      engagementCount: json['engagement_count'],
      targetUsersCount: json['target_users_count'],
      engagementRate: json['engagement_rate']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class PredictiveMetric {
  final int id;
  final String metricType;
  final double value;
  final double? predictedValue;
  final double? confidence;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  PredictiveMetric({
    required this.id,
    required this.metricType,
    required this.value,
    this.predictedValue,
    this.confidence,
    required this.periodStart,
    required this.periodEnd,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PredictiveMetric.fromJson(Map<String, dynamic> json) {
    return PredictiveMetric(
      id: json['id'],
      metricType: json['metric_type'],
      value: json['value'].toDouble(),
      predictedValue: json['predicted_value']?.toDouble(),
      confidence: json['confidence']?.toDouble(),
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: DateTime.parse(json['period_end']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class OperationalAlert {
  final int id;
  final String alertType;
  final String severity;
  final String title;
  final String message;
  final int? relatedMetric;
  final int? relatedCase;
  final bool isAcknowledged;
  final int? acknowledgedBy;
  final String? acknowledgedByName;
  final DateTime? acknowledgedAt;
  final bool isResolved;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  OperationalAlert({
    required this.id,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.message,
    this.relatedMetric,
    this.relatedCase,
    required this.isAcknowledged,
    this.acknowledgedBy,
    this.acknowledgedByName,
    this.acknowledgedAt,
    required this.isResolved,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OperationalAlert.fromJson(Map<String, dynamic> json) {
    return OperationalAlert(
      id: json['id'],
      alertType: json['alert_type'],
      severity: json['severity'],
      title: json['title'],
      message: json['message'],
      relatedMetric: json['related_metric'],
      relatedCase: json['related_case'],
      isAcknowledged: json['is_acknowledged'],
      acknowledgedBy: json['acknowledged_by'],
      acknowledgedByName: json['acknowledged_by_name'],
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'])
          : null,
      isResolved: json['is_resolved'],
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class CaseAnalytics {
  final int totalCases;
  final int resolvedCases;
  final int activeCases;
  final double resolutionRate;
  final Map<String, dynamic> slaMetrics;
  final double avgResolutionHours;
  final List<Map<String, dynamic>> byPriority;
  final List<Map<String, dynamic>> byStatus;

  CaseAnalytics({
    required this.totalCases,
    required this.resolvedCases,
    required this.activeCases,
    required this.resolutionRate,
    required this.slaMetrics,
    required this.avgResolutionHours,
    required this.byPriority,
    required this.byStatus,
  });

  factory CaseAnalytics.fromJson(Map<String, dynamic> json) {
    return CaseAnalytics(
      totalCases: json['total_cases'],
      resolvedCases: json['resolved_cases'],
      activeCases: json['active_cases'],
      resolutionRate: json['resolution_rate'].toDouble(),
      slaMetrics: Map<String, dynamic>.from(json['sla_metrics']),
      avgResolutionHours: json['avg_resolution_hours'].toDouble(),
      byPriority: List<Map<String, dynamic>>.from(json['by_priority']),
      byStatus: List<Map<String, dynamic>>.from(json['by_status']),
    );
  }
}

















