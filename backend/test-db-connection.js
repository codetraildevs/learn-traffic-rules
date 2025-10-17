#!/usr/bin/env node

// Test database connection script
require('dotenv').config();

const { Sequelize } = require('sequelize');

console.log('🔍 Testing database connection...');
console.log('Environment:', process.env.NODE_ENV);
console.log('DATABASE_URL set:', !!process.env.DATABASE_URL);

if (process.env.DATABASE_URL) {
  console.log('DATABASE_URL format:', process.env.DATABASE_URL.replace(/:[^:@]+@/, ':***@'));
}

const sequelize = new Sequelize(process.env.DATABASE_URL, {
  dialect: 'postgres',
  dialectOptions: {
    ssl: {
      require: true,
      rejectUnauthorized: false
    }
  },
  logging: console.log
});

async function testConnection() {
  try {
    console.log('🔄 Attempting to connect...');
    await sequelize.authenticate();
    console.log('✅ Database connection successful!');
    
    // Test a simple query
    const result = await sequelize.query('SELECT NOW() as current_time');
    console.log('✅ Query test successful:', result[0][0]);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Database connection failed:');
    console.error('Error name:', error.name);
    console.error('Error message:', error.message);
    console.error('Error code:', error.code);
    console.error('Parent error:', error.parent?.code);
    console.error('Original error:', error.original?.code);
    
    if (error.name === 'SequelizeConnectionRefusedError') {
      console.error('\n💡 Troubleshooting tips:');
      console.error('1. Check if DATABASE_URL is correct');
      console.error('2. Verify database is running');
      console.error('3. Check network connectivity');
      console.error('4. Ensure database is in same region');
    }
    
    process.exit(1);
  }
}

testConnection();
