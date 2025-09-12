const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const authMiddleware = require('../middleware/authMiddleware');
const { body } = require('express-validator');

/**
 * @swagger
 * components:
 *   schemas:
 *     PaymentRequest:
 *       type: object
 *       required:
 *         - examId
 *         - amount
 *         - paymentMethod
 *         - paymentProof
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           description: Unique payment request identifier
 *         userId:
 *           type: string
 *           format: uuid
 *           description: User ID
 *         amount:
 *           type: number
 *           format: decimal
 *           description: Payment amount
 *         paymentMethod:
 *           type: string
 *           description: Payment method used
 *         paymentProof:
 *           type: string
 *           description: Proof of payment (receipt, transaction ID, etc.)
 *         status:
 *           type: string
 *           enum: [PENDING, APPROVED, REJECTED]
 *           description: Payment status
 *         rejectionReason:
 *           type: string
 *           description: Reason for rejection (if rejected)
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 */

/**
 * @swagger
 * /api/payments/request:
 *   post:
 *     summary: Request global access with payment (unlocks all exams)
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - amount
 *               - paymentMethod
 *               - paymentProof
 *             properties:
 *               amount:
 *                 type: number
 *                 description: Payment amount (set by frontend)
 *               paymentMethod:
 *                 type: string
 *                 description: Payment method used (Bank Transfer, Mobile Money, etc.)
 *               paymentProof:
 *                 type: string
 *                 description: Proof of payment (receipt number, transaction ID, etc.)
 *     responses:
 *       201:
 *         description: Payment request submitted successfully
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
 *                   $ref: '#/components/schemas/PaymentRequest'
 *       400:
 *         description: Bad request - validation failed
 */
router.post('/request', 
  authMiddleware.authenticate,
  [
    body('amount').isFloat({ min: 0 }).withMessage('Amount must be a positive number'),
    body('paymentMethod').notEmpty().withMessage('Payment method is required'),
    body('paymentProof').notEmpty().withMessage('Payment proof is required')
  ],
  paymentController.requestGlobalAccess
);

/**
 * @swagger
 * /api/payments/my-requests:
 *   get:
 *     summary: Get user's payment requests
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User's payment requests
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
 *                     $ref: '#/components/schemas/PaymentRequest'
 */
router.get('/my-requests', 
  authMiddleware.authenticate,
  paymentController.getUserPaymentRequests
);

/**
 * @swagger
 * /api/payments/requests:
 *   get:
 *     summary: Get all payment requests (Manager/Admin only)
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [PENDING, APPROVED, REJECTED]
 *         description: Filter by payment status
 *     responses:
 *       200:
 *         description: All payment requests
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
 *                     $ref: '#/components/schemas/PaymentRequest'
 *       403:
 *         description: Forbidden - Manager/Admin access required
 */
router.get('/requests', 
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  paymentController.getAllPaymentRequests
);

/**
 * @swagger
 * /api/payments/requests/{id}/approve:
 *   patch:
 *     summary: Approve payment request (Manager/Admin only)
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Payment request ID
 *     responses:
 *       200:
 *         description: Payment request approved successfully
 *       404:
 *         description: Payment request not found
 *       403:
 *         description: Forbidden - Manager/Admin access required
 */
router.patch('/requests/:id/approve', 
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  paymentController.approvePaymentRequest
);

/**
 * @swagger
 * /api/payments/requests/{id}/reject:
 *   patch:
 *     summary: Reject payment request (Manager/Admin only)
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Payment request ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - rejectionReason
 *             properties:
 *               rejectionReason:
 *                 type: string
 *                 description: Reason for rejection
 *     responses:
 *       200:
 *         description: Payment request rejected successfully
 *       404:
 *         description: Payment request not found
 *       403:
 *         description: Forbidden - Manager/Admin access required
 */
router.patch('/requests/:id/reject', 
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  [
    body('rejectionReason').notEmpty().withMessage('Rejection reason is required')
  ],
  paymentController.rejectPaymentRequest
);

/**
 * @swagger
 * /api/payments/my-access-codes:
 *   get:
 *     summary: Get user's access codes
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User's access codes
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
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: string
 *                       code:
 *                         type: string
 *                       examId:
 *                         type: string
 *                       examTitle:
 *                         type: string
 *                       expiresAt:
 *                         type: string
 *                         format: date-time
 *                       isUsed:
 *                         type: boolean
 *                       usedAt:
 *                         type: string
 *                         format: date-time
 */
router.get('/my-access-codes', 
  authMiddleware.authenticate,
  paymentController.getUserAccessCodes
);

module.exports = router;
