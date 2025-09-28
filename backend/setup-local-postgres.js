#!/usr/bin/env node

// Setup script for local PostgreSQL database
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🐘 Setting up local PostgreSQL database...');

// Create .env.local file for local development
const envContent = `# Local Development Environment
NODE_ENV=development
PORT=3000

# Local PostgreSQL Database
DB_NAME=traffic_rules_local
DB_USER=postgres
DB_PASSWORD=password
DB_HOST=localhost
DB_PORT=5432

# JWT Configuration
JWT_SECRET=local-development-secret-key-for-testing-only
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# Frontend URL
FRONTEND_URL=http://localhost:3000

# Bcrypt Configuration
BCRYPT_ROUNDS=12

# Force database sync for initial setup
FORCE_SYNC=true
`;

fs.writeFileSync('.env.local', envContent);
console.log('✅ Created .env.local file for local development');

// Instructions for setting up PostgreSQL
console.log('\n📋 PostgreSQL Setup Instructions:');
console.log('1. Install PostgreSQL on your system:');
console.log('   - Windows: Download from https://www.postgresql.org/download/windows/');
console.log('   - macOS: brew install postgresql');
console.log('   - Ubuntu: sudo apt-get install postgresql postgresql-contrib');
console.log('');
console.log('2. Start PostgreSQL service:');
console.log('   - Windows: Start PostgreSQL service from Services');
console.log('   - macOS: brew services start postgresql');
console.log('   - Ubuntu: sudo systemctl start postgresql');
console.log('');
console.log('3. Create database and user:');
console.log('   psql -U postgres');
console.log('   CREATE DATABASE traffic_rules_local;');
console.log('   CREATE USER postgres WITH PASSWORD \'password\';');
console.log('   GRANT ALL PRIVILEGES ON DATABASE traffic_rules_local TO postgres;');
console.log('   \\q');
console.log('');
console.log('4. Test the connection:');
console.log('   node test-db-connection.js');
console.log('');
console.log('5. Start the server:');
console.log('   NODE_ENV=development node server.js');
