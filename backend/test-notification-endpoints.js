const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function testNotificationEndpoints() {
  console.log('🧪 Testing Notification Endpoints...\n');

  try {
    // Step 1: Login to get auth token
    console.log('1. Logging in as admin...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/login`, {
      phoneNumber: '0780494000',
      deviceId: 'admin-device-bypass'
    });
    
    if (!loginResponse.data.success) {
      throw new Error('Login failed');
    }
    
    const authToken = loginResponse.data.data.token;
    console.log('✅ Login successful');
    console.log(`   User: ${loginResponse.data.data.user.fullName}`);
    console.log(`   Token: ${authToken.substring(0, 20)}...\n`);

    // Step 2: Test notification preferences endpoint
    console.log('2. Testing notification preferences endpoint...');
    try {
      const prefsResponse = await axios.get(`${BASE_URL}/api/notifications/preferences`, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      if (prefsResponse.data.success) {
        console.log('✅ Notification preferences endpoint working');
        console.log(`   Push notifications: ${prefsResponse.data.data.pushNotifications}`);
        console.log(`   Study reminders: ${prefsResponse.data.data.studyReminders}\n`);
      }
    } catch (error) {
      console.log('❌ Notification preferences endpoint failed:', error.response?.data?.message || error.message);
    }

    // Step 3: Test study reminder endpoint
    console.log('3. Testing study reminder endpoint...');
    try {
      const reminderResponse = await axios.get(`${BASE_URL}/api/notifications/study-reminder`, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      if (reminderResponse.data.success) {
        console.log('✅ Study reminder endpoint working');
        console.log(`   Active reminder: ${reminderResponse.data.data ? 'Yes' : 'No'}\n`);
      }
    } catch (error) {
      console.log('❌ Study reminder endpoint failed:', error.response?.data?.message || error.message);
    }

    // Step 4: Test notifications list endpoint
    console.log('4. Testing notifications list endpoint...');
    try {
      const notificationsResponse = await axios.get(`${BASE_URL}/api/notifications`, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      if (notificationsResponse.data.success) {
        console.log('✅ Notifications list endpoint working');
        console.log(`   Total notifications: ${notificationsResponse.data.data.notifications.length}\n`);
      }
    } catch (error) {
      console.log('❌ Notifications list endpoint failed:', error.response?.data?.message || error.message);
    }

    console.log('🎉 Notification endpoints test completed!');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data?.message || error.message);
  }
}

// Run the test
testNotificationEndpoints();
