const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Course = sequelize.define('Course', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  title: {
    type: DataTypes.STRING(255),
    allowNull: false,
    validate: {
      len: [3, 255]
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
  courseType: {
    type: DataTypes.ENUM('free', 'paid'),
    defaultValue: 'free',
    allowNull: false
  },
  courseImageUrl: {
    type: DataTypes.STRING(500),
    allowNull: true,
    validate: {
      len: [0, 500]
    }
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
    allowNull: false
  }
}, {
  tableName: 'courses',
  timestamps: true,
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
});

// Instance methods
Course.prototype.toJSON = function() {
  return {
    id: this.id,
    title: this.title,
    description: this.description,
    category: this.category,
    difficulty: this.difficulty,
    courseType: this.courseType,
    courseImageUrl: this.courseImageUrl,
    isActive: this.isActive,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

module.exports = Course;

