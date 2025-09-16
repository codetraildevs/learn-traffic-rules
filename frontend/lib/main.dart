import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:learn_traffic_rules/screens/splash/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/app_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences
  await SharedPreferences.getInstance();

  // Initialize API service
  await ApiService().initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);

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
          home: _getInitialScreen(authState),
          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: widget!,
            );
          },
        );
      },
    );
  }

  Widget _getInitialScreen(AuthState authState) {
    switch (authState.status) {
      case AuthStatus.initial:
        return const SplashScreen();
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.loading:
        return const SplashScreen();
    }
  }
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
