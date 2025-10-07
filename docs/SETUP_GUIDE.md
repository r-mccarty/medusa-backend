# Medusa Backend Setup Guide

This guide walks you through setting up a Medusa 2.0 e-commerce backend on Google Cloud Platform (GCP) Compute Engine.

## Table of Contents
- [Prerequisites](#prerequisites)
- [VM Setup](#vm-setup)
- [Software Installation](#software-installation)
- [Medusa Installation](#medusa-installation)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Post-Deployment](#post-deployment)

---

## Prerequisites

### Required Accounts & Tools
- Google Cloud Platform account with billing enabled
- GitHub account (optional, for version control)
- Basic knowledge of Linux command line
- SSH client (gcloud CLI recommended)

### Local Requirements
- gcloud CLI installed (or use Cloud Shell)
- Git installed locally

---

## VM Setup

### 1. Create Compute Engine Instance

Using Cloud Console:
1. Navigate to Compute Engine > VM Instances
2. Click "Create Instance"
3. Configure:
   - **Name:** `medusa-backend` (or your preference)
   - **Region:** Choose closest to your users
   - **Machine type:** e2-standard-2 (for installation), can downgrade to e2-micro later
   - **Boot disk:** Debian GNU/Linux 11 (or latest)
   - **Firewall:** Allow HTTP and HTTPS traffic

Using gcloud CLI:
```bash
gcloud compute instances create medusa-backend \
  --zone=us-central1-c \
  --machine-type=e2-standard-2 \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --boot-disk-size=20GB \
  --boot-disk-type=pd-balanced \
  --tags=http-server,https-server
```

### 2. Connect to VM

```bash
# Using gcloud
gcloud compute ssh medusa-backend --zone=us-central1-c

# Or use Cloud Shell with built-in SSH
```

---

## Software Installation

### 1. Run Initial VM Setup

Clone the deployment repository:
```bash
git clone https://github.com/r-mccarty/medusa-backend.git
cd medusa-backend
```

Run the setup script:
```bash
chmod +x setup-vm.sh
./setup-vm.sh
```

This script installs:
- Node.js v20
- PostgreSQL 17
- Redis 8.0
- PM2 (process manager)
- nginx (optional)

### 2. Verify Installation

```bash
# Check versions
node --version    # Should be v20.x
psql --version    # Should be PostgreSQL 17.x
redis-cli --version  # Should be redis-cli 8.x
pm2 --version

# Check services
sudo systemctl status postgresql
sudo systemctl status redis-server
```

### 3. Configure PostgreSQL

The setup script creates:
- Database: `medusa`
- User: `medusa`
- Password: `medusa_password_change_me`

**⚠️ IMPORTANT: Change the default password for production!**

```bash
# Change PostgreSQL password
sudo -u postgres psql -c "ALTER USER medusa WITH PASSWORD 'your-secure-password';"

# Test connection
PGPASSWORD='your-secure-password' psql -h localhost -U medusa -d medusa -c "SELECT 1;"
```

---

## Medusa Installation

### 1. Install Medusa Application

```bash
cd ~
npx create-medusa-app@latest medusa-app \
  --db-url 'postgresql://medusa:your-secure-password@localhost:5432/medusa' \
  --no-browser
```

**Prompts:**
- Install Next.js Storefront? → **No** (we're deploying on Cloud Run separately)

This creates the `~/medusa-app` directory with:
- Medusa backend server
- Admin dashboard
- Database migrations
- Sample data

### 2. Build the Application

```bash
cd ~/medusa-app
npm run build
```

Build process:
- Compiles backend TypeScript → JavaScript
- Builds admin dashboard (React app)
- Creates `.medusa/` directory with compiled code

**Note:** On e2-micro instances, building can take 10-15 minutes and may require swap space.

---

## Configuration

### 1. Environment Variables

Copy the example environment file:
```bash
cd ~/medusa-app
cp ~/medusa-backend/.env.production.example .env
```

Edit `.env`:
```bash
nano .env
```

**Required Variables:**
```bash
# Database
DATABASE_URL=postgresql://medusa:your-secure-password@localhost:5432/medusa

# Redis
REDIS_URL=redis://localhost:6379

# Security - Generate with: openssl rand -base64 32
JWT_SECRET=<generated-secret>
COOKIE_SECRET=<generated-secret>

# CORS - Update with your actual URLs
STORE_CORS=https://your-storefront.run.app
ADMIN_CORS=https://admin.yourdomain.com,http://localhost:9000

# Server
NODE_ENV=production
PORT=9000
MEDUSA_BACKEND_URL=https://api.yourdomain.com
```

**Generate Secrets:**
```bash
# Generate JWT_SECRET
openssl rand -base64 32

# Generate COOKIE_SECRET
openssl rand -base64 32
```

### 2. Medusa Configuration

Copy the ecosystem config:
```bash
cp ~/medusa-backend/ecosystem.config.js ~/medusa-app/
```

Review `medusa-config.ts`:
```bash
cat ~/medusa-app/medusa-config.ts
```

The configuration should include:
- Database URL from environment
- Redis modules (cache, event bus, workflow engine)
- Worker mode configuration
- Admin disable flag for worker process

### 3. Create Symlink for Admin Build

```bash
cd ~/medusa-app
ln -sf .medusa/server/public public
```

This ensures the admin dashboard build is accessible.

---

## Deployment

### 1. PM2 Configuration

The `ecosystem.config.js` defines two processes:

**Backend Server:**
- Serves API and admin dashboard
- Port 9000
- Environment: `MEDUSA_WORKER_MODE=server`

**Worker Process:**
- Handles background jobs
- Processes scheduled tasks
- Environment: `MEDUSA_WORKER_MODE=worker`

### 2. Start with PM2

```bash
cd ~/medusa-app

# Start both processes
pm2 start ecosystem.config.js --env production

# Save process list
pm2 save

# Configure auto-start on boot
pm2 startup
# Copy and run the command it outputs (starts with sudo)

# Verify
pm2 status
```

Expected output:
```
┌────┬──────────────────┬─────────┬─────────┬──────┐
│ id │ name             │ status  │ cpu     │ mem  │
├────┼──────────────────┼─────────┼─────────┼──────┤
│ 0  │ medusa-backend   │ online  │ 0%      │ 55MB │
│ 1  │ medusa-worker    │ online  │ 0%      │ 54MB │
└────┴──────────────────┴─────────┴─────────┴──────┘
```

### 3. Verify Deployment

```bash
# Check health endpoint
curl http://localhost:9000/health
# Should return: OK

# Check logs
pm2 logs --lines 50

# Monitor in real-time
pm2 monit
```

---

## Post-Deployment

### 1. Create Admin User

```bash
cd ~/medusa-app
npx medusa user --email admin@yourdomain.com --password secure-password
```

Output:
```
User created successfully.
```

### 2. Configure Firewall

Create firewall rule for backend access:
```bash
gcloud compute firewall-rules create allow-medusa-backend \
  --allow tcp:9000 \
  --source-ranges 0.0.0.0/0 \
  --description "Allow traffic to Medusa backend on port 9000"
```

**For production:** Restrict `--source-ranges` to your storefront IP or VPC.

### 3. Test External Access

```bash
# Get your VM's external IP
gcloud compute instances describe medusa-backend \
  --zone=us-central1-c \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

# Test from local machine
curl http://EXTERNAL_IP:9000/health
```

### 4. Set Up SSL/TLS (Production)

#### Option A: nginx Reverse Proxy

```bash
# Copy nginx config
sudo cp ~/medusa-backend/nginx.conf /etc/nginx/sites-available/medusa

# Update server_name with your domain
sudo nano /etc/nginx/sites-available/medusa

# Enable site
sudo ln -s /etc/nginx/sites-available/medusa /etc/nginx/sites-enabled/

# Test config
sudo nginx -t

# Install certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d api.yourdomain.com

# Restart nginx
sudo systemctl restart nginx
```

#### Option B: Load Balancer

Use GCP Load Balancer with managed SSL certificate:
1. Create instance group
2. Create backend service
3. Create URL map
4. Create target HTTPS proxy
5. Create global forwarding rule

### 5. Update CORS Settings

After SSL setup, update CORS in `.env`:
```bash
nano ~/medusa-app/.env

# Update to use HTTPS
STORE_CORS=https://your-storefront.run.app
ADMIN_CORS=https://admin.yourdomain.com
MEDUSA_BACKEND_URL=https://api.yourdomain.com
```

Restart:
```bash
pm2 restart all
```

---

## Optimization

### 1. Downgrade VM for Cost Savings

After successful deployment, downgrade to e2-micro:

```bash
# Stop instance
gcloud compute instances stop medusa-backend --zone=us-central1-c

# Change machine type
gcloud compute instances set-machine-type medusa-backend \
  --zone=us-central1-c \
  --machine-type=e2-micro

# Start instance
gcloud compute instances start medusa-backend --zone=us-central1-c
```

**Note:** e2-micro has limited resources. Monitor performance and upgrade if needed.

### 2. Set Up Monitoring

```bash
# Install monitoring agent (optional)
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Configure PM2 monitoring
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
```

### 3. Database Backups

Create backup script:
```bash
nano ~/backup-db.sh
```

```bash
#!/bin/bash
BACKUP_DIR="$HOME/backups"
mkdir -p $BACKUP_DIR

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/medusa_$TIMESTAMP.sql"

PGPASSWORD='your-secure-password' pg_dump -h localhost -U medusa medusa > $BACKUP_FILE

# Keep only last 7 days
find $BACKUP_DIR -name "medusa_*.sql" -mtime +7 -delete

echo "Backup completed: $BACKUP_FILE"
```

Make executable and add to cron:
```bash
chmod +x ~/backup-db.sh

# Add to crontab (daily at 2 AM)
crontab -e
# Add line:
0 2 * * * /home/ryan/backup-db.sh >> /home/ryan/backup.log 2>&1
```

---

## Storefront Connection

### 1. Update Storefront Environment

In your Cloud Run storefront, set:
```bash
NEXT_PUBLIC_MEDUSA_BACKEND_URL=https://api.yourdomain.com
```

### 2. Test Connection

```bash
# From storefront
curl https://api.yourdomain.com/health
curl https://api.yourdomain.com/store/products
```

---

## Maintenance

### Common Commands

```bash
# View logs
pm2 logs
pm2 logs medusa-backend --lines 100

# Restart services
pm2 restart all
pm2 restart medusa-backend

# Update Medusa
cd ~/medusa-app
npm update
npm run build
pm2 restart all

# Database migrations
cd ~/medusa-app
npx medusa migrations run

# Clear PM2 logs
pm2 flush

# Monitor resources
pm2 monit
htop
```

### Update Deployment Scripts

```bash
cd ~/medusa-backend
git pull origin main
```

---

## Rollback Procedure

If deployment fails:

### 1. Stop Processes
```bash
pm2 stop all
```

### 2. Restore Database
```bash
PGPASSWORD='your-password' psql -h localhost -U medusa medusa < ~/backups/medusa_TIMESTAMP.sql
```

### 3. Revert Code
```bash
cd ~/medusa-app
git checkout previous-commit-hash
npm install
npm run build
```

### 4. Restart
```bash
pm2 restart all
```

---

## Security Checklist

- [ ] Changed default PostgreSQL password
- [ ] Generated strong JWT_SECRET and COOKIE_SECRET
- [ ] Configured firewall rules (restrictive source ranges)
- [ ] Set up SSL/TLS with valid certificate
- [ ] Updated CORS to production URLs only
- [ ] Enabled automatic security updates
- [ ] Set up database backups
- [ ] Configured log rotation
- [ ] Reviewed nginx security headers
- [ ] Disabled unnecessary services

---

## Troubleshooting

For common issues and solutions, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

For current deployment state, see [CURRENT_STATE.md](./CURRENT_STATE.md)

---

## Additional Resources

- **Medusa Documentation:** https://docs.medusajs.com/
- **Medusa GitHub:** https://github.com/medusajs/medusa
- **PM2 Documentation:** https://pm2.keymetrics.io/
- **GCP Documentation:** https://cloud.google.com/docs

---

*Last Updated: October 7, 2025*
