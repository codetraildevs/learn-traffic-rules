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
import '../../services/network_service.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/home/home_screen.dart';

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
  final NetworkService _networkService = NetworkService();

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
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.phone, color: AppColors.secondary, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                l10n.needHelp,
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
                l10n.contactSupport,
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
                              backgroundColor: AppColors.secondary,
                              action: SnackBarAction(
                                label: l10n.copy,
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
                    SnackBar(
                      content: Text(l10n.phoneNumber),
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
              child: Text(l10n.callNow),
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

      final l10n = AppLocalizations.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.pleaseCheckYourInformation,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  l10n.makeSureAllFieldsFilled,
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

    // Check internet connection before attempting registration
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

          final l10n = AppLocalizations.of(context);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.registrationSuccessful,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      l10n.welcomeToApp,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16.w),
              ),
            );
          }

          // Wait for auth state to update, then navigate to home screen
          // Registration automatically logs the user in
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
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
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

          DebugService.logAuthEvent('Registration failed', {
            'deviceId': deviceId,
            'fullName': _fullNameController.text.trim(),
            'phoneNumber': _phoneController.text.trim(),
            'role': _selectedRole,
            'error': error,
            'timestamp': DateTime.now().toIso8601String(),
          });

          // Show enhanced error message with specific handling for common errors
          final l10n = AppLocalizations.of(context);
          String errorMessage = l10n.registerFailed;
          String errorDescription = l10n.pleaseCheckYourInformation;
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
            errorMessage = l10n.phoneNumberAlreadyRegistered;
            errorDescription = l10n.phoneNumberAlreadyRegisteredDescription;
            errorIcon = '📱';
          } else if (errorString.contains('device is already registered') ||
              errorString.contains('device already registered') ||
              errorString.contains('device is already') ||
              errorString.contains('device already exists') ||
              errorString.contains('device already used') ||
              errorString.contains('device binding') ||
              errorString.contains('device conflict')) {
            // Check if user exists by attempting a login check
            // This handles the case where device is registered but user doesn't exist
            errorMessage = l10n.deviceAlreadyRegistered;
            errorDescription = l10n.deviceAlreadyRegisteredDescription;
            errorIcon = '📱';

            // Try to check if user exists by attempting login
            // This helps identify if it's a device binding issue vs user doesn't exist
            _checkUserExists(_phoneController.text.trim());
          } else if (errorString.contains('invalid phone') ||
              errorString.contains('phone number invalid') ||
              errorString.contains('invalid phone number')) {
            errorMessage = l10n.invalidPhoneNumber;
            errorDescription = l10n.invalidPhoneNumberDescription;
            errorIcon = '📞';
          } else if (errorString.contains('name too short') ||
              errorString.contains('invalid name') ||
              errorString.contains('name required')) {
            errorMessage = l10n.invalidName;
            errorDescription = l10n.invalidNameDescription;
            errorIcon = '✏️';
          } else if (errorString.contains('network') ||
              errorString.contains('connection') ||
              errorString.contains('timeout') ||
              errorString.contains('unreachable')) {
            errorMessage = l10n.networkError;
            errorDescription = l10n.networkError;
            errorIcon = '🌐';
          } else if (errorString.contains('server') ||
              errorString.contains('api error') ||
              errorString.contains('internal server') ||
              errorString.contains('500')) {
            errorMessage = l10n.serverError;
            errorDescription = l10n.serverError;
            errorIcon = '⚠️';
          } else if (errorString.contains('rate limit') ||
              errorString.contains('too many requests') ||
              errorString.contains('429')) {
            errorMessage = l10n.tooManyRequests;
            errorDescription = l10n.tooManyRequestsDescription;
            errorIcon = '⏱️';
          } else if (errorString.contains('unauthorized') ||
              errorString.contains('forbidden') ||
              errorString.contains('401') ||
              errorString.contains('403')) {
            errorMessage = l10n.accessDenied;
            errorDescription = l10n.accessDeniedDescription;
            errorIcon = '🔐';
          } else {
            // Generic error with the actual error message
            errorMessage = l10n.registerFailed;
            errorDescription =
                error?.toString() ?? l10n.pleaseCheckYourInformation;
            errorIcon = '❌';
          }

          if (mounted) {
            final showLoginAction =
                errorString.contains('phone number is already registered') ||
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
                errorString.contains('device conflict');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$errorMessage $errorIcon',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      errorDescription,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 8),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16.w),
                action: showLoginAction
                    ? SnackBarAction(
                        label: l10n.goToLogin,
                        textColor: Colors.white,
                        onPressed: () {
                          _showLoginConfirmationDialog();
                        },
                      )
                    : null,
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      DebugService.logError('Registration network error', e, stackTrace);

      if (mounted) {
        setState(() => _isLoading = false);

        final l10n = AppLocalizations.of(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.networkError,
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
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16.w),
            ),
          );
        }
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
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Column(
                        children: [
                          Text(
                            l10n.startLearningJourney,
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.black,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            l10n.learnPracticeMaster,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.grey700,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
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
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return Text(
                              l10n.importantInformation,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.fillDetailsToCreateAccount,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.grey700,
                                fontSize: 13.sp,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                                Expanded(
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
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
                                                mode: LaunchMode
                                                    .externalApplication,
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
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.secondary,
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w600,
                                                decoration:
                                                    TextDecoration.underline,
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
                                                mode: LaunchMode
                                                    .externalApplication,
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
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.secondary,
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w600,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
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
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.fillDetailsBelow,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.grey600,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              SizedBox(height: 12.h),

                              // Full Name Field
                              CustomTextField(
                                controller: _fullNameController,
                                label: l10n.fullName,
                                hint: l10n.enterYourFullName,
                                prefixIcon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.fullNameIsRequired;
                                  }
                                  if (value.length <
                                      AppConstants.minNameLength) {
                                    return l10n.nameMustBeAtLeast(
                                      AppConstants.minNameLength,
                                    );
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 12.h),

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

                              SizedBox(height: 16.h),

                              // Register Button
                              CustomButton(
                                text: l10n.createAccount,
                                icon: Icons.person_add,
                                onPressed: _isLoading ? null : _handleRegister,
                                isLoading: _isLoading,
                                height: 50.h,
                                backgroundColor: AppColors.primary,
                                textColor: Colors.white,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              // Login Link with Creative Design
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),

                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4.w,
                      children: [
                        Text(
                          l10n.alreadyHaveAccount,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey700,
                            fontSize: 14.sp,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to login screen explicitly
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Text(
                            l10n.signIn,
                            style: AppTextStyles.link.copyWith(
                              color: AppColors.primary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: 20.h),

              // Privacy Policy and Terms & Conditions Links
              Container(
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.grey200, width: 1),
                ),
                child: Column(
                  children: [
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Column(
                          children: [
                            Text(
                              l10n.byCreatingAccountYouAgree,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.grey600,
                                fontSize: 12.sp,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8.h),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4.w,
                              children: [
                                TextButton(
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
                                Text(
                                  l10n.and,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.grey600,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                TextButton(
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
                              ],
                            ),
                          ],
                        );
                      },
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

  // Check if user exists by attempting a login
  Future<void> _checkUserExists(String phoneNumber) async {
    try {
      debugPrint('🔍 Checking if user exists for phone: $phoneNumber');

      // Use fallback device ID if not available
      final deviceId =
          _deviceId ??
          'unknown_device_${DateTime.now().millisecondsSinceEpoch}';

      final loginRequest = LoginRequest(
        phoneNumber: phoneNumber,
        deviceId: deviceId,
      );

      // Try to login to check if user exists
      final loginResult = await ref
          .read(authProvider.notifier)
          .login(loginRequest);

      if (loginResult) {
        // User exists and login succeeded
        debugPrint('✅ User exists and login succeeded');
        if (mounted) {
          // User is now logged in, no need to show error
          return;
        }
      } else {
        // Login failed - check the error
        final authState = ref.read(authProvider);
        final error = authState.error?.toLowerCase() ?? '';
        debugPrint('❌ Login failed, error: $error');

        if (error.contains('phone number not found') ||
            error.contains('user not found') ||
            error.contains('phone not registered') ||
            error.contains('invalid phone number or device id')) {
          // User doesn't exist - this is the problematic scenario
          debugPrint('⚠️ Device is registered but user does not exist!');

          if (mounted) {
            // Show special error message for this scenario
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.deviceBindingIssue,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      l10n.deviceBindingIssueDescription,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 10),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16.w),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking user existence: $e');
      // Don't show error, just log it
    }
  }

  // Show Login Confirmation Dialog
  void _showLoginConfirmationDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.login, color: AppColors.primary, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                l10n.goToLogin,
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
                l10n.itLooksLikeYouAlreadyHaveAccount,
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
                          l10n.whatToDo,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      l10n.useSamePhoneNumber,
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
                l10n.stayHere,
                style: AppTextStyles.link.copyWith(color: AppColors.grey600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate to login screen explicitly
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(l10n.goToLogin),
            ),
          ],
        );
      },
    );
  }
}
