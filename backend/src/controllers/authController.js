const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');
const authService = require('../services/authService');
const deviceService = require('../services/deviceService');
const User = require('../models/User');

class AuthController {
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

      const { password, fullName, phoneNumber, deviceId, role } = req.body;

      // Check if device is already registered
      const existingDevice = await deviceService.findDeviceById(deviceId);
      if (existingDevice) {
        return res.status(409).json({
          success: false,
          message: 'This device is already registered to another account'
        });
      }

      // Hash password
      const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
      const hashedPassword = await bcrypt.hash(password, saltRounds);

      // Create user
      const userData = {
        password: hashedPassword,
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

      const { password, deviceId } = req.body;

      // Find user by device ID
      const user = await deviceService.findDeviceById(deviceId);
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Device not registered'
        });
      }

      // Check if account is active
      if (!user.isActive) {
        return res.status(403).json({
          success: false,
          message: 'Account is locked. Please contact support.'
        });
      }

      // Verify password
      const isPasswordValid = await bcrypt.compare(password, user.password);
      if (!isPasswordValid) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials'
        });
      }

      // Device is already validated by finding user with deviceId

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
          refreshToken
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
      const userId = req.user.userId;
      
      // Invalidate refresh tokens (implement token blacklist if needed)
      await authService.invalidateUserTokens(userId);

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
   * Delete user account
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

      // Get user and verify password
      const user = await authService.findUserById(userId);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      const isPasswordValid = await bcrypt.compare(password, user.password);
      if (!isPasswordValid) {
        return res.status(401).json({
          success: false,
          message: 'Invalid password'
        });
      }

      // Delete user (cascade will handle related records)
      await user.destroy();

      // Log account deletion for audit purposes
      console.log(`Account deleted for user: ${user.fullName} (${user.phoneNumber})`);

      res.json({
        success: true,
        message: 'Account deleted successfully'
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
