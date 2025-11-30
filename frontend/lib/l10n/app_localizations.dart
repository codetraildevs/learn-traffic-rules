import 'package:flutter/material.dart';
import 'app_localizations_en.dart';
import 'app_localizations_rw.dart';
import 'app_localizations_fr.dart';

/// Main AppLocalizations class that provides translations
abstract class AppLocalizations {
  // Common strings
  String get appName;
  String get welcome;
  String get login;
  String get register;
  String get logout;
  String get email;
  String get password;
  String get confirmPassword;
  String get forgotPassword;
  String get submit;
  String get cancel;
  String get save;
  String get delete;
  String get edit;
  String get back;
  String get next;
  String get finish;
  String get loading;
  String get error;
  String get success;
  String get ok;
  String get yes;
  String get no;
  
  // Auth strings
  String get loginSuccess;
  String get loginFailed;
  String get registerSuccess;
  String get registerFailed;
  String get invalidCredentials;
  String get passwordTooShort;
  String get passwordsDoNotMatch;
  
  // Exam strings
  String get exams;
  String get exam;
  String get startExam;
  String get finishExam;
  String get submitExam;
  String get examResults;
  String get score;
  String get passed;
  String get failed;
  String get timeRemaining;
  String get question;
  String get questions;
  String get answered;
  String get unanswered;
  
  // Dashboard strings
  String get dashboard;
  String get courses;
  String get notifications;
  String get profile;
  String get settings;
  
  // Language selection
  String get selectLanguage;
  String get english;
  String get kinyarwanda;
  String get french;
  
  // Disclaimer
  String get disclaimer;
  String get acceptDisclaimer;
  String get iUnderstand;
  
  // Error messages
  String get networkError;
  String get serverError;
  String get unknownError;
  String get tryAgain;
  
  // Success messages
  String get operationSuccess;
  String get dataSaved;
  
  // Factory constructor to get the appropriate localization
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizationsEn();
  }
  
  // Delegate for MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'rw', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'rw':
        return AppLocalizationsRw();
      case 'fr':
        return AppLocalizationsFr();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

