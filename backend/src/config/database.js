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
    return {
      url: databaseUrl,
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
      }
    };
  } else if (isProduction) {
    // Production without DATABASE_URL - use individual env vars
    console.log('🐘 Using PostgreSQL configuration with individual env vars');
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
  try {
    await sequelize.authenticate();
    console.log('✅ Database connected successfully');
    return true;
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    console.error('🔍 Error details:', {
      name: error.name,
      code: error.code,
      parent: error.parent?.code,
      original: error.original?.code
    });
    
    // If it's a connection refused error, provide helpful message
    if (error.name === 'SequelizeConnectionRefusedError' || error.code === 'ECONNREFUSED') {
      console.error('💡 Database connection troubleshooting:');
      console.error('   1. Check if DATABASE_URL is set in environment variables');
      console.error('   2. Verify database credentials are correct');
      console.error('   3. Ensure database server is running and accessible');
      console.error('   4. Check firewall settings and network connectivity');
    }
    
    return false;
  }
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

    // Sync all models - only force sync when explicitly requested
    if (process.env.FORCE_SYNC === 'true') {
      console.log('🔄 Force syncing database to apply new structure...');
      await sequelize.sync({ force: true });
      console.log('✅ Database tables recreated with new structure');
    } else {
      await sequelize.sync({ force: false, alter: false });
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
