import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_selector.dart';
import '../../widgets/theme_selector.dart';

class ViewProfileScreen extends ConsumerWidget {
  const ViewProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(l10n.viewProfile),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Profile Details
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileInformation,
                    style: AppTextStyles.heading3.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  _buildInfoRow(
                    l10n.fullName,
                    user?.fullName ?? l10n.notProvided,
                  ),
                  _buildInfoRow(
                    l10n.phoneLabel,
                    user?.phoneNumber ?? l10n.noPhoneNumber,
                  ),
                  _buildInfoRow(
                    l10n.accountStatus,
                    user?.isActive == true ? l10n.active : l10n.inactive,
                  ),
                  _buildInfoRow(
                    l10n.lastLogin,
                    user?.lastLogin != null
                        ? _formatDate(user!.lastLogin!, l10n)
                        : l10n.never,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Language Settings
            const LanguageSelector(),
            SizedBox(height: 12.h),

            // Theme Settings
            const ThemeSelector(),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
                fontSize: 13.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey800,
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    return l10n.dateTimeFormat(
      date.month,
      date.day,
      date.year,
      hour,
      int.parse(minute),
    );
  }
}
