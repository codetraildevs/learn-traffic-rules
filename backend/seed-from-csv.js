const fs = require('fs');
const path = require('path');
const { sequelize } = require('./src/config/database');
const { Exam, Question } = require('./src/models');

// Function to parse CSV line
function parseCSVLine(line) {
  const result = [];
  let current = '';
  let inQuotes = false;
  
  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    
    if (char === '"') {
      inQuotes = !inQuotes;
    } else if (char === ',' && !inQuotes) {
      result.push(current.trim());
      current = '';
    } else {
      current += char;
    }
  }
  
  result.push(current.trim());
  return result;
}

// Function to read and parse CSV file
function readCSVFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n').filter(line => line.trim());
  const headers = parseCSVLine(lines[0]);
  const data = [];
  
  for (let i = 1; i < lines.length; i++) {
    const values = parseCSVLine(lines[i]);
    if (values.length >= headers.length) {
      const row = {};
      headers.forEach((header, index) => {
        row[header] = values[index] || '';
      });
      data.push(row);
    }
  }
  
  return data;
}

async function seedFromCSV() {
  try {
    console.log('🌱 Starting CSV seeding process...');
    
    // Connect to database
    await sequelize.authenticate();
    console.log('✅ Database connected successfully');
    
    // Clear existing data
    console.log('🗑️  Clearing existing data...');
    await Question.destroy({ where: {} });
    await Exam.destroy({ where: {} });
    console.log('✅ Existing data cleared');
    
    // Process each CSV file
    for (let examNumber = 1; examNumber <= 20; examNumber++) {
      const csvPath = path.join(__dirname, `exam_${examNumber}_questions.csv`);
      
      if (!fs.existsSync(csvPath)) {
        console.log(`⚠️  CSV file not found: exam_${examNumber}_questions.csv`);
        continue;
      }
      
      console.log(`\n📝 Processing Exam ${examNumber}...`);
      
      // Read CSV data
      const csvData = readCSVFile(csvPath);
      console.log(`   Found ${csvData.length} questions`);
      
      // Create exam
      const exam = await Exam.create({
        id: examNumber.toString(),
        title: examNumber === 1 ? 'Free Exam' : `Traffic Rules Exam ${examNumber + 1}`,
        description: `Traffic rules examination ${examNumber}`,
        category: 'Traffic Rules',
        difficulty: 'MEDIUM',
        duration: 30,
        questionCount: csvData.length,
        passingScore: 70,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
      });
      
      console.log(`   ✅ Created exam: ${exam.title}`);
      
      // Create questions
      for (let i = 0; i < csvData.length; i++) {
        const row = csvData[i];
        
        // Skip questions that are too short (less than 10 characters)
        if (!row.question || row.question.length < 10) {
          console.log(`   ⚠️  Skipping question ${i + 1}: Too short (${row.question?.length || 0} chars)`);
          continue;
        }
        
        const question = await Question.create({
          id: `${examNumber}_q${i + 1}`,
          examId: examNumber.toString(),
          question: row.question,
          option1: row.option1,
          option2: row.option2,
          option3: row.option3,
          option4: row.option4,
          correctAnswer: row.correctAnswer,
          points: parseInt(row.points) || 1,
          questionImgUrl: row.questionImgUrl || null,
          questionOrder: i + 1,
          createdAt: new Date(),
          updatedAt: new Date()
        });
        
        console.log(`   ✅ Created question ${i + 1}: ${question.question.substring(0, 50)}...`);
      }
      
      console.log(`   📊 Exam ${examNumber} completed: ${csvData.length} questions`);
    }
    
    console.log('\n🎉 CSV seeding completed successfully!');
    
    // Verify the data
    const totalExams = await Exam.count();
    const totalQuestions = await Question.count();
    console.log(`📊 Final counts:`);
    console.log(`   Exams: ${totalExams}`);
    console.log(`   Questions: ${totalQuestions}`);
    
  } catch (error) {
    console.error('❌ Error during CSV seeding:', error);
    throw error;
  } finally {
    await sequelize.close();
  }
}

// Run the seeding process
if (require.main === module) {
  seedFromCSV()
    .then(() => {
      console.log('✅ Seeding process completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Seeding process failed:', error);
      process.exit(1);
    });
}

module.exports = { seedFromCSV };
