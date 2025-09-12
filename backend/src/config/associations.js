const User = require('../models/User');
const Exam = require('../models/Exam');
const Question = require('../models/Question');
const PaymentRequest = require('../models/PaymentRequest');
const AccessCode = require('../models/AccessCode');
const ExamResult = require('../models/ExamResult');

// Define associations
const setupAssociations = () => {
  // User associations
  User.hasMany(PaymentRequest, { foreignKey: 'userId', as: 'paymentRequests' });
  User.hasMany(AccessCode, { foreignKey: 'userId', as: 'accessCodes' });
  User.hasMany(ExamResult, { foreignKey: 'userId', as: 'examResults' });

  // Exam associations
  Exam.hasMany(Question, { foreignKey: 'examId', as: 'questions' });
  Exam.hasMany(ExamResult, { foreignKey: 'examId', as: 'examResults' });

  // PaymentRequest associations
  PaymentRequest.belongsTo(User, { foreignKey: 'userId', as: 'User' });

  // AccessCode associations
  AccessCode.belongsTo(User, { foreignKey: 'userId', as: 'User' });
  AccessCode.belongsTo(User, { foreignKey: 'generatedByManagerId', as: 'GeneratedByManager' });

  // ExamResult associations
  ExamResult.belongsTo(User, { foreignKey: 'userId', as: 'User' });
  ExamResult.belongsTo(Exam, { foreignKey: 'examId', as: 'Exam' });

  // Question associations
  Question.belongsTo(Exam, { foreignKey: 'examId', as: 'Exam' });
};

module.exports = setupAssociations;
