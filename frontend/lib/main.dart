import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flash_message/flash_message.dart';
import 'package:learn_traffic_rules/screens/auth/register_screen.dart';
// import 'package:firebase_core/firebase_core.dart';  // Temporarily disabled
import 'package:learn_traffic_rules/screens/splash/splash_screen.dart';
import 'package:learn_traffic_rules/screens/onboarding/disclaimer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/simple_notification_service.dart';
import 'services/notification_polling_service.dart';
import 'services/exam_sync_service.dart';
import 'services/network_service.dart';
import 'providers/auth_provider.dart';
import 'providers/app_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/user/view_profile_screen.dart';
import 'screens/user/about_app_screen.dart';
import 'screens/user/privacy_policy_screen.dart';
import 'screens/user/terms_conditions_screen.dart';
import 'screens/user/delete_account_screen.dart';
import 'screens/user/notifications_screen.dart';
import 'screens/user/study_reminders_screen.dart';
import 'screens/user/help_support_screen.dart';

// Provider for disclaimer status
final disclaimerAcceptedProvider = StateProvider<bool>((ref) => false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (temporarily disabled)
  // try {
  //   await Firebase.initializeApp();
  //   debugPrint('✅ Firebase initialized successfully');
  // } catch (e) {
  //   debugPrint('⚠️ Firebase initialization failed: $e');
  // }

  // Initialize shared preferences
  await SharedPreferences.getInstance();

  // Initialize API service
  await ApiService().initialize();

  // Initialize notification service with fallback
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint(
      '⚠️ Main notification service failed, using simple fallback: $e',
    );
    await SimpleNotificationService().initialize();
  }

  // Start notification polling service
  try {
    await NotificationPollingService().startPolling();
    debugPrint('✅ Notification polling service started');
  } catch (e) {
    debugPrint('⚠️ Failed to start notification polling service: $e');
  }

  // Initialize offline exam sync
  try {
    final networkService = NetworkService();
    final hasInternet = await networkService.hasInternetConnection();

    if (hasInternet) {
      // Download exams for offline use in background
      final syncService = ExamSyncService();
      syncService.downloadAllExams().catchError((e) {
        debugPrint('⚠️ Failed to download exams on startup: $e');
      });
      debugPrint('✅ Offline exam sync initialized');
    } else {
      debugPrint('📱 No internet on startup, will use offline data');
    }
  } catch (e) {
    debugPrint('⚠️ Failed to initialize offline sync: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Initialize disclaimer status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDisclaimerStatus(ref);
    });

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: FlashMessageOverlay(
            position: FlashMessagePosition.center,
            child: _getInitialScreen(authState),
          ),
          routes: {
            '/main': (context) => _getInitialScreen(authState),
            '/disclaimer': (context) => const DisclaimerScreen(),
            '/view-profile': (context) => const ViewProfileScreen(),
            '/about-app': (context) => const AboutAppScreen(),
            '/privacy-policy': (context) => const PrivacyPolicyScreen(),
            '/terms-conditions': (context) => const TermsConditionsScreen(),
            '/delete-account': (context) => const DeleteAccountScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/study-reminders': (context) => const StudyRemindersScreen(),
            '/help-support': (context) => const HelpSupportScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
          },
          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: widget!,
            );
          },
        );
      },
    );
  }

  Widget _getInitialScreen(AuthState authState) {
    return Consumer(
      builder: (context, ref, child) {
        final disclaimerAccepted = ref.watch(disclaimerAcceptedProvider);

        // If disclaimer not accepted, show disclaimer screen
        if (!disclaimerAccepted) {
          debugPrint(
            '🔄 MAIN: Disclaimer not accepted, showing DisclaimerScreen',
          );
          return const DisclaimerScreen();
        }

        // If disclaimer accepted, proceed with normal auth flow
        debugPrint('🔄 MAIN: Disclaimer accepted, checking auth state');
        debugPrint('🔄 MAIN: Auth state changed to: ${authState.status}');
        debugPrint('🔄 MAIN: User: ${authState.user?.fullName}');
        debugPrint('🔄 MAIN: Is loading: ${authState.isLoading}');
        debugPrint('🔄 MAIN: Auth provider state: ${ref.read(authProvider)}');

        // If auth state is still initial and disclaimer is accepted,
        // wait for auth initialization to complete
        if (authState.status == AuthStatus.initial) {
          debugPrint('🔄 MAIN: Auth still initializing, showing SplashScreen');
          return const SplashScreen();
        }

        switch (authState.status) {
          case AuthStatus.initial:
            debugPrint('🔄 MAIN: Showing SplashScreen');
            return const SplashScreen();
          case AuthStatus.authenticated:
            debugPrint('🔄 MAIN: Showing HomeScreen');
            return const HomeScreen();
          case AuthStatus.unauthenticated:
            debugPrint('🔄 MAIN: Showing LoginScreen');
            return const LoginScreen();
          case AuthStatus.loading:
            debugPrint('🔄 MAIN: Showing LoginScreen (loading)');
            // Don't show splash during login - stay on current screen
            return const LoginScreen();
        }
      },
    );
  }

  Future<void> _initializeDisclaimerStatus(WidgetRef ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final disclaimerAccepted = prefs.getBool('disclaimer_accepted') ?? false;
      ref.read(disclaimerAcceptedProvider.notifier).state = disclaimerAccepted;
      debugPrint('🔄 MAIN: Disclaimer status initialized: $disclaimerAccepted');
    } catch (e) {
      debugPrint('Error initializing disclaimer status: $e');
    }
  }

  // Future<bool> _checkDisclaimerAccepted() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     return prefs.getBool('disclaimer_accepted') ?? false;
  //   } catch (e) {
  //     debugPrint('Error checking disclaimer acceptance: $e');
  //     return false;
  //   }
  // }
}

// Global error handler
class GlobalErrorHandler {
  static void handleError(dynamic error, StackTrace stackTrace) {
    debugPrint('Global Error: $error');
    debugPrint('Stack Trace: $stackTrace');

    // In production, you might want to send this to a crash reporting service
    // like Firebase Crashlytics or Sentry
  }
}

// Global key for navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
