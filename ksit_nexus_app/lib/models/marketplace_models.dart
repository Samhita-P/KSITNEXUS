class MarketplaceItem {
  final int? id;
  final String itemType;
  final String title;
  final String description;
  final String status;
  final int postedBy;
  final String? postedByName;
  final String? location;
  final String? pickupLocation;
  final String? dropoffLocation;
  final String? contactPhone;
  final String? contactEmail;
  final List<String> images;
  final List<String> tags;
  final bool isActive;
  final int viewsCount;
  final BookListing? bookListing;
  final RideListing? rideListing;
  final LostFoundItem? lostFoundItem;
  final bool isFavorited;
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketplaceItem({
    this.id,
    required this.itemType,
    required this.title,
    required this.description,
    required this.status,
    required this.postedBy,
    this.postedByName,
    this.location,
    this.pickupLocation,
    this.dropoffLocation,
    this.contactPhone,
    this.contactEmail,
    required this.images,
    required this.tags,
    required this.isActive,
    required this.viewsCount,
    this.bookListing,
    this.rideListing,
    this.lostFoundItem,
    required this.isFavorited,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceItem(
      id: json['id'] as int?,
      itemType: json['item_type'] as String? ?? 'other',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'available',
      postedBy: json['posted_by'] as int? ?? 0,
      postedByName: json['posted_by_name'] as String?,
      location: json['location'] as String?,
      pickupLocation: json['pickup_location'] as String?,
      dropoffLocation: json['dropoff_location'] as String?,
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      images: (json['images'] as List?)?.cast<String>() ?? [],
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      isActive: json['is_active'] as bool? ?? true,
      viewsCount: json['views_count'] as int? ?? 0,
      bookListing: json['book_listing'] != null
          ? BookListing.fromJson(json['book_listing'] as Map<String, dynamic>)
          : null,
      rideListing: json['ride_listing'] != null
          ? RideListing.fromJson(json['ride_listing'] as Map<String, dynamic>)
          : null,
      lostFoundItem: json['lost_found_item'] != null
          ? LostFoundItem.fromJson(json['lost_found_item'] as Map<String, dynamic>)
          : null,
      isFavorited: json['is_favorited'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class BookListing {
  final int? id;
  final String? isbn;
  final String author;
  final String? publisher;
  final String? edition;
  final String condition;
  final int? year;
  final double price;
  final bool negotiable;
  final String? courseCode;
  final int? semester;

  BookListing({
    this.id,
    this.isbn,
    required this.author,
    this.publisher,
    this.edition,
    required this.condition,
    this.year,
    required this.price,
    required this.negotiable,
    this.courseCode,
    this.semester,
  });

  factory BookListing.fromJson(Map<String, dynamic> json) {
    return BookListing(
      id: json['id'] as int?,
      isbn: json['isbn'] as String?,
      author: json['author'] as String? ?? '',
      publisher: json['publisher'] as String?,
      edition: json['edition'] as String?,
      condition: json['condition'] as String? ?? 'good',
      year: json['year'] as int?,
      price: json['price'] != null ? (json['price'] is num ? (json['price'] as num).toDouble() : double.parse(json['price'].toString())) : 0.0,
      negotiable: json['negotiable'] as bool? ?? true,
      courseCode: json['course_code'] as String?,
      semester: json['semester'] as int?,
    );
  }
}

class RideListing {
  final int? id;
  final String rideType;
  final DateTime departureDate;
  final DateTime? returnDate;
  final String departureLocation;
  final String destination;
  final int availableSeats;
  final int totalSeats;
  final String? availableSeatsDisplay;
  final double pricePerSeat;
  final String? vehicleType;
  final String? vehicleNumber;
  final bool luggageSpace;
  final bool smokingAllowed;
  final bool petsAllowed;

  RideListing({
    this.id,
    required this.rideType,
    required this.departureDate,
    this.returnDate,
    required this.departureLocation,
    required this.destination,
    required this.availableSeats,
    required this.totalSeats,
    this.availableSeatsDisplay,
    required this.pricePerSeat,
    this.vehicleType,
    this.vehicleNumber,
    required this.luggageSpace,
    required this.smokingAllowed,
    required this.petsAllowed,
  });

  factory RideListing.fromJson(Map<String, dynamic> json) {
    return RideListing(
      id: json['id'],
      rideType: json['ride_type'],
      departureDate: DateTime.parse(json['departure_date']),
      returnDate: json['return_date'] != null
          ? DateTime.parse(json['return_date'])
          : null,
      departureLocation: json['departure_location'],
      destination: json['destination'],
      availableSeats: json['available_seats'],
      totalSeats: json['total_seats'],
      availableSeatsDisplay: json['available_seats_display'],
      pricePerSeat: json['price_per_seat'] != null
          ? (json['price_per_seat'] is num 
              ? (json['price_per_seat'] as num).toDouble() 
              : double.tryParse(json['price_per_seat'].toString()) ?? 0.0)
          : 0.0,
      vehicleType: json['vehicle_type'],
      vehicleNumber: json['vehicle_number'],
      luggageSpace: json['luggage_space'],
      smokingAllowed: json['smoking_allowed'],
      petsAllowed: json['pets_allowed'],
    );
  }
}

class LostFoundItem {
  final int? id;
  final String category;
  final String? brand;
  final String? color;
  final String? size;
  final String? foundLocation;
  final DateTime? foundDate;
  final double? rewardOffered;
  final bool verificationRequired;
  final String? verificationDetails;

  LostFoundItem({
    this.id,
    required this.category,
    this.brand,
    this.color,
    this.size,
    this.foundLocation,
    this.foundDate,
    this.rewardOffered,
    required this.verificationRequired,
    this.verificationDetails,
  });

  factory LostFoundItem.fromJson(Map<String, dynamic> json) {
    return LostFoundItem(
      id: json['id'],
      category: json['category'],
      brand: json['brand'],
      color: json['color'],
      size: json['size'],
      foundLocation: json['found_location'],
      foundDate: json['found_date'] != null
          ? DateTime.parse(json['found_date'])
          : null,
      rewardOffered: json['reward_offered'] != null
          ? (json['reward_offered'] is num 
              ? (json['reward_offered'] as num).toDouble() 
              : double.tryParse(json['reward_offered'].toString()))
          : null,
      verificationRequired: json['verification_required'],
      verificationDetails: json['verification_details'],
    );
  }
}

class MarketplaceTransaction {
  final int? id;
  final MarketplaceItem marketplaceItem;
  final int buyer;
  final String? buyerName;
  final int? seller;
  final String? sellerName;
  final String transactionType;
  final String status;
  final String? message;
  final int seatsRequested;
  final double? agreedPrice;
  final String? meetingLocation;
  final DateTime? meetingDate;
  final DateTime? completedAt;
  final int? rating;
  final String? review;
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketplaceTransaction({
    this.id,
    required this.marketplaceItem,
    required this.buyer,
    this.buyerName,
    this.seller,
    this.sellerName,
    required this.transactionType,
    required this.status,
    this.message,
    required this.seatsRequested,
    this.agreedPrice,
    this.meetingLocation,
    this.meetingDate,
    this.completedAt,
    this.rating,
    this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MarketplaceTransaction.fromJson(Map<String, dynamic> json) {
    return MarketplaceTransaction(
      id: json['id'],
      marketplaceItem: MarketplaceItem.fromJson(json['marketplace_item']),
      buyer: json['buyer'],
      buyerName: json['buyer_name'],
      seller: json['seller'],
      sellerName: json['seller_name'],
      transactionType: json['transaction_type'],
      status: json['status'],
      message: json['message'],
      seatsRequested: json['seats_requested'],
      agreedPrice: json['agreed_price'] != null
          ? (json['agreed_price'] is num 
              ? (json['agreed_price'] as num).toDouble() 
              : double.tryParse(json['agreed_price'].toString()) ?? 0.0)
          : null,
      meetingLocation: json['meeting_location'],
      meetingDate: json['meeting_date'] != null
          ? DateTime.parse(json['meeting_date'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      rating: json['rating'],
      review: json['review'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}




