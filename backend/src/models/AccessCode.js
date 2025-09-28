const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const AccessCode = sequelize.define('AccessCode', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  code: {
    type: DataTypes.STRING(12),
    allowNull: false,
    unique: true,
    validate: {
      len: [8, 12]
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
  // Payment and duration fields
  paymentAmount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    comment: 'Payment amount in Rwandan Francs (RWF)'
  },
  durationDays: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: 'Duration in days based on payment tier'
  },
  paymentTier: {
    type: DataTypes.ENUM('1_MONTH', '3_MONTHS', '6_MONTHS'),
    allowNull: false,
    comment: 'Payment tier for easy reference'
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
  },
  // Security and audit fields
  attemptCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    allowNull: false,
    comment: 'Number of failed attempts to use this code'
  },
  lastAttemptAt: {
    type: DataTypes.DATE,
    allowNull: true,
    comment: 'Last failed attempt timestamp'
  },
  isBlocked: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    allowNull: false,
    comment: 'Whether code is blocked due to too many attempts'
  },
  blockedUntil: {
    type: DataTypes.DATE,
    allowNull: true,
    comment: 'Blocked until timestamp'
  }
}, {
  tableName: 'access_codes',
  timestamps: true,
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  indexes: [
    {
      name: 'idx_access_codes_code',
      fields: ['code'],
      unique: true
    },
    {
      name: 'idx_access_codes_user_id',
      fields: ['userId']
    },
    {
      name: 'idx_access_codes_expires_at',
      fields: ['expiresAt']
    },
    {
      name: 'idx_access_codes_is_used',
      fields: ['isUsed']
    },
    {
      name: 'idx_access_codes_active',
      fields: ['isUsed', 'expiresAt', 'isBlocked']
    },
    {
      name: 'idx_access_codes_generated_by',
      fields: ['generatedByManagerId']
    }
  ]
});

// Instance methods
AccessCode.prototype.toJSON = function() {
  return {
    id: this.id,
    code: this.code,
    userId: this.userId,
    generatedByManagerId: this.generatedByManagerId,
    paymentAmount: this.paymentAmount,
    durationDays: this.durationDays,
    paymentTier: this.paymentTier,
    expiresAt: this.expiresAt,
    isUsed: this.isUsed,
    usedAt: this.usedAt,
    attemptCount: this.attemptCount,
    isBlocked: this.isBlocked,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

// Security methods
AccessCode.prototype.isExpired = function() {
  return new Date() > this.expiresAt;
};

AccessCode.prototype.isCurrentlyBlocked = function() {
  if (!this.isBlocked) return false;
  if (!this.blockedUntil) return true;
  return new Date() < this.blockedUntil;
};

AccessCode.prototype.canBeUsed = function() {
  return !this.isUsed && !this.isExpired() && !this.isCurrentlyBlocked();
};

AccessCode.prototype.recordFailedAttempt = async function() {
  this.attemptCount += 1;
  this.lastAttemptAt = new Date();
  
  // Block after 5 failed attempts for 1 hour
  if (this.attemptCount >= 5) {
    this.isBlocked = true;
    this.blockedUntil = new Date(Date.now() + 60 * 60 * 1000); // 1 hour
  }
  
  await this.save();
};

AccessCode.prototype.markAsUsed = async function() {
  this.isUsed = true;
  this.usedAt = new Date();
  await this.save();
};

// Static methods
AccessCode.generateCode = function() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = '';
  for (let i = 0; i < 10; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
};

// Payment tier configuration
AccessCode.PAYMENT_TIERS = {
  '1_MONTH': { amount: 1500, days: 30 },
  '3_MONTHS': { amount: 3000, days: 90 },
  '6_MONTHS': { amount: 5000, days: 180 }
};

AccessCode.getPaymentTierByAmount = function(amount) {
  const tiers = AccessCode.PAYMENT_TIERS;
  for (const [tier, config] of Object.entries(tiers)) {
    if (config.amount === amount) {
      return { tier, ...config };
    }
  }
  return null;
};

AccessCode.createWithPayment = async function(userId, generatedByManagerId, paymentAmount) {
  const tierConfig = AccessCode.getPaymentTierByAmount(paymentAmount);
  if (!tierConfig) {
    throw new Error('Invalid payment amount');
  }

  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + tierConfig.days);

  return AccessCode.create({
    code: AccessCode.generateCode(),
    userId,
    generatedByManagerId,
    paymentAmount,
    durationDays: tierConfig.days,
    paymentTier: tierConfig.tier,
    expiresAt
  });
};

AccessCode.validateAndUse = async function(code, userId) {
  const accessCode = await AccessCode.findOne({
    where: {
      code,
      userId,
      isUsed: false
    }
  });

  if (!accessCode) {
    throw new Error('Invalid access code');
  }

  if (accessCode.isExpired()) {
    throw new Error('Access code has expired');
  }

  if (accessCode.isCurrentlyBlocked()) {
    throw new Error('Access code is temporarily blocked due to too many failed attempts');
  }

  await accessCode.markAsUsed();
  return accessCode;
};

AccessCode.getActiveCodesForUser = function(userId) {
  return AccessCode.findAll({
    where: {
      userId,
      isUsed: false,
      isBlocked: false,
      expiresAt: {
        [sequelize.Sequelize.Op.gt]: new Date()
      }
    },
    order: [['expiresAt', 'ASC']]
  });
};

module.exports = AccessCode;
