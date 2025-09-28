const { Exam } = require('../models');

const sampleExams = [
  {
    title: "Traffic Signs and Signals",
    description: "Comprehensive test on traffic signs, signals, and road markings",
    category: "Traffic Rules",
    difficulty: "EASY",
    duration: 30,
    passingScore: 70,
    isActive: true,
    examImgUrl: "/uploads/exam1.png"
  },
  {
    title: "Highway and Expressway Rules",
    description: "Rules and regulations for highway and expressway driving",
    category: "Highway Rules",
    difficulty: "MEDIUM",
    duration: 45,
    passingScore: 75,
    isActive: true,
    examImgUrl: "/uploads/exam2.png"
  },
  {
    title: "Environmental and Eco-Driving",
    description: "Environmental considerations and eco-friendly driving practices",
    category: "Environment",
    difficulty: "EASY",
    duration: 25,
    passingScore: 70,
    isActive: true,
    examImgUrl: "/uploads/exam3.png"
  },
  {
    title: "Vehicle Safety and Maintenance",
    description: "Basic vehicle safety checks and maintenance requirements",
    category: "Vehicle Safety",
    difficulty: "MEDIUM",
    duration: 35,
    passingScore: 80,
    isActive: true,
    examImgUrl: "/uploads/exam4.png"
  },
  {
    title: "Emergency Situations",
    description: "How to handle emergency situations while driving",
    category: "Emergency Response",
    difficulty: "HARD",
    duration: 40,
    passingScore: 85,
    isActive: true,
    examImgUrl: "/uploads/exam5.png"
  }
];

const seedExams = async () => {
  try {
    console.log('🌱 Starting to seed exams...');
    
    // Always create exams (force seeding)
    console.log('🔄 Force creating exams...');
    
    // Create sample exams
    const createdExams = [];
    for (const examData of sampleExams) {
      try {
        const exam = await Exam.create(examData);
        createdExams.push(exam);
        console.log(`✅ Created exam: ${exam.title} (ID: ${exam.id})`);
      } catch (createError) {
        console.error(`❌ Error creating exam ${examData.title}:`, createError.message);
      }
    }
    
    console.log(`✅ Successfully seeded ${createdExams.length} exams`);
    return createdExams;
  } catch (error) {
    console.error('❌ Error seeding exams:', error);
    return [];
  }
};

module.exports = { seedExams };
