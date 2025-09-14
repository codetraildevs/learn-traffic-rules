const User = require('../models/User');
const ExamResult = require('../models/ExamResult');
const Exam = require('../models/Exam');

class AchievementController {
  /**
   * Get user achievements
   */
  async getUserAchievements(req, res) {
    try {
      const userId = req.user.userId;

      // Get user's exam results
      const results = await ExamResult.findAll({
        where: { userId },
        include: [{
          model: Exam,
          as: 'Exam',
          attributes: ['id', 'title', 'category', 'difficulty']
        }],
        order: [['completedAt', 'DESC']]
      });

      // Calculate achievements
      const achievements = await this.calculateAchievements(userId, results);

      res.json({
        success: true,
        data: {
          achievements,
          totalPoints: achievements.reduce((sum, a) => sum + a.points, 0),
          totalAchievements: achievements.length,
          unlockedAchievements: achievements.filter(a => a.unlocked).length
        }
      });

    } catch (error) {
      console.error('Get user achievements error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get leaderboard
   */
  async getLeaderboard(req, res) {
    try {
      const { type = 'points', limit = 10 } = req.query;

      let leaderboard = [];

      if (type === 'points') {
        leaderboard = await this.getPointsLeaderboard(parseInt(limit));
      } else if (type === 'exams') {
        leaderboard = await this.getExamsLeaderboard(parseInt(limit));
      } else if (type === 'streak') {
        leaderboard = await this.getStreakLeaderboard(parseInt(limit));
      }

      res.json({
        success: true,
        data: {
          leaderboard,
          type,
          limit: parseInt(limit)
        }
      });

    } catch (error) {
      console.error('Get leaderboard error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Get user stats
   */
  async getUserStats(req, res) {
    try {
      const userId = req.user.userId;

      // Get user's exam results
      const results = await ExamResult.findAll({
        where: { userId },
        include: [{
          model: Exam,
          as: 'Exam',
          attributes: ['id', 'title', 'category', 'difficulty']
        }]
      });

      // Calculate stats
      const stats = await this.calculateUserStats(userId, results);

      res.json({
        success: true,
        data: stats
      });

    } catch (error) {
      console.error('Get user stats error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Helper methods
  async calculateAchievements(userId, results) {
    const achievements = [];

    // First Exam Achievement
    if (results.length >= 1) {
      achievements.push({
        id: 'first_exam',
        name: 'First Steps',
        description: 'Complete your first exam',
        icon: '🎯',
        points: 10,
        unlocked: true,
        unlockedAt: results[0].completedAt,
        category: 'milestone'
      });
    }

    // Perfect Score Achievement
    const perfectScores = results.filter(r => r.score === 100);
    if (perfectScores.length >= 1) {
      achievements.push({
        id: 'perfect_score',
        name: 'Perfectionist',
        description: 'Get a perfect score on an exam',
        icon: '💯',
        points: 50,
        unlocked: true,
        unlockedAt: perfectScores[0].completedAt,
        category: 'performance'
      });
    }

    // Exam Streak Achievements
    const streak = this.calculateExamStreak(results);
    if (streak >= 3) {
      achievements.push({
        id: 'streak_3',
        name: 'On Fire',
        description: 'Complete 3 exams in a row',
        icon: '🔥',
        points: 25,
        unlocked: true,
        unlockedAt: results[0].completedAt,
        category: 'consistency'
      });
    }

    if (streak >= 7) {
      achievements.push({
        id: 'streak_7',
        name: 'Dedicated Learner',
        description: 'Complete 7 exams in a row',
        icon: '⭐',
        points: 100,
        unlocked: true,
        unlockedAt: results[0].completedAt,
        category: 'consistency'
      });
    }

    // Category Master Achievements
    const categories = [...new Set(results.map(r => r.Exam.category))];
    categories.forEach(category => {
      const categoryResults = results.filter(r => r.Exam.category === category);
      if (categoryResults.length >= 5) {
        achievements.push({
          id: `category_master_${category.toLowerCase()}`,
          name: `${category} Master`,
          description: `Complete 5 exams in ${category} category`,
          icon: '🏆',
          points: 75,
          unlocked: true,
          unlockedAt: categoryResults[0].completedAt,
          category: 'expertise'
        });
      }
    });

    // Speed Demon Achievement
    const fastExams = results.filter(r => r.timeSpent < 300); // Less than 5 minutes
    if (fastExams.length >= 1) {
      achievements.push({
        id: 'speed_demon',
        name: 'Speed Demon',
        description: 'Complete an exam in under 5 minutes',
        icon: '⚡',
        points: 30,
        unlocked: true,
        unlockedAt: fastExams[0].completedAt,
        category: 'performance'
      });
    }

    // High Scorer Achievement
    const highScores = results.filter(r => r.score >= 90);
    if (highScores.length >= 10) {
      achievements.push({
        id: 'high_scorer',
        name: 'High Scorer',
        description: 'Get 90% or higher on 10 exams',
        icon: '🎖️',
        points: 100,
        unlocked: true,
        unlockedAt: highScores[0].completedAt,
        category: 'performance'
      });
    }

    // Marathon Runner Achievement
    const totalTime = results.reduce((sum, r) => sum + r.timeSpent, 0);
    if (totalTime >= 3600) { // 1 hour total
      achievements.push({
        id: 'marathon_runner',
        name: 'Marathon Runner',
        description: 'Spend over 1 hour studying',
        icon: '🏃',
        points: 50,
        unlocked: true,
        unlockedAt: results[0].completedAt,
        category: 'dedication'
      });
    }

    // Add locked achievements
    const lockedAchievements = [
      {
        id: 'streak_30',
        name: 'Study Legend',
        description: 'Complete 30 exams in a row',
        icon: '👑',
        points: 500,
        unlocked: false,
        category: 'consistency'
      },
      {
        id: 'all_categories',
        name: 'Jack of All Trades',
        description: 'Complete exams in all categories',
        icon: '🎭',
        points: 200,
        unlocked: false,
        category: 'expertise'
      },
      {
        id: 'perfect_streak',
        name: 'Flawless',
        description: 'Get perfect scores on 5 exams in a row',
        icon: '💎',
        points: 300,
        unlocked: false,
        category: 'performance'
      }
    ];

    achievements.push(...lockedAchievements);

    return achievements;
  }

  calculateExamStreak(results) {
    if (results.length === 0) return 0;

    // Sort by completion date (newest first)
    const sortedResults = results.sort((a, b) => new Date(b.completedAt) - new Date(a.completedAt));
    
    let streak = 1;
    let currentDate = new Date(sortedResults[0].completedAt);
    
    for (let i = 1; i < sortedResults.length; i++) {
      const examDate = new Date(sortedResults[i].completedAt);
      const daysDiff = Math.floor((currentDate - examDate) / (1000 * 60 * 60 * 24));
      
      if (daysDiff === 1) {
        streak++;
        currentDate = examDate;
      } else {
        break;
      }
    }
    
    return streak;
  }

  async calculateUserStats(userId, results) {
    const totalExams = results.length;
    const passedExams = results.filter(r => r.passed).length;
    const averageScore = totalExams > 0 ? results.reduce((sum, r) => sum + r.score, 0) / totalExams : 0;
    const totalTimeSpent = results.reduce((sum, r) => sum + r.timeSpent, 0);
    const streak = this.calculateExamStreak(results);
    
    // Calculate level based on total points
    const totalPoints = await this.calculateTotalPoints(userId, results);
    const level = Math.floor(totalPoints / 100) + 1;
    const pointsToNextLevel = 100 - (totalPoints % 100);

    // Calculate category expertise
    const categories = [...new Set(results.map(r => r.Exam.category))];
    const categoryStats = categories.map(category => {
      const categoryResults = results.filter(r => r.Exam.category === category);
      const categoryPassed = categoryResults.filter(r => r.passed).length;
      const categoryAverage = categoryResults.length > 0 ? 
        categoryResults.reduce((sum, r) => sum + r.score, 0) / categoryResults.length : 0;
      
      return {
        category,
        exams: categoryResults.length,
        passed: categoryPassed,
        averageScore: categoryAverage.toFixed(2),
        expertise: this.calculateExpertiseLevel(categoryResults.length, categoryAverage)
      };
    });

    return {
      level,
      totalPoints,
      pointsToNextLevel,
      totalExams,
      passedExams,
      passRate: totalExams > 0 ? (passedExams / totalExams * 100).toFixed(2) : 0,
      averageScore: averageScore.toFixed(2),
      totalTimeSpent: Math.round(totalTimeSpent / 60), // in minutes
      currentStreak: streak,
      longestStreak: this.calculateLongestStreak(results),
      categoryStats,
      rank: await this.calculateUserRank(userId)
    };
  }

  async calculateTotalPoints(userId, results) {
    // Base points for completing exams
    let points = results.length * 10;
    
    // Bonus points for high scores
    results.forEach(result => {
      if (result.score >= 90) points += 20;
      else if (result.score >= 80) points += 10;
      else if (result.score >= 70) points += 5;
    });

    // Bonus points for perfect scores
    const perfectScores = results.filter(r => r.score === 100);
    points += perfectScores.length * 50;

    // Bonus points for streaks
    const streak = this.calculateExamStreak(results);
    if (streak >= 7) points += 100;
    else if (streak >= 3) points += 25;

    return points;
  }

  calculateExpertiseLevel(examCount, averageScore) {
    if (examCount >= 10 && averageScore >= 90) return 'Expert';
    if (examCount >= 5 && averageScore >= 80) return 'Advanced';
    if (examCount >= 3 && averageScore >= 70) return 'Intermediate';
    if (examCount >= 1) return 'Beginner';
    return 'Novice';
  }

  calculateLongestStreak(results) {
    if (results.length === 0) return 0;

    const sortedResults = results.sort((a, b) => new Date(a.completedAt) - new Date(b.completedAt));
    let longestStreak = 1;
    let currentStreak = 1;
    let currentDate = new Date(sortedResults[0].completedAt);

    for (let i = 1; i < sortedResults.length; i++) {
      const examDate = new Date(sortedResults[i].completedAt);
      const daysDiff = Math.floor((examDate - currentDate) / (1000 * 60 * 60 * 24));
      
      if (daysDiff === 1) {
        currentStreak++;
        longestStreak = Math.max(longestStreak, currentStreak);
      } else {
        currentStreak = 1;
      }
      
      currentDate = examDate;
    }

    return longestStreak;
  }

  async calculateUserRank(userId) {
    // In a real implementation, you'd calculate the user's rank based on points
    // For now, return a placeholder
    return Math.floor(Math.random() * 100) + 1;
  }

  async getPointsLeaderboard(limit) {
    // In a real implementation, you'd query the database for users with highest points
    // For now, return mock data
    const mockLeaderboard = Array.from({ length: limit }, (_, i) => ({
      rank: i + 1,
      userId: `user_${i + 1}`,
      fullName: `User ${i + 1}`,
      points: Math.floor(Math.random() * 1000) + 100,
      level: Math.floor(Math.random() * 10) + 1,
      avatar: `https://api.dicebear.com/7.x/avataaars/svg?seed=${i + 1}`
    }));

    return mockLeaderboard.sort((a, b) => b.points - a.points);
  }

  async getExamsLeaderboard(limit) {
    // In a real implementation, you'd query the database for users with most exams completed
    const mockLeaderboard = Array.from({ length: limit }, (_, i) => ({
      rank: i + 1,
      userId: `user_${i + 1}`,
      fullName: `User ${i + 1}`,
      examsCompleted: Math.floor(Math.random() * 50) + 10,
      level: Math.floor(Math.random() * 10) + 1,
      avatar: `https://api.dicebear.com/7.x/avataaars/svg?seed=${i + 1}`
    }));

    return mockLeaderboard.sort((a, b) => b.examsCompleted - a.examsCompleted);
  }

  async getStreakLeaderboard(limit) {
    // In a real implementation, you'd query the database for users with longest streaks
    const mockLeaderboard = Array.from({ length: limit }, (_, i) => ({
      rank: i + 1,
      userId: `user_${i + 1}`,
      fullName: `User ${i + 1}`,
      currentStreak: Math.floor(Math.random() * 20) + 1,
      level: Math.floor(Math.random() * 10) + 1,
      avatar: `https://api.dicebear.com/7.x/avataaars/svg?seed=${i + 1}`
    }));

    return mockLeaderboard.sort((a, b) => b.currentStreak - a.currentStreak);
  }
}

module.exports = new AchievementController();
