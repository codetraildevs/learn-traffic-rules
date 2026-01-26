/**
 * SERVER SETUP EXAMPLE
 * 
 * This file shows how to properly integrate the refactored NotificationService
 * and database initialization in your server.js file.
 * 
 * Copy this pattern to your actual server.js file.
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { sequelize, testConnection, initializeTables } = require('./src/config/database');
const notificationService = require('./src/services/notificationService');

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
// ... your routes here ...

// Error handlers
// ... your error handlers here ...

// Server startup
const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    // 1. Test database connection first
    console.log('🔄 Testing database connection...');
    const connected = await testConnection();
    if (!connected) {
      console.error('❌ Database connection failed. Exiting...');
      process.exit(1);
    }

    // 2. Initialize database tables (only if AUTO_DB_INIT is enabled)
    console.log('🔄 Initializing database tables...');
    await initializeTables();

    // 3. Start cron jobs AFTER database is ready
    console.log('🔄 Starting notification service cron jobs...');
    notificationService.startCronJobs();

    // 4. Start Express server
    app.listen(PORT, () => {
      console.log(`✅ Server running on port ${PORT}`);
      console.log(`✅ Database connected`);
      console.log(`✅ Cron jobs started`);
    });

    // Graceful shutdown
    process.on('SIGTERM', async () => {
      console.log('🛑 SIGTERM received, shutting down gracefully...');
      notificationService.stopCronJobs();
      await sequelize.close();
      process.exit(0);
    });

    process.on('SIGINT', async () => {
      console.log('🛑 SIGINT received, shutting down gracefully...');
      notificationService.stopCronJobs();
      await sequelize.close();
      process.exit(0);
    });

  } catch (error) {
    console.error('❌ Server startup failed:', error);
    process.exit(1);
  }
}

// Start the server
startServer();

module.exports = app;

