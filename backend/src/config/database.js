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
    // Production PostgreSQL configuration (Render)
    console.log('🐘 Using PostgreSQL configuration for production');
    console.log('🔍 DATABASE_URL:', databaseUrl.replace(/:[^:@]+@/, ':***@')); // Hide password in logs
    
    // Fix DATABASE_URL for Render internal URLs
    let fixedDatabaseUrl = databaseUrl;
    
    // If it's an external URL (.ohio-postgres.render.com), convert to internal
    if (databaseUrl.includes('.ohio-postgres.render.com')) {
      fixedDatabaseUrl = databaseUrl.replace('.ohio-postgres.render.com:5432', '');
      console.log('🔧 Converted external URL to internal URL:', fixedDatabaseUrl.replace(/:[^:@]+@/, ':***@'));
    }
    // If it's an internal URL without port, add port
    else if (databaseUrl.includes('@dpg-') && !databaseUrl.includes(':5432')) {
      // Check if there's already a port after the @ symbol
      const atIndex = databaseUrl.indexOf('@');
      const afterAt = databaseUrl.substring(atIndex);
      if (!afterAt.includes(':')) {
        fixedDatabaseUrl = databaseUrl.replace('@dpg-', ':5432@dpg-');
        console.log('🔧 Fixed DATABASE_URL to include port:', fixedDatabaseUrl.replace(/:[^:@]+@/, ':***@'));
      }
    }
    
    return {
      url: fixedDatabaseUrl,
      dialect: 'postgres',
      dialectOptions: {
        ssl: {
          require: true,
          rejectUnauthorized: false
        }
      },
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
    console.log('🐘 Using PostgreSQL configuration with individual env vars');
    console.log('🔍 Database config:', {
      database: process.env.DB_NAME || 'traffic_rules_db',
      username: process.env.DB_USER || process.env.POSTGRES_USER,
      host: process.env.DB_HOST || process.env.POSTGRES_HOST || 'localhost',
      port: process.env.DB_PORT || process.env.POSTGRES_PORT || 5432,
      hasPassword: !!(process.env.DB_PASSWORD || process.env.POSTGRES_PASSWORD)
    });
    
    return {
      database: process.env.DB_NAME || 'traffic_rules_db',
      username: process.env.DB_USER || process.env.POSTGRES_USER,
      password: process.env.DB_PASSWORD || process.env.POSTGRES_PASSWORD,
      host: process.env.DB_HOST || process.env.POSTGRES_HOST || 'localhost',
      port: process.env.DB_PORT || process.env.POSTGRES_PORT || 5432,
      dialect: 'postgres',
      dialectOptions: {
        ssl: {
          require: true,
          rejectUnauthorized: false
        }
      },
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
          console.error('🔍 Expected format: postgresql://username:password@hostname:port/database_name');
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
          console.error('   For Render PostgreSQL, use: dpg-xxxxx.ohio-postgres.render.com');
          console.error('   Instead of: dpg-xxxxx');
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

// Create PostgreSQL-compatible tables
const createPostgreSQLTables = async (sequelize) => {
  try {
    console.log('🔄 Creating PostgreSQL-compatible tables...');
    
    // Create tables with PostgreSQL-compatible syntax
    const tables = [
      // Notifications table
      `CREATE TABLE IF NOT EXISTS notifications (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "userId" UUID NOT NULL,
        type VARCHAR(50) NOT NULL CHECK (type IN ('EXAM_REMINDER','ACHIEVEMENT_ALERT','STUDY_REMINDER','SYSTEM_UPDATE','PAYMENT_NOTIFICATION','WEEKLY_REPORT','PAYMENT_APPROVED','PAYMENT_REJECTED','EXAM_PASSED','EXAM_FAILED','NEW_EXAM','ACCESS_GRANTED','ACCESS_REVOKED','GENERAL')),
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        data JSONB DEFAULT '{}',
        "isRead" BOOLEAN DEFAULT false,
        "isPushSent" BOOLEAN DEFAULT false,
        "scheduledFor" TIMESTAMP WITH TIME ZONE,
        priority VARCHAR(20) DEFAULT 'MEDIUM' CHECK (priority IN ('LOW','MEDIUM','HIGH','URGENT')),
        category VARCHAR(20) NOT NULL CHECK (category IN ('EXAM','PAYMENT','ACHIEVEMENT','SYSTEM','STUDY','ACCESS','GENERAL')),
        "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
        FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE CASCADE
      )`,
      
      // Study reminders table
      `CREATE TABLE IF NOT EXISTS studyreminders (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "userId" UUID NOT NULL,
        "isEnabled" BOOLEAN DEFAULT true,
        "reminderTime" TIME NOT NULL,
        "daysOfWeek" JSONB NOT NULL DEFAULT '[]',
        "studyGoalMinutes" INTEGER DEFAULT 30,
        timezone VARCHAR(50) DEFAULT 'UTC',
        "lastSentAt" TIMESTAMP WITH TIME ZONE,
        "nextScheduledAt" TIMESTAMP WITH TIME ZONE,
        "isActive" BOOLEAN DEFAULT true,
        "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
        FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE CASCADE
      )`,
      
      // Notification preferences table
      `CREATE TABLE IF NOT EXISTS notificationpreferences (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        "userId" UUID NOT NULL UNIQUE,
        "pushNotifications" BOOLEAN DEFAULT true,
        "studyReminders" BOOLEAN DEFAULT true,
        "examReminders" BOOLEAN DEFAULT true,
        "achievementAlerts" BOOLEAN DEFAULT true,
        "paymentNotifications" BOOLEAN DEFAULT true,
        "systemUpdates" BOOLEAN DEFAULT true,
        "weeklyReports" BOOLEAN DEFAULT true,
        "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
        "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
        FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE CASCADE
      )`
    ];
    
    // Create tables
    for (let i = 0; i < tables.length; i++) {
      try {
        console.log(`🔄 Creating table ${i + 1}/${tables.length}...`);
        await sequelize.query(tables[i]);
        console.log(`✅ Table ${i + 1} created successfully`);
      } catch (error) {
        if (error.message.includes('already exists')) {
          console.log(`⚠️  Table ${i + 1} already exists, skipping`);
        } else {
          console.error(`❌ Failed to create table ${i + 1}:`, error.message);
          throw error;
        }
      }
    }
    
    // Create indexes
    console.log('🔄 Creating indexes...');
    const indexes = [
      'CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications("userId")',
      'CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type)',
      'CREATE INDEX IF NOT EXISTS idx_notifications_scheduled_for ON notifications("scheduledFor")',
      'CREATE INDEX IF NOT EXISTS idx_studyreminders_user_id ON studyreminders("userId")',
      'CREATE INDEX IF NOT EXISTS idx_studyreminders_is_enabled ON studyreminders("isEnabled")',
      'CREATE INDEX IF NOT EXISTS idx_notificationpreferences_user_id ON notificationpreferences("userId")'
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
    
    console.log('🎉 PostgreSQL tables created successfully!');
    
  } catch (error) {
    console.error('❌ PostgreSQL table creation failed:', error.message);
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
      
      if (tables.length === 0) {
        console.log('🔄 No tables found, creating from SQL...');
        await createTablesFromSQL(sequelize);
      } else {
        console.log('✅ Database tables already exist, checking for missing tables...');
        
        // Check if notification tables are missing
        const requiredTables = ['notifications', 'studyreminders', 'notificationpreferences'];
        const missingTables = requiredTables.filter(table => !tables.includes(table));
        
        if (missingTables.length > 0) {
          console.log('🔄 Missing tables found:', missingTables);
          console.log('🔄 Creating missing tables...');
          await createPostgreSQLTables(sequelize);
        } else {
          console.log('✅ All required tables exist');
        }
      }
      
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
      const newSequelize = new Sequelize(sequelize.config);
      await newSequelize.authenticate();
      await createPostgreSQLTables(newSequelize);
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
