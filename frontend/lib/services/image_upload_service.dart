import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import '../core/constants/app_constants.dart';
import 'api_service.dart';

class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  final ApiService _apiService = ApiService();

  /// Pick image from gallery or camera
  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      debugPrint(
        '📸 IMAGE PICKER: Picking image from ${fromCamera ? 'camera' : 'gallery'}',
      );

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        debugPrint(
          '📸 IMAGE PICKER: Image selected: ${result.files.first.path}',
        );
        return File(result.files.first.path!);
      } else {
        debugPrint('📸 IMAGE PICKER: No image selected');
        return null;
      }
    } catch (e) {
      debugPrint('❌ IMAGE PICKER: Error picking image: $e');
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Upload image to server
  Future<String?> uploadImage(File imageFile) async {
    try {
      debugPrint('📤 IMAGE UPLOAD: Starting upload for ${imageFile.path}');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/exams/upload-image'),
      );

      // Add authorization header from API service
      final headers = _apiService.getHeaders();
      request.headers.addAll(headers);

      // Add image file with proper content type
      final fileExtension = path.extension(imageFile.path).toLowerCase();
      MediaType contentType;

      switch (fileExtension) {
        case '.jpg':
        case '.jpeg':
          contentType = MediaType('image', 'jpeg');
          break;
        case '.png':
          contentType = MediaType('image', 'png');
          break;
        case '.gif':
          contentType = MediaType('image', 'gif');
          break;
        case '.webp':
          contentType = MediaType('image', 'webp');
          break;
        default:
          contentType = MediaType('image', 'jpeg'); // Default fallback
      }

      var multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: path.basename(imageFile.path),
        contentType: contentType,
      );
      request.files.add(multipartFile);

      debugPrint('📤 IMAGE UPLOAD: Sending request to server...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('📤 IMAGE UPLOAD: Response status: ${response.statusCode}');
      debugPrint('📤 IMAGE UPLOAD: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final imageUrl = responseData['imageUrl'] as String?;
        debugPrint('📤 IMAGE UPLOAD: Upload successful, image URL: $imageUrl');
        return imageUrl;
      } else {
        debugPrint(
          '❌ IMAGE UPLOAD: Upload failed with status ${response.statusCode}',
        );
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ IMAGE UPLOAD: Error uploading image: $e');
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Show image source selection dialog
  Future<File?> showImageSourceDialog() async {
    // This will be handled by the UI layer
    return null;
  }

  /// Upload question image and return URL
  Future<String?> uploadQuestionImage(File imageFile) async {
    try {
      debugPrint('📸 QUESTION IMAGE UPLOAD: Starting upload');
      debugPrint('   File path: ${imageFile.path}');
      debugPrint('   File size: ${await imageFile.length()} bytes');

      final uri = Uri.parse(
        '${AppConstants.baseUrl}/exams/upload-question-image',
      );
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      final headers = _apiService.getHeaders();
      request.headers.addAll(headers);

      // Add file
      final fileName = path.basename(imageFile.path);
      final fileExtension = path.extension(fileName).toLowerCase();

      // Determine content type based on file extension
      String contentType;
      switch (fileExtension) {
        case '.jpg':
        case '.jpeg':
          contentType = 'image/jpeg';
          break;
        case '.png':
          contentType = 'image/png';
          break;
        case '.gif':
          contentType = 'image/gif';
          break;
        case '.webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg'; // Default fallback
      }

      debugPrint('📸 QUESTION IMAGE UPLOAD: Content type set to $contentType');

      var multipartFile = await http.MultipartFile.fromPath(
        'questionImage',
        imageFile.path,
        filename: path.basename(imageFile.path),
        contentType: MediaType.parse(contentType),
      );
      request.files.add(multipartFile);

      debugPrint('📤 QUESTION IMAGE UPLOAD: Sending request to server...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint(
        '📤 QUESTION IMAGE UPLOAD: Response status: ${response.statusCode}',
      );
      debugPrint('📤 QUESTION IMAGE UPLOAD: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final imageUrl = responseData['imageUrl'] as String?;
        debugPrint(
          '📤 QUESTION IMAGE UPLOAD: Upload successful, image URL: $imageUrl',
        );
        return imageUrl;
      } else {
        debugPrint(
          '❌ QUESTION IMAGE UPLOAD: Upload failed with status ${response.statusCode}',
        );
        throw Exception(
          'Failed to upload question image: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ QUESTION IMAGE UPLOAD: Error uploading image: $e');
      debugPrint('Error uploading question image: $e');
      return null;
    }
  }
}
