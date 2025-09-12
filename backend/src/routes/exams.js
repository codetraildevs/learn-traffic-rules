const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const examController = require('../controllers/examController');
const authMiddleware = require('../middleware/authMiddleware');

/**
 * @swagger
 * components:
 *   schemas:
 *     Exam:
 *       type: object
 *       required:
 *         - title
 *         - description
 *         - category
 *         - difficulty
 *         - duration
 *         - questionCount
 *         - passingScore
 *         - price
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           description: Unique exam identifier
 *         title:
 *           type: string
 *           description: Exam title
 *         description:
 *           type: string
 *           description: Exam description
 *         category:
 *           type: string
 *           description: Exam category
 *         difficulty:
 *           type: string
 *           enum: [EASY, MEDIUM, HARD]
 *           description: Exam difficulty level
 *         duration:
 *           type: integer
 *           description: Exam duration in minutes
 *         questionCount:
 *           type: integer
 *           description: Number of questions
 *         passingScore:
 *           type: integer
 *           description: Minimum score to pass (percentage)
 *         isActive:
 *           type: boolean
 *           description: Whether exam is active
 *         examImgUrl:
 *           type: string
 *           description: URL to exam image
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 */

/**
 * @swagger
 * /api/exams:
 *   get:
 *     summary: Get all active exams
 *     tags: [Exams]
 *     responses:
 *       200:
 *         description: List of active exams
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
 *                     $ref: '#/components/schemas/Exam'
 */
router.get('/', examController.getAllExams);

/**
 * @swagger
 * /api/exams/{id}:
 *   get:
 *     summary: Get exam by ID
 *     tags: [Exams]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Exam ID
 *     responses:
 *       200:
 *         description: Exam details
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/Exam'
 *       404:
 *         description: Exam not found
 */
router.get('/:id', examController.getExamById);

/**
 * @swagger
 * /api/exams/{id}/questions:
 *   get:
 *     summary: Get exam questions (requires access)
 *     tags: [Exams]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Exam ID
 *     responses:
 *       200:
 *         description: Exam questions
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
 *                       question:
 *                         type: string
 *                       options:
 *                         type: array
 *                         items:
 *                           type: string
 *                       difficulty:
 *                         type: string
 *                       points:
 *                         type: integer
 *       403:
 *         description: Access denied - exam not purchased
 *       404:
 *         description: Exam not found
 */
router.get('/:id/questions', authMiddleware.authenticate, examController.getExamQuestions);

/**
 * @swagger
 * /api/exams/{id}/questions:
 *   post:
 *     summary: Add questions to an exam (Admin/Manager only)
 *     tags: [Exams]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Exam ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - questions
 *             properties:
 *               questions:
 *                 type: array
 *                 items:
 *                   type: object
 *                   required:
 *                     - questionText
 *                     - options
 *                     - correctAnswer
 *                   properties:
 *                     questionText:
 *                       type: string
 *                       description: The question text
 *                     questionType:
 *                       type: string
 *                       enum: [MULTIPLE_CHOICE, TRUE_FALSE, FILL_BLANK]
 *                       description: Type of question
 *                     options:
 *                       type: array
 *                       items:
 *                         type: string
 *                       description: Answer options
 *                     correctAnswer:
 *                       type: string
 *                       description: The correct answer
 *                     explanation:
 *                       type: string
 *                       description: Explanation for the correct answer
 *                     imageUrl:
 *                       type: string
 *                       description: URL to question image
 *                     questionImgUrl:
 *                       type: string
 *                       description: URL to question image
 *                     difficulty:
 *                       type: string
 *                       enum: [EASY, MEDIUM, HARD]
 *                       description: Question difficulty
 *                     points:
 *                       type: integer
 *                       description: Points awarded
 *     responses:
 *       201:
 *         description: Questions added successfully
 *       400:
 *         description: Bad request - validation failed
 *       404:
 *         description: Exam not found
 */
router.post('/:id/questions',
  authMiddleware.authenticate,
  authMiddleware.requireManager,
  [
    body('questions').isArray({ min: 1 }).withMessage('At least one question is required')
  ],
  examController.addQuestionsToExam
);

/**
 * @swagger
 * /api/exams:
 *   post:
 *     summary: Create new exam (Admin/Manager only)
 *     tags: [Exams]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Exam'
 *     responses:
 *       201:
 *         description: Exam created successfully
 *       403:
 *         description: Forbidden - Admin/Manager access required
 */
router.post('/', 
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  [
    body('title').notEmpty().withMessage('Title is required'),
    body('description').notEmpty().withMessage('Description is required'),
    body('category').notEmpty().withMessage('Category is required'),
    body('difficulty').isIn(['EASY', 'MEDIUM', 'HARD']).withMessage('Invalid difficulty level'),
    body('duration').isInt({ min: 1 }).withMessage('Duration must be a positive integer'),
    body('questionCount').isInt({ min: 1 }).withMessage('Question count must be a positive integer'),
    body('passingScore').isInt({ min: 0, max: 100 }).withMessage('Passing score must be between 0 and 100')
  ],
  examController.createExam
);

/**
 * @swagger
 * /api/exams/{id}:
 *   put:
 *     summary: Update exam (Admin/Manager only)
 *     tags: [Exams]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Exam ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Exam'
 *     responses:
 *       200:
 *         description: Exam updated successfully
 *       404:
 *         description: Exam not found
 */
router.put('/:id', 
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  examController.updateExam
);

/**
 * @swagger
 * /api/exams/{id}/activate:
 *   patch:
 *     summary: Activate exam (Admin/Manager only)
 *     tags: [Exams]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Exam ID
 *     responses:
 *       200:
 *         description: Exam activated successfully
 *       404:
 *         description: Exam not found
 */
router.patch('/:id/activate', 
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  examController.activateExam
);

/**
 * @swagger
 * /api/exams/{id}/deactivate:
 *   patch:
 *     summary: Deactivate exam (Admin/Manager only)
 *     tags: [Exams]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Exam ID
 *     responses:
 *       200:
 *         description: Exam deactivated successfully
 *       404:
 *         description: Exam not found
 */
router.patch('/:id/deactivate', 
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  examController.deactivateExam
);

/**
 * @swagger
 * /api/exams/submit:
 *   post:
 *     summary: Submit exam answers and get results
 *     tags: [Exams]
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
 *               - timeSpent
 *             properties:
 *               examId:
 *                 type: string
 *                 description: Exam ID
 *               answers:
 *                 type: object
 *                 description: User answers (questionId to answer mapping)
 *               timeSpent:
 *                 type: integer
 *                 description: Time spent in seconds
 *     responses:
 *       200:
 *         description: Exam submitted successfully
 *       403:
 *         description: Access denied - exam not purchased
 *       404:
 *         description: Exam not found
 */
router.post('/submit', 
  authMiddleware.authenticate,
  [
    body('examId').notEmpty().withMessage('Exam ID is required'),
    body('answers').isObject().withMessage('Answers must be an object'),
    body('timeSpent').isInt({ min: 0 }).withMessage('Time spent must be a non-negative integer')
  ],
  examController.submitExam
);

/**
 * @swagger
 * /api/exams/results:
 *   get:
 *     summary: Get user's exam results
 *     tags: [Exams]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User's exam results
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
 *                       examId:
 *                         type: string
 *                       score:
 *                         type: integer
 *                       totalQuestions:
 *                         type: integer
 *                       correctAnswers:
 *                         type: integer
 *                       passed:
 *                         type: boolean
 *                       createdAt:
 *                         type: string
 *                         format: date-time
 *                       Exam:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: string
 *                           title:
 *                             type: string
 *                           category:
 *                             type: string
 *                           difficulty:
 *                             type: string
 */
router.get('/results', 
  authMiddleware.authenticate,
  examController.getUserExamResults
);

module.exports = router;
