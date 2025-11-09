const fs = require('fs');
const path = require('path');

// Read the data.json file
const data = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'data.json'), 'utf8'));

// CSV header matching exam_1_questions.csv format
const csvHeader = 'question,option1,option2,option3,option4,correctAnswer,questionImgUrl,points\n';

// Function to escape CSV fields (handle commas and quotes)
function escapeCsvField(field) {
  if (field === null || field === undefined) {
    return '';
  }
  const str = String(field);
  // If field contains comma, quote, or newline, wrap in quotes and escape quotes
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return '"' + str.replace(/"/g, '""') + '"';
  }
  return str;
}

// Function to convert exam to CSV
function examToCsv(exam) {
  let csv = csvHeader;
  
  exam.questions.forEach((question) => {
    const row = [
      escapeCsvField(question.question || ''),
      escapeCsvField(question.option1 || ''),
      escapeCsvField(question.option2 || ''),
      escapeCsvField(question.option3 || ''),
      escapeCsvField(question.option4 || ''),
      escapeCsvField(question.correctAnswer || ''),
      escapeCsvField(question.questionImgUrl || ''),
      escapeCsvField(question.points || 1)
    ];
    csv += row.join(',') + '\n';
  });
  
  return csv;
}

// Process exams and create CSV files
console.log(`📊 Found ${data.exams.length} exams in data.json\n`);

// Limit to 21 exams as requested
const examsToProcess = data.exams.slice(0, 21);

examsToProcess.forEach((exam, index) => {
  const examNumber = index + 1;
  const quizId = exam.quizId || examNumber;
  const filename = `exam_${quizId}_kinyarwanda_questions.csv`;
  const filepath = path.join(__dirname, filename);
  
  try {
    const csvContent = examToCsv(exam);
    fs.writeFileSync(filepath, csvContent, 'utf8');
    console.log(`✅ Created: ${filename} (${exam.questions.length} questions)`);
  } catch (error) {
    console.error(`❌ Error creating ${filename}:`, error.message);
  }
});

console.log(`\n✨ Successfully created ${examsToProcess.length} CSV files!`);

