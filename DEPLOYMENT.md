# MedusaJS Backend Deployment Guide

This guide walks you through deploying the MedusaJS backend on a GCP Compute Engine VM for production use.

## Architecture Overview

The deployment consists of:
- **Medusa Backend Server**: Node.js API server + Admin dashboard (port 9000)
- **Medusa Worker**: Background jobs, scheduled tasks, event subscribers
- **PostgreSQL**: Database (local on VM, port 5432)
- **Redis**: Cache, sessions, job queue (local on VM, port 6379)
- **PM2**: Process manager for both backend and worker
- **Nginx** (optional): Reverse proxy with SSL/TLS termination

The storefront runs separately on Cloud Run and connects to this backend via API.

---

## Prerequisites

### 1. GCP Compute Engine VM
Create a VM instance with:
- **Machine type**: e2-medium or higher (2 vCPU, 4GB RAM minimum)
- **OS**: Ubuntu 22.04 LTS or Debian 11
- **Boot disk**: 20GB+ SSD
- **Network tags**: Add tags for firewall rules

### 2. Firewall Rules
Configure GCP firewall rules:
```bash
# Allow HTTP (if using nginx)
gcloud compute firewall-rules create allow-http \
  --allow tcp:80 \
  --target-tags=medusa-backend

# Allow HTTPS (if using nginx)
gcloud compute firewall-rules create allow-https \
  --allow tcp:443 \
  --target-tags=medusa-backend

# Optional: Allow direct access to Medusa (port 9000)
gcloud compute firewall-rules create allow-medusa \
  --allow tcp:9000 \
  --target-tags=medusa-backend
```

### 3. DNS Configuration
Point your domain to the VM's external IP:
```
A record: api.yourdomain.com -> VM_EXTERNAL_IP
```

---

## Deployment Steps

### Step 1: SSH into Your VM

```bash
# From Cloud Shell or local machine
gcloud compute ssh your-vm-name --zone=your-zone
```

### Step 2: Clone Repository

```bash
cd ~
git clone https://github.com/yourusername/medusa-backend.git
cd medusa-backend
```

### Step 3: Run VM Setup Script

This installs Node.js, PostgreSQL, Redis, PM2, and optionally nginx:

```bash
chmod +x setup-vm.sh
./setup-vm.sh
```

**What this script does:**
- Updates system packages
- Installs Node.js v20
- Installs and configures PostgreSQL
- Installs and configures Redis
- Installs PM2 globally
- Sets up firewall (UFW)
- Optionally installs nginx

**Important:** Note the database credentials displayed at the end!

### Step 4: Initialize Medusa Application

You have two options:

#### Option A: Use create-medusa-app (Recommended for new projects)

```bash
cd ~
npx create-medusa-app@latest medusa-app
```

Answer "No" when asked about installing the storefront (it's on Cloud Run).

#### Option B: Use existing repository

If you have an existing Medusa project, update `deploy.sh` with your repository URL and run it.

### Step 5: Configure Environment Variables

```bash
cd ~/medusa-app

# Copy environment template
cp .env.production.example .env

# Edit with your production values
nano .env
```

**Critical settings to update:**
```bash
# Database (use credentials from setup-vm.sh output)
DATABASE_URL=postgresql://medusa:YOUR_PASSWORD@localhost:5432/medusa

# Redis
REDIS_URL=redis://localhost:6379

# Security (generate new secrets!)
JWT_SECRET=$(openssl rand -base64 32)
COOKIE_SECRET=$(openssl rand -base64 32)

# CORS (add your Cloud Run storefront URL)
STORE_CORS=https://your-storefront.run.app
ADMIN_CORS=https://api.yourdomain.com
```

### Step 6: Configure Medusa

Edit `medusa-config.ts` to ensure proper CORS and module configuration:

```typescript
// medusa-config.ts
module.exports = {
  projectConfig: {
    databaseUrl: process.env.DATABASE_URL,
    redisUrl: process.env.REDIS_URL,
    http: {
      storeCors: process.env.STORE_CORS,
      adminCors: process.env.ADMIN_CORS,
      authCors: process.env.AUTH_CORS,
    },
  },
  // ... rest of config
};
```

### Step 7: Copy PM2 Configuration

```bash
# If using create-medusa-app, copy the ecosystem config
cp ~/medusa-backend/ecosystem.config.js ~/medusa-app/

# Update paths in ecosystem.config.js
nano ~/medusa-app/ecosystem.config.js
# Change '/home/ryan/medusa-app' to match your actual path if different
```

### Step 8: Deploy Application

```bash
cd ~/medusa-backend
chmod +x deploy.sh

# Update REPO_URL in deploy.sh if using git deployment
nano deploy.sh

# Run deployment
./deploy.sh
```

**What this script does:**
- Installs dependencies
- Builds the application
- Runs database migrations
- Creates admin user (first deployment only)
- Starts backend and worker with PM2

### Step 9: Verify Deployment

```bash
# Check PM2 status
pm2 status

# View logs
pm2 logs

# Test the API
curl http://localhost:9000/health

# Check PostgreSQL
psql -U medusa -d medusa -c "SELECT COUNT(*) FROM store;"

# Check Redis
redis-cli ping
```

Access the admin dashboard:
```
http://VM_EXTERNAL_IP:9000/app
```

---

## Optional: Configure Nginx with SSL

### Step 1: Install Certbot

```bash
sudo apt-get install -y certbot python3-certbot-nginx
```

### Step 2: Set Up Nginx Configuration

```bash
# Copy nginx config
sudo cp ~/medusa-backend/nginx.conf /etc/nginx/sites-available/medusa

# Update domain name
sudo nano /etc/nginx/sites-available/medusa
# Replace 'your-domain.com' with your actual domain

# Enable the site
sudo ln -s /etc/nginx/sites-available/medusa /etc/nginx/sites-enabled/medusa

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

### Step 3: Obtain SSL Certificate

```bash
sudo certbot --nginx -d api.yourdomain.com
```

Follow the prompts. Certbot will automatically configure SSL and set up auto-renewal.

### Step 4: Update CORS Settings

After SSL is set up, update your `.env` file:

```bash
STORE_CORS=https://your-storefront.run.app
ADMIN_CORS=https://api.yourdomain.com
AUTH_CORS=https://api.yourdomain.com,https://your-storefront.run.app
```

Restart the application:
```bash
pm2 restart ecosystem.config.js
```

---

## Connecting Cloud Run Storefront

Your Cloud Run storefront needs these environment variables:

```bash
NEXT_PUBLIC_MEDUSA_BACKEND_URL=https://api.yourdomain.com
# or without nginx: http://VM_EXTERNAL_IP:9000
```

The backend CORS must include your Cloud Run URL in `STORE_CORS`.

---

## Maintenance & Operations

### Updating the Application

```bash
cd ~/medusa-backend
git pull origin main
./deploy.sh
```

### PM2 Commands

```bash
# View status
pm2 status

# View logs
pm2 logs
pm2 logs medusa-backend
pm2 logs medusa-worker

# Restart services
pm2 restart ecosystem.config.js

# Stop services
pm2 stop ecosystem.config.js

# Monitor
pm2 monit

# Save process list (after any changes)
pm2 save
```

### Database Operations

```bash
# Run migrations
cd ~/medusa-app
npx medusa migrations run

# Create admin user
npx medusa user -e admin@example.com -p password

# Backup database
pg_dump -U medusa medusa > backup_$(date +%Y%m%d).sql

# Restore database
psql -U medusa medusa < backup_20250101.sql
```

### Viewing Logs

```bash
# PM2 logs
pm2 logs

# Nginx logs
sudo tail -f /var/log/nginx/medusa-access.log
sudo tail -f /var/log/nginx/medusa-error.log

# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*.log

# Redis logs
sudo tail -f /var/log/redis/redis-server.log
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

---

## Troubleshooting

### Backend won't start

```bash
# Check logs
pm2 logs medusa-backend

# Common issues:
# 1. Database connection - verify DATABASE_URL in .env
# 2. Redis connection - ensure Redis is running
# 3. Port conflicts - check if port 9000 is in use
sudo lsof -i :9000
```

### Worker not processing jobs

```bash
# Check worker logs
pm2 logs medusa-worker

# Verify Redis connection
redis-cli ping

# Restart worker
pm2 restart medusa-worker
```

### CORS errors from storefront

```bash
# Verify CORS settings in .env
cat ~/medusa-app/.env | grep CORS

# Ensure Cloud Run URL is included
# Restart after changes
pm2 restart ecosystem.config.js
```

### Database connection issues

```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Test connection
psql -U medusa -d medusa -c "SELECT 1;"

# Check connection settings
cat ~/medusa-app/.env | grep DATABASE_URL
```

---

## Security Best Practices

1. **Change default passwords**: Update PostgreSQL password from setup script default
2. **Generate strong secrets**: Use `openssl rand -base64 32` for JWT_SECRET and COOKIE_SECRET
3. **Enable firewall**: UFW is configured by setup script, verify with `sudo ufw status`
4. **Use SSL/TLS**: Always use HTTPS in production (nginx + Let's Encrypt)
5. **Restrict CORS**: Only allow necessary domains in CORS settings
6. **Keep updated**: Regularly update system packages and Medusa version
7. **Backup database**: Set up automated PostgreSQL backups
8. **Monitor logs**: Regularly check logs for suspicious activity

---

## Performance Optimization

### PostgreSQL Tuning

Edit `/etc/postgresql/*/main/postgresql.conf`:

```conf
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 4MB
min_wal_size = 1GB
max_wal_size = 4GB
```

Restart PostgreSQL: `sudo systemctl restart postgresql`

### Redis Tuning

Edit `/etc/redis/redis.conf`:

```conf
maxmemory 256mb
maxmemory-policy allkeys-lru
```

Restart Redis: `sudo systemctl restart redis-server`

### PM2 Cluster Mode (Optional)

For higher traffic, enable cluster mode for the backend:

```javascript
// ecosystem.config.js
{
  name: 'medusa-backend',
  instances: 2,  // or 'max' for all CPUs
  exec_mode: 'cluster',
  // ... rest of config
}
```

---

## Monitoring & Alerts

### Set up PM2 Plus (Optional)

```bash
pm2 plus
# Follow prompts to connect to PM2 Plus dashboard
```

### Basic Health Check Script

Create `~/check-health.sh`:

```bash
#!/bin/bash
if ! curl -f http://localhost:9000/health > /dev/null 2>&1; then
    echo "Backend is down! Restarting..."
    pm2 restart medusa-backend
fi
```

Add to crontab:
```bash
crontab -e
# Add: */5 * * * * ~/check-health.sh
```

---

## Support

- [MedusaJS Documentation](https://docs.medusajs.com)
- [MedusaJS Discord](https://discord.gg/medusajs)
- [GitHub Issues](https://github.com/medusajs/medusa/issues)

---

## File Reference

- `setup-vm.sh` - Initial VM setup script
- `deploy.sh` - Application deployment script
- `ecosystem.config.js` - PM2 configuration
- `.env.production.example` - Environment variables template
- `nginx.conf` - Nginx reverse proxy configuration
- `DEPLOYMENT.md` - This documentation
