#!/usr/bin/env node

/**
 * Deployment script for VPS server (Namecheap)
 * Run this script after pulling the latest changes from git
 * 
 * Usage: node deploy-vps.js
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

console.log('🚀 Starting deployment process...\n');

try {
  // Step 1: Install/update dependencies
  console.log('📦 Step 1: Installing dependencies...');
  try {
    execSync('npm install', { stdio: 'inherit', cwd: __dirname });
    console.log('✅ Dependencies installed successfully\n');
  } catch (error) {
    console.error('❌ Failed to install dependencies:', error.message);
    process.exit(1);
  }

  // Step 2: Update exam images in database
  console.log('🖼️  Step 2: Updating exam images in database...');
  try {
    const updateScript = path.join(__dirname, 'update-exam-images.js');
    if (fs.existsSync(updateScript)) {
      execSync(`node ${updateScript}`, { stdio: 'inherit', cwd: __dirname });
      console.log('✅ Exam images updated successfully\n');
    } else {
      console.log('⚠️  Update script not found, skipping...\n');
    }
  } catch (error) {
    console.error('❌ Failed to update exam images:', error.message);
    console.log('⚠️  Continuing deployment despite image update failure...\n');
  }

  // Step 3: Optional - Restart application
  console.log('🔄 Step 3: Deployment completed!');
  console.log('\n📝 Next steps:');
  console.log('   - If using PM2: pm2 restart learn-traffic-rules');
  console.log('   - If using systemd: sudo systemctl restart learn-traffic-rules');
  console.log('   - If using direct node: Restart your node process manually');
  console.log('\n✅ Deployment script completed successfully!');

} catch (error) {
  console.error('❌ Deployment failed:', error.message);
  process.exit(1);
}
