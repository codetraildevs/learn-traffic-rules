import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/screens/user/payment_instructions_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/exam_model.dart';
import '../../services/flash_message_service.dart';
import '../../widgets/custom_button.dart';
import '../../services/user_management_service.dart';
import '../../services/offline_exam_service.dart';
import '../../services/exam_sync_service.dart';
import '../../services/network_service.dart';
import '../../models/free_exam_model.dart';
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
    // Initialize selected exam type from widget parameter
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload exams when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _loadFreeExams(forceReload: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load free exams after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFreeExams();
      _setupConnectivityListener();
    });
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

            // Download exams for offline use in background
            _syncService.downloadAllExams().catchError((e) {
              debugPrint('⚠️ Failed to download exams offline: $e');
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
        // Mark free exams by type before setting state
        final examsWithFreeMarked = _markFreeExamsByType(offlineExams);

        setState(() {
          _allExams = examsWithFreeMarked;
          _freeExamData = FreeExamData(
            exams: examsWithFreeMarked,
            isFreeUser: true, // Assume free user for offline
            freeExamsRemaining: 0,
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

  /// Marks the first 2 exams of each type as free
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
        } else if (titleLower.contains('french') || titleLower.contains('français')) {
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

    // Create a set of free exam IDs (first 2 of each type)
    final Set<String> freeExamIds = {};
    for (final type in ['kinyarwanda', 'english', 'french']) {
      final examsOfType = examsByType[type.toLowerCase()] ?? [];
      // Get first 2 exams of this type
      for (int i = 0; i < examsOfType.length && i < 2; i++) {
        freeExamIds.add(examsOfType[i].id);
      }
    }

    // Mark first 2 exams of each type as free
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

    // Free exams are already marked in _allExams, just filter by type
    List<Exam> filteredExams;
    if (_selectedExamType != null && _selectedExamType!.isNotEmpty) {
      filteredExams = _allExams
          .where(
            (exam) =>
                exam.examType?.toLowerCase() ==
                _selectedExamType?.toLowerCase(),
          )
          .toList();
      debugPrint(
        '✅ Filtered by type: ${filteredExams.length} exams match $_selectedExamType',
      );
    } else {
      filteredExams = List.from(_allExams);
      debugPrint('✅ Showing all exams: ${filteredExams.length} exams');
    }

    setState(() {
      _freeExamData = FreeExamData(
        exams: filteredExams,
        isFreeUser: _freeExamData!.isFreeUser,
        freeExamsRemaining: _freeExamData!.freeExamsRemaining,
        paymentInstructions: _freeExamData!.paymentInstructions,
      );
    });
    debugPrint(
      '🔄 Filtered to ${filteredExams.length} exams for type: $_selectedExamType',
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
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Custom App Bar
        SliverAppBar(
          expandedHeight: 200.h,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _freeExamData!.isFreeUser ? 'Free Exams' : 'All Exams',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.white,
                    fontSize: 20.sp,
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

        // Exam Type Filter
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: _buildExamTypeFilter(),
              ),
            ),
          ),
        ),

        // Exams grouped by type
        ..._buildExamsByType(),

        // Bottom Padding
        SliverToBoxAdapter(child: SizedBox(height: 100.h)),
      ],
    );
  }

  Widget _buildExamTypeFilter() {
    // Get unique exam types from exams
    final examTypes = _freeExamData!.exams
        .map((e) => e.examType?.toLowerCase())
        .where((type) => type != null)
        .toSet()
        .toList();

    // Order: kinyarwanda, english, french
    final orderedTypes = ['kinyarwanda', 'english', 'french'];
    final availableTypes = orderedTypes
        .where((type) => examTypes.contains(type))
        .toList();

    if (availableTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter by Language',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            // All option
            _buildFilterChip(null, 'All'),
            // Type options
            ...availableTypes.map((type) {
              final displayName = type[0].toUpperCase() + type.substring(1);
              return _buildFilterChip(type, displayName);
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String? type, String label) {
    final isSelected = _selectedExamType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        debugPrint(
          '🔍 Filter chip tapped: $label, selected: $selected, type: $type',
        );
        final newSelectedType = selected ? type : null;
        debugPrint('🔍 Will update _selectedExamType to: $newSelectedType');

        // Update state and filter in one setState call
        setState(() {
          _selectedExamType = newSelectedType;
          // Filter client-side without API call
          // Free exams are already marked in _allExams
          if (_freeExamData != null && _allExams.isNotEmpty) {
            List<Exam> filteredExams;
            if (newSelectedType != null && newSelectedType.isNotEmpty) {
              filteredExams = _allExams
                  .where(
                    (exam) =>
                        exam.examType?.toLowerCase() ==
                        newSelectedType.toLowerCase(),
                  )
                  .toList();
              debugPrint(
                '✅ Filtered by type: ${filteredExams.length} exams match $newSelectedType',
              );
            } else {
              filteredExams = List.from(_allExams);
              debugPrint('✅ Showing all exams: ${filteredExams.length} exams');
            }

            _freeExamData = FreeExamData(
              exams: filteredExams,
              isFreeUser: _freeExamData!.isFreeUser,
              freeExamsRemaining: _freeExamData!.freeExamsRemaining,
              paymentInstructions: _freeExamData!.paymentInstructions,
            );
          }
        });
        debugPrint(
          '🔄 Filtered to ${_freeExamData?.exams.length ?? 0} exams for type: $_selectedExamType',
        );
      },
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.white,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.white : AppColors.grey700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  List<Widget> _buildExamsByType() {
    // If filtering by type, show filtered list from API
    if (_selectedExamType != null) {
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
                    'No Exams Available',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'No exams found for this language',
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
              childAspectRatio: 0.75,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
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
      ];
    }

    // Group exams by type
    final Map<String, List<Exam>> examsByType = {};
    for (final exam in _freeExamData!.exams) {
      // Handle null examType: default to 'english' if null
      // Also try to infer from title if it contains language keywords
      String type = exam.examType?.toLowerCase() ?? 'english';
      
      // If examType is null, try to infer from title
      if (exam.examType == null) {
        final titleLower = exam.title.toLowerCase();
        if (titleLower.contains('kiny') || titleLower.contains('kinyarwanda')) {
          type = 'kinyarwanda';
        } else if (titleLower.contains('french') || titleLower.contains('français')) {
          type = 'french';
        } else {
          type = 'english'; // Default to english
        }
      }
      
      examsByType.putIfAbsent(type, () => []).add(exam);
    }

    // Order: kinyarwanda, english, french
    final orderedTypes = ['kinyarwanda', 'english', 'french'];
    final availableTypes = orderedTypes
        .where((type) => examsByType.containsKey(type))
        .toList();

    if (availableTypes.isEmpty) {
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
      ];
    }

    final List<Widget> slivers = [];

    // Add section headers and exams for each type
    for (final type in availableTypes) {
      final exams = examsByType[type]!;
      final displayName = type[0].toUpperCase() + type.substring(1);

      // Section header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: Row(
              children: [
                Icon(Icons.language, size: 20.sp, color: AppColors.primary),
                SizedBox(width: 8.w),
                Text(
                  '$displayName Exams',
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: 18.sp,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${exams.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Exams for this type
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final exam = exams[index];
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: _buildExamCard(exam, index),
                  ),
                ),
              );
            }, childCount: exams.length),
          ),
        ),
      );
    }

    return slivers;
  }

  Widget _buildExamCard(Exam exam, int index) {
    // Extract exam number from title (e.g., "exam 21" -> "21")
    final examNumber = exam.title.replaceAll(RegExp(r'[^0-9]'), '');
    final displayTitle = examNumber.isNotEmpty
        ? 'exam $examNumber'
        : exam.title;

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
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Exam Title
            Text(
              displayTitle,
              style: AppTextStyles.heading3.copyWith(
                fontSize: 18.sp,
                color: AppColors.grey800,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),

            // Questions Count
            Row(
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 16.sp,
                  color: AppColors.grey600,
                ),
                SizedBox(width: 6.w),
                Text(
                  '${exam.questionCount ?? 0} Questions',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey700,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Duration
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16.sp,
                  color: AppColors.grey600,
                ),
                SizedBox(width: 6.w),
                Text(
                  '${exam.duration}m',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey700,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Passing Score
            Row(
              children: [
                Icon(
                  Icons.trending_up_outlined,
                  size: 16.sp,
                  color: AppColors.grey600,
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    'Passing Score: ${exam.passingScore}%',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey700,
                      fontSize: 14.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Start Exam Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startExam(exam),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.grey800,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, size: 25.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Start Exam',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15.sp,
                        color: AppColors.white,
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
    // Check if this exam is marked as free (first 2 exams of each type)
    // Free status is determined per exam type (English, French, Kinyarwanda)
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
