const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const PaymentRequest = sequelize.define('PaymentRequest', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  amount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    validate: {
      min: 0
    }
  },
  paymentMethod: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  status: {
    type: DataTypes.ENUM('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'),
    defaultValue: 'PENDING',
    allowNull: false
  },
  paymentProof: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  rejectionReason: {
    type: DataTypes.TEXT,
    allowNull: true
  }
}, {
  tableName: 'payment_requests',
  timestamps: true,
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
});

// Instance methods
PaymentRequest.prototype.toJSON = function() {
  return {
    id: this.id,
    userId: this.userId,
    amount: parseFloat(this.amount),
    paymentMethod: this.paymentMethod,
    status: this.status,
    paymentProof: this.paymentProof,
    rejectionReason: this.rejectionReason,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

module.exports = PaymentRequest;
