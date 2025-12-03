import 'package:json_annotation/json_annotation.dart';

part 'meeting_model.g.dart';

@JsonSerializable()
class Meeting {
  final int? id;
  final String title;
  final String description;
  final String type;
  final String location;
  @JsonKey(name: 'scheduled_date')
  final DateTime scheduledDate;
  final String duration;
  final String audience;
  final String? notes;
  final String status;
  @JsonKey(name: 'created_by')
  final int? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Meeting({
    this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.location,
    required this.scheduledDate,
    required this.duration,
    required this.audience,
    this.notes,
    required this.status,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) => _$MeetingFromJson(json);
  
  Map<String, dynamic> toJson() => _$MeetingToJson(this);

  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'Scheduled';
      case 'ongoing':
        return 'Ongoing';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'faculty':
        return 'Faculty Meeting';
      case 'department':
        return 'Department Meeting';
      case 'committee':
        return 'Committee Meeting';
      case 'student':
        return 'Student Meeting';
      case 'other':
        return 'Other';
      default:
        return type;
    }
  }

  String get audienceDisplayName {
    switch (audience.toLowerCase()) {
      case 'all_faculty':
        return 'All Faculty';
      case 'department':
        return 'Department Only';
      case 'committee':
        return 'Committee Members';
      case 'specific':
        return 'Specific People';
      default:
        return audience;
    }
  }

  bool get isUpcoming => scheduledDate.isAfter(DateTime.now());
  bool get isPast => scheduledDate.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
           scheduledDate.month == now.month &&
           scheduledDate.day == now.day;
  }
}

@JsonSerializable()
class MeetingCreateRequest {
  final String title;
  final String description;
  final String type;
  final String location;
  @JsonKey(name: 'scheduled_date')
  final DateTime scheduledDate;
  final String duration;
  final String audience;
  final String? notes;

  const MeetingCreateRequest({
    required this.title,
    required this.description,
    required this.type,
    required this.location,
    required this.scheduledDate,
    required this.duration,
    required this.audience,
    this.notes,
  });

  factory MeetingCreateRequest.fromJson(Map<String, dynamic> json) => 
      _$MeetingCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$MeetingCreateRequestToJson(this);
}

@JsonSerializable()
class MeetingUpdateRequest {
  final String? title;
  final String? description;
  final String? type;
  final String? location;
  @JsonKey(name: 'scheduled_date')
  final DateTime? scheduledDate;
  final String? duration;
  final String? audience;
  final String? notes;
  final String? status;

  const MeetingUpdateRequest({
    this.title,
    this.description,
    this.type,
    this.location,
    this.scheduledDate,
    this.duration,
    this.audience,
    this.notes,
    this.status,
  });

  factory MeetingUpdateRequest.fromJson(Map<String, dynamic> json) => 
      _$MeetingUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$MeetingUpdateRequestToJson(this);
}
