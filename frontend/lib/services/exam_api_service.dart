import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/exam_model.dart';
import 'api_service.dart';

class ExamApiService {
  static final ExamApiService _instance = ExamApiService._internal();
  factory ExamApiService() => _instance;
  ExamApiService._internal();

  final ApiService _apiService = ApiService();

  /// Get all exams
  Future<List<Exam>> getExams() async {
    try {
      debugPrint(
        '🔄 EXAM API: Making request to ${AppConstants.examsEndpoint}',
      );
      final response = await _apiService.makeRequest(
        'GET',
        AppConstants.examsEndpoint,
      );
      debugPrint('🔄 EXAM API: Received response: $response');
      final examsData = response['data'] as List;
      debugPrint('🔄 EXAM API: Found ${examsData.length} exams in response');
      debugPrint('Exams data: $examsData');
      final exams = examsData.map((exam) => Exam.fromJson(exam)).toList();
      debugPrint('🔄 EXAM API: Successfully parsed ${exams.length} exams');
      return exams;
    } catch (e) {
      debugPrint('❌ EXAM API: Error fetching exams: $e');
      debugPrint('Error fetching exams: $e');
      rethrow;
    }
  }

  /// Get exam by ID
  Future<Exam> getExam(String examId) async {
    try {
      final response = await _apiService.makeRequest(
        'GET',
        '${AppConstants.examsEndpoint}/$examId',
      );
      return Exam.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error fetching exam $examId: $e');
      rethrow;
    }
  }

  /// Create new exam
  Future<Exam> createExam(CreateExamRequest request) async {
    try {
      final response = await _apiService.makeRequest(
        'POST',
        AppConstants.examsEndpoint,
        body: request.toJson(),
      );
      return Exam.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error creating exam: $e');
      rethrow;
    }
  }

  /// Update exam
  Future<Exam> updateExam(String examId, UpdateExamRequest request) async {
    try {
      final response = await _apiService.makeRequest(
        'PUT',
        '${AppConstants.examsEndpoint}/$examId',
        body: request.toJson(),
      );
      return Exam.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error updating exam $examId: $e');
      rethrow;
    }
  }

  /// Delete exam
  Future<void> deleteExam(String examId) async {
    try {
      await _apiService.makeRequest(
        'DELETE',
        '${AppConstants.examsEndpoint}/$examId',
      );
    } catch (e) {
      debugPrint('Error deleting exam $examId: $e');
      rethrow;
    }
  }

  /// Toggle exam active status
  Future<Exam> toggleExamStatus(String examId) async {
    try {
      final response = await _apiService.makeRequest(
        'PUT',
        '${AppConstants.examsEndpoint}/$examId/toggle-status',
      );
      return Exam.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error toggling exam status $examId: $e');
      rethrow;
    }
  }

  /// Get exam statistics
  Future<Map<String, dynamic>> getExamStats(String examId) async {
    try {
      final response = await _apiService.makeRequest(
        'GET',
        '${AppConstants.examsEndpoint}/$examId/stats',
      );
      return response['data'];
    } catch (e) {
      debugPrint('Error fetching exam stats $examId: $e');
      rethrow;
    }
  }

  /// Get all exam categories
  Future<List<String>> getExamCategories() async {
    try {
      final response = await _apiService.makeRequest(
        'GET',
        '${AppConstants.examsEndpoint}/categories',
      );
      return List<String>.from(response['data']);
    } catch (e) {
      debugPrint('Error fetching exam categories: $e');
      rethrow;
    }
  }
}
