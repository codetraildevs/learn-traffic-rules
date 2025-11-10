# Course Content Seeding Guide

This guide explains how to seed course contents for existing courses.

## Overview

Course contents are automatically seeded when courses are created via the main seeder (`seed.js`). However, if you have existing courses without contents, you can use the dedicated course content seeding script.

## Seeding Scripts

### 1. Main Seeder (Includes Course Contents)

The main seeder automatically creates course contents when creating courses:

```bash
# Seed everything (courses with contents)
npm run seed

# Force seed everything (overwrites existing data)
npm run seed:force

# Seed only courses (with contents)
npm run seed:courses
```

### 2. Course Content Seeder (For Existing Courses)

Use this script to add contents to courses that already exist but don't have contents:

```bash
# Seed contents for all courses that don't have contents
npm run seed:course-contents

# Seed contents for all courses (even if they already have contents)
npm run seed:course-contents:all

# Seed contents for a specific course
node seed-course-contents.js --course-id <course-id>
```

## How It Works

1. **Main Seeder (`seed.js`)**: 
   - Creates courses with their contents if courses don't exist
   - If a course exists but has no contents, it will add contents
   - If a course exists with contents, it skips that course

2. **Course Content Seeder (`seed-course-contents.js`)**:
   - Finds all courses (or a specific course)
   - Checks if they have contents
   - Adds default contents based on course title/category if missing
   - Uses intelligent templates based on course type

## Content Templates

The seeding script uses intelligent templates based on course titles and categories:

- **Parking courses**: Parking basics, zones, violations
- **Traffic Signs courses**: Types of signs, regulatory signs, warning signs, signals
- **Highway courses**: Highway driving, merging, lane discipline
- **Defensive Driving courses**: Defensive driving concepts, situational awareness, safe following
- **Default**: Introduction, fundamentals, advanced concepts

## Examples

### Seed contents for all courses without contents:
```bash
npm run seed:course-contents
```

### Seed contents for a specific course:
```bash
node seed-course-contents.js --course-id "123e4567-e89b-12d3-a456-426614174000"
```

### Force seed contents for all courses (overwrites existing):
```bash
npm run seed:course-contents:all
```

## Global Payment Access

**Important**: The backend now implements **global payment access** for courses:

- When a user pays once (via AccessCode), they get access to **ALL paid courses**
- The `enrollInCourse` endpoint checks for an active (non-expired) AccessCode
- If the user has an active AccessCode, they can enroll in any paid course
- Free courses are always accessible to all users

### Backend Logic:
```javascript
// In courseController.js - enrollInCourse method
if (course.courseType === 'paid') {
  // Check for active access code (provides global access to all paid courses)
  const activeAccessCode = await AccessCode.findOne({
    where: {
      userId: userId,
      expiresAt: { [Op.gt]: new Date() } // Not expired
    }
  });
  
  if (!activeAccessCode) {
    return res.status(403).json({
      message: 'Access denied. Please purchase access to unlock all paid courses.'
    });
  }
}
```

### Frontend Logic:
```dart
// In course_detail_screen.dart
final hasAccess = authState.accessPeriod?.hasAccess ?? false;
final canAccess = course.isFree || hasAccess; // Global access check
```

## Notes

- Course contents are created with `findOrCreate` to prevent duplicates
- Contents are ordered by `displayOrder` field
- The seeder respects existing data and won't overwrite unless forced
- All course contents include proper titles and display orders

