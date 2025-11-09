# Database Deployment Safety Guide

## Overview

This guide explains how the database initialization works to ensure **no data loss** when deploying to production servers.

## Key Safety Features

### 1. **No Table Recreation**
- ✅ Uses `CREATE TABLE IF NOT EXISTS` - never drops existing tables
- ✅ Only creates **missing tables** - existing tables are never touched
- ✅ Existing data is **always preserved**

### 2. **Smart Table Detection**
- The system checks which tables exist before creating any
- Only missing tables are created (e.g., if `courses` table doesn't exist, only that table is created)
- Existing tables like `users`, `exams`, `questions` are never recreated

### 3. **Safe Column Addition**
- Missing columns are added to existing tables using `ALTER TABLE ADD COLUMN`
- This is safe and doesn't affect existing data
- Uses `IF NOT EXISTS` logic to skip columns that already exist

### 4. **No Data Deletion**
- ❌ **Never** uses `DROP TABLE`
- ❌ **Never** uses `TRUNCATE TABLE`
- ❌ **Never** uses `DELETE FROM` for initialization
- ✅ Only uses `CREATE TABLE IF NOT EXISTS` and `ALTER TABLE ADD COLUMN`

## How It Works

### On Server Startup

1. **Check Existing Tables**
   ```sql
   SHOW TABLES
   ```

2. **Identify Missing Tables**
   - Compares existing tables with required tables
   - Only creates tables that are missing

3. **Create Missing Tables Only**
   - Uses `createMissingTablesOnly()` function
   - Creates only the tables that don't exist
   - Existing tables are completely untouched

4. **Add Missing Columns**
   - Checks each existing table for missing columns
   - Adds only missing columns (safe operation)
   - Skips columns that already exist

### Example Scenario

**Before Deployment:**
- Database has: `users`, `exams`, `questions`, `exam_results`
- New code requires: `courses`, `course_contents`, `course_progress`

**After Deployment:**
- ✅ Existing tables remain: `users`, `exams`, `questions`, `exam_results` (unchanged)
- ✅ New tables created: `courses`, `course_contents`, `course_progress`
- ✅ All existing data preserved

## Course Tables

When you deploy the course management feature:

1. **First Deployment:**
   - Creates `courses` table (if missing)
   - Creates `course_contents` table (if missing)
   - Creates `course_progress` table (if missing)
   - Creates `course_content_progress` table (if missing)
   - Adds foreign key constraints

2. **Subsequent Deployments:**
   - Detects that course tables already exist
   - Skips creation (no data loss)
   - Only checks for missing columns

## Safety Guarantees

### ✅ What Will NEVER Happen:
- Existing tables will NOT be dropped
- Existing data will NOT be deleted
- Existing columns will NOT be removed
- Existing indexes will NOT be dropped

### ✅ What WILL Happen:
- Missing tables will be created
- Missing columns will be added
- Foreign key constraints will be added (if tables are new)
- Table cache will be refreshed

## Deployment Process

### 1. Push to Main Branch
```bash
git add .
git commit -m "Add course management feature"
git push origin main
```

### 2. Pull on VPS Server
```bash
cd /var/www/learn-traffic-rules
git pull origin main
npm install  # if new dependencies
```

### 3. Restart Server
```bash
pm2 restart learn-traffic-rules-backend
```

### 4. Verify Logs
Check PM2 logs to see:
- ✅ "All required tables exist" or
- ✅ "Creating only missing tables"
- ✅ "Courses table created successfully" (if it was missing)

### 5. Verify Data
- Check that existing data is still present
- Verify new course tables exist
- Test course functionality

## Troubleshooting

### If Tables Are Not Created

1. **Check Server Logs**
   ```bash
   pm2 logs learn-traffic-rules-backend
   ```

2. **Check Database Connection**
   - Verify database credentials in `.env`
   - Test connection manually

3. **Check Table Creation Logs**
   - Look for "Creating table: courses" messages
   - Check for any error messages

### If You See Errors

**Error: "Table already exists"**
- ✅ This is OK - means table was already created
- System will skip and continue

**Error: "Cannot add foreign key constraint"**
- ⚠️ This is non-critical
- Tables will still work, just without foreign key constraints
- Can be fixed manually if needed

**Error: "Column already exists"**
- ✅ This is OK - means column was already added
- System will skip and continue

## Manual Table Creation (If Needed)

If for some reason tables are not created automatically, you can create them manually:

```sql
-- Create courses table
CREATE TABLE IF NOT EXISTS courses (
  id CHAR(36) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  category VARCHAR(100) NULL,
  difficulty ENUM('EASY', 'MEDIUM', 'HARD') DEFAULT 'MEDIUM',
  courseType ENUM('free', 'paid') DEFAULT 'free',
  courseImageUrl VARCHAR(500) NULL,
  isActive BOOLEAN DEFAULT true,
  createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create course_contents table
CREATE TABLE IF NOT EXISTS course_contents (
  id CHAR(36) PRIMARY KEY,
  courseId CHAR(36) NOT NULL,
  contentType ENUM('text', 'image', 'audio', 'video', 'link') DEFAULT 'text',
  content TEXT NOT NULL,
  title VARCHAR(255) NULL,
  displayOrder INTEGER DEFAULT 0,
  createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create course_progress table
CREATE TABLE IF NOT EXISTS course_progress (
  id CHAR(36) PRIMARY KEY,
  userId CHAR(36) NOT NULL,
  courseId CHAR(36) NOT NULL,
  completedContentCount INTEGER DEFAULT 0,
  totalContentCount INTEGER DEFAULT 0,
  progressPercentage DECIMAL(5,2) DEFAULT 0.00,
  isCompleted BOOLEAN DEFAULT false,
  lastAccessedAt TIMESTAMP NULL,
  completedAt TIMESTAMP NULL,
  createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_user_course (userId, courseId)
);

-- Create course_content_progress table
CREATE TABLE IF NOT EXISTS course_content_progress (
  id CHAR(36) PRIMARY KEY,
  userId CHAR(36) NOT NULL,
  courseId CHAR(36) NOT NULL,
  courseContentId CHAR(36) NOT NULL,
  isCompleted BOOLEAN DEFAULT false,
  completedAt TIMESTAMP NULL,
  timeSpent INTEGER DEFAULT 0,
  createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_user_content (userId, courseContentId)
);
```

## Summary

✅ **Safe for Production**: The system is designed to never lose data  
✅ **Automatic**: Tables are created automatically on server startup  
✅ **Idempotent**: Can be run multiple times safely  
✅ **Non-Destructive**: Never modifies or deletes existing data  

Your existing data is **100% safe** when deploying new features!

