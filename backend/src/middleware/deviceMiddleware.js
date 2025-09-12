/**
 * Validate device ID from headers
 */
const validateDeviceId = (req, res, next) => {
  const deviceId = req.headers['device-id'];

  if (!deviceId) {
    return res.status(400).json({
      success: false,
      message: 'Device ID is required in headers'
    });
  }

  // Basic device ID format validation
  if (typeof deviceId !== 'string' || deviceId.length < 10) {
    return res.status(400).json({
      success: false,
      message: 'Invalid device ID format'
    });
  }

  // Store device ID in request object
  req.deviceId = deviceId;
  next();
};

/**
 * Check if device is not already registered
 */
const checkDeviceNotRegistered = async (req, res, next) => {
  try {
    const authService = require('../services/authService');
    const deviceId = req.body.deviceId;

    if (!deviceId) {
      return res.status(400).json({
        success: false,
        message: 'Device ID is required'
      });
    }

    const isRegistered = await authService.isDeviceRegistered(deviceId);
    if (isRegistered) {
      return res.status(409).json({
        success: false,
        message: 'This device is already registered to another account'
      });
    }

    next();
  } catch (error) {
    console.error('Device registration check error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

module.exports = {
  validateDeviceId,
  checkDeviceNotRegistered
};
