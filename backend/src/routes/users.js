const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/authMiddleware');
const { body } = require('express-validator');

/**
 * @swagger
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       required:
 *         - fullName
 *         - phoneNumber
 *         - deviceId
 *         - role
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           description: Unique user identifier
 *         fullName:
 *           type: string
 *           description: User's full name
 *         phoneNumber:
 *           type: string
 *           description: User's phone number
 *         deviceId:
 *           type: string
 *           description: Unique device identifier
 *         role:
 *           type: string
 *           enum: [USER, MANAGER, ADMIN]
 *           description: User role
 *         isActive:
 *           type: boolean
 *           description: Whether user account is active
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 */

/**
 * @swagger
 * /api/users:
 *   get:
 *     summary: Get all users (Admin/Manager only)
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of users
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/User'
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin/Manager access required
 */
router.get('/', 
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  userController.getAllUsers
);

/**
 * @swagger
 * /api/users/{id}:
 *   get:
 *     summary: Get user by ID
 *     tags: [Users]
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
 *         description: User details
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/User'
 *       404:
 *         description: User not found
 */
router.get('/:id', 
  authMiddleware.authenticate,
  userController.getUserById
);

/**
 * @swagger
 * /api/users/{id}:
 *   put:
 *     summary: Update user (Admin/Manager only)
 *     tags: [Users]
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
 *             properties:
 *               fullName:
 *                 type: string
 *               phoneNumber:
 *                 type: string
 *               isActive:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: User updated successfully
 *       404:
 *         description: User not found
 */
router.put('/:id', 
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  [
    body('fullName').optional().notEmpty().withMessage('Full name cannot be empty'),
    body('phoneNumber').optional().notEmpty().withMessage('Phone number cannot be empty'),
    body('isActive').optional().isBoolean().withMessage('isActive must be a boolean')
  ],
  userController.updateUser
);

/**
 * @swagger
 * /api/users/{id}/activate:
 *   patch:
 *     summary: Activate user account (Admin/Manager only)
 *     tags: [Users]
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
 *         description: User activated successfully
 *       404:
 *         description: User not found
 */
router.patch('/:id/activate', 
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  userController.activateUser
);

/**
 * @swagger
 * /api/users/{id}/deactivate:
 *   patch:
 *     summary: Deactivate user account (Admin/Manager only)
 *     tags: [Users]
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
 *         description: User deactivated successfully
 *       404:
 *         description: User not found
 */
router.patch('/:id/deactivate', 
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  userController.deactivateUser
);

/**
 * @swagger
 * /api/users/dashboard:
 *   get:
 *     summary: Get user dashboard data
 *     tags: [Users]
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
 */
router.get('/dashboard', 
  authMiddleware.authenticate,
  userController.getUserDashboard
);

/**
 * @swagger
 * /api/users/me/preferred-language:
 *   patch:
 *     summary: Update current user's preferred language
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               preferredLanguage:
 *                 type: string
 *                 enum: [en, fr, rw]
 *                 description: Preferred language code (en, fr, or rw)
 *     responses:
 *       200:
 *         description: Preferred language updated successfully
 *       400:
 *         description: Invalid language code
 *       401:
 *         description: Unauthorized
 */
router.patch('/me/preferred-language',
  authMiddleware.authenticate,
  [
    body('preferredLanguage')
      .optional()
      .isIn(['en', 'fr', 'rw'])
      .withMessage('Preferred language must be one of: en, fr, rw')
  ],
  userController.updatePreferredLanguage
);

/**
 * @swagger
 * /api/users/{id}/statistics:
 *   get:
 *     summary: Get user statistics (Admin/Manager only)
 *     tags: [Users]
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
 *         description: User statistics retrieved successfully
 *       404:
 *         description: User not found
 *       403:
 *         description: Forbidden - Admin/Manager access required
 */
router.get('/:id/statistics', 
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  userController.getUserStatistics
);

module.exports = router;
