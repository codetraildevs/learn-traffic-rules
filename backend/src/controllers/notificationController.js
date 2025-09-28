const User = require('../models/User');
const PaymentRequest = require('../models/PaymentRequest');
const AccessCode = require('../models/AccessCode');
const Exam = require('../models/Exam');
const ExamResult = require('../models/ExamResult');
const Notification = require('../models/Notification');
const StudyReminder = require('../models/StudyReminder');
const NotificationPreferences = require('../models/NotificationPreferences');
const notificationService = require('../services/notificationService');

class NotificationController {
  /**
   * Get user notifications
   */
  async getUserNotifications(req, res) {
    try {
      const userId = req.user.userId;
      const { page = 1, limit = 20, unreadOnly = false, type = null, category = null } = req.query;

      const result = await notificationService.getUserNotifications(userId, {
        page: parseInt(page),
        limit: parseInt(limit),
        unreadOnly: unreadOnly === 'true',
        type,
        category,
      });

      res.json({
        success: true,
        data: result
      });

    } catch (error) {
      console.error('Get notifications error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Mark notification as read
   */
  async markAsRead(req, res) {
    try {
      const { notificationId } = req.params;
      const userId = req.user.userId;

      const notification = await notificationService.markAsRead(notificationId, userId);

      res.json({
        success: true,
        message: 'Notification marked as read',
        data: notification
      });

    } catch (error) {
      console.error('Mark notification as read error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Mark all notifications as read
   */
  async markAllAsRead(req, res) {
    try {
      const userId = req.user.userId;

      await notificationService.markAllAsRead(userId);

      res.json({
        success: true,
        message: 'All notifications marked as read'
      });

    } catch (error) {
      console.error('Mark all notifications as read error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Send notification to user
   */
  async sendNotification(req, res) {
    try {
      const { userId, type, title, message, data, category, priority } = req.body;
      const senderId = req.user.userId;

      // Validate required fields
      if (!userId || !type || !title || !message) {
        return res.status(400).json({
          success: false,
          message: 'Missing required fields: userId, type, title, message'
        });
      }

      // Check if user exists
      const user = await User.findByPk(userId);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      // Create notification using notification service
      const notification = await notificationService.createNotification({
        userId,
        type,
        title,
        message,
        category: category || 'GENERAL',
        priority: priority || 'MEDIUM',
        data: data || {},
      });

      res.json({
        success: true,
        message: 'Notification sent successfully',
        data: notification
      });

    } catch (error) {
      console.error('Send notification error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get notification preferences
   */
  async getNotificationPreferences(req, res) {
    try {
      const userId = req.user.userId;

      const preferences = await notificationService.getNotificationPreferences(userId);

      res.json({
        success: true,
        data: preferences
      });

    } catch (error) {
      console.error('Get notification preferences error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Update notification preferences
   */
  async updateNotificationPreferences(req, res) {
    try {
      const userId = req.user.userId;
      const preferences = req.body;

      // Validate preferences
      const validKeys = [
        'pushNotifications',
        'smsNotifications',
        'examReminders',
        'paymentUpdates',
        'systemAnnouncements',
        'studyReminders',
        'achievementNotifications',
        'weeklyReports',
        'quietHoursEnabled',
        'quietHoursStart',
        'quietHoursEnd',
        'vibrationEnabled',
        'soundEnabled'
      ];

      const invalidKeys = Object.keys(preferences).filter(key => !validKeys.includes(key));
      if (invalidKeys.length > 0) {
        return res.status(400).json({
          success: false,
          message: `Invalid preference keys: ${invalidKeys.join(', ')}`
        });
      }

      const updatedPreferences = await notificationService.updateNotificationPreferences(userId, preferences);

      res.json({
        success: true,
        message: 'Notification preferences updated successfully',
        data: updatedPreferences
      });

    } catch (error) {
      console.error('Update notification preferences error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Create study reminder
   */
  async createStudyReminder(req, res) {
    try {
      const userId = req.user.userId;
      const { reminderTime, daysOfWeek, studyGoalMinutes, timezone } = req.body;

      // Validate required fields
      if (!reminderTime || !daysOfWeek || !Array.isArray(daysOfWeek)) {
        return res.status(400).json({
          success: false,
          message: 'reminderTime and daysOfWeek are required'
        });
      }

      // Check if user already has a study reminder
      const existingReminder = await StudyReminder.findOne({
        where: { userId, isActive: true }
      });

      if (existingReminder) {
        return res.status(400).json({
          success: false,
          message: 'User already has an active study reminder'
        });
      }

      const reminder = await notificationService.createStudyReminder(userId, {
        reminderTime,
        daysOfWeek,
        studyGoalMinutes: studyGoalMinutes || 30,
        timezone: timezone || 'UTC'
      });

      res.json({
        success: true,
        message: 'Study reminder created successfully',
        data: reminder
      });

    } catch (error) {
      console.error('Create study reminder error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get study reminder
   */
  async getStudyReminder(req, res) {
    try {
      const userId = req.user.userId;

      const reminder = await StudyReminder.findOne({
        where: { userId, isActive: true }
      });

      res.json({
        success: true,
        data: reminder
      });

    } catch (error) {
      console.error('Get study reminder error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Update study reminder
   */
  async updateStudyReminder(req, res) {
    try {
      const userId = req.user.userId;
      const { reminderId } = req.params;
      const updateData = req.body;

      const reminder = await notificationService.updateStudyReminder(reminderId, userId, updateData);

      res.json({
        success: true,
        message: 'Study reminder updated successfully',
        data: reminder
      });

    } catch (error) {
      console.error('Update study reminder error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Delete study reminder
   */
  async deleteStudyReminder(req, res) {
    try {
      const userId = req.user.userId;
      const { reminderId } = req.params;

      const reminder = await StudyReminder.findOne({
        where: { id: reminderId, userId }
      });

      if (!reminder) {
        return res.status(404).json({
          success: false,
          message: 'Study reminder not found'
        });
      }

      // Cancel scheduled job
      if (notificationService.scheduledJobs.has(reminderId)) {
        notificationService.scheduledJobs.get(reminderId).destroy();
        notificationService.scheduledJobs.delete(reminderId);
      }

      reminder.isActive = false;
      await reminder.save();

      res.json({
        success: true,
        message: 'Study reminder deleted successfully'
      });

    } catch (error) {
      console.error('Delete study reminder error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Helper methods
  async generateUserNotifications(userId, options = {}) {
    const { page, limit, unreadOnly } = options;
    const offset = (page - 1) * limit;

    // Get user's recent activity to generate relevant notifications
    const user = await User.findByPk(userId);
    if (!user) return [];

    const notifications = [];

    // Payment-related notifications
    const recentPaymentRequests = await PaymentRequest.findAll({
      where: { userId },
      order: [['createdAt', 'DESC']],
      limit: 5
    });

    recentPaymentRequests.forEach(request => {
      if (request.status === 'APPROVED') {
        notifications.push({
          id: `payment_approved_${request.id}`,
          type: 'PAYMENT_APPROVED',
          title: 'Payment Approved! 🎉',
          message: 'Your payment request has been approved. You now have access to all exams!',
          data: { paymentRequestId: request.id },
          isRead: false,
          createdAt: request.updatedAt
        });
      } else if (request.status === 'REJECTED') {
        notifications.push({
          id: `payment_rejected_${request.id}`,
          type: 'PAYMENT_REJECTED',
          title: 'Payment Rejected',
          message: 'Your payment request was rejected. Please contact support for more information.',
          data: { paymentRequestId: request.id },
          isRead: false,
          createdAt: request.updatedAt
        });
      }
    });

    // Exam-related notifications
    const recentResults = await ExamResult.findAll({
      where: { userId },
      include: [{ model: Exam, as: 'Exam' }],
      order: [['completedAt', 'DESC']],
      limit: 5
    });

    recentResults.forEach(result => {
      if (result.passed) {
        notifications.push({
          id: `exam_passed_${result.id}`,
          type: 'EXAM_PASSED',
          title: 'Congratulations! 🏆',
          message: `You passed the ${result.Exam.title} exam with a score of ${result.score}%!`,
          data: { examId: result.examId, score: result.score },
          isRead: false,
          createdAt: result.completedAt
        });
      } else {
        notifications.push({
          id: `exam_failed_${result.id}`,
          type: 'EXAM_FAILED',
          title: 'Keep Studying! 📚',
          message: `You didn't pass the ${result.Exam.title} exam. Keep practicing to improve your score!`,
          data: { examId: result.examId, score: result.score },
          isRead: false,
          createdAt: result.completedAt
        });
      }
    });

    // System notifications
    notifications.push({
      id: 'welcome_notification',
      type: 'SYSTEM',
      title: 'Welcome to Traffic Rules App! 🚦',
      message: 'Start your journey to becoming a better driver. Take your first exam today!',
      data: {},
      isRead: false,
      createdAt: user.createdAt
    });

    // Sort by creation date (newest first)
    notifications.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    // Apply pagination
    const startIndex = offset;
    const endIndex = startIndex + limit;
    const paginatedNotifications = notifications.slice(startIndex, endIndex);

    return paginatedNotifications;
  }

  async sendPushNotification(userId, notification) {
    // In a real implementation, you'd integrate with FCM, APNs, or similar
    console.log(`Push notification sent to user ${userId}:`, notification.title);
  }

  // System notification methods
  async notifyPaymentApproved(userId, paymentRequestId) {
    const notification = {
      id: `payment_approved_${paymentRequestId}`,
      type: 'PAYMENT_APPROVED',
      title: 'Payment Approved! 🎉',
      message: 'Your payment request has been approved. You now have access to all exams!',
      data: { paymentRequestId },
      isRead: false,
      createdAt: new Date()
    };

    console.log(`Payment approved notification for user ${userId}:`, notification);
    // In real implementation, save to database and send push notification
  }

  async notifyPaymentRejected(userId, paymentRequestId, reason) {
    const notification = {
      id: `payment_rejected_${paymentRequestId}`,
      type: 'PAYMENT_REJECTED',
      title: 'Payment Rejected',
      message: `Your payment request was rejected. Reason: ${reason}`,
      data: { paymentRequestId, reason },
      isRead: false,
      createdAt: new Date()
    };

    console.log(`Payment rejected notification for user ${userId}:`, notification);
    // In real implementation, save to database and send push notification
  }

  async notifyNewExamAvailable(userId, examId) {
    const exam = await Exam.findByPk(examId);
    if (!exam) return;

    const notification = {
      id: `new_exam_${examId}`,
      type: 'NEW_EXAM',
      title: 'New Exam Available! 📚',
      message: `A new exam "${exam.title}" is now available. Take it to test your knowledge!`,
      data: { examId },
      isRead: false,
      createdAt: new Date()
    };

    console.log(`New exam notification for user ${userId}:`, notification);
    // In real implementation, save to database and send push notification
  }

  async notifyStudyReminder(userId) {
    const notification = {
      id: `study_reminder_${Date.now()}`,
      type: 'STUDY_REMINDER',
      title: 'Time to Study! 📖',
      message: 'Haven\'t studied today? Take a practice exam to keep your skills sharp!',
      data: {},
      isRead: false,
      createdAt: new Date()
    };

    console.log(`Study reminder for user ${userId}:`, notification);
    // In real implementation, save to database and send push notification
  }
}

module.exports = new NotificationController();
