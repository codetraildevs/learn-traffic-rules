const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const CourseContent = sequelize.define('CourseContent', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
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
  contentType: {
    type: DataTypes.ENUM('text', 'image', 'audio', 'video', 'link'),
    allowNull: false,
    defaultValue: 'text'
  },
  content: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  title: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  displayOrder: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  }
}, {
  tableName: 'course_contents',
  timestamps: true,
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
});

// Instance methods
CourseContent.prototype.toJSON = function() {
  return {
    id: this.id,
    courseId: this.courseId,
    contentType: this.contentType,
    content: this.content,
    title: this.title,
    displayOrder: this.displayOrder,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

module.exports = CourseContent;

