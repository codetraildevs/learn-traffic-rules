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
          questionCount: exam.questionCount,
          passingScore: exam.passingScore,
          examImgUrl: exam.examImgUrl,
          lastUpdated: exam.updatedAt
        },
        questions: exam.questions.map(q => ({
          id: q.id,
          question: q.question,
          options: q.options,
          correctAnswer: q.correctAnswer,
          explanation: q.explanation,
          difficulty: q.difficulty,
          points: q.points,
          imageUrl: q.imageUrl,
          questionImgUrl: q.questionImgUrl,
          lastUpdated: q.updatedAt
        })),
        downloadedAt: new Date(),
        version: 1 // Increment when data changes
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
          questionCount: exam.questionCount,
          passingScore: exam.passingScore,
          examImgUrl: exam.examImgUrl,
          lastUpdated: exam.updatedAt,
          questions: exam.questions.map(q => ({
            id: q.id,
            question: q.question,
            options: q.options,
            correctAnswer: q.correctAnswer,
            explanation: q.explanation,
            difficulty: q.difficulty,
            points: q.points,
            imageUrl: q.imageUrl,
            questionImgUrl: q.questionImgUrl,
            lastUpdated: q.updatedAt
          }))
        })),
        downloadedAt: new Date(),
        version: 1
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
