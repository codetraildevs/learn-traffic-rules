class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://traffic.cyangugudims.com/api';
  //static const String baseUrl = 'http://10.102.183.116:3000/api';
  //static const String baseUrlImage = 'http://10.102.183.116:3000';
  static const String baseUrlImage =
      'https://traffic.cyangugudims.com/uploads/images-exams/';

  // Image Paths
  static const String defaultQuestionImagePath = '/uploads/question-images/';

  static const String apiVersion = 'v1';
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String deviceIdKey = 'device_id';
  static const String lastSyncKey = 'last_sync';
  static const String offlineDataKey = 'offline_data';
  static const String notificationPrefsKey = 'notification_preferences';

  // App Configuration
  static const String appName = 'Rwanda Traffic Rule 🇷🇼';
  static const String appSubtitle = 'Provisional Driving License Preparation';
  static const String appDescription =
      'Educational app for provisional driving license preparation and traffic safety learning';
  static const String appVersion = '1.1.1';
  static const String appBuildNumber = '16';

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
  static const String notificationChannelId = 'traffic_rules_channel';
  static const String notificationChannelName = 'Traffic Rules Notifications';

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
  static const String databaseName = 'traffic_rules.db';
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
