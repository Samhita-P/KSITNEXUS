import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// SSO Service for Keycloak integration
class SSOService {
  static const String _ssoLoginUrlKey = 'sso_login_url';
  static const String _keycloakAccessTokenKey = 'keycloak_access_token';
  static const String _keycloakRefreshTokenKey = 'keycloak_refresh_token';
  
  final ApiService _apiService;
  final FlutterSecureStorage _storage;
  
  SSOService({
    ApiService? apiService,
    FlutterSecureStorage? storage,
  })  : _apiService = apiService ?? ApiService(),
        _storage = storage ?? const FlutterSecureStorage();

  /// Get SSO login URL from backend
  Future<Map<String, dynamic>> getSSOLoginUrl({
    String? redirectUri,
    String? state,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (redirectUri != null) {
        queryParams['redirect_uri'] = redirectUri;
      }
      if (state != null) {
        queryParams['state'] = state;
      }

      final response = await _apiService.dio.get(
        '/api/accounts/sso/login-url/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        // Store login URL for later use
        await _storage.write(
          key: _ssoLoginUrlKey,
          value: data['authorization_url'] as String?,
        );
        return data;
      } else {
        throw Exception('Failed to get SSO login URL');
      }
    } catch (e) {
      throw Exception('Error getting SSO login URL: $e');
    }
  }

  /// Handle SSO callback with authorization code
  Future<Map<String, dynamic>> handleSSOCallback({
    required String authorizationCode,
    String? state,
    String? redirectUri,
    String? deviceId,
    String? deviceName,
    String? deviceType,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/accounts/sso/callback/',
        data: {
          'code': authorizationCode,
          if (state != null) 'state': state,
          if (redirectUri != null) 'redirect_uri': redirectUri,
          if (deviceId != null) 'device_id': deviceId,
          if (deviceName != null) 'device_name': deviceName,
          if (deviceType != null) 'device_type': deviceType,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Store Keycloak tokens
        if (data['keycloak_access_token'] != null) {
          await _storage.write(
            key: _keycloakAccessTokenKey,
            value: data['keycloak_access_token'] as String,
          );
        }
        if (data['keycloak_refresh_token'] != null) {
          await _storage.write(
            key: _keycloakRefreshTokenKey,
            value: data['keycloak_refresh_token'] as String,
          );
        }
        
        return data;
      } else {
        throw Exception('SSO callback failed');
      }
    } catch (e) {
      throw Exception('Error handling SSO callback: $e');
    }
  }

  /// Refresh Keycloak access token
  Future<Map<String, dynamic>> refreshKeycloakToken() async {
    try {
      final refreshToken = await _storage.read(key: _keycloakRefreshTokenKey);
      
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _apiService.dio.post(
        '/api/accounts/sso/refresh-token/',
        data: {
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Update stored tokens
        if (data['access_token'] != null) {
          await _storage.write(
            key: _keycloakAccessTokenKey,
            value: data['access_token'] as String,
          );
        }
        if (data['refresh_token'] != null) {
          await _storage.write(
            key: _keycloakRefreshTokenKey,
            value: data['refresh_token'] as String,
          );
        }
        
        return data;
      } else {
        throw Exception('Token refresh failed');
      }
    } catch (e) {
      throw Exception('Error refreshing token: $e');
    }
  }

  /// Logout from SSO
  Future<void> ssoLogout() async {
    try {
      final refreshToken = await _storage.read(key: _keycloakRefreshTokenKey);
      
      if (refreshToken != null) {
        await _apiService.dio.post(
          '/api/accounts/sso/logout/',
          data: {
            'refresh_token': refreshToken,
          },
        );
      }
      
      // Clear stored SSO tokens
      await _storage.delete(key: _keycloakAccessTokenKey);
      await _storage.delete(key: _keycloakRefreshTokenKey);
      await _storage.delete(key: _ssoLoginUrlKey);
    } catch (e) {
      // Even if logout fails, clear local tokens
      await _storage.delete(key: _keycloakAccessTokenKey);
      await _storage.delete(key: _keycloakRefreshTokenKey);
      await _storage.delete(key: _ssoLoginUrlKey);
      throw Exception('Error during SSO logout: $e');
    }
  }

  /// Get stored Keycloak access token
  Future<String?> getKeycloakAccessToken() async {
    return await _storage.read(key: _keycloakAccessTokenKey);
  }

  /// Get stored Keycloak refresh token
  Future<String?> getKeycloakRefreshToken() async {
    return await _storage.read(key: _keycloakRefreshTokenKey);
  }

  /// Check if user has SSO tokens
  Future<bool> hasSSOTokens() async {
    final accessToken = await getKeycloakAccessToken();
    return accessToken != null;
  }
}

















