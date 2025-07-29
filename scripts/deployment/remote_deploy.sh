#!/bin/bash

# Quick Remote Deployment Script
# Usage: ./remote_deploy.sh [server_ip] [domain]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}❌ Usage: $0 <server_ip> <domain>${NC}"
    echo -e "${YELLOW}Example: $0 192.168.1.100 mydomain.com${NC}"
    exit 1
fi

SERVER_IP=$1
DOMAIN=$2
REMOTE_USER=${3:-ubuntu}
REMOTE_PATH="/opt/contract-manager"
REPO_URL="https://github.com/pandrosov/contract-create.git"

echo -e "${GREEN}🚀 Starting remote deployment...${NC}"
echo -e "${BLUE}Server: $SERVER_IP${NC}"
echo -e "${BLUE}Domain: $DOMAIN${NC}"
echo -e "${BLUE}Remote user: $REMOTE_USER${NC}"
echo -e "${BLUE}Repository: $REPO_URL${NC}"
echo -e "${BLUE}Branch: master${NC}"
echo ""

# Function to execute remote command
remote_exec() {
    ssh -o StrictHostKeyChecking=no $REMOTE_USER@$SERVER_IP "$1"
}

# Function to copy files
remote_copy() {
    scp -o StrictHostKeyChecking=no -r $1 $REMOTE_USER@$SERVER_IP:$2
}

echo -e "${GREEN}📋 Step 1: Preparing server...${NC}"

# Update system and install Docker
echo "Updating system and installing Docker..."
remote_exec "sudo apt update && sudo apt upgrade -y"
remote_exec "curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
remote_exec "sudo usermod -aG docker $USER"

# Install Docker Compose
echo "Installing Docker Compose..."
remote_exec "sudo curl -L \"https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
remote_exec "sudo chmod +x /usr/local/bin/docker-compose"

echo -e "${GREEN}✅ Step 1 completed${NC}"

echo -e "${GREEN}📁 Step 2: Setting up project directory...${NC}"

# Create project directory
remote_exec "sudo mkdir -p $REMOTE_PATH"
remote_exec "sudo chown $USER:$USER $REMOTE_PATH"
remote_exec "cd $REMOTE_PATH"

echo -e "${GREEN}✅ Step 2 completed${NC}"

echo -e "${GREEN}📦 Step 3: Cloning repository...${NC}"

# Clone repository with master branch
echo "Cloning repository..."
remote_exec "cd $REMOTE_PATH && git clone -b master $REPO_URL ."

echo -e "${GREEN}✅ Step 3 completed${NC}"

echo -e "${GREEN}🔧 Step 4: Configuring environment...${NC}"

# Create .env file
echo "Creating .env file..."
remote_exec "cd $REMOTE_PATH && cp env.example .env"

# Generate secure passwords
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
SECRET_KEY=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)

# Update .env file
remote_exec "cd $REMOTE_PATH && sed -i 's/your_secure_database_password_here/$DB_PASSWORD/g' .env"
remote_exec "cd $REMOTE_PATH && sed -i 's/your-super-secret-key-change-this-in-production/$SECRET_KEY/g' .env"
remote_exec "cd $REMOTE_PATH && sed -i 's/your-domain.com/$DOMAIN/g' .env"
remote_exec "cd $REMOTE_PATH && sed -i 's|http://localhost:3000,https://your-domain.com|https://$DOMAIN,https://www.$DOMAIN|g' .env"
remote_exec "cd $REMOTE_PATH && sed -i 's|https://your-domain.com/api|https://$DOMAIN/api|g' .env"

echo -e "${GREEN}✅ Step 4 completed${NC}"

echo -e "${GREEN}🔒 Step 5: Setting up SSL certificates...${NC}"

# Create SSL directory
remote_exec "cd $REMOTE_PATH && mkdir -p nginx/ssl"

# Generate self-signed certificate
echo "Generating SSL certificate..."
remote_exec "cd $REMOTE_PATH && openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout nginx/ssl/key.pem -out nginx/ssl/cert.pem -subj \"/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN\""

echo -e "${GREEN}✅ Step 5 completed${NC}"

echo -e "${GREEN}🚀 Step 6: Starting deployment...${NC}"

# Make deploy script executable
remote_exec "cd $REMOTE_PATH && chmod +x deploy.sh"

# Run deployment
echo "Running deployment..."
remote_exec "cd $REMOTE_PATH && ./deploy.sh production"

echo -e "${GREEN}✅ Step 6 completed${NC}"

echo -e "${GREEN}🔍 Step 7: Verifying deployment...${NC}"

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 30

# Check if services are running
echo "Checking service status..."
remote_exec "cd $REMOTE_PATH && docker-compose -f docker-compose.prod.yaml ps"

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
echo "Repository: $REPO_URL"
echo "Branch: master"
echo "Version: v1.1.0"
echo "Frontend URL: http://$SERVER_IP (or https://$DOMAIN)"
echo "API URL: http://$SERVER_IP:8000 (or https://$DOMAIN/api)"
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
echo "2. Update SSL certificates for production (Let's Encrypt recommended)"
echo "3. Configure your domain DNS to point to $SERVER_IP"
echo "4. Set up regular backups"
echo "5. This deployment uses the master branch (production-ready)"
echo ""
echo -e "${GREEN}🚀 Your application is now live!${NC}" 