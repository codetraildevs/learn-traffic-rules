const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function testImmediateReminder() {
  console.log('🔔 Testing Immediate Study Reminder...\n');

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

    // Step 2: Get current time
    const now = new Date();
    const timeString = now.toTimeString().slice(0, 5); // HH:MM format
    const currentDay = now.toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase();
    
    console.log(`2. Setting up test reminder for RIGHT NOW (${timeString}) on ${currentDay}...`);

    // Step 3: Create study reminder for current time
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

    // Step 4: Manually trigger the cron job check
    console.log('3. Manually triggering cron job check...');
    
    // Import the notification service and trigger manually
    const notificationService = require('./src/services/notificationService');
    await notificationService.checkStudyReminders();
    
    console.log('✅ Cron job check completed\n');

    // Step 5: Check for new notifications
    console.log('4. Checking for new notifications...');
    const notificationsResponse = await axios.get(`${BASE_URL}/api/notifications`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    
    const notifications = notificationsResponse.data.data.notifications;
    console.log(`✅ Found ${notifications.length} total notifications`);

    const studyReminders = notifications.filter(n => n.type === 'STUDY_REMINDER');
    console.log(`📚 Found ${studyReminders.length} study reminder notifications`);

    if (studyReminders.length > 0) {
      console.log('\n🎉 Study reminders found:');
      studyReminders.forEach((notif, index) => {
        console.log(`   ${index + 1}. ${notif.title}`);
        console.log(`      Message: ${notif.message}`);
        console.log(`      Created: ${new Date(notif.createdAt).toLocaleString()}`);
        console.log(`      Read: ${notif.isRead ? 'Yes' : 'No'}`);
      });
    } else {
      console.log('\n❌ No study reminder notifications found');
      console.log('   Possible issues:');
      console.log('   - Study reminders disabled in preferences');
      console.log('   - Time format mismatch');
      console.log('   - Day name mismatch');
    }

    console.log('\n🎉 Immediate reminder test completed!');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data?.message || error.message);
  }
}

// Run the test
testImmediateReminder();
