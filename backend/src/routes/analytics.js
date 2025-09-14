const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analyticsController');
const authMiddleware = require('../middleware/authMiddleware');
const { param, query } = require('express-validator');

/**
 * @swagger
 * components:
 *   schemas:
 *     DashboardAnalytics:
 *       type: object
 *       properties:
 *         overview:
 *           type: object
 *           properties:
 *             totalUsers:
 *               type: integer
 *             activeUsers:
 *               type: integer
 *             totalExams:
 *               type: integer
 *             totalQuestions:
 *               type: integer
 *             totalResults:
 *               type: integer
 *             period:
 *               type: string
 *         recentActivity:
 *           type: object
 *           properties:
 *             recentResults:
 *               type: integer
 *             userGrowth:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   date:
 *                     type: string
 *                   newUsers:
 *                     type: integer
 *             paymentStats:
 *               type: object
 *               properties:
 *                 totalRequests:
 *                   type: integer
 *                 approvedRequests:
 *                   type: integer
 *                 approvalRate:
 *                   type: string
 *         examAnalytics:
 *           type: object
 *           properties:
 *             examStats:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: string
 *                   title:
 *                     type: string
 *                   category:
 *                     type: string
 *                   difficulty:
 *                     type: string
 *                   questionCount:
 *                     type: integer
 *             examPerformance:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   examTitle:
 *                     type: string
 *                   category:
 *                     type: string
 *                   attempts:
 *                     type: integer
 *                   passed:
 *                     type: integer
 *                   passRate:
 *                     type: string
 *                   averageScore:
 *                     type: string
 *     UserPerformance:
 *       type: object
 *       properties:
 *         summary:
 *           type: object
 *           properties:
 *             totalExams:
 *               type: integer
 *             passedExams:
 *               type: integer
 *             passRate:
 *               type: string
 *             averageScore:
 *               type: string
 *             totalTimeSpent:
 *               type: integer
 *             averageTimePerExam:
 *               type: integer
 *         categoryPerformance:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               category:
 *                 type: string
 *               attempts:
 *                 type: integer
 *               passed:
 *                 type: integer
 *               passRate:
 *                 type: string
 *               averageScore:
 *                 type: string
 *         difficultyPerformance:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               difficulty:
 *                 type: string
 *               attempts:
 *                 type: integer
 *               passed:
 *                 type: integer
 *               passRate:
 *                 type: string
 *               averageScore:
 *                 type: string
 *         performanceTrend:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               week:
 *                 type: string
 *               attempts:
 *                 type: integer
 *               averageScore:
 *                 type: string
 *         recentResults:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               examTitle:
 *                 type: string
 *               score:
 *                 type: number
 *               passed:
 *                 type: boolean
 *               completedAt:
 *                 type: string
 *                 format: date-time
 *               timeSpent:
 *                 type: integer
 *     ExamAnalytics:
 *       type: object
 *       properties:
 *         exam:
 *           type: object
 *           properties:
 *             id:
 *               type: string
 *             title:
 *               type: string
 *             category:
 *               type: string
 *             difficulty:
 *               type: string
 *             questionCount:
 *               type: integer
 *         statistics:
 *           type: object
 *           properties:
 *             totalAttempts:
 *               type: integer
 *             passedAttempts:
 *               type: integer
 *             passRate:
 *               type: number
 *             averageScore:
 *               type: string
 *             averageTime:
 *               type: integer
 *         questionStats:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               questionId:
 *                 type: string
 *               difficulty:
 *                 type: string
 *               points:
 *                 type: integer
 *               totalAttempts:
 *                 type: integer
 *               correctAnswers:
 *                 type: integer
 *               accuracy:
 *                 type: string
 *         performanceOverTime:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               date:
 *                 type: string
 *               attempts:
 *                 type: integer
 *               passed:
 *                 type: integer
 *               passRate:
 *                 type: string
 *               averageScore:
 *                 type: string
 *         period:
 *               type: string
 */

/**
 * @swagger
 * /api/analytics/dashboard:
 *   get:
 *     summary: Get dashboard analytics (Admin/Manager only)
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 30
 *         description: Number of days to analyze (default 30)
 *     responses:
 *       200:
 *         description: Dashboard analytics retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/DashboardAnalytics'
 *       403:
 *         description: Access denied
 */
router.get('/dashboard',
  authMiddleware.authenticate,
  [
    query('days').optional().isInt({ min: 1, max: 365 }).withMessage('Days must be between 1 and 365')
  ],
  analyticsController.getDashboardAnalytics
);

/**
 * @swagger
 * /api/analytics/user-performance:
 *   get:
 *     summary: Get user performance analytics
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 30
 *         description: Number of days to analyze (default 30)
 *     responses:
 *       200:
 *         description: User performance analytics retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/UserPerformance'
 */
router.get('/user-performance',
  authMiddleware.authenticate,
  [
    query('days').optional().isInt({ min: 1, max: 365 }).withMessage('Days must be between 1 and 365')
  ],
  analyticsController.getUserPerformance
);

/**
 * @swagger
 * /api/analytics/exam/{examId}:
 *   get:
 *     summary: Get exam analytics
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: examId
 *         required: true
 *         schema:
 *           type: string
 *         description: Exam ID
 *       - in: query
 *         name: days
 *         schema:
 *           type: integer
 *           default: 30
 *         description: Number of days to analyze (default 30)
 *     responses:
 *       200:
 *         description: Exam analytics retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/ExamAnalytics'
 *       404:
 *         description: Exam not found
 */
router.get('/exam/:examId',
  authMiddleware.authenticate,
  [
    param('examId').isUUID().withMessage('Invalid exam ID'),
    query('days').optional().isInt({ min: 1, max: 365 }).withMessage('Days must be between 1 and 365')
  ],
  analyticsController.getExamAnalytics
);

module.exports = router;
