const { sequelize } = require('./src/config/database');
const { Question, Exam } = require('./src/models');

async function verifyQuestionOrder() {
  try {
    console.log('🔍 Verifying question order in database...');
    
    // Get all exams
    const exams = await Exam.findAll({
      order: [['createdAt', 'ASC']],
      limit: 3 // Check first 3 exams
    });
    
    for (const exam of exams) {
      console.log(`\n📝 Exam: ${exam.title} (ID: ${exam.id})`);
      
      // Get questions ordered by questionOrder
      const questions = await Question.findAll({
        where: { examId: exam.id },
        order: [['questionOrder', 'ASC']],
        attributes: ['id', 'questionOrder', 'question']
      });
      
      console.log(`   Total questions: ${questions.length}`);
      console.log('   Question order verification:');
      
      // Check first 10 questions
      const firstTen = questions.slice(0, 10);
      firstTen.forEach((q, index) => {
        const questionNumber = q.question.match(/^(\d+)\./)?.[1] || '?';
        const isCorrectOrder = q.questionOrder === index + 1;
        const status = isCorrectOrder ? '✅' : '❌';
        console.log(`     ${status} Order ${q.questionOrder}: Q${questionNumber} - ${q.question.substring(0, 50)}...`);
      });
      
      // Check if there are more questions
      if (questions.length > 10) {
        console.log(`     ... and ${questions.length - 10} more questions`);
        
        // Check last few questions
        const lastFew = questions.slice(-3);
        lastFew.forEach((q, index) => {
          const questionNumber = q.question.match(/^(\d+)\./)?.[1] || '?';
          const actualOrder = questions.length - 3 + index + 1;
          const isCorrectOrder = q.questionOrder === actualOrder;
          const status = isCorrectOrder ? '✅' : '❌';
          console.log(`     ${status} Order ${q.questionOrder}: Q${questionNumber} - ${q.question.substring(0, 50)}...`);
        });
      }
      
      // Verify sequence integrity
      let sequenceValid = true;
      for (let i = 0; i < questions.length; i++) {
        if (questions[i].questionOrder !== i + 1) {
          sequenceValid = false;
          break;
        }
      }
      
      console.log(`   📊 Sequence integrity: ${sequenceValid ? '✅ VALID' : '❌ INVALID'}`);
    }
    
    console.log('\n🎊 Question order verification completed!');
    
  } catch (error) {
    console.error('❌ Error verifying question order:', error);
    throw error;
  } finally {
    await sequelize.close();
  }
}

// Run the verification
if (require.main === module) {
  verifyQuestionOrder()
    .then(() => {
      console.log('✅ Verification completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Verification failed:', error);
      process.exit(1);
    });
}

module.exports = { verifyQuestionOrder };
