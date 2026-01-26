const PaymentRequest = require('../models/PaymentRequest');
const AccessCode = require('../models/AccessCode');
const Exam = require('../models/Exam');
const User = require('../models/User');
const { validationResult } = require('express-validator');
const notificationService = require('../services/notificationService');

class PaymentController {
  /**
   * Request global access with payment (unlocks all exams)
   */
  async requestGlobalAccess(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { amount, paymentMethod, paymentProof } = req.body;
      const userId = req.user.userId;

      // Check if user already has global access
      const existingAccess = await AccessCode.findOne({
        where: {
          userId: userId,
          isUsed: false,
          expiresAt: {
            [require('sequelize').Op.gt]: new Date()
          }
        }
      });

      if (existingAccess) {
        return res.status(409).json({
          success: false,
          message: 'You already have access to all exams'
        });
      }

      // Check if there's already a pending payment request
      const existingRequest = await PaymentRequest.findOne({
        where: {
          userId: userId,
          status: 'PENDING'
        }
      });

      if (existingRequest) {
        return res.status(409).json({
          success: false,
          message: 'You already have a pending payment request'
        });
      }

      // Create payment request
      const paymentRequest = await PaymentRequest.create({
        userId: userId,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentProof: paymentProof,
        status: 'PENDING'
      });

      res.status(201).json({
        success: true,
        message: 'Payment request submitted successfully. Manager will review and approve.',
        data: paymentRequest
      });
    } catch (error) {
      console.error('Payment request error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get user's payment requests
   */
  async getUserPaymentRequests(req, res) {
    try {
      const userId = req.user.userId;

      const paymentRequests = await PaymentRequest.findAll({
        where: { userId: userId },
        order: [['createdAt', 'DESC']]
      });

      res.json({
        success: true,
        message: 'Payment requests retrieved successfully',
        data: paymentRequests
      });
    } catch (error) {
      console.error('Get payment requests error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get all payment requests (Manager/Admin only)
   */
  async getAllPaymentRequests(req, res) {
    try {
      const { status } = req.query;
      const whereClause = status ? { status: status } : {};

      const paymentRequests = await PaymentRequest.findAll({
        where: whereClause,
        include: [{
          model: User,
          attributes: ['id', 'fullName', 'phoneNumber']
        }],
        order: [['createdAt', 'DESC']]
      });

      res.json({
        success: true,
        message: 'Payment requests retrieved successfully',
        data: paymentRequests
      });
    } catch (error) {
      console.error('Get all payment requests error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Approve payment request (Manager/Admin only)
   */
  async approvePaymentRequest(req, res) {
    try {
      const { id } = req.params;
      const managerId = req.user.userId;

      const paymentRequest = await PaymentRequest.findByPk(id);

      if (!paymentRequest) {
        return res.status(404).json({
          success: false,
          message: 'Payment request not found'
        });
      }

      if (paymentRequest.status !== 'PENDING') {
        return res.status(400).json({
          success: false,
          message: 'Payment request is not pending'
        });
      }

      // Update payment request status
      await paymentRequest.update({ 
        status: 'APPROVED',
        managerNotes: 'Payment approved by manager'
      });

      // Generate global access code (unlocks all exams)
      // Use createWithPayment for retry logic and proper handling
      const accessCode = await AccessCode.createWithPayment(
        paymentRequest.userId,
        managerId,
        1500, // Default 1 month payment amount
        30 // 30 days duration
      );

      // Send notification to user about payment approval
      try {
        await notificationService.notifyPaymentStatus(
          paymentRequest.userId, 
          'APPROVED', 
          paymentRequest.id
        );
        console.log(`📧 Payment approval notification sent to user ${paymentRequest.userId}`);
      } catch (notificationError) {
        console.error('Failed to send payment approval notification:', notificationError);
        // Don't fail the request if notification fails
      }

      res.json({
        success: true,
        message: 'Payment request approved and access code generated',
        data: {
          paymentRequest: paymentRequest,
          accessCode: accessCode
        }
      });
    } catch (error) {
      console.error('Approve payment request error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Reject payment request (Manager/Admin only)
   */
  async rejectPaymentRequest(req, res) {
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
      const { rejectionReason } = req.body;
      const managerId = req.user.userId;

      const paymentRequest = await PaymentRequest.findByPk(id);

      if (!paymentRequest) {
        return res.status(404).json({
          success: false,
          message: 'Payment request not found'
        });
      }

      if (paymentRequest.status !== 'PENDING') {
        return res.status(400).json({
          success: false,
          message: 'Payment request is not pending'
        });
      }

      // Update payment request status
      await paymentRequest.update({ 
        status: 'REJECTED',
        rejectionReason: rejectionReason,
        managerNotes: `Payment rejected by manager: ${rejectionReason}`
      });

      // Send notification to user about payment rejection
      try {
        await notificationService.notifyPaymentStatus(
          paymentRequest.userId, 
          'REJECTED', 
          paymentRequest.id,
          rejectionReason
        );
        console.log(`📧 Payment rejection notification sent to user ${paymentRequest.userId}`);
      } catch (notificationError) {
        console.error('Failed to send payment rejection notification:', notificationError);
        // Don't fail the request if notification fails
      }

      res.json({
        success: true,
        message: 'Payment request rejected',
        data: paymentRequest
      });
    } catch (error) {
      console.error('Reject payment request error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get user's access codes
   */
  async getUserAccessCodes(req, res) {
    try {
      const userId = req.user.userId;

      const accessCodes = await AccessCode.findAll({
        where: { userId: userId },
        order: [['createdAt', 'DESC']]
      });

      res.json({
        success: true,
        message: 'Access codes retrieved successfully',
        data: accessCodes
      });
    } catch (error) {
      console.error('Get access codes error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
}

module.exports = new PaymentController();
