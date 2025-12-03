import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'biometric_service.dart';
import '../utils/logger.dart';

final appLogger = Logger('AuthService');

class AuthService {
  static const String _storageKey = 'ksit_nexus_auth';
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _apiService;
  final BiometricService _biometricService = BiometricService();
  
  User? _currentUser;
  bool _isLoggedIn = false;

  AuthService(this._apiService);

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  // Check if user is logged in
  Future<bool> checkAuthStatus() async {
    try {
      final hasValidToken = await _apiService.hasValidToken();
      if (hasValidToken) {
        _currentUser = await _apiService.getCurrentUser();
        _isLoggedIn = true;
        return true;
      }
    } catch (e) {
      appLogger.error('Auth check failed: $e');
      await logout();
    }
    return false;
  }

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    return await _biometricService.isBiometricAvailable();
  }

  // Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    return await _biometricService.isBiometricEnabled();
  }

  // Enable biometric authentication
  Future<bool> enableBiometric() async {
    try {
      final enabled = await _biometricService.enableBiometric();
      if (enabled) {
        appLogger.info('Biometric authentication enabled');
      }
      return enabled;
    } catch (e) {
      appLogger.error('Error enabling biometric: $e');
      return false;
    }
  }

  // Disable biometric authentication
  Future<bool> disableBiometric() async {
    try {
      final disabled = await _biometricService.disableBiometric();
      if (disabled) {
        appLogger.info('Biometric authentication disabled');
      }
      return disabled;
    } catch (e) {
      appLogger.error('Error disabling biometric: $e');
      return false;
    }
  }

  // Login with biometric authentication
  Future<User?> loginWithBiometric() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw Exception('Biometric authentication is not available on this device');
      }

      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        throw Exception('Biometric authentication is not enabled');
      }

      final authenticated = await _biometricService.authenticateForLogin();
      if (!authenticated) {
        throw Exception('Biometric authentication failed');
      }

      // Check if we have stored credentials for biometric login
      // This would typically involve storing encrypted credentials
      // For now, we'll just check if user is already logged in
      final hasValidToken = await _apiService.hasValidToken();
      if (hasValidToken) {
        _currentUser = await _apiService.getCurrentUser();
        _isLoggedIn = true;
        return _currentUser;
      }

      // If no valid token, user needs to login normally first
      throw Exception('Please login with username and password first');
    } catch (e) {
      appLogger.error('Biometric login failed: $e');
      rethrow;
    }
  }

  // Get biometric status
  Future<Map<String, dynamic>> getBiometricStatus() async {
    return await _biometricService.getBiometricStatus();
  }

  // Login with username and password
  Future<User> login(String username, String password) async {
    try {
      // Clear any cached user data before logging in
      await _apiService.clearUserCache();
      
      final request = LoginRequest(
        username: username,
        password: password,
      );
      
      final authResponse = await _apiService.login(request);
      _currentUser = authResponse.user;
      _isLoggedIn = true;
      
      // Update cache with the user from login response to ensure consistency
      await _apiService.cacheUser(_currentUser!);
      
      return _currentUser!;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String userType,
    String? phoneNumber,
    String? usn,
  }) async {
    try {
      final request = RegisterRequest(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        userType: userType,
        phoneNumber: phoneNumber,
        usn: usn,
      );
      
      final response = await _apiService.register(request);
      // Registration returns a Map with user_id and message
      return response;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Verify registration OTP - returns AuthResponse to include requires_usn_entry
  Future<AuthResponse> verifyRegistrationOTP(int userId, String otp) async {
    try {
      final authResponse = await _apiService.verifyRegistrationOTP(userId, otp);
      
      // Tokens are automatically saved by the API service interceptor
      // But we ensure they're set here too
      _currentUser = authResponse.user;
      _isLoggedIn = true;
      
      print('OTP verification successful. User: ${_currentUser?.username}, Type: ${_currentUser?.userType}');
      print('User is authenticated: $_isLoggedIn, requires_usn_entry: ${authResponse.requiresUsnEntry}');
      
      return authResponse;
    } catch (e) {
      print('OTP verification error: $e');
      throw Exception('OTP verification failed: ${e.toString()}');
    }
  }

  // Request OTP
  Future<void> requestOTP(String email, String type) async {
    try {
      final request = OTPRequest(
        email: email,
        type: type,
      );
      
      await _apiService.requestOTP(request);
    } catch (e) {
      throw Exception('OTP request failed: ${e.toString()}');
    }
  }

  // Verify OTP
  Future<User> verifyOTP(String email, String otp) async {
    try {
      final request = OTPVerification(
        email: email,
        otp: otp,
      );
      
      final authResponse = await _apiService.verifyOTP(request);
      _currentUser = authResponse.user;
      _isLoggedIn = true;
      
      return _currentUser!;
    } catch (e) {
      throw Exception('OTP verification failed: ${e.toString()}');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _currentUser = null;
      _isLoggedIn = false;
    }
  }

  // Change Password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _apiService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
    } catch (e) {
      throw Exception('Change password failed: ${e.toString()}');
    }
  }

  // Get current user profile
  Future<User> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser!;
    }
    
    try {
      _currentUser = await _apiService.getCurrentUser();
      _isLoggedIn = true;
      return _currentUser!;
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  // Update user profile
  Future<User> updateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      _currentUser = await _apiService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      return _currentUser!;
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

  // Update profile picture
  Future<User> updateProfilePicture(String imageUrl) async {
    try {
      _currentUser = await _apiService.updateProfilePicture(imageUrl);
      return _currentUser!;
    } catch (e) {
      throw Exception('Profile picture update failed: ${e.toString()}');
    }
  }

  // Check if user is student
  bool get isStudent => _currentUser?.isStudent ?? false;

  // Check if user is faculty
  bool get isFaculty => _currentUser?.isFaculty ?? false;

  // Check if user is admin
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // Get user display name
  String get displayName => _currentUser?.displayName ?? 'Guest';

  // Get user email
  String get email => _currentUser?.email ?? '';

  // Get user type
  String get userType => _currentUser?.userType ?? 'guest';

  // Forgot Password Flow
  Future<Map<String, dynamic>> requestPasswordResetOTP(String phoneNumber) async {
    try {
      final response = await _apiService.requestPasswordResetOTP(phoneNumber);
      return response;
    } catch (e) {
      throw Exception('Failed to request password reset OTP: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> verifyPasswordResetOTP(String phoneNumber, String otp) async {
    try {
      final response = await _apiService.verifyPasswordResetOTP(phoneNumber, otp);
      return response;
    } catch (e) {
      throw Exception('Failed to verify password reset OTP: ${e.toString()}');
    }
  }

  Future<User> resetPassword(String resetToken, String newPassword, String confirmPassword) async {
    try {
      final authResponse = await _apiService.resetPassword(resetToken, newPassword, confirmPassword);
      _currentUser = authResponse.user;
      _isLoggedIn = true;
      return _currentUser!;
    } catch (e) {
      throw Exception('Failed to reset password: ${e.toString()}');
    }
  }
}