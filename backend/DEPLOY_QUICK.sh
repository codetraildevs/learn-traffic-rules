#!/bin/bash

# Quick Deployment Script for Learn Traffic Rules Backend
# Usage: ./DEPLOY_QUICK.sh

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/var/www/learn-traffic-rules"
BACKEND_DIR="$PROJECT_DIR/backend"
PM2_NAME="learn-traffic-rules-backend"
DB_USER="${DB_USER:-your_db_user}"
DB_NAME="${DB_NAME:-your_database_name}"
BACKUP_DIR="/var/backups/learn-traffic-rules"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Learn Traffic Rules - Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Navigate to project directory
echo -e "${YELLOW}📍 Step 1: Navigating to project directory...${NC}"
cd "$PROJECT_DIR" || { echo -e "${RED}❌ Project directory not found: $PROJECT_DIR${NC}"; exit 1; }
echo -e "${GREEN}✅ In project directory${NC}"
echo ""

# Step 2: Backup database (optional but recommended)
read -p "Do you want to backup database? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}📦 Step 2: Creating database backup...${NC}"
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql"
    mysqldump -u "$DB_USER" -p "$DB_NAME" > "$BACKUP_FILE" 2>/dev/null || {
        echo -e "${RED}❌ Database backup failed. Please check DB_USER and DB_NAME variables.${NC}"
        echo -e "${YELLOW}⚠️  Continuing without backup...${NC}"
    }
    if [ -f "$BACKUP_FILE" ]; then
        echo -e "${GREEN}✅ Backup created: $BACKUP_FILE${NC}"
    fi
else
    echo -e "${YELLOW}⏭️  Skipping database backup${NC}"
fi
echo ""

# Step 3: Check git status
echo -e "${YELLOW}🔍 Step 3: Checking git status...${NC}"
git status --short
echo ""

# Step 4: Pull latest changes
echo -e "${YELLOW}📥 Step 4: Pulling latest changes from main...${NC}"
git checkout main || { echo -e "${RED}❌ Failed to checkout main branch${NC}"; exit 1; }
git pull origin main || { echo -e "${RED}❌ Failed to pull from origin main${NC}"; exit 1; }
echo -e "${GREEN}✅ Code updated${NC}"
echo ""

# Step 5: Install dependencies
echo -e "${YELLOW}📦 Step 5: Installing dependencies...${NC}"
cd "$BACKEND_DIR" || { echo -e "${RED}❌ Backend directory not found${NC}"; exit 1; }
npm install || { echo -e "${RED}❌ Failed to install dependencies${NC}"; exit 1; }
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Step 6: Seed courses (optional)
read -p "Do you want to seed courses? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🌱 Step 6: Seeding courses...${NC}"
    npm run seed:courses || {
        echo -e "${YELLOW}⚠️  Course seeding had issues, but continuing...${NC}"
    }
    echo -e "${GREEN}✅ Courses seeded${NC}"
else
    echo -e "${YELLOW}⏭️  Skipping course seeding${NC}"
fi
echo ""

# Step 7: Restart PM2
echo -e "${YELLOW}🔄 Step 7: Restarting PM2 process...${NC}"
pm2 restart "$PM2_NAME" || {
    echo -e "${YELLOW}⚠️  PM2 process '$PM2_NAME' not found. Trying to start...${NC}"
    cd "$BACKEND_DIR"
    pm2 start server.js --name "$PM2_NAME" || {
        echo -e "${RED}❌ Failed to start PM2 process${NC}"
        exit 1
    }
}
echo -e "${GREEN}✅ Server restarted${NC}"
echo ""

# Step 8: Show status and logs
echo -e "${YELLOW}📋 Step 8: Checking PM2 status...${NC}"
pm2 status
echo ""

echo -e "${YELLOW}📋 Recent logs (last 30 lines):${NC}"
pm2 logs "$PM2_NAME" --lines 30 --nostream || echo -e "${YELLOW}⚠️  Could not retrieve logs${NC}"
echo ""

# Step 9: Verification
echo -e "${YELLOW}🔍 Step 9: Verifying deployment...${NC}"
sleep 3  # Wait a bit for server to start

# Check if PM2 process is running
if pm2 list | grep -q "$PM2_NAME.*online"; then
    echo -e "${GREEN}✅ PM2 process is running${NC}"
else
    echo -e "${RED}❌ PM2 process is not running${NC}"
    echo -e "${YELLOW}Check logs: pm2 logs $PM2_NAME${NC}"
fi

# Check for table creation messages in logs
if pm2 logs "$PM2_NAME" --lines 100 --nostream 2>/dev/null | grep -q "Table.*created successfully\|All required tables exist"; then
    echo -e "${GREEN}✅ Database tables verified${NC}"
else
    echo -e "${YELLOW}⚠️  Could not verify table creation. Check logs manually.${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Deployment completed!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Check logs: ${BLUE}pm2 logs $PM2_NAME${NC}"
echo -e "2. Test API: ${BLUE}curl http://localhost:5001/health${NC}"
echo -e "3. Verify courses: ${BLUE}mysql -u $DB_USER -p $DB_NAME -e 'SELECT COUNT(*) FROM courses;'${NC}"
echo ""

