# Drive Rwanda Prep - Backend API

Node.js + Express backend API for Drive Rwanda – Prep & Pass with MySQL database.

## Features

- ✅ User authentication with device ID validation
- ✅ JWT token-based authentication
- ✅ MySQL database integration
- ✅ Swagger API documentation
- ✅ Device binding security
- ✅ Manual payment processing
- ✅ Manager onboarding notifications

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Database Setup

1. Install MySQL on your system
2. Create a database named `rw_driving_prep_db` (or value from env)
3. Update the database credentials in `.env` file

### 3. Environment Configuration

Copy `env.example` to `.env` and update the values:

```bash
cp env.example .env
```

Update the following values in `.env`:
- `DB_HOST`: MySQL host (default: localhost)
- `DB_USER`: MySQL username (default: root)
- `DB_PASSWORD`: MySQL password
- `DB_NAME`: Database name (e.g. rw_driving_prep_db)
- `JWT_SECRET`: Your secret key for JWT tokens

### 4. Seed the Database (Optional)

```bash
# Seed database with sample data
npm run seed

# Clear all seeded data
npm run seed:clear

# Clear and re-seed data
npm run seed:fresh
```

### 5. Start the Server

```bash
# Development mode with auto-restart
npm run dev

# Production mode
npm start
```

The server will start on `http://localhost:3000`

## API Documentation

Once the server is running, visit:
- **Swagger UI**: `http://localhost:3000/api-docs`
- **Health Check**: `http://localhost:3000/health`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user

### Headers Required
All API requests require:
- `Content-Type: application/json`
- `device-id: your-device-id` (for device validation)

## Database Schema

The API automatically creates the following tables:
- `users` - User accounts with device binding
- `exams` - Exam information
- `payment_requests` - Manual payment requests
- `access_codes` - Generated access codes
- `questions` - Exam questions
- `exam_results` - User exam results

## Testing with Swagger

1. Open `http://localhost:3000/api-docs`
2. Use the "Try it out" feature to test endpoints
3. For authentication endpoints, include `device-id` header
4. Copy the JWT token from login response for authenticated requests

## Example API Usage

### Register User
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "password": "password123",
    "fullName": "John Doe",
    "phoneNumber": "+1234567890",
    "deviceId": "device123456789",
    "role": "USER"
  }'
```

### Login User
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "password": "password123",
    "deviceId": "device123456789"
  }'
```

## Sample Data

After running the seeder, you'll have:

### Users
- **Admin**: `admin-device-123456789` (password: `password123`)
- **Manager**: `manager-device-123456789` (password: `password123`)
- **Users**: `user-device-123456789`, `user-device-123456790` (password: `password123`)

### Exams
- Basic Traffic Signs (Easy, 15 questions, 20 min)
- Road Rules and Regulations (Medium, 25 questions, 30 min)
- Advanced Driving Scenarios (Hard, 30 questions, 45 min)
- Highway Driving Rules (Medium, 20 questions, 25 min)
- Parking and Maneuvering (Easy, 12 questions, 15 min) - Inactive

### Payment Model
- **Single Payment**: Pay once to unlock all exams
- **Price**: Set by frontend (recommended: $25 for all exams)
- **Access**: Global access code unlocks all active exams

## Development Notes

- The code is simplified for development purposes
- Device ID validation is basic but functional
- MySQL database is used instead of PostgreSQL
- All services use simple MySQL queries
- Swagger documentation is comprehensive for testing

## Next Steps

1. Test the authentication endpoints
2. Add exam management endpoints
3. Add payment processing endpoints
4. Add user management endpoints
5. Integrate with Flutter frontend
