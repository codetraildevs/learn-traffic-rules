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
import '../../services/network_service.dart';
import '../../l10n/app_localizations.dart';
import 'register_screen.dart';
import '../../screens/home/home_screen.dart';

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
  final NetworkService _networkService = NetworkService();

  @override
  void initState() {
    super.initState();
    // Initialize device info in background (non-blocking)
    _initializeDeviceInfo();
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
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.phone, color: AppColors.primary, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                l10n.needHelp,
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
                l10n.contactSupport,
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
                l10n.available247,
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
                l10n.close,
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
                              content: Text(l10n.phoneNumber),
                              backgroundColor: AppColors.primary,
                              action: SnackBarAction(
                                label: l10n.copy,
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
                      SnackBar(
                        content: Text(l10n.phoneNumber),
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
              child: Text(l10n.callNow),
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

      final l10n = AppLocalizations.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.pleaseCheckPhoneNumber,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  l10n.enterValidPhoneNumber,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
      return;
    }

    // Check internet connection before attempting login
    final hasInternet = await _networkService.hasInternetConnection();
    if (!hasInternet) {
      final l10n = AppLocalizations.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.noInternetConnection,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  l10n.networkError,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
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

          // Wait for auth state to update, then navigate to home screen
          // Poll auth state until it's authenticated (with timeout)
          int attempts = 0;
          const maxAttempts = 10;
          while (attempts < maxAttempts && mounted) {
            await Future.delayed(const Duration(milliseconds: 50));
            final authState = ref.read(authProvider);
            if (authState.status == AuthStatus.authenticated) {
              debugPrint(
                '✅ Auth state confirmed as authenticated, navigating...',
              );
              if (mounted) {
                // Navigate directly to HomeScreen to ensure proper state
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false, // Remove all previous routes
                );
              }
              return;
            }
            attempts++;
          }

          // Fallback: navigate even if state check didn't work (shouldn't happen)
          if (mounted) {
            debugPrint('⚠️ Navigating to dashboard (fallback)');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false, // Remove all previous routes
            );
          }
        } else {
          final error = ref.read(authProvider).error;

          DebugService.logAuthEvent('Login failed', {
            'deviceId': deviceId,
            'error': error,
            'timestamp': DateTime.now().toIso8601String(),
          });

          // Check for specific error types and provide clear messages
          final l10n = AppLocalizations.of(context);
          String errorMessage = l10n.loginFailed;
          String errorDescription = l10n.checkCredentials;

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
            errorMessage = l10n.deviceMismatch;
            errorDescription = l10n.deviceMismatchDescription;
          } else if (errorString.contains(
            'invalid phone number or device id',
          )) {
            errorMessage = l10n.phoneNumberNotFound;
            errorDescription = l10n.phoneNumberNotFoundDescription;
          } else if (errorString.contains('invalid phone') ||
              errorString.contains('phone number invalid') ||
              errorString.contains('invalid phone number') ||
              errorString.contains('phone not found') ||
              errorString.contains('user not found')) {
            errorMessage = l10n.phoneNumberNotFound;
            errorDescription = l10n.phoneNumberNotFoundDescription;
          } else if (errorString.contains('invalid credentials') ||
              errorString.contains('wrong password') ||
              errorString.contains('authentication failed') ||
              errorString.contains('unauthorized') ||
              errorString.contains('401')) {
            errorMessage = l10n.invalidCredentials;
            errorDescription = l10n.checkCredentials;
          } else if (errorString.contains('network') ||
              errorString.contains('connection') ||
              errorString.contains('timeout') ||
              errorString.contains('unreachable') ||
              errorString.contains('socketexception') ||
              errorString.contains('failed host lookup') ||
              errorString.contains('no internet') ||
              errorString.contains('internet')) {
            errorMessage = l10n.noInternetConnection;
            errorDescription = l10n.networkError;
          } else if (errorString.contains('server') ||
              errorString.contains('api error') ||
              errorString.contains('internal server') ||
              errorString.contains('500') ||
              errorString.contains('502') ||
              errorString.contains('503')) {
            errorMessage = l10n.serverError;
            errorDescription = l10n.serverError;
          } else if (errorString.contains('rate limit') ||
              errorString.contains('too many requests') ||
              errorString.contains('429')) {
            errorMessage = l10n.tooManyRequests;
            errorDescription = l10n.tooManyRequestsDescription;
          } else if (errorString.contains('forbidden') ||
              errorString.contains('403')) {
            errorMessage = l10n.accessDenied;
            errorDescription = l10n.accessDeniedDescription;
          } else {
            // Generic error with the actual error message
            errorMessage = l10n.loginFailed;
            errorDescription = error?.toString() ?? l10n.checkCredentials;
          }

          // Use addPostFrameCallback to safely show snackbar even if widget tree is updating
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      errorMessage,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (errorDescription.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        errorDescription,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ],
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16.w),
              ),
            );
          });
        }
      }
    } catch (e, stackTrace) {
      DebugService.logError('Login network error', e, stackTrace);

      if (mounted) {
        setState(() => _isLoading = false);

        final l10n = AppLocalizations.of(context);
        final errorString = e.toString().toLowerCase();

        // Check if it's a network error
        final isNetworkError =
            errorString.contains('network') ||
            errorString.contains('connection') ||
            errorString.contains('timeout') ||
            errorString.contains('unreachable') ||
            errorString.contains('socketexception') ||
            errorString.contains('failed host lookup') ||
            errorString.contains('no internet') ||
            errorString.contains('internet');

        // Use addPostFrameCallback to ensure context is valid before showing snackbar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNetworkError
                          ? l10n.noInternetConnection
                          : l10n.loginFailed,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      isNetworkError
                          ? l10n.networkError
                          : (e.toString().isNotEmpty
                                ? e.toString()
                                : l10n.checkCredentials),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16.w),
              ),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                      l10n.appName,
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
                    l10n.learnPracticeMaster,
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
                          l10n.importantInformation,
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
                      l10n.alreadyHaveAccount,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey700,
                        fontSize: 13.sp,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4.w,
                            children: [
                              Text(
                                l10n.needHelpCall,
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
                        l10n.enterPhoneNumberToContinue,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey600,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),

                      // Phone Number Field
                      CustomTextField(
                        controller: _phoneController,
                        label: l10n.phoneNumberLabel,
                        hint: l10n.enterYourPhoneNumber,
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.phoneNumberIsRequired;
                          }
                          if (value.length < 10) {
                            return l10n.enterValidPhoneNumber;
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 40.h),

                      // Login Button
                      CustomButton(
                        text: l10n.signIn,
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
                    l10n.newUser,
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
                      l10n.createAccount,
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
                      l10n.byUsingThisAppYouAgree,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey600,
                        fontSize: 12.sp,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => _showPrivacyPolicyModal(),
                            child: Text(
                              l10n.privacyPolicy,
                              style: AppTextStyles.link.copyWith(
                                color: AppColors.primary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          l10n.and,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey600,
                            fontSize: 12.sp,
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () => _showTermsConditionsModal(),
                            child: Text(
                              l10n.termsConditions,
                              style: AppTextStyles.link.copyWith(
                                color: AppColors.primary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
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
    final l10n = AppLocalizations.of(context);
    PrivacyPolicyModal.show(
      context,
      title: l10n.privacyPolicyTitle,
      content: l10n.privacyPolicyContent,
      fullPolicyUrl: 'https://traffic.cyangugudims.com/privacy-policy',
    );
  }

  // Show Terms & Conditions Modal
  void _showTermsConditionsModal() {
    final l10n = AppLocalizations.of(context);
    PrivacyPolicyModal.show(
      context,
      title: l10n.termsConditionsTitle,
      content: l10n.termsConditionsContent,
      fullPolicyUrl: 'https://traffic.cyangugudims.com/terms-conditions',
    );
  }
}
