const User = require('../models/User');
const ExamResult = require('../models/ExamResult');
const PaymentRequest = require('../models/PaymentRequest');
const AccessCode = require('../models/AccessCode');
const { validationResult } = require('express-validator');

class UserController {
  /**
   * Get all users (Admin/Manager only)
   */
  async getAllUsers(req, res) {
    try {
      const { role, isActive } = req.query;
      const whereClause = {};
      
      if (role) whereClause.role = role;
      if (isActive !== undefined) whereClause.isActive = isActive === 'true';

      const users = await User.findAll({
        where: whereClause,
        attributes: ['id', 'fullName', 'phoneNumber', 'deviceId', 'role', 'isActive', 'createdAt', 'lastLogin'],
        order: [['createdAt', 'DESC']]
      });

      res.json({
        success: true,
        message: 'Users retrieved successfully',
        data: users
      });
    } catch (error) {
      console.error('Get users error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get user by ID
   */
  async getUserById(req, res) {
    try {
      const { id } = req.params;
      const requestingUserId = req.user.userId;
      const requestingUserRole = req.user.role;

      // Users can only view their own profile unless they're admin/manager
      if (id !== requestingUserId && !['ADMIN', 'MANAGER'].includes(requestingUserRole)) {
        return res.status(403).json({
          success: false,
          message: 'Access denied'
        });
      }

      const user = await User.findByPk(id, {
        attributes: ['id', 'fullName', 'phoneNumber', 'deviceId', 'role', 'isActive', 'createdAt', 'lastLogin']
      });

      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      res.json({
        success: true,
        message: 'User retrieved successfully',
        data: user
      });
    } catch (error) {
      console.error('Get user error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Update user (Admin/Manager only)
   */
  async updateUser(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { id } = req.params;
      const updateData = req.body;

      const user = await User.findByPk(id);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      // Remove sensitive fields that shouldn't be updated through this endpoint
      delete updateData.password;
      delete updateData.deviceId;
      delete updateData.id;
      delete updateData.createdAt;

      await user.update(updateData);

      res.json({
        success: true,
        message: 'User updated successfully',
        data: user
      });
    } catch (error) {
      console.error('Update user error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Activate user account (Admin/Manager only)
   */
  async activateUser(req, res) {
    try {
      const { id } = req.params;

      const user = await User.findByPk(id);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      await user.update({ isActive: true });

      res.json({
        success: true,
        message: 'User activated successfully',
        data: user
      });
    } catch (error) {
      console.error('Activate user error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Deactivate user account (Admin/Manager only)
   */
  async deactivateUser(req, res) {
    try {
      const { id } = req.params;

      const user = await User.findByPk(id);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      await user.update({ isActive: false });

      res.json({
        success: true,
        message: 'User deactivated successfully',
        data: user
      });
    } catch (error) {
      console.error('Deactivate user error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get user dashboard data
   */
  async getUserDashboard(req, res) {
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
        include: [{
          model: require('../models/Exam'),
          attributes: ['id', 'title', 'price']
        }],
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
        include: [{
          model: require('../models/Exam'),
          attributes: ['id', 'title', 'category']
        }],
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
  }

  /**
   * Get user statistics (Admin/Manager only)
   */
  async getUserStatistics(req, res) {
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
        where: { userId: id },
        include: [{
          model: require('../models/Exam'),
          attributes: ['id', 'title', 'price']
        }]
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
  }
}

module.exports = new UserController();
