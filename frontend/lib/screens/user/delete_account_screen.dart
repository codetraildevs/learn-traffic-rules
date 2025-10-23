import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _confirmDeletion = false;
  final TextEditingController _confirmationController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _confirmationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Warning Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 48.sp,
                    color: AppColors.error,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Delete Account',
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 24.sp,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This action cannot be undone',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Account Information
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Information',
                    style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                  ),
                  SizedBox(height: 16.h),
                  _buildInfoRow('Name', user?.fullName ?? 'Not provided'),
                  _buildInfoRow('Phone', user?.phoneNumber ?? 'Not provided'),
                  //_buildInfoRow('User ID', user?.id ?? 'Not available'),
                  _buildInfoRow('Role', user?.role ?? 'USER'),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // What Will Be Deleted
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What Will Be Deleted',
                    style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                  ),
                  SizedBox(height: 16.h),
                  _buildDeletionItem('• Your personal profile information'),
                  _buildDeletionItem('• All exam results and progress data'),
                  _buildDeletionItem('• Study history and achievements'),
                  _buildDeletionItem('• App preferences and settings'),
                  _buildDeletionItem('• Any uploaded content or data'),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.warning,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'This action is permanent and cannot be reversed.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Confirmation
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirm Deletion',
                    style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'To confirm account deletion, please type "DELETE" in the box below:',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey700,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _confirmationController,
                    decoration: InputDecoration(
                      hintText: 'Type DELETE to confirm',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: AppColors.error),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _confirmDeletion = value.toUpperCase() == 'DELETE';
                      });
                    },
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Enter your password to confirm deletion:',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey700,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Checkbox(
                        value: _confirmDeletion,
                        onChanged: (value) {
                          setState(() {
                            _confirmDeletion = value ?? false;
                            if (_confirmDeletion) {
                              _confirmationController.text = 'DELETE';
                            } else {
                              _confirmationController.clear();
                            }
                          });
                        },
                        activeColor: AppColors.error,
                      ),
                      Expanded(
                        child: Text(
                          'I understand that this action cannot be undone',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Cancel',
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    backgroundColor: AppColors.grey400,
                    width: double.infinity,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: CustomButton(
                    text: 'Delete Account',
                    onPressed: _confirmDeletion && _passwordController.text.isNotEmpty && !_isLoading
                        ? _deleteAccount
                        : null,
                    backgroundColor: AppColors.error,
                    width: double.infinity,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletionItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey700),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    if (!_confirmDeletion) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Final Confirmation'),
          content: const Text(
            'Are you absolutely sure you want to delete your account? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Call delete account API with password
      await _apiService.deleteAccount(_passwordController.text);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );

        // Logout and navigate to login
        await ref.read(authProvider.notifier).logout();

        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
