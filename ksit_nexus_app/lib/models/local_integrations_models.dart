/// Models for Local Integrations

class Hostel {
  final int id;
  final String name;
  final String code;
  final String? address;
  final int totalRooms;
  final int totalCapacity;
  final int currentOccupancy;
  final List<String> amenities;
  final bool isActive;
  final double? availabilityRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Hostel({
    required this.id,
    required this.name,
    required this.code,
    this.address,
    required this.totalRooms,
    required this.totalCapacity,
    required this.currentOccupancy,
    required this.amenities,
    required this.isActive,
    this.availabilityRate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Hostel.fromJson(Map<String, dynamic> json) {
    return Hostel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      address: json['address'],
      totalRooms: json['total_rooms'],
      totalCapacity: json['total_capacity'],
      currentOccupancy: json['current_occupancy'],
      amenities: List<String>.from(json['amenities'] ?? []),
      isActive: json['is_active'],
      availabilityRate: json['availability_rate']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class HostelRoom {
  final int id;
  final int hostelId;
  final String? hostelName;
  final String roomNumber;
  final String roomType;
  final int capacity;
  final int currentOccupancy;
  final int? floor;
  final List<String> amenities;
  final bool isAvailable;
  final bool isOccupied;
  final DateTime createdAt;
  final DateTime updatedAt;

  HostelRoom({
    required this.id,
    required this.hostelId,
    this.hostelName,
    required this.roomNumber,
    required this.roomType,
    required this.capacity,
    required this.currentOccupancy,
    this.floor,
    required this.amenities,
    required this.isAvailable,
    required this.isOccupied,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HostelRoom.fromJson(Map<String, dynamic> json) {
    return HostelRoom(
      id: json['id'],
      hostelId: json['hostel'],
      hostelName: json['hostel_name'],
      roomNumber: json['room_number'],
      roomType: json['room_type'],
      capacity: json['capacity'],
      currentOccupancy: json['current_occupancy'],
      floor: json['floor'],
      amenities: List<String>.from(json['amenities'] ?? []),
      isAvailable: json['is_available'],
      isOccupied: json['is_occupied'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class HostelBooking {
  final int id;
  final String bookingId;
  final int userId;
  final String? userName;
  final int hostelId;
  final String? hostelName;
  final int? roomId;
  final String? roomNumber;
  final DateTime checkInDate;
  final DateTime? checkOutDate;
  final String status;
  final String? specialRequests;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  HostelBooking({
    required this.id,
    required this.bookingId,
    required this.userId,
    this.userName,
    required this.hostelId,
    this.hostelName,
    this.roomId,
    this.roomNumber,
    required this.checkInDate,
    this.checkOutDate,
    required this.status,
    this.specialRequests,
    this.confirmedAt,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HostelBooking.fromJson(Map<String, dynamic> json) {
    return HostelBooking(
      id: json['id'],
      bookingId: json['booking_id'],
      userId: json['user'],
      userName: json['user_name'],
      hostelId: json['hostel'],
      hostelName: json['hostel_name'],
      roomId: json['room'],
      roomNumber: json['room_number'],
      checkInDate: DateTime.parse(json['check_in_date']),
      checkOutDate: json['check_out_date'] != null
          ? DateTime.parse(json['check_out_date'])
          : null,
      status: json['status'],
      specialRequests: json['special_requests'],
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      cancellationReason: json['cancellation_reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class Cafeteria {
  final int id;
  final String name;
  final String code;
  final String location;
  final int capacity;
  final int currentOccupancy;
  final Map<String, dynamic> operatingHours;
  final bool isActive;
  final double? occupancyRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cafeteria({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    required this.capacity,
    required this.currentOccupancy,
    required this.operatingHours,
    required this.isActive,
    this.occupancyRate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cafeteria.fromJson(Map<String, dynamic> json) {
    return Cafeteria(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      location: json['location'],
      capacity: json['capacity'],
      currentOccupancy: json['current_occupancy'],
      operatingHours: Map<String, dynamic>.from(json['operating_hours'] ?? {}),
      isActive: json['is_active'],
      occupancyRate: json['occupancy_rate']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class CafeteriaMenu {
  final int id;
  final int cafeteriaId;
  final String? cafeteriaName;
  final String name;
  final String? description;
  final String mealType;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final bool isVegetarian;
  final bool isVegan;
  final List<String> allergens;
  final Map<String, dynamic> nutritionalInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  CafeteriaMenu({
    required this.id,
    required this.cafeteriaId,
    this.cafeteriaName,
    required this.name,
    this.description,
    required this.mealType,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.isVegetarian,
    required this.isVegan,
    required this.allergens,
    required this.nutritionalInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CafeteriaMenu.fromJson(Map<String, dynamic> json) {
    return CafeteriaMenu(
      id: json['id'],
      cafeteriaId: json['cafeteria'],
      cafeteriaName: json['cafeteria_name'],
      name: json['name'],
      description: json['description'],
      mealType: json['meal_type'],
      price: json['price'].toDouble(),
      imageUrl: json['image_url'],
      isAvailable: json['is_available'],
      isVegetarian: json['is_vegetarian'],
      isVegan: json['is_vegan'],
      allergens: List<String>.from(json['allergens'] ?? []),
      nutritionalInfo: Map<String, dynamic>.from(json['nutritional_info'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class CafeteriaBooking {
  final int id;
  final String bookingId;
  final int userId;
  final String? userName;
  final int cafeteriaId;
  final String? cafeteriaName;
  final DateTime bookingDate;
  final String bookingTime;
  final int numberOfGuests;
  final String? specialRequests;
  final String status;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  CafeteriaBooking({
    required this.id,
    required this.bookingId,
    required this.userId,
    this.userName,
    required this.cafeteriaId,
    this.cafeteriaName,
    required this.bookingDate,
    required this.bookingTime,
    required this.numberOfGuests,
    this.specialRequests,
    required this.status,
    this.confirmedAt,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CafeteriaBooking.fromJson(Map<String, dynamic> json) {
    return CafeteriaBooking(
      id: json['id'],
      bookingId: json['booking_id'],
      userId: json['user'],
      userName: json['user_name'],
      cafeteriaId: json['cafeteria'],
      cafeteriaName: json['cafeteria_name'],
      bookingDate: DateTime.parse(json['booking_date']),
      bookingTime: json['booking_time'],
      numberOfGuests: json['number_of_guests'],
      specialRequests: json['special_requests'],
      status: json['status'],
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class CafeteriaOrder {
  final int id;
  final String orderId;
  final int userId;
  final String? userName;
  final int cafeteriaId;
  final String? cafeteriaName;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String status;
  final String? specialInstructions;
  final DateTime? pickupTime;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  CafeteriaOrder({
    required this.id,
    required this.orderId,
    required this.userId,
    this.userName,
    required this.cafeteriaId,
    this.cafeteriaName,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.specialInstructions,
    this.pickupTime,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CafeteriaOrder.fromJson(Map<String, dynamic> json) {
    return CafeteriaOrder(
      id: json['id'],
      orderId: json['order_id'],
      userId: json['user'],
      userName: json['user_name'],
      cafeteriaId: json['cafeteria'],
      cafeteriaName: json['cafeteria_name'],
      items: List<Map<String, dynamic>>.from(json['items'] ?? []),
      totalAmount: json['total_amount'].toDouble(),
      status: json['status'],
      specialInstructions: json['special_instructions'],
      pickupTime: json['pickup_time'] != null
          ? DateTime.parse(json['pickup_time'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class TransportRoute {
  final int id;
  final String name;
  final String routeCode;
  final String routeType;
  final String startLocation;
  final String endLocation;
  final List<Map<String, dynamic>> stops;
  final double? distanceKm;
  final int? estimatedDurationMinutes;
  final bool isActive;
  final int? activeVehiclesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransportRoute({
    required this.id,
    required this.name,
    required this.routeCode,
    required this.routeType,
    required this.startLocation,
    required this.endLocation,
    required this.stops,
    this.distanceKm,
    this.estimatedDurationMinutes,
    required this.isActive,
    this.activeVehiclesCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransportRoute.fromJson(Map<String, dynamic> json) {
    return TransportRoute(
      id: json['id'],
      name: json['name'],
      routeCode: json['route_code'],
      routeType: json['route_type'],
      startLocation: json['start_location'],
      endLocation: json['end_location'],
      stops: List<Map<String, dynamic>>.from(json['stops'] ?? []),
      distanceKm: json['distance_km']?.toDouble(),
      estimatedDurationMinutes: json['estimated_duration_minutes'],
      isActive: json['is_active'],
      activeVehiclesCount: json['active_vehicles_count'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class TransportSchedule {
  final int id;
  final int routeId;
  final String? routeName;
  final String departureTime;
  final String? arrivalTime;
  final int dayOfWeek;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransportSchedule({
    required this.id,
    required this.routeId,
    this.routeName,
    required this.departureTime,
    this.arrivalTime,
    required this.dayOfWeek,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransportSchedule.fromJson(Map<String, dynamic> json) {
    return TransportSchedule(
      id: json['id'],
      routeId: json['route'],
      routeName: json['route_name'],
      departureTime: json['departure_time'],
      arrivalTime: json['arrival_time'],
      dayOfWeek: json['day_of_week'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class TransportVehicle {
  final int id;
  final String vehicleNumber;
  final String vehicleType;
  final int capacity;
  final int? currentRouteId;
  final String? routeName;
  final String? currentLocation;
  final double? latitude;
  final double? longitude;
  final String status;
  final DateTime lastUpdated;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransportVehicle({
    required this.id,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.capacity,
    this.currentRouteId,
    this.routeName,
    this.currentLocation,
    this.latitude,
    this.longitude,
    required this.status,
    required this.lastUpdated,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransportVehicle.fromJson(Map<String, dynamic> json) {
    return TransportVehicle(
      id: json['id'],
      vehicleNumber: json['vehicle_number'],
      vehicleType: json['vehicle_type'],
      capacity: json['capacity'],
      currentRouteId: json['current_route'],
      routeName: json['route_name'],
      currentLocation: json['current_location'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      status: json['status'],
      lastUpdated: DateTime.parse(json['last_updated']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class TransportLiveInfo {
  final int id;
  final int vehicleId;
  final String? vehicleNumber;
  final int routeId;
  final String? routeName;
  final String? currentStop;
  final String? nextStop;
  final double latitude;
  final double longitude;
  final double? speedKmh;
  final int? estimatedArrivalMinutes;
  final int currentPassengers;
  final bool isOnTime;
  final DateTime lastUpdated;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransportLiveInfo({
    required this.id,
    required this.vehicleId,
    this.vehicleNumber,
    required this.routeId,
    this.routeName,
    this.currentStop,
    this.nextStop,
    required this.latitude,
    required this.longitude,
    this.speedKmh,
    this.estimatedArrivalMinutes,
    required this.currentPassengers,
    required this.isOnTime,
    required this.lastUpdated,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransportLiveInfo.fromJson(Map<String, dynamic> json) {
    return TransportLiveInfo(
      id: json['id'],
      vehicleId: json['vehicle'],
      vehicleNumber: json['vehicle_number'],
      routeId: json['route'],
      routeName: json['route_name'],
      currentStop: json['current_stop'],
      nextStop: json['next_stop'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      speedKmh: json['speed_kmh']?.toDouble(),
      estimatedArrivalMinutes: json['estimated_arrival_minutes'],
      currentPassengers: json['current_passengers'],
      isOnTime: json['is_on_time'],
      lastUpdated: DateTime.parse(json['last_updated']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

















