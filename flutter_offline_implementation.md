# 📱 Flutter Offline Implementation Guide

## 🔄 Offline Exam System for Flutter

This guide shows how to implement offline exam functionality in your Flutter app.

## 📦 Required Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP requests
  http: ^1.1.0
  
  # Local storage
  sqflite: ^2.3.0
  path: ^1.8.3
  
  # JSON handling
  json_annotation: ^4.8.1
  
  # State management
  provider: ^6.1.1
  
  # Connectivity
  connectivity_plus: ^5.0.2
  
  # File operations
  path_provider: ^2.1.1
  
dev_dependencies:
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

## 🗄️ Local Database Models

### 1. Offline Exam Model

```dart
// lib/models/offline_exam.dart
import 'package:json_annotation/json_annotation.dart';

part 'offline_exam.g.dart';

@JsonSerializable()
class OfflineExam {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int duration;
  final int questionCount;
  final int passingScore;
  final String? examImgUrl;
  final DateTime lastUpdated;
  final List<OfflineQuestion> questions;
  final DateTime downloadedAt;
  final int version;

  OfflineExam({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.duration,
    required this.questionCount,
    required this.passingScore,
    this.examImgUrl,
    required this.lastUpdated,
    required this.questions,
    required this.downloadedAt,
    required this.version,
  });

  factory OfflineExam.fromJson(Map<String, dynamic> json) => _$OfflineExamFromJson(json);
  Map<String, dynamic> toJson() => _$OfflineExamToJson(this);
}

@JsonSerializable()
class OfflineQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final String difficulty;
  final int points;
  final String? imageUrl;
  final String? questionImgUrl;
  final DateTime lastUpdated;

  OfflineQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    required this.difficulty,
    required this.points,
    this.imageUrl,
    this.questionImgUrl,
    required this.lastUpdated,
  });

  factory OfflineQuestion.fromJson(Map<String, dynamic> json) => _$OfflineQuestionFromJson(json);
  Map<String, dynamic> toJson() => _$OfflineQuestionToJson(this);
}
```

### 2. Offline Exam Result Model

```dart
// lib/models/offline_exam_result.dart
import 'package:json_annotation/json_annotation.dart';

part 'offline_exam_result.g.dart';

@JsonSerializable()
class OfflineExamResult {
  final String examId;
  final double score;
  final int totalQuestions;
  final int correctAnswers;
  final int timeSpent; // in seconds
  final Map<String, String> answers; // questionId: selectedAnswer
  final bool passed;
  final DateTime completedAt;
  final bool synced; // whether this result has been synced to server

  OfflineExamResult({
    required this.examId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeSpent,
    required this.answers,
    required this.passed,
    required this.completedAt,
    this.synced = false,
  });

  factory OfflineExamResult.fromJson(Map<String, dynamic> json) => _$OfflineExamResultFromJson(json);
  Map<String, dynamic> toJson() => _$OfflineExamResultToJson(this);
}
```

## 🗃️ Local Database Service

```dart
// lib/services/local_database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/offline_exam.dart';
import '../models/offline_exam_result.dart';

class LocalDatabaseService {
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
        lastUpdated TEXT,
        downloadedAt TEXT,
        version INTEGER
      )
    ''');

    // Create questions table
    await db.execute('''
      CREATE TABLE $_questionsTable (
        id TEXT PRIMARY KEY,
        examId TEXT NOT NULL,
        question TEXT NOT NULL,
        options TEXT NOT NULL, -- JSON string
        correctAnswer TEXT NOT NULL,
        explanation TEXT,
        difficulty TEXT,
        points INTEGER,
        imageUrl TEXT,
        questionImgUrl TEXT,
        lastUpdated TEXT,
        FOREIGN KEY (examId) REFERENCES $_examsTable (id)
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
        answers TEXT NOT NULL, -- JSON string
        passed INTEGER NOT NULL, -- 0 or 1
        completedAt TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0 -- 0 or 1
      )
    ''');

    // Create sync status table
    await db.execute('''
      CREATE TABLE $_syncStatusTable (
        id INTEGER PRIMARY KEY,
        lastSyncAt TEXT,
        totalExams INTEGER DEFAULT 0,
        totalQuestions INTEGER DEFAULT 0
      )
    ''');
  }

  // Save offline exam data
  Future<void> saveOfflineExam(OfflineExam exam) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Save exam
      await txn.insert(
        _examsTable,
        {
          'id': exam.id,
          'title': exam.title,
          'description': exam.description,
          'category': exam.category,
          'difficulty': exam.difficulty,
          'duration': exam.duration,
          'questionCount': exam.questionCount,
          'passingScore': exam.passingScore,
          'examImgUrl': exam.examImgUrl,
          'lastUpdated': exam.lastUpdated.toIso8601String(),
          'downloadedAt': exam.downloadedAt.toIso8601String(),
          'version': exam.version,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save questions
      for (final question in exam.questions) {
        await txn.insert(
          _questionsTable,
          {
            'id': question.id,
            'examId': question.examId,
            'question': question.question,
            'options': jsonEncode(question.options),
            'correctAnswer': question.correctAnswer,
            'explanation': question.explanation,
            'difficulty': question.difficulty,
            'points': question.points,
            'imageUrl': question.imageUrl,
            'questionImgUrl': question.questionImgUrl,
            'lastUpdated': question.lastUpdated.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // Get offline exam by ID
  Future<OfflineExam?> getOfflineExam(String examId) async {
    final db = await database;
    
    final examMap = await db.query(
      _examsTable,
      where: 'id = ?',
      whereArgs: [examId],
    );

    if (examMap.isEmpty) return null;

    final exam = examMap.first;
    
    // Get questions for this exam
    final questionsMaps = await db.query(
      _questionsTable,
      where: 'examId = ?',
      whereArgs: [examId],
    );

    final questions = questionsMaps.map((q) => OfflineQuestion(
      id: q['id'] as String,
      examId: q['examId'] as String,
      question: q['question'] as String,
      options: List<String>.from(jsonDecode(q['options'] as String)),
      correctAnswer: q['correctAnswer'] as String,
      explanation: q['explanation'] as String?,
      difficulty: q['difficulty'] as String,
      points: q['points'] as int,
      imageUrl: q['imageUrl'] as String?,
      questionImgUrl: q['questionImgUrl'] as String?,
      lastUpdated: DateTime.parse(q['lastUpdated'] as String),
    )).toList();

    return OfflineExam(
      id: exam['id'] as String,
      title: exam['title'] as String,
      description: exam['description'] as String,
      category: exam['category'] as String,
      difficulty: exam['difficulty'] as String,
      duration: exam['duration'] as int,
      questionCount: exam['questionCount'] as int,
      passingScore: exam['passingScore'] as int,
      examImgUrl: exam['examImgUrl'] as String?,
      lastUpdated: DateTime.parse(exam['lastUpdated'] as String),
      questions: questions,
      downloadedAt: DateTime.parse(exam['downloadedAt'] as String),
      version: exam['version'] as int,
    );
  }

  // Get all offline exams
  Future<List<OfflineExam>> getAllOfflineExams() async {
    final db = await database;
    final examMaps = await db.query(_examsTable);
    
    List<OfflineExam> exams = [];
    
    for (final examMap in examMaps) {
      final exam = await getOfflineExam(examMap['id'] as String);
      if (exam != null) {
        exams.add(exam);
      }
    }
    
    return exams;
  }

  // Save exam result
  Future<void> saveExamResult(OfflineExamResult result) async {
    final db = await database;
    
    await db.insert(
      _resultsTable,
      {
        'examId': result.examId,
        'score': result.score,
        'totalQuestions': result.totalQuestions,
        'correctAnswers': result.correctAnswers,
        'timeSpent': result.timeSpent,
        'answers': jsonEncode(result.answers),
        'passed': result.passed ? 1 : 0,
        'completedAt': result.completedAt.toIso8601String(),
        'synced': result.synced ? 1 : 0,
      },
    );
  }

  // Get unsynced results
  Future<List<OfflineExamResult>> getUnsyncedResults() async {
    final db = await database;
    final resultMaps = await db.query(
      _resultsTable,
      where: 'synced = ?',
      whereArgs: [0],
    );

    return resultMaps.map((r) => OfflineExamResult(
      examId: r['examId'] as String,
      score: r['score'] as double,
      totalQuestions: r['totalQuestions'] as int,
      correctAnswers: r['correctAnswers'] as int,
      timeSpent: r['timeSpent'] as int,
      answers: Map<String, String>.from(jsonDecode(r['answers'] as String)),
      passed: r['passed'] == 1,
      completedAt: DateTime.parse(r['completedAt'] as String),
      synced: r['synced'] == 1,
    )).toList();
  }

  // Mark results as synced
  Future<void> markResultsAsSynced(List<int> resultIds) async {
    final db = await database;
    
    for (final id in resultIds) {
      await db.update(
        _resultsTable,
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // Update sync status
  Future<void> updateSyncStatus(DateTime lastSyncAt, int totalExams, int totalQuestions) async {
    final db = await database;
    
    await db.insert(
      _syncStatusTable,
      {
        'id': 1,
        'lastSyncAt': lastSyncAt.toIso8601String(),
        'totalExams': totalExams,
        'totalQuestions': totalQuestions,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get sync status
  Future<Map<String, dynamic>?> getSyncStatus() async {
    final db = await database;
    final statusMap = await db.query(
      _syncStatusTable,
      where: 'id = ?',
      whereArgs: [1],
    );

    if (statusMap.isEmpty) return null;

    return {
      'lastSyncAt': statusMap.first['lastSyncAt'] as String?,
      'totalExams': statusMap.first['totalExams'] as int,
      'totalQuestions': statusMap.first['totalQuestions'] as int,
    };
  }
}
```

## 🌐 API Service

```dart
// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/offline_exam.dart';
import '../models/offline_exam_result.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Download single exam
  Future<OfflineExam> downloadExam(String examId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/offline/download/exam/$examId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      return OfflineExam.fromJson(data);
    } else {
      throw Exception('Failed to download exam: ${response.body}');
    }
  }

  // Download all exams
  Future<List<OfflineExam>> downloadAllExams() async {
    final response = await http.get(
      Uri.parse('$baseUrl/offline/download/all'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      return (data['exams'] as List)
          .map((exam) => OfflineExam.fromJson(exam))
          .toList();
    } else {
      throw Exception('Failed to download exams: ${response.body}');
    }
  }

  // Check for updates
  Future<Map<String, dynamic>> checkForUpdates(DateTime lastSyncTime) async {
    final response = await http.post(
      Uri.parse('$baseUrl/offline/check-updates'),
      headers: _headers,
      body: jsonEncode({
        'lastSyncTime': lastSyncTime.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to check updates: ${response.body}');
    }
  }

  // Sync exam results
  Future<void> syncExamResults(List<OfflineExamResult> results) async {
    final response = await http.post(
      Uri.parse('$baseUrl/offline/sync-results'),
      headers: _headers,
      body: jsonEncode({
        'results': results.map((r) => r.toJson()).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sync results: ${response.body}');
    }
  }

  // Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/offline/sync-status'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to get sync status: ${response.body}');
    }
  }
}
```

## 🔄 Offline Manager

```dart
// lib/services/offline_manager.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';
import 'local_database_service.dart';
import '../models/offline_exam.dart';
import '../models/offline_exam_result.dart';

class OfflineManager {
  final ApiService _apiService = ApiService();
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final Connectivity _connectivity = Connectivity();
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;

  // Initialize offline manager
  void initialize() {
    _startConnectivityListener();
    _startPeriodicSync();
  }

  // Start listening to connectivity changes
  void _startConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        // Internet is available, sync data
        _syncWhenOnline();
      }
    });
  }

  // Start periodic sync (every 5 minutes when online)
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _checkConnectivityAndSync();
    });
  }

  // Check connectivity and sync if online
  Future<void> _checkConnectivityAndSync() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      await _syncWhenOnline();
    }
  }

  // Sync when online
  Future<void> _syncWhenOnline() async {
    try {
      // Sync exam results first
      await _syncExamResults();
      
      // Check for updates
      await _checkForUpdates();
    } catch (e) {
      print('Sync error: $e');
    }
  }

  // Download exam for offline use
  Future<void> downloadExam(String examId) async {
    try {
      final exam = await _apiService.downloadExam(examId);
      await _localDb.saveOfflineExam(exam);
      print('Exam downloaded: ${exam.title}');
    } catch (e) {
      print('Download error: $e');
      rethrow;
    }
  }

  // Download all exams
  Future<void> downloadAllExams() async {
    try {
      final exams = await _apiService.downloadAllExams();
      
      for (final exam in exams) {
        await _localDb.saveOfflineExam(exam);
      }
      
      print('Downloaded ${exams.length} exams');
    } catch (e) {
      print('Download all error: $e');
      rethrow;
    }
  }

  // Get offline exam
  Future<OfflineExam?> getOfflineExam(String examId) async {
    return await _localDb.getOfflineExam(examId);
  }

  // Get all offline exams
  Future<List<OfflineExam>> getAllOfflineExams() async {
    return await _localDb.getAllOfflineExams();
  }

  // Save exam result locally
  Future<void> saveExamResult(OfflineExamResult result) async {
    await _localDb.saveExamResult(result);
  }

  // Sync exam results to server
  Future<void> _syncExamResults() async {
    try {
      final unsyncedResults = await _localDb.getUnsyncedResults();
      
      if (unsyncedResults.isNotEmpty) {
        await _apiService.syncExamResults(unsyncedResults);
        
        // Mark as synced
        final resultIds = List.generate(unsyncedResults.length, (index) => index + 1);
        await _localDb.markResultsAsSynced(resultIds);
        
        print('Synced ${unsyncedResults.length} exam results');
      }
    } catch (e) {
      print('Sync results error: $e');
    }
  }

  // Check for updates
  Future<void> _checkForUpdates() async {
    try {
      final syncStatus = await _localDb.getSyncStatus();
      if (syncStatus == null) return;

      final lastSyncTime = DateTime.parse(syncStatus['lastSyncAt']!);
      final updateInfo = await _apiService.checkForUpdates(lastSyncTime);

      if (updateInfo['hasUpdates'] == true) {
        print('Updates available: ${updateInfo['updatedExams']} exams, ${updateInfo['updatedQuestions']} questions');
        
        // Download updated data
        await downloadAllExams();
        
        // Update sync status
        await _localDb.updateSyncStatus(
          DateTime.now(),
          updateInfo['totalExams'] ?? 0,
          updateInfo['totalQuestions'] ?? 0,
        );
      }
    } catch (e) {
      print('Check updates error: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }
}
```

## 🎯 Usage Example

```dart
// lib/screens/exam_screen.dart
import 'package:flutter/material.dart';
import '../services/offline_manager.dart';
import '../models/offline_exam.dart';

class ExamScreen extends StatefulWidget {
  final String examId;

  const ExamScreen({Key? key, required this.examId}) : super(key: key);

  @override
  _ExamScreenState createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final OfflineManager _offlineManager = OfflineManager();
  OfflineExam? _exam;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  Future<void> _loadExam() async {
    try {
      setState(() => _isLoading = true);
      
      // Try to get offline exam first
      _exam = await _offlineManager.getOfflineExam(widget.examId);
      
      if (_exam == null) {
        // Download if not available offline
        await _offlineManager.downloadExam(widget.examId);
        _exam = await _offlineManager.getOfflineExam(widget.examId);
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading exam: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_exam == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(child: Text('Exam not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_exam!.title)),
      body: Column(
        children: [
          // Exam info
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_exam!.title, style: Theme.of(context).textTheme.headlineSmall),
                  SizedBox(height: 8),
                  Text(_exam!.description),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(label: Text(_exam!.difficulty)),
                      SizedBox(width: 8),
                      Chip(label: Text('${_exam!.duration} min')),
                      SizedBox(width: 8),
                      Chip(label: Text('${_exam!.questions.length} questions')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Questions list
          Expanded(
            child: ListView.builder(
              itemCount: _exam!.questions.length,
              itemBuilder: (context, index) {
                final question = _exam!.questions[index];
                return Card(
                  child: ListTile(
                    title: Text(question.question),
                    subtitle: Text('${question.options.length} options'),
                    trailing: Icon(Icons.quiz),
                    onTap: () {
                      // Navigate to question screen
                      _navigateToQuestion(question);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToQuestion(OfflineQuestion question) {
    // Navigate to question screen
    // Implement question taking logic here
  }
}
```

## 🚀 Key Features Implemented

### ✅ **Backend Features:**
- **Download Exam Data**: Get complete exam with questions for offline use
- **Download All Exams**: Bulk download all available exams
- **Check for Updates**: Detect new/updated content since last sync
- **Sync Results**: Upload offline exam results when online
- **Access Control**: Only users with valid access codes can download
- **Version Control**: Track data versions for updates

### ✅ **Flutter Features:**
- **Local Storage**: SQLite database for offline data
- **Connectivity Detection**: Auto-sync when internet available
- **Periodic Sync**: Background sync every 5 minutes
- **Offline Exams**: Take exams without internet
- **Result Sync**: Upload results when online
- **Update Detection**: Download new content automatically

### 🔄 **Workflow:**
1. **User pays** → Gets access code
2. **Downloads exams** → Stores locally on device
3. **Takes exams offline** → No internet required
4. **Auto-syncs results** → When internet available
5. **Auto-updates content** → New questions/exams when available

This implementation provides a complete offline exam system with automatic synchronization! 🎉
