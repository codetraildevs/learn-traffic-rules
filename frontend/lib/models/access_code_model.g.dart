// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_code_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccessCodeUser _$AccessCodeUserFromJson(Map<String, dynamic> json) =>
    AccessCodeUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      role: json['role'] as String,
    );

Map<String, dynamic> _$AccessCodeUserToJson(AccessCodeUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'phoneNumber': instance.phoneNumber,
      'role': instance.role,
    };

AccessCode _$AccessCodeFromJson(Map<String, dynamic> json) => AccessCode(
  id: json['id'] as String,
  code: json['code'] as String,
  userId: json['userId'] as String,
  generatedByManagerId: json['generatedByManagerId'] as String?,
  paymentAmount: (json['paymentAmount'] as num).toDouble(),
  durationDays: (json['durationDays'] as num).toInt(),
  paymentTier: json['paymentTier'] as String,
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  isUsed: json['isUsed'] as bool,
  usedAt: json['usedAt'] == null
      ? null
      : DateTime.parse(json['usedAt'] as String),
  attemptCount: (json['attemptCount'] as num).toInt(),
  isBlocked: json['isBlocked'] as bool,
  blockedUntil: json['blockedUntil'] == null
      ? null
      : DateTime.parse(json['blockedUntil'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  user: json['user'] == null
      ? null
      : AccessCodeUser.fromJson(json['user'] as Map<String, dynamic>),
  generatedBy: json['generatedBy'] == null
      ? null
      : AccessCodeUser.fromJson(json['generatedBy'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AccessCodeToJson(AccessCode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'userId': instance.userId,
      'generatedByManagerId': instance.generatedByManagerId,
      'paymentAmount': instance.paymentAmount,
      'durationDays': instance.durationDays,
      'paymentTier': instance.paymentTier,
      'expiresAt': instance.expiresAt.toIso8601String(),
      'isUsed': instance.isUsed,
      'usedAt': instance.usedAt?.toIso8601String(),
      'attemptCount': instance.attemptCount,
      'isBlocked': instance.isBlocked,
      'blockedUntil': instance.blockedUntil?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'user': instance.user,
      'generatedBy': instance.generatedBy,
    };

CreateAccessCodeRequest _$CreateAccessCodeRequestFromJson(
  Map<String, dynamic> json,
) => CreateAccessCodeRequest(
  userId: json['userId'] as String,
  paymentAmount: (json['paymentAmount'] as num).toDouble(),
);

Map<String, dynamic> _$CreateAccessCodeRequestToJson(
  CreateAccessCodeRequest instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'paymentAmount': instance.paymentAmount,
};

ValidateAccessCodeRequest _$ValidateAccessCodeRequestFromJson(
  Map<String, dynamic> json,
) => ValidateAccessCodeRequest(code: json['code'] as String);

Map<String, dynamic> _$ValidateAccessCodeRequestToJson(
  ValidateAccessCodeRequest instance,
) => <String, dynamic>{'code': instance.code};

PaymentTier _$PaymentTierFromJson(Map<String, dynamic> json) => PaymentTier(
  amount: (json['amount'] as num).toDouble(),
  days: (json['days'] as num).toInt(),
);

Map<String, dynamic> _$PaymentTierToJson(PaymentTier instance) =>
    <String, dynamic>{'amount': instance.amount, 'days': instance.days};

AccessCodeResponse _$AccessCodeResponseFromJson(Map<String, dynamic> json) =>
    AccessCodeResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] == null
          ? null
          : AccessCode.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AccessCodeResponseToJson(AccessCodeResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

AccessCodeListResponse _$AccessCodeListResponseFromJson(
  Map<String, dynamic> json,
) => AccessCodeListResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: AccessCodeListData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AccessCodeListResponseToJson(
  AccessCodeListResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

AccessCodeListData _$AccessCodeListDataFromJson(Map<String, dynamic> json) =>
    AccessCodeListData(
      accessCodes: (json['accessCodes'] as List<dynamic>)
          .map((e) => AccessCode.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: AccessCodePagination.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$AccessCodeListDataToJson(AccessCodeListData instance) =>
    <String, dynamic>{
      'accessCodes': instance.accessCodes,
      'pagination': instance.pagination,
    };

AccessCodePagination _$AccessCodePaginationFromJson(
  Map<String, dynamic> json,
) => AccessCodePagination(
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
);

Map<String, dynamic> _$AccessCodePaginationToJson(
  AccessCodePagination instance,
) => <String, dynamic>{
  'total': instance.total,
  'page': instance.page,
  'limit': instance.limit,
  'totalPages': instance.totalPages,
};

PaymentTiersResponse _$PaymentTiersResponseFromJson(
  Map<String, dynamic> json,
) => PaymentTiersResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: (json['data'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, PaymentTier.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$PaymentTiersResponseToJson(
  PaymentTiersResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};
