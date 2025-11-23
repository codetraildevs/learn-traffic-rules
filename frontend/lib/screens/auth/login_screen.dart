import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/privacy_policy_modal.dart';
import '../../services/device_service.dart';
import '../../services/debug_service.dart';
import '../../services/flash_message_service.dart';
import 'package:flash_message/flash_message.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _deviceId;
  String? _deviceModel;
  String? _platformName;

  @override
  void initState() {
    super.initState();
    _initializeDeviceInfo();
    // Pre-fill for testing - using admin account
    // Admin: 0729111458 (bypasses device ID validation)
    _phoneController.text = '';
  }

  Future<void> _initializeDeviceInfo() async {
    try {
      DebugService.logUserAction('Initializing device info', null);

      final deviceService = DeviceService();
      _deviceId = await deviceService.getDeviceId();
      _deviceModel = await deviceService.getDeviceModel();
      _platformName = deviceService.getPlatformName();

      DebugService.logDeviceInfo({
        'deviceId': _deviceId,
        'deviceModel': _deviceModel,
        'platformName': _platformName,
      });

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      DebugService.logError(
        'Device info initialization failed',
        e,
        StackTrace.current,
      );

      // Set fallback values
      _deviceId = 'unknown_device_${DateTime.now().millisecondsSinceEpoch}';
      _deviceModel = 'Unknown Device';
      _platformName = 'Unknown Platform';

      DebugService.logDeviceInfo({
        'deviceId': _deviceId,
        'deviceModel': _deviceModel,
        'platformName': _platformName,
        'fallback': true,
      });

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    // _logoController.dispose();
    // _formController.dispose();
    super.dispose();
  }

  void _showPhoneNumberDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.phone, color: AppColors.primary, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                'Need Help?',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact our support team:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.grey700,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone, color: AppColors.primary, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      '+250 788 659 575',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Available 24/7 for your support',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: AppTextStyles.link.copyWith(color: AppColors.grey600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  const phoneNumber = '+250 788 659 575';
                  debugPrint('📞 Attempting to call: $phoneNumber');

                  // Try multiple URL schemes for better Android compatibility
                  debugPrint('📞 Trying multiple phone call methods');
                  // Try tel: scheme first
                  final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(
                      phoneUri,
                      mode: LaunchMode.externalApplication,
                    );
                    debugPrint(
                      '📞 Phone call launched successfully with tel: scheme',
                    );
                  } else {
                    // Try alternative approach with different mode
                    debugPrint(
                      '📞 tel: scheme failed, trying alternative approach',
                    );
                    try {
                      await launchUrl(
                        phoneUri,
                        mode: LaunchMode.platformDefault,
                      );
                      debugPrint(
                        '📞 Phone call launched with platform default mode',
                      );
                    } catch (e) {
                      debugPrint('📞 Platform default failed: $e');
                      // Try with different URI format
                      final Uri altUri = Uri.parse('tel:$phoneNumber');
                      try {
                        await launchUrl(altUri);
                        debugPrint(
                          '📞 Phone call launched with alternative URI format',
                        );
                      } catch (e2) {
                        debugPrint(
                          '📞 All methods failed, showing snackbar: $e2',
                        );
                        // If all methods fail, show a snackbar
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Phone number: +250 788 659 575',
                              ),
                              backgroundColor: AppColors.primary,
                              action: SnackBarAction(
                                label: 'Copy',
                                onPressed: () {
                                  // Copy to clipboard functionality could be added here
                                },
                              ),
                            ),
                          );
                        }
                      }
                    }
                  }
                } catch (e) {
                  debugPrint('📞 Error calling phone: $e');
                  // If still fails, show a snackbar
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Phone number: +250 788 659 575'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: const Text('Call Now'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    // Prevent multiple simultaneous login attempts
    if (_isLoading) return;

    DebugService.logUserAction('Login button clicked', {
      'hasPhone': _phoneController.text.isNotEmpty,
      'phoneLength': _phoneController.text.length,
      'deviceId': _deviceId,
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      DebugService.logFormValidation('Login Form', {
        'phoneNumber': {
          'valid': false,
          'message': 'Phone number validation failed',
        },
      });

      AppFlashMessage.show(
        context: context,
        message: 'Please check your phone number',
        description: 'Please enter a valid phone number',
        type: FlashMessageType.warning,
      );
      return;
    }

    // Use fallback device ID if not available
    final deviceId =
        _deviceId ?? 'unknown_device_${DateTime.now().millisecondsSinceEpoch}';

    DebugService.logAuthEvent('Login attempt started', {
      'deviceId': deviceId,
      'hasPhone': true,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Set loading state immediately
    if (mounted) {
      debugPrint('🔄 Setting loading state to TRUE');
      setState(() => _isLoading = true);
    }

    try {
      final phoneNumber = _phoneController.text.trim();
      final request = LoginRequest(
        phoneNumber: phoneNumber,
        deviceId: deviceId,
      );

      // Debug the actual request data
      debugPrint('🔍 LOGIN REQUEST DEBUG:');
      debugPrint('   phoneNumber: "$phoneNumber"');
      debugPrint('   deviceId: "$deviceId"');
      debugPrint('   request.toJson(): ${request.toJson()}');

      DebugService.logApiCall(
        'POST',
        '/api/auth/login',
        requestData: {
          'deviceId': deviceId,
          'phoneNumber': phoneNumber,
          'phoneLength': phoneNumber.length,
        },
      );

      final success = await ref.read(authProvider.notifier).login(request);

      if (mounted) {
        debugPrint('🔄 Setting loading state to FALSE - Success/Error');
        setState(() => _isLoading = false);

        if (success) {
          DebugService.logAuthEvent('Login successful', {
            'deviceId': deviceId,
            'timestamp': DateTime.now().toIso8601String(),
          });

          // Let main.dart handle navigation automatically
          // The auth state change will trigger the rebuild
        } else {
          final error = ref.read(authProvider).error;

          DebugService.logAuthEvent('Login failed', {
            'deviceId': deviceId,
            'error': error,
            'timestamp': DateTime.now().toIso8601String(),
          });

          // Check for specific error types and provide clear messages
          String errorMessage = 'Login Failed';
          String errorDescription =
              'Please check your credentials and try again';

          // Debug the actual error message
          debugPrint('🔍 LOGIN ERROR DEBUG:');
          debugPrint('   Raw error: $error');
          debugPrint('   Error type: ${error.runtimeType}');

          // Handle specific error cases with comprehensive pattern matching
          final errorString = error?.toString().toLowerCase() ?? '';

          if (errorString.contains('device mismatch') ||
              errorString.contains('device not found') ||
              errorString.contains('device binding') ||
              errorString.contains('device conflict') ||
              errorString.contains('device not registered')) {
            errorMessage = 'Device Mismatch';
            errorDescription =
                'This phone number is registered on a different device.\n\n'
                'Solutions:\n'
                '• Use the same device you registered with\n'
                '• Create a new account with "Create Account" button\n'
                '• Contact support if you need device change';
          } else if (errorString.contains(
            'invalid phone number or device id',
          )) {
            errorMessage = 'Phone Number Not Found';
            errorDescription =
                'This phone number is not registered. Please create an account first.\n\n'
                'If you tried to register and got "device already registered" error, '
                'this means your device is registered but your account doesn\'t exist.\n\n'
                'Please contact support: +250 788 659 575';
          } else if (errorString.contains('invalid phone') ||
              errorString.contains('phone number invalid') ||
              errorString.contains('invalid phone number') ||
              errorString.contains('phone not found') ||
              errorString.contains('user not found')) {
            errorMessage = 'Phone Number Not Found';
            errorDescription =
                'This phone number is not registered. Please create an account first.';
          } else if (errorString.contains('invalid credentials') ||
              errorString.contains('wrong password') ||
              errorString.contains('authentication failed') ||
              errorString.contains('unauthorized') ||
              errorString.contains('401')) {
            errorMessage = 'Invalid Credentials';
            errorDescription = 'Please check your phone number and try again.';
          } else if (errorString.contains('network') ||
              errorString.contains('connection') ||
              errorString.contains('timeout') ||
              errorString.contains('unreachable') ||
              errorString.contains('socketexception')) {
            errorMessage = 'Network Error';
            errorDescription =
                'Please check your internet connection and try again.';
          } else if (errorString.contains('server') ||
              errorString.contains('api error') ||
              errorString.contains('internal server') ||
              errorString.contains('500') ||
              errorString.contains('502') ||
              errorString.contains('503')) {
            errorMessage = 'Server Error';
            errorDescription =
                'There was a problem with the server. Please try again in a few moments.';
          } else if (errorString.contains('rate limit') ||
              errorString.contains('too many requests') ||
              errorString.contains('429')) {
            errorMessage = 'Too Many Requests';
            errorDescription =
                'You are making requests too quickly. Please wait a moment and try again.';
          } else if (errorString.contains('forbidden') ||
              errorString.contains('403')) {
            errorMessage = 'Access Denied';
            errorDescription =
                'You do not have permission to perform this action.';
          } else {
            // Generic error with the actual error message
            errorMessage = 'Login Failed';
            errorDescription =
                error?.toString() ??
                'Please check your credentials and try again';
          }

          AppFlashMessage.show(
            context: context,
            message: errorMessage,
            description: errorDescription,
            type: FlashMessageType.error,
            duration: const Duration(seconds: 8),
          );
        }
      }
    } catch (e, stackTrace) {
      DebugService.logError('Login network error', e, stackTrace);

      if (mounted) {
        setState(() => _isLoading = false);

        AppFlashMessage.show(
          context: context,
          message: 'Network Error',
          description: 'Please check your internet connection and try again',
          type: FlashMessageType.error,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20.h),

              // Creative Header with Traffic Rules SVG Illustration
              Column(
                children: [
                  //SizedBox(height: 20.h),
                  // App Title with Creative Styling
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 19.w,
                      vertical: 6.w,
                    ),

                    child: Text(
                      'Rwanda Traffic Rule 🇷🇼',
                      style: AppTextStyles.heading1.copyWith(
                        color: Colors.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  SizedBox(height: 6.h),

                  Text(
                    'Learn • Practice • Master',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.grey700,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Clean Information Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.grey200, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Important Information',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Already have account? Tap "Sign In" below. New User? Tap "Create Account" to continue.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey700,
                        fontSize: 13.sp,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // Help section with two phone numbers
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          color: AppColors.grey600,
                          size: 14.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Need help? Call ',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey600,
                            fontSize: 13.sp,
                          ),
                        ),
                        // First phone number
                        GestureDetector(
                          onTap: () async {
                            try {
                              const phoneNumber = '+250788659575';
                              final Uri phoneUri = Uri(
                                scheme: 'tel',
                                path: phoneNumber,
                              );
                              if (await canLaunchUrl(phoneUri)) {
                                await launchUrl(
                                  phoneUri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                _showPhoneNumberDialog();
                              }
                            } catch (e) {
                              _showPhoneNumberDialog();
                            }
                          },
                          child: Text(
                            '0788 659 575',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.secondary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          ' / ',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey600,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Second phone number
                        GestureDetector(
                          onTap: () async {
                            try {
                              const phoneNumber = '+250728877442';
                              final Uri phoneUri = Uri(
                                scheme: 'tel',
                                path: phoneNumber,
                              );
                              if (await canLaunchUrl(phoneUri)) {
                                await launchUrl(
                                  phoneUri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                _showPhoneNumberDialog();
                              }
                            } catch (e) {
                              _showPhoneNumberDialog();
                            }
                          },
                          child: Text(
                            '0728 877 442',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.secondary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8.h),

              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Enter your phone number to continue',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey600,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // Phone Number Field
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: 'Enter your phone number',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Phone number is required';
                          }
                          if (value.length < 10) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 40.h),

                      // Login Button
                      CustomButton(
                        text: 'Sign In',
                        icon: Icons.login,
                        onPressed: _isLoading ? null : _handleLogin,
                        isLoading: _isLoading,
                        height: 50.h,
                        backgroundColor: AppColors.primary,
                        textColor: Colors.white,
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              // Register Link with Creative Design
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey700,
                      fontSize: 14.sp,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Create Account',
                      style: AppTextStyles.link.copyWith(
                        color: AppColors.primary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              // Privacy Policy and Terms & Conditions Links
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.grey200, width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      'By using this app, you agree to our',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey600,
                        fontSize: 16.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => _showPrivacyPolicyModal(),
                          child: Text(
                            'Privacy Policy',
                            style: AppTextStyles.link.copyWith(
                              color: AppColors.primary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          ' and ',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey600,
                            fontSize: 12.sp,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showTermsConditionsModal(),
                          child: Text(
                            'Terms & Conditions',
                            style: AppTextStyles.link.copyWith(
                              color: AppColors.primary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

  // Show Privacy Policy Modal
  void _showPrivacyPolicyModal() {
    PrivacyPolicyModal.show(
      context,
      title: 'Privacy Policy',
      content:
          'Rwanda Traffic Rule 🇷🇼 is an educational application designed to help users prepare for provisional driving license examinations.\n\n'
          '⚠️ IMPORTANT: This app is NOT affiliated with, endorsed by, or associated with any government agency, the Government of Rwanda, or any official driving test authority. This is an independent educational tool created for learning purposes only.\n\n'
          'Official Source: For official traffic rules, regulations, and driving license information (including provisional and permanent driving licenses), please refer to Rwanda National Police (Driving License Services): https://police.gov.rw/home/\n\n'
          'We collect minimal data necessary to provide our educational services:\n'
          '• Phone number for account creation and security\n'
          '• Device information for fraud prevention\n'
          '• Learning progress to personalize your experience\n'
          '• App usage data to improve our services\n\n'
          'Your privacy is important to us. We use industry-standard security measures to protect your data and never share your personal information with third parties.',
      fullPolicyUrl: 'https://traffic.cyangugudims.com/privacy-policy',
    );
  }

  // Show Terms & Conditions Modal
  void _showTermsConditionsModal() {
    PrivacyPolicyModal.show(
      context,
      title: 'Terms & Conditions',
      content:
          'By using Rwanda Traffic Rule 🇷🇼, you agree to these terms:\n\n'
          '⚠️ IMPORTANT DISCLAIMER:\n'
          'This app is NOT affiliated with, endorsed by, or associated with any government agency, the Government of Rwanda, or any official driving test authority. This is an independent educational tool created for learning purposes only.\n\n'
          'Official Source: For official traffic rules, regulations, and driving license information (including provisional and permanent driving licenses), please refer to Rwanda National Police (Driving License Services): https://police.gov.rw/home/\n\n'
          'Educational Purpose: This app is designed for educational practice only. While we provide comprehensive study materials, users must complete official government procedures to obtain driving licenses. Always verify information with official sources and consult local authorities.\n\n'
          'User Responsibilities:\n'
          '• Provide accurate information during registration\n'
          '• Use the app for educational purposes only\n'
          '• Respect intellectual property rights\n'
          '• Not attempt to reverse engineer the app\n'
          '• Verify all information with official government sources\n\n'
          'Service Availability: We strive to maintain service availability but cannot guarantee uninterrupted access.\n\n'
          'Account Termination: You may delete your account at any time. We reserve the right to suspend accounts that violate these terms.',
      fullPolicyUrl: 'https://traffic.cyangugudims.com/terms-conditions',
    );
  }
}
