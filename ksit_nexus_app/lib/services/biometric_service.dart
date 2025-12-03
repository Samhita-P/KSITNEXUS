import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static const String _storageKey = 'ksit_nexus_biometric';
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      // Check if running on web platform
      if (kIsWeb) {
        print('Biometric authentication is not supported on web platform');
        return false;
      }
      
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      if (kIsWeb) {
        return [];
      }
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if biometric authentication is enabled for the user
  Future<bool> isBiometricEnabled() async {
    try {
      final String? enabled = await _storage.read(key: '${_storageKey}_enabled');
      return enabled == 'true';
    } catch (e) {
      print('Error checking biometric enabled status: $e');
      return false;
    }
  }

  /// Enable biometric authentication for the user
  Future<bool> enableBiometric() async {
    try {
      // Check if biometric is available first
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        print('Biometric authentication is not available on this device');
        return false;
      }

      // First authenticate to enable biometric
      final bool authenticated = await authenticate(
        reason: 'Enable biometric authentication for KSIT Nexus',
        useErrorDialogs: true,
      );

      if (authenticated) {
        await _storage.write(key: '${_storageKey}_enabled', value: 'true');
        print('Biometric authentication enabled successfully');
        return true;
      } else {
        print('Biometric authentication failed - user did not authenticate');
        return false;
      }
    } catch (e) {
      print('Error enabling biometric: $e');
      return false;
    }
  }

  /// Disable biometric authentication
  Future<bool> disableBiometric() async {
    try {
      await _storage.delete(key: '${_storageKey}_enabled');
      return true;
    } catch (e) {
      print('Error disabling biometric: $e');
      return false;
    }
  }

  /// Authenticate using biometric
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        print('Biometric authentication is not available on this device');
        return false;
      }

      print('Starting biometric authentication...');
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      print('Biometric authentication result: $authenticated');
      return authenticated;
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.code} - ${e.message}');
      if (e.code == 'NotAvailable') {
        print('Biometric authentication is not available');
      } else if (e.code == 'NotEnrolled') {
        print('No biometric data enrolled on device');
      } else if (e.code == 'LockedOut') {
        print('Biometric authentication is locked out');
      } else if (e.code == 'PermanentlyLockedOut') {
        print('Biometric authentication is permanently locked out');
      }
      return false;
    } catch (e) {
      print('Unexpected error during biometric authentication: $e');
      return false;
    }
  }

  /// Authenticate for login
  Future<bool> authenticateForLogin() async {
    final bool isEnabled = await isBiometricEnabled();
    if (!isEnabled) {
      return false;
    }

    return await authenticate(
      reason: 'Authenticate to login to KSIT Nexus',
      useErrorDialogs: true,
    );
  }

  /// Authenticate for sensitive operations
  Future<bool> authenticateForSensitiveOperation() async {
    final bool isEnabled = await isBiometricEnabled();
    if (!isEnabled) {
      return false;
    }

    return await authenticate(
      reason: 'Authenticate to perform this sensitive operation',
      useErrorDialogs: true,
    );
  }

  /// Get biometric type display name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }

  /// Get all available biometric types as display names
  Future<List<String>> getAvailableBiometricNames() async {
    final List<BiometricType> types = await getAvailableBiometrics();
    return types.map((type) => getBiometricTypeName(type)).toList();
  }

  /// Check if device has strong biometric (Face ID, Fingerprint)
  Future<bool> hasStrongBiometric() async {
    final List<BiometricType> types = await getAvailableBiometrics();
    return types.contains(BiometricType.fingerprint) || 
           types.contains(BiometricType.face) ||
           types.contains(BiometricType.strong);
  }

  /// Get biometric status summary
  Future<Map<String, dynamic>> getBiometricStatus() async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      final bool isEnabled = await isBiometricEnabled();
      final List<BiometricType> availableTypes = await getAvailableBiometrics();
      final List<String> typeNames = availableTypes
          .map((type) => getBiometricTypeName(type))
          .toList();

      return {
        'isAvailable': isAvailable,
        'isEnabled': isEnabled,
        'availableTypes': typeNames,
        'hasStrongBiometric': await hasStrongBiometric(),
      };
    } catch (e) {
      print('Error getting biometric status: $e');
      return {
        'isAvailable': false,
        'isEnabled': false,
        'availableTypes': <String>[],
        'hasStrongBiometric': false,
      };
    }
  }
}
