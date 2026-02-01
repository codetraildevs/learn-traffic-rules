import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/core/theme/app_theme.dart';
import 'package:learn_traffic_rules/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyModal extends StatelessWidget {
  final String title;
  final String content;
  final String fullPolicyUrl;

  const PrivacyPolicyModal({
    super.key,
    required this.title,
    required this.content,
    required this.fullPolicyUrl,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String content,
    required String fullPolicyUrl,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PrivacyPolicyModal(
        title: title,
        content: content,
        fullPolicyUrl: fullPolicyUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.grey900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: AppColors.grey600,
                    size: 24.sp,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Educational disclaimer
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.error,
                              size: 20.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                l10n.importantDisclaimer,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          l10n.privacyGovDisclaimer,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey800,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          l10n.officialSource,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        GestureDetector(
                          onTap: () async {
                            const url = 'https://police.gov.rw/home/';
                            try {
                              final uri = Uri.parse(url);
                              debugPrint('🌐 Attempting to open: $url');

                              bool launched = false;

                              // Try inAppWebView first (keeps app running)
                              try {
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.inAppWebView,
                                  );
                                  launched = true;
                                  debugPrint('✅ Opened with inAppWebView');
                                }
                              } catch (e) {
                                debugPrint('⚠️ inAppWebView failed: $e');
                              }

                              // Fallback to platformDefault
                              if (!launched) {
                                try {
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.platformDefault,
                                    );
                                    launched = true;
                                    debugPrint('✅ Opened with platformDefault');
                                  }
                                } catch (e) {
                                  debugPrint('⚠️ platformDefault failed: $e');
                                }
                              }

                              // Try without canLaunchUrl check
                              if (!launched) {
                                try {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.inAppWebView,
                                  );
                                  launched = true;
                                  debugPrint(
                                    '✅ Opened with inAppWebView (no check)',
                                  );
                                } catch (e) {
                                  debugPrint('⚠️ Direct launch failed: $e');
                                }
                              }

                              if (!launched) {
                                debugPrint(
                                  '❌ All launch attempts failed for: $url',
                                );
                              }
                            } catch (e) {
                              debugPrint('❌ Error launching URL: $e');
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.link_rounded,
                                color: AppColors.primary,
                                size: 16.sp,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  l10n.rnpDrivingLicense,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Privacy policy content
                  Text(
                    content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey700,
                      height: 1.6,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Data collection section
                  _buildSection(l10n.dataWeCollect, l10n.dataWeCollectContent),

                  SizedBox(height: 16.h),

                  // Data usage section
                  _buildSection(
                    l10n.howWeUseYourData,
                    l10n.howWeUseYourDataContent,
                  ),

                  SizedBox(height: 16.h),

                  // Data protection section
                  _buildSection(
                    l10n.dataProtection,
                    l10n.dataProtectionContent,
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),

          // Bottom section with full policy link
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: const BoxDecoration(
              color: AppColors.grey50,
              border: Border(
                top: BorderSide(color: AppColors.grey200, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Full policy link
                GestureDetector(
                  onTap: () => _launchFullPolicy(fullPolicyUrl, context),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.open_in_new,
                          color: AppColors.white,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          l10n.readFullPrivacyPolicy,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                // Contact info
                Text(
                  l10n.contactUsQuestion,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.grey900,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          content,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.grey700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Future<void> _launchFullPolicy(String url, BuildContext buildContext) async {
    final l10n = AppLocalizations.of(buildContext);
    try {
      final Uri uri = Uri.parse(url);

      // Try direct launch first
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching privacy policy: $e');

      // Show fallback dialog
      if (buildContext.mounted) {
        showDialog(
          context: buildContext,
          builder: (context) => AlertDialog(
            title: Text(l10n.openPrivacyPolicy),
            content: Text('${l10n.unableToOpenBrowser}: $url'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      }
    }
  }
}
