const bcrypt = require('bcrypt');
const { User } = require('./src/models');

async function testAdmin() {
  try {
    console.log('🔍 Testing admin user...');
    
    // Find admin users
    const adminUsers = await User.findAll({
      where: { role: 'ADMIN' }
    });
    
    console.log(`Found ${adminUsers.length} admin users`);
    
    for (const admin of adminUsers) {
      console.log(`Admin: ${admin.fullName} (${admin.phoneNumber})`);
      console.log(`Device ID: ${admin.deviceId}`);
      console.log(`Password hash: ${admin.password.substring(0, 20)}...`);
      
      // Test password
      const isPasswordValid = await bcrypt.compare('admin123', admin.password);
      console.log(`Password 'admin123' valid: ${isPasswordValid}`);
      
      // Test with different password
      const isPasswordValid2 = await bcrypt.compare('admin', admin.password);
      console.log(`Password 'admin' valid: ${isPasswordValid2}`);
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    process.exit(0);
  }
}

testAdmin();
