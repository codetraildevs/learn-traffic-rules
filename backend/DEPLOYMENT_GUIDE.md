# Production Deployment Guide

## Quick Reference

### Seed Courses on Production (One-Time)

```bash
# SSH into your VPS server
ssh root@your-server-ip

# Navigate to project directory
cd /var/www/learn-traffic-rules/backend

# Seed courses only (safe - won't affect existing data)
npm run seed:courses

# OR using node directly
node seed.js --courses-only
```

---

## Full Deployment Steps

### Step 1: Push Changes to Main Branch (Local Machine)

```bash
# Navigate to project root
cd /path/to/learn-traffic-rules

# Check current branch
git branch

# If not on main, switch to main
git checkout main

# Add all changes
git add .

# Commit changes
git commit -m "Add course management feature with safe database initialization"

# Push to remote main branch
git push origin main
```

---

### Step 2: Deploy on VPS Server

#### 2.1. SSH into Server

```bash
ssh root@your-server-ip
# or
ssh username@your-server-ip
```

#### 2.2. Navigate to Project Directory

```bash
cd /var/www/learn-traffic-rules
# or your project path
```

#### 2.3. Backup Database (Recommended - Safety First!)

```bash
# Create backup directory if it doesn't exist
mkdir -p /var/backups/learn-traffic-rules

# Backup database (adjust credentials as needed)
mysqldump -u your_db_user -p your_database_name > /var/backups/learn-traffic-rules/backup_$(date +%Y%m%d_%H%M%S).sql

# Enter database password when prompted
```

#### 2.4. Pull Latest Changes from Main

```bash
# Check current branch
git branch

# Make sure you're on main branch
git checkout main

# Pull latest changes
git pull origin main
```

#### 2.5. Install Dependencies (If New Packages Added)

```bash
# Navigate to backend directory
cd backend

# Install/update dependencies
npm install

# If you see package-lock.json changes, you might need:
# rm -rf node_modules package-lock.json
# npm install
```

#### 2.6. Check Environment Variables

```bash
# Verify .env file exists and has correct values
cat .env | grep -E "DB_|JWT_|PORT"

# If .env is missing, copy from .env.example
# cp .env.example .env
# nano .env  # Edit with your values
```

#### 2.7. Seed Courses (One-Time Only)

```bash
# Seed courses only (safe - won't affect existing data)
npm run seed:courses

# Expected output:
# ✅ Course "Introduction to Traffic Rules" created with 4 content items
# ✅ Course "Traffic Signs and Signals Mastery" created with 5 content items
# ... (12 courses total)
# ✅ Courses seeded successfully
```

**Note:** This command is safe to run multiple times - it will skip courses that already exist.

#### 2.8. Restart PM2 Process

```bash
# Restart the backend application
pm2 restart learn-traffic-rules-backend

# OR if you're using a different PM2 process name:
pm2 restart all

# Check PM2 status
pm2 status

# View logs to verify startup
pm2 logs learn-traffic-rules-backend --lines 50
```

#### 2.9. Verify Deployment

```bash
# Check PM2 logs for table creation messages
pm2 logs learn-traffic-rules-backend --lines 100 | grep -E "Creating|Table|Course|Error"

# Expected successful messages:
# ✅ All required tables exist
# OR
# 🔄 Creating only missing tables (existing tables will not be touched)
# ✅ Table "courses" created successfully
# ✅ Table "course_contents" created successfully
# ✅ Table "course_progress" created successfully
# ✅ Table "course_content_progress" created successfully
```

#### 2.10. Test API Endpoints

```bash
# Test health endpoint
curl http://localhost:5001/health

# Test courses endpoint (requires authentication)
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:5001/api/courses

# Check API documentation
curl http://localhost:5001/api-docs
```

---

## Complete Deployment Script (All-in-One)

You can create a deployment script for easier deployment:

### Create Deployment Script

```bash
# Create deployment script
nano /var/www/learn-traffic-rules/deploy.sh
```

### Script Content:

```bash
#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting deployment...${NC}"

# Navigate to project directory
cd /var/www/learn-traffic-rules || exit

# Backup database
echo -e "${YELLOW}📦 Creating database backup...${NC}"
mkdir -p /var/backups/learn-traffic-rules
mysqldump -u your_db_user -p your_database_name > /var/backups/learn-traffic-rules/backup_$(date +%Y%m%d_%H%M%S).sql
echo -e "${GREEN}✅ Backup created${NC}"

# Pull latest changes
echo -e "${YELLOW}📥 Pulling latest changes from main...${NC}"
git checkout main
git pull origin main
echo -e "${GREEN}✅ Code updated${NC}"

# Install dependencies
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
cd backend
npm install
echo -e "${GREEN}✅ Dependencies installed${NC}"

# Seed courses (one-time, safe to run multiple times)
echo -e "${YELLOW}🌱 Seeding courses...${NC}"
npm run seed:courses
echo -e "${GREEN}✅ Courses seeded${NC}"

# Restart PM2
echo -e "${YELLOW}🔄 Restarting PM2 process...${NC}"
pm2 restart learn-traffic-rules-backend
echo -e "${GREEN}✅ Server restarted${NC}"

# Show logs
echo -e "${YELLOW}📋 Recent logs:${NC}"
pm2 logs learn-traffic-rules-backend --lines 20 --nostream

echo -e "${GREEN}✅ Deployment completed!${NC}"
```

### Make Script Executable

```bash
chmod +x /var/www/learn-traffic-rules/deploy.sh
```

### Run Deployment Script

```bash
/var/www/learn-traffic-rules/deploy.sh
```

---

## Troubleshooting

### Issue: Git Pull Fails

```bash
# Check if you have uncommitted changes
git status

# If you have uncommitted changes, stash them
git stash

# Pull again
git pull origin main

# If you need your stashed changes back
git stash pop
```

### Issue: npm install Fails

```bash
# Clear npm cache
npm cache clean --force

# Remove node_modules and package-lock.json
rm -rf node_modules package-lock.json

# Install again
npm install
```

### Issue: PM2 Restart Fails

```bash
# Check PM2 status
pm2 status

# Check PM2 logs for errors
pm2 logs learn-traffic-rules-backend --err

# Stop and start manually
pm2 stop learn-traffic-rules-backend
pm2 start learn-traffic-rules-backend

# If process doesn't exist, start it
pm2 start server.js --name learn-traffic-rules-backend
```

### Issue: Database Connection Fails

```bash
# Check .env file
cat backend/.env | grep DB_

# Test database connection
mysql -u your_db_user -p -e "SHOW DATABASES;"

# Verify database credentials in .env match your MySQL setup
```

### Issue: Tables Not Created

```bash
# Check PM2 logs for table creation messages
pm2 logs learn-traffic-rules-backend | grep -i "table\|course\|error"

# Manually check if tables exist
mysql -u your_db_user -p your_database_name -e "SHOW TABLES;"

# If tables don't exist, check database.js initialization logs
pm2 logs learn-traffic-rules-backend | grep -i "creating\|missing"
```

### Issue: Courses Not Seeded

```bash
# Check if courses table exists
mysql -u your_db_user -p your_database_name -e "SELECT COUNT(*) FROM courses;"

# Run seed command again (safe to run multiple times)
cd /var/www/learn-traffic-rules/backend
npm run seed:courses

# Check seed logs for errors
npm run seed:courses 2>&1 | tee seed.log
```

---

## Verification Checklist

After deployment, verify:

- [ ] Git pull completed successfully
- [ ] Dependencies installed without errors
- [ ] Courses seeded successfully (12 courses)
- [ ] PM2 process restarted successfully
- [ ] Server logs show no errors
- [ ] Database tables created (courses, course_contents, etc.)
- [ ] Existing data is still present
- [ ] API endpoints are accessible
- [ ] Health check endpoint returns 200 OK

---

## Rollback Plan (If Something Goes Wrong)

### Rollback Code

```bash
# Go back to previous commit
cd /var/www/learn-traffic-rules
git log --oneline -10  # Find previous commit hash
git reset --hard <previous-commit-hash>
git push origin main --force  # Only if necessary

# Restart PM2
pm2 restart learn-traffic-rules-backend
```

### Restore Database Backup

```bash
# List backups
ls -lh /var/backups/learn-traffic-rules/

# Restore from backup
mysql -u your_db_user -p your_database_name < /var/backups/learn-traffic-rules/backup_YYYYMMDD_HHMMSS.sql
```

---

## Quick Commands Reference

```bash
# Seed courses only
cd /var/www/learn-traffic-rules/backend && npm run seed:courses

# Pull and deploy
cd /var/www/learn-traffic-rules && git pull origin main && cd backend && npm install && pm2 restart learn-traffic-rules-backend

# View logs
pm2 logs learn-traffic-rules-backend --lines 50

# Check PM2 status
pm2 status

# Check database tables
mysql -u your_db_user -p your_database_name -e "SHOW TABLES;"

# Check courses count
mysql -u your_db_user -p your_database_name -e "SELECT COUNT(*) FROM courses;"
```

---

## Important Notes

1. **Always backup database before deployment** - Safety first!
2. **Seed courses is safe to run multiple times** - It skips existing courses
3. **Table creation is automatic** - No manual SQL needed
4. **Existing data is never deleted** - Tables are never dropped
5. **Check logs after deployment** - Verify everything worked
6. **Test API endpoints** - Ensure functionality works
7. **Monitor PM2 process** - Ensure server is running properly

---

## Support

If you encounter any issues:
1. Check PM2 logs: `pm2 logs learn-traffic-rules-backend`
2. Check database connection: Verify .env file
3. Check table creation: Look for "Creating table" messages in logs
4. Verify courses: Check if courses table has data
5. Check API: Test endpoints with curl or Postman

---

## Summary

**Deployment Process:**
1. Push to main (local) → 2. Pull on server → 3. Install dependencies → 4. Seed courses → 5. Restart PM2 → 6. Verify

**Seed Courses Command:**
```bash
cd /var/www/learn-traffic-rules/backend && npm run seed:courses
```

**Safety:**
- ✅ Database backup recommended
- ✅ Existing data is preserved
- ✅ Tables are never dropped
- ✅ Seed is idempotent (safe to run multiple times)

Happy deploying! 🚀

