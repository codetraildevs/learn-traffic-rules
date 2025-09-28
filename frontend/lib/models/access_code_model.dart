import 'package:json_annotation/json_annotation.dart';

part 'access_code_model.g.dart';

@JsonSerializable()
class AccessCodeUser {
  final String id;
  final String fullName;
  final String? phoneNumber;
  final String role;

  const AccessCodeUser({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    required this.role,
  });

  factory AccessCodeUser.fromJson(Map<String, dynamic> json) {
    try {
      return AccessCodeUser(
        id: json['id']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
        phoneNumber: json['phoneNumber']?.toString(),
        role: json['role']?.toString() ?? 'USER',
      );
    } catch (e) {
      print('❌ Error parsing AccessCodeUser: $e');
      print('❌ JSON data: $json');
      return const AccessCodeUser(
        id: '',
        fullName: 'Unknown User',
        role: 'USER',
      );
    }
  }

  Map<String, dynamic> toJson() => _$AccessCodeUserToJson(this);
}

@JsonSerializable()
class AccessCode {
  final String id;
  final String code;
  final String userId;
  final String? generatedByManagerId;
  final double paymentAmount;
  final int durationDays;
  final String paymentTier;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime? usedAt;
  final int attemptCount;
  final bool isBlocked;
  final DateTime? blockedUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  // User information (populated by backend)
  final AccessCodeUser? user;
  final AccessCodeUser? generatedBy;

  const AccessCode({
    required this.id,
    required this.code,
    required this.userId,
    this.generatedByManagerId,
    required this.paymentAmount,
    required this.durationDays,
    required this.paymentTier,
    required this.expiresAt,
    required this.isUsed,
    this.usedAt,
    required this.attemptCount,
    required this.isBlocked,
    this.blockedUntil,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.generatedBy,
  });

  factory AccessCode.fromJson(Map<String, dynamic> json) {
    try {
      return AccessCode(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        generatedByManagerId: json['generatedByManagerId']?.toString(),
        paymentAmount: _parseDouble(json['paymentAmount']),
        durationDays: _parseInt(json['durationDays']),
        paymentTier: json['paymentTier']?.toString() ?? '',
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isUsed: json['isUsed'] ?? false,
        usedAt: json['usedAt'] != null
            ? DateTime.tryParse(json['usedAt'].toString())
            : null,
        attemptCount: _parseInt(json['attemptCount']),
        isBlocked: json['isBlocked'] ?? false,
        blockedUntil: json['blockedUntil'] != null
            ? DateTime.tryParse(json['blockedUntil'].toString())
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        user: json['user'] != null
            ? AccessCodeUser.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        generatedBy: json['generatedBy'] != null
            ? AccessCodeUser.fromJson(
                json['generatedBy'] as Map<String, dynamic>,
              )
            : null,
      );
    } catch (e) {
      print('❌ Error parsing AccessCode: $e');
      print('❌ JSON data: $json');
      // Return a default AccessCode with minimal required fields
      return AccessCode(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        paymentAmount: 0.0,
        durationDays: 0,
        paymentTier: json['paymentTier']?.toString() ?? '',
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isUsed: json['isUsed'] ?? false,
        attemptCount: 0,
        isBlocked: false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: DateTime.now(),
        user: json['user'] != null
            ? AccessCodeUser.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        generatedBy: json['generatedBy'] != null
            ? AccessCodeUser.fromJson(
                json['generatedBy'] as Map<String, dynamic>,
              )
            : null,
      );
    }
  }
  Map<String, dynamic> toJson() => _$AccessCodeToJson(this);

  // Helper methods
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isCurrentlyBlocked =>
      isBlocked &&
      (blockedUntil == null || DateTime.now().isBefore(blockedUntil!));
  bool get canBeUsed => !isUsed && !isExpired && !isCurrentlyBlocked;

  String get statusText {
    if (isUsed) return 'Used';
    if (isExpired) return 'Expired';
    if (isCurrentlyBlocked) return 'Blocked';
    return 'Active';
  }

  String get durationText {
    if (durationDays == 1) return '1 Day';
    if (durationDays < 7) return '$durationDays Days';
    if (durationDays == 7) return '1 Week';
    if (durationDays == 14) return '2 Weeks';
    if (durationDays == 30) return '1 Month';
    if (durationDays == 60) return '2 Months';
    return '$durationDays Days';
  }
}

@JsonSerializable()
class CreateAccessCodeRequest {
  final String userId;
  final double paymentAmount;

  const CreateAccessCodeRequest({
    required this.userId,
    required this.paymentAmount,
  });

  factory CreateAccessCodeRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAccessCodeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateAccessCodeRequestToJson(this);
}

@JsonSerializable()
class ValidateAccessCodeRequest {
  final String code;

  const ValidateAccessCodeRequest({required this.code});

  factory ValidateAccessCodeRequest.fromJson(Map<String, dynamic> json) =>
      _$ValidateAccessCodeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ValidateAccessCodeRequestToJson(this);
}

@JsonSerializable()
class PaymentTier {
  final double amount;
  final int days;

  const PaymentTier({required this.amount, required this.days});

  factory PaymentTier.fromJson(Map<String, dynamic> json) =>
      _$PaymentTierFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentTierToJson(this);

  String get displayName {
    if (days == 1) return '1 Day - ${amount.toInt()} RWF';
    if (days < 7) return '$days Days - ${amount.toInt()} RWF';
    if (days == 7) return '1 Week - ${amount.toInt()} RWF';
    if (days == 14) return '2 Weeks - ${amount.toInt()} RWF';
    if (days == 30) return '1 Month - ${amount.toInt()} RWF';
    if (days == 60) return '2 Months - ${amount.toInt()} RWF';
    return '$days Days - ${amount.toInt()} RWF';
  }
}

@JsonSerializable()
class AccessCodeResponse {
  final bool success;
  final String message;
  final AccessCode? data;

  const AccessCodeResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AccessCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$AccessCodeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AccessCodeResponseToJson(this);
}

@JsonSerializable()
class AccessCodeListResponse {
  final bool success;
  final String message;
  final AccessCodeListData data;

  const AccessCodeListResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AccessCodeListResponse.fromJson(Map<String, dynamic> json) =>
      _$AccessCodeListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AccessCodeListResponseToJson(this);
}

@JsonSerializable()
class AccessCodeListData {
  final List<AccessCode> accessCodes;
  final AccessCodePagination pagination;

  const AccessCodeListData({
    required this.accessCodes,
    required this.pagination,
  });

  factory AccessCodeListData.fromJson(Map<String, dynamic> json) {
    try {
      final accessCodesList = json['accessCodes'] as List<dynamic>? ?? [];
      final accessCodes = accessCodesList
          .map((e) {
            try {
              return AccessCode.fromJson(e as Map<String, dynamic>);
            } catch (e) {
              print('❌ Error parsing access code: $e');
              return null;
            }
          })
          .where((code) => code != null)
          .cast<AccessCode>()
          .toList();

      return AccessCodeListData(
        accessCodes: accessCodes,
        pagination: json['pagination'] != null
            ? AccessCodePagination.fromJson(
                json['pagination'] as Map<String, dynamic>,
              )
            : const AccessCodePagination(
                total: 0,
                page: 1,
                limit: 20,
                totalPages: 1,
              ),
      );
    } catch (e) {
      print('❌ Error parsing AccessCodeListData: $e');
      print('❌ JSON data: $json');
      rethrow;
    }
  }
  Map<String, dynamic> toJson() => _$AccessCodeListDataToJson(this);
}

@JsonSerializable()
class AccessCodePagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const AccessCodePagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory AccessCodePagination.fromJson(Map<String, dynamic> json) {
    try {
      return AccessCodePagination(
        total: (json['total'] as num?)?.toInt() ?? 0,
        page: (json['page'] as num?)?.toInt() ?? 1,
        limit: (json['limit'] as num?)?.toInt() ?? 20,
        totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      );
    } catch (e) {
      print('❌ Error parsing AccessCodePagination: $e');
      print('❌ JSON data: $json');
      return const AccessCodePagination(
        total: 0,
        page: 1,
        limit: 20,
        totalPages: 1,
      );
    }
  }
  Map<String, dynamic> toJson() => _$AccessCodePaginationToJson(this);
}

@JsonSerializable()
class PaymentTiersResponse {
  final bool success;
  final String message;
  final Map<String, PaymentTier> data;

  const PaymentTiersResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory PaymentTiersResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentTiersResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentTiersResponseToJson(this);
}

// Helper methods for parsing numbers from JSON
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
