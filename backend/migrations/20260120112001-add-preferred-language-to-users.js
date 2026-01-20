'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    // Check if the column exists before trying to add it
    const tableDescription = await queryInterface.describeTable('users');
    
    if (!tableDescription.preferredLanguage) {
      await queryInterface.addColumn('users', 'preferredLanguage', {
        type: Sequelize.STRING(10),
        allowNull: true,
        defaultValue: null,
      });
      console.log('✅ Added preferredLanguage column to users table');
    } else {
      console.log('⚠️  preferredLanguage column already exists, skipping addition');
    }
  },

  async down (queryInterface, Sequelize) {
    // Check if the column exists before trying to remove it
    const tableDescription = await queryInterface.describeTable('users');
    
    if (tableDescription.preferredLanguage) {
      await queryInterface.removeColumn('users', 'preferredLanguage');
      console.log('✅ Removed preferredLanguage column from users table');
    } else {
      console.log('⚠️  preferredLanguage column does not exist, skipping removal');
    }
  }
};

