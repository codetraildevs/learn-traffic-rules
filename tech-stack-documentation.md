# Traffic Rules Practice App - Technology Stack Documentation

## Overview
This document outlines the complete technology stack for the Traffic Rules Practice App, including backend and frontend technologies, architecture, and integration details.

## Backend Technology Stack

### **Core Backend: Node.js + Express.js**

#### **Node.js**
- **Runtime Environment**: JavaScript runtime built on Chrome's V8 engine
- **Architecture**: Event-driven, non-blocking I/O
- **Performance**: Excellent for handling concurrent connections
- **Ecosystem**: Largest package ecosystem (npm)

#### **Express.js**
- **Framework**: Minimalist web framework for Node.js
- **Features**: Fast, unopinionated, flexible
- **Middleware**: Extensive middleware support
- **Routing**: Simple and powerful routing system

### **Backend Architecture Components**

#### **1. Authentication & Security**
```javascript
// JWT Authentication Example
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

// Device ID validation middleware
const validateDevice = (req, res, next) => {
  const deviceId = req.headers['device-id'];
  // Validate device binding logic
  next();
};
```

**Technologies:**
- **JWT (JSON Web Tokens)**: For secure authentication
- **bcrypt**: For password hashing
- **Passport.js**: Authentication middleware
- **Helmet.js**: Security headers
- **Rate Limiting**: API protection

#### **2. Database Layer**
```javascript
// Prisma ORM Example
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// User registration with device binding
const createUser = async (userData, deviceId) => {
  return await prisma.user.create({
    data: {
      ...userData,
      deviceId: deviceId,
      isActive: true
    }
  });
};
```

**Technologies:**
- **PostgreSQL**: Primary database
- **Prisma ORM**: Type-safe database access
- **Redis**: Caching and session storage
- **Database Migrations**: Version control for schema

#### **3. Payment Processing**
```javascript
// Manual payment request handling
app.post('/api/payment/request', async (req, res) => {
  const { userId, examId, paymentMethod, amount } = req.body;
  
  // Create payment request
  const paymentRequest = await prisma.paymentRequest.create({
    data: {
      userId,
      examId,
      amount,
      status: 'PENDING',
      paymentMethod
    }
  });
  
  // Notify manager
  await notifyManager(paymentRequest);
  
  res.json({ requestId: paymentRequest.id, instructions: getPaymentInstructions() });
});
```

**Technologies:**
- **Custom Payment API**: Manual payment processing
- **Payment Request Management**: Database tracking
- **Manager Notification System**: Real-time alerts

#### **4. Access Code System**
```javascript
// Access code generation and validation
const generateAccessCode = async (userId, examId) => {
  const accessCode = crypto.randomBytes(8).toString('hex').toUpperCase();
  
  await prisma.accessCode.create({
    data: {
      code: accessCode,
      userId,
      examId,
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      isUsed: false
    }
  });
  
  return accessCode;
};
```

#### **5. Real-time Features**
```javascript
// Socket.io for real-time communication
const io = require('socket.io')(server);

io.on('connection', (socket) => {
  socket.on('exam-progress', (data) => {
    // Track exam progress in real-time
    socket.broadcast.emit('manager-update', data);
  });
});
```

**Technologies:**
- **Socket.io**: Real-time bidirectional communication
- **WebSocket**: For live updates
- **Event Emitters**: Internal communication

### **Backend Project Structure**
```
backend/
├── src/
│   ├── controllers/          # Route handlers
│   ├── middleware/           # Custom middleware
│   ├── models/              # Database models (Prisma)
│   ├── routes/              # API routes
│   ├── services/             # Business logic
│   ├── utils/                # Helper functions
│   └── config/               # Configuration files
├── prisma/
│   ├── schema.prisma         # Database schema
│   └── migrations/           # Database migrations
├── tests/                    # Test files
├── package.json
└── server.js                 # Entry point
```

## Frontend Technology Stack

### **Core Frontend: Flutter**

#### **Flutter**
- **Framework**: Google's UI toolkit for building natively compiled applications
- **Language**: Dart programming language
- **Platforms**: iOS, Android, Web, Desktop
- **Performance**: Native performance with hot reload
- **UI**: Material Design and Cupertino widgets

### **Flutter Architecture Components**

#### **1. State Management**
```dart
// Provider pattern for state management
class UserProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  
  Future<void> registerUser(UserRegistrationData data) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _user = await AuthService.register(data);
      notifyListeners();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

**Technologies:**
- **Provider**: State management
- **Riverpod**: Alternative state management
- **Bloc**: Business logic component
- **GetX**: All-in-one solution

#### **2. HTTP Client & API Integration**
```dart
// Dio HTTP client configuration
class ApiService {
  static final Dio _dio = Dio();
  
  static void init() {
    _dio.options.baseUrl = 'https://your-api.com/api';
    _dio.options.connectTimeout = 5000;
    _dio.options.receiveTimeout = 3000;
    
    // Add device ID to all requests
    _dio.interceptors.add(DeviceIdInterceptor());
  }
  
  static Future<Response> post(String path, dynamic data) async {
    return await _dio.post(path, data: data);
  }
}

// Device ID interceptor
class DeviceIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['device-id'] = DeviceInfoService.getDeviceId();
    super.onRequest(options, handler);
  }
}
```

**Technologies:**
- **Dio**: HTTP client
- **HTTP**: Alternative HTTP client
- **Retrofit**: Type-safe HTTP client
- **Connectivity**: Network status

#### **3. Local Storage**
```dart
// SharedPreferences for local storage
class LocalStorageService {
  static const String _userTokenKey = 'user_token';
  static const String _deviceIdKey = 'device_id';
  
  static Future<void> saveUserToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTokenKey, token);
  }
  
  static Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTokenKey);
  }
}
```

**Technologies:**
- **SharedPreferences**: Key-value storage
- **Hive**: Lightweight database
- **SQLite**: Local database
- **Secure Storage**: Encrypted storage

#### **4. Device Information**
```dart
// Device info service
class DeviceInfoService {
  static String? _deviceId;
  
  static Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    
    _deviceId = androidInfo.id;
    return _deviceId!;
  }
}
```

**Technologies:**
- **device_info_plus**: Device information
- **platform**: Platform detection
- **uuid**: Unique identifier generation

### **Flutter Project Structure**
```
lib/
├── main.dart                 # App entry point
├── app/
│   ├── app.dart             # Main app widget
│   └── routes.dart           # Route definitions
├── core/
│   ├── constants/           # App constants
│   ├── errors/              # Error handling
│   ├── network/             # Network configuration
│   └── utils/               # Utility functions
├── features/
│   ├── auth/                # Authentication feature
│   │   ├── data/            # Data layer
│   │   ├── domain/           # Business logic
│   │   └── presentation/     # UI layer
│   ├── exams/                # Exams feature
│   ├── payments/             # Payment feature
│   └── profile/              # User profile feature
├── shared/
│   ├── widgets/              # Reusable widgets
│   ├── services/             # Shared services
│   └── models/               # Data models
└── test/                     # Test files
```

## Backend-Frontend Integration

### **API Communication**

#### **1. RESTful API Design**
```javascript
// Backend API Routes
app.use('/api/auth', authRoutes);
app.use('/api/exams', examRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/users', userRoutes);

// Example: User registration endpoint
app.post('/api/auth/register', validateDevice, async (req, res) => {
  try {
    const user = await UserService.createUser(req.body);
    const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET);
    
    res.json({
      success: true,
      user: user,
      token: token
    });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});
```

```dart
// Flutter API Service
class AuthService {
  static Future<AuthResponse> register(UserRegistrationData data) async {
    try {
      final response = await ApiService.post('/auth/register', data.toJson());
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      throw ApiException('Registration failed: ${e.toString()}');
    }
  }
}
```

#### **2. Real-time Communication**
```javascript
// Backend Socket.io events
io.on('connection', (socket) => {
  socket.on('join-exam', (examId) => {
    socket.join(`exam-${examId}`);
  });
  
  socket.on('exam-progress', (data) => {
    socket.to(`exam-${data.examId}`).emit('progress-update', data);
  });
});
```

```dart
// Flutter Socket.io client
class SocketService {
  static late Socket socket;
  
  static void connect() {
    socket = io('https://your-api.com', {
      'transports': ['websocket'],
      'autoConnect': false,
    });
    
    socket.connect();
    
    socket.on('progress-update', (data) {
      // Handle real-time updates
    });
  }
}
```

### **Data Models**

#### **Backend Models (Prisma Schema)**
```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  deviceId  String   @unique
  role      UserRole @default(USER)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  exams     UserExam[]
  payments  PaymentRequest[]
}

model Exam {
  id          String   @id @default(cuid())
  title       String
  description String?
  questions   Question[]
  accessCodes AccessCode[]
}

model PaymentRequest {
  id          String   @id @default(cuid())
  userId      String
  examId      String
  amount      Float
  status      PaymentStatus @default(PENDING)
  createdAt   DateTime @default(now())
  
  user        User     @relation(fields: [userId], references: [id])
  exam        Exam     @relation(fields: [examId], references: [id])
}
```

#### **Flutter Models**
```dart
// User model
class User {
  final String id;
  final String email;
  final String deviceId;
  final UserRole role;
  final DateTime createdAt;
  
  User({
    required this.id,
    required this.email,
    required this.deviceId,
    required this.role,
    required this.createdAt,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      deviceId: json['deviceId'],
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
```

## Development Workflow

### **1. Development Environment Setup**

#### **Backend Setup**
```bash
# Initialize Node.js project
npm init -y

# Install dependencies
npm install express prisma @prisma/client bcryptjs jsonwebtoken socket.io cors helmet
npm install -D nodemon

# Setup Prisma
npx prisma init
npx prisma migrate dev
```

#### **Flutter Setup**
```bash
# Create Flutter project
flutter create traffic_rules_app

# Add dependencies to pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.3.2
  provider: ^6.0.5
  shared_preferences: ^2.2.2
  device_info_plus: ^9.1.0
  socket_io_client: ^2.0.3
```

### **2. API Testing**
```javascript
// Backend API testing with Jest
describe('User Registration', () => {
  test('should register user with device ID', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'test@example.com',
        password: 'password123',
        deviceId: 'device123'
      });
    
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
  });
});
```

```dart
// Flutter widget testing
testWidgets('User registration form', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password_field')), 'password123');
  
  await tester.tap(find.byKey(Key('register_button')));
  await tester.pump();
  
  expect(find.text('Registration successful'), findsOneWidget);
});
```

## Deployment & Production

### **Backend Deployment**
- **Platform**: AWS EC2, Google Cloud, or DigitalOcean
- **Process Manager**: PM2
- **Database**: PostgreSQL on cloud (AWS RDS, Google Cloud SQL)
- **CDN**: CloudFront or CloudFlare
- **Monitoring**: New Relic or DataDog

### **Flutter Deployment**
- **Android**: Google Play Store
- **iOS**: Apple App Store
- **Web**: Firebase Hosting or Netlify
- **CI/CD**: GitHub Actions or GitLab CI

## Security Considerations

### **Backend Security**
- JWT token expiration and refresh
- Rate limiting on API endpoints
- Input validation and sanitization
- HTTPS enforcement
- Device ID encryption

### **Flutter Security**
- Secure local storage for sensitive data
- Certificate pinning for API calls
- Code obfuscation for production
- Root/jailbreak detection

## Performance Optimization

### **Backend Optimization**
- Database indexing
- Redis caching
- Connection pooling
- API response compression

### **Flutter Optimization**
- Image caching and optimization
- Lazy loading for large lists
- State management optimization
- Memory leak prevention

## Conclusion

The Node.js + Express.js backend with Flutter frontend provides:

1. **Excellent Performance**: Both technologies are known for high performance
2. **Rapid Development**: Fast development cycles with hot reload
3. **Scalability**: Can handle growing user base efficiently
4. **Cross-platform**: Flutter provides native performance on multiple platforms
5. **Rich Ecosystem**: Extensive libraries and packages available
6. **Real-time Features**: Perfect for your app's requirements
7. **Security**: Strong security features for device binding and payment processing

This technology stack is ideal for your traffic rules practice app and will support all the features you've outlined in your system requirements.
