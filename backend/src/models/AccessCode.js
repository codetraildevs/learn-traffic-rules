const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const AccessCode = sequelize.define('AccessCode', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  code: {
    type: DataTypes.STRING(50),
    allowNull: false,
    unique: true,
    validate: {
      len: [8, 50]
    }
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  generatedByManagerId: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  expiresAt: {
    type: DataTypes.DATE,
    allowNull: false
  },
  isUsed: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    allowNull: false
  },
  usedAt: {
    type: DataTypes.DATE,
    allowNull: true
  }
}, {
  tableName: 'access_codes',
  timestamps: true,
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
});

// Instance methods
AccessCode.prototype.toJSON = function() {
  return {
    id: this.id,
    code: this.code,
    userId: this.userId,
    generatedByManagerId: this.generatedByManagerId,
    expiresAt: this.expiresAt,
    isUsed: this.isUsed,
    usedAt: this.usedAt,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

// Static methods
AccessCode.generateCode = function() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = '';
  for (let i = 0; i < 8; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

AccessCode.isValid = function(code, userId, examId) {
  return AccessCode.findOne({
    where: {
      code,
      userId,
      examId,
      isUsed: false,
      expiresAt: {
        [sequelize.Sequelize.Op.gt]: new Date()
      }
    }
  });
};

module.exports = AccessCode;
