const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function testCurrentTimeReminder() {
  console.log('🔔 Testing Current Time Study Reminder...\n');

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

    // Step 2: Get current time + 1 minute
    const now = new Date();
    const testTime = new Date(now.getTime() + 1 * 60 * 1000); // +1 minute
    const timeString = testTime.toTimeString().slice(0, 5); // HH:MM format
    const currentDay = testTime.toLocaleDateString('en-US', { weekday: 'long' });
    
    console.log(`2. Setting up test reminder for ${timeString} on ${currentDay}...`);
    console.log(`   Current time: ${now.toTimeString().slice(0, 5)}`);
    console.log(`   Test time: ${timeString}`);

    // Step 3: Delete existing reminder first
    console.log('\n3. Deleting existing reminder...');
    try {
      const existingReminder = await axios.get(`${BASE_URL}/api/notifications/study-reminder`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });
      
      if (existingReminder.data.data) {
        await axios.delete(`${BASE_URL}/api/notifications/study-reminder/${existingReminder.data.data.id}`, {
          headers: { Authorization: `Bearer ${adminToken}` }
        });
        console.log('✅ Existing reminder deleted');
      }
    } catch (error) {
      console.log('ℹ️  No existing reminder to delete');
    }

    // Step 4: Create new reminder for current time + 1 minute
    console.log('\n4. Creating new reminder...');
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

    // Step 5: Wait for the reminder to trigger
    console.log('5. Waiting for reminder to trigger...');
    console.log(`   Will wait 2 minutes for reminder at ${timeString}`);
    console.log('   Watch the backend console for cron job logs...\n');

    // Wait 2 minutes
    await new Promise(resolve => setTimeout(resolve, 2 * 60 * 1000));

    // Step 6: Check for notifications
    console.log('6. Checking for notifications after wait...');
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
      console.log('   Check the backend console logs for cron job execution');
    }

    console.log('\n🎉 Current time reminder test completed!');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data?.message || error.message);
  }
}

// Run the test
testCurrentTimeReminder();
