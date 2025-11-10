import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/course_model.dart';
import '../../services/course_service.dart';
import '../../widgets/custom_button.dart';

class CourseContentViewerScreen extends StatefulWidget {
  final Course course;
  final int initialContentIndex;

  const CourseContentViewerScreen({
    super.key,
    required this.course,
    this.initialContentIndex = 0,
  });

  @override
  State<CourseContentViewerScreen> createState() =>
      _CourseContentViewerScreenState();
}

class _CourseContentViewerScreenState extends State<CourseContentViewerScreen> {
  int _currentIndex = 0;
  List<CourseContent> _contents = [];
  VideoPlayerController? _videoController;
  bool _isLoading = true;
  String? _error;
  final CourseService _courseService = CourseService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialContentIndex;
    _loadCourseContents();
  }

  Future<void> _loadCourseContents() async {
    // If course already has contents, use them
    if (widget.course.contents != null && widget.course.contents!.isNotEmpty) {
      setState(() {
        _contents = List<CourseContent>.from(widget.course.contents!)
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        _isLoading = false;
      });
      _initializeVideo();
      return;
    }

    // Otherwise, load from API
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _courseService.getCourseById(
        widget.course.id,
        includeContents: true,
      );

      if (response.success && response.data != null) {
        final course = response.data!;
        if (course.contents != null && course.contents!.isNotEmpty) {
          setState(() {
            _contents = List<CourseContent>.from(course.contents!)
              ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
            _isLoading = false;
          });
          _initializeVideo();
        } else {
          setState(() {
            _contents = [];
            _isLoading = false;
            _error = 'No content available for this course';
          });
        }
      } else {
        setState(() {
          _contents = [];
          _isLoading = false;
          _error = response.message ?? 'Failed to load course content';
        });
      }
    } catch (e) {
      setState(() {
        _contents = [];
        _isLoading = false;
        _error = 'Error loading course content: $e';
      });
    }
  }

  void _initializeVideo() {
    if (_contents.isNotEmpty &&
        _contents[_currentIndex].contentType == CourseContentType.video) {
      final videoUrl = _getFullUrl(_contents[_currentIndex].content);
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
          }
        });
    }
  }

  String _getFullUrl(String url) {
    if (url.startsWith('http')) {
      return url;
    }
    return '${AppConstants.baseUrlImage}$url';
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentIndex < _contents.length - 1) {
      setState(() {
        _videoController?.dispose();
        _videoController = null;
        _currentIndex++;
        _initializeVideo();
      });
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _videoController?.dispose();
        _videoController = null;
        _currentIndex--;
        _initializeVideo();
      });
    }
  }

  Future<void> _handleLink(String url) async {
    final fullUrl = _getFullUrl(url);
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $fullUrl')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.course.title),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_contents.isEmpty || _error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.course.title),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCourseContents,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 64.sp,
                  color: AppColors.grey400,
                ),
                SizedBox(height: 16.h),
                Text(
                  _error ?? 'No content available',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.grey600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                CustomButton(
                  text: 'Retry',
                  onPressed: _loadCourseContents,
                  backgroundColor: AppColors.primary,
                  textColor: AppColors.white,
                  width: 120.w,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final content = _contents[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(content.title ?? 'Content ${_currentIndex + 1}'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: Text(
                '${_currentIndex + 1}/${_contents.length}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            height: 4.h,
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _contents.length,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),

          // Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: _buildContentWidget(content),
            ),
          ),

          // Navigation Buttons
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Previous',
                    onPressed: _currentIndex > 0 ? _goToPrevious : null,
                    backgroundColor: AppColors.grey300,
                    textColor: AppColors.black,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: CustomButton(
                    text: _currentIndex < _contents.length - 1
                        ? 'Next'
                        : 'Complete',
                    onPressed: _currentIndex < _contents.length - 1
                        ? _goToNext
                        : () {
                            Navigator.pop(context);
                          },
                    backgroundColor: AppColors.primary,
                    textColor: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentWidget(CourseContent content) {
    switch (content.contentType) {
      case CourseContentType.text:
        return _buildTextContent(content);
      case CourseContentType.image:
        return _buildImageContent(content);
      case CourseContentType.audio:
        return _buildAudioContent(content);
      case CourseContentType.video:
        return _buildVideoContent(content);
      case CourseContentType.link:
        return _buildLinkContent(content);
    }
  }

  Widget _buildTextContent(CourseContent content) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        content.content,
        style: AppTextStyles.bodyLarge.copyWith(fontSize: 16.sp, height: 1.6),
      ),
    );
  }

  Widget _buildImageContent(CourseContent content) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (content.title != null)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                content.title!,
                style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16.r),
              bottomRight: Radius.circular(16.r),
            ),
            child: Image.network(
              _getFullUrl(content.content),
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200.h,
                  color: AppColors.grey200,
                  child: Icon(
                    Icons.broken_image,
                    size: 48.sp,
                    color: AppColors.grey400,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioContent(CourseContent content) {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.audiotrack, size: 64.sp, color: AppColors.primary),
          SizedBox(height: 16.h),
          Text(content.title ?? 'Audio Content', style: AppTextStyles.heading3),
          SizedBox(height: 8.h),
          Text(
            'Audio player will be implemented here',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoContent(CourseContent content) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (content.title != null)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                content.title!,
                style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16.r),
              bottomRight: Radius.circular(16.r),
            ),
            child:
                _videoController != null &&
                    _videoController!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_videoController!),
                        IconButton(
                          icon: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: AppColors.white,
                            size: 48.sp,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_videoController!.value.isPlaying) {
                                _videoController!.pause();
                              } else {
                                _videoController!.play();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  )
                : Container(
                    height: 200.h,
                    color: AppColors.grey200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
          ),
          if (_videoController != null)
            VideoProgressIndicator(_videoController!, allowScrubbing: true),
        ],
      ),
    );
  }

  Widget _buildLinkContent(CourseContent content) {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.link, size: 64.sp, color: AppColors.primary),
          SizedBox(height: 16.h),
          Text(content.title ?? 'External Link', style: AppTextStyles.heading3),
          SizedBox(height: 8.h),
          Text(
            content.content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          CustomButton(
            text: 'Open Link',
            onPressed: () => _handleLink(content.content),
            backgroundColor: AppColors.primary,
            textColor: AppColors.white,
            width: 150.w,
          ),
        ],
      ),
    );
  }
}
