/**
 * Migration: Add 'CUSTOM' to paymentTier enum in access_codes table
 * 
 * This migration adds support for custom date ranges in access code generation.
 * Run this script manually: node migrations/add-custom-payment-tier.js
 */

require('dotenv').config();
const { Sequelize } = require('sequelize');

const getDatabaseConfig = () => {
  const databaseUrl = process.env.DATABASE_URL;
  
  if (databaseUrl) {
    return {
      url: databaseUrl,
      dialect: 'mysql',
      logging: console.log
    };
  } else {
    return {
      database: process.env.DB_NAME || 'traffic_rules_db',
      username: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 3306,
      dialect: 'mysql',
      logging: console.log
    };
  }
};

const sequelize = new Sequelize(getDatabaseConfig());

async function addCustomPaymentTier() {
  try {
    console.log('🔄 Starting migration: Add CUSTOM to paymentTier enum...');
    
    // Test connection
    await sequelize.authenticate();
    console.log('✅ Database connected successfully');
    
    // Check current enum values
    const [currentEnum] = await sequelize.query(`
      SELECT COLUMN_TYPE 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'access_codes' 
      AND COLUMN_NAME = 'paymentTier'
    `);
    
    console.log('📋 Current paymentTier enum:', currentEnum[0]?.COLUMN_TYPE);
    
    // Check if 'CUSTOM' already exists
    if (currentEnum[0]?.COLUMN_TYPE?.includes("'CUSTOM'")) {
      console.log('✅ CUSTOM already exists in paymentTier enum, skipping migration');
      await sequelize.close();
      return;
    }
    
    // Modify enum to include 'CUSTOM'
    // Note: MySQL doesn't support adding values to ENUM directly, so we need to modify the column
    console.log('🔄 Modifying paymentTier enum to include CUSTOM...');
    
    await sequelize.query(`
      ALTER TABLE access_codes 
      MODIFY COLUMN paymentTier ENUM('1_MONTH', '3_MONTHS', '6_MONTHS', 'CUSTOM') NOT NULL
    `);
    
    console.log('✅ Successfully added CUSTOM to paymentTier enum');
    
    // Verify the change
    const [updatedEnum] = await sequelize.query(`
      SELECT COLUMN_TYPE 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'access_codes' 
      AND COLUMN_NAME = 'paymentTier'
    `);
    
    console.log('📋 Updated paymentTier enum:', updatedEnum[0]?.COLUMN_TYPE);
    console.log('✅ Migration completed successfully!');
    
    await sequelize.close();
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    console.error('🔍 Error details:', error);
    await sequelize.close();
    process.exit(1);
  }
}

// Run migration
addCustomPaymentTier();

