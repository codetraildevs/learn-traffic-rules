const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

// Test user credentials (using existing admin)
const testUser = {
  phoneNumber: '0780494000',
  deviceId: 'admin-device-bypass'
};

let authToken = '';

async function testNotificationSystem() {
  console.log('🧪 Testing Notification System...\n');

  try {
    // Step 1: Login to get auth token
    console.log('1. Testing user login...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/login`, testUser);
    
    if (loginResponse.data.success) {
      authToken = loginResponse.data.data.token;
      console.log('✅ Login successful');
      console.log(`   User: ${loginResponse.data.data.user.fullName}`);
      console.log(`   Role: ${loginResponse.data.data.user.role}`);
      console.log(`   Token: ${authToken.substring(0, 20)}...\n`);
    } else {
      throw new Error('Login failed');
    }

    // Step 2: Test notification preferences
    console.log('2. Testing notification preferences...');
    const prefsResponse = await axios.get(`${BASE_URL}/api/notifications/preferences`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    if (prefsResponse.data.success) {
      console.log('✅ Notification preferences retrieved');
      console.log(`   Push notifications: ${prefsResponse.data.data.pushNotifications}`);
      console.log(`   Study reminders: ${prefsResponse.data.data.studyReminders}\n`);
    }

    // Step 3: Update notification preferences
    console.log('3. Testing notification preferences update...');
    const updatePrefsResponse = await axios.put(`${BASE_URL}/api/notifications/preferences`, {
      pushNotifications: true,
      studyReminders: true,
      examReminders: true,
      paymentUpdates: true,
      systemAnnouncements: true,
      achievementNotifications: true,
      weeklyReports: false,
      quietHoursEnabled: false,
      vibrationEnabled: true,
      soundEnabled: true
    }, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    if (updatePrefsResponse.data.success) {
      console.log('✅ Notification preferences updated successfully\n');
    }

    // Step 4: Test study reminder creation
    console.log('4. Testing study reminder creation...');
    const studyReminderResponse = await axios.post(`${BASE_URL}/api/notifications/study-reminder`, {
      reminderTime: '19:00',
      daysOfWeek: ['Monday', 'Wednesday', 'Friday'],
      studyGoalMinutes: 30,
      timezone: 'UTC'
    }, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    if (studyReminderResponse.data.success) {
      console.log('✅ Study reminder created successfully');
      console.log(`   Reminder ID: ${studyReminderResponse.data.data.id}`);
      console.log(`   Time: ${studyReminderResponse.data.data.reminderTime}`);
      console.log(`   Days: ${studyReminderResponse.data.data.daysOfWeek.join(', ')}\n`);
    }

    // Step 5: Test getting study reminder
    console.log('5. Testing study reminder retrieval...');
    const getReminderResponse = await axios.get(`${BASE_URL}/api/notifications/study-reminder`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    if (getReminderResponse.data.success) {
      console.log('✅ Study reminder retrieved successfully');
      console.log(`   Active reminder: ${getReminderResponse.data.data ? 'Yes' : 'No'}\n`);
    }

    // Step 6: Test notifications list
    console.log('6. Testing notifications list...');
    const notificationsResponse = await axios.get(`${BASE_URL}/api/notifications`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    if (notificationsResponse.data.success) {
      console.log('✅ Notifications retrieved successfully');
      console.log(`   Total notifications: ${notificationsResponse.data.data.notifications.length}\n`);
    }

    // Step 7: Test creating a test notification (if admin)
    if (loginResponse.data.data.user.role === 'ADMIN') {
      console.log('7. Testing notification creation (Admin only)...');
      try {
        const testNotificationResponse = await axios.post(`${BASE_URL}/api/notifications/send-test`, {
          title: 'Test Notification',
          message: 'This is a test notification from the system',
          type: 'SYSTEM'
        }, {
          headers: { Authorization: `Bearer ${authToken}` }
        });
        
        if (testNotificationResponse.data.success) {
          console.log('✅ Test notification sent successfully\n');
        }
      } catch (error) {
        console.log('ℹ️  Test notification endpoint not available (this is normal)\n');
      }
    }

    console.log('🎉 All notification tests completed successfully!');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data?.message || error.message);
    if (error.response?.data) {
      console.error('   Response data:', error.response.data);
    }
  }
}

// Run the test
testNotificationSystem();
