const { sequelize } = require('./src/config/database');
const { Question } = require('./src/models');

async function updateQuestionOrder() {
  try {
    console.log('🔄 Updating question order for existing questions...');
    
    // Get all questions grouped by exam
    const exams = await sequelize.query(`
      SELECT DISTINCT examId FROM Questions ORDER BY examId
    `, { type: sequelize.QueryTypes.SELECT });
    
    console.log(`📊 Found ${exams.length} exams to update`);
    
    for (const exam of exams) {
      const examId = exam.examId;
      console.log(`\n📝 Processing exam: ${examId}`);
      
      // Get questions for this exam ordered by createdAt (original insertion order)
      const questions = await Question.findAll({
        where: { examId: examId },
        order: [['createdAt', 'ASC']]
      });
      
      console.log(`   Found ${questions.length} questions`);
      
      // Update each question with its order
      for (let i = 0; i < questions.length; i++) {
        const question = questions[i];
        await question.update({
          questionOrder: i + 1
        });
        
        if ((i + 1) % 10 === 0 || i === questions.length - 1) {
          console.log(`     ✅ Updated ${i + 1}/${questions.length} questions`);
        }
      }
      
      console.log(`   🎉 Completed exam: ${examId}`);
    }
    
    console.log('\n✅ Question order update completed successfully!');
    
    // Verify the update
    console.log('\n🔍 Verification:');
    const sampleQuestions = await Question.findAll({
      where: { examId: exams[0].examId },
      order: [['questionOrder', 'ASC']],
      limit: 5,
      attributes: ['id', 'questionOrder', 'question']
    });
    
    console.log('First 5 questions in order:');
    sampleQuestions.forEach((q, index) => {
      console.log(`   ${q.questionOrder}. ${q.question.substring(0, 50)}...`);
    });
    
  } catch (error) {
    console.error('❌ Error updating question order:', error);
    throw error;
  } finally {
    await sequelize.close();
  }
}

// Run the update function
if (require.main === module) {
  updateQuestionOrder()
    .then(() => {
      console.log('✅ Update completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Update failed:', error);
      process.exit(1);
    });
}

module.exports = { updateQuestionOrder };
