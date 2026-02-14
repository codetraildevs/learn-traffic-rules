module.exports = {
  apps: [{
    name: 'drive-rwanda-prep-backend',
    script: 'npm',
    args: 'start',
    cwd: '/var/www/learn-traffic-rules/backend',
    instances: 1,
    exec_mode: 'fork',
    autorestart: true,
    watch: false,
    max_memory_restart: '512M',
    exp_backoff_restart_delay: 100,
    max_restarts: 10,
    min_uptime: '10s',
    env: {
      NODE_ENV: 'production',
      PORT: 5001
    },
    error_file: '/var/log/pm2/drive-rwanda-prep-error.log',
    out_file: '/var/log/pm2/drive-rwanda-prep-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    kill_timeout: 5000
  }]
};
