import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/privacy_policy_modal.dart';
import '../../services/device_service.dart';
import '../../services/debug_service.dart';
import '../../services/flash_message_service.dart';
import 'package:flash_message/flash_message.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  final String _selectedRole = 'USER';
  String? _deviceId;
  String? _deviceModel;
  String? _platformName;

  @override
  void initState() {
    super.initState();
    _initializeDeviceInfo();
    // Pre-fill for testing
    _fullNameController.text = '';
    _phoneController.text = '';
  }

  Future<void> _initializeDeviceInfo() async {
    try {
      DebugService.logUserAction(
        'Initializing device info for registration',
        null,
      );

      final deviceService = DeviceService();
      _deviceId = await deviceService.getDeviceId();
      _deviceModel = await deviceService.getDeviceModel();
      _platformName = deviceService.getPlatformName();

      DebugService.logDeviceInfo({
        'deviceId': _deviceId,
        'deviceModel': _deviceModel,
        'platformName': _platformName,
        'context': 'registration',
      });

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      DebugService.logError(
        'Device info initialization failed for registration',
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
        'context': 'registration',
      });

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showPhoneNumberDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.phone, color: AppColors.secondary, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                'Need Help?',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.secondary,
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
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone, color: AppColors.secondary, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      '+250 788 659 575',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.secondary,
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
                              backgroundColor: AppColors.secondary,
                              action: SnackBarAction(
                                label: 'Copy',
                                onPressed: () {},
                                // Copy functionality could be added
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
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number: +250 788 659 575'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
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

  Future<void> _handleRegister() async {
    // Prevent multiple simultaneous registration attempts
    if (_isLoading) return;

    DebugService.logUserAction('Register button clicked', {
      'fullName': _fullNameController.text.isNotEmpty,
      'phoneNumber': _phoneController.text.isNotEmpty,
      'selectedRole': _selectedRole,
      'deviceId': _deviceId,
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      DebugService.logFormValidation('Register Form', {
        'fullName': {
          'valid':
              _fullNameController.text.length >= AppConstants.minNameLength,
          'message':
              'Full name must be at least ${AppConstants.minNameLength} characters',
        },
        'phoneNumber': {
          'valid': _phoneController.text.length >= 10,
          'message': 'Please enter a valid phone number',
        },
      });

      AppFlashMessage.show(
        context: context,
        message: 'Please check your information',
        description: 'Make sure all fields are filled correctly',
        type: FlashMessageType.warning,
      );
      return;
    }

    // Use fallback device ID if not available
    final deviceId =
        _deviceId ?? 'unknown_device_${DateTime.now().millisecondsSinceEpoch}';

    DebugService.logAuthEvent('Registration attempt started', {
      'deviceId': deviceId,
      'fullName': _fullNameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'role': _selectedRole,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Set loading state immediately
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final request = RegisterRequest(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        deviceId: deviceId,
        role: _selectedRole,
      );

      DebugService.logApiCall(
        'POST',
        '/api/auth/register',
        requestData: {
          'deviceId': deviceId,
          'fullName': _fullNameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'role': _selectedRole,
        },
      );

      final success = await ref.read(authProvider.notifier).register(request);

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          DebugService.logAuthEvent('Registration successful', {
            'deviceId': deviceId,
            'fullName': _fullNameController.text.trim(),
            'phoneNumber': _phoneController.text.trim(),
            'role': _selectedRole,
            'timestamp': DateTime.now().toIso8601String(),
          });

          AppFlashMessage.show(
            context: context,
            message: 'Registration Successful!',
            description: 'Welcome to Traffic Rules Master! You can now login.',
            type: FlashMessageType.success,
            duration: const Duration(seconds: 3),
          );

          // Navigate back to login screen after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        } else {
          final error = ref.read(authProvider).error;

          DebugService.logAuthEvent('Registration failed', {
            'deviceId': deviceId,
            'fullName': _fullNameController.text.trim(),
            'phoneNumber': _phoneController.text.trim(),
            'role': _selectedRole,
            'error': error,
            'timestamp': DateTime.now().toIso8601String(),
          });

          // Show enhanced error message with specific handling for common errors
          String errorMessage = 'Registration Failed';
          String errorDescription =
              'Please check your information and try again';
          String errorIcon = '❌';

          // Debug the actual error message
          debugPrint('🔍 REGISTER ERROR DEBUG:');
          debugPrint('   Raw error: $error');
          debugPrint('   Error type: ${error.runtimeType}');

          // Handle specific error cases with comprehensive pattern matching
          final errorString = error?.toString().toLowerCase() ?? '';

          if (errorString.contains('phone number is already registered') ||
              errorString.contains('phone number is already') ||
              errorString.contains('phone already exists') ||
              errorString.contains('user already exists') ||
              errorString.contains('phone number already')) {
            errorMessage = 'Phone Number Already Registered';
            errorDescription =
                'This phone number is already registered. Please login instead.';
            errorIcon = '📱';
          } else if (errorString.contains('device is already registered') ||
              errorString.contains('device already registered') ||
              errorString.contains('device is already') ||
              errorString.contains('device already exists') ||
              errorString.contains('device already used') ||
              errorString.contains('device binding') ||
              errorString.contains('device conflict')) {
            errorMessage = 'Device Already Registered';
            errorDescription =
                'This device is already registered to another account.\n\n'
                'You can only have one account per device for security reasons.\n\n'
                'Please login with the existing account instead of creating a new one.';
            errorIcon = '📱';
          } else if (errorString.contains('invalid phone') ||
              errorString.contains('phone number invalid') ||
              errorString.contains('invalid phone number')) {
            errorMessage = 'Invalid Phone Number';
            errorDescription =
                'Please enter a valid phone number (10 digits starting with 07).';
            errorIcon = '📞';
          } else if (errorString.contains('name too short') ||
              errorString.contains('invalid name') ||
              errorString.contains('name required')) {
            errorMessage = 'Invalid Name';
            errorDescription =
                'Please enter a valid full name (at least 3 characters).';
            errorIcon = '✏️';
          } else if (errorString.contains('network') ||
              errorString.contains('connection') ||
              errorString.contains('timeout') ||
              errorString.contains('unreachable')) {
            errorMessage = 'Network Error';
            errorDescription =
                'Please check your internet connection and try again.';
            errorIcon = '🌐';
          } else if (errorString.contains('server') ||
              errorString.contains('api error') ||
              errorString.contains('internal server') ||
              errorString.contains('500')) {
            errorMessage = 'Server Error';
            errorDescription =
                'There was a problem with the server. Please try again in a few moments.';
            errorIcon = '⚠️';
          } else if (errorString.contains('rate limit') ||
              errorString.contains('too many requests') ||
              errorString.contains('429')) {
            errorMessage = 'Too Many Requests';
            errorDescription =
                'You are making requests too quickly. Please wait a moment and try again.';
            errorIcon = '⏱️';
          } else if (errorString.contains('unauthorized') ||
              errorString.contains('forbidden') ||
              errorString.contains('401') ||
              errorString.contains('403')) {
            errorMessage = 'Access Denied';
            errorDescription =
                'You do not have permission to perform this action.';
            errorIcon = '🔐';
          } else {
            // Generic error with the actual error message
            errorMessage = 'Registration Failed';
            errorDescription =
                error?.toString() ??
                'Please check your information and try again';
            errorIcon = '❌';
          }

          AppFlashMessage.show(
            context: context,
            message: '$errorMessage $errorIcon',
            description: errorDescription,
            type: FlashMessageType.error,
            duration: const Duration(seconds: 8),
            onTap:
                (errorString.contains('phone number is already registered') ||
                    errorString.contains('phone number is already') ||
                    errorString.contains('phone already exists') ||
                    errorString.contains('user already exists') ||
                    errorString.contains('phone number already') ||
                    errorString.contains('device is already registered') ||
                    errorString.contains('device already registered') ||
                    errorString.contains('device is already') ||
                    errorString.contains('device already exists') ||
                    errorString.contains('device already used') ||
                    errorString.contains('device binding') ||
                    errorString.contains('device conflict'))
                ? () {
                    // Show confirmation dialog before navigating to login
                    _showLoginConfirmationDialog();
                  }
                : null,
          );
        }
      }
    } catch (e, stackTrace) {
      DebugService.logError('Registration network error', e, stackTrace);

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
              // Creative Header with Traffic Rules SVG Illustration
              Column(
                children: [
                  SizedBox(height: 20.h),

                  // App Title with Creative Styling
                  Text(
                    'Create Account For Free',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),

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

              SizedBox(height: 8.h),

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
                          color: AppColors.secondary,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Important Information',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Fill in your details below to create your account. Your device will be automatically detected for security purposes.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey700,
                        fontSize: 13.sp,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 8.h),
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

              SizedBox(height: 16.h),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10.w),
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.1),
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
                        'Fill in your details below to create your account.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey600,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // Full Name Field
                      CustomTextField(
                        controller: _fullNameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Full name is required';
                          }
                          if (value.length < AppConstants.minNameLength) {
                            return 'Name must be at least ${AppConstants.minNameLength} characters';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 12.h),

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

                      SizedBox(height: 16.h),

                      // Register Button
                      CustomButton(
                        text: 'Create Account',
                        icon: Icons.person_add,
                        onPressed: _isLoading ? null : _handleRegister,
                        isLoading: _isLoading,
                        height: 50.h,
                        backgroundColor: AppColors.primary,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              // Login Link with Creative Design
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey700,
                      fontSize: 14.sp,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Sign In',
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
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.grey200, width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      'By creating an account, you agree to our',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey600,
                        fontSize: 12.sp,
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
      fullPolicyUrl: 'https://traffic.cyangugudims.com/terms-conditions',
    );
  }

  // Show Login Confirmation Dialog
  void _showLoginConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.login, color: AppColors.primary, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                'Go to Login',
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
                'It looks like you already have an account on this device.',
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
                        SizedBox(width: 6.w),
                        Text(
                          'What to do:',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '• Use the same phone number you registered with\n'
                      '• Your device is already linked to your account\n'
                      '• Just enter your phone number to login',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Stay Here',
                style: AppTextStyles.link.copyWith(color: AppColors.grey600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pop(context); // Go back to login screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: const Text('Go to Login'),
            ),
          ],
        );
      },
    );
  }
}
