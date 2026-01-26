const { AccessCode, User } = require('../models');
const { validationResult } = require('express-validator');

// Get all access codes (Admin/Manager only)
const getAllAccessCodes = async (req, res) => {
  try {
    const { page = 1, limit = 20, userId, isUsed, isBlocked } = req.query;
    const offset = (page - 1) * limit;

    const whereClause = {};
    if (userId) whereClause.userId = userId;
    if (isUsed !== undefined) whereClause.isUsed = isUsed === 'true';
    if (isBlocked !== undefined) whereClause.isBlocked = isBlocked === 'true';

    const { count, rows: accessCodes } = await AccessCode.findAndCountAll({
      where: whereClause,
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'fullName', 'phoneNumber', 'role']
        },
        {
          model: User,
          as: 'generatedBy',
          attributes: ['id', 'fullName', 'role']
        }
      ],
      order: [['createdAt', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });



    // Convert Sequelize instances to plain objects to include associations
    const plainAccessCodes = accessCodes.map(code => code.get({ plain: true }));

    res.json({
      success: true,
      message: 'Access codes retrieved successfully',
      data: {
        accessCodes: plainAccessCodes,
        pagination: {
          total: count,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages: Math.ceil(count / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get all access codes error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Create access code (Admin/Manager only)
const createAccessCode = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { userId, paymentAmount } = req.body;
    const generatedByManagerId = req.user.id;

    // Check if user exists
    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Create access code with payment
    let accessCode;
    try {
      accessCode = await AccessCode.createWithPayment(
        userId,
        generatedByManagerId,
        parseFloat(paymentAmount)
      );
      console.log(`✅ Access code created successfully: ${accessCode.code} for user ${userId}`);
    } catch (createError) {
      console.error(`❌ Failed to create access code for user ${userId}:`, createError);
      
      // Check if it's a validation error (should return 400, not 500)
      if (createError.message && (
        createError.message.includes('Invalid payment amount') ||
        createError.message.includes('Invalid duration days')
      )) {
        return res.status(400).json({
          success: false,
          message: createError.message,
          error: process.env.NODE_ENV === 'development' ? createError.stack : undefined
        });
      }
      
      // For other errors (including timeouts), return 500
      return res.status(500).json({
        success: false,
        message: createError.message || 'Failed to create access code. Please try again.',
        error: process.env.NODE_ENV === 'development' ? createError.message : undefined
      });
    }

    res.status(201).json({
      success: true,
      message: 'Access code created successfully',
      data: {
        id: accessCode.id,
        code: accessCode.code,
        userId: accessCode.userId,
        paymentAmount: accessCode.paymentAmount,
        durationDays: accessCode.durationDays,
        paymentTier: accessCode.paymentTier,
        expiresAt: accessCode.expiresAt,
        isUsed: accessCode.isUsed
      }
    });
  } catch (error) {
    console.error('Create access code error (unexpected):', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Validate and use access code
const validateAccessCode = async (req, res) => {
  try {
    const { code } = req.body;
    const userId = req.user.id;

    if (!code) {
      return res.status(400).json({
        success: false,
        message: 'Access code is required'
      });
    }

    try {
      const accessCode = await AccessCode.validateAndUse(code, userId);
      
      res.json({
        success: true,
        message: 'Access code validated successfully',
        data: {
          accessCode,
          expiresAt: accessCode.expiresAt,
          durationDays: accessCode.durationDays,
          paymentTier: accessCode.paymentTier
        }
      });
    } catch (validationError) {
      // Record failed attempt if code exists
      const existingCode = await AccessCode.findOne({
        where: { code, userId }
      });
      
      if (existingCode) {
        await existingCode.recordFailedAttempt();
      }

      res.status(400).json({
        success: false,
        message: validationError.message
      });
    }
  } catch (error) {
    console.error('Validate access code error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get user's active access codes
const getUserAccessCodes = async (req, res) => {
  try {
    const userId = req.user.id;
    const accessCodes = await AccessCode.getActiveCodesForUser(userId);

    res.json({
      success: true,
      message: 'User access codes retrieved successfully',
      data: accessCodes
    });
  } catch (error) {
    console.error('Get user access codes error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get payment tiers
const getPaymentTiers = async (req, res) => {
  try {
    res.json({
      success: true,
      message: 'Payment tiers retrieved successfully',
      data: AccessCode.PAYMENT_TIERS
    });
  } catch (error) {
    console.error('Get payment tiers error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Block/Unblock access code (Admin/Manager only)
const toggleAccessCodeBlock = async (req, res) => {
  try {
    const { id } = req.params;
    const { isBlocked, blockedUntil } = req.body;

    const accessCode = await AccessCode.findByPk(id);
    if (!accessCode) {
      return res.status(404).json({
        success: false,
        message: 'Access code not found'
      });
    }

    const { retryDbOperation } = require('../utils/dbRetry');
    const { sequelize } = require('../config/database');
    
    const blockedUntilValue = isBlocked && blockedUntil ? new Date(blockedUntil) : null;
    
    // Use direct UPDATE to avoid lock contention
    await retryDbOperation(async () => {
      await sequelize.query(
        `UPDATE access_codes 
         SET isBlocked = :isBlocked,
             blockedUntil = :blockedUntil,
             updatedAt = :updatedAt
         WHERE id = :id`,
        {
          replacements: {
            id: accessCode.id,
            isBlocked,
            blockedUntil: blockedUntilValue,
            updatedAt: new Date()
          },
          type: sequelize.QueryTypes.UPDATE
        }
      );
      
      // Update instance properties
      accessCode.isBlocked = isBlocked;
      accessCode.blockedUntil = blockedUntilValue;
    }, {
      maxRetries: 3,
      retryDelay: 100,
      retryOnLockTimeout: true
    });

    res.json({
      success: true,
      message: `Access code ${isBlocked ? 'blocked' : 'unblocked'} successfully`,
      data: accessCode
    });
  } catch (error) {
    console.error('Toggle access code block error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Delete access code (Admin/Manager only)
const deleteAccessCode = async (req, res) => {
  try {
    const { id } = req.params;

    const accessCode = await AccessCode.findByPk(id);
    if (!accessCode) {
      return res.status(404).json({
        success: false,
        message: 'Access code not found'
      });
    }

    await accessCode.destroy();

    res.json({
      success: true,
      message: 'Access code deleted successfully'
    });
  } catch (error) {
    console.error('Delete access code error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

module.exports = {
  getAllAccessCodes,
  createAccessCode,
  validateAccessCode,
  getUserAccessCodes,
  getPaymentTiers,
  toggleAccessCodeBlock,
  deleteAccessCode
};
