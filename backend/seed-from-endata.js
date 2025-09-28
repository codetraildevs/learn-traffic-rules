const { sequelize } = require('./src/config/database');
const { Exam, Question } = require('./src/models');

async function seedFromEndata() {
  try {
    console.log('🌱 Starting seed process from endata.json...');
    
    // Read the endata.json file
    const fs = require('fs');
    const path = require('path');
    const endataPath = path.join(__dirname, '..', 'endata.json');
    
    if (!fs.existsSync(endataPath)) {
      throw new Error('endata.json file not found');
    }
    
    const endata = JSON.parse(fs.readFileSync(endataPath, 'utf8'));
    console.log(`📊 Found ${endata.exams.length} exams in endata.json`);
    
    // Clear existing data
    console.log('🗑️  Clearing existing data...');
    await Question.destroy({ where: {} });
    await Exam.destroy({ where: {} });
    console.log('✅ Existing data cleared');
    
    // Process each exam
    for (let i = 0; i < endata.exams.length; i++) {
      const examData = endata.exams[i];
      console.log(`\n📝 Processing Exam ${i + 1}/${endata.exams.length}: ${examData.title}`);
      
      // Generate proper title if it's too short
      let examTitle = examData.title;
      if (examTitle.length < 5) {
        examTitle = `Traffic Rules ${examTitle} ${i + 1}`;
      }
      
      // Create exam
      const exam = await Exam.create({
        id: examData.quizId,
        title: examTitle,
        description: `Traffic Rules Exam - ${examTitle}`,
        category: 'Traffic Rules',
        difficulty: 'Medium',
        duration: 30, // 30 minutes default
        passingScore: 60,
        isActive: true,
        examImgUrl: examData.examImgUrl,
        createdAt: new Date(),
        updatedAt: new Date()
      });
      
      console.log(`   ✅ Created exam: ${exam.title} (ID: ${exam.id})`);
      
      // Process questions for this exam
      const questions = examData.questions;
      console.log(`   📋 Processing ${questions.length} questions...`);
      
      for (let j = 0; j < questions.length; j++) {
        const questionData = questions[j];
        
        // Create question
        const question = await Question.create({
          id: `${examData.quizId}_q${j + 1}`, // Generate unique ID
          examId: exam.id,
          question: questionData.question,
          option1: questionData.option1,
          option2: questionData.option2,
          option3: questionData.option3,
          option4: questionData.option4,
          correctAnswer: questionData.correctAnswer,
          points: 1, // Default points
          questionOrder: j + 1, // Question order (1, 2, 3, etc.)
          questionImgUrl: questionData.questionImgUrl || null,
          createdAt: new Date(),
          updatedAt: new Date()
        });
        
        if ((j + 1) % 20 === 0 || j === questions.length - 1) {
          console.log(`     ✅ Processed ${j + 1}/${questions.length} questions`);
        }
      }
      
      console.log(`   🎉 Completed exam: ${exam.title} with ${questions.length} questions`);
    }
    
    console.log('\n🎊 Seed process completed successfully!');
    console.log(`📊 Summary:`);
    console.log(`   - Exams created: ${endata.exams.length}`);
    
    // Count total questions
    const totalQuestions = await Question.count();
    console.log(`   - Total questions: ${totalQuestions}`);
    
    // Show exam breakdown
    for (const examData of endata.exams) {
      const exam = await Exam.findByPk(examData.quizId);
      const questionCount = await Question.count({ where: { examId: exam.id } });
      console.log(`   - ${exam.title}: ${questionCount} questions`);
    }
    
  } catch (error) {
    console.error('❌ Error during seed process:', error);
    throw error;
  } finally {
    await sequelize.close();
  }
}

// Run the seed function
if (require.main === module) {
  seedFromEndata()
    .then(() => {
      console.log('✅ Seed completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Seed failed:', error);
      process.exit(1);
    });
}

module.exports = { seedFromEndata };
