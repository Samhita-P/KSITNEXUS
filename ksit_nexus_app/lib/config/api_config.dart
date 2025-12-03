import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Configuration
/// 
/// Uses environment variables from .env file for configuration.
/// 
/// Setup Instructions:
/// 1. Copy .env.example to .env in the root of ksit_nexus_app/
/// 2. Update API_BASE_URL in .env with your Render backend URL:
///    API_BASE_URL=https://ksit-nexus.onrender.com
/// 3. For local development, you can use:
///    API_BASE_URL=http://192.168.x.x:8002
/// 
/// The app will automatically use the URL from .env file.
class ApiConfig {
  // Get the base URL from environment variables
  // Falls back to localhost for web, or a default for mobile if not set
  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    
    if (envUrl != null && envUrl.isNotEmpty) {
      // Use environment variable if set
      // Ensure it ends with /api, add if missing
      if (envUrl.endsWith('/api')) {
        return envUrl;
      } else {
        return '$envUrl/api';
      }
    }
    
    // Fallback for development
    if (kIsWeb) {
      return 'http://localhost:8002/api';
    } else {
      // Default fallback for mobile (should not happen if .env is configured)
      return 'https://ksit-nexus.onrender.com/api';
    }
  }
  
  // Get WebSocket URL
  static String get websocketUrl {
    final wsUrl = dotenv.env['WEBSOCKET_URL'];
    
    if (wsUrl != null && wsUrl.isNotEmpty) {
      return wsUrl;
    }
    
    // Fallback: derive from base URL
    final base = baseUrl.replaceAll('/api', '');
    if (base.startsWith('https://')) {
      return base.replaceFirst('https://', 'wss://') + '/ws';
    } else if (base.startsWith('http://')) {
      return base.replaceFirst('http://', 'ws://') + '/ws';
    }
    
    // Default fallback
    if (kIsWeb) {
      return 'ws://localhost:8001/ws';
    } else {
      return 'wss://ksit-nexus.onrender.com/ws';
    }
  }
  
  // Get media/base URL for images and files
  static String get mediaBaseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    
    if (envUrl != null && envUrl.isNotEmpty) {
      // Remove /api suffix if present
      if (envUrl.endsWith('/api')) {
        return envUrl.substring(0, envUrl.length - 4);
      }
      return envUrl;
    }
    
    // Fallback for development
    if (kIsWeb) {
      return 'http://localhost:8002';
    } else {
      return 'https://ksit-nexus.onrender.com';
    }
  }
}

