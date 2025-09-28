const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Notification = sequelize.define('Notification', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id',
    },
  },
  type: {
    type: DataTypes.ENUM(
      'EXAM_REMINDER',
      'ACHIEVEMENT_ALERT',
      'STUDY_REMINDER',
      'SYSTEM_UPDATE',
      'PAYMENT_NOTIFICATION',
      'WEEKLY_REPORT',
      'PAYMENT_APPROVED',
      'PAYMENT_REJECTED',
      'EXAM_PASSED',
      'EXAM_FAILED',
      'NEW_EXAM',
      'ACCESS_GRANTED',
      'ACCESS_REVOKED',
      'GENERAL'
    ),
    allowNull: false,
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  message: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  data: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: {},
  },
  isRead: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  isPushSent: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  scheduledFor: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  priority: {
    type: DataTypes.ENUM('LOW', 'MEDIUM', 'HIGH', 'URGENT'),
    defaultValue: 'MEDIUM',
  },
  category: {
    type: DataTypes.ENUM(
      'EXAM',
      'PAYMENT',
      'ACHIEVEMENT',
      'SYSTEM',
      'STUDY',
      'ACCESS',
      'GENERAL'
    ),
    allowNull: false,
  },
}, {
  tableName: 'Notifications',
  timestamps: true,
  indexes: [
    {
      fields: ['userId'],
    },
    {
      fields: ['type'],
    },
    {
      fields: ['isRead'],
    },
    {
      fields: ['scheduledFor'],
    },
    {
      fields: ['category'],
    },
  ],
});

module.exports = Notification;
