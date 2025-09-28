const express = require('express');
const { body, param, query } = require('express-validator');
const accessCodeController = require('../controllers/accessCodeController');
const authMiddleware = require('../middleware/authMiddleware');
const rateLimit = require('express-rate-limit');

const router = express.Router();

// Rate limiting for access code validation (security)
const validateCodeLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // limit each IP to 10 requests per windowMs
  message: {
    success: false,
    message: 'Too many validation attempts, please try again later'
  },
  standardHeaders: true,
  legacyHeaders: false
});

// Rate limiting for creating access codes
const createCodeLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 5, // limit each IP to 5 requests per windowMs
  message: {
    success: false,
    message: 'Too many access code creation attempts, please try again later'
  }
});

/**
 * @swagger
 * components:
 *   schemas:
 *     AccessCode:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *         code:
 *           type: string
 *           description: Unique access code
 *         userId:
 *           type: string
 *           format: uuid
 *         generatedByManagerId:
 *           type: string
 *           format: uuid
 *         paymentAmount:
 *           type: number
 *           format: decimal
 *           description: Payment amount in RWF
 *         durationDays:
 *           type: integer
 *           description: Duration in days
 *         paymentTier:
 *           type: string
 *           enum: [1_DAY, 2_DAYS, 1_WEEK, 2_WEEKS, 1_MONTH, BEYOND_MONTH]
 *         expiresAt:
 *           type: string
 *           format: date-time
 *         isUsed:
 *           type: boolean
 *         usedAt:
 *           type: string
 *           format: date-time
 *         attemptCount:
 *           type: integer
 *         isBlocked:
 *           type: boolean
 *         blockedUntil:
 *           type: string
 *           format: date-time
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 */

/**
 * @swagger
 * /api/access-codes:
 *   get:
 *     summary: Get all access codes (Admin/Manager only)
 *     tags: [Access Codes]
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
 *         name: userId
 *         schema:
 *           type: string
 *         description: Filter by user ID
 *       - in: query
 *         name: isUsed
 *         schema:
 *           type: boolean
 *         description: Filter by usage status
 *       - in: query
 *         name: isBlocked
 *         schema:
 *           type: boolean
 *         description: Filter by block status
 *     responses:
 *       200:
 *         description: Access codes retrieved successfully
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
 *                     accessCodes:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/AccessCode'
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
router.get('/',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  accessCodeController.getAllAccessCodes
);

/**
 * @swagger
 * /api/access-codes:
 *   post:
 *     summary: Create access code (Admin/Manager only)
 *     tags: [Access Codes]
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
 *               - paymentAmount
 *             properties:
 *               userId:
 *                 type: string
 *                 format: uuid
 *                 description: ID of the user to create access code for
 *               paymentAmount:
 *                 type: number
 *                 description: Payment amount in RWF (500, 1000, 2000, 3000, 5000, 10000)
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
 *                   $ref: '#/components/schemas/AccessCode'
 *       400:
 *         description: Validation failed or invalid payment amount
 *       404:
 *         description: User not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin/Manager role required
 */
router.post('/',
  createCodeLimiter,
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  [
    body('userId').isUUID().withMessage('Valid user ID is required'),
    body('paymentAmount').isNumeric().withMessage('Payment amount must be a number')
      .isIn([500, 1000, 2000, 3000, 5000, 10000]).withMessage('Invalid payment amount')
  ],
  accessCodeController.createAccessCode
);

/**
 * @swagger
 * /api/access-codes/validate:
 *   post:
 *     summary: Validate and use access code
 *     tags: [Access Codes]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - code
 *             properties:
 *               code:
 *                 type: string
 *                 description: Access code to validate
 *     responses:
 *       200:
 *         description: Access code validated successfully
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
 *                     expiresAt:
 *                       type: string
 *                       format: date-time
 *                     durationDays:
 *                       type: integer
 *                     paymentTier:
 *                       type: string
 *       400:
 *         description: Invalid, expired, or blocked access code
 *       401:
 *         description: Unauthorized
 */
router.post('/validate',
  validateCodeLimiter,
  authMiddleware.authenticate,
  accessCodeController.validateAccessCode
);

/**
 * @swagger
 * /api/access-codes/my-codes:
 *   get:
 *     summary: Get current user's active access codes
 *     tags: [Access Codes]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User access codes retrieved successfully
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
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/AccessCode'
 *       401:
 *         description: Unauthorized
 */
router.get('/my-codes',
  authMiddleware.authenticate,
  accessCodeController.getUserAccessCodes
);

/**
 * @swagger
 * /api/access-codes/payment-tiers:
 *   get:
 *     summary: Get available payment tiers
 *     tags: [Access Codes]
 *     responses:
 *       200:
 *         description: Payment tiers retrieved successfully
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
 *                   additionalProperties:
 *                     type: object
 *                     properties:
 *                       amount:
 *                         type: number
 *                       days:
 *                         type: integer
 */
router.get('/payment-tiers',
  accessCodeController.getPaymentTiers
);

/**
 * @swagger
 * /api/access-codes/{id}/toggle-block:
 *   put:
 *     summary: Block/Unblock access code (Admin/Manager only)
 *     tags: [Access Codes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Access code ID
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
 *                 description: Whether to block or unblock the code
 *               blockedUntil:
 *                 type: string
 *                 format: date-time
 *                 description: Block until this date (optional)
 *     responses:
 *       200:
 *         description: Access code blocked/unblocked successfully
 *       404:
 *         description: Access code not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin/Manager role required
 */
router.put('/:id/toggle-block',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  [
    param('id').isUUID().withMessage('Valid access code ID is required'),
    body('isBlocked').isBoolean().withMessage('isBlocked must be a boolean')
  ],
  accessCodeController.toggleAccessCodeBlock
);

/**
 * @swagger
 * /api/access-codes/{id}:
 *   delete:
 *     summary: Delete access code (Admin/Manager only)
 *     tags: [Access Codes]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: Access code ID
 *     responses:
 *       200:
 *         description: Access code deleted successfully
 *       404:
 *         description: Access code not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - Admin/Manager role required
 */
router.delete('/:id',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  [
    param('id').isUUID().withMessage('Valid access code ID is required')
  ],
  accessCodeController.deleteAccessCode
);

module.exports = router;
