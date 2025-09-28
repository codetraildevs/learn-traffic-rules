const express = require('express');
const { body, param, query } = require('express-validator');
const userManagementController = require('../controllers/userManagementController');
const authMiddleware = require('../middleware/authMiddleware');
const rateLimit = require('express-rate-limit');

const router = express.Router();

// Rate limiting for access code creation
const createCodeLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 10, // limit each IP to 10 requests per windowMs
  message: {
    success: false,
    message: 'Too many access code creation attempts, please try again later'
  }
});

/**
 * @swagger
 * components:
 *   schemas:
 *     UserWithStats:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         fullName:
 *           type: string
 *         phoneNumber:
 *           type: string
 *         role:
 *           type: string
 *           enum: [ADMIN, MANAGER, USER]
 *         isActive:
 *           type: boolean
 *         lastLogin:
 *           type: string
 *           format: date-time
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *         accessCodeStats:
 *           type: object
 *           properties:
 *             total:
 *               type: integer
 *             active:
 *               type: integer
 *             used:
 *               type: integer
 *             expired:
 *               type: integer
 *             latestCode:
 *               $ref: '#/components/schemas/AccessCode'
 */

/**
 * @swagger
 * /api/user-management/users:
 *   get:
 *     summary: Get all users with access code statistics (Admin/Manager only)
 *     tags: [User Management]
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
 *         description: Number of items per page
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Search by name or phone
 *       - in: query
 *         name: role
 *         schema:
 *           type: string
 *           enum: [ADMIN, MANAGER, USER]
 *         description: Filter by role
 *       - in: query
 *         name: sortBy
 *         schema:
 *           type: string
 *           default: createdAt
 *         description: Sort field
 *       - in: query
 *         name: sortOrder
 *         schema:
 *           type: string
 *           enum: [ASC, DESC]
 *           default: DESC
 *         description: Sort order
 *     responses:
 *       200:
 *         description: Users retrieved successfully
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
 *                   type: object
 *                   properties:
 *                     users:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/UserWithStats'
 *                     pagination:
 *                       type: object
 *                       properties:
 *                         total:
 *                           type: integer
 *                         page:
 *                           type: integer
 *                         limit:
 *                           type: integer
 *                         totalPages:
 *                           type: integer
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin/Manager role required
 */
router.get('/users',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  userManagementController.getAllUsers
);

/**
 * @swagger
 * /api/user-management/users/{id}:
 *   get:
 *     summary: Get user details with access codes (Admin/Manager only)
 *     tags: [User Management]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: User ID
 *     responses:
 *       200:
 *         description: User details retrieved successfully
 *       404:
 *         description: User not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin/Manager role required
 */
router.get('/users/:id',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  [
    param('id').isUUID().withMessage('Valid user ID is required')
  ],
  userManagementController.getUserDetails
);

/**
 * @swagger
 * /api/user-management/users/{id}/access-codes:
 *   get:
 *     summary: Get user's access codes (Admin/Manager only)
 *     tags: [User Management]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: User ID
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
 *         description: Number of items per page
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, used, expired]
 *         description: Filter by status
 *     responses:
 *       200:
 *         description: User access codes retrieved successfully
 *       404:
 *         description: User not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin/Manager role required
 */
router.get('/users/:id/access-codes',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  [
    param('id').isUUID().withMessage('Valid user ID is required')
  ],
  userManagementController.getUserAccessCodes
);

/**
 * @swagger
 * /api/user-management/users/{id}/access-codes:
 *   post:
 *     summary: Create access code for specific user (Admin/Manager only)
 *     tags: [User Management]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: User ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - paymentAmount
 *             properties:
 *               paymentAmount:
 *                 type: number
 *                 description: Payment amount in RWF (1500, 3000, 5000)
 *     responses:
 *       201:
 *         description: Access code created successfully
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
 *                   type: object
 *                   properties:
 *                     accessCode:
 *                       $ref: '#/components/schemas/AccessCode'
 *                     user:
 *                       type: object
 *                       properties:
 *                         id:
 *                           type: string
 *                         fullName:
 *                           type: string
 *                         phoneNumber:
 *                           type: string
 *                         role:
 *                           type: string
 *       400:
 *         description: Validation failed or invalid payment amount
 *       404:
 *         description: User not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin/Manager role required
 */
router.post('/users/:id/access-codes',
  createCodeLimiter,
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  [
    param('id').isUUID().withMessage('Valid user ID is required'),
    body('paymentAmount').isNumeric().withMessage('Payment amount must be a number')
      .isIn([1500, 3000, 5000]).withMessage('Invalid payment amount')
  ],
  userManagementController.createAccessCodeForUser
);

/**
 * @swagger
 * /api/user-management/users/{id}/toggle-status:
 *   put:
 *     summary: Toggle user active status (Admin/Manager only)
 *     tags: [User Management]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: User ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - isActive
 *             properties:
 *               isActive:
 *                 type: boolean
 *                 description: Whether to activate or deactivate the user
 *     responses:
 *       200:
 *         description: User status updated successfully
 *       404:
 *         description: User not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin/Manager role required
 */
router.put('/users/:id/toggle-status',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  [
    param('id').isUUID().withMessage('Valid user ID is required'),
    body('isActive').isBoolean().withMessage('isActive must be a boolean')
  ],
  userManagementController.toggleUserStatus
);

/**
 * @swagger
 * /api/user-management/statistics:
 *   get:
 *     summary: Get user and access code statistics (Admin/Manager only)
 *     tags: [User Management]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Statistics retrieved successfully
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
 *                   type: object
 *                   properties:
 *                     users:
 *                       type: object
 *                       properties:
 *                         total:
 *                           type: integer
 *                         active:
 *                           type: integer
 *                         recent:
 *                           type: integer
 *                         byRole:
 *                           type: object
 *                           properties:
 *                             admin:
 *                               type: integer
 *                             manager:
 *                               type: integer
 *                             regular:
 *                               type: integer
 *                     accessCodes:
 *                       type: object
 *                       properties:
 *                         total:
 *                           type: integer
 *                         active:
 *                           type: integer
 *                         used:
 *                           type: integer
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin/Manager role required
 */
router.get('/statistics',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  userManagementController.getUserStatistics
);

/**
 * @swagger
 * /api/user-management/dashboard:
 *   get:
 *     summary: Get user dashboard data
 *     tags: [User Management]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dashboard data retrieved successfully
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
 *                   type: object
 *                   properties:
 *                     statistics:
 *                       type: object
 *                       properties:
 *                         totalExams:
 *                           type: integer
 *                         passedExams:
 *                           type: integer
 *                         failedExams:
 *                           type: integer
 *                         averageScore:
 *                           type: integer
 *                         activeAccessCodes:
 *                           type: integer
 *                     recentResults:
 *                       type: array
 *                       items:
 *                         type: object
 *                     recentPayments:
 *                       type: array
 *                       items:
 *                         type: object
 *                     activeAccessCodes:
 *                       type: array
 *                       items:
 *                         type: object
 *       401:
 *         description: Unauthorized
 */
router.get('/dashboard',
  authMiddleware.authenticate,
  userManagementController.getUserDashboard
);

/**
 * @swagger
 * /api/user-management/users/{id}/statistics:
 *   get:
 *     summary: Get individual user statistics (Admin/Manager only)
 *     tags: [User Management]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: User ID
 *     responses:
 *       200:
 *         description: User statistics retrieved successfully
 *       404:
 *         description: User not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin/Manager role required
 */
router.get('/users/:id/statistics',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  [
    param('id').isUUID().withMessage('Valid user ID is required')
  ],
  userManagementController.getUserIndividualStatistics
);

/**
 * @swagger
 * /api/user-management/free-exams:
 *   get:
 *     summary: Get free exams for users without access codes
 *     tags: [User Management]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Free exams retrieved successfully
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
 *                   type: object
 *                   properties:
 *                     exams:
 *                       type: array
 *                       items:
 *                         type: object
 *                     isFreeUser:
 *                       type: boolean
 *                     freeExamsRemaining:
 *                       type: integer
 *                     paymentInstructions:
 *                       type: object
 *       401:
 *         description: Unauthorized
 */
router.get('/free-exams',
  authMiddleware.authenticate,
  userManagementController.getFreeExams
);

/**
 * @swagger
 * /api/user-management/submit-free-exam:
 *   post:
 *     summary: Submit free exam result
 *     tags: [User Management]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - examId
 *               - answers
 *             properties:
 *               examId:
 *                 type: string
 *                 format: uuid
 *               answers:
 *                 type: object
 *                 description: Object with question IDs as keys and user answers as values
 *               timeSpent:
 *                 type: integer
 *                 description: Time spent in seconds
 *     responses:
 *       200:
 *         description: Free exam submitted successfully
 *       403:
 *         description: User has used all free exams
 *       401:
 *         description: Unauthorized
 */
router.post('/submit-free-exam',
  authMiddleware.authenticate,
  [
    body('examId').isUUID().withMessage('Valid exam ID is required'),
    body('answers').isObject().withMessage('Answers must be an object'),
    body('timeSpent').optional().isInt().withMessage('Time spent must be an integer')
  ],
  userManagementController.submitFreeExamResult
);

/**
 * @swagger
 * /api/user-management/my-remaining-days:
 *   get:
 *     summary: Get current user's remaining access days
 *     tags: [User Management]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Remaining days retrieved successfully
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
 *                   type: object
 *                   properties:
 *                     remainingDays:
 *                       type: integer
 *                       description: Number of days remaining
 *                     hasActiveAccess:
 *                       type: boolean
 *                       description: Whether user has any active access codes
 *                     activeCodesCount:
 *                       type: integer
 *                       description: Number of active access codes
 *       401:
 *         description: Unauthorized
 */
router.get('/my-remaining-days',
  authMiddleware.authenticate,
  userManagementController.getMyRemainingDays
);

/**
 * @swagger
 * /api/user-management/payment-instructions:
 *   get:
 *     summary: Get payment instructions and contact information
 *     tags: [User Management]
 *     responses:
 *       200:
 *         description: Payment instructions retrieved successfully
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
 *                   type: object
 *                   properties:
 *                     title:
 *                       type: string
 *                     description:
 *                       type: string
 *                     steps:
 *                       type: array
 *                       items:
 *                         type: string
 *                     contactInfo:
 *                       type: object
 *                       properties:
 *                         phone:
 *                           type: string
 *                         whatsapp:
 *                           type: string
 *                         workingHours:
 *                           type: string
 *                     paymentMethods:
 *                       type: array
 *                       items:
 *                         type: object
 *                     paymentTiers:
 *                       type: array
 *                       items:
 *                         type: object
 */
router.get('/payment-instructions',
  userManagementController.getPaymentInstructions
);

/**
 * @swagger
 * /api/user-management/{id}/block:
 *   put:
 *     summary: Block/Unblock user (Admin/Manager only)
 *     tags: [User Management]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - isBlocked
 *             properties:
 *               isBlocked:
 *                 type: boolean
 *                 description: Whether to block or unblock the user
 *               blockReason:
 *                 type: string
 *                 description: Reason for blocking (optional)
 *     responses:
 *       200:
 *         description: User blocked/unblocked successfully
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin/Manager role required
 *       404:
 *         description: User not found
 */
router.put('/:id/block',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  userManagementController.blockUser
);

/**
 * @swagger
 * /api/user-management/{id}:
 *   delete:
 *     summary: Delete user (Admin only)
 *     tags: [User Management]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: User ID
 *     responses:
 *       200:
 *         description: User deleted successfully
 *       400:
 *         description: Cannot delete user with existing data
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin role required
 *       404:
 *         description: User not found
 */
router.delete('/:id',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN']),
  userManagementController.deleteUser
);

/**
 * @swagger
 * /api/user-management/delete-account:
 *   delete:
 *     summary: Delete current user's account
 *     tags: [User Management]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Account deleted successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: User not found
 */
router.delete('/delete-account',
  authMiddleware.authenticate,
  userManagementController.deleteOwnAccount
);

module.exports = router;
