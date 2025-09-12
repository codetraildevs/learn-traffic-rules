const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const swaggerUi = require('swagger-ui-express');
const swaggerJsdoc = require('swagger-jsdoc');
const { testConnection, initializeTables } = require('./src/config/database');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Swagger configuration
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Traffic Rules Practice App API',
      version: '1.0.0',
      description: 'API documentation for Traffic Rules Practice App with manual payment processing and device ID validation',
      contact: {
        name: 'API Support',
        email: 'support@trafficrules.com'
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
        url: 'https://api.trafficrules.com',
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
            email: {
              type: 'string',
              format: 'email',
              description: 'User email address'
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
app.use('/api/auth', require('./src/routes/auth'));
app.use('/api/users', require('./src/routes/users'));
app.use('/api/exams', require('./src/routes/exams'));
app.use('/api/payments', require('./src/routes/payments'));
app.use('/api/questions', require('./src/routes/questions'));
app.use('/api/bulk-upload', require('./src/routes/bulkUpload'));
app.use('/api/offline', require('./src/routes/offline'));

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to Traffic Rules Practice App API',
    version: '1.0.0',
    documentation: '/api-docs',
    health: '/health'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
    availableRoutes: [
      'GET /',
      'GET /health',
      'GET /api-docs',
      'POST /api/auth/register',
      'POST /api/auth/login',
      'GET /api/users/profile',
      'GET /api/exams',
      'POST /api/payments/request',
      'GET /api/questions/exam/:examId',
      'POST /api/questions'
    ]
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
    await testConnection();
    
    // Initialize database tables
    await initializeTables();
    
    // Start server
    app.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📚 API Documentation: http://localhost:${PORT}/api-docs`);
      console.log(`🏥 Health Check: http://localhost:${PORT}/health`);
      console.log(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error.message);
    process.exit(1);
  }
};

startServer();

module.exports = app;
