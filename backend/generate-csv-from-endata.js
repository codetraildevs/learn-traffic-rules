const fs = require('fs');
const path = require('path');

// Read the endata.json file
const endataPath = path.join(__dirname, '..', 'endata.json');
const endataFile = JSON.parse(fs.readFileSync(endataPath, 'utf8'));
const endata = endataFile.exams;

console.log('📚 Processing endata.json...');
console.log(`   Found ${endata.length} exams`);

// Function to remove numbers from question text
function removeQuestionNumber(questionText) {
  // Remove patterns like "1. ", "10. ", "100. " etc.
  return questionText.replace(/^\d+\.\s*/, '');
}

// Function to keep option text with letters (a), b), c), d))
function keepOptionText(optionText) {
  return optionText; // Keep the original format with letters
}

// Function to get correct answer (keep full text format)
function getCorrectAnswer(correctAnswer) {
  return correctAnswer; // Keep the full text format like "a) A driver"
}

// Process each exam
endata.forEach((exam, examIndex) => {
  console.log(`\n📝 Processing Exam ${examIndex + 1}: ${exam.title}`);
  console.log(`   Questions: ${exam.questions.length}`);
  
  // Create CSV content
  const csvHeader = 'question,option1,option2,option3,option4,correctAnswer,questionImgUrl,points\n';
  let csvContent = csvHeader;
  
  // Process each question
  exam.questions.forEach((question, questionIndex) => {
    // Remove question number
    const cleanQuestion = removeQuestionNumber(question.question);
    
    // Keep option texts with letters
    const option1 = keepOptionText(question.option1);
    const option2 = keepOptionText(question.option2);
    const option3 = keepOptionText(question.option3);
    const option4 = keepOptionText(question.option4);
    
    // Get correct answer (full text format)
    const correctAnswer = getCorrectAnswer(question.correctAnswer);
    
    // Create CSV row
    const csvRow = [
      `"${cleanQuestion}"`,
      `"${option1}"`,
      `"${option2}"`,
      `"${option3}"`,
      `"${option4}"`,
      `"${correctAnswer}"`,
      `"${question.questionImgUrl || ''}"`,
      '1'
    ].join(',') + '\n';
    
    csvContent += csvRow;
  });
  
  // Create filename
  const examNumber = examIndex + 1;
  const filename = `exam_${examNumber}_questions.csv`;
  const filepath = path.join(__dirname, filename);
  
  // Write CSV file
  fs.writeFileSync(filepath, csvContent, 'utf8');
  
  console.log(`   ✅ Created: ${filename}`);
  console.log(`   📊 Questions: ${exam.questions.length}`);
  console.log(`   📁 File size: ${(csvContent.length / 1024).toFixed(2)} KB`);
});

console.log('\n🎉 CSV generation completed!');
console.log(`📁 Generated ${endata.length} CSV files in: ${__dirname}`);

// Also create a summary file
const summaryPath = path.join(__dirname, 'csv_generation_summary.txt');
let summaryContent = 'CSV Generation Summary\n';
summaryContent += '========================\n\n';

endata.forEach((exam, examIndex) => {
  summaryContent += `Exam ${examIndex + 1}: ${exam.title}\n`;
  summaryContent += `  File: exam_${examIndex + 1}_questions.csv\n`;
  summaryContent += `  Questions: ${exam.questions.length}\n`;
  summaryContent += `  Sample Question: ${removeQuestionNumber(exam.questions[0].question).substring(0, 50)}...\n\n`;
});

fs.writeFileSync(summaryPath, summaryContent, 'utf8');
console.log(`📋 Summary created: csv_generation_summary.txt`);
