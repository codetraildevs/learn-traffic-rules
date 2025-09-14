const Exam = require('../models/Exam');
const Question = require('../models/Question');
const ExamResult = require('../models/ExamResult');
const User = require('../models/User');
const PaymentRequest = require('../models/PaymentRequest');
const AccessCode = require('../models/AccessCode');

class AnalyticsController {
  /**
   * Get dashboard analytics for admins/managers
   */
  async getDashboardAnalytics(req, res) {
    try {
      const userRole = req.user.role;
      
      // Only admins and managers can access analytics
      if (!['ADMIN', 'MANAGER'].includes(userRole)) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. Admin or Manager role required.'
        });
      }

      // Get date range from query params (default: last 30 days)
      const days = parseInt(req.query.days) || 30;
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);

      // Parallel data fetching for better performance
      const [
        totalUsers,
        activeUsers,
        totalExams,
        totalQuestions,
        totalResults,
        recentResults,
        paymentStats,
        examStats,
        userGrowth,
        examPerformance
      ] = await Promise.all([
        this.getTotalUsers(),
        this.getActiveUsers(startDate),
        this.getTotalExams(),
        this.getTotalQuestions(),
        this.getTotalResults(),
        this.getRecentResults(startDate),
        this.getPaymentStats(startDate),
        this.getExamStats(),
        this.getUserGrowth(days),
        this.getExamPerformance(startDate)
      ]);

      res.json({
        success: true,
        data: {
          overview: {
            totalUsers,
            activeUsers,
            totalExams,
            totalQuestions,
            totalResults,
            period: `${days} days`
          },
          recentActivity: {
            recentResults,
            userGrowth,
            paymentStats
          },
          examAnalytics: {
            examStats,
            examPerformance
          },
          generatedAt: new Date()
        }
      });

    } catch (error) {
      console.error('Dashboard analytics error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get user performance analytics
   */
  async getUserPerformance(req, res) {
    try {
      const userId = req.user.userId;
      const days = parseInt(req.query.days) || 30;
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);

      // Get user's exam results
      const results = await ExamResult.findAll({
        where: {
          userId: userId,
          completedAt: {
            [require('sequelize').Op.gte]: startDate
          }
        },
        include: [{
          model: Exam,
          as: 'Exam',
          attributes: ['id', 'title', 'category', 'difficulty']
        }],
        order: [['completedAt', 'DESC']]
      });

      // Calculate performance metrics
      const totalExams = results.length;
      const passedExams = results.filter(r => r.passed).length;
      const averageScore = totalExams > 0 ? results.reduce((sum, r) => sum + r.score, 0) / totalExams : 0;
      const totalTimeSpent = results.reduce((sum, r) => sum + r.timeSpent, 0);
      const averageTimePerExam = totalExams > 0 ? totalTimeSpent / totalExams : 0;

      // Performance by category
      const categoryPerformance = this.calculateCategoryPerformance(results);
      
      // Performance by difficulty
      const difficultyPerformance = this.calculateDifficultyPerformance(results);

      // Recent performance trend
      const performanceTrend = this.calculatePerformanceTrend(results);

      res.json({
        success: true,
        data: {
          summary: {
            totalExams,
            passedExams,
            passRate: totalExams > 0 ? (passedExams / totalExams * 100).toFixed(2) : 0,
            averageScore: averageScore.toFixed(2),
            totalTimeSpent: Math.round(totalTimeSpent / 60), // in minutes
            averageTimePerExam: Math.round(averageTimePerExam / 60) // in minutes
          },
          categoryPerformance,
          difficultyPerformance,
          performanceTrend,
          recentResults: results.slice(0, 10).map(r => ({
            examTitle: r.Exam.title,
            score: r.score,
            passed: r.passed,
            completedAt: r.completedAt,
            timeSpent: Math.round(r.timeSpent / 60)
          }))
        }
      });

    } catch (error) {
      console.error('User performance analytics error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get exam analytics
   */
  async getExamAnalytics(req, res) {
    try {
      const examId = req.params.examId;
      const days = parseInt(req.query.days) || 30;
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);

      // Get exam details
      const exam = await Exam.findByPk(examId, {
        include: [{
          model: Question,
          as: 'questions',
          attributes: ['id', 'difficulty', 'points']
        }]
      });

      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      // Get exam results
      const results = await ExamResult.findAll({
        where: {
          examId: examId,
          completedAt: {
            [require('sequelize').Op.gte]: startDate
          }
        },
        include: [{
          model: User,
          as: 'User',
          attributes: ['id', 'fullName', 'role']
        }]
      });

      // Calculate analytics
      const totalAttempts = results.length;
      const passedAttempts = results.filter(r => r.passed).length;
      const passRate = totalAttempts > 0 ? (passedAttempts / totalAttempts * 100).toFixed(2) : 0;
      const averageScore = totalAttempts > 0 ? results.reduce((sum, r) => sum + r.score, 0) / totalAttempts : 0;
      const averageTime = totalAttempts > 0 ? results.reduce((sum, r) => sum + r.timeSpent, 0) / totalAttempts : 0;

      // Question difficulty analysis
      const questionStats = this.analyzeQuestionDifficulty(exam.questions, results);

      // Performance over time
      const performanceOverTime = this.calculatePerformanceOverTime(results, days);

      res.json({
        success: true,
        data: {
          exam: {
            id: exam.id,
            title: exam.title,
            category: exam.category,
            difficulty: exam.difficulty,
            questionCount: exam.questions.length
          },
          statistics: {
            totalAttempts,
            passedAttempts,
            passRate: parseFloat(passRate),
            averageScore: averageScore.toFixed(2),
            averageTime: Math.round(averageTime / 60) // in minutes
          },
          questionStats,
          performanceOverTime,
          period: `${days} days`
        }
      });

    } catch (error) {
      console.error('Exam analytics error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Helper methods
  async getTotalUsers() {
    return await User.count();
  }

  async getActiveUsers(startDate) {
    return await User.count({
      where: {
        lastLogin: {
          [require('sequelize').Op.gte]: startDate
        }
      }
    });
  }

  async getTotalExams() {
    return await Exam.count({ where: { isActive: true } });
  }

  async getTotalQuestions() {
    return await Question.count({
      include: [{
        model: Exam,
        as: 'Exam',
        where: { isActive: true }
      }]
    });
  }

  async getTotalResults() {
    return await ExamResult.count();
  }

  async getRecentResults(startDate) {
    return await ExamResult.count({
      where: {
        completedAt: {
          [require('sequelize').Op.gte]: startDate
        }
      }
    });
  }

  async getPaymentStats(startDate) {
    const totalRequests = await PaymentRequest.count({
      where: {
        createdAt: {
          [require('sequelize').Op.gte]: startDate
        }
      }
    });

    const approvedRequests = await PaymentRequest.count({
      where: {
        status: 'APPROVED',
        createdAt: {
          [require('sequelize').Op.gte]: startDate
        }
      }
    });

    return {
      totalRequests,
      approvedRequests,
      approvalRate: totalRequests > 0 ? (approvedRequests / totalRequests * 100).toFixed(2) : 0
    };
  }

  async getExamStats() {
    const exams = await Exam.findAll({
      where: { isActive: true },
      include: [{
        model: Question,
        as: 'questions',
        attributes: ['id']
      }]
    });

    return exams.map(exam => ({
      id: exam.id,
      title: exam.title,
      category: exam.category,
      difficulty: exam.difficulty,
      questionCount: exam.questions.length
    }));
  }

  async getUserGrowth(days) {
    const growthData = [];
    for (let i = days; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const startOfDay = new Date(date.setHours(0, 0, 0, 0));
      const endOfDay = new Date(date.setHours(23, 59, 59, 999));

      const newUsers = await User.count({
        where: {
          createdAt: {
            [require('sequelize').Op.between]: [startOfDay, endOfDay]
          }
        }
      });

      growthData.push({
        date: startOfDay.toISOString().split('T')[0],
        newUsers
      });
    }

    return growthData;
  }

  async getExamPerformance(startDate) {
    const results = await ExamResult.findAll({
      where: {
        completedAt: {
          [require('sequelize').Op.gte]: startDate
        }
      },
      include: [{
        model: Exam,
        as: 'Exam',
        attributes: ['id', 'title', 'category']
      }]
    });

    // Group by exam
    const examPerformance = {};
    results.forEach(result => {
      const examId = result.Exam.id;
      if (!examPerformance[examId]) {
        examPerformance[examId] = {
          examTitle: result.Exam.title,
          category: result.Exam.category,
          attempts: 0,
          passed: 0,
          totalScore: 0
        };
      }
      
      examPerformance[examId].attempts++;
      if (result.passed) examPerformance[examId].passed++;
      examPerformance[examId].totalScore += result.score;
    });

    // Calculate averages
    return Object.values(examPerformance).map(exam => ({
      ...exam,
      passRate: exam.attempts > 0 ? (exam.passed / exam.attempts * 100).toFixed(2) : 0,
      averageScore: exam.attempts > 0 ? (exam.totalScore / exam.attempts).toFixed(2) : 0
    }));
  }

  calculateCategoryPerformance(results) {
    const categories = {};
    results.forEach(result => {
      const category = result.Exam.category;
      if (!categories[category]) {
        categories[category] = { attempts: 0, passed: 0, totalScore: 0 };
      }
      categories[category].attempts++;
      if (result.passed) categories[category].passed++;
      categories[category].totalScore += result.score;
    });

    return Object.entries(categories).map(([category, stats]) => ({
      category,
      attempts: stats.attempts,
      passed: stats.passed,
      passRate: stats.attempts > 0 ? (stats.passed / stats.attempts * 100).toFixed(2) : 0,
      averageScore: stats.attempts > 0 ? (stats.totalScore / stats.attempts).toFixed(2) : 0
    }));
  }

  calculateDifficultyPerformance(results) {
    const difficulties = {};
    results.forEach(result => {
      const difficulty = result.Exam.difficulty;
      if (!difficulties[difficulty]) {
        difficulties[difficulty] = { attempts: 0, passed: 0, totalScore: 0 };
      }
      difficulties[difficulty].attempts++;
      if (result.passed) difficulties[difficulty].passed++;
      difficulties[difficulty].totalScore += result.score;
    });

    return Object.entries(difficulties).map(([difficulty, stats]) => ({
      difficulty,
      attempts: stats.attempts,
      passed: stats.passed,
      passRate: stats.attempts > 0 ? (stats.passed / stats.attempts * 100).toFixed(2) : 0,
      averageScore: stats.attempts > 0 ? (stats.totalScore / stats.attempts).toFixed(2) : 0
    }));
  }

  calculatePerformanceTrend(results) {
    // Group results by week
    const weeklyData = {};
    results.forEach(result => {
      const week = this.getWeekNumber(result.completedAt);
      if (!weeklyData[week]) {
        weeklyData[week] = { attempts: 0, totalScore: 0 };
      }
      weeklyData[week].attempts++;
      weeklyData[week].totalScore += result.score;
    });

    return Object.entries(weeklyData).map(([week, stats]) => ({
      week: `Week ${week}`,
      attempts: stats.attempts,
      averageScore: stats.attempts > 0 ? (stats.totalScore / stats.attempts).toFixed(2) : 0
    }));
  }

  analyzeQuestionDifficulty(questions, results) {
    const questionStats = questions.map(question => {
      const questionResults = results.filter(r => 
        r.answers && r.answers[question.id]
      );
      
      const correctAnswers = questionResults.filter(r => 
        r.answers[question.id] === question.correctAnswer
      ).length;

      return {
        questionId: question.id,
        difficulty: question.difficulty,
        points: question.points,
        totalAttempts: questionResults.length,
        correctAnswers,
        accuracy: questionResults.length > 0 ? 
          (correctAnswers / questionResults.length * 100).toFixed(2) : 0
      };
    });

    return questionStats;
  }

  calculatePerformanceOverTime(results, days) {
    const dailyData = {};
    for (let i = days; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      dailyData[dateStr] = { attempts: 0, passed: 0, totalScore: 0 };
    }

    results.forEach(result => {
      const dateStr = result.completedAt.toISOString().split('T')[0];
      if (dailyData[dateStr]) {
        dailyData[dateStr].attempts++;
        if (result.passed) dailyData[dateStr].passed++;
        dailyData[dateStr].totalScore += result.score;
      }
    });

    return Object.entries(dailyData).map(([date, stats]) => ({
      date,
      attempts: stats.attempts,
      passed: stats.passed,
      passRate: stats.attempts > 0 ? (stats.passed / stats.attempts * 100).toFixed(2) : 0,
      averageScore: stats.attempts > 0 ? (stats.totalScore / stats.attempts).toFixed(2) : 0
    }));
  }

  getWeekNumber(date) {
    const d = new Date(date);
    const dayNum = d.getDay() || 7;
    d.setDate(d.getDate() + 4 - dayNum);
    const yearStart = new Date(d.getFullYear(), 0, 1);
    return Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
  }
}

module.exports = new AnalyticsController();
