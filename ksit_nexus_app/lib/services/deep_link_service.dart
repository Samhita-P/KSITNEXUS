/// Deep link service for handling deep links and URL schemes
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';
import '../utils/logger.dart';

final appLogger = Logger('DeepLinkService');

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;

  /// Initialize deep link service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Handle initial link (if app was opened from a link)
      try {
        final initialUri = await _appLinks.getInitialLink();
        if (initialUri != null) {
          appLogger.info('App opened from deep link: $initialUri');
          // Store for processing when router is ready
          _pendingLink = initialUri;
        }
      } catch (e) {
        appLogger.warning('Could not get initial link: $e');
      }

      // Listen for app links (custom URL schemes and app links)
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          appLogger.info('Received deep link: $uri');
          _handleDeepLink(uri.toString());
        },
        onError: (err) {
          appLogger.error('Deep link error: $err');
        },
      );

      _initialized = true;
      appLogger.info('Deep link service initialized');
    } catch (e) {
      appLogger.error('Failed to initialize deep link service: $e');
    }
  }

  Uri? _pendingLink;
  GoRouter? _router;

  /// Set router for navigation
  void setRouter(GoRouter router) {
    _router = router;
    // Process pending link if any
    if (_pendingLink != null) {
      _handleDeepLink(_pendingLink!.toString());
      _pendingLink = null;
    }
  }

  /// Handle deep link
  void _handleDeepLink(String link) {
    try {
      final uri = Uri.parse(link);
      appLogger.info('Processing deep link: ${uri.toString()}');
      
      // Route based on path
      final path = uri.path;
      final queryParams = uri.queryParameters;

      if (_router == null) {
        appLogger.warning('Router not set, storing link for later');
        _pendingLink = uri;
        return;
      }

      // Handle different deep link paths
      switch (path) {
        case '/notice':
        case '/notices':
          _handleNoticeLink(queryParams);
          break;
        case '/complaint':
        case '/complaints':
          _handleComplaintLink(queryParams);
          break;
        case '/study-group':
        case '/study-groups':
          _handleStudyGroupLink(queryParams);
          break;
        case '/reservation':
        case '/reservations':
          _handleReservationLink(queryParams);
          break;
        case '/notification':
        case '/notifications':
          _handleNotificationLink(queryParams);
          break;
        case '/chatbot':
          _handleChatbotLink(queryParams);
          break;
        case '/profile':
          _router?.go('/profile');
          break;
        case '/home':
          _router?.go('/home');
          break;
        case '/login':
          _handleLoginLink(queryParams);
          break;
        case '/register':
          _handleRegisterLink(queryParams);
          break;
        case '/otp-verification':
          _handleOTPLink(queryParams);
          break;
        default:
          appLogger.warning('Unknown deep link path: $path');
          // Default to home
          _router?.go('/home');
      }
    } catch (e) {
      appLogger.error('Error handling deep link: $e');
    }
  }

  /// Handle notice deep link
  void _handleNoticeLink(Map<String, String> params) {
    final id = params['id'];
    if (id != null) {
      _router?.go('/notices/$id');
    } else {
      _router?.go('/notices');
    }
  }

  /// Handle complaint deep link
  void _handleComplaintLink(Map<String, String> params) {
    final id = params['id'];
    if (id != null) {
      // Navigate to complaint detail
      _router?.go('/complaints?complaintId=$id');
    } else {
      _router?.go('/complaints');
    }
  }

  /// Handle study group deep link
  void _handleStudyGroupLink(Map<String, String> params) {
    final id = params['id'];
    if (id != null) {
      // Navigate to study group detail
      _router?.go('/study-groups?groupId=$id');
    } else {
      _router?.go('/study-groups');
    }
  }

  /// Handle reservation deep link
  void _handleReservationLink(Map<String, String> params) {
    final id = params['id'];
    if (id != null) {
      // Navigate to reservation detail
      _router?.go('/reservations?reservationId=$id');
    } else {
      _router?.go('/reservations');
    }
  }

  /// Handle notification deep link
  void _handleNotificationLink(Map<String, String> params) {
    final id = params['id'];
    if (id != null) {
      // Navigate to notification detail
      _router?.go('/notifications?notificationId=$id');
    } else {
      _router?.go('/notifications');
    }
  }

  /// Handle chatbot deep link
  void _handleChatbotLink(Map<String, String> params) {
    final query = params['query'];
    if (query != null) {
      // Navigate to chatbot with query
      _router?.go('/chatbot?query=${Uri.encodeComponent(query)}');
    } else {
      _router?.go('/chatbot');
    }
  }

  /// Handle login deep link
  void _handleLoginLink(Map<String, String> params) {
    final redirect = params['redirect'];
    _router?.go('/login${redirect != null ? '?redirect=${Uri.encodeComponent(redirect)}' : ''}');
  }

  /// Handle register deep link
  void _handleRegisterLink(Map<String, String> params) {
    final userType = params['userType'];
    _router?.go('/register${userType != null ? '?userType=$userType' : ''}');
  }

  /// Handle OTP verification deep link
  void _handleOTPLink(Map<String, String> params) {
    final userId = params['userId'];
    final phoneNumber = params['phoneNumber'];
    final purpose = params['purpose'] ?? 'registration';
    final userType = params['userType'];
    
    if (userId != null && phoneNumber != null) {
      _router?.go('/otp-verification?userId=$userId&phoneNumber=${Uri.encodeComponent(phoneNumber)}&purpose=$purpose${userType != null ? '&userType=$userType' : ''}');
    } else {
      appLogger.warning('OTP verification link missing required parameters');
    }
  }

  /// Generate deep link URL
  static String generateDeepLink({
    required String path,
    Map<String, String>? params,
    String? scheme,
  }) {
    scheme = scheme ?? 'ksitnexus';
    final uri = Uri(
      scheme: scheme,
      host: 'app',
      path: path,
      queryParameters: params,
    );
    return uri.toString();
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
    _initialized = false;
    appLogger.info('Deep link service disposed');
  }
}

/// Global deep link service instance
final deepLinkService = DeepLinkService();

