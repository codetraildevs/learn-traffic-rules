import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'access_code_model.dart';

part 'user_management_model.g.dart';

@JsonSerializable()
class UserWithStats {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String role;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AccessCodeStats accessCodeStats;
  final int remainingDays;
  final DateTime? expiresAt;
  final bool? isBlocked;
  final String? blockReason;
  final DateTime? blockedAt;

  const UserWithStats({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.role,
    required this.isActive,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
    required this.accessCodeStats,
    this.remainingDays = 0,
    this.expiresAt,
    this.isBlocked,
    this.blockReason,
    this.blockedAt,
  });

  factory UserWithStats.fromJson(Map<String, dynamic> json) {
    try {
      return UserWithStats(
        id: json['id']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
        phoneNumber: json['phoneNumber']?.toString() ?? '',
        email: json['email']?.toString(),
        role: json['role']?.toString() ?? 'USER',
        isActive: json['isActive'] ?? true,
        lastLogin: json['lastLogin'] != null
            ? DateTime.tryParse(json['lastLogin'].toString())
            : null,
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
        accessCodeStats: json['accessCodeStats'] != null
            ? AccessCodeStats.fromJson(
                json['accessCodeStats'] as Map<String, dynamic>,
              )
            : const AccessCodeStats(),
        remainingDays: (json['remainingDays'] as num?)?.toInt() ?? 0,
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'].toString())
            : null,
        isBlocked: () {
          final rawValue = json['isBlocked'];
          // Database: 0 = blocked (true), 1 = unblocked (false)
          // Frontend: true = blocked, false = unblocked
          final boolValue = rawValue == 0;
          debugPrint(
            '🔍 Parsing isBlocked: raw=$rawValue, parsed=$boolValue (0=blocked, 1=unblocked)',
          );
          return boolValue;
        }(),
        blockReason: json['blockReason']?.toString(),
        blockedAt: json['blockedAt'] != null
            ? DateTime.tryParse(json['blockedAt'].toString())
            : null,
      );
    } catch (e) {
      debugPrint('❌ Error parsing UserWithStats: $e');
      debugPrint('❌ JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => _$UserWithStatsToJson(this);

  String get displayName => fullName;
  String get roleDisplayName {
    switch (role) {
      case 'ADMIN':
        return 'Administrator';
      case 'MANAGER':
        return 'Manager';
      case 'USER':
        return 'User';
      default:
        return role;
    }
  }
}

@JsonSerializable()
class AccessCodeStats {
  final int total;
  final int active;
  final int used;
  final int expired;
  final AccessCode? latestCode;

  const AccessCodeStats({
    this.total = 0,
    this.active = 0,
    this.used = 0,
    this.expired = 0,
    this.latestCode,
  });

  factory AccessCodeStats.fromJson(Map<String, dynamic> json) {
    try {
      return AccessCodeStats(
        total: (json['total'] as num?)?.toInt() ?? 0,
        active: (json['active'] as num?)?.toInt() ?? 0,
        used: (json['used'] as num?)?.toInt() ?? 0,
        expired: (json['expired'] as num?)?.toInt() ?? 0,
        latestCode: json['latestCode'] != null
            ? AccessCode.fromJson(json['latestCode'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      debugPrint('❌ Error parsing AccessCodeStats: $e');
      debugPrint('❌ JSON data: $json');
      return const AccessCodeStats();
    }
  }
  Map<String, dynamic> toJson() => _$AccessCodeStatsToJson(this);

  String get statusSummary {
    if (total == 0) return 'No access codes';
    if (active > 0) return '$active active';
    if (used > 0) return '$used used';
    return '$expired expired';
  }
}

@JsonSerializable()
class UserListResponse {
  final bool success;
  final String message;
  final UserListData data;

  const UserListResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory UserListResponse.fromJson(Map<String, dynamic> json) {
    try {
      return UserListResponse(
        success: json['success'] ?? false,
        message: json['message']?.toString() ?? '',
        data: json['data'] != null
            ? UserListData.fromJson(json['data'] as Map<String, dynamic>)
            : const UserListData(users: [], pagination: UserPagination()),
      );
    } catch (e) {
      debugPrint('❌ Error parsing UserListResponse: $e');
      debugPrint('❌ JSON data: $json');
      rethrow;
    }
  }
  Map<String, dynamic> toJson() => _$UserListResponseToJson(this);
}

@JsonSerializable()
class UserListData {
  final List<UserWithStats> users;
  final UserPagination pagination;

  const UserListData({required this.users, required this.pagination});

  factory UserListData.fromJson(Map<String, dynamic> json) {
    try {
      final usersList = json['users'] as List<dynamic>? ?? [];
      final users = usersList
          .map((e) {
            try {
              return UserWithStats.fromJson(e as Map<String, dynamic>);
            } catch (e) {
              debugPrint('❌ Error parsing user: $e');
              debugPrint('❌ User data: $e');
              return null;
            }
          })
          .where((user) => user != null)
          .cast<UserWithStats>()
          .toList();

      return UserListData(
        users: users,
        pagination: json['pagination'] != null
            ? UserPagination.fromJson(
                json['pagination'] as Map<String, dynamic>,
              )
            : const UserPagination(),
      );
    } catch (e) {
      debugPrint('❌ Error parsing UserListData: $e');
      debugPrint('❌ JSON data: $json');
      rethrow;
    }
  }
  Map<String, dynamic> toJson() => _$UserListDataToJson(this);
}

@JsonSerializable()
class UserPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const UserPagination({
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 1,
  });

  factory UserPagination.fromJson(Map<String, dynamic> json) {
    try {
      return UserPagination(
        total: (json['total'] as num?)?.toInt() ?? 0,
        page: (json['page'] as num?)?.toInt() ?? 1,
        limit: (json['limit'] as num?)?.toInt() ?? 20,
        totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      );
    } catch (e) {
      debugPrint('❌ Error parsing UserPagination: $e');
      debugPrint('❌ JSON data: $json');
      return const UserPagination();
    }
  }
  Map<String, dynamic> toJson() => _$UserPaginationToJson(this);
}

@JsonSerializable()
class UserDetailsResponse {
  final bool success;
  final String message;
  final UserWithStats data;

  const UserDetailsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory UserDetailsResponse.fromJson(Map<String, dynamic> json) =>
      _$UserDetailsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserDetailsResponseToJson(this);
}

@JsonSerializable()
class CreateAccessCodeForUserRequest {
  final double paymentAmount;

  const CreateAccessCodeForUserRequest({required this.paymentAmount});

  factory CreateAccessCodeForUserRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAccessCodeForUserRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateAccessCodeForUserRequestToJson(this);
}

@JsonSerializable()
class CreateAccessCodeForUserResponse {
  final bool success;
  final String message;
  final CreateAccessCodeForUserData data;

  const CreateAccessCodeForUserResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CreateAccessCodeForUserResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateAccessCodeForUserResponseFromJson(json);
  Map<String, dynamic> toJson() =>
      _$CreateAccessCodeForUserResponseToJson(this);
}

@JsonSerializable()
class CreateAccessCodeForUserData {
  final AccessCode accessCode;
  final UserInfo user;

  const CreateAccessCodeForUserData({
    required this.accessCode,
    required this.user,
  });

  factory CreateAccessCodeForUserData.fromJson(Map<String, dynamic> json) =>
      _$CreateAccessCodeForUserDataFromJson(json);
  Map<String, dynamic> toJson() => _$CreateAccessCodeForUserDataToJson(this);
}

@JsonSerializable()
class UserInfo {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String role;

  const UserInfo({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.role,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}

@JsonSerializable()
class UserAccessCodesResponse {
  final bool success;
  final String message;
  final UserAccessCodesData data;

  const UserAccessCodesResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory UserAccessCodesResponse.fromJson(Map<String, dynamic> json) =>
      _$UserAccessCodesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserAccessCodesResponseToJson(this);
}

@JsonSerializable()
class UserAccessCodesData {
  final List<AccessCode> accessCodes;
  final UserInfo user;
  final UserPagination pagination;

  const UserAccessCodesData({
    required this.accessCodes,
    required this.user,
    required this.pagination,
  });

  factory UserAccessCodesData.fromJson(Map<String, dynamic> json) =>
      _$UserAccessCodesDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserAccessCodesDataToJson(this);
}

@JsonSerializable()
class ToggleUserStatusRequest {
  final bool isActive;

  const ToggleUserStatusRequest({required this.isActive});

  factory ToggleUserStatusRequest.fromJson(Map<String, dynamic> json) =>
      _$ToggleUserStatusRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ToggleUserStatusRequestToJson(this);
}

@JsonSerializable()
class UserStatisticsResponse {
  final bool success;
  final String message;
  final UserStatisticsData data;

  const UserStatisticsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory UserStatisticsResponse.fromJson(Map<String, dynamic> json) =>
      _$UserStatisticsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserStatisticsResponseToJson(this);
}

@JsonSerializable()
class UserStatisticsData {
  final UserStats users;
  final AccessCodeStatsSummary accessCodes;

  const UserStatisticsData({required this.users, required this.accessCodes});

  factory UserStatisticsData.fromJson(Map<String, dynamic> json) =>
      _$UserStatisticsDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserStatisticsDataToJson(this);
}

@JsonSerializable()
class UserStats {
  final int total;
  final int active;
  final int recent;
  final UserRoleStats byRole;

  const UserStats({
    this.total = 0,
    this.active = 0,
    this.recent = 0,
    required this.byRole,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);
  Map<String, dynamic> toJson() => _$UserStatsToJson(this);
}

@JsonSerializable()
class UserRoleStats {
  final int admin;
  final int manager;
  final int regular;

  const UserRoleStats({this.admin = 0, this.manager = 0, this.regular = 0});

  factory UserRoleStats.fromJson(Map<String, dynamic> json) =>
      _$UserRoleStatsFromJson(json);
  Map<String, dynamic> toJson() => _$UserRoleStatsToJson(this);
}

@JsonSerializable()
class AccessCodeStatsSummary {
  final int total;
  final int active;
  final int used;

  const AccessCodeStatsSummary({
    this.total = 0,
    this.active = 0,
    this.used = 0,
  });

  factory AccessCodeStatsSummary.fromJson(Map<String, dynamic> json) =>
      _$AccessCodeStatsSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$AccessCodeStatsSummaryToJson(this);
}

@JsonSerializable()
class RemainingDaysResponse {
  final bool success;
  final String message;
  final RemainingDaysData data;

  const RemainingDaysResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory RemainingDaysResponse.fromJson(Map<String, dynamic> json) {
    try {
      return RemainingDaysResponse(
        success: json['success'] ?? false,
        message: json['message']?.toString() ?? '',
        data: json['data'] != null
            ? RemainingDaysData.fromJson(json['data'] as Map<String, dynamic>)
            : const RemainingDaysData(
                remainingDays: 0,
                hasActiveAccess: false,
                activeCodesCount: 0,
              ),
      );
    } catch (e) {
      debugPrint('❌ Error parsing RemainingDaysResponse: $e');
      debugPrint('❌ JSON data: $json');
      rethrow;
    }
  }
  Map<String, dynamic> toJson() => _$RemainingDaysResponseToJson(this);
}

@JsonSerializable()
class RemainingDaysData {
  final int remainingDays;
  final bool hasActiveAccess;
  final int activeCodesCount;

  const RemainingDaysData({
    required this.remainingDays,
    required this.hasActiveAccess,
    required this.activeCodesCount,
  });

  factory RemainingDaysData.fromJson(Map<String, dynamic> json) {
    try {
      return RemainingDaysData(
        remainingDays: (json['remainingDays'] as num?)?.toInt() ?? 0,
        hasActiveAccess: json['hasActiveAccess'] ?? false,
        activeCodesCount: (json['activeCodesCount'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('❌ Error parsing RemainingDaysData: $e');
      debugPrint('❌ JSON data: $json');
      return const RemainingDaysData(
        remainingDays: 0,
        hasActiveAccess: false,
        activeCodesCount: 0,
      );
    }
  }
  Map<String, dynamic> toJson() => _$RemainingDaysDataToJson(this);
}
