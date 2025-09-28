const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function testStudyReminder() {
  console.log('🔔 Testing Study Reminder System...\n');

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

    // Step 2: Get current time and add 1 minute
    const now = new Date();
    const testTime = new Date(now.getTime() + 1 * 60 * 1000); // +1 minute
    const timeString = testTime.toTimeString().slice(0, 5); // HH:MM format
    const currentDay = testTime.toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase();
    
    console.log(`2. Setting up test reminder for ${timeString} on ${currentDay}...`);

    // Step 3: Create study reminder for current time + 1 minute
    const reminderResponse = await axios.post(`${BASE_URL}/api/notifications/study-reminder`, {
      reminderTime: timeString,
      daysOfWeek: [currentDay],
      studyGoalMinutes: 15,
      timezone: 'UTC'
    }, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    
    console.log('✅ Study reminder created');
    console.log(`   Time: ${reminderResponse.data.data.reminderTime}`);
    console.log(`   Days: ${reminderResponse.data.data.daysOfWeek.join(', ')}`);
    console.log(`   Goal: ${reminderResponse.data.data.studyGoalMinutes} minutes\n`);

    // Step 4: Check existing notifications
    console.log('3. Checking existing notifications...');
    const notificationsResponse = await axios.get(`${BASE_URL}/api/notifications`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    
    const notifications = notificationsResponse.data.data.notifications;
    console.log(`✅ Found ${notifications.length} notifications\n`);

    // Step 5: Wait and check for new notifications
    console.log('4. Waiting for reminder to trigger...');
    console.log(`   Reminder should trigger at: ${timeString}`);
    console.log(`   Current time: ${now.toTimeString().slice(0, 5)}`);
    console.log(`   Waiting 2 minutes for reminder to trigger...\n`);

    // Wait 2 minutes
    await new Promise(resolve => setTimeout(resolve, 2 * 60 * 1000));

    // Check notifications again
    console.log('5. Checking for new notifications after wait...');
    const newNotificationsResponse = await axios.get(`${BASE_URL}/api/notifications`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    
    const newNotifications = newNotificationsResponse.data.data.notifications;
    console.log(`✅ Found ${newNotifications.length} notifications after wait`);

    if (newNotifications.length > notifications.length) {
      const studyReminders = newNotifications.filter(n => n.type === 'STUDY_REMINDER');
      console.log(`🎉 Study reminder triggered! Found ${studyReminders.length} study reminder notifications`);
      
      studyReminders.forEach((notif, index) => {
        console.log(`   ${index + 1}. ${notif.title}`);
        console.log(`      Message: ${notif.message}`);
        console.log(`      Created: ${new Date(notif.createdAt).toLocaleString()}`);
      });
    } else {
      console.log('❌ No new study reminder notifications found');
      console.log('   This might be due to:');
      console.log('   - Cron job not running');
      console.log('   - Time mismatch');
      console.log('   - Study reminders disabled in preferences');
    }

    console.log('\n🎉 Study reminder test completed!');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data?.message || error.message);
  }
}

// Run the test
testStudyReminder();
