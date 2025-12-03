import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';

class WebSocketService {
  static String get baseUrl => ApiConfig.websocketUrl;
  
  WebSocketChannel? _notificationChannel;
  WebSocketChannel? _chatChannel;
  WebSocketChannel? _groupChannel;
  WebSocketChannel? _reservationChannel;
  
  final Map<String, StreamController<dynamic>> _controllers = {};
  Timer? _reconnectTimer;
  bool _isConnected = false;

  // Notification stream
  StreamController<Map<String, dynamic>> get notificationController {
    if (!_controllers.containsKey('notifications')) {
      _controllers['notifications'] = StreamController<Map<String, dynamic>>.broadcast();
    }
    return _controllers['notifications'] as StreamController<Map<String, dynamic>>;
  }

  // Chat stream
  StreamController<Map<String, dynamic>> get chatController {
    if (!_controllers.containsKey('chat')) {
      _controllers['chat'] = StreamController<Map<String, dynamic>>.broadcast();
    }
    return _controllers['chat'] as StreamController<Map<String, dynamic>>;
  }

  // Study group stream
  StreamController<Map<String, dynamic>> get groupController {
    if (!_controllers.containsKey('group')) {
      _controllers['group'] = StreamController<Map<String, dynamic>>.broadcast();
    }
    return _controllers['group'] as StreamController<Map<String, dynamic>>;
  }

  // Reservation stream
  StreamController<Map<String, dynamic>> get reservationController {
    if (!_controllers.containsKey('reservation')) {
      _controllers['reservation'] = StreamController<Map<String, dynamic>>.broadcast();
    }
    return _controllers['reservation'] as StreamController<Map<String, dynamic>>;
  }

  // Connect to notification WebSocket
  Future<void> connectNotifications(int userId) async {
    try {
      _notificationChannel = WebSocketChannel.connect(
        Uri.parse('$baseUrl/notifications/$userId/'),
      );

      _notificationChannel!.stream.listen(
        (data) {
          final message = jsonDecode(data);
          notificationController.add(message);
        },
        onError: (error) {
          print('Notification WebSocket error: $error');
          _scheduleReconnect(() => connectNotifications(userId));
        },
        onDone: () {
          print('Notification WebSocket closed');
          _scheduleReconnect(() => connectNotifications(userId));
        },
      );

      _isConnected = true;
    } catch (e) {
      print('Failed to connect to notification WebSocket: $e');
      _scheduleReconnect(() => connectNotifications(userId));
    }
  }

  // Connect to chat WebSocket
  Future<void> connectChat(int groupId) async {
    try {
      _chatChannel = WebSocketChannel.connect(
        Uri.parse('$baseUrl/chat/$groupId/'),
      );

      _chatChannel!.stream.listen(
        (data) {
          final message = jsonDecode(data);
          chatController.add(message);
        },
        onError: (error) {
          print('Chat WebSocket error: $error');
          _scheduleReconnect(() => connectChat(groupId));
        },
        onDone: () {
          print('Chat WebSocket closed');
          _scheduleReconnect(() => connectChat(groupId));
        },
      );
    } catch (e) {
      print('Failed to connect to chat WebSocket: $e');
      _scheduleReconnect(() => connectChat(groupId));
    }
  }

  // Connect to study group WebSocket
  Future<void> connectStudyGroup(int groupId) async {
    try {
      _groupChannel = WebSocketChannel.connect(
        Uri.parse('$baseUrl/study-groups/$groupId/'),
      );

      _groupChannel!.stream.listen(
        (data) {
          final message = jsonDecode(data);
          groupController.add(message);
        },
        onError: (error) {
          print('Study group WebSocket error: $error');
          _scheduleReconnect(() => connectStudyGroup(groupId));
        },
        onDone: () {
          print('Study group WebSocket closed');
          _scheduleReconnect(() => connectStudyGroup(groupId));
        },
      );
    } catch (e) {
      print('Failed to connect to study group WebSocket: $e');
      _scheduleReconnect(() => connectStudyGroup(groupId));
    }
  }

  // Connect to reservation WebSocket
  Future<void> connectReservations(String resourceType) async {
    try {
      _reservationChannel = WebSocketChannel.connect(
        Uri.parse('$baseUrl/reservations/$resourceType/'),
      );

      _reservationChannel!.stream.listen(
        (data) {
          final message = jsonDecode(data);
          reservationController.add(message);
        },
        onError: (error) {
          print('Reservation WebSocket error: $error');
          _scheduleReconnect(() => connectReservations(resourceType));
        },
        onDone: () {
          print('Reservation WebSocket closed');
          _scheduleReconnect(() => connectReservations(resourceType));
        },
      );
    } catch (e) {
      print('Failed to connect to reservation WebSocket: $e');
      _scheduleReconnect(() => connectReservations(resourceType));
    }
  }

  // Send message through chat WebSocket
  void sendChatMessage(int groupId, String message, {String? messageType}) {
    if (_chatChannel != null) {
      _chatChannel!.sink.add(jsonEncode({
        'type': 'chat_message',
        'group_id': groupId,
        'message': message,
        'message_type': messageType ?? 'text',
        'timestamp': DateTime.now().toIso8601String(),
      }));
    }
  }

  // Send typing indicator
  void sendTypingIndicator(int groupId, bool isTyping) {
    if (_chatChannel != null) {
      _chatChannel!.sink.add(jsonEncode({
        'type': 'typing',
        'group_id': groupId,
        'is_typing': isTyping,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    }
  }

  // Send group update
  void sendGroupUpdate(int groupId, String updateType, Map<String, dynamic> data) {
    if (_groupChannel != null) {
      _groupChannel!.sink.add(jsonEncode({
        'type': 'group_update',
        'group_id': groupId,
        'update_type': updateType,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    }
  }

  // Send reservation update
  void sendReservationUpdate(String updateType, Map<String, dynamic> data) {
    if (_reservationChannel != null) {
      _reservationChannel!.sink.add(jsonEncode({
        'type': 'reservation_update',
        'update_type': updateType,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    }
  }

  // Schedule reconnection
  void _scheduleReconnect(VoidCallback reconnectFunction) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        reconnectFunction();
      }
    });
  }

  // Disconnect all WebSockets
  Future<void> disconnect() async {
    _isConnected = false;
    _reconnectTimer?.cancel();
    
    await _notificationChannel?.sink.close(status.goingAway);
    await _chatChannel?.sink.close(status.goingAway);
    await _groupChannel?.sink.close(status.goingAway);
    await _reservationChannel?.sink.close(status.goingAway);
    
    _notificationChannel = null;
    _chatChannel = null;
    _groupChannel = null;
    _reservationChannel = null;
  }

  // Close all controllers
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    disconnect();
  }

  bool get isConnected => _isConnected;
}

// Provider for WebSocket service
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Stream providers for different WebSocket data
final notificationStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final webSocketService = ref.watch(webSocketServiceProvider);
  return webSocketService.notificationController.stream;
});

final chatStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final webSocketService = ref.watch(webSocketServiceProvider);
  return webSocketService.chatController.stream;
});

final groupStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final webSocketService = ref.watch(webSocketServiceProvider);
  return webSocketService.groupController.stream;
});

final reservationStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final webSocketService = ref.watch(webSocketServiceProvider);
  return webSocketService.reservationController.stream;
});