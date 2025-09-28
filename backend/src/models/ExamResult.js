const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const ExamResult = sequelize.define('ExamResult', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  examId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'exams',
      key: 'id'
    }
  },
  score: {
    type: DataTypes.INTEGER,
    allowNull: false,
    validate: {
      min: 0,
      max: 100
    }
  },
  totalQuestions: {
    type: DataTypes.INTEGER,
    allowNull: false,
    validate: {
      min: 1
    }
  },
  correctAnswers: {
    type: DataTypes.INTEGER,
    allowNull: false,
    validate: {
      min: 0
    }
  },
  timeSpent: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: 'Time spent in seconds',
    validate: {
      min: 0
    }
  },
  answers: {
    type: DataTypes.JSON,
    allowNull: true,
    comment: 'User answers for each question'
  },
  passed: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  },
  completedAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
    allowNull: false
  },
  isFreeExam: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false,
    comment: 'Whether this exam was taken as a free exam'
  },
  questionResults: {
    type: DataTypes.JSON,
    allowNull: true,
    comment: 'Detailed question-by-question results with correct/incorrect answers'
  }
}, {
  tableName: 'exam_results',
  timestamps: true,
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
});

// Instance methods
ExamResult.prototype.toJSON = function() {
  return {
    id: this.id,
    userId: this.userId,
    examId: this.examId,
    score: this.score,
    totalQuestions: this.totalQuestions,
    correctAnswers: this.correctAnswers,
    timeSpent: this.timeSpent,
    answers: this.answers,
    passed: this.passed,
    completedAt: this.completedAt,
    isFreeExam: this.isFreeExam,
    questionResults: this.questionResults,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

// Static methods
ExamResult.calculateScore = function(correctAnswers, totalQuestions) {
  return Math.round((correctAnswers / totalQuestions) * 100);
};

ExamResult.determinePassed = function(score, passingScore) {
  return score >= passingScore;
};

module.exports = ExamResult;
