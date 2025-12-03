import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';  // Temporarily disabled
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ksit_nexus_app/services/api_service.dart';
import 'package:ksit_nexus_app/firebase_options.dart';

class FirebaseService {
  // static FirebaseMessaging? _messaging;  // Temporarily disabled
  static String? _fcmToken;
  static final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // _messaging = FirebaseMessaging.instance;  // Temporarily disabled
      
      // Request permission for notifications - DISABLED
      // await _requestPermission();
      
      // Get FCM token - DISABLED
      // await _getFCMToken();
      
      // Set up message handlers - DISABLED
      // _setupMessageHandlers();
      
      if (kDebugMode) {
        print('Firebase initialized successfully (messaging disabled)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase: $e');
      }
    }
  }

  // Request notification permission - DISABLED
  static Future<void> _requestPermission() async {
    // TODO: Re-enable when firebase_messaging is fixed
    if (kDebugMode) {
      print('Firebase messaging temporarily disabled');
    }
  }

  // Get FCM token - DISABLED
  static Future<String?> _getFCMToken() async {
    // TODO: Re-enable when firebase_messaging is fixed
    if (kDebugMode) {
      print('Firebase messaging temporarily disabled');
    }
    return null;
  }

  // Send FCM token to server - DISABLED
  static Future<void> _sendTokenToServer(String token) async {
    // TODO: Re-enable when firebase_messaging is fixed
    if (kDebugMode) {
      print('Firebase messaging temporarily disabled');
    }
  }

  // Set up message handlers - DISABLED
  static void _setupMessageHandlers() {
    // TODO: Re-enable when firebase_messaging is fixed
    if (kDebugMode) {
      print('Firebase messaging temporarily disabled');
    }
  }

  // Handle foreground messages - DISABLED
  static void _handleForegroundMessage(dynamic message) {
    // TODO: Re-enable when firebase_messaging is fixed
    if (kDebugMode) {
      print('Firebase messaging temporarily disabled');
    }
  }

  // Handle notification tap - DISABLED
  static void _handleNotificationTap(dynamic message) {
    // TODO: Re-enable when firebase_messaging is fixed
    if (kDebugMode) {
      print('Firebase messaging temporarily disabled');
    }
  }

  // Handle initial message - DISABLED
  static Future<void> _handleInitialMessage() async {
    // TODO: Re-enable when firebase_messaging is fixed
    if (kDebugMode) {
      print('Firebase messaging temporarily disabled');
    }
  }

  // Subscribe to topic - DISABLED
  static Future<void> subscribeToTopic(String topic) async {
    // TODO: Re-enable when firebase_messaging is fixed
    if (kDebugMode) {
      print('Firebase messaging temporarily disabled');
    }
  }

  // Unsubscribe from topic - DISABLED
  static Future<void> unsubscribeFromTopic(String topic) async {
    // TODO: Re-enable when firebase_messaging is fixed
    if (kDebugMode) {
      print('Firebase messaging temporarily disabled');
    }
  }

  // Get current FCM token - DISABLED
  static String? get fcmToken => null;

  // Refresh FCM token - DISABLED
  static Future<String?> refreshToken() async {
    // TODO: Re-enable when firebase_messaging is fixed
    if (kDebugMode) {
      print('Firebase messaging temporarily disabled');
    }
    return null;
  }

  // Dispose
  static void dispose() {
    _messageController.close();
  }
}

// Background message handler - DISABLED
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(dynamic message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  if (kDebugMode) {
    print('Firebase messaging temporarily disabled');
  }
}

// Provider for Firebase Service
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// Stream provider for FCM messages - DISABLED
final fcmMessageStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return FirebaseService.messageStream;
});

// Provider for FCM token - DISABLED
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  return null; // FirebaseService.fcmToken ?? await FirebaseService.refreshToken();
});

// Provider for notification permission status - DISABLED
final notificationPermissionProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return {'authorizationStatus': 'denied'}; // await FirebaseMessaging.instance.getNotificationSettings();
});