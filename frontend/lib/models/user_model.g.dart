// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  fullName: json['fullName'] as String,
  phoneNumber: json['phoneNumber'] as String,
  role: json['role'] as String,
  deviceId: json['deviceId'] as String,
  isActive: json['isActive'] as bool?,
  lastLogin: json['lastLogin'] == null
      ? null
      : DateTime.parse(json['lastLogin'] as String),
  lastSyncAt: json['lastSyncAt'] == null
      ? null
      : DateTime.parse(json['lastSyncAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'fullName': instance.fullName,
  'phoneNumber': instance.phoneNumber,
  'role': instance.role,
  'deviceId': instance.deviceId,
  'isActive': instance.isActive,
  'lastLogin': instance.lastLogin?.toIso8601String(),
  'lastSyncAt': instance.lastSyncAt?.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  phoneNumber: json['phoneNumber'] as String,
  deviceId: json['deviceId'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'phoneNumber': instance.phoneNumber,
      'deviceId': instance.deviceId,
    };

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      deviceId: json['deviceId'] as String,
      role: json['role'] as String? ?? 'USER',
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'fullName': instance.fullName,
      'phoneNumber': instance.phoneNumber,
      'deviceId': instance.deviceId,
      'role': instance.role,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  success: json['success'] as bool?,
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : AuthData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

AuthData _$AuthDataFromJson(Map<String, dynamic> json) => AuthData(
  user: User.fromJson(json['user'] as Map<String, dynamic>),
  token: json['token'] as String,
  refreshToken: json['refreshToken'] as String,
  accessPeriod: json['accessPeriod'] == null
      ? null
      : AccessPeriod.fromJson(json['accessPeriod'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthDataToJson(AuthData instance) => <String, dynamic>{
  'user': instance.user,
  'token': instance.token,
  'refreshToken': instance.refreshToken,
  'accessPeriod': instance.accessPeriod,
};

AccessPeriod _$AccessPeriodFromJson(Map<String, dynamic> json) => AccessPeriod(
  hasAccess: json['hasAccess'] as bool,
  remainingDays: (json['remainingDays'] as num).toInt(),
  expiresAt: json['expiresAt'] as String?,
  paymentTier: json['paymentTier'] as String?,
  durationDays: (json['durationDays'] as num?)?.toInt(),
);

Map<String, dynamic> _$AccessPeriodToJson(AccessPeriod instance) =>
    <String, dynamic>{
      'hasAccess': instance.hasAccess,
      'remainingDays': instance.remainingDays,
      'expiresAt': instance.expiresAt,
      'paymentTier': instance.paymentTier,
      'durationDays': instance.durationDays,
    };

ForgotPasswordRequest _$ForgotPasswordRequestFromJson(
  Map<String, dynamic> json,
) => ForgotPasswordRequest(phoneNumber: json['phoneNumber'] as String);

Map<String, dynamic> _$ForgotPasswordRequestToJson(
  ForgotPasswordRequest instance,
) => <String, dynamic>{'phoneNumber': instance.phoneNumber};

ResetPasswordRequest _$ResetPasswordRequestFromJson(
  Map<String, dynamic> json,
) => ResetPasswordRequest(
  phoneNumber: json['phoneNumber'] as String,
  resetCode: json['resetCode'] as String,
  newPassword: json['newPassword'] as String,
);

Map<String, dynamic> _$ResetPasswordRequestToJson(
  ResetPasswordRequest instance,
) => <String, dynamic>{
  'phoneNumber': instance.phoneNumber,
  'resetCode': instance.resetCode,
  'newPassword': instance.newPassword,
};

DeleteAccountRequest _$DeleteAccountRequestFromJson(
  Map<String, dynamic> json,
) => DeleteAccountRequest(password: json['password'] as String);

Map<String, dynamic> _$DeleteAccountRequestToJson(
  DeleteAccountRequest instance,
) => <String, dynamic>{'password': instance.password};
