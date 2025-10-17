# Force Database Sync Deployment

## Temporary Fix for Table Creation

To force database table creation on Render, add this environment variable:

```
FORCE_SYNC=true
```

## Steps:

1. Go to your Render service settings
2. Add environment variable: `FORCE_SYNC=true`
3. Redeploy your service
4. After successful deployment, remove the `FORCE_SYNC=true` variable
5. Redeploy again (this will use normal sync)

## What this does:

- `FORCE_SYNC=true` will drop and recreate all tables
- This ensures all tables are created properly
- After tables are created, remove the variable for normal operation

## Expected Logs:

```
🔄 Starting database table initialization...
✅ All models imported successfully
✅ Model associations set up
🔄 Force syncing database to apply new structure...
✅ Database tables recreated with new structure
📋 Created tables: ['Users', 'Exams', 'PaymentRequests', 'AccessCodes', 'Questions', 'ExamResults', 'Notifications', 'StudyReminders', 'NotificationPreferences']
```
