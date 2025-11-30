import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/locale_service.dart';

/// Provider for managing app locale
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
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
      // Keep default locale (English)
    }
  }

  /// Set locale and save to storage
  Future<void> setLocale(Locale locale) async {
    try {
      await LocaleService.saveLocale(locale.languageCode);
      state = locale;
      debugPrint('Locale changed to: ${locale.languageCode}');
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  /// Get current locale
  Locale get currentLocale => state;
}

