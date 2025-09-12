const Exam = require('../models/Exam');
const Question = require('../models/Question');
const AccessCode = require('../models/AccessCode');
const ExamResult = require('../models/ExamResult');
const { validationResult } = require('express-validator');

class ExamController {
  /**
   * Get all active exams
   */
  async getAllExams(req, res) {
    try {
      const exams = await Exam.findAll({
        where: { isActive: true },
        order: [['createdAt', 'DESC']]
      });

      res.json({
        success: true,
        message: 'Exams retrieved successfully',
        data: exams
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

      res.json({
        success: true,
        message: 'Exam retrieved successfully',
        data: exam
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
        order: [['createdAt', 'ASC']],
        attributes: ['id', 'question', 'options', 'difficulty', 'points']
      });

      res.json({
        success: true,
        message: 'Exam questions retrieved successfully',
        data: {
          exam: {
            id: exam.id,
            title: exam.title,
            description: exam.description,
            duration: exam.duration,
            questionCount: exam.questionCount,
            passingScore: exam.passingScore
          },
          questions: questions
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
          questionText: questionData.questionText,
          questionType: questionData.questionType || 'MULTIPLE_CHOICE',
          options: questionData.options,
          correctAnswer: questionData.correctAnswer,
          explanation: questionData.explanation,
          imageUrl: questionData.imageUrl,
          questionImgUrl: questionData.questionImgUrl,
          difficulty: questionData.difficulty || 'MEDIUM',
          points: questionData.points || 1
        });
        createdQuestions.push(question);
      }

      // Update exam question count
      const questionCount = await Question.count({ where: { examId: id } });
      await exam.update({ questionCount: questionCount });

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
        examImgUrl
      } = req.body;

      const exam = await Exam.create({
        title,
        description,
        category,
        difficulty,
        duration,
        questionCount,
        passingScore,
        examImgUrl,
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
      const updateData = req.body;

      const exam = await Exam.findByPk(id);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      await exam.update(updateData);

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
   * Get user's exam results
   */
  async getUserExamResults(req, res) {
    try {
      const userId = req.user.userId;

      const results = await ExamResult.findAll({
        where: { userId: userId },
        include: [{
          model: Exam,
          attributes: ['id', 'title', 'category', 'difficulty']
        }],
        order: [['createdAt', 'DESC']]
      });

      res.json({
        success: true,
        message: 'Exam results retrieved successfully',
        data: results
      });
    } catch (error) {
      console.error('Get exam results error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
}

module.exports = new ExamController();
