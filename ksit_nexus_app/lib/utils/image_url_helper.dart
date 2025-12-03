import '../config/api_config.dart';

/// Utility class for handling image URLs from the backend
/// Ensures all image URLs are absolute and use the correct base URL for mobile
class ImageUrlHelper {
  /// Normalize an image URL to ensure it's absolute
  /// 
  /// Handles:
  /// - Relative URLs (e.g., /media/profile_pictures/...)
  /// - Absolute URLs (e.g., https://ksitnexus.onrender.com/media/...)
  /// - Already full URLs (e.g., https://example.com/image.jpg)
  /// 
  /// Returns null if the input is null or empty
  static String? normalizeImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    // If already a full URL (http:// or https://), return as is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // If it's a relative URL (starts with /), prepend the media base URL
    if (imageUrl.startsWith('/')) {
      return '${ApiConfig.mediaBaseUrl}$imageUrl';
    }

    // If it doesn't start with /, assume it's a relative path and add /
    return '${ApiConfig.mediaBaseUrl}/$imageUrl';
  }

  /// Get profile picture URL
  /// Convenience method for profile pictures
  static String? getProfilePictureUrl(String? profilePicture) {
    return normalizeImageUrl(profilePicture);
  }

  /// Get media file URL
  /// Convenience method for media files
  static String? getMediaUrl(String? mediaPath) {
    return normalizeImageUrl(mediaPath);
  }
}

