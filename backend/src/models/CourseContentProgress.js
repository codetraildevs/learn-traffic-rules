const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const CourseContentProgress = sequelize.define('CourseContentProgress', {
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
  courseContentId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'course_contents',
      key: 'id'
    },
    onDelete: 'CASCADE'
  },
  isCompleted: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    allowNull: false
  },
  completedAt: {
    type: DataTypes.DATE,
    allowNull: true
  },
  timeSpent: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    allowNull: false,
    comment: 'Time spent in seconds'
  }
}, {
  tableName: 'course_content_progress',
  timestamps: true,
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  indexes: [
    {
      unique: true,
      fields: ['userId', 'courseContentId']
    },
    {
      fields: ['userId', 'courseId']
    }
  ]
});

// Instance methods
CourseContentProgress.prototype.toJSON = function() {
  return {
    id: this.id,
    userId: this.userId,
    courseId: this.courseId,
    courseContentId: this.courseContentId,
    isCompleted: this.isCompleted,
    completedAt: this.completedAt,
    timeSpent: this.timeSpent,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

module.exports = CourseContentProgress;

