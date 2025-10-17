import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
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
    // Pre-fill for testing - using admin account
    // Admin: 0729111458 (bypasses device ID validation)
    _phoneController.text = '';
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _formAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
        );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _formController.forward();
    });
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
    // For admin users, we'll use the actual device ID to bypass device validation
    // For regular users, device ID validation is still enforced
    final deviceId =
        _deviceId ?? 'unknown_device_${DateTime.now().millisecondsSinceEpoch}';

    DebugService.logAuthEvent('Login attempt started', {
      'deviceId': deviceId,
      'hasPhone': true,
      'timestamp': DateTime.now().toIso8601String(),
    });

    setState(() => _isLoading = true);

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
          // Navigation will be handled by the main app
        } else {
          final error = ref.read(authProvider).error;

          DebugService.logAuthEvent('Login failed', {
            'deviceId': deviceId,
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
            message: 'Login Failed $errorIcon',
            description: error ?? 'Please check your credentials and try again',
            type: FlashMessageType.error,
            duration: const Duration(seconds: 6),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FF), // Light purple background
              Color(0xFFE8E3FF), // Slightly darker purple
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
                          // Traffic Rules SVG Illustration Container
                          //                           Container(
                          //                             width: 350.w,
                          //                             height: 180.h,
                          //                             decoration: BoxDecoration(
                          //                               color: Colors.white,
                          //                               borderRadius: BorderRadius.circular(24.r),
                          //                               boxShadow: [
                          //                                 BoxShadow(
                          //                                   color: AppColors.primary.withValues(
                          //                                     alpha: 0.1,
                          //                                   ),
                          //                                   blurRadius: 20,
                          //                                   offset: const Offset(0, 10),
                          //                                 ),
                          //                               ],
                          //                             ),
                          //                             child: Center(
                          //                               child: Padding(
                          //                                 padding: EdgeInsets.all(8.w),
                          //                                 child: SvgPicture.string(
                          //                                   '''
                          // <svg width="220" height="150" viewBox="0 0 220 150" fill="none" xmlns="http://www.w3.org/2000/svg">
                          //   <!-- Road -->
                          //   <rect x="90" y="60" width="40" height="80" rx="20" fill="#E0E0E0"/>
                          //   <rect x="108" y="60" width="4" height="80" fill="#FFF"/>
                          //   <rect x="108" y="70" width="4" height="10" fill="#FFD600"/>
                          //   <rect x="108" y="90" width="4" height="10" fill="#FFD600"/>
                          //   <rect x="108" y="110" width="4" height="10" fill="#FFD600"/>
                          //   <rect x="108" y="130" width="4" height="10" fill="#FFD600"/>
                          //   <!-- Stop Sign -->
                          //   <g>
                          //     <polygon points="50,40 58,32 70,32 78,40 78,52 70,60 58,60 50,52" fill="#E53935" stroke="#B71C1C" stroke-width="2"/>
                          //     <text x="64" y="48" text-anchor="middle" font-size="10" font-family="Arial" fill="#FFF" font-weight="bold">STOP</text>
                          //   </g>
                          //   <!-- Traffic Light -->
                          //   <g>
                          //     <rect x="160" y="30" width="18" height="48" rx="6" fill="#333"/>
                          //     <circle cx="169" cy="40" r="5" fill="#E53935"/>
                          //     <circle cx="169" cy="54" r="5" fill="#FFD600"/>
                          //     <circle cx="169" cy="68" r="5" fill="#43A047"/>
                          //   </g>
                          //   <!-- Pedestrian Crossing -->
                          //   <g>
                          //     <rect x="90" y="120" width="40" height="6" fill="#FFF"/>
                          //     <rect x="90" y="122" width="40" height="2" fill="#BDBDBD"/>
                          //     <rect x="92" y="120" width="4" height="6" fill="#BDBDBD"/>
                          //     <rect x="100" y="120" width="4" height="6" fill="#BDBDBD"/>
                          //     <rect x="108" y="120" width="4" height="6" fill="#BDBDBD"/>
                          //     <rect x="116" y="120" width="4" height="6" fill="#BDBDBD"/>
                          //     <rect x="124" y="120" width="4" height="6" fill="#BDBDBD"/>
                          //   </g>
                          //   <!-- Car -->
                          //   <g>
                          //     <rect x="120" y="100" width="28" height="14" rx="4" fill="#1976D2"/>
                          //     <rect x="124" y="104" width="8" height="6" rx="2" fill="#90CAF9"/>
                          //     <rect x="134" y="104" width="8" height="6" rx="2" fill="#90CAF9"/>
                          //     <circle cx="126" cy="116" r="3" fill="#424242"/>
                          //     <circle cx="142" cy="116" r="3" fill="#424242"/>
                          //   </g>
                          // </svg>
                          //                                   ''',
                          //                                   width: 220.w,
                          //                                   height: 150.h,
                          //                                 ),
                          //                               ),
                          //                             ),
                          //                           ),
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
                                  AppColors.primary,
                                  AppColors.secondary,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(25.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Text(
                              'LEARN TRAFFIC RULES',
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

                SizedBox(height: 10.h),

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
                        'If you are new to this application, click the "Register" button below. If you already have an account, click "Login" to continue your learning journey.',
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
                            color: AppColors.primary,
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
                                color: AppColors.primary,
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

                SizedBox(height: 20.h),

                // Animated Login Form
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _formAnimation,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.w),
                      padding: EdgeInsets.all(28.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
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
                            SizedBox(height: 8.h),

                            Text(
                              'Enter your phone number to continue',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.grey600,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: 20.h),

                            // Device Info Display with Creative Design

                            // Phone Number Field with Enhanced Design
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
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
                                  if (value.length < 10) {
                                    return 'Please enter a valid phone number';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            SizedBox(height: 20.h),

                            // Login Button with Enhanced Design
                            Container(
                              height: 56.h,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.secondary,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: CustomButton(
                                  text: 'Sign In',
                                  icon: Icons.login,
                                  onPressed: _isLoading ? null : _handleLogin,
                                  isLoading: _isLoading,
                                  height: 56.h,
                                  backgroundColor: Colors.transparent,
                                  textColor: Colors.white,
                                  //alignment: MainAxisAlignment.center, // If CustomButton supports alignment
                                ),
                              ),
                            ),

                            SizedBox(height: 10.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 10.h),

                // Register Link with Creative Design
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.secondary.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
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
                        'By using this app, you agree to our',
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
                            onPressed: () => _launchPrivacyPolicy(),
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
                            onPressed: () => _launchTermsConditions(),
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

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Launch Privacy Policy
  void _launchPrivacyPolicy() async {
    try {
      // You can replace this with your actual privacy policy URL
      const privacyPolicyUrl = 'https://your-website.com/privacy-policy';

      if (await canLaunchUrl(Uri.parse(privacyPolicyUrl))) {
        await launchUrl(
          Uri.parse(privacyPolicyUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback: Show privacy policy in a dialog
        _showPrivacyPolicyDialog();
      }
    } catch (e) {
      // Fallback: Show privacy policy in a dialog
      _showPrivacyPolicyDialog();
    }
  }

  // Launch Terms & Conditions
  void _launchTermsConditions() async {
    try {
      // You can replace this with your actual terms & conditions URL
      const termsUrl = 'https://your-website.com/terms-conditions';

      if (await canLaunchUrl(Uri.parse(termsUrl))) {
        await launchUrl(
          Uri.parse(termsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback: Show terms & conditions in a dialog
        _showTermsConditionsDialog();
      }
    } catch (e) {
      // Fallback: Show terms & conditions in a dialog
      _showTermsConditionsDialog();
    }
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
            Text(
              'Terms & Conditions',
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
                '• This app is NOT affiliated with any government agency\n'
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
