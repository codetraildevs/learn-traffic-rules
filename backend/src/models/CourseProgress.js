const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const CourseProgress = sequelize.define('CourseProgress', {
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
    },
    onDelete: 'CASCADE'
  },
  courseId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'courses',
      key: 'id'
    },
    onDelete: 'CASCADE'
  },
  completedContentCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    allowNull: false
  },
  totalContentCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    allowNull: false
  },
  progressPercentage: {
    type: DataTypes.DECIMAL(5, 2),
    defaultValue: 0.00,
    allowNull: false,
    validate: {
      min: 0,
      max: 100
    }
  },
  isCompleted: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    allowNull: false
  },
  lastAccessedAt: {
    type: DataTypes.DATE,
    allowNull: true
  },
  completedAt: {
    type: DataTypes.DATE,
    allowNull: true
  }
}, {
  tableName: 'course_progress',
  timestamps: true,
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  indexes: [
    {
      unique: true,
      fields: ['userId', 'courseId']
    }
  ]
});

// Instance methods
CourseProgress.prototype.toJSON = function() {
  return {
    id: this.id,
    userId: this.userId,
    courseId: this.courseId,
    completedContentCount: this.completedContentCount,
    totalContentCount: this.totalContentCount,
    progressPercentage: parseFloat(this.progressPercentage) || 0,
    isCompleted: this.isCompleted,
    lastAccessedAt: this.lastAccessedAt,
    completedAt: this.completedAt,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

module.exports = CourseProgress;

