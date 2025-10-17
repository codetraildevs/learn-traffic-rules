import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';

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
                    'Version 1.0.0',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
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
                    'Learn Traffic Rules is a comprehensive mobile application designed to help users master traffic rules and regulations through interactive quizzes and practice exams.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey700,
                      height: 1.5,
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
                  _buildFeatureItem('• Progress tracking and analytics'),
                  _buildFeatureItem(
                    '• Detailed explanations for each question',
                  ),
                  _buildFeatureItem('• Offline study mode'),
                  _buildFeatureItem('• Achievement system'),
                  _buildFeatureItem('• Regular updates with new questions'),
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
                  _buildInfoRow('Developer', 'Traffic Rules Learning Team'),
                  _buildInfoRow('Contact', 'support@learntrafficrules.com'),
                  _buildInfoRow('Website', 'www.learntrafficrules.com'),
                  _buildInfoRow('Last Updated', 'September 2024'),
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
