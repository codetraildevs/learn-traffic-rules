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
    const { fullName, phoneNumber, deviceId, role } = userData;
    
    return await User.create({
      fullName,
      phoneNumber,
      deviceId,
      role: role || 'USER'
    });
  }

  /**
   * Update user last login
   * Uses direct UPDATE query to avoid lock contention
   * Single attempt only - lastLogin is non-critical; failing fast avoids holding connections
   */
  async updateLastLogin(userId) {
    const maxRetries = 1;
    const retryDelay = 100;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Use direct UPDATE instead of fetch-then-save to reduce lock contention
        // This avoids SELECT ... FOR UPDATE lock, only uses UPDATE lock
        await User.update(
          { 
            lastLogin: new Date(),
            updatedAt: new Date()
          },
          { 
            where: { id: userId },
            // Use a transaction with shorter timeout to prevent long waits
            transaction: null, // No transaction needed for simple update
            // Skip validation and hooks for performance
            validate: false,
            hooks: false
          }
        );
        
        // Success - exit retry loop
        return;
      } catch (error) {
        // Check if it's a lock timeout error
        const isLockTimeout = error.code === 'ER_LOCK_WAIT_TIMEOUT' || 
                             error.errno === 1205 ||
                             error.message?.includes('Lock wait timeout');
        
        if (isLockTimeout && attempt < maxRetries) {
          // Wait before retrying (exponential backoff)
          const delay = retryDelay * Math.pow(2, attempt - 1);
          console.warn(`⚠️ Lock timeout updating lastLogin for user ${userId}, retrying in ${delay}ms (attempt ${attempt}/${maxRetries})`);
          await new Promise(resolve => setTimeout(resolve, delay));
          continue;
        }
        
        // If not a lock timeout, or max retries reached, log and throw
        if (isLockTimeout) {
          console.error(`❌ Failed to update lastLogin for user ${userId} after ${maxRetries} attempts: Lock timeout`);
          // Don't throw - lastLogin update failure shouldn't block login
          return;
        }
        
        // For other errors, log and throw
        console.error(`❌ Error updating lastLogin for user ${userId}:`, error);
        throw error;
      }
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
