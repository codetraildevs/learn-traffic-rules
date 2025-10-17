import 'package:json_annotation/json_annotation.dart';
import 'exam_model.dart';

part 'free_exam_model.g.dart';

@JsonSerializable()
class FreeExamResponse {
  final bool success;
  final String message;
  final FreeExamData data;

  const FreeExamResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory FreeExamResponse.fromJson(Map<String, dynamic> json) {
    return FreeExamResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? 'Unknown error',
      data: json['data'] != null
          ? FreeExamData.fromJson(json['data'] as Map<String, dynamic>)
          : const FreeExamData(
              exams: [],
              isFreeUser: true,
              freeExamsRemaining: 0,
            ),
    );
  }
  Map<String, dynamic> toJson() => _$FreeExamResponseToJson(this);
}

@JsonSerializable()
class FreeExamData {
  final List<Exam> exams;
  final bool isFreeUser;
  final int freeExamsRemaining;
  final PaymentInstructions? paymentInstructions;

  const FreeExamData({
    required this.exams,
    required this.isFreeUser,
    required this.freeExamsRemaining,
    this.paymentInstructions,
  });

  factory FreeExamData.fromJson(Map<String, dynamic> json) {
    return FreeExamData(
      exams:
          (json['exams'] as List<dynamic>?)
              ?.map((e) => Exam.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isFreeUser: json['isFreeUser'] as bool? ?? true,
      freeExamsRemaining: (json['freeExamsRemaining'] as num?)?.toInt() ?? 0,
      paymentInstructions: json['paymentInstructions'] != null
          ? PaymentInstructions.fromJson(
              json['paymentInstructions'] as Map<String, dynamic>,
            )
          : null,
    );
  }
  Map<String, dynamic> toJson() => _$FreeExamDataToJson(this);
}

@JsonSerializable()
class PaymentInstructions {
  final String title;
  final String description;
  final List<String> steps;
  final ContactInfo contactInfo;
  final List<PaymentTier> paymentTiers;

  const PaymentInstructions({
    required this.title,
    required this.description,
    required this.steps,
    required this.contactInfo,
    required this.paymentTiers,
  });

  factory PaymentInstructions.fromJson(Map<String, dynamic> json) =>
      _$PaymentInstructionsFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentInstructionsToJson(this);
}

@JsonSerializable()
class ContactInfo {
  final String phone;
  final String whatsapp;
  final String? email;
  final String? workingHours;

  const ContactInfo({
    required this.phone,
    required this.whatsapp,
    this.email,
    this.workingHours,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      phone: json['phone'] as String? ?? '',
      whatsapp: json['whatsapp'] as String? ?? '',
      email: json['email'] as String?,
      workingHours: json['workingHours'] as String?,
    );
  }
  Map<String, dynamic> toJson() => _$ContactInfoToJson(this);
}

@JsonSerializable()
class PaymentTier {
  final int amount;
  final int days;
  final String description;
  final List<String>? features;

  const PaymentTier({
    required this.amount,
    required this.days,
    required this.description,
    this.features,
  });

  factory PaymentTier.fromJson(Map<String, dynamic> json) {
    return PaymentTier(
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      days: (json['days'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
  Map<String, dynamic> toJson() => _$PaymentTierToJson(this);

  String get formattedAmount => '$amount RWF';
  String get durationText {
    if (days == 1) return '1 Day';
    if (days < 7) return '$days Days';
    if (days < 30) {
      return '$days Week';
    }
    return '$days Month';
  }
}

@JsonSerializable()
class SubmitFreeExamRequest {
  final String examId;
  final Map<String, String> answers;
  final int? timeSpent;

  const SubmitFreeExamRequest({
    required this.examId,
    required this.answers,
    this.timeSpent,
  });

  factory SubmitFreeExamRequest.fromJson(Map<String, dynamic> json) =>
      _$SubmitFreeExamRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SubmitFreeExamRequestToJson(this);
}

@JsonSerializable()
class SubmitFreeExamResponse {
  final bool success;
  final String message;
  final SubmitFreeExamData data;

  const SubmitFreeExamResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SubmitFreeExamResponse.fromJson(Map<String, dynamic> json) =>
      _$SubmitFreeExamResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SubmitFreeExamResponseToJson(this);
}

@JsonSerializable()
class SubmitFreeExamData {
  final FreeExamResult examResult;
  final int freeExamsRemaining;

  const SubmitFreeExamData({
    required this.examResult,
    required this.freeExamsRemaining,
  });

  factory SubmitFreeExamData.fromJson(Map<String, dynamic> json) =>
      _$SubmitFreeExamDataFromJson(json);
  Map<String, dynamic> toJson() => _$SubmitFreeExamDataToJson(this);
}

@JsonSerializable()
class FreeExamResult {
  final String id;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final bool passed;
  final bool isFreeExam;

  const FreeExamResult({
    required this.id,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.passed,
    required this.isFreeExam,
  });

  factory FreeExamResult.fromJson(Map<String, dynamic> json) =>
      _$FreeExamResultFromJson(json);
  Map<String, dynamic> toJson() => _$FreeExamResultToJson(this);

  String get scoreText => '$score%';
  String get resultText => passed ? 'Passed' : 'Failed';
}

@JsonSerializable()
class PaymentInstructionsResponse {
  final bool success;
  final String message;
  final PaymentInstructionsData data;

  const PaymentInstructionsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory PaymentInstructionsResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentInstructionsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentInstructionsResponseToJson(this);
}

@JsonSerializable()
class PaymentInstructionsData {
  final String title;
  final String description;
  final List<String> steps;
  final ContactInfo contactInfo;
  final List<PaymentMethod> paymentMethods;
  final List<PaymentTier> paymentTiers;

  const PaymentInstructionsData({
    required this.title,
    required this.description,
    required this.steps,
    required this.contactInfo,
    required this.paymentMethods,
    required this.paymentTiers,
  });

  factory PaymentInstructionsData.fromJson(Map<String, dynamic> json) {
    return PaymentInstructionsData(
      title: json['title'] as String? ?? 'Payment Instructions',
      description:
          json['description'] as String? ??
          'Choose a payment plan and follow these steps:',
      steps:
          (json['steps'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      contactInfo: ContactInfo.fromJson(
        json['contactInfo'] as Map<String, dynamic>,
      ),
      paymentMethods:
          (json['paymentMethods'] as List<dynamic>?)
              ?.map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      paymentTiers:
          (json['paymentTiers'] as List<dynamic>?)
              ?.map((e) => PaymentTier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
  Map<String, dynamic> toJson() => _$PaymentInstructionsDataToJson(this);
}

@JsonSerializable()
class PaymentMethod {
  final String name;
  final String details;
  final String instructions;

  const PaymentMethod({
    required this.name,
    required this.details,
    required this.instructions,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      name: json['name'] as String? ?? '',
      details: json['details'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
    );
  }
  Map<String, dynamic> toJson() => _$PaymentMethodToJson(this);
}
