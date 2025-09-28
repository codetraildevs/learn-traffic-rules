const { sequelize, initializeTables } = require('../config/database');
const { seedExams } = require('./seedExams');
const { seedQuestions } = require('./seedQuestions');

const runSeeders = async () => {
  try {
    console.log('🚀 Starting database seeding...');
    
    // Set force sync for seeding
    process.env.FORCE_SYNC = 'true';
    
    // Test database connection
    await sequelize.authenticate();
    console.log('✅ Database connected successfully');
    
    // Initialize tables first
    await initializeTables();
    
    // Seed exams first
    const exams = await seedExams();
    
    // Seed questions if exams were created
    if (exams.length > 0) {
      await seedQuestions();
    }
    
    console.log('🎉 Database seeding completed successfully!');
  } catch (error) {
    console.error('❌ Database seeding failed:', error);
  } finally {
    await sequelize.close();
    process.exit(0);
  }
};

// Run seeders if this file is executed directly
if (require.main === module) {
  runSeeders();
}

module.exports = { runSeeders };
