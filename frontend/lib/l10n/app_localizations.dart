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
  String get continueText;
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
  String get ikinyarwanda;

  // Theme selection
  String get appTheme;
  String get systemDefault;
  String get lightTheme;
  String get darkTheme;
  String get followDeviceTheme;
  String get alwaysUseLightTheme;
  String get alwaysUseDarkTheme;
  String themeChangedTo(String themeName);

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

  // Phone and Contact
  String get needHelp;
  String get contactSupport;
  String get available247;
  String get close;
  String get callNow;
  String get copy;
  String get phoneNumber;
  String get needHelpCall;

  // Login/Register specific
  String get signIn;
  String get createAccount;
  String get fullName;
  String get phoneNumberLabel;
  String get alreadyHaveAccount;
  String get newUser;
  String get learnPracticeMaster;
  String get importantInformation;
  String get accountInfo;

  // Form validation
  String get pleaseCheckPhoneNumber;
  String get enterValidPhoneNumber;
  String get deviceMismatch;
  String get deviceMismatchDescription;
  String get phoneNumberNotFound;
  String get phoneNumberNotFoundDescription;
  String get contactSupportPhone;
  String get tooManyRequests;
  String get tooManyRequestsDescription;
  String get accessDenied;
  String get accessDeniedDescription;
  String get checkCredentials;

  // Exam related
  String get securityAlert;
  String get continueExam;
  String get exitExam;
  String get exitWithoutSubmitting;
  String get timesUp;
  String get correct;
  String get incorrect;
  String get passingScore;
  String get totalQuestions;
  String get correctAnswers;
  String get incorrectAnswers;
  String get timeSpent;
  String get completedAt;
  String get examType;

  // User Management
  String get userManagement;
  String get allUsers;
  String get users;
  String get managers;
  String get admins;
  String get withCode;
  String get noCode;
  String get called;
  String get notCalled;
  String get name;
  String get role;
  String get created;
  String get lastLogin;
  String get generateAccessCode;
  String get generateCode;

  // Payment
  String get select;
  String get call;
  String get whatsApp;
  String get cancelPayment;
  String get dialMoMo;
  String get contactAlexis;
  String get couldNotLaunchPhone;
  String get codeCopied;
  String get whatsAppNotAvailable;
  String get callInstead;

  // Terms and Conditions
  String get termsConditions;

  // About App
  String get aboutApp;
  String get aboutThisApp;
  String get keyFeatures;
  String get practiceExams;
  String get multiLanguage;
  String get richMedia;
  String get offlineMode;
  String get progressTracking;
  String get accessCodes;
  String get completeFeatureList;

  // Disclaimer
  String get provisionalDrivingLicense;
  String get disclaimerContent;

  // Other
  String get resetCodeSentCheckConsole;
  String get failedToSaveReminder;
  String get failedToSavePreferences;
  String get callColon;
  String get whatsAppColon;
  String get manualColon;
  String get whatsAppWebColon;
  String get failedToDeleteAccount;

  // Forgot Password
  String get resetPassword;
  String get enterPhoneNumberToReceiveResetCode;
  String get pleaseEnterYourPhoneNumber;
  String get phoneNumberIsRequired;
  String phoneNumberMustBeDigits(int digits);
  String get sendResetCode;
  String get resetCodeSentSuccessfully;
  String get checkConsoleForCode;
  String get rememberYourPassword;

  // Registration
  String get registrationSuccessful;
  String get welcomeToApp;
  String get phoneNumberAlreadyRegistered;
  String get phoneNumberAlreadyRegisteredDescription;
  String get deviceAlreadyRegistered;
  String get deviceAlreadyRegisteredDescription;
  String get invalidPhoneNumber;
  String get invalidPhoneNumberDescription;
  String get invalidName;
  String get invalidNameDescription;
  String get pleaseCheckYourInformation;
  String get makeSureAllFieldsFilled;
  String get fullNameMustBeAtLeast;
  String get deviceBindingIssue;
  String get deviceBindingIssueDescription;
  String get goToLogin;

  // Splash Screen
  String get masterTrafficRules;

  // Form fields and validation
  String get enterPhoneNumberToContinue;
  String get enterYourPhoneNumber;
  String get enterYourFullName;
  String get fullNameIsRequired;
  String nameMustBeAtLeast(int minLength);

  // Legal and agreements
  String get byUsingThisAppYouAgree;
  String get byCreatingAccountYouAgree;
  String get privacyPolicy;
  String get and;
  String get privacyPolicyTitle;
  String get privacyPolicyContent;
  String get termsConditionsTitle;
  String get termsConditionsContent;

  // Registration specific
  String get startLearningJourney;
  String get fillDetailsToCreateAccount;
  String get fillDetailsToCreateAccountDescription;
  String get fillDetailsBelow;

  // Login confirmation dialog
  String get itLooksLikeYouAlreadyHaveAccount;
  String get whatToDo;
  String get stayHere;
  String get useSamePhoneNumber;
  String get deviceAlreadyLinked;
  String get justEnterPhoneToLogin;

  // User Management Screen - Additional keys
  String get totalUsers;
  String usersCount(int count);
  String get refresh;
  String get searchUsers;
  String get noUsersFound;
  String noUsersFoundMatching(String query);
  String get dateFilter;
  String get filter;
  String get sort;
  String get blocked;
  String blockedWithReason(String reason);
  String get unblockUser;
  String get blockUser;
  String get deleteUser;
  String get createdLabel;
  String createdDate(String date);
  String lastLoginDate(String date);
  String get never;
  String get expiresAt;
  String expiresAtDate(String date);
  String get daysLeft;
  String daysLeftCount(int days);
  String calledWithTime(String time);
  String get justNow;
  String minutesAgo(int minutes);
  String hoursAgo(int hours);
  String get yesterday;
  String daysAgo(int days);
  String get ascending;
  String get descending;
  String get previousPage;
  String get nextPage;
  String accessCodeGeneratedFor(String name);
  String userDeletedSuccessfully(String name);
  String get failedToGenerateAccessCode;
  String get failedToDeleteUser;
  String get errorGeneratingAccessCode;
  String get errorDeletingUser;
  String get thisActionCannotBeUndone;
  String get userAndDataWillBePermanentlyRemoved;
  String get selectPaymentTier;
  String get reasonForBlocking;
  String get reasonForBlockingOptional;
  String areYouSureYouWantToBlockUser(String name);
  String areYouSureYouWantToUnblockUser(String name);
  String get unblockedUsersWillRegainAccess;
  String get blockedUsersWillNotBeAbleToAccess;
  String get userBlockedSuccessfully;
  String get userUnblockedSuccessfully;
  String get failedToBlockUser;
  String get failedToUnblockUser;
  String get errorBlockingUser;
  String get errorUnblockingUser;
  String callingUser(String name);
  String get couldNotMakePhoneCall;
  String get errorMakingPhoneCall;
  String get today;
  String get startDate;
  String get endDate;
  String get clear;
  String areYouSureYouWantToPermanentlyDeleteUser(String name);
  String get thisUserHasActiveAccessCodesPleaseDeleteThemFirst;
  String get deletePermanently;

  // Home Screen - Additional keys
  String get exitApp;
  String get areYouSureYouWantToExitApp;
  String get adminDashboard;
  String welcomeBack(String name);
  String get manageYourTrafficRulesLearningPlatform;
  String get readyToMasterTrafficRules;
  String get accessActive;
  String get accessExpired;
  String get noAccessCode;
  String accessActiveDaysLeft(int days);
  String get paymentTier;
  String get none;
  String get managePlatform;
  String get startLearning;
  String get getAccessCode;
  String get adminActions;
  String get manageUsers;
  String get viewSearchAndManageAllUsers;
  String get manageExams;
  String get createEditAndManageExams;
  String get manageAccessCodesAndPayments;
  String get manageCourses;
  String get createEditAndManageCourses;
  String get quickStats;
  String get totalUsersLabel;
  String get totalExams;
  String get totalAttempts;
  String get avgScore;
  String get examsTaken;
  String get averageScore;
  String get studyStreak;
  String studyStreakDays(int days);
  String get achievements;
  String get availableExams;
  String get viewAll;
  String get noExamsAvailable;
  String get noCoursesAvailable;
  String get errorLoadingCourses;
  String get lessons;
  String lessonsCount(int count);
  String get recentActivity;
  String get noRecentActivity;
  String get noExamAttemptsRecordedYet;
  String get startTakingExamsToSeeYourProgressHere;
  String examScore(String score);
  String get errorLoadingDashboard;
  String get retry;
  String get noInternetConnectionAndNoCachedDataAvailable;
  String get failedToLoadDashboardData;
  String get manageExamsLabel;
  String get progress;
  String get viewProfile;
  String get viewAndManageYourProfileInformation;
  String get manageYourNotificationPreferences;
  String get studyReminders;
  String get setUpStudyReminders;
  String get learnMoreAboutThisApplication;
  String get privacyPolicyLabel;
  String get readOurPrivacyPolicy;
  String get termsConditionsLabel;
  String get readOurTermsAndConditions;
  String get shareApp;
  String get shareThisAppWithFriendsAndFamily;
  String get helpSupport;
  String get getHelpAndContactSupport;
  String get deleteAccount;
  String get permanentlyDeleteYourAccount;
  String get areYouSureYouWantToLogout;
  String get exit;

  // User Dashboard Screen
  String get welcomeBackExclamation;
  String get trackYourAccessAndProgress;
  String get accessStatus;
  String get activeAccess;
  String youHaveDaysRemaining(int days);
  String activeAccessCodesCount(int count);

  // Available Exams Screen
  String get allExams;
  String get filterByExamType;
  String get all;
  String get noExamsFoundForThisLanguage;
  String get checkBackLaterForNewTrafficRulesExams;
  String get noExamsAvailableForThisLanguage;
  String examTypeExams(String type);
  String get freeTrialFirstExamOfEachTypeIsFree;
  String get upgradeToAccessAllExams;
  String get viewPlans;
  String questionsCount(int count);
  String durationMinutes(int minutes);

  // Course List Screen
  String get viewCourse;
  String get getAccess;
  String get content;
  String get checkBackLaterForNewCourses;
  String get allCourses;
  String contentCount(int count);

  // Progress Screen
  String get errorLoadingProgress;
  String get myProgress;
  String get yourProgressAndAnalyticsWillAppearHere;
  String get takeYourFirstExamToStartTrackingYourPerformance;
  String get whatYouWillSeeHere;
  String get trackYourImprovementOverTime;
  String get seeYourStrengthsAndWeaknesses;
  String get getPersonalizedStudyTips;
  String get yourStatistics;
  String get totalTime;
  String get recentResults;
  String correctAnswersCount(int correct, int total);
  String get areasOfImprovement;
  String get failedExamsTitle;
  String youHaveFailedExams(int count, String plural);
  String get lowPerformance;
  String examsWithLowScores(int count, String plural);
  String get studyStrategy;
  String get focusOnConsistentPractice;
  String get performanceTrend;
  String get greatJobPerformanceImproving;
  String get performanceNeedsAttention;
  String get categoryPerformance;
  String examsCountWithPassed(int total, String plural, int passed);
  String get takeMorePracticeExams;
  String get focusOnUnderstandingMaterial;
  String get reviewFailedExamTopics;
  String get excellentPerformanceConsiderAdvanced;
  String get keepPracticingRegularly;
  String failedExams(int count);
  String latestScore(int score);
  String get retakeExam;
  String get viewAnswer;
  String get studyStrategies;
  String get reviewMaterialBeforeTakingExams;
  String get takePracticeExamsRegularly;
  String get focusOnWeakAreasIdentifiedInResults;
  String get useSpacedRepetitionForBetterRetention;
  String get examTips;
  String get readQuestionsCarefully;
  String get eliminateObviouslyWrongAnswers;
  String get manageYourTimeEffectively;
  String get stayCalmAndFocused;
  String get gotIt;
  String get retakeThisExam;
  String get errorCouldNotStartExamRetake;
  String get screenshotsDisabledToProtectIntegrity;
  String get noDetailedResultsAvailable;
  String get questionBreakdownNotAvailable;
  String get wrong;
  String scoreWithCorrectCount(int score, int correct, int total);
  String get offlineModeShowingCachedResultsOnly;
  String get showingCachedResultsResultsWillSyncWhenInternetIsAvailable;
  String get unknownErrorOccurred;
  String get myResults;
  String get resultsComingSoon;
  String get paymentComingSoon;
  String get helpComingSoon;
  String get examsComingSoon;
  String get paymentScreenComingSoon;
  String get noActiveAccess;
  String get youDontHaveAnyActiveAccessCodes;
  String get quickActions;
  String get myDashboard;

  // Exam Taking Screen
  String get examPausedDueToAppSwitching;
  String get toMaintainExamIntegrity;
  String get stayInExamAppDuringTest;
  String get doNotSwitchToOtherApps;
  String get doNotTakeScreenshots;
  String get repeatedViolationsMayResultInExamTermination;
  String get whatWouldYouLikeToDo;
  String get youCanExitAndReturnLater;
  String get submitExamQuestion;
  String get onceSubmittedYouCannotChangeAnswers;
  String get allQuestionsHaveBeenAnswered;
  String get youHaveUnansweredQuestions;
  String youHaveUnansweredQuestionsCount(int count);

  // Payment Instructions Screen
  String get contactAdmin;
  String get afterMakingPaymentContactAdmin;
  String get whatsapp;
  String selectedPlan(String amount);
  String get amount;
  String get duration;
  String get toPayViaMoMoDialThisCode;
  String get afterPaymentContactAdminToVerify;
  String get codeCopiedToClipboard;
  String get copyCode;

  // Payment Instructions Screen - Additional
  String get paymentPlans;
  String get noInternetConnection;
  String get errorLoadingPaymentPlans;
  String get paymentInstructionsNotAvailableOffline;
  String get howToGetFullAccess;
  String get chooseAPlan;
  String get makePayment;
  String get chooseYourPlan;
  String get popular;
  String get couldNotLaunchPhoneApp;
  String get whatsappNotAvailableTryAlternatives;
  String get couldNotLaunchPhoneAppPleaseDial;

  // User Profile & Account
  String get user;
  String get userRole;
  String get profileInformation;
  String get notProvided;
  String get noPhoneNumber;
  String get accountStatus;
  String get accountInformation;
  String get active;
  String get inactive;
  String dateTimeFormat(int month, int day, int year, int hour, int minute);

  // Delete Account Screen
  String get deleteConfirmationWord;
  String get whatWillBeDeleted;
  String get yourPersonalProfileInformation;
  String get allExamResultsAndProgressData;
  String get studyHistoryAndAchievements;
  String get appPreferencesAndSettings;
  String get anyUploadedContentOrData;
  String get thisActionIsPermanentAndCannotBeReversed;
  String get confirmDeletion;
  String get toConfirmAccountDeletionPleaseTypeDelete;
  String get typeDeleteToConfirm;
  String get enterYourPhoneNumberToConfirmDeletion;
  String get iUnderstandThatThisActionCannotBeUndone;
  String get finalConfirmation;
  String get areYouAbsolutelySureYouWantToDeleteYourAccount;
  String get accountDeletedSuccessfully;

  // Help & Support
  String get weAreHereToHelpYouSucceed;
  String get quickHelp;
  String get howToTakeAnExam;
  String get learnTheBasicsOfTakingExams;
  String get understandingYourProgress;
  String get trackYourLearningJourney;
  String get paymentAndAccessCodes;
  String get learnAboutPaymentOptions;
  String get accountManagement;
  String get manageYourProfileAndSettings;
  String get emailSupport;
  String get phoneSupport;
  String get whatsappLabel;
  String get liveChat;
  String get liveChatCurrentlyUnavailable;
  String get frequentlyAskedQuestions;
  String get faqHowDoIResetMyProgress;
  String get faqHowDoIResetMyProgressAnswer;
  String get faqCanIUseTheAppOffline;
  String get faqCanIUseTheAppOfflineAnswer;
  String get faqHowOftenAreNewQuestionsAdded;
  String get faqHowOftenAreNewQuestionsAddedAnswer;
  String get faqIsMyDataSecure;
  String get faqIsMyDataSecureAnswer;
  String get supportRequestSubject;
  String get emailNotAvailableTryTheseAlternatives;
  String get whatsappNotAvailableTryTheseAlternatives;

  // Help & Support - Help Text
  String get examHelpText;
  String get progressHelpText;
  String get paymentHelpText;
  String get accountHelpText;

  // Progress Screen - Additional
  String get performanceTrends;
  String get detailedAnalytics;
  String get retakeFailedExams;
  String get reviewTopics;
  String get studyTips;
  String lowPerformanceExams(int count);
  String get examResult;

  // Free Exams Screen
  String youHaveFreeExamsRemaining(int count, String plural);
  String get checkBackLaterForNewExams;
  String startingExam(String examTitle);
  String get getFullAccess;
  String get youveUsedAllFreeExams;

  // Study Reminders Screen
  String get monday;
  String get tuesday;
  String get wednesday;
  String get thursday;
  String get friday;
  String get saturday;
  String get sunday;
  String get setUpRemindersToMaintainStudyRoutine;
  String get enableStudyReminders;
  String get receiveDailyRemindersToStudy;
  String get reminderTime;
  String get reminderDays;
  String get dailyStudyGoal;
  String minutesPerDayValue(int minutes);
  String get createReminder;
  String get updateReminder;
  String get studyReminderCreatedSuccessfully;
  String get studyReminderUpdatedSuccessfully;
  String get studyReminderDeletedSuccessfully;

  // Category and Difficulty Names
  String get trafficRules;
  String get roadSigns;
  String get safety;
  String get environment;
  String get general;
  String get medium;

  // Free Exams Screen - Additional
  String failedToLoadExams(String error);
  String get freeExams;
  String get errorLoadingExams;
  String get freeTrial;
  String get min;
  String get pass;
  String get free;

  // Progress Screen - Additional Keys
  String get studyRecommendations;

  // Exam Progress Screen
  String get examSummary;
  String get freeExam;
  String get backToExams;
  String get secureView;
  String get screenshotsAreDisabledToProtectAnswerIntegrity;
  String detailedAnswersFor(String examTitle);
  String get questionByQuestionResultsNotAvailable;

  // About App Screen - Detailed Content
  String get interactivePracticeExams;
  String get multiLanguageSupport;
  String get comprehensiveCourseContent;
  String get audioAndVideoPlayback;
  String get progressTrackingAndAnalytics;
  String get detailedExplanations;
  String get offlineStudyMode;
  String get offlineExamTaking;
  String get achievementSystem;
  String get courseManagement;
  String get paymentSystem;
  String get globalCourseAccess;
  String get regularUpdates;
  String get developerInformation;
  String get appNameLabel;
  String get descriptionLabel;
  String get phoneLabel;
  String get developerLabel;
  String get contactLabel;
  String get websiteLabel;
  String lastUpdated(String date);
  String get legalPrivacy;
  String get legalNotice;
  String get privacyData;
  String get technicalFeatures;
  String get offlineFirst;
  String get autoSync;
  String get securePayment;
  String get officialGovernmentSources;
  String get appDescription;
  String get importantNotice;
  String get notAffiliatedNotice;
  String get legalNoticeContent;
  String get privacyDataContent;

  // Privacy Policy Screen
  String get privacyPolicySection1Title;
  String get privacyPolicySection1Content;
  String get privacyPolicySection2Title;
  String get privacyPolicySection2Content;
  String get privacyPolicySection3Title;
  String get privacyPolicySection3Content;
  String get privacyPolicySection4Title;
  String get privacyPolicySection4Content;
  String get privacyPolicySection5Title;
  String get privacyPolicySection5Content;
  String get privacyPolicySection6Title;
  String get privacyPolicySection6Content;
  String get privacyPolicySection7Title;
  String get privacyPolicySection7Content;
  String get privacyPolicySection8Title;
  String get privacyPolicySection8Content;
  String get privacyPolicySection9Title;
  String get privacyPolicySection9Content;

  // Notifications Screen
  String get notificationSettings;
  String get customizeNotificationPreferences;
  String get notificationTypes;
  String get examReminders;
  String get achievementAlerts;
  String get celebrateProgressAndAchievements;
  String get getNotifiedAboutUpcomingExams;
  String get systemUpdates;
  String get dailyRemindersToKeepUp;
  String get importantAppUpdatesAndMaintenance;
  String get paymentNotifications;
  String get updatesAboutPaymentsAndAccessCodes;
  String get weeklyReports;
  String get summaryOfWeeklyProgressAndPerformance;
  String get notificationTiming;
  String get quietHours;
  String get vibration;
  String get savePreferences;
  String get notificationPreferencesSavedSuccessfully;
  //async data builder
  String get somethingWentWrong;
  String get pleaseTryAgainLater;
  String get noDataAvailable;
  String get importantLegalNotice;
  String get governmentAffiliation;
  String get governmentAffiliationContent;
  String get educationalPurposeOnlyDisclaimer;
  String get educationalPurposeOnlyContent;
  String get noOfficialCertification;
  String get noOfficialCertificationContent;
  String get yourResponsibility;
  String get yourResponsibilityContent;
  String get remember;
  String get privateEducationalToolDisclaimer;
  String get continueLearning;

  // Privacy Policy Modal – English
  String get importantDisclaimer;

  String get privacyGovDisclaimer;

  String get officialSource;

  String get rnpDrivingLicense;

  String get dataWeCollect;

  String get dataWeCollectContent;

  String get howWeUseYourData;

  String get howWeUseYourDataContent;

  String get dataProtection;

  String get dataProtectionContent;

  String get readFullPrivacyPolicy;

  String get contactUsQuestion;

  String get openPrivacyPolicy;

  String get unableToOpenBrowser;

  // Disclaimer Screen
  String get educationalDisclaimer;
  String get educationalPurposeOnlyDescription;
  String get practiceSimulation;
  String get practiceSimulationDescription;
  String get notOfficial;
  String get officialSourceDescription;
  String get iUnderstandContinue;
  String get iHaveReadAndUnderstoodTheEducationalDisclaimer;
  String get pleaseAcceptTermsAndConditions;
  String get pleaseCheckTheBoxBelowToAcceptTermsAndConditions;
  String get couldNotOpenLinkTapCopyToCopyTheUrl;
  String get urlCopiedToClipboard;
  String get copyUrl;
  String errorMessage(String error);

  // Language Selection Screen
  String get chooseYourPreferredLanguage;

  // Course List Screen
  String get paidCourse;
  String get freeCourse;

  // Course Content Viewer Screen
  String contentExistsButFailedToLoad(int count);
  String get noContentAvailableForThisCourse;
  String get failedToLoadCourseContent;
  String errorLoadingCourseContent(String error);
  String get invalidAudioUrl;
  String invalidAudioUrlMessage(String url);
  String get audioFileNotFoundOrInvalid;
  String get unableToLoadAudioFile;
  String errorPlayingAudio(String error);
  String get timeoutLoadingAudioFile;
  String get audioFileCouldNotBeLoaded;
  String get errorLoadingAudio;
  String get audioFileFormatNotSupported;
  String get cannotLoadAudioFile;
  String get timeoutLoadingAudioFileSlow;
  String get audioFileNotFound;
  String get accessDeniedToAudioFile;
  String get serverReturnedErrorPageForAudio;
  String errorLoadingAudioWithMessage(String message);
  String couldNotOpenUrl(String url);
  String contentNumber(int number);
  String get audioContent;
  String get loadingAudio;
  String get pleaseWaitWhileWeLoadTheAudioFile;
  String get externalLink;
  String get openLink;
  String get noContentAvailable;

  // Course Detail Screen
  String get startCourse;
  String get getAccessToStart;
  String get courseContentBeingPrepared;
  String get difficulty;
  String contentItemsCount(int count);
  String get courseContent;
  String get errorLoadingCourse;
  String get failedToLoadCourseDetails;
  String get previous;
  String get noNotificationsYet;
  String get youllSeeYourNotificationsHere;

  // Terms & Conditions Screen
  String get termsConditionsSection1Title;
  String get termsConditionsSection1Content;
  String get termsConditionsSection2Title;
  String get termsConditionsSection2Content;
  String get termsConditionsSection3Title;
  String get termsConditionsSection3Content;
  String get termsConditionsSection4Title;
  String get termsConditionsSection4Content;
  String get termsConditionsSection5Title;
  String get termsConditionsSection5Content;
  String get termsConditionsSection6Title;
  String get termsConditionsSection6Content;
  String get termsConditionsSection7Title;
  String get termsConditionsSection7Content;
  String get termsConditionsSection8Title;
  String get termsConditionsSection8Content;
  String get termsConditionsSection9Title;
  String get termsConditionsSection9Content;
  String get termsConditionsSection10Title;
  String get termsConditionsSection10Content;
  String get termsConditionsSection11Title;
  String get termsConditionsSection11Content;
  String get termsConditionsSection12Title;
  String get termsConditionsSection12Content;
  String get termsConditionsSection13Title;
  String get termsConditionsSection13Content;
  String lastUpdatedDate(String date);
  String get joinWhatsAppGroup;
  String get connectWithLearners;
  String get shareProgram;
  String get shareWithFriends;
  String get availableServices;
  String get officialGazette;
  String get officialGazetteDescription;

  String get roadSignsGuide;
  String get roadSignsDescription;

  String get errorLoadingData;
  String get noInternet;

  String get totalLessons;

  //share message
  String get shareAppSubject;
  String get shareAppMessage;
  String get shareFailed;

  String get timeUpTitle;
  String get timeUpMessage;

  String get securityAlertTitle;
  String get examPausedMessage;
  String get examIntegrityNotice;
  String get stayInAppRule;
  String get noAppSwitchRule;
  String get noScreenshotRule;
  String get repeatedViolationWarning;
  String get time;
  String get off;

  String get examSubmittedSuccess;
  String get examSavedOffline;
  String get examScoreDescription;
  String get errorSubmittingExam;
  String get correctQuestions;
  String get incorrectQuestions;

  // Factory constructor to get the appropriate localization
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizationsRw();
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
      case 'en':
        return AppLocalizationsEn();
      case 'fr':
        return AppLocalizationsFr();
      case 'rw':
      default:
        return AppLocalizationsRw();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
