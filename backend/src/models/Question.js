const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Question = sequelize.define('Question', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  examId: {
    type: DataTypes.UUID,
    allowNull: false
  },
  question: {
    type: DataTypes.TEXT,
    allowNull: false,
    validate: {
      len: [10, 1000]
    }
  },
  option1: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  option2: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  option3: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  option4: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  correctAnswer: {
    type: DataTypes.TEXT,
    allowNull: false,
    validate: {
      isValidAnswer(value) {
        if (!value || value.trim().length === 0) {
          throw new Error('Correct answer cannot be empty');
        }
      }
    }
  },
  points: {
    type: DataTypes.INTEGER,
    defaultValue: 1,
    allowNull: false,
    validate: {
      min: 1,
      max: 10
    }
  },
  questionOrder: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1,
    comment: 'Order of question within the exam (1, 2, 3, etc.)'
  },
  questionImgUrl: {
    type: DataTypes.STRING(500),
    allowNull: true
  }
}, {
  tableName: 'questions',
  timestamps: true,
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
});

// Instance methods
Question.prototype.toJSON = function() {
  return {
    id: this.id,
    examId: this.examId,
    question: this.question,
    option1: this.option1,
    option2: this.option2,
    option3: this.option3,
    option4: this.option4,
    correctAnswer: this.correctAnswer,
    points: this.points,
    questionImgUrl: this.questionImgUrl,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

module.exports = Question;
