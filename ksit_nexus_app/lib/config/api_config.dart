import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Configuration
/// 
/// Uses environment variables from .env file for configuration.
/// 
/// Setup Instructions:
/// 1. Copy .env.example to .env in the root of ksit_nexus_app/
/// 2. Update API_BASE_URL in .env with your Render backend URL:
///    API_BASE_URL=https://ksitnexus.onrender.com
/// 3. For local development, you can use:
///    API_BASE_URL=http://192.168.x.x:8002
/// 
/// The app will automatically use the URL from .env file.
class ApiConfig {
  // Get the base URL from environment variables
  // Falls back to production URL if .env is not loaded or variable is missing
  static String get baseUrl {
    try {
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
    } catch (e) {
      // dotenv not loaded or error accessing it - use fallback
      print('⚠️ Warning: Could not read API_BASE_URL from .env: $e');
    }
    
    // Safe fallback to production URL
    return 'https://ksitnexus.onrender.com/api';
  }
  
  // Get WebSocket URL
  static String get websocketUrl {
    try {
      final wsUrl = dotenv.env['WEBSOCKET_URL'];
      
      if (wsUrl != null && wsUrl.isNotEmpty) {
        return wsUrl;
      }
    } catch (e) {
      // dotenv not loaded or error accessing it - use fallback
      print('⚠️ Warning: Could not read WEBSOCKET_URL from .env: $e');
    }
    
    // Fallback: derive from base URL
    try {
      final base = baseUrl.replaceAll('/api', '');
      if (base.startsWith('https://')) {
        return base.replaceFirst('https://', 'wss://') + '/ws';
      } else if (base.startsWith('http://')) {
        return base.replaceFirst('http://', 'ws://') + '/ws';
      }
    } catch (e) {
      // Error deriving from baseUrl - use direct fallback
      print('⚠️ Warning: Could not derive WebSocket URL: $e');
    }
    
    // Safe fallback to production WebSocket URL
    return 'wss://ksitnexus.onrender.com/ws';
  }
  
  // Get media/base URL for images and files
  static String get mediaBaseUrl {
    try {
      final envUrl = dotenv.env['API_BASE_URL'];
      
      if (envUrl != null && envUrl.isNotEmpty) {
        // Remove /api suffix if present
        if (envUrl.endsWith('/api')) {
          return envUrl.substring(0, envUrl.length - 4);
        }
        return envUrl;
      }
    } catch (e) {
      // dotenv not loaded or error accessing it - use fallback
      print('⚠️ Warning: Could not read API_BASE_URL from .env for media URL: $e');
    }
    
    // Safe fallback to production URL
    return 'https://ksitnexus.onrender.com';
  }
}

