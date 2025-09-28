#!/usr/bin/env node

// Database initialization script
require('dotenv').config();
const { testConnection, initializeTables } = require('./src/config/database');

async function initDatabase() {
  console.log('🚀 Starting database initialization...');
  
  try {
    // Test connection
    const connected = await testConnection();
    if (!connected) {
      console.error('❌ Database connection failed');
      process.exit(1);
    }
    
    // Initialize tables
    await initializeTables();
    
    console.log('✅ Database initialization completed successfully!');
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Database initialization failed:', error.message);
    console.error('🔍 Error details:', error);
    process.exit(1);
  }
}

initDatabase();
