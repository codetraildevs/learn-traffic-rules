# Drive Rwanda – Prep & Pass

A driving exam prep application for Rwanda with role-based access control and manual payment system.

## 🏗️ Architecture

### Backend (Node.js + Express.js)
- **Framework**: Express.js
- **Database**: MySQL with Sequelize ORM
- **Authentication**: JWT with device ID validation
- **Security**: Helmet, Rate Limiting, bcrypt
- **Documentation**: Swagger/OpenAPI
- **File Upload**: Multer for CSV/JSON imports

### Frontend (Flutter)
- **Framework**: Flutter
- **Platform**: Cross-platform (iOS, Android)
- **State Management**: Provider/Riverpod
- **UI**: Material Design 3

## 🚀 Features

### 👥 User Management
- **Role-based Access**: ADMIN, MANAGER, USER
- **Device ID Validation**: One account per device
- **User Registration**: Full name, phone number, device ID
- **Password Reset**: 6-digit code via SMS
- **Account Deletion**: With password verification

### 📚 Exam System
- **Multiple Exams**: Traffic signs, road rules, vehicle regulations
- **Question Types**: Multiple choice with images
- **Difficulty Levels**: Easy, Medium, Hard
- **Time Limits**: Configurable per exam
- **Passing Scores**: Customizable thresholds

### 💳 Payment System
- **Manual Payment**: Users request access, pay manually
- **Manager Approval**: Managers approve payments
- **Access Codes**: Auto-generated for approved payments
- **Global Access**: Pay once, access all exams

### 📊 Progress Tracking
- **Exam Results**: Score, time spent, answers
- **Performance Analytics**: User progress tracking
- **History**: Complete exam attempt history

### 🔧 Admin Features
- **Bulk Upload**: CSV and JSON question imports
- **Exam Management**: Create, update, delete exams
- **User Management**: View, activate/deactivate users
- **Payment Management**: Approve/reject payment requests

## 🛠️ Installation & Setup

### Prerequisites
- Node.js (v16 or higher)
- MySQL (v8.0 or higher)
- Flutter SDK (for frontend)

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd <repo>/backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment Configuration**
   ```bash
   cp .env.example .env
   ```
   
   Update `.env` with your database credentials:
   ```env
   DB_HOST=localhost
   DB_PORT=3306
   DB_NAME=rw_driving_prep_db
   DB_USER=root
   DB_PASSWORD=your_password
   JWT_SECRET=your_jwt_secret
   JWT_EXPIRES_IN=7d
   JWT_REFRESH_EXPIRES_IN=30d
   BCRYPT_ROUNDS=12
   NODE_ENV=development
   PORT=3000
   ```

4. **Database Setup**
   ```bash
   # Create database
   mysql -u root -p
   CREATE DATABASE rw_driving_prep_db;
   ```

5. **Run the application**
   ```bash
   # Development mode
   npm run dev
   
   # Production mode
   npm start
   ```

6. **Seed the database**
   ```bash
   npm run seed
   ```

### API Documentation
- **Swagger UI**: http://localhost:3000/api-docs
- **Health Check**: http://localhost:3000/health

## 🧪 Testing Credentials

### Admin User
- **Device ID**: admin-device-123456789
- **Password**: password123
- **Role**: ADMIN

### Manager User
- **Device ID**: manager-device-123456789
- **Password**: password123
- **Role**: MANAGER

### Regular Users
- **Device ID**: user-device-123456789
- **Password**: password123
- **Role**: USER

## 📁 Project Structure

```
<repo>/
├── backend/
│   ├── src/
│   │   ├── config/
│   │   │   ├── database.js
│   │   │   ├── associations.js
│   │   │   └── seeders.js
│   │   ├── controllers/
│   │   │   ├── authController.js
│   │   │   ├── examController.js
│   │   │   ├── paymentController.js
│   │   │   ├── questionController.js
│   │   │   └── bulkUploadController.js
│   │   ├── middleware/
│   │   │   ├── authMiddleware.js
│   │   │   └── deviceMiddleware.js
│   │   ├── models/
│   │   │   ├── User.js
│   │   │   ├── Exam.js
│   │   │   ├── Question.js
│   │   │   ├── PaymentRequest.js
│   │   │   ├── AccessCode.js
│   │   │   └── ExamResult.js
│   │   ├── routes/
│   │   │   ├── auth.js
│   │   │   ├── exams.js
│   │   │   ├── payments.js
│   │   │   ├── questions.js
│   │   │   └── bulkUpload.js
│   │   └── services/
│   │       ├── authService.js
│   │       └── deviceService.js
│   ├── uploads/
│   ├── package.json
│   ├── server.js
│   └── seed.js
├── frontend/ (Flutter app - coming soon)
├── .gitignore
└── README.md
```

## 🔧 Available Scripts

### Backend Scripts
```bash
npm start          # Start production server
npm run dev        # Start development server with nodemon
npm run seed       # Seed database with sample data
npm run seed:clear # Clear all seeded data
npm run seed:fresh # Clear and re-seed data
```

## 🚀 API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `POST /api/auth/refresh-token` - Refresh access token
- `POST /api/auth/forgot-password` - Request password reset
- `POST /api/auth/reset-password` - Reset password with code
- `DELETE /api/auth/delete-account` - Delete user account

### Exams
- `GET /api/exams` - Get all exams
- `GET /api/exams/:id` - Get exam by ID
- `GET /api/exams/:id/questions` - Get exam questions
- `POST /api/exams` - Create new exam (Admin/Manager)
- `PUT /api/exams/:id` - Update exam (Admin/Manager)
- `DELETE /api/exams/:id` - Delete exam (Admin/Manager)
- `POST /api/exams/:id/questions` - Add questions to exam

### Payments
- `POST /api/payments/request` - Request payment access
- `GET /api/payments/requests` - Get payment requests (Manager/Admin)
- `PUT /api/payments/requests/:id/approve` - Approve payment (Manager/Admin)
- `PUT /api/payments/requests/:id/reject` - Reject payment (Manager/Admin)
- `GET /api/payments/access-codes` - Get access codes (Manager/Admin)

### Questions
- `GET /api/questions` - Get all questions
- `GET /api/questions/:id` - Get question by ID
- `POST /api/questions` - Create question (Admin/Manager)
- `PUT /api/questions/:id` - Update question (Admin/Manager)
- `DELETE /api/questions/:id` - Delete question (Admin/Manager)

### Bulk Upload
- `POST /api/bulk-upload/questions/csv` - Upload questions via CSV
- `POST /api/bulk-upload/questions/json` - Upload questions via JSON
- `GET /api/bulk-upload/template/csv` - Download CSV template
- `GET /api/bulk-upload/template/json` - Download JSON template

## 🔒 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Device ID Validation**: One account per device
- **Password Hashing**: bcrypt with configurable rounds
- **Rate Limiting**: API request rate limiting
- **Security Headers**: Helmet for security headers
- **Input Validation**: Express-validator for request validation
- **CORS**: Cross-origin resource sharing configuration

## 📱 Mobile App Features (Coming Soon)

- **Cross-platform**: iOS and Android support
- **Offline Support**: Download exams for offline practice
- **Progress Sync**: Real-time progress synchronization
- **Push Notifications**: Exam reminders and updates
- **Dark Mode**: Theme customization
- **Accessibility**: Screen reader support

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support, email the address listed in the app (Settings / Legal) or open an issue in the repository.

## 🎯 Roadmap

- [ ] Flutter frontend development
- [ ] SMS integration for password reset
- [ ] Push notifications
- [ ] Offline exam support
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Voice-guided questions
- [ ] Social features (leaderboards, achievements)

---

**Happy Learning! 🚗📚**
