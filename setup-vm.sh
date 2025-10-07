#!/bin/bash

###############################################################################
# Medusa Backend VM Setup Script
# This script sets up a GCP Compute Engine VM for running MedusaJS backend
# Includes: Node.js, PostgreSQL, Redis, PM2
###############################################################################

set -e  # Exit on error

echo "=========================================="
echo "MedusaJS VM Setup Script"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please do not run as root. Run as a regular user with sudo privileges.${NC}"
    exit 1
fi

echo -e "${GREEN}Step 1: Updating system packages...${NC}"
sudo apt-get update
sudo apt-get upgrade -y

echo -e "${GREEN}Step 2: Installing essential tools...${NC}"
sudo apt-get install -y curl wget git build-essential

echo -e "${GREEN}Step 3: Installing Node.js v20...${NC}"
# Install Node.js 20.x using NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
node --version
npm --version

echo -e "${GREEN}Step 4: Installing PostgreSQL...${NC}"
sudo apt-get install -y postgresql postgresql-contrib

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

echo -e "${GREEN}Step 5: Configuring PostgreSQL database...${NC}"
# Create medusa database and user
sudo -u postgres psql << EOF
-- Create medusa user (change password in production!)
CREATE USER medusa WITH PASSWORD 'medusa_password_change_me';

-- Create medusa database
CREATE DATABASE medusa;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE medusa TO medusa;

-- Connect to medusa database and grant schema privileges
\c medusa
GRANT ALL ON SCHEMA public TO medusa;
ALTER DATABASE medusa OWNER TO medusa;

\q
EOF

echo -e "${YELLOW}PostgreSQL database 'medusa' created with user 'medusa'${NC}"
echo -e "${YELLOW}⚠️  IMPORTANT: Change the default password in production!${NC}"

echo -e "${GREEN}Step 6: Installing Redis...${NC}"
sudo apt-get install -y redis-server

# Configure Redis to start on boot
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Test Redis
redis-cli ping

echo -e "${GREEN}Step 7: Installing PM2 globally...${NC}"
sudo npm install -g pm2

# Configure PM2 to start on boot
sudo pm2 startup systemd -u $USER --hp $HOME

echo -e "${GREEN}Step 8: Configuring firewall (UFW)...${NC}"
# Install UFW if not already installed
sudo apt-get install -y ufw

# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS (if using nginx)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow Medusa backend (optional - if you want direct access)
# sudo ufw allow 9000/tcp

# Enable firewall
sudo ufw --force enable

echo -e "${GREEN}Step 9: Creating application directory...${NC}"
APP_DIR="$HOME/medusa-app"
mkdir -p $APP_DIR

echo -e "${GREEN}Step 10: Installing nginx (optional reverse proxy)...${NC}"
read -p "Do you want to install nginx as a reverse proxy? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo apt-get install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo -e "${GREEN}Nginx installed and enabled${NC}"
else
    echo -e "${YELLOW}Skipping nginx installation${NC}"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "VM Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "Summary of installed services:"
echo "  • Node.js version: $(node --version)"
echo "  • npm version: $(npm --version)"
echo "  • PostgreSQL: Running on port 5432"
echo "  • Redis: Running on port 6379"
echo "  • PM2: Installed globally"
echo ""
echo "Database Configuration:"
echo "  • Database: medusa"
echo "  • User: medusa"
echo "  • Password: medusa_password_change_me (⚠️  CHANGE THIS!)"
echo "  • Connection string: postgresql://medusa:medusa_password_change_me@localhost:5432/medusa"
echo ""
echo "Application Directory: $APP_DIR"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Clone your medusa-backend repository to $APP_DIR"
echo "  2. Update .env file with production credentials"
echo "  3. Run the deploy.sh script to install and start the application"
echo ""
