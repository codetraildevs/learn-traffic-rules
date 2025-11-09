import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/course_model.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialContentIndex;
    if (widget.course.contents != null) {
      _contents = List<CourseContent>.from(widget.course.contents!)
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    }
    _initializeVideo();
  }

  void _initializeVideo() {
    if (_contents.isNotEmpty &&
        _contents[_currentIndex].contentType == CourseContentType.video) {
      final videoUrl = _getFullUrl(_contents[_currentIndex].content);
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          setState(() {});
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
    if (_contents.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.course.title),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
        body: const Center(child: Text('No content available')),
      );
    }

    final content = _contents[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(content.title ?? 'Content ${_currentIndex + 1}'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _contents.length,
            backgroundColor: AppColors.grey200,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                  child: ElevatedButton(
                    onPressed: _currentIndex > 0 ? _goToPrevious : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.grey300,
                      foregroundColor: AppColors.black,
                    ),
                    child: const Text('Previous'),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentIndex < _contents.length - 1
                        ? _goToNext
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: Text(
                      _currentIndex < _contents.length - 1
                          ? 'Next'
                          : 'Complete',
                    ),
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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Text(
          content.content,
          style: AppTextStyles.bodyLarge.copyWith(fontSize: 16.sp, height: 1.6),
        ),
      ),
    );
  }

  Widget _buildImageContent(CourseContent content) {
    return Card(
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
          Image.network(
            _getFullUrl(content.content),
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200.h,
                color: AppColors.grey200,
                child: const Center(child: Icon(Icons.broken_image, size: 48)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAudioContent(CourseContent content) {
    // TODO: Implement audio player
    return Card(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          children: [
            Icon(Icons.audiotrack, size: 64.sp, color: AppColors.primary),
            SizedBox(height: 16.h),
            Text(
              content.title ?? 'Audio Content',
              style: AppTextStyles.heading3,
            ),
            SizedBox(height: 8.h),
            Text(
              'Audio player will be implemented here',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent(CourseContent content) {
    return Card(
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
          if (_videoController != null && _videoController!.value.isInitialized)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            )
          else
            Container(
              height: 200.h,
              color: AppColors.grey200,
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (_videoController != null)
            VideoProgressIndicator(_videoController!, allowScrubbing: true),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _videoController?.value.isPlaying ?? false
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_videoController?.value.isPlaying ?? false) {
                        _videoController?.pause();
                      } else {
                        _videoController?.play();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkContent(CourseContent content) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          children: [
            Icon(Icons.link, size: 64.sp, color: AppColors.primary),
            SizedBox(height: 16.h),
            Text(
              content.title ?? 'External Link',
              style: AppTextStyles.heading3,
            ),
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
            ElevatedButton(
              onPressed: () => _handleLink(content.content),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Open Link'),
            ),
          ],
        ),
      ),
    );
  }
}
