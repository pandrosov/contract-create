#!/bin/bash

# Deployment script for contract.alnilam.by
# Usage: ./deploy_alnilam.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SERVER_IP="178.172.138.229"
DOMAIN="contract.alnilam.by"
WWW_DOMAIN="www.contract.alnilam.by"
REMOTE_USER="root"
REMOTE_PATH="/opt/contract-manager"
REPO_URL="https://github.com/pandrosov/contract-create.git"

echo -e "${GREEN}🚀 Starting deployment for $DOMAIN...${NC}"
echo -e "${BLUE}Server IP: $SERVER_IP${NC}"
echo -e "${BLUE}Domain: $DOMAIN${NC}"
echo -e "${BLUE}WWW Domain: $WWW_DOMAIN${NC}"
echo -e "${BLUE}Remote user: $REMOTE_USER${NC}"
echo ""

# Function to execute remote command
remote_exec() {
    ssh -o StrictHostKeyChecking=no $REMOTE_USER@$SERVER_IP "$1"
}

# Function to copy files
remote_copy() {
    scp -o StrictHostKeyChecking=no -r $1 $REMOTE_USER@$SERVER_IP:$2
}

echo -e "${GREEN}📋 Step 1: Checking server configuration...${NC}"

# Check system info
echo "Checking system information..."
remote_exec "uname -a"
remote_exec "cat /etc/os-release"

# Check Docker installation
echo "Checking Docker installation..."
remote_exec "docker --version"
remote_exec "docker-compose --version"

# Check existing containers
echo "Checking existing containers..."
remote_exec "docker ps -a"

# Check disk space
echo "Checking disk space..."
remote_exec "df -h"

# Check memory
echo "Checking memory..."
remote_exec "free -h"

echo -e "${GREEN}✅ Step 1 completed${NC}"

echo -e "${GREEN}📁 Step 2: Setting up project directory...${NC}"

# Create project directory
remote_exec "mkdir -p $REMOTE_PATH"
remote_exec "cd $REMOTE_PATH"

echo -e "${GREEN}✅ Step 2 completed${NC}"

echo -e "${GREEN}📦 Step 3: Cloning repository...${NC}"

# Clone repository
remote_exec "git clone -b master $REPO_URL ."

echo -e "${GREEN}✅ Step 3 completed${NC}"

echo -e "${GREEN}🔧 Step 4: Configuring environment...${NC}"

# Create .env file
remote_exec "cp env.example .env"

# Generate secure passwords
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
SECRET_KEY=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)

# Update .env file
remote_exec "sed -i 's/your_secure_database_password_here/$DB_PASSWORD/g' .env"
remote_exec "sed -i 's/your-super-secret-key-change-this-in-production/$SECRET_KEY/g' .env"
remote_exec "sed -i 's/your-domain.com/$DOMAIN/g' .env"
remote_exec "sed -i 's|http://localhost:3000,https://your-domain.com|https://$DOMAIN,https://$WWW_DOMAIN|g' .env"
remote_exec "sed -i 's|https://your-domain.com/api|https://$DOMAIN/api|g' .env"

echo -e "${GREEN}✅ Step 4 completed${NC}"

echo -e "${GREEN}🔒 Step 5: Setting up SSL certificates...${NC}"

# Create SSL directory
remote_exec "mkdir -p nginx/ssl"

# Generate self-signed certificate
remote_exec "openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout nginx/ssl/key.pem -out nginx/ssl/cert.pem -subj \"/C=BY/ST=Minsk/L=Minsk/O=Alnilam/CN=$DOMAIN\""

echo -e "${GREEN}✅ Step 5 completed${NC}"

echo -e "${GREEN}🚀 Step 6: Starting deployment...${NC}"

# Make deploy script executable
remote_exec "chmod +x deploy.sh"

# Run deployment
remote_exec "./deploy.sh production"

echo -e "${GREEN}✅ Step 6 completed${NC}"

echo -e "${GREEN}🔍 Step 7: Verifying deployment...${NC}"

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 30

# Check if services are running
echo "Checking service status..."
remote_exec "docker-compose -f docker-compose.prod.yaml ps"

# Test frontend
echo "Testing frontend..."
if remote_exec "curl -f http://localhost > /dev/null 2>&1"; then
    echo -e "${GREEN}✅ Frontend is accessible${NC}"
else
    echo -e "${RED}❌ Frontend is not accessible${NC}"
fi

# Test API
echo "Testing API..."
if remote_exec "curl -f http://localhost:8000/health > /dev/null 2>&1"; then
    echo -e "${GREEN}✅ API is accessible${NC}"
else
    echo -e "${RED}❌ API is not accessible${NC}"
fi

echo -e "${GREEN}✅ Step 7 completed${NC}"

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Deployment Information:${NC}"
echo "Server IP: $SERVER_IP"
echo "Domain: $DOMAIN"
echo "WWW Domain: $WWW_DOMAIN"
echo "Frontend URL: https://$DOMAIN"
echo "API URL: https://$DOMAIN/api"
echo "Admin credentials: admin/admin"
echo ""
echo -e "${YELLOW}🔧 Useful commands:${NC}"
echo "SSH to server: ssh $REMOTE_USER@$SERVER_IP"
echo "View logs: ssh $REMOTE_USER@$SERVER_IP 'cd $REMOTE_PATH && docker-compose -f docker-compose.prod.yaml logs -f'"
echo "Restart services: ssh $REMOTE_USER@$SERVER_IP 'cd $REMOTE_PATH && docker-compose -f docker-compose.prod.yaml restart'"
echo "Update from repository: ssh $REMOTE_USER@$SERVER_IP 'cd $REMOTE_PATH && git pull origin master && docker-compose -f docker-compose.prod.yaml up --build -d'"
echo ""
echo -e "${YELLOW}⚠️  Important notes:${NC}"
echo "1. Change default admin password after first login"
echo "2. Consider using Let's Encrypt for production SSL certificates"
echo "3. Configure your domain DNS to point to $SERVER_IP"
echo "4. Set up regular backups"
echo "5. This deployment uses the master branch (production-ready)"
echo ""
echo -e "${GREEN}🚀 Your application is now live at https://$DOMAIN!${NC}" 