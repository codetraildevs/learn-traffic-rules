const User = require('../models/User');
const Exam = require('../models/Exam');
const Question = require('../models/Question');
const PaymentRequest = require('../models/PaymentRequest');
const AccessCode = require('../models/AccessCode');
const ExamResult = require('../models/ExamResult');
const Notification = require('../models/Notification');
const StudyReminder = require('../models/StudyReminder');
const NotificationPreferences = require('../models/NotificationPreferences');

// Define associations
const setupAssociations = () => {
  // User associations
  User.hasMany(PaymentRequest, { foreignKey: 'userId', as: 'paymentRequests' });
  User.hasMany(AccessCode, { foreignKey: 'userId', as: 'accessCodes' });
  User.hasMany(ExamResult, { foreignKey: 'userId', as: 'examResults' });
  User.hasMany(Notification, { foreignKey: 'userId', as: 'notifications' });
  User.hasMany(StudyReminder, { foreignKey: 'userId', as: 'studyReminders' });
  User.hasOne(NotificationPreferences, { foreignKey: 'userId', as: 'notificationPreferences' });

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
};

module.exports = setupAssociations;
