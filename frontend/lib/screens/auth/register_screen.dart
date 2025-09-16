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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
    _passwordController.text = 'password123';
    _confirmPasswordController.text = 'password123';
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
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _logoController.dispose();
    _formController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
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

    final request = RegisterRequest(
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      deviceId: _deviceId!,
      role: _selectedRole,
    );

    final success = await ref.read(authProvider.notifier).register(request);

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        final error = ref.read(authProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Registration failed'),
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
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.secondary, AppColors.primary, Color(0xFFE65100)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 30.h),

                // Animated Header
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: Column(
                        children: [
                          // Animated Icon
                          Container(
                            width: 100.w,
                            height: 100.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppColors.white, Color(0xFFF5F5F5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.white.withOpacity(0.4),
                                  blurRadius: 25,
                                  spreadRadius: 3,
                                ),
                                BoxShadow(
                                  color: AppColors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person_add_alt_1,
                              size: 50.sp,
                              color: AppColors.primary,
                            ),
                          ),

                          SizedBox(height: 20.h),

                          Text(
                            'Join Us!',
                            style: AppTextStyles.heading1.copyWith(
                              color: AppColors.white,
                              fontSize: 28.sp,
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
                            'Start your traffic rules journey',
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

                SizedBox(height: 40.h),

                // Animated Registration Form
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _formAnimation,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.w),
                      padding: EdgeInsets.all(28.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(28.r),
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
                            // Header
                            Text(
                              'Create Account',
                              style: AppTextStyles.heading2.copyWith(
                                fontSize: 24.sp,
                                color: AppColors.grey800,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: 8.h),

                            Text(
                              'Fill in your details below',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.grey600,
                                fontSize: 14.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: 32.h),

                            // Device Info Display
                            if (_deviceId != null) ...[
                              Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.1),
                                      AppColors.secondary.withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
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
                                                color: AppColors.primary,
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

                            SizedBox(height: 16.h),

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
                                if (value.length !=
                                    AppConstants.phoneNumberLength) {
                                  return 'Phone number must be ${AppConstants.phoneNumberLength} digits';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 16.h),

                            // Role Selection
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.grey100,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: AppColors.grey300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedRole,
                                  isExpanded: true,
                                  items: AppConstants.userRoles.map((role) {
                                    return DropdownMenuItem<String>(
                                      value: role,
                                      child: Text(
                                        role,
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          fontSize: 16.sp,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  },
                                ),
                              ),
                            ),

                            SizedBox(height: 16.h),

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

                            SizedBox(height: 16.h),

                            // Confirm Password Field
                            CustomTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              hint: 'Confirm your password',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.grey500,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 32.h),

                            // Register Button
                            CustomButton(
                              text: 'Create Account',
                              onPressed: _isLoading ? null : _handleRegister,
                              isLoading: _isLoading,
                              height: 56.h,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white.withOpacity(0.9),
                        fontSize: 16.sp,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Sign In',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
