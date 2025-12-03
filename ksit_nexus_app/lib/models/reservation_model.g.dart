// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReadingRoom _$ReadingRoomFromJson(Map<String, dynamic> json) => ReadingRoom(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  description: json['description'] as String?,
  location: json['location'] as String?,
  capacity: (json['capacity'] as num).toInt(),
  isActive: json['isActive'] as bool,
  hasWifi: json['hasWifi'] as bool,
  hasChargingPoints: json['hasChargingPoints'] as bool,
  hasAirConditioning: json['hasAirConditioning'] as bool,
  openingTime: json['openingTime'] as String?,
  closingTime: json['closingTime'] as String?,
  maxReservationHours: (json['maxReservationHours'] as num).toInt(),
  advanceBookingHours: (json['advanceBookingHours'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  seats:
      (json['seats'] as List<dynamic>?)
          ?.map((e) => Seat.fromJson(e as Map<String, dynamic>))
          .toList(),
  totalSeats: (json['totalSeats'] as num).toInt(),
  availableSeats: (json['availableSeats'] as num).toInt(),
  occupiedSeats: (json['occupiedSeats'] as num).toInt(),
);

Map<String, dynamic> _$ReadingRoomToJson(ReadingRoom instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'location': instance.location,
      'capacity': instance.capacity,
      'isActive': instance.isActive,
      'hasWifi': instance.hasWifi,
      'hasChargingPoints': instance.hasChargingPoints,
      'hasAirConditioning': instance.hasAirConditioning,
      'openingTime': instance.openingTime,
      'closingTime': instance.closingTime,
      'maxReservationHours': instance.maxReservationHours,
      'advanceBookingHours': instance.advanceBookingHours,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'seats': instance.seats,
      'totalSeats': instance.totalSeats,
      'availableSeats': instance.availableSeats,
      'occupiedSeats': instance.occupiedSeats,
    };

Seat _$SeatFromJson(Map<String, dynamic> json) => Seat(
  id: (json['id'] as num).toInt(),
  seatNumber: json['seatNumber'] as String,
  seatType: json['seatType'] as String,
  isActive: json['isActive'] as bool,
  hasPowerOutlet: json['hasPowerOutlet'] as bool,
  hasLight: json['hasLight'] as bool,
  room:
      json['room'] == null
          ? null
          : ReadingRoom.fromJson(json['room'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  currentReservation:
      json['currentReservation'] == null
          ? null
          : Reservation.fromJson(
            json['currentReservation'] as Map<String, dynamic>,
          ),
  rowNumber: (json['rowNumber'] as num?)?.toInt(),
  columnNumber: (json['columnNumber'] as num?)?.toInt(),
  isAvailableNow: json['isAvailableNow'] as bool,
  status: json['status'] as String,
);

Map<String, dynamic> _$SeatToJson(Seat instance) => <String, dynamic>{
  'id': instance.id,
  'seatNumber': instance.seatNumber,
  'seatType': instance.seatType,
  'isActive': instance.isActive,
  'hasPowerOutlet': instance.hasPowerOutlet,
  'hasLight': instance.hasLight,
  'room': instance.room,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'currentReservation': instance.currentReservation,
  'rowNumber': instance.rowNumber,
  'columnNumber': instance.columnNumber,
  'isAvailableNow': instance.isAvailableNow,
  'status': instance.status,
};

Reservation _$ReservationFromJson(Map<String, dynamic> json) => Reservation(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  userName: json['userName'] as String?,
  roomId: (json['roomId'] as num).toInt(),
  roomName: json['roomName'] as String?,
  seatId: (json['seatId'] as num?)?.toInt(),
  seatNumber: json['seatNumber'] as String?,
  seat:
      json['seat'] == null
          ? null
          : Seat.fromJson(json['seat'] as Map<String, dynamic>),
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
  status: json['status'] as String?,
  checkedInAt:
      json['checkedInAt'] == null
          ? null
          : DateTime.parse(json['checkedInAt'] as String),
  checkedOutAt:
      json['checkedOutAt'] == null
          ? null
          : DateTime.parse(json['checkedOutAt'] as String),
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  history:
      (json['history'] as List<dynamic>)
          .map((e) => ReservationHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
  durationHours: (json['durationHours'] as num).toDouble(),
  purpose: json['purpose'] as String?,
);

Map<String, dynamic> _$ReservationToJson(Reservation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'userName': instance.userName,
      'roomId': instance.roomId,
      'roomName': instance.roomName,
      'seatId': instance.seatId,
      'seatNumber': instance.seatNumber,
      'seat': instance.seat,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'status': instance.status,
      'checkedInAt': instance.checkedInAt?.toIso8601String(),
      'checkedOutAt': instance.checkedOutAt?.toIso8601String(),
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'history': instance.history,
      'durationHours': instance.durationHours,
      'purpose': instance.purpose,
    };

ReservationHistory _$ReservationHistoryFromJson(Map<String, dynamic> json) =>
    ReservationHistory(
      id: (json['id'] as num).toInt(),
      reservationId: (json['reservationId'] as num).toInt(),
      status: json['status'] as String?,
      comment: json['comment'] as String?,
      updatedBy: json['updatedBy'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ReservationHistoryToJson(ReservationHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reservationId': instance.reservationId,
      'status': instance.status,
      'comment': instance.comment,
      'updatedBy': instance.updatedBy,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

SeatAvailability _$SeatAvailabilityFromJson(Map<String, dynamic> json) =>
    SeatAvailability(
      seatId: (json['seatId'] as num).toInt(),
      seatNumber: json['seatNumber'] as String,
      isAvailable: json['isAvailable'] as bool,
      nextAvailableTime:
          json['nextAvailableTime'] == null
              ? null
              : DateTime.parse(json['nextAvailableTime'] as String),
      currentReservation:
          json['currentReservation'] == null
              ? null
              : Reservation.fromJson(
                json['currentReservation'] as Map<String, dynamic>,
              ),
    );

Map<String, dynamic> _$SeatAvailabilityToJson(SeatAvailability instance) =>
    <String, dynamic>{
      'seatId': instance.seatId,
      'seatNumber': instance.seatNumber,
      'isAvailable': instance.isAvailable,
      'nextAvailableTime': instance.nextAvailableTime?.toIso8601String(),
      'currentReservation': instance.currentReservation,
    };

ReservationCreateRequest _$ReservationCreateRequestFromJson(
  Map<String, dynamic> json,
) => ReservationCreateRequest(
  roomId: (json['roomId'] as num).toInt(),
  seatId: (json['seatId'] as num).toInt(),
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
  purpose: json['purpose'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$ReservationCreateRequestToJson(
  ReservationCreateRequest instance,
) => <String, dynamic>{
  'roomId': instance.roomId,
  'seatId': instance.seatId,
  'startTime': instance.startTime.toIso8601String(),
  'endTime': instance.endTime.toIso8601String(),
  'purpose': instance.purpose,
  'notes': instance.notes,
};

ReservationUpdateRequest _$ReservationUpdateRequestFromJson(
  Map<String, dynamic> json,
) => ReservationUpdateRequest(
  startTime:
      json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
  endTime:
      json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$ReservationUpdateRequestToJson(
  ReservationUpdateRequest instance,
) => <String, dynamic>{
  'startTime': instance.startTime?.toIso8601String(),
  'endTime': instance.endTime?.toIso8601String(),
  'notes': instance.notes,
};

ReservationStats _$ReservationStatsFromJson(Map<String, dynamic> json) =>
    ReservationStats(
      totalReservations: (json['totalReservations'] as num).toInt(),
      activeReservations: (json['activeReservations'] as num).toInt(),
      completedReservations: (json['completedReservations'] as num).toInt(),
      cancelledReservations: (json['cancelledReservations'] as num).toInt(),
      reservationsByStatus: Map<String, int>.from(
        json['reservationsByStatus'] as Map,
      ),
      reservationsByRoom: Map<String, int>.from(
        json['reservationsByRoom'] as Map,
      ),
      recentReservations:
          (json['recentReservations'] as List<dynamic>)
              .map((e) => Reservation.fromJson(e as Map<String, dynamic>))
              .toList(),
      averageReservationDuration:
          (json['averageReservationDuration'] as num).toDouble(),
    );

Map<String, dynamic> _$ReservationStatsToJson(ReservationStats instance) =>
    <String, dynamic>{
      'totalReservations': instance.totalReservations,
      'activeReservations': instance.activeReservations,
      'completedReservations': instance.completedReservations,
      'cancelledReservations': instance.cancelledReservations,
      'reservationsByStatus': instance.reservationsByStatus,
      'reservationsByRoom': instance.reservationsByRoom,
      'recentReservations': instance.recentReservations,
      'averageReservationDuration': instance.averageReservationDuration,
    };

ReservationFilter _$ReservationFilterFromJson(Map<String, dynamic> json) =>
    ReservationFilter(
      roomId: (json['roomId'] as num?)?.toInt(),
      status: json['status'] as String?,
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

Map<String, dynamic> _$ReservationFilterToJson(ReservationFilter instance) =>
    <String, dynamic>{
      'roomId': instance.roomId,
      'status': instance.status,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'searchQuery': instance.searchQuery,
    };
