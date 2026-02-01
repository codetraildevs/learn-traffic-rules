const Exam = require('../models/Exam');
const Question = require('../models/Question');
const AccessCode = require('../models/AccessCode');
const ExamResult = require('../models/ExamResult');
const { validationResult } = require('express-validator');
const path = require('path');
const fs = require('fs');
const csv = require('csv-parser');
const xlsx = require('xlsx');
const { withQueryTimeout } = require('../utils/dbRetry');
const { allQuestionCountsCache, CACHE_KEYS } = require('../utils/cache');
const { sequelize } = require('../config/database');

/**
 * Get all question counts in a single query (replaces N+1 pattern)
 * Standalone function to avoid 'this' context loss when passed to Express routes
 * @returns {Promise<Map>} Map of examId -> questionCount
 */
async function getQuestionCountsMap(examIds) {
  const cacheKey = CACHE_KEYS.ALL_QUESTION_COUNTS;
  const cached = allQuestionCountsCache.get(cacheKey);
  if (cached) {
    console.log('📦 Using cached question counts');
    return cached;
  }

  try {
    const questionCounts = await withQueryTimeout(
      () => Question.findAll({
        attributes: [
          'examId',
          [sequelize.fn('COUNT', sequelize.col('id')), 'count']
        ],
        group: ['examId'],
        raw: true
      }),
      15000,
      'Get all question counts'
    );

    const countMap = new Map();
    questionCounts.forEach(q => {
      countMap.set(q.examId, parseInt(q.count) || 0);
    });

    allQuestionCountsCache.set(cacheKey, countMap);
    console.log(`✅ Cached ${countMap.size} question counts`);

    return countMap;
  } catch (error) {
    console.error('❌ Failed to get question counts:', error.message);
    return new Map();
  }
}

/**
 * Parse CSV file and extract questions
 * Standalone function to avoid 'this' context loss when passed to Express routes
 */
async function parseCSVFile(filePath) {
  return new Promise((resolve, reject) => {
    const questions = [];

    fs.createReadStream(filePath)
      .pipe(csv())
      .on('data', (row) => {
        if (row.question && row.correctAnswer && row.option1 && row.option2) {
          questions.push({
            question: row.question.trim(),
            option1: row.option1.trim(),
            option2: row.option2.trim(),
            option3: row.option3 ? row.option3.trim() : '',
            option4: row.option4 ? row.option4.trim() : '',
            correctAnswer: row.correctAnswer.trim(),
            questionImgUrl: row.questionImgUrl ? row.questionImgUrl.trim() : '',
            points: parseInt(row.points) || 1
          });
        }
      })
      .on('end', () => resolve(questions))
      .on('error', (error) => reject(error));
  });
}

/**
 * Parse Excel file and extract questions
 * Standalone function to avoid 'this' context loss when passed to Express routes
 */
async function parseExcelFile(filePath) {
  const workbook = xlsx.readFile(filePath);
  const sheetName = workbook.SheetNames[0];
  const worksheet = workbook.Sheets[sheetName];
  const data = xlsx.utils.sheet_to_json(worksheet);

  const questions = [];

  for (const row of data) {
    if (row.question && row.correctAnswer && row.option1 && row.option2) {
      questions.push({
        question: row.question.trim(),
        option1: row.option1.trim(),
        option2: row.option2.trim(),
        option3: row.option3 ? row.option3.trim() : '',
        option4: row.option4 ? row.option4.trim() : '',
        correctAnswer: row.correctAnswer.trim(),
        questionImgUrl: row.questionImgUrl ? row.questionImgUrl.trim() : '',
        points: parseInt(row.points) || 1
      });
    }
  }

  return questions;
}

class ExamController {
  /**
   * Get all active exams
   */
  async getAllExams(req, res) {
    try {
      const { examType } = req.query;
      
      // Build where clause
      const whereClause = { isActive: true };
      if (examType) {
        // Filter by exam type (case-insensitive)
        whereClause.examType = examType.toLowerCase();
      }
      
      // Use timeout to prevent hanging queries
      let exams;
      try {
        exams = await withQueryTimeout(
          () => Exam.findAll({
            where: whereClause,
            order: [['createdAt', 'DESC']]
          }),
          20000,  // 20 second timeout
          'Get all exams'
        );
      } catch (timeoutError) {
        console.error(`❌ GET EXAMS TIMEOUT: ${timeoutError.message}`);
        return res.status(503).json({
          success: false,
          message: 'Service temporarily unavailable. Please try again.',
          retryAfter: 5
        });
      }

      // Get all question counts in a SINGLE query (instead of N+1 queries)
      const questionCountMap = await getQuestionCountsMap(exams.map(e => e.id));

      // Apply question counts to exams - O(1) lookup per exam
      const examsWithQuestionCounts = exams.map(exam => {
        const examData = exam.toJSON();
        examData.questionCount = questionCountMap.get(exam.id) || 0;
        
        // Ensure examType is never null - default to 'kinyarwanda' if missing
        if (!examData.examType) {
          examData.examType = 'kinyarwanda';
        }
        
        return examData;
      });

      // Convert relative image URLs to full URLs
      const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
      const examsWithFullUrls = examsWithQuestionCounts.map(examData => {
        if (examData.examImgUrl && !examData.examImgUrl.startsWith('http')) {
          // If it's just a filename (e.g., "exam1.png"), construct the full path
          if (!examData.examImgUrl.startsWith('/') && !examData.examImgUrl.startsWith('uploads/')) {
            examData.examImgUrl = `${baseUrl}/uploads/images-exams/${examData.examImgUrl}`;
          } else if (examData.examImgUrl.startsWith('/uploads/')) {
            examData.examImgUrl = `${baseUrl}${examData.examImgUrl}`;
          } else if (examData.examImgUrl.startsWith('uploads/')) {
            examData.examImgUrl = `${baseUrl}/${examData.examImgUrl}`;
          }
        }
        return examData;
      });

      res.json({
        success: true,
        message: 'Exams retrieved successfully',
        data: examsWithFullUrls
      });
    } catch (error) {
      console.error('Get exams error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get exam by ID
   */
  async getExamById(req, res) {
    try {
      const { id } = req.params;
      
      const exam = await Exam.findByPk(id);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      // Get question count
      const questionCount = await Question.count({
        where: { examId: exam.id }
      });

      // Convert relative image URL to full URL and add question count
      const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
      const examData = exam.toJSON();
      if (examData.examImgUrl && !examData.examImgUrl.startsWith('http')) {
        // If it's just a filename (e.g., "exam1.png"), construct the full path
        if (!examData.examImgUrl.startsWith('/') && !examData.examImgUrl.startsWith('uploads/')) {
          examData.examImgUrl = `${baseUrl}/uploads/images-exams/${examData.examImgUrl}`;
        } else if (examData.examImgUrl.startsWith('/uploads/')) {
          examData.examImgUrl = `${baseUrl}${examData.examImgUrl}`;
        } else if (examData.examImgUrl.startsWith('uploads/')) {
          examData.examImgUrl = `${baseUrl}/${examData.examImgUrl}`;
        }
      }
      // Add question count
      examData.questionCount = questionCount;

      res.json({
        success: true,
        message: 'Exam retrieved successfully',
        data: examData
      });
    } catch (error) {
      console.error('Get exam error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get exam questions (requires access)
   */
  async getExamQuestions(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.userId;

      // Check if user has global access to all exams
      const hasAccess = await AccessCode.findOne({
        where: {
          userId: userId,
          isUsed: false,
          expiresAt: {
            [require('sequelize').Op.gt]: new Date()
          }
        }
      });

      if (!hasAccess) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. Please purchase access to all exams first.'
        });
      }

      // Get exam details
      const exam = await Exam.findByPk(id);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      // Get questions
      const questions = await Question.findAll({
        where: { examId: id },
        order: [['questionOrder', 'ASC']],
        attributes: ['id', 'question', 'option1', 'option2', 'option3', 'option4', 'correctAnswer', 'points', 'questionImgUrl', 'questionOrder']
      });

      res.json({
        success: true,
        message: 'Exam questions retrieved successfully',
        data: questions
      });
    } catch (error) {
      console.error('Get exam questions error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get exam questions for taking (regular users)
   * OPTIMIZED: Added timeout wrappers and parallel queries where possible
   */
  async getExamQuestionsForTaking(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.userId;
      const { Op } = require('sequelize');

      console.log('🔍 GET EXAM QUESTIONS FOR TAKING:', { examId: id, userId });

      // Get exam details with timeout
      let exam;
      try {
        exam = await withQueryTimeout(
          () => Exam.findByPk(id),
          15000, // 15s - allow more time when DB is under load
          'Get exam by ID'
        );
      } catch (timeoutError) {
        console.error(`❌ GET EXAM TIMEOUT: ${timeoutError.message}`);
        return res.status(503).json({
          success: false,
          message: 'Service temporarily unavailable. Please try again.',
          retryAfter: 5
        });
      }
      
      if (!exam) {
        console.log('❌ Exam not found');
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      // Run access check and same-type exam query in PARALLEL (both needed for access decision)
      const examType = exam.examType || 'english';
      
      let hasAccess, examsOfSameType;
      try {
        [hasAccess, examsOfSameType] = await withQueryTimeout(
          () => Promise.all([
            AccessCode.findOne({
              where: {
                userId: userId,
                isUsed: false,
                expiresAt: { [Op.gt]: new Date() }
              }
            }),
            Exam.findAll({
              where: { 
                isActive: true,
                [Op.or]: [
                  { examType: examType },
                  ...(examType === 'english' ? [{ examType: null }] : [])
                ]
              },
              order: [['createdAt', 'ASC']],
              attributes: ['id'],
              limit: 1
            })
          ]),
          20000, // 20s for parallel queries under load
          'Access check and first exam lookup'
        );
      } catch (timeoutError) {
        console.error(`❌ ACCESS CHECK TIMEOUT: ${timeoutError.message}`);
        return res.status(503).json({
          success: false,
          message: 'Service temporarily unavailable. Please try again.',
          retryAfter: 5
        });
      }

      console.log('   Has access code:', !!hasAccess);

      // Check if current exam is the first exam of this type
      const isFirstOneExam = examsOfSameType.length > 0 && examsOfSameType[0].id === id;
      console.log('   Is first exam of type:', isFirstOneExam);

      // Allow access if user has paid access OR if it's the first exam of this type
      if (!hasAccess && !isFirstOneExam) {
        console.log('❌ No access to this exam');
        return res.status(403).json({
          success: false,
          message: `This exam requires payment. First ${examType} exam is free with unlimited attempts.`
        });
      }

      // Get questions with timeout
      let questions;
      try {
        questions = await withQueryTimeout(
          () => Question.findAll({
            where: { examId: id },
            order: [['questionOrder', 'ASC']],
            attributes: ['id', 'question', 'option1', 'option2', 'option3', 'option4', 'correctAnswer', 'points', 'questionImgUrl', 'questionOrder']
          }),
          20000, // 20s under load
          'Get exam questions'
        );
      } catch (timeoutError) {
        console.error(`❌ GET QUESTIONS TIMEOUT: ${timeoutError.message}`);
        return res.status(503).json({
          success: false,
          message: 'Service temporarily unavailable. Please try again.',
          retryAfter: 5
        });
      }

      console.log('   Questions found:', questions.length);

      if (questions.length === 0) {
        console.log('❌ No questions available for this exam');
        return res.status(400).json({
          success: false,
          message: 'No questions available for this exam'
        });
      }

      // Format questions for frontend
      const formattedQuestions = questions.map(q => ({
        id: q.id,
        examId: q.examId,
        questionText: q.question,
        options: [q.option1, q.option2, q.option3, q.option4].filter(opt => opt && opt.trim() !== ''),
        correctAnswer: q.correctAnswer,
        questionImgUrl: q.questionImgUrl,
        points: q.points || 1,
        createdAt: q.createdAt,
        updatedAt: q.updatedAt
      }));

      console.log('✅ Successfully formatted questions:', formattedQuestions.length);
      console.log('   First question sample:', formattedQuestions[0] ? {
        id: formattedQuestions[0].id,
        questionText: formattedQuestions[0].questionText?.substring(0, 50) + '...',
        optionsCount: formattedQuestions[0].options.length
      } : 'No questions');

      res.json({
        success: true,
        message: 'Exam questions retrieved successfully',
        data: formattedQuestions
      });
    } catch (error) {
      console.error('Get exam questions for taking error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Add questions to an exam (Admin/Manager only)
   */
  async addQuestionsToExam(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { id } = req.params;
      const { questions } = req.body;

      // Check if exam exists
      const exam = await Exam.findByPk(id);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      // Validate questions array
      if (!Array.isArray(questions) || questions.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Questions array is required and must not be empty'
        });
      }

      // Create questions
      const createdQuestions = [];
      for (const questionData of questions) {
        const question = await Question.create({
          examId: id,
          question: questionData.question,
          option1: questionData.option1,
          option2: questionData.option2,
          option3: questionData.option3,
          option4: questionData.option4,
          correctAnswer: questionData.correctAnswer,
          questionImgUrl: questionData.questionImgUrl || '',
          points: questionData.points || 1
        });
        createdQuestions.push(question);
      }

      // Update exam question count
      const questionCount = await Question.count({ where: { examId: id } });
      await exam.update({ questionCount: questionCount });

      // Invalidate question count cache
      allQuestionCountsCache.delete(CACHE_KEYS.ALL_QUESTION_COUNTS);
      console.log('📦 Invalidated question counts cache after adding questions');

      res.status(201).json({
        success: true,
        message: `${createdQuestions.length} questions added to exam successfully`,
        data: {
          examId: id,
          questionCount: questionCount,
          questions: createdQuestions
        }
      });

    } catch (error) {
      console.error('Add questions to exam error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Create new exam (Admin/Manager only)
   */
  async createExam(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const {
        title,
        description,
        category,
        difficulty,
        duration,
        questionCount,
        passingScore,
        examImgUrl,
        examType
      } = req.body;

      // Validate examType if provided
      const validExamTypes = ['kinyarwanda', 'english', 'french'];
      const finalExamType = examType && validExamTypes.includes(examType.toLowerCase())
        ? examType.toLowerCase()
        : 'english'; // Default to english

      const exam = await Exam.create({
        title,
        description,
        category,
        difficulty,
        duration,
        questionCount,
        passingScore,
        examImgUrl,
        examType: finalExamType,
        isActive: true
      });

      res.status(201).json({
        success: true,
        message: 'Exam created successfully',
        data: exam
      });
    } catch (error) {
      console.error('Create exam error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Update exam (Admin/Manager only)
   */
  async updateExam(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { id } = req.params;
      const {
        title,
        description,
        category,
        difficulty,
        duration,
        questionCount,
        passingScore,
        examImgUrl,
        examType,
        isActive
      } = req.body;

      const exam = await Exam.findByPk(id);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      // Validate examType if provided
      const validExamTypes = ['kinyarwanda', 'english', 'french'];
      let finalExamType = exam.examType; // Keep existing if not provided
      
      if (examType !== undefined && examType !== null) {
        if (validExamTypes.includes(examType.toLowerCase())) {
          finalExamType = examType.toLowerCase();
        } else {
          // Invalid examType provided, use default
          finalExamType = 'english';
        }
      } else if (!finalExamType) {
        // No examType in request and exam doesn't have one, set default
        finalExamType = 'english';
      }

      // Build update data
      const updateData = {
        title,
        description,
        category,
        difficulty,
        duration,
        questionCount,
        passingScore,
        examImgUrl,
        examType: finalExamType,
        isActive
      };

      // Remove undefined fields
      Object.keys(updateData).forEach(key => {
        if (updateData[key] === undefined) {
          delete updateData[key];
        }
      });

      await exam.update(updateData);

      // Reload exam to get updated data
      await exam.reload();

      res.json({
        success: true,
        message: 'Exam updated successfully',
        data: exam
      });
    } catch (error) {
      console.error('Update exam error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Activate exam (Admin/Manager only)
   */
  async activateExam(req, res) {
    try {
      const { id } = req.params;

      const exam = await Exam.findByPk(id);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      await exam.update({ isActive: true });

      res.json({
        success: true,
        message: 'Exam activated successfully',
        data: exam
      });
    } catch (error) {
      console.error('Activate exam error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Deactivate exam (Admin/Manager only)
   */
  async deactivateExam(req, res) {
    try {
      const { id } = req.params;

      const exam = await Exam.findByPk(id);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      await exam.update({ isActive: false });

      res.json({
        success: true,
        message: 'Exam deactivated successfully',
        data: exam
      });
    } catch (error) {
      console.error('Deactivate exam error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Toggle exam active status
   */
  async toggleExamStatus(req, res) {
    try {
      const { id } = req.params;
      
      const exam = await Exam.findByPk(id);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      // Toggle the isActive status
      exam.isActive = !exam.isActive;
      await exam.save();

      res.json({
        success: true,
        message: `Exam ${exam.isActive ? 'activated' : 'deactivated'} successfully`,
        data: exam
      });
    } catch (error) {
      console.error('Toggle exam status error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Delete an exam
   */
  async deleteExam(req, res) {
    try {
      const { id } = req.params;
      
      const exam = await Exam.findByPk(id);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      // Delete associated questions first
      await Question.destroy({
        where: { examId: id }
      });

      // Delete the exam
      await exam.destroy();

      // Invalidate question count cache
      allQuestionCountsCache.delete(CACHE_KEYS.ALL_QUESTION_COUNTS);
      console.log('📦 Invalidated question counts cache after deleting exam');

      res.json({
        success: true,
        message: 'Exam deleted successfully'
      });
    } catch (error) {
      console.error('Delete exam error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Submit exam answers and get results
   */
  async submitExam(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { examId, answers, timeSpent } = req.body;
      const userId = req.user.userId;

      // Check if user has global access to all exams
      const hasAccess = await AccessCode.findOne({
        where: {
          userId: userId,
          isUsed: false,
          expiresAt: {
            [require('sequelize').Op.gt]: new Date()
          }
        }
      });

      if (!hasAccess) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. Please purchase access to all exams first.'
        });
      }

      // Get exam and questions
      const exam = await Exam.findByPk(examId);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      const questions = await Question.findAll({
        where: { examId: examId }
      });

      // Calculate score
      let correctAnswers = 0;
      const totalQuestions = questions.length;
      const userAnswers = {};

      for (const question of questions) {
        const userAnswer = answers[question.id];
        userAnswers[question.id] = userAnswer;
        
        if (userAnswer === question.correctAnswer) {
          correctAnswers++;
        }
      }

      const score = Math.round((correctAnswers / totalQuestions) * 100);
      const passed = score >= exam.passingScore;

      // Create exam result
      const examResult = await ExamResult.create({
        userId: userId,
        examId: examId,
        score: score,
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        incorrectAnswers: totalQuestions - correctAnswers,
        timeSpent: timeSpent,
        passed: passed,
        answers: userAnswers
      });

      // Mark access code as used
      await hasAccess.update({ 
        isUsed: true, 
        usedAt: new Date() 
      });

      res.json({
        success: true,
        message: 'Exam submitted successfully',
        data: {
          result: examResult,
          passed: passed,
          score: score,
          passingScore: exam.passingScore
        }
      });
    } catch (error) {
      console.error('Submit exam error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Submit exam result (for both free and paid exams)
   * OPTIMIZED: Reduced redundant queries, added timeouts, parallel queries
   */
  async submitExamResult(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { examId, answers, timeSpent, isFreeExam } = req.body;
      const userId = req.user.userId;
      const { Op } = require('sequelize');

      console.log('🔍 SUBMIT EXAM RESULT:', { examId, userId, timeSpent, isFreeExam });

      // OPTIMIZED: Fetch exam, questions, access check, and first exam of type in PARALLEL
      let exam, questions, hasAccess, firstExamOfType;
      try {
        const examType = 'english'; // Default, will be refined after exam fetch
        
        [exam, questions] = await withQueryTimeout(
          () => Promise.all([
            Exam.findByPk(examId),
            Question.findAll({ where: { examId: examId } })
          ]),
          25000, // 25s - allow more time when DB is under load
          'Get exam and questions'
        );

        if (!exam) {
          console.log('❌ Exam not found for ID:', examId);
          return res.status(404).json({
            success: false,
            message: 'Exam not found'
          });
        }

        // Now fetch access check and first exam of type in parallel
        const actualExamType = exam.examType || 'english';
        [hasAccess, firstExamOfType] = await withQueryTimeout(
          () => Promise.all([
            AccessCode.findOne({
              where: {
                userId: userId,
                isUsed: false,
                expiresAt: { [Op.gt]: new Date() }
              }
            }),
            Exam.findOne({
              where: { 
                isActive: true,
                [Op.or]: [
                  { examType: actualExamType },
                  ...(actualExamType === 'english' ? [{ examType: null }] : [])
                ]
              },
              order: [['createdAt', 'ASC']],
              attributes: ['id']
            })
          ]),
          15000, // 15s
          'Access check and first exam lookup'
        );
      } catch (timeoutError) {
        console.error(`❌ SUBMIT EXAM TIMEOUT: ${timeoutError.message}`);
        return res.status(503).json({
          success: false,
          message: 'Service temporarily unavailable. Please try again.',
          retryAfter: 5
        });
      }

      console.log('   Exam found:', exam.title, '| Questions:', questions.length);

      const isFirstOneExam = firstExamOfType && firstExamOfType.id === examId;
      console.log('   Is first exam:', isFirstOneExam, '| Has access:', !!hasAccess);

      // Allow if it's the first exam of this type OR if user has paid access
      if (!isFirstOneExam && !hasAccess) {
        const examType = exam.examType || 'english';
        return res.status(403).json({
          success: false,
          message: `This exam requires payment. First ${examType} exam is free with unlimited attempts.`
        });
      }

      if (questions.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'No questions found for this exam'
        });
      }

      // Calculate score and create detailed question results
      let correctAnswers = 0;
      const totalQuestions = questions.length;
      const userAnswers = {};
      const questionResults = [];

      for (const question of questions) {
        const userAnswer = answers[question.id];
        userAnswers[question.id] = userAnswer;

        const isCorrect = userAnswer === question.correctAnswer;
        if (isCorrect) {
          correctAnswers++;
        }

        questionResults.push({
          questionId: question.id,
          questionText: question.question,
          options: {
            a: question.option1,
            b: question.option2,
            c: question.option3,
            d: question.option4
          },
          userAnswer: userAnswer || 'No answer',
          userAnswerLetter: userAnswer ? userAnswer.charAt(0) : 'No answer',
          correctAnswer: question.correctAnswer,
          correctAnswerLetter: question.correctAnswer === question.option1 ? 'a' : 
                              question.correctAnswer === question.option2 ? 'b' :
                              question.correctAnswer === question.option3 ? 'c' :
                              question.correctAnswer === question.option4 ? 'd' : 'Unknown',
          isCorrect: isCorrect,
          points: isCorrect ? (question.points || 1) : 0,
          questionImgUrl: question.questionImgUrl
        });
      }

      const score = Math.round((correctAnswers / totalQuestions) * 100);
      const passed = score >= exam.passingScore;

      console.log('📊 Score:', score, '| Passed:', passed, '| Correct:', correctAnswers, '/', totalQuestions);

      // Create exam result with timeout
      let examResult;
      try {
        examResult = await withQueryTimeout(
          () => ExamResult.create({
            userId: userId,
            examId: examId,
            score: score,
            totalQuestions: totalQuestions,
            correctAnswers: correctAnswers,
            timeSpent: timeSpent,
            passed: passed,
            isFreeExam: isFreeExam,
            answers: userAnswers,
            questionResults: questionResults,
            completedAt: new Date()
          }),
          60000, // 60s - ExamResult.create with large JSON can be slow under load
          'Create exam result'
        );
      } catch (timeoutError) {
        console.error(`❌ CREATE RESULT TIMEOUT: ${timeoutError.message}`);
        return res.status(503).json({
          success: false,
          message: 'Service temporarily unavailable. Please try again.',
          retryAfter: 5
        });
      }

      const responseData = {
        id: examResult.id,
        examId: examResult.examId,
        userId: examResult.userId,
        score: examResult.score,
        totalQuestions: examResult.totalQuestions,
        correctAnswers: examResult.correctAnswers,
        timeSpent: examResult.timeSpent,
        passed: examResult.passed,
        isFreeExam: examResult.isFreeExam,
        submittedAt: examResult.createdAt,
        questionResults: questionResults
      };

      console.log('✅ Exam result created:', examResult.id);

      res.json({
        success: true,
        message: 'Exam submitted successfully',
        data: responseData
      });
    } catch (error) {
      console.error('Submit exam result error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }


  /**
   * Upload exam image
   */
  async uploadExamImage(req, res) {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'No image file provided'
        });
      }

      const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
      const imageUrl = `${baseUrl}/uploads/${req.file.filename}`;
      
      console.log('📸 UPLOAD SUCCESS: Image uploaded');
      console.log('   Filename:', req.file.filename);
      console.log('   Image URL:', imageUrl);
      
      res.json({
        success: true,
        message: 'Image uploaded successfully',
        imageUrl: imageUrl
      });
    } catch (error) {
      console.error('Upload image error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Upload question image
   */
  async uploadQuestionImage(req, res) {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'No image file provided'
        });
      }

      const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
      const imageUrl = `${baseUrl}/uploads/question-images/${req.file.filename}`;
      
      console.log('📸 QUESTION IMAGE UPLOAD: Image uploaded');
      console.log('   Filename:', req.file.filename);
      console.log('   Image URL:', imageUrl);
      
      res.json({
        success: true,
        message: 'Question image uploaded successfully',
        imageUrl: imageUrl
      });
    } catch (error) {
      console.error('Upload question image error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get all questions for an exam
   */
  async getExamQuestions(req, res) {
    try {
      const { id } = req.params;
      const { page = 1, limit = 50 } = req.query;

      // Check if exam exists
      const exam = await Exam.findByPk(id);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      const offset = (page - 1) * limit;
      const questions = await Question.findAndCountAll({
        where: { examId: id },
        order: [['createdAt', 'DESC']],
        limit: parseInt(limit),
        offset: parseInt(offset)
      });

      res.json({
        success: true,
        message: 'Questions retrieved successfully',
        data: {
          questions: questions.rows,
          pagination: {
            currentPage: parseInt(page),
            totalPages: Math.ceil(questions.count / limit),
            totalQuestions: questions.count,
            hasNext: offset + questions.rows.length < questions.count,
            hasPrev: page > 1
          }
        }
      });
    } catch (error) {
      console.error('Get exam questions error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get single question by ID
   */
  async getQuestionById(req, res) {
    try {
      const { id, questionId } = req.params;

      // Check if exam exists
      const exam = await Exam.findByPk(id);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      const question = await Question.findOne({
        where: { 
          id: questionId,
          examId: id 
        }
      });

      if (!question) {
        return res.status(404).json({
          success: false,
          message: 'Question not found'
        });
      }

      res.json({
        success: true,
        message: 'Question retrieved successfully',
        data: question
      });
    } catch (error) {
      console.error('Get question error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Update question
   */
  async updateQuestion(req, res) {
    try {
      const { id, questionId } = req.params;
      const { question, option1, option2, option3, option4, correctAnswer, points } = req.body;

      // Check if exam exists
      const exam = await Exam.findByPk(id);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      // Find question
      const existingQuestion = await Question.findOne({
        where: { 
          id: questionId,
          examId: id 
        }
      });

      if (!existingQuestion) {
        return res.status(404).json({
          success: false,
          message: 'Question not found'
        });
      }

      // Handle question image upload - check both file upload and URL from body
      let questionImgUrl = existingQuestion.questionImgUrl;
      if (req.file) {
        // Image uploaded via multipart form
        const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
        questionImgUrl = `${baseUrl}/uploads/question-images/${req.file.filename}`;
        console.log('📸 QUESTION IMAGE UPDATE: Image uploaded via multipart');
        console.log('   Filename:', req.file.filename);
        console.log('   Image URL:', questionImgUrl);
      } else if (req.body.questionImgUrl !== undefined) {
        // Image URL provided in body (or null to remove image)
        questionImgUrl = req.body.questionImgUrl || null;
        console.log('📸 QUESTION IMAGE UPDATE: Image URL provided in body');
        console.log('   Image URL:', questionImgUrl || '(removed)');
      }

      // Update question
      await existingQuestion.update({
        question: question ? question.trim() : existingQuestion.question,
        option1: option1 ? option1.trim() : existingQuestion.option1,
        option2: option2 ? option2.trim() : existingQuestion.option2,
        option3: option3 ? option3.trim() : existingQuestion.option3,
        option4: option4 ? option4.trim() : existingQuestion.option4,
        correctAnswer: correctAnswer ? correctAnswer.trim() : existingQuestion.correctAnswer,
        questionImgUrl: questionImgUrl,
        points: points || existingQuestion.points
      });

      res.json({
        success: true,
        message: 'Question updated successfully',
        data: existingQuestion
      });
    } catch (error) {
      console.error('Update question error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Delete question
   */
  async deleteQuestion(req, res) {
    try {
      const { id, questionId } = req.params;

      // Check if exam exists
      const exam = await Exam.findByPk(id);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      // Find and delete question
      const question = await Question.findOne({
        where: { 
          id: questionId,
          examId: id 
        }
      });

      if (!question) {
        return res.status(404).json({
          success: false,
          message: 'Question not found'
        });
      }

      await question.destroy();

      res.json({
        success: true,
        message: 'Question deleted successfully'
      });
    } catch (error) {
      console.error('Delete question error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Upload single question
   */
  async uploadSingleQuestion(req, res) {
    try {
      const { id } = req.params;
      const { question, option1, option2, option3, option4, correctAnswer, points, questionImgUrl } = req.body;

      // Check if exam exists
      const exam = await Exam.findByPk(id);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      // Validate required fields
      if (!question || !option1 || !option2 || !correctAnswer) {
        return res.status(400).json({
          success: false,
          message: 'Question, option1, option2, and correctAnswer are required'
        });
      }

      // Handle question image upload - check both file upload and URL
      let finalQuestionImgUrl = '';
      if (req.file) {
        // Image uploaded via multipart form
        const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
        finalQuestionImgUrl = `${baseUrl}/uploads/question-images/${req.file.filename}`;
        console.log('📸 QUESTION IMAGE UPLOAD: Image uploaded via multipart');
        console.log('   Filename:', req.file.filename);
        console.log('   Image URL:', finalQuestionImgUrl);
      } else if (questionImgUrl) {
        // Image URL provided in body
        finalQuestionImgUrl = questionImgUrl;
        console.log('📸 QUESTION IMAGE UPLOAD: Image URL provided');
        console.log('   Image URL:', finalQuestionImgUrl);
      }

      // Create question
      const newQuestion = await Question.create({
        examId: id,
        question: question.trim(),
        option1: option1.trim(),
        option2: option2.trim(),
        option3: option3 ? option3.trim() : '',
        option4: option4 ? option4.trim() : '',
        correctAnswer: correctAnswer.trim(),
        questionImgUrl: finalQuestionImgUrl,
        points: points || 1
      });

      console.log('✅ QUESTION CREATED: Question saved to database');
      console.log('   Question ID:', newQuestion.id);

      // Invalidate question count cache
      allQuestionCountsCache.delete(CACHE_KEYS.ALL_QUESTION_COUNTS);
      console.log('📦 Invalidated question counts cache after uploading question');

      res.status(201).json({
        success: true,
        message: 'Question added successfully',
        data: newQuestion
      });
    } catch (error) {
      console.error('Upload single question error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Upload questions in bulk from CSV/Excel files
   */
  async uploadQuestions(req, res) {
    try {
      const { id } = req.params;
      
      if (!req.files || req.files.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'No files provided'
        });
      }

      // Check if exam exists
      const exam = await Exam.findByPk(id);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      let totalQuestionsAdded = 0;

      for (const file of req.files) {
        const filePath = file.path;
        const fileExtension = path.extname(file.originalname).toLowerCase();
        
        let questions = [];
        
        if (fileExtension === '.csv') {
          questions = await parseCSVFile(filePath);
        } else if (fileExtension === '.xlsx') {
          questions = await parseExcelFile(filePath);
        } else {
          continue; // Skip unsupported files
        }

        // Add questions to database
        for (const questionData of questions) {
          try {
            await Question.create({
              examId: id,
              question: questionData.question,
              option1: questionData.option1,
              option2: questionData.option2,
              option3: questionData.option3,
              option4: questionData.option4,
              correctAnswer: questionData.correctAnswer,
              questionImgUrl: questionData.questionImgUrl || '',
              points: questionData.points || 1
            });
            totalQuestionsAdded++;
          } catch (questionError) {
            console.error('Error adding question:', questionError);
          }
        }

        // Clean up uploaded file
        fs.unlinkSync(filePath);
      }

      // Invalidate question count cache if any questions were added
      if (totalQuestionsAdded > 0) {
        allQuestionCountsCache.delete(CACHE_KEYS.ALL_QUESTION_COUNTS);
        console.log('📦 Invalidated question counts cache after bulk upload');
      }

      res.json({
        success: true,
        message: 'Questions uploaded successfully',
        questionsAdded: totalQuestionsAdded
      });
    } catch (error) {
      console.error('Upload questions error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get user's exam results
   */
  async getUserExamResults(req, res) {
    try {
      const userId = req.user.userId;
      console.log('🔍 GET USER EXAM RESULTS DEBUG:');
      console.log('   User ID:', userId);

      // Use timeout to prevent hanging queries
      let results;
      try {
        results = await withQueryTimeout(
          () => ExamResult.findAll({
            where: { userId: userId },
            include: [
              {
                model: Exam,
                as: 'Exam',
                attributes: ['id', 'title', 'category', 'difficulty', 'imageUrl']
              }
            ],
            order: [['createdAt', 'DESC']],
            limit: 100,  // Limit results to prevent large queries
            attributes: [
              'id',
              'examId', 
              'userId',
              'score',
              'totalQuestions',
              'correctAnswers',
              'timeSpent',
              'passed',
              'isFreeExam',
              'submittedAt',
              'createdAt'
              // NOTE: questionResults excluded - too large for list view
              // Fetch individual result details when viewing specific exam result
            ]
          }),
          15000,  // 15s - much faster without questionResults
          'Get user exam results'
        );
      } catch (timeoutError) {
        console.error(`❌ GET USER RESULTS TIMEOUT: ${timeoutError.message}`);
        return res.status(503).json({
          success: false,
          message: 'Service temporarily unavailable. Please try again.',
          data: [],
          retryAfter: 5
        });
      }

      // Convert to plain objects to ensure associations are included
      const plainResults = results.map(result => result.get({ plain: true }));

      console.log('   Results found:', results.length);
      console.log('   Results:', results.map(r => ({ id: r.id, examId: r.examId, score: r.score })));
      
      // No need to parse questionResults since we excluded it
      const processedResults = plainResults;

      // Debug exam information (first 5 results only)
      processedResults.slice(0, 5).forEach((result, index) => {
        console.log(`   Result ${index + 1}/${results.length}:`);
        console.log(`     Exam ID: ${result.examId}`);
        console.log(`     Title: ${result.Exam?.title || 'No title'}`);
        console.log(`     Score: ${result.score}% (${result.correctAnswers}/${result.totalQuestions})`);
        console.log(`     Passed: ${result.passed ? 'Yes' : 'No'}`);
        console.log(`     Date: ${result.submittedAt || result.createdAt}`);
      });

      res.json({
        success: true,
        message: 'Exam results retrieved successfully',
        data: processedResults
      });
    } catch (error) {
      console.error('Get user exam results error:', error);
      
      // Check if it's an association error
      if (error.name === 'SequelizeEagerLoadingError' || error.message?.includes('not associated')) {
        console.error('❌ Association error detected. Ensure associations are set up before routes are loaded.');
        console.error('   Error details:', error.message);
        
        // Try to set up associations on the fly (fallback)
        try {
          const setupAssociations = require('../config/associations');
          setupAssociations();
          console.log('✅ Associations set up as fallback');
        } catch (setupError) {
          console.error('❌ Failed to set up associations:', setupError);
        }
      }
      
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
}

module.exports = new ExamController();
