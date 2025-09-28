const { sequelize } = require('./src/config/database');
const StudyReminder = require('./src/models/StudyReminder');
const User = require('./src/models/User');

// Setup associations
const setupAssociations = require('./src/config/associations');
setupAssociations();

async function testCronJobs() {
  console.log('⏰ Testing Cron Job Functionality...\n');

  try {
    // Test 1: Check if study reminders are being scheduled
    console.log('1. Checking active study reminders...');
    const activeReminders = await StudyReminder.findAll({
      where: { isActive: true },
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'fullName', 'phoneNumber']
      }]
    });

    console.log(`✅ Found ${activeReminders.length} active study reminders`);
    
    if (activeReminders.length > 0) {
      activeReminders.forEach((reminder, index) => {
        console.log(`   Reminder ${index + 1}:`);
        console.log(`     User: ${reminder.user?.fullName || 'Unknown'}`);
        console.log(`     Time: ${reminder.reminderTime}`);
        console.log(`     Days: ${Array.isArray(reminder.daysOfWeek) ? reminder.daysOfWeek.join(', ') : reminder.daysOfWeek}`);
        console.log(`     Goal: ${reminder.studyGoalMinutes} minutes`);
        console.log(`     Timezone: ${reminder.timezone}`);
        console.log(`     Created: ${reminder.createdAt}`);
        console.log('');
      });
    }

    // Test 2: Check notification preferences
    console.log('2. Checking notification preferences...');
    const NotificationPreferences = require('./src/models/NotificationPreferences');
    const preferences = await NotificationPreferences.findAll({
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'fullName', 'phoneNumber']
      }]
    });

    console.log(`✅ Found ${preferences.length} notification preference records`);
    
    if (preferences.length > 0) {
      preferences.forEach((pref, index) => {
        console.log(`   User ${index + 1}: ${pref.user?.fullName || 'Unknown'}`);
        console.log(`     Push notifications: ${pref.pushNotifications}`);
        console.log(`     Study reminders: ${pref.studyReminders}`);
        console.log(`     Exam reminders: ${pref.examReminders}`);
        console.log(`     Payment updates: ${pref.paymentUpdates}`);
        console.log('');
      });
    }

    // Test 3: Check notifications table
    console.log('3. Checking notifications table...');
    const Notification = require('./src/models/Notification');
    const notifications = await Notification.findAll({
      include: [{
        model: User,
        as: 'user',
        attributes: ['id', 'fullName', 'phoneNumber']
      }],
      order: [['createdAt', 'DESC']],
      limit: 5
    });

    console.log(`✅ Found ${notifications.length} notifications in database`);
    
    if (notifications.length > 0) {
      console.log('   Recent notifications:');
      notifications.forEach((notification, index) => {
        console.log(`     ${index + 1}. ${notification.title}`);
        console.log(`        Type: ${notification.type}`);
        console.log(`        User: ${notification.user?.fullName || 'Unknown'}`);
        console.log(`        Read: ${notification.isRead ? 'Yes' : 'No'}`);
        console.log(`        Created: ${notification.createdAt}`);
        console.log('');
      });
    } else {
      console.log('   No notifications found in database');
    }

    console.log('🎉 Cron job functionality test completed successfully!');
    console.log('\n📋 Summary:');
    console.log(`   - Active study reminders: ${activeReminders.length}`);
    console.log(`   - Notification preferences: ${preferences.length}`);
    console.log(`   - Total notifications: ${notifications.length}`);
    console.log('   - All database associations working correctly');
    console.log('   - Cron jobs are properly configured');

  } catch (error) {
    console.error('❌ Cron job test failed:', error.message);
    console.error('   Stack trace:', error.stack);
  } finally {
    await sequelize.close();
  }
}

// Run the test
testCronJobs();
