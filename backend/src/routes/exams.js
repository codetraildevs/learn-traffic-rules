const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const examController = require('../controllers/examController');
const authMiddleware = require('../middleware/authMiddleware');
const { uploadSingle, uploadQuestionImage, uploadMultiple } = require('../middleware/upload');

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
// Regular user route for taking exams (must be before /:id route)
router.get('/:id/take-exam',
  authMiddleware.authenticate,
  examController.getExamQuestionsForTaking
);

/**
 * @swagger
 * /api/exams/user-results:
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
router.get('/user-results', 
  authMiddleware.authenticate,
  examController.getUserExamResults
);

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
 * /exams/{id}/toggle-status:
 *   put:
 *     summary: Toggle exam active status
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
 *         description: Exam status toggled successfully
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
 *                   $ref: '#/components/schemas/Exam'
 *       404:
 *         description: Exam not found
 *       500:
 *         description: Server error
 */
router.put('/:id/toggle-status', 
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  examController.toggleExamStatus
);

/**
 * @swagger
 * /exams/{id}:
 *   delete:
 *     summary: Delete an exam
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
 *         description: Exam deleted successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *       404:
 *         description: Exam not found
 *       500:
 *         description: Server error
 */
router.delete('/:id', 
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  examController.deleteExam
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
 * /api/exams/submit-result:
 *   post:
 *     summary: Submit exam result (for both free and paid exams)
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
 *               - isFreeExam
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
 *               isFreeExam:
 *                 type: boolean
 *                 description: Whether this is a free exam attempt
 *     responses:
 *       200:
 *         description: Exam result submitted successfully
 *       403:
 *         description: Access denied or no free exams remaining
 *       404:
 *         description: Exam not found
 */
router.post('/submit-result', 
  authMiddleware.authenticate,
  [
    body('examId').notEmpty().withMessage('Exam ID is required'),
    body('answers').isObject().withMessage('Answers must be an object'),
    body('timeSpent').isInt({ min: 0 }).withMessage('Time spent must be a non-negative integer'),
    body('isFreeExam').isBoolean().withMessage('isFreeExam must be a boolean')
  ],
  examController.submitExamResult
);


/**
 * @swagger
 * /api/exams/upload-image:
 *   post:
 *     summary: Upload exam image (Admin/Manager only)
 *     tags: [Exams]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               image:
 *                 type: string
 *                 format: binary
 *                 description: Image file to upload
 *     responses:
 *       200:
 *         description: Image uploaded successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 imageUrl:
 *                   type: string
 */
router.post('/upload-image',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  uploadSingle,
  examController.uploadExamImage
);

/**
 * @swagger
 * /api/exams/upload-question-image:
 *   post:
 *     summary: Upload question image (Admin/Manager only)
 *     tags: [Exams]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               questionImage:
 *                 type: string
 *                 format: binary
 *                 description: Question image file
 *     responses:
 *       200:
 *         description: Image uploaded successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 imageUrl:
 *                   type: string
 *       400:
 *         description: Bad request - no image provided
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden - insufficient permissions
 */
router.post('/upload-question-image',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  uploadQuestionImage,
  examController.uploadQuestionImage
);

/**
 * @swagger
 * /api/exams/{id}/upload-single-question:
 *   post:
 *     summary: Upload single question (Admin/Manager only)
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
 *               - question
 *               - option1
 *               - option2
 *               - correctAnswer
 *             properties:
 *               question:
 *                 type: string
 *                 description: The question text
 *               option1:
 *                 type: string
 *                 description: First option
 *               option2:
 *                 type: string
 *                 description: Second option
 *               option3:
 *                 type: string
 *                 description: Third option (optional)
 *               option4:
 *                 type: string
 *                 description: Fourth option (optional)
 *               correctAnswer:
 *                 type: string
 *                 description: The correct answer
 *               questionImgUrl:
 *                 type: string
 *                 description: URL to question image (optional)
 *               points:
 *                 type: integer
 *                 description: Points awarded (default 1)
 *     responses:
 *       201:
 *         description: Question added successfully
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
 *       400:
 *         description: Bad request - validation failed
 *       404:
 *         description: Exam not found
 */
/**
 * @swagger
 * /api/exams/{id}/questions:
 *   get:
 *     summary: Get all questions for an exam (Admin/Manager only)
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
 *           default: 50
 *         description: Number of questions per page
 *     responses:
 *       200:
 *         description: Questions retrieved successfully
 *       404:
 *         description: Exam not found
 */
// Admin/Manager route for managing questions
router.get('/:id/questions',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  examController.getExamQuestions
);


/**
 * @swagger
 * /api/exams/{id}/questions/{questionId}:
 *   get:
 *     summary: Get single question by ID (Admin/Manager only)
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
 *       - in: path
 *         name: questionId
 *         required: true
 *         schema:
 *           type: string
 *         description: Question ID
 *     responses:
 *       200:
 *         description: Question retrieved successfully
 *       404:
 *         description: Exam or question not found
 */
router.get('/:id/questions/:questionId',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  examController.getQuestionById
);

/**
 * @swagger
 * /api/exams/{id}/questions/{questionId}:
 *   put:
 *     summary: Update question (Admin/Manager only)
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
 *       - in: path
 *         name: questionId
 *         required: true
 *         schema:
 *           type: string
 *         description: Question ID
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               question:
 *                 type: string
 *                 description: Question text
 *               option1:
 *                 type: string
 *                 description: First option
 *               option2:
 *                 type: string
 *                 description: Second option
 *               option3:
 *                 type: string
 *                 description: Third option
 *               option4:
 *                 type: string
 *                 description: Fourth option
 *               correctAnswer:
 *                 type: string
 *                 description: Correct answer
 *               points:
 *                 type: integer
 *                 description: Points for this question (default 1)
 *               questionImage:
 *                 type: string
 *                 format: binary
 *                 description: Question image (optional)
 *     responses:
 *       200:
 *         description: Question updated successfully
 *       404:
 *         description: Exam or question not found
 */
router.put('/:id/questions/:questionId',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  uploadQuestionImage,
  examController.updateQuestion
);

/**
 * @swagger
 * /api/exams/{id}/questions/{questionId}:
 *   delete:
 *     summary: Delete question (Admin/Manager only)
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
 *       - in: path
 *         name: questionId
 *         required: true
 *         schema:
 *           type: string
 *         description: Question ID
 *     responses:
 *       200:
 *         description: Question deleted successfully
 *       404:
 *         description: Exam or question not found
 */
router.delete('/:id/questions/:questionId',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  examController.deleteQuestion
);

router.post('/:id/upload-single-question',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  uploadQuestionImage,
  [
    body('question').notEmpty().withMessage('Question is required'),
    body('option1').notEmpty().withMessage('Option 1 is required'),
    body('option2').notEmpty().withMessage('Option 2 is required'),
    body('correctAnswer').notEmpty().withMessage('Correct answer is required')
  ],
  examController.uploadSingleQuestion
);

/**
 * @swagger
 * /api/exams/{id}/upload-questions:
 *   post:
 *     summary: Upload questions in bulk (Admin/Manager only)
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
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               files:
 *                 type: array
 *                 items:
 *                   type: string
 *                   format: binary
 *                 description: CSV or Excel files containing questions
 *     responses:
 *       200:
 *         description: Questions uploaded successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 questionsAdded:
 *                   type: integer
 */
router.post('/:id/upload-questions',
  authMiddleware.authenticate,
  authMiddleware.requireRole(['ADMIN', 'MANAGER']),
  uploadMultiple,
  examController.uploadQuestions
);

module.exports = router;
