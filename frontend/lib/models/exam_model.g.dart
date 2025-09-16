// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Exam _$ExamFromJson(Map<String, dynamic> json) => Exam(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as String,
      duration: (json['duration'] as num).toInt(),
      questionCount: (json['questionCount'] as num).toInt(),
      passingScore: (json['passingScore'] as num).toInt(),
      examImgUrl: json['examImgUrl'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      questions: (json['questions'] as List<dynamic>?)
          ?.map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ExamToJson(Exam instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'difficulty': instance.difficulty,
      'duration': instance.duration,
      'questionCount': instance.questionCount,
      'passingScore': instance.passingScore,
      'examImgUrl': instance.examImgUrl,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'questions': instance.questions,
    };

ExamResult _$ExamResultFromJson(Map<String, dynamic> json) => ExamResult(
      id: json['id'] as String,
      userId: json['userId'] as String,
      examId: json['examId'] as String,
      score: (json['score'] as num).toDouble(),
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      correctAnswers: (json['correctAnswers'] as num).toInt(),
      timeSpent: (json['timeSpent'] as num).toInt(),
      answers: Map<String, String>.from(json['answers'] as Map),
      passed: json['passed'] as bool,
      completedAt: DateTime.parse(json['completedAt'] as String),
      exam: json['exam'] == null
          ? null
          : Exam.fromJson(json['exam'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ExamResultToJson(ExamResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'examId': instance.examId,
      'score': instance.score,
      'totalQuestions': instance.totalQuestions,
      'correctAnswers': instance.correctAnswers,
      'timeSpent': instance.timeSpent,
      'answers': instance.answers,
      'passed': instance.passed,
      'completedAt': instance.completedAt.toIso8601String(),
      'exam': instance.exam,
    };

ExamSubmission _$ExamSubmissionFromJson(Map<String, dynamic> json) =>
    ExamSubmission(
      examId: json['examId'] as String,
      answers: Map<String, String>.from(json['answers'] as Map),
      timeSpent: (json['timeSpent'] as num).toInt(),
    );

Map<String, dynamic> _$ExamSubmissionToJson(ExamSubmission instance) =>
    <String, dynamic>{
      'examId': instance.examId,
      'answers': instance.answers,
      'timeSpent': instance.timeSpent,
    };

OfflineExamData _$OfflineExamDataFromJson(Map<String, dynamic> json) =>
    OfflineExamData(
      exam: Exam.fromJson(json['exam'] as Map<String, dynamic>),
      questions: (json['questions'] as List<dynamic>)
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList(),
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      version: (json['version'] as num).toInt(),
    );

Map<String, dynamic> _$OfflineExamDataToJson(OfflineExamData instance) =>
    <String, dynamic>{
      'exam': instance.exam,
      'questions': instance.questions,
      'downloadedAt': instance.downloadedAt.toIso8601String(),
      'version': instance.version,
    };

OfflineExamResult _$OfflineExamResultFromJson(Map<String, dynamic> json) =>
    OfflineExamResult(
      examId: json['examId'] as String,
      score: (json['score'] as num).toDouble(),
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      correctAnswers: (json['correctAnswers'] as num).toInt(),
      timeSpent: (json['timeSpent'] as num).toInt(),
      answers: Map<String, String>.from(json['answers'] as Map),
      passed: json['passed'] as bool,
      completedAt: DateTime.parse(json['completedAt'] as String),
      synced: json['synced'] as bool? ?? false,
    );

Map<String, dynamic> _$OfflineExamResultToJson(OfflineExamResult instance) =>
    <String, dynamic>{
      'examId': instance.examId,
      'score': instance.score,
      'totalQuestions': instance.totalQuestions,
      'correctAnswers': instance.correctAnswers,
      'timeSpent': instance.timeSpent,
      'answers': instance.answers,
      'passed': instance.passed,
      'completedAt': instance.completedAt.toIso8601String(),
      'synced': instance.synced,
    };
