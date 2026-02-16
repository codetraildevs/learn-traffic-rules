// Load environment variables first
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const swaggerUi = require('swagger-ui-express');
const swaggerJsdoc = require('swagger-jsdoc');
const http = require('http');
const { Server } = require('socket.io');
const { testConnection, initializeTables } = require('./src/config/database');
const notificationService = require('./src/services/notificationService');

// ⭐ SETUP ASSOCIATIONS IMMEDIATELY (before routes are loaded)
// This ensures associations are available even if AUTO_DB_INIT=false
// Import models first to ensure they're loaded
require('./src/models/User');
require('./src/models/Exam');
require('./src/models/Question');
require('./src/models/PaymentRequest');
require('./src/models/AccessCode');
require('./src/models/ExamResult');
require('./src/models/Notification');
require('./src/models/StudyReminder');
require('./src/models/NotificationPreferences');
require('./src/models/Course');
require('./src/models/CourseContent');
require('./src/models/CourseProgress');
require('./src/models/CourseContentProgress');

// Now set up associations
const setupAssociations = require('./src/config/associations');
setupAssociations();
console.log('✅ Model associations set up (early initialization)');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.FRONTEND_URL || 'http://localhost:3000',
    methods: ['GET', 'POST']
  }
});

const PORT = process.env.PORT || 3000;

// Debug: Check if JWT secret is loaded
console.log('🔑 JWT Secret loaded:', process.env.JWT_SECRET ? 'YES' : 'NO');
console.log('🔑 All env vars:', Object.keys(process.env).filter(key => key.includes('JWT')));
if (process.env.JWT_SECRET) {
  console.log('🔑 JWT Secret length:', process.env.JWT_SECRET.length);
} else {
  console.log('❌ JWT_SECRET not found in environment variables');
  console.log('🔍 Current working directory:', process.cwd());
  console.log('🔍 .env file exists:', require('fs').existsSync('.env'));
}

// Trust proxy for rate limiting behind reverse proxy
app.set('trust proxy', 1);

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));

// Rate limiting - More generous limits for mobile app
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5000, // limit each IP to 5000 requests per windowMs (increased from 100)
  message: {
    error: 'Rate limit exceeded',
    message: 'Too many requests from this IP, please try again later.',
    retryAfter: '15 minutes'
  },
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  skip: (req) => {
    // Skip rate limiting for health checks
    return req.path === '/health' || req.path === '/api/health';
  }
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Serve static files from uploads directory
app.use('/uploads', express.static('uploads'));

// Serve privacy policy and delete account instructions pages
app.use('/public', express.static('public'));

// Privacy policy route
app.get('/privacy-policy', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'privacy-policy.html'));
});

// Delete account instructions route
app.get('/delete-account-instructions', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'delete-account-instructions.html'));
});

// Terms and conditions route
app.get('/terms-conditions', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'terms-conditions.html'));
});

// Swagger configuration
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Drive Rwanda - Prep & Pass API',
      version: '1.0.0',
      description: 'API documentation for Drive Rwanda - Prep & Pass with manual payment processing and device ID validation',
      contact: {
        name: 'API Support',
      },
      license: {
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT'
      }
    },
    servers: [
      {
        url: `http://localhost:${PORT}`,
        description: 'Development server'
      },
      {
        url: 'https://drive-rwanda-prep.cyangugudims.com',
        description: 'Production server'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT'
        },
        deviceAuth: {
          type: 'apiKey',
          in: 'header',
          name: 'device-id',
          description: 'Device ID for device binding validation'
        }
      },
      schemas: {
        User: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              description: 'Unique user identifier'
            },
            deviceId: {
              type: 'string',
              description: 'Unique device identifier'
            },
            role: {
              type: 'string',
              enum: ['USER', 'MANAGER', 'ADMIN'],
              description: 'User role'
            },
            isActive: {
              type: 'boolean',
              description: 'User account status'
            },
            createdAt: {
              type: 'string',
              format: 'date-time',
              description: 'Account creation timestamp'
            },
            updatedAt: {
              type: 'string',
              format: 'date-time',
              description: 'Last update timestamp'
            }
          }
        },
        Exam: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              description: 'Unique exam identifier'
            },
            title: {
              type: 'string',
              description: 'Exam title'
            },
            description: {
              type: 'string',
              description: 'Exam description'
            },
            category: {
              type: 'string',
              description: 'Exam category'
            },
            difficulty: {
              type: 'string',
              enum: ['EASY', 'MEDIUM', 'HARD'],
              description: 'Exam difficulty level'
            },
            duration: {
              type: 'integer',
              description: 'Exam duration in minutes'
            },
            questionCount: {
              type: 'integer',
              description: 'Number of questions in exam'
            },
            passingScore: {
              type: 'integer',
              description: 'Minimum score required to pass'
            },
            price: {
              type: 'number',
              description: 'Exam price'
            },
            isActive: {
              type: 'boolean',
              description: 'Exam availability status'
            }
          }
        },
        PaymentRequest: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              description: 'Unique payment request identifier'
            },
            userId: {
              type: 'string',
              description: 'User identifier'
            },
            examId: {
              type: 'string',
              description: 'Exam identifier'
            },
            amount: {
              type: 'number',
              description: 'Payment amount'
            },
            paymentMethod: {
              type: 'string',
              description: 'Payment method used'
            },
            status: {
              type: 'string',
              enum: ['PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'],
              description: 'Payment request status'
            },
            paymentProof: {
              type: 'string',
              description: 'Payment proof document/image'
            },
            createdAt: {
              type: 'string',
              format: 'date-time',
              description: 'Request creation timestamp'
            }
          }
        },
        AccessCode: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              description: 'Unique access code identifier'
            },
            code: {
              type: 'string',
              description: 'Access code string'
            },
            userId: {
              type: 'string',
              description: 'User identifier'
            },
            examId: {
              type: 'string',
              description: 'Exam identifier'
            },
            expiresAt: {
              type: 'string',
              format: 'date-time',
              description: 'Access code expiration timestamp'
            },
            isUsed: {
              type: 'boolean',
              description: 'Access code usage status'
            },
            createdAt: {
              type: 'string',
              format: 'date-time',
              description: 'Code creation timestamp'
            }
          }
        },
        Error: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: false
            },
            message: {
              type: 'string',
              description: 'Error message'
            },
            error: {
              type: 'string',
              description: 'Detailed error information'
            }
          }
        },
        Success: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: true
            },
            message: {
              type: 'string',
              description: 'Success message'
            },
            data: {
              type: 'object',
              description: 'Response data'
            }
          }
        }
      }
    },
    security: [
      {
        bearerAuth: [],
        deviceAuth: []
      }
    ]
  },
  apis: ['./src/routes/*.js', './src/controllers/*.js'] // paths to files containing OpenAPI definitions
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);

// Swagger UI
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  explorer: true,
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'Traffic Rules API Documentation'
}));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// API routes (will be added)
console.log('🔄 Loading API routes...');
app.use('/api/auth', require('./src/routes/auth'));
console.log('✅ Auth routes loaded');

app.use('/api/users', require('./src/routes/users'));
console.log('✅ Users routes loaded');

const userManagementRoutes = require('./src/routes/userManagement');
console.log('✅ User management routes loaded:', userManagementRoutes.stack ? userManagementRoutes.stack.length : 'No stack');
app.use('/api/user-management', userManagementRoutes);

app.use('/api/exams', require('./src/routes/exams'));
app.use('/api/payments', require('./src/routes/payments'));
app.use('/api/questions', require('./src/routes/questions'));
app.use('/api/access-codes', require('./src/routes/accessCodes'));
app.use('/api/bulk-upload', require('./src/routes/bulkUpload'));
app.use('/api/offline', require('./src/routes/offline'));
app.use('/api/analytics', require('./src/routes/analytics'));
app.use('/api/notifications', require('./src/routes/notifications'));
app.use('/api/achievements', require('./src/routes/achievements'));
app.use('/api/courses', require('./src/routes/courses'));
console.log('✅ All API routes loaded');

// Error handling middleware - must be after routes
app.use((err, req, res, next) => {
  console.error('🚨 Unhandled error:', err);
  
  // Handle rate limit errors specifically
  if (err.status === 429) {
    return res.status(429).json({
      success: false,
      error: 'Rate limit exceeded',
      message: 'Too many requests from this IP, please try again later.',
      retryAfter: '15 minutes'
    });
  }
  
  // Handle JSON parsing errors
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    return res.status(400).json({
      success: false,
      error: 'Invalid JSON',
      message: 'Request body contains invalid JSON'
    });
  }
  
  // Handle other errors
  res.status(err.status || 500).json({
    success: false,
    error: err.name || 'Internal Server Error',
    message: err.message || 'An unexpected error occurred'
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to Drive Rwanda - Prep & Pass API',
    version: '1.0.0',
    documentation: '/api-docs',
    health: '/health'
  });
});

// 404 handler
app.use('*', (req, res) => {
  // Get all registered routes dynamically
  const routes = [];
  app._router.stack.forEach((middleware) => {
    if (middleware.route) {
      const methods = Object.keys(middleware.route.methods).join(',').toUpperCase();
      routes.push(`${methods} ${middleware.route.path}`);
    } else if (middleware.name === 'router') {
      middleware.handle.stack.forEach((handler) => {
        if (handler.route) {
          const methods = Object.keys(handler.route.methods).join(',').toUpperCase();
          routes.push(`${methods} ${middleware.regexp.source.replace(/\\\//g, '/').replace(/\^|\$|\?/g, '')}${handler.route.path}`);
        }
      });
    }
  });

  res.status(404).json({
    success: false,
    message: 'Route not found',
    availableRoutes: routes.slice(0, 20) // Limit to first 20 routes
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// Initialize database and start server
const startServer = async () => {
  try {
    // Test database connection
    const dbConnected = await testConnection();
    
    if (!dbConnected) {
      console.error('❌ Database connection failed. Server will start but database features will be unavailable.');
      console.error('💡 Please check your database configuration and try again.');
    } else {
      // Initialize database tables
      await initializeTables();
      
      // Create default admin user
      await createDefaultAdmin();
    }
    
    // Initialize notification service with Socket.IO
    notificationService.setSocketIO(io);
    
    // ⭐ START CRON JOBS AFTER DATABASE IS READY
    console.log('🔄 Starting notification service cron jobs...');
    notificationService.startCronJobs();
    
    // Socket.IO connection handling
    io.on('connection', (socket) => {
      console.log(`🔌 User connected: ${socket.id}`);
      
      // Join user to their personal room
      socket.on('join-user-room', (userId) => {
        socket.join(`user_${userId}`);
        console.log(`👤 User ${userId} joined their room`);
      });
      
      // Handle disconnection
      socket.on('disconnect', () => {
        console.log(`🔌 User disconnected: ${socket.id}`);
      });
    });
    
    // Start server
    server.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📚 API Documentation: http://localhost:${PORT}/api-docs`);
      console.log(`🏥 Health Check: http://localhost:${PORT}/health`);
      console.log(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🔑 Admin credentials: admin123 / admin123`);
      console.log(`🔌 Socket.IO enabled for real-time notifications`);
      console.log(`✅ Cron jobs started successfully`);
      
      if (!dbConnected) {
        console.log(`⚠️  WARNING: Database is not connected. Some features may not work.`);
      }
    }).on('error', (err) => {
      if (err.code === 'EADDRINUSE') {
        console.error(`❌ Port ${PORT} is already in use. Please stop the existing process or use a different port.`);
        console.error(`💡 Try running: pm2 stop learn-traffic-rules-backend && pm2 start learn-traffic-rules-backend`);
        console.error(`💡 Or kill the process using port ${PORT}: lsof -ti:${PORT} | xargs kill -9`);
      } else {
        console.error(`❌ Server failed to start:`, err.message);
      }
      process.exit(1);
    });
    
    // Graceful shutdown handlers
    process.on('SIGTERM', async () => {
      console.log('🛑 SIGTERM received, shutting down gracefully...');
      notificationService.stopCronJobs();
      await require('./src/config/database').sequelize.close();
      process.exit(0);
    });

    process.on('SIGINT', async () => {
      console.log('🛑 SIGINT received, shutting down gracefully...');
      notificationService.stopCronJobs();
      await require('./src/config/database').sequelize.close();
      process.exit(0);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error.message);
    console.error('🔍 Error details:', error);
    process.exit(1);
  }
};

// Create default admin user
const createDefaultAdmin = async () => {
  try {
    const User = require('./src/models/User');
    const bcrypt = require('bcryptjs');
    const { v4: uuidv4 } = require('uuid');

    // Check if admin already exists
    const existingAdmin = await User.findOne({
      where: { role: 'ADMIN' }
    });

    if (existingAdmin) {
      console.log('✅ Admin user already exists');
      return;
    }

    // Create admin user
    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
    const hashedPassword = await bcrypt.hash('admin123', saltRounds);

    await User.create({
      id: uuidv4(),
      fullName: 'System Administrator',
      phoneNumber: '0782828282',
      password: hashedPassword,
      role: 'ADMIN',
      deviceId: 'admin-device-bypass',
      isActive: true
    });

    console.log('🔑 DEFAULT ADMIN CREATED:');
    console.log('   Username: admin123');
    console.log('   Password: admin123');
    console.log('   Role: ADMIN');
    console.log('   Note: Admin can login from any device');
  } catch (error) {
    console.error('❌ Error creating default admin:', error.message);
  }
};

startServer();

module.exports = app;
