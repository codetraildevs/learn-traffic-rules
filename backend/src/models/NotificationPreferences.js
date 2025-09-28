const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const NotificationPreferences = sequelize.define('NotificationPreferences', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    unique: true,
    references: {
      model: 'users',
      key: 'id',
    },
  },
  pushNotifications: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  smsNotifications: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  examReminders: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  paymentUpdates: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  systemAnnouncements: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  studyReminders: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  achievementNotifications: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  weeklyReports: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  quietHoursEnabled: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  quietHoursStart: {
    type: DataTypes.TIME,
    defaultValue: '22:00:00',
  },
  quietHoursEnd: {
    type: DataTypes.TIME,
    defaultValue: '07:00:00',
  },
  vibrationEnabled: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  soundEnabled: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
}, {
  tableName: 'notificationpreferences',
  timestamps: true,
  indexes: [
    {
      fields: ['userId'],
      unique: true,
    },
  ],
});

module.exports = NotificationPreferences;
