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

  // late AnimationController _logoController;
  // late AnimationController _formController;
  // late Animation<double> _logoAnimation;
  // late Animation<double> _formAnimation;
  // late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    //_initializeAnimations();
    _initializeDeviceInfo();
    // Pre-fill for testing - using admin account
    // Admin: 0729111458 (bypasses device ID validation)
    _phoneController.text = '';
  }

  // void _initializeAnimations() {
  //   _logoController = AnimationController(
  //     duration: const Duration(milliseconds: 1500),
  //     vsync: this,
  //   );

  //   _formController = AnimationController(
  //     duration: const Duration(milliseconds: 800),
  //     vsync: this,
  //   );

  //   _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
  //     CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
  //   );

  //   _formAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
  //     CurvedAnimation(parent: _formController, curve: Curves.easeInOut),
  //   );

  //   _slideAnimation =
  //       Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
  //         CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
  //       );

  //   // Start animations
  //   _logoController.forward();
  //   Future.delayed(const Duration(milliseconds: 500), () {
  //     _formController.forward();
  //   });
  // }

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
                      '+250 780 494 000',
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
                  const phoneNumber = '+250780494000';
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
                                'Phone number: +250 780 494 000',
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
                        content: Text('Phone number: +250 780 494 000'),
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

          AppFlashMessage.show(
            context: context,
            message: 'Login Successful!',
            description: 'Welcome back to Traffic Rules Master',
            type: FlashMessageType.success,
            duration: const Duration(seconds: 2),
          );
          // Navigation will be handled by main.dart automatically
        } else {
          final error = ref.read(authProvider).error;

          DebugService.logAuthEvent('Login failed', {
            'deviceId': deviceId,
            'error': error,
            'timestamp': DateTime.now().toIso8601String(),
          });

          // Check for specific error types and provide clear messages
          String errorMessage;
          String errorDescription;
          String errorIcon;

          if (error?.contains('Invalid phone number or device ID') == true) {
            errorIcon = '📱';
            errorMessage = 'Device Mismatch $errorIcon';
            errorDescription =
                'This phone number is registered on a different device.\n\n'
                'Solutions:\n'
                '• Use the same device you registered with\n'
                '• Create a new account with "Create Account" button\n'
                '• Contact support if you need device change';
          } else if (error?.contains('🌐') == true) {
            errorIcon = '🌐';
            errorMessage = 'Network Error $errorIcon';
            errorDescription = error ?? 'Please check your internet connection';
          } else if (error?.contains('⚠️') == true) {
            errorIcon = '⚠️';
            errorMessage = 'Warning $errorIcon';
            errorDescription = error ?? 'Please check your input';
          } else if (error?.contains('🔐') == true) {
            errorIcon = '🔐';
            errorMessage = 'Authentication Error $errorIcon';
            errorDescription = error ?? 'Please check your credentials';
          } else if (error?.contains('📱') == true) {
            errorIcon = '📱';
            errorMessage = 'Device Error $errorIcon';
            errorDescription = error ?? 'Please check your device';
          } else if (error?.contains('⏱️') == true) {
            errorIcon = '⏱️';
            errorMessage = 'Timeout Error $errorIcon';
            errorDescription = error ?? 'Request timed out, please try again';
          } else {
            errorIcon = '❌';
            errorMessage = 'Login Failed $errorIcon';
            errorDescription =
                error ?? 'Please check your credentials and try again';
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
                      'LEARN TRAFFIC RULES',
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
                      'New user? Tap "Create Account" below. Already have an account? Tap "Sign In" to continue.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey700,
                        fontSize: 13.sp,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
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
                        GestureDetector(
                          onTap: () async {
                            try {
                              const phoneNumber = '+250780494000';
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
                            '+250 780 494 000',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
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

              // Animated Login Form
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

              SizedBox(height: 30.h),

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
          'Learn Traffic Rules is an educational application designed to help users prepare for provisional driving license examinations. This app is not affiliated with any government agency and serves as a practice tool only.\n\n'
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
          'By using Learn Traffic Rules, you agree to these terms:\n\n'
          'Educational Purpose: This app is designed for educational practice only and is not affiliated with any government agency or official driving examination body.\n\n'
          'User Responsibilities:\n'
          '• Provide accurate information during registration\n'
          '• Use the app for educational purposes only\n'
          '• Respect intellectual property rights\n'
          '• Not attempt to reverse engineer the app\n\n'
          'Service Availability: We strive to maintain service availability but cannot guarantee uninterrupted access.\n\n'
          'Account Termination: You may delete your account at any time. We reserve the right to suspend accounts that violate these terms.',
      fullPolicyUrl: 'https://traffic.cyangugudims.com/privacy-policy',
    );
  }

  // Show Privacy Policy Dialog
  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
            SizedBox(width: 8.w),
            Text(
              'Privacy Policy',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Learn Traffic Rules - Privacy Policy',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              const Text(
                'This educational app is designed to help you learn traffic rules and prepare for driving tests.',
                style: AppTextStyles.bodyMedium,
              ),
              SizedBox(height: 12.h),
              Text(
                'Data Collection:',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              const Text(
                '• We collect minimal information necessary for educational purposes\n'
                '• Your learning progress and quiz scores\n'
                '• Device information for app functionality\n'
                '• No personal identification or sensitive data',
                style: AppTextStyles.bodySmall,
              ),
              SizedBox(height: 12.h),
              Text(
                'Data Use:',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              const Text(
                '• Educational progress tracking\n'
                '• App improvement and features\n'
                '• Technical support\n'
                '• We do not share your data with third parties',
                style: AppTextStyles.bodySmall,
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'This is a private educational tool and is not affiliated with any government agency.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: AppTextStyles.button.copyWith(color: AppColors.grey600),
            ),
          ),
        ],
      ),
    );
  }

  // Show Terms & Conditions Dialog
  void _showTermsConditionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.description_outlined, color: AppColors.primary),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Terms & Conditions',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Learn Traffic Rules - Terms & Conditions',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Educational Purpose:',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              const Text(
                'This app is designed solely for educational purposes to help you learn traffic rules and practice for driving examinations.',
                style: AppTextStyles.bodySmall,
              ),
              SizedBox(height: 12.h),
              Text(
                'Important Disclaimers:',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              const Text(
                '• This app is NOT affiliated with any government agency \n'
                '• This app does NOT provide official driving licenses\n'
                '• This app does NOT guarantee passing any examination\n'
                '• You must complete official government procedures',
                style: AppTextStyles.bodySmall,
              ),
              SizedBox(height: 12.h),
              Text(
                'User Responsibilities:',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              const Text(
                '• Use for educational purposes only\n'
                '• Complete official procedures for licenses\n'
                '• Verify information with official sources\n'
                '• Follow local traffic laws and regulations',
                style: AppTextStyles.bodySmall,
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'This is a private educational tool. Always verify information with official government sources.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: AppTextStyles.button.copyWith(color: AppColors.grey600),
            ),
          ),
        ],
      ),
    );
  }
}
