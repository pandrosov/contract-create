#!/bin/bash

# Server Configuration Check Script
# Usage: ./check_server.sh [--ssh-agent] [--key-path /path/to/key]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SERVER_IP="178.172.138.229"
REMOTE_USER="root"
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

echo -e "${GREEN}🔍 Checking server configuration...${NC}"
echo -e "${BLUE}Server: $SERVER_IP${NC}"
echo -e "${BLUE}User: $REMOTE_USER${NC}"
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

# Function to check command result
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
    fi
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

echo -e "${GREEN}📋 Step 1: Basic system information...${NC}"

echo -e "${BLUE}System information:${NC}"
remote_exec "uname -a"
check_result "System info"

echo -e "${BLUE}OS release:${NC}"
remote_exec "cat /etc/os-release"
check_result "OS release"

echo -e "${BLUE}Uptime:${NC}"
remote_exec "uptime"
check_result "Uptime"

echo -e "${GREEN}📋 Step 2: Hardware resources...${NC}"

echo -e "${BLUE}CPU information:${NC}"
remote_exec "lscpu | grep 'Model name'"
check_result "CPU info"

echo -e "${BLUE}Memory usage:${NC}"
remote_exec "free -h"
check_result "Memory info"

echo -e "${BLUE}Disk usage:${NC}"
remote_exec "df -h"
check_result "Disk info"

echo -e "${GREEN}📋 Step 3: Docker installation...${NC}"

echo -e "${BLUE}Docker version:${NC}"
remote_exec "docker --version"
check_result "Docker installation"

echo -e "${BLUE}Docker Compose version:${NC}"
remote_exec "docker-compose --version"
check_result "Docker Compose installation"

echo -e "${BLUE}Docker service status:${NC}"
remote_exec "systemctl is-active docker"
check_result "Docker service"

echo -e "${GREEN}📋 Step 4: Existing containers...${NC}"

echo -e "${BLUE}Running containers:${NC}"
remote_exec "docker ps"
check_result "Running containers"

echo -e "${BLUE}All containers:${NC}"
remote_exec "docker ps -a"
check_result "All containers"

echo -e "${BLUE}Docker volumes:${NC}"
remote_exec "docker volume ls"
check_result "Docker volumes"

echo -e "${BLUE}Docker networks:${NC}"
remote_exec "docker network ls"
check_result "Docker networks"

echo -e "${GREEN}📋 Step 5: Network configuration...${NC}"

echo -e "${BLUE}Network interfaces:${NC}"
remote_exec "ip addr show"
check_result "Network interfaces"

echo -e "${BLUE}Open ports:${NC}"
remote_exec "netstat -tlnp"
check_result "Open ports"

echo -e "${BLUE}Firewall status:${NC}"
remote_exec "ufw status"
check_result "Firewall status"

echo -e "${GREEN}📋 Step 6: Package management...${NC}"

echo -e "${BLUE}Package manager:${NC}"
remote_exec "which apt-get || which yum || which dnf"
check_result "Package manager"

echo -e "${BLUE}Available updates:${NC}"
remote_exec "apt list --upgradable 2>/dev/null | head -10 || yum check-update 2>/dev/null | head -10"
check_result "Available updates"

echo -e "${GREEN}📋 Step 7: Git installation...${NC}"

echo -e "${BLUE}Git version:${NC}"
remote_exec "git --version"
check_result "Git installation"

echo -e "${GREEN}📋 Step 8: SSL certificates...${NC}"

echo -e "${BLUE}OpenSSL version:${NC}"
remote_exec "openssl version"
check_result "OpenSSL installation"

echo -e "${GREEN}📋 Step 9: Directory permissions...${NC}"

echo -e "${BLUE}Creating test directory:${NC}"
remote_exec "mkdir -p /opt/contract-manager && ls -la /opt/"
check_result "Directory creation"

echo -e "${GREEN}📋 Step 10: Port availability...${NC}"

echo -e "${BLUE}Checking port 80:${NC}"
remote_exec "netstat -tlnp | grep :80 || echo 'Port 80 is free'"
check_result "Port 80"

echo -e "${BLUE}Checking port 443:${NC}"
remote_exec "netstat -tlnp | grep :443 || echo 'Port 443 is free'"
check_result "Port 443"

echo -e "${BLUE}Checking port 8000:${NC}"
remote_exec "netstat -tlnp | grep :8000 || echo 'Port 8000 is free'"
check_result "Port 8000"

echo -e "${BLUE}Checking port 5437:${NC}"
remote_exec "netstat -tlnp | grep :5437 || echo 'Port 5437 is free'"
check_result "Port 5437"

echo -e "${GREEN}📋 Step 11: DNS resolution...${NC}"

echo -e "${BLUE}Checking DNS resolution:${NC}"
remote_exec "nslookup contract.alnilam.by || echo 'DNS resolution failed'"
check_result "DNS resolution"

echo -e "${GREEN}📋 Step 12: Summary...${NC}"

echo -e "${YELLOW}📊 Server Configuration Summary:${NC}"
echo "Server IP: $SERVER_IP"
echo "User: $REMOTE_USER"
echo "SSH Agent: $USE_SSH_AGENT"
if [ -n "$SSH_KEY_PATH" ]; then
    echo "SSH Key: $SSH_KEY_PATH"
fi
echo ""

echo -e "${YELLOW}🔧 Recommendations:${NC}"
echo "1. Ensure all required ports are free (80, 443, 8000, 5437)"
echo "2. Configure firewall rules if needed"
echo "3. Set up SSL certificates for production"
echo "4. Configure DNS to point to $SERVER_IP"
echo "5. Set up regular backups"
echo ""

echo -e "${GREEN}✅ Server configuration check completed!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Run: ./deploy_alnilam.sh"
echo "2. Or run manual deployment steps"
echo "3. Configure domain DNS settings"
echo ""
echo -e "${GREEN}🚀 Ready for deployment!${NC}" 