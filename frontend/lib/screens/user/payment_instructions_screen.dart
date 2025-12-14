import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/screens/user/available_exams_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../models/free_exam_model.dart';
import '../../services/user_management_service.dart';
import '../../services/network_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../l10n/app_localizations.dart';

class PaymentInstructionsScreen extends StatefulWidget {
  final PaymentInstructions? cachedInstructions;

  const PaymentInstructionsScreen({super.key, this.cachedInstructions});

  @override
  State<PaymentInstructionsScreen> createState() =>
      _PaymentInstructionsScreenState();
}

class _PaymentInstructionsScreenState extends State<PaymentInstructionsScreen> {
  final UserManagementService _userManagementService = UserManagementService();
  final NetworkService _networkService = NetworkService();
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

      // First, try to use cached instructions if provided
      if (widget.cachedInstructions != null) {
        debugPrint('🔍 Using cached payment instructions');
        _paymentData = _convertPaymentInstructionsToData(
          widget.cachedInstructions!,
        );
        setState(() {
          _isLoading = false;
        });
        // Still try to load from API in background if online (for updates)
        _loadPaymentInstructionsFromAPI();
        return;
      }

      // Try to load from offline storage first
      final offlineData = await _loadPaymentInstructionsOffline();
      if (offlineData != null) {
        debugPrint('🔍 Using offline payment instructions');
        setState(() {
          _paymentData = offlineData;
          _isLoading = false;
        });
        // Still try to load from API in background if online (for updates)
        _loadPaymentInstructionsFromAPI();
        return;
      }

      // If no cached/offline data, load from API
      await _loadPaymentInstructionsFromAPI();
    } catch (e, stackTrace) {
      debugPrint('🔍 DEBUG: Payment instructions error: $e');
      debugPrint('🔍 DEBUG: Stack trace: $stackTrace');

      // If API fails, try to use offline data as fallback
      final offlineData = await _loadPaymentInstructionsOffline();
      if (offlineData != null) {
        debugPrint('🔍 Using offline payment instructions as fallback');
        setState(() {
          _paymentData = offlineData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load payment instructions: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPaymentInstructionsFromAPI() async {
    try {
      final hasInternet = await _networkService.hasInternetConnection();
      if (!hasInternet) {
        debugPrint('🔍 No internet, skipping API load');
        return;
      }

      debugPrint('🔍 Loading payment instructions from API...');
      final response = await _userManagementService.getPaymentInstructions();
      debugPrint('🔍 Payment instructions response: ${response.success}');

      if (response.success) {
        // Store for offline use
        await _storePaymentInstructionsOffline(response.data);

        setState(() {
          _paymentData = response.data;
          _isLoading = false;
        });
        debugPrint('🔍 Payment data loaded successfully from API');
      } else {
        // Don't show error if we have offline data
        if (_paymentData == null) {
          setState(() {
            _error = response.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('🔍 Error loading from API: $e');
      // Don't show error if we have offline data
      if (_paymentData == null && _error == null) {
        setState(() {
          _error = 'Failed to load payment instructions: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Store payment instructions in SharedPreferences for offline access
  Future<void> _storePaymentInstructionsOffline(
    PaymentInstructionsData data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = jsonEncode(data.toJson());
      await prefs.setString('payment_instructions_data', dataJson);
      debugPrint('💾 Stored payment instructions offline');
    } catch (e) {
      debugPrint('❌ Error storing payment instructions: $e');
    }
  }

  /// Load payment instructions from SharedPreferences
  Future<PaymentInstructionsData?> _loadPaymentInstructionsOffline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = prefs.getString('payment_instructions_data');
      if (dataJson != null) {
        final data = jsonDecode(dataJson) as Map<String, dynamic>;
        return PaymentInstructionsData.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error loading payment instructions offline: $e');
      return null;
    }
  }

  /// Convert PaymentInstructions to PaymentInstructionsData
  PaymentInstructionsData _convertPaymentInstructionsToData(
    PaymentInstructions instructions,
  ) {
    return PaymentInstructionsData(
      title: instructions.title,
      description: instructions.description,
      steps: instructions.steps,
      contactInfo: instructions.contactInfo,
      paymentMethods: [], // PaymentInstructions doesn't have paymentMethods
      paymentTiers: instructions.paymentTiers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.paymentPlans,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
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
    final l10n = AppLocalizations.of(context)!;
    // Check if error is due to no internet
    final isNetworkError =
        _error != null &&
        (_error!.toLowerCase().contains('internet') ||
            _error!.toLowerCase().contains('network') ||
            _error!.toLowerCase().contains('connection') ||
            _error!.toLowerCase().contains('status: 0'));

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off : Icons.error_outline,
              size: 64.w,
              color: Colors.red,
            ),
            SizedBox(height: 16.h),
            Text(
              isNetworkError
                  ? l10n.noInternetConnection
                  : l10n.errorLoadingPaymentPlans,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              isNetworkError
                  ? l10n.paymentInstructionsNotAvailableOffline
                  : _error ?? l10n.unknownErrorOccurred,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            CustomButton(
              text: l10n.retry,
              onPressed: _loadPaymentInstructions,
              width: 120.w,
            ),
          ],
        ),
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
          //_buildHeader(),
          SizedBox(height: 8.h),

          // Quick Access to Free Exams
          // _buildQuickAccessSection(),
          SizedBox(height: 8.h),

          // Simplified Payment Steps
          _buildSimplifiedPaymentSteps(),

          SizedBox(height: 8.h),

          // Payment Plans
          _buildPaymentTiers(),

          SizedBox(height: 8.h),

          // Contact Admin
          _buildContactInfo(),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  // Widget _buildHeader() {
  //   return Container(
  //     padding: EdgeInsets.all(8.w),
  //     decoration: BoxDecoration(
  //       gradient: const LinearGradient(
  //         colors: [AppColors.primary, AppColors.secondary],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.circular(8.r),
  //       boxShadow: [
  //         BoxShadow(
  //           color: AppColors.primary.withValues(alpha: 0.1),
  //           blurRadius: 4,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(Icons.star, color: Colors.white, size: 18.w),
  //             SizedBox(width: 4.w),
  //             // Expanded(
  //             //   child: Text(
  //             //     _paymentData!.title,
  //             //     style: TextStyle(
  //             //       fontSize: 14.sp,
  //             //       fontWeight: FontWeight.bold,
  //             //       color: Colors.white,
  //             //     ),
  //             //   ),
  //             // ),
  //             // Add a visible indicator that changes are applied
  //             // Container(
  //             //   padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
  //             //   decoration: BoxDecoration(
  //             //     color: Colors.orange,
  //             //     borderRadius: BorderRadius.circular(4.r),
  //             //   ),
  //             //   child: Text(
  //             //     'OPTIMIZED',
  //             //     style: TextStyle(
  //             //       fontSize: 8.sp,
  //             //       fontWeight: FontWeight.bold,
  //             //       color: Colors.white,
  //             //     ),
  //             //   ),
  //             // ),
  //           ],
  //         ),
  //         SizedBox(height: 4.h),
  //         Text(
  //           _paymentData!.description,
  //           style: TextStyle(fontSize: 10.sp, color: Colors.white70),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildQuickAccessSection() {
  //   return Container(
  //     padding: EdgeInsets.all(12.w),
  //     decoration: BoxDecoration(
  //       gradient: const LinearGradient(
  //         colors: [AppColors.primary, AppColors.secondary],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.circular(10.r),
  //       boxShadow: [
  //         BoxShadow(
  //           color: AppColors.secondary.withValues(alpha: 0.15),
  //           blurRadius: 6,
  //           offset: const Offset(0, 3),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(Icons.school, color: Colors.white, size: 20.w),
  //             SizedBox(width: 6.w),
  //             Text(
  //               'Start Learning Now',
  //               style: TextStyle(
  //                 fontSize: 16.sp,
  //                 fontWeight: FontWeight.bold,
  //                 color: Colors.white,
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: 8.h),
  //         Text(
  //           'You can start with FREE practice exams while you get your access code!',
  //           style: TextStyle(
  //             fontSize: 12.sp,
  //             color: Colors.white70,
  //             height: 1.2,
  //           ),
  //         ),
  //         SizedBox(height: 12.h),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: ElevatedButton.icon(
  //                 onPressed: () {
  //                   // Navigate to available exams
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (context) => const AvailableExamsScreen(),
  //                     ),
  //                   );
  //                 },
  //                 icon: Icon(Icons.quiz, size: 14.w),
  //                 label: const Text('Take Free Exams'),
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.white,
  //                   foregroundColor: const Color(0xFF2196F3),
  //                   padding: EdgeInsets.symmetric(vertical: 8.h),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(6.r),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSimplifiedPaymentSteps() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.howToGetFullAccess,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.sp,

            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8.h),
        _buildSimpleStepItem(
          '1',
          l10n.chooseAPlan,
          'Select from 1 Month =31 days, 3 Months = 93 days, or 6 Months = 186 days',
          Icons.credit_card,
        ),
        SizedBox(height: 8.h),
        _buildSimpleStepItem(
          '2',
          l10n.makePayment,
          'Send money via MoMo using the payment code:329494  after selecting a plan by dialing *182*8*1*329494*FRW#',
          Icons.payment,
        ),
        SizedBox(height: 8.h),
        _buildSimpleStepItem(
          '3',
          l10n.getAccessCode,
          'Contact admin (Alexis:0788659575) or whatsapp (Alexis:0788659575) if exams access is not granted after payment in 5-10 minutes',
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
              color: AppColors.primary,
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
          Icon(icon, size: 20.w, color: AppColors.primary),
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.chooseYourPlan,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16.h),
        // Show payment tiers (up to 3) in a simplified format
        if (_paymentData!.paymentTiers.isNotEmpty)
          ..._paymentData!.paymentTiers
              .take(3)
              .map((tier) => _buildSimplePaymentTierCard(tier))
        else
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              'No payment plans available at the moment.',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildSimplePaymentTierCard(PaymentTier tier) {
    final isPopular = tier.amount == 1500; // 1 month plan

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isPopular ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isPopular ? AppColors.primary : Colors.grey[300]!,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? AppColors.primary.withValues(alpha: 0.15)
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
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                AppLocalizations.of(context)!.popular,
                style: TextStyle(
                  fontSize: 10.sp,
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
              backgroundColor: isPopular ? Colors.white : AppColors.primary,
              foregroundColor: isPopular ? AppColors.primary : Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.select,
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    final l10n = AppLocalizations.of(context)!;
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
              Icon(Icons.contact_phone, color: AppColors.secondary, size: 20.w),
              SizedBox(width: 6.w),
              Text(
                l10n.contactAdmin,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            l10n.afterMakingPaymentContactAdmin,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
              height: 1.3,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Always use the correct phone number
                    _makeCall('+250788659575');
                  },
                  icon: Icon(Icons.phone, size: 16.w),
                  label: Text(l10n.call),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                  label: Text(l10n.whatsapp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectedPlan(tier.formattedAmount)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.amount} ${tier.formattedAmount}\n${l10n.duration} ${tier.durationText}',
            ),
            SizedBox(height: 16.h),
            Text(
              '${l10n.toPayViaMoMoDialThisCode} *182*8*1*329494*${tier.amount}#:',
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
                      '*182*8*1*329494*${tier.amount}#',
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
                        _copyToClipboard('*182*8*1*329494*${tier.amount}#'),
                    icon: Icon(Icons.copy, color: Colors.blue[600]),
                    tooltip: l10n.copyCode,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.afterPaymentContactAdminToVerify,
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
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _dialMoMoPayment(tier.amount);
            },
            child: Text(l10n.dialMoMo),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _contactAdmin();
            },
            child: Text(l10n.contactAlexis),
          ),
        ],
      ),
    );
  }

  void _makeCall(String phoneNumber) async {
    // Check if widget is still mounted before proceeding
    if (!mounted) {
      debugPrint('⚠️ Widget not mounted, skipping call');
      return;
    }

    // Use the correct phone number as primary, or fallback to provided number
    const correctPhoneNumber = '+250788659575';
    final phoneToUse = phoneNumber.isNotEmpty
        ? phoneNumber
        : correctPhoneNumber;

    // Clean the phone number - remove spaces and ensure it starts with +
    String cleanPhone = phoneToUse.replaceAll(' ', '').replaceAll('-', '');
    if (!cleanPhone.startsWith('+')) {
      // If it starts with 0, replace with +250
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '+250${cleanPhone.substring(1)}';
      } else if (cleanPhone.startsWith('250')) {
        cleanPhone = '+$cleanPhone';
      } else {
        cleanPhone = '+250$cleanPhone';
      }
    }

    // If the number contains 123456, replace with correct number
    if (cleanPhone.contains('123456') || cleanPhone.contains('788123')) {
      cleanPhone = correctPhoneNumber;
    }

    debugPrint('📞 Attempting to call: $cleanPhone');
    debugPrint('📞 Original number: $phoneNumber');

    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanPhone);

      // Use platformDefault first - it's safer and won't crash the app
      // This keeps the app in foreground while opening dialer
      try {
        final launched = await launchUrl(
          phoneUri,
          mode: LaunchMode.platformDefault,
        );

        if (launched) {
          debugPrint('✅ Phone call launched successfully');
          // Small delay to ensure the launch completes
          await Future.delayed(const Duration(milliseconds: 100));
        } else {
          throw Exception('Launch returned false');
        }
      } catch (e) {
        debugPrint('⚠️ Platform default failed: $e, trying external');

        // Fallback to externalApplication only if platformDefault fails
        try {
          await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
          debugPrint('✅ Phone call launched with external application');
          // Small delay to ensure the launch completes
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e2) {
          debugPrint('❌ External application also failed: $e2');

          // Final fallback: try with different URI format
          try {
            final Uri altUri = Uri.parse('tel:$cleanPhone');
            await launchUrl(altUri, mode: LaunchMode.platformDefault);
            debugPrint('✅ Phone call launched with alternative URI');
          } catch (e3) {
            debugPrint('❌ All launch methods failed: $e3');
            _showCallError(cleanPhone);
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Unexpected error calling phone: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _showCallError(cleanPhone);
    }
  }

  void _showCallError(String phoneNumber) {
    if (!mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.couldNotLaunchPhoneApp} Number: $phoneNumber',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Copy',
            textColor: Colors.white,
            onPressed: () {
              try {
                Clipboard.setData(ClipboardData(text: phoneNumber));
              } catch (e) {
                debugPrint('❌ Error copying to clipboard: $e');
              }
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing snackbar: $e');
    }
  }

  void _openWhatsApp(String phoneNumber) async {
    // Use the specific admin WhatsApp number
    const cleanNumber = '250788659575';
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
                  Text(AppLocalizations.of(context)!.whatsappNotAvailableTryAlternatives),
                  SizedBox(height: 4.h),
                  Text('• ${AppLocalizations.of(context)!.call}: +250788659575'),
                  Text('• WhatsApp Web: web.whatsapp.com'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: AppLocalizations.of(context)!.callInstead,
                textColor: Colors.white,
                onPressed: () => ('+250788659575'),
              ),
            ),
          );
        }
      }
    }
  }

  void _contactAdmin() async {
    if (!mounted) return;

    const phoneNumber = '+250788659575';

    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

      // Use platformDefault first - safer and won't crash
      try {
        final launched = await launchUrl(
          phoneUri,
          mode: LaunchMode.platformDefault,
        );

        if (launched) {
          debugPrint('✅ Admin call launched successfully');
          await Future.delayed(const Duration(milliseconds: 100));
        } else {
          throw Exception('Launch returned false');
        }
      } catch (e) {
        debugPrint('⚠️ Platform default failed: $e, trying external');
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
        debugPrint('✅ Admin call launched with external application');
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      debugPrint('❌ Error calling admin: $e');
      if (!mounted) return;
      _showCallError(phoneNumber);
    }
  }

  void _copyToClipboard(String text) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.codeCopiedToClipboard),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _dialMoMoPayment(int amount) async {
    final usdCode = '*182*8*1*329494*$amount#';
    final Uri usdUri = Uri(scheme: 'tel', path: usdCode);

    if (await canLaunchUrl(usdUri)) {
      await launchUrl(usdUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.couldNotLaunchPhoneAppPleaseDial} $usdCode'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
