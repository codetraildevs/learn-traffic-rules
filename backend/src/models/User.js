const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  fullName: {
    type: DataTypes.STRING(200),
    allowNull: false,
    validate: {
      len: [2, 200]
    }
  },
  phoneNumber: {
    type: DataTypes.STRING(20),
    allowNull: false,
    unique: true,
    validate: {
      is: /^(\+250|250|0)?[7][2389][0-9]{7}$/
    }
  },
  deviceId: {
    type: DataTypes.STRING(255),
    allowNull: false,
    unique: true,
    validate: {
      len: [10, 255]
    }
  },
  role: {
    type: DataTypes.ENUM('USER', 'MANAGER', 'ADMIN'),
    defaultValue: 'USER',
    allowNull: false
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
    allowNull: false
  },
  lastLogin: {
    type: DataTypes.DATE,
    allowNull: true
  },
  resetCode: {
    type: DataTypes.STRING(10),
    allowNull: true
  },
  resetCodeExpires: {
    type: DataTypes.DATE,
    allowNull: true
  },
  lastSyncAt: {
    type: DataTypes.DATE,
    allowNull: true
  },
  isBlocked: {
    type: DataTypes.INTEGER,
    defaultValue: 1,
    allowNull: false
  },
  blockReason: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  blockedAt: {
    type: DataTypes.DATE,
    allowNull: true
  }
}, {
  tableName: 'users',
  timestamps: true,
  createdAt: 'createdAt',
  updatedAt: 'updatedAt',
  hooks: {
    beforeCreate: (user) => {
      // Remove password from JSON output
      user.toJSON = function() {
        const values = Object.assign({}, this.get());
        delete values.password;
        return values;
      };
    }
  }
});

// Instance methods
User.prototype.updateLastLogin = async function() {
  this.lastLogin = new Date();
  await this.save();
  return this;
};

User.prototype.toPublicJSON = function() {
  return {
    id: this.id,
    fullName: this.fullName,
    phoneNumber: this.phoneNumber,
    role: this.role,
    isActive: this.isActive,
    createdAt: this.createdAt,
    lastLogin: this.lastLogin
  };
};

// Static methods
User.isDeviceRegistered = async function(deviceId) {
  const user = await User.findOne({ where: { deviceId } });
  return user !== null;
};

module.exports = User;
