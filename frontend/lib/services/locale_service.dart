import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const String _localeKey = 'app_locale';
  static const String _languageSelectedKey = 'language_selected';

  /// Get saved locale code
  static Future<String?> getSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_localeKey);
    } catch (e) {
      debugPrint('Error getting saved locale: $e');
      return null;
    }
  }

  /// Save locale code
  static Future<bool> saveLocale(String localeCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_localeKey, localeCode);
    } catch (e) {
      debugPrint('Error saving locale: $e');
      return false;
    }
  }

  /// Check if language has been selected
  static Future<bool> isLanguageSelected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_languageSelectedKey) ?? false;
    } catch (e) {
      debugPrint('Error checking language selection: $e');
      return false;
    }
  }

  /// Mark language as selected
  static Future<bool> setLanguageSelected(bool selected) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_languageSelectedKey, selected);
    } catch (e) {
      debugPrint('Error setting language selection: $e');
      return false;
    }
  }

  /// Clear saved locale (for testing/debugging)
  static Future<bool> clearLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_localeKey);
    } catch (e) {
      debugPrint('Error clearing locale: $e');
      return false;
    }
  }
}

