const { sequelize } = require('./src/config/database');
const { Exam } = require('./src/models');
const fs = require('fs');
const path = require('path');

/**
 * Script to update exam images in the database
 * Assigns images from exam1.png to exam21.png (filename only, no path)
 * Each exam type (kinyarwanda, english, french) uses the same set of 21 images
 * The frontend will construct the full path: /uploads/images-exams/{filename}
 */
async function updateExamImages() {
  try {
    console.log('🔄 Starting exam image update process...');
    
    // Connect to database
    await sequelize.authenticate();
    console.log('✅ Database connected successfully');
    
    // Get all exams from database
    const exams = await Exam.findAll({
      order: [
        ['examType', 'ASC'],
        ['createdAt', 'ASC']
      ]
    });
    
    if (exams.length === 0) {
      console.log('⚠️  No exams found in database');
      return;
    }
    
    console.log(`📊 Found ${exams.length} exams in database`);
    
    // Group exams by examType
    const examsByType = {
      kinyarwanda: [],
      english: [],
      french: []
    };
    
    exams.forEach(exam => {
      const examType = exam.examType || 'kinyarwanda'; // Default to kinyarwanda if null
      if (examsByType[examType]) {
        examsByType[examType].push(exam);
      } else {
        // If examType is not one of the three, default to kinyarwanda
        examsByType.kinyarwanda.push(exam);
      }
    });
    
    console.log('\n📋 Exams by type:');
    console.log(`   Kinyarwanda: ${examsByType.kinyarwanda.length}`);
    console.log(`   English: ${examsByType.english.length}`);
    console.log(`   French: ${examsByType.french.length}`);
    
    // Verify images exist - read actual files from directory
    const imagesDir = path.join(__dirname, 'uploads', 'images-exams');
    const imageFiles = [];
    
    if (fs.existsSync(imagesDir)) {
      // Read all files from the directory
      const files = fs.readdirSync(imagesDir);
      
      // Filter and sort image files (exam1.png, exam2.png, etc.)
      const examImageFiles = files
        .filter(file => /^exam\d+\.png$/i.test(file))
        .sort((a, b) => {
          // Extract numbers for proper sorting (exam1, exam2, ..., exam10, exam11, ...)
          const numA = parseInt(a.match(/\d+/)[0]);
          const numB = parseInt(b.match(/\d+/)[0]);
          return numA - numB;
        });
      
      imageFiles.push(...examImageFiles);
      
      if (examImageFiles.length === 0) {
        console.log(`⚠️  Warning: No exam*.png files found in ${imagesDir}`);
      } else {
        console.log(`✅ Found ${examImageFiles.length} exam images in directory`);
      }
    } else {
      console.log(`⚠️  Warning: Images directory not found: ${imagesDir}`);
      console.log(`   Creating directory...`);
      fs.mkdirSync(imagesDir, { recursive: true });
      console.log(`   Directory created. Please add exam images and run the script again.`);
    }
    
    console.log(`\n🖼️  Total images available: ${imageFiles.length}`);
    
    if (imageFiles.length === 0) {
      console.log('❌ No images found. Please ensure images are in backend/uploads/images-exams/');
      console.log('   Expected format: exam1.png, exam2.png, ..., exam21.png');
      return;
    }
    
    // Update exam images for each type
    let totalUpdated = 0;
    
    for (const [examType, typeExams] of Object.entries(examsByType)) {
      if (typeExams.length === 0) continue;
      
      console.log(`\n🔄 Updating ${examType} exams...`);
      
      for (let i = 0; i < typeExams.length; i++) {
        const exam = typeExams[i];
        // Cycle through images (1-21), repeating if there are more than 21 exams
        const imageIndex = i % imageFiles.length;
        const imageFileName = imageFiles[imageIndex]; // Just the filename: exam1.png, exam2.png, etc.
        
        // Update exam image with just the filename (frontend will construct the full path)
        await exam.update({
          examImgUrl: imageFileName
        });
        
        console.log(`   ✅ Updated exam "${exam.title}" (ID: ${exam.id})`);
        console.log(`      Image: ${imageFileName}`);
        totalUpdated++;
      }
    }
    
    console.log(`\n✅ Successfully updated ${totalUpdated} exam images`);
    
    // Show summary
    console.log('\n📊 Summary by exam type:');
    for (const [examType, typeExams] of Object.entries(examsByType)) {
      if (typeExams.length > 0) {
        console.log(`\n   ${examType.toUpperCase()}:`);
        typeExams.forEach((exam, index) => {
          const imageIndex = index % imageFiles.length;
          const imageFileName = imageFiles[imageIndex];
          console.log(`      ${index + 1}. ${exam.title}`);
          console.log(`         Image: ${imageFileName}`);
        });
      }
    }
    
  } catch (error) {
    console.error('❌ Error updating exam images:', error);
    throw error;
  } finally {
    await sequelize.close();
    console.log('\n🔌 Database connection closed');
  }
}

// Run the update process
if (require.main === module) {
  updateExamImages()
    .then(() => {
      console.log('\n✅ Exam image update process completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Exam image update process failed:', error);
      process.exit(1);
    });
}

module.exports = { updateExamImages };
