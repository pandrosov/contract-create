#!/bin/bash

# Deployment script for contract.alnilam.by
# Usage: ./deploy_alnilam.sh [--ssh-agent] [--key-path /path/to/key]

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
SSH_OPTIONS=""
USE_SSH_AGENT=false
SSH_KEY_PATH=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --ssh-agent)
            USE_SSH_AGENT=true
            shift
            ;;
        --key-path)
            SSH_KEY_PATH="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --ssh-agent     Use SSH agent for key management"
            echo "  --key-path PATH Specify custom SSH key path"
            echo "  --help          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}🚀 Starting deployment for $DOMAIN...${NC}"
echo -e "${BLUE}Server IP: $SERVER_IP${NC}"
echo -e "${BLUE}Domain: $DOMAIN${NC}"
echo -e "${BLUE}WWW Domain: $WWW_DOMAIN${NC}"
echo -e "${BLUE}Remote user: $REMOTE_USER${NC}"
echo -e "${BLUE}SSH Agent: $USE_SSH_AGENT${NC}"
if [ -n "$SSH_KEY_PATH" ]; then
    echo -e "${BLUE}SSH Key: $SSH_KEY_PATH${NC}"
fi
echo ""

# Setup SSH options
if [ "$USE_SSH_AGENT" = true ]; then
    echo -e "${BLUE}🔑 Using SSH agent...${NC}"
    # Check if ssh-agent is running
    if ! ssh-add -l >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  SSH agent is not running. Starting it...${NC}"
        eval $(ssh-agent -s)
        echo -e "${GREEN}✅ SSH agent started${NC}"
    fi
    
    # Add default key to agent
    if [ -f ~/.ssh/id_rsa ]; then
        ssh-add ~/.ssh/id_rsa 2>/dev/null || echo -e "${YELLOW}⚠️  Could not add default key to agent${NC}"
    fi
    
    SSH_OPTIONS="-o StrictHostKeyChecking=no"
elif [ -n "$SSH_KEY_PATH" ]; then
    echo -e "${BLUE}🔑 Using custom SSH key: $SSH_KEY_PATH${NC}"
    SSH_OPTIONS="-o StrictHostKeyChecking=no -i $SSH_KEY_PATH"
else
    echo -e "${BLUE}🔑 Using default SSH configuration${NC}"
    SSH_OPTIONS="-o StrictHostKeyChecking=no"
fi

# Function to execute remote command
remote_exec() {
    ssh $SSH_OPTIONS $REMOTE_USER@$SERVER_IP "$1"
}

# Function to copy files
remote_copy() {
    scp $SSH_OPTIONS -r $1 $REMOTE_USER@$SERVER_IP:$2
}

# Test SSH connection first
echo -e "${GREEN}📋 Step 0: Testing SSH connection...${NC}"
if remote_exec "echo 'SSH connection test successful'" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ SSH connection established${NC}"
else
    echo -e "${RED}❌ SSH connection failed${NC}"
    echo -e "${YELLOW}💡 Tips:${NC}"
    echo "1. Make sure your SSH key is added to the server"
    echo "2. Try: ssh-copy-id root@$SERVER_IP"
    echo "3. Or use: $0 --ssh-agent"
    echo "4. Or use: $0 --key-path /path/to/your/key"
    exit 1
fi

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

# Check if directory exists and handle it
echo "Checking project directory..."
if remote_exec "[ -d $REMOTE_PATH ]"; then
    echo -e "${YELLOW}⚠️  Directory $REMOTE_PATH already exists${NC}"
    echo "Checking contents..."
    remote_exec "ls -la $REMOTE_PATH"
    
    echo -e "${BLUE}Backing up existing directory...${NC}"
    remote_exec "mv $REMOTE_PATH ${REMOTE_PATH}_backup_$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✅ Existing directory backed up${NC}"
    
    # Ensure the directory is completely removed
    echo "Ensuring directory is completely removed..."
    remote_exec "rm -rf $REMOTE_PATH"
fi

# Create fresh project directory
echo "Creating fresh project directory..."
remote_exec "mkdir -p $REMOTE_PATH"

echo -e "${GREEN}✅ Step 2 completed${NC}"

echo -e "${GREEN}📦 Step 3: Cloning repository...${NC}"

# Clone repository into a temporary directory and then move files
echo "Cloning repository to temporary location..."
remote_exec "cd /opt && git clone -b master $REPO_URL contract-manager-temp"

echo "Moving files to final location..."
remote_exec "cp -r /opt/contract-manager-temp/* $REMOTE_PATH/"
remote_exec "cp -r /opt/contract-manager-temp/.* $REMOTE_PATH/ 2>/dev/null || true"
remote_exec "rm -rf /opt/contract-manager-temp"

echo "Switching to project directory..."
remote_exec "cd $REMOTE_PATH"

echo "Verifying files were copied correctly..."
remote_exec "ls -la"

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
echo "6. Previous deployment was backed up to ${REMOTE_PATH}_backup_*"
echo ""
echo -e "${GREEN}🚀 Your application is now live at https://$DOMAIN!${NC}" 