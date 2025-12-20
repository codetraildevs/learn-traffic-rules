import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/screens/user/payment_instructions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../models/exam_model.dart';
import '../../widgets/custom_button.dart';
import '../../services/user_management_service.dart';
import '../../services/offline_exam_service.dart';
import '../../services/exam_sync_service.dart';
import '../../services/network_service.dart';
import '../../services/image_cache_service.dart';
import '../../models/free_exam_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants/app_constants.dart';
import 'dart:io';
import 'exam_taking_screen.dart';
import 'exam_progress_screen.dart';

class AvailableExamsScreen extends ConsumerStatefulWidget {
  final String? initialExamType;

  const AvailableExamsScreen({super.key, this.initialExamType});

  @override
  ConsumerState<AvailableExamsScreen> createState() =>
      _AvailableExamsScreenState();
}

class _AvailableExamsScreenState extends ConsumerState<AvailableExamsScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final UserManagementService _userManagementService = UserManagementService();
  final OfflineExamService _offlineService = OfflineExamService();
  final ExamSyncService _syncService = ExamSyncService();
  final NetworkService _networkService = NetworkService();
  FreeExamData? _freeExamData;
  List<Exam> _allExams = []; // Cache all exams
  bool _isLoadingFreeExams = true;
  bool _isOffline = false;
  bool _isSyncing = false;
  String? _selectedExamType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize selected exam type from widget parameter if provided
    // Otherwise, will be set from locale in didChangeDependencies
    _selectedExamType = widget.initialExamType?.toLowerCase();

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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  DateTime? _lastBackgroundTime;
  static const Duration _minBackgroundDuration = Duration(seconds: 3);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Only reload if app was in background for a meaningful duration
    // This prevents refresh when taking screenshots (which briefly triggers inactive/resumed)
    // Screenshots trigger: inactive -> resumed (very quickly, < 1 second)
    // Real background: paused -> resumed (usually > 3 seconds)
    if (state == AppLifecycleState.paused) {
      // Only track paused state, not inactive (screenshots trigger inactive)
      _lastBackgroundTime = DateTime.now();
      debugPrint('🔄 App paused, tracking background time');
    } else if (state == AppLifecycleState.resumed) {
      // Only reload if app was paused (in background) for at least 3 seconds
      // Ignore inactive->resumed transitions (screenshots)
      if (_lastBackgroundTime != null) {
        final backgroundDuration = DateTime.now().difference(
          _lastBackgroundTime!,
        );
        if (backgroundDuration >= _minBackgroundDuration) {
          debugPrint(
            '🔄 App resumed after ${backgroundDuration.inSeconds}s, reloading data',
          );
          _loadFreeExams(forceReload: true);
        } else {
          debugPrint(
            '🔄 App resumed quickly (${backgroundDuration.inSeconds}s), skipping reload (likely screenshot)',
          );
        }
        _lastBackgroundTime = null;
      }
    } else if (state == AppLifecycleState.inactive) {
      // Screenshots trigger inactive state - don't track this
      debugPrint('🔄 App inactive (likely screenshot), ignoring');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load free exams after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always set exam type based on current locale (auto-detect)
      final currentLocale = ref.read(localeProvider);
      final examTypeFromLocale = _mapLocaleToExamType(
        currentLocale.languageCode,
      );

      // Only update if different or not set
      if (_selectedExamType != examTypeFromLocale) {
        setState(() {
          _selectedExamType = examTypeFromLocale;
        });
      }

      // Initialize image cache service for offline support
      ImageCacheService.instance.initialize();
      _loadFreeExams();
      _setupConnectivityListener();
    });
  }

  /// Map locale code to exam type
  String _mapLocaleToExamType(String localeCode) {
    switch (localeCode.toLowerCase()) {
      case 'rw':
        return 'kinyarwanda';
      case 'en':
        return 'english';
      case 'fr':
        return 'french';
      default:
        return 'kinyarwanda'; // Default to kinyarwanda
    }
  }

  void _setupConnectivityListener() {
    // Listen for connectivity changes
    _networkService.connectivityStream.listen((connectivityResult) async {
      final hasInternet = await _networkService.hasInternetConnection();

      if (hasInternet && _isOffline) {
        // Internet came back - sync data
        debugPrint('🌐 Internet connection restored, syncing...');
        setState(() {
          _isOffline = false;
          _isSyncing = true;
        });

        // Sync results first, then download exams
        await _syncService.fullSync();

        // Reload exams after sync
        await _loadFreeExams(forceReload: true);

        setState(() {
          _isSyncing = false;
        });
      } else if (!hasInternet && !_isOffline) {
        // Internet lost
        debugPrint('🌐 Internet connection lost, using offline data');
        setState(() {
          _isOffline = true;
        });
      }
    });
  }

  Future<void> _loadFreeExams({bool forceReload = false}) async {
    // If we already have exams and not forcing reload, just filter client-side
    if (!forceReload && _allExams.isNotEmpty && _freeExamData != null) {
      debugPrint('🔄 Using cached exams, filtering client-side');
      _filterExamsClientSide();
      return;
    }

    try {
      setState(() {
        _isLoadingFreeExams = true;
      });

      // Check internet connection
      final hasInternet = await _networkService.hasInternetConnection();
      setState(() {
        _isOffline = !hasInternet;
      });

      if (hasInternet) {
        // Online: Try to load from API and download for offline
        debugPrint('🌐 Online: Loading exams from API...');
        try {
          final response = await _userManagementService.getFreeExams();
          debugPrint('🔄 Free exams response: $response');

          if (response.success) {
            debugPrint(
              '🔄 Free exams data: ${response.data.exams.length} exams',
            );
            // Mark free exams by type before caching
            final examsWithFreeMarked = _markFreeExamsByType(
              response.data.exams,
            );

            // Store payment instructions for offline use
            if (response.data.paymentInstructions != null) {
              await _storePaymentInstructionsOffline(
                response.data.paymentInstructions!,
              );
            }

            setState(() {
              _allExams =
                  examsWithFreeMarked; // Cache all exams with free marked
              _freeExamData = FreeExamData(
                exams: examsWithFreeMarked,
                isFreeUser: response.data.isFreeUser,
                freeExamsRemaining: response.data.freeExamsRemaining,
                paymentInstructions: response.data.paymentInstructions,
              );
              _isLoadingFreeExams = false;
            });

            // Download ALL exams for offline use in background (not just free exams)
            // Only start download if we still have internet
            // Use forceDownload=false to only download new/updated exams
            _networkService.hasInternetConnection().then((stillOnline) {
              if (stillOnline) {
                // Initialize image cache service
                ImageCacheService.instance.initialize().then((_) {
                  // Cache exam images in background
                  for (final exam in examsWithFreeMarked) {
                    if (exam.examImgUrl != null &&
                        exam.examImgUrl!.isNotEmpty) {
                      // Construct full image URL using baseUrlImage
                      final imageUrl = exam.examImgUrl!.startsWith('http')
                          ? exam.examImgUrl!
                          : '${AppConstants.baseUrlImage}${exam.examImgUrl}';
                      ImageCacheService.instance
                          .cacheImage(imageUrl)
                          .catchError((e) {
                            debugPrint('⚠️ Failed to cache exam image: $e');
                            return null;
                          });
                    }
                  }
                });

                _syncService.downloadAllExams(forceDownload: false).catchError((
                  e,
                ) {
                  debugPrint('⚠️ Failed to download exams offline: $e');
                });
              } else {
                debugPrint(
                  '🌐 Internet connection lost, skipping exam download',
                );
              }
            });

            // Filter after loading
            _filterExamsClientSide();
          } else {
            debugPrint('❌ Failed to load free exams: ${response.message}');
            // Fallback to offline data
            await _loadOfflineExams();
          }
        } catch (e) {
          debugPrint('❌ Error loading from API: $e');
          // Fallback to offline data
          await _loadOfflineExams();
        }
      } else {
        // Offline: Load from local database
        debugPrint('📱 Offline: Loading exams from local storage...');
        await _loadOfflineExams();
      }
    } catch (e) {
      debugPrint('❌ Error loading free exams: $e');
      setState(() {
        _isLoadingFreeExams = false;
      });
    }
  }

  Future<void> _loadOfflineExams() async {
    try {
      final offlineExams = await _offlineService.getAllExams();

      if (offlineExams.isNotEmpty) {
        debugPrint(
          '📱 Loaded ${offlineExams.length} exams from offline storage',
        );

        // Ensure _selectedExamType is set before filtering
        if (_selectedExamType == null) {
          final currentLocale = ref.read(localeProvider);
          _selectedExamType = _mapLocaleToExamType(currentLocale.languageCode);
          debugPrint('📱 Set _selectedExamType to: $_selectedExamType');
        }

        // Remove duplicates by ID (additional safety check)
        final uniqueExams = <String, Exam>{};
        for (final exam in offlineExams) {
          if (!uniqueExams.containsKey(exam.id)) {
            uniqueExams[exam.id] = exam;
          }
        }
        final distinctExams = uniqueExams.values.toList();

        debugPrint(
          '📱 After removing duplicates: ${distinctExams.length} unique exams',
        );

        // Mark free exams by type before setting state
        final examsWithFreeMarked = _markFreeExamsByType(distinctExams);

        // Check user access from authProvider (stored in SharedPreferences)
        final authState = ref.read(authProvider);
        final hasAccess = authState.accessPeriod?.hasAccess ?? false;
        final isFreeUser = !hasAccess; // User is free if they don't have access

        // Load payment instructions from offline storage if available
        PaymentInstructions? offlinePaymentInstructions;
        if (isFreeUser) {
          offlinePaymentInstructions = await _loadPaymentInstructionsOffline();
        }

        setState(() {
          _allExams = examsWithFreeMarked;
          _freeExamData = FreeExamData(
            exams: examsWithFreeMarked,
            isFreeUser: isFreeUser,
            freeExamsRemaining: 0,
            paymentInstructions: offlinePaymentInstructions,
          );
          _isLoadingFreeExams = false;
        });
        // Filter after loading
        _filterExamsClientSide();
      } else {
        debugPrint('📱 No offline exams available');
        setState(() {
          _isLoadingFreeExams = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading offline exams: $e');
      setState(() {
        _isLoadingFreeExams = false;
      });
    }
  }

  /// Marks the first 1 exam of each type as free
  List<Exam> _markFreeExamsByType(List<Exam> exams) {
    if (exams.isEmpty) return exams;

    // Group exams by type
    final Map<String, List<Exam>> examsByType = {};
    for (final exam in exams) {
      // Handle null examType: default to 'english' if null
      // Also try to infer from title if it contains language keywords
      String type = exam.examType?.toLowerCase() ?? 'english';

      // If examType is null, try to infer from title
      if (exam.examType == null) {
        final titleLower = exam.title.toLowerCase();
        if (titleLower.contains('kiny') || titleLower.contains('kinyarwanda')) {
          type = 'kinyarwanda';
        } else if (titleLower.contains('french') ||
            titleLower.contains('français')) {
          type = 'french';
        } else {
          type = 'english'; // Default to english
        }
      }

      examsByType.putIfAbsent(type, () => []).add(exam);
    }

    // Sort exams within each type by createdAt (oldest first)
    // If createdAt is null, use a very early date to push them to the end
    for (final type in examsByType.keys) {
      examsByType[type]!.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(1970);
        final bDate = b.createdAt ?? DateTime(1970);
        return aDate.compareTo(bDate);
      });
    }

    // Create a set of free exam IDs (first 1 of each type)
    final Set<String> freeExamIds = {};
    for (final type in ['kinyarwanda', 'english', 'french']) {
      final examsOfType = examsByType[type.toLowerCase()] ?? [];
      // Get first 1 exam of this type
      for (int i = 0; i < examsOfType.length && i < 1; i++) {
        freeExamIds.add(examsOfType[i].id);
      }
    }

    // Mark first 1 exam of each type as free
    final List<Exam> updatedExams = exams.map((exam) {
      final isFree = freeExamIds.contains(exam.id);
      // Use copyWith, but ensure we set isFirstTwo explicitly
      // Since copyWith uses ?? operator, we need to be careful with false values
      return Exam(
        id: exam.id,
        title: exam.title,
        description: exam.description,
        category: exam.category,
        difficulty: exam.difficulty,
        duration: exam.duration,
        passingScore: exam.passingScore,
        isActive: exam.isActive,
        examImgUrl: exam.examImgUrl,
        questionCount: exam.questionCount,
        isFirstTwo: isFree, // Explicitly set free status
        examType: exam.examType,
        createdAt: exam.createdAt,
        updatedAt: exam.updatedAt,
      );
    }).toList();

    debugPrint('🆓 Marked free exams by type:');
    for (final type in ['kinyarwanda', 'english', 'french']) {
      final examsOfType =
          updatedExams
              .where((e) => e.examType?.toLowerCase() == type.toLowerCase())
              .toList()
            ..sort((a, b) {
              final aDate = a.createdAt ?? DateTime(1970);
              final bDate = b.createdAt ?? DateTime(1970);
              return aDate.compareTo(bDate);
            });
      final freeExams = examsOfType.where((e) => e.isFirstTwo == true).toList();
      if (freeExams.isNotEmpty) {
        debugPrint(
          '   $type: ${freeExams.length} free exams (${freeExams.map((e) => e.title).join(", ")})',
        );
      }
    }

    return updatedExams;
  }

  void _filterExamsClientSide() {
    debugPrint('🔍 _filterExamsClientSide called');
    debugPrint('   _freeExamData is null: ${_freeExamData == null}');
    debugPrint('   _allExams.isEmpty: ${_allExams.isEmpty}');
    debugPrint('   _allExams.length: ${_allExams.length}');
    debugPrint('   _selectedExamType: $_selectedExamType');

    if (_freeExamData == null) {
      debugPrint('❌ Cannot filter: _freeExamData is null');
      return;
    }

    if (_allExams.isEmpty) {
      debugPrint('❌ Cannot filter: _allExams is empty');
      return;
    }

    // Get exam type from locale if not set
    String examTypeToFilter;
    if (_selectedExamType != null && _selectedExamType!.isNotEmpty) {
      examTypeToFilter = _selectedExamType!;
    } else {
      // Get from current locale
      final currentLocale = ref.read(localeProvider);
      examTypeToFilter = _mapLocaleToExamType(currentLocale.languageCode);
      // Update state for next build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedExamType = examTypeToFilter;
          });
        }
      });
    }

    // Always filter by selected language (from locale)
    final filteredExams = _allExams.where((exam) {
      // Get exam type using same logic as _markFreeExamsByType
      String type = exam.examType?.toLowerCase() ?? 'english';

      // If examType is null, try to infer from title
      if (exam.examType == null) {
        final titleLower = exam.title.toLowerCase();
        if (titleLower.contains('kiny') || titleLower.contains('kinyarwanda')) {
          type = 'kinyarwanda';
        } else if (titleLower.contains('french') ||
            titleLower.contains('français')) {
          type = 'french';
        } else {
          type = 'english'; // Default to english
        }
      }

      // Match against selected type
      return type == examTypeToFilter.toLowerCase();
    }).toList();

    debugPrint(
      '✅ Filtered by type: ${filteredExams.length} exams match $examTypeToFilter',
    );

    setState(() {
      _freeExamData = FreeExamData(
        exams: filteredExams,
        isFreeUser: _freeExamData!.isFreeUser,
        freeExamsRemaining: _freeExamData!.freeExamsRemaining,
        paymentInstructions: _freeExamData!.paymentInstructions,
      );
    });
    debugPrint(
      '🔄 Filtered to ${filteredExams.length} exams for type: $examTypeToFilter',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: RefreshIndicator(
        onRefresh: () => _loadFreeExams(forceReload: true),
        child: _isLoadingFreeExams
            ? const Center(child: CircularProgressIndicator())
            : _freeExamData == null
            ? _buildErrorWidget()
            : _buildContent(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.w, color: Colors.red),
          SizedBox(height: 16.h),
          Text(
            l10n.errorLoadingDashboard,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 24.h),
          CustomButton(
            text: l10n.retry,
            onPressed: _loadFreeExams,
            width: 120.w,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Custom App Bar
        SliverAppBar(
          expandedHeight: 50.h,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.secondary,
          flexibleSpace: FlexibleSpaceBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _freeExamData!.isFreeUser
                        ? l10n.availableExams
                        : l10n.allExams,
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.white,
                      fontSize: 20.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isOffline) ...[
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.cloud_off,
                    size: 18.sp,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ],
                if (_isSyncing) ...[
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 16.w,
                    height: 16.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // background: Container(
            //   decoration: const BoxDecoration(
            //     gradient: LinearGradient(
            //       begin: Alignment.topLeft,
            //       end: Alignment.bottomRight,
            //       colors: [AppColors.primary, AppColors.secondary],
            //     ),
            //   ),
            //   // child:
            //   //  Stack(
            //   //   children: [
            //   //     // Background Pattern
            //   //     Positioned(
            //   //       top: -50.h,
            //   //       right: -50.w,
            //   //       child: Container(
            //   //         width: 200.w,
            //   //         height: 200.h,
            //   //         decoration: BoxDecoration(
            //   //           shape: BoxShape.circle,
            //   //           color: AppColors.white.withValues(alpha: 0.1),
            //   //         ),
            //   //       ),
            //   //     ),
            //   //     Positioned(
            //   //       bottom: -30.h,
            //   //       left: -30.w,
            //   //       child: Container(
            //   //         width: 150.w,
            //   //         height: 150.h,
            //   //         decoration: BoxDecoration(
            //   //           shape: BoxShape.circle,
            //   //           color: AppColors.white.withValues(alpha: 0.05),
            //   //         ),
            //   //       ),
            //   //     ),
            //   //     // Content
            //   //     Center(
            //   //       child: Column(
            //   //         mainAxisAlignment: MainAxisAlignment.center,
            //   //         children: [
            //   //           Icon(Icons.quiz, size: 48.sp, color: AppColors.white),
            //   //           SizedBox(height: 8.h),
            //   //           Text(
            //   //             'Test Your Traffic Rules Knowledge',
            //   //             style: AppTextStyles.bodyLarge.copyWith(
            //   //               color: AppColors.white.withValues(alpha: 0.9),
            //   //             ),
            //   //           ),
            //   //         ],
            //   //       ),
            //   //     ),
            //   //   ],
            //   // ),
            // ),
          ),
        ),

        // Language Dropdown Section (below app bar)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: _buildLanguageDropdownSection(),
          ),
        ),

        // Exams filtered by selected language (no filter UI, no grouping)
        ..._buildExamsByType(),

        // Free user status banner (moved below exams, made smaller)
        if (_freeExamData!.isFreeUser)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: _buildFreeUserBanner(),
            ),
          ),

        // Bottom Padding
        SliverToBoxAdapter(child: SizedBox(height: 100.h)),
      ],
    );
  }

  Widget _buildLanguageDropdownSection() {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);

    // Get current exam type from selected language
    final currentExamType =
        _selectedExamType ?? _mapLocaleToExamType(currentLocale.languageCode);

    // Map locale codes to exam types and display names
    final languageOptions = [
      {
        'code': 'rw',
        'examType': 'kinyarwanda',
        'name': l10n.ikinyarwanda,
        'flag': '🇷🇼',
      },
      {
        'code': 'en',
        'examType': 'english',
        'name': l10n.english,
        'flag': '🇬🇧',
      },
      {'code': 'fr', 'examType': 'french', 'name': l10n.french, 'flag': '🇫🇷'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectLanguage,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.grey800,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.grey200, width: 1),
          ),
          child: DropdownButton<String>(
            value: currentExamType,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: languageOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option['examType'] as String,
                child: Row(
                  children: [
                    Text(
                      option['flag'] as String,
                      style: TextStyle(fontSize: 20.sp),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      option['name'] as String,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newExamType) async {
              if (newExamType == null || newExamType == currentExamType) return;

              debugPrint('🌐 Language changed to: $newExamType');

              // Find corresponding locale code
              final languageOption = languageOptions.firstWhere(
                (opt) => opt['examType'] == newExamType,
                orElse: () => languageOptions[0],
              );
              final localeCode = languageOption['code'] as String;

              // Update locale provider
              final localeNotifier = ref.read(localeProvider.notifier);
              await localeNotifier.setLocale(Locale(localeCode));

              // Update selected exam type before reloading
              setState(() {
                _selectedExamType = newExamType;
              });

              // Reload exams with new language filter
              // _loadFreeExams will handle:
              // - Online: Load from API and filter by language
              // - Offline: Load from local database and filter by language
              await _loadFreeExams(forceReload: true);
            },
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
            dropdownColor: AppColors.white,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildExamsByType() {
    final l10n = AppLocalizations.of(context);

    // Use exams already filtered by _filterExamsClientSide
    // No need to filter again as they're already filtered by selected language
    final filteredExams = _freeExamData!.exams;

    if (filteredExams.isEmpty) {
      return [
        SliverToBoxAdapter(
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
                  l10n.noExamsAvailable,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  l10n.noExamsFoundForThisLanguage,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.67,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final exam = filteredExams[index];
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildExamCard(exam, index),
              ),
            );
          }, childCount: filteredExams.length),
        ),
      ),
    ];
  }

  Widget _buildExamCard(Exam exam, int index) {
    final l10n = AppLocalizations.of(context);
    // Extract exam number from title (e.g., "exam 21" -> "21")
    final examNumber = exam.title.replaceAll(RegExp(r'[^0-9]'), '');
    final displayTitle = examNumber.isNotEmpty
        ? 'exam $examNumber'
        : exam.title;

    // Get exam image URL - construct full path if it's just a filename
    final imageUrl = exam.examImgUrl != null && exam.examImgUrl!.isNotEmpty
        ? (exam.examImgUrl!.startsWith('http')
              ? exam.examImgUrl!
              : '${AppConstants.baseUrlImage}${exam.examImgUrl}')
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Exam Image
            if (imageUrl != null)
              FutureBuilder<String>(
                future: ImageCacheService.instance.getImagePath(imageUrl),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final imagePath = snapshot.data!;
                    final isLocalFile = !imagePath.startsWith('http');

                    if (isLocalFile) {
                      // Check if file exists
                      return FutureBuilder<bool>(
                        future: File(
                          imagePath,
                        ).exists().catchError((e) => false),
                        builder: (context, fileSnapshot) {
                          if (fileSnapshot.hasData &&
                              fileSnapshot.data == true) {
                            // Image is cached, load from file
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Image.file(
                                File(imagePath),
                                width: double.infinity,
                                height: 85.h,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImagePlaceholder();
                                },
                              ),
                            );
                          } else {
                            // File doesn't exist, try network if online
                            if (!_isOffline) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Image.network(
                                  imageUrl,
                                  width: double.infinity,
                                  height: 85.h,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildImagePlaceholder();
                                  },
                                ),
                              );
                            } else {
                              return _buildImagePlaceholder();
                            }
                          }
                        },
                      );
                    } else {
                      // Network URL
                      if (_isOffline) {
                        return _buildImagePlaceholder();
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.network(
                          imagePath,
                          width: double.infinity,
                          height: 85.h,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder();
                          },
                        ),
                      );
                    }
                  }
                  // Loading or no data
                  return _buildImagePlaceholder();
                },
              )
            else
              _buildImagePlaceholder(),
            SizedBox(height: 6.h),

            // Exam Title
            Text(
              displayTitle,
              style: AppTextStyles.heading3.copyWith(
                fontSize: 15.sp,
                color: AppColors.grey800,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 6.h),

            // Questions Count
            Row(
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 13.sp,
                  color: AppColors.grey600,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    l10n.questionsCount(exam.questionCount ?? 0),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey700,
                      fontSize: 11.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Duration
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 13.sp,
                  color: AppColors.grey600,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    l10n.durationMinutes(exam.duration),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey700,
                      fontSize: 11.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Start Exam Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startExam(exam),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.grey800,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, size: 18.sp),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        l10n.startExam,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 11.sp,
                          color: AppColors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeUserBanner() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.white, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.freeTrialFirstExamOfEachTypeIsFree,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  l10n.upgradeToAccessAllExams,
                  style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          TextButton(
            onPressed: () => _showPaymentInstructions(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
            child: Text(
              l10n.viewPlans,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startExam(Exam exam) {
    // Check if this exam is marked as free (first 1 exam of each type)
    // Free status is determined per exam type (English, French, Kinyarwanda)
    final isFreeExam = exam.isFirstTwo ?? false;

    // Check user access from authProvider (more reliable than _freeExamData.isFreeUser)
    final authState = ref.read(authProvider);
    final hasAccess = authState.accessPeriod?.hasAccess ?? false;

    // Only show payment instructions if:
    // 1. User has NO access (isFreeUser = true)
    // 2. AND they're trying to access a paid exam (not free)
    // If user has access, allow them to take any exam even offline
    if (!hasAccess && !isFreeExam) {
      _showPaymentInstructions();
      return;
    }

    // Navigate to exam taking screen
    // Use hasAccess to determine if it's a free exam (free exam = hasAccess && isFreeExam)
    // If user has access, all exams are accessible, so isFreeExam should be false
    final isFreeExamForUser = !hasAccess && isFreeExam;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamTakingScreen(
          exam: exam,
          isFreeExam: isFreeExamForUser,
          onExamCompleted: (result) {
            // Navigate to progress screen after exam completion
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ExamProgressScreen(
                  exam: exam,
                  examResult: result,
                  isFreeExam: isFreeExamForUser,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Store payment instructions in SharedPreferences for offline access
  Future<void> _storePaymentInstructionsOffline(
    PaymentInstructions instructions,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convert PaymentInstructions to JSON and store
      // Store both as PaymentInstructions (for FreeExamData) and as PaymentInstructionsData (for PaymentInstructionsScreen)
      final instructionsJson = jsonEncode(instructions.toJson());
      await prefs.setString('payment_instructions', instructionsJson);

      // Also store as PaymentInstructionsData format for PaymentInstructionsScreen
      final dataJson = jsonEncode({
        'title': instructions.title,
        'description': instructions.description,
        'steps': instructions.steps,
        'contactInfo': instructions.contactInfo.toJson(),
        'paymentMethods': <Map<String, dynamic>>[], // Empty list
        'paymentTiers': instructions.paymentTiers
            .map((tier) => tier.toJson())
            .toList(),
      });
      await prefs.setString('payment_instructions_data', dataJson);
      debugPrint('💾 Stored payment instructions offline');
    } catch (e) {
      debugPrint('❌ Error storing payment instructions: $e');
    }
  }

  /// Load payment instructions from SharedPreferences
  Future<PaymentInstructions?> _loadPaymentInstructionsOffline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Try loading as PaymentInstructions first
      final instructionsJson = prefs.getString('payment_instructions');
      if (instructionsJson != null) {
        final data = jsonDecode(instructionsJson) as Map<String, dynamic>;
        return PaymentInstructions.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error loading payment instructions offline: $e');
      return null;
    }
  }

  void _showPaymentInstructions() {
    // Pass payment instructions if available (for offline support)
    final paymentInstructions = _freeExamData?.paymentInstructions;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PaymentInstructionsScreen(cachedInstructions: paymentInstructions),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 85.h,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(Icons.quiz_outlined, size: 36.sp, color: AppColors.grey400),
    );
  }
}
