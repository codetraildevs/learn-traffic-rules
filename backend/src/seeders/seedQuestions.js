const { Question, Exam } = require('../models');

const sampleQuestions = [
  {
    question: "Headlights of vehicle must be switched off when:",
    option1: "a) A roadway lighting is continuous and sufficient to permit the driver to see distinctly up to a distance of 20 meters",
    option2: "b) When a vehicle is going to cross another",
    option3: "c) In agglomeration",
    option4: "d) All responses are correct",
    correctAnswer: "b) When a vehicle is going to cross another",
    questionImgUrl: "",
    points: 1
  },
  {
    question: "What does this sign mean?",
    option1: "a. Emerging into a quay or a river bank or approaching a ferry",
    option2: "b. Steep hill downwards",
    option3: "c. Uneven road surface",
    option4: "d. Over flooding road",
    correctAnswer: "a. Emerging into a quay or a river bank or approaching a ferry",
    questionImgUrl: "assets/examimages/q247.png",
    points: 1
  },
  {
    question: "When should you use your turn signals?",
    option1: "Only when turning",
    option2: "At least 100 feet before turning or changing lanes",
    option3: "Only on highways",
    option4: "Only during the day",
    correctAnswer: "At least 100 feet before turning or changing lanes",
    questionImgUrl: "",
    points: 1
  },
  {
    question: "What is the speed limit in a school zone?",
    option1: "25 mph",
    option2: "30 mph",
    option3: "35 mph",
    option4: "40 mph",
    correctAnswer: "25 mph",
    questionImgUrl: "",
    points: 1
  },
  {
    question: "When approaching a stop sign, you must:",
    option1: "Slow down and proceed if clear",
    option2: "Come to a complete stop",
    option3: "Only stop if other vehicles are present",
    option4: "Stop only if pedestrians are crossing",
    correctAnswer: "Come to a complete stop",
    questionImgUrl: "",
    points: 1
  },
  {
    question: "What does a red traffic light mean?",
    option1: "Slow down and proceed with caution",
    option2: "Stop and wait for green light",
    option3: "Proceed if no other vehicles are present",
    option4: "Turn right only",
    correctAnswer: "Stop and wait for green light",
    questionImgUrl: "",
    points: 1
  },
  {
    question: "When parallel parking, you should:",
    option1: "Park at least 6 inches from the curb",
    option2: "Park at least 12 inches from the curb",
    option3: "Park as close to the curb as possible",
    option4: "Park in the middle of the street",
    correctAnswer: "Park as close to the curb as possible",
    questionImgUrl: "",
    points: 1
  },
  {
    question: "What is the minimum following distance in good weather?",
    option1: "1 second",
    option2: "2 seconds",
    option3: "3 seconds",
    option4: "4 seconds",
    correctAnswer: "3 seconds",
    questionImgUrl: "",
    points: 1
  },
  {
    question: "When should you yield the right of way?",
    option1: "Only at stop signs",
    option2: "Only at traffic lights",
    option3: "When required by law or traffic signs",
    option4: "Never",
    correctAnswer: "When required by law or traffic signs",
    questionImgUrl: "",
    points: 1
  },
  {
    question: "What does a yellow traffic light mean?",
    option1: "Speed up to make it through",
    option2: "Stop if you can do so safely",
    option3: "Proceed with caution",
    option4: "Both B and C",
    correctAnswer: "Both B and C",
    questionImgUrl: "",
    points: 1
  }
];

const seedQuestions = async () => {
  try {
    console.log('🌱 Starting to seed questions...');
    
    // Get all exams to assign questions to
    const exams = await Exam.findAll();
    
    if (exams.length === 0) {
      console.log('⚠️  No exams found. Please create exams first.');
      return;
    }
    
    // Create questions for each exam
    for (const exam of exams) {
      console.log(`📝 Adding questions to exam: ${exam.title}`);
      
      for (const questionData of sampleQuestions) {
        await Question.create({
          examId: exam.id,
          ...questionData
        });
      }
    }
    
    console.log(`✅ Successfully seeded ${sampleQuestions.length * exams.length} questions across ${exams.length} exams`);
  } catch (error) {
    console.error('❌ Error seeding questions:', error);
  }
};

module.exports = { seedQuestions };
