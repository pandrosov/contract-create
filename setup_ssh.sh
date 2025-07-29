#!/bin/bash

# SSH Setup Script
# Usage: ./setup_ssh.sh [--copy-key] [--start-agent]

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

echo -e "${GREEN}🔑 SSH Setup Script${NC}"
echo -e "${BLUE}Server: $SERVER_IP${NC}"
echo -e "${BLUE}User: $REMOTE_USER${NC}"
echo ""

# Parse command line arguments
COPY_KEY=false
START_AGENT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --copy-key)
            COPY_KEY=true
            shift
            ;;
        --start-agent)
            START_AGENT=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --copy-key      Copy SSH key to server"
            echo "  --start-agent   Start SSH agent and add key"
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

# Function to check if SSH key exists
check_ssh_key() {
    if [ -f ~/.ssh/id_rsa ]; then
        echo -e "${GREEN}✅ Found SSH key: ~/.ssh/id_rsa${NC}"
        return 0
    elif [ -f ~/.ssh/id_rsa_pandrosov ]; then
        echo -e "${GREEN}✅ Found SSH key: ~/.ssh/id_rsa_pandrosov${NC}"
        return 0
    else
        echo -e "${RED}❌ No SSH key found${NC}"
        return 1
    fi
}

# Function to copy SSH key to server
copy_ssh_key() {
    echo -e "${GREEN}📋 Step 1: Copying SSH key to server...${NC}"
    
    if ! check_ssh_key; then
        echo -e "${RED}❌ No SSH key found. Please create one first:${NC}"
        echo "ssh-keygen -t rsa -b 4096 -C 'your_email@example.com'"
        exit 1
    fi
    
    # Try to copy the key
    if [ -f ~/.ssh/id_rsa ]; then
        echo "Copying ~/.ssh/id_rsa to server..."
        ssh-copy-id -i ~/.ssh/id_rsa $REMOTE_USER@$SERVER_IP
    elif [ -f ~/.ssh/id_rsa_pandrosov ]; then
        echo "Copying ~/.ssh/id_rsa_pandrosov to server..."
        ssh-copy-id -i ~/.ssh/id_rsa_pandrosov $REMOTE_USER@$SERVER_IP
    fi
    
    echo -e "${GREEN}✅ SSH key copied to server${NC}"
}

# Function to start SSH agent
start_ssh_agent() {
    echo -e "${GREEN}📋 Step 2: Starting SSH agent...${NC}"
    
    # Check if ssh-agent is already running
    if ssh-add -l >/dev/null 2>&1; then
        echo -e "${GREEN}✅ SSH agent is already running${NC}"
    else
        echo -e "${BLUE}Starting SSH agent...${NC}"
        eval $(ssh-agent -s)
        echo -e "${GREEN}✅ SSH agent started${NC}"
    fi
    
    # Add key to agent
    if [ -f ~/.ssh/id_rsa ]; then
        echo "Adding ~/.ssh/id_rsa to SSH agent..."
        ssh-add ~/.ssh/id_rsa
    elif [ -f ~/.ssh/id_rsa_pandrosov ]; then
        echo "Adding ~/.ssh/id_rsa_pandrosov to SSH agent..."
        ssh-add ~/.ssh/id_rsa_pandrosov
    fi
    
    echo -e "${GREEN}✅ SSH key added to agent${NC}"
}

# Function to test SSH connection
test_ssh_connection() {
    echo -e "${GREEN}📋 Step 3: Testing SSH connection...${NC}"
    
    if ssh -o ConnectTimeout=5 $REMOTE_USER@$SERVER_IP "echo 'SSH connection successful'" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ SSH connection successful${NC}"
        return 0
    else
        echo -e "${RED}❌ SSH connection failed${NC}"
        return 1
    fi
}

# Main execution
echo -e "${GREEN}🔍 Checking SSH configuration...${NC}"

# Check if SSH key exists
check_ssh_key

# Copy key if requested
if [ "$COPY_KEY" = true ]; then
    copy_ssh_key
fi

# Start agent if requested
if [ "$START_AGENT" = true ]; then
    start_ssh_agent
fi

# Test connection
if test_ssh_connection; then
    echo -e "${GREEN}🎉 SSH setup completed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}📋 Next steps:${NC}"
    echo "1. Run: ./check_server.sh"
    echo "2. Run: ./deploy_alnilam.sh"
    echo ""
    echo -e "${BLUE}💡 Tips:${NC}"
    echo "- Use --ssh-agent flag for automatic key management"
    echo "- Use --key-path flag for custom key location"
    echo "- SSH agent will remember your key for this session"
else
    echo -e "${RED}❌ SSH setup failed${NC}"
    echo ""
    echo -e "${YELLOW}💡 Troubleshooting:${NC}"
    echo "1. Make sure your SSH key is correct"
    echo "2. Try: $0 --copy-key"
    echo "3. Try: $0 --start-agent"
    echo "4. Check server firewall settings"
    exit 1
fi 