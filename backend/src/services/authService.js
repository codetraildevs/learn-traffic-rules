const User = require('../models/User');

class AuthService {
  /**
   * Find user by ID
   */
  async findUserById(id) {
    return await User.findByPk(id);
  }

  /**
   * Create new user
   */
  async createUser(userData) {
    const { password, fullName, phoneNumber, deviceId, role } = userData;
    
    return await User.create({
      password,
      fullName,
      phoneNumber,
      deviceId,
      role: role || 'USER'
    });
  }

  /**
   * Update user last login
   */
  async updateLastLogin(userId) {
    const user = await User.findByPk(userId);
    if (user) {
      await user.updateLastLogin();
    }
  }

  /**
   * Check if device is already registered
   */
  async isDeviceRegistered(deviceId) {
    return await User.isDeviceRegistered(deviceId);
  }

  /**
   * Notify manager for onboarding call
   */
  async notifyManagerForOnboarding(user) {
    console.log(`📞 Manager notification: New user ${user.phoneNumber} registered. Please call for onboarding.`);
    // In real implementation, you would send notification to manager dashboard
  }

  /**
   * Find user by phone number
   */
  async findUserByPhoneNumber(phoneNumber) {
    try {
      const user = await User.findOne({ where: { phoneNumber } });
      return user;
    } catch (error) {
      console.error('Find user by phone number error:', error);
      throw error;
    }
  }

  /**
   * Update user password
   */
  async updateUserPassword(userId, hashedPassword) {
    try {
      const user = await User.findByPk(userId);
      if (!user) {
        throw new Error('User not found');
      }
      
      await user.update({ password: hashedPassword });
      return user;
    } catch (error) {
      console.error('Update user password error:', error);
      throw error;
    }
  }

  /**
   * Notify admin for device change request
   */
  async notifyAdminForDeviceChange(userId, newDeviceId, reason) {
    console.log(`🔒 Admin notification: User ${userId} requested device change to ${newDeviceId}. Reason: ${reason}`);
    // In real implementation, you would send notification to admin dashboard
  }
}

module.exports = new AuthService();
