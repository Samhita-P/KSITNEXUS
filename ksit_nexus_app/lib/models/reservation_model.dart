import 'package:json_annotation/json_annotation.dart';

part 'reservation_model.g.dart';

@JsonSerializable()
class ReadingRoom {
  final int id;
  final String? name;
  final String? description;
  final String? location;
  final int capacity;
  final bool isActive;
  final bool hasWifi;
  final bool hasChargingPoints;
  final bool hasAirConditioning;
  final String? openingTime;
  final String? closingTime;
  final int maxReservationHours;
  final int advanceBookingHours;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Seat>? seats;
  
  // New availability fields
  final int totalSeats;
  final int availableSeats;
  final int occupiedSeats;

  ReadingRoom({
    required this.id,
    this.name,
    this.description,
    this.location,
    required this.capacity,
    required this.isActive,
    required this.hasWifi,
    required this.hasChargingPoints,
    required this.hasAirConditioning,
    this.openingTime,
    this.closingTime,
    required this.maxReservationHours,
    required this.advanceBookingHours,
    required this.createdAt,
    required this.updatedAt,
    this.seats,
    required this.totalSeats,
    required this.availableSeats,
    required this.occupiedSeats,
  });

  factory ReadingRoom.fromJson(Map<String, dynamic> json) => _$ReadingRoomFromJson(json);
  Map<String, dynamic> toJson() => _$ReadingRoomToJson(this);

  // Use the backend-provided counts instead of calculating from seats
  double get occupancyRate => totalSeats > 0 ? (occupiedSeats / totalSeats) * 100 : 0;
  
  // Helper methods for seat status
  bool get hasAvailableSeats => availableSeats > 0;
  bool get isFullyOccupied => availableSeats == 0 && totalSeats > 0;
}

@JsonSerializable()
class Seat {
  final int id;
  final String seatNumber;
  final String seatType;
  final bool isActive;
  final bool hasPowerOutlet;
  final bool hasLight;
  final ReadingRoom? room; // Add room property
  final DateTime createdAt;
  final DateTime updatedAt;
  final Reservation? currentReservation;
  final int? rowNumber;
  final int? columnNumber;
  final int? tableNumber;
  final bool isAvailableNow;
  final String status; // 'free', 'occupied', 'reserved'

  Seat({
    required this.id,
    required this.seatNumber,
    required this.seatType,
    required this.isActive,
    required this.hasPowerOutlet,
    required this.hasLight,
    this.room,
    required this.createdAt,
    required this.updatedAt,
    this.currentReservation,
    this.rowNumber,
    this.columnNumber,
    this.tableNumber,
    required this.isAvailableNow,
    required this.status,
  });

  // Add missing properties
  int get roomId => room?.id ?? 0;
  bool get isAvailable => status == 'free';
  bool get isReserved => status == 'reserved';
  bool get isMaintenance => status == 'maintenance';
  String? get position => '${rowNumber ?? 0},${columnNumber ?? 0}';

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id'] as int,
      seatNumber: json['seatNumber'] as String? ?? '',
      seatType: json['seatType'] as String? ?? 'single',
      isActive: json['isActive'] as bool? ?? true,
      hasPowerOutlet: json['hasPowerOutlet'] as bool? ?? false,
      hasLight: json['hasLight'] as bool? ?? true,
      room: json['room'] != null ? ReadingRoom.fromJson(json['room'] as Map<String, dynamic>) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
      currentReservation: json['currentReservation'] != null ? Reservation.fromJson(json['currentReservation'] as Map<String, dynamic>) : null,
      rowNumber: json['rowNumber'] as int?,
      columnNumber: json['columnNumber'] as int?,
      tableNumber: json['tableNumber'] as int?,
      isAvailableNow: json['isAvailable'] as bool? ?? true,
      status: json['status'] as String? ?? 'free',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'seat_number': seatNumber,
      'seat_type': seatType,
      'is_available': isAvailable,
      'is_reserved': isReserved,
      'is_maintenance': isMaintenance,
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get seatTypeDisplayName {
    switch (seatType) {
      case 'single': return 'Single';
      case 'double': return 'Double';
      case 'group': return 'Group';
      case 'computer': return 'Computer';
      case 'study': return 'Study';
      default: return seatType;
    }
  }
}

@JsonSerializable()
class Reservation {
  final int id;
  final int userId;
  final String? userName;
  final int roomId;
  final String? roomName;
  final int? seatId;
  final String? seatNumber;
  final Seat? seat; // Add seat property
  final DateTime startTime;
  final DateTime endTime;
  final String? status;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ReservationHistory> history;
  final double durationHours;
  final String? purpose;

  Reservation({
    required this.id,
    required this.userId,
    this.userName,
    required this.roomId,
    this.roomName,
    this.seatId,
    this.seatNumber,
    this.seat,
    required this.startTime,
    required this.endTime,
    this.status,
    this.checkedInAt,
    this.checkedOutAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.history,
    required this.durationHours,
    this.purpose,
  });

  // Add missing properties
  ReadingRoom? get room => null; // This should be populated from the API

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String?,
      roomId: json['roomId'] as int,
      roomName: json['roomName'] as String?,
      seatId: json['seatId'] as int?,
      seatNumber: json['seatNumber'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: json['status'] as String?,
      checkedInAt: json['checkedInAt'] != null ? DateTime.parse(json['checkedInAt'] as String) : null,
      checkedOutAt: json['checkedOutAt'] != null ? DateTime.parse(json['checkedOutAt'] as String) : null,
      purpose: json['purpose'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      history: (json['history'] as List?)?.map((e) => ReservationHistory.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      durationHours: (json['durationHours'] as num?)?.toDouble() ?? 0.0,
      seat: json['seat'] != null ? Seat.fromJson(json['seat'] as Map<String, dynamic>) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'room_id': roomId,
      'seat_id': seatId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      'purpose': purpose,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'room': room?.toJson(),
      'seat': seat?.toJson(),
    };
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'checked_in': return 'Checked In';
      case 'checked_out': return 'Checked Out';
      case 'cancelled': return 'Cancelled';
      case 'expired': return 'Expired';
      default: return status ?? 'Unknown';
    }
  }

  bool get isActive => status == 'confirmed' || status == 'checked_in';
  bool get isCompleted => status == 'checked_out' || status == 'cancelled' || status == 'expired';
  bool get isUpcoming => status == 'pending' || status == 'confirmed';
  bool get isCurrent => status == 'checked_in';
  bool get canCheckIn => status == 'confirmed' && DateTime.now().isAfter(startTime.subtract(const Duration(minutes: 15)));
  bool get canCheckOut => status == 'checked_in';
  bool get canCancel => status == 'pending' || status == 'confirmed';

  Duration get duration => endTime.difference(startTime);
  String get durationFormatted {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

@JsonSerializable()
class ReservationHistory {
  final int id;
  final int reservationId;
  final String? status;
  final String? comment;
  final String? updatedBy;
  final DateTime updatedAt;

  ReservationHistory({
    required this.id,
    required this.reservationId,
    this.status,
    this.comment,
    this.updatedBy,
    required this.updatedAt,
  });

  // Add missing properties
  DateTime get changedAt => updatedAt;
  int? get changedBy => int.tryParse(updatedBy ?? '');
  String? get reason => comment;

  factory ReservationHistory.fromJson(Map<String, dynamic> json) {
    return ReservationHistory(
      id: json['id'] as int,
      reservationId: json['reservationId'] as int,
      status: json['status'] as String?,
      comment: json['comment'] as String?,
      updatedBy: json['updatedBy'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reservation_id': reservationId,
      'status': status,
      'changed_at': changedAt.toIso8601String(),
      'changed_by': changedBy,
      'reason': reason,
    };
  }
}

@JsonSerializable()
class SeatAvailability {
  final int seatId;
  final String seatNumber;
  final bool isAvailable;
  final DateTime? nextAvailableTime;
  final Reservation? currentReservation;

  SeatAvailability({
    required this.seatId,
    required this.seatNumber,
    required this.isAvailable,
    this.nextAvailableTime,
    this.currentReservation,
  });

  // Add missing properties
  int get roomId => 0;
  int get totalSeats => 0;
  int get availableSeats => isAvailable ? 1 : 0;
  int get reservedSeats => isAvailable ? 0 : 1;
  int get maintenanceSeats => 0;
  DateTime get lastUpdated => DateTime.now();

  factory SeatAvailability.fromJson(Map<String, dynamic> json) {
    return SeatAvailability(
      seatId: json['seatId'] as int,
      seatNumber: json['seatNumber'] as String? ?? '',
      isAvailable: json['isAvailable'] as bool,
      nextAvailableTime: json['nextAvailableTime'] != null ? DateTime.parse(json['nextAvailableTime'] as String) : null,
      currentReservation: json['currentReservation'] != null ? Reservation.fromJson(json['currentReservation'] as Map<String, dynamic>) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'total_seats': totalSeats,
      'available_seats': availableSeats,
      'reserved_seats': reservedSeats,
      'maintenance_seats': maintenanceSeats,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

@JsonSerializable()
class ReservationCreateRequest {
  final int roomId;
  final int? seatId;
  final List<int>? seatIds;
  final DateTime startTime;
  final DateTime endTime;
  final String? purpose;
  final String? notes;

  ReservationCreateRequest({
    required this.roomId,
    this.seatId,
    this.seatIds,
    required this.startTime,
    required this.endTime,
    this.purpose,
    this.notes,
  });

  factory ReservationCreateRequest.fromJson(Map<String, dynamic> json) {
    return ReservationCreateRequest(
      roomId: json['room_id'] as int,
      seatId: json['seat_id'] as int?,
      seatIds: json['seatIds'] != null ? List<int>.from(json['seatIds'] as List) : null,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      notes: json['notes'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'roomId': roomId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
    
    // Include seatId or seatIds based on what's provided
    if (seatIds != null && seatIds!.isNotEmpty) {
      map['seatIds'] = seatIds!;
    } else if (seatId != null) {
      map['seatId'] = seatId!;
    }
    
    if (purpose != null) map['purpose'] = purpose!;
    if (notes != null) map['notes'] = notes!;
    
    return map;
  }
}

@JsonSerializable()
class ReservationUpdateRequest {
  final DateTime? startTime;
  final DateTime? endTime;
  final String? notes;

  ReservationUpdateRequest({
    this.startTime,
    this.endTime,
    this.notes,
  });

  // Add missing properties
  String? get status => null;
  String? get purpose => null;

  factory ReservationUpdateRequest.fromJson(Map<String, dynamic> json) {
    return ReservationUpdateRequest(
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time'] as String) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      notes: json['notes'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status,
      'purpose': purpose,
      'notes': notes,
    };
  }
}

@JsonSerializable()
class ReservationStats {
  final int totalReservations;
  final int activeReservations;
  final int completedReservations;
  final int cancelledReservations;
  final Map<String, int> reservationsByStatus;
  final Map<String, int> reservationsByRoom;
  final List<Reservation> recentReservations;
  final double averageReservationDuration;

  ReservationStats({
    required this.totalReservations,
    required this.activeReservations,
    required this.completedReservations,
    required this.cancelledReservations,
    required this.reservationsByStatus,
    required this.reservationsByRoom,
    required this.recentReservations,
    required this.averageReservationDuration,
  });

  // Add missing properties
  int get totalRooms => 0;
  int get totalSeats => 0;
  int get availableSeats => 0;
  double get occupancyRate => 0.0;
  String? get mostPopularRoom => null;
  List<String> get peakHours => [];

  factory ReservationStats.fromJson(Map<String, dynamic> json) {
    return ReservationStats(
      totalReservations: json['total_reservations'] as int,
      activeReservations: json['active_reservations'] as int,
      completedReservations: json['completed_reservations'] as int,
      cancelledReservations: json['cancelled_reservations'] as int,
      reservationsByStatus: Map<String, int>.from(json['reservations_by_status'] as Map? ?? {}),
      reservationsByRoom: Map<String, int>.from(json['reservations_by_room'] as Map? ?? {}),
      recentReservations: (json['recent_reservations'] as List?)?.map((e) => Reservation.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      averageReservationDuration: (json['average_reservation_duration'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'total_reservations': totalReservations,
      'active_reservations': activeReservations,
      'completed_reservations': completedReservations,
      'cancelled_reservations': cancelledReservations,
      'total_rooms': totalRooms,
      'total_seats': totalSeats,
      'available_seats': availableSeats,
      'occupancy_rate': occupancyRate,
      'average_reservation_duration': averageReservationDuration,
      'most_popular_room': mostPopularRoom,
      'peak_hours': peakHours,
    };
  }
}

@JsonSerializable()
class ReservationFilter {
  final int? roomId;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  ReservationFilter({
    this.roomId,
    this.status,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });

  // Add missing property
  int? get userId => null;

  factory ReservationFilter.fromJson(Map<String, dynamic> json) {
    return ReservationFilter(
      roomId: json['room_id'] as int?,
      status: json['status'] as String?,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      searchQuery: json['search_query'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'user_id': userId,
    };
  }

  bool get hasFilters => 
    roomId != null ||
    status != null ||
    startDate != null ||
    endDate != null ||
    (searchQuery != null && searchQuery!.isNotEmpty);
}
