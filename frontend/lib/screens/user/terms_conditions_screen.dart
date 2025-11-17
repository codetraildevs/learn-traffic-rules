import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.termsConditions),
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
                    l10n.termsConditions,
                    style: AppTextStyles.heading2.copyWith(fontSize: 24.sp),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    l10n.lastUpdated('November 2025'),
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
                    l10n.termsSection1Title,
                    l10n.termsSection1Content,
                  ),

                  _buildSection(
                    l10n.termsSection2Title,
                    l10n.termsSection2Content,
                  ),

                  _buildSection(
                    l10n.termsSection3Title,
                    l10n.termsSection3Content,
                  ),

                  _buildSection(
                    l10n.termsSection4Title,
                    l10n.termsSection4Content,
                  ),

                  _buildSection(
                    l10n.termsSection5Title,
                    l10n.termsSection5Content,
                  ),

                  _buildSection(
                    l10n.termsSection6Title,
                    l10n.termsSection6Content,
                  ),

                  _buildSection(
                    l10n.termsSection7Title,
                    l10n.termsSection7Content,
                  ),

                  _buildSection(
                    l10n.termsSection8Title,
                    l10n.termsSection8Content,
                  ),

                  _buildSection(
                    l10n.termsSection9Title,
                    l10n.termsSection9Content,
                  ),

                  _buildSection(
                    l10n.termsSection10Title,
                    l10n.termsSection10Content,
                  ),

                  _buildSection(
                    l10n.termsSection11Title,
                    l10n.termsSection11Content,
                  ),

                  _buildSection(
                    l10n.termsSection12Title,
                    l10n.termsSection12Content,
                  ),

                  _buildSection(
                    l10n.termsSection13Title,
                    l10n.termsSection13Content,
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
