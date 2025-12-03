import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/web_download_stub.dart'
    if (dart.library.html) '../utils/web_download_web.dart' as web_download;
import '../models/user_model.dart';
import '../models/complaint_model.dart';
import '../models/feedback_model.dart';
import '../models/study_group_model.dart';
import '../models/notice_model.dart';
import '../models/meeting_model.dart';
import '../models/reservation_model.dart';
import '../models/notification_model.dart';
import '../models/chatbot_model.dart';
import '../models/chatbot_nlp_model.dart';
import '../models/calendar_event_model.dart';
import '../models/recommendation_model.dart';
import '../models/gamification_models.dart';
import '../models/academic_planner_models.dart';
import '../models/marketplace_models.dart';
import '../models/faculty_admin_models.dart';
import '../models/safety_wellbeing_models.dart';
import '../models/lifecycle_models.dart';
import '../models/local_integrations_models.dart';
import '../models/awards_models.dart';
import '../utils/cache.dart';
import '../utils/logger.dart';
import '../config/api_config.dart';

final appLogger = Logger('ApiService');

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const String _storageKey = 'ksit_nexus_token';
  
  late final Dio _dio;
  late final FlutterSecureStorage _storage;
  String? _accessToken;
  String? _refreshToken;

  ApiService() {
    _storage = const FlutterSecureStorage();
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        // Accept all status codes to handle errors properly
        return status != null && status < 500;
      },
    ));

    // Only add cookie manager on non-web platforms
    if (!kIsWeb) {
      try {
        // Import and use cookie manager only on mobile platforms
        // This will be handled by the backend setting cookies directly
      } catch (e) {
        print('Cookie manager not available on this platform: $e');
      }
    }
    
    _setupInterceptors();
    _loadTokens();
    _initCache();
  }

  Future<void> _initCache() async {
    try {
      await cacheManager.init();
    } catch (e) {
      appLogger.error('Error initializing cache: $e');
    }
  }

  // Helper method to handle paginated responses
  List<T> _parsePaginatedResponse<T>(Response response, T Function(Map<String, dynamic>) fromJson) {
    try {
      // Handle paginated response
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('results')) {
          return (data['results'] as List)
              .map((json) => fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      
      // Fallback for direct list response
      if (response.data is List) {
        return (response.data as List)
            .map((json) => fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      // If it's a Map but no 'results' key, return empty list
      return [];
    } catch (e) {
      print('Error parsing response data: $e, type: ${response.data.runtimeType}');
      return [];
    }
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('Making request to: ${options.uri}');
          print('Current access token: ${_accessToken != null ? 'present' : 'null'}');
          
          // Add JWT token to Authorization header if available
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
            print('Added Authorization header: Bearer $_accessToken');
          } else {
            print('No access token available - relying on cookies');
          }
          
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Check if response contains new tokens and update them
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            if (data.containsKey('access_token') && data.containsKey('refresh_token')) {
              _accessToken = data['access_token'];
              _refreshToken = data['refresh_token'];
              _saveTokens(_accessToken!, _refreshToken!);
              print('Updated tokens from response');
            }
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          // Handle connection errors
          if (error.type == DioExceptionType.connectionError || 
              error.type == DioExceptionType.connectionTimeout ||
              error.message?.contains('Connection refused') == true ||
              error.message?.contains('Failed host lookup') == true) {
            print('Connection error detected: ${error.message}');
            // Don't retry connection errors immediately - let the UI handle it
            handler.next(error);
            return;
          }
          
          // Don't attempt token refresh for authentication-related endpoints
          final requestPath = error.requestOptions.path;
          final authEndpoints = ['/auth/login/', '/auth/register/', '/auth/verify-registration/', '/auth/forgot-password/', '/auth/reset-password/'];
          
          if (error.response?.statusCode == 401 && !authEndpoints.contains(requestPath)) {
            print('Received 401, attempting token refresh...');
            final refreshed = await _refreshAccessToken();
            if (refreshed) {
              print('Token refresh successful, retrying request');
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $_accessToken';
              try {
                final response = await _dio.fetch(options);
                handler.resolve(response);
                return;
              } catch (retryError) {
                print('Retry after token refresh failed: $retryError');
                handler.next(error);
                return;
              }
            } else {
              print('Token refresh failed, clearing tokens');
              await _clearTokens();
              // You might want to navigate to login screen here
              // For now, just pass the error through
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<void> _loadTokens() async {
    _accessToken = await _storage.read(key: '${_storageKey}_access');
    _refreshToken = await _storage.read(key: '${_storageKey}_refresh');
    print('Loaded tokens: access=${_accessToken != null ? 'present' : 'null'}, refresh=${_refreshToken != null ? 'present' : 'null'}');
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.write(key: '${_storageKey}_access', value: accessToken);
    await _storage.write(key: '${_storageKey}_refresh', value: refreshToken);
    print('Saved tokens: access=${accessToken.substring(0, 10)}..., refresh=${refreshToken.substring(0, 10)}...');
  }

  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: '${_storageKey}_access');
    await _storage.delete(key: '${_storageKey}_refresh');
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) {
      print('No refresh token available');
      return false;
    }
    
    try {
      print('Attempting to refresh token with refresh token: ${_refreshToken!.substring(0, 10)}...');
      final response = await _dio.post('/auth/refresh/', data: {
        'refresh_token': _refreshToken,
      });
      
      print('Token refresh response status: ${response.statusCode}');
      print('Token refresh response data: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        await _saveTokens(data['access_token'], data['refresh_token']);
        print('Token refresh successful');
        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
      if (e is DioException) {
        print('DioException details: ${e.response?.data}');
        print('Status code: ${e.response?.statusCode}');
      }
    }
    return false;
  }

  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Get device information for session tracking
  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().deviceInfo;
      String deviceId;
      String deviceName;
      String deviceType;

      if (Platform.isAndroid) {
        final androidInfo = deviceInfo as AndroidDeviceInfo;
        deviceId = androidInfo.id;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
        deviceType = 'mobile';
      } else if (Platform.isIOS) {
        final iosInfo = deviceInfo as IosDeviceInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceName = '${iosInfo.name} (${iosInfo.model})';
        deviceType = 'mobile';
      } else if (Platform.isWindows) {
        final windowsInfo = deviceInfo as WindowsDeviceInfo;
        deviceId = windowsInfo.deviceId;
        deviceName = '${windowsInfo.computerName} (Windows)';
        deviceType = 'desktop';
      } else if (Platform.isMacOS) {
        final macInfo = deviceInfo as MacOsDeviceInfo;
        deviceId = macInfo.systemGUID ?? 'unknown';
        deviceName = '${macInfo.model} (macOS)';
        deviceType = 'desktop';
      } else if (Platform.isLinux) {
        final linuxInfo = deviceInfo as LinuxDeviceInfo;
        deviceId = linuxInfo.machineId ?? 'unknown';
        deviceName = '${linuxInfo.name} (Linux)';
        deviceType = 'desktop';
      } else if (kIsWeb) {
        deviceId = 'web-${DateTime.now().millisecondsSinceEpoch}';
        deviceName = 'Web Browser';
        deviceType = 'web';
      } else {
        deviceId = 'unknown-${DateTime.now().millisecondsSinceEpoch}';
        deviceName = 'Unknown Device';
        deviceType = 'unknown';
      }

      return {
        'device_id': deviceId,
        'device_name': deviceName,
        'device_type': deviceType,
      };
    } catch (e) {
      print('Error getting device info: $e');
      return {
        'device_id': 'unknown-${DateTime.now().millisecondsSinceEpoch}',
        'device_name': 'Unknown Device',
        'device_type': 'unknown',
      };
    }
  }

  // Authentication APIs
  Future<AuthResponse> login(LoginRequest request) async {
    print('Sending login request to: ${baseUrl}/auth/login/');
    print('Request data: ${request.toJson()}');
    try {
      // Get device information
      final deviceInfo = await _getDeviceInfo();
      
      final response = await _dio.post('/auth/login/', data: {
        'username': request.username,
        'password': request.password,
        'device_id': deviceInfo['device_id'],
        'device_name': deviceInfo['device_name'],
        'device_type': deviceInfo['device_type'],
      });
      print('Login response status: ${response.statusCode}');
      print('Login response data: ${response.data}');
      
      // Check if response data contains required fields
      if (response.data == null) {
        throw Exception('Invalid response from server');
      }
      
      final data = response.data as Map<String, dynamic>;
      if (!data.containsKey('access_token') || !data.containsKey('refresh_token') || !data.containsKey('user')) {
        throw Exception('Invalid response format from server');
      }
      
      // Parse user data and log it for debugging
      final userData = data['user'] as Map<String, dynamic>;
      print('=== LOGIN RESPONSE DEBUG ===');
      print('User data from backend: $userData');
      print('User type from backend: ${userData['user_type']}');
      print('User email: ${userData['email']}');
      print('===========================');
      
      // Create AuthResponse from the response
      final authResponse = AuthResponse(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        user: User.fromJson(userData),
        expiresAt: DateTime.now().add(const Duration(hours: 24)), // Default 24 hours
      );
      
      // Log the parsed user object
      print('=== PARSED USER OBJECT ===');
      print('User email: ${authResponse.user.email}');
      print('User type: ${authResponse.user.userType}');
      print('isFaculty: ${authResponse.user.isFaculty}');
      print('isStudent: ${authResponse.user.isStudent}');
      print('===========================');
      
      // Tokens are automatically saved by the response interceptor
      return authResponse;
    } catch (e) {
      print('Login request failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    print('Sending registration request to: ${baseUrl}/auth/register/');
    print('Request data: ${request.toJson()}');
    try {
      final response = await _dio.post('/auth/register/', data: request.toJson());
      print('Registration response status: ${response.statusCode}');
      print('Registration response data: ${response.data}');
      return response.data;
    } catch (e) {
      print('Registration request failed: $e');
      rethrow;
    }
  }

  Future<AuthResponse> verifyRegistrationOTP(int userId, String otp) async {
    print('Sending OTP verification request to: ${baseUrl}/auth/verify-registration/');
    print('Request data: user_id=$userId, otp=$otp');
    try {
      final response = await _dio.post('/auth/verify-registration/', data: {
        'user_id': userId,
        'otp': otp,
      });
      print('OTP verification response status: ${response.statusCode}');
      print('OTP verification response data: ${response.data}');
      
      // Check if response data contains required fields
      if (response.data == null) {
        throw Exception('No response received from server');
      }
      
      final data = response.data as Map<String, dynamic>;
      
      // Check if this is an error response
      if (data.containsKey('error')) {
        throw Exception(data['error'] as String);
      }
      
      // Check if this is a success response with required fields
      if (!data.containsKey('access_token') || !data.containsKey('refresh_token') || !data.containsKey('user')) {
        // Log the actual response for debugging
        print('Unexpected response format: $data');
        throw Exception('Server returned unexpected response format');
      }
      
      // Create AuthResponse from the response
      final requiresUsnEntry = data['requires_usn_entry'] as bool? ?? false;
      print('🔵 OTP Verification Response - requires_usn_entry: $requiresUsnEntry'); // Debug
      
      final authResponse = AuthResponse(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        user: User.fromJson(data['user'] as Map<String, dynamic>),
        expiresAt: DateTime.now().add(const Duration(hours: 24)), // Default 24 hours
        requiresUsnEntry: requiresUsnEntry, // Parse requires_usn_entry flag
      );
      
      print('🔵 AuthResponse created: requires_usn_entry=${authResponse.requiresUsnEntry}'); // Debug
      
      // Tokens are automatically saved by the response interceptor
      return authResponse;
    } catch (e) {
      print('OTP verification request failed: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Status code: ${e.response?.statusCode}');
        print('  Response data: ${e.response?.data}');
        print('  Request URL: ${e.requestOptions.uri}');
        print('  Request data: ${e.requestOptions.data}');
        
        // Handle different error responses
        if (e.response?.statusCode == 400) {
          // Bad request - extract error message from response
          final responseData = e.response?.data;
          if (responseData is Map<String, dynamic> && responseData.containsKey('error')) {
            throw Exception(responseData['error'] as String);
          }
        } else if (e.response?.statusCode == 401) {
          throw Exception('Authentication failed. Please try again.');
        } else if (e.response?.statusCode == 404) {
          throw Exception('Service not found. Please try again later.');
        } else if (e.response?.statusCode == 500) {
          throw Exception('Server error. Please try again later.');
        }
      }
      rethrow;
    }
  }

  Future<void> requestOTP(OTPRequest request) async {
    await _dio.post('/auth/otp/request/', data: request.toJson());
  }

  Future<AuthResponse> verifyOTP(OTPVerification request) async {
    final response = await _dio.post('/auth/otp/verify/', data: request.toJson());
    final authResponse = AuthResponse.fromJson(response.data);
    await _saveTokens(authResponse.accessToken, authResponse.refreshToken);
    return authResponse;
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout/');
    } finally {
      await _clearTokens();
      // Cookies will be cleared by the backend response
    }
  }

  Future<User> getCurrentUser({bool useCache = true}) async {
    final cacheKey = 'user:profile';
    
    // Try to get from cache first
    if (useCache) {
      try {
        final cached = await cacheManager.get<User>(
          cacheKey,
          (json) => User.fromJson(json),
        );
        if (cached != null) {
          appLogger.info('Returning user profile from cache');
          return cached;
        }
      } catch (e) {
        appLogger.warning('Error reading user from cache: $e');
      }
    }
    
    // Fetch from API
    final response = await _dio.get('/auth/profile/');
    final user = User.fromJson(response.data);
    
    // Cache the response
    if (useCache) {
      try {
        await cacheManager.set(
          cacheKey,
          user,
          (user) => user.toJson(),
          ttl: 300, // Cache for 5 minutes
        );
      } catch (e) {
        appLogger.warning('Error caching user profile: $e');
      }
    }
    
    return user;
  }

  /// Clear the cached user profile
  Future<void> clearUserCache() async {
    try {
      await cacheManager.remove('user:profile');
      appLogger.info('User profile cache cleared');
    } catch (e) {
      appLogger.warning('Error clearing user cache: $e');
    }
  }

  /// Cache a user profile (used after login to ensure cache consistency)
  Future<void> cacheUser(User user) async {
    try {
      await cacheManager.set(
        'user:profile',
        user,
        (user) => user.toJson(),
        ttl: 300, // Cache for 5 minutes
      );
      appLogger.info('User profile cached: ${user.email}');
    } catch (e) {
      appLogger.warning('Error caching user profile: $e');
    }
  }

  Future<User> updateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    final response = await _dio.patch('/auth/profile/', data: {
      'firstName': firstName,
      'lastName': lastName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    });
    return User.fromJson(response.data);
  }

  Future<String> uploadProfilePicture(XFile image) async {
    final formData = FormData.fromMap({
      'profile_picture': await MultipartFile.fromFile(image.path),
    });
    
    final response = await _dio.post('/auth/profile/picture/', data: formData);
    
    if (response.data == null) {
      throw Exception('Invalid response from server');
    }
    
    final data = response.data as Map<String, dynamic>;
    if (!data.containsKey('profile_picture_url')) {
      throw Exception('Invalid response format from server');
    }
    
    return data['profile_picture_url'] as String;
  }

  Future<String> uploadProfilePictureFromFile(dynamic image) async {
    MultipartFile multipartFile;
    
    if (kIsWeb) {
      // For web, we need to use bytes
      if (image is XFile) {
        final bytes = await image.readAsBytes();
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: image.name,
        );
      } else {
        throw Exception('On web, image must be an XFile');
      }
    } else {
      // For mobile, use file path
      if (image is File) {
        multipartFile = await MultipartFile.fromFile(image.path);
      } else if (image is XFile) {
        multipartFile = await MultipartFile.fromFile(image.path);
      } else {
        throw Exception('Invalid image type');
      }
    }
    
    final formData = FormData.fromMap({
      'profile_picture': multipartFile,
    });
    
    final response = await _dio.post('/auth/profile/picture/', data: formData);
    
    if (response.data == null) {
      throw Exception('Invalid response from server');
    }
    
    final data = response.data as Map<String, dynamic>;
    if (!data.containsKey('profile_picture_url')) {
      throw Exception('Invalid response format from server');
    }
    
    return data['profile_picture_url'] as String;
  }

  Future<User> updateProfilePicture(String imageUrl) async {
    final response = await _dio.patch('/auth/profile/', data: {
      'profile_picture': imageUrl,
    });
    return User.fromJson(response.data);
  }

  // File Upload APIs - Note: Backend doesn't have separate file upload endpoints
  // Files are uploaded directly with their respective entities (complaints, etc.)

  // Register FCM token
  Future<void> registerFCMToken(String token) async {
    try {
      await _dio.post('/fcm-tokens/', data: {
        'token': token,
        'platform': 'flutter',
      });
    } catch (e) {
      throw Exception('Failed to register FCM token: $e');
    }
  }

  // Unregister FCM token
  Future<void> unregisterFCMToken(String token) async {
    try {
      await _dio.delete('/fcm-tokens/$token/');
    } catch (e) {
      throw Exception('Failed to unregister FCM token: $e');
    }
  }

  // Forgot Password APIs
  Future<Map<String, dynamic>> requestPasswordResetOTP(String phoneNumber) async {
    print('Sending forgot password OTP request to: ${baseUrl}/auth/forgot-password/');
    try {
      final response = await _dio.post('/auth/forgot-password/', data: {
        'phone_number': phoneNumber,
      });
      print('Forgot password OTP response status: ${response.statusCode}');
      print('Forgot password OTP response data: ${response.data}');
      return response.data;
    } catch (e) {
      print('Forgot password OTP request failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyPasswordResetOTP(String phoneNumber, String otp) async {
    print('Sending verify password reset OTP request to: ${baseUrl}/auth/forgot-password/verify-otp/');
    try {
      final response = await _dio.post('/auth/forgot-password/verify-otp/', data: {
        'phone_number': phoneNumber,
        'otp': otp,
      });
      print('Verify password reset OTP response status: ${response.statusCode}');
      print('Verify password reset OTP response data: ${response.data}');
      
      // Check if response data is valid
      if (response.data == null) {
        throw Exception('Invalid response from server');
      }
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Verify password reset OTP request failed: $e');
      rethrow;
    }
  }

  Future<AuthResponse> resetPassword(String resetToken, String newPassword, String confirmPassword) async {
    print('Sending reset password request to: ${baseUrl}/auth/reset-password/');
    try {
      final response = await _dio.post('/auth/reset-password/', data: {
        'reset_token': resetToken,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });
      print('Reset password response status: ${response.statusCode}');
      print('Reset password response data: ${response.data}');
      
      // Check if response data contains required fields
      if (response.data == null) {
        throw Exception('Invalid response from server');
      }
      
      final data = response.data as Map<String, dynamic>;
      if (!data.containsKey('access_token') || !data.containsKey('refresh_token') || !data.containsKey('user')) {
        throw Exception('Invalid response format from server');
      }
      
      // Create AuthResponse from the response
      final authResponse = AuthResponse(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        user: User.fromJson(data['user'] as Map<String, dynamic>),
        expiresAt: DateTime.now().add(const Duration(hours: 24)), // Default 24 hours
      );
      
      // Tokens are automatically saved by the response interceptor
      return authResponse;
    } catch (e) {
      print('Reset password request failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    print('Sending change password request to: ${baseUrl}/auth/password/change/');
    try {
      final response = await _dio.post('/auth/password/change/', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });
      print('Change password response status: ${response.statusCode}');
      print('Change password response data: ${response.data}');
      return response.data;
    } catch (e) {
      print('Change password request failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateStudentProfile({
    required String studentId,
    required int yearOfStudy,
    required String branch,
    String? section,
    String? bio,
    List<String>? interests,
  }) async {
    print('Sending update student profile request to: ${baseUrl}/auth/student/');
    try {
      // Create FormData for multipart form submission
      final formData = FormData.fromMap({
        'student_id': studentId,
        'year_of_study': yearOfStudy,
        'branch': branch,
        if (section != null && section.isNotEmpty) 'section': section,
        if (bio != null && bio.isNotEmpty) 'bio': bio,
        if (interests != null && interests.isNotEmpty) 'interests': interests,
      });
      
      final response = await _dio.patch('/auth/student/', data: formData);
      print('Update student profile response status: ${response.statusCode}');
      print('Update student profile response data: ${response.data}');
      return response.data;
    } catch (e) {
      print('Update student profile request failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createStudentProfile({
    required String studentId,
    required int yearOfStudy,
    required String branch,
    String? section,
    String? bio,
    List<String>? interests,
  }) async {
    print('Sending create student profile request to: ${baseUrl}/auth/student/create/');
    try {
      // Create FormData for multipart form submission
      final formData = FormData.fromMap({
        'student_id': studentId,
        'year_of_study': yearOfStudy,
        'branch': branch,
        if (section != null && section.isNotEmpty) 'section': section,
        if (bio != null && bio.isNotEmpty) 'bio': bio,
        if (interests != null && interests.isNotEmpty) 'interests': interests,
      });
      
      final response = await _dio.post('/auth/student/create/', data: formData);
      print('Create student profile response status: ${response.statusCode}');
      print('Create student profile response data: ${response.data}');
      return response.data;
    } catch (e) {
      print('Create student profile request failed: $e');
      rethrow;
    }
  }

  // Authentication helper methods
  Future<bool> isLoggedIn() async {
    // Ensure tokens are loaded before checking
    if (_accessToken == null) {
      await _loadTokens();
    }
    return _accessToken != null;
  }

  Future<bool> hasValidToken() async {
    // Ensure tokens are loaded before checking
    if (_accessToken == null) {
      await _loadTokens();
    }
    if (_accessToken == null) return false;
    
    try {
      // Try to get current user to validate token
      await getCurrentUser();
      return true;
    } catch (e) {
      print('Token validation failed: $e');
      // Try to refresh token
      if (_refreshToken != null) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return true;
        }
      }
      // Clear invalid tokens
      await _clearTokens();
      return false;
    }
  }

  // ==================== Advanced Authentication Features ====================
  
  // Two-Factor Authentication
  Future<Map<String, dynamic>> setup2FA() async {
    final response = await _dio.post('/auth/2fa/setup/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verify2FA(String code) async {
    final response = await _dio.post('/auth/2fa/verify/', data: {'code': code});
    return response.data as Map<String, dynamic>;
  }

  Future<void> disable2FA() async {
    await _dio.post('/auth/2fa/disable/');
  }

  Future<Map<String, dynamic>> get2FAStatus() async {
    final response = await _dio.get('/auth/2fa/status/');
    return response.data as Map<String, dynamic>;
  }

  Future<List<String>> generateBackupCodes() async {
    final response = await _dio.post('/auth/2fa/backup-codes/');
    return (response.data['backup_codes'] as List).cast<String>();
  }

  Future<AuthResponse> loginWith2FA(String username, String password, String code) async {
    final response = await _dio.post('/auth/login-2fa/', data: {
      'username': username,
      'password': password,
      'code': code,
    });
    final authResponse = AuthResponse.fromJson(response.data);
    await _saveTokens(authResponse.accessToken, authResponse.refreshToken);
    return authResponse;
  }

  // Device Session Management
  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    final response = await _dio.get('/auth/sessions/');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createDeviceSession({
    required String deviceName,
    required String deviceType,
    String? deviceId,
  }) async {
    final response = await _dio.post('/auth/create-session/', data: {
      'device_name': deviceName,
      'device_type': deviceType,
      if (deviceId != null) 'device_id': deviceId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> deactivateSession(int sessionId) async {
    await _dio.post('/auth/sessions/$sessionId/deactivate/');
  }

  Future<void> logoutAllDevices() async {
    await _dio.post('/auth/sessions/logout-all/');
  }

  // Profile Summary
  Future<Map<String, dynamic>> getProfileSummary() async {
    final response = await _dio.get('/auth/profile/summary/');
    return response.data as Map<String, dynamic>;
  }

  // Faculty Profile
  Future<Map<String, dynamic>> getFacultyProfile() async {
    final response = await _dio.get('/auth/faculty/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createFacultyProfile(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/faculty/create/', data: data);
    return response.data as Map<String, dynamic>;
  }

  // SSO Integration
  Future<Map<String, dynamic>> getSSOLoginUrl() async {
    final response = await _dio.get('/auth/sso/login-url/');
    return response.data as Map<String, dynamic>;
  }

  Future<AuthResponse> ssoCallback(String code, String state) async {
    final response = await _dio.post('/auth/sso/callback/', data: {
      'code': code,
      'state': state,
    });
    final authResponse = AuthResponse.fromJson(response.data);
    await _saveTokens(authResponse.accessToken, authResponse.refreshToken);
    return authResponse;
  }

  Future<AuthResponse> ssoRefreshToken(String refreshToken) async {
    final response = await _dio.post('/auth/sso/refresh-token/', data: {
      'refresh_token': refreshToken,
    });
    final authResponse = AuthResponse.fromJson(response.data);
    await _saveTokens(authResponse.accessToken, authResponse.refreshToken);
    return authResponse;
  }

  Future<void> ssoLogout() async {
    await _dio.post('/auth/sso/logout/');
    await _clearTokens();
  }

  // Complaints APIs
  Future<List<Complaint>> getComplaints() async {
    final response = await _dio.get('/complaints/');
    print('Complaints API response: ${response.data}');
    return _parsePaginatedResponse(response, Complaint.fromJson);
  }

  Future<Complaint> createComplaint(ComplaintCreateRequest request) async {
    // Convert to FormData for multipart/form-data submission
    final Map<String, dynamic> formFields = {
      'category': request.category,
      'title': request.title,
      'description': request.description,
      'urgency': request.urgency,
      if (request.contactEmail != null && request.contactEmail!.isNotEmpty) 'contact_email': request.contactEmail,
      if (request.contactPhone != null && request.contactPhone!.isNotEmpty) 'contact_phone': request.contactPhone,
      if (request.location != null && request.location!.isNotEmpty) 'location': request.location,
    };
    
    // Add file attachments if any
    if (request.attachments != null && request.attachments!.isNotEmpty) {
      final List<MultipartFile> files = [];
      for (final path in request.attachments!) {
        if (path.isNotEmpty) {
          if (kIsWeb) {
            // For web platform - skip file upload for now as it's causing issues
            // TODO: Implement proper web file upload using FileReader API
            print('Skipping file upload on web platform: $path');
            continue;
          } else {
            // For mobile/desktop platforms
            try {
              files.add(MultipartFile.fromFileSync(path));
            } catch (e) {
              print('Error reading file for mobile upload: $e');
              // Skip this file if we can't read it
            }
          }
        }
      }
      if (files.isNotEmpty) {
        formFields['attachments'] = files;
      }
    }
    
    final formData = FormData.fromMap(formFields);
    print('Creating complaint with form data: $formFields');
    final response = await _dio.post('/complaints/', data: formData);
    print('Complaint creation response: ${response.data}');
    return Complaint.fromJson(response.data);
  }

  Future<Complaint> updateComplaint(int id, ComplaintUpdateRequest request) async {
    final response = await _dio.patch('/complaints/$id/', data: request.toJson());
    return Complaint.fromJson(response.data);
  }

  Future<void> deleteComplaint(int id) async {
    await _dio.delete('/complaints/$id/');
  }

  Future<Map<String, dynamic>> getComplaintStats() async {
    final response = await _dio.get('/complaints/stats/');
    return response.data;
  }

  // Advanced Complaints Features
  Future<List<Complaint>> getMyComplaints() async {
    final response = await _dio.get('/complaints/my/');
    return _parsePaginatedResponse(response, Complaint.fromJson);
  }

  Future<List<Complaint>> getAdminComplaints() async {
    final response = await _dio.get('/complaints/admin/');
    return _parsePaginatedResponse(response, Complaint.fromJson);
  }

  Future<Map<String, dynamic>> getFacultyComplaintsDashboard() async {
    final response = await _dio.get('/complaints/faculty/dashboard/');
    return response.data as Map<String, dynamic>;
  }

  Future<List<Complaint>> getFacultyComplaints({String status = 'pending'}) async {
    final response = await _dio.get('/complaints/faculty/dashboard/', queryParameters: {
      'status': status,
    });
    return _parsePaginatedResponse(response, Complaint.fromJson);
  }

  Future<Complaint> respondToComplaint(int id, String response) async {
    final responseData = await _dio.post('/complaints/$id/respond/', data: {
      'response': response,
    });
    return Complaint.fromJson(responseData.data as Map<String, dynamic>);
  }

  Future<Complaint> markComplaintResolved(int id) async {
    final response = await _dio.post('/complaints/$id/mark-resolved/');
    return Complaint.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getFacultyComplaintStats() async {
    final response = await _dio.get('/complaints/faculty/stats/');
    return response.data as Map<String, dynamic>;
  }

  Future<Complaint> assignComplaint(int id, int assigneeId) async {
    final response = await _dio.post('/complaints/$id/assign/', data: {
      'assignee_id': assigneeId,
    });
    return Complaint.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getComplaintAttachments(int id) async {
    final response = await _dio.get('/complaints/$id/attachments/');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> uploadComplaintAttachment(int id, dynamic file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final response = await _dio.post('/complaints/$id/attachments/', data: formData);
    return response.data as Map<String, dynamic>;
  }

  // Feedback APIs
  Future<List<Feedback>> getFeedbacks() async {
    final response = await _dio.get('/feedbacks/my/');
    return _parsePaginatedResponse(response, Feedback.fromJson);
  }

  Future<Feedback> getFeedbackById(int id) async {
    final response = await _dio.get('/feedbacks/$id/');
    return Feedback.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Feedback>> getFacultyFeedback(int facultyId) async {
    final response = await _dio.get('/feedbacks/faculty/$facultyId/');
    return _parsePaginatedResponse(response, Feedback.fromJson);
  }
  
  Future<FacultyFeedbackSummary> getFacultyFeedbackSummary() async {
    final response = await _dio.get('/feedbacks/summary/');
    return FacultyFeedbackSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getFeedbackSummary() async {
    final response = await _dio.get('/feedbacks/summary/');
    return response.data as Map<String, dynamic>;
  }

  Future<List<Feedback>> getMyFeedback() async {
    final response = await _dio.get('/feedbacks/my/');
    return _parsePaginatedResponse(response, Feedback.fromJson);
  }

  Future<Map<String, dynamic>> getFeedbackStats() async {
    final response = await _dio.get('/feedbacks/stats/');
    return response.data as Map<String, dynamic>;
  }

  Future<Feedback> createFeedback(FeedbackCreateRequest request) async {
    final payload = request.toJson();
    print("=== FEEDBACK API REQUEST ===");
    print("URL: $baseUrl/feedbacks/");
    print("Payload: $payload");
    print("Payload type: ${payload.runtimeType}");
    
    // Validate payload before sending
    for (final entry in payload.entries) {
      print("${entry.key}: ${entry.value} (${entry.value.runtimeType})");
    }
    
    try {
      final response = await _dio.post('/feedbacks/submit/', data: payload);
      print("=== FEEDBACK API RESPONSE ===");
      print("Status: ${response.statusCode}");
      print("Data: ${response.data}");
      return Feedback.fromJson(response.data);
    } catch (e) {
      print("=== FEEDBACK API ERROR ===");
      print("Error: $e");
      if (e is DioException) {
        print("DioException type: ${e.type}");
        print("Response data: ${e.response?.data}");
        print("Response status: ${e.response?.statusCode}");
      }
      rethrow;
    }
  }

  Future<List<Faculty>> getFaculties() async {
    final response = await _dio.get('/faculties/');
    return _parsePaginatedResponse(response, Faculty.fromJson);
  }

  // Study Groups APIs
  Future<List<StudyGroup>> getStudyGroups() async {
    try {
      print('Making request to: ${_dio.options.baseUrl}/study-groups/');
      final response = await _dio.get('/study-groups/');
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      
      // Check for error status codes
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Failed to load study groups: ${response.statusCode}',
        );
      }
      
      return _parsePaginatedResponse(response, StudyGroup.fromJson);
    } on DioException catch (e) {
      print('DioException in getStudyGroups: ${e.type} - ${e.message}');
      
      // Provide more user-friendly error messages
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.message?.contains('Connection refused') == true ||
          e.message?.contains('Failed host lookup') == true ||
          e.message?.contains('XMLHttpRequest') == true) {
        throw Exception(
          'Unable to connect to the server. Please check:\n'
          '1. The backend server is running on ${ApiConfig.baseUrl.replaceAll('/api', '')}\n'
          '2. Your internet connection is active\n'
          '3. Your phone and computer are on the same WiFi network\n'
          '4. CORS is properly configured on the backend'
        );
      }
      
      rethrow;
    } catch (e) {
      print('Error in getStudyGroups: $e');
      rethrow;
    }
  }

  Future<StudyGroup> createStudyGroup(StudyGroupCreateRequest request) async {
    final response = await _dio.post('/study-groups/', data: request.toJson());
    return StudyGroup.fromJson(response.data);
  }


  // Study Group Messages APIs
  Future<List<GroupMessage>> getStudyGroupMessages(int groupId) async {
    final response = await _dio.get('/study-groups/$groupId/messages/');
    return _parsePaginatedResponse(response, GroupMessage.fromJson);
  }

  Future<GroupMessage> sendStudyGroupMessage(int groupId, GroupMessageCreateRequest request) async {
    final response = await _dio.post('/study-groups/$groupId/messages/', data: request.toJson());
    return GroupMessage.fromJson(response.data);
  }

  // Study Group Resources APIs
  Future<List<GroupResource>> getStudyGroupResources(int groupId) async {
    try {
      final response = await _dio.get('/study-groups/$groupId/resources/');
      return _parsePaginatedResponse(response, GroupResource.fromJson);
    } catch (e) {
      print('Error in getStudyGroupResources: $e');
      rethrow;
    }
  }

  Future<GroupResource> uploadStudyGroupResource(int groupId, dynamic file, {String? description, String? category}) async {
    try {
      String fileName;
      String fileExtension;
      
      if (kIsWeb) {
        // For web, file is a PlatformFile from file_picker
        fileName = file.name;
        fileExtension = fileName.split('.').last.toLowerCase();
      } else {
        // For mobile, file is a File object
        fileName = (file as File).path.split('/').last;
        fileExtension = fileName.split('.').last.toLowerCase();
      }
      
      // Determine resource type based on file extension
      String resourceType = 'other';
      if (['pdf', 'doc', 'docx', 'txt'].contains(fileExtension)) {
        resourceType = 'document';
      } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(fileExtension)) {
        resourceType = 'image';
      } else if (['mp4', 'avi', 'mov', 'wmv', 'flv'].contains(fileExtension)) {
        resourceType = 'video';
      }

      MultipartFile multipartFile;
      
      if (kIsWeb) {
        // For web, create MultipartFile from bytes
        multipartFile = MultipartFile.fromBytes(
          file.bytes,
          filename: fileName,
        );
      } else {
        // For mobile, use fromFile
        multipartFile = await MultipartFile.fromFile(
          (file as File).path,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap({
        'title': fileName,
        'description': description ?? '',
        'resource_type': resourceType,
        'file': multipartFile,
      });

      final response = await _dio.post(
        '/study-groups/$groupId/resources/',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return GroupResource.fromJson(response.data);
    } catch (e) {
      print('Error in uploadStudyGroupResource: $e');
      rethrow;
    }
  }

  Future<void> downloadStudyGroupResource(GroupResource resource) async {
    try {
      if (resource.fileUrl != null && resource.id != null) {
        // Use the new download endpoint with proper MIME type handling
        final downloadUrl = '/study-groups/${resource.groupId}/resources/${resource.id}/download/';
        
        final response = await _dio.get(
          downloadUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        
        // Handle download based on platform
        final bytes = response.data as List<int>;
        final filename = resource.fileName ?? 'download';
        final mimeType = response.headers.value('content-type') ?? 
                        _getMimeTypeFromFileName(resource.fileName) ?? 
                        _getMimeTypeFromFileType(resource.fileType) ?? 
                        'application/octet-stream';
        
        if (kIsWeb) {
          // For web, use conditional import
          await web_download.downloadFileWeb(bytes, filename, mimeType);
        } else {
          // For mobile, save to downloads folder
          await _downloadFileMobile(bytes, filename);
        }
      }
    } catch (e) {
      print('Error downloading resource: $e');
      rethrow;
    }
  }

  // Helper method to get MIME type from file name
  String? _getMimeTypeFromFileName(String? fileName) {
    if (fileName == null) return null;
    
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      default:
        return null;
    }
  }

  // Helper method to get MIME type from stored file type
  String? _getMimeTypeFromFileType(String? fileType) {
    if (fileType == null) return null;
    
    switch (fileType.toLowerCase()) {
      case 'image/png':
      case 'png':
        return 'image/png';
      case 'image/jpeg':
      case 'jpeg':
      case 'jpg':
        return 'image/jpeg';
      case 'image/gif':
      case 'gif':
        return 'image/gif';
      case 'application/pdf':
      case 'pdf':
        return 'application/pdf';
      case 'text/plain':
      case 'txt':
        return 'text/plain';
      case 'application/zip':
      case 'zip':
        return 'application/zip';
      case 'video/mp4':
      case 'mp4':
        return 'video/mp4';
      case 'audio/mpeg':
      case 'mp3':
        return 'audio/mpeg';
      default:
        return fileType;
    }
  }

  // Study Group Events APIs
  Future<List<GroupEvent>> getStudyGroupEvents(int groupId) async {
    try {
      final response = await _dio.get('/study-groups/$groupId/events/');
      return _parsePaginatedResponse(response, GroupEvent.fromJson);
    } catch (e) {
      print('Error in getStudyGroupEvents: $e');
      rethrow;
    }
  }

  Future<GroupEvent> createStudyGroupEvent(int groupId, GroupEventCreateRequest request) async {
    try {
      final data = request.toJson();
      print('Sending event creation request: $data');
      final response = await _dio.post('/study-groups/$groupId/events/', data: data);
      print('Event creation response: ${response.data}');
      return GroupEvent.fromJson(response.data);
    } catch (e) {
      print('Error in createStudyGroupEvent: $e');
      if (e is DioException) {
        print('Dio error response: ${e.response?.data}');
        print('Dio error status: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  // Study Group Join/Leave APIs
  Future<Map<String, dynamic>> joinStudyGroup(int groupId, {String? message}) async {
    try {
      final data = <String, dynamic>{};
      if (message != null && message.isNotEmpty) {
        data['message'] = message;
      }
      
      final response = await _dio.post('/study-groups/$groupId/join/', data: data);
      return response.data;
    } catch (e) {
      print('Error in joinStudyGroup: $e');
      if (e is DioException) {
        print('Dio error response: ${e.response?.data}');
        print('Dio error status: ${e.response?.statusCode}');
        
        // Extract error message from response
        if (e.response?.data is Map<String, dynamic>) {
          final errorData = e.response!.data as Map<String, dynamic>;
          if (errorData.containsKey('error')) {
            throw Exception(errorData['error']);
          }
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> leaveStudyGroup(int groupId) async {
    try {
      final response = await _dio.post('/study-groups/$groupId/leave/');
      return response.data;
    } catch (e) {
      print('Error in leaveStudyGroup: $e');
      if (e is DioException) {
        print('Dio error response: ${e.response?.data}');
        print('Dio error status: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> reportStudyGroup(int groupId, String issueDescription, String contentToRemove, String warningMessage) async {
    try {
      final response = await _dio.post('/study-groups/$groupId/report/', data: {
        'issue_description': issueDescription,
        'content_to_remove': contentToRemove,
        'warning_message': warningMessage,
      });
      return response.data;
    } catch (e) {
      print('Error in reportStudyGroup: $e');
      if (e is DioException) {
        print('Dio error response: ${e.response?.data}');
        print('Dio error status: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> closeStudyGroup(int groupId) async {
    try {
      final response = await _dio.post('/study-groups/$groupId/close/');
      return response.data;
    } catch (e) {
      print('Error in closeStudyGroup: $e');
      if (e is DioException) {
        print('Dio error response: ${e.response?.data}');
        print('Dio error status: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> muteStudyGroup(int groupId) async {
    try {
      final response = await _dio.post('/study-groups/$groupId/mute/');
      return response.data;
    } catch (e) {
      print('Error in muteStudyGroup: $e');
      if (e is DioException) {
        print('Dio error response: ${e.response?.data}');
        print('Dio error status: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  // Faculty Study Groups Management APIs
  Future<List<StudyGroup>> getFacultyStudyGroups({String filter = 'all'}) async {
    try {
      final response = await _dio.get('/study-groups/faculty/', queryParameters: {
        'filter': filter,
      });
      return _parsePaginatedResponse(response, StudyGroup.fromJson);
    } catch (e) {
      print('Error in getFacultyStudyGroups: $e');
      if (e is DioException) {
        print('Dio error response: ${e.response?.data}');
        print('Dio error status: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> reportStudyGroupAsFaculty(
    int groupId, 
    String issueDescription, 
    String contentToRemove, 
    String warningMessage
  ) async {
    try {
      final response = await _dio.post('/study-groups/$groupId/report/', data: {
        'issue_description': issueDescription,
        'content_to_remove': contentToRemove,
        'warning_message': warningMessage,
      });
      return response.data;
    } catch (e) {
      print('Error in reportStudyGroupAsFaculty: $e');
      if (e is DioException) {
        print('Dio error response: ${e.response?.data}');
        print('Dio error status: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> approveStudyGroup(int groupId) async {
    try {
      final response = await _dio.post('/study-groups/$groupId/approve/');
      return response.data;
    } catch (e) {
      print('Error in approveStudyGroup: $e');
      if (e is DioException) {
        print('Dio error response: ${e.response?.data}');
        print('Dio error status: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> rejectStudyGroup(int groupId) async {
    try {
      final response = await _dio.post('/study-groups/$groupId/reject/');
      return response.data;
    } catch (e) {
      print('Error in rejectStudyGroup: $e');
      if (e is DioException) {
        print('Dio error response: ${e.response?.data}');
        print('Dio error status: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> reopenStudyGroup(int groupId) async {
    try {
      final response = await _dio.post('/study-groups/$groupId/reopen/');
      return response.data;
    } catch (e) {
      print('Error in reopenStudyGroup: $e');
      if (e is DioException) {
        print('Dio error response: ${e.response?.data}');
        print('Dio error status: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  // Notices APIs
  Future<List<Notice>> getNotices() async {
    final response = await _dio.get('/notices/');
    return _parsePaginatedResponse(response, _parseNoticeFromJson);
  }

  Future<Notice> getNoticeById(int id) async {
    final response = await _dio.get('/notices/$id/');
    return _parseNoticeFromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Notice>> getDraftNotices() async {
    final response = await _dio.get('/notices/drafts/');
    return _parsePaginatedResponse(response, _parseNoticeFromJson);
  }

  Future<void> deleteNotice(int id) async {
    await _dio.delete('/notices/$id/');
  }

  Future<void> publishNotice(int id) async {
    await _dio.post('/notices/$id/publish/');
  }

  // Advanced Notices Features
  Future<void> markNoticeAsViewed(int id) async {
    await _dio.post('/notices/$id/view/');
  }

  Future<Notice> pinNotice(int id) async {
    final response = await _dio.post('/notices/$id/pin/');
    return Notice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Notice>> getAnnouncements() async {
    final response = await _dio.get('/notices/announcements/');
    return _parsePaginatedResponse(response, Notice.fromJson);
  }

  Future<Notice> getAnnouncementById(int id) async {
    final response = await _dio.get('/notices/announcements/$id/');
    return Notice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Notice>> getMyNotices() async {
    final response = await _dio.get('/notices/my/');
    return _parsePaginatedResponse(response, Notice.fromJson);
  }

  Future<Notice> saveDraft(NoticeCreateRequest request, {int? draftId}) async {
    final url = draftId != null ? '/notices/save-draft/$draftId/' : '/notices/save-draft/';
    final response = await _dio.post(url, data: request.toJson());
    return Notice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getNoticeStats() async {
    final response = await _dio.get('/notices/stats/');
    return response.data as Map<String, dynamic>;
  }
  
  Notice _parseNoticeFromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int
    int safeToInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    }
    
    // Helper function to safely convert to string
    String safeToString(dynamic value, {String defaultValue = ''}) {
      if (value == null) return defaultValue;
      return value.toString();
    }
    
    // Helper function to safely convert to bool
    bool safeToBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      return defaultValue;
    }
    
    // Ensure all required fields are present with proper defaults
    final noticeData = {
      'id': safeToInt(json['id']),
      'title': safeToString(json['title']),
      'content': safeToString(json['content']),
      'category': safeToString(json['category'], defaultValue: 'general'),
      'priority': safeToString(json['priority'], defaultValue: 'medium'),
      'targetAudience': safeToString(json['targetAudience'] ?? json['visibility'], defaultValue: 'all'),
      'targetBranch': json['targetBranch'] ?? (json['target_branches']?.isNotEmpty == true ? json['target_branches'][0] : null),
      'targetYear': json['targetYear'] ?? (json['target_years']?.isNotEmpty == true ? json['target_years'][0] : null),
      'attachmentUrl': json['attachmentUrl'] ?? json['attachment']?.toString(),
      'attachmentName': json['attachmentName'] ?? json['attachment_name'],
      'createdById': safeToInt(json['createdById'], defaultValue: 1),
      'createdByName': safeToString(json['createdByName'] ?? json['author'], defaultValue: 'Unknown'),
      'createdByRole': safeToString(json['createdByRole'], defaultValue: 'faculty'),
      'createdAt': safeToString(json['createdAt'] ?? json['created_at'], defaultValue: DateTime.now().toIso8601String()),
      'updatedAt': safeToString(json['updatedAt'] ?? json['updated_at'], defaultValue: DateTime.now().toIso8601String()),
      'expiresAt': json['expiresAt'] ?? json['expires_at'],
      'isActive': safeToBool(json['isActive'] ?? (json['status'] == 'published')),
      'isPinned': safeToBool(json['isPinned'] ?? json['is_pinned']),
      'viewCount': safeToInt(json['viewCount'] ?? json['view_count']),
      'views': json['views'] is List ? json['views'] : [],
      'status': safeToString(json['status'], defaultValue: 'published'),
    };
    
    return Notice.fromJson(noticeData);
  }

  Future<Notice> createNotice(NoticeCreateRequest request) async {
    final response = await _dio.post('/notices/', data: request.toJson());
    print('Create notice response: ${response.data}');
    
    // Handle the response data properly
    if (response.data is Map<String, dynamic>) {
      return _parseNoticeFromJson(response.data as Map<String, dynamic>);
    } else {
      throw Exception('Invalid response format from server');
    }
  }

  // Meetings APIs
  Future<List<Meeting>> getMeetings() async {
    final response = await _dio.get('/meetings/');
    return _parsePaginatedResponse(response, Meeting.fromJson);
  }

  Future<Meeting> getMeetingById(int id) async {
    final response = await _dio.get('/meetings/$id/');
    return Meeting.fromJson(response.data);
  }

  Future<Meeting> createMeeting(MeetingCreateRequest request) async {
    print('ApiService: Creating meeting with data: ${request.toJson()}');
    final response = await _dio.post('/meetings/', data: request.toJson());
    print('ApiService: Meeting creation response status: ${response.statusCode}');
    print('ApiService: Meeting creation response data: ${response.data}');
    return Meeting.fromJson(response.data);
  }

  Future<Meeting> updateMeeting(int id, MeetingUpdateRequest request) async {
    final response = await _dio.patch('/meetings/$id/', data: request.toJson());
    return Meeting.fromJson(response.data);
  }

  Future<void> deleteMeeting(int id) async {
    await _dio.delete('/meetings/$id/');
  }

  Future<Meeting> cancelMeeting(int id) async {
    final response = await _dio.post('/meetings/$id/cancel/');
    return Meeting.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Meeting> completeMeeting(int id) async {
    final response = await _dio.post('/meetings/$id/complete/');
    return Meeting.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Meeting>> getUpcomingMeetings() async {
    final response = await _dio.get('/meetings/', queryParameters: {
      'status': 'scheduled',
      'ordering': 'scheduled_date',
    });
    return _parsePaginatedResponse(response, Meeting.fromJson);
  }

  // Reservations APIs
  Future<List<ReadingRoom>> getReadingRooms() async {
    final response = await _dio.get('/reservations/rooms/');
    return _parsePaginatedResponse(response, ReadingRoom.fromJson);
  }

  Future<List<Seat>> getRoomSeats(int roomId) async {
    final response = await _dio.get('/reservations/rooms/$roomId/seats/');
    // Handle both paginated and non-paginated responses
    List<Seat> allSeats = [];
    
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('results')) {
        // Paginated response - fetch all pages
        allSeats = (data['results'] as List)
            .map((json) => Seat.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Check if there are more pages
        String? nextUrl = data['next'];
        while (nextUrl != null) {
          final nextResponse = await _dio.get(nextUrl);
          final nextData = nextResponse.data as Map<String, dynamic>;
          final nextSeats = (nextData['results'] as List)
              .map((json) => Seat.fromJson(json as Map<String, dynamic>))
              .toList();
          allSeats.addAll(nextSeats);
          nextUrl = nextData['next'];
        }
      } else {
        // Non-paginated response - direct list
        allSeats = (data.values.first as List? ?? [])
            .map((json) => Seat.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } else if (response.data is List) {
      // Direct list response
      allSeats = (response.data as List)
          .map((json) => Seat.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    
    return allSeats;
  }

  Future<List<Seat>> getAvailableSeats(int roomId, DateTime startTime, DateTime endTime) async {
    final response = await _dio.get('/reservations/rooms/$roomId/seats/', queryParameters: {
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
    });
    // Handle both paginated and non-paginated responses
    List<Seat> allSeats = [];
    
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('results')) {
        // Paginated response - fetch all pages
        allSeats = (data['results'] as List)
            .map((json) => Seat.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Check if there are more pages
        String? nextUrl = data['next'];
        while (nextUrl != null) {
          final nextResponse = await _dio.get(nextUrl);
          final nextData = nextResponse.data as Map<String, dynamic>;
          final nextSeats = (nextData['results'] as List)
              .map((json) => Seat.fromJson(json as Map<String, dynamic>))
              .toList();
          allSeats.addAll(nextSeats);
          nextUrl = nextData['next'];
        }
      } else {
        // Non-paginated response
        allSeats = (data.values.first as List? ?? [])
            .map((json) => Seat.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } else if (response.data is List) {
      // Direct list response
      allSeats = (response.data as List)
          .map((json) => Seat.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    
    return allSeats;
  }

  Future<List<Reservation>> getReservations() async {
    final response = await _dio.get('/reservations/');
    return _parsePaginatedResponse(response, Reservation.fromJson);
  }

  Future<Reservation> createReservation(ReservationCreateRequest request) async {
    final response = await _dio.post('/reservations/', data: request.toJson());
    return Reservation.fromJson(response.data);
  }

  Future<void> cancelReservation(int id) async {
    await _dio.post('/reservations/$id/cancel/');
  }

  Future<void> checkInReservation(int id) async {
    await _dio.post('/reservations/$id/checkin/');
  }

  Future<void> checkOutReservation(int id) async {
    await _dio.post('/reservations/$id/checkout/');
  }

  // Notifications APIs
  Future<List<Notification>> getNotifications({bool useCache = true}) async {
    final cacheKey = 'notifications:list';
    
    // Try to get from cache first
    if (useCache) {
      try {
        final cached = await cacheManager.get<List<Notification>>(
          cacheKey,
          (json) {
            if (json.containsKey('notifications') && json['notifications'] is List) {
              return (json['notifications'] as List)
                  .map((item) => Notification.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
            return <Notification>[];
          },
        );
        if (cached != null && cached.isNotEmpty) {
          appLogger.info('Returning ${cached.length} notifications from cache');
          return cached;
        }
      } catch (e) {
        appLogger.warning('Error reading from cache: $e');
      }
    }
    
    // Fetch from API
    final response = await _dio.get('/notifications/');
    final notifications = _parsePaginatedResponse(response, Notification.fromJson);
    
    // Cache the response
    if (useCache && notifications.isNotEmpty) {
      try {
        await cacheManager.set(
          cacheKey,
          notifications,
          (items) => {'notifications': items.map((item) => item.toJson()).toList()},
          ttl: 60, // Cache for 1 minute
        );
      } catch (e) {
        appLogger.warning('Error caching notifications: $e');
      }
    }
    
    return notifications;
  }

  Future<void> markNotificationAsRead(int id) async {
    await _dio.patch('/notifications/$id/mark-read/');
  }

  Future<void> markAllNotificationsAsRead() async {
    await _dio.post('/notifications/mark-all-read/');
    // Invalidate cache
    await cacheManager.remove('notifications:list');
  }

  Future<void> deleteNotification(int id) async {
    await _dio.delete('/notifications/$id/');
    // Invalidate cache
    await cacheManager.remove('notifications:list');
  }

  // Quiet Hours APIs
  Future<Map<String, dynamic>> getQuietHoursStatus() async {
    final response = await _dio.get('/notifications/quiet-hours/status/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> setQuietHours({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    String timezone = 'Asia/Kolkata',
  }) async {
    final response = await _dio.post(
      '/notifications/quiet-hours/set/',
      data: {
        'start_hour': startHour,
        'start_minute': startMinute,
        'end_hour': endHour,
        'end_minute': endMinute,
        'timezone': timezone,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> disableQuietHours() async {
    await _dio.post('/notifications/quiet-hours/disable/');
  }

  // Digest APIs
  Future<List<Map<String, dynamic>>> getDigests() async {
    final response = await _dio.get('/notifications/digests/');
    if (response.data is List) {
      return (response.data as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> getDigest(int id) async {
    final response = await _dio.get('/notifications/digests/$id/');
    return response.data as Map<String, dynamic>;
  }

  Future<void> markDigestAsRead(int id) async {
    await _dio.patch('/notifications/digests/$id/read/');
  }

  Future<Map<String, dynamic>> generateDailyDigest() async {
    final response = await _dio.post('/notifications/digests/generate-daily/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateWeeklyDigest() async {
    final response = await _dio.post('/notifications/digests/generate-weekly/');
    return response.data as Map<String, dynamic>;
  }

  // Tier APIs
  Future<List<Map<String, dynamic>>> getTiers() async {
    final response = await _dio.get('/notifications/tiers/');
    if (response.data is List) {
      return (response.data as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> createTier(Map<String, dynamic> data) async {
    final response = await _dio.post('/notifications/tiers/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTier(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/notifications/tiers/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteTier(int id) async {
    await _dio.delete('/notifications/tiers/$id/');
  }

  // Summary APIs
  Future<Map<String, dynamic>> getSummary(int notificationId) async {
    final response = await _dio.get('/notifications/summaries/$notificationId/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateSummary({
    required int notificationId,
    String summaryType = 'short',
  }) async {
    final response = await _dio.post(
      '/notifications/summaries/generate/',
      data: {
        'notification_id': notificationId,
        'summary_type': summaryType,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // Priority APIs
  Future<List<Map<String, dynamic>>> getPriorityRules() async {
    final response = await _dio.get('/notifications/priority-rules/');
    if (response.data is List) {
      return (response.data as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> createPriorityRule(Map<String, dynamic> data) async {
    final response = await _dio.post('/notifications/priority-rules/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePriorityRule(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/notifications/priority-rules/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deletePriorityRule(int id) async {
    await _dio.delete('/notifications/priority-rules/$id/');
  }

  Future<Map<String, dynamic>> getNotificationPriority(int notificationId) async {
    final response = await _dio.get('/notifications/notifications/$notificationId/priority/');
    return response.data as Map<String, dynamic>;
  }

  Future<List<Notification>> filterByPriority(String priority) async {
    final response = await _dio.get(
      '/notifications/notifications/filter-by-priority/',
      queryParameters: {'priority': priority},
    );
    if (response.data is List) {
      return (response.data as List)
          .map((item) => Notification.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // FCM and Push Notification Features
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final response = await _dio.get('/notifications/preferences/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    final response = await _dio.put('/notifications/preferences/', data: preferences);
    return response.data as Map<String, dynamic>;
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get('/notifications/unread-count/');
    return response.data['unread_count'] as int;
  }

  // FCM Token Management
  Future<List<Map<String, dynamic>>> getFCMTokens() async {
    final response = await _dio.get('/notifications/fcm-tokens/');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getFCMToken(int tokenId) async {
    final response = await _dio.get('/notifications/fcm-tokens/$tokenId/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerFCMTokenForNotifications(String token) async {
    final response = await _dio.post('/notifications/fcm-tokens/register/', data: {
      'token': token,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> unregisterFCMTokenForNotifications(String token) async {
    await _dio.post('/notifications/fcm-tokens/$token/unregister/');
  }

  // Push Notification Endpoints (Admin)
  Future<Map<String, dynamic>> sendPushNotification({
    required String title,
    required String body,
    List<int>? userIds,
    String? topic,
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.post('/notifications/push-notifications/send/', data: {
      'title': title,
      'body': body,
      if (userIds != null) 'user_ids': userIds,
      if (topic != null) 'topic': topic,
      if (data != null) 'data': data,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendTopicNotification({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.post('/notifications/push-notifications/topic/', data: {
      'topic': topic,
      'title': title,
      'body': body,
      if (data != null) 'data': data,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getNotificationHistory({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _dio.get(
      '/notifications/push-notifications/history/',
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      },
    );
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // Topic Subscription
  Future<void> subscribeToTopic(String topic) async {
    await _dio.post('/notifications/topics/subscribe/', data: {'topic': topic});
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _dio.post('/notifications/topics/unsubscribe/', data: {'topic': topic});
  }

  // Notification Templates
  Future<List<Map<String, dynamic>>> getNotificationTemplates() async {
    final response = await _dio.get('/notifications/templates/');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getNotificationTemplate(int templateId) async {
    final response = await _dio.get('/notifications/templates/$templateId/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createNotificationTemplate(Map<String, dynamic> data) async {
    final response = await _dio.post('/notifications/templates/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateNotificationTemplate(int templateId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/notifications/templates/$templateId/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteNotificationTemplate(int templateId) async {
    await _dio.delete('/notifications/templates/$templateId/');
  }

  Future<Map<String, dynamic>> sendTemplateNotification({
    required int templateId,
    List<int>? userIds,
    String? topic,
    Map<String, dynamic>? variables,
  }) async {
    final response = await _dio.post('/notifications/templates/send/', data: {
      'template_id': templateId,
      if (userIds != null) 'user_ids': userIds,
      if (topic != null) 'topic': topic,
      if (variables != null) 'variables': variables,
    });
    return response.data as Map<String, dynamic>;
  }

  // Chatbot APIs
  Future<List<ChatbotCategory>> getChatbotCategories() async {
    final response = await _dio.get('/chatbot/categories/');
    return _parsePaginatedResponse(response, ChatbotCategory.fromJson);
  }

  Future<List<ChatbotQuestion>> getChatbotQuestions({int? categoryId}) async {
    final queryParams = categoryId != null ? {'category_id': categoryId} : <String, dynamic>{};
    final response = await _dio.get('/chatbot/questions/', queryParameters: queryParams);
    return _parsePaginatedResponse(response, ChatbotQuestion.fromJson);
  }

  Future<List<ChatbotQuestion>> getChatbotFAQs() async {
    final response = await _dio.get('/chatbot/questions/');
    return _parsePaginatedResponse(response, ChatbotQuestion.fromJson);
  }

  Future<ChatbotConversation> createChatbotConversation() async {
    final response = await _dio.post('/chatbot/conversations/');
    return ChatbotConversation.fromJson(response.data);
  }

  Future<ChatbotMessage> sendChatbotMessage(int conversationId, String message) async {
    final response = await _dio.post('/chatbot/conversations/$conversationId/messages/', data: {
      'message': message,
    });
    return ChatbotMessage.fromJson(response.data);
  }

  // Additional missing methods
  Future<ChatbotConversation> createChatbotSession() async {
    final response = await _dio.post('/chatbot/sessions/');
    return ChatbotConversation.fromJson(response.data);
  }

  Future<List<Reservation>> getUserReservations() async {
    final response = await _dio.get('/reservations/user/');
    return _parsePaginatedResponse(response, Reservation.fromJson);
  }

  Future<List<Notification>> getUserNotifications() async {
    final response = await _dio.get('/notifications/');
    return _parsePaginatedResponse(response, Notification.fromJson);
  }

  Future<List<ChatbotConversation>> getUserChatbotSessions() async {
    final response = await _dio.get('/chatbot/sessions/user/');
    return _parsePaginatedResponse(response, ChatbotConversation.fromJson);
  }

  // Enhanced Chatbot APIs
  Future<ChatbotResponse> sendChatbotMessageWithFAQ({
    required String message,
    String? sessionId,
    int? categoryId,
  }) async {
    final response = await _dio.post('/chatbot/chat/', data: {
      'message': message,
      'session_id': sessionId,
      'category_id': categoryId,
    });
    return ChatbotResponse.fromJson(response.data);
  }

  Future<List<ChatbotQuestion>> getQuestionSuggestions({
    required String query,
    int? categoryId,
    int limit = 5,
  }) async {
    final response = await _dio.get('/chatbot/suggestions/', queryParameters: {
      'query': query,
      if (categoryId != null) 'category_id': categoryId,
      'limit': limit,
    });
    return (response.data as List)
        .map((json) => ChatbotQuestion.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatbotQuestion>> searchFAQ({
    required String query,
    int? categoryId,
    int limit = 10,
  }) async {
    final response = await _dio.get('/chatbot/search/', queryParameters: {
      'query': query,
      if (categoryId != null) 'category_id': categoryId,
      'limit': limit,
    });
    return (response.data as List)
        .map((json) => ChatbotQuestion.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatbotQuestion>> getPopularQuestions({
    int? categoryId,
    int limit = 10,
  }) async {
    final response = await _dio.get('/chatbot/popular/', queryParameters: {
      if (categoryId != null) 'category_id': categoryId,
      'limit': limit,
    });
    return (response.data as List)
        .map((json) => ChatbotQuestion.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitChatbotFeedback({
    required String sessionId,
    required int messageId,
    required int rating,
    String? comment,
  }) async {
    await _dio.post('/chatbot/feedback/', data: {
      'session_id': sessionId,
      'message_id': messageId,
      'rating': rating,
      'comment': comment,
    });
  }

  // NLP-enhanced Chatbot APIs
  Future<EnhancedChatbotResponse> sendEnhancedChatbotMessage({
    required String message,
    String? sessionId,
    int? categoryId,
  }) async {
    final response = await _dio.post('/chatbot/chat/', data: {
      'message': message,
      if (sessionId != null) 'session_id': sessionId,
      if (categoryId != null) 'category_id': categoryId,
    });
    return EnhancedChatbotResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ConversationContext> getConversationContext(String sessionId) async {
    final response = await _dio.get('/chatbot/context/$sessionId/');
    return ConversationContext.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> clearConversationContext(String sessionId) async {
    await _dio.post('/chatbot/context/$sessionId/clear/');
  }

  // Personalization APIs
  Future<ChatbotUserProfile> getChatbotUserProfile() async {
    final response = await _dio.get('/chatbot/profile/');
    // Backend returns: { 'profile': {...}, 'preferences': {...}, 'statistics': {...} }
    // The profile key already contains all ChatbotUserProfile fields including id, user_id, total_interactions, etc.
    final profileData = response.data['profile'] as Map<String, dynamic>;
    return ChatbotUserProfile.fromJson(profileData);
  }

  Future<void> updateChatbotUserProfile({
    String? preferredLanguage,
    String? responseStyle,
    Map<String, dynamic>? preferences,
    bool? isPersonalizedEnabled,
  }) async {
    final data = <String, dynamic>{};
    if (preferredLanguage != null) data['preferred_language'] = preferredLanguage;
    if (responseStyle != null) data['response_style'] = responseStyle;
    if (preferences != null) data['preferences'] = preferences;
    if (isPersonalizedEnabled != null) data['is_personalized_enabled'] = isPersonalizedEnabled;
    
    await _dio.put('/chatbot/profile/update/', data: data);
  }

  Future<List<ChatbotQuestion>> getPersonalizedRecommendations({
    int limit = 5,
  }) async {
    final response = await _dio.get('/chatbot/recommendations/', queryParameters: {
      'limit': limit,
    });
    return (response.data as List)
        .map((json) => ChatbotQuestion.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getUserInteractionHistory({
    int limit = 10,
  }) async {
    final response = await _dio.get('/chatbot/history/', queryParameters: {
      'limit': limit,
    });
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<ChatbotUserStatistics> getUserStatistics() async {
    final response = await _dio.get('/chatbot/statistics/');
    return ChatbotUserStatistics.fromJson(response.data as Map<String, dynamic>);
  }

  // Action execution APIs
  Future<List<ChatbotAction>> getAvailableActions() async {
    final response = await _dio.get('/chatbot/actions/');
    return (response.data as List)
        .map((json) => ChatbotAction.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ChatbotActionExecution> executeAction({
    required int actionId,
    required String sessionId,
    required Map<String, dynamic> parameters,
  }) async {
    final response = await _dio.post(
      '/chatbot/actions/$actionId/execute/',
      data: {
        'session_id': sessionId,
        'parameters': parameters,
      },
    );
    return ChatbotActionExecution.fromJson(response.data as Map<String, dynamic>);
  }

  // Knowledge base APIs
  Future<AnswerQualityMetrics> getAnswerQualityMetrics(int questionId) async {
    final response = await _dio.get('/chatbot/questions/$questionId/quality/');
    return AnswerQualityMetrics.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<String>> getSuggestedImprovements(int questionId) async {
    final response = await _dio.get('/chatbot/questions/$questionId/suggestions/');
    return (response.data['suggestions'] as List).cast<String>();
  }

  Future<List<List<int>>> clusterQuestions({double threshold = 0.7}) async {
    final response = await _dio.post('/chatbot/questions/cluster/', data: {
      'threshold': threshold,
    });
    return (response.data['clusters'] as List)
        .map((cluster) => (cluster as List).cast<int>())
        .toList();
  }

  Future<List<Map<String, dynamic>>> getUnansweredQuestions({
    int limit = 10,
  }) async {
    final response = await _dio.get('/chatbot/questions/unanswered/', queryParameters: {
      'limit': limit,
    });
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getPopularTopics({
    int limit = 10,
  }) async {
    final response = await _dio.get('/chatbot/topics/popular/', queryParameters: {
      'limit': limit,
    });
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // Calendar Events API
  Future<List<CalendarEvent>> getCalendarEvents({
    String? startDate,
    String? endDate,
    String? eventType,
    bool? isCancelled,
    String? privacy,
    String? search,
  }) async {
    print('📅 getCalendarEvents called with params: startDate=$startDate, endDate=$endDate, eventType=$eventType, isCancelled=$isCancelled, privacy=$privacy');
    
    final response = await _dio.get('/calendars/events/', queryParameters: {
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (eventType != null) 'event_type': eventType,
      if (isCancelled != null) 'is_cancelled': isCancelled.toString(),
      if (privacy != null) 'privacy': privacy,
      if (search != null) 'search': search,
    });
    
    print('📅 Response status: ${response.statusCode}');
    print('📅 Response data type: ${response.data.runtimeType}');
    
    // Handle paginated response (Django REST Framework returns {results: [...]})
    // or direct list response
    try {
      List<dynamic> eventsList;
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('results')) {
          // Paginated response
          eventsList = data['results'] as List;
          print('📅 Found paginated response with ${eventsList.length} events');
        } else {
          // If it's a Map but no 'results' key, return empty list
          print('📅 Response is Map but no results key found');
          return [];
        }
      } else if (response.data is List) {
        // Direct list response
        eventsList = response.data as List;
        print('📅 Found direct list response with ${eventsList.length} events');
      } else {
        print('📅 Unexpected response type: ${response.data.runtimeType}');
        return [];
      }
      
      final events = eventsList
          .map((json) {
            try {
              return CalendarEvent.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              print('📅 Error parsing event: $e');
              print('📅 Event JSON: $json');
              return null;
            }
          })
          .where((event) => event != null)
          .cast<CalendarEvent>()
          .toList();
      
      print('📅 Successfully parsed ${events.length} events');
      for (final event in events) {
        print('   - Event ${event.id}: ${event.title} - ${event.startTime} (allDay: ${event.allDay})');
      }
      
      return events;
    } catch (e, stackTrace) {
      print('📅 Error parsing calendar events: $e');
      print('📅 Stack trace: $stackTrace');
      print('📅 Response data: ${response.data}');
      return [];
    }
  }

  Future<CalendarEvent> getCalendarEvent(int id) async {
    final response = await _dio.get('/calendars/events/$id/');
    return CalendarEvent.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CalendarEvent> createCalendarEvent(CalendarEvent event) async {
    try {
      // Ensure all required fields are present before sending
      final eventData = event.toJson();
      
      // Validate required fields
      if (eventData['title'] == null || (eventData['title'] as String).isEmpty) {
        throw Exception('Event title is required');
      }
      if (eventData['event_type'] == null || (eventData['event_type'] as String).isEmpty) {
        eventData['event_type'] = 'event';
      }
      if (eventData['timezone'] == null || (eventData['timezone'] as String).isEmpty) {
        eventData['timezone'] = 'UTC';
      }
      if (eventData['recurrence_pattern'] == null || (eventData['recurrence_pattern'] as String).isEmpty) {
        eventData['recurrence_pattern'] = 'none';
      }
      if (eventData['color'] == null || (eventData['color'] as String).isEmpty) {
        eventData['color'] = '#3b82f6';
      }
      if (eventData['privacy'] == null || (eventData['privacy'] as String).isEmpty) {
        eventData['privacy'] = 'private';
      }
      
      final response = await _dio.post(
        '/calendars/events/',
        data: eventData,
      );
      
      // Ensure response data is valid before parsing
      if (response.data == null) {
        throw Exception('Invalid response from server');
      }
      
      return CalendarEvent.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('Error creating calendar event: $e');
      print('Event data: ${event.toJson()}');
      rethrow;
    }
  }

  Future<CalendarEvent> updateCalendarEvent(int id, CalendarEvent event) async {
    final response = await _dio.patch(
      '/calendars/events/$id/',
      data: event.toJson(),
    );
    return CalendarEvent.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCalendarEvent(int id) async {
    await _dio.delete('/calendars/events/$id/');
  }

  Future<List<CalendarEvent>> getUpcomingEvents({int days = 7}) async {
    final response = await _dio.get(
      '/calendars/events/upcoming/',
      queryParameters: {'days': days},
    );
    
    // Handle paginated response or direct list response
    try {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('results')) {
          return (data['results'] as List)
              .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else if (response.data is List) {
        return (response.data as List)
            .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing upcoming events: $e');
      return [];
    }
  }

  Future<List<CalendarEvent>> getEventsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _dio.get(
      '/calendars/events/date-range/',
      queryParameters: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
    );
    
    // Handle paginated response or direct list response
    try {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('results')) {
          return (data['results'] as List)
              .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else if (response.data is List) {
        return (response.data as List)
            .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing events by date range: $e');
      return [];
    }
  }

  Future<List<CalendarEvent>> getEventsByType(String eventType) async {
    final response = await _dio.get('/calendars/events/type/$eventType/');
    
    // Handle paginated response or direct list response
    try {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('results')) {
          return (data['results'] as List)
              .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else if (response.data is List) {
        return (response.data as List)
            .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing events by type: $e');
      return [];
    }
  }

  Future<CalendarEvent> cancelCalendarEvent(int id) async {
    final response = await _dio.post('/calendars/events/$id/cancel/');
    return CalendarEvent.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EventReminder> addEventReminder({
    required int eventId,
    required String reminderType,
    required int minutesBefore,
  }) async {
    final response = await _dio.post(
      '/calendars/events/$eventId/reminders/',
      data: {
        'reminder_type': reminderType,
        'minutes_before': minutesBefore,
      },
    );
    return EventReminder.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> removeEventReminder({
    required int eventId,
    String? reminderType,
    int? minutesBefore,
  }) async {
    await _dio.delete(
      '/calendars/events/$eventId/reminders/remove/',
      data: {
        if (reminderType != null) 'reminder_type': reminderType,
        if (minutesBefore != null) 'minutes_before': minutesBefore,
      },
    );
  }

  // iCal export/import
  Future<Uint8List> exportICal() async {
    final response = await _dio.get(
      '/calendars/ical/export/',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'Accept': 'text/calendar',
        },
      ),
    );
    if (response.data is List<int>) {
      return Uint8List.fromList(response.data as List<int>);
    } else if (response.data is List) {
      return Uint8List.fromList((response.data as List).cast<int>());
    } else {
      throw Exception('Unexpected response type for iCal export');
    }
  }

  Future<List<CalendarEvent>> importICal(Uint8List icalContent) async {
    final formData = FormData.fromMap({
      'ical_file': MultipartFile.fromBytes(
        icalContent,
        filename: 'calendar.ics',
      ),
    });
    final response = await _dio.post(
      '/calendars/ical/import/',
      data: formData,
    );
    return (response.data as List)
        .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<String> getICalFeedUrl(int userId) async {
    final response = await _dio.get('/calendars/ical/feed/$userId/');
    return response.data['feed_url'] as String;
  }

  // Google Calendar integration
  Future<Map<String, dynamic>> getGoogleCalendarAuthorizationUrl() async {
    final response = await _dio.get('/calendars/google/authorize/');
    return response.data as Map<String, dynamic>;
  }

  Future<GoogleCalendarSync> connectGoogleCalendar({
    required String authorizationCode,
    String? state,
  }) async {
    final response = await _dio.post(
      '/calendars/google/callback/',
      data: {
        'authorization_code': authorizationCode,
        if (state != null) 'state': state,
      },
    );
    return GoogleCalendarSync.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> disconnectGoogleCalendar() async {
    await _dio.post('/calendars/google/disconnect/');
  }

  Future<GoogleCalendarSync> getGoogleCalendarSyncStatus() async {
    final response = await _dio.get('/calendars/google/sync-status/');
    return GoogleCalendarSync.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CalendarEvent>> syncGoogleCalendar({
    String syncDirection = 'bidirectional',
  }) async {
    final response = await _dio.post(
      '/calendars/google/sync/',
      data: {'sync_direction': syncDirection},
    );
    return (response.data as List)
        .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Recommendation APIs
  Future<List<Recommendation>> getRecommendations({
    String? contentType,
    String recommendationType = 'content_based',
    bool excludeDismissed = true,
    bool excludeViewed = false,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      '/recommendations/',
      queryParameters: {
        if (contentType != null) 'content_type': contentType,
        'recommendation_type': recommendationType,
        'exclude_dismissed': excludeDismissed.toString(),
        'exclude_viewed': excludeViewed.toString(),
        'limit': limit.toString(),
      },
    );
    return (response.data as List)
        .map((json) => Recommendation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Recommendation>> getNoticeRecommendations({
    String recommendationType = 'content_based',
    int limit = 10,
  }) async {
    final response = await _dio.get(
      '/recommendations/notices/',
      queryParameters: {
        'recommendation_type': recommendationType,
        'limit': limit.toString(),
      },
    );
    return (response.data as List)
        .map((json) => Recommendation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Recommendation>> getStudyGroupRecommendations({
    String recommendationType = 'content_based',
    int limit = 10,
  }) async {
    final response = await _dio.get(
      '/recommendations/study-groups/',
      queryParameters: {
        'recommendation_type': recommendationType,
        'limit': limit.toString(),
      },
    );
    return (response.data as List)
        .map((json) => Recommendation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Recommendation>> getResourceRecommendations({
    String recommendationType = 'content_based',
    int limit = 10,
  }) async {
    final response = await _dio.get(
      '/recommendations/resources/',
      queryParameters: {
        'recommendation_type': recommendationType,
        'limit': limit.toString(),
      },
    );
    return (response.data as List)
        .map((json) => Recommendation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> dismissRecommendation(int recommendationId) async {
    await _dio.post('/recommendations/$recommendationId/dismiss/');
  }

  Future<void> submitRecommendationFeedback({
    required String contentType,
    required int contentId,
    String? recommendationType,
    required String feedbackType,
    required Map<String, dynamic> feedbackData,
  }) async {
    await _dio.post(
      '/recommendations/feedback/',
      data: {
        'content_type': contentType,
        'content_id': contentId,
        if (recommendationType != null) 'recommendation_type': recommendationType,
        'feedback_type': feedbackType,
        'feedback_data': feedbackData,
      },
    );
  }

  Future<List<Recommendation>> refreshRecommendations({
    String contentType = 'notice',
    String recommendationType = 'content_based',
    int limit = 10,
    bool clearExisting = false,
  }) async {
    final response = await _dio.post(
      '/recommendations/refresh/',
      data: {
        'content_type': contentType,
        'recommendation_type': recommendationType,
        'limit': limit,
        'clear_existing': clearExisting,
      },
    );
    return (response.data as List)
        .map((json) => Recommendation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<PopularItem>> getPopularItems({
    String contentType = 'notice',
    int limit = 10,
  }) async {
    final response = await _dio.get(
      '/recommendations/popular/',
      queryParameters: {
        'content_type': contentType,
        'limit': limit.toString(),
      },
    );
    return (response.data as List)
        .map((json) => PopularItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<TrendingItem>> getTrendingItems({
    String contentType = 'notice',
    int limit = 10,
    int days = 7,
  }) async {
    final response = await _dio.get(
      '/recommendations/trending/',
      queryParameters: {
        'content_type': contentType,
        'limit': limit.toString(),
        'days': days.toString(),
      },
    );
    return (response.data as List)
        .map((json) => TrendingItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<UserPreference> getUserPreference({
    String contentType = 'notice',
  }) async {
    final response = await _dio.get(
      '/recommendations/preferences/',
      queryParameters: {'content_type': contentType},
    );
    return UserPreference.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserPreference> updateUserPreference({
    String contentType = 'notice',
    Map<String, dynamic>? preferences,
    List<String>? interests,
    Map<String, dynamic>? behaviorPatterns,
    Map<String, dynamic>? weightPreferences,
  }) async {
    final data = <String, dynamic>{};
    if (preferences != null) data['preferences'] = preferences;
    if (interests != null) data['interests'] = interests;
    if (behaviorPatterns != null) data['behavior_patterns'] = behaviorPatterns;
    if (weightPreferences != null) data['weight_preferences'] = weightPreferences;

    final response = await _dio.put(
      '/recommendations/preferences/',
      queryParameters: {'content_type': contentType},
      data: data,
    );
    return UserPreference.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ContentInteraction>> getContentInteractions() async {
    final response = await _dio.get('/recommendations/interactions/');
    return (response.data as List)
        .map((json) => ContentInteraction.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ContentInteraction> trackInteraction({
    required String contentType,
    required int contentId,
    required String interactionType,
    int? rating,
    int? duration,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _dio.post(
      '/recommendations/interactions/',
      data: {
        'content_type': contentType,
        'content_id': contentId,
        'interaction_type': interactionType,
        if (rating != null) 'rating': rating,
        if (duration != null) 'duration': duration,
        if (metadata != null) 'metadata': metadata,
      },
    );
    return ContentInteraction.fromJson(response.data as Map<String, dynamic>);
  }

  // ============================
  // Gamification API Methods
  // ============================

  // Achievements
  Future<List<Achievement>> getAchievements() async {
    final response = await _dio.get('/gamification/achievements/');
    
    // Handle paginated response (Django REST Framework returns {results: [...]})
    // or direct list response
    try {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('results')) {
          // Paginated response
          return (data['results'] as List)
              .map((json) => Achievement.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        // If it's a Map but no 'results' key, return empty list
        return [];
      } else if (response.data is List) {
        // Direct list response
        return (response.data as List)
            .map((json) => Achievement.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing achievements: $e, type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');
      return [];
    }
  }

  Future<List<UserAchievement>> getUserAchievements({bool unlockedOnly = false}) async {
    final response = await _dio.get(
      '/gamification/achievements/user/',
      queryParameters: {'unlocked_only': unlockedOnly},
    );
    
    // Handle paginated response or direct list response
    try {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('results')) {
          return (data['results'] as List)
              .map((json) => UserAchievement.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else if (response.data is List) {
        return (response.data as List)
            .map((json) => UserAchievement.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing user achievements: $e');
      return [];
    }
  }

  Future<List<UserAchievement>> getAvailableAchievements() async {
    final response = await _dio.get('/gamification/achievements/available/');
    
    // Handle paginated response or direct list response
    try {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('results')) {
          return (data['results'] as List)
              .map((json) => UserAchievement.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else if (response.data is List) {
        return (response.data as List)
            .map((json) => UserAchievement.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing available achievements: $e');
      return [];
    }
  }

  // Points
  Future<UserPoints> getUserPoints() async {
    final response = await _dio.get('/gamification/points/');
    return UserPoints.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PointTransaction>> getPointTransactions() async {
    final response = await _dio.get('/gamification/points/transactions/');
    
    // Handle paginated response or direct list response
    try {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('results')) {
          return (data['results'] as List)
              .map((json) => PointTransaction.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else if (response.data is List) {
        return (response.data as List)
            .map((json) => PointTransaction.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing point transactions: $e');
      return [];
    }
  }

  // Rewards
  Future<List<Reward>> getRewards() async {
    final response = await _dio.get('/gamification/rewards/');
    
    // Handle paginated response or direct list response
    try {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('results')) {
          return (data['results'] as List)
              .map((json) => Reward.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else if (response.data is List) {
        return (response.data as List)
            .map((json) => Reward.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing rewards: $e');
      return [];
    }
  }

  Future<RewardRedemption> redeemReward(int rewardId) async {
    final response = await _dio.post(
      '/gamification/rewards/redeem/',
      data: {'reward_id': rewardId},
    );
    return RewardRedemption.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<RewardRedemption>> getUserRewardRedemptions() async {
    final response = await _dio.get('/gamification/rewards/my-redemptions/');
    
    // Handle paginated response or direct list response
    try {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('results')) {
          return (data['results'] as List)
              .map((json) => RewardRedemption.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else if (response.data is List) {
        return (response.data as List)
            .map((json) => RewardRedemption.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing reward redemptions: $e');
      return [];
    }
  }

  // Streak
  Future<UserStreak> getUserStreak() async {
    final response = await _dio.get('/gamification/streak/');
    return UserStreak.fromJson(response.data as Map<String, dynamic>);
  }

  // Leaderboards
  Future<List<LeaderboardEntry>> getLeaderboard({
    required String leaderboardType,
    String period = 'all_time',
    int limit = 100,
  }) async {
    final response = await _dio.get(
      '/gamification/leaderboard/$leaderboardType/$period/',
      queryParameters: {'limit': limit},
    );
    return (response.data as List)
        .map((json) => LeaderboardEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getUserRank({
    required String leaderboardType,
    String period = 'all_time',
  }) async {
    final response = await _dio.get(
      '/gamification/leaderboard/$leaderboardType/$period/rank/',
    );
    return response.data as Map<String, dynamic>;
  }

  // Stats
  Future<UserGamificationStats> getUserGamificationStats() async {
    final response = await _dio.get('/gamification/stats/');
    return UserGamificationStats.fromJson(response.data as Map<String, dynamic>);
  }

  // Actions
  Future<Map<String, dynamic>> checkAchievements({
    required String achievementType,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _dio.post(
      '/gamification/check-achievements/',
      data: {
        'achievement_type': achievementType,
        if (metadata != null) 'metadata': metadata,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ============================
  // Academic Planner API Methods
  // ============================

  // Courses
  Future<List<Course>> getCourses({int? semester, String? academicYear}) async {
    final response = await _dio.get(
      '/academic/courses/',
      queryParameters: {
        if (semester != null) 'semester': semester,
        if (academicYear != null) 'academic_year': academicYear,
      },
    );
    
    // Handle paginated response (Django REST Framework returns {results: [...]})
    // or direct list response
    try {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('results')) {
          // Paginated response
          return (data['results'] as List)
              .map((json) => Course.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        // If it's a Map but no 'results' key, return empty list
        return [];
      } else if (response.data is List) {
        // Direct list response
        return (response.data as List)
            .map((json) => Course.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing courses: $e, type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');
      return [];
    }
  }

  Future<Course> getCourse(int courseId) async {
    final response = await _dio.get('/academic/courses/$courseId/');
    return Course.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Course> createCourse(Map<String, dynamic> data) async {
    final response = await _dio.post('/academic/courses/', data: data);
    return Course.fromJson(response.data as Map<String, dynamic>);
  }

  // Course Enrollments
  Future<List<CourseEnrollment>> getCourseEnrollments() async {
    final response = await _dio.get('/academic/enrollments/');
    
    // Handle paginated response (Django REST Framework returns {results: [...]})
    // or direct list response
    try {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('results')) {
          // Paginated response
          return (data['results'] as List)
              .map((json) => CourseEnrollment.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        // If it's a Map but no 'results' key, return empty list
        return [];
      } else if (response.data is List) {
        // Direct list response
        return (response.data as List)
            .map((json) => CourseEnrollment.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing course enrollments: $e, type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');
      return [];
    }
  }

  Future<CourseEnrollment> enrollInCourse(int courseId) async {
    try {
      final response = await _dio.post(
        '/academic/enrollments/',
        data: {'course_id': courseId},
      );
      
      if (response.statusCode == null || response.statusCode! >= 400) {
        final errorMessage = response.data is Map
            ? (response.data['error'] ?? response.data['detail'] ?? 'Failed to enroll in course')
            : 'Failed to enroll in course';
        throw Exception(errorMessage);
      }
      
      return CourseEnrollment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map
            ? (errorData['error'] ?? errorData['detail'] ?? errorData['course_id'] ?? 'Failed to enroll in course')
            : 'Failed to enroll in course';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> dropCourse(int enrollmentId) async {
    await _dio.delete('/academic/enrollments/$enrollmentId/');
  }

  // Assignments
  Future<List<Assignment>> getAssignments({
    int? courseId,
    String? status,
  }) async {
    final response = await _dio.get(
      '/academic/assignments/',
      queryParameters: {
        if (courseId != null) 'course_id': courseId,
        if (status != null) 'status': status,
      },
    );
    return (response.data as List)
        .map((json) => Assignment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Assignment> getAssignment(int assignmentId) async {
    final response = await _dio.get('/academic/assignments/$assignmentId/');
    return Assignment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Assignment> createAssignment(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/academic/assignments/', data: data);
      
      if (response.statusCode == null || response.statusCode! >= 400) {
        final errorMessage = response.data is Map
            ? (response.data['error'] ?? response.data['detail'] ?? 'Failed to create assignment')
            : 'Failed to create assignment';
        throw Exception(errorMessage);
      }
      
      return Assignment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map
            ? (errorData['error'] ?? errorData['detail'] ?? errorData['course_id'] ?? 'Failed to create assignment')
            : 'Failed to create assignment';
        throw Exception(errorMessage);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Assignment> submitAssignment(int assignmentId, String? submissionLink) async {
    final response = await _dio.post(
      '/academic/assignments/$assignmentId/submit/',
      data: {
        if (submissionLink != null) 'submission_link': submissionLink,
      },
    );
    return Assignment.fromJson(response.data as Map<String, dynamic>);
  }

  // Grades
  Future<List<Grade>> getGrades({int? semester, String? academicYear}) async {
    final response = await _dio.get(
      '/academic/grades/',
      queryParameters: {
        if (semester != null) 'semester': semester,
        if (academicYear != null) 'academic_year': academicYear,
      },
    );
    return (response.data as List)
        .map((json) => Grade.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Grade> getGrade(int gradeId) async {
    final response = await _dio.get('/academic/grades/$gradeId/');
    return Grade.fromJson(response.data as Map<String, dynamic>);
  }

  // Academic Reminders
  Future<List<AcademicReminder>> getAcademicReminders() async {
    final response = await _dio.get('/academic/reminders/');
    return (response.data as List)
        .map((json) => AcademicReminder.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<AcademicReminder> createAcademicReminder(Map<String, dynamic> data) async {
    final response = await _dio.post('/academic/reminders/', data: data);
    return AcademicReminder.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> completeReminder(int reminderId) async {
    await _dio.patch(
      '/academic/reminders/$reminderId/',
      data: {'is_completed': true},
    );
  }

  Future<void> deleteReminder(int reminderId) async {
    await _dio.delete('/academic/reminders/$reminderId/');
  }

  // Dashboard and Statistics
  Future<AcademicDashboard> getAcademicDashboard() async {
    final response = await _dio.get('/academic/dashboard/');
    return AcademicDashboard.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getUpcomingDeadlines({int days = 7}) async {
    final response = await _dio.get(
      '/academic/deadlines/',
      queryParameters: {'days': days},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> calculateGPA({int? semester, String? academicYear}) async {
    final response = await _dio.get(
      '/academic/gpa/',
      queryParameters: {
        if (semester != null) 'semester': semester,
        if (academicYear != null) 'academic_year': academicYear,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> calculateCourseGrade(int courseId, {int? semester, String? academicYear}) async {
    final response = await _dio.post(
      '/academic/courses/$courseId/calculate-grade/',
      data: {
        if (semester != null) 'semester': semester,
        if (academicYear != null) 'academic_year': academicYear,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ============================
  // Marketplace API Methods
  // ============================

  // Marketplace Items
  Future<List<MarketplaceItem>> getMarketplaceItems({
    String? itemType,
    String? status,
    String? search,
  }) async {
    final response = await _dio.get(
      '/marketplace/items/',
      queryParameters: {
        if (itemType != null) 'item_type': itemType,
        if (status != null) 'status': status,
        if (search != null) 'search': search,
      },
    );
    // Handle paginated response: extract 'results' if present, otherwise use data directly
    final data = response.data;
    final List<dynamic> items;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      items = data['results'] as List<dynamic>;
    } else if (data is List) {
      items = data;
    } else {
      return [];
    }
    return items
        .map((json) => MarketplaceItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<MarketplaceItem> getMarketplaceItem(int itemId) async {
    final response = await _dio.get('/marketplace/items/$itemId/');
    return MarketplaceItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MarketplaceItem> createMarketplaceItem(Map<String, dynamic> data) async {
    final response = await _dio.post('/marketplace/items/', data: data);
    return MarketplaceItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<MarketplaceItem>> getMyListings() async {
    final response = await _dio.get('/marketplace/my-listings/');
    // Handle paginated response: extract 'results' if present, otherwise use data directly
    final data = response.data;
    final List<dynamic> items;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      items = data['results'] as List<dynamic>;
    } else if (data is List) {
      items = data;
    } else {
      return [];
    }
    return items
        .map((json) => MarketplaceItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Books
  Future<List<MarketplaceItem>> getBookListings({
    String? courseCode,
    String? isbn,
  }) async {
    final response = await _dio.get(
      '/marketplace/books/',
      queryParameters: {
        if (courseCode != null) 'course_code': courseCode,
        if (isbn != null) 'isbn': isbn,
      },
    );
    // Handle paginated response: extract 'results' if present, otherwise use data directly
    final data = response.data;
    final List<dynamic> items;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      items = data['results'] as List<dynamic>;
    } else if (data is List) {
      items = data;
    } else {
      return [];
    }
    return items
        .map((json) => MarketplaceItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<MarketplaceItem> getBookListing(int bookId) async {
    final response = await _dio.get('/marketplace/books/$bookId/');
    return MarketplaceItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MarketplaceItem> createBookListing(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/marketplace/books/', data: data);
      
      // Backend now returns MarketplaceItem directly
      if (response.data is Map<String, dynamic>) {
        return MarketplaceItem.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Unexpected response format: ${response.data.runtimeType}');
      }
    } catch (e) {
      print('Error creating book listing: $e');
      rethrow;
    }
  }

  // Rides
  Future<List<MarketplaceItem>> getRideListings({
    String? departureLocation,
    String? destination,
  }) async {
    final response = await _dio.get(
      '/marketplace/rides/',
      queryParameters: {
        if (departureLocation != null) 'departure_location': departureLocation,
        if (destination != null) 'destination': destination,
      },
    );
    // Handle paginated response: extract 'results' if present, otherwise use data directly
    final data = response.data;
    final List<dynamic> items;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      items = data['results'] as List<dynamic>;
    } else if (data is List) {
      items = data;
    } else {
      return [];
    }
    return items
        .map((json) => MarketplaceItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<MarketplaceItem> getRideListing(int rideId) async {
    final response = await _dio.get('/marketplace/rides/$rideId/');
    return MarketplaceItem.fromJson(response.data as Map<String, dynamic>);
  }

  // Lost & Found
  Future<List<MarketplaceItem>> getLostFoundItems({
    String? category,
    String? foundLocation,
  }) async {
    final response = await _dio.get(
      '/marketplace/lost-found/',
      queryParameters: {
        if (category != null) 'category': category,
        if (foundLocation != null) 'found_location': foundLocation,
      },
    );
    // Handle paginated response: extract 'results' if present, otherwise use data directly
    final data = response.data;
    final List<dynamic> items;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      items = data['results'] as List<dynamic>;
    } else if (data is List) {
      items = data;
    } else {
      return [];
    }
    return items
        .map((json) => MarketplaceItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<MarketplaceItem> getLostFoundItem(int itemId) async {
    final response = await _dio.get('/marketplace/lost-found/$itemId/');
    return MarketplaceItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MarketplaceItem> createLostFoundItem(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/marketplace/lost-found/', data: data);
      
      // Backend now returns MarketplaceItem directly
      if (response.data is Map<String, dynamic>) {
        return MarketplaceItem.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Unexpected response format: ${response.data.runtimeType}');
      }
    } catch (e) {
      print('Error creating lost found item: $e');
      rethrow;
    }
  }

  Future<String> uploadMarketplaceImage(XFile image) async {
    MultipartFile multipartFile;
    
    if (kIsWeb) {
      // For web, we need to use bytes
      final bytes = await image.readAsBytes();
      multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: image.name,
      );
    } else {
      // For mobile platforms
      multipartFile = await MultipartFile.fromFile(image.path);
    }
    
    final formData = FormData.fromMap({
      'image': multipartFile,
    });
    
    final response = await _dio.post(
      '/marketplace/upload-image/',
      data: formData,
    );
    
    if (response.data == null) {
      throw Exception('Invalid response from server');
    }
    
    final data = response.data as Map<String, dynamic>;
    if (!data.containsKey('image_url')) {
      throw Exception('Invalid response format from server');
    }
    
    return data['image_url'] as String;
  }

  // Transactions
  Future<List<MarketplaceTransaction>> getMarketplaceTransactions({
    String? status,
  }) async {
    final response = await _dio.get(
      '/marketplace/transactions/',
      queryParameters: {
        if (status != null) 'status': status,
      },
    );
    // Handle paginated response: extract 'results' if present, otherwise use data directly
    final data = response.data;
    final List<dynamic> items;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      items = data['results'] as List<dynamic>;
    } else if (data is List) {
      items = data;
    } else {
      return [];
    }
    return items
        .map((json) => MarketplaceTransaction.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<MarketplaceTransaction> getMarketplaceTransaction(int transactionId) async {
    final response = await _dio.get('/marketplace/transactions/$transactionId/');
    return MarketplaceTransaction.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MarketplaceTransaction> createTransaction(Map<String, dynamic> data) async {
    final response = await _dio.post('/marketplace/transactions/', data: data);
    return MarketplaceTransaction.fromJson(response.data as Map<String, dynamic>);
  }

  // Favorites
  Future<List<MarketplaceItem>> getFavorites() async {
    final response = await _dio.get('/marketplace/favorites/');
    // Handle paginated response: extract 'results' if present, otherwise use data directly
    final data = response.data;
    final List<dynamic> items;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      items = data['results'] as List<dynamic>;
    } else if (data is List) {
      items = data;
    } else {
      return [];
    }
    return items
        .map((json) => MarketplaceItem.fromJson(json['marketplace_item'] as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> toggleFavorite(int itemId) async {
    final response = await _dio.post('/marketplace/items/$itemId/favorite/');
    return response.data as Map<String, dynamic>;
  }

  // ==================== Faculty & Admin Tools ====================

  // Case Management
  Future<List<Case>> getCases({
    String? status,
    String? priority,
    bool? myCases,
  }) async {
    final response = await _dio.get(
      '/faculty-admin/cases/',
      queryParameters: {
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (myCases == true) 'my_cases': 'true',
      },
    );
    return _parsePaginatedResponse(response, Case.fromJson);
  }

  Future<Case> getCase(int caseId) async {
    final response = await _dio.get('/faculty-admin/cases/$caseId/');
    return Case.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Case> createCase(Map<String, dynamic> data) async {
    final response = await _dio.post('/faculty-admin/cases/', data: data);
    return Case.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Case> updateCase(int caseId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/faculty-admin/cases/$caseId/', data: data);
    return Case.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CaseUpdate>> getCaseUpdates(int caseId) async {
    final response = await _dio.get(
      '/faculty-admin/cases/$caseId/updates/',
      queryParameters: {'case_id': caseId},
    );
    return (response.data as List)
        .map((json) => CaseUpdate.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CaseUpdate> createCaseUpdate(int caseId, Map<String, dynamic> data) async {
    final response = await _dio.post(
      '/faculty-admin/cases/$caseId/updates/',
      data: {...data, 'case': caseId},
    );
    return CaseUpdate.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CaseAnalytics> getCaseAnalytics({String? department}) async {
    final response = await _dio.get(
      '/faculty-admin/cases/analytics/',
      queryParameters: {
        if (department != null) 'department': department,
      },
    );
    return CaseAnalytics.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Case>> getCasesAtRisk() async {
    final response = await _dio.get('/faculty-admin/cases/at-risk/');
    return _parsePaginatedResponse(response, Case.fromJson);
  }

  // Broadcast Studio
  Future<List<Broadcast>> getBroadcasts({String? type, bool? myBroadcasts}) async {
    final response = await _dio.get(
      '/faculty-admin/broadcasts/',
      queryParameters: {
        if (type != null) 'type': type,
        if (myBroadcasts == true) 'my_broadcasts': 'true',
      },
    );
    return _parsePaginatedResponse(response, Broadcast.fromJson);
  }

  Future<Broadcast> getBroadcast(int broadcastId) async {
    final response = await _dio.get('/faculty-admin/broadcasts/$broadcastId/');
    return Broadcast.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Broadcast> createBroadcast(Map<String, dynamic> data) async {
    final response = await _dio.post('/faculty-admin/broadcasts/', data: data);
    return Broadcast.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Broadcast> updateBroadcast(int broadcastId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/faculty-admin/broadcasts/$broadcastId/', data: data);
    return Broadcast.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Broadcast> publishBroadcast(int broadcastId) async {
    final response = await _dio.post('/faculty-admin/broadcasts/$broadcastId/publish/');
    return Broadcast.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<String>> getBranches() async {
    // Get unique branches from AllowedUSN model (from Excel import)
    final response = await _dio.get('/auth/branches/');
    final data = response.data as Map<String, dynamic>;
    return List<String>.from(data['branches'] ?? []);
  }

  // Predictive Operations
  Future<List<PredictiveMetric>> getPredictiveMetrics({String? metricType}) async {
    final response = await _dio.get(
      '/faculty-admin/predictive/metrics/',
      queryParameters: {
        if (metricType != null && metricType != 'all') 'metric_type': metricType,
      },
    );
    return _parsePaginatedResponse(response, PredictiveMetric.fromJson);
  }

  Future<List<OperationalAlert>> getOperationalAlerts({
    String? severity,
    bool? isAcknowledged,
  }) async {
    final response = await _dio.get(
      '/faculty-admin/alerts/',
      queryParameters: {
        if (severity != null) 'severity': severity,
        if (isAcknowledged != null) 'is_acknowledged': isAcknowledged.toString(),
      },
    );
    return _parsePaginatedResponse(response, OperationalAlert.fromJson);
  }

  Future<OperationalAlert> acknowledgeAlert(int alertId) async {
    final response = await _dio.post('/faculty-admin/alerts/$alertId/acknowledge/');
    return OperationalAlert.fromJson(response.data as Map<String, dynamic>);
  }

  // ==================== Safety & Wellbeing ====================

  // Emergency Mode
  Future<List<EmergencyAlert>> getEmergencyAlerts({String? status}) async {
    final response = await _dio.get(
      '/safety/emergency/alerts/',
      queryParameters: {
        if (status != null) 'status': status,
      },
    );
    
    // Handle paginated response (Django REST Framework returns {results: [...]})
    // or direct list response
    try {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('results')) {
          // Paginated response
          return (data['results'] as List)
              .map((json) => EmergencyAlert.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        // If it's a Map but no 'results' key, return empty list
        return [];
      } else if (response.data is List) {
        // Direct list response
        return (response.data as List)
            .map((json) => EmergencyAlert.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing emergency alerts: $e, type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');
      return [];
    }
  }

  Future<EmergencyAlert> getEmergencyAlert(int alertId) async {
    final response = await _dio.get('/safety/emergency/alerts/$alertId/');
    return EmergencyAlert.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EmergencyAlert> createEmergencyAlert(Map<String, dynamic> data) async {
    final response = await _dio.post('/safety/emergency/alerts/', data: data);
    return EmergencyAlert.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> acknowledgeEmergencyAlert({
    required int alertId,
    required bool isSafe,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _dio.post(
      '/safety/emergency/alerts/$alertId/acknowledge/',
      data: {
        'is_safe': isSafe,
        if (notes != null) 'notes': notes,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<EmergencyAlert> resolveEmergencyAlert(int alertId) async {
    final response = await _dio.post('/safety/emergency/alerts/$alertId/resolve/');
    return EmergencyAlert.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<EmergencyAlert>> getActiveEmergencyAlerts() async {
    final response = await _dio.get('/safety/emergency/alerts/active/');
    return (response.data as List)
        .map((json) => EmergencyAlert.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<EmergencyContact>> getEmergencyContacts() async {
    final response = await _dio.get('/safety/emergency/contacts/');
    return (response.data as List)
        .map((json) => EmergencyContact.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // User Personal Emergency Contacts
  Future<List<UserPersonalEmergencyContact>> getPersonalEmergencyContacts() async {
    final response = await _dio.get('/safety/emergency/personal-contacts/');
    
    // Handle paginated response (Django REST Framework returns {results: [...]})
    // or direct list response
    try {
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('results')) {
          // Paginated response
          return (data['results'] as List)
              .map((json) => UserPersonalEmergencyContact.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        // If it's a Map but no 'results' key, return empty list
        return [];
      } else if (response.data is List) {
        // Direct list response
        return (response.data as List)
            .map((json) => UserPersonalEmergencyContact.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error parsing personal emergency contacts: $e, type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');
      return [];
    }
  }

  Future<UserPersonalEmergencyContact> createPersonalEmergencyContact(
    Map<String, dynamic> contactData,
  ) async {
    final response = await _dio.post(
      '/safety/emergency/personal-contacts/',
      data: contactData,
    );
    return UserPersonalEmergencyContact.fromJson(response.data);
  }

  Future<UserPersonalEmergencyContact> updatePersonalEmergencyContact(
    int contactId,
    Map<String, dynamic> contactData,
  ) async {
    final response = await _dio.patch(
      '/safety/emergency/personal-contacts/$contactId/',
      data: contactData,
    );
    return UserPersonalEmergencyContact.fromJson(response.data);
  }

  Future<void> deletePersonalEmergencyContact(int contactId) async {
    await _dio.delete('/safety/emergency/personal-contacts/$contactId/');
  }

  Future<Map<String, dynamic>> sendAlertToContact(int contactId, {String? message}) async {
    final response = await _dio.post(
      '/safety/emergency/personal-contacts/$contactId/send-alert/',
      data: {
        if (message != null) 'message': message,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // Counseling Services
  Future<List<CounselingService>> getCounselingServices({String? serviceType}) async {
    final response = await _dio.get(
      '/safety/counseling/services/',
      queryParameters: {
        if (serviceType != null) 'service_type': serviceType,
      },
    );
    return (response.data as List)
        .map((json) => CounselingService.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CounselingService> getCounselingService(int serviceId) async {
    final response = await _dio.get('/safety/counseling/services/$serviceId/');
    return CounselingService.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CounselingAppointment>> getCounselingAppointments({
    String? status,
    int? serviceId,
  }) async {
    final response = await _dio.get(
      '/safety/counseling/appointments/',
      queryParameters: {
        if (status != null) 'status': status,
        if (serviceId != null) 'service_id': serviceId,
      },
    );
    return (response.data as List)
        .map((json) => CounselingAppointment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CounselingAppointment> getCounselingAppointment(int appointmentId) async {
    final response = await _dio.get('/safety/counseling/appointments/$appointmentId/');
    return CounselingAppointment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CounselingAppointment> createCounselingAppointment(Map<String, dynamic> data) async {
    final response = await _dio.post('/safety/counseling/appointments/', data: data);
    return CounselingAppointment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CounselingAppointment> updateCounselingAppointment(int appointmentId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/safety/counseling/appointments/$appointmentId/', data: data);
    return CounselingAppointment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CounselingAppointment>> getUpcomingAppointments({int? serviceId}) async {
    final response = await _dio.get(
      '/safety/counseling/appointments/upcoming/',
      queryParameters: {
        if (serviceId != null) 'service_id': serviceId,
      },
    );
    return (response.data as List)
        .map((json) => CounselingAppointment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<AnonymousCheckIn> submitAnonymousCheckIn(Map<String, dynamic> data) async {
    final response = await _dio.post('/safety/counseling/check-ins/', data: data);
    return AnonymousCheckIn.fromJson(response.data as Map<String, dynamic>);
  }

  // Safety Admin Features
  Future<List<AnonymousCheckIn>> getAnonymousCheckIns({
    String? status,
    int? limit,
  }) async {
    final response = await _dio.get(
      '/safety/counseling/check-ins/list/',
      queryParameters: {
        if (status != null) 'status': status,
        if (limit != null) 'limit': limit,
      },
    );
    return (response.data as List)
        .map((json) => AnonymousCheckIn.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<AnonymousCheckIn> respondToCheckIn({
    required int checkInId,
    required String response,
    String? notes,
  }) async {
    final responseData = await _dio.post(
      '/safety/counseling/check-ins/$checkInId/respond/',
      data: {
        'response': response,
        if (notes != null) 'notes': notes,
      },
    );
    return AnonymousCheckIn.fromJson(responseData.data as Map<String, dynamic>);
  }

  // Safety Resources
  Future<List<SafetyResource>> getSafetyResources({String? resourceType}) async {
    final response = await _dio.get(
      '/safety/resources/',
      queryParameters: {
        if (resourceType != null) 'resource_type': resourceType,
      },
    );
    return (response.data as List)
        .map((json) => SafetyResource.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<SafetyResource> getSafetyResource(int resourceId) async {
    final response = await _dio.get('/safety/resources/$resourceId/');
    return SafetyResource.fromJson(response.data as Map<String, dynamic>);
  }

  // ==================== Lifecycle Extensions ====================

  // Onboarding
  Future<List<OnboardingStep>> getOnboardingSteps() async {
    final response = await _dio.get('/lifecycle/onboarding/steps/');
    return (response.data as List)
        .map((json) => OnboardingStep.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<UserOnboardingProgress> getOnboardingProgress() async {
    final response = await _dio.get('/lifecycle/onboarding/progress/');
    return UserOnboardingProgress.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserOnboardingProgress> completeOnboardingStep({
    required int stepId,
    Map<String, dynamic>? stepData,
  }) async {
    final response = await _dio.post(
      '/lifecycle/onboarding/complete-step/',
      data: {
        'step_id': stepId,
        if (stepData != null) 'step_data': stepData,
      },
    );
    return UserOnboardingProgress.fromJson(response.data as Map<String, dynamic>);
  }

  // Alumni
  Future<List<AlumniProfile>> getAlumniProfiles({
    int? graduationYear,
    String? industry,
    bool? isMentor,
  }) async {
    final response = await _dio.get(
      '/lifecycle/alumni/profiles/',
      queryParameters: {
        if (graduationYear != null) 'graduation_year': graduationYear,
        if (industry != null) 'industry': industry,
        if (isMentor == true) 'is_mentor': 'true',
      },
    );
    return (response.data as List)
        .map((json) => AlumniProfile.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<AlumniProfile> getAlumniProfile(int profileId) async {
    final response = await _dio.get('/lifecycle/alumni/profiles/$profileId/');
    return AlumniProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AlumniProfile> updateAlumniProfile(int profileId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/lifecycle/alumni/profiles/$profileId/', data: data);
    return AlumniProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<MentorshipRequest>> getMentorshipRequests({String? status}) async {
    final response = await _dio.get(
      '/lifecycle/alumni/mentorship/requests/',
      queryParameters: {
        if (status != null) 'status': status,
      },
    );
    return (response.data as List)
        .map((json) => MentorshipRequest.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<MentorshipRequest> createMentorshipRequest(Map<String, dynamic> data) async {
    final response = await _dio.post('/lifecycle/alumni/mentorship/requests/', data: data);
    return MentorshipRequest.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MentorshipRequest> respondToMentorshipRequest({
    required int requestId,
    required String action,
    String? responseMessage,
  }) async {
    final response = await _dio.post(
      '/lifecycle/alumni/mentorship/requests/$requestId/respond/',
      data: {
        'action': action,
        if (responseMessage != null) 'response_message': responseMessage,
      },
    );
    return MentorshipRequest.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AlumniEvent>> getAlumniEvents() async {
    final response = await _dio.get('/lifecycle/alumni/events/');
    return (response.data as List)
        .map((json) => AlumniEvent.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Placement
  Future<List<PlacementOpportunity>> getPlacementOpportunities({String? type}) async {
    final response = await _dio.get(
      '/lifecycle/placement/opportunities/',
      queryParameters: {
        if (type != null) 'type': type,
      },
    );
    return (response.data as List)
        .map((json) => PlacementOpportunity.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PlacementOpportunity> getPlacementOpportunity(int opportunityId) async {
    final response = await _dio.get('/lifecycle/placement/opportunities/$opportunityId/');
    return PlacementOpportunity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PlacementApplication>> getPlacementApplications({
    String? status,
    int? opportunityId,
  }) async {
    final response = await _dio.get(
      '/lifecycle/placement/applications/',
      queryParameters: {
        if (status != null) 'status': status,
        if (opportunityId != null) 'opportunity_id': opportunityId,
      },
    );
    return (response.data as List)
        .map((json) => PlacementApplication.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PlacementApplication> createPlacementApplication(Map<String, dynamic> data) async {
    final response = await _dio.post('/lifecycle/placement/applications/', data: data);
    return PlacementApplication.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PlacementApplication> getPlacementApplication(int applicationId) async {
    final response = await _dio.get('/lifecycle/placement/applications/$applicationId/');
    return PlacementApplication.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getPlacementStatistics() async {
    final response = await _dio.get('/lifecycle/placement/statistics/');
    return response.data as Map<String, dynamic>;
  }

  // ==================== Local Integrations ====================

  // Hostel
  Future<List<Hostel>> getHostels() async {
    final response = await _dio.get('/local/hostels/');
    return (response.data as List)
        .map((json) => Hostel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Hostel> getHostel(int hostelId) async {
    final response = await _dio.get('/local/hostels/$hostelId/');
    return Hostel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<HostelRoom>> getHostelRooms({int? hostelId, bool? isAvailable}) async {
    final response = await _dio.get(
      '/local/hostels/rooms/',
      queryParameters: {
        if (hostelId != null) 'hostel_id': hostelId,
        if (isAvailable == true) 'is_available': 'true',
      },
    );
    return (response.data as List)
        .map((json) => HostelRoom.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<HostelBooking>> getHostelBookings({String? status}) async {
    final response = await _dio.get(
      '/local/hostels/bookings/',
      queryParameters: {
        if (status != null) 'status': status,
      },
    );
    return (response.data as List)
        .map((json) => HostelBooking.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<HostelBooking> createHostelBooking(Map<String, dynamic> data) async {
    final response = await _dio.post('/local/hostels/bookings/', data: data);
    return HostelBooking.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HostelBooking> getHostelBooking(int bookingId) async {
    final response = await _dio.get('/local/hostels/bookings/$bookingId/');
    return HostelBooking.fromJson(response.data as Map<String, dynamic>);
  }

  // Cafeteria
  Future<List<Cafeteria>> getCafeterias() async {
    final response = await _dio.get('/local/cafeterias/');
    return (response.data as List)
        .map((json) => Cafeteria.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Cafeteria> getCafeteria(int cafeteriaId) async {
    final response = await _dio.get('/local/cafeterias/$cafeteriaId/');
    return Cafeteria.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CafeteriaMenu>> getCafeteriaMenu({int? cafeteriaId, String? mealType}) async {
    final response = await _dio.get(
      '/local/cafeterias/menu/',
      queryParameters: {
        if (cafeteriaId != null) 'cafeteria_id': cafeteriaId,
        if (mealType != null) 'meal_type': mealType,
      },
    );
    return (response.data as List)
        .map((json) => CafeteriaMenu.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<CafeteriaBooking>> getCafeteriaBookings() async {
    final response = await _dio.get('/local/cafeterias/bookings/');
    return (response.data as List)
        .map((json) => CafeteriaBooking.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CafeteriaBooking> createCafeteriaBooking(Map<String, dynamic> data) async {
    final response = await _dio.post('/local/cafeterias/bookings/', data: data);
    return CafeteriaBooking.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CafeteriaOrder>> getCafeteriaOrders({String? status}) async {
    final response = await _dio.get(
      '/local/cafeterias/orders/',
      queryParameters: {
        if (status != null) 'status': status,
      },
    );
    return (response.data as List)
        .map((json) => CafeteriaOrder.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CafeteriaOrder> createCafeteriaOrder(Map<String, dynamic> data) async {
    final response = await _dio.post('/local/cafeterias/orders/', data: data);
    return CafeteriaOrder.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CafeteriaOrder> getCafeteriaOrder(int orderId) async {
    final response = await _dio.get('/local/cafeterias/orders/$orderId/');
    return CafeteriaOrder.fromJson(response.data as Map<String, dynamic>);
  }

  // Transport
  Future<List<TransportRoute>> getTransportRoutes() async {
    final response = await _dio.get('/local/transport/routes/');
    return (response.data as List)
        .map((json) => TransportRoute.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<TransportRoute> getTransportRoute(int routeId) async {
    final response = await _dio.get('/local/transport/routes/$routeId/');
    return TransportRoute.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TransportSchedule>> getTransportSchedules({int? routeId, int? dayOfWeek}) async {
    final response = await _dio.get(
      '/local/transport/schedules/',
      queryParameters: {
        if (routeId != null) 'route_id': routeId,
        if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      },
    );
    return (response.data as List)
        .map((json) => TransportSchedule.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<TransportLiveInfo>> getTransportLiveInfo({int? routeId, int? vehicleId}) async {
    final response = await _dio.get(
      '/local/transport/live-info/',
      queryParameters: {
        if (routeId != null) 'route_id': routeId,
        if (vehicleId != null) 'vehicle_id': vehicleId,
      },
    );
    return (response.data as List)
        .map((json) => TransportLiveInfo.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<TransportVehicle>> getTransportVehicles({int? routeId, String? status}) async {
    final response = await _dio.get(
      '/local/transport/vehicles/',
      queryParameters: {
        if (routeId != null) 'route_id': routeId,
        if (status != null) 'status': status,
      },
    );
    return (response.data as List)
        .map((json) => TransportVehicle.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ==================== Awards & Recognition ====================

  // Awards
  Future<List<AwardCategory>> getAwardCategories() async {
    final response = await _dio.get('/awards/categories/');
    return (response.data as List)
        .map((json) => AwardCategory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Award>> getAwards({
    String? awardType,
    int? categoryId,
    bool? isFeatured,
  }) async {
    final response = await _dio.get(
      '/awards/awards/',
      queryParameters: {
        if (awardType != null) 'award_type': awardType,
        if (categoryId != null) 'category_id': categoryId,
        if (isFeatured == true) 'is_featured': 'true',
      },
    );
    return (response.data as List)
        .map((json) => Award.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Award> getAward(int awardId) async {
    final response = await _dio.get('/awards/awards/$awardId/');
    return Award.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<UserAward>> getUserAwards({
    int? userId,
    int? awardId,
  }) async {
    final response = await _dio.get(
      '/awards/user-awards/',
      queryParameters: {
        if (userId != null) 'user_id': userId,
        if (awardId != null) 'award_id': awardId,
      },
    );
    return (response.data as List)
        .map((json) => UserAward.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<UserAward> createUserAward(Map<String, dynamic> data) async {
    final response = await _dio.post('/awards/user-awards/', data: data);
    return UserAward.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserAwardsSummary> getUserAwardsSummary(int userId) async {
    final response = await _dio.get('/awards/users/$userId/awards-summary/');
    return UserAwardsSummary.fromJson(response.data as Map<String, dynamic>);
  }

  // Recognition Posts
  Future<List<RecognitionPost>> getRecognitionPosts({String? postType}) async {
    final response = await _dio.get(
      '/awards/recognition-posts/',
      queryParameters: {
        if (postType != null) 'post_type': postType,
      },
    );
    return (response.data as List)
        .map((json) => RecognitionPost.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<RecognitionPost> getRecognitionPost(int postId) async {
    final response = await _dio.get('/awards/recognition-posts/$postId/');
    return RecognitionPost.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RecognitionPost> createRecognitionPost(Map<String, dynamic> data) async {
    final response = await _dio.post('/awards/recognition-posts/', data: data);
    return RecognitionPost.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> toggleRecognitionLike(int postId) async {
    final response = await _dio.post('/awards/recognition-posts/$postId/like/');
    return response.data as Map<String, dynamic>;
  }

  Future<void> unlikeRecognitionPost(int postId) async {
    await _dio.delete('/awards/recognition-posts/$postId/like/');
  }

  // Award Nominations
  Future<List<AwardNomination>> getAwardNominations({String? status}) async {
    final response = await _dio.get(
      '/awards/nominations/',
      queryParameters: {
        if (status != null) 'status': status,
      },
    );
    return (response.data as List)
        .map((json) => AwardNomination.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<AwardNomination> createAwardNomination(Map<String, dynamic> data) async {
    final response = await _dio.post('/awards/nominations/', data: data);
    return AwardNomination.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AwardNomination> getAwardNomination(int nominationId) async {
    final response = await _dio.get('/awards/nominations/$nominationId/');
    return AwardNomination.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AwardNomination> updateAwardNomination(int nominationId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/awards/nominations/$nominationId/', data: data);
    return AwardNomination.fromJson(response.data as Map<String, dynamic>);
  }

  // Award Ceremonies
  Future<List<AwardCeremony>> getAwardCeremonies() async {
    final response = await _dio.get('/awards/ceremonies/');
    return (response.data as List)
        .map((json) => AwardCeremony.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<AwardCeremony> getAwardCeremony(int ceremonyId) async {
    final response = await _dio.get('/awards/ceremonies/$ceremonyId/');
    return AwardCeremony.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AwardCeremony> createAwardCeremony(Map<String, dynamic> data) async {
    final response = await _dio.post('/awards/ceremonies/', data: data);
    return AwardCeremony.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AwardCeremony> updateAwardCeremony(int ceremonyId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/awards/ceremonies/$ceremonyId/', data: data);
    return AwardCeremony.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserAward> getUserAward(int userAwardId) async {
    final response = await _dio.get('/awards/user-awards/$userAwardId/');
    return UserAward.fromJson(response.data as Map<String, dynamic>);
  }

  // Verify and update USN for student after OTP verification
  Future<Map<String, dynamic>> verifyAndUpdateUSN(int userId, String usn) async {
    print('Verifying and updating USN: userId=$userId, usn=$usn');
    try {
      final response = await _dio.post('/auth/verify-usn/', data: {
        'user_id': userId,
        'usn': usn.toUpperCase().trim(),
      });
      print('USN verification response: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('USN verification failed: $e');
      rethrow;
    }
  }

  // Platform-specific file download methods
  Future<void> _downloadFileMobile(List<int> bytes, String filename) async {
    try {
      final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);
      appLogger.info('File downloaded to: ${file.path}');
    } catch (e) {
      appLogger.error('Error downloading file on mobile: $e');
      rethrow;
    }
  }
}