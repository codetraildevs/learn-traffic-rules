# Production Deployment - Quick Steps

## 🎯 Seed Courses Command (One-Time on Production)

```bash
# SSH into your VPS
ssh root@your-server-ip

# Navigate to backend directory
cd /var/www/learn-traffic-rules/backend

# Seed courses (safe to run multiple times - skips existing)
npm run seed:courses
```

**Expected Output:**
```
✅ Course "Introduction to Traffic Rules" created with 4 content items
✅ Course "Traffic Signs and Signals Mastery" created with 5 content items
... (12 courses total)
✅ Courses seeded successfully
```

---

## 📋 Full Deployment Steps (After git pull on Server)

### Step 1: SSH into Server
```bash
ssh root@your-server-ip
```

### Step 2: Navigate to Project Directory
```bash
cd /var/www/learn-traffic-rules
```

### Step 3: Pull Latest Changes
```bash
# Make sure you're on main branch
git checkout main

# Pull latest changes
git pull origin main
```

### Step 4: Install Dependencies
```bash
# Navigate to backend directory
cd backend

# Install/update dependencies
npm install
```

### Step 5: Seed Courses (One-Time, Optional)
```bash
# Seed courses only (safe - won't affect existing data)
npm run seed:courses
```

### Step 6: Restart PM2 Process
```bash
# Restart the backend application
pm2 restart learn-traffic-rules-backend

# OR if using different name
pm2 restart all
```

### Step 7: Verify Deployment
```bash
# Check PM2 status
pm2 status

# View logs to verify startup
pm2 logs learn-traffic-rules-backend --lines 50

# Look for these messages in logs:
# ✅ All required tables exist
# OR
# ✅ Table "courses" created successfully
# ✅ Table "course_contents" created successfully
```

### Step 8: Test API
```bash
# Test health endpoint
curl http://localhost:5001/health

# Should return: {"status":"ok"}
```

---

## 🚀 One-Line Deployment (Quick Method)

```bash
cd /var/www/learn-traffic-rules && git pull origin main && cd backend && npm install && pm2 restart learn-traffic-rules-backend
```

---

## 🔍 Verification Commands

### Check if Courses are Seeded
```bash
# Connect to MySQL
mysql -u your_db_user -p your_database_name

# Check courses count
SELECT COUNT(*) FROM courses;

# Should show 12 courses
# Exit MySQL
exit;
```

### Check PM2 Status
```bash
pm2 status
pm2 logs learn-traffic-rules-backend --lines 30
```

### Check Database Tables
```bash
mysql -u your_db_user -p your_database_name -e "SHOW TABLES;"
```

---

## ⚠️ Important Notes

1. **Database Safety**: Tables are never dropped or recreated - only missing tables are created
2. **Data Preservation**: Existing data is always preserved
3. **Seed Safety**: `npm run seed:courses` is safe to run multiple times - it skips existing courses
4. **Automatic Table Creation**: Course tables will be created automatically on server restart if they don't exist
5. **No Manual SQL Needed**: Everything is handled automatically

---

## 🆘 Troubleshooting

### If git pull fails:
```bash
git status
git stash  # Save local changes
git pull origin main
```

### If npm install fails:
```bash
rm -rf node_modules package-lock.json
npm install
```

### If PM2 restart fails:
```bash
pm2 stop learn-traffic-rules-backend
pm2 start server.js --name learn-traffic-rules-backend
```

### If courses don't seed:
```bash
# Check database connection
cat .env | grep DB_

# Run seed again
npm run seed:courses
```

---

## 📝 Complete Deployment Checklist

- [ ] Pushed changes to main branch (local)
- [ ] SSH into VPS server
- [ ] Navigated to project directory
- [ ] Pulled latest changes (`git pull origin main`)
- [ ] Installed dependencies (`npm install`)
- [ ] Seeded courses (`npm run seed:courses`) - Optional
- [ ] Restarted PM2 (`pm2 restart learn-traffic-rules-backend`)
- [ ] Verified PM2 status
- [ ] Checked logs for table creation
- [ ] Tested API endpoints
- [ ] Verified courses in database

---

## 🎉 Success Indicators

After deployment, you should see:

✅ PM2 process is `online`  
✅ Logs show "All required tables exist" or "Table created successfully"  
✅ Health endpoint returns 200 OK  
✅ Courses table has 12 courses  
✅ No errors in PM2 logs  
✅ Server is accessible  

---

## 📞 Quick Reference

**Seed Courses:**
```bash
cd /var/www/learn-traffic-rules/backend && npm run seed:courses
```

**Full Deployment:**
```bash
cd /var/www/learn-traffic-rules && git pull origin main && cd backend && npm install && pm2 restart learn-traffic-rules-backend
```

**Check Logs:**
```bash
pm2 logs learn-traffic-rules-backend --lines 50
```

**Check Status:**
```bash
pm2 status
```

---

That's it! Your deployment is complete. 🚀

