class AppConstants {
  // API Configuration - Backend at drive-rwanda-prep.cyangugudims.com
  static const String baseUrl =
      'https://drive-rwanda-prep.cyangugudims.com/api';
  static const String baseUrlImage =
      'https://drive-rwanda-prep.cyangugudims.com/uploads/images-exams/';
  static const String baseUrlDocument =
      'https://drive-rwanda-prep.cyangugudims.com/uploads/documents/';
  static const String imageBaseUrl =
      'https://drive-rwanda-prep.cyangugudims.com/uploads/images/';
  static const String siteBaseUrl =
      'https://drive-rwanda-prep.cyangugudims.com';

  // Image Paths
  static const String defaultQuestionImagePath = '/uploads/question-images/';

  static const String apiVersion = 'v1';
  static const int connectionTimeout = 60000; // 60s for slow mobile/VPS latency
  static const int receiveTimeout = 60000;

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String deviceIdKey = 'device_id';
  static const String lastSyncKey = 'last_sync';
  static const String offlineDataKey = 'offline_data';
  static const String notificationPrefsKey = 'notification_preferences';

  // App Configuration
  static const String appName = 'Drive Rwanda – Prep & Pass';
  // REPLACE with new publisher contact - used in About screen
  static const String supportEmail = 'support@your-domain.com';
  static const String supportPhone = '+250 XXX XXX XXX';
  static const String supportPhoneRaw =
      '250000000000'; // Digits only for tel/wa links
  static const String appSubtitle = 'Educational Study Platform';
  static const String appDescription =
      'Independent educational application for studying Rwanda traffic rules and driving theory through interactive practice materials';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Exam Configuration
  static const int defaultExamDuration = 30; // minutes
  static const int defaultPassingScore = 70; // percentage
  static const int maxRetakeAttempts = 3;
  static const int questionTimeLimit = 60; // seconds per question

  // Offline Configuration
  static const int syncIntervalMinutes = 5;
  static const int maxOfflineResults = 100;
  static const int offlineDataExpiryDays = 30;

  // Notification Configuration
  static const int notificationIdStart = 1000;
  static const String notificationChannelId = 'rw_driving_prep_channel';
  static const String notificationChannelName =
      'Drive Rwanda – Prep & Pass Notifications';

  // Achievement Configuration
  static const int pointsPerExam = 10;
  static const int pointsPerPerfectScore = 50;
  static const int pointsPerStreak = 25;
  static const int pointsPerCategory = 75;

  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Validation Rules
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int phoneNumberLength = 10;

  // Error Messages
  static const String networkError =
      'Network connection error. Please check your internet connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError =
      'An unknown error occurred. Please try again.';
  static const String validationError =
      'Please check your input and try again.';
  static const String authenticationError =
      'Authentication failed. Please login again.';
  static const String authorizationError =
      'You do not have permission to perform this action.';

  // Success Messages
  static const String loginSuccess = 'Login successful!';
  static const String registrationSuccess = 'Registration successful!';
  static const String examCompleted = 'Exam completed successfully!';
  static const String paymentApproved =
      'Payment approved! You now have access to all exams.';
  static const String dataSynced = 'Data synchronized successfully!';

  // Exam Categories - Educational Focus for Provisional License
  static const List<String> examCategories = [
    'Traffic Signs & Signals',
    'Road Rules & Regulations',
    'Vehicle Safety & Maintenance',
    'Emergency Procedures',
    'Parking & Maneuvering',
    'Highway & Expressway Rules',
    'City & Urban Driving',
    'Pedestrian & Cyclist Safety',
    'Weather & Road Conditions',
    'Alcohol & Drug Awareness',
  ];

  // Difficulty Levels
  static const List<String> difficultyLevels = ['EASY', 'MEDIUM', 'HARD'];

  // User Roles
  static const List<String> userRoles = ['USER', 'MANAGER', 'ADMIN'];

  // Payment Status
  static const List<String> paymentStatuses = [
    'PENDING',
    'APPROVED',
    'REJECTED',
  ];

  // Notification Types
  static const List<String> notificationTypes = [
    'PAYMENT_APPROVED',
    'PAYMENT_REJECTED',
    'EXAM_PASSED',
    'EXAM_FAILED',
    'NEW_EXAM',
    'STUDY_REMINDER',
    'SYSTEM',
  ];

  // Achievement Categories
  static const List<String> achievementCategories = [
    'milestone',
    'performance',
    'consistency',
    'expertise',
    'dedication',
  ];

  // File Extensions
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  static const List<String> supportedDocumentFormats = ['pdf', 'doc', 'docx'];
  static const paymentCode = '*182*8*1*329494*';

  // API Endpoints
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String userEndpoint = '/user-management';
  static const String userManagementEndpoint = '/user-management';
  static const String examsEndpoint = '/exams';
  static const String questionsEndpoint = '/questions';
  static const String paymentsEndpoint = '/payments';
  static const String accessCodesEndpoint = '/access-codes';
  static const String offlineEndpoint = '/offline';
  static const String analyticsEndpoint = '/analytics';
  static const String notificationsEndpoint = '/notifications';
  static const String achievementsEndpoint = '/achievements';
  static const String bulkUploadEndpoint = '/bulk-upload';

  // Local Database
  static const String databaseName = 'rw_driving_prep.db';
  static const int databaseVersion = 1;

  // Cache Configuration
  static const int cacheExpiryHours = 24;
  static const int maxCacheSize = 100; // MB

  // Security
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;
  static const int tokenExpiryDays = 7;
  static const int refreshTokenExpiryDays = 30;
}

class ImageUrlResolver {
  static String resolve(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';

    // Already absolute URL
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // Ensure leading slash
    final normalized = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';

    // Always attach to site root
    return '${AppConstants.siteBaseUrl}$normalized';
  }

  /// Add cache-busting parameter to force image reload
  /// Use this when you know backend images have been updated
  static String withCacheBust(String? imageUrl) {
    final resolved = resolve(imageUrl);
    if (resolved.isEmpty) return '';

    // Add timestamp as cache-busting parameter
    final separator = resolved.contains('?') ? '&' : '?';
    return '$resolved${separator}v=${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Add app version as cache-busting parameter
  /// More stable than timestamp - only updates when app version changes
  static String withVersionCache(String? imageUrl, {String version = '1.0.0'}) {
    final resolved = resolve(imageUrl);
    if (resolved.isEmpty) return '';

    // Add version as cache-busting parameter
    final separator = resolved.contains('?') ? '&' : '?';
    return '$resolved${separator}v=$version';
  }
}
