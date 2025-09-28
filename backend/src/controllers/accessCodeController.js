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
    const accessCode = await AccessCode.createWithPayment(
      userId,
      generatedByManagerId,
      parseFloat(paymentAmount)
    );

    res.status(201).json({
      success: true,
      message: 'Access code created successfully',
      data: accessCode
    });
  } catch (error) {
    console.error('Create access code error:', error);
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

    accessCode.isBlocked = isBlocked;
    if (isBlocked && blockedUntil) {
      accessCode.blockedUntil = new Date(blockedUntil);
    } else if (!isBlocked) {
      accessCode.blockedUntil = null;
    }

    await accessCode.save();

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
