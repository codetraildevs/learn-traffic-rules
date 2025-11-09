/**
 * Database Seeding Script
 * 
 * This script allows you to seed the database with initial data.
 * It will skip existing data by default to prevent data loss.
 * 
 * Usage:
 *   node seed.js              - Seed with skip existing (default, safe)
 *   node seed.js --force      - Seed everything (may create duplicates)
 *   node seed.js --courses-only - Seed only courses
 */

const DatabaseSeeder = require('./src/config/seeders');
const { testConnection } = require('./src/config/database');

async function main() {
  try {
    console.log('🌱 Starting database seeding process...');
    
    // Test database connection
    const connected = await testConnection();
    if (!connected) {
      console.error('❌ Database connection failed. Please check your database configuration.');
      process.exit(1);
    }
    
    // Parse command line arguments
    const args = process.argv.slice(2);
    const force = args.includes('--force');
    const coursesOnly = args.includes('--courses-only');
    
    if (coursesOnly) {
      console.log('📚 Seeding courses only...');
      await DatabaseSeeder.seedCourses();
    } else {
      // Run all seeders
      await DatabaseSeeder.run(!force); // skipExisting = !force
    }
    
    console.log('✅ Seeding completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  }
}

main();
