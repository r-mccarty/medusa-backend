# Troubleshooting Guide

This guide covers common issues and their solutions for the Medusa backend deployment on GCP Compute Engine.

## Table of Contents
- [Server Issues](#server-issues)
- [Database Issues](#database-issues)
- [Redis Issues](#redis-issues)
- [PM2 Issues](#pm2-issues)
- [Network & Connectivity](#network--connectivity)
- [Build & Deployment](#build--deployment)

---

## Server Issues

### Issue: Backend won't start

**Symptoms:**
- PM2 shows process as "stopped" or constantly restarting
- Error logs show startup failures

**Diagnostic Steps:**
```bash
# Check PM2 status
pm2 status

# View error logs
pm2 logs medusa-backend --err --lines 50

# Check if port is already in use
ss -tlnp | grep :9000
```

**Common Causes & Solutions:**

#### 1. Port Already in Use
```bash
# Find process using port 9000
ss -tlnp | grep :9000

# Kill the process (replace PID)
kill <PID>

# Restart PM2
pm2 restart medusa-backend
```

#### 2. Database Connection Failed
```bash
# Verify DATABASE_URL in .env
cat ~/medusa-app/.env | grep DATABASE_URL

# Test database connection
PGPASSWORD=medusa_password_change_me psql -h localhost -U medusa -d medusa -c "SELECT 1;"

# If connection fails, check PostgreSQL is running
sudo systemctl status postgresql
sudo systemctl restart postgresql
```

#### 3. Missing Environment Variables
```bash
# Check .env exists
ls -la ~/medusa-app/.env*

# Verify required variables
cat ~/medusa-app/.env | grep -E '(DATABASE_URL|REDIS_URL|JWT_SECRET|COOKIE_SECRET)'

# Copy from example if missing
cp ~/medusa-app/.env.production.example ~/medusa-app/.env
```

### Issue: Admin/Store Routes Return 404

**Symptoms:**
- Health endpoint works: `curl http://localhost:9000/health` returns "OK"
- All `/admin/*` and `/store/*` routes return 404
- Build completed successfully

**Diagnostic Steps:**
```bash
# Check if admin build exists
ls -la ~/medusa-app/.medusa/server/public/admin/

# Check for route registration errors
pm2 logs medusa-backend | grep -i "route\|admin\|store"

# Verify build completed
ls -la ~/medusa-app/.medusa/
```

**Possible Solutions:**

#### 1. Rebuild Application
```bash
cd ~/medusa-app

# Stop PM2
pm2 stop all

# Clean build
rm -rf .medusa/

# Rebuild
npm run build

# Restart
pm2 restart all
```

#### 2. Check Medusa Configuration
```bash
# Review medusa-config.ts
cat ~/medusa-app/medusa-config.ts

# Ensure worker mode is set correctly
# Backend should have: MEDUSA_WORKER_MODE=server
# Worker should have: MEDUSA_WORKER_MODE=worker
```

#### 3. Verify Package Installation
```bash
cd ~/medusa-app

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Rebuild
npm run build

# Restart
pm2 restart all
```

### Issue: Worker Not Processing Jobs

**Symptoms:**
- Background jobs not executing
- Scheduled tasks not running
- Events not being processed

**Diagnostic Steps:**
```bash
# Check worker status
pm2 status | grep worker

# View worker logs
pm2 logs medusa-worker --lines 50

# Check Redis connection
pm2 logs medusa-worker | grep -i redis
```

**Solutions:**

#### 1. Verify Worker Configuration
```bash
# Check ecosystem.config.js
cat ~/medusa-app/ecosystem.config.js | grep -A 10 "medusa-worker"

# Ensure MEDUSA_WORKER_MODE=worker is set
# Ensure DISABLE_MEDUSA_ADMIN=true is set
```

#### 2. Check Redis Connection
```bash
# Test Redis
redis-cli ping

# Check Redis URL
cat ~/medusa-app/.env | grep REDIS_URL

# Restart Redis if needed
sudo systemctl restart redis-server
```

#### 3. Restart Worker
```bash
pm2 restart medusa-worker

# If issues persist, delete and restart
pm2 delete medusa-worker
pm2 start ~/medusa-app/ecosystem.config.js --only medusa-worker --env production
```

---

## Database Issues

### Issue: Cannot Connect to PostgreSQL

**Symptoms:**
- Error: "connection refused" or "authentication failed"
- Backend fails to start with database errors

**Diagnostic Steps:**
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Try connecting locally
sudo -u postgres psql -c "\l"

# Try connecting as medusa user
PGPASSWORD=medusa_password_change_me psql -h localhost -U medusa -d medusa -c "SELECT 1;"
```

**Solutions:**

#### 1. PostgreSQL Not Running
```bash
# Start PostgreSQL
sudo systemctl start postgresql

# Enable auto-start
sudo systemctl enable postgresql

# Check status
sudo systemctl status postgresql
```

#### 2. Authentication Failed
```bash
# Check pg_hba.conf
sudo cat /etc/postgresql/*/main/pg_hba.conf | grep -v "^#"

# Should contain:
# host    medusa    medusa    127.0.0.1/32    md5

# If not, edit and add the line
sudo nano /etc/postgresql/*/main/pg_hba.conf

# Reload PostgreSQL
sudo systemctl reload postgresql
```

#### 3. User or Database Doesn't Exist
```bash
# Connect as postgres
sudo -u postgres psql

# Create database and user
CREATE DATABASE medusa;
CREATE USER medusa WITH PASSWORD 'medusa_password_change_me';
GRANT ALL PRIVILEGES ON DATABASE medusa TO medusa;
\q
```

### Issue: Migration Errors

**Symptoms:**
- Error: "relation does not exist"
- Backend fails with database schema errors

**Solutions:**
```bash
cd ~/medusa-app

# Run migrations
npx medusa migrations run

# If errors persist, check migration status
npx medusa migrations show

# To start fresh (CAUTION: destroys data)
# 1. Drop and recreate database
sudo -u postgres psql -c "DROP DATABASE medusa;"
sudo -u postgres psql -c "CREATE DATABASE medusa OWNER medusa;"

# 2. Run migrations
npx medusa migrations run
```

---

## Redis Issues

### Issue: Redis Connection Failed

**Symptoms:**
- Warning: "redisUrl not found. A fake redis instance will be used."
- Cache and event bus not working properly

**Diagnostic Steps:**
```bash
# Check Redis status
sudo systemctl status redis-server

# Test connection
redis-cli ping

# Check configuration
cat ~/medusa-app/.env | grep REDIS_URL
```

**Solutions:**

#### 1. Redis Not Running
```bash
# Start Redis
sudo systemctl start redis-server

# Enable auto-start
sudo systemctl enable redis-server

# Verify
redis-cli ping
```

#### 2. Missing REDIS_URL
```bash
# Add to .env
echo "REDIS_URL=redis://localhost:6379" >> ~/medusa-app/.env

# Also add to .env.production if using it
echo "REDIS_URL=redis://localhost:6379" >> ~/medusa-app/.env.production

# Restart backend
pm2 restart all
```

#### 3. Redis Port Conflict
```bash
# Check what's using port 6379
ss -tlnp | grep :6379

# Check Redis config
sudo cat /etc/redis/redis.conf | grep "^port"

# If needed, update REDIS_URL to match actual port
```

---

## PM2 Issues

### Issue: PM2 Processes Keep Restarting

**Symptoms:**
- High restart count in `pm2 status`
- Processes constantly showing as "restarting"

**Diagnostic Steps:**
```bash
# Check status and restart count
pm2 status

# View recent errors
pm2 logs --err --lines 50

# Check process info
pm2 info medusa-backend
```

**Solutions:**

#### 1. Memory Limit Exceeded
```bash
# Check memory usage
pm2 status

# Increase memory limit in ecosystem.config.js
nano ~/medusa-app/ecosystem.config.js

# Change max_memory_restart to higher value (e.g., '2G')
# Reload config
pm2 delete all
pm2 start ~/medusa-app/ecosystem.config.js --env production
```

#### 2. Application Crashes on Startup
```bash
# Delete process and start fresh
pm2 delete all

# Start with detailed logging
cd ~/medusa-app
pm2 start ecosystem.config.js --env production

# Monitor startup
pm2 logs --lines 100
```

#### 3. PM2 Daemon Issues
```bash
# Kill PM2 daemon
pm2 kill

# Restart
pm2 start ~/medusa-app/ecosystem.config.js --env production

# Save
pm2 save
```

### Issue: PM2 Doesn't Start on Boot

**Symptoms:**
- After VM restart, processes are not running
- `pm2 status` shows no processes

**Solutions:**

#### 1. Reconfigure Startup
```bash
# Generate startup script
pm2 startup

# Copy and run the command it outputs (starts with sudo)
# Example:
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ryan --hp /home/ryan

# Save current process list
pm2 save

# Verify service is enabled
sudo systemctl status pm2-ryan
```

#### 2. Check Systemd Service
```bash
# View service status
sudo systemctl status pm2-ryan

# Enable if disabled
sudo systemctl enable pm2-ryan

# Start manually for testing
sudo systemctl start pm2-ryan
```

---

## Network & Connectivity

### Issue: Cannot Access Backend from External IP

**Symptoms:**
- `curl http://34.28.27.211:9000/health` fails
- Works locally: `curl http://localhost:9000/health` succeeds

**Solutions:**

#### 1. Create Firewall Rule
```bash
# Create firewall rule for port 9000
gcloud compute firewall-rules create allow-medusa-backend \
  --allow tcp:9000 \
  --source-ranges 0.0.0.0/0 \
  --description "Allow traffic to Medusa backend"

# Verify rule
gcloud compute firewall-rules list | grep medusa
```

#### 2. Check Server is Listening on All Interfaces
```bash
# Verify server is listening on all interfaces (should show :::9000 or 0.0.0.0:9000)
ss -tlnp | grep :9000

# If only listening on 127.0.0.1, check Medusa config for host binding
```

### Issue: CORS Errors

**Symptoms:**
- Browser console shows CORS errors
- Storefront cannot connect to backend

**Solutions:**

#### 1. Update CORS Configuration
```bash
# Edit .env
nano ~/medusa-app/.env

# Update STORE_CORS with your storefront URL
STORE_CORS=https://your-storefront-url.run.app,http://localhost:8000

# Update ADMIN_CORS with your admin URL
ADMIN_CORS=https://your-admin-url.com,http://localhost:9000

# Restart
pm2 restart all
```

#### 2. Check medusa-config.ts
```bash
# Verify CORS settings are loaded
cat ~/medusa-app/medusa-config.ts | grep -A 5 "storeCors\|adminCors"
```

---

## Build & Deployment

### Issue: Build Fails

**Symptoms:**
- `npm run build` fails with errors
- Frontend or backend build errors

**Diagnostic Steps:**
```bash
cd ~/medusa-app

# Try building with verbose output
npm run build

# Check Node.js version
node --version  # Should be v20+
```

**Solutions:**

#### 1. Clear Cache and Rebuild
```bash
cd ~/medusa-app

# Remove build artifacts
rm -rf .medusa/

# Clear npm cache
npm cache clean --force

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Rebuild
npm run build
```

#### 2. Check Disk Space
```bash
# Check available disk space
df -h /home

# If low, clean up
pm2 flush  # Clear PM2 logs
npm cache clean --force
```

#### 3. Memory Issues During Build
```bash
# If building on small VM, increase Node.js memory
NODE_OPTIONS="--max-old-space-size=4096" npm run build
```

### Issue: Admin User Creation Fails

**Symptoms:**
- `npx medusa user` command fails
- Error creating admin user

**Solutions:**

#### 1. Database Not Ready
```bash
# Ensure migrations are run first
cd ~/medusa-app
npx medusa migrations run

# Then create user
npx medusa user --email admin@medusa.com --password yourpassword
```

#### 2. User Already Exists
```bash
# Connect to database
PGPASSWORD=medusa_password_change_me psql -h localhost -U medusa -d medusa

# Check for existing user
SELECT * FROM public.user WHERE email = 'admin@medusa.com';

# If exists, update password or delete and recreate
DELETE FROM public.user WHERE email = 'admin@medusa.com';
\q

# Create new user
npx medusa user --email admin@medusa.com --password newpassword
```

---

## Performance Issues

### Issue: High Memory Usage

**Symptoms:**
- VM running out of memory
- PM2 processes being killed

**Solutions:**

#### 1. Reduce Memory Limits
```bash
# Edit ecosystem.config.js
nano ~/medusa-app/ecosystem.config.js

# Adjust max_memory_restart values
# Backend: 1G -> 800M
# Worker: 512M -> 400M

# Reload
pm2 delete all
pm2 start ~/medusa-app/ecosystem.config.js --env production
```

#### 2. Upgrade VM Instance
```bash
# Stop the instance
gcloud compute instances stop instance-20251003-095148 --zone=us-central1-c

# Change machine type
gcloud compute instances set-machine-type instance-20251003-095148 \
  --zone=us-central1-c \
  --machine-type=e2-medium

# Start instance
gcloud compute instances start instance-20251003-095148 --zone=us-central1-c
```

### Issue: Slow Response Times

**Solutions:**

#### 1. Check Database Performance
```bash
# Connect to PostgreSQL
PGPASSWORD=medusa_password_change_me psql -h localhost -U medusa -d medusa

# Check slow queries
SELECT pid, now() - query_start as duration, query
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY duration DESC;

# Check database size
SELECT pg_size_pretty(pg_database_size('medusa'));
```

#### 2. Monitor Redis
```bash
# Check Redis memory
redis-cli INFO memory

# Monitor commands
redis-cli MONITOR  # Ctrl+C to stop

# Check slow log
redis-cli SLOWLOG GET 10
```

---

## Emergency Recovery

### Complete System Reset (Last Resort)

**⚠️ WARNING: This will destroy all data!**

```bash
# 1. Stop all services
pm2 kill
sudo systemctl stop postgresql redis-server

# 2. Drop database
sudo -u postgres psql -c "DROP DATABASE IF EXISTS medusa;"
sudo -u postgres psql -c "CREATE DATABASE medusa OWNER medusa;"

# 3. Clear Redis
redis-cli FLUSHALL

# 4. Remove Medusa app
rm -rf ~/medusa-app

# 5. Reinstall Medusa
npx create-medusa-app@latest medusa-app \
  --db-url 'postgresql://medusa:medusa_password_change_me@localhost:5432/medusa' \
  --no-browser

# 6. Configure and deploy
cd ~/medusa-app
cp ~/medusa-backend/.env.production.example .env
# Edit .env with proper values
npm run build
pm2 start ~/medusa-backend/ecosystem.config.js --env production
pm2 save
```

---

## Getting Help

### Collect Diagnostic Information

Before asking for help, collect this information:

```bash
# System info
uname -a
node --version
npm --version
pm2 --version

# Service status
sudo systemctl status postgresql redis-server pm2-ryan

# PM2 status
pm2 status
pm2 logs --lines 100 --nostream

# Network
ss -tlnp | grep -E ':(9000|5432|6379)'

# Disk space
df -h

# Memory
free -h

# Environment
cat ~/medusa-app/.env | grep -v SECRET | grep -v PASSWORD
```

### Resources

- **Medusa Docs:** https://docs.medusajs.com/
- **Medusa Discord:** https://discord.gg/medusajs
- **GitHub Issues:** https://github.com/medusajs/medusa/issues
- **Deployment Repo:** https://github.com/r-mccarty/medusa-backend

---

*Last Updated: October 7, 2025*
