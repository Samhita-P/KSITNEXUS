// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Meeting _$MeetingFromJson(Map<String, dynamic> json) => Meeting(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  type: json['type'] as String,
  location: json['location'] as String,
  scheduledDate: DateTime.parse(json['scheduled_date'] as String),
  duration: json['duration'] as String,
  audience: json['audience'] as String,
  notes: json['notes'] as String?,
  status: json['status'] as String,
  createdBy: (json['created_by'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$MeetingToJson(Meeting instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'type': instance.type,
  'location': instance.location,
  'scheduled_date': instance.scheduledDate.toIso8601String(),
  'duration': instance.duration,
  'audience': instance.audience,
  'notes': instance.notes,
  'status': instance.status,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

MeetingCreateRequest _$MeetingCreateRequestFromJson(
  Map<String, dynamic> json,
) => MeetingCreateRequest(
  title: json['title'] as String,
  description: json['description'] as String,
  type: json['type'] as String,
  location: json['location'] as String,
  scheduledDate: DateTime.parse(json['scheduled_date'] as String),
  duration: json['duration'] as String,
  audience: json['audience'] as String,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$MeetingCreateRequestToJson(
  MeetingCreateRequest instance,
) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
  'type': instance.type,
  'location': instance.location,
  'scheduled_date': instance.scheduledDate.toIso8601String(),
  'duration': instance.duration,
  'audience': instance.audience,
  'notes': instance.notes,
};

MeetingUpdateRequest _$MeetingUpdateRequestFromJson(
  Map<String, dynamic> json,
) => MeetingUpdateRequest(
  title: json['title'] as String?,
  description: json['description'] as String?,
  type: json['type'] as String?,
  location: json['location'] as String?,
  scheduledDate:
      json['scheduled_date'] == null
          ? null
          : DateTime.parse(json['scheduled_date'] as String),
  duration: json['duration'] as String?,
  audience: json['audience'] as String?,
  notes: json['notes'] as String?,
  status: json['status'] as String?,
);

Map<String, dynamic> _$MeetingUpdateRequestToJson(
  MeetingUpdateRequest instance,
) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
  'type': instance.type,
  'location': instance.location,
  'scheduled_date': instance.scheduledDate?.toIso8601String(),
  'duration': instance.duration,
  'audience': instance.audience,
  'notes': instance.notes,
  'status': instance.status,
};
