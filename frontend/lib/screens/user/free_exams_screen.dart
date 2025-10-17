import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/free_exam_model.dart';
import '../../models/exam_model.dart';
import '../../services/user_management_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import 'payment_instructions_screen.dart';

class FreeExamsScreen extends StatefulWidget {
  const FreeExamsScreen({super.key});

  @override
  State<FreeExamsScreen> createState() => _FreeExamsScreenState();
}

class _FreeExamsScreenState extends State<FreeExamsScreen> {
  final UserManagementService _userManagementService = UserManagementService();
  FreeExamData? _freeExamData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFreeExams();
  }

  Future<void> _loadFreeExams() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _userManagementService.getFreeExams();

      if (response.success) {
        setState(() {
          _freeExamData = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load exams: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _freeExamData?.isFreeUser == true ? 'Free Exams' : 'All Exams',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
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
          SizedBox(height: 8.h),
          Text(
            _error!,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          CustomButton(text: 'Retry', onPressed: _loadFreeExams, width: 120.w),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_freeExamData == null) return const SizedBox();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Free user status banner
          if (_freeExamData!.isFreeUser) _buildFreeUserBanner(),

          SizedBox(height: 16.h),

          // Exams list
          if (_freeExamData!.exams.isNotEmpty) ...[
            Text(
              'Available Exams',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12.h),
            _buildExamsList(),
          ] else ...[
            _buildNoExamsWidget(),
          ],

          SizedBox(height: 24.h),

          // Payment instructions if free user
          if (_freeExamData!.isFreeUser &&
              _freeExamData!.freeExamsRemaining == 0)
            _buildPaymentInstructionsCard(),
        ],
      ),
    );
  }

  Widget _buildFreeUserBanner() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
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
            'You have ${_freeExamData!.freeExamsRemaining} free exam${_freeExamData!.freeExamsRemaining == 1 ? '' : 's'} remaining',
            style: TextStyle(fontSize: 14.sp, color: Colors.white70),
          ),
          if (_freeExamData!.freeExamsRemaining == 0) ...[
            SizedBox(height: 8.h),
            Text(
              'Upgrade to access all exams and features',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExamsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _freeExamData!.exams.length,
      itemBuilder: (context, index) {
        final exam = _freeExamData!.exams[index];
        return _buildExamCard(exam, index);
      },
    );
  }

  Widget _buildExamCard(Exam exam, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () => _startExam(exam),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Exam image
                    if (exam.examImgUrl != null && exam.examImgUrl!.isNotEmpty)
                      Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          image: DecorationImage(
                            image: NetworkImage(exam.examImgUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.quiz,
                          color: Colors.grey[400],
                          size: 24.w,
                        ),
                      ),

                    SizedBox(width: 12.w),

                    // Exam details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.title,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            exam.description ?? '',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              _buildInfoChip(
                                '${exam.duration} min',
                                Icons.timer,
                              ),
                              SizedBox(width: 8.w),
                              _buildInfoChip(
                                '${exam.passingScore}% pass',
                                Icons.flag,
                              ),
                              SizedBox(width: 8.w),
                              _buildInfoChip(
                                exam.difficulty,
                                Icons.trending_up,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Free exam indicator
                    if (_freeExamData!.isFreeUser)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'FREE',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Start exam button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Start Exam',
                    onPressed: () => _startExam(exam),
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.w, color: Colors.grey[600]),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoExamsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64.w, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No Exams Available',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Check back later for new exams',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructionsCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.blue[700], size: 24.w),
              SizedBox(width: 8.w),
              Text(
                'Get Full Access',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'You\'ve used all your free exams. Upgrade to access all features!',
            style: TextStyle(fontSize: 14.sp, color: Colors.blue[600]),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'View Plans',
                  onPressed: () => _showPaymentInstructions(),
                  width: double.infinity,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomButton(
                  text: 'Contact Admin',
                  onPressed: _contactAdmin,
                  width: double.infinity,
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startExam(Exam exam) {
    // Navigate to exam screen
    // This would be implemented based on your exam taking flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting exam: ${exam.title}'),
        backgroundColor: Colors.green,
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
    const phoneNumber = '+250788123456';
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch phone app'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
