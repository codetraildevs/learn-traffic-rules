import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _hasAcceptedDisclaimer = true; // Default to checked

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon
                      Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(24.r),
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
                          size: 60.w,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // App Title
                      Text(
                        l10n.appName,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey800,
                          fontFamily: 'Poppins',
                          fontStyle: FontStyle.normal,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // Subtitle
                      Text(
                        l10n.provisionalDrivingLicense,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
                        l10n.educationalDisclaimer,
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
                              l10n,
                              icon: Icons.school,
                              title: l10n.educationalPurposeOnlyDisclaimer,
                              description:
                                  l10n.educationalPurposeOnlyDescription,
                            ),
                            SizedBox(height: 16.h),
                            _buildDisclaimerItem(
                              l10n,
                              icon: Icons.sim_card,
                              title: l10n.practiceSimulation,
                              description: l10n.practiceSimulationDescription,
                            ),
                            SizedBox(height: 16.h),
                            _buildDisclaimerItem(
                              l10n,
                              icon: Icons.warning_amber,
                              title: l10n.notOfficial,
                              description: l10n.notAffiliatedNotice,
                            ),
                            SizedBox(height: 16.h),
                            _buildOfficialSourceItem(context, l10n),
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
                        height: 50.h,
                        child: ElevatedButton(
                          onPressed: _proceedToApp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.iUnderstandContinue,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              SizedBox(width: 8.w),
                              !_hasAcceptedDisclaimer
                                  ? Icon(
                                      Icons.arrow_downward,
                                      size: 20.sp,
                                      color: Colors.white,
                                    )
                                  : Icon(
                                      Icons.arrow_circle_right,
                                      size: 20.sp,
                                      color: Colors.white,
                                    ),
                            ],
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
                              l10n.iHaveReadAndUnderstoodTheEducationalDisclaimer,
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

  Widget _buildDisclaimerItem(
    AppLocalizations l10n, {
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

  Widget _buildOfficialSourceItem(BuildContext context, AppLocalizations l10n) {
    const policeUrl = 'https://police.gov.rw/home/';

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
          child: Icon(Icons.link, size: 20.w, color: const Color(0xFF4F46E5)),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.officialSource,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                l10n.officialSourceDescription,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 4.h),
              GestureDetector(
                onTap: () => _openPoliceWebsite(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 16.sp,
                      color: const Color(0xFF4F46E5),
                    ),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        l10n.rnpDrivingLicense,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF4F46E5),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              GestureDetector(
                onTap: () => _openPoliceWebsite(context),
                child: Text(
                  policeUrl,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF4F46E5),
                    decoration: TextDecoration.underline,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openPoliceWebsite(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    const url = 'https://police.gov.rw/home/';
    try {
      final uri = Uri.parse(url);
      debugPrint('🌐 Attempting to open: $url');

      // Try to launch the URL with multiple fallback strategies
      bool launched = false;

      // First, try with inAppWebView (keeps app running, opens in-app browser)
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
          launched = true;
          debugPrint('✅ Opened with inAppWebView');
        }
      } catch (e) {
        debugPrint('⚠️ inAppWebView failed: $e');
      }

      // If that didn't work, try platformDefault (keeps app in foreground)
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

      // If still not launched, try without checking canLaunchUrl first
      // (sometimes canLaunchUrl returns false but launchUrl still works)
      if (!launched) {
        try {
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
          launched = true;
          debugPrint('✅ Opened with inAppWebView (no check)');
        } catch (e) {
          debugPrint('⚠️ Direct inAppWebView launch failed: $e');
        }
      }

      // Last resort: externalApplication (may cause app to exit)
      if (!launched) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          debugPrint('⚠️ Opened with externalApplication (app may exit)');
        } catch (e) {
          debugPrint('⚠️ externalApplication failed: $e');
        }
      }

      // If all attempts failed, show error with copy option
      if (!launched) {
        debugPrint('❌ All launch attempts failed for: $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.couldNotOpenLinkTapCopyToCopyTheUrl),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: l10n.copy,
                textColor: Colors.white,
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: url));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.urlCopiedToClipboard),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error opening website: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorMessage(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: l10n.copyUrl,
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: url));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.urlCopiedToClipboard),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    }
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
