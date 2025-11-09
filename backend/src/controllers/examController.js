const Exam = require('../models/Exam');
const Question = require('../models/Question');
const AccessCode = require('../models/AccessCode');
const ExamResult = require('../models/ExamResult');
const { validationResult } = require('express-validator');
const path = require('path');
const fs = require('fs');
const csv = require('csv-parser');
const xlsx = require('xlsx');

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
      
      const exams = await Exam.findAll({
        where: whereClause,
        order: [['createdAt', 'DESC']]
      });

      // Get question counts for each exam
      const examsWithQuestionCounts = await Promise.all(
        exams.map(async (exam) => {
          const questionCount = await Question.count({
            where: { examId: exam.id }
          });
          
          const examData = exam.toJSON();
          examData.questionCount = questionCount;
          
          // Ensure examType is never null - default to 'english' if missing
          if (!examData.examType) {
            examData.examType = 'english';
          }
          
          return examData;
        })
      );

      // Convert relative image URLs to full URLs
      const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
      const examsWithFullUrls = examsWithQuestionCounts.map(examData => {
        if (examData.examImgUrl && !examData.examImgUrl.startsWith('http')) {
          // If it's a relative path, make it a full URL
          if (examData.examImgUrl.startsWith('/uploads/')) {
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
        // If it's a relative path, make it a full URL
        if (examData.examImgUrl.startsWith('/uploads/')) {
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
   */
  async getExamQuestionsForTaking(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.userId;

      console.log('🔍 GET EXAM QUESTIONS FOR TAKING DEBUG:');
      console.log('   Exam ID:', id);
      console.log('   User ID:', userId);
      console.log('   Request URL:', req.url);
      console.log('   Request Method:', req.method);

      // Get exam details
      const exam = await Exam.findByPk(id);
      console.log('   Exam found:', !!exam);
      if (exam) {
        console.log('   Exam title:', exam.title);
        console.log('   Exam active:', exam.isActive);
      }
      
      if (!exam) {
        console.log('❌ Exam not found');
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      // Check if user has access (either free or paid)
      const hasAccess = await AccessCode.findOne({
        where: {
          userId: userId,
          isUsed: false,
          expiresAt: {
            [require('sequelize').Op.gt]: new Date()
          }
        }
      });

      console.log('   Has access code:', !!hasAccess);
      if (hasAccess) {
        console.log('   Access code expires at:', hasAccess.expiresAt);
      }

      // Check if this is one of the first 2 exams (free with unlimited attempts)
      const allExams = await Exam.findAll({
        where: { isActive: true },
        order: [['createdAt', 'ASC']],
        attributes: ['id', 'title', 'createdAt']
      });

      console.log('   All active exams:', allExams.map(exam => ({ id: exam.id, title: exam.title, createdAt: exam.createdAt })));
      console.log('   First 2 exam IDs:', allExams.slice(0, 2).map(exam => exam.id));
      console.log('   Current exam ID:', id);

      const isFirstTwoExam = allExams.slice(0, 2).some(exam => exam.id === id);
      console.log('   Is first 2 exam:', isFirstTwoExam);
      
      // Additional debugging for exam access
      if (allExams.length >= 2) {
        console.log('   First exam:', { id: allExams[0].id, title: allExams[0].title });
        console.log('   Second exam:', { id: allExams[1].id, title: allExams[1].title });
      }

      // Allow access if user has paid access OR if it's one of the first 2 exams
      if (!hasAccess && !isFirstTwoExam) {
        console.log('❌ No access to this exam');
        return res.status(403).json({
          success: false,
          message: 'This exam requires payment. First 2 exams are free with unlimited attempts.'
        });
      }

      if (isFirstTwoExam) {
        console.log('✅ First 2 exam - allowing unlimited attempts');
      } else if (hasAccess) {
        console.log('✅ Paid user - allowing access');
      }

      // Get questions
      const questions = await Question.findAll({
        where: { examId: id },
        order: [['questionOrder', 'ASC']],
        attributes: ['id', 'question', 'option1', 'option2', 'option3', 'option4', 'correctAnswer', 'points', 'questionImgUrl', 'questionOrder']
      });

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

      console.log('🔍 SUBMIT EXAM RESULT DEBUG:');
      console.log('   Received examId:', examId);
      console.log('   Received userId:', userId);
      console.log('   Received answers:', answers);
      console.log('   Received timeSpent:', timeSpent);
      console.log('   Received isFreeExam:', isFreeExam);

      // Get exam
      const exam = await Exam.findByPk(examId);
      if (!exam) {
        console.log('❌ Exam not found for ID:', examId);
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }
      console.log('   Exam found:', exam.title);

      // Check if this is one of the first 2 exams (free with unlimited attempts)
      const allExams = await Exam.findAll({
        where: { isActive: true },
        order: [['createdAt', 'ASC']],
        attributes: ['id', 'title', 'createdAt']
      });

      console.log('   All active exams:', allExams.map(exam => ({ id: exam.id, title: exam.title, createdAt: exam.createdAt })));
      console.log('   First 2 exam IDs:', allExams.slice(0, 2).map(exam => exam.id));
      console.log('   Current exam ID:', examId);

      const isFirstTwoExam = allExams.slice(0, 2).some(exam => exam.id === examId);
      console.log('   Is first 2 exam:', isFirstTwoExam);
      
      // Additional debugging for exam access
      if (allExams.length >= 2) {
        console.log('   First exam:', { id: allExams[0].id, title: allExams[0].title });
        console.log('   Second exam:', { id: allExams[1].id, title: allExams[1].title });
      }

      // Check if user has paid access
      const hasAccess = await AccessCode.findOne({
        where: {
          userId: userId,
          isUsed: false,
          expiresAt: {
            [require('sequelize').Op.gt]: new Date()
          }
        }
      });

      // Allow if it's one of the first 2 exams OR if user has paid access
      if (!isFirstTwoExam && !hasAccess) {
        console.log('❌ No access to this exam');
        return res.status(403).json({
          success: false,
          message: 'This exam requires payment. First 2 exams are free with unlimited attempts.'
        });
      }

      if (isFirstTwoExam) {
        console.log('✅ First 2 exam - allowing unlimited attempts');
      } else if (hasAccess) {
        console.log('✅ Paid user - allowing access');
      }

      // Get questions
      const questions = await Question.findAll({
        where: { examId: examId }
      });

      console.log('   Questions found:', questions.length);

      if (questions.length === 0) {
        console.log('❌ No questions found for this exam');
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

      console.log('🔍 SCORE CALCULATION DEBUG:');
      console.log('   Total questions:', totalQuestions);
      console.log('   User answers received:', answers);

      for (const question of questions) {
        const userAnswer = answers[question.id];
        userAnswers[question.id] = userAnswer;

        // Compare user answer directly with correct answer
        const isCorrect = userAnswer === question.correctAnswer;
        if (isCorrect) {
          correctAnswers++;
        }

        // Create detailed question result
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

        console.log(`   Question ${question.id}:`);
        console.log(`     User answer: "${userAnswer}"`);
        console.log(`     Correct answer: "${question.correctAnswer}"`);
        console.log(`     Option A: "${question.option1}"`);
        console.log(`     Option B: "${question.option2}"`);
        console.log(`     Option C: "${question.option3}"`);
        console.log(`     Option D: "${question.option4}"`);
        console.log(`     Direct comparison: "${userAnswer}" === "${question.correctAnswer}" = ${isCorrect}`);
        console.log(`     User answer letter: ${userAnswer ? userAnswer.charAt(0) : 'No answer'}`);
        console.log(`     Correct answer letter: ${question.correctAnswer === question.option1 ? 'a' : 
                              question.correctAnswer === question.option2 ? 'b' :
                              question.correctAnswer === question.option3 ? 'c' :
                              question.correctAnswer === question.option4 ? 'd' : 'Unknown'}`);
      }

      const score = Math.round((correctAnswers / totalQuestions) * 100);
      const passed = score >= exam.passingScore;

      console.log('📊 FINAL SCORE CALCULATION:');
      console.log('   Correct answers:', correctAnswers);
      console.log('   Total questions:', totalQuestions);
      console.log('   Calculated score:', score);
      console.log('   Exam passing score:', exam.passingScore);
      console.log('   Passed:', passed);
      console.log('   Question results created:', questionResults.length);

      // Create exam result
      const examResult = await ExamResult.create({
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
      });

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

      console.log('📤 SENDING RESPONSE TO FRONTEND:');
      console.log('   Response data keys:', Object.keys(responseData));
      console.log('   Question results length:', questionResults.length);
      console.log('   Question results sample:', questionResults.slice(0, 2));
      console.log('   Full response data:', JSON.stringify(responseData, null, 2));

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

      // Handle question image upload
      let questionImgUrl = existingQuestion.questionImgUrl;
      if (req.file) {
        const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
        questionImgUrl = `${baseUrl}/uploads/question-images/${req.file.filename}`;
        console.log('📸 QUESTION IMAGE UPDATE: Image uploaded');
        console.log('   Filename:', req.file.filename);
        console.log('   Image URL:', questionImgUrl);
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
      console.log('   Image URL:', finalQuestionImgUrl);

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
          questions = await this.parseCSVFile(filePath);
        } else if (fileExtension === '.xlsx') {
          questions = await this.parseExcelFile(filePath);
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
   * Parse CSV file and extract questions
   */
  async parseCSVFile(filePath) {
    return new Promise((resolve, reject) => {
      const questions = [];
      
      fs.createReadStream(filePath)
        .pipe(csv())
        .on('data', (row) => {
          // Expected CSV format: question,option1,option2,option3,option4,correctAnswer,questionImgUrl,points
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
        .on('end', () => {
          resolve(questions);
        })
        .on('error', (error) => {
          reject(error);
        });
    });
  }

  /**
   * Parse Excel file and extract questions
   */
  async parseExcelFile(filePath) {
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

  /**
   * Get user's exam results
   */
  async getUserExamResults(req, res) {
    try {
      const userId = req.user.userId;
      console.log('🔍 GET USER EXAM RESULTS DEBUG:');
      console.log('   User ID:', userId);

      const results = await ExamResult.findAll({
        where: { userId: userId },
        include: [
          {
            model: Exam,
            as: 'Exam',
            attributes: ['id', 'title', 'category', 'difficulty']
          }
        ],
        order: [['createdAt', 'DESC']],
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
          'questionResults',
          'createdAt'
        ]
      });

      // Convert to plain objects to ensure associations are included
      const plainResults = results.map(result => result.get({ plain: true }));

      console.log('   Results found:', results.length);
      console.log('   Results:', results.map(r => ({ id: r.id, examId: r.examId, score: r.score })));
      
      // Parse questionResults JSON strings to objects
      const processedResults = plainResults.map(result => {
        if (result.questionResults && typeof result.questionResults === 'string') {
          try {
            result.questionResults = JSON.parse(result.questionResults);
          } catch (error) {
            console.error(`Error parsing questionResults for exam ${result.examId}:`, error);
            result.questionResults = [];
          }
        }
        return result;
      });

      // Debug exam information
      for (const result of processedResults) {
        console.log(`   Exam ${result.examId}:`);
        console.log(`     Exam data:`, result.Exam);
        console.log(`     Title: ${result.Exam?.title || 'No title'}`);
        console.log(`     Category: ${result.Exam?.category || 'No category'}`);
        console.log(`     Difficulty: ${result.Exam?.difficulty || 'No difficulty'}`);
        console.log(`     Question Results:`, result.questionResults);
        console.log(`     Question Results Length: ${result.questionResults?.length || 0}`);
      }

      res.json({
        success: true,
        message: 'Exam results retrieved successfully',
        data: processedResults
      });
    } catch (error) {
      console.error('Get user exam results error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
}

module.exports = new ExamController();
