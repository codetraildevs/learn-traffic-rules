'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.removeColumn('notificationpreferences', 'emailNotifications');
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.addColumn('notificationpreferences', 'emailNotifications', {
      type: Sequelize.BOOLEAN,
      defaultValue: true,
      allowNull: false,
    });
  }
};
