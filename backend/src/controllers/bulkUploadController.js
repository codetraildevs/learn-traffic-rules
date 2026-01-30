const Exam = require('../models/Exam');
const Question = require('../models/Question');
const { validationResult } = require('express-validator');
const csv = require('csv-parser');
const fs = require('fs');
const path = require('path');
const { allQuestionCountsCache, CACHE_KEYS } = require('../utils/cache');

class BulkUploadController {
  /**
   * Upload questions from CSV file
   */
  async uploadQuestionsFromCSV(req, res) {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'CSV file is required'
        });
      }

      const { examId } = req.params;
      
      // Check if exam exists
      const exam = await Exam.findByPk(examId);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      const questions = [];
      const errors = [];

      // Parse CSV file
      const csvPath = req.file.path;
      const results = [];

      return new Promise((resolve, reject) => {
        fs.createReadStream(csvPath)
          .pipe(csv())
          .on('data', (data) => results.push(data))
          .on('end', async () => {
            try {
              // Process each row
              for (let i = 0; i < results.length; i++) {
                const row = results[i];
                const rowNumber = i + 2; // +2 because CSV has header and 0-indexed

                try {
                  // Validate required fields
                  if (!row.question || !row.options || !row.correctAnswer) {
                    errors.push(`Row ${rowNumber}: Missing required fields (question, options, correctAnswer)`);
                    continue;
                  }

                  // Parse options (assuming comma-separated)
                  const options = row.options.split(',').map(opt => opt.trim());
                  if (options.length < 2) {
                    errors.push(`Row ${rowNumber}: At least 2 options are required`);
                    continue;
                  }

                  // Validate correct answer
                  const correctAnswer = row.correctAnswer.trim().toUpperCase();
                  if (!['A', 'B', 'C', 'D', 'E'].includes(correctAnswer)) {
                    errors.push(`Row ${rowNumber}: Correct answer must be A, B, C, D, or E`);
                    continue;
                  }

                  // Create question
                  const question = await Question.create({
                    examId: examId,
                    questionText: row.question.trim(),
                    questionType: row.questionType || 'MULTIPLE_CHOICE',
                    options: options,
                    correctAnswer: correctAnswer,
                    explanation: row.explanation ? row.explanation.trim() : null,
                    imageUrl: row.imageUrl ? row.imageUrl.trim() : null,
                    questionImgUrl: row.questionImgUrl ? row.questionImgUrl.trim() : null,
                    difficulty: row.difficulty || 'MEDIUM',
                    points: parseInt(row.points) || 1
                  });

                  questions.push(question);
                } catch (error) {
                  errors.push(`Row ${rowNumber}: ${error.message}`);
                }
              }

              // Update exam question count
              const questionCount = await Question.count({ where: { examId: examId } });
              await exam.update({ questionCount: questionCount });

              // Invalidate question count cache
              allQuestionCountsCache.delete(CACHE_KEYS.ALL_QUESTION_COUNTS);
              console.log('📦 Invalidated question counts cache after CSV upload');

              // Clean up uploaded file
              fs.unlinkSync(csvPath);

              res.json({
                success: true,
                message: `${questions.length} questions uploaded successfully`,
                data: {
                  examId: examId,
                  questionCount: questionCount,
                  questionsCreated: questions.length,
                  errors: errors
                }
              });

              resolve();
            } catch (error) {
              // Clean up uploaded file
              if (fs.existsSync(csvPath)) {
                fs.unlinkSync(csvPath);
              }
              reject(error);
            }
          })
          .on('error', (error) => {
            // Clean up uploaded file
            if (fs.existsSync(csvPath)) {
              fs.unlinkSync(csvPath);
            }
            reject(error);
          });
      });

    } catch (error) {
      console.error('CSV upload error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Upload questions from JSON file
   */
  async uploadQuestionsFromJSON(req, res) {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'JSON file is required'
        });
      }

      const { examId } = req.params;
      
      // Check if exam exists
      const exam = await Exam.findByPk(examId);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'Exam not found'
        });
      }

      // Read and parse JSON file
      const jsonPath = req.file.path;
      const jsonData = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

      // Validate JSON structure
      if (!Array.isArray(jsonData.questions) && !Array.isArray(jsonData)) {
        return res.status(400).json({
          success: false,
          message: 'JSON must contain an array of questions or have a "questions" property with an array'
        });
      }

      const questionsData = Array.isArray(jsonData.questions) ? jsonData.questions : jsonData;
      const questions = [];
      const errors = [];

      // Process each question
      for (let i = 0; i < questionsData.length; i++) {
        const questionData = questionsData[i];
        const questionNumber = i + 1;

        try {
          // Validate required fields
          if (!questionData.questionText && !questionData.question) {
            errors.push(`Question ${questionNumber}: Missing question text`);
            continue;
          }

          if (!questionData.options || !Array.isArray(questionData.options)) {
            errors.push(`Question ${questionNumber}: Missing or invalid options array`);
            continue;
          }

          if (!questionData.correctAnswer) {
            errors.push(`Question ${questionNumber}: Missing correct answer`);
            continue;
          }

          // Create question
          const question = await Question.create({
            examId: examId,
            questionText: questionData.questionText || questionData.question,
            questionType: questionData.questionType || 'MULTIPLE_CHOICE',
            options: questionData.options,
            correctAnswer: questionData.correctAnswer,
            explanation: questionData.explanation || null,
            imageUrl: questionData.imageUrl || null,
            questionImgUrl: questionData.questionImgUrl || null,
            difficulty: questionData.difficulty || 'MEDIUM',
            points: questionData.points || 1
          });

          questions.push(question);
        } catch (error) {
          errors.push(`Question ${questionNumber}: ${error.message}`);
        }
      }

      // Update exam question count
      const questionCount = await Question.count({ where: { examId: examId } });
      await exam.update({ questionCount: questionCount });

      // Invalidate question count cache
      allQuestionCountsCache.delete(CACHE_KEYS.ALL_QUESTION_COUNTS);
      console.log('📦 Invalidated question counts cache after JSON upload');

      // Clean up uploaded file
      fs.unlinkSync(jsonPath);

      res.json({
        success: true,
        message: `${questions.length} questions uploaded successfully`,
        data: {
          examId: examId,
          questionCount: questionCount,
          questionsCreated: questions.length,
          errors: errors
        }
      });

    } catch (error) {
      console.error('JSON upload error:', error);
      
      // Clean up uploaded file
      if (req.file && fs.existsSync(req.file.path)) {
        fs.unlinkSync(req.file.path);
      }

      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Download CSV template
   */
  async downloadCSVTemplate(req, res) {
    try {
      const csvContent = `question,options,correctAnswer,explanation,imageUrl,questionImgUrl,difficulty,points
"What does a red traffic light mean?","Stop,Go,Slow down,Yield",A,"A red traffic light means you must come to a complete stop.","","assets/examimages/q1.png",EASY,1
"What does a yellow traffic light mean?","Stop,Go,Caution - Prepare to stop,Speed up",C,"A yellow light means prepare to stop, unless you cannot stop safely.","","assets/examimages/q2.png",EASY,1
"What does a stop sign mean?","Slow down,Stop completely,Yield,Go",B,"A stop sign requires a complete stop before proceeding.","","assets/examimages/q3.png",EASY,1`;

      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename="questions_template.csv"');
      res.send(csvContent);

    } catch (error) {
      console.error('CSV template download error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  /**
   * Download JSON template
   */
  async downloadJSONTemplate(req, res) {
    try {
      const jsonTemplate = {
        questions: [
          {
            questionText: "What does a red traffic light mean?",
            questionType: "MULTIPLE_CHOICE",
            options: ["Stop", "Go", "Slow down", "Yield"],
            correctAnswer: "A",
            explanation: "A red traffic light means you must come to a complete stop.",
            imageUrl: "",
            questionImgUrl: "assets/examimages/q1.png",
            difficulty: "EASY",
            points: 1
          },
          {
            questionText: "What does a yellow traffic light mean?",
            questionType: "MULTIPLE_CHOICE",
            options: ["Stop", "Go", "Caution - Prepare to stop", "Speed up"],
            correctAnswer: "C",
            explanation: "A yellow light means prepare to stop, unless you cannot stop safely.",
            imageUrl: "",
            questionImgUrl: "assets/examimages/q2.png",
            difficulty: "EASY",
            points: 1
          }
        ]
      };

      res.setHeader('Content-Type', 'application/json');
      res.setHeader('Content-Disposition', 'attachment; filename="questions_template.json"');
      res.json(jsonTemplate);

    } catch (error) {
      console.error('JSON template download error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
}

module.exports = new BulkUploadController();
