import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/locale_service.dart';
import '../services/user_management_service.dart';
import 'auth_provider.dart';

/// Provider for managing app locale
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(ref),
);

class LocaleNotifier extends StateNotifier<Locale> {
  final Ref _ref;
  final UserManagementService _userManagementService = UserManagementService();

  LocaleNotifier(this._ref) : super(const Locale('rw')) {
    loadSavedLocale();
  }

  /// Load saved locale from storage
  Future<void> loadSavedLocale() async {
    try {
      final savedLocaleCode = await LocaleService.getSavedLocale();
      if (savedLocaleCode != null) {
        state = Locale(savedLocaleCode);
      }
    } catch (e) {
      debugPrint('Error loading saved locale: $e');
      // Keep default locale (Kinyarwanda)
    }
  }

  /// Set locale and save to storage
  /// Also updates preferred language in backend if user is authenticated
  Future<void> setLocale(Locale locale) async {
    try {
      await LocaleService.saveLocale(locale.languageCode);
      state = locale;
      debugPrint('Locale changed to: ${locale.languageCode}');

      // Update preferred language in backend if user is authenticated
      final authState = _ref.read(authProvider);
      if (authState.status == AuthStatus.authenticated && authState.user != null) {
        // Update in background (non-blocking)
        _userManagementService.updatePreferredLanguage(locale.languageCode).catchError((e) {
          debugPrint('⚠️ Failed to update preferred language in backend: $e');
          // Don't throw - language change should still work even if backend update fails
          return <String, dynamic>{};
        });
      }
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  /// Get current locale
  Locale get currentLocale => state;
}
