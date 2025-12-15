#!/bin/bash

# Deployment script for VPS server (Namecheap)
# Run this script after pulling the latest changes from git

echo "🚀 Starting deployment process..."

# Navigate to backend directory
cd backend || exit 1

# Install/update dependencies
echo "📦 Installing dependencies..."
npm install

# Update exam images in database
echo "🖼️  Updating exam images in database..."
node update-exam-images.js

# Check if update was successful
if [ $? -eq 0 ]; then
    echo "✅ Exam images updated successfully"
else
    echo "❌ Failed to update exam images"
    exit 1
fi

# Restart the application (adjust based on your process manager)
# For PM2:
# pm2 restart learn-traffic-rules || pm2 start server.js --name learn-traffic-rules

# For systemd:
# sudo systemctl restart learn-traffic-rules

# For direct node:
# pkill -f "node.*server.js" && nohup node server.js > server.log 2>&1 &

echo "✅ Deployment completed successfully!"
