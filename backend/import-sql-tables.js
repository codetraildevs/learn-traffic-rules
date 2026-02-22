#!/usr/bin/env node

// SQL Table Importer for Render deployment
require('dotenv').config();
const fs = require('fs');
const path = require('path');
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

async function importSqlTables() {
  console.log('🚀 Starting SQL table import...');
  
  const sequelize = new Sequelize(config);
  
  try {
    // Test connection
    await sequelize.authenticate();
    console.log('✅ Database connection established');
    
    // Read SQL file
    const sqlFilePath = path.join(__dirname, 'traffic_rules_db.sql');
    if (!fs.existsSync(sqlFilePath)) {
      throw new Error(`SQL file not found: ${sqlFilePath}`);
    }
    
    const sqlContent = fs.readFileSync(sqlFilePath, 'utf8');
    console.log('📄 SQL file loaded successfully');
    
    // Split SQL into individual statements
    const statements = sqlContent
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));
    
    console.log(`📋 Found ${statements.length} SQL statements to execute`);
    
    // Execute statements one by one
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      if (statement.trim()) {
        try {
          console.log(`🔄 Executing statement ${i + 1}/${statements.length}...`);
          await sequelize.query(statement);
          console.log(`✅ Statement ${i + 1} executed successfully`);
        } catch (error) {
          // Skip errors for tables that already exist
          if (error.message.includes('already exists') || 
              error.message.includes('relation') && error.message.includes('already exists')) {
            console.log(`⚠️  Statement ${i + 1} skipped (table already exists)`);
            continue;
          }
          console.error(`❌ Statement ${i + 1} failed:`, error.message);
          throw error;
        }
      }
    }
    
    // Verify tables were created
    const tables = await sequelize.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `, { type: Sequelize.QueryTypes.SELECT });
    
    console.log('📋 Created tables:', tables.map(t => t.table_name));
    
    // Create default admin user
    console.log('👤 Creating default admin user...');
    try {
      await sequelize.query(`
        INSERT INTO users (id, fullName, phoneNumber, password, role, isActive, createdAt, updatedAt)
        VALUES (
          gen_random_uuid(),
          'Admin User',
          'admin123',
          '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
          'ADMIN',
          true,
          NOW(),
          NOW()
        )
        ON CONFLICT (phoneNumber) DO NOTHING
      `);
      console.log('✅ Default admin user created');
    } catch (adminError) {
      console.log('⚠️  Admin user may already exist:', adminError.message);
    }
    
    console.log('🎉 Database initialization completed successfully!');
    
  } catch (error) {
    console.error('❌ Database initialization failed:', error.message);
    console.error('🔍 Error details:', error);
    process.exit(1);
  } finally {
    await sequelize.close();
  }
}

importSqlTables();
