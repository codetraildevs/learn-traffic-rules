const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const bulkUploadController = require('../controllers/bulkUploadController');
const authMiddleware = require('../middleware/authMiddleware');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['.csv', '.json'];
    const ext = path.extname(file.originalname).toLowerCase();
    
    if (allowedTypes.includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Only CSV and JSON files are allowed'), false);
    }
  }
});

/**
 * @swagger
 * /api/bulk-upload/exam/{examId}/questions/csv:
 *   post:
 *     summary: Upload questions from CSV file (Admin/Manager only)
 *     tags: [Bulk Upload]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: examId
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
 *               file:
 *                 type: string
 *                 format: binary
 *                 description: CSV file with questions
 *     responses:
 *       200:
 *         description: Questions uploaded successfully
 *       400:
 *         description: Bad request - invalid file or missing data
 *       404:
 *         description: Exam not found
 */
router.post('/exam/:examId/questions/csv',
  authMiddleware.authenticate,
  authMiddleware.requireManager,
  upload.single('file'),
  bulkUploadController.uploadQuestionsFromCSV
);

/**
 * @swagger
 * /api/bulk-upload/exam/{examId}/questions/json:
 *   post:
 *     summary: Upload questions from JSON file (Admin/Manager only)
 *     tags: [Bulk Upload]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: examId
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
 *               file:
 *                 type: string
 *                 format: binary
 *                 description: JSON file with questions
 *     responses:
 *       200:
 *         description: Questions uploaded successfully
 *       400:
 *         description: Bad request - invalid file or missing data
 *       404:
 *         description: Exam not found
 */
router.post('/exam/:examId/questions/json',
  authMiddleware.authenticate,
  authMiddleware.requireManager,
  upload.single('file'),
  bulkUploadController.uploadQuestionsFromJSON
);

/**
 * @swagger
 * /api/bulk-upload/template/csv:
 *   get:
 *     summary: Download CSV template for questions
 *     tags: [Bulk Upload]
 *     responses:
 *       200:
 *         description: CSV template downloaded
 *         content:
 *           text/csv:
 *             schema:
 *               type: string
 */
router.get('/template/csv', bulkUploadController.downloadCSVTemplate);

/**
 * @swagger
 * /api/bulk-upload/template/json:
 *   get:
 *     summary: Download JSON template for questions
 *     tags: [Bulk Upload]
 *     responses:
 *       200:
 *         description: JSON template downloaded
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 */
router.get('/template/json', bulkUploadController.downloadJSONTemplate);

module.exports = router;
