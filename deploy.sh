#!/bin/bash

###############################################################################
# Medusa Backend Deployment Script
# This script deploys/updates the MedusaJS application on the VM
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="$HOME/medusa-app"
REPO_URL="https://github.com/yourusername/medusa-backend.git"  # Update this!
BRANCH="main"

echo "=========================================="
echo "MedusaJS Deployment Script"
echo "=========================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verify prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"
if ! command_exists node; then
    echo -e "${RED}Error: Node.js is not installed. Run setup-vm.sh first.${NC}"
    exit 1
fi

if ! command_exists pm2; then
    echo -e "${RED}Error: PM2 is not installed. Run setup-vm.sh first.${NC}"
    exit 1
fi

if ! command_exists psql; then
    echo -e "${RED}Error: PostgreSQL is not installed. Run setup-vm.sh first.${NC}"
    exit 1
fi

if ! command_exists redis-cli; then
    echo -e "${RED}Error: Redis is not installed. Run setup-vm.sh first.${NC}"
    exit 1
fi

# Check if this is first deployment or update
if [ -d "$APP_DIR" ]; then
    echo -e "${YELLOW}Existing installation detected. This will update the application.${NC}"
    IS_UPDATE=true
else
    echo -e "${GREEN}First time deployment.${NC}"
    IS_UPDATE=false
fi

# Clone or pull repository
if [ "$IS_UPDATE" = false ]; then
    echo -e "${GREEN}Step 1: Cloning repository...${NC}"

    # Check if we should use create-medusa-app instead
    read -p "Use create-medusa-app to initialize? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd $HOME
        npx create-medusa-app@latest medusa-app

        echo -e "${YELLOW}Manual configuration required:${NC}"
        echo "  1. Copy .env.production.example to .env"
        echo "  2. Update database credentials in .env"
        echo "  3. Configure CORS settings in medusa-config.ts"
        echo "  4. Create admin user"

        read -p "Press enter when configuration is complete..."
    else
        git clone -b $BRANCH $REPO_URL $APP_DIR
        cd $APP_DIR
    fi
else
    echo -e "${GREEN}Step 1: Updating repository...${NC}"
    cd $APP_DIR

    # Stash any local changes
    git stash

    # Pull latest changes
    git pull origin $BRANCH
fi

# Create logs directory
echo -e "${GREEN}Step 2: Setting up log directory...${NC}"
mkdir -p $APP_DIR/logs

# Check if .env file exists
if [ ! -f "$APP_DIR/.env" ]; then
    echo -e "${YELLOW}Warning: .env file not found!${NC}"
    if [ -f "$APP_DIR/.env.production.example" ]; then
        echo -e "${YELLOW}Copying .env.production.example to .env${NC}"
        cp $APP_DIR/.env.production.example $APP_DIR/.env
        echo -e "${RED}⚠️  IMPORTANT: Update .env with your production credentials before continuing!${NC}"
        read -p "Press enter when .env is configured..."
    else
        echo -e "${RED}Error: No .env.production.example found. Please create .env manually.${NC}"
        exit 1
    fi
fi

# Install dependencies
echo -e "${GREEN}Step 3: Installing dependencies...${NC}"
npm install --production

# Build the application
echo -e "${GREEN}Step 4: Building application...${NC}"
npm run build

# Run database migrations
echo -e "${GREEN}Step 5: Running database migrations...${NC}"
npx medusa migrations run

# Create admin user (only on first deployment)
if [ "$IS_UPDATE" = false ]; then
    echo -e "${GREEN}Step 6: Creating admin user...${NC}"
    echo -e "${YELLOW}Enter admin credentials:${NC}"
    read -p "Admin email: " ADMIN_EMAIL
    read -s -p "Admin password: " ADMIN_PASSWORD
    echo

    npx medusa user -e "$ADMIN_EMAIL" -p "$ADMIN_PASSWORD"
else
    echo -e "${YELLOW}Step 6: Skipping admin user creation (update deployment)${NC}"
fi

# Stop existing PM2 processes (if updating)
if [ "$IS_UPDATE" = true ]; then
    echo -e "${GREEN}Step 7: Stopping existing processes...${NC}"
    pm2 stop ecosystem.config.js || true
    pm2 delete ecosystem.config.js || true
fi

# Copy ecosystem config if it exists in repo
if [ -f "$APP_DIR/ecosystem.config.js" ]; then
    echo -e "${GREEN}Step 8: Using ecosystem.config.js from repository${NC}"
else
    echo -e "${RED}Error: ecosystem.config.js not found in repository${NC}"
    exit 1
fi

# Start application with PM2
echo -e "${GREEN}Step 9: Starting application with PM2...${NC}"
pm2 start ecosystem.config.js --env production

# Save PM2 process list
pm2 save

# Display status
echo -e "${GREEN}Step 10: Checking application status...${NC}"
sleep 3
pm2 status

# Display logs
echo ""
echo -e "${BLUE}=========================================="
echo "Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo "Application Status:"
pm2 list
echo ""
echo "To view logs:"
echo "  • All processes:    pm2 logs"
echo "  • Backend only:     pm2 logs medusa-backend"
echo "  • Worker only:      pm2 logs medusa-worker"
echo ""
echo "Useful commands:"
echo "  • Restart:          pm2 restart ecosystem.config.js"
echo "  • Stop:             pm2 stop ecosystem.config.js"
echo "  • Monitor:          pm2 monit"
echo "  • View dashboard:   pm2 plus"
echo ""
echo "Access your application:"
echo "  • Backend API:      http://$(hostname -I | awk '{print $1}'):9000"
echo "  • Admin Dashboard:  http://$(hostname -I | awk '{print $1}'):9000/app"
echo ""
if command_exists nginx && systemctl is-active --quiet nginx; then
    echo "  • Via Nginx:        http://$(hostname -I | awk '{print $1}')"
    echo ""
fi

echo -e "${YELLOW}⚠️  Don't forget to:${NC}"
echo "  1. Configure your GCP firewall rules to allow traffic"
echo "  2. Set up SSL/TLS certificates if using HTTPS"
echo "  3. Update CORS settings for your Cloud Run storefront"
echo ""
