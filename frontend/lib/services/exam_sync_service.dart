import 'dart:async';
import 'package:flutter/foundation.dart';
import 'offline_exam_service.dart';
import 'exam_service.dart';
import 'user_management_service.dart';
import 'network_service.dart';
import 'image_cache_service.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart' as question_model;

class ExamSyncService {
  final OfflineExamService _offlineService = OfflineExamService();
  final ExamService _examService = ExamService();
  final UserManagementService _userManagementService = UserManagementService();
  final NetworkService _networkService = NetworkService();

  bool _isSyncing = false;

  /// Download and cache all exams when online
  /// Only downloads new or updated exams to avoid unnecessary downloads
  /// Set forceDownload to true to re-download all exams regardless of change detection
  Future<void> downloadAllExams({bool forceDownload = false}) async {
    if (_isSyncing) {
      debugPrint('🔄 Sync already in progress, skipping...');
      return;
    }

    // Check internet connectivity BEFORE starting
    final hasInternet = await _networkService.hasInternetConnection();
    if (!hasInternet) {
      debugPrint('🌐 No internet connection, cannot download exams');
      return;
    }

    _isSyncing = true;
    try {
      debugPrint('📥 Starting exam download...');

      // Get ALL available exams from API (not just free exams)
      // This ensures all exams are downloaded for offline use
      List<Exam> exams;
      try {
        // Double-check connectivity before fetching exams list
        final hasInternetForList = await _networkService
            .hasInternetConnection();
        if (!hasInternetForList) {
          debugPrint(
            '🌐 No internet connection before fetching exams list, aborting',
          );
          return;
        }

        exams = await _examService.getAvailableExams();
        debugPrint('📥 Found ${exams.length} exams from API');

        // Log exam types for debugging
        final examsByType = <String, int>{};
        for (final exam in exams) {
          final type = exam.examType?.toLowerCase() ?? 'unknown';
          examsByType[type] = (examsByType[type] ?? 0) + 1;
        }
        debugPrint('📥 Exams by type: $examsByType');

        if (exams.isEmpty) {
          debugPrint('⚠️ No exams found from API, nothing to download');
          return;
        }
      } catch (e) {
        // Check if it's a network error
        final errorString = e.toString().toLowerCase();
        final isNetworkError =
            errorString.contains('network') ||
            errorString.contains('internet') ||
            errorString.contains('connection') ||
            errorString.contains('socket') ||
            errorString.contains('status: 0');

        if (isNetworkError) {
          debugPrint(
            '❌ Network error while fetching exams list: $e. Aborting download.',
          );
        } else {
          debugPrint('❌ Failed to fetch exams from API: $e');
        }
        // If we can't fetch exams list, we can't proceed
        return;
      }

      // Get existing offline exams to compare
      final existingExams = await _offlineService.getAllExams();
      final existingExamMap = <String, Exam>{};
      for (final exam in existingExams) {
        existingExamMap[exam.id] = exam;
      }
      debugPrint('📥 Found ${existingExams.length} existing offline exams');

      int totalQuestions = 0;
      int successCount = 0;
      int failCount = 0;
      int skippedCount = 0;

      // Initialize image cache service
      await ImageCacheService.instance.initialize();

      // OPTIMIZATION: Download exams in batches with delays to prevent ANR
      // Download each exam with its questions
      int batchCount = 0;
      for (final exam in exams) {
        // OPTIMIZATION: Add small delay every 5 exams to prevent ANR
        if (batchCount > 0 && batchCount % 5 == 0) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        batchCount++;

        // Check internet connectivity BEFORE each exam download
        // If we lose connectivity, stop trying to download
        final stillHasInternet = await _networkService.hasInternetConnection();
        if (!stillHasInternet) {
          debugPrint(
            '🌐 Internet connection lost during download, stopping sync. Downloaded: $successCount, Failed: $failCount, Skipped: $skippedCount',
          );
          break; // Stop downloading if internet is lost
        }

        try {
          // Check if exam needs to be downloaded/updated
          final existingExam = existingExamMap[exam.id];
          final needsDownload =
              forceDownload || _needsDownload(exam, existingExam);

          if (!needsDownload) {
            debugPrint('⏭️ Skipping exam ${exam.id} (no changes detected)');
            skippedCount++;
            continue;
          }

          debugPrint(
            '📥 Downloading exam ${exam.id} (${existingExam != null ? 'updated' : 'new'})',
          );

          // Get questions for this exam
          // Check connectivity again before fetching questions
          final hasInternetForQuestions = await _networkService
              .hasInternetConnection();
          if (!hasInternetForQuestions) {
            debugPrint(
              '🌐 Internet connection lost before fetching questions for exam ${exam.id}, stopping sync',
            );
            break; // Stop downloading if internet is lost
          }

          List<question_model.Question> questions;
          try {
            // Pass exam type and free status to help with backend logic
            questions = await _examService.getQuestionsByExamId(
              exam.id,
              isFreeExam: exam.isFirstTwo ?? false,
              examType: exam.examType,
            );
          } catch (e) {
            // Check if it's a payment error (403) for a free exam
            final errorString = e.toString().toLowerCase();
            final isPaymentError =
                errorString.contains('403') ||
                errorString.contains('requires payment') ||
                errorString.contains('payment');
            final isFreeExam = exam.isFirstTwo ?? false;

            if (isPaymentError && isFreeExam) {
              // Free exam blocked by backend - this is a backend issue
              // Skip it but log it as a backend problem, not a user error
              debugPrint(
                '⚠️ Backend blocking free exam ${exam.id} (${exam.title}, type: ${exam.examType}): $e',
              );
              debugPrint(
                '   This is a backend issue - free exams should be accessible',
              );
              skippedCount++;
              continue; // Skip this exam and continue with next
            }

            // Check if it's a "no questions" error
            final isNoQuestionsError =
                errorString.contains('no questions') ||
                errorString.contains('questions available');

            if (isNoQuestionsError) {
              debugPrint(
                '⚠️ Skipping exam ${exam.id} (${exam.title}): No questions available',
              );
              skippedCount++;
              continue; // Skip this exam and continue with next
            }

            // Check if it's a network error
            final isNetworkError =
                errorString.contains('network') ||
                errorString.contains('internet') ||
                errorString.contains('connection') ||
                errorString.contains('socket') ||
                errorString.contains('status: 0');

            if (isNetworkError) {
              // Verify we're actually offline
              final stillOnline = await _networkService.hasInternetConnection();
              if (!stillOnline) {
                debugPrint(
                  '🌐 Internet connection lost while fetching questions for exam ${exam.id}, stopping sync',
                );
                break; // Stop downloading if internet is lost
              }
            }
            // Re-throw if not a network error or if we're still online (might be a different error)
            debugPrint('❌ Failed to fetch questions for exam ${exam.id}: $e');
            failCount++;
            continue; // Skip this exam and continue with next
          }

          // Check if questions list is empty
          if (questions.isEmpty) {
            debugPrint(
              '⚠️ Skipping exam ${exam.id} (${exam.title}): Questions list is empty',
            );
            skippedCount++;
            continue; // Skip this exam and continue with next
          }

          // OPTIMIZATION: Cache images in background to prevent ANR
          // Download and cache images for questions (only if we still have internet)
          // Images can be cached later when online, so don't fail the exam download if image caching fails
          // Use hasInternetForQuestions instead of stillHasInternet since we just checked it
          if (hasInternetForQuestions) {
            // OPTIMIZATION: Cache images in background (non-blocking)
            // Don't await - let it happen in background to prevent ANR
            _cacheQuestionImagesInBackground(exam, questions).catchError((e) {
              debugPrint('⚠️ Background image caching error: $e');
            });
          }

          // Save exam to offline storage with timeout to prevent ANR
          await _offlineService.saveExam(exam, questions).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⚠️ saveExam timeout for ${exam.id}');
              throw TimeoutException('saveExam timeout');
            },
          );

          totalQuestions += questions.length;
          successCount++;

          debugPrint(
            '✅ Downloaded exam ${exam.id}: ${questions.length} questions',
          );
        } catch (e) {
          // Check if error is due to network issues
          final errorString = e.toString().toLowerCase();
          final isNetworkError =
              errorString.contains('network') ||
              errorString.contains('internet') ||
              errorString.contains('connection') ||
              errorString.contains('socket') ||
              errorString.contains('status: 0');

          if (isNetworkError) {
            // If it's a network error, check connectivity and stop if offline
            final stillHasInternet = await _networkService
                .hasInternetConnection();
            if (!stillHasInternet) {
              debugPrint(
                '🌐 Internet connection lost, stopping sync after network error',
              );
              break; // Stop downloading if internet is lost
            }
          }

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
        '📥 Download complete: $successCount new/updated, $skippedCount skipped, $failCount failed',
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

  /// Download a single exam with its questions
  /// Useful when user tries to start an exam that hasn't been downloaded yet
  Future<void> downloadSingleExam(Exam exam) async {
    try {
      debugPrint('📥 Downloading single exam: ${exam.id} (${exam.title})');
      debugPrint('   Exam Type: ${exam.examType}');

      // Check internet connectivity
      final hasInternet = await _networkService.hasInternetConnection();
      if (!hasInternet) {
        throw Exception('No internet connection');
      }

      // Get questions for this exam
      List<question_model.Question> questions;
      try {
        questions = await _examService.getQuestionsByExamId(
          exam.id,
          isFreeExam: exam.isFirstTwo ?? false,
          examType: exam.examType,
        );
        debugPrint('   Questions fetched: ${questions.length}');
      } catch (e) {
        // Check if it's a payment error (403) for a free exam
        final errorString = e.toString().toLowerCase();
        final isPaymentError =
            errorString.contains('403') ||
            errorString.contains('requires payment') ||
            errorString.contains('payment');
        final isFreeExam = exam.isFirstTwo ?? false;

        if (isPaymentError && isFreeExam) {
          // Free exam blocked by backend - this is a backend issue
          debugPrint(
            '⚠️ Backend blocking free exam ${exam.id} (${exam.title}, type: ${exam.examType})',
          );
          debugPrint(
            '   This is a backend issue - free exams should be accessible',
          );
          throw Exception(
            'Backend is blocking this free exam. This is a backend configuration issue.',
          );
        }

        debugPrint('❌ Failed to fetch questions for exam ${exam.id}: $e');
        rethrow;
      }

      if (questions.isEmpty) {
        debugPrint('⚠️ Exam ${exam.id} has no questions');
        throw Exception('No questions available for this exam');
      }

      // Download and cache images for questions (if internet available)
      if (hasInternet) {
        int imageCacheSuccess = 0;
        int imageCacheFail = 0;
        for (final question in questions) {
          if (question.questionImgUrl != null &&
              question.questionImgUrl!.isNotEmpty) {
            try {
              final cachedPath = await ImageCacheService.instance.cacheImage(
                question.questionImgUrl!,
              );
              if (cachedPath != null) {
                imageCacheSuccess++;
              } else {
                imageCacheFail++;
              }
            } catch (e) {
              imageCacheFail++;
              // Continue even if image caching fails
            }
          }
        }
        if (imageCacheSuccess > 0 || imageCacheFail > 0) {
          debugPrint(
            '🖼️ Image caching: $imageCacheSuccess successful, $imageCacheFail failed',
          );
        }

        // Download and cache exam image if available
        if (exam.examImgUrl != null && exam.examImgUrl!.isNotEmpty) {
          try {
            await ImageCacheService.instance.cacheImage(exam.examImgUrl!);
          } catch (e) {
            // Continue even if image caching fails
          }
        }
      }

      // Save exam and questions offline
      await _offlineService.saveExam(exam, questions);
      debugPrint(
        '✅ Successfully downloaded exam ${exam.id} with ${questions.length} questions',
      );
    } catch (e) {
      debugPrint('❌ Error downloading single exam: $e');
      rethrow;
    }
  }

  /// Check if an exam needs to be downloaded/updated
  /// Returns true if:
  /// - Exam doesn't exist offline
  /// - Exam's updatedAt is newer than offline version
  /// - Exam's questionCount changed
  bool _needsDownload(Exam onlineExam, Exam? offlineExam) {
    // If exam doesn't exist offline, needs download
    if (offlineExam == null) {
      return true;
    }

    // If updatedAt is null, always download (to be safe)
    if (onlineExam.updatedAt == null) {
      return true;
    }

    // Compare updatedAt timestamps
    if (offlineExam.updatedAt == null) {
      // Offline exam has no updatedAt, download to update
      return true;
    }

    // If online exam is newer, needs download
    if (onlineExam.updatedAt!.isAfter(offlineExam.updatedAt!)) {
      return true;
    }

    // If questionCount changed, needs download
    if (onlineExam.questionCount != offlineExam.questionCount) {
      return true;
    }

    // No changes detected, skip download
    return false;
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
  /// Set forceDownload to true to re-download all exams
  Future<void> fullSync({bool forceDownload = false}) async {
    if (_isSyncing) {
      debugPrint('🔄 Sync already in progress, skipping...');
      return;
    }

    final hasInternet = await _networkService.hasInternetConnection();
    if (!hasInternet) {
      debugPrint('🌐 No internet connection, cannot sync');
      return;
    }

    debugPrint('🔄 Starting full sync (forceDownload: $forceDownload)...');

    // First sync results (they might be older)
    await syncExamResults();

    // Then download/update exams
    await downloadAllExams(forceDownload: forceDownload);

    debugPrint('✅ Full sync complete');
  }

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  /// OPTIMIZATION: Cache question images in background to prevent ANR
  Future<void> _cacheQuestionImagesInBackground(
    Exam exam,
    List<question_model.Question> questions,
  ) async {
    try {
      // Cache exam image
      if (exam.examImgUrl != null && exam.examImgUrl!.isNotEmpty) {
        ImageCacheService.instance.cacheImage(exam.examImgUrl!).catchError((e) {
          debugPrint('⚠️ Failed to cache exam image: $e');
          return null;
        });
      }

      // Cache question images in batches with delays
      int batchCount = 0;
      for (final question in questions) {
        if (question.questionImgUrl != null &&
            question.questionImgUrl!.isNotEmpty) {
          // Add delay every 10 images to prevent ANR
          if (batchCount > 0 && batchCount % 10 == 0) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
          batchCount++;

          ImageCacheService.instance
              .cacheImage(question.questionImgUrl!)
              .catchError((e) {
            debugPrint('⚠️ Failed to cache question image: $e');
            return null;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error in background image caching: $e');
    }
  }
}
