const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');
const deviceMiddleware = require('../middleware/deviceMiddleware');

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register a new user with device ID validation
 *     tags: [Authentication]
 *     security:
 *       - deviceAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - password
 *               - fullName
 *               - phoneNumber
 *               - deviceId
 *             properties:
 *               password:
 *                 type: string
 *                 minLength: 8
 *                 example: password123
 *               fullName:
 *                 type: string
 *                 example: John Doe
 *               phoneNumber:
 *                 type: string
 *                 example: +1234567890
 *               deviceId:
 *                 type: string
 *                 example: device123456789
 *               role:
 *                 type: string
 *                 enum: [USER, MANAGER, ADMIN]
 *                 example: USER
 *     responses:
 *       201:
 *         description: User registered successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         user:
 *                           $ref: '#/components/schemas/User'
 *                         token:
 *                           type: string
 *                           description: JWT access token
 *       400:
 *         description: Bad request - validation error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       409:
 *         description: User already exists or device already registered
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post('/register', 
  [
    body('fullName').trim().isLength({ min: 2 }).withMessage('Full name must be at least 2 characters'),
    body('phoneNumber').isMobilePhone().withMessage('Invalid phone number'),
    body('deviceId').isLength({ min: 5 }).withMessage('Device ID must be at least 5 characters'),
    body('role').optional().isIn(['USER', 'MANAGER', 'ADMIN']).withMessage('Invalid role')
  ],
  authController.register.bind(authController)
);

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Login user with device ID validation
 *     tags: [Authentication]
 *     security:
 *       - deviceAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - password
 *               - deviceId
 *             properties:
 *               password:
 *                 type: string
 *                 example: password123
 *               deviceId:
 *                 type: string
 *                 example: device123456789
 *     responses:
 *       200:
 *         description: Login successful
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         user:
 *                           $ref: '#/components/schemas/User'
 *                         token:
 *                           type: string
 *                           description: JWT access token
 *                         refreshToken:
 *                           type: string
 *                           description: JWT refresh token
 *       400:
 *         description: Bad request - validation error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Invalid credentials or device mismatch
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       403:
 *         description: Account locked or device not authorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post('/login',
  [
    body('phoneNumber').isMobilePhone().withMessage('Invalid phone number'),
    body('deviceId').isLength({ min: 5 }).withMessage('Device ID must be at least 5 characters')
  ],
  authController.login.bind(authController)
);

/**
 * @swagger
 * /api/auth/create-admin:
 *   post:
 *     summary: Create default admin user for testing
 *     tags: [Authentication]
 *     responses:
 *       200:
 *         description: Admin user created successfully
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
 *                     admin:
 *                       type: object
 *       400:
 *         description: Admin user already exists
 */
router.post('/create-admin', authController.createDefaultAdmin.bind(authController));

/**
 * @swagger
 * /api/auth/logout:
 *   post:
 *     summary: Logout user and invalidate token
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *       - deviceAuth: []
 *     responses:
 *       200:
 *         description: Logout successful
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post('/logout',
  authMiddleware.authenticateToken,
  deviceMiddleware.validateDeviceId,
  authController.logout.bind(authController)
);

/**
 * @swagger
 * /api/auth/refresh:
 *   post:
 *     summary: Refresh access token using refresh token
 *     tags: [Authentication]
 *     security:
 *       - deviceAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - refreshToken
 *             properties:
 *               refreshToken:
 *                 type: string
 *                 description: Valid refresh token
 *     responses:
 *       200:
 *         description: Token refreshed successfully
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/Success'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         token:
 *                           type: string
 *                           description: New JWT access token
 *                         refreshToken:
 *                           type: string
 *                           description: New JWT refresh token
 *       401:
 *         description: Invalid refresh token
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post('/refresh',
  [
    body('refreshToken').notEmpty().withMessage('Refresh token is required'),
    deviceMiddleware.validateDeviceId
  ],
  authController.refreshToken.bind(authController)
);


/**
 * @swagger
 * /api/auth/device-change-request:
 *   post:
 *     summary: Request device change (requires admin approval)
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *       - deviceAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - newDeviceId
 *               - reason
 *             properties:
 *               newDeviceId:
 *                 type: string
 *                 description: New device identifier
 *               reason:
 *                 type: string
 *                 description: Reason for device change
 *                 example: "Lost my phone"
 *     responses:
 *       200:
 *         description: Device change request submitted
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Success'
 *       400:
 *         description: Bad request - validation error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       401:
 *         description: Unauthorized
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
router.post('/device-change-request',
  authMiddleware.authenticateToken,
  [
    body('newDeviceId').notEmpty().withMessage('New device ID is required'),
    body('reason').trim().isLength({ min: 10 }).withMessage('Reason must be at least 10 characters'),
    deviceMiddleware.validateDeviceId
  ],
  authController.requestDeviceChange.bind(authController)
);

/**
 * @swagger
 * /api/auth/forgot-password:
 *   post:
 *     summary: Request password reset
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phoneNumber
 *             properties:
 *               phoneNumber:
 *                 type: string
 *                 description: User's phone number
 *     responses:
 *       200:
 *         description: Password reset code sent (if account exists)
 *       400:
 *         description: Bad request - validation failed
 */
router.post('/forgot-password',
  [
    body('phoneNumber').notEmpty().withMessage('Phone number is required')
  ],
  authController.forgotPassword.bind(authController)
);

/**
 * @swagger
 * /api/auth/reset-password:
 *   post:
 *     summary: Reset password with code
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phoneNumber
 *               - resetCode
 *               - newPassword
 *             properties:
 *               phoneNumber:
 *                 type: string
 *                 description: User's phone number
 *               resetCode:
 *                 type: string
 *                 description: 6-digit reset code
 *               newPassword:
 *                 type: string
 *                 minLength: 6
 *                 description: New password
 *     responses:
 *       200:
 *         description: Password reset successfully
 *       400:
 *         description: Bad request - invalid code or validation failed
 */
router.post('/reset-password',
  [
    body('phoneNumber').notEmpty().withMessage('Phone number is required'),
    body('resetCode').isLength({ min: 6, max: 6 }).withMessage('Reset code must be 6 digits'),
    body('newPassword').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
  ],
  authController.resetPassword.bind(authController)
);

/**
 * @swagger
 * /api/auth/delete-account:
 *   post:
 *     summary: Delete user account
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phoneNumber
 *             properties:
 *               phoneNumber:
 *                 type: string
 *                 description: Phone number for verification
 *     responses:
 *       200:
 *         description: Account deleted successfully
 *       401:
 *         description: Phone number does not match
 *       404:
 *         description: User not found
 */
router.post('/delete-account',
  authMiddleware.authenticate,
  [
    body('phoneNumber').notEmpty().withMessage('Phone number is required for account deletion')
  ],
  authController.deleteAccount.bind(authController)
);

module.exports = router;
