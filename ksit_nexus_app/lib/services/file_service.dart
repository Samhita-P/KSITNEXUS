import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class FileService {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  // Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      return image;
    } catch (e) {
      print('Error picking image from gallery: $e');
    }
    return null;
  }

  // Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      return image;
    } catch (e) {
      print('Error picking image from camera: $e');
    }
    return null;
  }

  // Pick file from device
  Future<File?> pickFile({List<String>? allowedExtensions}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          // For mobile/desktop platforms
          return File(file.path!);
        } else if (file.bytes != null) {
          // For web platform - create temporary file from bytes
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/${file.name}');
          await tempFile.writeAsBytes(file.bytes!);
          return tempFile;
        }
      }
    } catch (e) {
      print('Error picking file: $e');
    }
    return null;
  }

  // Pick multiple files
  Future<List<File>> pickMultipleFiles({List<String>? allowedExtensions}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );

      if (result != null) {
        List<File> files = [];
        for (var file in result.files) {
          if (file.path != null) {
            // For mobile/desktop platforms
            files.add(File(file.path!));
          } else if (file.bytes != null) {
            // For web platform - create temporary file from bytes
            final tempDir = await getTemporaryDirectory();
            final tempFile = File('${tempDir.path}/${file.name}');
            await tempFile.writeAsBytes(file.bytes!);
            files.add(tempFile);
          }
        }
        return files;
      }
    } catch (e) {
      print('Error picking multiple files: $e');
    }
    return [];
  }

  // Note: File upload methods removed as backend doesn't have separate file upload endpoints
  // Files are uploaded directly with their respective entities (complaints, etc.)

  // Upload complaint attachment - returns file path for use in complaint creation
  Future<String> uploadComplaintAttachment(File file) async {
    // Since the backend doesn't have separate file upload endpoints,
    // we just return the file path. The actual upload happens when creating the complaint.
    return file.path;
  }

  // Download file
  Future<File> downloadFile(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to download file: ${e.toString()}');
    }
  }

  // Get file size in human readable format
  String getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '${bytes}B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
      if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    } catch (e) {
      // Fallback for web platform or when lengthSync is not available
      return 'Unknown size';
    }
  }

  // Get file extension
  String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  // Check if file is image
  bool isImageFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  // Check if file is document
  bool isDocumentFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(extension);
  }

  // Check if file is video
  bool isVideoFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'].contains(extension);
  }

  // Check if file is audio
  bool isAudioFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['mp3', 'wav', 'aac', 'flac', 'ogg'].contains(extension);
  }

  // Validate file size
  bool validateFileSize(File file, int maxSizeInMB) {
    try {
      final bytes = file.lengthSync();
      final maxBytes = maxSizeInMB * 1024 * 1024;
      return bytes <= maxBytes;
    } catch (e) {
      // For web platform, assume file is valid if we can't check size
      return true;
    }
  }

  // Validate file type
  bool validateFileType(String fileName, List<String> allowedExtensions) {
    final extension = getFileExtension(fileName);
    return allowedExtensions.contains(extension);
  }

  // Request storage permission
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Check if file exists
  bool fileExists(String filePath) {
    return File(filePath).existsSync();
  }

  // Delete file
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
    return false;
  }

  // Get file info
  Map<String, dynamic> getFileInfo(File file) {
    try {
      final stat = file.statSync();
      return {
        'name': file.path.split('/').last,
        'path': file.path,
        'size': stat.size,
        'sizeFormatted': getFileSize(file),
        'extension': getFileExtension(file.path),
        'isImage': isImageFile(file.path),
        'isDocument': isDocumentFile(file.path),
        'isVideo': isVideoFile(file.path),
        'isAudio': isAudioFile(file.path),
        'modified': stat.modified,
        'created': stat.changed,
      };
    } catch (e) {
      // Fallback for web platform or when statSync is not available
      return {
        'name': file.path.split('/').last,
        'path': file.path,
        'size': 0,
        'sizeFormatted': 'Unknown size',
        'extension': getFileExtension(file.path),
        'isImage': isImageFile(file.path),
        'isDocument': isDocumentFile(file.path),
        'isVideo': isVideoFile(file.path),
        'isAudio': isAudioFile(file.path),
        'modified': DateTime.now(),
        'created': DateTime.now(),
      };
    }
  }

  // Create directory if it doesn't exist
  Future<Directory> createDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  // Get application documents directory
  Future<Directory> getDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  // Get temporary directory
  Future<Directory> getTemporaryDirectory() async {
    return await getTemporaryDirectory();
  }

  // Save file to documents directory
  Future<File> saveFileToDocuments(Uint8List data, String fileName) async {
    final directory = await getDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(data);
    return file;
  }

  // Read file as bytes
  Future<Uint8List> readFileAsBytes(File file) async {
    return await file.readAsBytes();
  }

  // Read file as string
  Future<String> readFileAsString(File file) async {
    return await file.readAsString();
  }
}