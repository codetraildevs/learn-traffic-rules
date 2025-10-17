# Render Deployment Guide

## Database Connection Issues Fix

The current deployment is failing because the database connection is not properly configured. Here's how to fix it:

### 1. Create PostgreSQL Database on Render

1. Go to your Render dashboard
2. Click "New +" → "PostgreSQL"
3. Create a new PostgreSQL database
4. Note down the connection details

### 2. Set Environment Variables

In your Render service settings, add these environment variables:

```
NODE_ENV=production
PORT=10000
JWT_SECRET=your-super-secret-jwt-key-here-make-it-long-and-random
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d
DATABASE_URL=postgresql://username:password@hostname:port/database_name
FRONTEND_URL=https://your-frontend-domain.com
BCRYPT_ROUNDS=12
```

### 3. Database URL Format

The `DATABASE_URL` should look like:
```
postgresql://username:password@hostname:port/database_name
```

Example:
```
postgresql://traffic_rules_user:password123@dpg-abc123-a.oregon-postgres.render.com:5432/traffic_rules_db
```

### 4. Alternative: Individual Database Variables

If `DATABASE_URL` doesn't work, use individual variables:

```
DB_NAME=traffic_rules_db
DB_USER=your_postgres_username
DB_PASSWORD=your_postgres_password
DB_HOST=your_postgres_host
DB_PORT=5432
```

### 5. Deploy and Test

1. Save the environment variables
2. Redeploy your service
3. Check the logs for database connection status
4. Test the health endpoint: `https://your-app.onrender.com/health`

### 6. Troubleshooting

If you still get connection errors:

1. **Check database status**: Ensure the PostgreSQL database is running
2. **Verify credentials**: Double-check username, password, and database name
3. **Check network**: Ensure the database is accessible from Render
4. **SSL settings**: The code automatically handles SSL for production

### 7. Expected Logs

After fixing, you should see:
```
🔍 Environment check: { NODE_ENV: 'production', isProduction: true, hasDatabaseUrl: true, databaseUrl: 'SET' }
🐘 Using PostgreSQL configuration for production
✅ Database connected successfully
✅ Database tables synchronized successfully
🔑 DEFAULT ADMIN CREATED:
   Username: admin123
   Password: admin123
```

### 8. Health Check

Test your deployment:
```bash
curl https://your-app.onrender.com/health
```

Should return:
```json
{
  "success": true,
  "message": "Server is running",
  "timestamp": "2025-01-28T07:27:00.000Z",
  "uptime": 123.456
}
```



traffic_rules_db_user