import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import '../core/constants/app_constants.dart';
import 'api_service.dart';

class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  /// Pick image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      print('📸 IMAGE PICKER: Picking image from ${source.name}');
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        print('📸 IMAGE PICKER: Image selected: ${image.path}');
        return File(image.path);
      } else {
        print('📸 IMAGE PICKER: No image selected');
        return null;
      }
    } catch (e) {
      print('❌ IMAGE PICKER: Error picking image: $e');
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Upload image to server
  Future<String?> uploadImage(File imageFile) async {
    try {
      print('📤 IMAGE UPLOAD: Starting upload for ${imageFile.path}');

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

      print('📤 IMAGE UPLOAD: Sending request to server...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📤 IMAGE UPLOAD: Response status: ${response.statusCode}');
      print('📤 IMAGE UPLOAD: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final imageUrl = responseData['imageUrl'] as String?;
        print('📤 IMAGE UPLOAD: Upload successful, image URL: $imageUrl');
        return imageUrl;
      } else {
        print(
          '❌ IMAGE UPLOAD: Upload failed with status ${response.statusCode}',
        );
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ IMAGE UPLOAD: Error uploading image: $e');
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
      print('📸 QUESTION IMAGE UPLOAD: Starting upload');
      print('   File path: ${imageFile.path}');
      print('   File size: ${await imageFile.length()} bytes');

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

      print('📸 QUESTION IMAGE UPLOAD: Content type set to $contentType');

      var multipartFile = await http.MultipartFile.fromPath(
        'questionImage',
        imageFile.path,
        filename: path.basename(imageFile.path),
        contentType: MediaType.parse(contentType),
      );
      request.files.add(multipartFile);

      print('📤 QUESTION IMAGE UPLOAD: Sending request to server...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print(
        '📤 QUESTION IMAGE UPLOAD: Response status: ${response.statusCode}',
      );
      print('📤 QUESTION IMAGE UPLOAD: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final imageUrl = responseData['imageUrl'] as String?;
        print(
          '📤 QUESTION IMAGE UPLOAD: Upload successful, image URL: $imageUrl',
        );
        return imageUrl;
      } else {
        print(
          '❌ QUESTION IMAGE UPLOAD: Upload failed with status ${response.statusCode}',
        );
        throw Exception(
          'Failed to upload question image: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ QUESTION IMAGE UPLOAD: Error uploading image: $e');
      debugPrint('Error uploading question image: $e');
      return null;
    }
  }
}
