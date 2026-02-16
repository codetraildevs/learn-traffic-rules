# Backend Rebrand – Drive Rwanda – Prep & Pass

**Branch:** `rebrand-backend`  
**App:** Drive Rwanda – Prep & Pass

---

## Pull on VPS – Use rebrand-backend (Not main)

On your VPS, pull from **rebrand-backend** branch:

```bash
cd /var/www/learn-traffic-rules
git fetch origin
git checkout rebrand-backend
git pull origin rebrand-backend
```

---

## Before Deploying – Configure These

### 1. Subdomain and Nginx

- **Subdomain:** `drive-rwanda-prep.cyangugudims.com` (reflects system name)
- **DNS:** Add A record for `drive-rwanda-prep.cyangugudims.com` pointing to server IP
- **SSL:** `sudo certbot --nginx -d drive-rwanda-prep.cyangugudims.com`
- **Deploy nginx config** to `/etc/nginx/sites-available/drive-rwanda-prep.cyangugudims.com`
- **env.example:** Copy to `.env` and set your values

### 2. PM2

- **ecosystem.config.js:** App name `drive-rwanda-prep-backend`, port 5001, logs `drive-rwanda-prep-*.log`
- Stop old process: `pm2 stop learn-traffic-rules-backend`
- Start new: `cd /var/www/learn-traffic-rules/backend && pm2 start ecosystem.config.js`
- Save: `pm2 save`

### 3. Contact Emails

All HTML files use `support@your-domain.com` and `dpo@your-domain.com`.  
Replace these with the actual publisher emails.

### 4. Database (Rebrand uses separate DB)

- **DB_NAME:** `rw_driving_prep_db` – create this database; do NOT use `learn_traffic_rules` (main backend)
- Create: `CREATE DATABASE rw_driving_prep_db;`
- See `DUAL_BACKEND_DEPLOYMENT.md` to run main and rebrand backends side by side

---

## Changes Made

| File | Changes |
|------|---------|
| server.js | API title, description, Swagger URL |
| package.json | name, description, keywords |
| env.example | EMAIL_FROM, SWAGGER_* |
| nginx-config-vps.conf | Subdomain drive-rwanda-prep.cyangugudims.com, port 5001, static HTML aliases |
| ecosystem.config.js | New file: drive-rwanda-prep-backend, port 5001, new log names |
| terms-conditions.html | App name, contact email |
| privacy-policy.html | App name, contact emails |
| delete-account-instructions.html | App name, contact email |

---

## Deployment Paths

Nginx still references `/var/www/learn-traffic-rules`.  
If you deploy under a different path (e.g. `/var/www/drive-rwanda-prep`), update the `root` and `alias` paths in `nginx-config-vps.conf`.

---

## Linkage Removed

- No `traffic.cyangugudims.com`
- No `codetrail.dev@gmail.com`
- No `Rwanda Traffic Driving School`
- App name set to Drive Rwanda – Prep & Pass
