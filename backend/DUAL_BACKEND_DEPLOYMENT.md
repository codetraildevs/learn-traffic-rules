# Dual Backend Deployment – Main + Rebrand (Both Running)

Run **both** the main branch backend and the rebrand-backend on the same VPS, each with its own database.

---

## Architecture

| Backend | Branch | Port | Domain | Database | PM2 App |
|---------|--------|------|--------|----------|---------|
| Main | main | 5000 | traffic.cyangugudims.com | learn_traffic_rules | learn-traffic-rules-backend |
| Rebrand | rebrand-backend | 5001 | drive-rwanda-prep.cyangugudims.com | rw_driving_prep_db | drive-rwanda-prep-backend |

---

## 1. Create Rebrand Database

```bash
mysql -u root -p
```

```sql
CREATE DATABASE rw_driving_prep_db;
-- Grant same user if shared: GRANT ALL ON rw_driving_prep_db.* TO 'cdims_user'@'localhost';
```

---

## 2. Clone Rebrand Backend (Separate Directory)

**Option A: Two directories (recommended)**

```bash
# Main backend (already exists)
/var/www/learn-traffic-rules   # main branch, port 5000, DB learn_traffic_rules

# Rebrand backend (new clone)
cd /var/www
git clone -b rebrand-backend https://github.com/codetraildevs/learn-traffic-rules.git drive-rwanda-prep
```

**Option B: Same directory, different branch**

If you only have one clone, you can't run both from the same folder. Use two clones.

---

## 3. Rebrand Backend Config

```bash
cd /var/www/drive-rwanda-prep/backend
cp env.example .env
nano .env
```

Set:

- `PORT=5001`
- `DB_NAME=rw_driving_prep_db`
- `DB_USER`, `DB_PASSWORD`, etc.
- `BASE_URL=https://drive-rwanda-prep.cyangugudims.com`

---

## 4. Rebrand ecosystem (Different Path)

Use `ecosystem-rebrand-standalone.config.js` (already set for `/var/www/drive-rwanda-prep/backend`).

---

## 5. Main Backend ecosystem.config.js (Port 5000)

Main backend must use port 5000 (or another port) so it doesn't conflict. Create/update ecosystem for main:

- `cwd: '/var/www/learn-traffic-rules/backend'`
- `PORT: 5000`
- `name: 'learn-traffic-rules-backend'`
- DB: `learn_traffic_rules`

---

## 6. Nginx

Both domains already have server blocks:

- `traffic.cyangugudims.com` → `localhost:5000`
- `drive-rwanda-prep.cyangugudims.com` → `localhost:5001`

Ensure each `proxy_pass` matches the correct port.

---

## 7. PM2 – Start Both

```bash
# Main backend (from main clone)
cd /var/www/learn-traffic-rules/backend
pm2 start ecosystem.config.js   # or your main ecosystem with port 5000

# Rebrand backend
cd /var/www/drive-rwanda-prep/backend
pm2 start ecosystem-rebrand-standalone.config.js

pm2 save
pm2 status
```

---

## 8. Quick Reference

| Item | Main | Rebrand |
|------|------|---------|
| Path | /var/www/learn-traffic-rules | /var/www/drive-rwanda-prep |
| Port | 5000 | 5001 |
| DB | learn_traffic_rules | rw_driving_prep_db |
| PM2 | learn-traffic-rules-backend | drive-rwanda-prep-backend |
| Domain | traffic.cyangugudims.com | drive-rwanda-prep.cyangugudims.com |
