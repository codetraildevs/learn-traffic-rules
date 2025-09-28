import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../models/exam_model.dart';
import '../../providers/exam_provider.dart';
import '../../services/flash_message_service.dart';
import '../../widgets/custom_button.dart';
import 'create_exam_screen.dart';
import 'edit_exam_screen.dart';
import 'question_upload_screen.dart';
import 'question_management_screen.dart';

class ExamManagementScreen extends ConsumerStatefulWidget {
  const ExamManagementScreen({super.key});

  @override
  ConsumerState<ExamManagementScreen> createState() =>
      _ExamManagementScreenState();
}

class _ExamManagementScreenState extends ConsumerState<ExamManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load exams after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(examProvider.notifier).loadExams();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final examState = ref.watch(examProvider);

    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 200.h,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Exam Management',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.white,
                  fontSize: 20.sp,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background Pattern
                    Positioned(
                      top: -50.h,
                      right: -50.w,
                      child: Container(
                        width: 200.w,
                        height: 200.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30.h,
                      left: -30.w,
                      child: Container(
                        width: 150.w,
                        height: 150.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    // Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.quiz, size: 48.sp, color: AppColors.white),
                          SizedBox(height: 6.h),
                          Text(
                            'Manage Traffic Rules Exams',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.white),
                onPressed: () => _navigateToCreateExam(),
              ),
            ],
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Exams',
                          '${examState.exams.length}',
                          Icons.quiz,
                          AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildStatCard(
                          'Active',
                          '${examState.exams.where((e) => e.isActive).length}',
                          Icons.check_circle,
                          AppColors.success,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildStatCard(
                          'Inactive',
                          '${examState.exams.where((e) => !e.isActive).length}',
                          Icons.pause_circle,
                          AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading State
          if (examState.isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),

          // Error State
          if (examState.error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: AppColors.error),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          examState.error!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.read(examProvider.notifier).loadExams(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Exams List
          if (examState.exams.isEmpty &&
              !examState.isLoading &&
              examState.error == null)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.all(32.w),
                    child: Column(
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 80.sp,
                          color: AppColors.grey400,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No Exams Yet',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.grey600,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Create your first exam to get started',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24.h),
                        CustomButton(
                          text: 'Create First Exam',
                          onPressed: () => _navigateToCreateExam(),
                          width: 200.w,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Exams Grid
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio:
                    1.15, // Slightly more space to prevent overflow
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final exam = examState.exams[index];
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildExamCard(exam, index),
                  ),
                );
              }, childCount: examState.exams.length),
            ),
          ),

          // Bottom Padding
          SliverToBoxAdapter(child: SizedBox(height: 100.h)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateExam(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Exam'),
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
          Icon(icon, size: 24.sp, color: color),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(
              fontSize: 20.sp,
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

  Widget _buildExamCard(Exam exam, int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              height: 70.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: exam.isActive
                      ? [AppColors.primary, AppColors.secondary]
                      : [AppColors.grey400, AppColors.grey500],
                ),
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned(
                    top: -30.h,
                    right: -20.w,
                    child: Container(
                      width: 80.w,
                      height: 80.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  exam.title,
                                  style: AppTextStyles.heading3.copyWith(
                                    color: AppColors.white,
                                    fontSize: 16.sp,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    exam.difficultyDisplay,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.white,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Status indicator
                        Container(
                          width: 12.w,
                          height: 12.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: exam.isActive
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Exam Image (Clickable)
            if (exam.examImgUrl != null && exam.examImgUrl!.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _navigateToQuestionUpload(exam),
                child: Container(
                  height: 100.h,
                  width: double.infinity,
                  decoration: const BoxDecoration(color: AppColors.grey100),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.zero,
                        child: Image.network(
                          exam.examImgUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.grey200,
                              child: Icon(
                                Icons.image_not_supported,
                                color: AppColors.grey400,
                                size: 40.sp,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppColors.grey200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Overlay with upload icon
                      Container(
                        color: AppColors.black.withOpacity(0.3),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_file,
                                color: AppColors.white,
                                size: 24.sp,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Upload Questions',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.white,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // No image - show upload placeholder
              GestureDetector(
                onTap: () => _navigateToQuestionUpload(exam),
                child: Container(
                  height: 100.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    border: Border.all(
                      color: AppColors.grey300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file,
                        color: AppColors.grey400,
                        size: 32.sp,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Upload Questions',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Content
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (exam.description != null) ...[
                    Text(
                      exam.description!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                  ],

                  // Stats row
                  Row(
                    children: [
                      _buildStatItem(Icons.timer, exam.durationDisplay),
                      SizedBox(width: 8.w),
                      _buildStatItem(
                        Icons.trending_up,
                        '${exam.passingScore}%',
                      ),
                      SizedBox(width: 8.w),
                      _buildStatItem(
                        Icons.device_unknown,
                        exam.difficultyDisplay,
                      ),
                      SizedBox(width: 8.w),
                      _buildStatItem(
                        Icons.quiz,
                        '${exam.questionCount ?? 0} Q',
                      ),
                    ],
                  ),

                  SizedBox(height: 6.h),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Edit',
                          onPressed: () => _navigateToEditExam(exam),
                          backgroundColor: AppColors.primary,
                          textColor: AppColors.white,
                          height: 40.h,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: CustomButton(
                          text: exam.isActive ? 'Deactivate' : 'Activate',
                          onPressed: () => _toggleExamStatus(exam),
                          backgroundColor: exam.isActive
                              ? AppColors.grey500
                              : AppColors.success,
                          textColor: AppColors.white,
                          height: 40.h,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      GestureDetector(
                        onTap: () => _showDeleteDialog(exam),
                        child: Container(
                          width: 36.w,
                          height: 36.h,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(8.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: AppColors.white,
                            size: 18.sp,
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
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: AppColors.primary),
          SizedBox(width: 3.w),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey700,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateExam() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateExamScreen()),
    ).then((_) {
      ref.read(examProvider.notifier).loadExams();
    });
  }

  void _navigateToEditExam(Exam exam) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditExamScreen(exam: exam)),
    ).then((_) {
      ref.read(examProvider.notifier).loadExams();
    });
  }

  void _navigateToQuestionUpload(Exam exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionManagementScreen(exam: exam),
      ),
    );
  }

  void _toggleExamStatus(Exam exam) async {
    final success = await ref
        .read(examProvider.notifier)
        .toggleExamStatus(exam.id);
    if (success) {
      AppFlashMessage.showSuccess(
        context,
        'Exam ${exam.isActive ? 'deactivated' : 'activated'} successfully',
      );
    } else {
      AppFlashMessage.showError(
        context,
        'Failed to ${exam.isActive ? 'deactivate' : 'activate'} exam',
      );
    }
  }

  void _showDeleteDialog(Exam exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text(
          'Are you sure you want to delete "${exam.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(examProvider.notifier)
                  .deleteExam(exam.id);
              if (success) {
                AppFlashMessage.showSuccess(
                  context,
                  'Exam deleted successfully',
                );
              } else {
                AppFlashMessage.showError(context, 'Failed to delete exam');
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
