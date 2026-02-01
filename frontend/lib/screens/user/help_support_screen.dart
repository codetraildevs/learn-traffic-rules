import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(l10n.helpSupport),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.help_outline,
                      size: 40.sp,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.helpSupport,
                    style: AppTextStyles.heading3.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    l10n.weAreHereToHelpYouSucceed,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                      fontSize: 13.sp,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Quick Help
            _buildSectionCard(
              title: l10n.quickHelp,
              icon: Icons.help_rounded,
              child: Column(
                children: [
                  _buildHelpItem(
                    l10n.howToTakeAnExam,
                    l10n.learnTheBasicsOfTakingExams,
                    Icons.quiz,
                    () => _showHelpModal(
                      context,
                      l10n.howToTakeAnExam,
                      _getExamHelpText(),
                      Icons.quiz,
                    ),
                  ),

                  _buildHelpItem(
                    l10n.understandingYourProgress,
                    l10n.trackYourLearningJourney,
                    Icons.analytics,
                    () => _showHelpModal(
                      context,
                      l10n.understandingYourProgress,
                      _getProgressHelpText(),
                      Icons.analytics,
                    ),
                  ),

                  _buildHelpItem(
                    l10n.paymentAndAccessCodes,
                    l10n.learnAboutPaymentOptions,
                    Icons.payment,
                    () => _showHelpModal(
                      context,
                      l10n.paymentAndAccessCodes,
                      _getPaymentHelpText(),
                      Icons.payment,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Contact Support
            _buildSectionCard(
              title: l10n.contactSupport,
              icon: Icons.phone_rounded,
              child: Column(
                children: [
                  _buildContactItem(
                    l10n.emailSupport,
                    'engineers.devs@gmail.com',
                    Icons.email,
                    () => _launchEmail(),
                  ),

                  _buildContactItem(
                    l10n.phoneSupport,
                    '+250 788 659 575',
                    Icons.phone,
                    () => _launchPhone(),
                  ),

                  _buildContactItem(
                    l10n.whatsappLabel,
                    '+250 788 659 575',
                    Icons.chat,
                    () => _launchWhatsApp(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // FAQ
            _buildSectionCard(
              title: l10n.frequentlyAskedQuestions,
              icon: Icons.question_answer_rounded,
              child: Column(
                children: [
                  _buildFAQItem(
                    l10n.faqHowDoIResetMyProgress,
                    l10n.faqHowDoIResetMyProgressAnswer,
                  ),

                  _buildFAQItem(
                    l10n.faqCanIUseTheAppOffline,
                    l10n.faqCanIUseTheAppOfflineAnswer,
                  ),

                  _buildFAQItem(
                    l10n.faqHowOftenAreNewQuestionsAdded,
                    l10n.faqHowOftenAreNewQuestionsAddedAnswer,
                  ),

                  _buildFAQItem(
                    l10n.faqIsMyDataSecure,
                    l10n.faqIsMyDataSecureAnswer,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }

  Widget _buildHelpItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: AppColors.grey800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey600,
                      fontSize: 12.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: AppColors.grey800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey600,
                      fontSize: 12.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        childrenPadding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        title: Text(
          question,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
            color: AppColors.grey800,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Text(
            answer,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey700,
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpModal(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon and Title
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            icon,
                            color: AppColors.primary,
                            size: 28.sp,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.heading3.copyWith(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    // Content with formatted steps
                    _buildFormattedContent(content),
                  ],
                ),
              ),
            ),
            // Close Button
            Padding(
              padding: EdgeInsets.all(20.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.close,
                    style: AppTextStyles.button.copyWith(fontSize: 15.sp),
                  ),
                ),
              ),
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedContent(String content) {
    // Split content by lines and format numbered steps
    final lines = content.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(SizedBox(height: 12.h));
        continue;
      }

      // Check if line starts with a number (step)
      final stepMatch = RegExp(r'^(\d+)\.?\s*(.+)$').firstMatch(line);
      if (stepMatch != null) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      stepMatch.group(1)!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    stepMatch.group(2)!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey800,
                      fontSize: 14.sp,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Regular paragraph
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Text(
              line,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey700,
                fontSize: 14.sp,
                height: 1.6,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  void _launchEmail() async {
    final l10n = AppLocalizations.of(context);
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'engineers.devs@gmail.com',
      query: 'subject=${l10n.supportRequestSubject}',
    );

    debugPrint('🔍 Email URI: $emailUri');

    try {
      // Try launching email directly without checking canLaunchUrl first
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      debugPrint('✅ Email launched successfully');
    } catch (e) {
      debugPrint('❌ Direct email launch failed: $e');

      try {
        // Fallback: try with platform default mode
        await launchUrl(emailUri, mode: LaunchMode.platformDefault);
        debugPrint('✅ Email launched with platform default mode');
      } catch (finalError) {
        debugPrint('❌ All email launch attempts failed: $finalError');
        if (!mounted) return;

        // Show user-friendly error with alternative options
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.emailNotAvailableTryTheseAlternatives),
                SizedBox(height: 4.h),
                Text('${l10n.callColon} +250 788 659 575'),
                Text('${l10n.whatsAppColon} +250 788 659 575'),
                Text('${l10n.manualColon} engineers.devs@gmail.com'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: l10n.callInstead,
              textColor: Colors.white,
              onPressed: () => _launchPhone(),
            ),
          ),
        );
      }
    }
  }

  void _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+250788659575');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _launchWhatsApp() async {
    // Use the specific admin WhatsApp number
    const cleanNumber = '250788659575';
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');

    debugPrint('🔍 WhatsApp URL: $whatsappUri');
    debugPrint('🔍 Clean phone: $cleanNumber');

    try {
      // Try launching WhatsApp directly without checking canLaunchUrl first
      // This often works better on Android devices
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      debugPrint('✅ WhatsApp launched successfully');
    } catch (e) {
      debugPrint('❌ Direct WhatsApp launch failed: $e');

      try {
        // Fallback: try WhatsApp Web
        final webUri = Uri.parse(
          'https://web.whatsapp.com/send?phone=$cleanNumber',
        );
        debugPrint('🔄 Trying WhatsApp Web: $webUri');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        debugPrint('✅ WhatsApp Web launched successfully');
      } catch (webError) {
        debugPrint('❌ WhatsApp Web also failed: $webError');

        // Final fallback: try with different launch modes
        try {
          await launchUrl(whatsappUri, mode: LaunchMode.platformDefault);
          debugPrint('✅ WhatsApp launched with platform default mode');
        } catch (finalError) {
          debugPrint('❌ All WhatsApp launch attempts failed: $finalError');
          if (!mounted) return;

          // Show user-friendly error with alternative options
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.whatsappNotAvailableTryTheseAlternatives),
                  SizedBox(height: 4.h),
                  Text('${l10n.callColon} +250 788 659 575'),
                  Text('${l10n.whatsAppWebColon} web.whatsapp.com'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: l10n.callInstead,
                textColor: Colors.white,
                onPressed: () => _launchPhone(),
              ),
            ),
          );
        }
      }
    }
  }

  String _getExamHelpText() {
    final l10n = AppLocalizations.of(context);
    return l10n.examHelpText;
  }

  String _getProgressHelpText() {
    final l10n = AppLocalizations.of(context);
    return l10n.progressHelpText;
  }

  String _getPaymentHelpText() {
    final l10n = AppLocalizations.of(context);
    return l10n.paymentHelpText;
  }

  // String _getAccountHelpText() {
  //   final l10n = AppLocalizations.of(context);
  //   return l10n.accountHelpText;
  // }
}
