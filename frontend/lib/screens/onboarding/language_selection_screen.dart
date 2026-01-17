import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/locale_provider.dart';
import '../../services/locale_service.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
    // OPTIMIZATION: Auto-detect device language to reduce friction
    _autoDetectLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final savedLocale = await LocaleService.getSavedLocale();
    setState(() {
      _selectedLanguage = savedLocale ?? 'rw';
    });
  }

  // OPTIMIZATION: Auto-detect language from device settings
  Future<void> _autoDetectLanguage() async {
    // Check if language was already selected
    final isSelected = await LocaleService.isLanguageSelected();
    if (isSelected) return;

    // Get device locale
    final deviceLocale = Localizations.localeOf(context);
    final deviceLanguage = deviceLocale.languageCode;

    // Map device language to supported languages
    String? detectedLanguage;
    if (deviceLanguage == 'rw' || deviceLanguage == 'kin') {
      detectedLanguage = 'rw';
    } else if (deviceLanguage == 'en') {
      detectedLanguage = 'en';
    } else if (deviceLanguage == 'fr') {
      detectedLanguage = 'fr';
    }

    // If device language matches a supported language, auto-select it
    if (detectedLanguage != null && _selectedLanguage == null) {
      debugPrint('🌍 Auto-detected language: $detectedLanguage from device');
      await _selectLanguage(detectedLanguage);
      // Auto-continue after 1 second if language was auto-detected
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _selectedLanguage == detectedLanguage) {
          _handleContinue();
        }
      });
    }
  }

  Future<void> _selectLanguage(String languageCode) async {
    setState(() {
      _selectedLanguage = languageCode;
    });

    // Update locale provider immediately for UI feedback
    final localeNotifier = ref.read(localeProvider.notifier);
    await localeNotifier.setLocale(Locale(languageCode));

    debugPrint('Language selected: $languageCode');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(Icons.language, size: 60.w, color: Colors.white),
              ),
              SizedBox(height: 32.h),

              // Title
              Text(
                l10n.selectLanguage,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey800,
                  fontFamily: 'Poppins',
                  fontStyle: FontStyle.normal,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 8.h),

              // Subtitle
              Text(
                l10n.chooseYourPreferredLanguage,
                style: TextStyle(fontSize: 14.sp, color: AppColors.grey600),
              ),
              SizedBox(height: 48.h),

              // Language Options
              _buildLanguageOption(
                languageCode: 'en',
                languageName: l10n.english,
                flag: '🇬🇧',
                isSelected: _selectedLanguage == 'en',
              ),
              SizedBox(height: 16.h),
              _buildLanguageOption(
                languageCode: 'rw',
                languageName: l10n.ikinyarwanda,
                flag: '🇷🇼',
                isSelected: _selectedLanguage == 'rw',
              ),
              SizedBox(height: 16.h),
              _buildLanguageOption(
                languageCode: 'fr',
                languageName: l10n.french,
                flag: '🇫🇷',
                isSelected: _selectedLanguage == 'fr',
              ),

              // Continue Button (shown after language selection)
              if (_selectedLanguage != null) ...[
                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.continueText,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(Icons.arrow_forward, size: 20.sp),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (_selectedLanguage == null) return;

    // Update locale provider
    final localeNotifier = ref.read(localeProvider.notifier);
    await localeNotifier.setLocale(Locale(_selectedLanguage!));

    // Mark language as selected
    await LocaleService.setLanguageSelected(true);

    // Update the language selection provider
    ref.read(languageSelectedProvider.notifier).state = true;

    debugPrint('Language selected and continuing: $_selectedLanguage');
  }

  Widget _buildLanguageOption({
    required String languageCode,
    required String languageName,
    required String flag,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _selectLanguage(languageCode),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.grey50,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey400,
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // Flag
            Text(flag, style: TextStyle(fontSize: 30.sp)),
            SizedBox(width: 16.w),
            // Language Name
            Expanded(
              child: Text(
                languageName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontFamily: 'Poppins',
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.grey800,
                ),
              ),
            ),
            // Check Icon
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 24.sp),
          ],
        ),
      ),
    );
  }
}
