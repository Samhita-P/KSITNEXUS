import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'api_service.dart';

class TwoFactorService {
  static const String _storageKey = 'ksit_nexus_token';
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  TwoFactorService() {
    _dio.options.baseUrl = ApiService.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// Check if user is authenticated
  Future<bool> _isAuthenticated() async {
    final token = await _storage.read(key: '${_storageKey}_access');
    return token != null;
  }

  /// Setup Two-Factor Authentication
  Future<Map<String, dynamic>> setup2FA() async {
    try {
      final token = await _storage.read(key: '${_storageKey}_access');
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.post(
        '/auth/2fa/setup/',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to setup 2FA: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to setup 2FA: ${e.response?.data['message']}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Setup 2FA error: $e');
    }
  }

  /// Verify 2FA setup with code
  Future<Map<String, dynamic>> verify2FA(String code) async {
    try {
      final token = await _storage.read(key: '${_storageKey}_access');
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.post(
        '/auth/2fa/verify/',
        data: {'code': code},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to verify 2FA: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to verify 2FA: ${e.response?.data['message']}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Verify 2FA error: $e');
    }
  }

  /// Disable 2FA
  Future<Map<String, dynamic>> disable2FA(String password, String code) async {
    try {
      final token = await _storage.read(key: '${_storageKey}_access');
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.post(
        '/auth/2fa/disable/',
        data: {
          'password': password,
          'code': code,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to disable 2FA: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to disable 2FA: ${e.response?.data['message']}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Disable 2FA error: $e');
    }
  }

  /// Get 2FA status
  Future<Map<String, dynamic>> get2FAStatus() async {
    try {
      if (!await _isAuthenticated()) {
        throw Exception('User not authenticated');
      }
      
      final token = await _storage.read(key: '${_storageKey}_access');

      final response = await _dio.get(
        '/auth/2fa/status/',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get 2FA status: ${response.data['message'] ?? response.data['error'] ?? 'Unknown error'}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response?.statusCode == 401) {
          throw Exception('User not authenticated');
        }
        throw Exception('Failed to get 2FA status: ${e.response?.data['message'] ?? e.response?.data['error'] ?? 'Unknown error'}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Get 2FA status error: $e');
    }
  }

  /// Generate new backup codes
  Future<Map<String, dynamic>> generateBackupCodes(String password) async {
    try {
      final token = await _storage.read(key: '${_storageKey}_access');
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.post(
        '/auth/2fa/backup-codes/',
        data: {'password': password},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to generate backup codes: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to generate backup codes: ${e.response?.data['message']}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Generate backup codes error: $e');
    }
  }

  /// Get active device sessions
  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    try {
      if (!await _isAuthenticated()) {
        throw Exception('User not authenticated');
      }
      
      final token = await _storage.read(key: '${_storageKey}_access');

      final response = await _dio.get(
        '/auth/sessions/',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to get active sessions: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to get active sessions: ${e.response?.data['message']}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Get active sessions error: $e');
    }
  }

  /// Create a device session for current user (if not exists)
  Future<Map<String, dynamic>> createCurrentDeviceSession() async {
    try {
      if (!await _isAuthenticated()) {
        throw Exception('User not authenticated');
      }
      
      final token = await _storage.read(key: '${_storageKey}_access');
      
      // Get device information
      final deviceInfo = await _getDeviceInfo();
      
      final response = await _dio.post(
        '/auth/create-session/',
        data: {
          'device_id': deviceInfo['device_id'],
          'device_name': deviceInfo['device_name'],
          'device_type': deviceInfo['device_type'],
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to create device session: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to create device session: ${e.response?.data['message']}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Create device session error: $e');
    }
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

  /// Deactivate a specific session
  Future<Map<String, dynamic>> deactivateSession(int sessionId) async {
    try {
      final token = await _storage.read(key: '${_storageKey}_access');
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.post(
        '/auth/sessions/$sessionId/deactivate/',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to deactivate session: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to deactivate session: ${e.response?.data['message']}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Deactivate session error: $e');
    }
  }

  /// Logout from all devices
  Future<Map<String, dynamic>> logoutAllDevices(int? currentSessionId) async {
    try {
      final token = await _storage.read(key: '${_storageKey}_access');
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _dio.post(
        '/auth/sessions/logout-all/',
        data: {'current_session_id': currentSessionId},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to logout all devices: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to logout all devices: ${e.response?.data['message']}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Logout all devices error: $e');
    }
  }

  /// Login with 2FA
  Future<Map<String, dynamic>> loginWith2FA({
    required String username,
    required String password,
    String? code,
    String? backupCode,
    required String deviceId,
    required String deviceName,
    required String deviceType,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login-2fa/',
        data: {
          'username': username,
          'password': password,
          if (code != null) 'code': code,
          if (backupCode != null) 'backup_code': backupCode,
          'device_id': deviceId,
          'device_name': deviceName,
          'device_type': deviceType,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Login failed: ${response.data['message']}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Login failed: ${e.response?.data['message']}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Login with 2FA error: $e');
    }
  }

  /// Check if 2FA is enabled locally
  Future<bool> is2FAEnabledLocally() async {
    try {
      final String? enabled = await _storage.read(key: '${_storageKey}_enabled');
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Set 2FA enabled status locally
  Future<void> set2FAEnabledLocally(bool enabled) async {
    await _storage.write(
      key: '${_storageKey}_enabled',
      value: enabled.toString(),
    );
  }

  /// Get device ID (unique identifier for this device)
  Future<String> getDeviceId() async {
    try {
      String? deviceId = await _storage.read(key: '${_storageKey}_device_id');
      if (deviceId == null) {
        // Generate a new device ID
        deviceId = DateTime.now().millisecondsSinceEpoch.toString();
        await _storage.write(key: '${_storageKey}_device_id', value: deviceId);
      }
      return deviceId;
    } catch (e) {
      // Fallback to timestamp-based ID
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }
}
