import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/course_model.dart';
import '../../services/course_service.dart';
import '../../widgets/custom_button.dart';
import '../../l10n/app_localizations.dart';

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

          final l10n = AppLocalizations.of(context)!;
          setState(() {
            _contents = [];
            _isLoading = false;
            _error = expectedContents
                ? l10n.contentExistsButFailedToLoad(course.contentCount ?? 0)
                : l10n.noContentAvailableForThisCourse;
          });
        }
      } else {
        print('❌ API Error: ${response.message}');
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _contents = [];
          _isLoading = false;
          _error = response.message ?? l10n.failedToLoadCourseContent;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Exception loading course contents: $e');
      print('Stack trace: $stackTrace');
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _contents = [];
        _isLoading = false;
        _error = l10n.errorLoadingCourseContent(e.toString());
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

  Future<bool> _validateAudioUrl(String url) async {
    try {
      print('🔍 AUDIO: Validating URL: $url');

      // Try HEAD request first (lighter, faster)
      try {
        final headResponse = await http
            .head(Uri.parse(url))
            .timeout(const Duration(seconds: 5));

        print('🔍 AUDIO: HEAD Response status: ${headResponse.statusCode}');
        print(
          '🔍 AUDIO: Content-Type: ${headResponse.headers['content-type']}',
        );
        print(
          '🔍 AUDIO: Content-Length: ${headResponse.headers['content-length']}',
        );

        if (headResponse.statusCode != 200) {
          print('❌ AUDIO: File not found (HTTP ${headResponse.statusCode})');
          return false;
        }

        final contentType =
            headResponse.headers['content-type']?.toLowerCase() ?? '';
        // Check if it's HTML/text (likely an error page)
        if (contentType.contains('text/html') ||
            contentType.contains('text/plain') ||
            contentType.contains('application/json')) {
          print('❌ AUDIO: Server returned $contentType instead of audio file');
          return false;
        }

        // If we get here, the file seems to exist and has a valid content type
        print('✅ AUDIO: URL validation passed');
        return true;
      } catch (headError) {
        // HEAD request failed, try GET request with range header (just first bytes)
        print(
          '⚠️ AUDIO: HEAD request failed, trying GET with range header: $headError',
        );
        try {
          final getResponse = await http
              .get(
                Uri.parse(url),
                headers: {'Range': 'bytes=0-1023'}, // Request first 1KB only
              )
              .timeout(const Duration(seconds: 5));

          print('🔍 AUDIO: GET Response status: ${getResponse.statusCode}');
          print(
            '🔍 AUDIO: Content-Type: ${getResponse.headers['content-type']}',
          );

          if (getResponse.statusCode == 200 || getResponse.statusCode == 206) {
            final contentType =
                getResponse.headers['content-type']?.toLowerCase() ?? '';
            if (contentType.contains('text/html') ||
                contentType.contains('text/plain') ||
                contentType.contains('application/json')) {
              print(
                '❌ AUDIO: Server returned $contentType instead of audio file',
              );
              return false;
            }
            print('✅ AUDIO: URL validation passed (via GET)');
            return true;
          } else {
            print('❌ AUDIO: File not found (HTTP ${getResponse.statusCode})');
            return false;
          }
        } catch (getError) {
          print('❌ AUDIO: GET request also failed: $getError');
          // Don't fail completely - let the player try to load it
          // Some servers might block HEAD/GET but allow streaming
          return true;
        }
      }
    } catch (e) {
      print('❌ AUDIO URL VALIDATION ERROR: $e');
      // Don't block playback - let the player try and show its own error
      return true;
    }
  }

  Future<void> _initializeAudio() async {
    if (_contents.isNotEmpty &&
        _contents[_currentIndex].contentType == CourseContentType.audio) {
      try {
        _audioPlayer?.dispose();
        _audioPlayer = AudioPlayer();
        final content = _contents[_currentIndex].content;
        final audioUrl = _getFullUrl(content);

        print('🎵 AUDIO: Initializing audio player');
        print('   Content path: $content');
        print('   Full URL: $audioUrl');

        // Validate URL format
        final l10n = AppLocalizations.of(context)!;
        if (!audioUrl.startsWith('http://') &&
            !audioUrl.startsWith('https://')) {
          throw Exception(l10n.invalidAudioUrlMessage(audioUrl));
        }

        // Validate URL exists and is accessible (non-blocking)
        final isValid = await _validateAudioUrl(audioUrl);
        if (!isValid) {
          throw Exception(l10n.audioFileNotFoundOrInvalid);
        }

        // Listen to player state changes
        _audioPlayer!.playerStateStream.listen((state) {
          if (mounted) {
            setState(() {
              _isAudioPlaying = state.playing;
            });

            // Check for loading errors
            if (state.processingState == ProcessingState.idle &&
                state.playing == false &&
                _audioDuration == Duration.zero) {
              // If we're idle and duration is still zero, there might be an error
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted &&
                    _audioPlayer != null &&
                    _audioPlayer!.duration == null &&
                    _audioPlayer!.playerState.processingState ==
                        ProcessingState.idle) {
                  final l10n = AppLocalizations.of(context)!;
                  setState(() {
                    _error = l10n.unableToLoadAudioFile;
                    _audioPlayer?.dispose();
                    _audioPlayer = null;
                  });
                }
              });
            }

            print(
              '🎵 AUDIO: Player state - playing: ${state.playing}, processingState: ${state.processingState}',
            );
          }
        });

        // Listen to duration changes
        _audioPlayer!.durationStream.listen((duration) {
          if (mounted && duration != null && duration != Duration.zero) {
            setState(() {
              _audioDuration = duration;
            });
            print('✅ AUDIO: Duration loaded: ${duration.inSeconds}s');
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

        // Listen to player errors using error stream
        _audioPlayer!.playbackEventStream.listen(
          (event) {
            // Check for errors in the event - playback events don't directly provide errors
            // Errors are caught in the catch block below
          },
          onError: (error) {
            print('❌ AUDIO PLAYBACK ERROR: $error');
            if (mounted) {
              final l10n = AppLocalizations.of(context)!;
              setState(() {
                _error = l10n.errorPlayingAudio(error.toString());
                _audioPlayer?.dispose();
                _audioPlayer = null;
              });
            }
          },
        );

        // Set audio source with timeout
        try {
          await _audioPlayer!
              .setUrl(audioUrl)
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  if (!mounted) return;
                  final l10n = AppLocalizations.of(context);
                  throw Exception(l10n.timeoutLoadingAudioFile);
                },
              );
          print('🎵 AUDIO: Audio URL set successfully');

          // Wait a bit and check if duration was loaded (indicates file is valid)
          await Future.delayed(const Duration(seconds: 2));
          if (_audioPlayer != null && mounted) {
            final duration = _audioPlayer!.duration;
            if (duration == null || duration == Duration.zero) {
              print('⚠️ AUDIO: Duration is still null after 2 seconds');
              // Check player state
              final state = _audioPlayer!.playerState;
              if (state.processingState == ProcessingState.idle) {
                final l10n = AppLocalizations.of(context)!;
                throw Exception(l10n.audioFileCouldNotBeLoaded);
              }
            } else {
              print('✅ AUDIO: Duration loaded: ${duration.inSeconds}s');
            }
          }
        } catch (e) {
          print('❌ AUDIO SET URL ERROR: $e');
          rethrow;
        }
      } catch (e, stackTrace) {
        print('❌ AUDIO ERROR: $e');
        print('   Stack trace: $stackTrace');
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          String errorMessage = l10n.errorLoadingAudio;
          final errorStr = e.toString().toLowerCase();

          if (errorStr.contains('unrecognizedinputformatexception') ||
              errorStr.contains('could read the stream') ||
              errorStr.contains('none of the available extractors')) {
            errorMessage = l10n.audioFileFormatNotSupported;
          } else if (errorStr.contains('source error') ||
              errorStr.contains('socketexception') ||
              errorStr.contains('failed host lookup')) {
            errorMessage = l10n.cannotLoadAudioFile;
          } else if (errorStr.contains('timeout')) {
            errorMessage = l10n.timeoutLoadingAudioFileSlow;
          } else if (errorStr.contains('404') ||
              errorStr.contains('not found')) {
            errorMessage = l10n.audioFileNotFound;
          } else if (errorStr.contains('403') ||
              errorStr.contains('forbidden')) {
            errorMessage = l10n.accessDeniedToAudioFile;
          } else if (errorStr.contains('html') ||
              errorStr.contains('text/html')) {
            errorMessage = l10n.serverReturnedErrorPageForAudio;
          } else if (errorStr.contains('could not be loaded')) {
            errorMessage = errorStr;
          } else {
            // Extract meaningful error message
            final cleanError = e
                .toString()
                .replaceAll('Exception: ', '')
                .replaceAll('Error: ', '')
                .split('\n')
                .first;
            errorMessage = l10n.errorLoadingAudioWithMessage(cleanError);
          }

          setState(() {
            _error = errorMessage;
            _audioPlayer?.dispose();
            _audioPlayer = null;
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorPlayingAudio(e.toString()))),
        );
      }
    }
  }

  Future<void> _seekAudio(Duration position) async {
    if (_audioPlayer == null) return;
    await _audioPlayer!.seek(position);
  }

  String _getFullUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Ensure URL starts with / if it doesn't already
    if (!url.startsWith('/')) {
      url = '/$url';
    }
    // Remove duplicate slashes
    final baseUrl = AppConstants.baseUrlImage.replaceAll(RegExp(r'/+$'), '');
    return '$baseUrl$url';
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
        _error = null; // Clear error when navigating
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
        _error = null; // Clear error when navigating
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.couldNotOpenUrl(fullUrl))));
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
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Text(
                      _error ?? l10n.noContentAvailable,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.grey600,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                SizedBox(height: 16.h),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return CustomButton(
                      text: l10n.retry,
                      onPressed: _loadCourseContents,
                      backgroundColor: AppColors.primary,
                      textColor: AppColors.white,
                      width: 120.w,
                    );
                  },
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
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Text(content.title ?? l10n.contentNumber(_currentIndex + 1));
          },
        ),
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
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
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
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return CustomButton(
                        text: l10n.previous,
                        onPressed: _currentIndex > 0 ? _goToPrevious : null,
                        backgroundColor: AppColors.grey300,
                        textColor: AppColors.black,
                      );
                    },
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return CustomButton(
                        text: _currentIndex < _contents.length - 1
                            ? l10n.next
                            : l10n.finish,
                        onPressed: _currentIndex < _contents.length - 1
                            ? _goToNext
                            : () {
                                Navigator.pop(context);
                              },
                        backgroundColor: AppColors.primary,
                        textColor: AppColors.white,
                      );
                    },
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
    // Check if there's an error for this specific content
    final hasError =
        _error != null &&
        _contents.isNotEmpty &&
        _contents[_currentIndex].contentType == CourseContentType.audio;

    final audioUrl = _getFullUrl(content.content);

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
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Text(
                content.title ?? l10n.audioContent,
                style: AppTextStyles.heading3,
                textAlign: TextAlign.center,
              );
            },
          ),
          SizedBox(height: 8.h),
          // Show file path for debugging (can be removed in production)
          Text(
            content.content,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey500,
              fontSize: 10.sp,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 24.h),

          // Error State
          if (hasError) ...[
            Icon(Icons.error_outline, size: 48.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                _error!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 8.h),
            // Show URL for debugging
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'URL: $audioUrl',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grey500,
                  fontSize: 9.sp,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return CustomButton(
                      text: l10n.retry,
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _audioPlayer?.dispose();
                          _audioPlayer = null;
                        });
                        _initializeAudio();
                      },
                      backgroundColor: AppColors.primary,
                      textColor: AppColors.white,
                      width: 120.w,
                    );
                  },
                ),
              ],
            ),
          ]
          // Audio Player Controls
          else if (_audioPlayer != null && _error == null) ...[
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
              decoration: const BoxDecoration(
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
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Column(
                  children: [
                    Text(
                      l10n.loadingAudio,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      l10n.pleaseWaitWhileWeLoadTheAudioFile,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey500,
                        fontSize: 11.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
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
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Text(
                content.title ?? l10n.externalLink,
                style: AppTextStyles.heading3,
              );
            },
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
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return CustomButton(
                text: l10n.openLink,
                onPressed: () => _handleLink(content.content),
                backgroundColor: AppColors.primary,
                textColor: AppColors.white,
                width: 150.w,
              );
            },
          ),
        ],
      ),
    );
  }
}
