# Medusa Backend Documentation

Welcome to the documentation for the Medusa 2.0 e-commerce backend deployment on Google Cloud Platform.

## 📚 Documentation Index

### Quick Start
- **[Setup Guide](./SETUP_GUIDE.md)** - Complete walkthrough for deploying Medusa on GCP Compute Engine
- **[Current State](./CURRENT_STATE.md)** - Current deployment status, configuration, and known issues

### Reference
- **[API Reference](./API_REFERENCE.md)** - API endpoints, authentication, and integration examples
- **[Troubleshooting](./TROUBLESHOOTING.md)** - Common issues and solutions

## 🚀 Quick Links

### Current Deployment
- **VM Instance:** instance-20251003-095148 (us-central1-c)
- **External IP:** 34.28.27.211
- **Health Check:** http://34.28.27.211:9000/health
- **Admin Dashboard:** http://34.28.27.211:9000/app

### Admin Credentials
- **Email:** admin@medusa.com
- **Password:** supersecret123

### GitHub Repository
- **URL:** https://github.com/r-mccarty/medusa-backend.git

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────┐
│         GCP Compute Engine VM           │
│  ┌───────────────────────────────────┐  │
│  │         PM2 Process Manager        │  │
│  │  ┌──────────────┐  ┌────────────┐ │  │
│  │  │    Medusa    │  │   Medusa   │ │  │
│  │  │   Backend    │  │   Worker   │ │  │
│  │  │  (Port 9000) │  │ (Background)│ │  │
│  │  └──────────────┘  └────────────┘ │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │        PostgreSQL 17              │  │
│  │        (Port 5432)                │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │        Redis 8.0                  │  │
│  │        (Port 6379)                │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
           │
           │ HTTPS (with nginx/SSL)
           ▼
    ┌─────────────┐
    │  Storefront │
    │  (Cloud Run)│
    └─────────────┘
```

## 📦 What's Included

### Deployment Scripts
- `setup-vm.sh` - Initial VM setup (Node.js, PostgreSQL, Redis, PM2)
- `deploy.sh` - Application deployment script
- `ecosystem.config.js` - PM2 process configuration
- `nginx.conf` - Reverse proxy configuration (optional)
- `.env.production.example` - Environment variables template

### Configuration Files
- `medusa-config.ts` - Medusa application configuration
- `.env` / `.env.production` - Environment variables
- `package.json` - Node.js dependencies

### Documentation
- Setup guides and tutorials
- API reference
- Troubleshooting guides
- Current deployment state

## ✅ Features

### Deployed Components
- ✅ Medusa 2.0 Backend (Node.js v20)
- ✅ PostgreSQL 17 Database
- ✅ Redis 8.0 Cache & Queue
- ✅ PM2 Process Management
- ✅ Auto-restart on boot
- ✅ Separate worker process for background jobs
- ✅ Admin dashboard
- ✅ Health monitoring endpoint

### Configured Modules
- ✅ Redis Cache Module
- ✅ Redis Event Bus Module
- ✅ Redis Workflow Engine Module
- ✅ Worker Mode (Server + Worker processes)

## ⚠️ Known Issues

### Current Status
- **Health Endpoint:** ✅ Working (`/health` returns "OK")
- **PM2 Processes:** ✅ Stable (backend + worker running)
- **Database & Redis:** ✅ Connected
- **Admin Routes:** ❌ Returning 404 errors
- **Store Routes:** ❌ Returning 404 errors

See [CURRENT_STATE.md](./CURRENT_STATE.md) for detailed status and [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for solutions.

## 🛠️ Common Tasks

### View Application Status
```bash
# SSH to VM
gcloud compute ssh instance-20251003-095148 --zone=us-central1-c

# Check PM2 status
pm2 status

# View logs
pm2 logs

# Check health
curl http://localhost:9000/health
```

### Restart Application
```bash
# Restart all processes
pm2 restart all

# Restart specific process
pm2 restart medusa-backend
pm2 restart medusa-worker
```

### Update Configuration
```bash
# Edit environment variables
nano ~/medusa-app/.env

# Restart to apply changes
pm2 restart all
```

### Database Operations
```bash
# Run migrations
cd ~/medusa-app
npx medusa migrations run

# Create admin user
npx medusa user --email admin@example.com --password password

# Backup database
pg_dump -U medusa medusa > backup_$(date +%Y%m%d).sql
```

### Build & Deploy
```bash
# Rebuild application
cd ~/medusa-app
npm run build

# Restart processes
pm2 restart all
```

## 📊 Monitoring

### Health Checks
```bash
# Local health check
curl http://localhost:9000/health

# External health check
curl http://34.28.27.211:9000/health
```

### Process Monitoring
```bash
# PM2 status
pm2 status

# Real-time monitoring
pm2 monit

# View logs
pm2 logs --lines 50
```

### System Resources
```bash
# Check disk space
df -h

# Check memory
free -h

# Check CPU
top

# Network connections
ss -tulpn | grep -E ':(9000|5432|6379)'
```

## 🔐 Security

### Current Security Measures
- ✅ PostgreSQL password authentication
- ✅ JWT & Cookie secrets configured
- ✅ Redis local-only access
- ✅ PM2 process isolation
- ⚠️ No SSL/TLS (firewall not configured)
- ⚠️ Default PostgreSQL password in use

### Production Hardening Needed
- [ ] Configure SSL/TLS (nginx + Let's Encrypt)
- [ ] Change PostgreSQL password
- [ ] Regenerate JWT and Cookie secrets
- [ ] Configure firewall rules
- [ ] Set up proper CORS for production URLs
- [ ] Enable audit logging
- [ ] Implement rate limiting
- [ ] Set up automated backups

See [SETUP_GUIDE.md](./SETUP_GUIDE.md#security-checklist) for complete checklist.

## 🔄 Update & Maintenance

### Update Medusa
```bash
cd ~/medusa-app

# Update packages
npm update

# Rebuild
npm run build

# Run migrations
npx medusa migrations run

# Restart
pm2 restart all
```

### Update Node.js
```bash
# Using nvm
nvm install 20
nvm use 20
nvm alias default 20

# Reinstall PM2 globally
npm install -g pm2

# Restart application
cd ~/medusa-app
pm2 restart all
```

### Update Deployment Scripts
```bash
cd ~/medusa-backend
git pull origin main
```

## 🐛 Debugging

### Check Logs
```bash
# All logs
pm2 logs

# Backend only
pm2 logs medusa-backend

# Worker only
pm2 logs medusa-worker

# Search for errors
pm2 logs | grep -i error

# Last 100 lines
pm2 logs --lines 100 --nostream
```

### Database Debugging
```bash
# Connect to database
PGPASSWORD=medusa_password_change_me psql -h localhost -U medusa -d medusa

# Check tables
\dt

# Check migrations
SELECT * FROM migrations;

# Exit
\q
```

### Redis Debugging
```bash
# Check Redis
redis-cli ping

# Monitor commands
redis-cli MONITOR

# Check memory
redis-cli INFO memory
```

## 📖 Learning Resources

### Medusa Documentation
- **Main Docs:** https://docs.medusajs.com/
- **API Reference:** https://docs.medusajs.com/api/store
- **Admin API:** https://docs.medusajs.com/api/admin
- **Deployment:** https://docs.medusajs.com/learn/deployment

### Community
- **Discord:** https://discord.gg/medusajs
- **GitHub:** https://github.com/medusajs/medusa
- **Twitter:** https://twitter.com/medusajs

### GCP Resources
- **Compute Engine:** https://cloud.google.com/compute/docs
- **Firewall Rules:** https://cloud.google.com/vpc/docs/firewalls
- **Load Balancing:** https://cloud.google.com/load-balancing/docs

## 🤝 Contributing

### Report Issues
1. Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) first
2. Search existing GitHub issues
3. Create new issue with:
   - Clear description
   - Steps to reproduce
   - Expected vs actual behavior
   - Logs and error messages

### Submit Changes
1. Fork the repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

## 📝 Documentation Updates

To update this documentation:

```bash
# Edit documentation files
cd ~/medusa-backend/docs
nano CURRENT_STATE.md  # Update current state
nano TROUBLESHOOTING.md  # Add new solutions
nano SETUP_GUIDE.md  # Update setup steps
nano API_REFERENCE.md  # Add new endpoints

# Commit changes
git add docs/
git commit -m "docs: Update documentation"
git push origin main
```

## 🆘 Getting Help

### Quick Help
1. Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Review [CURRENT_STATE.md](./CURRENT_STATE.md)
3. Search [Medusa Discord](https://discord.gg/medusajs)
4. Check [GitHub Issues](https://github.com/medusajs/medusa/issues)

### Escalation Path
1. **Application Issues:** Medusa Discord community
2. **Infrastructure Issues:** GCP Support
3. **Deployment Issues:** Check this repository's issues
4. **Urgent Production Issues:** Contact system administrator

## 📅 Maintenance Schedule

### Daily
- Monitor PM2 status
- Check error logs
- Verify health endpoint

### Weekly
- Review resource usage
- Check for security updates
- Backup database

### Monthly
- Update dependencies
- Review and rotate secrets
- Performance optimization
- Documentation updates

## 🎯 Roadmap

### Short Term (Current Sprint)
- [ ] Debug admin/store routes 404 issue
- [ ] Configure firewall rules
- [ ] Set up SSL/TLS with nginx
- [ ] Downgrade VM to e2-micro

### Medium Term
- [ ] Configure Redis session store
- [ ] Set up automated backups
- [ ] Implement monitoring & alerting
- [ ] Create CI/CD pipeline

### Long Term
- [ ] Migrate to Cloud SQL (managed PostgreSQL)
- [ ] Set up Redis cluster
- [ ] Implement autoscaling
- [ ] Multi-region deployment

## 📄 License

This deployment configuration and documentation is provided as-is. Medusa itself is licensed under MIT License.

---

## Quick Reference Card

```bash
# Essential Commands
pm2 status                    # Check status
pm2 logs                      # View logs
pm2 restart all               # Restart all
curl localhost:9000/health    # Health check

# Database
psql -U medusa -d medusa      # Connect to DB
npx medusa migrations run     # Run migrations
npx medusa user -e EMAIL -p PASS  # Create admin

# System
df -h                         # Disk space
free -h                       # Memory
sudo systemctl status postgresql redis-server  # Services

# Deployment
git pull                      # Update code
npm run build                 # Build
pm2 restart all               # Apply changes
```

---

*For detailed information, see the individual documentation files.*

*Last Updated: October 7, 2025*
