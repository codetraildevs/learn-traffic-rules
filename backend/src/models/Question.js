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
    allowNull: false,
    references: {
      model: 'exams',
      key: 'id'
    }
  },
  question: {
    type: DataTypes.TEXT,
    allowNull: false,
    validate: {
      len: [10, 1000]
    }
  },
  options: {
    type: DataTypes.JSON,
    allowNull: false,
    validate: {
      isValidOptions(value) {
        if (!Array.isArray(value) || value.length < 2) {
          throw new Error('Options must be an array with at least 2 items');
        }
      }
    }
  },
  correctAnswer: {
    type: DataTypes.STRING(10),
    allowNull: false,
    validate: {
      isValidAnswer(value) {
        const validAnswers = ['A', 'B', 'C', 'D', 'E'];
        if (!validAnswers.includes(value.toUpperCase())) {
          throw new Error('Correct answer must be A, B, C, D, or E');
        }
      }
    }
  },
  explanation: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  difficulty: {
    type: DataTypes.ENUM('EASY', 'MEDIUM', 'HARD'),
    defaultValue: 'MEDIUM',
    allowNull: false
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
  imageUrl: {
    type: DataTypes.STRING(500),
    allowNull: true,
    validate: {
      len: [0, 500]
    }
  },
  questionImgUrl: {
    type: DataTypes.STRING(500),
    allowNull: true,
    validate: {
      len: [0, 500]
    }
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
    options: this.options,
    correctAnswer: this.correctAnswer,
    explanation: this.explanation,
    difficulty: this.difficulty,
    points: this.points,
    imageUrl: this.imageUrl,
    questionImgUrl: this.questionImgUrl,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

module.exports = Question;
