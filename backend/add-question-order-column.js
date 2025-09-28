const { sequelize } = require('./src/config/database');

async function addQuestionOrderColumn() {
  try {
    console.log('🔄 Adding questionOrder column to Questions table...');
    
    // Add the questionOrder column
    await sequelize.query(`
      ALTER TABLE questions 
      ADD COLUMN questionOrder INT NOT NULL DEFAULT 1 
      COMMENT 'Order of question within the exam (1, 2, 3, etc.)'
    `);
    
    console.log('✅ questionOrder column added successfully');
    
    // Verify the column was added
    const [results] = await sequelize.query(`
      DESCRIBE questions
    `);
    
    const questionOrderColumn = results.find(col => col.Field === 'questionOrder');
    if (questionOrderColumn) {
      console.log('✅ Column verification successful:');
      console.log(`   Field: ${questionOrderColumn.Field}`);
      console.log(`   Type: ${questionOrderColumn.Type}`);
      console.log(`   Null: ${questionOrderColumn.Null}`);
      console.log(`   Default: ${questionOrderColumn.Default}`);
    } else {
      console.log('❌ Column not found after creation');
    }
    
  } catch (error) {
    console.error('❌ Error adding questionOrder column:', error);
    throw error;
  } finally {
    await sequelize.close();
  }
}

// Run the migration
if (require.main === module) {
  addQuestionOrderColumn()
    .then(() => {
      console.log('✅ Migration completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Migration failed:', error);
      process.exit(1);
    });
}

module.exports = { addQuestionOrderColumn };
