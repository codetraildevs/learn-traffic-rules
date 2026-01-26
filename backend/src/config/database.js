const { Sequelize } = require('sequelize');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

// Determine database dialect based on environment
const getDatabaseConfig = () => {
  const isProduction = process.env.NODE_ENV === 'production';
  const databaseUrl = process.env.DATABASE_URL; // Render provides this for PostgreSQL
  
  console.log('🔍 Environment check:', {
    NODE_ENV: process.env.NODE_ENV,
    isProduction,
    hasDatabaseUrl: !!databaseUrl,
    databaseUrl: databaseUrl ? 'SET' : 'NOT SET'
  });
  
  if (databaseUrl) {
    // Production MySQL configuration (VPS)
    console.log('🐬 Using MySQL configuration for production');
    console.log('🔍 DATABASE_URL:', databaseUrl.replace(/:[^:@]+@/, ':***@')); // Hide password in logs
    
    return {
      url: databaseUrl,
      dialect: 'mysql',
      logging: false,
      pool: {
        max: 20,
        min: 2,
        acquire: 60000,
        idle: 10000,
        evict: 1000
      },
      retry: {
        match: [
          /ETIMEDOUT/,
          /EHOSTUNREACH/,
          /ECONNRESET/,
          /ECONNREFUSED/,
          /ETIMEDOUT/,
          /ESOCKETTIMEDOUT/,
          /EHOSTUNREACH/,
          /EPIPE/,
          /EAI_AGAIN/,
          /SequelizeConnectionError/,
          /SequelizeConnectionRefusedError/,
          /SequelizeHostNotFoundError/,
          /SequelizeHostNotReachableError/,
          /SequelizeInvalidConnectionError/,
          /SequelizeConnectionTimedOutError/
        ],
        max: 3
      }
    };
  } else if (isProduction) {
    // Production without DATABASE_URL - use individual env vars
    console.log('🐬 Using MySQL configuration with individual env vars');
    console.log('🔍 Database config:', {
      database: process.env.DB_NAME || 'traffic_rules_db',
      username: process.env.DB_USER || 'root',
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 3306,
      hasPassword: !!process.env.DB_PASSWORD
    });
    
    return {
      database: process.env.DB_NAME || 'traffic_rules_db',
      username: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 3306,
      dialect: 'mysql',
      logging: false,
      pool: {
        max: 20,
        min: 2,
        acquire: 60000,
        idle: 10000,
        evict: 1000
      },
      retry: {
        match: [
          /ETIMEDOUT/,
          /EHOSTUNREACH/,
          /ECONNRESET/,
          /ECONNREFUSED/,
          /ETIMEDOUT/,
          /ESOCKETTIMEDOUT/,
          /EHOSTUNREACH/,
          /EPIPE/,
          /EAI_AGAIN/,
          /SequelizeConnectionError/,
          /SequelizeConnectionRefusedError/,
          /SequelizeHostNotFoundError/,
          /SequelizeHostNotReachableError/,
          /SequelizeInvalidConnectionError/,
          /SequelizeConnectionTimedOutError/
        ],
        max: 3
      }
    };
  } else {
    // Development MySQL configuration
    console.log('🐬 Using MySQL configuration for development');
    return {
      database: process.env.DB_NAME || 'traffic_rules_db',
      username: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 3306,
      dialect: 'mysql',
      logging: false,
      pool: {
        max: 5,
        min: 0,
        acquire: 30000,
        idle: 10000
      }
    };
  }
};

// Database configuration
const sequelize = new Sequelize(getDatabaseConfig());

// Test database connection
const testConnection = async () => {
  const maxRetries = 3;
  let retryCount = 0;
  
  while (retryCount < maxRetries) {
    try {
      console.log(`🔄 Attempting database connection (attempt ${retryCount + 1}/${maxRetries})...`);
      await sequelize.authenticate();
      console.log('✅ Database connected successfully');
      return true;
    } catch (error) {
      retryCount++;
      console.error(`❌ Database connection failed (attempt ${retryCount}/${maxRetries}):`, error.message);
      console.error('🔍 Error details:', {
        name: error.name,
        code: error.code,
        parent: error.parent?.code,
        original: error.original?.code
      });
      
      // If it's a connection refused error, provide helpful message
      if (error.name === 'SequelizeConnectionRefusedError' || error.code === 'ECONNREFUSED') {
        console.error('💡 Database connection troubleshooting:');
        console.error('   1. Check if DATABASE_URL is set correctly in environment variables');
        console.error('   2. Verify database credentials are correct');
        console.error('   3. Ensure database server is running and accessible');
        console.error('   4. Check if database is in the same region as your service');
        console.error('   5. Verify the database URL format is correct');
        console.error('   6. Try using individual DB_* environment variables instead of DATABASE_URL');
        
        // Show the actual DATABASE_URL format for debugging
        const databaseUrl = process.env.DATABASE_URL;
        if (databaseUrl) {
          console.error('🔍 Current DATABASE_URL format:', databaseUrl.replace(/:[^:@]+@/, ':***@'));
          console.error('🔍 Expected format: mysql://username:password@hostname:port/database_name');
        }
        
        // Show individual environment variables
        console.error('🔍 Individual DB variables:');
        console.error('   DB_NAME:', process.env.DB_NAME || 'NOT SET');
        console.error('   DB_USER:', process.env.DB_USER || 'NOT SET');
        console.error('   DB_HOST:', process.env.DB_HOST || 'NOT SET');
        console.error('   DB_PORT:', process.env.DB_PORT || 'NOT SET');
        console.error('   DB_PASSWORD:', process.env.DB_PASSWORD ? 'SET' : 'NOT SET');
        
        // If hostname not found, suggest using external hostname
        if (error.name === 'SequelizeHostNotFoundError') {
          console.error('💡 Hostname resolution failed. Try using external hostname:');
          console.error('   For VPS MySQL, use: your-vps-domain.com or IP address');
          console.error('   Ensure MySQL is running and accessible from your deployment');
        }
      }
      
      if (retryCount < maxRetries) {
        console.log(`⏳ Retrying in 5 seconds...`);
        await new Promise(resolve => setTimeout(resolve, 5000));
      }
    }
  }
  
  console.error('❌ All database connection attempts failed');
  console.error('💡 Try using individual DB_* environment variables instead of DATABASE_URL');
  return false;
};

// Create all MySQL-compatible tables (core + notification tables)
// Create only specific missing tables (safe for production)
const createMissingTablesOnly = async (sequelize, missingTables) => {
  try {
    console.log('🔄 Creating only missing tables (preserving existing data)...');
    
    // Define all table creation SQL with table name mapping
    const tableDefinitions = {
      'users': `CREATE TABLE IF NOT EXISTS users (
        id CHAR(36) PRIMARY KEY,
        fullName VARCHAR(255) NOT NULL,
        phoneNumber VARCHAR(20) UNIQUE NOT NULL,
        email VARCHAR(255),
        deviceId VARCHAR(255),
        role ENUM('USER', 'ADMIN') DEFAULT 'USER',
        isActive BOOLEAN DEFAULT true,
        isBlocked BOOLEAN DEFAULT false,
        blockReason TEXT NULL,
        blockedAt TIMESTAMP NULL,
        lastLogin TIMESTAMP NULL,
        lastSyncAt TIMESTAMP NULL,
        resetCode VARCHAR(255) NULL,
        resetCodeExpires TIMESTAMP NULL,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      'exams': `CREATE TABLE IF NOT EXISTS exams (
        id CHAR(36) PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        category VARCHAR(100),
        difficulty ENUM('EASY', 'MEDIUM', 'HARD') DEFAULT 'MEDIUM',
        duration INTEGER DEFAULT 30,
        passingScore INTEGER DEFAULT 60,
        examImgUrl VARCHAR(500) NULL,
        examType ENUM('kinyarwanda', 'english', 'french') DEFAULT 'english',
        isActive BOOLEAN DEFAULT true,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      'questions': `CREATE TABLE IF NOT EXISTS questions (
        id CHAR(36) PRIMARY KEY,
        examId CHAR(36) NOT NULL,
        question TEXT NOT NULL,
        option1 TEXT NOT NULL,
        option2 TEXT NOT NULL,
        option3 TEXT NOT NULL,
        option4 TEXT NOT NULL,
        correctAnswer TEXT NOT NULL,
        points INTEGER DEFAULT 1,
        questionOrder INTEGER DEFAULT 1,
        questionImgUrl VARCHAR(500) NULL,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      'exam_results': `CREATE TABLE IF NOT EXISTS exam_results (
        id CHAR(36) PRIMARY KEY,
        examId CHAR(36) NOT NULL,
        userId CHAR(36) NOT NULL,
        score INTEGER NOT NULL,
        totalQuestions INTEGER NOT NULL,
        correctAnswers INTEGER NOT NULL,
        timeSpent INTEGER NOT NULL,
        passed BOOLEAN NOT NULL,
        isFreeExam BOOLEAN DEFAULT false,
        questionResults JSON NULL,
        answers JSON NULL,
        completedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      'payment_requests': `CREATE TABLE IF NOT EXISTS payment_requests (
        id CHAR(36) PRIMARY KEY,
        userId CHAR(36) NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        status ENUM('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',
        paymentMethod VARCHAR(50),
        transactionId VARCHAR(255),
        notes TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      'access_codes': `CREATE TABLE IF NOT EXISTS access_codes (
        id CHAR(36) PRIMARY KEY,
        code VARCHAR(50) UNIQUE NOT NULL,
        userId CHAR(36),
        examId CHAR(36),
        isUsed BOOLEAN DEFAULT false,
        paymentTier ENUM('1_MONTH', '3_MONTHS', '6_MONTHS') NOT NULL,
        paymentAmount DECIMAL(10,2) NOT NULL,
        durationDays INTEGER NOT NULL,
        generatedByManagerId CHAR(36) NULL,
        expiresAt TIMESTAMP NULL,
        usedAt TIMESTAMP NULL,
        attemptCount INTEGER DEFAULT 0,
        lastAttemptAt TIMESTAMP NULL,
        isBlocked BOOLEAN DEFAULT false,
        blockedUntil TIMESTAMP NULL,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      'notifications': `CREATE TABLE IF NOT EXISTS notifications (
        id CHAR(36) PRIMARY KEY,
        userId CHAR(36) NOT NULL,
        type VARCHAR(50) NOT NULL,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        data JSON DEFAULT ('{}'),
        isRead BOOLEAN DEFAULT false,
        isPushSent BOOLEAN DEFAULT false,
        scheduledFor TIMESTAMP NULL,
        priority VARCHAR(20) DEFAULT 'MEDIUM',
        category VARCHAR(20) NOT NULL,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      'user_call_tracking': `CREATE TABLE IF NOT EXISTS user_call_tracking (
        id CHAR(36) PRIMARY KEY,
        user_id CHAR(36) NOT NULL,
        admin_id CHAR(36) NOT NULL,
        called_at TIMESTAMP NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY unique_user_admin (user_id, admin_id),
        INDEX idx_admin_id (admin_id),
        INDEX idx_user_id (user_id),
        INDEX idx_called_at (called_at)
      )`,
      
      'studyreminders': `CREATE TABLE IF NOT EXISTS studyreminders (
        id CHAR(36) PRIMARY KEY,
        userId CHAR(36) NOT NULL,
        isEnabled BOOLEAN DEFAULT true,
        reminderTime TIME NOT NULL,
        daysOfWeek JSON DEFAULT ('[]'),
        studyGoalMinutes INTEGER DEFAULT 30,
        timezone VARCHAR(50) DEFAULT 'UTC',
        lastSentAt TIMESTAMP NULL,
        nextScheduledAt TIMESTAMP NULL,
        isActive BOOLEAN DEFAULT true,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      'notificationpreferences': `CREATE TABLE IF NOT EXISTS notificationpreferences (
        id CHAR(36) PRIMARY KEY,
        userId CHAR(36) NOT NULL UNIQUE,
        pushNotifications BOOLEAN DEFAULT true,
        smsNotifications BOOLEAN DEFAULT true,
        examReminders BOOLEAN DEFAULT true,
        paymentUpdates BOOLEAN DEFAULT true,
        systemAnnouncements BOOLEAN DEFAULT true,
        studyReminders BOOLEAN DEFAULT true,
        achievementNotifications BOOLEAN DEFAULT true,
        weeklyReports BOOLEAN DEFAULT true,
        quietHoursEnabled BOOLEAN DEFAULT true,
        quietHoursStart TIME DEFAULT '22:00:00',
        quietHoursEnd TIME DEFAULT '07:00:00',
        vibrationEnabled BOOLEAN DEFAULT true,
        soundEnabled BOOLEAN DEFAULT true,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      'courses': `CREATE TABLE IF NOT EXISTS courses (
        id CHAR(36) PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        description TEXT NULL,
        category VARCHAR(100) NULL,
        difficulty ENUM('EASY', 'MEDIUM', 'HARD') DEFAULT 'MEDIUM',
        courseType ENUM('free', 'paid') DEFAULT 'free',
        courseImageUrl VARCHAR(500) NULL,
        isActive BOOLEAN DEFAULT true,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      'course_contents': `CREATE TABLE IF NOT EXISTS course_contents (
        id CHAR(36) PRIMARY KEY,
        courseId CHAR(36) NOT NULL,
        contentType ENUM('text', 'image', 'audio', 'video', 'link') DEFAULT 'text',
        content TEXT NOT NULL,
        title VARCHAR(255) NULL,
        displayOrder INTEGER DEFAULT 0,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      'course_progress': `CREATE TABLE IF NOT EXISTS course_progress (
        id CHAR(36) PRIMARY KEY,
        userId CHAR(36) NOT NULL,
        courseId CHAR(36) NOT NULL,
        completedContentCount INTEGER DEFAULT 0,
        totalContentCount INTEGER DEFAULT 0,
        progressPercentage DECIMAL(5,2) DEFAULT 0.00,
        isCompleted BOOLEAN DEFAULT false,
        lastAccessedAt TIMESTAMP NULL,
        completedAt TIMESTAMP NULL,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY unique_user_course (userId, courseId)
      )`,
      
      'course_content_progress': `CREATE TABLE IF NOT EXISTS course_content_progress (
        id CHAR(36) PRIMARY KEY,
        userId CHAR(36) NOT NULL,
        courseId CHAR(36) NOT NULL,
        courseContentId CHAR(36) NOT NULL,
        isCompleted BOOLEAN DEFAULT false,
        completedAt TIMESTAMP NULL,
        timeSpent INTEGER DEFAULT 0,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY unique_user_content (userId, courseContentId)
      )`
    };
    
    // Create only the missing tables
    for (const tableName of missingTables) {
      if (tableDefinitions[tableName]) {
        try {
          console.log(`🔄 Creating table: ${tableName}...`);
          await sequelize.query(tableDefinitions[tableName]);
          console.log(`✅ Table "${tableName}" created successfully (or already exists)`);
        } catch (error) {
          // If table already exists, that's fine - CREATE TABLE IF NOT EXISTS should handle this
          if (error.message.includes('already exists') || error.message.includes('Duplicate')) {
            console.log(`⚠️  Table "${tableName}" already exists, skipping`);
          } else {
            console.error(`❌ Failed to create table "${tableName}":`, error.message);
            // Don't throw - continue with other tables
          }
        }
      } else {
        console.warn(`⚠️  No definition found for table: ${tableName}`);
      }
    }
    
      // Add foreign key constraints for course tables if they were created
      // Also check and add foreign keys for existing course tables
      const courseTablesToCheck = ['courses', 'course_contents', 'course_progress', 'course_content_progress'];
      const courseTablesExist = courseTablesToCheck.filter(table => !missingTables.includes(table));
      
      if (missingTables.some(table => courseTablesToCheck.includes(table)) || courseTablesExist.length > 0) {
        console.log('🔄 Ensuring foreign key constraints exist for course tables...');
        const foreignKeys = [];
        
        // Check if course_contents table exists (newly created or existing)
        if (missingTables.includes('course_contents') || courseTablesExist.includes('course_contents')) {
          foreignKeys.push({
            name: 'fk_course_contents_course_id',
            sql: 'ALTER TABLE course_contents ADD CONSTRAINT fk_course_contents_course_id FOREIGN KEY (courseId) REFERENCES courses(id) ON DELETE CASCADE',
            table: 'course_contents'
          });
        }
        
        // Check if course_progress table exists (newly created or existing)
        if (missingTables.includes('course_progress') || courseTablesExist.includes('course_progress')) {
          foreignKeys.push(
            {
              name: 'fk_course_progress_user_id',
              sql: 'ALTER TABLE course_progress ADD CONSTRAINT fk_course_progress_user_id FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE',
              table: 'course_progress'
            },
            {
              name: 'fk_course_progress_course_id',
              sql: 'ALTER TABLE course_progress ADD CONSTRAINT fk_course_progress_course_id FOREIGN KEY (courseId) REFERENCES courses(id) ON DELETE CASCADE',
              table: 'course_progress'
            }
          );
        }
        
        // Check if course_content_progress table exists (newly created or existing)
        if (missingTables.includes('course_content_progress') || courseTablesExist.includes('course_content_progress')) {
          foreignKeys.push(
            {
              name: 'fk_course_content_progress_user_id',
              sql: 'ALTER TABLE course_content_progress ADD CONSTRAINT fk_course_content_progress_user_id FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE',
              table: 'course_content_progress'
            },
            {
              name: 'fk_course_content_progress_course_id',
              sql: 'ALTER TABLE course_content_progress ADD CONSTRAINT fk_course_content_progress_course_id FOREIGN KEY (courseId) REFERENCES courses(id) ON DELETE CASCADE',
              table: 'course_content_progress'
            },
            {
              name: 'fk_course_content_progress_content_id',
              sql: 'ALTER TABLE course_content_progress ADD CONSTRAINT fk_course_content_progress_content_id FOREIGN KEY (courseContentId) REFERENCES course_contents(id) ON DELETE CASCADE',
              table: 'course_content_progress'
            }
          );
        }
        
        // Check if foreign keys exist before adding them
        for (const fk of foreignKeys) {
          try {
            // Check if constraint already exists
            const [constraints] = await sequelize.query(`
              SELECT CONSTRAINT_NAME 
              FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = '${fk.table}' 
              AND CONSTRAINT_NAME = '${fk.name}'
            `);
            
            if (constraints.length === 0) {
              // Constraint doesn't exist, add it
              await sequelize.query(fk.sql);
              console.log(`✅ Foreign key constraint ${fk.name} added for ${fk.table}`);
            } else {
              console.log(`✅ Foreign key constraint ${fk.name} already exists for ${fk.table}`);
            }
          } catch (error) {
            if (error.message.includes('Duplicate key name') || error.message.includes('already exists') || error.message.includes('Duplicate')) {
              console.log(`⚠️  Foreign key constraint ${fk.name} already exists, skipping`);
            } else {
              console.log(`⚠️  Foreign key constraint ${fk.name} failed (non-critical):`, error.message);
              // Don't throw - foreign keys are nice to have but not critical for functionality
            }
          }
        }
      }
    
    console.log('✅ Missing tables creation completed');
  } catch (error) {
    console.error('❌ Error creating missing tables:', error.message);
    // Don't throw - allow server to continue even if some tables fail
    console.error('⚠️  Server will continue, but some features may not work until tables are created');
  }
};

// Legacy function - kept for backward compatibility but should not be used
const createAllMySQLTables = async (sequelize) => {
  try {
    console.log('🔄 Creating all MySQL-compatible tables...');
    console.log('⚠️  WARNING: This function creates all tables. Use createMissingTablesOnly instead.');
    
    // Create tables with MySQL-compatible syntax
    const tables = [
      // Users table
      `CREATE TABLE IF NOT EXISTS users (
        id CHAR(36) PRIMARY KEY,
        fullName VARCHAR(255) NOT NULL,
        phoneNumber VARCHAR(20) UNIQUE NOT NULL,
        email VARCHAR(255),
        deviceId VARCHAR(255),
        role ENUM('USER', 'ADMIN') DEFAULT 'USER',
        isActive BOOLEAN DEFAULT true,
        isBlocked BOOLEAN DEFAULT false,
        blockReason TEXT NULL,
        blockedAt TIMESTAMP NULL,
        lastLogin TIMESTAMP NULL,
        lastSyncAt TIMESTAMP NULL,
        resetCode VARCHAR(255) NULL,
        resetCodeExpires TIMESTAMP NULL,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      // Exams table
      `CREATE TABLE IF NOT EXISTS exams (
        id CHAR(36) PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        category VARCHAR(100),
        difficulty ENUM('EASY', 'MEDIUM', 'HARD') DEFAULT 'MEDIUM',
        duration INTEGER DEFAULT 30,
        passingScore INTEGER DEFAULT 60,
        examImgUrl VARCHAR(500) NULL,
        examType ENUM('kinyarwanda', 'english', 'french') DEFAULT 'english',
        isActive BOOLEAN DEFAULT true,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      // Questions table
      `CREATE TABLE IF NOT EXISTS questions (
        id CHAR(36) PRIMARY KEY,
        examId CHAR(36) NOT NULL,
        question TEXT NOT NULL,
        option1 TEXT NOT NULL,
        option2 TEXT NOT NULL,
        option3 TEXT NOT NULL,
        option4 TEXT NOT NULL,
        correctAnswer TEXT NOT NULL,
        points INTEGER DEFAULT 1,
        questionOrder INTEGER DEFAULT 1,
        questionImgUrl VARCHAR(500) NULL,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      // Exam Results table
      `CREATE TABLE IF NOT EXISTS exam_results (
        id CHAR(36) PRIMARY KEY,
        examId CHAR(36) NOT NULL,
        userId CHAR(36) NOT NULL,
        score INTEGER NOT NULL,
        totalQuestions INTEGER NOT NULL,
        correctAnswers INTEGER NOT NULL,
        timeSpent INTEGER NOT NULL,
        passed BOOLEAN NOT NULL,
        isFreeExam BOOLEAN DEFAULT false,
        questionResults JSON NULL,
        answers JSON NULL,
        completedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      // Payment Requests table
      `CREATE TABLE IF NOT EXISTS payment_requests (
        id CHAR(36) PRIMARY KEY,
        userId CHAR(36) NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        status ENUM('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',
        paymentMethod VARCHAR(50),
        transactionId VARCHAR(255),
        notes TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      // Access Codes table
      `CREATE TABLE IF NOT EXISTS access_codes (
        id CHAR(36) PRIMARY KEY,
        code VARCHAR(50) UNIQUE NOT NULL,
        userId CHAR(36),
        examId CHAR(36),
        isUsed BOOLEAN DEFAULT false,
        paymentTier VARCHAR(50) DEFAULT 'BASIC',
        paymentAmount DECIMAL(10,2) NULL,
        durationDays INTEGER DEFAULT 30,
        generatedByManagerId CHAR(36) NULL,
        expiresAt TIMESTAMP NULL,
        usedAt TIMESTAMP NULL,
        attemptCount INTEGER DEFAULT 0,
        lastAttemptAt TIMESTAMP NULL,
        isBlocked BOOLEAN DEFAULT false,
        blockedUntil TIMESTAMP NULL,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      // Notifications table
      `CREATE TABLE IF NOT EXISTS notifications (
        id CHAR(36) PRIMARY KEY,
        userId CHAR(36) NOT NULL,
        type VARCHAR(50) NOT NULL,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        data JSON DEFAULT ('{}'),
        isRead BOOLEAN DEFAULT false,
        isPushSent BOOLEAN DEFAULT false,
        scheduledFor TIMESTAMP NULL,
        priority VARCHAR(20) DEFAULT 'MEDIUM',
        category VARCHAR(20) NOT NULL,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      // Study reminders table
      `CREATE TABLE IF NOT EXISTS studyreminders (
        id CHAR(36) PRIMARY KEY,
        userId CHAR(36) NOT NULL,
        isEnabled BOOLEAN DEFAULT true,
        reminderTime TIME NOT NULL,
        daysOfWeek JSON DEFAULT ('[]'),
        studyGoalMinutes INTEGER DEFAULT 30,
        timezone VARCHAR(50) DEFAULT 'UTC',
        lastSentAt TIMESTAMP NULL,
        nextScheduledAt TIMESTAMP NULL,
        isActive BOOLEAN DEFAULT true,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      // Notification preferences table
      `CREATE TABLE IF NOT EXISTS notificationpreferences (
        id CHAR(36) PRIMARY KEY,
        userId CHAR(36) NOT NULL UNIQUE,
        pushNotifications BOOLEAN DEFAULT true,
        smsNotifications BOOLEAN DEFAULT true,
        examReminders BOOLEAN DEFAULT true,
        paymentUpdates BOOLEAN DEFAULT true,
        systemAnnouncements BOOLEAN DEFAULT true,
        studyReminders BOOLEAN DEFAULT true,
        achievementNotifications BOOLEAN DEFAULT true,
        weeklyReports BOOLEAN DEFAULT true,
        quietHoursEnabled BOOLEAN DEFAULT true,
        quietHoursStart TIME DEFAULT '22:00:00',
        quietHoursEnd TIME DEFAULT '07:00:00',
        vibrationEnabled BOOLEAN DEFAULT true,
        soundEnabled BOOLEAN DEFAULT true,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      // Courses table
      `CREATE TABLE IF NOT EXISTS courses (
        id CHAR(36) PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        description TEXT NULL,
        category VARCHAR(100) NULL,
        difficulty ENUM('EASY', 'MEDIUM', 'HARD') DEFAULT 'MEDIUM',
        courseType ENUM('free', 'paid') DEFAULT 'free',
        courseImageUrl VARCHAR(500) NULL,
        isActive BOOLEAN DEFAULT true,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      // Course contents table
      `CREATE TABLE IF NOT EXISTS course_contents (
        id CHAR(36) PRIMARY KEY,
        courseId CHAR(36) NOT NULL,
        contentType ENUM('text', 'image', 'audio', 'video', 'link') DEFAULT 'text',
        content TEXT NOT NULL,
        title VARCHAR(255) NULL,
        displayOrder INTEGER DEFAULT 0,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      // Course progress table
      `CREATE TABLE IF NOT EXISTS course_progress (
        id CHAR(36) PRIMARY KEY,
        userId CHAR(36) NOT NULL,
        courseId CHAR(36) NOT NULL,
        completedContentCount INTEGER DEFAULT 0,
        totalContentCount INTEGER DEFAULT 0,
        progressPercentage DECIMAL(5,2) DEFAULT 0.00,
        isCompleted BOOLEAN DEFAULT false,
        lastAccessedAt TIMESTAMP NULL,
        completedAt TIMESTAMP NULL,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY unique_user_course (userId, courseId)
      )`,
      
      // Course content progress table
      `CREATE TABLE IF NOT EXISTS course_content_progress (
        id CHAR(36) PRIMARY KEY,
        userId CHAR(36) NOT NULL,
        courseId CHAR(36) NOT NULL,
        courseContentId CHAR(36) NOT NULL,
        isCompleted BOOLEAN DEFAULT false,
        completedAt TIMESTAMP NULL,
        timeSpent INTEGER DEFAULT 0,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY unique_user_content (userId, courseContentId)
      )`
    ];
    
    // Create tables
    for (let i = 0; i < tables.length; i++) {
      try {
        console.log(`🔄 Creating table ${i + 1}/${tables.length}...`);
        console.log(`🔍 SQL: ${tables[i].substring(0, 100)}...`);
        await sequelize.query(tables[i]);
        console.log(`✅ Table ${i + 1} created successfully`);
      } catch (error) {
        if (error.message.includes('already exists')) {
          console.log(`⚠️  Table ${i + 1} already exists, skipping`);
        } else {
          console.error(`❌ Failed to create table ${i + 1}:`, error.message);
          console.error(`🔍 Full SQL:`, tables[i]);
          throw error;
        }
      }
    }
    
    // Add foreign key constraints after all tables are created
    console.log('🔄 Adding foreign key constraints...');
    const foreignKeys = [
      'ALTER TABLE questions ADD CONSTRAINT fk_questions_exam_id FOREIGN KEY (examId) REFERENCES exams(id) ON DELETE CASCADE',
      'ALTER TABLE exam_results ADD CONSTRAINT fk_exam_results_exam_id FOREIGN KEY (examId) REFERENCES exams(id) ON DELETE CASCADE',
      'ALTER TABLE exam_results ADD CONSTRAINT fk_exam_results_user_id FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE',
      'ALTER TABLE payment_requests ADD CONSTRAINT fk_payment_requests_user_id FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE',
      'ALTER TABLE access_codes ADD CONSTRAINT fk_access_codes_user_id FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE',
      'ALTER TABLE access_codes ADD CONSTRAINT fk_access_codes_exam_id FOREIGN KEY (examId) REFERENCES exams(id) ON DELETE CASCADE',
      'ALTER TABLE notifications ADD CONSTRAINT fk_notifications_user_id FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE',
      'ALTER TABLE studyreminders ADD CONSTRAINT fk_studyreminders_user_id FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE',
      'ALTER TABLE notificationpreferences ADD CONSTRAINT fk_notificationpreferences_user_id FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE',
      'ALTER TABLE course_contents ADD CONSTRAINT fk_course_contents_course_id FOREIGN KEY (courseId) REFERENCES courses(id) ON DELETE CASCADE',
      'ALTER TABLE course_progress ADD CONSTRAINT fk_course_progress_user_id FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE',
      'ALTER TABLE course_progress ADD CONSTRAINT fk_course_progress_course_id FOREIGN KEY (courseId) REFERENCES courses(id) ON DELETE CASCADE',
      'ALTER TABLE course_content_progress ADD CONSTRAINT fk_course_content_progress_user_id FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE',
      'ALTER TABLE course_content_progress ADD CONSTRAINT fk_course_content_progress_course_id FOREIGN KEY (courseId) REFERENCES courses(id) ON DELETE CASCADE',
      'ALTER TABLE course_content_progress ADD CONSTRAINT fk_course_content_progress_content_id FOREIGN KEY (courseContentId) REFERENCES course_contents(id) ON DELETE CASCADE'
    ];
    
    for (const fk of foreignKeys) {
      try {
        await sequelize.query(fk);
        console.log('✅ Foreign key constraint added');
      } catch (error) {
        if (error.message.includes('Duplicate key name') || error.message.includes('already exists')) {
          console.log('⚠️  Foreign key constraint already exists, skipping');
        } else {
          console.log('⚠️  Foreign key constraint failed:', error.message);
        }
      }
    }

    // Create indexes
    console.log('🔄 Creating indexes...');
    const indexes = [
      'CREATE INDEX IF NOT EXISTS idx_users_phone_number ON users(phoneNumber)',
      'CREATE INDEX IF NOT EXISTS idx_users_device_id ON users(deviceId)',
      'CREATE INDEX IF NOT EXISTS idx_exams_category ON exams(category)',
      'CREATE INDEX IF NOT EXISTS idx_exams_is_active ON exams(isActive)',
      'CREATE INDEX IF NOT EXISTS idx_questions_exam_id ON questions(examId)',
      'CREATE INDEX IF NOT EXISTS idx_exam_results_user_id ON exam_results(userId)',
      'CREATE INDEX IF NOT EXISTS idx_exam_results_exam_id ON exam_results(examId)',
      'CREATE INDEX IF NOT EXISTS idx_payment_requests_user_id ON payment_requests(userId)',
      'CREATE INDEX IF NOT EXISTS idx_access_codes_code ON access_codes(code)',
      'CREATE INDEX IF NOT EXISTS idx_access_codes_user_id ON access_codes(userId)',
      'CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(userId)',
      'CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type)',
      'CREATE INDEX IF NOT EXISTS idx_notifications_scheduled_for ON notifications(scheduledFor)',
      'CREATE INDEX IF NOT EXISTS idx_studyreminders_user_id ON studyreminders(userId)',
      'CREATE INDEX IF NOT EXISTS idx_studyreminders_is_enabled ON studyreminders(isEnabled)',
      'CREATE INDEX IF NOT EXISTS idx_notificationpreferences_user_id ON notificationpreferences(userId)',
      'CREATE INDEX IF NOT EXISTS idx_courses_category ON courses(category)',
      'CREATE INDEX IF NOT EXISTS idx_courses_course_type ON courses(courseType)',
      'CREATE INDEX IF NOT EXISTS idx_courses_is_active ON courses(isActive)',
      'CREATE INDEX IF NOT EXISTS idx_course_contents_course_id ON course_contents(courseId)',
      'CREATE INDEX IF NOT EXISTS idx_course_contents_display_order ON course_contents(displayOrder)',
      'CREATE INDEX IF NOT EXISTS idx_course_progress_user_id ON course_progress(userId)',
      'CREATE INDEX IF NOT EXISTS idx_course_progress_course_id ON course_progress(courseId)',
      'CREATE INDEX IF NOT EXISTS idx_course_content_progress_user_id ON course_content_progress(userId)',
      'CREATE INDEX IF NOT EXISTS idx_course_content_progress_course_id ON course_content_progress(courseId)',
      'CREATE INDEX IF NOT EXISTS idx_course_content_progress_content_id ON course_content_progress(courseContentId)'
    ];
    
    for (const index of indexes) {
      try {
        await sequelize.query(index);
        console.log('✅ Index created');
      } catch (error) {
        console.log('⚠️  Index may already exist:', error.message);
      }
    }
    
    // Add missing columns to existing tables
    console.log('🔄 Checking for missing columns in existing tables...');
    await addMissingColumns(sequelize);
    await addMissingAccessCodesColumns(sequelize);
    await addMissingExamsColumns(sequelize);
    await addMissingQuestionsColumns(sequelize);
    await addMissingExamResultsColumns(sequelize);
    await addMissingAccessCodesAdditionalColumns(sequelize);
    await addMissingNotificationPreferencesColumns(sequelize);
    await addMissingCoursesColumns(sequelize);
    await refreshTableCache(sequelize);
    
    console.log('🎉 All MySQL tables created successfully!');
    
  } catch (error) {
    console.error('❌ MySQL table creation failed:', error.message);
    throw error;
  }
};

// Add missing columns to existing tables
const addMissingColumns = async (sequelize) => {
  try {
    // Check if columns exist first (MySQL doesn't support ADD COLUMN IF NOT EXISTS)
    const checkColumns = await sequelize.query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'users' 
      AND COLUMN_NAME IN ('isBlocked', 'blockReason', 'blockedAt', 'lastSyncAt', 'resetCode', 'resetCodeExpires')
    `);
    
    const existingColumns = checkColumns[0].map(row => row.COLUMN_NAME);
    console.log('📋 Existing columns in users table:', existingColumns);
    
    const columnsToAdd = [
      { name: 'isBlocked', type: 'BOOLEAN DEFAULT false' },
      { name: 'blockReason', type: 'TEXT NULL' },
      { name: 'blockedAt', type: 'TIMESTAMP NULL' },
      { name: 'lastSyncAt', type: 'TIMESTAMP NULL' },
      { name: 'resetCode', type: 'VARCHAR(255) NULL' },
      { name: 'resetCodeExpires', type: 'TIMESTAMP NULL' }
    ];
    
    for (const column of columnsToAdd) {
      if (!existingColumns.includes(column.name)) {
        try {
          console.log(`🔄 Adding column: ${column.name}`);
          await sequelize.query(`ALTER TABLE users ADD COLUMN ${column.name} ${column.type}`);
          console.log(`✅ Column ${column.name} added successfully`);
        } catch (error) {
          console.log(`⚠️  Failed to add column ${column.name}:`, error.message);
        }
      } else {
        console.log(`✅ Column ${column.name} already exists, skipping`);
      }
    }
  } catch (error) {
    console.log('⚠️  Error checking/adding missing columns:', error.message);
  }
};

// Add missing columns to access_codes table
const addMissingAccessCodesColumns = async (sequelize) => {
  try {
    console.log('🔄 Checking for missing columns in access_codes table...');
    
    const checkColumns = await sequelize.query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'access_codes' 
      AND COLUMN_NAME = 'paymentTier'
    `);
    
    const existingColumns = checkColumns[0].map(row => row.COLUMN_NAME);
    console.log('📋 Existing columns in access_codes table:', existingColumns);
    
    if (!existingColumns.includes('paymentTier')) {
      try {
        console.log('🔄 Adding column: paymentTier');
        await sequelize.query(`ALTER TABLE access_codes ADD COLUMN paymentTier VARCHAR(50) DEFAULT 'BASIC'`);
        console.log('✅ Column paymentTier added successfully');
      } catch (error) {
        console.log('⚠️  Failed to add column paymentTier:', error.message);
      }
    } else {
      console.log('✅ Column paymentTier already exists, skipping');
    }
  } catch (error) {
    console.log('⚠️  Error checking/adding missing columns in access_codes:', error.message);
  }
};

// Add missing columns to exams table
const addMissingExamsColumns = async (sequelize) => {
  try {
    console.log('🔄 Checking for missing columns in exams table...');
    
    const checkColumns = await sequelize.query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'exams' 
      AND COLUMN_NAME IN ('examImgUrl', 'examType')
    `);
    
    const existingColumns = checkColumns[0].map(row => row.COLUMN_NAME);
    console.log('📋 Existing columns in exams table:', existingColumns);
    
    // Add examImgUrl if missing
    if (!existingColumns.includes('examImgUrl')) {
      try {
        console.log('🔄 Adding column: examImgUrl');
        await sequelize.query(`ALTER TABLE exams ADD COLUMN examImgUrl VARCHAR(500) NULL`);
        console.log('✅ Column examImgUrl added successfully');
      } catch (error) {
        console.log('⚠️  Failed to add column examImgUrl:', error.message);
      }
    } else {
      console.log('✅ Column examImgUrl already exists, skipping');
    }
    
    // Add examType if missing
    if (!existingColumns.includes('examType')) {
      try {
        console.log('🔄 Adding column: examType');
        // First check if ENUM type exists, if not create it
        await sequelize.query(`
          ALTER TABLE exams 
          ADD COLUMN examType ENUM('kinyarwanda', 'english', 'french') 
          DEFAULT 'english'
        `);
        console.log('✅ Column examType added successfully');
      } catch (error) {
        console.log('⚠️  Failed to add column examType:', error.message);
        // If ENUM doesn't work, try VARCHAR as fallback
        try {
          console.log('🔄 Trying VARCHAR as fallback for examType...');
          await sequelize.query(`
            ALTER TABLE exams 
            ADD COLUMN examType VARCHAR(20) 
            DEFAULT 'english'
          `);
          console.log('✅ Column examType added as VARCHAR successfully');
        } catch (fallbackError) {
          console.log('⚠️  Failed to add column examType as VARCHAR:', fallbackError.message);
        }
      }
    } else {
      console.log('✅ Column examType already exists, skipping');
      
      // Update existing exams with NULL examType to default 'english'
      try {
        console.log('🔄 Updating existing exams with NULL examType to default...');
        const updateResult = await sequelize.query(`
          UPDATE exams 
          SET examType = 'kinyarwanda' 
          WHERE examType IS NULL
        `);
        console.log(`✅ Updated ${updateResult[0].affectedRows || 0} exams with NULL examType`);
      } catch (updateError) {
        console.log('⚠️  Failed to update NULL examType values:', updateError.message);
      }
    }
  } catch (error) {
    console.log('⚠️  Error checking/adding missing columns in exams:', error.message);
  }
};

// Add missing columns to questions table
const addMissingQuestionsColumns = async (sequelize) => {
  try {
    console.log('🔄 Checking for missing columns in questions table...');
    
    const checkColumns = await sequelize.query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'questions' 
      AND COLUMN_NAME = 'questionImgUrl'
    `);
    
    const existingColumns = checkColumns[0].map(row => row.COLUMN_NAME);
    console.log('📋 Existing columns in questions table:', existingColumns);
    
    if (!existingColumns.includes('questionImgUrl')) {
      try {
        console.log('🔄 Adding column: questionImgUrl');
        await sequelize.query(`ALTER TABLE questions ADD COLUMN questionImgUrl VARCHAR(500) NULL`);
        console.log('✅ Column questionImgUrl added successfully');
      } catch (error) {
        console.log('⚠️  Failed to add column questionImgUrl:', error.message);
      }
    } else {
      console.log('✅ Column questionImgUrl already exists, skipping');
    }
  } catch (error) {
    console.log('⚠️  Error checking/adding missing columns in questions:', error.message);
  }
};

// Add missing columns to exam_results table
const addMissingExamResultsColumns = async (sequelize) => {
  try {
    console.log('🔄 Checking for missing columns in exam_results table...');
    
    const checkColumns = await sequelize.query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'exam_results' 
      AND COLUMN_NAME IN ('questionResults', 'answers', 'completedAt')
    `);
    
    const existingColumns = checkColumns[0].map(row => row.COLUMN_NAME);
    console.log('📋 Existing columns in exam_results table:', existingColumns);
    
    // Add questionResults column if missing
    if (!existingColumns.includes('questionResults')) {
      try {
        console.log('🔄 Adding column: questionResults');
        await sequelize.query(`ALTER TABLE exam_results ADD COLUMN questionResults JSON NULL`);
        console.log('✅ Column questionResults added successfully');
      } catch (error) {
        console.log('⚠️  Failed to add column questionResults:', error.message);
      }
    } else {
      console.log('✅ Column questionResults already exists, skipping');
    }
    
    // Add answers column if missing
    if (!existingColumns.includes('answers')) {
      try {
        console.log('🔄 Adding column: answers');
        await sequelize.query(`ALTER TABLE exam_results ADD COLUMN answers JSON NULL`);
        console.log('✅ Column answers added successfully');
      } catch (error) {
        console.log('⚠️  Failed to add column answers:', error.message);
      }
    } else {
      console.log('✅ Column answers already exists, skipping');
    }
    
    // Check if submittedAt exists and needs to be renamed to completedAt
    const checkSubmittedAt = await sequelize.query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'exam_results' 
      AND COLUMN_NAME = 'submittedAt'
    `);
    
    if (checkSubmittedAt[0].length > 0 && !existingColumns.includes('completedAt')) {
      try {
        console.log('🔄 Renaming column: submittedAt to completedAt');
        await sequelize.query(`ALTER TABLE exam_results CHANGE COLUMN submittedAt completedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP`);
        console.log('✅ Column renamed from submittedAt to completedAt successfully');
      } catch (error) {
        console.log('⚠️  Failed to rename column submittedAt:', error.message);
      }
    } else if (existingColumns.includes('completedAt')) {
      console.log('✅ Column completedAt already exists, skipping rename');
    }
    
  } catch (error) {
    console.log('⚠️  Error checking/adding missing columns in exam_results:', error.message);
  }
};

// Add missing columns to access_codes table (additional columns)
const addMissingAccessCodesAdditionalColumns = async (sequelize) => {
  try {
    console.log('🔄 Checking for additional missing columns in access_codes table...');
    
    const checkColumns = await sequelize.query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'access_codes' 
      AND COLUMN_NAME IN ('generatedByManagerId', 'paymentAmount', 'durationDays', 'usedAt', 'attemptCount', 'lastAttemptAt', 'isBlocked', 'blockedUntil')
    `);
    
    const existingColumns = checkColumns[0].map(row => row.COLUMN_NAME);
    console.log('📋 Existing additional columns in access_codes table:', existingColumns);
    
    const columnsToAdd = [
      { name: 'generatedByManagerId', sql: 'CHAR(36) NULL' },
      { name: 'paymentAmount', sql: 'DECIMAL(10,2) NULL' },
      { name: 'durationDays', sql: 'INTEGER DEFAULT 30' },
      { name: 'usedAt', sql: 'TIMESTAMP NULL' },
      { name: 'attemptCount', sql: 'INTEGER DEFAULT 0' },
      { name: 'lastAttemptAt', sql: 'TIMESTAMP NULL' },
      { name: 'isBlocked', sql: 'BOOLEAN DEFAULT false' },
      { name: 'blockedUntil', sql: 'TIMESTAMP NULL' }
    ];
    
    for (const column of columnsToAdd) {
      if (!existingColumns.includes(column.name)) {
        try {
          console.log(`🔄 Adding column: ${column.name}`);
          await sequelize.query(`ALTER TABLE access_codes ADD COLUMN ${column.name} ${column.sql}`);
          console.log(`✅ Column ${column.name} added successfully`);
        } catch (error) {
          console.log(`⚠️  Failed to add column ${column.name}:`, error.message);
        }
      } else {
        console.log(`✅ Column ${column.name} already exists, skipping`);
      }
    }
  } catch (error) {
    console.log('⚠️  Error checking/adding additional missing columns in access_codes:', error.message);
  }
};

// Add missing columns to notificationpreferences table
const addMissingNotificationPreferencesColumns = async (sequelize) => {
  try {
    console.log('🔄 Checking for missing columns in notificationpreferences table...');
    
    const checkColumns = await sequelize.query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'notificationpreferences' 
      AND COLUMN_NAME IN ('smsNotifications', 'paymentUpdates', 'systemAnnouncements', 'achievementNotifications', 'quietHoursEnabled', 'quietHoursStart', 'quietHoursEnd', 'vibrationEnabled', 'soundEnabled')
    `);
    
    const existingColumns = checkColumns[0].map(row => row.COLUMN_NAME);
    console.log('📋 Existing columns in notificationpreferences table:', existingColumns);
    
    const columnsToAdd = [
      { name: 'smsNotifications', sql: 'BOOLEAN DEFAULT true' },
      { name: 'paymentUpdates', sql: 'BOOLEAN DEFAULT true' },
      { name: 'systemAnnouncements', sql: 'BOOLEAN DEFAULT true' },
      { name: 'achievementNotifications', sql: 'BOOLEAN DEFAULT true' },
      { name: 'quietHoursEnabled', sql: 'BOOLEAN DEFAULT true' },
      { name: 'quietHoursStart', sql: "TIME DEFAULT '22:00:00'" },
      { name: 'quietHoursEnd', sql: "TIME DEFAULT '07:00:00'" },
      { name: 'vibrationEnabled', sql: 'BOOLEAN DEFAULT true' },
      { name: 'soundEnabled', sql: 'BOOLEAN DEFAULT true' }
    ];
    
    for (const column of columnsToAdd) {
      if (!existingColumns.includes(column.name)) {
        try {
          console.log(`🔄 Adding column: ${column.name}`);
          await sequelize.query(`ALTER TABLE notificationpreferences ADD COLUMN ${column.name} ${column.sql}`);
          console.log(`✅ Column ${column.name} added successfully`);
        } catch (error) {
          console.log(`⚠️  Failed to add column ${column.name}:`, error.message);
        }
      } else {
        console.log(`✅ Column ${column.name} already exists, skipping`);
      }
    }
  } catch (error) {
    console.log('⚠️  Error checking/adding missing columns in notificationpreferences:', error.message);
  }
};

// Add missing columns to courses table
const addMissingCoursesColumns = async (sequelize) => {
  try {
    console.log('🔄 Checking for missing columns in courses tables...');
    
    // Check courses table columns
    const coursesColumns = await sequelize.query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'courses'
    `);
    const existingCoursesColumns = coursesColumns[0].map(row => row.COLUMN_NAME);
    
    // Check if courses table exists and has required columns
    if (existingCoursesColumns.length > 0) {
      const requiredCoursesColumns = ['id', 'title', 'description', 'category', 'difficulty', 'courseType', 'courseImageUrl', 'isActive'];
      const missingCoursesColumns = requiredCoursesColumns.filter(col => !existingCoursesColumns.includes(col));
      
      if (missingCoursesColumns.length > 0) {
        console.log(`⚠️  Missing columns in courses table: ${missingCoursesColumns.join(', ')}`);
        // Note: Adding columns to existing table with data is safe, but we'll skip for now
        // to avoid any potential issues. The table should be created with all columns.
      } else {
        console.log('✅ Courses table columns are up to date');
      }
    } else {
      console.log('⚠️  Courses table does not exist - will be created if missing tables are detected');
    }
    
    // Check course_contents table
    const courseContentsColumns = await sequelize.query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'course_contents'
    `);
    const existingContentsColumns = courseContentsColumns[0].map(row => row.COLUMN_NAME);
    
    if (existingContentsColumns.length > 0) {
      console.log('✅ Course contents table columns are up to date');
    }
    
    // Check course_progress table
    const courseProgressColumns = await sequelize.query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'course_progress'
    `);
    const existingProgressColumns = courseProgressColumns[0].map(row => row.COLUMN_NAME);
    
    if (existingProgressColumns.length > 0) {
      console.log('✅ Course progress table columns are up to date');
    }
    
    // Check course_content_progress table
    const courseContentProgressColumns = await sequelize.query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'course_content_progress'
    `);
    const existingContentProgressColumns = courseContentProgressColumns[0].map(row => row.COLUMN_NAME);
    
    if (existingContentProgressColumns.length > 0) {
      console.log('✅ Course content progress table columns are up to date');
    }
    
  } catch (error) {
    // If table doesn't exist, that's okay - it will be created if needed
    if (error.message.includes("doesn't exist") || error.message.includes('Unknown table')) {
      console.log('⚠️  Course tables do not exist yet - will be created if in missing tables list');
    } else {
      console.log('⚠️  Error checking courses tables:', error.message);
    }
  }
};

// Refresh Sequelize table cache to ensure latest schema
const refreshTableCache = async (sequelize) => {
  try {
    console.log('🔄 Refreshing Sequelize table cache...');
    // Force Sequelize to reload table information
    await sequelize.getQueryInterface().showAllTables();
    console.log('✅ Table cache refreshed');
  } catch (error) {
    console.log('⚠️  Error refreshing table cache:', error.message);
  }
};

// Create admin user if it doesn't exist
const createAdminUser = async (sequelize) => {
  try {
    console.log('👤 Ensuring admin user exists...');
    
    const adminExists = await sequelize.query(
      'SELECT id FROM users WHERE phoneNumber = ?',
      { 
        replacements: ['0781234567'],
        type: Sequelize.QueryTypes.SELECT 
      }
    );
    
    if (adminExists.length === 0) {
      console.log('🔄 Creating admin user...');
      await sequelize.query(`
        INSERT INTO users (id, fullName, phoneNumber, deviceId, role, isActive, isBlocked, blockReason, blockedAt, lastSyncAt, resetCode, resetCodeExpires, createdAt, updatedAt)
        VALUES (
          'admin-user-uuid-12345678901234567890123456789012',
          'Admin User',
          '0781234567',
          'admin-device-bypass',
          'ADMIN',
          true,
          false,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NOW(),
          NOW()
        )
      `);
      console.log('✅ Admin user created successfully');
    } else {
      console.log('✅ Admin user already exists');
    }
  } catch (adminError) {
    console.error('❌ Admin user creation failed:', adminError.message);
    console.error('🔍 Full error:', adminError);
  }
};

// Create MySQL-compatible tables
const createMySQLTables = async (sequelize) => {
  try {
    console.log('🔄 Creating MySQL-compatible tables...');
    
    // Create tables with MySQL-compatible syntax
    const tables = [
      // Notifications table
      `CREATE TABLE IF NOT EXISTS notifications (
        id CHAR(36) PRIMARY KEY,
        userId CHAR(36) NOT NULL,
        type VARCHAR(50) NOT NULL,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        data JSON DEFAULT ('{}'),
        isRead BOOLEAN DEFAULT false,
        isPushSent BOOLEAN DEFAULT false,
        scheduledFor TIMESTAMP NULL,
        priority VARCHAR(20) DEFAULT 'MEDIUM',
        category VARCHAR(20) NOT NULL,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      // Study reminders table
      `CREATE TABLE IF NOT EXISTS studyreminders (
        id CHAR(36) PRIMARY KEY,
        userId CHAR(36) NOT NULL,
        isEnabled BOOLEAN DEFAULT true,
        reminderTime TIME NOT NULL,
        daysOfWeek JSON DEFAULT ('[]'),
        studyGoalMinutes INTEGER DEFAULT 30,
        timezone VARCHAR(50) DEFAULT 'UTC',
        lastSentAt TIMESTAMP NULL,
        nextScheduledAt TIMESTAMP NULL,
        isActive BOOLEAN DEFAULT true,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`,
      
      // Notification preferences table
      `CREATE TABLE IF NOT EXISTS notificationpreferences (
        id CHAR(36) PRIMARY KEY,
        userId CHAR(36) NOT NULL UNIQUE,
        pushNotifications BOOLEAN DEFAULT true,
        smsNotifications BOOLEAN DEFAULT true,
        examReminders BOOLEAN DEFAULT true,
        paymentUpdates BOOLEAN DEFAULT true,
        systemAnnouncements BOOLEAN DEFAULT true,
        studyReminders BOOLEAN DEFAULT true,
        achievementNotifications BOOLEAN DEFAULT true,
        weeklyReports BOOLEAN DEFAULT true,
        quietHoursEnabled BOOLEAN DEFAULT true,
        quietHoursStart TIME DEFAULT '22:00:00',
        quietHoursEnd TIME DEFAULT '07:00:00',
        vibrationEnabled BOOLEAN DEFAULT true,
        soundEnabled BOOLEAN DEFAULT true,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )`
    ];
    
    // Create tables
    for (let i = 0; i < tables.length; i++) {
      try {
        console.log(`🔄 Creating table ${i + 1}/${tables.length}...`);
        console.log(`🔍 SQL: ${tables[i].substring(0, 100)}...`);
        await sequelize.query(tables[i]);
        console.log(`✅ Table ${i + 1} created successfully`);
      } catch (error) {
        if (error.message.includes('already exists')) {
          console.log(`⚠️  Table ${i + 1} already exists, skipping`);
        } else {
          console.error(`❌ Failed to create table ${i + 1}:`, error.message);
          console.error(`🔍 Full SQL:`, tables[i]);
          throw error;
        }
      }
    }
    
    // Add foreign key constraints after all tables are created
    console.log('🔄 Adding foreign key constraints...');
    const foreignKeys = [
      'ALTER TABLE notifications ADD CONSTRAINT fk_notifications_user_id FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE',
      'ALTER TABLE studyreminders ADD CONSTRAINT fk_studyreminders_user_id FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE',
      'ALTER TABLE notificationpreferences ADD CONSTRAINT fk_notificationpreferences_user_id FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE'
    ];
    
    for (const fk of foreignKeys) {
      try {
        await sequelize.query(fk);
        console.log('✅ Foreign key constraint added');
      } catch (error) {
        if (error.message.includes('Duplicate key name') || error.message.includes('already exists')) {
          console.log('⚠️  Foreign key constraint already exists, skipping');
        } else {
          console.log('⚠️  Foreign key constraint failed:', error.message);
        }
      }
    }

    // Create indexes
    console.log('🔄 Creating indexes...');
    const indexes = [
      'CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(userId)',
      'CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type)',
      'CREATE INDEX IF NOT EXISTS idx_notifications_scheduled_for ON notifications(scheduledFor)',
      'CREATE INDEX IF NOT EXISTS idx_studyreminders_user_id ON studyreminders(userId)',
      'CREATE INDEX IF NOT EXISTS idx_studyreminders_is_enabled ON studyreminders(isEnabled)',
      'CREATE INDEX IF NOT EXISTS idx_notificationpreferences_user_id ON notificationpreferences(userId)'
    ];
    
    for (const index of indexes) {
      try {
        await sequelize.query(index);
        console.log('✅ Index created');
      } catch (error) {
        console.log('⚠️  Index may already exist:', error.message);
      }
    }
    
    // Check if we need to import data from SQL file
    const userCount = await sequelize.query('SELECT COUNT(*) as count FROM users', { type: Sequelize.QueryTypes.SELECT });
    const examCount = await sequelize.query('SELECT COUNT(*) as count FROM exams', { type: Sequelize.QueryTypes.SELECT });
    const questionCount = await sequelize.query('SELECT COUNT(*) as count FROM questions', { type: Sequelize.QueryTypes.SELECT });
    
    if (userCount[0].count <= 1 || examCount[0].count === 0 || questionCount[0].count === 0) {
      console.log('📊 Importing data from SQL file...');
      try {
        const { spawn } = require('child_process');
        const path = require('path');
        
        await new Promise((resolve, reject) => {
          const importer = spawn('node', [path.join(__dirname, '../../import-data-from-sql.js')], {
            stdio: 'inherit',
            env: process.env
          });
          
          importer.on('close', (code) => {
            if (code === 0) {
              console.log('✅ Data imported successfully from SQL file');
              resolve();
            } else {
              console.log('⚠️  Data import failed, continuing without data');
              resolve(); // Don't fail the server startup
            }
          });
          
          importer.on('error', (error) => {
            console.log('⚠️  Data importer error:', error.message);
            resolve(); // Don't fail the server startup
          });
        });
      } catch (error) {
        console.log('⚠️  Data import failed:', error.message);
      }
    } else {
      console.log('✅ Data already exists, skipping import');
    }
    
    
    // Create sample exams and questions if they don't exist
    console.log('📚 Ensuring sample data exists...');
    try {
      const examCount = await sequelize.query(
        'SELECT COUNT(*) as count FROM exams',
        { type: Sequelize.QueryTypes.SELECT }
      );
      
      if (examCount[0].count === 0) {
        // Create sample exam
        await sequelize.query(`
          INSERT INTO exams (id, title, description, category, difficulty, duration, passingScore, isActive, createdAt, updatedAt)
          VALUES (
            '1',
            'Free Exam',
            'Traffic rules examination 1',
            'Traffic Rules',
            'MEDIUM',
            20,
            60,
            true,
            NOW(),
            NOW()
          )
          ON DUPLICATE KEY UPDATE id=id
        `);
        
        // Create sample questions
        const questions = [
          {
            id: '1_q1',
            examId: '1',
            question: 'What should you do when approaching a red traffic light?',
            option1: 'a) Stop completely',
            option2: 'b) Slow down and proceed if clear',
            option3: 'c) Speed up to beat the light',
            option4: 'd) Honk and proceed',
            correctAnswer: 'a) Stop completely',
            points: 1,
            questionOrder: 1
          },
          {
            id: '1_q2',
            examId: '1',
            question: 'What is the speed limit in a school zone?',
            option1: 'a) 30 mph',
            option2: 'b) 25 mph',
            option3: 'c) 35 mph',
            option4: 'd) 40 mph',
            correctAnswer: 'b) 25 mph',
            points: 1,
            questionOrder: 2
          }
        ];
        
        for (const question of questions) {
          await sequelize.query(`
            INSERT INTO questions (id, examId, question, option1, option2, option3, option4, correctAnswer, points, createdAt, updatedAt, questionOrder)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), ?)
            ON DUPLICATE KEY UPDATE id=id
          `, {
            replacements: [
              question.id,
              question.examId,
              question.question,
              question.option1,
              question.option2,
              question.option3,
              question.option4,
              question.correctAnswer,
              question.points,
              question.questionOrder
            ]
          });
        }
        
        console.log('✅ Sample exam and questions created');
      } else {
        console.log('✅ Sample data already exists');
      }
    } catch (dataError) {
      console.log('⚠️  Sample data creation failed:', dataError.message);
    }
    
    console.log('🎉 MySQL tables created successfully!');
    
  } catch (error) {
    console.error('❌ MySQL table creation failed:', error.message);
    throw error;
  }
};

// Initialize database tables
const initializeTables = async () => {
  // Check if auto-initialization is disabled (production safety)
  const autoInit = process.env.AUTO_DB_INIT !== 'false';
  const isProduction = process.env.NODE_ENV === 'production';
  
  if (isProduction && !autoInit) {
    console.log('⚠️  AUTO_DB_INIT=false: Skipping database table initialization in production');
    console.log('💡 Use migrations or manual initialization for production databases');
    return;
  }

  try {
    console.log('🔄 Starting database table initialization...');
    
    // Import models
    const User = require('../models/User');
    const Exam = require('../models/Exam');
    const PaymentRequest = require('../models/PaymentRequest');
    const AccessCode = require('../models/AccessCode');
    const Question = require('../models/Question');
    const ExamResult = require('../models/ExamResult');
    const Notification = require('../models/Notification');
    const StudyReminder = require('../models/StudyReminder');
    const NotificationPreferences = require('../models/NotificationPreferences');
    const Course = require('../models/Course');
    const CourseContent = require('../models/CourseContent');
    const CourseProgress = require('../models/CourseProgress');
    const CourseContentProgress = require('../models/CourseContentProgress');

    console.log('✅ All models imported successfully');

    // Setup associations
    const setupAssociations = require('./associations');
    setupAssociations();
    console.log('✅ Model associations set up');

    // Check if tables exist, if not, create them using direct SQL
    try {
      const tables = await sequelize.getQueryInterface().showAllTables();
      console.log('📋 Existing tables:', tables);
      
      // Check for all required tables (core + notification + course + call tracking tables)
      const allRequiredTables = [
        'users', 'exams', 'questions', 'exam_results', 'payment_requests', 'access_codes',
        'notifications', 'studyreminders', 'notificationpreferences',
        'courses', 'course_contents', 'course_progress', 'course_content_progress',
        'user_call_tracking'
      ];
      const missingTables = allRequiredTables.filter(table => !tables.includes(table));
      
      if (missingTables.length > 0) {
        console.log('🔄 Missing tables found:', missingTables);
        console.log('🔄 Creating only missing tables (existing tables will not be touched)...');
        // Create only the missing tables, not all tables
        await createMissingTablesOnly(sequelize, missingTables);
      } else {
        console.log('✅ All required tables exist');
      }
      
      // Always check for missing columns in existing tables (this is safe and won't modify data)
      console.log('🔄 Checking for missing columns in existing tables...');
      await addMissingColumns(sequelize);
      await addMissingAccessCodesColumns(sequelize);
      await addMissingExamsColumns(sequelize);
      await addMissingQuestionsColumns(sequelize);
      await addMissingExamResultsColumns(sequelize);
      await addMissingAccessCodesAdditionalColumns(sequelize);
      await addMissingNotificationPreferencesColumns(sequelize);
      await addMissingCoursesColumns(sequelize);
      await refreshTableCache(sequelize);
      
      // Create admin user after ensuring all tables and columns exist
      await createAdminUser(sequelize);
      
    } catch (error) {
      console.error('❌ Error checking tables:', error.message);
      throw error;
    }
    
  } catch (error) {
    console.error('❌ Database synchronization failed:', error.message);
    console.error('🔍 Error details:', {
      name: error.name,
      code: error.code,
      parent: error.parent?.code,
      original: error.original?.code,
      sql: error.sql
    });
    
    // Don't try to recreate all tables on error - this could cause data loss
    // Instead, log the error and let the server continue
    console.error('⚠️  Database initialization had errors, but server will continue');
    console.error('⚠️  Please check the database manually or run migrations');
  }
};

module.exports = {
  sequelize,
  testConnection,
  initializeTables
};
