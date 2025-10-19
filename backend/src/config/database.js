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
        max: 5,
        min: 0,
        acquire: 30000,
        idle: 10000
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
        max: 5,
        min: 0,
        acquire: 30000,
        idle: 10000
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
const createAllMySQLTables = async (sequelize) => {
  try {
    console.log('🔄 Creating all MySQL-compatible tables...');
    
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
        studyReminders BOOLEAN DEFAULT true,
        examReminders BOOLEAN DEFAULT true,
        achievementAlerts BOOLEAN DEFAULT true,
        paymentNotifications BOOLEAN DEFAULT true,
        systemUpdates BOOLEAN DEFAULT true,
        weeklyReports BOOLEAN DEFAULT true,
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
      'ALTER TABLE questions ADD CONSTRAINT fk_questions_exam_id FOREIGN KEY (examId) REFERENCES exams(id) ON DELETE CASCADE',
      'ALTER TABLE exam_results ADD CONSTRAINT fk_exam_results_exam_id FOREIGN KEY (examId) REFERENCES exams(id) ON DELETE CASCADE',
      'ALTER TABLE exam_results ADD CONSTRAINT fk_exam_results_user_id FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE',
      'ALTER TABLE payment_requests ADD CONSTRAINT fk_payment_requests_user_id FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE',
      'ALTER TABLE access_codes ADD CONSTRAINT fk_access_codes_user_id FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE',
      'ALTER TABLE access_codes ADD CONSTRAINT fk_access_codes_exam_id FOREIGN KEY (examId) REFERENCES exams(id) ON DELETE CASCADE',
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
    
    // Add missing columns to existing tables
    console.log('🔄 Checking for missing columns in existing tables...');
    await addMissingColumns(sequelize);
    await addMissingAccessCodesColumns(sequelize);
    await addMissingExamsColumns(sequelize);
    await addMissingQuestionsColumns(sequelize);
    await addMissingExamResultsColumns(sequelize);
    await addMissingAccessCodesAdditionalColumns(sequelize);
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
      AND COLUMN_NAME = 'examImgUrl'
    `);
    
    const existingColumns = checkColumns[0].map(row => row.COLUMN_NAME);
    console.log('📋 Existing columns in exams table:', existingColumns);
    
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
        studyReminders BOOLEAN DEFAULT true,
        examReminders BOOLEAN DEFAULT true,
        achievementAlerts BOOLEAN DEFAULT true,
        paymentNotifications BOOLEAN DEFAULT true,
        systemUpdates BOOLEAN DEFAULT true,
        weeklyReports BOOLEAN DEFAULT true,
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

    console.log('✅ All models imported successfully');

    // Setup associations
    const setupAssociations = require('./associations');
    setupAssociations();
    console.log('✅ Model associations set up');

    // Check if tables exist, if not, create them using direct SQL
    try {
      const tables = await sequelize.getQueryInterface().showAllTables();
      console.log('📋 Existing tables:', tables);
      
      // Check for all required tables (core + notification tables)
      const allRequiredTables = [
        'users', 'exams', 'questions', 'exam_results', 'payment_requests', 'access_codes',
        'notifications', 'studyreminders', 'notificationpreferences'
      ];
      const missingTables = allRequiredTables.filter(table => !tables.includes(table));
      
      if (missingTables.length > 0) {
        console.log('🔄 Missing tables found:', missingTables);
        console.log('🔄 Creating missing tables...');
        await createAllMySQLTables(sequelize);
      } else {
        console.log('✅ All required tables exist');
        // Still check for missing columns in existing tables
        console.log('🔄 Checking for missing columns...');
        await addMissingColumns(sequelize);
        await addMissingAccessCodesColumns(sequelize);
        await addMissingExamsColumns(sequelize);
        await addMissingQuestionsColumns(sequelize);
        await addMissingExamResultsColumns(sequelize);
        await addMissingAccessCodesAdditionalColumns(sequelize);
        await refreshTableCache(sequelize);
      }
      
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
    
    // Try to create tables individually if sync fails
    console.log('🔄 Attempting to create tables individually...');
    try {
      // Create a new connection to avoid transaction issues
      const newSequelize = new Sequelize(getDatabaseConfig());
      await newSequelize.authenticate();
      await createAllMySQLTables(newSequelize);
      await newSequelize.close();
      console.log('✅ Database tables created successfully');
    } catch (individualError) {
      console.error('❌ Individual table creation also failed:', individualError.message);
      throw individualError;
    }
  }
};

module.exports = {
  sequelize,
  testConnection,
  initializeTables
};
