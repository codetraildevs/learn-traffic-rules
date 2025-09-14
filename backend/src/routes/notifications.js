const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const authMiddleware = require('../middleware/authMiddleware');
const { body, param, query } = require('express-validator');

/**
 * @swagger
 * components:
 *   schemas:
 *     Notification:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *         type:
 *           type: string
 *           enum: [PAYMENT_APPROVED, PAYMENT_REJECTED, EXAM_PASSED, EXAM_FAILED, NEW_EXAM, STUDY_REMINDER, SYSTEM]
 *         title:
 *           type: string
 *         message:
 *           type: string
 *         data:
 *           type: object
 *         isRead:
 *           type: boolean
 *         createdAt:
 *           type: string
 *           format: date-time
 *     NotificationPreferences:
 *       type: object
 *       properties:
 *         emailNotifications:
 *           type: boolean
 *         pushNotifications:
 *           type: boolean
 *         smsNotifications:
 *           type: boolean
 *         examReminders:
 *           type: boolean
 *         paymentUpdates:
 *           type: boolean
 *         systemAnnouncements:
 *           type: boolean
 *         studyReminders:
 *           type: boolean
 *         achievementNotifications:
 *           type: boolean
 */

/**
 * @swagger
 * /api/notifications:
 *   get:
 *     summary: Get user notifications
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Number of notifications per page
 *       - in: query
 *         name: unreadOnly
 *         schema:
 *           type: boolean
 *           default: false
 *         description: Show only unread notifications
 *     responses:
 *       200:
 *         description: Notifications retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     notifications:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Notification'
 *                     pagination:
 *                       type: object
 *                       properties:
 *                         page:
 *                           type: integer
 *                         limit:
 *                           type: integer
 *                         total:
 *                           type: integer
 */
router.get('/',
  authMiddleware.authenticate,
  [
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
    query('unreadOnly').optional().isBoolean().withMessage('unreadOnly must be a boolean')
  ],
  notificationController.getUserNotifications
);

/**
 * @swagger
 * /api/notifications/{notificationId}/read:
 *   put:
 *     summary: Mark notification as read
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: notificationId
 *         required: true
 *         schema:
 *           type: string
 *         description: Notification ID
 *     responses:
 *       200:
 *         description: Notification marked as read
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 */
router.put('/:notificationId/read',
  authMiddleware.authenticate,
  [
    param('notificationId').notEmpty().withMessage('Notification ID is required')
  ],
  notificationController.markAsRead
);

/**
 * @swagger
 * /api/notifications/read-all:
 *   put:
 *     summary: Mark all notifications as read
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: All notifications marked as read
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 */
router.put('/read-all',
  authMiddleware.authenticate,
  notificationController.markAllAsRead
);

/**
 * @swagger
 * /api/notifications/send:
 *   post:
 *     summary: Send notification to user (Admin/Manager only)
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - userId
 *               - type
 *               - title
 *               - message
 *             properties:
 *               userId:
 *                 type: string
 *                 description: Target user ID
 *               type:
 *                 type: string
 *                 enum: [PAYMENT_APPROVED, PAYMENT_REJECTED, EXAM_PASSED, EXAM_FAILED, NEW_EXAM, STUDY_REMINDER, SYSTEM]
 *               title:
 *                 type: string
 *               message:
 *                 type: string
 *               data:
 *                 type: object
 *                 description: Additional data for the notification
 *     responses:
 *       200:
 *         description: Notification sent successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 data:
 *                   $ref: '#/components/schemas/Notification'
 *       400:
 *         description: Bad request - missing required fields
 *       404:
 *         description: User not found
 */
router.post('/send',
  authMiddleware.authenticate,
  [
    body('userId').isUUID().withMessage('Invalid user ID'),
    body('type').isIn(['PAYMENT_APPROVED', 'PAYMENT_REJECTED', 'EXAM_PASSED', 'EXAM_FAILED', 'NEW_EXAM', 'STUDY_REMINDER', 'SYSTEM']).withMessage('Invalid notification type'),
    body('title').notEmpty().withMessage('Title is required'),
    body('message').notEmpty().withMessage('Message is required'),
    body('data').optional().isObject().withMessage('Data must be an object')
  ],
  notificationController.sendNotification
);

/**
 * @swagger
 * /api/notifications/preferences:
 *   get:
 *     summary: Get notification preferences
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Notification preferences retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/NotificationPreferences'
 */
router.get('/preferences',
  authMiddleware.authenticate,
  notificationController.getNotificationPreferences
);

/**
 * @swagger
 * /api/notifications/preferences:
 *   put:
 *     summary: Update notification preferences
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/NotificationPreferences'
 *     responses:
 *       200:
 *         description: Notification preferences updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 data:
 *                   $ref: '#/components/schemas/NotificationPreferences'
 *       400:
 *         description: Bad request - invalid preference keys
 */
router.put('/preferences',
  authMiddleware.authenticate,
  [
    body('emailNotifications').optional().isBoolean().withMessage('emailNotifications must be a boolean'),
    body('pushNotifications').optional().isBoolean().withMessage('pushNotifications must be a boolean'),
    body('smsNotifications').optional().isBoolean().withMessage('smsNotifications must be a boolean'),
    body('examReminders').optional().isBoolean().withMessage('examReminders must be a boolean'),
    body('paymentUpdates').optional().isBoolean().withMessage('paymentUpdates must be a boolean'),
    body('systemAnnouncements').optional().isBoolean().withMessage('systemAnnouncements must be a boolean'),
    body('studyReminders').optional().isBoolean().withMessage('studyReminders must be a boolean'),
    body('achievementNotifications').optional().isBoolean().withMessage('achievementNotifications must be a boolean')
  ],
  notificationController.updateNotificationPreferences
);

module.exports = router;
