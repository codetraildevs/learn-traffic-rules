const { Sequelize } = require('sequelize');
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

// Initialize database tables
const initializeTables = async () => {
  try {
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

    // Setup associations
    const setupAssociations = require('./associations');
    setupAssociations();

    // Sync all models - create tables if they don't exist
    if (process.env.FORCE_SYNC === 'true') {
      console.log('🔄 Force syncing database to apply new structure...');
      await sequelize.sync({ force: true });
      console.log('✅ Database tables recreated with new structure');
    } else {
      // For production, use alter: true to create missing tables
      await sequelize.sync({ force: false, alter: true });
      console.log('✅ Database tables synchronized successfully');
    }
  } catch (error) {
    console.error('❌ Database synchronization failed:', error.message);
  }
};

module.exports = {
  sequelize,
  testConnection,
  initializeTables
};
