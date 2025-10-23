const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const authService = require('../services/authService');
const deviceService = require('../services/deviceService');
const User = require('../models/User');

class AuthController {
  /**
   * Find admin user by password (for testing purposes)
   * This allows admin to login from any device
   */
  async findAdminByPassword(password) {
    try {
      console.log(`🔍 FINDING ADMIN: Looking for admin with password`);
      // Find admin users
      const adminUsers = await User.findAll({
        where: { role: 'ADMIN' }
      });
      console.log(`🔍 ADMIN USERS FOUND: ${adminUsers.length} admin users`);

      // Check each admin's password
      for (const admin of adminUsers) {
        console.log(`🔍 CHECKING ADMIN: ${admin.fullName} (${admin.phoneNumber})`);
        const isPasswordValid = await bcrypt.compare(password, admin.password);
        console.log(`🔍 PASSWORD VALID: ${isPasswordValid}`);
        if (isPasswordValid) {
          console.log(`✅ ADMIN FOUND: ${admin.fullName}`);
          return admin;
        }
      }
      console.log(`❌ NO ADMIN FOUND: No admin with matching password`);
      return null;
    } catch (error) {
      console.error('Error finding admin by password:', error);
      return null;
    }
  }

  /**
   * Create default admin user for testing
   */
  async createDefaultAdmin(req, res) {
    try {
      // Check if admin already exists
      const existingAdmin = await User.findOne({
        where: { role: 'ADMIN' }
      });

      if (existingAdmin) {
        return res.status(400).json({
          success: false,
          message: 'Admin user already exists',
          data: { admin: existingAdmin }
        });
      }

      // Create admin user
      const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
      const hashedPassword = await bcrypt.hash('admin123', saltRounds);

      const adminUser = await User.create({
        id: uuidv4(),
        fullName: 'System Administrator',
        phoneNumber: '+1234567890',
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

      res.status(200).json({
        success: true,
        message: 'Admin user created successfully',
        data: {
          admin: {
            id: adminUser.id,
            fullName: adminUser.fullName,
            phoneNumber: adminUser.phoneNumber,
            role: adminUser.role,
            deviceId: adminUser.deviceId,
            isActive: adminUser.isActive
          },
          credentials: {
            username: 'admin123',
            password: 'admin123'
          }
        }
      });
    } catch (error) {
      console.error('Error creating default admin:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Register a new user with device ID validation
   */
  async register(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { fullName, phoneNumber, deviceId, role } = req.body;

      console.log(`🔍 REGISTRATION ATTEMPT: Name: ${fullName}, Phone: ${phoneNumber}, Device: ${deviceId}`);

      // Check if phone number is already registered
      const existingPhone = await User.findOne({
        where: { phoneNumber: phoneNumber }
      });
      if (existingPhone) {
        return res.status(409).json({
          success: false,
          message: 'This phone number is already registered'
        });
      }

      // Check if device is already registered
      const existingDevice = await User.findOne({
        where: { deviceId: deviceId }
      });
      if (existingDevice) {
        return res.status(409).json({
          success: false,
          message: 'This device is already registered to another account'
        });
      }

      // Create user (no password needed)
      const userData = {
        fullName,
        phoneNumber,
        deviceId,
        role: role || 'USER'
      };

      const user = await authService.createUser(userData);

      // Generate JWT tokens
      const token = jwt.sign(
        { userId: user.id, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
      );

      const refreshToken = jwt.sign(
        { userId: user.id, type: 'refresh' },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d' }
      );

      // Notify manager for onboarding call
      await authService.notifyManagerForOnboarding(user);

      res.status(201).json({
        success: true,
        message: 'User registered successfully. Manager will call you for onboarding.',
        data: {
          user: {
            id: user.id,
            fullName: user.fullName,
            phoneNumber: user.phoneNumber,
            role: user.role,
            deviceId: user.deviceId,
            createdAt: user.createdAt
          },
          token,
          refreshToken
        }
      });

    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Login user with device ID validation
   */
  async login(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { phoneNumber, deviceId } = req.body;

      console.log(`🔍 LOGIN ATTEMPT: Phone: ${phoneNumber}, Device: ${deviceId}`);

      // Find user by phone number first
      let user = await User.findOne({
        where: {
          phoneNumber: phoneNumber
        }
      });

      if (!user) {
        console.log(`❌ USER NOT FOUND: No user found with phone ${phoneNumber}`);
        return res.status(401).json({
          success: false,
          message: 'Invalid phone number or device ID'
        });
      }

      // For non-admin users, also check device ID
      if (user.role !== 'ADMIN' && user.deviceId !== deviceId) {
        console.log(`❌ DEVICE MISMATCH: User ${user.fullName} device ${user.deviceId} != ${deviceId}`);
        return res.status(401).json({
          success: false,
          message: 'Invalid phone number or device ID'
        });
      }

      console.log(`✅ USER FOUND: ${user.fullName} (${user.role})`);

      // Check if account is active
      if (!user.isActive) {
        return res.status(403).json({
          success: false,
          message: 'Account is locked. Please contact support.'
        });
      }

      // Log security event
      console.log(`🔐 LOGIN: User ${user.fullName} (${user.role}) logged in from device ${deviceId}`);

      // Generate JWT tokens
      const token = jwt.sign(
        { userId: user.id, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
      );

      const refreshToken = jwt.sign(
        { userId: user.id, type: 'refresh' },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d' }
      );

      // Update last login
      await authService.updateLastLogin(user.id);

      // Get access period information for regular users
      let accessPeriodInfo = null;
      if (user.role === 'USER') {
        const AccessCode = require('../models/AccessCode');
        console.log(`🔍 CHECKING ACCESS PERIOD for user ${user.id} (${user.phoneNumber})`);
        
        const activeAccessCode = await AccessCode.findOne({
          where: {
            userId: user.id,
            expiresAt: {
              [require('sequelize').Op.gt]: new Date()
            }
          },
          order: [['expiresAt', 'DESC']]
        });

        console.log(`🔍 ACTIVE ACCESS CODE FOUND:`, activeAccessCode ? {
          id: activeAccessCode.id,
          code: activeAccessCode.code,
          expiresAt: activeAccessCode.expiresAt,
          isUsed: activeAccessCode.isUsed,
          paymentTier: activeAccessCode.paymentTier,
          durationDays: activeAccessCode.durationDays
        } : 'None');

        if (activeAccessCode) {
          const now = new Date();
          const expiresAt = new Date(activeAccessCode.expiresAt);
          const remainingDays = Math.ceil((expiresAt - now) / (1000 * 60 * 60 * 24));
          
          console.log(`🔍 CALCULATED REMAINING DAYS: ${remainingDays} (expiresAt: ${expiresAt}, now: ${now})`);
          
          accessPeriodInfo = {
            hasAccess: true,
            expiresAt: activeAccessCode.expiresAt,
            remainingDays: Math.max(0, remainingDays),
            paymentTier: activeAccessCode.paymentTier,
            durationDays: activeAccessCode.durationDays,
            isUsed: activeAccessCode.isUsed
          };
        } else {
          console.log(`❌ NO ACTIVE ACCESS CODE for user ${user.id}`);
          accessPeriodInfo = {
            hasAccess: false,
            remainingDays: 0
          };
        }
      }

      res.json({
        success: true,
        message: 'Login successful',
        data: {
          user: {
            id: user.id,
            fullName: user.fullName,
            phoneNumber: user.phoneNumber,
            role: user.role,
            deviceId: user.deviceId,
            lastLogin: user.lastLogin
          },
          token,
          refreshToken,
          accessPeriod: accessPeriodInfo
        }
      });

    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Logout user and invalidate token
   */
  async logout(req, res) {
    try {
      // Simple logout - just return success
      // In a production app, you might want to implement token blacklisting
      res.json({
        success: true,
        message: 'Logout successful'
      });

    } catch (error) {
      console.error('Logout error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Refresh access token
   */
  async refreshToken(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { refreshToken } = req.body;
      const deviceId = req.deviceId;

      // Verify refresh token
      const decoded = jwt.verify(refreshToken, process.env.JWT_SECRET);
      
      if (decoded.type !== 'refresh') {
        return res.status(401).json({
          success: false,
          message: 'Invalid refresh token'
        });
      }

      // Find user and verify device
      const user = await authService.findUserById(decoded.userId);
      if (!user || user.deviceId !== deviceId) {
        return res.status(401).json({
          success: false,
          message: 'Invalid refresh token'
        });
      }

      // Generate new tokens
      const newToken = jwt.sign(
        { userId: user.id, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
      );

      const newRefreshToken = jwt.sign(
        { userId: user.id, type: 'refresh' },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d' }
      );

      res.json({
        success: true,
        message: 'Token refreshed successfully',
        data: {
          token: newToken,
          refreshToken: newRefreshToken
        }
      });

    } catch (error) {
      console.error('Token refresh error:', error);
      res.status(401).json({
        success: false,
        message: 'Invalid refresh token',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }


  /**
   * Request device change
   */
  async requestDeviceChange(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { newDeviceId, reason } = req.body;
      const userId = req.user.userId;

      // Check if new device is already registered
      const existingDevice = await deviceService.findDeviceById(newDeviceId);
      if (existingDevice) {
        return res.status(409).json({
          success: false,
          message: 'This device is already registered to another account'
        });
      }

      // Create device change request
      await authService.createDeviceChangeRequest(userId, newDeviceId, reason);

      // Notify admin
      await authService.notifyAdminForDeviceChange(userId, newDeviceId, reason);

      res.json({
        success: true,
        message: 'Device change request submitted. Admin approval required.'
      });

    } catch (error) {
      console.error('Device change request error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Request password reset
   */
  async forgotPassword(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { phoneNumber } = req.body;

      // Find user by phone number
      const user = await authService.findUserByPhoneNumber(phoneNumber);
      if (!user) {
        // Don't reveal if user exists or not for security
        return res.json({
          success: true,
          message: 'If an account with this phone number exists, a password reset code has been sent.'
        });
      }

      // Generate a simple 6-digit reset code
      const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
      const expiresAt = new Date();
      expiresAt.setMinutes(expiresAt.getMinutes() + 15); // 15 minutes expiry

      // Store reset code in user record temporarily
      await user.update({
        resetCode: resetCode,
        resetCodeExpires: expiresAt
      });

      // Send reset code via SMS (simplified for now)
      console.log(`Password reset code for ${user.fullName}: ${resetCode}`);
      
      // In production, you would send this via SMS
      // For now, we'll just log it for testing

      res.json({
        success: true,
        message: 'If an account with this phone number exists, a password reset code has been sent.',
        // For development only - remove in production
        resetCode: process.env.NODE_ENV === 'development' ? resetCode : undefined
      });

    } catch (error) {
      console.error('Forgot password error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Reset password with code
   */
  async resetPassword(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { phoneNumber, resetCode, newPassword } = req.body;

      // Find user with valid reset code
      const user = await User.findOne({
        where: {
          phoneNumber: phoneNumber,
          resetCode: resetCode,
          resetCodeExpires: {
            [require('sequelize').Op.gt]: new Date()
          }
        }
      });

      if (!user) {
        return res.status(400).json({
          success: false,
          message: 'Invalid or expired reset code'
        });
      }

      // Hash new password
      const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
      const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

      // Update user password and clear reset code
      await user.update({
        password: hashedPassword,
        resetCode: null,
        resetCodeExpires: null
      });

      res.json({
        success: true,
        message: 'Password reset successfully'
      });

    } catch (error) {
      console.error('Reset password error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Delete user account with cascade deletion
   */
  async deleteAccount(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { password } = req.body;
      const userId = req.user.userId;

      console.log('🗑️ User deleting own account via auth endpoint:', userId);

      // Get user and verify password
      const user = await authService.findUserById(userId);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      console.log('👤 User found:', {
        id: user.id,
        fullName: user.fullName,
        phoneNumber: user.phoneNumber
      });

      const isPasswordValid = await bcrypt.compare(password, user.password);
      if (!isPasswordValid) {
        return res.status(401).json({
          success: false,
          message: 'Invalid password'
        });
      }

      // Import models for cascade deletion
      const { AccessCode, ExamResult, PaymentRequest } = require('../models');

      // Delete all related data first (cascade deletion)
      console.log('🗑️ Deleting related data...');
      
      const deletionResults = await Promise.all([
        // Delete all access codes
        AccessCode.destroy({ where: { userId } }),
        // Delete all exam results
        ExamResult.destroy({ where: { userId } }),
        // Delete all payment requests
        PaymentRequest.destroy({ where: { userId } })
      ]);

      console.log('✅ Related data deleted:', {
        accessCodes: deletionResults[0],
        examResults: deletionResults[1],
        paymentRequests: deletionResults[2]
      });

      // Delete the user account
      await user.destroy();

      console.log('✅ User account deleted successfully');

      // Log account deletion for audit purposes
      console.log(`Account deleted for user: ${user.fullName} (${user.phoneNumber})`);

      res.json({
        success: true,
        message: 'Account and all related data deleted successfully',
        data: {
          deletedUserId: userId,
          deletedUserName: user.fullName,
          deletedData: {
            accessCodes: deletionResults[0],
            examResults: deletionResults[1],
            paymentRequests: deletionResults[2]
          }
        }
      });

    } catch (error) {
      console.error('Delete account error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
}

module.exports = new AuthController();
