const { User, AccessCode, ExamResult, PaymentRequest, Exam } = require('../models');
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
      sortOrder = 'DESC' 
    } = req.query;
    
    const offset = (page - 1) * limit;
    
    // Build where clause
    const whereClause = {};
    if (search) {
      whereClause[require('sequelize').Op.or] = [
        { fullName: { [require('sequelize').Op.iLike]: `%${search}%` } },
        { phoneNumber: { [require('sequelize').Op.iLike]: `%${search}%` } }
      ];
    }
    if (role) {
      whereClause.role = role;
    }

    // Get users with access code count
    const { count, rows: users } = await User.findAndCountAll({
      where: whereClause,
      include: [
        {
          model: AccessCode,
          as: 'accessCodes',
          attributes: ['id', 'isUsed', 'expiresAt', 'paymentTier', 'createdAt'],
          required: false
        }
      ],
      attributes: [
        'id', 'fullName', 'phoneNumber', 'role', 
        'isActive', 'lastLogin', 'createdAt', 'updatedAt',
        'isBlocked', 'blockReason', 'blockedAt'
      ],
      order: [[sortBy, sortOrder.toUpperCase()]],
      limit: parseInt(limit),
      offset: parseInt(offset),
      distinct: true
    });

    // Process users to add access code statistics and remaining days
    const processedUsers = users.map(user => {
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
        }
      };
    });

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
        'isBlocked', 'blockReason', 'blockedAt'
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
    const { paymentAmount } = req.body;
    const generatedByManagerId = req.user.userId;

    console.log('🔍 Creating access code for user:', {
      userId,
      paymentAmount,
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
    if (isNaN(numericPaymentAmount)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payment amount'
      });
    }

    // Create access code with payment
    const accessCode = await AccessCode.createWithPayment(
      userId,
      generatedByManagerId,
      numericPaymentAmount
    );

    // Get user details for response
    const userWithCode = await User.findByPk(userId, {
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

    // Send notification to user about access granted
    try {
      await notificationService.notifyAccessGranted(userId, accessCode);
      console.log(`📧 Notification sent to user ${userId} about access granted`);
    } catch (notificationError) {
      console.error('Failed to send access granted notification:', notificationError);
      // Don't fail the request if notification fails
    }

    res.status(201).json({
      success: true,
      message: 'Access code created successfully',
      data: {
        accessCode,
        user: userWithCode
      }
    });
  } catch (error) {
    console.error('Create access code for user error:', error);
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

    // Get all active exams
    const allExams = await Exam.findAll({
      where: { isActive: true },
      attributes: ['id', 'title', 'description', 'category', 'difficulty', 'duration', 'passingScore', 'examImgUrl', 'createdAt'],
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

    // For free users, first 2 exams (oldest by creation date) are completely free with unlimited attempts
    // Get the first 2 exams (by creation date ASC - oldest first)
    const firstTwoExams = examsWithQuestions.slice(0, 2);
    const remainingExams = examsWithQuestions.slice(2);

    // Debug: Log exam creation dates and which are marked as free
    console.log('📅 Exam Creation Dates (ordered ASC):');
    examsWithQuestions.forEach((exam, index) => {
      console.log(`   ${index + 1}. ${exam.title} - Created: ${exam.createdAt} - Free: ${index < 2}`);
    });

    // Mark which exams are free (first 2 exams in the ordered list)
    const examsWithFreeStatus = examsWithQuestions.map((exam, index) => ({
      ...exam.toJSON(),
      questionCount: exam.dataValues.questionCount,
      isFree: index < 2, // First 2 exams are free
      isFirstTwo: index < 2
    }));

    res.json({
      success: true,
      message: 'All exams retrieved successfully',
      data: {
        exams: examsWithFreeStatus,
        isFreeUser: true,
        freeExamsRemaining: 2, // Always 2 free exams
        freeExamIds: firstTwoExams.map(exam => exam.id),
        paymentInstructions: {
          title: 'Get Full Access',
          description: 'First 2 exams are free with unlimited attempts. For more exams:',
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

    if (freeExamResults >= 2) {
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
        freeExamsRemaining: Math.max(0, 1 - freeExamResults)
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
  deleteOwnAccount
};
