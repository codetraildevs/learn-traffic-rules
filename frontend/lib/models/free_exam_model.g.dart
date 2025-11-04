// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'free_exam_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

// FreeExamResponse _$FreeExamResponseFromJson(Map<String, dynamic> json) =>
//     FreeExamResponse(
//       success: json['success'] as bool,
//       message: json['message'] as String,
//       data: FreeExamData.fromJson(json['data'] as Map<String, dynamic>),
//     );

Map<String, dynamic> _$FreeExamResponseToJson(FreeExamResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

// FreeExamData _$FreeExamDataFromJson(Map<String, dynamic> json) => FreeExamData(
//   exams: (json['exams'] as List<dynamic>)
//       .map((e) => Exam.fromJson(e as Map<String, dynamic>))
//       .toList(),
//   isFreeUser: json['isFreeUser'] as bool,
//   freeExamsRemaining: (json['freeExamsRemaining'] as num).toInt(),
//   paymentInstructions: json['paymentInstructions'] == null
//       ? null
//       : PaymentInstructions.fromJson(
//           json['paymentInstructions'] as Map<String, dynamic>,
//         ),
// );

Map<String, dynamic> _$FreeExamDataToJson(FreeExamData instance) =>
    <String, dynamic>{
      'exams': instance.exams,
      'isFreeUser': instance.isFreeUser,
      'freeExamsRemaining': instance.freeExamsRemaining,
      'paymentInstructions': instance.paymentInstructions,
    };

PaymentInstructions _$PaymentInstructionsFromJson(Map<String, dynamic> json) =>
    PaymentInstructions(
      title: json['title'] as String,
      description: json['description'] as String,
      steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
      contactInfo: ContactInfo.fromJson(
        json['contactInfo'] as Map<String, dynamic>,
      ),
      paymentTiers: (json['paymentTiers'] as List<dynamic>)
          .map((e) => PaymentTier.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PaymentInstructionsToJson(
  PaymentInstructions instance,
) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
  'steps': instance.steps,
  'contactInfo': instance.contactInfo,
  'paymentTiers': instance.paymentTiers,
};

// ContactInfo _$ContactInfoFromJson(Map<String, dynamic> json) => ContactInfo(
//   phone: json['phone'] as String,
//   whatsapp: json['whatsapp'] as String,
//   email: json['email'] as String?,
//   workingHours: json['workingHours'] as String?,
// );

Map<String, dynamic> _$ContactInfoToJson(ContactInfo instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'whatsapp': instance.whatsapp,
      'email': instance.email,
      'workingHours': instance.workingHours,
    };

// PaymentTier _$PaymentTierFromJson(Map<String, dynamic> json) => PaymentTier(
//   amount: (json['amount'] as num).toInt(),
//   days: (json['days'] as num).toInt(),
//   description: json['description'] as String,
//   features: (json['features'] as List<dynamic>?)
//       ?.map((e) => e as String)
//       .toList(),
// );

Map<String, dynamic> _$PaymentTierToJson(PaymentTier instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'days': instance.days,
      'description': instance.description,
      'features': instance.features,
    };

SubmitFreeExamRequest _$SubmitFreeExamRequestFromJson(
  Map<String, dynamic> json,
) => SubmitFreeExamRequest(
  examId: json['examId'] as String,
  answers: Map<String, String>.from(json['answers'] as Map),
  timeSpent: (json['timeSpent'] as num?)?.toInt(),
);

Map<String, dynamic> _$SubmitFreeExamRequestToJson(
  SubmitFreeExamRequest instance,
) => <String, dynamic>{
  'examId': instance.examId,
  'answers': instance.answers,
  'timeSpent': instance.timeSpent,
};

SubmitFreeExamResponse _$SubmitFreeExamResponseFromJson(
  Map<String, dynamic> json,
) => SubmitFreeExamResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: SubmitFreeExamData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SubmitFreeExamResponseToJson(
  SubmitFreeExamResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

SubmitFreeExamData _$SubmitFreeExamDataFromJson(Map<String, dynamic> json) =>
    SubmitFreeExamData(
      examResult: FreeExamResult.fromJson(
        json['examResult'] as Map<String, dynamic>,
      ),
      freeExamsRemaining: (json['freeExamsRemaining'] as num).toInt(),
    );

Map<String, dynamic> _$SubmitFreeExamDataToJson(SubmitFreeExamData instance) =>
    <String, dynamic>{
      'examResult': instance.examResult,
      'freeExamsRemaining': instance.freeExamsRemaining,
    };

FreeExamResult _$FreeExamResultFromJson(Map<String, dynamic> json) =>
    FreeExamResult(
      id: json['id'] as String,
      score: (json['score'] as num).toInt(),
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      correctAnswers: (json['correctAnswers'] as num).toInt(),
      passed: json['passed'] as bool,
      isFreeExam: json['isFreeExam'] as bool,
    );

Map<String, dynamic> _$FreeExamResultToJson(FreeExamResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'score': instance.score,
      'totalQuestions': instance.totalQuestions,
      'correctAnswers': instance.correctAnswers,
      'passed': instance.passed,
      'isFreeExam': instance.isFreeExam,
    };

PaymentInstructionsResponse _$PaymentInstructionsResponseFromJson(
  Map<String, dynamic> json,
) => PaymentInstructionsResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: PaymentInstructionsData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PaymentInstructionsResponseToJson(
  PaymentInstructionsResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

// PaymentInstructionsData _$PaymentInstructionsDataFromJson(
//   Map<String, dynamic> json,
// ) => PaymentInstructionsData(
//   title: json['title'] as String,
//   description: json['description'] as String,
//   steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
//   contactInfo: ContactInfo.fromJson(
//     json['contactInfo'] as Map<String, dynamic>,
//   ),
//   paymentMethods: (json['paymentMethods'] as List<dynamic>)
//       .map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
//       .toList(),
//   paymentTiers: (json['paymentTiers'] as List<dynamic>)
//       .map((e) => PaymentTier.fromJson(e as Map<String, dynamic>))
//       .toList(),
// );

Map<String, dynamic> _$PaymentInstructionsDataToJson(
  PaymentInstructionsData instance,
) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
  'steps': instance.steps,
  'contactInfo': instance.contactInfo,
  'paymentMethods': instance.paymentMethods,
  'paymentTiers': instance.paymentTiers,
};

// PaymentMethod _$PaymentMethodFromJson(Map<String, dynamic> json) =>
//     PaymentMethod(
//       name: json['name'] as String,
//       details: json['details'] as String,
//       instructions: json['instructions'] as String,
//     );

Map<String, dynamic> _$PaymentMethodToJson(PaymentMethod instance) =>
    <String, dynamic>{
      'name': instance.name,
      'details': instance.details,
      'instructions': instance.instructions,
    };
