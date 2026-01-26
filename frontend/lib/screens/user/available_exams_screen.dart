import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/screens/user/payment_instructions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../models/exam_model.dart';
import '../../widgets/custom_button.dart';
import '../../services/user_management_service.dart';
import '../../services/offline_exam_service.dart';
import '../../services/exam_sync_service.dart';
import '../../services/exam_service.dart';
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
  final ExamService _examService = ExamService();
  final NetworkService _networkService = NetworkService();
  // Track which exams are being pre-downloaded to avoid duplicate downloads
  final Set<String> _preloadingExams = {};
  FreeExamData? _freeExamData;
  List<Exam> _allExams = []; // Cache all exams
  bool _isLoadingFreeExams = true;
  bool _isOffline = false;
  bool _isSyncing = false;
  String? _selectedExamType;
  // Cache for image paths - key is imageUrl, value is cached path
  final Map<String, String?> _imagePathCache = {};
  // Track which images are being preloaded
  final Set<String> _preloadingImages = {};

  // Track previous access state to detect changes
  bool? _previousHasAccess;
  DateTime? _lastAccessRefresh;

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

  Timer? _periodicRefreshTimer;

  /// Load cached exams when access changes (works offline)
  /// This shows exams immediately from cache, then API will update if online
  Future<void> _loadCachedExamsForAccessChange() async {
    try {
      debugPrint('📱 Loading cached exams for access change...');

      // First, try to use in-memory cache
      if (_allExams.isNotEmpty) {
        debugPrint('📱 Using ${_allExams.length} exams from memory cache');
        await _applyCachedExamsToUI();
        return;
      }

      // If no memory cache, try offline database
      final offlineExams = await _offlineService.getAllExams();
      if (offlineExams.isNotEmpty) {
        debugPrint(
          '📱 Using ${offlineExams.length} exams from offline database',
        );
        // Mark free exams by type
        final examsWithFreeMarked = _markFreeExamsByType(offlineExams);
        // Store in memory cache
        _allExams = examsWithFreeMarked;
        await _applyCachedExamsToUI();
        return;
      }

      debugPrint('📱 No cached exams found');
    } catch (e) {
      debugPrint('❌ Error loading cached exams: $e');
    }
  }

  /// Apply cached exams to UI (filter by selected type and update state)
  Future<void> _applyCachedExamsToUI() async {
    if (_allExams.isEmpty) return;

    // Ensure _selectedExamType is set
    if (_selectedExamType == null) {
      final currentLocale = ref.read(localeProvider);
      _selectedExamType = _mapLocaleToExamType(currentLocale.languageCode);
    }

    // Check user access from authProvider
    final authState = ref.read(authProvider);
    final hasAccess = authState.accessPeriod?.hasAccess ?? false;
    final isFreeUser = !hasAccess;

    // Load payment instructions from offline storage if available
    PaymentInstructions? offlinePaymentInstructions;
    if (isFreeUser) {
      offlinePaymentInstructions = await _loadPaymentInstructionsOffline();
    }

    // Filter by selected exam type
    final filteredExams = _allExams.where((exam) {
      String type = exam.examType?.toLowerCase() ?? 'english';
      if (exam.examType == null) {
        final titleLower = exam.title.toLowerCase();
        if (titleLower.contains('kiny') || titleLower.contains('kinyarwanda')) {
          type = 'kinyarwanda';
        } else if (titleLower.contains('french') ||
            titleLower.contains('français')) {
          type = 'french';
        }
      }
      return type == _selectedExamType!.toLowerCase();
    }).toList();

    if (mounted) {
      setState(() {
        _freeExamData = FreeExamData(
          exams: filteredExams,
          isFreeUser: isFreeUser,
          freeExamsRemaining: 0,
          paymentInstructions: offlinePaymentInstructions,
        );
        _isLoadingFreeExams = false;
      });

      // Preload image paths
      _preloadImagePaths();

      debugPrint('✅ Applied ${filteredExams.length} cached exams to UI');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _periodicRefreshTimer?.cancel();
    super.dispose();
  }

  /// Start periodic refresh of access period (every 30 seconds)
  /// This ensures access is detected even when screen is in background tab
  void _startPeriodicAccessRefresh() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Only refresh if we're online and user doesn't have access yet
      // (to detect when admin grants access)
      final authState = ref.read(authProvider);
      final hasAccess = authState.accessPeriod?.hasAccess ?? false;

      if (!hasAccess) {
        debugPrint(
          '🔄 Periodic access check (every 30s) - checking for new access...',
        );
        _networkService.hasInternetConnection().then((hasInternet) {
          if (hasInternet && mounted) {
            final authNotifier = ref.read(authProvider.notifier);
            authNotifier.refreshAccessPeriod().then((_) async {
              if (mounted) {
                final newAuthState = ref.read(authProvider);
                final newHasAccess =
                    newAuthState.accessPeriod?.hasAccess ?? false;
                if (newHasAccess && _previousHasAccess == false) {
                  debugPrint(
                    '🔄 Access detected during periodic check! Loading cached exams first...',
                  );
                  // Load cached exams first, then fetch from API if online
                  if (mounted) {
                    await _loadCachedExamsForAccessChange();
                    // Then fetch from API if online
                    final hasInternet = await _networkService
                        .hasInternetConnection();
                    if (hasInternet) {
                      _loadFreeExams(forceReload: true);
                    }
                  }
                  _previousHasAccess = newHasAccess;
                } else if (newHasAccess != _previousHasAccess) {
                  // Access status changed, load cached first
                  debugPrint(
                    '🔄 Access status changed, loading cached exams first...',
                  );
                  if (mounted) {
                    await _loadCachedExamsForAccessChange();
                    final hasInternet = await _networkService
                        .hasInternetConnection();
                    if (hasInternet) {
                      _loadFreeExams(forceReload: true);
                    }
                  }
                  _previousHasAccess = newHasAccess;
                }
              }
            });
          }
        });
      } else {
        // User already has access, cancel periodic refresh
        timer.cancel();
        debugPrint('✅ User has access, stopping periodic refresh');
      }
    });
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
          // Refresh access period when app comes to foreground
          final authNotifier = ref.read(authProvider.notifier);
          authNotifier.refreshAccessPeriod().then((_) {
            if (mounted) {
              _loadFreeExams(forceReload: true);
            }
          });
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Always set exam type based on current locale (auto-detect)
      final currentLocale = ref.read(localeProvider);
      final examTypeFromLocale = _mapLocaleToExamType(
        currentLocale.languageCode,
      );

      // Only update if different or not set
      if (_selectedExamType != examTypeFromLocale && mounted) {
        setState(() {
          _selectedExamType = examTypeFromLocale;
        });
      }

      // Initialize previous access state
      final authState = ref.read(authProvider);
      _previousHasAccess = authState.accessPeriod?.hasAccess ?? false;

      // Refresh access period when screen loads (to detect if admin granted access)
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.refreshAccessPeriod();

      // Update previous access state after refresh
      final refreshedAuthState = ref.read(authProvider);
      _previousHasAccess = refreshedAuthState.accessPeriod?.hasAccess ?? false;
      _lastAccessRefresh = DateTime.now(); // Initialize last refresh time

      // Initialize image cache service for offline support
      ImageCacheService.instance.initialize();
      _loadFreeExams();
      _setupConnectivityListener();

      // Set up periodic refresh when screen is visible (every 30 seconds)
      _startPeriodicAccessRefresh();
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

  /// Group exams by type for debugging
  Map<String, int> _groupExamsByType(List<Exam> exams) {
    final Map<String, int> examsByType = {};
    for (final exam in exams) {
      String type = exam.examType?.toLowerCase() ?? 'english';
      if (exam.examType == null) {
        final titleLower = exam.title.toLowerCase();
        if (titleLower.contains('kiny') || titleLower.contains('kinyarwanda')) {
          type = 'kinyarwanda';
        } else if (titleLower.contains('french') ||
            titleLower.contains('français')) {
          type = 'french';
        }
      }
      examsByType[type] = (examsByType[type] ?? 0) + 1;
    }
    return examsByType;
  }

  void _setupConnectivityListener() {
    // Listen for connectivity changes
    _networkService.connectivityStream.listen((connectivityResult) async {
      final hasInternet = await _networkService.hasInternetConnection();

      if (hasInternet && _isOffline) {
        // Internet came back - sync data
        debugPrint('🌐 Internet connection restored, syncing...');
        if (mounted) {
          setState(() {
            _isOffline = false;
            _isSyncing = true;
          });
        }

        // Refresh access period when internet comes back
        final authNotifier = ref.read(authProvider.notifier);
        await authNotifier.refreshAccessPeriod();

        // Sync results first, then download exams
        await _syncService.fullSync();

        // Reload exams after sync
        if (mounted) {
          await _loadFreeExams(forceReload: true);
        }

        if (mounted) {
          setState(() {
            _isSyncing = false;
          });
        }
      } else if (!hasInternet && !_isOffline) {
        // Internet lost
        debugPrint('🌐 Internet connection lost, using offline data');
        if (mounted) {
          setState(() {
            _isOffline = true;
          });
        }
      }
    });
  }

  Future<void> _loadFreeExams({bool forceReload = false}) async {
    // If we already have exams and not forcing reload, just filter client-side
    // BUT: Always reload if access status might have changed (forceReload = true)
    if (!forceReload && _allExams.isNotEmpty && _freeExamData != null) {
      debugPrint('🔄 Using cached exams, filtering client-side');
      _filterExamsClientSide();
      return;
    }

    // If forceReload is true, we'll merge with cached exams (preserves cache, adds/updates from API)
    if (forceReload) {
      debugPrint(
        '🔄 Force reload requested - will merge API exams with cached exams',
      );
    }

    try {
      if (mounted) {
        setState(() {
          _isLoadingFreeExams = true;
        });
      }

      // Check internet connection
      final hasInternet = await _networkService.hasInternetConnection();
      if (mounted) {
        setState(() {
          _isOffline = !hasInternet;
        });
      }

      if (hasInternet) {
        // Online: Refresh access period first to ensure we have latest access status
        final authNotifier = ref.read(authProvider.notifier);
        await authNotifier.refreshAccessPeriod();

        // Get updated access state after refresh
        final updatedAuthState = ref.read(authProvider);
        final hasAccess = updatedAuthState.accessPeriod?.hasAccess ?? false;
        debugPrint('🔄 Access status after refresh: hasAccess=$hasAccess');

        // Online: Try to load from API and download for offline
        debugPrint('🌐 Online: Loading exams from API...');
        try {
          final response = await _userManagementService.getFreeExams();
          debugPrint('🔄 Free exams response: $response');
          debugPrint(
            '🔄 Is free user: ${response.data.isFreeUser}, hasAccess: $hasAccess',
          );

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

            // Merge with existing cached exams instead of replacing
            // This preserves cached exams and adds/updates with new ones from API
            if (forceReload && _allExams.isNotEmpty) {
              debugPrint(
                '🔄 Merging ${examsWithFreeMarked.length} API exams with ${_allExams.length} cached exams',
              );
              // Create a map of existing exams by ID for quick lookup
              final existingExamsMap = <String, Exam>{};
              for (final exam in _allExams) {
                existingExamsMap[exam.id] = exam;
              }

              // Add/update exams from API
              for (final exam in examsWithFreeMarked) {
                existingExamsMap[exam.id] = exam; // Update or add
              }

              // Convert back to list
              _allExams = existingExamsMap.values.toList();
              debugPrint('🔄 After merge: ${_allExams.length} total exams');
            } else {
              // No existing cache or not force reload, just set directly
              _allExams = examsWithFreeMarked;
            }

            // Filter by selected exam type
            final filteredExams = _allExams.where((exam) {
              String type = exam.examType?.toLowerCase() ?? 'english';
              if (exam.examType == null) {
                final titleLower = exam.title.toLowerCase();
                if (titleLower.contains('kiny') ||
                    titleLower.contains('kinyarwanda')) {
                  type = 'kinyarwanda';
                } else if (titleLower.contains('french') ||
                    titleLower.contains('français')) {
                  type = 'french';
                }
              }
              final examTypeToFilter =
                  _selectedExamType ??
                  _mapLocaleToExamType(ref.read(localeProvider).languageCode);
              return type == examTypeToFilter.toLowerCase();
            }).toList();

            if (mounted) {
              setState(() {
                _freeExamData = FreeExamData(
                  exams: filteredExams, // Set filtered exams directly
                  isFreeUser: response.data.isFreeUser,
                  freeExamsRemaining: response.data.freeExamsRemaining,
                  paymentInstructions: response.data.paymentInstructions,
                );
                _isLoadingFreeExams = false;
              });
            }

            debugPrint(
              '🌐 Online: Filtered to ${filteredExams.length} exams for type: ${_selectedExamType ?? _mapLocaleToExamType(ref.read(localeProvider).languageCode)}',
            );

            // Download ALL exams for offline use in background (not just free exams)
            // Only start download if we still have internet
            // Use forceDownload=false to only download new/updated exams
            _networkService.hasInternetConnection().then((stillOnline) async {
              if (stillOnline) {
                // Initialize image cache service
                await ImageCacheService.instance.initialize();

                // Cache exam images in background
                for (final exam in examsWithFreeMarked) {
                  if (exam.examImgUrl != null && exam.examImgUrl!.isNotEmpty) {
                    // Construct full image URL using baseUrlImage
                    final imageUrl = exam.examImgUrl!.startsWith('http')
                        ? exam.examImgUrl!
                        : '${AppConstants.baseUrlImage}${exam.examImgUrl}';
                    ImageCacheService.instance.cacheImage(imageUrl).catchError((
                      e,
                    ) {
                      debugPrint('⚠️ Failed to cache exam image: $e');
                      return null;
                    });
                  }
                }

                // Download ALL exams for offline use - ensure all exams are cached
                // This is critical for offline functionality
                try {
                  await _syncService.downloadAllExams(forceDownload: false);
                  debugPrint('✅ All exams downloaded for offline use');
                } catch (e) {
                  debugPrint('⚠️ Failed to download exams offline: $e');
                }
              } else {
                debugPrint(
                  '🌐 Internet connection lost, skipping exam download',
                );
              }
            });

            // Preload all image paths for the filtered exams
            _preloadImagePaths();

            // Pre-download questions for visible exams in background (non-blocking)
            // This ensures questions are cached before user clicks "Start Exam"
            _preloadExamQuestions(filteredExams);
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
      if (mounted) {
        setState(() {
          _isLoadingFreeExams = false;
        });
      }
    }
  }

  Future<void> _loadOfflineExams() async {
    try {
      // If we already have exams cached in _allExams, use those instead of reloading from DB
      // This preserves all exams that were loaded when online
      if (_allExams.isNotEmpty) {
        debugPrint(
          '📱 Offline: Using ${_allExams.length} cached exams from memory (not reloading from DB)',
        );

        // Ensure _selectedExamType is set before filtering
        if (_selectedExamType == null) {
          final currentLocale = ref.read(localeProvider);
          _selectedExamType = _mapLocaleToExamType(currentLocale.languageCode);
          debugPrint('📱 Set _selectedExamType to: $_selectedExamType');
        }

        // Check user access from authProvider (stored in SharedPreferences)
        final authState = ref.read(authProvider);
        final hasAccess = authState.accessPeriod?.hasAccess ?? false;
        final isFreeUser = !hasAccess; // User is free if they don't have access

        // Load payment instructions from offline storage if available
        PaymentInstructions? offlinePaymentInstructions;
        if (isFreeUser) {
          offlinePaymentInstructions = await _loadPaymentInstructionsOffline();
        }

        debugPrint('📱 Offline: Total exams in cache: ${_allExams.length}');
        debugPrint('📱 Offline: Selected exam type: $_selectedExamType');

        // Group exams by type for debugging
        final Map<String, List<Exam>> examsByTypeDebug = {};
        for (final exam in _allExams) {
          String type = exam.examType?.toLowerCase() ?? 'english';
          if (exam.examType == null) {
            final titleLower = exam.title.toLowerCase();
            if (titleLower.contains('kiny') ||
                titleLower.contains('kinyarwanda')) {
              type = 'kinyarwanda';
            } else if (titleLower.contains('french') ||
                titleLower.contains('français')) {
              type = 'french';
            }
          }
          examsByTypeDebug.putIfAbsent(type, () => []).add(exam);
        }
        for (final entry in examsByTypeDebug.entries) {
          debugPrint(
            '📱 Offline: Type "${entry.key}": ${entry.value.length} exams',
          );
        }

        // Now filter and set state - filter by selected exam type
        final filteredExams = _allExams.where((exam) {
          String type = exam.examType?.toLowerCase() ?? 'english';
          if (exam.examType == null) {
            final titleLower = exam.title.toLowerCase();
            if (titleLower.contains('kiny') ||
                titleLower.contains('kinyarwanda')) {
              type = 'kinyarwanda';
            } else if (titleLower.contains('french') ||
                titleLower.contains('français')) {
              type = 'french';
            }
          }
          return type == _selectedExamType!.toLowerCase();
        }).toList();

        debugPrint(
          '📱 Offline: After filtering by type "$_selectedExamType": ${filteredExams.length} exams',
        );

        setState(() {
          _freeExamData = FreeExamData(
            exams: filteredExams, // Set filtered exams directly
            isFreeUser: isFreeUser,
            freeExamsRemaining: 0,
            paymentInstructions: offlinePaymentInstructions,
          );
          _isLoadingFreeExams = false;
        });

        // Preload all image paths for the filtered exams
        _preloadImagePaths();

        // Pre-download questions for visible exams in background (if online)
        _preloadExamQuestions(filteredExams);
        return; // Exit early since we used cached exams
      }

      // If _allExams is empty, load from offline database
      final offlineExams = await _offlineService.getAllExams();

      if (offlineExams.isNotEmpty) {
        debugPrint(
          '📱 Loaded ${offlineExams.length} exams from offline database',
        );
        debugPrint(
          '📱 Offline exams by type: ${_groupExamsByType(offlineExams)}',
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

        // Store all exams first
        _allExams = examsWithFreeMarked;

        debugPrint(
          '📱 Offline: Total exams loaded from DB: ${examsWithFreeMarked.length}',
        );
        debugPrint('📱 Offline: Selected exam type: $_selectedExamType');

        // Group exams by type for debugging
        final Map<String, List<Exam>> examsByTypeDebug2 = {};
        for (final exam in examsWithFreeMarked) {
          String type = exam.examType?.toLowerCase() ?? 'english';
          if (exam.examType == null) {
            final titleLower = exam.title.toLowerCase();
            if (titleLower.contains('kiny') ||
                titleLower.contains('kinyarwanda')) {
              type = 'kinyarwanda';
            } else if (titleLower.contains('french') ||
                titleLower.contains('français')) {
              type = 'french';
            }
          }
          examsByTypeDebug2.putIfAbsent(type, () => []).add(exam);
        }
        for (final entry in examsByTypeDebug2.entries) {
          debugPrint(
            '📱 Offline: Type "${entry.key}": ${entry.value.length} exams',
          );
        }

        // Now filter and set state
        // Filter by selected exam type first
        final filteredExams = _allExams.where((exam) {
          String type = exam.examType?.toLowerCase() ?? 'english';
          if (exam.examType == null) {
            final titleLower = exam.title.toLowerCase();
            if (titleLower.contains('kiny') ||
                titleLower.contains('kinyarwanda')) {
              type = 'kinyarwanda';
            } else if (titleLower.contains('french') ||
                titleLower.contains('français')) {
              type = 'french';
            }
          }
          return type == _selectedExamType!.toLowerCase();
        }).toList();

        debugPrint(
          '📱 Offline: After filtering by type "$_selectedExamType": ${filteredExams.length} exams',
        );

        if (mounted) {
          setState(() {
            _freeExamData = FreeExamData(
              exams: filteredExams, // Set filtered exams directly
              isFreeUser: isFreeUser,
              freeExamsRemaining: 0,
              paymentInstructions: offlinePaymentInstructions,
            );
            _isLoadingFreeExams = false;
          });
        }

        // Preload all image paths for the filtered exams
        _preloadImagePaths();

        // Pre-download questions for visible exams in background (if online)
        _preloadExamQuestions(filteredExams);
      } else {
        debugPrint('📱 No offline exams available');
        if (mounted) {
          setState(() {
            _isLoadingFreeExams = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading offline exams: $e');
      if (mounted) {
        setState(() {
          _isLoadingFreeExams = false;
        });
      }
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
    // Then apply search filter if search query is not empty
    var filteredExams = _allExams.where((exam) {
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
    if (filteredExams.isNotEmpty) {
      debugPrint(
        '   Exam titles: ${filteredExams.take(5).map((e) => e.title).join(", ")}${filteredExams.length > 5 ? "..." : ""}',
      );
    }

    if (mounted) {
      setState(() {
        _freeExamData = FreeExamData(
          exams: filteredExams,
          isFreeUser: _freeExamData!.isFreeUser,
          freeExamsRemaining: _freeExamData!.freeExamsRemaining,
          paymentInstructions: _freeExamData!.paymentInstructions,
        );
      });
    }
    debugPrint(
      '🔄 Filtered to ${filteredExams.length} exams for type: $examTypeToFilter (total in _allExams: ${_allExams.length})',
    );

    // Preload image paths after filtering
    _preloadImagePaths();

    // Pre-download questions for visible exams in background (if online)
    _preloadExamQuestions(filteredExams);
  }

  /// Preload all image paths for currently filtered exams
  Future<void> _preloadImagePaths() async {
    if (_freeExamData == null || _freeExamData!.exams.isEmpty) {
      return;
    }

    debugPrint(
      '🖼️ Preloading image paths for ${_freeExamData!.exams.length} exams',
    );

    // Collect all unique image URLs
    final Set<String> imageUrls = {};
    for (final exam in _freeExamData!.exams) {
      if (exam.examImgUrl != null && exam.examImgUrl!.isNotEmpty) {
        final imageUrl = exam.examImgUrl!.startsWith('http')
            ? exam.examImgUrl!
            : '${AppConstants.baseUrlImage}${exam.examImgUrl}';
        imageUrls.add(imageUrl);
      }
    }

    // Preload all image paths concurrently
    final List<Future<void>> preloadFutures = [];
    for (final imageUrl in imageUrls) {
      // Skip if already cached or being preloaded
      if (_imagePathCache.containsKey(imageUrl) ||
          _preloadingImages.contains(imageUrl)) {
        continue;
      }

      _preloadingImages.add(imageUrl);
      preloadFutures.add(
        ImageCacheService.instance
            .getImagePath(imageUrl)
            .then((path) {
              if (mounted) {
                setState(() {
                  _imagePathCache[imageUrl] = path;
                  _preloadingImages.remove(imageUrl);
                });
              }
            })
            .catchError((e) {
              debugPrint('⚠️ Failed to preload image path for $imageUrl: $e');
              if (mounted) {
                setState(() {
                  _imagePathCache[imageUrl] = null;
                  _preloadingImages.remove(imageUrl);
                });
              }
            }),
      );
    }

    // Wait for all preloads to complete
    await Future.wait(preloadFutures);
    debugPrint('🖼️ Finished preloading ${imageUrls.length} image paths');
  }

  /// Pre-download questions for visible exams in background
  /// This ensures questions are cached before user clicks "Start Exam"
  Future<void> _preloadExamQuestions(List<Exam> exams) async {
    if (exams.isEmpty) return;

    // Check internet connection first
    final hasInternet = await _networkService.hasInternetConnection();
    if (!hasInternet) {
      debugPrint('📱 Offline: Skipping question pre-download');
      return;
    }

    debugPrint(
      '📥 Pre-downloading questions for ${exams.length} visible exams...',
    );

    // Pre-download questions for each exam in background (non-blocking)
    for (final exam in exams) {
      // Skip if already preloading or if exam ID is invalid
      if (_preloadingExams.contains(exam.id) || exam.id.isEmpty) {
        continue;
      }

      // Check if questions are already cached offline
      final examData = await _offlineService.getExam(exam.id);
      if (examData != null && examData['questions'] != null) {
        final cachedQuestions = examData['questions'] as List;
        if (cachedQuestions.isNotEmpty) {
          debugPrint('✅ Questions already cached for exam ${exam.id}');
          continue;
        }
      }

      // Mark as preloading
      _preloadingExams.add(exam.id);

      // Pre-download questions in background (non-blocking)
      _preloadQuestionsForExam(exam).catchError((e) {
        debugPrint(
          '⚠️ Failed to pre-download questions for exam ${exam.id}: $e',
        );
        _preloadingExams.remove(exam.id);
      });
    }
  }

  /// Pre-download questions for a specific exam
  Future<void> _preloadQuestionsForExam(Exam exam) async {
    try {
      debugPrint(
        '📥 Pre-downloading questions for exam: ${exam.id} (${exam.title})',
      );

      // Fetch questions from API
      final questions = await _examService.getQuestionsByExamId(
        exam.id,
        isFreeExam: exam.isFirstTwo ?? false,
        examType: exam.examType,
      );

      if (questions.isNotEmpty) {
        // Save to offline storage
        await _offlineService.saveExam(exam, questions);
        debugPrint(
          '✅ Pre-downloaded ${questions.length} questions for exam ${exam.id}',
        );
      } else {
        debugPrint('⚠️ No questions found for exam ${exam.id}');
      }
    } catch (e) {
      debugPrint('❌ Error pre-downloading questions for exam ${exam.id}: $e');
      rethrow;
    } finally {
      _preloadingExams.remove(exam.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth provider for access period changes
    final authState = ref.watch(authProvider);
    final currentHasAccess = authState.accessPeriod?.hasAccess ?? false;

    // Detect access period changes and refresh exams automatically
    // Only check if the value has changed to avoid unnecessary refreshes
    if (_previousHasAccess != currentHasAccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleAccessPeriodChange(currentHasAccess);
        }
      });
    }

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

  /// Handle access period changes - refresh exams when access is granted
  void _handleAccessPeriodChange(bool currentHasAccess) async {
    debugPrint(
      '🔄 Access period change detected: $_previousHasAccess -> $currentHasAccess',
    );

    // Only refresh if access status changed from no access to having access
    if (_previousHasAccess != null &&
        _previousHasAccess == false &&
        currentHasAccess == true) {
      debugPrint(
        '🔄 Access granted! Loading cached exams first, then fetching missing from API...',
      );

      if (mounted) {
        // Step 1: Load cached exams first (works offline, instant display)
        await _loadCachedExamsForAccessChange();

        // Step 2: If online, fetch from API to get any new/missing exams
        final hasInternet = await _networkService.hasInternetConnection();
        if (hasInternet) {
          debugPrint('🔄 Online: Fetching new/missing exams from API...');
          // Fetch from API and merge with cached exams
          await _loadFreeExams(forceReload: true);
        } else {
          debugPrint('📱 Offline: Using cached exams only');
        }
      }
    }

    // Also refresh periodically (every 30 seconds) when user has access
    // This ensures access is detected even if the change wasn't detected immediately
    if (currentHasAccess) {
      final now = DateTime.now();
      if (_lastAccessRefresh == null ||
          now.difference(_lastAccessRefresh!).inSeconds >= 30) {
        debugPrint('🔄 Periodic access refresh (every 30s)...');
        _lastAccessRefresh = now;
        final authNotifier = ref.read(authProvider.notifier);
        authNotifier.refreshAccessPeriod().then((_) {
          if (mounted) {
            // Reload exams to ensure we have the latest data
            final newAuthState = ref.read(authProvider);
            final newHasAccess = newAuthState.accessPeriod?.hasAccess ?? false;
            if (newHasAccess) {
              debugPrint('🔄 Access confirmed, reloading exams...');
              _loadFreeExams(forceReload: true);
            }
          }
        });
      }
    }

    // Update previous access state
    _previousHasAccess = currentHasAccess;
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
          backgroundColor: AppColors.primary,
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
          ),
        ),

        // Language Dropdown Section (below app bar)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: _buildLanguageDropdownSection(),
          ),
        ),

        // Exams filtered by selected language
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
      {'code': 'rw', 'examType': 'kinyarwanda', 'name': l10n.ikinyarwanda},
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
              final flag = option['flag'];
              return DropdownMenuItem<String>(
                value: option['examType']!,
                child: Row(
                  children: [
                    if (flag != null && flag.isNotEmpty)
                      Text(flag, style: TextStyle(fontSize: 20.sp))
                    else
                      Icon(
                        Icons.language,
                        size: 20.sp,
                        color: AppColors.primary,
                      ),
                    SizedBox(width: 8.w),
                    Text(
                      option['name']!,
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
              final localeCode = languageOption['code']!;

              // Update locale provider
              final localeNotifier = ref.read(localeProvider.notifier);
              await localeNotifier.setLocale(Locale(localeCode));

              // Clear image cache when language changes to reload images for new language
              if (mounted) {
                setState(() {
                  _selectedExamType = newExamType;
                  _imagePathCache
                      .clear(); // Clear cache to reload images for new language
                });
              }

              // Check if we're offline
              final hasInternet = await _networkService.hasInternetConnection();

              // If we have cached exams, filter them immediately
              if (_allExams.isNotEmpty && _freeExamData != null) {
                debugPrint(
                  '🔄 Language changed: Filtering cached exams immediately',
                );
                debugPrint(
                  '📱 _allExams has ${_allExams.length} exams before filtering',
                );
                // Log exams by type for debugging
                final Map<String, int> examsByTypeCount = {};
                for (final exam in _allExams) {
                  String type = exam.examType?.toLowerCase() ?? 'english';
                  if (exam.examType == null) {
                    final titleLower = exam.title.toLowerCase();
                    if (titleLower.contains('kiny') ||
                        titleLower.contains('kinyarwanda')) {
                      type = 'kinyarwanda';
                    } else if (titleLower.contains('french') ||
                        titleLower.contains('français')) {
                      type = 'french';
                    }
                  }
                  examsByTypeCount[type] = (examsByTypeCount[type] ?? 0) + 1;
                }
                for (final entry in examsByTypeCount.entries) {
                  debugPrint(
                    '📱 _allExams: ${entry.value} exams of type "${entry.key}"',
                  );
                }
                _filterExamsClientSide();

                // Only reload from source if online (to get latest data)
                // If offline, don't reload because it will overwrite cache with limited offline data
                if (hasInternet) {
                  debugPrint('🌐 Online: Reloading from API in background');
                  _loadFreeExams(forceReload: true);
                } else {
                  debugPrint(
                    '📱 Offline: Using cached exams, not reloading from DB',
                  );
                }
              } else {
                // No cached exams, reload from source (API if online, DB if offline)
                await _loadFreeExams(forceReload: true);
              }
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

    // Get exams filtered by language (from _filterExamsClientSide)
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
            childAspectRatio: 0.80,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 8.h,
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
        ? '${l10n.practiceExamTitle} $examNumber'
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
          color: AppColors.primary.withValues(alpha: 0.2),
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
            // Exam Image - use cached path if available
            if (imageUrl != null)
              _buildExamImage(imageUrl)
            else
              _buildImagePlaceholder(),

            // Exam Title
            Expanded(
              child: Text(
                displayTitle,
                style: AppTextStyles.heading3.copyWith(
                  fontSize: 16.sp,
                  color: AppColors.grey800,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // SizedBox(height: 6.h),

            // Start Exam Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startExam(exam),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.white,
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

    // Navigate to exam taking screen immediately without waiting
    // Use hasAccess to determine if it's a free exam (free exam = hasAccess && isFreeExam)
    // If user has access, all exams are accessible, so isFreeExam should be false
    final isFreeExamForUser = !hasAccess && isFreeExam;

    // Use unawaited navigation to avoid blocking the UI
    Navigator.of(context).push(
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

  Widget _buildExamImage(String imageUrl) {
    // Check if we have cached path
    final cachedPath = _imagePathCache[imageUrl];

    if (cachedPath != null && cachedPath.isNotEmpty) {
      // Check if it's a network URL
      final isNetworkUrl =
          cachedPath.startsWith('http://') ||
          cachedPath.startsWith('https://') ||
          cachedPath.startsWith('file://');

      // Handle file:// URI by extracting the actual path
      String? localFilePath;
      if (cachedPath.startsWith('file://')) {
        try {
          final uri = Uri.parse(cachedPath);
          localFilePath = uri.path;
        } catch (e) {
          debugPrint('❌ Error parsing file:// URI: $cachedPath - $e');
          localFilePath = null;
        }
      } else if (!isNetworkUrl) {
        localFilePath = cachedPath;
      }

      if (localFilePath != null) {
        // Use cached local file - validate path first
        try {
          final file = File(localFilePath);
          // Check if file exists before trying to load
          if (file.existsSync()) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.file(
                file,
                width: double.infinity,
                height: 85.h,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint(
                    '❌ Error loading cached image file: $localFilePath - $error',
                  );
                  // Clear invalid cache entry
                  _imagePathCache.remove(imageUrl);
                  return _buildImagePlaceholder();
                },
              ),
            );
          } else {
            // File doesn't exist, try network or show placeholder
            debugPrint('⚠️ Cached file does not exist: $localFilePath');
            // Clear invalid cache entry
            _imagePathCache.remove(imageUrl);
            // Fall through to network loading
          }
        } catch (e) {
          debugPrint('❌ Error accessing cached file: $localFilePath - $e');
          // Clear invalid cache entry
          _imagePathCache.remove(imageUrl);
          // Fall through to network loading
        }
      } else if (isNetworkUrl && !cachedPath.startsWith('file://')) {
        // Network URL from cache
        if (_isOffline) {
          return _buildImagePlaceholder();
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.network(
            cachedPath,
            width: double.infinity,
            height: 85.h,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint(
                '❌ Error loading cached network image: $cachedPath - $error',
              );
              // Clear invalid cache entry
              _imagePathCache.remove(imageUrl);
              return _buildImagePlaceholder();
            },
          ),
        );
      }
    }

    // Path not yet cached or invalid, try to load directly
    if (_isOffline) {
      // Offline and not cached, show placeholder
      return _buildImagePlaceholder();
    }
    // Online, try network image
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: 85.h,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Error loading network image: $imageUrl - $error');
          return _buildImagePlaceholder();
        },
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
