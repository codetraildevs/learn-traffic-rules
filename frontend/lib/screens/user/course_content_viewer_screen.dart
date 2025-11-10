import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
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
  AudioPlayer? _audioPlayer;
  bool _isLoading = true;
  String? _error;
  bool _isAudioPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
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
      _initializeAudio();
      return;
    }

    // Otherwise, load from API
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔄 Loading course contents for course: ${widget.course.id}');
      print('📊 Course contentCount: ${widget.course.contentCount}');

      final response = await _courseService.getCourseById(
        widget.course.id,
        includeContents: true,
      );

      print('✅ API Response Success: ${response.success}');
      print('📦 Response Data: ${response.data != null}');

      if (response.success && response.data != null) {
        final course = response.data!;
        print(
          '📚 Course contents: ${course.contents != null ? course.contents!.length : 'null'}',
        );
        print('📊 Course contentCount: ${course.contentCount}');

        // Check if contents exist (could be empty list or null)
        final hasContents =
            course.contents != null && course.contents!.isNotEmpty;

        if (hasContents) {
          print('✅ Found ${course.contents!.length} contents, displaying...');
          setState(() {
            _contents = List<CourseContent>.from(course.contents!)
              ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
            _isLoading = false;
          });
          _initializeVideo();
          _initializeAudio();
        } else {
          // Check if contentCount indicates contents should exist
          final expectedContents =
              course.contentCount != null && course.contentCount! > 0;
          print('⚠️ No contents in response');
          print('   - contentCount: ${course.contentCount}');
          print('   - contents is null: ${course.contents == null}');
          print(
            '   - contents is empty: ${course.contents != null && course.contents!.isEmpty}',
          );

          setState(() {
            _contents = [];
            _isLoading = false;
            _error = expectedContents
                ? 'Content exists (${course.contentCount} items) but failed to load. Please check your connection and try again.'
                : 'No content available for this course';
          });
        }
      } else {
        print('❌ API Error: ${response.message}');
        setState(() {
          _contents = [];
          _isLoading = false;
          _error = response.message ?? 'Failed to load course content';
        });
      }
    } catch (e, stackTrace) {
      print('❌ Exception loading course contents: $e');
      print('Stack trace: $stackTrace');
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
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
          }
        });
    }
  }

  Future<void> _initializeAudio() async {
    if (_contents.isNotEmpty &&
        _contents[_currentIndex].contentType == CourseContentType.audio) {
      try {
        _audioPlayer?.dispose();
        _audioPlayer = AudioPlayer();
        final audioUrl = _getFullUrl(_contents[_currentIndex].content);

        // Listen to player state changes
        _audioPlayer!.playerStateStream.listen((state) {
          if (mounted) {
            setState(() {
              _isAudioPlaying = state.playing;
            });
          }
        });

        // Listen to duration changes
        _audioPlayer!.durationStream.listen((duration) {
          if (mounted && duration != null) {
            setState(() {
              _audioDuration = duration;
            });
          }
        });

        // Listen to position changes
        _audioPlayer!.positionStream.listen((position) {
          if (mounted) {
            setState(() {
              _audioPosition = position;
            });
          }
        });

        await _audioPlayer!.setUrl(audioUrl);
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Error loading audio: $e';
          });
        }
      }
    }
  }

  Future<void> _toggleAudio() async {
    if (_audioPlayer == null) return;

    try {
      if (_isAudioPlaying) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
      }
    }
  }

  Future<void> _seekAudio(Duration position) async {
    if (_audioPlayer == null) return;
    await _audioPlayer!.seek(position);
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
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentIndex < _contents.length - 1) {
      setState(() {
        _videoController?.dispose();
        _videoController = null;
        _audioPlayer?.dispose();
        _audioPlayer = null;
        _isAudioPlaying = false;
        _audioDuration = Duration.zero;
        _audioPosition = Duration.zero;
        _currentIndex++;
        _initializeVideo();
        _initializeAudio();
      });
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _videoController?.dispose();
        _videoController = null;
        _audioPlayer?.dispose();
        _audioPlayer = null;
        _isAudioPlaying = false;
        _audioDuration = Duration.zero;
        _audioPosition = Duration.zero;
        _currentIndex--;
        _initializeVideo();
        _initializeAudio();
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
          Text(
            content.title ?? 'Audio Content',
            style: AppTextStyles.heading3,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),

          // Audio Player Controls
          if (_audioPlayer != null) ...[
            // Progress Bar
            Column(
              children: [
                Slider(
                  value: _audioDuration.inMilliseconds > 0
                      ? _audioPosition.inMilliseconds.toDouble()
                      : 0.0,
                  max: _audioDuration.inMilliseconds > 0
                      ? _audioDuration.inMilliseconds.toDouble()
                      : 1.0,
                  onChanged: (value) {
                    _seekAudio(Duration(milliseconds: value.toInt()));
                  },
                  activeColor: AppColors.primary,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_audioPosition),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                      Text(
                        _formatDuration(_audioDuration),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Play/Pause Button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: IconButton(
                icon: Icon(
                  _isAudioPlaying ? Icons.pause : Icons.play_arrow,
                  color: AppColors.white,
                  size: 48.sp,
                ),
                onPressed: _toggleAudio,
                iconSize: 48.sp,
                padding: EdgeInsets.all(16.w),
              ),
            ),
          ] else ...[
            // Loading state
            const CircularProgressIndicator(),
            SizedBox(height: 16.h),
            Text(
              'Loading audio...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.grey600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
