import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../main.dart';
import '../../services/flash_message_service.dart';
import '../../l10n/app_localizations.dart';
import '../auth/register_screen.dart';

class DisclaimerScreen extends ConsumerStatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  ConsumerState<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends ConsumerState<DisclaimerScreen> {
  bool _hasAcceptedDisclaimer = false; // Must be explicitly checked

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false, // Prevent back button - unskippable
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Scrollable Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      // App Icon
                      Container(
                        width: 100.w,
                        height: 100.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.school,
                          size: 50.w,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // App Title
                      Text(
                        l10n.appNameFull,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey800,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6.h),

                      // Subtitle
                      Text(
                        l10n.educationalStudyPlatform,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32.h),

                      // Disclaimer Icon
                      Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 40.w,
                          color: const Color(0xFFDC3545),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Disclaimer Title
                      Text(
                        l10n.importantDisclaimerReadCarefully,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFDC3545),
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
                            color: const Color(0xFFDC3545),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.disclaimerPrivateEntity,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              l10n.disclaimerWeAre,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _buildBulletPoint(l10n.disclaimerNotAffiliated),
                            _buildBulletPoint(l10n.disclaimerNotEndorsed),
                            _buildBulletPoint(l10n.disclaimerNotConnected),
                            _buildBulletPoint(l10n.disclaimerNotGovernment),
                            _buildBulletPoint(l10n.disclaimerNotAuthorized),
                            _buildBulletPoint(l10n.disclaimerNotConducting),
                            SizedBox(height: 16.h),
                            Text(
                              l10n.disclaimerPrivateEducationalTool,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFDC3545),
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              l10n.disclaimerOfficialProcedures,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF6B7280),
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              l10n.disclaimerAcknowledge,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFF6B7280),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),

              // Fixed Bottom Section (Checkbox + Button)
              Container(
                padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Checkbox for acceptance
                    InkWell(
                      onTap: () {
                        setState(() {
                          _hasAcceptedDisclaimer = !_hasAcceptedDisclaimer;
                        });
                      },
                      child: Row(
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
                              l10n.disclaimerReadUnderstood,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF1F2937),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: _hasAcceptedDisclaimer
                            ? _proceedToApp
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasAcceptedDisclaimer
                              ? AppColors.primary
                              : AppColors.grey400,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          disabledBackgroundColor: AppColors.grey400,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                l10n.disclaimerUnderstandButton,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(Icons.arrow_forward, size: 20.sp),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToApp() async {
    final l10n = AppLocalizations.of(context);
    // Check if user has accepted the disclaimer
    if (!_hasAcceptedDisclaimer) {
      // Show flash message asking user to accept terms
      AppFlashMessage.showWarning(
        context,
        l10n.pleaseAcceptTermsAndConditions,
        description: l10n.pleaseCheckTheBoxBelowToAcceptTermsAndConditions,
      );

      // Scroll to checkbox to make it visible
      // The flash message will guide the user
      return;
    }

    // Save that user has accepted disclaimer
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disclaimer_accepted', true);

    // Update the provider to trigger rebuild
    ref.read(disclaimerAcceptedProvider.notifier).state = true;

    debugPrint(
      '🔄 DISCLAIMER: Disclaimer accepted, navigating to RegisterScreen',
    );

    // Navigate directly to RegisterScreen (first time user opens app)
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RegisterScreen()),
      );
    }
  }
}
