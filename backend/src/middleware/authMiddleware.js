const jwt = require('jsonwebtoken');

/**
 * Authenticate JWT token
 */
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Access token required'
    });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) {
      return res.status(403).json({
        success: false,
        message: 'Invalid or expired token'
      });
    }

    req.user = decoded;
    next();
  });
};

/**
 * Check if user has required role
 */
const requireRole = (roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    const userRole = req.user.role;
    const allowedRoles = Array.isArray(roles) ? roles : [roles];

    if (!allowedRoles.includes(userRole)) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions'
      });
    }

    next();
  };
};

/**
 * Check if user is admin
 */
const requireAdmin = requireRole('ADMIN');

/**
 * Check if user is manager or admin
 */
const requireManager = requireRole(['MANAGER', 'ADMIN']);

/**
 * Check if user is active
 */
const requireActiveUser = async (req, res, next) => {
  try {
    const authService = require('../services/authService');
    const user = await authService.findUserById(req.user.userId);
    
    if (!user || !user.isActive) {
      return res.status(403).json({
        success: false,
        message: 'Account is inactive'
      });
    }

    req.userData = user;
    next();
  } catch (error) {
    console.error('Active user check error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

/**
 * Check if user email is verified
 */
const requireVerifiedEmail = async (req, res, next) => {
  try {
    const authService = require('../services/authService');
    const user = await authService.findUserById(req.user.userId);
    
    if (!user || !user.emailVerified) {
      return res.status(403).json({
        success: false,
        message: 'Email verification required'
      });
    }

    next();
  } catch (error) {
    console.error('Email verification check error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

module.exports = {
  authenticate: authenticateToken,
  authenticateToken,
  requireRole,
  requireAdmin,
  requireManager,
  requireActiveUser,
  requireVerifiedEmail
};
