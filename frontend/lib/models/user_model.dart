import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String role;
  final String deviceId;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime? lastSyncAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.deviceId,
    required this.isActive,
    this.lastLogin,
    this.lastSyncAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? role,
    String? deviceId,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? lastSyncAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      deviceId: deviceId ?? this.deviceId,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAdmin => role == 'ADMIN';
  bool get isManager => role == 'MANAGER';
  bool get isUser => role == 'USER';
}

@JsonSerializable()
class LoginRequest {
  final String password;
  final String deviceId;

  LoginRequest({
    required this.password,
    required this.deviceId,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String password;
  final String fullName;
  final String phoneNumber;
  final String deviceId;
  final String role;

  RegisterRequest({
    required this.password,
    required this.fullName,
    required this.phoneNumber,
    required this.deviceId,
    this.role = 'USER',
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final bool success;
  final String message;
  final AuthData? data;

  AuthResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class AuthData {
  final User user;
  final String token;
  final String refreshToken;

  AuthData({
    required this.user,
    required this.token,
    required this.refreshToken,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) =>
      _$AuthDataFromJson(json);
  Map<String, dynamic> toJson() => _$AuthDataToJson(this);
}

@JsonSerializable()
class ForgotPasswordRequest {
  final String phoneNumber;

  ForgotPasswordRequest({
    required this.phoneNumber,
  });

  factory ForgotPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ForgotPasswordRequestToJson(this);
}

@JsonSerializable()
class ResetPasswordRequest {
  final String phoneNumber;
  final String resetCode;
  final String newPassword;

  ResetPasswordRequest({
    required this.phoneNumber,
    required this.resetCode,
    required this.newPassword,
  });

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ResetPasswordRequestToJson(this);
}

@JsonSerializable()
class DeleteAccountRequest {
  final String password;

  DeleteAccountRequest({
    required this.password,
  });

  factory DeleteAccountRequest.fromJson(Map<String, dynamic> json) =>
      _$DeleteAccountRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DeleteAccountRequestToJson(this);
}
