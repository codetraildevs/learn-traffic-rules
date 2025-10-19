const express = require('express');
const router = express.Router();
const offlineController = require('../controllers/offlineController');
const authMiddleware = require('../middleware/authMiddleware');
const { body, param } = require('express-validator');

/**
 * @swagger
 * components:
 *   schemas:
 *     OfflineExamData:
 *       type: object
 *       properties:
 *         exam:
 *           type: object
 *           properties:
 *             id:
 *               type: string
 *             title:
 *               type: string
 *             description:
 *               type: string
 *             category:
 *               type: string
 *             difficulty:
 *               type: string
 *               enum: [EASY, MEDIUM, HARD]
 *             duration:
 *               type: integer
 *             questionCount:
 *               type: integer
 *             passingScore:
 *               type: integer
 *             examImgUrl:
 *               type: string
 *             lastUpdated:
 *               type: string
 *               format: date-time
 *         questions:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               id:
 *                 type: string
 *               question:
 *                 type: string
 *               options:
 *                 type: array
 *                 items:
 *                   type: string
 *               correctAnswer:
 *                 type: string
 *               explanation:
 *                 type: string
 *               difficulty:
 *                 type: string
 *               points:
 *                 type: integer
 *               imageUrl:
 *                 type: string
 *               questionImgUrl:
 *                 type: string
 *               lastUpdated:
 *                 type: string
 *                 format: date-time
 *         downloadedAt:
 *           type: string
 *           format: date-time
 *         version:
 *           type: integer
 *     OfflineExamResult:
 *       type: object
 *       properties:
 *         examId:
 *           type: string
 *         score:
 *           type: number
 *         totalQuestions:
 *           type: integer
 *         correctAnswers:
 *           type: integer
 *         timeSpent:
 *           type: integer
 *         answers:
 *           type: object
 *         passed:
 *           type: boolean
 *         completedAt:
 *           type: string
 *           format: date-time
 *     SyncStatus:
 *       type: object
 *       properties:
 *         lastSyncAt:
 *           type: string
 *           format: date-time
 *         totalExams:
 *           type: integer
 *         totalQuestions:
 *           type: integer
 *         hasAccess:
 *           type: boolean
 */

/**
 * @swagger
 * /api/offline/download/exam/{examId}:
 *   get:
 *     summary: Download exam data for offline use
 *     tags: [Offline]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: examId
 *         required: true
 *         schema:
 *           type: string
 *         description: Exam ID to download
 *     responses:
 *       200:
 *         description: Exam data downloaded successfully
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
 *                   $ref: '#/components/schemas/OfflineExamData'
 *       403:
 *         description: Access denied
 *       404:
 *         description: Exam not found
 */
router.get('/download/exam/:examId',
  authMiddleware.authenticate,
  [
    param('examId').isUUID().withMessage('Invalid exam ID')
  ],
  offlineController.downloadExamData
);

/**
 * @swagger
 * /api/offline/download/all:
 *   get:
 *     summary: Download all exams for offline use
 *     tags: [Offline]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: All exams downloaded successfully
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
 *                         $ref: '#/components/schemas/OfflineExamData'
 *                     downloadedAt:
 *                       type: string
 *                       format: date-time
 *                     version:
 *                       type: integer
 *       403:
 *         description: Access denied
 */
router.get('/download/all',
  authMiddleware.authenticate,
  offlineController.downloadAllExams
);

/**
 * @swagger
 * /api/offline/check-updates:
 *   post:
 *     summary: Check for updates since last sync
 *     tags: [Offline]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               lastSyncTime:
 *                 type: string
 *                 format: date-time
 *                 description: Last sync timestamp
 *     responses:
 *       200:
 *         description: Update check completed
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 hasUpdates:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     updatedExams:
 *                       type: integer
 *                     updatedQuestions:
 *                       type: integer
 *                     newQuestions:
 *                       type: integer
 *                     lastChecked:
 *                       type: string
 *                       format: date-time
 *       403:
 *         description: Access denied
 */
router.post('/check-updates',
  authMiddleware.authenticate,
  [
    body('lastSyncTime').isISO8601().withMessage('Invalid last sync time format')
  ],
  offlineController.checkForUpdates
);

/**
 * @swagger
 * /api/offline/sync-results:
 *   post:
 *     summary: Sync offline exam results
 *     tags: [Offline]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               results:
 *                 type: array
 *                 items:
 *                   $ref: '#/components/schemas/OfflineExamResult'
 *     responses:
 *       200:
 *         description: Exam results synced successfully
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
 *                     syncedCount:
 *                       type: integer
 *                     totalSubmitted:
 *                       type: integer
 *                     syncedAt:
 *                       type: string
 *                       format: date-time
 *       400:
 *         description: Bad request - no results to sync
 */
router.post('/sync-results',
  authMiddleware.authenticate,
  [
    body('results').isArray().withMessage('Results must be an array'),
    body('results.*.examId').isUUID().withMessage('Invalid exam ID'),
    body('results.*.score').isNumeric().withMessage('Score must be numeric'),
    body('results.*.answers').isObject().withMessage('Answers must be an object')
  ],
  offlineController.syncExamResults
);

/**
 * @swagger
 * /api/offline/sync-status:
 *   get:
 *     summary: Get user's offline sync status
 *     tags: [Offline]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Sync status retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/SyncStatus'
 */
router.get('/sync-status',
  authMiddleware.authenticate,
  offlineController.getSyncStatus
);

/**
 * @swagger
 * /api/offline/update-sync:
 *   post:
 *     summary: Update user's last sync time
 *     tags: [Offline]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Last sync time updated successfully
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
 *                     lastSyncAt:
 *                       type: string
 *                       format: date-time
 */
router.post('/update-sync',
  authMiddleware.authenticate,
  offlineController.updateLastSync
);

/**
 * @swagger
 * /api/offline/download/free:
 *   get:
 *     summary: Download free exams for offline use (no access required)
 *     tags: [Offline]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Free exams downloaded successfully
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
 *                         $ref: '#/components/schemas/OfflineExamData'
 *                     metadata:
 *                       type: object
 *                       properties:
 *                         downloadedAt:
 *                           type: string
 *                           format: date-time
 *                         version:
 *                           type: integer
 *                         totalExams:
 *                           type: integer
 *                         totalQuestions:
 *                           type: integer
 *                         isFreeContent:
 *                           type: boolean
 */
router.get('/download/free',
  authMiddleware.authenticate,
  offlineController.downloadFreeExams
);

/**
 * @swagger
 * /api/offline/summary:
 *   get:
 *     summary: Get offline capabilities summary
 *     tags: [Offline]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Offline summary retrieved successfully
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
 *                     hasAccess:
 *                       type: boolean
 *                     totalExams:
 *                       type: integer
 *                     freeExamsCount:
 *                       type: integer
 *                     premiumExamsCount:
 *                       type: integer
 *                     lastSyncAt:
 *                       type: string
 *                       format: date-time
 *                     offlineCapabilities:
 *                       type: object
 *                       properties:
 *                         canDownloadFreeExams:
 *                           type: boolean
 *                         canDownloadAllExams:
 *                           type: boolean
 *                         canSyncResults:
 *                           type: boolean
 *                         canCheckUpdates:
 *                           type: boolean
 */
router.get('/summary',
  authMiddleware.authenticate,
  offlineController.getOfflineSummary
);

/**
 * @swagger
 * /api/offline/validate-result:
 *   post:
 *     summary: Validate offline exam result before syncing
 *     tags: [Offline]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               examId:
 *                 type: string
 *               answers:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     questionId:
 *                       type: string
 *                     selectedAnswer:
 *                       type: string
 *               score:
 *                 type: number
 *               timeSpent:
 *                 type: integer
 *     responses:
 *       200:
 *         description: Validation completed
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
 *                     isValid:
 *                       type: boolean
 *                     validationErrors:
 *                       type: array
 *                       items:
 *                         type: string
 *                     examInfo:
 *                       type: object
 *                       properties:
 *                         id:
 *                           type: string
 *                         title:
 *                           type: string
 *                         totalQuestions:
 *                           type: integer
 *                         passingScore:
 *                           type: integer
 *       404:
 *         description: Exam not found
 */
router.post('/validate-result',
  authMiddleware.authenticate,
  [
    body('examId').isUUID().withMessage('Invalid exam ID'),
    body('answers').isArray().withMessage('Answers must be an array'),
    body('score').isNumeric().withMessage('Score must be numeric'),
    body('timeSpent').isInt().withMessage('Time spent must be an integer')
  ],
  offlineController.validateOfflineResult
);

module.exports = router;
