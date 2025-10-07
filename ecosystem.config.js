/**
 * PM2 Ecosystem Configuration for MedusaJS
 *
 * This configuration manages two processes:
 * 1. Medusa Backend Server (API + Admin)
 * 2. Medusa Worker (Background jobs, scheduled tasks, event subscribers)
 *
 * Both processes share the same Redis instance for job queue management
 */

module.exports = {
  apps: [
    {
      name: 'medusa-backend',
      script: 'npm',
      args: 'run start',
      cwd: '/home/ryan/medusa-app',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PORT: 9000,
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 9000,
      },
      env_development: {
        NODE_ENV: 'development',
        PORT: 9000,
      },
      error_file: '/home/ryan/medusa-app/logs/backend-error.log',
      out_file: '/home/ryan/medusa-app/logs/backend-out.log',
      log_file: '/home/ryan/medusa-app/logs/backend-combined.log',
      time: true,
      merge_logs: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    },
    {
      name: 'medusa-worker',
      script: 'npm',
      args: 'run start',
      cwd: '/home/ryan/medusa-app',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '512M',
      env: {
        NODE_ENV: 'production',
        IS_WORKER: 'true',
      },
      env_production: {
        NODE_ENV: 'production',
        IS_WORKER: 'true',
      },
      env_development: {
        NODE_ENV: 'development',
        IS_WORKER: 'true',
      },
      error_file: '/home/ryan/medusa-app/logs/worker-error.log',
      out_file: '/home/ryan/medusa-app/logs/worker-out.log',
      log_file: '/home/ryan/medusa-app/logs/worker-combined.log',
      time: true,
      merge_logs: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    },
  ],

  /**
   * Deployment configuration (optional)
   * Uncomment and configure if you want to use PM2 deploy functionality
   */
  // deploy: {
  //   production: {
  //     user: 'ryan',
  //     host: 'your-vm-external-ip',
  //     ref: 'origin/main',
  //     repo: 'git@github.com:yourname/medusa-backend.git',
  //     path: '/home/ryan/medusa-app',
  //     'post-deploy': 'npm install && npm run build && pm2 reload ecosystem.config.js --env production',
  //   },
  // },
};
