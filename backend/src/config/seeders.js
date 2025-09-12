const User = require('../models/User');
const Exam = require('../models/Exam');
const Question = require('../models/Question');
const PaymentRequest = require('../models/PaymentRequest');
const AccessCode = require('../models/AccessCode');
const ExamResult = require('../models/ExamResult');
const bcrypt = require('bcryptjs');

// Setup associations
const setupAssociations = require('./associations');
setupAssociations();

class DatabaseSeeder {
  /**
   * Run all seeders
   */
  static async run() {
    try {
      console.log('🌱 Starting database seeding...');
      
      await this.seedUsers();
      await this.seedExams();
      await this.seedQuestions();
      await this.seedPaymentRequests();
      await this.seedAccessCodes();
      await this.seedExamResults();
      
      console.log('✅ Database seeding completed successfully!');
    } catch (error) {
      console.error('❌ Database seeding failed:', error);
      throw error;
    }
  }

  /**
   * Seed users table
   */
  static async seedUsers() {
    console.log('👥 Seeding users...');
    
    const hashedPassword = await bcrypt.hash('password123', 12);
    
    const users = [
      {
        password: hashedPassword,
        fullName: 'Admin User',
        phoneNumber: '+1234567890',
        deviceId: 'admin-device-123456789',
        role: 'ADMIN',
        isActive: true
      },
      {
        password: hashedPassword,
        fullName: 'Manager User',
        phoneNumber: '+1234567891',
        deviceId: 'manager-device-123456789',
        role: 'MANAGER',
        isActive: true
      },
      {
        password: hashedPassword,
        fullName: 'John Doe',
        phoneNumber: '+1234567892',
        deviceId: 'user-device-123456789',
        role: 'USER',
        isActive: true
      },
      {
        password: hashedPassword,
        fullName: 'Jane Smith',
        phoneNumber: '+1234567893',
        deviceId: 'user-device-123456790',
        role: 'USER',
        isActive: true
      },
      {
        password: hashedPassword,
        fullName: 'Mike Johnson',
        phoneNumber: '+1234567894',
        deviceId: 'user-device-123456791',
        role: 'USER',
        isActive: false
      }
    ];

    for (const userData of users) {
      await User.findOrCreate({
        where: { deviceId: userData.deviceId },
        defaults: userData
      });
    }
    
    console.log('✅ Users seeded successfully');
  }

  /**
   * Seed exams table
   */
  static async seedExams() {
    console.log('📝 Seeding exams...');
    
    const exams = [
      {
        title: 'Free Exam',
        description: 'Basic traffic rules and regulations - Free practice exam',
        category: 'Traffic Rules',
        difficulty: 'EASY',
        duration: 20,
        questionCount: 15,
        passingScore: 70,
        isActive: true,
        examImgUrl: 'assets/examimages/free.jpg'
      },
      {
        title: 'Traffic Signs and Signals',
        description: 'Comprehensive test on traffic signs, signals, and road markings',
        category: 'Traffic Signs',
        difficulty: 'MEDIUM',
        duration: 30,
        questionCount: 25,
        passingScore: 75,
        isActive: true,
        examImgUrl: 'assets/examimages/exam1.png'
      },
      {
        title: 'Vehicle Regulations',
        description: 'Vehicle requirements, inspections, and safety regulations',
        category: 'Vehicle Rules',
        difficulty: 'MEDIUM',
        duration: 25,
        questionCount: 20,
        passingScore: 75,
        isActive: true,
        examImgUrl: 'assets/examimages/exam2.jpg'
      },
      {
        title: 'Road Safety and Emergencies',
        description: 'Road safety procedures and emergency response',
        category: 'Safety',
        difficulty: 'HARD',
        duration: 35,
        questionCount: 30,
        passingScore: 80,
        isActive: true,
        examImgUrl: 'assets/examimages/exam10.png'
      },
      {
        title: 'Parking and Traffic Control',
        description: 'Parking rules and traffic control devices',
        category: 'Traffic Control',
        difficulty: 'EASY',
        duration: 15,
        questionCount: 12,
        passingScore: 70,
        isActive: true,
        examImgUrl: 'assets/examimages/exam4.png'
      },
      {
        title: 'Highway and Expressway Rules',
        description: 'Rules and regulations for highway and expressway driving',
        category: 'Highway Rules',
        difficulty: 'MEDIUM',
        duration: 30,
        questionCount: 25,
        passingScore: 75,
        isActive: true,
        examImgUrl: 'assets/examimages/exam5.png'
      },
      {
        title: 'Advanced Driving Techniques',
        description: 'Advanced driving techniques and defensive driving',
        category: 'Driving Techniques',
        difficulty: 'HARD',
        duration: 40,
        questionCount: 35,
        passingScore: 80,
        isActive: true,
        examImgUrl: 'assets/examimages/exam6.png'
      },
      {
        title: 'Traffic Violations and Penalties',
        description: 'Understanding traffic violations and their penalties',
        category: 'Legal',
        difficulty: 'MEDIUM',
        duration: 25,
        questionCount: 20,
        passingScore: 75,
        isActive: true,
        examImgUrl: 'assets/examimages/exam7.png'
      },
      {
        title: 'Environmental and Eco-Driving',
        description: 'Environmental considerations and eco-friendly driving',
        category: 'Environment',
        difficulty: 'EASY',
        duration: 20,
        questionCount: 15,
        passingScore: 70,
        isActive: true,
        examImgUrl: 'assets/examimages/exam8.png'
      }
    ];

    for (const examData of exams) {
      await Exam.findOrCreate({
        where: { title: examData.title },
        defaults: examData
      });
    }
    
    console.log('✅ Exams seeded successfully');
  }

  /**
   * Seed questions table
   */
  static async seedQuestions() {
    console.log('❓ Seeding questions...');
    
    const exams = await Exam.findAll();
    const freeExam = exams.find(e => e.title === 'Free Exam');
    const trafficSignsExam = exams.find(e => e.title === 'Traffic Signs and Signals');
    
    if (!freeExam || !trafficSignsExam) {
      console.log('⚠️ Exams not found, skipping questions seeding');
      return;
    }

    const questions = [
      // Free Exam Questions (from endata.json)
      {
        examId: freeExam.id,
        question: '1. Every vehicle or set of vehicles in motion must have:',
        options: ['a) A driver', 'b) A conveyor', 'c) A and B are correct', 'd) No correct answer'],
        correctAnswer: 'A',
        explanation: 'Every vehicle in motion must have a driver.',
        difficulty: 'EASY',
        points: 1,
        questionImgUrl: ''
      },
      {
        examId: freeExam.id,
        question: '2. The term "Foot path" designates a narrow public way accessible only to the traffic of:',
        options: ['a) Pedestrians', 'b) Two wheel vehicles', 'c) A and B both are correct', 'd) All responses are correct'],
        correctAnswer: 'D',
        explanation: 'A foot path is accessible to pedestrians and two-wheel vehicles.',
        difficulty: 'EASY',
        points: 1,
        questionImgUrl: ''
      },
      {
        examId: freeExam.id,
        question: '3. The broken line which announces the approach of a continuous line may be completed by white fall back arrows, these marks announce:',
        options: ['a) The traffic lane that drivers must follow', 'b) Approach of a continuous line', 'c) Reduction of the number of traffic lanes which may be used in the direction followed', 'd) A and C are both correct'],
        correctAnswer: 'C',
        explanation: 'These marks announce the reduction of traffic lanes.',
        difficulty: 'MEDIUM',
        points: 2,
        questionImgUrl: ''
      },
      {
        examId: freeExam.id,
        question: '4. In places where there are traffic lights, vehicles cannot move:',
        options: ['a) In parallel lines', 'b) On one line', 'c) A and B are both correct', 'd) None'],
        correctAnswer: 'D',
        explanation: 'Vehicles can move in parallel lines or on one line at traffic lights.',
        difficulty: 'EASY',
        points: 1,
        questionImgUrl: ''
      },
      {
        examId: freeExam.id,
        question: '5. The following vehicles must be inspected for road worthiness every year',
        options: ['a) Vehicles for public transport', 'b) Vehicles for transport of goods of which carrying capacity exceed 3.5 tones', 'c) Vehicles for driving school', 'd) None'],
        correctAnswer: 'B',
        explanation: 'Vehicles carrying goods over 3.5 tons must be inspected yearly.',
        difficulty: 'MEDIUM',
        points: 2,
        questionImgUrl: ''
      },
      {
        examId: freeExam.id,
        question: 'What does a yellow traffic light indicate?',
        options: ['Stop', 'Go', 'Caution - Prepare to stop', 'Speed up'],
        correctAnswer: 'C',
        explanation: 'A yellow light means caution - prepare to stop if it\'s safe to do so.',
        difficulty: 'EASY',
        points: 1
      },
      {
        examId: freeExam.id,
        question: 'What does a stop sign look like?',
        options: ['Red octagon', 'Yellow triangle', 'Blue circle', 'Green square'],
        correctAnswer: 'A',
        explanation: 'A stop sign is a red octagon with white letters.',
        difficulty: 'EASY',
        points: 1
      },
      {
        examId: freeExam.id,
        question: 'What does a yield sign mean?',
        options: ['Stop completely', 'Slow down and give right of way', 'Speed up', 'Turn around'],
        correctAnswer: 'B',
        explanation: 'A yield sign means slow down and give right of way to other traffic.',
        difficulty: 'MEDIUM',
        points: 1
      },
      {
        examId: freeExam.id,
        question: 'What color are warning signs typically?',
        options: ['Red', 'Blue', 'Yellow', 'Green'],
        correctAnswer: 'C',
        explanation: 'Warning signs are typically yellow with black symbols or text.',
        difficulty: 'EASY',
        points: 1
      },

      // Road Rules Questions
      {
        examId: trafficSignsExam.id,
        question: 'What is the speed limit in a school zone?',
        options: ['25 mph', '35 mph', '45 mph', '55 mph'],
        correctAnswer: 'A',
        explanation: 'The speed limit in school zones is typically 25 mph.',
        difficulty: 'MEDIUM',
        points: 2
      },
      {
        examId: trafficSignsExam.id,
        question: 'When should you use your turn signals?',
        options: ['Only when turning', 'At least 100 feet before turning', 'Only in heavy traffic', 'Never'],
        correctAnswer: 'B',
        explanation: 'You should signal at least 100 feet before making a turn or lane change.',
        difficulty: 'MEDIUM',
        points: 2
      },
      {
        examId: trafficSignsExam.id,
        question: 'What should you do when approaching a school bus with flashing red lights?',
        options: ['Speed up and pass', 'Stop and wait', 'Honk your horn', 'Change lanes'],
        correctAnswer: 'B',
        explanation: 'You must stop and wait when a school bus has flashing red lights.',
        difficulty: 'MEDIUM',
        points: 2
      },
      {
        examId: trafficSignsExam.id,
        question: 'What is the legal blood alcohol limit for driving?',
        options: ['0.05%', '0.08%', '0.10%', '0.12%'],
        correctAnswer: 'B',
        explanation: 'The legal blood alcohol limit is typically 0.08% in most states.',
        difficulty: 'HARD',
        points: 3
      },
      {
        examId: trafficSignsExam.id,
        question: 'When should you wear a seatbelt?',
        options: ['Only on highways', 'Only in the front seat', 'Always when the vehicle is moving', 'Only at night'],
        correctAnswer: 'C',
        explanation: 'You should always wear a seatbelt when the vehicle is moving.',
        difficulty: 'EASY',
        points: 1,
        questionImgUrl: ''
      },
      
      // Questions with images from endata.json
      {
        examId: trafficSignsExam.id,
        question: 'What does this traffic sign indicate?',
        options: ['No entry', 'One way', 'Stop', 'Yield'],
        correctAnswer: 'A',
        explanation: 'This sign indicates no entry for vehicles.',
        difficulty: 'MEDIUM',
        points: 2,
        questionImgUrl: 'assets/examimages/q214.png'
      },
      {
        examId: trafficSignsExam.id,
        question: 'What is the meaning of this road marking?',
        options: ['Lane divider', 'No passing zone', 'Speed limit', 'Parking area'],
        correctAnswer: 'B',
        explanation: 'This marking indicates a no passing zone.',
        difficulty: 'MEDIUM',
        points: 2,
        questionImgUrl: 'assets/examimages/q224.png'
      },
      {
        examId: trafficSignsExam.id,
        question: 'What should you do when you see this signal?',
        options: ['Stop', 'Proceed with caution', 'Turn right only', 'Speed up'],
        correctAnswer: 'A',
        explanation: 'This signal means you must stop.',
        difficulty: 'EASY',
        points: 1,
        questionImgUrl: 'assets/examimages/q229.png'
      }
    ];

    for (const questionData of questions) {
      await Question.findOrCreate({
        where: { 
          examId: questionData.examId,
          question: questionData.question 
        },
        defaults: questionData
      });
    }
    
    console.log('✅ Questions seeded successfully');
  }

  /**
   * Seed payment requests table
   */
  static async seedPaymentRequests() {
    console.log('💳 Seeding payment requests...');
    
    const users = await User.findAll({ where: { role: 'USER' } });
    const exams = await Exam.findAll({ where: { isActive: true } });
    
    if (users.length === 0 || exams.length === 0) {
      console.log('⚠️ Users or exams not found, skipping payment requests seeding');
      return;
    }

    const paymentRequests = [
      {
        userId: users[0].id,
        amount: 25.00, // Global access price
        paymentMethod: 'Bank Transfer',
        status: 'APPROVED',
        paymentProof: 'Bank receipt #12345'
      },
      {
        userId: users[0].id,
        amount: 25.00, // Global access price
        paymentMethod: 'Mobile Money',
        status: 'PENDING',
        paymentProof: 'Mobile money transaction #67890'
      },
      {
        userId: users[1].id,
        amount: 25.00, // Global access price
        paymentMethod: 'Bank Transfer',
        status: 'REJECTED',
        paymentProof: 'Invalid receipt',
        rejectionReason: 'Payment proof is unclear'
      }
    ];

    for (const paymentData of paymentRequests) {
      await PaymentRequest.findOrCreate({
        where: { 
          userId: paymentData.userId,
          status: paymentData.status
        },
        defaults: paymentData
      });
    }
    
    console.log('✅ Payment requests seeded successfully');
  }

  /**
   * Seed access codes table
   */
  static async seedAccessCodes() {
    console.log('🔑 Seeding access codes...');
    
    const approvedPayments = await PaymentRequest.findAll({ 
      where: { status: 'APPROVED' },
      include: [{ model: User, as: 'User' }]
    });
    
    if (approvedPayments.length === 0) {
      console.log('⚠️ No approved payments found, skipping access codes seeding');
      return;
    }

    for (const payment of approvedPayments) {
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 30); // 30 days from now
      
      await AccessCode.findOrCreate({
        where: { 
          userId: payment.userId
        },
        defaults: {
          code: AccessCode.generateCode(),
          userId: payment.userId,
          expiresAt: expiresAt,
          isUsed: false
        }
      });
    }
    
    console.log('✅ Access codes seeded successfully');
  }

  /**
   * Seed exam results table
   */
  static async seedExamResults() {
    console.log('📊 Seeding exam results...');
    
    const users = await User.findAll({ where: { role: 'USER' } });
    const exams = await Exam.findAll({ where: { isActive: true } });
    
    if (users.length === 0 || exams.length === 0) {
      console.log('⚠️ Users or exams not found, skipping exam results seeding');
      return;
    }

    const examResults = [
      {
        userId: users[0].id,
        examId: exams[0].id,
        score: 85,
        totalQuestions: 15,
        correctAnswers: 13,
        timeSpent: 1200, // 20 minutes in seconds
        passed: true,
        answers: {
          '1': 'A',
          '2': 'C',
          '3': 'A',
          '4': 'B',
          '5': 'C'
        }
      },
      {
        userId: users[1].id,
        examId: exams[0].id,
        score: 60,
        totalQuestions: 15,
        correctAnswers: 9,
        timeSpent: 900, // 15 minutes in seconds
        passed: false,
        answers: {
          '1': 'B',
          '2': 'A',
          '3': 'C',
          '4': 'A',
          '5': 'B'
        }
      }
    ];

    for (const resultData of examResults) {
      await ExamResult.findOrCreate({
        where: { 
          userId: resultData.userId,
          examId: resultData.examId
        },
        defaults: resultData
      });
    }
    
    console.log('✅ Exam results seeded successfully');
  }

  /**
   * Clear all seeded data
   */
  static async clear() {
    try {
      console.log('🧹 Clearing seeded data...');
      
      await ExamResult.destroy({ where: {} });
      await AccessCode.destroy({ where: {} });
      await PaymentRequest.destroy({ where: {} });
      await Question.destroy({ where: {} });
      await Exam.destroy({ where: {} });
      await User.destroy({ where: {} });
      
      console.log('✅ Seeded data cleared successfully');
    } catch (error) {
      console.error('❌ Failed to clear seeded data:', error);
      throw error;
    }
  }
}

module.exports = DatabaseSeeder;
