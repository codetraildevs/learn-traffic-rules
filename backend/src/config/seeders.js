const User = require('../models/User');
const Exam = require('../models/Exam');
const Question = require('../models/Question');
const PaymentRequest = require('../models/PaymentRequest');
const AccessCode = require('../models/AccessCode');
const ExamResult = require('../models/ExamResult');
const Course = require('../models/Course');
const CourseContent = require('../models/CourseContent');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

// Setup associations
const setupAssociations = require('./associations');
setupAssociations();

class DatabaseSeeder {
  /**
   * Run all seeders
   * Set skipExisting to true to skip seeding if data already exists
   */
  static async run(skipExisting = true) {
    try {
      console.log('🌱 Starting database seeding...');
      console.log(`📋 Skip existing data: ${skipExisting ? 'YES' : 'NO'}`);
      
      // Check if data exists
      if (skipExisting) {
        const userCount = await User.count();
        const examCount = await Exam.count();
        const courseCount = await Course.count();
        
        if (userCount > 0) {
          console.log('⚠️  Users already exist, skipping user seeding');
        } else {
          await this.seedUsers();
        }
        
        if (examCount > 0) {
          console.log('⚠️  Exams already exist, skipping exam seeding');
        } else {
          await this.seedExams();
          await this.seedQuestions();
        }
        
        if (courseCount > 0) {
          console.log('⚠️  Courses already exist, skipping course seeding');
        } else {
          await this.seedCourses();
        }
        
        // Always seed payment requests and access codes if users exist
        const users = await User.findAll({ where: { role: 'USER' } });
        if (users.length > 0) {
          await this.seedPaymentRequests();
          await this.seedAccessCodes();
          await this.seedExamResults();
        }
      } else {
        // Seed everything regardless of existing data
        await this.seedUsers();
        await this.seedExams();
        await this.seedQuestions();
        await this.seedCourses();
        await this.seedPaymentRequests();
        await this.seedAccessCodes();
        await this.seedExamResults();
      }
      
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
        phoneNumber: '0788888888',
        deviceId: 'admin-device-0788888888',
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
        phoneNumber: '0788888889',
        deviceId: 'user-device-0788888889',
        role: 'USER',
        isActive: true
      },
      {
        password: hashedPassword,
        fullName: 'Jane Smith',
        phoneNumber: '0788888890',
        deviceId: 'user-device-0788888890',
        role: 'USER',
        isActive: true
      },
      {
        password: hashedPassword,
        fullName: 'Mike Johnson',
        phoneNumber: '0788888891',
        deviceId: 'user-device-0788888891',
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
        passingScore: 70,
        examType: 'english',
        isActive: true,
        examImgUrl: '/uploads/exam-images/free.jpg'
      },
      {
        title: 'Traffic Signs and Signals',
        description: 'Comprehensive test on traffic signs, signals, and road markings',
        category: 'Traffic Signs',
        difficulty: 'MEDIUM',
        duration: 30,
        passingScore: 75,
        examType: 'english',
        isActive: true,
        examImgUrl: '/uploads/exam-images/exam1.png'
      },
      {
        title: 'Vehicle Regulations',
        description: 'Vehicle requirements, inspections, and safety regulations',
        category: 'Vehicle Rules',
        difficulty: 'MEDIUM',
        duration: 25,
        passingScore: 75,
        examType: 'english',
        isActive: true,
        examImgUrl: '/uploads/exam-images/exam2.jpg'
      },
      {
        title: 'Road Safety and Emergencies',
        description: 'Road safety procedures and emergency response',
        category: 'Safety',
        difficulty: 'HARD',
        duration: 35,
        passingScore: 80,
        examType: 'english',
        isActive: true,
        examImgUrl: '/uploads/exam-images/exam10.png'
      },
      {
        title: 'Parking and Traffic Control',
        description: 'Parking rules and traffic control devices',
        category: 'Traffic Control',
        difficulty: 'EASY',
        duration: 15,
        passingScore: 70,
        examType: 'english',
        isActive: true,
        examImgUrl: '/uploads/exam-images/exam4.png'
      },
      {
        title: 'Highway and Expressway Rules',
        description: 'Rules and regulations for highway and expressway driving',
        category: 'Highway Rules',
        difficulty: 'MEDIUM',
        duration: 30,
        passingScore: 75,
        examType: 'english',
        isActive: true,
        examImgUrl: '/uploads/exam-images/exam5.png'
      },
      {
        title: 'Advanced Driving Techniques',
        description: 'Advanced driving techniques and defensive driving',
        category: 'Driving Techniques',
        difficulty: 'HARD',
        duration: 40,
        passingScore: 80,
        examType: 'english',
        isActive: true,
        examImgUrl: '/uploads/exam-images/exam6.png'
      },
      {
        title: 'Traffic Violations and Penalties',
        description: 'Understanding traffic violations and their penalties',
        category: 'Legal',
        difficulty: 'MEDIUM',
        duration: 25,
        passingScore: 75,
        examType: 'english',
        isActive: true,
        examImgUrl: '/uploads/exam-images/exam7.png'
      },
      {
        title: 'Environmental and Eco-Driving',
        description: 'Environmental considerations and eco-friendly driving',
        category: 'Environment',
        difficulty: 'EASY',
        duration: 20,
        passingScore: 70,
        examType: 'english',
        isActive: true,
        examImgUrl: '/uploads/exam-images/exam8.png'
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
        question: 'Every vehicle or set of vehicles in motion must have:',
        option1: 'A driver',
        option2: 'A conveyor',
        option3: 'A and B are correct',
        option4: 'No correct answer',
        correctAnswer: 'A driver',
        points: 1,
        questionOrder: 1,
        questionImgUrl: null
      },
      {
        examId: freeExam.id,
        question: 'The term "Foot path" designates a narrow public way accessible only to the traffic of:',
        option1: 'Pedestrians',
        option2: 'Two wheel vehicles',
        option3: 'A and B both are correct',
        option4: 'All responses are correct',
        correctAnswer: 'All responses are correct',
        points: 1,
        questionOrder: 2,
        questionImgUrl: null
      },
      {
        examId: freeExam.id,
        question: 'The broken line which announces the approach of a continuous line may be completed by white fall back arrows, these marks announce:',
        option1: 'The traffic lane that drivers must follow',
        option2: 'Approach of a continuous line',
        option3: 'Reduction of the number of traffic lanes which may be used in the direction followed',
        option4: 'A and C are both correct',
        correctAnswer: 'Reduction of the number of traffic lanes which may be used in the direction followed',
        points: 2,
        questionOrder: 3,
        questionImgUrl: null
      },
      {
        examId: freeExam.id,
        question: 'In places where there are traffic lights, vehicles cannot move:',
        option1: 'In parallel lines',
        option2: 'On one line',
        option3: 'A and B are both correct',
        option4: 'None',
        correctAnswer: 'None',
        points: 1,
        questionOrder: 4,
        questionImgUrl: null
      },
      {
        examId: freeExam.id,
        question: 'The following vehicles must be inspected for road worthiness every year',
        option1: 'Vehicles for public transport',
        option2: 'Vehicles for transport of goods of which carrying capacity exceed 3.5 tones',
        option3: 'Vehicles for driving school',
        option4: 'None',
        correctAnswer: 'Vehicles for transport of goods of which carrying capacity exceed 3.5 tones',
        points: 2,
        questionOrder: 5,
        questionImgUrl: null
      },
      {
        examId: freeExam.id,
        question: 'What does a yellow traffic light indicate?',
        option1: 'Stop',
        option2: 'Go',
        option3: 'Caution - Prepare to stop',
        option4: 'Speed up',
        correctAnswer: 'Caution - Prepare to stop',
        points: 1,
        questionOrder: 6,
        questionImgUrl: null
      },
      {
        examId: freeExam.id,
        question: 'What does a stop sign look like?',
        option1: 'Red octagon',
        option2: 'Yellow triangle',
        option3: 'Blue circle',
        option4: 'Green square',
        correctAnswer: 'Red octagon',
        points: 1,
        questionOrder: 7,
        questionImgUrl: null
      },
      {
        examId: freeExam.id,
        question: 'What does a yield sign mean?',
        option1: 'Stop completely',
        option2: 'Slow down and give right of way',
        option3: 'Speed up',
        option4: 'Turn around',
        correctAnswer: 'Slow down and give right of way',
        points: 1,
        questionOrder: 8,
        questionImgUrl: null
      },
      {
        examId: freeExam.id,
        question: 'What color are warning signs typically?',
        option1: 'Red',
        option2: 'Blue',
        option3: 'Yellow',
        option4: 'Green',
        correctAnswer: 'Yellow',
        points: 1,
        questionOrder: 9,
        questionImgUrl: null
      },

      // Road Rules Questions
      {
        examId: trafficSignsExam.id,
        question: 'What is the speed limit in a school zone?',
        option1: '25 mph',
        option2: '35 mph',
        option3: '45 mph',
        option4: '55 mph',
        correctAnswer: '25 mph',
        points: 2,
        questionOrder: 1,
        questionImgUrl: null
      },
      {
        examId: trafficSignsExam.id,
        question: 'When should you use your turn signals?',
        option1: 'Only when turning',
        option2: 'At least 100 feet before turning',
        option3: 'Only in heavy traffic',
        option4: 'Never',
        correctAnswer: 'At least 100 feet before turning',
        points: 2,
        questionOrder: 2,
        questionImgUrl: null
      },
      {
        examId: trafficSignsExam.id,
        question: 'What should you do when approaching a school bus with flashing red lights?',
        option1: 'Speed up and pass',
        option2: 'Stop and wait',
        option3: 'Honk your horn',
        option4: 'Change lanes',
        correctAnswer: 'Stop and wait',
        points: 2,
        questionOrder: 3,
        questionImgUrl: null
      },
      {
        examId: trafficSignsExam.id,
        question: 'What is the legal blood alcohol limit for driving?',
        option1: '0.05%',
        option2: '0.08%',
        option3: '0.10%',
        option4: '0.12%',
        correctAnswer: '0.08%',
        points: 3,
        questionOrder: 4,
        questionImgUrl: null
      },
      {
        examId: trafficSignsExam.id,
        question: 'When should you wear a seatbelt?',
        option1: 'Only on highways',
        option2: 'Only in the front seat',
        option3: 'Always when the vehicle is moving',
        option4: 'Only at night',
        correctAnswer: 'Always when the vehicle is moving',
        points: 1,
        questionOrder: 5,
        questionImgUrl: null
      },
      
      // Questions with images from endata.json
      {
        examId: trafficSignsExam.id,
        question: 'What does this traffic sign indicate?',
        option1: 'No entry',
        option2: 'One way',
        option3: 'Stop',
        option4: 'Yield',
        correctAnswer: 'No entry',
        points: 2,
        questionOrder: 6,
        questionImgUrl: '/uploads/question-images/q214.png'
      },
      {
        examId: trafficSignsExam.id,
        question: 'What is the meaning of this road marking?',
        option1: 'Lane divider',
        option2: 'No passing zone',
        option3: 'Speed limit',
        option4: 'Parking area',
        correctAnswer: 'No passing zone',
        points: 2,
        questionOrder: 7,
        questionImgUrl: '/uploads/question-images/q224.png'
      },
      {
        examId: trafficSignsExam.id,
        question: 'What should you do when you see this signal?',
        option1: 'Stop',
        option2: 'Proceed with caution',
        option3: 'Turn right only',
        option4: 'Speed up',
        correctAnswer: 'Stop',
        points: 1,
        questionOrder: 8,
        questionImgUrl: '/uploads/question-images/q229.png'
      }
    ];

    for (const questionData of questions) {
      await Question.findOrCreate({
        where: { 
          examId: questionData.examId,
          question: questionData.question 
        },
        defaults: {
          id: uuidv4(),
          examId: questionData.examId,
          question: questionData.question,
          option1: questionData.option1,
          option2: questionData.option2,
          option3: questionData.option3,
          option4: questionData.option4,
          correctAnswer: questionData.correctAnswer,
          points: questionData.points,
          questionOrder: questionData.questionOrder,
          questionImgUrl: questionData.questionImgUrl || null
        }
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
          userId: payment.userId,
          isUsed: false
        },
        defaults: {
          code: AccessCode.generateCode(),
          userId: payment.userId,
          expiresAt: expiresAt,
          isUsed: false,
          paymentTier: '1_MONTH',
          paymentAmount: payment.amount || 25.00,
          durationDays: 30
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
   * Seed courses table
   */
  static async seedCourses() {
    console.log('📚 Seeding courses...');
    
    const courses = [
      {
        title: 'Introduction to Traffic Rules',
        description: 'Learn the fundamental traffic rules and regulations that every driver must know. This course covers basic road signs, right-of-way rules, and safe driving practices.',
        category: 'Traffic Rules',
        difficulty: 'EASY',
        courseType: 'free',
        courseImageUrl: 'course1.png',
        isActive: true,
        contents: [
          {
            contentType: 'text',
            content: 'Welcome to Introduction to Traffic Rules! This course will teach you the essential traffic rules and regulations that every driver needs to know. Understanding traffic rules is crucial for safe driving and avoiding accidents.',
            title: 'Welcome',
            displayOrder: 0
          },
          {
            contentType: 'text',
            content: 'Traffic rules are designed to ensure the safety of all road users, including drivers, passengers, pedestrians, and cyclists. These rules help maintain order on the roads and prevent accidents.',
            title: 'Importance of Traffic Rules',
            displayOrder: 1
          },
          {
            contentType: 'image',
            content: 'traffic-signs-intro.png',
            title: 'Common Traffic Signs',
            displayOrder: 2
          },
          {
            contentType: 'text',
            content: 'Right-of-way rules determine who has priority when multiple vehicles or pedestrians are approaching the same point. Understanding these rules helps prevent collisions and ensures smooth traffic flow.',
            title: 'Right-of-Way Rules',
            displayOrder: 3
          }
        ]
      },
      {
        title: 'Traffic Signs and Signals Mastery',
        description: 'Master all traffic signs, signals, and road markings. Understand what each sign means and how to respond appropriately in different situations.',
        category: 'Traffic Signs',
        difficulty: 'MEDIUM',
        courseType: 'free',
        courseImageUrl: 'course2.png',
        isActive: true,
        contents: [
          {
            contentType: 'text',
            content: 'Traffic signs are visual communication devices that provide important information to road users. They are categorized into regulatory signs, warning signs, and informational signs.',
            title: 'Types of Traffic Signs',
            displayOrder: 0
          },
          {
            contentType: 'image',
            content: 'regulatory-signs.png',
            title: 'Regulatory Signs',
            displayOrder: 1
          },
          {
            contentType: 'image',
            content: 'warning-signs.png',
            title: 'Warning Signs',
            displayOrder: 2
          },
          {
            contentType: 'text',
            content: 'Traffic signals use colored lights to control the flow of traffic. Red means stop, yellow means caution, and green means go. Understanding signal timing and how to respond is essential for safe driving.',
            title: 'Traffic Signals',
            displayOrder: 3
          },
          {
            contentType: 'video',
            content: 'traffic-signals-explained.mp4',
            title: 'Traffic Signals Explained',
            displayOrder: 4
          }
        ]
      },
      {
        title: 'Vehicle Regulations and Safety',
        description: 'Learn about vehicle requirements, inspections, safety regulations, and maintenance requirements for different types of vehicles.',
        category: 'Vehicle Rules',
        difficulty: 'MEDIUM',
        courseType: 'free',
        courseImageUrl: 'course3.png',
        isActive: true,
        contents: [
          {
            contentType: 'text',
            content: 'All vehicles on the road must meet certain safety requirements and pass regular inspections. This ensures that vehicles are roadworthy and safe to operate.',
            title: 'Vehicle Safety Requirements',
            displayOrder: 0
          },
          {
            contentType: 'text',
            content: 'Regular vehicle maintenance is essential for safety and performance. This includes checking brakes, tires, lights, and other critical components.',
            title: 'Vehicle Maintenance',
            displayOrder: 1
          },
          {
            contentType: 'image',
            content: 'vehicle-inspection.png',
            title: 'Vehicle Inspection Checklist',
            displayOrder: 2
          }
        ]
      },
      {
        title: 'Parking Rules and Regulations',
        description: 'Understand parking rules, restrictions, and proper parking techniques. Learn about parking zones, time limits, and parking violations.',
        category: 'Parking',
        difficulty: 'EASY',
        courseType: 'free',
        courseImageUrl: 'course4.png',
        isActive: true,
        contents: [
          {
            contentType: 'text',
            content: 'Parking rules vary by location and are designed to ensure traffic flow and safety. It is important to understand where you can and cannot park, and for how long.',
            title: 'Parking Basics',
            displayOrder: 0
          },
          {
            contentType: 'image',
            content: 'parking-zones.png',
            title: 'Parking Zones',
            displayOrder: 1
          },
          {
            contentType: 'text',
            content: 'Common parking violations include parking in no-parking zones, blocking fire hydrants, parking in handicapped spaces without permits, and exceeding time limits.',
            title: 'Parking Violations',
            displayOrder: 2
          }
        ]
      },
      {
        title: 'Highway and Expressway Driving',
        description: 'Master the rules and techniques for safe highway and expressway driving. Learn about merging, lane changes, speed limits, and emergency procedures.',
        category: 'Highway Rules',
        difficulty: 'HARD',
        courseType: 'paid',
        courseImageUrl: 'course5.png',
        isActive: true,
        contents: [
          {
            contentType: 'text',
            content: 'Highway driving requires special skills and knowledge. Higher speeds, multiple lanes, and complex traffic patterns make it essential to understand highway-specific rules and regulations.',
            title: 'Introduction to Highway Driving',
            displayOrder: 0
          },
          {
            contentType: 'text',
            content: 'Merging onto a highway requires proper timing and communication. Always use your turn signals and check blind spots before merging. Yield to traffic already on the highway.',
            title: 'Merging Techniques',
            displayOrder: 1
          },
          {
            contentType: 'video',
            content: 'highway-merging.mp4',
            title: 'Highway Merging Tutorial',
            displayOrder: 2
          },
          {
            contentType: 'text',
            content: 'Lane discipline is crucial on highways. Stay in the right lane except when passing. The left lane is for passing only, not for cruising.',
            title: 'Lane Discipline',
            displayOrder: 3
          },
          {
            contentType: 'text',
            content: 'In case of an emergency on the highway, move your vehicle to the shoulder, turn on hazard lights, and place warning devices behind your vehicle. Never stand in the traffic lane.',
            title: 'Emergency Procedures',
            displayOrder: 4
          }
        ]
      },
      {
        title: 'Defensive Driving Techniques',
        description: 'Learn advanced defensive driving techniques to anticipate and avoid potential hazards on the road. Become a safer, more aware driver.',
        category: 'Driving Techniques',
        difficulty: 'HARD',
        courseType: 'paid',
        courseImageUrl: 'course6.png',
        isActive: true,
        contents: [
          {
            contentType: 'text',
            content: 'Defensive driving is a set of skills that allows you to defend yourself against possible collisions caused by bad drivers, drunk drivers, and poor weather.',
            title: 'What is Defensive Driving?',
            displayOrder: 0
          },
          {
            contentType: 'text',
            content: 'Always be aware of your surroundings. Scan the road ahead, check your mirrors frequently, and be prepared to react to unexpected situations.',
            title: 'Situational Awareness',
            displayOrder: 1
          },
          {
            contentType: 'video',
            content: 'defensive-driving.mp4',
            title: 'Defensive Driving Techniques',
            displayOrder: 2
          },
          {
            contentType: 'text',
            content: 'Maintain a safe following distance. The general rule is to stay at least 3 seconds behind the vehicle in front of you. Increase this distance in bad weather or poor visibility.',
            title: 'Safe Following Distance',
            displayOrder: 3
          },
          {
            contentType: 'text',
            content: 'Always expect the unexpected. Assume that other drivers may make mistakes, and be prepared to react defensively to protect yourself and your passengers.',
            title: 'Expect the Unexpected',
            displayOrder: 4
          }
        ]
      },
      {
        title: 'Traffic Violations and Penalties',
        description: 'Understand common traffic violations, their penalties, and the consequences of breaking traffic laws. Learn how to avoid violations and keep your driving record clean.',
        category: 'Legal',
        difficulty: 'MEDIUM',
        courseType: 'paid',
        courseImageUrl: 'course7.png',
        isActive: true,
        contents: [
          {
            contentType: 'text',
            content: 'Traffic violations can result in fines, points on your license, increased insurance rates, and in severe cases, license suspension or revocation.',
            title: 'Understanding Traffic Violations',
            displayOrder: 0
          },
          {
            contentType: 'text',
            content: 'Common violations include speeding, running red lights, illegal parking, driving without a license or insurance, and driving under the influence.',
            title: 'Common Violations',
            displayOrder: 1
          },
          {
            contentType: 'text',
            content: 'Penalties vary depending on the severity of the violation. Minor violations may result in fines and points, while serious violations can lead to criminal charges.',
            title: 'Penalties and Consequences',
            displayOrder: 2
          },
          {
            contentType: 'link',
            content: 'https://www.example.com/traffic-laws',
            title: 'Official Traffic Laws Reference',
            displayOrder: 3
          }
        ]
      },
      {
        title: 'Road Safety and Emergency Response',
        description: 'Learn about road safety procedures, emergency response protocols, and how to handle accidents and emergencies on the road.',
        category: 'Safety',
        difficulty: 'MEDIUM',
        courseType: 'free',
        courseImageUrl: 'course8.png',
        isActive: true,
        contents: [
          {
            contentType: 'text',
            content: 'Road safety is everyone\'s responsibility. Understanding safety procedures and emergency response protocols can save lives and prevent serious injuries.',
            title: 'Road Safety Basics',
            displayOrder: 0
          },
          {
            contentType: 'text',
            content: 'In case of an accident, first ensure your own safety, then check on others. Call emergency services immediately and provide accurate information about the location and situation.',
            title: 'Accident Response',
            displayOrder: 1
          },
          {
            contentType: 'image',
            content: 'emergency-kit.png',
            title: 'Emergency Kit Contents',
            displayOrder: 2
          },
          {
            contentType: 'text',
            content: 'Always carry an emergency kit in your vehicle. This should include a first aid kit, flashlight, warning triangles, and basic tools.',
            title: 'Emergency Preparedness',
            displayOrder: 3
          }
        ]
      },
      {
        title: 'Eco-Friendly and Environmental Driving',
        description: 'Learn how to drive in an environmentally friendly manner. Reduce fuel consumption, minimize emissions, and contribute to a cleaner environment.',
        category: 'Environment',
        difficulty: 'EASY',
        courseType: 'free',
        courseImageUrl: 'course9.png',
        isActive: true,
        contents: [
          {
            contentType: 'text',
            content: 'Eco-driving techniques can significantly reduce fuel consumption and emissions while also saving you money on fuel costs.',
            title: 'What is Eco-Driving?',
            displayOrder: 0
          },
          {
            contentType: 'text',
            content: 'Smooth acceleration and braking, maintaining steady speeds, and avoiding unnecessary idling are key to eco-friendly driving.',
            title: 'Eco-Driving Techniques',
            displayOrder: 1
          },
          {
            contentType: 'text',
            content: 'Proper vehicle maintenance, including regular tune-ups and proper tire inflation, can improve fuel efficiency and reduce emissions.',
            title: 'Vehicle Maintenance for Efficiency',
            displayOrder: 2
          },
          {
            contentType: 'link',
            content: 'https://www.example.com/eco-driving-tips',
            title: 'More Eco-Driving Tips',
            displayOrder: 3
          }
        ]
      },
      {
        title: 'Night Driving and Adverse Weather',
        description: 'Master the skills needed for safe driving at night and in adverse weather conditions. Learn about visibility, weather hazards, and safe driving practices.',
        category: 'Safety',
        difficulty: 'HARD',
        courseType: 'paid',
        courseImageUrl: 'course10.png',
        isActive: true,
        contents: [
          {
            contentType: 'text',
            content: 'Driving at night requires extra caution due to reduced visibility. Always ensure your headlights are working properly and use them correctly.',
            title: 'Night Driving Basics',
            displayOrder: 0
          },
          {
            contentType: 'text',
            content: 'Adverse weather conditions such as rain, fog, snow, and ice require special driving techniques. Reduce speed, increase following distance, and use appropriate lights.',
            title: 'Weather Hazards',
            displayOrder: 1
          },
          {
            contentType: 'video',
            content: 'rain-driving.mp4',
            title: 'Driving in Rain',
            displayOrder: 2
          },
          {
            contentType: 'video',
            content: 'snow-driving.mp4',
            title: 'Driving in Snow',
            displayOrder: 3
          },
          {
            contentType: 'text',
            content: 'In severe weather conditions, it may be safest to delay your trip or find alternative transportation. Never drive if conditions are too dangerous.',
            title: 'When Not to Drive',
            displayOrder: 4
          }
        ]
      },
      {
        title: 'Motorcycle and Bicycle Safety',
        description: 'Learn about sharing the road with motorcycles and bicycles. Understand the unique challenges and safety considerations for two-wheeled vehicles.',
        category: 'Safety',
        difficulty: 'MEDIUM',
        courseType: 'free',
        courseImageUrl: 'course11.png',
        isActive: true,
        contents: [
          {
            contentType: 'text',
            content: 'Motorcycles and bicycles are more vulnerable on the road and require special consideration from all drivers. Understanding their needs helps prevent accidents.',
            title: 'Sharing the Road',
            displayOrder: 0
          },
          {
            contentType: 'text',
            content: 'Motorcycles are smaller and harder to see. Always check blind spots carefully and give motorcycles extra space when passing or changing lanes.',
            title: 'Motorcycle Awareness',
            displayOrder: 1
          },
          {
            contentType: 'text',
            content: 'Bicycles have the right to share the road with motor vehicles. Give cyclists at least 3 feet of space when passing, and never pass too closely.',
            title: 'Bicycle Safety',
            displayOrder: 2
          },
          {
            contentType: 'image',
            content: 'bicycle-lane.png',
            title: 'Bicycle Lanes and Paths',
            displayOrder: 3
          }
        ]
      },
      {
        title: 'Advanced Intersection Navigation',
        description: 'Master the art of navigating complex intersections safely. Learn about roundabouts, multi-lane intersections, and traffic flow management.',
        category: 'Traffic Rules',
        difficulty: 'HARD',
        courseType: 'paid',
        courseImageUrl: 'course12.png',
        isActive: true,
        contents: [
          {
            contentType: 'text',
            content: 'Intersections are among the most dangerous areas on the road. Understanding how to navigate them safely is crucial for preventing accidents.',
            title: 'Intersection Safety',
            displayOrder: 0
          },
          {
            contentType: 'text',
            content: 'Roundabouts require understanding of yield rules and lane positioning. Always yield to traffic already in the roundabout and use proper signals.',
            title: 'Roundabout Navigation',
            displayOrder: 1
          },
          {
            contentType: 'video',
            content: 'roundabout-navigation.mp4',
            title: 'How to Navigate Roundabouts',
            displayOrder: 2
          },
          {
            contentType: 'text',
            content: 'Multi-lane intersections require careful lane selection and positioning. Choose your lane early and maintain it through the intersection.',
            title: 'Multi-Lane Intersections',
            displayOrder: 3
          },
          {
            contentType: 'text',
            content: 'Always be cautious at intersections, even when you have the right-of-way. Watch for drivers who may not yield or who may be distracted.',
            title: 'Defensive Intersection Driving',
            displayOrder: 4
          }
        ]
      }
    ];

    for (const courseData of courses) {
      const { contents, ...courseFields } = courseData;
      
      const [course, created] = await Course.findOrCreate({
        where: { title: courseFields.title },
        defaults: courseFields
      });
      
      // Only create contents if course was just created
      if (created && contents && contents.length > 0) {
        // Check if contents already exist
        const existingContentCount = await CourseContent.count({
          where: { courseId: course.id }
        });
        
        if (existingContentCount === 0) {
          // Create course contents only if none exist
          for (const contentData of contents) {
            await CourseContent.findOrCreate({
              where: {
                courseId: course.id,
                contentType: contentData.contentType,
                content: contentData.content,
                displayOrder: contentData.displayOrder
              },
              defaults: {
                id: uuidv4(),
                courseId: course.id,
                contentType: contentData.contentType,
                content: contentData.content,
                title: contentData.title || null,
                displayOrder: contentData.displayOrder
              }
            });
          }
          console.log(`✅ Course "${courseFields.title}" created with ${contents.length} content items`);
        } else {
          console.log(`⚠️  Course "${courseFields.title}" already has ${existingContentCount} content items, skipping content creation`);
        }
      } else if (!created) {
        console.log(`⚠️  Course "${courseFields.title}" already exists, skipping`);
      }
    }
    
    console.log('✅ Courses seeded successfully');
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
      await CourseContent.destroy({ where: {} });
      await Course.destroy({ where: {} });
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
