# Medusa Backend - Current State Documentation

**Last Updated:** October 7, 2025
**VM Instance:** instance-20251003-095148 (us-central1-c)
**Medusa Version:** 2.0 (latest)

## Overview

This document describes the current state of the Medusa e-commerce backend deployment on GCP Compute Engine. The deployment consists of a Node.js-based Medusa server with PostgreSQL database, Redis cache, and PM2 process management.

## Infrastructure

### Compute Engine VM
- **Instance Name:** instance-20251003-095148
- **Zone:** us-central1-c
- **Machine Type:** e2-standard-2 (2 vCPUs, 8GB RAM) - *Temporarily upgraded for installation*
- **External IP:** 34.28.27.211
- **Internal IP:** 10.128.0.2
- **OS:** Debian GNU/Linux (Linux 6.6.105+)

### Installed Software
- **Node.js:** v20.19.5
- **PostgreSQL:** 17.6 (Debian 17.6-0+deb13u1)
- **Redis:** 8.0.2
- **Git:** 2.47.3
- **PM2:** Global installation (process manager)

### Database Configuration
- **Database Name:** medusa
- **Database User:** medusa
- **Database Password:** medusa_password_change_me ⚠️ *Should be changed in production*
- **Connection:** localhost:5432
- **Authentication:** Password-based (md5) over TCP/IP

### Redis Configuration
- **Host:** localhost
- **Port:** 6379
- **Authentication:** None (local only)

## Application Structure

### Directory Layout
```
/home/ryan/
├── medusa-backend/          # Deployment scripts & config (Git repo)
│   ├── deploy.sh
│   ├── setup-vm.sh
│   ├── ecosystem.config.js
│   ├── nginx.conf
│   ├── .env.production.example
│   └── CLAUDE.md
│
└── medusa-app/              # Medusa application
    ├── .medusa/
    │   ├── client/          # Admin dashboard build
    │   └── server/          # Backend build
    │       └── public/admin/
    ├── node_modules/
    ├── logs/                # PM2 logs
    ├── .env                 # Development environment
    ├── .env.production      # Production environment
    ├── ecosystem.config.js  # PM2 configuration
    ├── medusa-config.ts     # Medusa configuration
    └── package.json
```

### GitHub Repository
- **URL:** https://github.com/r-mccarty/medusa-backend.git
- **Branch:** main
- **Status:** Public
- **Contents:** Deployment scripts, configuration templates, documentation

## PM2 Process Management

### Running Processes
```
┌────┬──────────────────┬─────────┬────────┐
│ ID │ Name             │ Status  │ Port   │
├────┼──────────────────┼─────────┼────────┤
│ 0  │ medusa-backend   │ online  │ 9000   │
│ 1  │ medusa-worker    │ online  │ N/A    │
└────┴──────────────────┴─────────┴────────┘
```

### Process Configuration

#### Backend Server (medusa-backend)
- **Script:** npm run start
- **Working Directory:** /home/ryan/medusa-app
- **Environment:**
  - `NODE_ENV=production`
  - `PORT=9000`
  - `MEDUSA_WORKER_MODE=server`
  - `DISABLE_MEDUSA_ADMIN=false`
- **Memory Limit:** 1GB
- **Auto Restart:** Enabled
- **Logs:**
  - Error: `/home/ryan/medusa-app/logs/backend-error.log`
  - Output: `/home/ryan/medusa-app/logs/backend-out.log`

#### Worker Process (medusa-worker)
- **Script:** npm run start
- **Working Directory:** /home/ryan/medusa-app
- **Environment:**
  - `NODE_ENV=production`
  - `MEDUSA_WORKER_MODE=worker`
  - `DISABLE_MEDUSA_ADMIN=true`
- **Memory Limit:** 512MB
- **Auto Restart:** Enabled
- **Logs:**
  - Error: `/home/ryan/medusa-app/logs/worker-error.log`
  - Output: `/home/ryan/medusa-app/logs/worker-out.log`

### PM2 Startup
- **System Service:** pm2-ryan.service (systemd)
- **Auto-start on Boot:** Enabled
- **Saved Process List:** /home/ryan/.pm2/dump.pm2

## Environment Configuration

### Production Environment Variables (.env.production)
```bash
# Database
DATABASE_URL=postgresql://medusa:medusa_password_change_me@localhost:5432/medusa

# Redis
REDIS_URL=redis://localhost:6379

# Security
JWT_SECRET=YA5MMmcD45Wcw3mZl59G6ClozUrbi2u0gzVXcppKpdc=
COOKIE_SECRET=eSGzIfvVg22iah2bxuqyARevEQ7gpq26UBW2s+8Og6c=

# CORS
STORE_CORS=http://localhost:8000,https://your-storefront.run.app
ADMIN_CORS=http://localhost:9000,http://34.28.27.211:9000

# Server
NODE_ENV=production
PORT=9000
MEDUSA_BACKEND_URL=http://34.28.27.211:9000
```

### Medusa Configuration (medusa-config.ts)
- **Worker Mode:** Dynamic based on `MEDUSA_WORKER_MODE` env var
- **Admin Dashboard:** Conditionally disabled based on `DISABLE_MEDUSA_ADMIN`
- **Redis Modules:**
  - Cache: `@medusajs/medusa/cache-redis`
  - Event Bus: `@medusajs/medusa/event-bus-redis`
  - Workflow Engine: `@medusajs/medusa/workflow-engine-redis`

## Admin User

### Created Admin Account
- **Email:** admin@medusa.com
- **Password:** supersecret123
- **Status:** ✅ Successfully created
- **Creation Date:** October 7, 2025

## Current Status

### ✅ Working Components
- **Health Endpoint:** `http://localhost:9000/health` returns "OK"
- **PM2 Processes:** Both backend and worker running stable (no restarts)
- **Database Connection:** PostgreSQL connected and accessible
- **Redis Connection:** All Redis modules (cache, event bus, workflow) connected
- **Admin User:** Successfully created in database
- **Build Process:** Admin dashboard and backend built successfully

### ⚠️ Known Issues

#### 1. Admin/Store Routes Not Loading (404 Errors)
- **Symptom:** All `/admin/*` and `/store/*` routes return 404
- **Impact:** Cannot access admin dashboard or store API
- **Details:**
  - Health endpoint works (`/health` returns "OK")
  - Express server is running on port 9000
  - Medusa routes are not being registered
  - Build files exist in `.medusa/server/public/admin/`
  - No errors in startup logs related to route loading

**Tested Endpoints (All 404):**
- `http://localhost:9000/admin/products`
- `http://localhost:9000/admin/auth`
- `http://localhost:9000/store/products`
- `http://localhost:9000/store/auth`

#### 2. Session Store Warning
- **Warning:** "connect.session() MemoryStore is not designed for production"
- **Impact:** Sessions stored in memory, will not persist across restarts
- **Solution Needed:** Configure Redis-based session store

#### 3. Locking Module Warning
- **Warning:** 'Locking module: Using "in-memory" as default'
- **Impact:** Distributed locking not available
- **Solution Needed:** Configure Redis-based locking module

## Logs & Debugging

### Key Log Locations
```bash
# PM2 Process Logs
/home/ryan/medusa-app/logs/backend-out.log
/home/ryan/medusa-app/logs/backend-error.log
/home/ryan/medusa-app/logs/worker-out.log
/home/ryan/medusa-app/logs/worker-error.log

# PM2 Combined Logs
/home/ryan/medusa-app/logs/backend-combined.log
/home/ryan/medusa-app/logs/worker-combined.log

# System Logs
/home/ryan/.pm2/pm2.log
/home/ryan/.pm2/logs/
```

### Recent Log Observations
```
✅ Connection to Redis in module 'event-bus-redis' established
✅ Connection to Redis in module 'cache-redis' established
✅ Connection to Redis in module 'workflow-engine-redis' established
✅ Connection to Redis PubSub in module 'workflow-engine-redis' established
✅ Creating server
❌ No admin/store routes registered
```

## Network & Firewall

### Open Ports
- **Port 9000:** Medusa backend (listening on all interfaces `:::9000`)
- **Port 5432:** PostgreSQL (localhost only)
- **Port 6379:** Redis (localhost only)

### External Access
- **Current:** Backend is NOT accessible from external IP (no firewall rule)
- **Health Check (internal):** ✅ Works via localhost
- **Admin Dashboard:** ❌ 404 errors (routes not loaded)

### Required Firewall Rules (Not Yet Created)
```bash
# Allow HTTP traffic to backend
gcloud compute firewall-rules create allow-medusa-backend \
  --allow tcp:9000 \
  --source-ranges 0.0.0.0/0 \
  --target-tags medusa-backend
```

## Build Information

### Last Build
- **Date:** October 7, 2025
- **Command:** `npm run build`
- **Backend Build Time:** 6.82s
- **Frontend Build Time:** 45.99s
- **Status:** ✅ Successful
- **Output Directory:** `.medusa/`

### Build Artifacts
```
.medusa/
├── client/
│   ├── index.html
│   ├── index.css
│   └── entry.jsx
└── server/
    ├── src/
    └── public/
        └── admin/
            ├── index.html
            └── assets/
```

## Deployment History

### Installation Timeline
1. **VM Setup:** Upgraded from e2-micro to e2-standard-2
2. **Prerequisites Verified:** Node.js v20, PostgreSQL 17, Redis 8.0, Git 2.47
3. **Medusa Installed:** Using `create-medusa-app@latest` with existing database
4. **Configuration:** Redis modules, worker mode, environment variables
5. **PM2 Deployment:** Backend + worker processes started
6. **Admin User Created:** admin@medusa.com successfully created
7. **PM2 Startup:** Configured for auto-start on boot

### Key Commands Used
```bash
# Installation
npx create-medusa-app@latest medusa-app \
  --db-url 'postgresql://medusa:medusa_password_change_me@localhost:5432/medusa' \
  --no-browser

# Build
npm run build

# Create Admin User
npx medusa user --email admin@medusa.com --password supersecret123

# PM2 Management
pm2 start ecosystem.config.js --env production
pm2 save
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ryan --hp /home/ryan
```

## Next Steps & Recommendations

### Immediate Actions
1. **Debug Route Loading Issue**
   - Review Medusa 2.0 route registration process
   - Check if additional configuration is needed
   - Verify build process completed all necessary steps
   - Review official Medusa 2.0 deployment documentation

2. **Configure Firewall**
   - Create GCP firewall rule for port 9000
   - Test external accessibility

3. **Downgrade VM**
   - Once deployment is stable, downgrade to e2-micro to save costs
   - Document performance on smaller instance

### Production Hardening
1. **Security**
   - Change PostgreSQL password from default
   - Regenerate JWT and Cookie secrets
   - Configure SSL/TLS with nginx reverse proxy
   - Update CORS settings with actual storefront URL

2. **Session & Locking**
   - Configure Redis session store
   - Configure Redis locking module

3. **Monitoring**
   - Set up log rotation
   - Configure PM2 monitoring
   - Set up health check alerts

4. **Backup**
   - Configure PostgreSQL automated backups
   - Document backup/restore procedures

## Useful Commands

### PM2 Management
```bash
# View status
pm2 status

# View logs
pm2 logs
pm2 logs medusa-backend
pm2 logs medusa-worker

# Restart
pm2 restart all
pm2 restart medusa-backend

# Stop
pm2 stop all

# Monitor
pm2 monit

# Save current state
pm2 save
```

### Database Management
```bash
# Connect to database
PGPASSWORD=medusa_password_change_me psql -h localhost -U medusa -d medusa

# Backup
pg_dump -U medusa medusa > backup_$(date +%Y%m%d).sql

# Restore
psql -U medusa medusa < backup_20251007.sql

# Run migrations
cd ~/medusa-app && npx medusa migrations run
```

### System Checks
```bash
# Check ports
ss -tlnp | grep :9000

# Check processes
ps aux | grep medusa

# Test health
curl http://localhost:9000/health

# Check Redis
redis-cli ping
redis-cli INFO

# Check PostgreSQL
sudo systemctl status postgresql
```

## Contact & Support

### Repository
- **GitHub:** https://github.com/r-mccarty/medusa-backend.git
- **Documentation:** See `/docs` directory

### Medusa Resources
- **Documentation:** https://docs.medusajs.com/
- **GitHub:** https://github.com/medusajs/medusa
- **Discord:** https://discord.gg/medusajs

---

*This documentation was generated based on the deployment state as of October 7, 2025.*
