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

// Create tables from SQL file
const createTablesFromSQL = async (sequelize) => {
  try {
    // Read SQL file
    const sqlFilePath = path.join(__dirname, '../../traffic_rules_db.sql');
    if (!fs.existsSync(sqlFilePath)) {
      throw new Error(`SQL file not found: ${sqlFilePath}`);
    }
    
    const sqlContent = fs.readFileSync(sqlFilePath, 'utf8');
    console.log('📄 SQL file loaded successfully');
    
    // Split SQL into individual statements
    const statements = sqlContent
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));
    
    console.log(`📋 Found ${statements.length} SQL statements to execute`);
    
    // Execute statements one by one
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      if (statement.trim()) {
        try {
          console.log(`🔄 Executing statement ${i + 1}/${statements.length}...`);
          await sequelize.query(statement);
          console.log(`✅ Statement ${i + 1} executed successfully`);
        } catch (error) {
          // Skip errors for tables that already exist
          if (error.message.includes('already exists') || 
              (error.message.includes('relation') && error.message.includes('already exists'))) {
            console.log(`⚠️  Statement ${i + 1} skipped (table already exists)`);
            continue;
          }
          console.error(`❌ Statement ${i + 1} failed:`, error.message);
          throw error;
        }
      }
    }
    
    // Create default admin user
    console.log('👤 Creating default admin user...');
    try {
      await sequelize.query(`
        INSERT INTO users (id, fullName, phoneNumber, password, role, isActive, createdAt, updatedAt)
        VALUES (
          gen_random_uuid(),
          'Admin User',
          'admin123',
          '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
          'ADMIN',
          true,
          NOW(),
          NOW()
        )
        ON CONFLICT (phoneNumber) DO NOTHING
      `);
      console.log('✅ Default admin user created');
    } catch (adminError) {
      console.log('⚠️  Admin user may already exist:', adminError.message);
    }
    
    console.log('🎉 SQL tables created successfully!');
    
  } catch (error) {
    console.error('❌ SQL table creation failed:', error.message);
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
          console.log('🔄 Importing missing tables...');
          await createTablesFromSQL(sequelize);
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
      await sequelize.sync({ force: false, alter: false });
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
