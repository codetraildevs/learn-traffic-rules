import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(l10n.aboutApp),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
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
                children: [
                  CircleAvatar(
                    radius: 40.r,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.drive_eta_rounded,
                      size: 40.sp,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.appNameFull,
                    style: AppTextStyles.heading3.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      'Version ${AppConstants.appVersion}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // About Section
            _buildSectionCard(
              title: l10n.aboutAppTitle,
              icon: Icons.info_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appDescriptionFull,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey700,
                      fontSize: 13.sp,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFDC3545),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: const Color(0xFFDC3545),
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                l10n.criticalDisclaimer,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: const Color(0xFFDC3545),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          l10n.developerEntity,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey800,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        _buildDisclaimerBullet(l10n.disclaimerNotAffiliated),
                        _buildDisclaimerBullet(l10n.disclaimerNotEndorsed),
                        _buildDisclaimerBullet(l10n.disclaimerNotConnected),
                        _buildDisclaimerBullet(l10n.disclaimerNotGovernment),
                        _buildDisclaimerBullet(l10n.disclaimerNotAuthorized),
                        _buildDisclaimerBullet(l10n.disclaimerNotConducting),
                        SizedBox(height: 12.h),
                        Text(
                          l10n.disclaimerPrivateEducationalTool,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey800,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Features Section
            _buildSectionCard(
              title: l10n.keyFeatures,
              icon: Icons.star_rounded,
              child: Column(
                children: [
                  _buildFeatureListItem(
                    icon: Icons.quiz_rounded,
                    title: l10n.practiceExams,
                  ),
                  _buildFeatureListItem(
                    icon: Icons.language_rounded,
                    title: l10n.multiLanguage,
                  ),
                  _buildFeatureListItem(
                    icon: Icons.video_library_rounded,
                    title: l10n.richMedia,
                  ),
                  _buildFeatureListItem(
                    icon: Icons.offline_bolt_rounded,
                    title: l10n.offlineMode,
                  ),
                  _buildFeatureListItem(
                    icon: Icons.track_changes_rounded,
                    title: l10n.progressTracking,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Developer Information Section
            _buildSectionCard(
              title: l10n.developerInformation,
              icon: Icons.code_rounded,
              child: Column(
                children: [
                  _buildInfoRow(
                    label: l10n.appNameLabelText,
                    value: l10n.appNameFull,
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoRow(
                    label: l10n.descriptionLabelText,
                    value: l10n.appDescriptionShort,
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoRow(
                    label: l10n.developerLabelText,
                    value: l10n.termsDeveloperInfo,
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoRow(
                    label: l10n.contactEmailLabelText,
                    value: 'codetrail.dev@gmail.com',
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Contact Section
            _buildSectionCard(
              title: l10n.contactSupport,
              icon: Icons.phone_rounded,
              child: Column(
                children: [
                  _buildContactRow(
                    icon: Icons.phone_rounded,
                    label: l10n.phoneLabel,
                    value: '+250 780 494 000',
                    onTap: () async {
                      final uri = Uri.parse('tel:+250780494000');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                  SizedBox(height: 12.h),
                  _buildContactRow(
                    icon: Icons.chat_rounded,
                    label: l10n.whatsapp,
                    value: '+250 780 494 000',
                    onTap: () async {
                      final uri = Uri.parse('https://wa.me/250780494000');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                  SizedBox(height: 12.h),
                  _buildContactRow(
                    icon: Icons.email_rounded,
                    label: l10n.email,
                    value: 'codetrail.dev@gmail.com',
                    onTap: () async {
                      final uri = Uri(
                        scheme: 'mailto',
                        path: 'codetrail.dev@gmail.com',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
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
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }

  Widget _buildFeatureListItem({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey800,
                fontSize: 13.sp,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.grey600,
              fontSize: 12.sp,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey800,
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey600,
                      fontSize: 11.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey800,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerBullet(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.grey800,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey800,
                fontSize: 12.sp,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
