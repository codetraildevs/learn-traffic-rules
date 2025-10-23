import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/core/theme/app_theme.dart';
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
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          color: AppColors.warning,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Educational Purpose Only',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
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
                  _buildSection(
                    'Data We Collect',
                    '• Phone number for account creation\n'
                        '• Device information for security\n'
                        '• Learning progress and exam results\n'
                        '• App usage patterns for improvement',
                  ),

                  SizedBox(height: 16.h),

                  // Data usage section
                  _buildSection(
                    'How We Use Your Data',
                    '• Provide personalized learning experience\n'
                        '• Track your progress and performance\n'
                        '• Send educational notifications\n'
                        '• Improve app functionality',
                  ),

                  SizedBox(height: 16.h),

                  // Data protection section
                  _buildSection(
                    'Data Protection',
                    '• Your data is encrypted and secure\n'
                        '• We never share personal information\n'
                        '• You can delete your account anytime\n'
                        '• Contact us for data requests',
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),

          // Bottom section with full policy link
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              border: Border(
                top: BorderSide(color: AppColors.grey200, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Full policy link
                GestureDetector(
                  onTap: () => _launchFullPolicy(fullPolicyUrl),
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
                          'Read Full Privacy Policy',
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
                  'Questions? Contact us at +250 780 494 000',
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

  Future<void> _launchFullPolicy(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      
      // Try direct launch first
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching privacy policy: $e');
      
      // Show fallback dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Open Privacy Policy'),
            content: Text('Unable to open browser automatically.\n\nPlease visit: $url'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
