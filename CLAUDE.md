# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains deployment configuration for a MedusaJS e-commerce backend on GCP Compute Engine. It includes automated setup scripts, PM2 process management, and nginx reverse proxy configuration. The actual Medusa application is installed separately (typically in `~/medusa-app`) using `create-medusa-app`.

## Architecture

The deployment consists of:
- **Medusa Backend Server**: Node.js API server + Admin dashboard (port 9000)
- **Medusa Worker**: Background jobs, scheduled tasks, event subscribers (separate PM2 process)
- **PostgreSQL**: Database (local on VM, port 5432)
- **Redis**: Cache, sessions, job queue (local on VM, port 6379)
- **PM2**: Process manager for both backend and worker
- **Nginx** (optional): Reverse proxy with SSL/TLS termination

The storefront runs separately on Cloud Run and connects to this backend via API.

## Deployment Commands

### Initial VM Setup
```bash
# Run once on a new VM to install all dependencies
chmod +x setup-vm.sh
./setup-vm.sh
```

This installs Node.js v20, PostgreSQL, Redis, PM2, and optionally nginx. Creates a PostgreSQL database named `medusa` with user `medusa` (default password: `medusa_password_change_me`).

### Deploy/Update Application
```bash
# Deploy or update the Medusa application
chmod +x deploy.sh
./deploy.sh
```

This script:
1. Installs dependencies with `npm install --production`
2. Builds the application with `npm run build`
3. Runs database migrations with `npx medusa migrations run`
4. Creates admin user (first deployment only) with `npx medusa user -e <email> -p <password>`
5. Starts both backend and worker with `pm2 start ecosystem.config.js --env production`

### PM2 Process Management
```bash
# View process status
pm2 status

# View logs
pm2 logs                    # All processes
pm2 logs medusa-backend     # Backend only
pm2 logs medusa-worker      # Worker only

# Restart/stop
pm2 restart ecosystem.config.js
pm2 stop ecosystem.config.js

# Monitor in real-time
pm2 monit

# Save process list (after changes)
pm2 save
```

### Database Operations
```bash
cd ~/medusa-app

# Run migrations
npx medusa migrations run

# Create admin user
npx medusa user -e admin@example.com -p password

# Backup database
pg_dump -U medusa medusa > backup_$(date +%Y%m%d).sql

# Restore database
psql -U medusa medusa < backup_20250101.sql
```

### Service Management
```bash
# PostgreSQL
sudo systemctl status postgresql
sudo systemctl restart postgresql

# Redis
sudo systemctl status redis-server
sudo systemctl restart redis-server

# Nginx
sudo systemctl status nginx
sudo systemctl restart nginx
sudo nginx -t  # Test config before restart
```

## Configuration Files

### ecosystem.config.js
PM2 configuration defining two processes:
- `medusa-backend`: Main API server (port 9000)
- `medusa-worker`: Background worker (with `IS_WORKER=true` env var)

Both processes run from `/home/ryan/medusa-app` directory and log to `~/medusa-app/logs/`. Update the `cwd` path if the Medusa app is installed in a different location.

### .env.production.example
Template for production environment variables. Critical settings:
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `JWT_SECRET` and `COOKIE_SECRET`: Generate with `openssl rand -base64 32`
- `STORE_CORS`: Add Cloud Run storefront URL
- `ADMIN_CORS`: Add production domain
- `IS_WORKER`: Set to `true` for worker process (managed by PM2)

### nginx.conf
Reverse proxy configuration for production with SSL/TLS. Features:
- HTTP to HTTPS redirect
- Rate limiting (10 req/s with burst of 20)
- SSL security headers
- 50MB max upload size for product images
- Separate locations for `/app` (admin), `/admin`, `/store`, `/health`

Update `server_name` with your domain before deploying.

## Medusa Application Structure

The actual Medusa application (installed in `~/medusa-app`) follows the standard structure:

### src/ Directory
- `admin/`: Admin dashboard widgets and UI routes
- `api/`: Custom API routes (added as endpoints)
- `jobs/`: Scheduled jobs that run at specified intervals
- `links/`: Module links (associations between data models)
- `modules/`: Custom modules implementing business logic
- `scripts/`: Custom CLI scripts (run with Medusa CLI)
- `subscribers/`: Event listeners (executed asynchronously when events are emitted)
- `workflows/`: Custom flows that can be executed from anywhere

### medusa-config.ts
Medusa configuration file in the application root. Configure:
- Database URL (from `DATABASE_URL` env var)
- Redis URL (from `REDIS_URL` env var)
- CORS settings for store, admin, and auth
- Modules and plugins

## Environment-Specific Notes

### Worker Process
The worker process is distinguished from the backend server by the `IS_WORKER=true` environment variable. This allows the same codebase to run in two modes:
- Backend mode: Handles HTTP requests, serves admin dashboard
- Worker mode: Processes background jobs, scheduled tasks, and event subscribers

### CORS Configuration
The backend must include the Cloud Run storefront URL in `STORE_CORS`. After SSL setup with nginx, update URLs to use `https://` protocol.

### SSL/TLS Setup
After initial deployment without SSL:
1. Install certbot: `sudo apt-get install -y certbot python3-certbot-nginx`
2. Update nginx config with actual domain name
3. Run: `sudo certbot --nginx -d api.yourdomain.com`
4. Update CORS settings in `.env` to use HTTPS
5. Restart: `pm2 restart ecosystem.config.js`

## Development vs Production

This repository is for **production deployment** on GCP Compute Engine. For local development:
- Run `npm run dev` in the Medusa app directory (starts both server and admin at `http://localhost:9000`)
- Hot reloading enabled for changes under `src/` directory
- Use local PostgreSQL and Redis instances

## Troubleshooting

### Backend won't start
- Check logs: `pm2 logs medusa-backend`
- Verify `DATABASE_URL` and Redis connection in `.env`
- Check port 9000: `sudo lsof -i :9000`

### Worker not processing jobs
- Check logs: `pm2 logs medusa-worker`
- Verify Redis is running: `redis-cli ping`
- Restart: `pm2 restart medusa-worker`

### CORS errors from storefront
- Verify CORS settings: `cat ~/medusa-app/.env | grep CORS`
- Ensure Cloud Run URL is included in `STORE_CORS`
- Restart after changes: `pm2 restart ecosystem.config.js`

### Database connection issues
- Check PostgreSQL status: `sudo systemctl status postgresql`
- Test connection: `psql -U medusa -d medusa -c "SELECT 1;"`
- Verify `DATABASE_URL` in `.env`
