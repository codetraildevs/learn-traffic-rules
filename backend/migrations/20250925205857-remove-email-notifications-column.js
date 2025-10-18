'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    // Check if the column exists before trying to drop it
    const tableDescription = await queryInterface.describeTable('notificationpreferences');
    
    if (tableDescription.emailNotifications) {
      await queryInterface.removeColumn('notificationpreferences', 'emailNotifications');
      console.log('✅ Removed emailNotifications column');
    } else {
      console.log('⚠️  emailNotifications column does not exist, skipping removal');
    }
  },

  async down (queryInterface, Sequelize) {
    // Check if the column exists before trying to add it
    const tableDescription = await queryInterface.describeTable('notificationpreferences');
    
    if (!tableDescription.emailNotifications) {
      await queryInterface.addColumn('notificationpreferences', 'emailNotifications', {
        type: Sequelize.BOOLEAN,
        defaultValue: true,
        allowNull: false,
      });
      console.log('✅ Added emailNotifications column');
    } else {
      console.log('⚠️  emailNotifications column already exists, skipping addition');
    }
  }
};
