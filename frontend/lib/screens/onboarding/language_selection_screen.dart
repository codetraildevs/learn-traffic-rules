import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/locale_provider.dart';
import '../../services/locale_service.dart';
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
  }

  Future<void> _loadCurrentLanguage() async {
    final savedLocale = await LocaleService.getSavedLocale();
    setState(() {
      _selectedLanguage = savedLocale ?? 'en';
    });
  }

  Future<void> _selectLanguage(String languageCode) async {
    setState(() {
      _selectedLanguage = languageCode;
    });

    // Update locale provider
    final localeNotifier = ref.read(localeProvider.notifier);
    await localeNotifier.setLocale(Locale(languageCode));

    // Mark language as selected
    await LocaleService.setLanguageSelected(true);

    // Update the language selection provider
    ref.read(languageSelectedProvider.notifier).state = true;

    debugPrint('Language selected: $languageCode');
  }

  @override
  Widget build(BuildContext context) {
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
                child: Icon(
                  Icons.language,
                  size: 60.w,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 32.h),

              // Title
              Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey800,
                ),
              ),
              SizedBox(height: 8.h),

              // Subtitle
              Text(
                'Choose your preferred language',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.grey600,
                ),
              ),
              SizedBox(height: 48.h),

              // Language Options
              _buildLanguageOption(
                languageCode: 'en',
                languageName: 'English',
                flag: '🇬🇧',
                isSelected: _selectedLanguage == 'en',
              ),
              SizedBox(height: 16.h),
              _buildLanguageOption(
                languageCode: 'rw',
                languageName: 'Ikinyarwanda',
                flag: '🇷🇼',
                isSelected: _selectedLanguage == 'rw',
              ),
              SizedBox(height: 16.h),
              _buildLanguageOption(
                languageCode: 'fr',
                languageName: 'Français',
                flag: '🇫🇷',
                isSelected: _selectedLanguage == 'fr',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String languageCode,
    required String languageName,
    required String flag,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _selectLanguage(languageCode),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.grey50,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Flag
            Text(
              flag,
              style: TextStyle(fontSize: 32.sp),
            ),
            SizedBox(width: 16.w),
            // Language Name
            Expanded(
              child: Text(
                languageName,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.grey800,
                ),
              ),
            ),
            // Check Icon
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }
}

