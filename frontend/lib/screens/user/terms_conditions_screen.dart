import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
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
                    'Terms & Conditions',
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
                    '1. Acceptance of Terms',
                    'By downloading, installing, or using the Learn Traffic Rules mobile application, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our app.',
                  ),

                  _buildSection(
                    '2. Description of Service',
                    'Learn Traffic Rules is an educational mobile application that provides:\n\n'
                        '• Interactive traffic rules quizzes and practice exams\n\n'
                        '• Progress tracking and performance analytics\n\n'
                        '• Educational content about traffic regulations\n\n'
                        '• Offline study capabilities\n\n'
                        '• Achievement and progress tracking features',
                  ),

                  _buildSection(
                    '3. User Accounts',
                    'To use our app, you must:\n\n'
                        '• Provide accurate and complete information during registration\n\n'
                        '• Maintain the security of your account\n\n'
                        '• Be responsible for all activities under your account\n\n'
                        '• Notify us immediately of any unauthorized use\n\n'
                        '• Be at least 13 years old to create an account',
                  ),

                  _buildSection(
                    '4. Acceptable Use',
                    'You agree to use our app only for lawful purposes and in accordance with these terms. You may not:\n\n'
                        '• Use the app for any illegal or unauthorized purpose\n\n'
                        '• Attempt to gain unauthorized access to our systems\n\n'
                        '• Interfere with or disrupt the app\'s functionality\n\n'
                        '• Share your account credentials with others\n\n'
                        '• Use automated systems to access the app\n\n'
                        '• Reverse engineer or attempt to extract source code',
                  ),

                  _buildSection(
                    '5. Educational Content',
                    'The content provided in our app is for educational purposes only. While we strive for accuracy:\n\n'
                        '• Information may not reflect the most current traffic laws\n\n'
                        '• Local regulations may vary and take precedence\n\n'
                        '• Users should verify information with official sources\n\n'
                        '• We are not responsible for decisions made based on app content',
                  ),

                  _buildSection(
                    '6. Intellectual Property',
                    'All content, features, and functionality of the app are owned by us and are protected by copyright, trademark, and other intellectual property laws. You may not:\n\n'
                        '• Copy, modify, or distribute our content\n\n'
                        '• Use our trademarks without permission\n\n'
                        '• Create derivative works based on our app\n\n'
                        '• Remove or alter copyright notices',
                  ),

                  _buildSection(
                    '7. Privacy and Data Protection',
                    'Your privacy is important to us. Our collection and use of personal information is governed by our Privacy Policy, which is incorporated into these terms by reference.',
                  ),

                  _buildSection(
                    '8. Disclaimers and Limitations',
                    'THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND. WE DISCLAIM ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO:\n\n'
                        '• WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE\n\n'
                        '• WARRANTIES OF NON-INFRINGEMENT\n\n'
                        '• WARRANTIES THAT THE APP WILL BE UNINTERRUPTED OR ERROR-FREE\n\n'
                        '• WARRANTIES REGARDING THE ACCURACY OR RELIABILITY OF CONTENT',
                  ),

                  _buildSection(
                    '9. Limitation of Liability',
                    'TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO:\n\n'
                        '• LOSS OF PROFITS, DATA, OR USE\n\n'
                        '• BUSINESS INTERRUPTION\n\n'
                        '• PERSONAL INJURY OR PROPERTY DAMAGE\n\n'
                        '• DAMAGES RESULTING FROM USE OR INABILITY TO USE THE APP',
                  ),

                  _buildSection(
                    '10. Termination',
                    'We may terminate or suspend your account at any time for:\n\n'
                        '• Violation of these terms\n\n'
                        '• Fraudulent or illegal activity\n\n'
                        '• Extended periods of inactivity\n\n'
                        '• At our sole discretion\n\n'
                        'You may also terminate your account at any time by contacting us.',
                  ),

                  _buildSection(
                    '11. Changes to Terms',
                    'We reserve the right to modify these terms at any time. Changes will be effective immediately upon posting. Your continued use of the app constitutes acceptance of the modified terms.',
                  ),

                  _buildSection(
                    '12. Governing Law',
                    'These terms are governed by and construed in accordance with the laws of [Your Jurisdiction], without regard to conflict of law principles.',
                  ),

                  _buildSection(
                    '13. Contact Information',
                    'If you have any questions about these Terms and Conditions, please contact us at:\n\n'
                        'Email: engineers.devs@gmail.com\n\n'
                        'Phone: +250791347174\n\n'
                        'WhatsApp: +250791347174\n\n'
                        'Live Chat: Available 24/7',
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
