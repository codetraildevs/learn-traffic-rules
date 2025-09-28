const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';

async function testAdminLogin() {
  try {
    console.log('🔑 Testing Admin Login...\n');

    // Test admin login with any device ID
    const loginData = {
      password: 'admin123',
      deviceId: 'test-device-12345' // Any device ID should work for admin
    };

    console.log('📤 Sending login request:');
    console.log('   Password: admin123');
    console.log('   Device ID: test-device-12345');
    console.log('   Expected: Should work (admin bypass)\n');

    const response = await axios.post(`${BASE_URL}/auth/login`, loginData);

    console.log('✅ Admin Login Successful!');
    console.log('📊 Response:');
    console.log(`   Success: ${response.data.success}`);
    console.log(`   Message: ${response.data.message}`);
    console.log(`   User: ${response.data.data.user.fullName}`);
    console.log(`   Role: ${response.data.data.user.role}`);
    console.log(`   Device ID: ${response.data.data.user.deviceId}`);
    console.log(`   Token: ${response.data.data.token.substring(0, 20)}...`);

  } catch (error) {
    console.error('❌ Admin Login Failed:');
    if (error.response) {
      console.error(`   Status: ${error.response.status}`);
      console.error(`   Message: ${error.response.data.message}`);
    } else {
      console.error(`   Error: ${error.message}`);
    }
  }
}

async function testRegularUserLogin() {
  try {
    console.log('\n👤 Testing Regular User Login...\n');

    // Test regular user login with wrong device ID
    const loginData = {
      password: 'password123',
      deviceId: 'wrong-device-12345' // Wrong device ID
    };

    console.log('📤 Sending login request:');
    console.log('   Password: password123');
    console.log('   Device ID: wrong-device-12345');
    console.log('   Expected: Should fail (device not registered)\n');

    const response = await axios.post(`${BASE_URL}/auth/login`, loginData);

    console.log('❌ Unexpected Success!');
    console.log('📊 Response:', response.data);

  } catch (error) {
    console.log('✅ Regular User Login Failed (Expected):');
    if (error.response) {
      console.log(`   Status: ${error.response.status}`);
      console.log(`   Message: ${error.response.data.message}`);
    } else {
      console.log(`   Error: ${error.message}`);
    }
  }
}

async function runTests() {
  console.log('🚀 Starting Security Tests...\n');
  console.log('=' .repeat(50));
  
  await testAdminLogin();
  await testRegularUserLogin();
  
  console.log('\n' + '=' .repeat(50));
  console.log('🏁 Tests completed!');
}

runTests();
