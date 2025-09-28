const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function checkAndUpdateReminder() {
  console.log('🔔 Checking and Updating Study Reminder...\n');

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

    // Step 2: Get existing study reminder
    console.log('2. Getting existing study reminder...');
    const reminderResponse = await axios.get(`${BASE_URL}/api/notifications/study-reminder`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    
    if (reminderResponse.data.success && reminderResponse.data.data) {
      const reminder = reminderResponse.data.data;
      const daysOfWeek = Array.isArray(reminder.daysOfWeek) ? reminder.daysOfWeek : JSON.parse(reminder.daysOfWeek || '[]');
      
      console.log('✅ Found existing study reminder:');
      console.log(`   Time: ${reminder.reminderTime}`);
      console.log(`   Days: ${daysOfWeek.join(', ')}`);
      console.log(`   Goal: ${reminder.studyGoalMinutes} minutes`);
      console.log(`   Enabled: ${reminder.isEnabled}`);
      console.log(`   Active: ${reminder.isActive}\n`);

      // Step 3: Update reminder to current time
      const now = new Date();
      const timeString = now.toTimeString().slice(0, 5); // HH:MM format
      const currentDay = now.toLocaleDateString('en-US', { weekday: 'long' }); // Keep capitalized
      
      console.log(`3. Updating reminder to current time (${timeString}) on ${currentDay}...`);
      
      const updateResponse = await axios.put(`${BASE_URL}/api/notifications/study-reminder/${reminder.id}`, {
        reminderTime: timeString,
        daysOfWeek: [currentDay],
        studyGoalMinutes: 15,
        timezone: 'UTC'
      }, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });
      
      console.log('✅ Study reminder updated');
      console.log(`   New Time: ${updateResponse.data.data.reminderTime}`);
      console.log(`   New Days: ${updateResponse.data.data.daysOfWeek.join(', ')}\n`);

      // Step 4: Manually trigger the cron job check
      console.log('4. Manually triggering cron job check...');
      
      // Import the notification service and trigger manually
      const notificationService = require('./src/services/notificationService');
      await notificationService.checkStudyReminders();
      
      console.log('✅ Cron job check completed\n');

      // Step 5: Check for new notifications
      console.log('5. Checking for new notifications...');
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
        console.log('   This means the cron job is not working properly');
      }

    } else {
      console.log('❌ No existing study reminder found');
    }

    console.log('\n🎉 Reminder check and update completed!');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data?.message || error.message);
  }
}

// Run the test
checkAndUpdateReminder();
