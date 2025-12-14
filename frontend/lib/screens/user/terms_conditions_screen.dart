import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.termsConditionsTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.termsConditionsTitle,
                    style: AppTextStyles.heading2.copyWith(fontSize: 24.sp),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    l10n.lastUpdatedDate('December 2025'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Terms Content
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    l10n.termsConditionsSection1Title,
                    l10n.termsConditionsSection1Content,
                  ),
                  _buildSection(
                    l10n.termsConditionsSection2Title,
                    l10n.termsConditionsSection2Content,
                  ),
                  _buildSection(
                    l10n.termsConditionsSection3Title,
                    l10n.termsConditionsSection3Content,
                  ),
                  _buildSection(
                    l10n.termsConditionsSection4Title,
                    l10n.termsConditionsSection4Content,
                  ),
                  _buildSection(
                    l10n.termsConditionsSection5Title,
                    l10n.termsConditionsSection5Content,
                  ),
                  _buildSection(
                    l10n.termsConditionsSection6Title,
                    l10n.termsConditionsSection6Content,
                  ),
                  _buildSection(
                    l10n.termsConditionsSection7Title,
                    l10n.termsConditionsSection7Content,
                  ),
                  _buildSection(
                    l10n.termsConditionsSection8Title,
                    l10n.termsConditionsSection8Content,
                  ),
                  _buildSection(
                    l10n.termsConditionsSection9Title,
                    l10n.termsConditionsSection9Content,
                  ),
                  _buildSection(
                    l10n.termsConditionsSection10Title,
                    l10n.termsConditionsSection10Content,
                  ),
                  _buildSection(
                    l10n.termsConditionsSection11Title,
                    l10n.termsConditionsSection11Content,
                  ),
                  _buildSection(
                    l10n.termsConditionsSection12Title,
                    l10n.termsConditionsSection12Content,
                  ),
                  _buildSection(
                    l10n.termsConditionsSection13Title,
                    l10n.termsConditionsSection13Content,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              fontSize: 16.sp,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
