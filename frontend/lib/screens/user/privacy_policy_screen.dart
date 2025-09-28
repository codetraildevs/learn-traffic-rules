import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy',
                    style: AppTextStyles.heading2.copyWith(fontSize: 24.sp),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Last updated: September 2024',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Privacy Policy Content
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    '1. Information We Collect',
                    'We collect the following information when you use our app:\n\n'
                        '• Personal Information: Your name and phone number for account creation and identification.\n\n'
                        '• Device Information: Device ID for security and authentication purposes.\n\n'
                        '• Usage Data: Your exam results, progress, and app usage patterns to improve our services.\n\n'
                        '• Technical Data: App performance data, crash reports, and device specifications.',
                  ),

                  _buildSection(
                    '2. How We Use Your Information',
                    'We use your information to:\n\n'
                        '• Provide and maintain our educational services\n\n'
                        '• Track your learning progress and exam results\n\n'
                        '• Improve app functionality and user experience\n\n'
                        '• Send important updates and notifications\n\n'
                        '• Ensure app security and prevent fraud\n\n'
                        '• Provide customer support when needed',
                  ),

                  _buildSection(
                    '3. Information Sharing',
                    'We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:\n\n'
                        '• With your explicit consent\n\n'
                        '• To comply with legal obligations\n\n'
                        '• To protect our rights and prevent fraud\n\n'
                        '• With service providers who assist in app operations (under strict confidentiality agreements)',
                  ),

                  _buildSection(
                    '4. Data Security',
                    'We implement appropriate security measures to protect your personal information:\n\n'
                        '• Data encryption during transmission and storage\n\n'
                        '• Secure authentication using device ID\n\n'
                        '• Regular security audits and updates\n\n'
                        '• Limited access to personal data by authorized personnel only',
                  ),

                  _buildSection(
                    '5. Data Retention',
                    'We retain your information for as long as necessary to:\n\n'
                        '• Provide our services to you\n\n'
                        '• Comply with legal obligations\n\n'
                        '• Resolve disputes and enforce agreements\n\n'
                        'You can request deletion of your account and associated data at any time.',
                  ),

                  _buildSection(
                    '6. Your Rights',
                    'You have the right to:\n\n'
                        '• Access your personal information\n\n'
                        '• Correct inaccurate information\n\n'
                        '• Delete your account and data\n\n'
                        '• Withdraw consent for data processing\n\n'
                        '• Export your data in a portable format\n\n'
                        '• Object to certain data processing activities',
                  ),

                  _buildSection(
                    '7. Children\'s Privacy',
                    'Our app is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately.',
                  ),

                  _buildSection(
                    '8. Changes to This Policy',
                    'We may update this Privacy Policy from time to time. We will notify you of any changes by:\n\n'
                        '• Posting the new Privacy Policy in the app\n\n'
                        '• Sending you a notification\n\n'
                        '• Updating the "Last updated" date\n\n'
                        'Your continued use of the app after changes constitutes acceptance of the new policy.',
                  ),

                  _buildSection(
                    '9. Contact Us',
                    'If you have any questions about this Privacy Policy or our data practices, please contact us at:\n\n'
                        'Email: privacy@learntrafficrules.com\n\n'
                        'Phone: +1 (555) 123-4567\n\n'
                        'Address: 123 Learning Street, Education City, EC 12345',
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
