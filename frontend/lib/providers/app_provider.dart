import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/theme_service.dart';

// Theme Mode Provider

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    loadSavedThemeMode();
  }

  /// Load saved theme mode from storage
  Future<void> loadSavedThemeMode() async {
    try {
      final savedThemeMode = await ThemeService.getSavedThemeMode();
      state = savedThemeMode;
      debugPrint('Theme mode loaded: $savedThemeMode');
    } catch (e) {
      debugPrint('Error loading saved theme mode: $e');
      // Keep default theme (system)
    }
  }

  /// Set theme mode and save to storage
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      await ThemeService.saveThemeMode(mode);
      state = mode;
      debugPrint('Theme mode changed to: $mode');
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  /// Get current theme mode
  ThemeMode get currentThemeMode => state;
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

// Connectivity Provider
class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    // In a real app, you would use connectivity_plus package
    // For now, we'll assume connected
    state = true;
  }

  void setConnected(bool connected) {
    state = connected;
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>((
  ref,
) {
  return ConnectivityNotifier();
});

// App State Provider
class AppState {
  final bool isOnline;
  final bool isInitialized;
  final String? error;
  final Map<String, dynamic>? userPreferences;

  AppState({
    required this.isOnline,
    required this.isInitialized,
    this.error,
    this.userPreferences,
  });

  AppState copyWith({
    bool? isOnline,
    bool? isInitialized,
    String? error,
    Map<String, dynamic>? userPreferences,
  }) {
    return AppState(
      isOnline: isOnline ?? this.isOnline,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
      userPreferences: userPreferences ?? this.userPreferences,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState(isOnline: true, isInitialized: false)) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize app state
      await _loadUserPreferences();

      state = state.copyWith(isInitialized: true);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isInitialized: true);
    }
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final preferences = <String, dynamic>{};

    // Load notification preferences
    preferences['notifications'] = {
      'examReminders': prefs.getBool('exam_reminders') ?? true,
      'paymentUpdates': prefs.getBool('payment_updates') ?? true,
      'studyReminders': prefs.getBool('study_reminders') ?? true,
      'achievementNotifications':
          prefs.getBool('achievement_notifications') ?? true,
    };

    // Load other preferences
    preferences['autoSync'] = prefs.getBool('auto_sync') ?? true;
    preferences['offlineMode'] = prefs.getBool('offline_mode') ?? false;

    state = state.copyWith(userPreferences: preferences);
  }

  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    final prefs = await SharedPreferences.getInstance();

    // Save notification preferences
    if (preferences.containsKey('notifications')) {
      final notifications =
          preferences['notifications'] as Map<String, dynamic>;
      await prefs.setBool(
        'exam_reminders',
        notifications['examReminders'] ?? true,
      );
      await prefs.setBool(
        'payment_updates',
        notifications['paymentUpdates'] ?? true,
      );
      await prefs.setBool(
        'study_reminders',
        notifications['studyReminders'] ?? true,
      );
      await prefs.setBool(
        'achievement_notifications',
        notifications['achievementNotifications'] ?? true,
      );
    }

    // Save other preferences
    if (preferences.containsKey('autoSync')) {
      await prefs.setBool('auto_sync', preferences['autoSync'] ?? true);
    }
    if (preferences.containsKey('offlineMode')) {
      await prefs.setBool('offline_mode', preferences['offlineMode'] ?? false);
    }

    state = state.copyWith(userPreferences: preferences);
  }

  void setOnlineStatus(bool isOnline) {
    state = state.copyWith(isOnline: isOnline);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((
  ref,
) {
  return AppStateNotifier();
});

// Convenience providers
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isOnline;
});

final isInitializedProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).isInitialized;
});

final userPreferencesProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(appStateProvider).userPreferences;
});

final appErrorProvider = Provider<String?>((ref) {
  return ref.watch(appStateProvider).error;
});

// Notification Preferences Provider
final notificationPreferencesProvider = Provider<Map<String, bool>>((ref) {
  final preferences = ref.watch(userPreferencesProvider);
  if (preferences != null && preferences.containsKey('notifications')) {
    return Map<String, bool>.from(preferences['notifications']);
  }
  return {
    'examReminders': true,
    'paymentUpdates': true,
    'studyReminders': true,
    'achievementNotifications': true,
  };
});

// App Settings Provider
final appSettingsProvider = Provider<Map<String, dynamic>>((ref) {
  final preferences = ref.watch(userPreferencesProvider);
  return {
    'autoSync': preferences?['autoSync'] ?? true,
    'offlineMode': preferences?['offlineMode'] ?? false,
    'themeMode': ref.watch(themeModeProvider),
    'isOnline': ref.watch(isOnlineProvider),
  };
});
