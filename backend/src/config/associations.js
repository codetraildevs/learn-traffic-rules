const User = require('../models/User');
const Exam = require('../models/Exam');
const Question = require('../models/Question');
const PaymentRequest = require('../models/PaymentRequest');
const AccessCode = require('../models/AccessCode');
const ExamResult = require('../models/ExamResult');
const Notification = require('../models/Notification');
const StudyReminder = require('../models/StudyReminder');
const NotificationPreferences = require('../models/NotificationPreferences');
const Course = require('../models/Course');
const CourseContent = require('../models/CourseContent');
const CourseProgress = require('../models/CourseProgress');
const CourseContentProgress = require('../models/CourseContentProgress');

// Define associations
const setupAssociations = () => {
  // User associations
  User.hasMany(PaymentRequest, { foreignKey: 'userId', as: 'paymentRequests' });
  User.hasMany(AccessCode, { foreignKey: 'userId', as: 'accessCodes' });
  User.hasMany(ExamResult, { foreignKey: 'userId', as: 'examResults' });
  User.hasMany(Notification, { foreignKey: 'userId', as: 'notifications' });
  User.hasMany(StudyReminder, { foreignKey: 'userId', as: 'studyReminders' });
  User.hasOne(NotificationPreferences, { foreignKey: 'userId', as: 'notificationPreferences' });
  User.hasMany(CourseProgress, { foreignKey: 'userId', as: 'courseProgress' });
  User.hasMany(CourseContentProgress, { foreignKey: 'userId', as: 'courseContentProgress' });

  // Exam associations
  Exam.hasMany(Question, { foreignKey: 'examId', as: 'questions' });
  Exam.hasMany(ExamResult, { foreignKey: 'examId', as: 'examResults' });

  // PaymentRequest associations
  PaymentRequest.belongsTo(User, { foreignKey: 'userId', as: 'User' });

  // AccessCode associations
  AccessCode.belongsTo(User, { foreignKey: 'userId', as: 'user' });
  AccessCode.belongsTo(User, { foreignKey: 'generatedByManagerId', as: 'generatedBy' });

  // ExamResult associations
  ExamResult.belongsTo(User, { foreignKey: 'userId', as: 'User' });
  ExamResult.belongsTo(Exam, { foreignKey: 'examId', as: 'Exam' });

  // Question associations
  Question.belongsTo(Exam, { foreignKey: 'examId', as: 'Exam' });

  // Notification associations
  Notification.belongsTo(User, { foreignKey: 'userId', as: 'user' });

  // StudyReminder associations
  StudyReminder.belongsTo(User, { foreignKey: 'userId', as: 'user' });

  // NotificationPreferences associations
  NotificationPreferences.belongsTo(User, { foreignKey: 'userId', as: 'user' });

  // Course associations
  Course.hasMany(CourseContent, { foreignKey: 'courseId', as: 'contents' });
  Course.hasMany(CourseProgress, { foreignKey: 'courseId', as: 'progress' });

  // CourseContent associations
  CourseContent.belongsTo(Course, { foreignKey: 'courseId', as: 'course' });
  CourseContent.hasMany(CourseContentProgress, { foreignKey: 'courseContentId', as: 'contentProgress' });

  // CourseProgress associations
  CourseProgress.belongsTo(User, { foreignKey: 'userId', as: 'user' });
  CourseProgress.belongsTo(Course, { foreignKey: 'courseId', as: 'course' });

  // CourseContentProgress associations
  CourseContentProgress.belongsTo(User, { foreignKey: 'userId', as: 'user' });
  CourseContentProgress.belongsTo(Course, { foreignKey: 'courseId', as: 'course' });
  CourseContentProgress.belongsTo(CourseContent, { foreignKey: 'courseContentId', as: 'content' });
};

module.exports = setupAssociations;
