// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Exam _$ExamFromJson(Map<String, dynamic> json) => Exam(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  category: json['category'] as String?,
  difficulty: json['difficulty'] as String,
  duration: (json['duration'] as num).toInt(),
  passingScore: (json['passingScore'] as num).toInt(),
  isActive: json['isActive'] as bool,
  examImgUrl: json['examImgUrl'] as String?,
  questionCount: (json['questionCount'] as num?)?.toInt(),
  isFirstTwo: json['isFirstTwo'] as bool?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ExamToJson(Exam instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'category': instance.category,
  'difficulty': instance.difficulty,
  'duration': instance.duration,
  'passingScore': instance.passingScore,
  'isActive': instance.isActive,
  'examImgUrl': instance.examImgUrl,
  'questionCount': instance.questionCount,
  'isFirstTwo': instance.isFirstTwo,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

CreateExamRequest _$CreateExamRequestFromJson(Map<String, dynamic> json) =>
    CreateExamRequest(
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String,
      duration: (json['duration'] as num).toInt(),
      passingScore: (json['passingScore'] as num).toInt(),
      isActive: json['isActive'] as bool,
      examImgUrl: json['examImgUrl'] as String?,
    );

Map<String, dynamic> _$CreateExamRequestToJson(CreateExamRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'difficulty': instance.difficulty,
      'duration': instance.duration,
      'passingScore': instance.passingScore,
      'isActive': instance.isActive,
      'examImgUrl': instance.examImgUrl,
    };

UpdateExamRequest _$UpdateExamRequestFromJson(Map<String, dynamic> json) =>
    UpdateExamRequest(
      title: json['title'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      passingScore: (json['passingScore'] as num?)?.toInt(),
      isActive: json['isActive'] as bool?,
      examImgUrl: json['examImgUrl'] as String?,
    );

Map<String, dynamic> _$UpdateExamRequestToJson(UpdateExamRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'difficulty': instance.difficulty,
      'duration': instance.duration,
      'passingScore': instance.passingScore,
      'isActive': instance.isActive,
      'examImgUrl': instance.examImgUrl,
    };

ExamResponse _$ExamResponseFromJson(Map<String, dynamic> json) => ExamResponse(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : Exam.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ExamResponseToJson(ExamResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

ExamListResponse _$ExamListResponseFromJson(Map<String, dynamic> json) =>
    ExamListResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Exam.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ExamListResponseToJson(ExamListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

ExamSubmission _$ExamSubmissionFromJson(Map<String, dynamic> json) =>
    ExamSubmission(
      examId: json['examId'] as String,
      answers: (json['answers'] as List<dynamic>)
          .map((e) => QuestionAnswer.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeSpent: (json['timeSpent'] as num).toInt(),
    );

Map<String, dynamic> _$ExamSubmissionToJson(ExamSubmission instance) =>
    <String, dynamic>{
      'examId': instance.examId,
      'answers': instance.answers,
      'timeSpent': instance.timeSpent,
    };

Question _$QuestionFromJson(Map<String, dynamic> json) => Question(
  id: json['id'] as String,
  examId: json['examId'] as String,
  question: json['question'] as String,
  option1: json['option1'] as String,
  option2: json['option2'] as String,
  option3: json['option3'] as String,
  option4: json['option4'] as String,
  correctAnswer: json['correctAnswer'] as String,
  points: (json['points'] as num).toInt(),
  questionImgUrl: json['questionImgUrl'] as String?,
);

Map<String, dynamic> _$QuestionToJson(Question instance) => <String, dynamic>{
  'id': instance.id,
  'examId': instance.examId,
  'question': instance.question,
  'option1': instance.option1,
  'option2': instance.option2,
  'option3': instance.option3,
  'option4': instance.option4,
  'correctAnswer': instance.correctAnswer,
  'points': instance.points,
  'questionImgUrl': instance.questionImgUrl,
};

CreateQuestionRequest _$CreateQuestionRequestFromJson(
  Map<String, dynamic> json,
) => CreateQuestionRequest(
  question: json['question'] as String,
  option1: json['option1'] as String,
  option2: json['option2'] as String,
  option3: json['option3'] as String,
  option4: json['option4'] as String,
  correctAnswer: json['correctAnswer'] as String,
  questionImgUrl: json['questionImgUrl'] as String?,
  points: (json['points'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$CreateQuestionRequestToJson(
  CreateQuestionRequest instance,
) => <String, dynamic>{
  'question': instance.question,
  'option1': instance.option1,
  'option2': instance.option2,
  'option3': instance.option3,
  'option4': instance.option4,
  'correctAnswer': instance.correctAnswer,
  'questionImgUrl': instance.questionImgUrl,
  'points': instance.points,
};

QuestionAnswer _$QuestionAnswerFromJson(Map<String, dynamic> json) =>
    QuestionAnswer(
      questionId: json['questionId'] as String,
      selectedAnswer: json['selectedAnswer'] as String,
      isCorrect: json['isCorrect'] as bool,
    );

Map<String, dynamic> _$QuestionAnswerToJson(QuestionAnswer instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'selectedAnswer': instance.selectedAnswer,
      'isCorrect': instance.isCorrect,
    };

ExamResult _$ExamResultFromJson(Map<String, dynamic> json) => ExamResult(
  id: json['id'] as String,
  examId: json['examId'] as String,
  userId: json['userId'] as String,
  score: (json['score'] as num).toInt(),
  totalQuestions: (json['totalQuestions'] as num).toInt(),
  correctAnswers: (json['correctAnswers'] as num).toInt(),
  timeSpent: (json['timeSpent'] as num).toInt(),
  passed: json['passed'] as bool,
  completedAt: DateTime.parse(json['completedAt'] as String),
);

Map<String, dynamic> _$ExamResultToJson(ExamResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'examId': instance.examId,
      'userId': instance.userId,
      'score': instance.score,
      'totalQuestions': instance.totalQuestions,
      'correctAnswers': instance.correctAnswers,
      'timeSpent': instance.timeSpent,
      'passed': instance.passed,
      'completedAt': instance.completedAt.toIso8601String(),
    };
