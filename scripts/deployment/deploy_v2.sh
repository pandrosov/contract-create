#!/bin/bash

# Contract Management System v2.0 Deployment Script
# Usage: ./deploy_v2.sh [--ssh-agent] [--key-path /path/to/key] [--backup] [--rollback]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
VERSION="2.0.0"
SERVER_IP="178.172.138.229"
DOMAIN="contract.alnilam.by"
WWW_DOMAIN="www.contract.alnilam.by"
REMOTE_USER="root"
REMOTE_PATH="/opt/contract-manager"
REPO_URL="https://github.com/pandrosov/contract-create.git"
SSH_OPTIONS=""
USE_SSH_AGENT=false
SSH_KEY_PATH=""
CREATE_BACKUP=false
ROLLBACK_MODE=false

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
        --backup)
            CREATE_BACKUP=true
            shift
            ;;
        --rollback)
            ROLLBACK_MODE=true
            shift
            ;;
        --help)
            echo "Contract Management System v$VERSION Deployment Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --ssh-agent     Use SSH agent for key management"
            echo "  --key-path PATH Specify custom SSH key path"
            echo "  --backup        Create backup before deployment"
            echo "  --rollback      Rollback to previous version"
            echo "  --help          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Standard deployment"
            echo "  $0 --backup          # Deployment with backup"
            echo "  $0 --ssh-agent       # Use SSH agent"
            echo "  $0 --rollback        # Rollback to previous version"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}🚀 Contract Management System v$VERSION Deployment${NC}"
echo -e "${BLUE}Server IP: $SERVER_IP${NC}"
echo -e "${BLUE}Domain: $DOMAIN${NC}"
echo -e "${BLUE}WWW Domain: $WWW_DOMAIN${NC}"
echo -e "${BLUE}Remote user: $REMOTE_USER${NC}"
echo -e "${BLUE}SSH Agent: $USE_SSH_AGENT${NC}"
echo -e "${BLUE}Create Backup: $CREATE_BACKUP${NC}"
echo -e "${BLUE}Rollback Mode: $ROLLBACK_MODE${NC}"
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

# Function to show step progress
show_step() {
    echo -e "${CYAN}📋 Step $1: $2${NC}"
}

# Function to show success
show_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to show warning
show_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to show error
show_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Test SSH connection first
show_step "0" "Testing SSH connection..."
if remote_exec "echo 'SSH connection test successful'" >/dev/null 2>&1; then
    show_success "SSH connection established"
else
    show_error "Failed to connect to server"
    exit 1
fi

# Check server status
show_step "1" "Checking server status..."
SERVER_STATUS=$(remote_exec "cd $REMOTE_PATH && docker-compose -f docker-compose.prod.yaml ps --format json" 2>/dev/null || echo "[]")
if echo "$SERVER_STATUS" | grep -q "Up"; then
    show_success "Server is running"
else
    show_warning "Server is not running or containers are down"
fi

# Create backup if requested
if [ "$CREATE_BACKUP" = true ]; then
    show_step "2" "Creating backup..."
    remote_exec "cd $REMOTE_PATH && ./scripts/deployment/backup.sh full"
    show_success "Backup created successfully"
fi

# Rollback mode
if [ "$ROLLBACK_MODE" = true ]; then
    show_step "3" "Rolling back to previous version..."
    remote_exec "cd $REMOTE_PATH && git reset --hard HEAD~1"
    remote_exec "cd $REMOTE_PATH && docker-compose -f docker-compose.prod.yaml down"
    remote_exec "cd $REMOTE_PATH && docker-compose -f docker-compose.prod.yaml build --no-cache"
    remote_exec "cd $REMOTE_PATH && docker-compose -f docker-compose.prod.yaml up -d"
    show_success "Rollback completed"
    exit 0
fi

# Update code
show_step "3" "Updating code..."
remote_exec "cd $REMOTE_PATH && git fetch origin"
remote_exec "cd $REMOTE_PATH && git reset --hard origin/master"
COMMIT_HASH=$(remote_exec "cd $REMOTE_PATH && git rev-parse --short HEAD")
show_success "Code updated to commit: $COMMIT_HASH"

# Check new structure
show_step "4" "Checking new file structure..."
if remote_exec "cd $REMOTE_PATH && test -f app/main.py && test -f frontend/src/App.js"; then
    show_success "New file structure confirmed"
else
    show_error "New file structure not found"
    exit 1
fi

# Stop services
show_step "5" "Stopping services..."
remote_exec "cd $REMOTE_PATH && docker-compose -f docker-compose.prod.yaml down"
show_success "Services stopped"

# Rebuild containers
show_step "6" "Rebuilding containers..."
remote_exec "cd $REMOTE_PATH && docker-compose -f docker-compose.prod.yaml build --no-cache"
show_success "Containers rebuilt"

# Start services
show_step "7" "Starting services..."
remote_exec "cd $REMOTE_PATH && docker-compose -f docker-compose.prod.yaml up -d"
show_success "Services started"

# Wait for services to be ready
show_step "8" "Waiting for services to be ready..."
sleep 30

# Check service health
show_step "9" "Checking service health..."
HEALTH_CHECK=$(curl -s "https://$DOMAIN/api/health" 2>/dev/null || echo "{}")
if echo "$HEALTH_CHECK" | grep -q "healthy"; then
    show_success "Backend health check passed"
else
    show_warning "Backend health check failed"
fi

# Check frontend
FRONTEND_CHECK=$(curl -s -I "https://$DOMAIN" 2>/dev/null | head -1 || echo "")
if echo "$FRONTEND_CHECK" | grep -q "200"; then
    show_success "Frontend is accessible"
else
    show_warning "Frontend check failed"
fi

# Test SSL certificate
show_step "10" "Testing SSL certificate..."
SSL_CHECK=$(echo | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "")
if [ -n "$SSL_CHECK" ]; then
    show_success "SSL certificate is valid"
else
    show_warning "SSL certificate check failed"
fi

# Show deployment summary
echo ""
echo -e "${GREEN}🎉 Deployment Summary${NC}"
echo -e "${BLUE}Version: $VERSION${NC}"
echo -e "${BLUE}Commit: $COMMIT_HASH${NC}"
echo -e "${BLUE}Domain: https://$DOMAIN${NC}"
echo -e "${BLUE}API Health: https://$DOMAIN/api/health${NC}"
echo -e "${BLUE}Documentation: https://$DOMAIN/api/docs${NC}"
echo ""

# Show new features
echo -e "${PURPLE}🆕 New Features in v$VERSION:${NC}"
echo "• Fixed number-to-text conversion with proper Russian declension"
echo "• Added placeholder descriptions management"
echo "• Improved template management interface"
echo "• Enhanced error handling and validation"
echo "• Better CORS configuration"
echo "• Updated file structure and organization"
echo ""

show_success "Deployment completed successfully!"
echo -e "${YELLOW}💡 Tip: Monitor logs with: ssh $REMOTE_USER@$SERVER_IP 'cd $REMOTE_PATH && docker-compose -f docker-compose.prod.yaml logs -f'${NC}" 