# 🚀 Render Deployment Guide

## 📋 **Prerequisites**
- GitHub repository with backend code
- Render account (free tier available)
- PostgreSQL database (provided by Render)

## 🔧 **Deployment Steps**

### **1. Connect Repository to Render**
1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click **"New +"** → **"Web Service"**
3. Connect your GitHub repository
4. Select the `backend` folder as the root directory

### **2. Configure Environment Variables**
In Render dashboard, add these environment variables:

```bash
# Required
NODE_ENV=production
PORT=10000
JWT_SECRET=your-super-secret-jwt-key-here
JWT_EXPIRES_IN=7d
JWT_REFRESH_EXPIRES_IN=30d
BCRYPT_ROUNDS=12

# Optional (with defaults)
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
MAX_FILE_SIZE=10485760
UPLOAD_PATH=./uploads
SWAGGER_TITLE=Traffic Rules Practice App API
SWAGGER_VERSION=1.0.0
SWAGGER_DESCRIPTION=API documentation for Traffic Rules Practice App
```

### **3. Create PostgreSQL Database**
1. In Render dashboard, click **"New +"** → **"PostgreSQL"**
2. Choose **"Free"** plan
3. Name: `traffic-rules-postgres`
4. Copy the **DATABASE_URL** (automatically set as environment variable)

### **4. Deploy Configuration**
- **Build Command**: `npm install`
- **Start Command**: `npm start`
- **Node Version**: `18.x` (or latest LTS)

### **5. Automatic Database Setup**
The app will automatically:
- ✅ Connect to PostgreSQL database
- ✅ Create all tables and relationships
- ✅ Seed initial data (users, exams, questions)
- ✅ Start the API server

## 🌐 **API Endpoints**

Once deployed, your API will be available at:
```
https://your-app-name.onrender.com
```

### **Key Endpoints:**
- **API Documentation**: `https://your-app-name.onrender.com/api-docs`
- **Health Check**: `https://your-app-name.onrender.com/api/health`
- **Authentication**: `https://your-app-name.onrender.com/api/auth/login`

## 🔐 **Default Admin Credentials**

After deployment, use these credentials to test:

```json
{
  "phoneNumber": "admin@trafficrules.com",
  "password": "admin123",
  "deviceId": "admin-device-001"
}
```

## 📊 **Database Features**

### **Development (MySQL)**
- Local development with MySQL
- Hot reloading with nodemon
- Detailed logging

### **Production (PostgreSQL)**
- SSL-enabled PostgreSQL connection
- Optimized connection pooling
- Automatic migrations and seeding

## 🛠 **Troubleshooting**

### **Common Issues:**

1. **Database Connection Failed**
   - Check if PostgreSQL service is running
   - Verify DATABASE_URL environment variable

2. **Build Failed**
   - Ensure Node.js version is 18.x or higher
   - Check if all dependencies are in package.json

3. **Seeding Failed**
   - Check database permissions
   - Verify table creation completed

### **Logs Access:**
- View logs in Render dashboard
- Check build logs for deployment issues
- Monitor runtime logs for errors

## 🔄 **Updates and Maintenance**

### **Redeploy:**
- Push changes to GitHub
- Render automatically redeploys
- Database migrations run automatically

### **Database Backup:**
- Render provides automatic backups
- Export data via Render dashboard
- Use `pg_dump` for manual backups

## 📈 **Scaling**

### **Free Tier Limits:**
- 750 hours/month
- Sleeps after 15 minutes of inactivity
- Cold start takes ~30 seconds

### **Upgrade Options:**
- **Starter Plan**: $7/month (always-on)
- **Standard Plan**: $25/month (better performance)
- **Pro Plan**: $85/month (production-ready)

## 🎯 **Next Steps**

1. **Deploy to Render** using this guide
2. **Update frontend** API endpoints to use Render URL
3. **Test all endpoints** with Postman/Thunder Client
4. **Set up monitoring** and alerts
5. **Configure custom domain** (optional)

---

## 📞 **Support**

For deployment issues:
- Check Render documentation
- Review application logs
- Test locally first
- Contact support if needed

**Happy Deploying! 🚀**
