const Question = require('../models/Question');
const Exam = require('../models/Exam');
const { validationResult } = require('express-validator');
const { allQuestionCountsCache, CACHE_KEYS } = require('../utils/cache');

class QuestionController {
  /**
   * Get all questions for an exam
   */
  async getExamQuestions(req, res) {
    try {
      const { examId } = req.params;
      const userId = req.user.userId;

      // Check if user has global access to all exams
      const AccessCode = require('../models/AccessCode');
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
      const exam = await Exam.findByPk(examId);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      if (!exam.isActive) {
        return res.status(403).json({
          success: false,
          message: 'Exam is not active'
        });
      }

      // Get questions for the exam
      const questions = await Question.findAll({
        where: { examId: examId },
        order: [['createdAt', 'ASC']]
      });

      res.json({
        success: true,
        message: 'Questions retrieved successfully',
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
   * Create a new question for an exam
   */
  async createQuestion(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { examId, questionText, questionType, options, correctAnswer, explanation, imageUrl, questionImgUrl, difficulty, points } = req.body;

      // Check if exam exists
      const exam = await Exam.findByPk(examId);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      // Create question
      const question = await Question.create({
        examId: examId,
        questionText: questionText,
        questionType: questionType || 'MULTIPLE_CHOICE',
        options: options,
        correctAnswer: correctAnswer,
        explanation: explanation,
        imageUrl: imageUrl,
        questionImgUrl: questionImgUrl,
        difficulty: difficulty || 'MEDIUM',
        points: points || 1
      });

      // Update exam question count
      const questionCount = await Question.count({ where: { examId: examId } });
      await exam.update({ questionCount: questionCount });

      // Invalidate question count cache
      allQuestionCountsCache.delete(CACHE_KEYS.ALL_QUESTION_COUNTS);
      console.log('📦 Invalidated question counts cache after creating question');

      res.status(201).json({
        success: true,
        message: 'Question created successfully',
        data: question
      });

    } catch (error) {
      console.error('Create question error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Update a question
   */
  async updateQuestion(req, res) {
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

      const question = await Question.findByPk(id);
      if (!question) {
        return res.status(404).json({
          success: false,
          message: 'Question not found'
        });
      }

      // Update question
      await question.update(updateData);

      res.json({
        success: true,
        message: 'Question updated successfully',
        data: question
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
   * Delete a question
   */
  async deleteQuestion(req, res) {
    try {
      const { id } = req.params;

      const question = await Question.findByPk(id);
      if (!question) {
        return res.status(404).json({
          success: false,
          message: 'Question not found'
        });
      }

      const examId = question.examId;
      
      // Delete question
      await question.destroy();

      // Update exam question count
      const exam = await Exam.findByPk(examId);
      if (exam) {
        const questionCount = await Question.count({ where: { examId: examId } });
        await exam.update({ questionCount: questionCount });
      }

      // Invalidate question count cache
      allQuestionCountsCache.delete(CACHE_KEYS.ALL_QUESTION_COUNTS);
      console.log('📦 Invalidated question counts cache after deleting question');

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
   * Get question by ID
   */
  async getQuestionById(req, res) {
    try {
      const { id } = req.params;

      const question = await Question.findByPk(id, {
        include: [{
          model: Exam,
          attributes: ['id', 'title', 'category', 'difficulty']
        }]
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
   * Bulk create questions for an exam
   */
  async bulkCreateQuestions(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { examId, questions } = req.body;

      // Check if exam exists
      const exam = await Exam.findByPk(examId);
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
          examId: examId,
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
      const questionCount = await Question.count({ where: { examId: examId } });
      await exam.update({ questionCount: questionCount });

      // Invalidate question count cache
      allQuestionCountsCache.delete(CACHE_KEYS.ALL_QUESTION_COUNTS);
      console.log('📦 Invalidated question counts cache after bulk creating questions');

      res.status(201).json({
        success: true,
        message: `${createdQuestions.length} questions created successfully`,
        data: {
          examId: examId,
          questionCount: questionCount,
          questions: createdQuestions
        }
      });

    } catch (error) {
      console.error('Bulk create questions error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
}

module.exports = new QuestionController();
