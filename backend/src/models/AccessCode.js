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
    type: DataTypes.ENUM('1_MONTH', '3_MONTHS', '6_MONTHS', 'CUSTOM'),
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
  const { retryDbOperation } = require('../utils/dbRetry');
  const { sequelize } = require('../config/database');
  
  const attemptCount = this.attemptCount + 1;
  const lastAttemptAt = new Date();
  const shouldBlock = attemptCount >= 5;
  const blockedUntil = shouldBlock ? new Date(Date.now() + 60 * 60 * 1000) : null;
  
  // Use direct UPDATE to avoid lock contention
  await retryDbOperation(async () => {
    await sequelize.query(
      `UPDATE access_codes 
       SET attemptCount = :attemptCount, 
           lastAttemptAt = :lastAttemptAt,
           isBlocked = :isBlocked,
           blockedUntil = :blockedUntil,
           updatedAt = :updatedAt
       WHERE id = :id`,
      {
        replacements: {
          id: this.id,
          attemptCount,
          lastAttemptAt,
          isBlocked: shouldBlock,
          blockedUntil,
          updatedAt: new Date()
        },
        type: sequelize.QueryTypes.UPDATE
      }
    );
    
    // Update instance properties
    this.attemptCount = attemptCount;
    this.lastAttemptAt = lastAttemptAt;
    this.isBlocked = shouldBlock;
    this.blockedUntil = blockedUntil;
  }, {
    maxRetries: 3,
    retryDelay: 100,
    retryOnLockTimeout: true
  });
};

AccessCode.prototype.markAsUsed = async function() {
  const { retryDbOperation } = require('../utils/dbRetry');
  const { sequelize } = require('../config/database');
  
  const usedAt = new Date();
  
  // Use direct UPDATE to avoid lock contention
  await retryDbOperation(async () => {
    await sequelize.query(
      `UPDATE access_codes 
       SET isUsed = true, 
           usedAt = :usedAt,
           updatedAt = :updatedAt
       WHERE id = :id`,
      {
        replacements: {
          id: this.id,
          usedAt,
          updatedAt: new Date()
        },
        type: sequelize.QueryTypes.UPDATE
      }
    );
    
    // Update instance properties
    this.isUsed = true;
    this.usedAt = usedAt;
  }, {
    maxRetries: 3,
    retryDelay: 100,
    retryOnLockTimeout: true
  });
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
  // Convert amount to number for comparison (handles string, decimal, etc.)
  const numericAmount = Number(amount);
  
  if (isNaN(numericAmount)) {
    return null;
  }
  
  for (const [tier, config] of Object.entries(tiers)) {
    // Compare as numbers to handle decimal precision and string conversion
    if (Math.abs(config.amount - numericAmount) < 0.01) {
      return { tier, ...config };
    }
  }
  return null;
};

AccessCode.createWithPayment = async function(userId, generatedByManagerId, paymentAmount, durationDays = null) {
  const { retryDbOperation } = require('../utils/dbRetry');
  
  // Validate payment amount
  const numericPaymentAmount = Number(paymentAmount);
  if (isNaN(numericPaymentAmount) || numericPaymentAmount <= 0) {
    throw new Error(`Invalid payment amount: ${paymentAmount}. Payment amount must be a positive number.`);
  }
  
  let tierConfig = null;
  let days = null;
  let tier = 'CUSTOM';

  // If durationDays is provided and valid, use it for custom dates
  if (durationDays !== null && durationDays !== undefined && durationDays !== '') {
    const numericDurationDays = Number(durationDays);
    if (isNaN(numericDurationDays) || numericDurationDays < 1) {
      throw new Error(`Invalid duration days: ${durationDays}. Duration must be a positive number greater than or equal to 1.`);
    }
    if (numericDurationDays > 3650) {
      throw new Error(`Invalid duration days: ${durationDays}. Duration cannot exceed 3650 days (10 years).`);
    }
    days = numericDurationDays;
    tier = 'CUSTOM';
    console.log(`📅 Using custom duration: ${days} days for payment amount: ${numericPaymentAmount} RWF`);
  } else {
    // Otherwise, use payment tier logic (1500→30 days, 3000→90 days, 5000→180 days)
    tierConfig = AccessCode.getPaymentTierByAmount(numericPaymentAmount);
    if (!tierConfig) {
      const validTiers = Object.values(AccessCode.PAYMENT_TIERS).map(t => `${t.amount} (${t.days} days)`).join(', ');
      throw new Error(
        `Invalid payment amount: ${numericPaymentAmount} RWF. ` +
        `Valid payment tier amounts are: ${validTiers}. ` +
        `For custom payment amounts, you must provide durationDays parameter (1-3650 days).`
      );
    }
    days = tierConfig.days;
    tier = tierConfig.tier;
    console.log(`💰 Using payment tier: ${tier} (${days} days) for amount: ${numericPaymentAmount} RWF`);
  }

  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + days);

  // Retry on lock timeout with new code generation for duplicate entries
  return await retryDbOperation(async () => {
    let code = AccessCode.generateCode();
    let attempts = 0;
    const maxCodeAttempts = 5;
    
    while (attempts < maxCodeAttempts) {
      try {
        return await AccessCode.create({
          code,
          userId,
          generatedByManagerId,
          paymentAmount,
          durationDays: days,
          paymentTier: tier,
          expiresAt
        });
      } catch (error) {
        // If duplicate code, generate new one and retry immediately
        if (error.code === 'ER_DUP_ENTRY' || error.errno === 1062) {
          attempts++;
          code = AccessCode.generateCode();
          if (attempts >= maxCodeAttempts) {
            throw new Error('Failed to generate unique access code after multiple attempts');
          }
          continue;
        }
        // For other errors (including lock timeout), throw to trigger retry logic
        throw error;
      }
    }
  }, {
    maxRetries: 3,
    retryDelay: 100,
    retryOnLockTimeout: true,
    onRetry: (attempt, maxRetries, delay, error) => {
      console.warn(`⚠️ Lock timeout creating access code for user ${userId}, retrying in ${delay}ms (attempt ${attempt}/${maxRetries})`);
    }
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
