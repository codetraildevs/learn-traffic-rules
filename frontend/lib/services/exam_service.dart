import 'package:flutter/foundation.dart';
import '../models/question_model.dart' as question_model;
import '../models/exam_result_model.dart';
import '../models/exam_model.dart';
import 'api_service.dart';

class ExamService {
  final ApiService _apiService = ApiService();

  Future<List<question_model.Question>> getQuestionsByExamId(
    String examId, {
    bool isFreeExam = false,
    String? examType,
  }) async {
    try {
      debugPrint('🔍 FRONTEND DEBUG - Getting questions for exam: $examId');
      debugPrint('   API endpoint: /exams/$examId/take-exam');
      debugPrint('   Is Free Exam: $isFreeExam');
      debugPrint('   Exam Type: $examType');

      // Initialize ApiService to load stored tokens
      await _apiService.initialize();
      final headers = _apiService.getHeaders();
      debugPrint(
        '   ApiService initialized, token available: ${headers.containsKey('Authorization')}',
      );
      debugPrint('   Headers: $headers');
      if (headers.containsKey('Authorization')) {
        debugPrint(
          '   Auth token: ${headers['Authorization']?.substring(0, 20)}...',
        );
      }

      final response = await _apiService.makeRequest(
        'GET',
        '/exams/$examId/take-exam',
        maxRetries: 2, // Reduce retries for exam questions
      );

      debugPrint('🔍 FRONTEND DEBUG - API Response received:');
      debugPrint('   Response type: ${response.runtimeType}');
      debugPrint('   Success: ${response['success']}');
      debugPrint('   Message: ${response['message']}');
      debugPrint('   Data type: ${response['data'].runtimeType}');
      debugPrint(
        '   Data length: ${response['data'] is List ? (response['data'] as List).length : 'N/A'}',
      );

      if (response['success'] == true) {
        final data = response['data'];

        // Validate data structure
        if (data == null) {
          throw Exception('No questions data received from server');
        }

        if (data is! List) {
          throw Exception('Invalid questions data format');
        }

        final questionsData = data;
        debugPrint('   Questions data length: ${questionsData.length}');

        if (questionsData.isEmpty) {
          throw Exception('No questions available for this exam');
        }

        if (questionsData.isNotEmpty) {
          debugPrint('   First question sample: ${questionsData.first}');
        }

        // Parse questions with validation
        final List<question_model.Question> questions = [];
        for (int i = 0; i < questionsData.length; i++) {
          try {
            final question = question_model.Question.fromJson(
              questionsData[i] as Map<String, dynamic>,
            );
            questions.add(question);
          } catch (e) {
            debugPrint('❌ Failed to parse question $i: $e');
            // Continue with other questions instead of failing completely
          }
        }

        if (questions.isEmpty) {
          throw Exception('No valid questions could be parsed');
        }

        debugPrint('✅ Successfully parsed ${questions.length} questions');
        return questions;
      } else {
        final errorMessage = response['message'] ?? 'Failed to load questions';
        debugPrint('❌ API returned error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ FRONTEND ERROR: $e');

      // Provide more specific error messages
      if (e.toString().contains('No internet connection')) {
        throw Exception(
          'No internet connection. Please check your network and try again.',
        );
      } else if (e.toString().contains('timeout')) {
        throw Exception('Request timed out. Please try again.');
      } else if (e.toString().contains('401') ||
          e.toString().contains('unauthorized')) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Error loading questions: $e');
      }
    }
  }

  Future<ExamResultResponse> submitExamResult({
    required String examId,
    required Map<String, String> answers,
    required int timeSpent,
    required bool isFreeExam,
  }) async {
    try {
      debugPrint('🔍 FRONTEND DEBUG - Submitting exam result:');
      debugPrint('   Exam ID: $examId');
      debugPrint('   Answers: $answers');
      debugPrint('   Time Spent: $timeSpent');
      debugPrint('   Is Free Exam: $isFreeExam');

      final response = await _apiService.makeRequest(
        'POST',
        '/exams/submit-result',
        body: {
          'examId': examId,
          'answers': answers,
          'timeSpent': timeSpent,
          'isFreeExam': isFreeExam,
        },
        requestTimeout: const Duration(seconds: 65),
      );

      if (response['success'] == true) {
        return ExamResultResponse.fromJson(response);
      } else {
        throw Exception(response['message'] ?? 'Failed to submit exam');
      }
    } catch (e) {
      throw Exception('Error submitting exam: $e');
    }
  }

  Future<List<ExamResultData>> getUserExamResults() async {
    try {
      await _apiService.initialize();

      final response = await _apiService.makeRequest(
        'GET',
        '/exams/user-results',
      );

      if (response['success'] == true) {
        final resultsData = response['data'] as List<dynamic>;
        return resultsData
            .map(
              (resultJson) =>
                  ExamResultData.fromJson(resultJson as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to load exam results');
      }
    } catch (e) {
      throw Exception('Error loading exam results: $e');
    }
  }

  Future<List<Exam>> getAvailableExams() async {
    try {
      await _apiService.initialize();

      final response = await _apiService.makeRequest('GET', '/exams');

      if (response['success'] == true) {
        final examsData = response['data'] as List<dynamic>;
        return examsData
            .map((examJson) => Exam.fromJson(examJson as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to load exams');
      }
    } catch (e) {
      throw Exception('Error loading exams: $e');
    }
  }
}
