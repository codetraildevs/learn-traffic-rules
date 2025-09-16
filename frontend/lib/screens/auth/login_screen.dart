import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/device_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
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
    // Pre-fill password for testing
    _passwordController.text = 'password123';
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
    final deviceService = DeviceService();
    _deviceId = await deviceService.getDeviceId();
    _deviceModel = await deviceService.getDeviceModel();
    _platformName = deviceService.getPlatformName();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _logoController.dispose();
    _formController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device ID not ready. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final request = LoginRequest(
      password: _passwordController.text.trim(),
      deviceId: _deviceId!,
    );

    final success = await ref.read(authProvider.notifier).login(request);

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        // Navigation will be handled by the main app
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final error = ref.read(authProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Login failed'),
            backgroundColor: AppColors.error,
          ),
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary, Color(0xFF4A148C)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 40.h),

                // Animated Logo Section
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: Column(
                        children: [
                          // Floating Logo with Glow Effect
                          Container(
                            width: 120.w,
                            height: 120.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppColors.white, Color(0xFFF5F5F5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.white.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: AppColors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.traffic,
                              size: 60.sp,
                              color: AppColors.primary,
                            ),
                          ),

                          SizedBox(height: 24.h),

                          // App Title with Animation
                          Text(
                            'Traffic Rules',
                            style: AppTextStyles.heading1.copyWith(
                              color: AppColors.white,
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: AppColors.black.withOpacity(0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 8.h),

                          Text(
                            'Master the Rules, Master the Road',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.white.withOpacity(0.9),
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 60.h),

                // Animated Login Form
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _formAnimation,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 24.w),
                      padding: EdgeInsets.all(32.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Welcome Text
                            Text(
                              'Welcome Back!',
                              style: AppTextStyles.heading2.copyWith(
                                fontSize: 28.sp,
                                color: AppColors.grey800,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: 8.h),

                            Text(
                              'Enter your password to continue',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.grey600,
                                fontSize: 16.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: 40.h),

                            // Device Info Display
                            if (_deviceId != null) ...[
                              Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: AppColors.grey50,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: AppColors.grey200,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_android,
                                          color: AppColors.primary,
                                          size: 20.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'Device: $_platformName',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                    if (_deviceModel != null) ...[
                                      SizedBox(height: 4.h),
                                      Text(
                                        _deviceModel!,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.grey600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              SizedBox(height: 24.h),
                            ],

                            // Password Field
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'Enter your password',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.grey500,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                if (value.length <
                                    AppConstants.minPasswordLength) {
                                  return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 32.h),

                            // Login Button
                            CustomButton(
                              text: 'Sign In',
                              onPressed: _isLoading ? null : _handleLogin,
                              isLoading: _isLoading,
                              height: 56.h,
                            ),

                            SizedBox(height: 24.h),

                            // Forgot Password Link
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: AppTextStyles.link.copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40.h),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white.withOpacity(0.9),
                        fontSize: 16.sp,
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
                          color: AppColors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 40.h),

                // Test Credentials Info
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.white,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Test Credentials',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Password: password123',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Device ID will be auto-detected',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white.withOpacity(0.8),
                          fontSize: 12.sp,
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
