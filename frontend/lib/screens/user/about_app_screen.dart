import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About App'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // App Logo and Info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
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
                children: [
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.drive_eta,
                      size: 40.sp,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Learn Traffic Rules',
                    style: AppTextStyles.heading2.copyWith(fontSize: 24.sp),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Version ${AppConstants.appVersion}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Build ${AppConstants.appBuildNumber}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // App Description
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
                    'About This App',
                    style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Learn Traffic Rules is a comprehensive educational mobile application designed to help individuals prepare for their provisional driving license examination. This app provides interactive practice tests, comprehensive courses, and study materials with multi-language support to enhance safe driving knowledge development.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey700,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.warning, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.warning,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Educational Purpose Only: This app is not affiliated with any government agency or official driving test authority.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.grey700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Features:',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildFeatureItem('• Interactive practice exams'),
                  _buildFeatureItem(
                    '• Multi-language support for exams only (English, French, Kinyarwanda)',
                  ),
                  _buildFeatureItem(
                    '• Comprehensive course content with text, images, audio, and video',
                  ),
                  _buildFeatureItem(
                    '• Audio and video playback for enhanced learning',
                  ),
                  _buildFeatureItem('• Progress tracking and analytics'),
                  _buildFeatureItem(
                    '• Detailed explanations for each question',
                  ),
                  _buildFeatureItem(
                    '• Offline study mode - download exams and courses',
                  ),
                  _buildFeatureItem(
                    '• Offline exam taking with automatic sync',
                  ),
                  _buildFeatureItem(
                    '• Achievement system and progress tracking',
                  ),
                  _buildFeatureItem(
                    '• Course management with structured learning paths',
                  ),
                  _buildFeatureItem('• Payment system with access codes'),
                  _buildFeatureItem(
                    '• Global course access (pay once, unlock all)',
                  ),
                  _buildFeatureItem(
                    '• Regular updates with new questions and courses',
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Developer Info
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
                    'Developer Information',
                    style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                  ),
                  SizedBox(height: 16.h),
                  _buildInfoRow('App Name', AppConstants.appName),
                  _buildInfoRow('Description', AppConstants.appDescription),
                  _buildInfoRow('Developer', 'Traffic Rules Learning Team'),
                  _buildInfoRow('Contact', 'engineers.devs@gmail.com'),
                  _buildInfoRow('Website', 'www.learntrafficrules.com'),
                  _buildInfoRow('Last Updated', 'November 2024'),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Legal Info
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
                    'Legal Information',
                    style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'This app is designed for educational purposes only. While we strive to provide accurate and up-to-date information, users should always refer to official traffic regulations and consult with local authorities for the most current rules.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey700,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Privacy & Data:',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Your data is securely stored and synchronized. Exam results and progress are saved locally and synced to the server when connected. We respect your privacy and do not share your personal information with third parties.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey700,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Technical Features:',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildFeatureItem('• Offline-first architecture'),
                  _buildFeatureItem('• Automatic data synchronization'),
                  _buildFeatureItem('• Multi-language exam support'),
                  _buildFeatureItem('• Rich media course content'),
                  _buildFeatureItem('• Secure payment processing'),
                  _buildFeatureItem('• Real-time progress tracking'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey700),
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
            width: 100.w,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
