// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_management_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

// UserWithStats _$UserWithStatsFromJson(Map<String, dynamic> json) =>
//     UserWithStats(
//       id: json['id'] as String,
//       fullName: json['fullName'] as String,
//       phoneNumber: json['phoneNumber'] as String,
//       email: json['email'] as String?,
//       role: json['role'] as String,
//       isActive: json['isActive'] as bool,
//       lastLogin: json['lastLogin'] == null
//           ? null
//           : DateTime.parse(json['lastLogin'] as String),
//       createdAt: DateTime.parse(json['createdAt'] as String),
//       updatedAt: DateTime.parse(json['updatedAt'] as String),
//       accessCodeStats: AccessCodeStats.fromJson(
//         json['accessCodeStats'] as Map<String, dynamic>,
//       ),
//       remainingDays: (json['remainingDays'] as num?)?.toInt() ?? 0,
//       expiresAt: json['expiresAt'] == null
//           ? null
//           : DateTime.parse(json['expiresAt'] as String),
//       isBlocked: json['isBlocked'] as bool?,
//       blockReason: json['blockReason'] as String?,
//       blockedAt: json['blockedAt'] == null
//           ? null
//           : DateTime.parse(json['blockedAt'] as String),
//     );

Map<String, dynamic> _$UserWithStatsToJson(UserWithStats instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'phoneNumber': instance.phoneNumber,
      'email': instance.email,
      'role': instance.role,
      'isActive': instance.isActive,
      'lastLogin': instance.lastLogin?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'accessCodeStats': instance.accessCodeStats,
      'remainingDays': instance.remainingDays,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'isBlocked': instance.isBlocked,
      'blockReason': instance.blockReason,
      'blockedAt': instance.blockedAt?.toIso8601String(),
    };

// AccessCodeStats _$AccessCodeStatsFromJson(Map<String, dynamic> json) =>
//     AccessCodeStats(
//       total: (json['total'] as num?)?.toInt() ?? 0,
//       active: (json['active'] as num?)?.toInt() ?? 0,
//       used: (json['used'] as num?)?.toInt() ?? 0,
//       expired: (json['expired'] as num?)?.toInt() ?? 0,
//       latestCode: json['latestCode'] == null
//           ? null
//           : AccessCode.fromJson(json['latestCode'] as Map<String, dynamic>),
//     );

Map<String, dynamic> _$AccessCodeStatsToJson(AccessCodeStats instance) =>
    <String, dynamic>{
      'total': instance.total,
      'active': instance.active,
      'used': instance.used,
      'expired': instance.expired,
      'latestCode': instance.latestCode,
    };

// UserListResponse _$UserListResponseFromJson(Map<String, dynamic> json) =>
//     UserListResponse(
//       success: json['success'] as bool,
//       message: json['message'] as String,
//       data: UserListData.fromJson(json['data'] as Map<String, dynamic>),
//     );

Map<String, dynamic> _$UserListResponseToJson(UserListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

// UserListData _$UserListDataFromJson(Map<String, dynamic> json) => UserListData(
//   users: (json['users'] as List<dynamic>)
//       .map((e) => UserWithStats.fromJson(e as Map<String, dynamic>))
//       .toList(),
//   pagination: UserPagination.fromJson(
//     json['pagination'] as Map<String, dynamic>,
//   ),
// );

Map<String, dynamic> _$UserListDataToJson(UserListData instance) =>
    <String, dynamic>{
      'users': instance.users,
      'pagination': instance.pagination,
    };

// UserPagination _$UserPaginationFromJson(Map<String, dynamic> json) =>
//     UserPagination(
//       total: (json['total'] as num?)?.toInt() ?? 0,
//       page: (json['page'] as num?)?.toInt() ?? 1,
//       limit: (json['limit'] as num?)?.toInt() ?? 20,
//       totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
//     );

Map<String, dynamic> _$UserPaginationToJson(UserPagination instance) =>
    <String, dynamic>{
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'totalPages': instance.totalPages,
    };

UserDetailsResponse _$UserDetailsResponseFromJson(Map<String, dynamic> json) =>
    UserDetailsResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: UserWithStats.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserDetailsResponseToJson(
  UserDetailsResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

CreateAccessCodeForUserRequest _$CreateAccessCodeForUserRequestFromJson(
  Map<String, dynamic> json,
) => CreateAccessCodeForUserRequest(
  paymentAmount: (json['paymentAmount'] as num).toDouble(),
);

Map<String, dynamic> _$CreateAccessCodeForUserRequestToJson(
  CreateAccessCodeForUserRequest instance,
) => <String, dynamic>{'paymentAmount': instance.paymentAmount};

CreateAccessCodeForUserResponse _$CreateAccessCodeForUserResponseFromJson(
  Map<String, dynamic> json,
) => CreateAccessCodeForUserResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: CreateAccessCodeForUserData.fromJson(
    json['data'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$CreateAccessCodeForUserResponseToJson(
  CreateAccessCodeForUserResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

CreateAccessCodeForUserData _$CreateAccessCodeForUserDataFromJson(
  Map<String, dynamic> json,
) => CreateAccessCodeForUserData(
  accessCode: AccessCode.fromJson(json['accessCode'] as Map<String, dynamic>),
  user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CreateAccessCodeForUserDataToJson(
  CreateAccessCodeForUserData instance,
) => <String, dynamic>{
  'accessCode': instance.accessCode,
  'user': instance.user,
};

UserInfo _$UserInfoFromJson(Map<String, dynamic> json) => UserInfo(
  id: json['id'] as String,
  fullName: json['fullName'] as String,
  phoneNumber: json['phoneNumber'] as String,
  email: json['email'] as String?,
  role: json['role'] as String,
);

Map<String, dynamic> _$UserInfoToJson(UserInfo instance) => <String, dynamic>{
  'id': instance.id,
  'fullName': instance.fullName,
  'phoneNumber': instance.phoneNumber,
  'email': instance.email,
  'role': instance.role,
};

UserAccessCodesResponse _$UserAccessCodesResponseFromJson(
  Map<String, dynamic> json,
) => UserAccessCodesResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: UserAccessCodesData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserAccessCodesResponseToJson(
  UserAccessCodesResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

UserAccessCodesData _$UserAccessCodesDataFromJson(Map<String, dynamic> json) =>
    UserAccessCodesData(
      accessCodes: (json['accessCodes'] as List<dynamic>)
          .map((e) => AccessCode.fromJson(e as Map<String, dynamic>))
          .toList(),
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
      pagination: UserPagination.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$UserAccessCodesDataToJson(
  UserAccessCodesData instance,
) => <String, dynamic>{
  'accessCodes': instance.accessCodes,
  'user': instance.user,
  'pagination': instance.pagination,
};

ToggleUserStatusRequest _$ToggleUserStatusRequestFromJson(
  Map<String, dynamic> json,
) => ToggleUserStatusRequest(isActive: json['isActive'] as bool);

Map<String, dynamic> _$ToggleUserStatusRequestToJson(
  ToggleUserStatusRequest instance,
) => <String, dynamic>{'isActive': instance.isActive};

UserStatisticsResponse _$UserStatisticsResponseFromJson(
  Map<String, dynamic> json,
) => UserStatisticsResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: UserStatisticsData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserStatisticsResponseToJson(
  UserStatisticsResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

UserStatisticsData _$UserStatisticsDataFromJson(Map<String, dynamic> json) =>
    UserStatisticsData(
      users: UserStats.fromJson(json['users'] as Map<String, dynamic>),
      accessCodes: AccessCodeStatsSummary.fromJson(
        json['accessCodes'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$UserStatisticsDataToJson(UserStatisticsData instance) =>
    <String, dynamic>{
      'users': instance.users,
      'accessCodes': instance.accessCodes,
    };

UserStats _$UserStatsFromJson(Map<String, dynamic> json) => UserStats(
  total: (json['total'] as num?)?.toInt() ?? 0,
  active: (json['active'] as num?)?.toInt() ?? 0,
  recent: (json['recent'] as num?)?.toInt() ?? 0,
  byRole: UserRoleStats.fromJson(json['byRole'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserStatsToJson(UserStats instance) => <String, dynamic>{
  'total': instance.total,
  'active': instance.active,
  'recent': instance.recent,
  'byRole': instance.byRole,
};

UserRoleStats _$UserRoleStatsFromJson(Map<String, dynamic> json) =>
    UserRoleStats(
      admin: (json['admin'] as num?)?.toInt() ?? 0,
      manager: (json['manager'] as num?)?.toInt() ?? 0,
      regular: (json['regular'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$UserRoleStatsToJson(UserRoleStats instance) =>
    <String, dynamic>{
      'admin': instance.admin,
      'manager': instance.manager,
      'regular': instance.regular,
    };

AccessCodeStatsSummary _$AccessCodeStatsSummaryFromJson(
  Map<String, dynamic> json,
) => AccessCodeStatsSummary(
  total: (json['total'] as num?)?.toInt() ?? 0,
  active: (json['active'] as num?)?.toInt() ?? 0,
  used: (json['used'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AccessCodeStatsSummaryToJson(
  AccessCodeStatsSummary instance,
) => <String, dynamic>{
  'total': instance.total,
  'active': instance.active,
  'used': instance.used,
};

// RemainingDaysResponse _$RemainingDaysResponseFromJson(
//   Map<String, dynamic> json,
// ) => RemainingDaysResponse(
//   success: json['success'] as bool,
//   message: json['message'] as String,
//   data: RemainingDaysData.fromJson(json['data'] as Map<String, dynamic>),
// );

Map<String, dynamic> _$RemainingDaysResponseToJson(
  RemainingDaysResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

// RemainingDaysData _$RemainingDaysDataFromJson(Map<String, dynamic> json) =>
//     RemainingDaysData(
//       remainingDays: (json['remainingDays'] as num).toInt(),
//       hasActiveAccess: json['hasActiveAccess'] as bool,
//       activeCodesCount: (json['activeCodesCount'] as num).toInt(),
//     );

Map<String, dynamic> _$RemainingDaysDataToJson(RemainingDaysData instance) =>
    <String, dynamic>{
      'remainingDays': instance.remainingDays,
      'hasActiveAccess': instance.hasActiveAccess,
      'activeCodesCount': instance.activeCodesCount,
    };
