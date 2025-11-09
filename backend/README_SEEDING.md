# Database Seeding Guide

## Overview

This guide explains how to use the database seeding system. The seeding system is **NOT automatic** - it only runs when you explicitly call the seed script. This prevents data loss when the server starts.

## Seeding Behavior

- **Default behavior**: Seeding will **skip existing data** to prevent data loss
- **Safe by default**: If data already exists, it won't be overwritten
- **Manual execution only**: Seeding only runs when you explicitly call the seed script

## Available Commands

### Seed All Data (Skip Existing)
```bash
npm run seed
# or
node seed.js
```
This will seed all data (users, exams, questions, courses, etc.) but will skip any data that already exists.

### Seed All Data (Force - May Create Duplicates)
```bash
npm run seed:force
# or
node seed.js --force
```
This will attempt to seed all data regardless of existing data. Use with caution as it may create duplicates.

### Seed Courses Only
```bash
npm run seed:courses
# or
node seed.js --courses-only
```
This will seed only courses and their content. Useful when you only need to add course data.

## Course Seeding

The course seeder includes **12 comprehensive courses** with the following features:

1. **Introduction to Traffic Rules** (Free, Easy)
2. **Traffic Signs and Signals Mastery** (Free, Medium)
3. **Vehicle Regulations and Safety** (Free, Medium)
4. **Parking Rules and Regulations** (Free, Easy)
5. **Highway and Expressway Driving** (Paid, Hard)
6. **Defensive Driving Techniques** (Paid, Hard)
7. **Traffic Violations and Penalties** (Paid, Medium)
8. **Road Safety and Emergency Response** (Free, Medium)
9. **Eco-Friendly and Environmental Driving** (Free, Easy)
10. **Night Driving and Adverse Weather** (Paid, Hard)
11. **Motorcycle and Bicycle Safety** (Free, Medium)
12. **Advanced Intersection Navigation** (Paid, Hard)

Each course includes:
- Multiple content items (text, images, videos, links)
- Proper categorization and difficulty levels
- Free and paid course types
- Rich descriptions and titles

## Content Types

Courses support the following content types:
- **text**: Textual content (required - at least one per course)
- **image**: Image content (e.g., `/uploads/course-images/image.png`)
- **audio**: Audio content (e.g., `/uploads/course-audio/audio.mp3`)
- **video**: Video content (e.g., `/uploads/course-videos/video.mp4`)
- **link**: External links (e.g., `https://example.com`)

## Preventing Data Loss

The seeding system uses `findOrCreate` which means:
- If a course with the same title exists, it will **not** be overwritten
- Existing content will **not** be modified
- Only new courses/content will be created
- Your existing data is **safe**

## Manual Seeding

If you need to seed data manually, you can use the DatabaseSeeder class directly:

```javascript
const DatabaseSeeder = require('./src/config/seeders');

// Seed all data (skip existing)
await DatabaseSeeder.run(true);

// Seed all data (force)
await DatabaseSeeder.run(false);

// Seed only courses
await DatabaseSeeder.seedCourses();
```

## Troubleshooting

### Courses Not Appearing
- Check if courses already exist in the database
- Verify that the course table was created successfully
- Check server logs for any errors

### Seeding Errors
- Ensure database connection is working
- Verify all models are properly imported
- Check that associations are set up correctly

### Data Not Persisting
- Verify database connection is stable
- Check for transaction rollbacks
- Ensure proper error handling

## Notes

- Seeding is **never automatic** on server startup
- Existing data is **never deleted** by the seeding process
- Use `--force` flag with caution
- Course images and media should be placed in the appropriate `/uploads/` directories

