// Use when rebrand is cloned to /var/www/drive-rwanda-prep (dual backend setup)
// Start: cd /var/www/drive-rwanda-prep/backend && pm2 start ecosystem-rebrand-standalone.config.js

module.exports = {
  apps: [{
    name: 'drive-rwanda-prep-backend',
    script: 'npm',
    args: 'start',
    cwd: '/var/www/drive-rwanda-prep/backend',
    instances: 1,
    exec_mode: 'fork',
    autorestart: true,
    watch: false,
    max_memory_restart: '512M',
    env: {
      NODE_ENV: 'production',
      PORT: 5001
    },
    error_file: '/var/log/pm2/drive-rwanda-prep-error.log',
    out_file: '/var/log/pm2/drive-rwanda-prep-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true
  }]
};
