const Exam = require('../models/Exam');
const Question = require('../models/Question');
const AccessCode = require('../models/AccessCode');
const ExamResult = require('../models/ExamResult');
const User = require('../models/User');

class OfflineController {
  /**
   * Download exam data for offline use
   */
  async downloadExamData(req, res) {
    try {
      const userId = req.user.userId;
      const { examId } = req.params;

      // Check if user has access
      const hasAccess = await this.checkUserAccess(userId);
      if (!hasAccess) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. Please purchase access first.'
        });
      }

      // Get exam with questions
      const exam = await Exam.findByPk(examId, {
        include: [{
          model: Question,
          as: 'questions',
          where: { examId: examId },
          required: false
        }]
      });

      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      // Prepare offline data
      const offlineData = {
        exam: {
          id: exam.id,
          title: exam.title,
          description: exam.description,
          category: exam.category,
          difficulty: exam.difficulty,
          duration: exam.duration,
          passingScore: exam.passingScore,
          examImgUrl: exam.examImgUrl,
          isActive: exam.isActive,
          createdAt: exam.createdAt,
          lastUpdated: exam.updatedAt
        },
        questions: exam.questions.map(q => ({
          id: q.id,
          examId: q.examId,
          question: q.question,
          option1: q.option1,
          option2: q.option2,
          option3: q.option3,
          option4: q.option4,
          correctAnswer: q.correctAnswer,
          points: q.points,
          questionOrder: q.questionOrder,
          questionImgUrl: q.questionImgUrl,
          createdAt: q.createdAt,
          lastUpdated: q.updatedAt
        })),
        metadata: {
          downloadedAt: new Date(),
          version: 1,
          totalQuestions: exam.questions.length,
          examId: exam.id
        }
      };

      res.json({
        success: true,
        message: 'Exam data downloaded successfully',
        data: offlineData
      });

    } catch (error) {
      console.error('Download exam data error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Download all available exams for offline use
   */
  async downloadAllExams(req, res) {
    try {
      const userId = req.user.userId;

      // Check if user has access
      const hasAccess = await this.checkUserAccess(userId);
      if (!hasAccess) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. Please purchase access first.'
        });
      }

      // Get all active exams with questions
      const exams = await Exam.findAll({
        where: { isActive: true },
        include: [{
          model: Question,
          as: 'questions',
          required: false
        }],
        order: [['createdAt', 'ASC']]
      });

      // Prepare offline data
      const offlineData = {
        exams: exams.map(exam => ({
          id: exam.id,
          title: exam.title,
          description: exam.description,
          category: exam.category,
          difficulty: exam.difficulty,
          duration: exam.duration,
          passingScore: exam.passingScore,
          examImgUrl: exam.examImgUrl,
          isActive: exam.isActive,
          createdAt: exam.createdAt,
          lastUpdated: exam.updatedAt,
          questions: exam.questions.map(q => ({
            id: q.id,
            examId: q.examId,
            question: q.question,
            option1: q.option1,
            option2: q.option2,
            option3: q.option3,
            option4: q.option4,
            correctAnswer: q.correctAnswer,
            points: q.points,
            questionOrder: q.questionOrder,
            questionImgUrl: q.questionImgUrl,
            createdAt: q.createdAt,
            lastUpdated: q.updatedAt
          }))
        })),
        metadata: {
          downloadedAt: new Date(),
          version: 1,
          totalExams: exams.length,
          totalQuestions: exams.reduce((sum, exam) => sum + exam.questions.length, 0)
        }
      };

      res.json({
        success: true,
        message: 'All exams downloaded successfully',
        data: offlineData
      });

    } catch (error) {
      console.error('Download all exams error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Check for updates since last download
   */
  async checkForUpdates(req, res) {
    try {
      const userId = req.user.userId;
      const { lastSyncTime } = req.body;

      // Check if user has access
      const hasAccess = await this.checkUserAccess(userId);
      if (!hasAccess) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. Please purchase access first.'
        });
      }

      const lastSync = new Date(lastSyncTime);
      
      // Check for updated exams
      const updatedExams = await Exam.findAll({
        where: {
          isActive: true,
          updatedAt: {
            [require('sequelize').Op.gt]: lastSync
          }
        },
        attributes: ['id', 'title', 'updatedAt']
      });

      // Check for updated questions
      const updatedQuestions = await Question.findAll({
        where: {
          updatedAt: {
            [require('sequelize').Op.gt]: lastSync
          }
        },
        include: [{
          model: Exam,
          as: 'Exam',
          where: { isActive: true }
        }],
        attributes: ['id', 'examId', 'updatedAt']
      });

      // Check for new questions
      const newQuestions = await Question.findAll({
        where: {
          createdAt: {
            [require('sequelize').Op.gt]: lastSync
          }
        },
        include: [{
          model: Exam,
          as: 'Exam',
          where: { isActive: true }
        }],
        attributes: ['id', 'examId', 'createdAt']
      });

      const hasUpdates = updatedExams.length > 0 || updatedQuestions.length > 0 || newQuestions.length > 0;

      res.json({
        success: true,
        hasUpdates,
        data: {
          updatedExams: updatedExams.length,
          updatedQuestions: updatedQuestions.length,
          newQuestions: newQuestions.length,
          lastChecked: new Date()
        }
      });

    } catch (error) {
      console.error('Check for updates error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Sync offline exam results
   */
  async syncExamResults(req, res) {
    try {
      const userId = req.user.userId;
      const { results } = req.body; // Array of offline exam results

      if (!Array.isArray(results) || results.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'No results to sync'
        });
      }

      const syncedResults = [];

      for (const result of results) {
        // Validate result data
        if (!result.examId || !result.score || !result.answers) {
          console.warn('Invalid result data:', result);
          continue;
        }

        // Check if result already exists (prevent duplicates)
        const existingResult = await ExamResult.findOne({
          where: {
            userId: userId,
            examId: result.examId,
            completedAt: new Date(result.completedAt)
          }
        });

        if (existingResult) {
          console.log('Result already exists, skipping:', result.examId);
          continue;
        }

        // Create exam result
        const examResult = await ExamResult.create({
          userId: userId,
          examId: result.examId,
          score: result.score,
          totalQuestions: result.totalQuestions,
          correctAnswers: result.correctAnswers,
          timeSpent: result.timeSpent,
          answers: result.answers,
          passed: result.passed,
          completedAt: new Date(result.completedAt)
        });

        syncedResults.push(examResult);
      }

      res.json({
        success: true,
        message: `${syncedResults.length} exam results synced successfully`,
        data: {
          syncedCount: syncedResults.length,
          totalSubmitted: results.length,
          syncedAt: new Date()
        }
      });

    } catch (error) {
      console.error('Sync exam results error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get user's offline sync status
   */
  async getSyncStatus(req, res) {
    try {
      const userId = req.user.userId;

      // Get user's last sync time
      const user = await User.findByPk(userId, {
        attributes: ['id', 'lastSyncAt']
      });

      // Get total exams and questions count
      const totalExams = await Exam.count({ where: { isActive: true } });
      const totalQuestions = await Question.count({
        include: [{
          model: Exam,
          as: 'Exam',
          where: { isActive: true }
        }]
      });

      res.json({
        success: true,
        data: {
          lastSyncAt: user.lastSyncAt,
          totalExams,
          totalQuestions,
          hasAccess: await this.checkUserAccess(userId)
        }
      });

    } catch (error) {
      console.error('Get sync status error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Update user's last sync time
   */
  async updateLastSync(req, res) {
    try {
      const userId = req.user.userId;

      await User.update(
        { lastSyncAt: new Date() },
        { where: { id: userId } }
      );

      res.json({
        success: true,
        message: 'Last sync time updated',
        data: {
          lastSyncAt: new Date()
        }
      });

    } catch (error) {
      console.error('Update last sync error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Download free exams for offline use (no access required)
   */
  async downloadFreeExams(req, res) {
    try {
      const userId = req.user.userId;

      // Get first 2 exams (free exams) with questions
      const freeExams = await Exam.findAll({
        where: { isActive: true },
        include: [{
          model: Question,
          as: 'questions',
          required: false
        }],
        order: [['createdAt', 'ASC'], ['id', 'ASC']],
        limit: 2
      });

      // Prepare offline data for free exams
      const offlineData = {
        exams: freeExams.map(exam => ({
          id: exam.id,
          title: exam.title,
          description: exam.description,
          category: exam.category,
          difficulty: exam.difficulty,
          duration: exam.duration,
          passingScore: exam.passingScore,
          examImgUrl: exam.examImgUrl,
          isActive: exam.isActive,
          isFree: true,
          createdAt: exam.createdAt,
          lastUpdated: exam.updatedAt,
          questions: exam.questions.map(q => ({
            id: q.id,
            examId: q.examId,
            question: q.question,
            option1: q.option1,
            option2: q.option2,
            option3: q.option3,
            option4: q.option4,
            correctAnswer: q.correctAnswer,
            points: q.points,
            questionOrder: q.questionOrder,
            questionImgUrl: q.questionImgUrl,
            createdAt: q.createdAt,
            lastUpdated: q.updatedAt
          }))
        })),
        metadata: {
          downloadedAt: new Date(),
          version: 1,
          totalExams: freeExams.length,
          totalQuestions: freeExams.reduce((sum, exam) => sum + exam.questions.length, 0),
          isFreeContent: true
        }
      };

      res.json({
        success: true,
        message: 'Free exams downloaded successfully',
        data: offlineData
      });

    } catch (error) {
      console.error('Download free exams error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get offline exam summary (for checking what's available offline)
   */
  async getOfflineSummary(req, res) {
    try {
      const userId = req.user.userId;

      // Get user's access status
      const hasAccess = await this.checkUserAccess(userId);

      // Get exam counts
      const totalExams = await Exam.count({ where: { isActive: true } });
      const freeExamsCount = Math.min(2, totalExams); // First 2 exams are free
      const premiumExamsCount = Math.max(0, totalExams - 2);

      // Get user's last sync time
      const user = await User.findByPk(userId, {
        attributes: ['id', 'lastSyncAt']
      });

      res.json({
        success: true,
        data: {
          hasAccess,
          totalExams,
          freeExamsCount,
          premiumExamsCount,
          lastSyncAt: user.lastSyncAt,
          offlineCapabilities: {
            canDownloadFreeExams: true,
            canDownloadAllExams: hasAccess,
            canSyncResults: true,
            canCheckUpdates: true
          }
        }
      });

    } catch (error) {
      console.error('Get offline summary error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Validate offline exam result before syncing
   */
  async validateOfflineResult(req, res) {
    try {
      const { examId, answers, score, timeSpent } = req.body;

      // Validate exam exists
      const exam = await Exam.findByPk(examId);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      // Get exam questions to validate answers
      const questions = await Question.findAll({
        where: { examId: examId },
        order: [['questionOrder', 'ASC']]
      });

      // Validate answers structure
      const validationResult = this.validateAnswersStructure(answers, questions);

      res.json({
        success: true,
        data: {
          isValid: validationResult.isValid,
          validationErrors: validationResult.errors,
          examInfo: {
            id: exam.id,
            title: exam.title,
            totalQuestions: questions.length,
            passingScore: exam.passingScore
          }
        }
      });

    } catch (error) {
      console.error('Validate offline result error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Helper method to validate answers structure
   */
  validateAnswersStructure(answers, questions) {
    const errors = [];

    if (!Array.isArray(answers)) {
      errors.push('Answers must be an array');
      return { isValid: false, errors };
    }

    if (answers.length !== questions.length) {
      errors.push(`Expected ${questions.length} answers, got ${answers.length}`);
    }

    answers.forEach((answer, index) => {
      const question = questions[index];
      if (!question) return;

      if (!answer.questionId || answer.questionId !== question.id) {
        errors.push(`Answer ${index + 1}: Invalid question ID`);
      }

      if (!answer.selectedAnswer) {
        errors.push(`Answer ${index + 1}: No answer selected`);
      }

      // Validate selected answer is one of the options
      const validOptions = [question.option1, question.option2, question.option3, question.option4];
      if (answer.selectedAnswer && !validOptions.includes(answer.selectedAnswer)) {
        errors.push(`Answer ${index + 1}: Invalid answer option`);
      }
    });

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * Check if user has access to exams
   */
  async checkUserAccess(userId) {
    try {
      // Check if user has valid access code
      const accessCode = await AccessCode.findOne({
        where: {
          userId: userId,
          isUsed: true,
          expiresAt: {
            [require('sequelize').Op.gt]: new Date()
          }
        }
      });

      return !!accessCode;
    } catch (error) {
      console.error('Check user access error:', error);
      return false;
    }
  }
}

module.exports = new OfflineController();
