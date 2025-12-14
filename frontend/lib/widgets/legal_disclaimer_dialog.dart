import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class LegalDisclaimerDialog extends StatelessWidget {
  const LegalDisclaimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 24.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              l10n.importantLegalNotice,
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Government Disclaimer
            _buildDisclaimerSection(
              icon: Icons.warning_amber_rounded,
              title: l10n.governmentAffiliation,
              content: l10n.governmentAffiliationContent,
              isWarning: true,
            ),

            SizedBox(height: 16.h),

            // Educational Purpose
            _buildDisclaimerSection(
              icon: Icons.school_rounded,
              title: l10n.educationalPurposeOnlyDisclaimer,
              content: l10n.educationalPurposeOnlyContent,
              isWarning: false,
            ),

            SizedBox(height: 16.h),

            // No Official Certification
            _buildDisclaimerSection(
              icon: Icons.cancel_outlined,
              title: l10n.noOfficialCertification,
              content: l10n.noOfficialCertificationContent,
              isWarning: true,
            ),

            SizedBox(height: 16.h),

            // User Responsibility
            _buildDisclaimerSection(
              icon: Icons.person_outline,
              title: l10n.yourResponsibility,
              content: l10n.yourResponsibilityContent,
              isWarning: false,
            ),

            SizedBox(height: 20.h),

            // Additional Info
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.primary,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        l10n.remember,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    l10n.privateEducationalToolDisclaimer,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.iUnderstand,
            style: AppTextStyles.button.copyWith(color: AppColors.grey600),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          ),
          child: Text(
            l10n.continueLearning,
            style: AppTextStyles.button.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimerSection({
    required IconData icon,
    required String title,
    required String content,
    required bool isWarning,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isWarning
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isWarning
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isWarning ? AppColors.error : AppColors.primary,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isWarning ? AppColors.error : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// Usage in your app
class LegalDisclaimerService {
  static Future<bool> showDisclaimer(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const LegalDisclaimerDialog(),
        ) ??
        false;
  }
}
