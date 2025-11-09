import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/course_model.dart';

class CourseService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<CourseListResponse> getAllCourses({
    String? category,
    String? difficulty,
    CourseType? courseType,
    bool? isActive,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      var url = Uri.parse('${AppConstants.baseUrl}/courses');
      final queryParams = <String, String>{};

      if (category != null) queryParams['category'] = category;
      if (difficulty != null) queryParams['difficulty'] = difficulty;
      if (courseType != null) queryParams['courseType'] = courseType.name;
      if (isActive != null) queryParams['isActive'] = isActive.toString();

      if (queryParams.isNotEmpty) {
        url = url.replace(queryParameters: queryParams);
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CourseListResponse.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        return CourseListResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to load courses',
        );
      }
    } catch (e) {
      return CourseListResponse(
        success: false,
        message: 'Error loading courses: $e',
      );
    }
  }

  Future<CourseResponse> getCourseById(
    String courseId, {
    bool includeContents = false,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      var url = Uri.parse('${AppConstants.baseUrl}/courses/$courseId');
      if (includeContents) {
        url = url.replace(queryParameters: {'includeContents': 'true'});
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CourseResponse.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        return CourseResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to load course',
        );
      }
    } catch (e) {
      return CourseResponse(
        success: false,
        message: 'Error loading course: $e',
      );
    }
  }

  Future<CourseResponse> createCourse(CreateCourseRequest request) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/courses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CourseResponse.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        return CourseResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to create course',
        );
      }
    } catch (e) {
      return CourseResponse(
        success: false,
        message: 'Error creating course: $e',
      );
    }
  }

  Future<CourseResponse> updateCourse(
    String courseId,
    UpdateCourseRequest request,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/courses/$courseId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CourseResponse.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        return CourseResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to update course',
        );
      }
    } catch (e) {
      return CourseResponse(
        success: false,
        message: 'Error updating course: $e',
      );
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/courses/$courseId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<CourseListResponse> getUserCourses() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/courses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CourseListResponse.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        return CourseListResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to load user courses',
        );
      }
    } catch (e) {
      return CourseListResponse(
        success: false,
        message: 'Error loading user courses: $e',
      );
    }
  }

  Future<CourseProgressResponse> getCourseProgress(String courseId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/courses/$courseId/progress'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CourseProgressResponse.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        return CourseProgressResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to load course progress',
        );
      }
    } catch (e) {
      return CourseProgressResponse(
        success: false,
        message: 'Error loading course progress: $e',
      );
    }
  }

  Future<bool> updateCourseProgress(
    String courseId,
    String contentId,
    bool isCompleted,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/courses/$courseId/progress'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'contentId': contentId, 'isCompleted': isCompleted}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> enrollInCourse(String courseId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/courses/$courseId/enroll'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
