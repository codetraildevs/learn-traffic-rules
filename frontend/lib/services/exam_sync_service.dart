import 'package:flutter/foundation.dart';
import 'offline_exam_service.dart';
import 'exam_service.dart';
import 'user_management_service.dart';
import 'network_service.dart';

class ExamSyncService {
  final OfflineExamService _offlineService = OfflineExamService();
  final ExamService _examService = ExamService();
  final UserManagementService _userManagementService = UserManagementService();
  final NetworkService _networkService = NetworkService();

  bool _isSyncing = false;

  /// Download and cache all exams when online
  Future<void> downloadAllExams() async {
    if (_isSyncing) {
      debugPrint('🔄 Sync already in progress, skipping...');
      return;
    }

    final hasInternet = await _networkService.hasInternetConnection();
    if (!hasInternet) {
      debugPrint('🌐 No internet connection, cannot download exams');
      return;
    }

    _isSyncing = true;
    try {
      debugPrint('📥 Starting exam download...');

      // Get all free exams from API
      final response = await _userManagementService.getFreeExams();

      if (!response.success) {
        debugPrint('❌ Failed to fetch exams: ${response.message}');
        return;
      }

      final exams = response.data.exams;
      debugPrint('📥 Found ${exams.length} exams to download');

      int totalQuestions = 0;
      int successCount = 0;
      int failCount = 0;

      // Download each exam with its questions
      for (final exam in exams) {
        try {
          // Get questions for this exam
          final questions = await _examService.getQuestionsByExamId(exam.id);

          // Save exam and questions offline
          await _offlineService.saveExam(exam, questions);

          totalQuestions += questions.length;
          successCount++;

          debugPrint(
            '✅ Downloaded exam ${exam.id}: ${questions.length} questions',
          );
        } catch (e) {
          debugPrint('❌ Failed to download exam ${exam.id}: $e');
          failCount++;
        }
      }

      // Update sync status
      await _offlineService.updateSyncStatus(
        totalExams: successCount,
        totalQuestions: totalQuestions,
      );

      debugPrint(
        '📥 Download complete: $successCount exams, $totalQuestions questions',
      );
      if (failCount > 0) {
        debugPrint('⚠️ Failed to download $failCount exams');
      }
    } catch (e) {
      debugPrint('❌ Error downloading exams: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync unsynced exam results to server
  Future<void> syncExamResults() async {
    if (_isSyncing) {
      debugPrint('🔄 Sync already in progress, skipping...');
      return;
    }

    final hasInternet = await _networkService.hasInternetConnection();
    if (!hasInternet) {
      debugPrint('🌐 No internet connection, cannot sync results');
      return;
    }

    _isSyncing = true;
    try {
      debugPrint('🔄 Starting exam result sync...');

      // Get all unsynced results
      final unsyncedResults = await _offlineService.getUnsyncedResults();

      if (unsyncedResults.isEmpty) {
        debugPrint('✅ No unsynced results to sync');
        return;
      }

      debugPrint('🔄 Found ${unsyncedResults.length} unsynced results');

      int successCount = 0;
      int failCount = 0;

      // Sync each result
      for (final result in unsyncedResults) {
        try {
          if (result['isFreeExam'] == true) {
            // Sync free exam result
            await _userManagementService.submitFreeExam(
              result['examId'] as String,
              Map<String, String>.from(result['answers'] as Map),
              timeSpent: result['timeSpent'] as int,
            );
          } else {
            // Sync regular exam result
            await _examService.submitExamResult(
              examId: result['examId'] as String,
              answers: Map<String, String>.from(result['answers'] as Map),
              timeSpent: result['timeSpent'] as int,
              isFreeExam: false,
            );
          }

          // Mark as synced
          await _offlineService.markResultAsSynced(result['id'] as int);
          successCount++;

          debugPrint('✅ Synced result for exam ${result['examId']}');
        } catch (e) {
          debugPrint('❌ Failed to sync result ${result['id']}: $e');
          failCount++;
        }
      }

      debugPrint('🔄 Sync complete: $successCount synced, $failCount failed');
    } catch (e) {
      debugPrint('❌ Error syncing results: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Full sync: download exams and sync results
  Future<void> fullSync() async {
    if (_isSyncing) {
      debugPrint('🔄 Sync already in progress, skipping...');
      return;
    }

    final hasInternet = await _networkService.hasInternetConnection();
    if (!hasInternet) {
      debugPrint('🌐 No internet connection, cannot sync');
      return;
    }

    debugPrint('🔄 Starting full sync...');

    // First sync results (they might be older)
    await syncExamResults();

    // Then download/update exams
    await downloadAllExams();

    debugPrint('✅ Full sync complete');
  }

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;
}
