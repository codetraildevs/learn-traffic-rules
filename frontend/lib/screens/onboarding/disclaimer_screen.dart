import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../main.dart';

class DisclaimerScreen extends ConsumerStatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  ConsumerState<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends ConsumerState<DisclaimerScreen> {
  bool _hasAcceptedDisclaimer = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              // App Logo and Title
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon
                    Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4F46E5,
                            ).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.school,
                        size: 60.w,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // App Title
                    Text(
                      'Learn Traffic Rules',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // Subtitle
                    Text(
                      'Provisional Driving License Preparation',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Disclaimer Content
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Disclaimer Icon
                      Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          size: 40.w,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Disclaimer Title
                      Text(
                        'Educational Disclaimer',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),

                      // Disclaimer Text
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildDisclaimerItem(
                              icon: Icons.school,
                              title: 'Educational Purpose Only',
                              description:
                                  'This app is designed for educational purposes to help you prepare for your provisional driving license exam.',
                            ),
                            SizedBox(height: 16.h),
                            _buildDisclaimerItem(
                              icon: Icons.sim_card,
                              title: 'Practice Simulation',
                              description:
                                  'The practice tests simulate real exam conditions but are not official government examinations.',
                            ),
                            SizedBox(height: 16.h),
                            _buildDisclaimerItem(
                              icon: Icons.warning_amber,
                              title: 'Not Official',
                              description:
                                  'This app is not affiliated with any government agency or official driving test authority.',
                            ),
                            SizedBox(height: 16.h),
                            _buildDisclaimerItem(
                              icon: Icons.update,
                              title: 'Stay Updated',
                              description:
                                  'Always refer to official sources for the most current traffic rules and regulations.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Accept Button
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton(
                          onPressed: _hasAcceptedDisclaimer
                              ? _proceedToApp
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          child: Text(
                            'I Understand - Continue',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Checkbox for acceptance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _hasAcceptedDisclaimer,
                            onChanged: (value) {
                              setState(() {
                                _hasAcceptedDisclaimer = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFF4F46E5),
                          ),
                          Expanded(
                            child: Text(
                              'I have read and understood the educational disclaimer',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimerItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 20.w, color: const Color(0xFF4F46E5)),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _proceedToApp() async {
    // Save that user has accepted disclaimer
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disclaimer_accepted', true);

    // Update the provider to trigger rebuild
    ref.read(disclaimerAcceptedProvider.notifier).state = true;

    debugPrint('🔄 DISCLAIMER: Disclaimer accepted, provider updated');
    debugPrint(
      '🔄 DISCLAIMER: Letting main app handle navigation automatically',
    );

    // Don't navigate manually - let the main app handle it automatically
    // The provider update will trigger a rebuild and show the appropriate screen
  }
}
