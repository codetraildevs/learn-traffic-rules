const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const courseController = require('../controllers/courseController');
const { authenticateToken } = require('../middleware/authMiddleware');

/**
 * @swagger
 * /api/courses:
 *   get:
 *     summary: Get all courses
 *     tags: [Courses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *         description: Filter by category
 *       - in: query
 *         name: difficulty
 *         schema:
 *           type: string
 *           enum: [EASY, MEDIUM, HARD]
 *         description: Filter by difficulty
 *       - in: query
 *         name: courseType
 *         schema:
 *           type: string
 *           enum: [free, paid]
 *         description: Filter by course type
 *       - in: query
 *         name: isActive
 *         schema:
 *           type: boolean
 *         description: Filter by active status
 *     responses:
 *       200:
 *         description: Courses retrieved successfully
 *       500:
 *         description: Internal server error
 */
// User courses route (must be before /:id)
router.get('/user/my-courses', authenticateToken, courseController.getUserCourses);

// Get all courses
router.get('/', authenticateToken, courseController.getAllCourses);

// Get course progress (must be before /:id)
router.get('/:courseId/progress', authenticateToken, courseController.getCourseProgress);

// Get course by ID
router.get('/:id', authenticateToken, courseController.getCourseById);

/**
 * @swagger
 * /api/courses:
 *   post:
 *     summary: Create a new course (Admin only)
 *     tags: [Courses]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               category:
 *                 type: string
 *               difficulty:
 *                 type: string
 *                 enum: [EASY, MEDIUM, HARD]
 *               courseType:
 *                 type: string
 *                 enum: [free, paid]
 *               courseImageUrl:
 *                 type: string
 *               isActive:
 *                 type: boolean
 *               contents:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     contentType:
 *                       type: string
 *                       enum: [text, image, audio, video, link]
 *                     content:
 *                       type: string
 *                     title:
 *                       type: string
 *                     displayOrder:
 *                       type: integer
 *     responses:
 *       201:
 *         description: Course created successfully
 *       400:
 *         description: Validation failed
 *       500:
 *         description: Internal server error
 */
router.post(
  '/',
  authenticateToken,
  [
    body('title').trim().isLength({ min: 3, max: 255 }).withMessage('Title must be between 3 and 255 characters'),
    body('difficulty').optional().isIn(['EASY', 'MEDIUM', 'HARD']).withMessage('Invalid difficulty'),
    body('courseType').optional().isIn(['free', 'paid']).withMessage('Invalid course type'),
    body('contents').optional().isArray().withMessage('Contents must be an array')
  ],
  (req, res) => courseController.createCourse(req, res)
);

/**
 * @swagger
 * /api/courses/{id}:
 *   put:
 *     summary: Update a course (Admin only)
 *     tags: [Courses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Course ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               category:
 *                 type: string
 *               difficulty:
 *                 type: string
 *                 enum: [EASY, MEDIUM, HARD]
 *               courseType:
 *                 type: string
 *                 enum: [free, paid]
 *               courseImageUrl:
 *                 type: string
 *               isActive:
 *                 type: boolean
 *               contents:
 *                 type: array
 *     responses:
 *       200:
 *         description: Course updated successfully
 *       404:
 *         description: Course not found
 *       500:
 *         description: Internal server error
 */
router.put(
  '/:id',
  authenticateToken,
  [
    body('title').optional().trim().isLength({ min: 3, max: 255 }).withMessage('Title must be between 3 and 255 characters'),
    body('difficulty').optional().isIn(['EASY', 'MEDIUM', 'HARD']).withMessage('Invalid difficulty'),
    body('courseType').optional().isIn(['free', 'paid']).withMessage('Invalid course type'),
    body('contents').optional().isArray().withMessage('Contents must be an array')
  ],
  (req, res) => courseController.updateCourse(req, res)
);

/**
 * @swagger
 * /api/courses/{id}:
 *   delete:
 *     summary: Delete a course (Admin only)
 *     tags: [Courses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Course ID
 *     responses:
 *       200:
 *         description: Course deleted successfully
 *       404:
 *         description: Course not found
 *       500:
 *         description: Internal server error
 */
router.delete(
  '/:id',
  authenticateToken,
  (req, res) => courseController.deleteCourse(req, res)
);


/**
 * @swagger
 * /api/courses/{courseId}/enroll:
 *   post:
 *     summary: Enroll in a course
 *     tags: [Courses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: courseId
 *         required: true
 *         schema:
 *           type: string
 *         description: Course ID
 *     responses:
 *       200:
 *         description: Successfully enrolled in course
 *       403:
 *         description: Access denied
 *       404:
 *         description: Course not found
 *       500:
 *         description: Internal server error
 */
router.post(
  '/:courseId/enroll',
  authenticateToken,
  (req, res) => courseController.enrollInCourse(req, res)
);

/**
 * @swagger
 * /api/courses/{courseId}/content/{contentId}/complete:
 *   post:
 *     summary: Mark course content as completed
 *     tags: [Courses]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: courseId
 *         required: true
 *         schema:
 *           type: string
 *         description: Course ID
 *       - in: path
 *         name: contentId
 *         required: true
 *         schema:
 *           type: string
 *         description: Course Content ID
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               timeSpent:
 *                 type: integer
 *                 description: Time spent in seconds
 *     responses:
 *       200:
 *         description: Content marked as completed
 *       404:
 *         description: Course content not found
 *       500:
 *         description: Internal server error
 */
router.post(
  '/:courseId/content/:contentId/complete',
  authenticateToken,
  (req, res) => courseController.markContentComplete(req, res)
);

module.exports = router;

