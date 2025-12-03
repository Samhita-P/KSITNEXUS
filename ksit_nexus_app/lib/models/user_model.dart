import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class User {
  final int id;
  final String username;
  final String email;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  @JsonKey(name: 'user_type')
  final String? userType;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  final bool isVerified;
  final DateTime dateJoined;
  final StudentProfile? studentProfile;
  final FacultyProfile? facultyProfile;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.userType,
    this.phoneNumber,
    required this.isVerified,
    required this.dateJoined,
    this.studentProfile,
    this.facultyProfile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      userType: json['user_type'] as String?,
      phoneNumber: json['phone_number'] as String?,
      isVerified: json['is_verified'] as bool,
      dateJoined: DateTime.parse(json['date_joined'] as String),
      studentProfile: json['student_profile'] != null 
          ? StudentProfile.fromJson(json['student_profile'] as Map<String, dynamic>)
          : null,
      facultyProfile: json['faculty_profile'] != null 
          ? FacultyProfile.fromJson(json['faculty_profile'] as Map<String, dynamic>)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'user_type': userType,
      'phone_number': phoneNumber,
      'is_verified': isVerified,
      'date_joined': dateJoined.toIso8601String(),
      'student_profile': studentProfile?.toJson(),
      'faculty_profile': facultyProfile?.toJson(),
    };
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  String get displayName => fullName.isNotEmpty ? fullName : username;
  bool get isStudent => userType == 'student';
  bool get isFaculty => userType == 'faculty';
  bool get isAdmin => userType == 'admin';
}

@JsonSerializable()
class StudentProfile {
  final int id;
  final String studentId;
  final String? usn;
  final int yearOfStudy;
  final String branch;
  final String? section;
  final String? profilePicture;
  final String? bio;
  final List<String> interests;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentProfile({
    required this.id,
    required this.studentId,
    this.usn,
    required this.yearOfStudy,
    required this.branch,
    this.section,
    this.profilePicture,
    this.bio,
    required this.interests,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as int,
      studentId: json['student_id'] as String,
      usn: json['usn'] as String?,
      yearOfStudy: json['year_of_study'] as int,
      branch: json['branch'] as String,
      section: json['section'] as String?,
      profilePicture: json['profile_picture'] as String?,
      bio: json['bio'] as String?,
      interests: (json['interests'] as List?)?.map((e) => e as String).toList() ?? [],
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'usn': usn,
      'year_of_study': yearOfStudy,
      'branch': branch,
      'section': section,
      'profile_picture': profilePicture,
      'bio': bio,
      'interests': interests,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

@JsonSerializable()
class FacultyProfile {
  final int id;
  final String employeeId;
  final String department;
  final String designation;
  final String? profilePicture;
  final String? bio;
  final List<String> specializations;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  FacultyProfile({
    required this.id,
    required this.employeeId,
    required this.department,
    required this.designation,
    this.profilePicture,
    this.bio,
    required this.specializations,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FacultyProfile.fromJson(Map<String, dynamic> json) {
    return FacultyProfile(
      id: json['id'] as int,
      employeeId: json['employee_id'] as String,
      department: json['department'] as String,
      designation: json['designation'] as String,
      profilePicture: json['profile_picture'] as String?,
      bio: json['bio'] as String?,
      specializations: (json['specializations'] as List?)?.map((e) => e as String).toList() ?? [],
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'department': department,
      'designation': designation,
      'profile_picture': profilePicture,
      'bio': bio,
      'specializations': specializations,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User user;
  final DateTime expiresAt;
  final bool requiresUsnEntry; // For students who need to enter USN after OTP

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresAt,
    this.requiresUsnEntry = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(const Duration(days: 7)), // Default expiry
      requiresUsnEntry: json['requires_usn_entry'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user': user.toJson(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}

@JsonSerializable()
class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

@JsonSerializable()
class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String userType;
  final String? phoneNumber;
  final String? usn;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.userType,
    this.phoneNumber,
    this.usn,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      userType: json['user_type'] as String,
      usn: json['usn'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'user_type': userType,
      if (usn != null) 'usn': usn,
    };
  }
}

@JsonSerializable()
class OTPRequest {
  final String email;
  final String type; // 'register', 'login', 'reset_password'

  OTPRequest({
    required this.email,
    required this.type,
  });

  factory OTPRequest.fromJson(Map<String, dynamic> json) {
    return OTPRequest(
      email: json['email'] as String,
      type: json['type'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'type': type,
    };
  }
}

@JsonSerializable()
class OTPVerification {
  final String email;
  final String otp;

  OTPVerification({
    required this.email,
    required this.otp,
  });

  factory OTPVerification.fromJson(Map<String, dynamic> json) {
    return OTPVerification(
      email: json['email'] as String,
      otp: json['otp'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
    };
  }
}