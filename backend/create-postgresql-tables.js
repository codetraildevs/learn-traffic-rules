#!/usr/bin/env node

// Create PostgreSQL-compatible tables
require('dotenv').config();
const { Sequelize } = require('sequelize');

// Database configuration
const config = {
  database: process.env.DB_NAME || 'traffic_rules_db_6j3n',
  username: process.env.DB_USER || 'traffic_rules_db_user',
  password: process.env.DB_PASSWORD,
  host: process.env.DB_HOST || 'dpg-d3cenur7mgec73aeevcg-a.ohio-postgres.render.com',
  port: process.env.DB_PORT || 5432,
  dialect: 'postgres',
  logging: console.log,
  ssl: {
    require: true,
    rejectUnauthorized: false
  }
};

async function createPostgreSQLTables() {
  console.log('🚀 Creating PostgreSQL-compatible tables...');
  
  const sequelize = new Sequelize(config);
  
  try {
    // Test connection
    await sequelize.authenticate();
    console.log('✅ Database connection established');
    
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
    
    // Insert sample notification data
    console.log('📊 Inserting sample notification data...');
    try {
      // Get a user ID to use for sample data
      const users = await sequelize.query('SELECT id FROM users LIMIT 1', { type: Sequelize.QueryTypes.SELECT });
      if (users.length > 0) {
        const userId = users[0].id;
        
        // Insert sample notifications
        await sequelize.query(`
          INSERT INTO notifications (id, "userId", type, title, message, data, "isRead", "isPushSent", priority, category, "createdAt", "updatedAt")
          VALUES 
            (gen_random_uuid(), $1, 'STUDY_REMINDER', 'Time to Study! 📖', 'Haven''t studied today? Take a practice exam to keep your skills sharp!', '{"studyGoalMinutes":30}', false, false, 'MEDIUM', 'STUDY', NOW(), NOW()),
            (gen_random_uuid(), $1, 'SYSTEM_UPDATE', 'Welcome to Traffic Rules App! 🚗', 'Welcome! Start your learning journey with our comprehensive traffic rules course.', '{}', false, false, 'HIGH', 'SYSTEM', NOW(), NOW())
          ON CONFLICT (id) DO NOTHING
        `, {
          replacements: [userId]
        });
        console.log('✅ Sample notification data inserted');
      }
    } catch (error) {
      console.log('⚠️  Sample data insertion failed:', error.message);
    }
    
    // Verify tables were created
    const finalTables = await sequelize.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `, { type: Sequelize.QueryTypes.SELECT });
    
    console.log('📋 Final tables:', finalTables.map(t => t.table_name));
    
    console.log('🎉 PostgreSQL tables created successfully!');
    
  } catch (error) {
    console.error('❌ Table creation failed:', error.message);
    console.error('🔍 Error details:', error);
    process.exit(1);
  } finally {
    await sequelize.close();
  }
}

createPostgreSQLTables();
