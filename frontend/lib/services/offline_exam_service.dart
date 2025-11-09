import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart' as question_model;

class OfflineExamService {
  static Database? _database;
  static const String _databaseName = 'offline_exams.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _examsTable = 'offline_exams';
  static const String _questionsTable = 'offline_questions';
  static const String _resultsTable = 'offline_results';
  static const String _syncStatusTable = 'sync_status';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create exams table
    await db.execute('''
      CREATE TABLE $_examsTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT,
        difficulty TEXT,
        duration INTEGER,
        questionCount INTEGER,
        passingScore INTEGER,
        examImgUrl TEXT,
        examType TEXT,
        isActive INTEGER DEFAULT 1,
        isFirstTwo INTEGER DEFAULT 0,
        createdAt TEXT,
        updatedAt TEXT,
        lastUpdated TEXT,
        downloadedAt TEXT,
        version INTEGER DEFAULT 1
      )
    ''');

    // Create questions table
    await db.execute('''
      CREATE TABLE $_questionsTable (
        id TEXT PRIMARY KEY,
        examId TEXT NOT NULL,
        questionText TEXT NOT NULL,
        options TEXT NOT NULL,
        correctAnswer TEXT NOT NULL,
        points INTEGER DEFAULT 1,
        questionImgUrl TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        lastUpdated TEXT,
        FOREIGN KEY (examId) REFERENCES $_examsTable (id) ON DELETE CASCADE
      )
    ''');

    // Create results table
    await db.execute('''
      CREATE TABLE $_resultsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        examId TEXT NOT NULL,
        score REAL NOT NULL,
        totalQuestions INTEGER NOT NULL,
        correctAnswers INTEGER NOT NULL,
        timeSpent INTEGER NOT NULL,
        answers TEXT NOT NULL,
        passed INTEGER NOT NULL DEFAULT 0,
        isFreeExam INTEGER NOT NULL DEFAULT 0,
        completedAt TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create sync status table
    await db.execute('''
      CREATE TABLE $_syncStatusTable (
        id INTEGER PRIMARY KEY DEFAULT 1,
        lastSyncAt TEXT,
        totalExams INTEGER DEFAULT 0,
        totalQuestions INTEGER DEFAULT 0,
        CHECK (id = 1)
      )
    ''');

    // Insert default sync status
    await db.insert(_syncStatusTable, {
      'id': 1,
      'lastSyncAt': null,
      'totalExams': 0,
      'totalQuestions': 0,
    });
  }

  // Save exam with questions
  Future<void> saveExam(
    Exam exam,
    List<question_model.Question> questions,
  ) async {
    final db = await database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      // Save exam
      await txn.insert(_examsTable, {
        'id': exam.id,
        'title': exam.title,
        'description': exam.description,
        'category': exam.category,
        'difficulty': exam.difficulty,
        'duration': exam.duration,
        'questionCount': exam.questionCount ?? questions.length,
        'passingScore': exam.passingScore,
        'examImgUrl': exam.examImgUrl,
        'examType': exam.examType,
        'isActive': exam.isActive ? 1 : 0,
        'isFirstTwo': exam.isFirstTwo == true ? 1 : 0,
        'createdAt': exam.createdAt?.toIso8601String(),
        'updatedAt': exam.updatedAt?.toIso8601String(),
        'lastUpdated': now.toIso8601String(),
        'downloadedAt': now.toIso8601String(),
        'version': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Delete old questions for this exam
      await txn.delete(
        _questionsTable,
        where: 'examId = ?',
        whereArgs: [exam.id],
      );

      // Save questions
      for (final question in questions) {
        await txn.insert(_questionsTable, {
          'id': question.id,
          'examId': question.examId ?? exam.id,
          'questionText': question.questionText,
          'options': jsonEncode(question.options),
          'correctAnswer': question.correctAnswer,
          'points': question.points,
          'questionImgUrl': question.questionImgUrl,
          'createdAt': question.createdAt?.toIso8601String(),
          'updatedAt': question.updatedAt?.toIso8601String(),
          'lastUpdated': now.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });

    debugPrint(
      '💾 Saved exam ${exam.id} with ${questions.length} questions offline',
    );
  }

  // Get exam with questions
  Future<Map<String, dynamic>?> getExam(String examId) async {
    final db = await database;

    final examMaps = await db.query(
      _examsTable,
      where: 'id = ?',
      whereArgs: [examId],
    );

    if (examMaps.isEmpty) return null;

    final examMap = examMaps.first;

    // Get questions for this exam
    final questionsMaps = await db.query(
      _questionsTable,
      where: 'examId = ?',
      whereArgs: [examId],
      orderBy: 'id ASC',
    );

    final questions = questionsMaps.map((q) {
      return question_model.Question(
        id: q['id'] as String,
        examId: q['examId'] as String,
        questionText: q['questionText'] as String,
        options: List<String>.from(jsonDecode(q['options'] as String)),
        correctAnswer: q['correctAnswer'] as String,
        points: q['points'] as int? ?? 1,
        questionImgUrl: q['questionImgUrl'] as String?,
        createdAt: q['createdAt'] != null
            ? DateTime.tryParse(q['createdAt'] as String)
            : null,
        updatedAt: q['updatedAt'] != null
            ? DateTime.tryParse(q['updatedAt'] as String)
            : null,
      );
    }).toList();

    return {
      'exam': Exam(
        id: examMap['id'] as String,
        title: examMap['title'] as String,
        description: examMap['description'] as String?,
        category: examMap['category'] as String?,
        difficulty: examMap['difficulty'] as String,
        duration: examMap['duration'] as int,
        passingScore: examMap['passingScore'] as int,
        isActive: (examMap['isActive'] as int) == 1,
        examImgUrl: examMap['examImgUrl'] as String?,
        questionCount: examMap['questionCount'] as int?,
        isFirstTwo: (examMap['isFirstTwo'] as int) == 1,
        examType: examMap['examType'] as String?,
        createdAt: examMap['createdAt'] != null
            ? DateTime.tryParse(examMap['createdAt'] as String)
            : null,
        updatedAt: examMap['updatedAt'] != null
            ? DateTime.tryParse(examMap['updatedAt'] as String)
            : null,
      ),
      'questions': questions,
    };
  }

  // Get all offline exams
  Future<List<Exam>> getAllExams() async {
    final db = await database;
    final examMaps = await db.query(
      _examsTable,
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'title ASC',
    );

    return examMaps.map((examMap) {
      return Exam(
        id: examMap['id'] as String,
        title: examMap['title'] as String,
        description: examMap['description'] as String?,
        category: examMap['category'] as String?,
        difficulty: examMap['difficulty'] as String,
        duration: examMap['duration'] as int,
        passingScore: examMap['passingScore'] as int,
        isActive: (examMap['isActive'] as int) == 1,
        examImgUrl: examMap['examImgUrl'] as String?,
        questionCount: examMap['questionCount'] as int?,
        isFirstTwo: (examMap['isFirstTwo'] as int) == 1,
        examType: examMap['examType'] as String?,
        createdAt: examMap['createdAt'] != null
            ? DateTime.tryParse(examMap['createdAt'] as String)
            : null,
        updatedAt: examMap['updatedAt'] != null
            ? DateTime.tryParse(examMap['updatedAt'] as String)
            : null,
      );
    }).toList();
  }

  // Save exam result for later sync
  Future<void> saveExamResult({
    required String examId,
    required double score,
    required int totalQuestions,
    required int correctAnswers,
    required int timeSpent,
    required Map<String, String> answers,
    required bool passed,
    required bool isFreeExam,
  }) async {
    final db = await database;

    await db.insert(_resultsTable, {
      'examId': examId,
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'timeSpent': timeSpent,
      'answers': jsonEncode(answers),
      'passed': passed ? 1 : 0,
      'isFreeExam': isFreeExam ? 1 : 0,
      'completedAt': DateTime.now().toIso8601String(),
      'synced': 0, // Not synced yet
    });

    debugPrint('💾 Saved exam result for $examId offline (not synced)');
  }

  // Get unsynced results
  Future<List<Map<String, dynamic>>> getUnsyncedResults() async {
    final db = await database;
    final resultMaps = await db.query(
      _resultsTable,
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'completedAt ASC',
    );

    return resultMaps.map((r) {
      return {
        'id': r['id'] as int,
        'examId': r['examId'] as String,
        'score': r['score'] as double,
        'totalQuestions': r['totalQuestions'] as int,
        'correctAnswers': r['correctAnswers'] as int,
        'timeSpent': r['timeSpent'] as int,
        'answers': jsonDecode(r['answers'] as String) as Map<String, dynamic>,
        'passed': (r['passed'] as int) == 1,
        'isFreeExam': (r['isFreeExam'] as int) == 1,
        'completedAt': r['completedAt'] as String,
      };
    }).toList();
  }

  // Mark result as synced
  Future<void> markResultAsSynced(int resultId) async {
    final db = await database;
    await db.update(
      _resultsTable,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [resultId],
    );
  }

  // Update sync status
  Future<void> updateSyncStatus({
    required int totalExams,
    required int totalQuestions,
  }) async {
    final db = await database;
    await db.update(
      _syncStatusTable,
      {
        'lastSyncAt': DateTime.now().toIso8601String(),
        'totalExams': totalExams,
        'totalQuestions': totalQuestions,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // Get sync status
  Future<Map<String, dynamic>?> getSyncStatus() async {
    final db = await database;
    final statusMaps = await db.query(
      _syncStatusTable,
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (statusMaps.isEmpty) return null;

    final status = statusMaps.first;
    return {
      'lastSyncAt': status['lastSyncAt'] != null
          ? DateTime.tryParse(status['lastSyncAt'] as String)
          : null,
      'totalExams': status['totalExams'] as int,
      'totalQuestions': status['totalQuestions'] as int,
    };
  }

  // Clear all offline data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_examsTable);
    await db.delete(_questionsTable);
    await db.delete(_resultsTable);
    await db.update(
      _syncStatusTable,
      {'lastSyncAt': null, 'totalExams': 0, 'totalQuestions': 0},
      where: 'id = ?',
      whereArgs: [1],
    );
    debugPrint('🗑️ Cleared all offline exam data');
  }
}
