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
  },
  examType: {
    type: DataTypes.ENUM('kinyarwanda', 'english', 'french'),
    allowNull: true,
    defaultValue: 'kinyarwanda',
    validate: {
      isIn: [['kinyarwanda', 'english', 'french']]
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
    passingScore: this.passingScore,
    isActive: this.isActive,
    examImgUrl: this.examImgUrl,
    examType: this.examType,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

module.exports = Exam;
