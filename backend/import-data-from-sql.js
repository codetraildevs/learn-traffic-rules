#!/usr/bin/env node

// Import data from SQL file to PostgreSQL
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

async function importDataFromSQL() {
  console.log('🚀 Starting data import from SQL file...');
  
  const sequelize = new Sequelize(config);
  
  try {
    // Test connection
    await sequelize.authenticate();
    console.log('✅ Database connection established');
    
    // Read SQL file
    const sqlFilePath = path.join(__dirname, 'traffic_rules_db.sql');
    const sqlContent = fs.readFileSync(sqlFilePath, 'utf8');
    console.log('📄 SQL file loaded successfully');
    
    // Import users data
    console.log('👤 Importing users data...');
    await importUsersData(sequelize, sqlContent);
    
    // Import exams data
    console.log('📚 Importing exams data...');
    await importExamsData(sequelize, sqlContent);
    
    // Import questions data
    console.log('❓ Importing questions data...');
    await importQuestionsData(sequelize, sqlContent);
    
    // Verify data
    console.log('🔍 Verifying imported data...');
    const userCount = await sequelize.query('SELECT COUNT(*) as count FROM users', { type: Sequelize.QueryTypes.SELECT });
    const examCount = await sequelize.query('SELECT COUNT(*) as count FROM exams', { type: Sequelize.QueryTypes.SELECT });
    const questionCount = await sequelize.query('SELECT COUNT(*) as count FROM questions', { type: Sequelize.QueryTypes.SELECT });
    
    console.log(`📊 Data imported successfully:`);
    console.log(`   Users: ${userCount[0].count}`);
    console.log(`   Exams: ${examCount[0].count}`);
    console.log(`   Questions: ${questionCount[0].count}`);
    
    console.log('🎉 Data import completed successfully!');
    
  } catch (error) {
    console.error('❌ Data import failed:', error.message);
    console.error('🔍 Error details:', error);
    process.exit(1);
  } finally {
    await sequelize.close();
  }
}

async function importUsersData(sequelize, sqlContent) {
  const usersMatch = sqlContent.match(/INSERT INTO `users`[^;]+;/i);
  if (!usersMatch) {
    console.log('⚠️  No users data found in SQL file');
    return;
  }
  
  // Clear existing users (except admin)
  await sequelize.query('DELETE FROM users WHERE role != \'ADMIN\'');
  console.log('🗑️  Cleared existing non-admin users');
  
  // Extract user data
  const usersData = extractUsersData(usersMatch[0]);
  
  for (const user of usersData) {
    try {
      await sequelize.query(`
        INSERT INTO users (id, "fullName", "phoneNumber", "deviceId", role, "isActive", "lastLogin", "resetCode", "resetCodeExpires", "lastSyncAt", "createdAt", "updatedAt", "isBlocked", "blockReason", "blockedAt")
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
        ON CONFLICT (id) DO NOTHING
      `, {
        replacements: [
          user.id,
          user.fullName,
          user.phoneNumber,
          user.deviceId,
          user.role,
          user.isActive,
          user.lastLogin,
          user.resetCode,
          user.resetCodeExpires,
          user.lastSyncAt,
          user.createdAt,
          user.updatedAt,
          user.isBlocked,
          user.blockReason,
          user.blockedAt
        ]
      });
    } catch (error) {
      console.log('⚠️  User import error:', error.message);
    }
  }
  
  console.log(`✅ Imported ${usersData.length} users`);
}

async function importExamsData(sequelize, sqlContent) {
  const examsMatch = sqlContent.match(/INSERT INTO `exams`[^;]+;/i);
  if (!examsMatch) {
    console.log('⚠️  No exams data found in SQL file');
    return;
  }
  
  // Clear existing exams
  await sequelize.query('DELETE FROM exams');
  console.log('🗑️  Cleared existing exams');
  
  // Extract exam data
  const examsData = extractExamsData(examsMatch[0]);
  
  for (const exam of examsData) {
    try {
      await sequelize.query(`
        INSERT INTO exams (id, title, description, category, difficulty, duration, "passingScore", "isActive", "examImgUrl", "createdAt", "updatedAt")
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        ON CONFLICT (id) DO NOTHING
      `, {
        replacements: [
          exam.id,
          exam.title,
          exam.description,
          exam.category,
          exam.difficulty,
          exam.duration,
          exam.passingScore,
          exam.isActive,
          exam.examImgUrl,
          exam.createdAt,
          exam.updatedAt
        ]
      });
    } catch (error) {
      console.log('⚠️  Exam import error:', error.message);
    }
  }
  
  console.log(`✅ Imported ${examsData.length} exams`);
}

async function importQuestionsData(sequelize, sqlContent) {
  // Find all question INSERT statements
  const questionMatches = sqlContent.match(/INSERT INTO `questions`[^;]+;/gi);
  if (!questionMatches) {
    console.log('⚠️  No questions data found in SQL file');
    return;
  }
  
  // Clear existing questions
  await sequelize.query('DELETE FROM questions');
  console.log('🗑️  Cleared existing questions');
  
  let totalQuestions = 0;
  
  for (const match of questionMatches) {
    const questionsData = extractQuestionsData(match);
    
    for (const question of questionsData) {
      try {
        await sequelize.query(`
          INSERT INTO questions (id, "examId", question, option1, option2, option3, option4, "correctAnswer", points, "questionImgUrl", "createdAt", "updatedAt", "questionOrder")
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
          ON CONFLICT (id) DO NOTHING
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
            question.questionImgUrl,
            question.createdAt,
            question.updatedAt,
            question.questionOrder
          ]
        });
        totalQuestions++;
      } catch (error) {
        console.log('⚠️  Question import error:', error.message);
      }
    }
  }
  
  console.log(`✅ Imported ${totalQuestions} questions`);
}

function extractUsersData(sqlString) {
  const valuesMatch = sqlString.match(/VALUES\s*\(([^)]+)\)/i);
  if (!valuesMatch) return [];
  
  const values = valuesMatch[1].split(',').map(v => v.trim().replace(/^'|'$/g, ''));
  const users = [];
  
  // Parse each user record
  const userRecords = sqlString.match(/\([^)]+\)/g);
  for (const record of userRecords) {
    const fields = record.replace(/[()]/g, '').split(',').map(f => f.trim().replace(/^'|'$/g, ''));
    if (fields.length >= 15) {
      users.push({
        id: fields[0],
        fullName: fields[1],
        phoneNumber: fields[2],
        deviceId: fields[3],
        role: fields[4],
        isActive: fields[5] === '1',
        lastLogin: fields[6] === 'NULL' ? null : fields[6],
        resetCode: fields[7] === 'NULL' ? null : fields[7],
        resetCodeExpires: fields[8] === 'NULL' ? null : fields[8],
        lastSyncAt: fields[9] === 'NULL' ? null : fields[9],
        createdAt: fields[10],
        updatedAt: fields[11],
        isBlocked: fields[12] === '1',
        blockReason: fields[13] === 'NULL' ? null : fields[13],
        blockedAt: fields[14] === 'NULL' ? null : fields[14]
      });
    }
  }
  
  return users;
}

function extractExamsData(sqlString) {
  const examRecords = sqlString.match(/\([^)]+\)/g);
  const exams = [];
  
  for (const record of examRecords) {
    const fields = record.replace(/[()]/g, '').split(',').map(f => f.trim().replace(/^'|'$/g, ''));
    if (fields.length >= 11) {
      exams.push({
        id: fields[0],
        title: fields[1],
        description: fields[2],
        category: fields[3],
        difficulty: fields[4],
        duration: parseInt(fields[5]),
        passingScore: parseInt(fields[6]),
        isActive: fields[7] === '1',
        examImgUrl: fields[8] === 'NULL' ? null : fields[8],
        createdAt: fields[9],
        updatedAt: fields[10]
      });
    }
  }
  
  return exams;
}

function extractQuestionsData(sqlString) {
  const questionRecords = sqlString.match(/\([^)]+\)/g);
  const questions = [];
  
  for (const record of questionRecords) {
    const fields = record.replace(/[()]/g, '').split(',').map(f => f.trim().replace(/^'|'$/g, ''));
    if (fields.length >= 13) {
      questions.push({
        id: fields[0],
        examId: fields[1],
        question: fields[2],
        option1: fields[3],
        option2: fields[4],
        option3: fields[5],
        option4: fields[6],
        correctAnswer: fields[7],
        points: parseInt(fields[8]),
        questionImgUrl: fields[9] === 'NULL' ? null : fields[9],
        createdAt: fields[10],
        updatedAt: fields[11],
        questionOrder: parseInt(fields[12])
      });
    }
  }
  
  return questions;
}

importDataFromSQL();
