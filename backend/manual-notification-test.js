const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function manualNotificationTest() {
  console.log('🔔 Manual Notification Test...\n');

  try {
    // Step 1: Login as admin
    console.log('1. Logging in as admin...');
    const adminLogin = await axios.post(`${BASE_URL}/api/auth/login`, {
      phoneNumber: '0780494000',
      deviceId: 'admin-device-bypass'
    });
    
    const adminToken = adminLogin.data.data.token;
    const adminUserId = adminLogin.data.data.user.id;
    console.log('✅ Admin logged in\n');

    // Step 2: Manually create a notification
    console.log('2. Creating manual notification...');
    const notificationResponse = await axios.post(`${BASE_URL}/api/notifications/send`, {
      userId: adminUserId,
      type: 'STUDY_REMINDER',
      title: 'Test Study Reminder! 📖',
      message: 'This is a test notification to verify the system is working.',
      category: 'STUDY',
      priority: 'MEDIUM'
    }, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    
    console.log('✅ Manual notification created');
    console.log(`   ID: ${notificationResponse.data.data.id}`);
    console.log(`   Title: ${notificationResponse.data.data.title}`);
    console.log(`   Message: ${notificationResponse.data.data.message}\n`);

    // Step 3: Check notifications
    console.log('3. Checking notifications...');
    const notificationsResponse = await axios.get(`${BASE_URL}/api/notifications`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    
    const notifications = notificationsResponse.data.data.notifications;
    console.log(`✅ Found ${notifications.length} total notifications`);

    if (notifications.length > 0) {
      console.log('\n📱 Recent notifications:');
      notifications.slice(0, 3).forEach((notif, index) => {
        console.log(`   ${index + 1}. ${notif.title}`);
        console.log(`      Message: ${notif.message}`);
        console.log(`      Type: ${notif.type}`);
        console.log(`      Created: ${new Date(notif.createdAt).toLocaleString()}`);
        console.log(`      Read: ${notif.isRead ? 'Yes' : 'No'}`);
        console.log('');
      });
    }

    console.log('🎉 Manual notification test completed!');
    console.log('\n💡 If you can see this notification in your app, the system is working!');
    console.log('   Check your mobile app notifications screen.');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data?.message || error.message);
  }
}

// Run the test
manualNotificationTest();
