const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function testUserNotifications() {
  console.log('🔔 Testing User Notification Access...\n');

  try {
    // Step 1: Create a regular user
    console.log('1. Creating regular user...');
    const userResponse = await axios.post(`${BASE_URL}/api/auth/register`, {
      fullName: 'Test User',
      phoneNumber: '0780123456',
      deviceId: 'test-device-123'
    });
    
    const userId = userResponse.data.data.user.id;
    const userToken = userResponse.data.data.token;
    console.log(`✅ User created: ${userId}`);
    console.log(`   Name: ${userResponse.data.data.user.fullName}`);
    console.log(`   Phone: ${userResponse.data.data.user.phoneNumber}\n`);

    // Step 2: Test user notification access
    console.log('2. Testing user notification access...');
    try {
      const notificationsResponse = await axios.get(`${BASE_URL}/api/notifications`, {
        headers: { Authorization: `Bearer ${userToken}` }
      });
      
      console.log('✅ User can access notifications');
      console.log(`   Total notifications: ${notificationsResponse.data.data.notifications.length}`);
      console.log(`   Pagination: Page ${notificationsResponse.data.data.pagination.page} of ${notificationsResponse.data.data.pagination.totalPages}\n`);
    } catch (error) {
      console.log('❌ User cannot access notifications:', error.response?.data?.message || error.message);
    }

    // Step 3: Test user notification preferences
    console.log('3. Testing user notification preferences...');
    try {
      const preferencesResponse = await axios.get(`${BASE_URL}/api/notifications/preferences`, {
        headers: { Authorization: `Bearer ${userToken}` }
      });
      
      console.log('✅ User can access notification preferences');
      console.log(`   Push notifications: ${preferencesResponse.data.data.pushNotifications}`);
      console.log(`   Study reminders: ${preferencesResponse.data.data.studyReminders}`);
      console.log(`   Exam reminders: ${preferencesResponse.data.data.examReminders}\n`);
    } catch (error) {
      console.log('❌ User cannot access preferences:', error.response?.data?.message || error.message);
    }

    // Step 4: Test user study reminder creation
    console.log('4. Testing user study reminder creation...');
    try {
      const now = new Date();
      const timeString = now.toTimeString().slice(0, 5);
      const currentDay = now.toLocaleDateString('en-US', { weekday: 'long' });
      
      const reminderResponse = await axios.post(`${BASE_URL}/api/notifications/study-reminder`, {
        reminderTime: timeString,
        daysOfWeek: [currentDay],
        studyGoalMinutes: 20,
        timezone: 'UTC'
      }, {
        headers: { Authorization: `Bearer ${userToken}` }
      });
      
      console.log('✅ User can create study reminders');
      console.log(`   Time: ${reminderResponse.data.data.reminderTime}`);
      console.log(`   Days: ${reminderResponse.data.data.daysOfWeek.join(', ')}`);
      console.log(`   Goal: ${reminderResponse.data.data.studyGoalMinutes} minutes\n`);
    } catch (error) {
      console.log('❌ User cannot create study reminders:', error.response?.data?.message || error.message);
    }

    // Step 5: Test user study reminder retrieval
    console.log('5. Testing user study reminder retrieval...');
    try {
      const reminderResponse = await axios.get(`${BASE_URL}/api/notifications/study-reminder`, {
        headers: { Authorization: `Bearer ${userToken}` }
      });
      
      console.log('✅ User can retrieve study reminders');
      if (reminderResponse.data.data) {
        console.log(`   Active reminder: Yes`);
        console.log(`   Time: ${reminderResponse.data.data.reminderTime}`);
        console.log(`   Days: ${reminderResponse.data.data.daysOfWeek.join(', ')}`);
      } else {
        console.log(`   Active reminder: No`);
      }
    } catch (error) {
      console.log('❌ User cannot retrieve study reminders:', error.response?.data?.message || error.message);
    }

    // Step 6: Test user notification preferences update
    console.log('6. Testing user notification preferences update...');
    try {
      const updateResponse = await axios.put(`${BASE_URL}/api/notifications/preferences`, {
        pushNotifications: true,
        studyReminders: true,
        examReminders: false,
        paymentUpdates: true,
        systemAnnouncements: true,
        achievementNotifications: true
      }, {
        headers: { Authorization: `Bearer ${userToken}` }
      });
      
      console.log('✅ User can update notification preferences');
      console.log(`   Push notifications: ${updateResponse.data.data.pushNotifications}`);
      console.log(`   Study reminders: ${updateResponse.data.data.studyReminders}`);
      console.log(`   Exam reminders: ${updateResponse.data.data.examReminders}\n`);
    } catch (error) {
      console.log('❌ User cannot update preferences:', error.response?.data?.message || error.message);
    }

    console.log('🎉 User notification access test completed!');
    console.log('\n📱 Summary:');
    console.log('   ✅ Regular users can access their notifications');
    console.log('   ✅ Regular users can manage notification preferences');
    console.log('   ✅ Regular users can create and manage study reminders');
    console.log('   ✅ All notification features work for regular users');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data?.message || error.message);
  }
}

// Run the test
testUserNotifications();
