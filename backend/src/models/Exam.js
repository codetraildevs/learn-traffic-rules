const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Exam = sequelize.define('Exam', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  title: {
    type: DataTypes.STRING(255),
    allowNull: false,
    validate: {
      len: [5, 255]
    }
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  category: {
    type: DataTypes.STRING(100),
    allowNull: true,
    validate: {
      len: [2, 100]
    }
  },
  difficulty: {
    type: DataTypes.ENUM('EASY', 'MEDIUM', 'HARD'),
    defaultValue: 'MEDIUM',
    allowNull: false
  },
  duration: {
    type: DataTypes.INTEGER,
    defaultValue: 30,
    allowNull: false,
    validate: {
      min: 5,
      max: 180
    }
  },
  questionCount: {
    type: DataTypes.INTEGER,
    defaultValue: 20,
    allowNull: false,
    validate: {
      min: 5,
      max: 100
    }
  },
  passingScore: {
    type: DataTypes.INTEGER,
    defaultValue: 70,
    allowNull: false,
    validate: {
      min: 50,
      max: 100
    }
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
    allowNull: false
  },
  examImgUrl: {
    type: DataTypes.STRING(500),
    allowNull: true,
    validate: {
      len: [0, 500]
    }
  }
}, {
  tableName: 'exams',
  timestamps: true,
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
});

// Instance methods
Exam.prototype.toJSON = function() {
  return {
    id: this.id,
    title: this.title,
    description: this.description,
    category: this.category,
    difficulty: this.difficulty,
    duration: this.duration,
    questionCount: this.questionCount,
    passingScore: this.passingScore,
    isActive: this.isActive,
    examImgUrl: this.examImgUrl,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

module.exports = Exam;
