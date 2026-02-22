#!/usr/bin/env node

// Quick data fix - insert essential data
require('dotenv').config();
const { Sequelize } = require('sequelize');

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

async function quickDataFix() {
  console.log('🚀 Starting quick data fix...');
  
  const sequelize = new Sequelize(config);
  
  try {
    // Test connection
    await sequelize.authenticate();
    console.log('✅ Database connection established');
    
    // Check if admin user exists
    const adminExists = await sequelize.query(
      'SELECT id FROM users WHERE "phoneNumber" = $1',
      { 
        replacements: ['admin123'],
        type: Sequelize.QueryTypes.SELECT 
      }
    );
    
    if (adminExists.length === 0) {
      console.log('👤 Creating admin user...');
      await sequelize.query(`
        INSERT INTO users (id, "fullName", "phoneNumber", "deviceId", role, "isActive", "createdAt", "updatedAt")
        VALUES (
          gen_random_uuid(),
          'Admin User',
          'admin123',
          'admin-device-bypass',
          'ADMIN',
          true,
          NOW(),
          NOW()
        )
      `);
      console.log('✅ Admin user created');
    } else {
      console.log('✅ Admin user already exists');
    }
    
    // Check if we have any exams
    const existingExamCount = await sequelize.query(
      'SELECT COUNT(*) as count FROM exams',
      { type: Sequelize.QueryTypes.SELECT }
    );
    
    if (existingExamCount[0].count === 0) {
      console.log('📚 Creating sample exams...');
      
      // Create sample exams
      const exams = [
        {
          id: '1',
          title: 'Free Exam',
          description: 'Traffic rules examination 1',
          category: 'Traffic Rules',
          difficulty: 'MEDIUM',
          duration: 20,
          passingScore: 60,
          isActive: true
        },
        {
          id: '2',
          title: 'Traffic Rules Exam 2',
          description: 'Traffic rules examination 2',
          category: 'Traffic Rules',
          difficulty: 'MEDIUM',
          duration: 20,
          passingScore: 60,
          isActive: true
        },
        {
          id: '3',
          title: 'Traffic Rules Exam 3',
          description: 'Traffic rules examination 3',
          category: 'Traffic Rules',
          difficulty: 'HARD',
          duration: 30,
          passingScore: 70,
          isActive: true
        }
      ];
      
      for (const exam of exams) {
        await sequelize.query(`
          INSERT INTO exams (id, title, description, category, difficulty, duration, "passingScore", "isActive", "createdAt", "updatedAt")
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
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
            exam.isActive
          ]
        });
      }
      
      console.log('✅ Sample exams created');
    } else {
      console.log('✅ Exams already exist');
    }
    
    // Check if we have any questions
    const existingQuestionCount = await sequelize.query(
      'SELECT COUNT(*) as count FROM questions',
      { type: Sequelize.QueryTypes.SELECT }
    );
    
    if (existingQuestionCount[0].count === 0) {
      console.log('❓ Creating sample questions...');
      
      // Create sample questions for exam 1
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
        },
        {
          id: '1_q3',
          examId: '1',
          question: 'When should you use your turn signals?',
          option1: 'a) Only when changing lanes',
          option2: 'b) Only when turning',
          option3: 'c) When changing lanes or turning',
          option4: 'd) Never',
          correctAnswer: 'c) When changing lanes or turning',
          points: 1,
          questionOrder: 3
        }
      ];
      
      for (const question of questions) {
        await sequelize.query(`
          INSERT INTO questions (id, "examId", question, option1, option2, option3, option4, "correctAnswer", points, "createdAt", "updatedAt", "questionOrder")
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW(), $10)
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
            question.questionOrder
          ]
        });
      }
      
      console.log('✅ Sample questions created');
    } else {
      console.log('✅ Questions already exist');
    }
    
    // Verify data
    const userCount = await sequelize.query('SELECT COUNT(*) as count FROM users', { type: Sequelize.QueryTypes.SELECT });
    const examCount = await sequelize.query('SELECT COUNT(*) as count FROM exams', { type: Sequelize.QueryTypes.SELECT });
    const questionCount = await sequelize.query('SELECT COUNT(*) as count FROM questions', { type: Sequelize.QueryTypes.SELECT });
    
    console.log('📊 Data verification:');
    console.log(`   Users: ${userCount[0].count}`);
    console.log(`   Exams: ${examCount[0].count}`);
    console.log(`   Questions: ${questionCount[0].count}`);
    
    console.log('🎉 Quick data fix completed successfully!');
    
  } catch (error) {
    console.error('❌ Quick data fix failed:', error.message);
    console.error('🔍 Error details:', error);
    process.exit(1);
  } finally {
    await sequelize.close();
  }
}

quickDataFix();
