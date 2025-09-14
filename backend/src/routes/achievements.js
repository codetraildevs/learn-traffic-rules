const express = require('express');
const router = express.Router();
const achievementController = require('../controllers/achievementController');
const authMiddleware = require('../middleware/authMiddleware');
const { query } = require('express-validator');

/**
 * @swagger
 * components:
 *   schemas:
 *     Achievement:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *         name:
 *           type: string
 *         description:
 *           type: string
 *         icon:
 *           type: string
 *         points:
 *           type: integer
 *         unlocked:
 *           type: boolean
 *         unlockedAt:
 *           type: string
 *           format: date-time
 *         category:
 *           type: string
 *           enum: [milestone, performance, consistency, expertise, dedication]
 *     UserStats:
 *       type: object
 *       properties:
 *         level:
 *           type: integer
 *         totalPoints:
 *           type: integer
 *         pointsToNextLevel:
 *           type: integer
 *         totalExams:
 *           type: integer
 *         passedExams:
 *           type: integer
 *         passRate:
 *           type: string
 *         averageScore:
 *           type: string
 *         totalTimeSpent:
 *           type: integer
 *         currentStreak:
 *           type: integer
 *         longestStreak:
 *           type: integer
 *         categoryStats:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               category:
 *                 type: string
 *               exams:
 *                 type: integer
 *               passed:
 *                 type: integer
 *               averageScore:
 *                 type: string
 *               expertise:
 *                 type: string
 *                 enum: [Novice, Beginner, Intermediate, Advanced, Expert]
 *         rank:
 *           type: integer
 *     LeaderboardEntry:
 *       type: object
 *       properties:
 *         rank:
 *           type: integer
 *         userId:
 *           type: string
 *         fullName:
 *           type: string
 *         points:
 *           type: integer
 *         level:
 *           type: integer
 *         avatar:
 *           type: string
 *         examsCompleted:
 *           type: integer
 *         currentStreak:
 *           type: integer
 */

/**
 * @swagger
 * /api/achievements:
 *   get:
 *     summary: Get user achievements
 *     tags: [Achievements]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User achievements retrieved successfully
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
 *                     achievements:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Achievement'
 *                     totalPoints:
 *                       type: integer
 *                     totalAchievements:
 *                       type: integer
 *                     unlockedAchievements:
 *                       type: integer
 */
router.get('/',
  authMiddleware.authenticate,
  achievementController.getUserAchievements
);

/**
 * @swagger
 * /api/achievements/leaderboard:
 *   get:
 *     summary: Get leaderboard
 *     tags: [Achievements]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [points, exams, streak]
 *           default: points
 *         description: Leaderboard type
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *           minimum: 1
 *           maximum: 100
 *         description: Number of entries to return
 *     responses:
 *       200:
 *         description: Leaderboard retrieved successfully
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
 *                     leaderboard:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/LeaderboardEntry'
 *                     type:
 *                       type: string
 *                     limit:
 *                       type: integer
 */
router.get('/leaderboard',
  authMiddleware.authenticate,
  [
    query('type').optional().isIn(['points', 'exams', 'streak']).withMessage('Type must be points, exams, or streak'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100')
  ],
  achievementController.getLeaderboard
);

/**
 * @swagger
 * /api/achievements/stats:
 *   get:
 *     summary: Get user stats
 *     tags: [Achievements]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User stats retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/UserStats'
 */
router.get('/stats',
  authMiddleware.authenticate,
  achievementController.getUserStats
);

module.exports = router;
