const { Sequelize } = require('sequelize');
require('dotenv').config();

// Determine database dialect based on environment
const getDatabaseConfig = () => {
  const isProduction = process.env.NODE_ENV === 'production';
  const databaseUrl = process.env.DATABASE_URL; // Render provides this for PostgreSQL
  
  // Debug logging only in development
  if (process.env.NODE_ENV === 'development') {
    console.log('🔍 Environment check:', {
      NODE_ENV: process.env.NODE_ENV,
      DATABASE_URL: databaseUrl ? 'Set' : 'Not set',
      isProduction,
      DB_NAME: process.env.DB_NAME,
      DB_HOST: process.env.DB_HOST
    });
  }
  
  // Use PostgreSQL if DATABASE_URL is set AND we're in production
  // OR if we explicitly want PostgreSQL in development
  if (databaseUrl && isProduction) {
    // Production PostgreSQL configuration (Render)
    return {
      url: databaseUrl,
      dialect: 'postgres',
      dialectOptions: {
        ssl: {
          require: true,
          rejectUnauthorized: false
        }
      },
      logging: false, // Disable logging in production
      pool: {
        max: 5,
        min: 0,
        acquire: 30000,
        idle: 10000
      }
    };
  } else {
    // Development MySQL configuration
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
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    console.error('🔍 Full error details:', error);
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

    // Setup associations
    const setupAssociations = require('./associations');
    setupAssociations();

    // Sync all models - use alter: true for development, force: false for production
    if (process.env.NODE_ENV === 'development') {
      await sequelize.sync({ alter: true });
      console.log('✅ Database tables synchronized successfully');
    } else {
      await sequelize.sync({ force: false });
      console.log('✅ Database tables synchronized successfully');
    }
  } catch (error) {
    console.error('❌ Database synchronization failed:', error.message);
    console.error('🔍 Full sync error details:', error);
  }
};

module.exports = {
  sequelize,
  testConnection,
  initializeTables
};
