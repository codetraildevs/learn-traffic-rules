const User = require('../models/User');

class DeviceService {
  /**
   * Check if device is already registered
   */
  async findDeviceById(deviceId) {
    return await User.findOne({ where: { deviceId } });
  }

  /**
   * Simple device validation
   */
  async validateDevice(deviceId) {
    const device = await this.findDeviceById(deviceId);
    return device !== null;
  }
}

module.exports = new DeviceService();
