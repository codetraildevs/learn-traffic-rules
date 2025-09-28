const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const StudyReminder = sequelize.define('StudyReminder', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id',
    },
  },
  isEnabled: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  reminderTime: {
    type: DataTypes.TIME,
    allowNull: false,
  },
  daysOfWeek: {
    type: DataTypes.JSON,
    allowNull: false,
    defaultValue: [],
    validate: {
      isValidDays(value) {
        const validDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        if (!Array.isArray(value)) {
          throw new Error('Days of week must be an array');
        }
        const invalidDays = value.filter(day => !validDays.includes(day));
        if (invalidDays.length > 0) {
          throw new Error(`Invalid days: ${invalidDays.join(', ')}`);
        }
      },
    },
  },
  studyGoalMinutes: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 30,
    validate: {
      min: 5,
      max: 480, // 8 hours max
    },
  },
  timezone: {
    type: DataTypes.STRING,
    allowNull: true,
    defaultValue: 'UTC',
  },
  lastSentAt: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  nextScheduledAt: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
}, {
  tableName: 'studyreminders',
  timestamps: true,
  indexes: [
    {
      fields: ['userId'],
    },
    {
      fields: ['isEnabled'],
    },
    {
      fields: ['nextScheduledAt'],
    },
    {
      fields: ['isActive'],
    },
  ],
});

module.exports = StudyReminder;
