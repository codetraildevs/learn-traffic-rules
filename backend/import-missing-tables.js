#!/usr/bin/env node

// Import missing notification tables
require('dotenv').config();
const { Sequelize } = require('sequelize');
const fs = require('fs');
const path = require('path');

// Database configuration
const config = {
  database: process.env.DB_NAME || 'rw_driving_prep_db',
  username: process.env.DB_USER || 'root',
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

async function importMissingTables() {
  console.log('🚀 Starting missing tables import...');
  
  const sequelize = new Sequelize(config);
  
  try {
    // Test connection
    await sequelize.authenticate();
    console.log('✅ Database connection established');
    
    // Check existing tables
    const existingTables = await sequelize.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `, { type: Sequelize.QueryTypes.SELECT });
    
    console.log('📋 Existing tables:', existingTables.map(t => t.table_name));
    
    // Read SQL file
    const sqlFilePath = path.join(__dirname, 'traffic_rules_db.sql');
    const sqlContent = fs.readFileSync(sqlFilePath, 'utf8');
    
    // Extract specific table creation statements
    const tableStatements = {
      notifications: extractTableStatement(sqlContent, 'notifications'),
      studyreminders: extractTableStatement(sqlContent, 'studyreminders'),
      notificationpreferences: extractTableStatement(sqlContent, 'notificationpreferences')
    };
    
    // Import missing tables
    for (const [tableName, statement] of Object.entries(tableStatements)) {
      const tableExists = existingTables.some(t => t.table_name === tableName);
      
      if (!tableExists && statement) {
        console.log(`🔄 Creating table: ${tableName}...`);
        try {
          await sequelize.query(statement);
          console.log(`✅ Table ${tableName} created successfully`);
        } catch (error) {
          console.error(`❌ Failed to create table ${tableName}:`, error.message);
        }
      } else if (tableExists) {
        console.log(`⚠️  Table ${tableName} already exists, skipping`);
      } else {
        console.log(`⚠️  No statement found for table ${tableName}`);
      }
    }
    
    // Import data for notifications table
    console.log('📊 Importing notification data...');
    const notificationData = extractNotificationData(sqlContent);
    if (notificationData.length > 0) {
      try {
        // Clear existing notifications first
        await sequelize.query('DELETE FROM notifications');
        console.log('🗑️  Cleared existing notifications');
        
        // Insert notification data
        for (const notification of notificationData) {
          await sequelize.query(`
            INSERT INTO notifications (id, userId, type, title, message, data, isRead, isPushSent, scheduledFor, priority, category, createdAt, updatedAt)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT (id) DO NOTHING
          `, {
            replacements: [
              notification.id,
              notification.userId,
              notification.type,
              notification.title,
              notification.message,
              notification.data,
              notification.isRead,
              notification.isPushSent,
              notification.scheduledFor,
              notification.priority,
              notification.category,
              notification.createdAt,
              notification.updatedAt
            ]
          });
        }
        console.log(`✅ Imported ${notificationData.length} notification records`);
      } catch (error) {
        console.error('❌ Failed to import notification data:', error.message);
      }
    }
    
    // Verify final tables
    const finalTables = await sequelize.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `, { type: Sequelize.QueryTypes.SELECT });
    
    console.log('📋 Final tables:', finalTables.map(t => t.table_name));
    
    console.log('🎉 Missing tables import completed!');
    
  } catch (error) {
    console.error('❌ Import failed:', error.message);
    console.error('🔍 Error details:', error);
    process.exit(1);
  } finally {
    await sequelize.close();
  }
}

function extractTableStatement(sqlContent, tableName) {
  const regex = new RegExp(`CREATE TABLE \`${tableName}\`[\\s\\S]*?;`, 'i');
  const match = sqlContent.match(regex);
  return match ? match[0] : null;
}

function extractNotificationData(sqlContent) {
  const regex = /INSERT INTO `notifications`[^;]+;/gi;
  const matches = sqlContent.match(regex);
  
  if (!matches) return [];
  
  const notifications = [];
  for (const match of matches) {
    // Extract VALUES part
    const valuesMatch = match.match(/VALUES\s*\(([^)]+)\)/i);
    if (valuesMatch) {
      const values = valuesMatch[1].split(',').map(v => v.trim().replace(/^'|'$/g, ''));
      if (values.length >= 13) {
        notifications.push({
          id: values[0],
          userId: values[1],
          type: values[2],
          title: values[3],
          message: values[4],
          data: values[5],
          isRead: values[6] === '1',
          isPushSent: values[7] === '1',
          scheduledFor: values[8] === 'NULL' ? null : values[8],
          priority: values[9],
          category: values[10],
          createdAt: values[11],
          updatedAt: values[12]
        });
      }
    }
  }
  
  return notifications;
}

importMissingTables();
