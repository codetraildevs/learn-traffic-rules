/**
 * Script to seed course contents for existing courses
 * This script will add course contents to courses that don't have any contents yet
 * 
 * Usage:
 *   node seed-course-contents.js
 *   node seed-course-contents.js --course-id <course-id>  (seed specific course)
 *   node seed-course-contents.js --all                    (seed all courses, even if they have contents)
 */

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const { sequelize } = require('./src/config/database');
const Course = require('./src/models/Course');
const CourseContent = require('./src/models/CourseContent');
const { v4: uuidv4 } = require('uuid');

// Course content templates based on course category/title
const getContentTemplate = (course) => {
  const title = course.title.toLowerCase();
  const category = course.category?.toLowerCase() || '';

  // Default content template
  const defaultContents = [
    {
      contentType: 'text',
      content: `Welcome to ${course.title}! This course will guide you through the essential concepts and practices.`,
      title: 'Introduction',
      displayOrder: 0
    },
    {
      contentType: 'text',
      content: `In this section, we will explore the fundamentals of ${course.category || 'the topic'}. Understanding these basics is crucial for success.`,
      title: 'Fundamentals',
      displayOrder: 1
    },
    {
      contentType: 'text',
      content: `Now that you understand the basics, let's dive deeper into advanced concepts and practical applications.`,
      title: 'Advanced Concepts',
      displayOrder: 2
    }
  ];

  // Specific templates based on course title/category
  if (title.includes('parking')) {
    return [
      {
        contentType: 'text',
        content: 'Parking rules vary by location and are designed to ensure traffic flow and safety. It is important to understand where you can and cannot park, and for how long.',
        title: 'Parking Basics',
        displayOrder: 0
      },
      {
        contentType: 'image',
        content: 'parking-zones.png',
        title: 'Parking Zones',
        displayOrder: 1
      },
      {
        contentType: 'text',
        content: 'Common parking violations include parking in no-parking zones, blocking fire hydrants, parking in handicapped spaces without permits, and exceeding time limits.',
        title: 'Parking Violations',
        displayOrder: 2
      }
    ];
  }

  if (title.includes('traffic signs') || title.includes('signals')) {
    return [
      {
        contentType: 'text',
        content: 'Traffic signs are visual communication devices that provide important information to road users. They are categorized into regulatory signs, warning signs, and informational signs.',
        title: 'Types of Traffic Signs',
        displayOrder: 0
      },
      {
        contentType: 'image',
        content: 'regulatory-signs.png',
        title: 'Regulatory Signs',
        displayOrder: 1
      },
      {
        contentType: 'image',
        content: 'warning-signs.png',
        title: 'Warning Signs',
        displayOrder: 2
      },
      {
        contentType: 'text',
        content: 'Traffic signals use colored lights to control the flow of traffic. Red means stop, yellow means caution, and green means go.',
        title: 'Traffic Signals',
        displayOrder: 3
      }
    ];
  }

  if (title.includes('highway') || title.includes('expressway')) {
    return [
      {
        contentType: 'text',
        content: 'Highway driving requires special skills and knowledge. Higher speeds, multiple lanes, and complex traffic patterns make it essential to understand highway-specific rules.',
        title: 'Introduction to Highway Driving',
        displayOrder: 0
      },
      {
        contentType: 'text',
        content: 'Merging onto a highway requires proper timing and communication. Always use your turn signals and check blind spots before merging.',
        title: 'Merging Techniques',
        displayOrder: 1
      },
      {
        contentType: 'text',
        content: 'Lane discipline is crucial on highways. Stay in the right lane except when passing. The left lane is for passing only.',
        title: 'Lane Discipline',
        displayOrder: 2
      }
    ];
  }

  if (title.includes('defensive') || title.includes('driving techniques')) {
    return [
      {
        contentType: 'text',
        content: 'Defensive driving is a set of skills that allows you to defend yourself against possible collisions caused by bad drivers, drunk drivers, and poor weather.',
        title: 'What is Defensive Driving?',
        displayOrder: 0
      },
      {
        contentType: 'text',
        content: 'Always be aware of your surroundings. Scan the road ahead, check your mirrors frequently, and be prepared to react to unexpected situations.',
        title: 'Situational Awareness',
        displayOrder: 1
      },
      {
        contentType: 'text',
        content: 'Maintain a safe following distance. The general rule is to stay at least 3 seconds behind the vehicle in front of you.',
        title: 'Safe Following Distance',
        displayOrder: 2
      }
    ];
  }

  // Return default template
  return defaultContents;
};

async function seedCourseContents(courseId = null, seedAll = false) {
  try {
    console.log('🌱 Starting course content seeding...');
    
    // Connect to database
    await sequelize.authenticate();
    console.log('✅ Database connection established');

    // Get courses to seed
    let courses;
    if (courseId) {
      courses = await Course.findAll({ where: { id: courseId } });
      if (courses.length === 0) {
        console.log(`❌ Course with ID ${courseId} not found`);
        return;
      }
      console.log(`📚 Seeding contents for course: ${courses[0].title}`);
    } else {
      courses = await Course.findAll();
      console.log(`📚 Found ${courses.length} courses`);
    }

    let seededCount = 0;
    let skippedCount = 0;

    for (const course of courses) {
      // Check if course already has contents
      const existingContentCount = await CourseContent.count({
        where: { courseId: course.id }
      });

      if (existingContentCount > 0 && !seedAll) {
        console.log(`⚠️  Course "${course.title}" already has ${existingContentCount} content items, skipping`);
        skippedCount++;
        continue;
      }

      // Get content template for this course
      const contents = getContentTemplate(course);

      // Create contents
      for (const contentData of contents) {
        await CourseContent.findOrCreate({
          where: {
            courseId: course.id,
            contentType: contentData.contentType,
            content: contentData.content,
            displayOrder: contentData.displayOrder
          },
          defaults: {
            id: uuidv4(),
            courseId: course.id,
            contentType: contentData.contentType,
            content: contentData.content,
            title: contentData.title || null,
            displayOrder: contentData.displayOrder
          }
        });
      }

      console.log(`✅ Seeded ${contents.length} content items for course: "${course.title}"`);
      seededCount++;
    }

    console.log('\n📊 Seeding Summary:');
    console.log(`   ✅ Seeded: ${seededCount} courses`);
    console.log(`   ⚠️  Skipped: ${skippedCount} courses`);
    console.log('✅ Course content seeding completed successfully!');
  } catch (error) {
    console.error('❌ Course content seeding failed:', error);
    throw error;
  } finally {
    await sequelize.close();
  }
}

// Parse command line arguments
const args = process.argv.slice(2);
let courseId = null;
let seedAll = false;

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--course-id' && args[i + 1]) {
    courseId = args[i + 1];
    i++;
  } else if (args[i] === '--all') {
    seedAll = true;
  }
}

// Run the seeder
seedCourseContents(courseId, seedAll)
  .then(() => {
    console.log('✅ Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Script failed:', error);
    process.exit(1);
  });

