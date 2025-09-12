#!/usr/bin/env node

const DatabaseSeeder = require('./src/config/seeders');
const { sequelize } = require('./src/config/database');

async function runSeeder() {
  try {
    // Test database connection
    await sequelize.authenticate();
    console.log('✅ Database connected successfully');
    
    // Check command line arguments
    const command = process.argv[2];
    
    if (command === 'clear') {
      await DatabaseSeeder.clear();
    } else if (command === 'fresh') {
      await DatabaseSeeder.clear();
      await DatabaseSeeder.run();
    } else {
      // Default: run seeder
      await DatabaseSeeder.run();
    }
    
    console.log('🎉 Seeding process completed!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Seeding failed:', error.message);
    process.exit(1);
  }
}

// Show usage information
if (process.argv.includes('--help') || process.argv.includes('-h')) {
  console.log(`
🌱 Database Seeder Usage:

  node seed.js           # Run seeder (add data)
  node seed.js clear     # Clear all seeded data
  node seed.js fresh     # Clear and re-seed data
  node seed.js --help    # Show this help

📋 What gets seeded:
  - Users (Admin, Manager, Regular users)
  - Exams (Traffic signs, Road rules, etc.)
  - Questions (Sample questions for exams)
  - Payment requests (Sample payment data)
  - Access codes (Generated for approved payments)
  - Exam results (Sample user results)

🔑 Default login credentials:
  - All users have password: "password123"
  - Device IDs are unique for each user
  `);
  process.exit(0);
}

runSeeder();
