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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpSupport),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
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
                  Icon(
                    Icons.help_outline,
                    size: 48.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.helpSupport,
                    style: AppTextStyles.heading2.copyWith(fontSize: 24.sp),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    l10n.weAreHereToHelpYouSucceed,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Quick Help
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
                    l10n.quickHelp,
                    style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                  ),
                  SizedBox(height: 16.h),

                  _buildHelpItem(
                    l10n.howToTakeAnExam,
                    l10n.learnTheBasicsOfTakingExams,
                    Icons.quiz,
                    () => _showHelpDialog(
                      l10n.howToTakeAnExam,
                      _getExamHelpText(),
                    ),
                  ),

                  _buildHelpItem(
                    l10n.understandingYourProgress,
                    l10n.trackYourLearningJourney,
                    Icons.analytics,
                    () => _showHelpDialog(
                      l10n.understandingYourProgress,
                      _getProgressHelpText(),
                    ),
                  ),

                  _buildHelpItem(
                    l10n.paymentAndAccessCodes,
                    l10n.learnAboutPaymentOptions,
                    Icons.payment,
                    () => _showHelpDialog(
                      l10n.paymentAndAccessCodes,
                      _getPaymentHelpText(),
                    ),
                  ),

                  _buildHelpItem(
                    l10n.accountManagement,
                    l10n.manageYourProfileAndSettings,
                    Icons.person,
                    () => _showHelpDialog(
                      l10n.accountManagement,
                      _getAccountHelpText(),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Contact Support
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
                    l10n.contactSupport,
                    style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                  ),
                  SizedBox(height: 16.h),

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

                  _buildContactItem(
                    l10n.liveChat,
                    l10n.available247,
                    Icons.chat_bubble,
                    () => _showLiveChatDialog(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Send Message
            // Container(
            //   width: double.infinity,
            //   padding: EdgeInsets.all(20.w),
            //   decoration: BoxDecoration(
            //     color: AppColors.white,
            //     borderRadius: BorderRadius.circular(16.r),
            //     boxShadow: [
            //       BoxShadow(
            //         color: AppColors.black.withValues(alpha: 0.05),
            //         blurRadius: 10,
            //         offset: const Offset(0, 5),
            //       ),
            //     ],
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Text(
            //         'Send us a Message',
            //         style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
            //       ),
            //       SizedBox(height: 16.h),

            //       TextField(
            //         controller: _subjectController,
            //         decoration: InputDecoration(
            //           labelText: 'Subject',
            //           hintText: 'What can we help you with?',
            //           border: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(8.r),
            //           ),
            //         ),
            //       ),

            //       SizedBox(height: 16.h),

            //       TextField(
            //         controller: _messageController,
            //         maxLines: 4,
            //         decoration: InputDecoration(
            //           labelText: 'Message',
            //           hintText: 'Describe your issue or question...',
            //           border: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(8.r),
            //           ),
            //         ),
            //       ),

            //       SizedBox(height: 20.h),

            //       CustomButton(
            //         text: 'Send Message',
            //         onPressed: _sendMessage,
            //         backgroundColor: AppColors.primary,
            //         width: double.infinity,
            //       ),
            //     ],
            //   ),
            // ),

            // SizedBox(height: 24.h),

            // FAQ
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
                    l10n.frequentlyAskedQuestions,
                    style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                  ),
                  SizedBox(height: 16.h),

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
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey600,
                    ),
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
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey600,
                    ),
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
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: ExpansionTile(
        title: Text(
          question,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Text(
              answer,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(String title, String content) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showLiveChatDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.liveChat),
        content: Text(l10n.liveChatCurrentlyUnavailable),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _launchEmail() async {
    final l10n = AppLocalizations.of(context)!;
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
        final l10n = AppLocalizations.of(context)!;
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
          final l10n = AppLocalizations.of(context)!;
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
    return '''
1. Go to the Exams tab
2. Select an exam you want to take
3. Read each question carefully
4. Click on the circle next to your chosen answer
5. Use the Next/Previous buttons to navigate
6. Click "Finish Exam" when you're done
7. Review your results and see detailed explanations

Tips:
- Take your time to read each question
- Don't rush through the exam
- Review your answers before submitting
- Use the progress indicator to track your position
''';
  }

  String _getProgressHelpText() {
    return '''
Your progress is tracked in several ways:

1. Overall Performance: Your average score across all exams
2. Study Streak: Consecutive days you've studied
3. Achievements: Badges earned for milestones
4. Category Performance: How well you do in different topics
5. Areas of Improvement: Topics that need more practice

To improve your progress:
- Study regularly
- Review incorrect answers
- Focus on weak areas
- Take practice exams frequently
''';
  }

  String _getPaymentHelpText() {
    return '''
Payment Options:
1. Mobile Money (MTN, Airtel, etc.)
2. Bank Transfer
3. Credit/Debit Card

Access Codes:
- 1500 RWF: 30 days access
- 3000 RWF: 90 days access  
- 5000 RWF: 180 days access

To purchase:
1. Go to Payment Instructions
2. Follow the payment steps
3. Send proof of payment
4. Receive your access code
5. Enter the code to unlock exams

Free Exams:
- First 2 exams are always free for users without access codes
- Unlimited attempts on free exams
''';
  }

  String _getAccountHelpText() {
    return '''
Account Management:

Profile Settings:
- View your profile information
- Update personal details
- Manage notification preferences

Security:
- Your account is secured with device ID
- No password required (device-based authentication)
- Contact support if you need to change devices

Data Management:
- View your exam history
- Track your progress
- Export your results
- Delete your account if needed

Privacy:
- Your data is encrypted and secure
- We don't share your information
- You can request data deletion anytime
''';
  }
}
