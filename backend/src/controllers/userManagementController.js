const { User, AccessCode, ExamResult, PaymentRequest, Exam } = require('../models');
const { sequelize } = require('../config/database');
const { validationResult } = require('express-validator');
const notificationService = require('../services/notificationService');

// Get all users with pagination and filtering
const getAllUsers = async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      search = '', 
      role = '', 
      sortBy = 'createdAt', 
      sortOrder = 'DESC',
      filter = '', // 'with_code', 'without_code', 'called', 'not_called'
      startDate = '', // ISO date string
      endDate = '', // ISO date string
      filterByToday = false // 'true' or 'false' as string
    } = req.query;
    
    const offset = (page - 1) * limit;
    const { Op } = require('sequelize');
    const Sequelize = require('sequelize');
    
    // Build where clause
    const whereClause = {};
    if (search) {
      // Use LIKE with LOWER for case-insensitive search in MySQL
      whereClause[Op.or] = [
        Sequelize.where(
          Sequelize.fn('LOWER', Sequelize.col('User.fullName')),
          { [Op.like]: `%${search.toLowerCase()}%` }
        ),
        Sequelize.where(
          Sequelize.fn('LOWER', Sequelize.col('User.phoneNumber')),
          { [Op.like]: `%${search.toLowerCase()}%` }
        )
      ];
    }
    if (role) {
      whereClause.role = role;
    }

    // Date filters
    if (filterByToday === 'true' || filterByToday === true) {
      const today = new Date();
      const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
      const todayEnd = new Date(todayStart);
      todayEnd.setDate(todayEnd.getDate() + 1);
      whereClause.createdAt = {
        [Op.gte]: todayStart,
        [Op.lt]: todayEnd
      };
    } else if (startDate || endDate) {
      whereClause.createdAt = {};
      if (startDate) {
        const start = new Date(startDate);
        start.setHours(0, 0, 0, 0);
        whereClause.createdAt[Op.gte] = start;
      }
      if (endDate) {
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);
        whereClause.createdAt[Op.lte] = end;
      }
    }

    // Build include clause with access code filtering
    const includeClause = [
      {
        model: AccessCode,
        as: 'accessCodes',
        attributes: ['id', 'isUsed', 'expiresAt', 'paymentTier', 'createdAt'],
        required: false
      }
    ];

    // Access code filters (with_code, without_code)
    if (filter === 'with_code') {
      // Users with active access codes
      includeClause[0].required = true;
      includeClause[0].where = {
        isUsed: false,
        expiresAt: { [Op.gt]: new Date() }
      };
    } else if (filter === 'without_code') {
      // Users without active access codes - use subquery
      // This is complex, we'll handle it after getting users
    }

    // Get users with access code count
    let { count, rows: users } = await User.findAndCountAll({
      where: whereClause,
      include: includeClause,
      attributes: [
        'id', 'fullName', 'phoneNumber', 'role', 
        'isActive', 'lastLogin', 'createdAt', 'updatedAt',
        'isBlocked', 'blockReason', 'blockedAt', 'preferredLanguage'
      ],
      order: [[sortBy, sortOrder.toUpperCase()]],
      limit: parseInt(limit),
      offset: parseInt(offset),
      distinct: true
    });


    // Get called users for the current admin (for called/not_called filter)
    const adminId = req.user?.userId;
    let calledUserIds = new Set();
    if ((filter === 'called' || filter === 'not_called') && adminId) {
      try {
        const calledUsers = await sequelize.query(
          `SELECT user_id FROM user_call_tracking WHERE admin_id = :adminId`,
          {
            replacements: { adminId },
            type: sequelize.QueryTypes.SELECT
          }
        );
        calledUserIds = new Set(calledUsers.map(r => r.user_id));
      } catch (error) {
        console.error('Error fetching called users:', error);
        // Continue without call tracking filter if table doesn't exist yet
      }
    }

    // Process users first to check access codes and call status
    let processedUsers = users.map(user => {
      const userJson = user.toJSON();
      const activeCodes = userJson.accessCodes.filter(code => 
        !code.isUsed && new Date(code.expiresAt) > new Date()
      );
      const usedCodes = userJson.accessCodes.filter(code => code.isUsed);
      const expiredCodes = userJson.accessCodes.filter(code => 
        !code.isUsed && new Date(code.expiresAt) <= new Date()
      );

      // Calculate remaining days from the latest active access code
      let remainingDays = 0;
      let expiresAt = null;
      if (activeCodes.length > 0) {
        const latestActiveCode = activeCodes.reduce((latest, current) => 
          new Date(current.expiresAt) > new Date(latest.expiresAt) ? current : latest
        );
        const now = new Date();
        const expiryDate = new Date(latestActiveCode.expiresAt);
        const diffTime = expiryDate - now;
        remainingDays = Math.max(0, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));
        expiresAt = latestActiveCode.expiresAt;
      }

      return {
        ...userJson,
        remainingDays,
        expiresAt,
        accessCodeStats: {
          total: userJson.accessCodes.length,
          active: activeCodes.length,
          used: usedCodes.length,
          expired: expiredCodes.length,
          latestCode: userJson.accessCodes.length > 0 
            ? userJson.accessCodes[0] 
            : null
        },
        _hasActiveCode: activeCodes.length > 0,
        _isCalled: calledUserIds.has(user.id)
      };
    });

    // Apply filters that need processing (without_code, called, not_called)
    if (filter === 'without_code') {
      processedUsers = processedUsers.filter(user => !user._hasActiveCode);
    } else if (filter === 'called') {
      processedUsers = processedUsers.filter(user => user._isCalled);
    } else if (filter === 'not_called') {
      processedUsers = processedUsers.filter(user => !user._isCalled);
    }

    // Remove internal filter flags
    processedUsers = processedUsers.map(user => {
      const { _hasActiveCode, _isCalled, ...userWithoutFlags } = user;
      return userWithoutFlags;
    });

    // Recalculate count for filters that need post-processing
    if (filter === 'without_code' || filter === 'called' || filter === 'not_called') {
      // Get all users matching base filters (without pagination)
      const allUsersForCount = await User.findAll({
        where: whereClause,
        include: includeClause,
        attributes: ['id'],
        distinct: true
      });

      // Process and filter
      let filteredForCount = allUsersForCount.map(user => {
        const userJson = user.toJSON();
        const activeCodes = userJson.accessCodes.filter(code => 
          !code.isUsed && new Date(code.expiresAt) > new Date()
        );
        return {
          id: user.id,
          _hasActiveCode: activeCodes.length > 0,
          _isCalled: calledUserIds.has(user.id)
        };
      });

      if (filter === 'without_code') {
        filteredForCount = filteredForCount.filter(u => !u._hasActiveCode);
      } else if (filter === 'called') {
        filteredForCount = filteredForCount.filter(u => u._isCalled);
      } else if (filter === 'not_called') {
        filteredForCount = filteredForCount.filter(u => !u._isCalled);
      }

      count = filteredForCount.length;
      
      // Re-apply pagination to processed users
      const startIndex = offset;
      const endIndex = offset + parseInt(limit);
      processedUsers = processedUsers.slice(startIndex, endIndex);
    }

    res.json({
      success: true,
      message: 'Users retrieved successfully',
      data: {
        users: processedUsers,
        pagination: {
          total: count,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages: Math.ceil(count / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get all users error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get user details with access codes
const getUserDetails = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findByPk(id, {
      include: [
        {
          model: AccessCode,
          as: 'accessCodes',
          order: [['createdAt', 'DESC']]
        }
      ],
      attributes: [
        'id', 'fullName', 'phoneNumber', 'role', 
        'isActive', 'lastLogin', 'createdAt', 'updatedAt',
        'isBlocked', 'blockReason', 'blockedAt', 'preferredLanguage'
      ]
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const userJson = user.toJSON();
    const activeCodes = userJson.accessCodes.filter(code => 
      !code.isUsed && new Date(code.expiresAt) > new Date()
    );
    const usedCodes = userJson.accessCodes.filter(code => code.isUsed);
    const expiredCodes = userJson.accessCodes.filter(code => 
      !code.isUsed && new Date(code.expiresAt) <= new Date()
    );

    // Calculate remaining days from the latest active access code
    let remainingDays = 0;
    if (activeCodes.length > 0) {
      const latestActiveCode = activeCodes.reduce((latest, current) => 
        new Date(current.expiresAt) > new Date(latest.expiresAt) ? current : latest
      );
      const now = new Date();
      const expiryDate = new Date(latestActiveCode.expiresAt);
      const diffTime = expiryDate - now;
      remainingDays = Math.max(0, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));
    }

    res.json({
      success: true,
      message: 'User details retrieved successfully',
      data: {
        ...userJson,
        remainingDays,
        accessCodeStats: {
          total: userJson.accessCodes.length,
          active: activeCodes.length,
          used: usedCodes.length,
          expired: expiredCodes.length
        }
      }
    });
  } catch (error) {
    console.error('Get user details error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Create access code for specific user
const createAccessCodeForUser = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { id: userId } = req.params;
    const { paymentAmount, durationDays } = req.body;
    const generatedByManagerId = req.user.userId;

    console.log('🔍 Creating access code for user:', {
      userId,
      paymentAmount,
      durationDays: durationDays || 'not provided (using tier)',
      generatedByManagerId
    });

    // Check if user exists
    const user = await User.findByPk(userId);
    console.log('🔍 User found:', user ? 'Yes' : 'No');
    
    if (!user) {
      console.log('❌ User not found with ID:', userId);
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Ensure paymentAmount is a number
    const numericPaymentAmount = Number(paymentAmount);
    if (isNaN(numericPaymentAmount) || numericPaymentAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payment amount'
      });
    }

    // Validate durationDays if provided
    let numericDurationDays = null;
    if (durationDays !== undefined && durationDays !== null) {
      numericDurationDays = Number(durationDays);
      if (isNaN(numericDurationDays) || numericDurationDays < 1 || numericDurationDays > 3650) {
        return res.status(400).json({
          success: false,
          message: 'Invalid duration days. Must be between 1 and 3650.'
        });
      }
    }

    // Create access code with payment (with optional custom duration)
    console.log(`🔑 Attempting to create access code for user ${userId}...`);
    let accessCode;
    try {
      accessCode = await AccessCode.createWithPayment(
        userId,
        generatedByManagerId,
        numericPaymentAmount,
        numericDurationDays
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

    // Get user details for response
    let userWithCode;
    try {
      userWithCode = await User.findByPk(userId, {
        include: [
          {
            model: AccessCode,
            as: 'accessCodes',
            where: { id: accessCode.id },
            required: false
          }
        ],
        attributes: ['id', 'fullName', 'phoneNumber', 'role']
      });
    } catch (userFetchError) {
      console.warn(`⚠️ Failed to fetch user with access code, but access code was created:`, userFetchError);
      // Still return success since access code was created
      userWithCode = await User.findByPk(userId, {
        attributes: ['id', 'fullName', 'phoneNumber', 'role']
      });
    }

    // Send notification to user about access granted (non-blocking)
    try {
      await notificationService.notifyAccessGranted(userId, accessCode);
      console.log(`📧 Notification sent to user ${userId} about access granted`);
    } catch (notificationError) {
      console.error('⚠️ Failed to send access granted notification (non-critical):', notificationError);
      // Don't fail the request if notification fails
    }

    res.status(201).json({
      success: true,
      message: 'Access code created successfully',
      data: {
        accessCode: {
          id: accessCode.id,
          code: accessCode.code,
          userId: accessCode.userId,
          paymentAmount: accessCode.paymentAmount,
          durationDays: accessCode.durationDays,
          paymentTier: accessCode.paymentTier,
          expiresAt: accessCode.expiresAt,
          isUsed: accessCode.isUsed
        },
        user: userWithCode
      }
    });
  } catch (error) {
    console.error('❌ Create access code for user error (unexpected):', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get user's access codes
const getUserAccessCodes = async (req, res) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 20, status = '' } = req.query;
    const offset = (page - 1) * limit;

    // Check if user exists
    const user = await User.findByPk(id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Build where clause for access codes
    const whereClause = { userId: id };
    if (status === 'active') {
      whereClause.isUsed = false;
      whereClause.expiresAt = { [require('sequelize').Op.gt]: new Date() };
    } else if (status === 'used') {
      whereClause.isUsed = true;
    } else if (status === 'expired') {
      whereClause.isUsed = false;
      whereClause.expiresAt = { [require('sequelize').Op.lte]: new Date() };
    }

    const { count, rows: accessCodes } = await AccessCode.findAndCountAll({
      where: whereClause,
      include: [
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

    res.json({
      success: true,
      message: 'User access codes retrieved successfully',
      data: {
        accessCodes,
        user: {
          id: user.id,
          fullName: user.fullName,
          phoneNumber: user.phoneNumber
        },
        pagination: {
          total: count,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages: Math.ceil(count / limit)
        }
      }
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

// Toggle user active status
const toggleUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { isActive } = req.body;

    const user = await User.findByPk(id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    user.isActive = isActive;
    await user.save();

    res.json({
      success: true,
      message: `User ${isActive ? 'activated' : 'deactivated'} successfully`,
      data: {
        id: user.id,
        fullName: user.fullName,
        isActive: user.isActive
      }
    });
  } catch (error) {
    console.error('Toggle user status error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get user statistics
const getUserStatistics = async (req, res) => {
  try {
    const totalUsers = await User.count();
    const activeUsers = await User.count({ where: { isActive: true } });
    const adminUsers = await User.count({ where: { role: 'ADMIN' } });
    const managerUsers = await User.count({ where: { role: 'MANAGER' } });
    const regularUsers = await User.count({ where: { role: 'USER' } });

    // Access code statistics
    const totalAccessCodes = await AccessCode.count();
    const activeAccessCodes = await AccessCode.count({
      where: {
        isUsed: false,
        expiresAt: { [require('sequelize').Op.gt]: new Date() }
      }
    });
    const usedAccessCodes = await AccessCode.count({ where: { isUsed: true } });

    // Recent users (last 30 days)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const recentUsers = await User.count({
      where: {
        createdAt: { [require('sequelize').Op.gte]: thirtyDaysAgo }
      }
    });

    res.json({
      success: true,
      message: 'User statistics retrieved successfully',
      data: {
        users: {
          total: totalUsers,
          active: activeUsers,
          recent: recentUsers,
          byRole: {
            admin: adminUsers,
            manager: managerUsers,
            regular: regularUsers
          }
        },
        accessCodes: {
          total: totalAccessCodes,
          active: activeAccessCodes,
          used: usedAccessCodes
        }
      }
    });
  } catch (error) {
    console.error('Get user statistics error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get user dashboard data
const getUserDashboard = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Get user's exam results
    const examResults = await ExamResult.findAll({
      where: { userId: userId },
      include: [{
        model: require('../models/Exam'),
        attributes: ['id', 'title', 'category', 'difficulty']
      }],
      order: [['createdAt', 'DESC']],
      limit: 5
    });

    // Get user's payment requests
    const paymentRequests = await PaymentRequest.findAll({
      where: { userId: userId },
      order: [['createdAt', 'DESC']],
      limit: 5
    });

    // Get user's access codes
    const accessCodes = await AccessCode.findAll({
      where: { 
        userId: userId,
        isUsed: false,
        expiresAt: {
          [require('sequelize').Op.gt]: new Date()
        }
      },
      order: [['createdAt', 'DESC']]
    });

    // Calculate statistics
    const totalExams = examResults.length;
    const passedExams = examResults.filter(result => result.passed).length;
    const averageScore = totalExams > 0 
      ? Math.round(examResults.reduce((sum, result) => sum + result.score, 0) / totalExams)
      : 0;

    res.json({
      success: true,
      message: 'Dashboard data retrieved successfully',
      data: {
        statistics: {
          totalExams,
          passedExams,
          failedExams: totalExams - passedExams,
          averageScore,
          activeAccessCodes: accessCodes.length
        },
        recentResults: examResults,
        recentPayments: paymentRequests,
        activeAccessCodes: accessCodes
      }
    });
  } catch (error) {
    console.error('Get dashboard error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get individual user statistics (Admin/Manager only)
const getUserIndividualStatistics = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findByPk(id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Get user's exam results
    const examResults = await ExamResult.findAll({
      where: { userId: id },
      include: [{
        model: require('../models/Exam'),
        attributes: ['id', 'title', 'category', 'difficulty']
      }]
    });

    // Get user's payment requests
    const paymentRequests = await PaymentRequest.findAll({
      where: { userId: id }
    });

    // Calculate statistics
    const totalExams = examResults.length;
    const passedExams = examResults.filter(result => result.passed).length;
    const averageScore = totalExams > 0 
      ? Math.round(examResults.reduce((sum, result) => sum + result.score, 0) / totalExams)
      : 0;

    const totalSpent = paymentRequests
      .filter(request => request.status === 'APPROVED')
      .reduce((sum, request) => sum + parseFloat(request.amount), 0);

    res.json({
      success: true,
      message: 'User statistics retrieved successfully',
      data: {
        user: {
          id: user.id,
          fullName: user.fullName,
          phoneNumber: user.phoneNumber,
          role: user.role,
          isActive: user.isActive,
          createdAt: user.createdAt,
          lastLogin: user.lastLogin
        },
        statistics: {
          totalExams,
          passedExams,
          failedExams: totalExams - passedExams,
          averageScore,
          totalSpent,
          totalPaymentRequests: paymentRequests.length,
          approvedPayments: paymentRequests.filter(r => r.status === 'APPROVED').length,
          pendingPayments: paymentRequests.filter(r => r.status === 'PENDING').length,
          rejectedPayments: paymentRequests.filter(r => r.status === 'REJECTED').length
        },
        examResults,
        paymentRequests
      }
    });
  } catch (error) {
    console.error('Get user statistics error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get all exams for users (both free and paid, but filter out exams with 0 questions)
const getFreeExams = async (req, res) => {
  try {
    const userId = req.user.userId;
    
    // Check if user has any active access codes
    const activeAccessCodes = await AccessCode.count({
      where: {
        userId: userId,
        isUsed: false,
        expiresAt: {
          [require('sequelize').Op.gt]: new Date()
        }
      }
    });

    // Get examType filter from query parameter
    const { examType } = req.query;
    
    // Build where clause
    const whereClause = { isActive: true };
    if (examType) {
      // Filter by exam type (case-insensitive)
      whereClause.examType = examType.toLowerCase();
    }
    
    // Get all active exams (optionally filtered by examType)
    const allExams = await Exam.findAll({
      where: whereClause,
      attributes: ['id', 'title', 'description', 'category', 'difficulty', 'duration', 'passingScore', 'examImgUrl', 'examType', 'createdAt'],
      order: [['createdAt', 'ASC']] // Order by creation date ASC to get the oldest first
    });

    // Add question count to each exam and filter out exams with 0 questions
    const examsWithQuestions = [];
    for (const exam of allExams) {
      const questionCount = await require('../models/Question').count({
        where: { examId: exam.id }
      });
      
      // Only include exams that have questions
      if (questionCount > 0) {
        exam.dataValues.questionCount = questionCount;
        examsWithQuestions.push(exam);
        console.log(`📊 Exam ${exam.title}: ${questionCount} questions`);
      } else {
        console.log(`❌ Skipping exam ${exam.title}: 0 questions`);
      }
    }

    // If user has active access codes, return all exams with questions
    if (activeAccessCodes > 0) {
      return res.json({
        success: true,
        message: 'All exams retrieved successfully',
        data: {
          exams: examsWithQuestions.map(exam => ({
            ...exam.toJSON(),
            questionCount: exam.dataValues.questionCount
          })),
          isFreeUser: false,
          freeExamsRemaining: 0
        }
      });
    }

    // For free users, first 1 exam of EACH TYPE (oldest by creation date) is completely free with unlimited attempts
    // Group exams by type and identify the first 1 of each type
    const examsByType = {
      kinyarwanda: [],
      english: [],
      french: []
    };

    // Group exams by type (default to 'english' if examType is null)
    examsWithQuestions.forEach(exam => {
      const examType = exam.examType || 'english';
      if (examsByType[examType]) {
        examsByType[examType].push(exam);
      }
    });

    // Sort exams within each type by createdAt ASC (oldest first) to ensure correct free exam identification
    Object.keys(examsByType).forEach(type => {
      examsByType[type].sort((a, b) => {
        const dateA = new Date(a.createdAt);
        const dateB = new Date(b.createdAt);
        return dateA - dateB; // ASC order (oldest first)
      });
    });

    // Create a set of free exam IDs (first 1 of each type)
    const freeExamIds = new Set();
    Object.keys(examsByType).forEach(type => {
      const examsOfType = examsByType[type];
      // Get first 1 exam of this type (ordered by createdAt ASC)
      const firstOneOfType = examsOfType.slice(0, 1);
      firstOneOfType.forEach(exam => {
        freeExamIds.add(exam.id);
        console.log(`🆓 Free exam (${type}): ${exam.title} (ID: ${exam.id})`);
      });
    });

    // Debug: Log exam creation dates and which are marked as free
    console.log('📅 Exam Creation Dates by Type:');
    Object.keys(examsByType).forEach(type => {
      console.log(`   ${type.toUpperCase()} exams:`);
      examsByType[type].forEach((exam, index) => {
        const isFree = freeExamIds.has(exam.id);
        console.log(`     ${index + 1}. ${exam.title} - Created: ${exam.createdAt} - Free: ${isFree}`);
      });
    });

    // Mark which exams are free (first 1 of each type)
    const examsWithFreeStatus = examsWithQuestions.map(exam => ({
      ...exam.toJSON(),
      questionCount: exam.dataValues.questionCount,
      isFree: freeExamIds.has(exam.id),
      isFirstTwo: freeExamIds.has(exam.id)
    }));

    // Count free exams by type
    const freeExamsByType = {
      kinyarwanda: examsWithFreeStatus.filter(e => e.isFirstTwo && (e.examType || 'english') === 'kinyarwanda').length,
      english: examsWithFreeStatus.filter(e => e.isFirstTwo && (e.examType || 'english') === 'english').length,
      french: examsWithFreeStatus.filter(e => e.isFirstTwo && (e.examType || 'english') === 'french').length
    };
    console.log('🆓 Free exams by type:', freeExamsByType);

    res.json({
      success: true,
      message: 'All exams retrieved successfully',
      data: {
        exams: examsWithFreeStatus,
        isFreeUser: true,
        freeExamsRemaining: freeExamIds.size, // Total free exams (1 per type)
        freeExamIds: Array.from(freeExamIds),
        paymentInstructions: {
          title: 'Get Full Access',
          description: 'First exam of each language (Kinyarwanda, English, French) is free with unlimited attempts. For more exams:',
          steps: [
            'Choose a payment plan below',
            'Make payment via mobile money (MoMo: 808085) or bank transfer',
            'Contact admin to verify payment',
            'Receive access code via SMS or call'
          ],
          contactInfo: {
            phone: '+250 788 123 456',
            whatsapp: '+250 788 123 456',
          },
          paymentTiers: [
            { amount: 1500, days: 30, description: '1 Month Access' },
            { amount: 3000, days: 90, description: '3 Months Access' },
            { amount: 5000, days: 180, description: '6 Months Access' }
          ]
        }
      }
    });
  } catch (error) {
    console.error('Get free exams error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Submit free exam result
const submitFreeExamResult = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { examId, answers, timeSpent } = req.body;

    // Check if user has active access codes
    const activeAccessCodes = await AccessCode.count({
      where: {
        userId: userId,
        isUsed: false,
        expiresAt: {
          [require('sequelize').Op.gt]: new Date()
        }
      }
    });

    // If user has active access codes, they can take any exam
    if (activeAccessCodes > 0) {
      // Regular exam submission logic here
      return res.json({
        success: true,
        message: 'Exam submitted successfully',
        data: { isFreeExam: false }
      });
    }

    // For free users, check if they can take more free exams
    const freeExamResults = await ExamResult.count({
      where: {
        userId: userId,
        isFreeExam: true
      }
    });

    // With 1 free exam per type (3 types = 3 total free exams), check if user has used all 3
    if (freeExamResults >= 3) {
      return res.status(403).json({
        success: false,
        message: 'You have used all your free exams. Please purchase access to continue.',
        data: {
          freeExamsRemaining: 0,
          paymentInstructions: {
            title: 'Get Full Access',
            description: 'You have used your free exams. To access all exams and features:',
            steps: [
              'Choose a payment plan below',
              'Make payment via mobile money or bank transfer',
              'Contact admin to verify payment',
              'Receive access code via SMS or call'
            ],
            contactInfo: {
              phone: '+250 788 123 456',
              whatsapp: '+250 788 123 456',
            }
          }
        }
      });
    }

    // Get exam details
    const exam = await Exam.findByPk(examId);
    if (!exam) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found'
      });
    }

    // Get exam questions
    const questions = await require('../models/Question').findAll({
      where: { examId: examId }
    });

    // Calculate score
    let correctAnswers = 0;
    const results = [];

    for (const question of questions) {
      const userAnswer = answers[question.id];
      const isCorrect = userAnswer === question.correctAnswer;
      
      if (isCorrect) correctAnswers++;
      
      results.push({
        questionId: question.id,
        userAnswer: userAnswer,
        correctAnswer: question.correctAnswer,
        isCorrect: isCorrect,
        points: isCorrect ? question.points : 0
      });
    }

    const totalQuestions = questions.length;
    const score = Math.round((correctAnswers / totalQuestions) * 100);
    const passed = score >= exam.passingScore;

    // Create exam result
    const examResult = await ExamResult.create({
      userId: userId,
      examId: examId,
      score: score,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      timeSpent: timeSpent || 0,
      answers: JSON.stringify(results),
      passed: passed,
      isFreeExam: true,
      completedAt: new Date()
    });

    res.json({
      success: true,
      message: 'Free exam submitted successfully',
      data: {
        examResult: {
          id: examResult.id,
          score: score,
          totalQuestions: totalQuestions,
          correctAnswers: correctAnswers,
          passed: passed,
          isFreeExam: true
        },
        freeExamsRemaining: Math.max(0, 3 - freeExamResults - 1) // 3 total free exams (1 per type), minus already taken, minus this one
      }
    });
  } catch (error) {
    console.error('Submit free exam error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get current user's remaining days
const getMyRemainingDays = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Get user's active access codes
    const activeCodes = await AccessCode.findAll({
      where: {
        userId: userId,
        isUsed: false,
        expiresAt: {
          [require('sequelize').Op.gt]: new Date()
        }
      },
      order: [['expiresAt', 'DESC']]
    });

    // Calculate remaining days from the latest active access code
    let remainingDays = 0;
    if (activeCodes.length > 0) {
      const latestActiveCode = activeCodes[0]; // Already sorted by expiresAt DESC
      const now = new Date();
      const expiryDate = new Date(latestActiveCode.expiresAt);
      const diffTime = expiryDate - now;
      remainingDays = Math.max(0, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));
    }

    res.json({
      success: true,
      message: 'Remaining days retrieved successfully',
      data: {
        remainingDays,
        hasActiveAccess: activeCodes.length > 0,
        activeCodesCount: activeCodes.length
      }
    });
  } catch (error) {
    console.error('Get remaining days error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get payment instructions
const getPaymentInstructions = async (req, res) => {
  try {
    res.json({
      success: true,
      message: 'Payment instructions retrieved successfully',
      data: {
        title: 'Get Full Access to All Exams',
        description: 'Choose a payment plan and follow these steps:',
        steps: [
          'Select your preferred payment plan below',
          'Make payment via mobile money or bank transfer',
          'Contact admin to verify your payment',
          'Receive your access code via SMS or phone call',
          'Enter the access code in the app to unlock all features'
        ],
        contactInfo: {
          phone: '+250 788 123 456',
          whatsapp: '+250 788 123 456',
          workingHours: 'Monday - Friday: 8:00 AM - 6:00 PM'
        },
        paymentMethods: [
          {
            name: 'Mobile Money',
            details: 'MTN: 0788 123 456, Airtel: 0738 123 456',
            instructions: 'Send money and include your phone number in the reference'
          },
          {
            name: 'Bank Transfer',
            details: 'Bank: Bank of Kigali, Account: 1234567890',
            instructions: 'Include your phone number in the transfer reference'
          }
        ],
        paymentTiers: [
          { 
            amount: 1500, 
            days: 30, 
            description: '1 Month Access',
            features: ['Access to all exams', 'Unlimited attempts', 'Detailed results', 'Progress tracking', 'Study materials', 'Certificate download']
          },
          { 
            amount: 3000, 
            days: 90, 
            description: '3 Months Access',
            features: ['Access to all exams', 'Unlimited attempts', 'Detailed results', 'Progress tracking', 'Study materials', 'Certificate download', 'Priority support']
          },
          { 
            amount: 5000, 
            days: 180, 
            description: '6 Months Access',
            features: ['Access to all exams', 'Unlimited attempts', 'Detailed results', 'Progress tracking', 'Study materials', 'Certificate download', 'Priority support', 'Extended support']
          }
        ]
      }
    });
  } catch (error) {
    console.error('Get payment instructions error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Block/Unblock user (Admin/Manager only)
const blockUser = async (req, res) => {
  try {
    console.log('🔒 Block user request received:', {
      userId: req.params.id,
      isBlocked: req.body.isBlocked,
      blockReason: req.body.blockReason,
      user: req.user
    });

    const { id } = req.params;
    const { isBlocked, blockReason } = req.body;

    const user = await User.findByPk(id);
    if (!user) {
      console.log('❌ User not found:', id);
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    console.log('👤 User found:', {
      id: user.id,
      fullName: user.fullName,
      currentIsBlocked: user.isBlocked
    });

    // Update user block status
    // Convert boolean to database format: true=0 (blocked), false=1 (unblocked)
    const dbValue = isBlocked ? 0 : 1;
    user.isBlocked = dbValue;
    user.blockReason = blockReason || null;
    user.blockedAt = isBlocked ? new Date() : null;
    
    console.log('💾 Saving user with new block status:', {
      frontendBoolean: isBlocked,
      databaseValue: dbValue,
      isBlocked: user.isBlocked,
      blockReason: user.blockReason,
      blockedAt: user.blockedAt
    });
    
    await user.save();

    console.log('✅ User block status updated successfully');

    res.json({
      success: true,
      message: `User ${isBlocked ? 'blocked' : 'unblocked'} successfully`,
      data: {
        userId: user.id,
        fullName: user.fullName,
        isBlocked: user.isBlocked,
        blockReason: user.blockReason,
        blockedAt: user.blockedAt
      }
    });
  } catch (error) {
    console.error('❌ Block user error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Delete user (Admin only) - Cascade delete all related data
const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    console.log('🗑️ Deleting user and all related data:', id);

    const user = await User.findByPk(id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    console.log('👤 User found:', {
      id: user.id,
      fullName: user.fullName,
      phoneNumber: user.phoneNumber
    });

    // Delete all related data first (cascade deletion)
    console.log('🗑️ Deleting related data...');
    
    const deletionResults = await Promise.all([
      // Delete all access codes
      AccessCode.destroy({ where: { userId: id } }),
      // Delete all exam results
      ExamResult.destroy({ where: { userId: id } }),
      // Delete all payment requests
      PaymentRequest.destroy({ where: { userId: id } })
    ]);

    console.log('✅ Related data deleted:', {
      accessCodes: deletionResults[0],
      examResults: deletionResults[1],
      paymentRequests: deletionResults[2]
    });

    // Delete the user account
    await user.destroy();

    console.log('✅ User account deleted successfully');

    res.json({
      success: true,
      message: 'User and all related data deleted successfully',
      data: {
        deletedUserId: id,
        deletedUserName: user.fullName,
        deletedData: {
          accessCodes: deletionResults[0],
          examResults: deletionResults[1],
          paymentRequests: deletionResults[2]
        }
      }
    });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Delete own account (User can delete their own account) - Cascade delete all related data
const deleteOwnAccount = async (req, res) => {
  try {
    const userId = req.user.userId; // Use userId from JWT token

    console.log('🗑️ User deleting own account and all related data:', userId);

    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    console.log('👤 User found:', {
      id: user.id,
      fullName: user.fullName,
      phoneNumber: user.phoneNumber
    });

    // Delete all related data first (cascade deletion)
    console.log('🗑️ Deleting related data...');
    
    const deletionResults = await Promise.all([
      // Delete all access codes
      AccessCode.destroy({ where: { userId } }),
      // Delete all exam results
      ExamResult.destroy({ where: { userId } }),
      // Delete all payment requests
      PaymentRequest.destroy({ where: { userId } })
    ]);

    console.log('✅ Related data deleted:', {
      accessCodes: deletionResults[0],
      examResults: deletionResults[1],
      paymentRequests: deletionResults[2]
    });

    // Delete the user account
    await user.destroy();

    console.log('✅ User account deleted successfully');

    res.json({
      success: true,
      message: 'Account and all related data deleted successfully',
      data: {
        deletedUserId: userId,
        deletedUserName: user.fullName,
        deletedData: {
          accessCodes: deletionResults[0],
          examResults: deletionResults[1],
          paymentRequests: deletionResults[2]
        }
      }
    });
  } catch (error) {
    console.error('Delete own account error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Mark user as called (Admin/Manager only)
const markUserAsCalled = async (req, res) => {
  try {
    const { userId } = req.params;
    const adminId = req.user.userId;

    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const calledAt = new Date();
    
    // Use INSERT ... ON DUPLICATE KEY UPDATE for MySQL
    await sequelize.query(
      `INSERT INTO user_call_tracking (id, user_id, admin_id, called_at, created_at, updated_at) 
       VALUES (UUID(), :userId, :adminId, :calledAt, NOW(), NOW())
       ON DUPLICATE KEY UPDATE called_at = :calledAt, updated_at = NOW()`,
      {
        replacements: { userId, adminId, calledAt },
        type: sequelize.QueryTypes.INSERT
      }
    );

    res.json({
      success: true,
      message: 'User marked as called',
      data: {
        userId,
        calledAt: calledAt.toISOString()
      }
    });
  } catch (error) {
    console.error('Mark user as called error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get all called users (Admin/Manager only)
const getCalledUsers = async (req, res) => {
  try {
    const adminId = req.user.userId;

    const calledUsers = await sequelize.query(
      `SELECT uct.user_id, uct.called_at
       FROM user_call_tracking uct
       WHERE uct.admin_id = :adminId
       ORDER BY uct.called_at DESC`,
      {
        replacements: { adminId },
        type: sequelize.QueryTypes.SELECT
      }
    );

    // Convert to map format for frontend (userId -> ISO timestamp string)
    const calledUsersMap = {};
    calledUsers.forEach(record => {
      calledUsersMap[record.user_id] = new Date(record.called_at).toISOString();
    });

    res.json({
      success: true,
      message: 'Called users retrieved successfully',
      data: {
        calledUsers: calledUsersMap
      }
    });
  } catch (error) {
    console.error('Get called users error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Sync call tracking (bulk update)
const syncCallTracking = async (req, res) => {
  try {
    const adminId = req.user.userId;
    const { calledUsers } = req.body; // Map of userId -> calledAt timestamp

    if (!calledUsers || typeof calledUsers !== 'object') {
      return res.status(400).json({
        success: false,
        message: 'Invalid calledUsers data'
      });
    }

    // Get existing call tracking for this admin
    const existing = await sequelize.query(
      `SELECT user_id, called_at FROM user_call_tracking WHERE admin_id = :adminId`,
      {
        replacements: { adminId },
        type: sequelize.QueryTypes.SELECT
      }
    );

    const existingMap = {};
    existing.forEach(record => {
      existingMap[record.user_id] = new Date(record.called_at);
    });

    // Merge: keep the latest called_at for each user
    const updates = [];
    const inserts = [];

    Object.keys(calledUsers).forEach(userId => {
      const localCalledAt = new Date(calledUsers[userId]);
      const existingCalledAt = existingMap[userId] ? new Date(existingMap[userId]) : null;

      if (existingCalledAt) {
        // Update if local is newer
        if (localCalledAt > existingCalledAt) {
          updates.push({ userId, calledAt: localCalledAt });
        } else if (existingCalledAt > localCalledAt) {
          // Server has newer data, will return it
        }
      } else {
        // Insert new
        inserts.push({ userId, calledAt: localCalledAt });
      }
    });

    // Execute updates and inserts using INSERT ... ON DUPLICATE KEY UPDATE
    const allOperations = [...updates, ...inserts];
    for (const op of allOperations) {
      await sequelize.query(
        `INSERT INTO user_call_tracking (id, user_id, admin_id, called_at, created_at, updated_at) 
         VALUES (UUID(), :userId, :adminId, :calledAt, NOW(), NOW())
         ON DUPLICATE KEY UPDATE called_at = :calledAt, updated_at = NOW()`,
        {
          replacements: { userId: op.userId, calledAt: op.calledAt, adminId },
          type: sequelize.QueryTypes.INSERT
        }
      );
    }

    // Return merged data (server has the latest)
    const merged = { ...calledUsers };
    existing.forEach(record => {
      const existingDate = new Date(record.called_at);
      const localDate = merged[record.user_id] ? new Date(merged[record.user_id]) : null;
      if (!localDate || existingDate > localDate) {
        merged[record.user_id] = record.called_at;
      }
    });

    res.json({
      success: true,
      message: 'Call tracking synced successfully',
      data: {
        calledUsers: merged
      }
    });
  } catch (error) {
    console.error('Sync call tracking error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

module.exports = {
  getAllUsers,
  getUserDetails,
  createAccessCodeForUser,
  getUserAccessCodes,
  toggleUserStatus,
  getUserStatistics,
  getUserDashboard,
  getUserIndividualStatistics,
  getFreeExams,
  submitFreeExamResult,
  getMyRemainingDays,
  getPaymentInstructions,
  blockUser,
  deleteUser,
  deleteOwnAccount,
  markUserAsCalled,
  getCalledUsers,
  syncCallTracking
};
