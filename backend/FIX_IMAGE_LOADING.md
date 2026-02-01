# 🔧 Fix Image Loading Errors - "Connection closed while receiving data"

## Problem

Images are failing to load with error:
```
❌ Connection closed while receiving data, uri = https://traffic.cyangugudims.com/uploads/images/...
```

**Root Cause**: Nginx is not properly configured to serve static image files. The connection times out or gets closed while transferring larger files.

## Solution

Update your Nginx configuration on the VPS to properly serve static files with correct timeouts and buffering.

## 🚀 Deployment Steps

### 1. Backup Current Config

```bash
# SSH to your VPS
ssh root@your-vps-ip

# Backup existing nginx config
sudo cp /etc/nginx/sites-available/traffic /etc/nginx/sites-available/traffic.backup
```

### 2. Update Nginx Config

```bash
# Edit the nginx config
sudo nano /etc/nginx/sites-available/traffic
```

Replace the content with the configuration from `nginx-config-vps.conf` file in this directory.

**Key Changes:**
- ✅ Increased timeouts: `60s` for `proxy_read_timeout`, `proxy_send_timeout`, `send_timeout`
- ✅ Proper buffer sizes: `proxy_buffers 8 16k`
- ✅ Direct file serving for `/uploads/` (no proxy)
- ✅ `sendfile on` for efficient static file serving
- ✅ Proper `keepalive` settings
- ✅ CORS headers for images

### 3. Test Nginx Config

```bash
# Test for syntax errors
sudo nginx -t
```

You should see:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

### 4. Reload Nginx

```bash
# Reload nginx (no downtime)
sudo systemctl reload nginx

# Or restart if reload doesn't work
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx
```

### 5. Verify File Permissions

```bash
# Ensure nginx can read the upload directory
cd /var/www/learn-traffic-rules

# Check if uploads directory exists
ls -la uploads/

# Fix permissions if needed
sudo chown -R www-data:www-data uploads/
sudo chmod -R 755 uploads/

# Verify specific image directories
ls -la uploads/images/
ls -la uploads/images-exams/
```

### 6. Test Image Loading

```bash
# Test image download directly
curl -I https://traffic.cyangugudims.com/uploads/images/official_roads_signs.png

# Should return 200 OK with proper headers
# HTTP/2 200
# content-type: image/png
# cache-control: public, immutable
# expires: ...
```

### 7. Monitor Nginx Logs

```bash
# Watch nginx error log for issues
sudo tail -f /var/log/nginx/traffic-error.log

# In another terminal, watch access log
sudo tail -f /var/log/nginx/traffic-access.log
```

## 🔍 Troubleshooting

### Issue 1: 404 Not Found for Images

**Problem**: Images return 404

**Solution**:
```bash
# Check if files exist
ls -la /var/www/learn-traffic-rules/uploads/images/

# Check nginx error log
sudo tail -50 /var/log/nginx/traffic-error.log

# Verify the alias path in nginx config matches actual directory
```

### Issue 2: Permission Denied

**Problem**: Nginx logs show "Permission denied"

**Solution**:
```bash
# Fix ownership
sudo chown -R www-data:www-data /var/www/learn-traffic-rules/uploads/

# Fix permissions
sudo chmod -R 755 /var/www/learn-traffic-rules/uploads/

# Check SELinux (if enabled)
sudo setenforce 0  # Temporary - for testing only
```

### Issue 3: Still Timing Out

**Problem**: Images still timeout after 60s

**Solution**:
```bash
# Check PM2 backend logs
pm2 logs backend --lines 50

# If backend is serving images (it shouldn't be), ensure nginx is serving directly
# Verify nginx config has:
# location /uploads/ { alias /var/www/.../uploads/; }

# Restart PM2 backend
pm2 restart all
```

### Issue 4: Mixed Content Error

**Problem**: HTTP/HTTPS mixed content

**Solution**: Ensure all image URLs use HTTPS:
```bash
# Check database for HTTP URLs
mysql -u your_user -p your_database
SELECT id, title, examImgUrl FROM Exams WHERE examImgUrl LIKE 'http://%' LIMIT 10;

# Update to HTTPS if needed
UPDATE Exams SET examImgUrl = REPLACE(examImgUrl, 'http://', 'https://') WHERE examImgUrl LIKE 'http://%';
```

## ✅ Verification

After deploying the fix, you should see:

1. **In Nginx Access Log**: `200` status codes for image requests
   ```
   GET /uploads/images/exam14.png HTTP/2.0 200 ...
   ```

2. **In Flutter App**: Images loading successfully, no more errors

3. **In Browser DevTools**: 
   - Status: `200 OK`
   - Cache-Control: `public, immutable`
   - Content-Type: `image/png` or `image/jpeg`

## 📊 Performance Improvements

After this fix:
- ✅ Images served directly by Nginx (faster)
- ✅ No more connection timeouts
- ✅ Proper caching (7 days)
- ✅ Reduced backend load (Node.js doesn't serve images)
- ✅ Better bandwidth utilization

## 🔄 Related Backend Code Changes

The backend has already been updated to:
1. Remove `questionResults` from exam results list (reduced payload from several MB to ~50KB)
2. Remove non-existent `submittedAt` and `imageUrl` columns
3. Optimize query timeouts

With this Nginx fix, both API and images will work perfectly!

---

**Last Updated**: 2026-02-01  
**Status**: Ready to deploy on VPS
