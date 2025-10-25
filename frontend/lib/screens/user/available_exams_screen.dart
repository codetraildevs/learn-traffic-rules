import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:learn_traffic_rules/screens/user/payment_instructions_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/exam_model.dart';
import '../../services/flash_message_service.dart';
import '../../widgets/custom_button.dart';
import '../../services/user_management_service.dart';
import '../../models/free_exam_model.dart';
import 'exam_taking_screen.dart';
import 'exam_progress_screen.dart';

class AvailableExamsScreen extends ConsumerStatefulWidget {
  const AvailableExamsScreen({super.key});

  @override
  ConsumerState<AvailableExamsScreen> createState() =>
      _AvailableExamsScreenState();
}

class _AvailableExamsScreenState extends ConsumerState<AvailableExamsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final UserManagementService _userManagementService = UserManagementService();
  FreeExamData? _freeExamData;
  bool _isLoadingFreeExams = true;

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
    // Load free exams after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFreeExams();
    });
  }

  Future<void> _loadFreeExams() async {
    try {
      setState(() {
        _isLoadingFreeExams = true;
      });

      debugPrint('🔄 Loading free exams...');
      final response = await _userManagementService.getFreeExams();
      debugPrint('🔄 Free exams response: $response');

      if (response.success) {
        debugPrint('🔄 Free exams data: ${response.data.exams.length} exams');
        setState(() {
          _freeExamData = response.data;
          _isLoadingFreeExams = false;
        });
      } else {
        debugPrint('❌ Failed to load free exams: ${response.message}');
        setState(() {
          _isLoadingFreeExams = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading free exams: $e');
      setState(() {
        _isLoadingFreeExams = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: _isLoadingFreeExams
          ? const Center(child: CircularProgressIndicator())
          : _freeExamData == null
          ? _buildErrorWidget()
          : _buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.w, color: Colors.red),
          SizedBox(height: 16.h),
          Text(
            'Error Loading Exams',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 24.h),
          CustomButton(text: 'Retry', onPressed: _loadFreeExams, width: 120.w),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // Custom App Bar
        SliverAppBar(
          expandedHeight: 200.h,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              _freeExamData!.isFreeUser ? 'Free Exams' : 'All Exams',
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
                        color: AppColors.white.withValues(alpha: 0.1),
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
                        color: AppColors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  // Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.quiz, size: 48.sp, color: AppColors.white),
                        SizedBox(height: 8.h),
                        Text(
                          'Test Your Traffic Rules Knowledge',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Free user status banner
        if (_freeExamData!.isFreeUser)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: _buildFreeUserBanner(),
            ),
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
                        'Available',
                        '${_freeExamData!.exams.length}',
                        Icons.quiz,
                        AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildStatCard(
                        'Easy',
                        '${_freeExamData!.exams.where((e) => e.difficulty == 'Easy').length}',
                        Icons.check_circle,
                        AppColors.success,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildStatCard(
                        'Free Exams',
                        '2',
                        Icons.star,
                        AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Empty State
        if (_freeExamData!.exams.isEmpty)
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
                        'No Exams Available',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Check back later for new traffic rules exams',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey500,
                        ),
                        textAlign: TextAlign.center,
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
              childAspectRatio: 1.9,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final exam = _freeExamData!.exams[index];
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildExamCard(exam, index),
                ),
              );
            }, childCount: _freeExamData!.exams.length),
          ),
        ),

        // Bottom Padding
        SliverToBoxAdapter(child: SizedBox(height: 100.h)),
      ],
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
            color: AppColors.black.withValues(alpha: 0.05),
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
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              height: 50.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getDifficultyColors(exam.difficulty),
                ),
              ),
              child: Stack(
                children: [
                  // Content
                  Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Traffic Rules Exam ${index + 1}',
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppColors.white,
                                  fontSize: 14.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Free exam indicator
                        if (exam.isFirstTwo == true) // First 2 exams are free
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              'FREE',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 12.w,
                            height: 12.w,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.grey400,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // if (exam.description != null) ...[
                  //   Text(
                  //     exam.description!,
                  //     style: AppTextStyles.bodySmall.copyWith(
                  //       color: AppColors.grey600,
                  //     ),
                  //     maxLines: 2,
                  //     overflow: TextOverflow.ellipsis,
                  //   ),
                  //   SizedBox(height: 8.h),
                  // ],

                  // Creation date (for debugging)
                  if (exam.createdAt != null) ...[
                    Text(
                      'Created: ${DateFormat('MMM dd, yyyy').format(exam.createdAt!)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey500,
                        fontSize: 10.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                  ],

                  // Stats row
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: [
                      _buildModernStatChip(
                        Icons.timer_outlined,
                        '${exam.duration}min',
                        AppColors.primary,
                      ),
                      _buildModernStatChip(
                        Icons.trending_up_outlined,
                        '${exam.passingScore}%',
                        AppColors.success,
                      ),
                      _buildModernStatChip(
                        Icons.quiz_outlined,
                        '${exam.questionCount} Q',
                        AppColors.warning,
                      ),
                      // if (exam.category != null)
                      //   _buildModernStatChip(
                      //     Icons.category_outlined,
                      //     exam.category!,
                      //     AppColors.info,
                      //   ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  // Action button
                  ElevatedButton(
                    onPressed: () => _startExam(exam),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      // shape: RoundedRectangleBorder(
                      //   borderRadius: BorderRadius.circular(12.r),
                      // ),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, size: 18.sp),
                        SizedBox(width: 6.w),
                        Text(
                          'Start Exam',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getDifficultyColors(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'EASY':
        return [AppColors.success, AppColors.success.withValues(alpha: 0.8)];
      case 'MEDIUM':
        return [AppColors.warning, AppColors.warning.withValues(alpha: 0.8)];
      case 'HARD':
        return [AppColors.error, AppColors.error.withValues(alpha: 0.8)];
      default:
        return [AppColors.primary, AppColors.secondary];
    }
  }

  Widget _buildFreeUserBanner() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.white, size: 24.w),
              SizedBox(width: 8.w),
              Text(
                'Free Trial',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'First 2 exams are free with unlimited attempts',
            style: TextStyle(fontSize: 14.sp, color: Colors.white70),
          ),
          SizedBox(height: 8.h),
          Text(
            'Upgrade to access all exams and features',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'View Plans',
                  onPressed: () => _showPaymentInstructions(),
                  width: double.infinity,
                  backgroundColor: Colors.white,
                  textColor: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomButton(
                  text: 'Contact Admin',
                  onPressed: _contactAdmin,
                  width: double.infinity,
                  backgroundColor: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startExam(Exam exam) {
    // Check if this exam is marked as free in the backend response
    final isFreeExam = exam.isFirstTwo ?? false;

    // Check if user is free user and trying to access a paid exam
    if (_freeExamData!.isFreeUser && !isFreeExam) {
      _showPaymentInstructions();
      return;
    }

    // Navigate to exam taking screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamTakingScreen(
          exam: exam,
          isFreeExam: _freeExamData!.isFreeUser && isFreeExam,
          onExamCompleted: (result) {
            // Navigate to progress screen after exam completion
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ExamProgressScreen(
                  exam: exam,
                  examResult: result,
                  isFreeExam: _freeExamData!.isFreeUser && isFreeExam,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showPaymentInstructions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentInstructionsScreen(),
      ),
    );
  }

  void _contactAdmin() async {
    const phoneNumber = '+250780494000';
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (!mounted) return;
      AppFlashMessage.showError(context, 'Could not launch phone app');
    }
  }
}
