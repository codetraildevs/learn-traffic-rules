import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/screens/user/available_exams_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/free_exam_model.dart';
import '../../services/user_management_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';

class PaymentInstructionsScreen extends StatefulWidget {
  const PaymentInstructionsScreen({super.key});

  @override
  State<PaymentInstructionsScreen> createState() =>
      _PaymentInstructionsScreenState();
}

class _PaymentInstructionsScreenState extends State<PaymentInstructionsScreen> {
  final UserManagementService _userManagementService = UserManagementService();
  PaymentInstructionsData? _paymentData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPaymentInstructions();
  }

  Future<void> _loadPaymentInstructions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      debugPrint('🔍 DEBUG: Loading payment instructions...');
      final response = await _userManagementService.getPaymentInstructions();
      debugPrint(
        '🔍 DEBUG: Payment instructions response: ${response.success}',
      );
      debugPrint('🔍 DEBUG: Payment instructions data: ${response.data}');

      if (response.success) {
        setState(() {
          _paymentData = response.data;
          _isLoading = false;
        });
        debugPrint('🔍 DEBUG: Payment data loaded successfully');
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
        debugPrint(
          '🔍 DEBUG: Payment instructions failed: ${response.message}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🔍 DEBUG: Payment instructions error: $e');
      debugPrint('🔍 DEBUG: Stack trace: $stackTrace');
      setState(() {
        _error = 'Failed to load payment instructions: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Plans',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
          ? _buildErrorWidget()
          : _buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.w, color: Colors.red),
          SizedBox(height: 16.h),
          Text(
            'Error Loading Payment Plans',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _error!,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          CustomButton(
            text: 'Retry',
            onPressed: _loadPaymentInstructions,
            width: 120.w,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_paymentData == null) return const SizedBox();

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          SizedBox(height: 8.h),

          // Quick Access to Free Exams
          _buildQuickAccessSection(),

          SizedBox(height: 8.h),

          // Simplified Payment Steps
          _buildSimplifiedPaymentSteps(),

          SizedBox(height: 8.h),

          // Payment Plans
          _buildPaymentTiers(),

          SizedBox(height: 8.h),

          // Contact Admin
          _buildContactInfo(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.white, size: 18.w),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  _paymentData!.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Add a visible indicator that changes are applied
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'OPTIMIZED',
                  style: TextStyle(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            _paymentData!.description,
            style: TextStyle(fontSize: 10.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: Colors.white, size: 20.w),
              SizedBox(width: 6.w),
              Text(
                'Start Learning Now',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'You can start with FREE practice exams while you get your access code!',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white70,
              height: 1.2,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to available exams
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AvailableExamsScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.quiz, size: 14.w),
                  label: const Text('Take Free Exams'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2196F3),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimplifiedPaymentSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to Get Full Access',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8.h),
        _buildSimpleStepItem(
          '1',
          'Choose a Plan',
          'Select from 1 Month =30 days, 3 Months = 90 days, or 6 Months = 180 days',
          Icons.credit_card,
        ),
        SizedBox(height: 8.h),
        _buildSimpleStepItem(
          '2',
          'Make Payment',
          'Send money via MoMo using the payment code provided after selecting a plan',
          Icons.payment,
        ),
        SizedBox(height: 8.h),
        _buildSimpleStepItem(
          '3',
          'Get Access Code',
          'Contact admin if exams access is not granted after payment in 5-10 minutes',
          Icons.vpn_key,
        ),
      ],
    );
  }

  Widget _buildSimpleStepItem(
    String number,
    String title,
    String description,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Icon(icon, size: 20.w, color: const Color(0xFF2E7D32)),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                    height: 1.2,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTiers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8.h),
        // Show only the first 3 payment tiers in a simplified format
        ..._paymentData!.paymentTiers
            .take(3)
            .map((tier) => _buildSimplePaymentTierCard(tier)),
      ],
    );
  }

  Widget _buildSimplePaymentTierCard(PaymentTier tier) {
    final isPopular = tier.amount == 1500; // 1 month plan

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isPopular ? const Color(0xFF2E7D32) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isPopular ? const Color(0xFF2E7D32) : Colors.grey[300]!,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isPopular)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                'POPULAR',
                style: TextStyle(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          if (isPopular) SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.formattedAmount,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isPopular ? Colors.white : Colors.grey[800],
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  tier.durationText,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isPopular ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _selectPlan(tier),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPopular
                  ? Colors.white
                  : const Color(0xFF2E7D32),
              foregroundColor: isPopular
                  ? const Color(0xFF2E7D32)
                  : Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            child: Text('Select', style: TextStyle(fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_phone, color: Colors.blue[700], size: 20.w),
              SizedBox(width: 6.w),
              Text(
                'Contact Admin',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'After making payment, contact admin to verify and get your access code:',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
              height: 1.3,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _makeCall(_paymentData!.contactInfo.phone),
                  icon: Icon(Icons.phone, size: 16.w),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _openWhatsApp(_paymentData!.contactInfo.whatsapp),
                  icon: Icon(Icons.chat, size: 16.w),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectPlan(PaymentTier tier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Selected Plan: ${tier.formattedAmount}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: ${tier.formattedAmount}\nDuration: ${tier.durationText}',
            ),
            SizedBox(height: 16.h),
            Text(
              'To pay via MoMo, dial this code *182*8*1*888085*${tier.amount}#:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '*182*8*1*888085*${tier.amount}#',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        _copyToClipboard('*182*8*1*888085*${tier.amount}#'),
                    icon: Icon(Icons.copy, color: Colors.blue[600]),
                    tooltip: 'Copy  Code',
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'After payment, contact admin to verify and get your access code.',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _dialMoMoPayment(tier.amount);
            },
            child: const Text('Dial MoMo'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _contactAdmin();
            },
            child: const Text('Contact Admin'),
          ),
        ],
      ),
    );
  }

  void _makeCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _openWhatsApp(String phoneNumber) async {
    // Use the specific admin WhatsApp number
    const cleanNumber = '250780494000';
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');

    debugPrint('🔍 WhatsApp URL: $whatsappUri');
    debugPrint('🔍 Original phone: $phoneNumber');
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WhatsApp not available. Try these alternatives:'),
                  SizedBox(height: 4.h),
                  const Text('• Call: +250780494000'),
                  const Text('• WhatsApp Web: web.whatsapp.com'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Call Instead',
                textColor: Colors.white,
                onPressed: () => _makeCall('+250780494000'),
              ),
            ),
          );
        }
      }
    }
  }

  void _contactAdmin() async {
    const phoneNumber = '+250788123456';
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch phone app'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _dialMoMoPayment(int amount) async {
    final usdCode = '*182*8*1*888085*$amount#';
    final Uri usdUri = Uri(scheme: 'tel', path: usdCode);

    if (await canLaunchUrl(usdUri)) {
      await launchUrl(usdUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch phone app. Please dial: $usdCode'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
