import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          _buildExamsTab(),
          _buildProgressTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Exams'),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Progress',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Navigate to notifications
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.grey50, AppColors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.white,
                          fontSize: 24.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Ready to master traffic rules?',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      CustomButton(
                        text: 'Start Learning',
                        onPressed: () {
                          setState(() {
                            _currentIndex = 1; // Switch to exams tab
                          });
                        },
                        backgroundColor: AppColors.white,
                        textColor: AppColors.primary,
                        width: 150.w,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Quick Stats
                Text(
                  'Quick Stats',
                  style: AppTextStyles.heading3.copyWith(fontSize: 20.sp),
                ),
                SizedBox(height: 16.h),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Exams Taken',
                        '0',
                        Icons.quiz,
                        AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildStatCard(
                        'Average Score',
                        '0%',
                        Icons.trending_up,
                        AppColors.success,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Study Streak',
                        '0 days',
                        Icons.local_fire_department,
                        AppColors.warning,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildStatCard(
                        'Achievements',
                        '0',
                        Icons.emoji_events,
                        AppColors.secondary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Recent Activity
                Text(
                  'Recent Activity',
                  style: AppTextStyles.heading3.copyWith(fontSize: 20.sp),
                ),
                SizedBox(height: 16.h),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48.sp,
                        color: AppColors.grey400,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No recent activity',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Start taking exams to see your progress here',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24.sp, color: color),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              fontSize: 18.sp,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(fontSize: 12.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExamsTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exams'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz, size: 64.sp, color: AppColors.grey400),
            SizedBox(height: 16.h),
            Text(
              'Exams Coming Soon',
              style: AppTextStyles.heading3.copyWith(color: AppColors.grey600),
            ),
            SizedBox(height: 8.h),
            Text(
              'Exam functionality will be implemented soon',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64.sp, color: AppColors.grey400),
            SizedBox(height: 16.h),
            Text(
              'Progress Tracking',
              style: AppTextStyles.heading3.copyWith(color: AppColors.grey600),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your progress and analytics will appear here',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Profile Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40.r,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.person,
                      size: 40.sp,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    user?.fullName ?? 'User',
                    style: AppTextStyles.heading3.copyWith(fontSize: 20.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    user?.phoneNumber ?? 'No phone number',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      user?.role ?? 'USER',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Settings Options
            _buildSettingsOption(
              'Notifications',
              'Manage your notification preferences',
              Icons.notifications,
              () {},
            ),

            _buildSettingsOption(
              'Achievements',
              'View your achievements and badges',
              Icons.emoji_events,
              () {},
            ),

            _buildSettingsOption(
              'Study Reminders',
              'Set up study reminders',
              Icons.schedule,
              () {},
            ),

            _buildSettingsOption(
              'Help & Support',
              'Get help and contact support',
              Icons.help,
              () {},
            ),

            SizedBox(height: 24.h),

            // Logout Button
            CustomButton(
              text: 'Logout',
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
              },
              backgroundColor: AppColors.error,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20.sp),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16.sp,
          color: AppColors.grey400,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        tileColor: AppColors.white,
      ),
    );
  }
}
