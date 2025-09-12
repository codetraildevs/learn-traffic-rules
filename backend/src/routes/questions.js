const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const questionController = require('../controllers/questionController');
const authMiddleware = require('../middleware/authMiddleware');

/**
 * @swagger
 * components:
 *   schemas:
 *     Question:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           format: uuid
 *           description: Unique question identifier
 *         examId:
 *           type: string
 *           format: uuid
 *           description: Exam ID this question belongs to
 *         questionText:
 *           type: string
 *           description: The question text
 *         questionType:
 *           type: string
 *           enum: [MULTIPLE_CHOICE, TRUE_FALSE, FILL_BLANK]
 *           description: Type of question
 *         options:
 *           type: array
 *           items:
 *             type: string
 *           description: Answer options for multiple choice questions
 *         correctAnswer:
 *           type: string
 *           description: The correct answer
 *         explanation:
 *           type: string
 *           description: Explanation for the correct answer
 *         imageUrl:
 *           type: string
 *           description: URL to question image (optional)
 *         questionImgUrl:
 *           type: string
 *           description: URL to question image (optional)
 *         difficulty:
 *           type: string
 *           enum: [EASY, MEDIUM, HARD]
 *           description: Question difficulty level
 *         points:
 *           type: integer
 *           description: Points awarded for correct answer
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 */

/**
 * @swagger
 * /api/questions/exam/{examId}:
 *   get:
 *     summary: Get all questions for an exam (requires access)
 *     tags: [Questions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: examId
 *         required: true
 *         schema:
 *           type: string
 *         description: Exam ID
 *     responses:
 *       200:
 *         description: Questions retrieved successfully
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
 *                     exam:
 *                       type: object
 *                       properties:
 *                         id:
 *                           type: string
 *                         title:
 *                           type: string
 *                         description:
 *                           type: string
 *                         duration:
 *                           type: integer
 *                         questionCount:
 *                           type: integer
 *                         passingScore:
 *                           type: integer
 *                     questions:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Question'
 *       403:
 *         description: Access denied
 *       404:
 *         description: Exam not found
 */
router.get('/exam/:examId',
  authMiddleware.authenticate,
  questionController.getExamQuestions
);

/**
 * @swagger
 * /api/questions:
 *   post:
 *     summary: Create a new question (Admin/Manager only)
 *     tags: [Questions]
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
 *               - questionText
 *               - options
 *               - correctAnswer
 *             properties:
 *               examId:
 *                 type: string
 *                 description: Exam ID
 *               questionText:
 *                 type: string
 *                 description: The question text
 *               questionType:
 *                 type: string
 *                 enum: [MULTIPLE_CHOICE, TRUE_FALSE, FILL_BLANK]
 *                 description: Type of question
 *               options:
 *                 type: array
 *                 items:
 *                   type: string
 *                 description: Answer options
 *               correctAnswer:
 *                 type: string
 *                 description: The correct answer
 *               explanation:
 *                 type: string
 *                 description: Explanation for the correct answer
 *               imageUrl:
 *                 type: string
 *                 description: URL to question image
 *               difficulty:
 *                 type: string
 *                 enum: [EASY, MEDIUM, HARD]
 *                 description: Question difficulty
 *               points:
 *                 type: integer
 *                 description: Points awarded
 *     responses:
 *       201:
 *         description: Question created successfully
 *       400:
 *         description: Bad request - validation failed
 *       404:
 *         description: Exam not found
 */
router.post('/',
  authMiddleware.authenticate,
  authMiddleware.requireManager,
  [
    body('examId').notEmpty().withMessage('Exam ID is required'),
    body('questionText').notEmpty().withMessage('Question text is required'),
    body('options').isArray({ min: 2 }).withMessage('At least 2 options are required'),
    body('correctAnswer').notEmpty().withMessage('Correct answer is required'),
    body('questionType').optional().isIn(['MULTIPLE_CHOICE', 'TRUE_FALSE', 'FILL_BLANK']).withMessage('Invalid question type'),
    body('difficulty').optional().isIn(['EASY', 'MEDIUM', 'HARD']).withMessage('Invalid difficulty level'),
    body('points').optional().isInt({ min: 1 }).withMessage('Points must be a positive integer')
  ],
  questionController.createQuestion
);

/**
 * @swagger
 * /api/questions/bulk:
 *   post:
 *     summary: Bulk create questions for an exam (Admin/Manager only)
 *     tags: [Questions]
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
 *               - questions
 *             properties:
 *               examId:
 *                 type: string
 *                 description: Exam ID
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
 *                     questionType:
 *                       type: string
 *                       enum: [MULTIPLE_CHOICE, TRUE_FALSE, FILL_BLANK]
 *                     options:
 *                       type: array
 *                       items:
 *                         type: string
 *                     correctAnswer:
 *                       type: string
 *                     explanation:
 *                       type: string
 *                     imageUrl:
 *                       type: string
 *                     difficulty:
 *                       type: string
 *                       enum: [EASY, MEDIUM, HARD]
 *                     points:
 *                       type: integer
 *     responses:
 *       201:
 *         description: Questions created successfully
 *       400:
 *         description: Bad request - validation failed
 *       404:
 *         description: Exam not found
 */
router.post('/bulk',
  authMiddleware.authenticate,
  authMiddleware.requireManager,
  [
    body('examId').notEmpty().withMessage('Exam ID is required'),
    body('questions').isArray({ min: 1 }).withMessage('At least one question is required')
  ],
  questionController.bulkCreateQuestions
);

/**
 * @swagger
 * /api/questions/{id}:
 *   get:
 *     summary: Get question by ID
 *     tags: [Questions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Question ID
 *     responses:
 *       200:
 *         description: Question retrieved successfully
 *       404:
 *         description: Question not found
 */
router.get('/:id',
  authMiddleware.authenticate,
  questionController.getQuestionById
);

/**
 * @swagger
 * /api/questions/{id}:
 *   put:
 *     summary: Update a question (Admin/Manager only)
 *     tags: [Questions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Question ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               questionText:
 *                 type: string
 *               questionType:
 *                 type: string
 *                 enum: [MULTIPLE_CHOICE, TRUE_FALSE, FILL_BLANK]
 *               options:
 *                 type: array
 *                 items:
 *                   type: string
 *               correctAnswer:
 *                 type: string
 *               explanation:
 *                 type: string
 *               imageUrl:
 *                 type: string
 *               difficulty:
 *                 type: string
 *                 enum: [EASY, MEDIUM, HARD]
 *               points:
 *                 type: integer
 *     responses:
 *       200:
 *         description: Question updated successfully
 *       400:
 *         description: Bad request - validation failed
 *       404:
 *         description: Question not found
 */
router.put('/:id',
  authMiddleware.authenticate,
  authMiddleware.requireManager,
  [
    body('questionText').optional().notEmpty().withMessage('Question text cannot be empty'),
    body('options').optional().isArray({ min: 2 }).withMessage('At least 2 options are required'),
    body('correctAnswer').optional().notEmpty().withMessage('Correct answer cannot be empty'),
    body('questionType').optional().isIn(['MULTIPLE_CHOICE', 'TRUE_FALSE', 'FILL_BLANK']).withMessage('Invalid question type'),
    body('difficulty').optional().isIn(['EASY', 'MEDIUM', 'HARD']).withMessage('Invalid difficulty level'),
    body('points').optional().isInt({ min: 1 }).withMessage('Points must be a positive integer')
  ],
  questionController.updateQuestion
);

/**
 * @swagger
 * /api/questions/{id}:
 *   delete:
 *     summary: Delete a question (Admin/Manager only)
 *     tags: [Questions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Question ID
 *     responses:
 *       200:
 *         description: Question deleted successfully
 *       404:
 *         description: Question not found
 */
router.delete('/:id',
  authMiddleware.authenticate,
  authMiddleware.requireManager,
  questionController.deleteQuestion
);

module.exports = router;
