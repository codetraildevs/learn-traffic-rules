import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('About App'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section with Gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.all(32.w),
                  child: Column(
                    children: [
                      // App Icon with Shadow
                      Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.drive_eta_rounded,
                          size: 60.sp,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'Rwanda Traffic Rule 🇷🇼',
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 28.sp,
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          'Version ${AppConstants.appVersion} • Build ${AppConstants.appBuildNumber}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content Section
            Transform.translate(
              offset: Offset(0, -20.h),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.r),
                    topRight: Radius.circular(30.r),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // About Section
                      _buildSectionCard(
                        title: 'About This App',
                        icon: Icons.info_rounded,
                        iconColor: AppColors.primary,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rwanda Traffic Rule 🇷🇼 is a comprehensive educational mobile application designed to help individuals prepare for their provisional driving license examination. This app provides interactive practice tests, comprehensive courses, and study materials with multi-language support to enhance safe driving knowledge development.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.grey700,
                                height: 1.6,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _buildInfoBanner(
                              icon: Icons.school_rounded,
                              message:
                                  '⚠️ IMPORTANT: This app is NOT affiliated with, endorsed by, or associated with the Government of Rwanda or any official driving test authority. This is an independent educational tool.',
                            ),
                            SizedBox(height: 16.h),
                            _buildSourceLinksSection(),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Features Section
                      _buildSectionCard(
                        title: 'Key Features',
                        icon: Icons.star_rounded,
                        iconColor: AppColors.warning,
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12.w,
                          crossAxisSpacing: 12.h,
                          childAspectRatio: 1.1,
                          children: [
                            _buildFeatureCard(
                              icon: Icons.quiz_rounded,
                              title: 'Practice Exams',
                              color: AppColors.primary,
                            ),
                            _buildFeatureCard(
                              icon: Icons.language_rounded,
                              title: 'Multi-Language',
                              color: AppColors.success,
                            ),
                            _buildFeatureCard(
                              icon: Icons.video_library_rounded,
                              title: 'Rich Media',
                              color: AppColors.error,
                            ),
                            _buildFeatureCard(
                              icon: Icons.offline_bolt_rounded,
                              title: 'Offline Mode',
                              color: AppColors.warning,
                            ),
                            _buildFeatureCard(
                              icon: Icons.track_changes_rounded,
                              title: 'Progress Tracking',
                              color: AppColors.primary,
                            ),
                            _buildFeatureCard(
                              icon: Icons.payment_rounded,
                              title: 'Access Codes',
                              color: AppColors.success,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // All Features List
                      _buildSectionCard(
                        title: 'Complete Feature List',
                        icon: Icons.list_rounded,
                        iconColor: AppColors.success,
                        child: Column(
                          children: [
                            _buildFeatureListItem(
                              Icons.quiz_rounded,
                              'Interactive practice exams',
                            ),
                            _buildFeatureListItem(
                              Icons.language_rounded,
                              'Multi-language support (English, French, Kinyarwanda)',
                            ),
                            _buildFeatureListItem(
                              Icons.video_library_rounded,
                              'Comprehensive course content with text, images, audio, and video',
                            ),
                            _buildFeatureListItem(
                              Icons.play_circle_rounded,
                              'Audio and video playback for enhanced learning',
                            ),
                            _buildFeatureListItem(
                              Icons.analytics_rounded,
                              'Progress tracking and analytics',
                            ),
                            _buildFeatureListItem(
                              Icons.help_outline_rounded,
                              'Detailed explanations for each question',
                            ),
                            _buildFeatureListItem(
                              Icons.download_rounded,
                              'Offline study mode - download exams and courses',
                            ),
                            _buildFeatureListItem(
                              Icons.sync_rounded,
                              'Offline exam taking with automatic sync',
                            ),
                            _buildFeatureListItem(
                              Icons.emoji_events_rounded,
                              'Achievement system and progress tracking',
                            ),
                            _buildFeatureListItem(
                              Icons.book_rounded,
                              'Course management with structured learning paths',
                            ),
                            _buildFeatureListItem(
                              Icons.payment_rounded,
                              'Payment system with access codes',
                            ),
                            _buildFeatureListItem(
                              Icons.lock_open_rounded,
                              'Global course access (pay once, unlock all)',
                            ),
                            _buildFeatureListItem(
                              Icons.update_rounded,
                              'Regular updates with new questions and courses',
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Developer Info Section
                      _buildSectionCard(
                        title: 'Developer Information',
                        icon: Icons.code_rounded,
                        iconColor: AppColors.primary,
                        child: Column(
                          children: [
                            _buildContactCard(
                              icon: Icons.apps_rounded,
                              label: 'App Name',
                              value: AppConstants.appName,
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 12.h),
                            _buildContactCard(
                              icon: Icons.description_rounded,
                              label: 'Description',
                              value: AppConstants.appDescription,
                              color: AppColors.success,
                            ),
                            SizedBox(height: 12.h),
                            _buildContactCard(
                              icon: Icons.phone_rounded,
                              label: 'Phone',
                              value: '+250 780 494 000',
                              color: AppColors.success,
                            ),
                            SizedBox(height: 12.h),
                            _buildContactCard(
                              icon: Icons.chat_rounded,
                              label: 'WhatsApp',
                              value: '+250 780 494 000',
                              color: AppColors.success,
                            ),

                            SizedBox(height: 12.h),
                            _buildContactCard(
                              icon: Icons.people_rounded,
                              label: 'Developer',
                              value: 'Traffic Rules Learning Team',
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 12.h),
                            _buildContactCard(
                              icon: Icons.email_rounded,
                              label: 'Contact',
                              value: 'engineers.devs@gmail.com',
                              color: AppColors.error,
                            ),
                            SizedBox(height: 12.h),
                            _buildContactCard(
                              icon: Icons.language_rounded,
                              label: 'Website',
                              value: 'www.cyangugudims.com',
                              color: AppColors.warning,
                            ),
                            SizedBox(height: 12.h),
                            _buildContactCard(
                              icon: Icons.calendar_today_rounded,
                              label: 'Last Updated',
                              value: 'November 2025',
                              color: AppColors.grey600,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Legal & Privacy Section
                      _buildSectionCard(
                        title: 'Legal & Privacy',
                        icon: Icons.gavel_rounded,
                        iconColor: AppColors.error,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoBox(
                              icon: Icons.info_outline_rounded,
                              title: 'Legal Notice',
                              content:
                                  'This app is designed for educational purposes only. While we strive to provide accurate and up-to-date information, users should always refer to official traffic regulations and consult with local authorities for the most current rules.\n\nFor official driving license information (provisional and permanent), please visit:\n• Rwanda National Police (Driving License Services): police.gov.rw/home',
                              color: AppColors.error,
                            ),
                            SizedBox(height: 16.h),
                            _buildInfoBox(
                              icon: Icons.lock_rounded,
                              title: 'Privacy & Data',
                              content:
                                  'Your data is securely stored and synchronized. Exam results and progress are saved locally and synced to the server when connected. We respect your privacy and do not share your personal information with third parties.',
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Technical Features
                      _buildSectionCard(
                        title: 'Technical Features',
                        icon: Icons.settings_rounded,
                        iconColor: AppColors.warning,
                        child: Wrap(
                          spacing: 12.w,
                          runSpacing: 12.h,
                          children: [
                            _buildTechBadge(
                              'Offline-first',
                              Icons.cloud_off_rounded,
                            ),
                            _buildTechBadge('Auto Sync', Icons.sync_rounded),
                            _buildTechBadge(
                              'Multi-language',
                              Icons.language_rounded,
                            ),
                            _buildTechBadge(
                              'Rich Media',
                              Icons.video_library_rounded,
                            ),
                            _buildTechBadge(
                              'Secure Payment',
                              Icons.payment_rounded,
                            ),
                            _buildTechBadge(
                              'Real-time Tracking',
                              Icons.track_changes_rounded,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: iconColor, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: AppTextStyles.heading3.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoBanner({required IconData icon, required String message}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.1),
            AppColors.warning.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.warning, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey800,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 28.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.grey800,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureListItem(IconData icon, String text) {
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
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
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
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechBadge(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: AppColors.primary),
          SizedBox(width: 6.w),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceLinksSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
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
              Icon(Icons.link_rounded, color: AppColors.error, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Official Government Sources',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'For official traffic rules, regulations, and driving license information (including provisional and permanent driving licenses), please refer to:',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.grey700,
              height: 1.5,
            ),
          ),
          SizedBox(height: 12.h),
          _buildSourceLink(
            'Rwanda National Police (Driving License Services)',
            'police.gov.rw/home',
            'https://police.gov.rw/home/',
          ),
        ],
      ),
    );
  }

  Widget _buildSourceLink(String title, String url, String fullUrl) {
    return InkWell(
      onTap: () async {
        try {
          final uri = Uri.parse(fullUrl);
          debugPrint('🌐 Attempting to open: $fullUrl');

          bool launched = false;

          // Try inAppWebView first (keeps app running)
          try {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.inAppWebView);
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
                await launchUrl(uri, mode: LaunchMode.platformDefault);
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
              await launchUrl(uri, mode: LaunchMode.inAppWebView);
              launched = true;
              debugPrint('✅ Opened with inAppWebView (no check)');
            } catch (e) {
              debugPrint('⚠️ Direct launch failed: $e');
            }
          }

          if (!launched) {
            debugPrint('❌ All launch attempts failed for: $fullUrl');
          }
        } catch (e) {
          debugPrint('❌ Error launching URL: $e');
        }
      },
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.open_in_new_rounded,
              size: 16.sp,
              color: AppColors.error,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey800,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    url,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                      fontSize: 11.sp,
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
}
