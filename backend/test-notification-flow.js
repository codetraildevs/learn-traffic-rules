const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function testNotificationFlow() {
  console.log('🔔 Testing Notification Flow...\n');

  try {
    // Step 1: Login as admin
    console.log('1. Logging in as admin...');
    const adminLogin = await axios.post(`${BASE_URL}/api/auth/login`, {
      phoneNumber: '0780494000',
      deviceId: 'admin-device-bypass'
    });
    
    const adminToken = adminLogin.data.data.token;
    console.log('✅ Admin logged in\n');

    // Step 2: Create a test user
    console.log('2. Creating test user...');
    const userResponse = await axios.post(`${BASE_URL}/api/auth/register`, {
      fullName: 'Test User',
      phoneNumber: '0780123456',
      deviceId: 'test-device-123'
    });
    
    const userId = userResponse.data.data.user.id;
    console.log(`✅ Test user created: ${userId}\n`);

    // Step 3: Give access to user (this should trigger notification)
    console.log('3. Giving access to user (triggers notification)...');
    const accessResponse = await axios.post(`${BASE_URL}/api/user-management/give-access`, {
      userId: userId,
      accessCode: 'TEST123',
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
    }, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    
    console.log('✅ Access granted - notification should be sent\n');

    // Step 4: Check if notification was created
    console.log('4. Checking notifications...');
    const notificationsResponse = await axios.get(`${BASE_URL}/api/notifications`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    
    const notifications = notificationsResponse.data.data.notifications;
    console.log(`✅ Found ${notifications.length} notifications`);
    
    if (notifications.length > 0) {
      const latestNotification = notifications[0];
      console.log(`   Type: ${latestNotification.type}`);
      console.log(`   Title: ${latestNotification.title}`);
      console.log(`   Message: ${latestNotification.message}`);
      console.log(`   Created: ${latestNotification.createdAt}`);
    }

    // Step 5: Test study reminder creation
    console.log('\n5. Creating study reminder...');
    const reminderResponse = await axios.post(`${BASE_URL}/api/notifications/study-reminder`, {
      reminderTime: '09:00',
      daysOfWeek: ['monday', 'wednesday', 'friday'],
      studyGoalMinutes: 30,
      timezone: 'UTC'
    }, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    
    console.log('✅ Study reminder created');
    console.log(`   Time: ${reminderResponse.data.data.reminderTime}`);
    console.log(`   Days: ${reminderResponse.data.data.daysOfWeek.join(', ')}`);
    console.log(`   Goal: ${reminderResponse.data.data.studyGoalMinutes} minutes`);

    console.log('\n🎉 Notification flow test completed!');
    console.log('\n📱 To see real-time notifications:');
    console.log('   1. Open the mobile app');
    console.log('   2. Login with the test user');
    console.log('   3. Check the notifications screen');
    console.log('   4. Study reminders will trigger at scheduled times');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data?.message || error.message);
  }
}

// Run the test
testNotificationFlow();
