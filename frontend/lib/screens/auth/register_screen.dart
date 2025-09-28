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
  String _selectedRole = 'USER';
  String? _deviceId;
  String? _deviceModel;
  String? _platformName;

  late AnimationController _logoController;
  late AnimationController _formController;
  late Animation<double> _logoAnimation;
  late Animation<double> _formAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDeviceInfo();
    // Pre-fill for testing
    _fullNameController.text = 'Test User';
    _phoneController.text = '1234567890';
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _formAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
        );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _formController.forward();
    });
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
    _logoController.dispose();
    _formController.dispose();
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
                      '+250 780 494 000',
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Phone number: +250 780 494 000',
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
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phone number: +250 780 494 000'),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  }
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

    setState(() => _isLoading = true);

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

          // Show enhanced error message
          final errorIcon = error?.contains('🌐') == true
              ? '🌐'
              : error?.contains('⚠️') == true
              ? '⚠️'
              : error?.contains('🔐') == true
              ? '🔐'
              : error?.contains('📱') == true
              ? '📱'
              : error?.contains('⏱️') == true
              ? '⏱️'
              : '❌';

          AppFlashMessage.show(
            context: context,
            message: 'Registration Failed $errorIcon',
            description: error ?? 'Please check your information and try again',
            type: FlashMessageType.error,
            duration: const Duration(seconds: 6),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0E6FF), // Light purple background
              Color(0xFFE1D5FF), // Slightly darker purple
              Color(0xFFD1C7FF), // Medium purple
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20.h),

                // Creative Header with Traffic Rules SVG Illustration
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: Column(
                        children: [
                          SizedBox(height: 20.h),

                          // App Title with Creative Styling
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.secondary,
                                  AppColors.primary,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(5.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Text(
                              'JOIN OUR COMMUNITY',
                              style: AppTextStyles.heading1.copyWith(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
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
                    );
                  },
                ),

                SizedBox(height: 20.h),

                // Information Section
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE91E63),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'IMPORTANT INFORMATION',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: const Color(0xFFE91E63),
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Fill in your details below to create your account. Your device will be automatically detected for security purposes.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey700,
                          fontSize: 14.sp,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone,
                            color: AppColors.secondary,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Need help? Call ',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.grey700,
                              fontSize: 14.sp,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              try {
                                const phoneNumber = '+250780494000';
                                debugPrint(
                                  '📞 Attempting to call: $phoneNumber',
                                );

                                // Try multiple URL schemes for better Android compatibility
                                debugPrint(
                                  '📞 Trying multiple phone call methods',
                                );
                                // Try tel: scheme first
                                final Uri phoneUri = Uri(
                                  scheme: 'tel',
                                  path: phoneNumber,
                                );

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
                                    debugPrint(
                                      '📞 Platform default failed: $e',
                                    );
                                    // Try with different URI format
                                    final Uri altUri = Uri.parse(
                                      'tel:$phoneNumber',
                                    );
                                    try {
                                      await launchUrl(altUri);
                                      debugPrint(
                                        '📞 Phone call launched with alternative URI format',
                                      );
                                    } catch (e2) {
                                      debugPrint(
                                        '📞 All methods failed, showing dialog: $e2',
                                      );
                                      _showPhoneNumberDialog();
                                    }
                                  }
                                }
                              } catch (e) {
                                debugPrint('📞 Call error: $e');
                                _showPhoneNumberDialog();
                              }
                            },
                            child: Text(
                              '+250 780 494 000',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.secondary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10.h),

                // Animated Registration Form
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _formAnimation,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.w),
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
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
                            /// SizedBox(height: 4.h),
                            Text(
                              'Fill in your details below to create your account.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.info,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.start,
                            ),

                            SizedBox(height: 20.h),
                            // Full Name Field with Enhanced Design
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.1,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CustomTextField(
                                controller: _fullNameController,
                                label: 'Full Name',
                                hint: 'Enter your full name',
                                prefixIcon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Full name is required';
                                  }
                                  if (value.length <
                                      AppConstants.minNameLength) {
                                    return 'Name must be at least ${AppConstants.minNameLength} characters';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            SizedBox(height: 16.h),

                            // Phone Number Field with Enhanced Design
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.1,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CustomTextField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                hint: 'Enter your phone number',
                                prefixIcon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Phone number is required';
                                  }
                                  if (value.length !=
                                      AppConstants.phoneNumberLength) {
                                    return 'Phone number must be ${AppConstants.phoneNumberLength} digits';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            SizedBox(height: 16.h),

                            SizedBox(height: 20.h),

                            // Register Button with Enhanced Design
                            Container(
                              height: 56.h,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.secondary,
                                    AppColors.primary,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CustomButton(
                                text: 'Create Account',
                                icon: Icons.person_add,
                                onPressed: _isLoading ? null : _handleRegister,
                                isLoading: _isLoading,
                                height: 56.h,
                                backgroundColor: Colors.transparent,
                                textColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 10.h),

                // Login Link with Creative Design
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withValues(alpha: 0.1),
                        AppColors.primary.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
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
                            color: AppColors.secondary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
