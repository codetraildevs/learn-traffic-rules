const cron = require('node-cron');
const { Op } = require('sequelize');
const Notification = require('../models/Notification');
const StudyReminder = require('../models/StudyReminder');
const NotificationPreferences = require('../models/NotificationPreferences');
const User = require('../models/User');

class NotificationService {
  constructor() {
    this.io = null;
    this.scheduledJobs = new Map();
    this.initializeCronJobs();
  }

  setSocketIO(io) {
    this.io = io;
  }

  /**
   * Initialize cron jobs for study reminders
   */
  initializeCronJobs() {
    // Check for study reminders every minute
    cron.schedule('* * * * *', async () => {
      await this.checkStudyReminders();
    });

    // Check for scheduled notifications every minute
    cron.schedule('* * * * *', async () => {
      await this.processScheduledNotifications();
    });

    // Weekly reports every Sunday at 9 AM
    cron.schedule('0 9 * * 0', async () => {
      await this.sendWeeklyReports();
    });

    console.log('Notification cron jobs initialized');
  }

  /**
   * Create a new notification
   */
  async createNotification(notificationData) {
    try {
      const notification = await Notification.create({
        ...notificationData,
        scheduledFor: notificationData.scheduledFor || new Date(),
      });

      // Send real-time notification if user is online
      if (this.io) {
        this.io.to(`user_${notification.userId}`).emit('notification', {
          id: notification.id,
          type: notification.type,
          title: notification.title,
          message: notification.message,
          data: notification.data,
          createdAt: notification.createdAt,
        });
      }

      return notification;
    } catch (error) {
      console.error('Error creating notification:', error);
      throw error;
    }
  }

  /**
   * Get user notifications with pagination
   */
  async getUserNotifications(userId, options = {}) {
    const {
      page = 1,
      limit = 20,
      unreadOnly = false,
      type = null,
      category = null,
    } = options;

    const offset = (page - 1) * limit;
    const whereClause = { userId };

    if (unreadOnly) {
      whereClause.isRead = false;
    }

    if (type) {
      whereClause.type = type;
    }

    if (category) {
      whereClause.category = category;
    }

    const { count, rows } = await Notification.findAndCountAll({
      where: whereClause,
      order: [['createdAt', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset),
    });

    return {
      notifications: rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count,
        totalPages: Math.ceil(count / limit),
      },
    };
  }

  /**
   * Mark notification as read
   */
  async markAsRead(notificationId, userId) {
    const notification = await Notification.findOne({
      where: { id: notificationId, userId },
    });

    if (!notification) {
      throw new Error('Notification not found');
    }

    notification.isRead = true;
    await notification.save();

    return notification;
  }

  /**
   * Mark all notifications as read for a user
   */
  async markAllAsRead(userId) {
    await Notification.update(
      { isRead: true },
      { where: { userId, isRead: false } }
    );
  }

  /**
   * Get user notification preferences
   */
  async getNotificationPreferences(userId) {
    let preferences = await NotificationPreferences.findOne({
      where: { userId },
    });

    if (!preferences) {
      // Create default preferences
      preferences = await NotificationPreferences.create({
        userId,
      });
    }

    return preferences;
  }

  /**
   * Update user notification preferences
   */
  async updateNotificationPreferences(userId, preferences) {
    const [updatedPreferences] = await NotificationPreferences.upsert({
      userId,
      ...preferences,
    });

    return updatedPreferences;
  }

  /**
   * Create study reminder for user
   */
  async createStudyReminder(userId, reminderData) {
    const { reminderTime, daysOfWeek, studyGoalMinutes, timezone = 'UTC' } = reminderData;

    // Calculate next scheduled time
    const nextScheduledAt = this.calculateNextReminderTime(reminderTime, daysOfWeek, timezone);

    const reminder = await StudyReminder.create({
      userId,
      reminderTime,
      daysOfWeek,
      studyGoalMinutes,
      timezone,
      nextScheduledAt,
    });

    // Schedule the reminder
    this.scheduleStudyReminder(reminder);

    return reminder;
  }

  /**
   * Update study reminder
   */
  async updateStudyReminder(reminderId, userId, updateData) {
    const reminder = await StudyReminder.findOne({
      where: { id: reminderId, userId },
    });

    if (!reminder) {
      throw new Error('Study reminder not found');
    }

    // Cancel existing job
    if (this.scheduledJobs.has(reminderId)) {
      this.scheduledJobs.get(reminderId).destroy();
      this.scheduledJobs.delete(reminderId);
    }

    // Update reminder
    Object.assign(reminder, updateData);
    
    if (updateData.reminderTime || updateData.daysOfWeek || updateData.timezone) {
      reminder.nextScheduledAt = this.calculateNextReminderTime(
        reminder.reminderTime,
        reminder.daysOfWeek,
        reminder.timezone
      );
    }

    await reminder.save();

    // Reschedule if enabled
    if (reminder.isEnabled && reminder.isActive) {
      this.scheduleStudyReminder(reminder);
    }

    return reminder;
  }

  /**
   * Check for study reminders that need to be sent
   */
  async checkStudyReminders() {
    const now = new Date();
    const currentTime = now.toTimeString().slice(0, 5); // HH:MM format
    const currentDay = this.getCurrentDayName(now);

    console.log(`[CRON] Checking study reminders at ${currentTime} on ${currentDay}`);

    const reminders = await StudyReminder.findAll({
      where: {
        isEnabled: true,
        isActive: true,
      },
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'fullName', 'phoneNumber'],
      }],
    });

    console.log(`[CRON] Found ${reminders.length} active reminders`);

    for (const reminder of reminders) {
      const reminderTime = reminder.reminderTime.slice(0, 5); // HH:MM format
      const daysOfWeek = Array.isArray(reminder.daysOfWeek) ? reminder.daysOfWeek : JSON.parse(reminder.daysOfWeek || '[]');
      
      console.log(`[CRON] Checking reminder: ${reminderTime} on ${daysOfWeek.join(', ')}`);
      console.log(`[CRON] Time match: ${reminderTime} === ${currentTime} ? ${reminderTime === currentTime}`);
      console.log(`[CRON] Day match: ${currentDay} in [${daysOfWeek.join(', ')}] ? ${daysOfWeek.includes(currentDay)}`);
      
      // Check if current time matches reminder time and current day is in the days list
      if (reminderTime === currentTime && daysOfWeek.includes(currentDay)) {
        console.log(`[CRON] ✅ MATCH! Sending study reminder to user ${reminder.userId}`);
        
        try {
          await this.sendStudyReminder(reminder);
          
          // Update next scheduled time
          reminder.nextScheduledAt = this.calculateNextReminderTime(
            reminder.reminderTime,
            daysOfWeek,
            reminder.timezone
          );
          reminder.lastSentAt = now;
          await reminder.save();
          
          console.log(`[CRON] ✅ Study reminder sent successfully to user ${reminder.userId}`);
        } catch (error) {
          console.error(`[CRON] ❌ Error sending study reminder to user ${reminder.userId}:`, error);
        }
      } else {
        console.log(`[CRON] ❌ No match for reminder ${reminder.id}`);
      }
    }
  }

  /**
   * Send study reminder notification
   */
  async sendStudyReminder(reminder) {
    try {
      const preferences = await this.getNotificationPreferences(reminder.userId);
      
      if (!preferences.studyReminders) {
        console.log(`[REMINDER] Study reminders disabled for user ${reminder.userId}`);
        return;
      }

      console.log(`[REMINDER] Creating study reminder notification for user ${reminder.userId}`);

      const notification = await this.createNotification({
        userId: reminder.userId,
        type: 'STUDY_REMINDER',
        title: 'Time to Study! 📖',
        message: `Haven't studied today? Take a practice exam to keep your skills sharp! Your daily goal is ${reminder.studyGoalMinutes} minutes.`,
        category: 'STUDY',
        priority: 'MEDIUM',
        data: {
          studyGoalMinutes: reminder.studyGoalMinutes,
          reminderId: reminder.id,
        },
      });

      console.log(`[REMINDER] Study reminder notification created with ID: ${notification.id}`);
      return notification;
    } catch (error) {
      console.error(`[REMINDER] Error creating study reminder notification:`, error);
      throw error;
    }
  }

  /**
   * Process scheduled notifications
   */
  async processScheduledNotifications() {
    const now = new Date();
    
    const notifications = await Notification.findAll({
      where: {
        scheduledFor: {
          [Op.lte]: now,
        },
        isPushSent: false,
      },
    });

    for (const notification of notifications) {
      await this.sendPushNotification(notification);
    }
  }

  /**
   * Send weekly reports
   */
  async sendWeeklyReports() {
    const users = await User.findAll({
      where: { isActive: true },
    });

    for (const user of users) {
      const preferences = await this.getNotificationPreferences(user.id);
      
      if (!preferences.weeklyReports) {
        continue;
      }

      // Get user's exam results from the past week
      const oneWeekAgo = new Date();
      oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

      const examResults = await ExamResult.findAll({
        where: {
          userId: user.id,
          completedAt: {
            [Op.gte]: oneWeekAgo,
          },
        },
        include: [{
          model: Exam,
          as: 'Exam',
        }],
      });

      if (examResults.length > 0) {
        const totalExams = examResults.length;
        const passedExams = examResults.filter(result => result.passed).length;
        const averageScore = examResults.reduce((sum, result) => sum + result.score, 0) / totalExams;

        await this.createNotification({
          userId: user.id,
          type: 'WEEKLY_REPORT',
          title: 'Weekly Study Report 📊',
          message: `This week you took ${totalExams} exams, passed ${passedExams}, with an average score of ${averageScore.toFixed(1)}%. Keep up the great work!`,
          category: 'GENERAL',
          priority: 'LOW',
          data: {
            totalExams,
            passedExams,
            averageScore: parseFloat(averageScore.toFixed(1)),
            weekStart: oneWeekAgo,
            weekEnd: new Date(),
          },
        });
      }
    }
  }

  /**
   * Send push notification
   */
  async sendPushNotification(notification) {
    try {
      // In a real implementation, you would integrate with FCM, APNs, etc.
      console.log(`Push notification sent: ${notification.title}`);
      
      notification.isPushSent = true;
      await notification.save();
    } catch (error) {
      console.error('Error sending push notification:', error);
    }
  }

  /**
   * Calculate next reminder time
   */
  calculateNextReminderTime(reminderTime, daysOfWeek, timezone) {
    const now = new Date();
    const [hours, minutes] = reminderTime.split(':').map(Number);
    
    // Find next occurrence
    for (let i = 0; i < 7; i++) {
      const checkDate = new Date(now);
      checkDate.setDate(checkDate.getDate() + i);
      const dayName = this.getCurrentDayName(checkDate);
      
      if (daysOfWeek.includes(dayName)) {
        checkDate.setHours(hours, minutes, 0, 0);
        
        if (checkDate > now) {
          return checkDate;
        }
      }
    }
    
    // If no valid time found in next 7 days, return next week
    const nextWeek = new Date(now);
    nextWeek.setDate(nextWeek.getDate() + 7);
    nextWeek.setHours(hours, minutes, 0, 0);
    return nextWeek;
  }

  /**
   * Get current day name
   */
  getCurrentDayName(date) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[date.getDay()];
  }

  /**
   * Schedule study reminder
   */
  scheduleStudyReminder(reminder) {
    if (!reminder.isEnabled || !reminder.isActive) {
      return;
    }

    const cronExpression = this.getCronExpression(reminder.reminderTime, reminder.daysOfWeek);
    
    const job = cron.schedule(cronExpression, async () => {
      await this.sendStudyReminder(reminder);
    }, {
      scheduled: false,
    });

    this.scheduledJobs.set(reminder.id, job);
    job.start();
  }

  /**
   * Get cron expression for study reminder
   */
  getCronExpression(reminderTime, daysOfWeek) {
    const [hours, minutes] = reminderTime.split(':').map(Number);
    const dayNumbers = daysOfWeek.map(day => {
      const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      return days.indexOf(day);
    });

    return `${minutes} ${hours} * * ${dayNumbers.join(',')}`;
  }

  /**
   * Notify user when admin grants access
   */
  async notifyAccessGranted(userId, accessCode) {
    await this.createNotification({
      userId,
      type: 'ACCESS_GRANTED',
      title: 'Access Granted! 🎉',
      message: `You have been granted access to all exams! Your access code is ${accessCode.code} and expires on ${new Date(accessCode.expiresAt).toLocaleDateString()}.`,
      category: 'ACCESS',
      priority: 'HIGH',
      data: {
        accessCodeId: accessCode.id,
        expiresAt: accessCode.expiresAt,
      },
    });
  }

  /**
   * Notify user when admin revokes access
   */
  async notifyAccessRevoked(userId, reason = 'Access has been revoked by administrator') {
    await this.createNotification({
      userId,
      type: 'ACCESS_REVOKED',
      title: 'Access Revoked',
      message: reason,
      category: 'ACCESS',
      priority: 'HIGH',
      data: {
        reason,
      },
    });
  }

  /**
   * Notify user about payment status
   */
  async notifyPaymentStatus(userId, status, paymentRequestId, reason = null) {
    const type = status === 'APPROVED' ? 'PAYMENT_APPROVED' : 'PAYMENT_REJECTED';
    const title = status === 'APPROVED' ? 'Payment Approved! 🎉' : 'Payment Rejected';
    const message = status === 'APPROVED' 
      ? 'Your payment request has been approved. You now have access to all exams!'
      : `Your payment request was rejected. ${reason ? `Reason: ${reason}` : 'Please contact support for more information.'}`;

    await this.createNotification({
      userId,
      type,
      title,
      message,
      category: 'PAYMENT',
      priority: 'HIGH',
      data: {
        paymentRequestId,
        status,
        reason,
      },
    });
  }

  /**
   * Notify user about exam results
   */
  async notifyExamResult(userId, examResult) {
    const type = examResult.passed ? 'EXAM_PASSED' : 'EXAM_FAILED';
    const title = examResult.passed ? 'Congratulations! 🏆' : 'Keep Studying! 📚';
    const message = examResult.passed
      ? `You passed the exam with a score of ${examResult.score}%! Great job!`
      : `You didn't pass this time with a score of ${examResult.score}%. Keep practicing to improve!`;

    await this.createNotification({
      userId,
      type,
      title,
      message,
      category: 'EXAM',
      priority: 'MEDIUM',
      data: {
        examId: examResult.examId,
        score: examResult.score,
        passed: examResult.passed,
        examResultId: examResult.id,
      },
    });
  }
}

module.exports = new NotificationService();
