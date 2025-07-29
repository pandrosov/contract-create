#!/bin/bash

# Cleanup Deployments Script
# Usage: ./cleanup_deployments.sh [--ssh-agent] [--key-path /path/to/key] [--dry-run]

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
REMOTE_PATH="/opt/contract-manager"
SSH_OPTIONS=""
USE_SSH_AGENT=false
SSH_KEY_PATH=""
DRY_RUN=false

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
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --ssh-agent     Use SSH agent for key management"
            echo "  --key-path PATH Specify custom SSH key path"
            echo "  --dry-run       Show what would be deleted without actually deleting"
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

echo -e "${GREEN}🧹 Cleanup Deployments Script${NC}"
echo -e "${BLUE}Server: $SERVER_IP${NC}"
echo -e "${BLUE}User: $REMOTE_USER${NC}"
echo -e "${BLUE}Path: $REMOTE_PATH${NC}"
echo -e "${BLUE}Dry run: $DRY_RUN${NC}"
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

# Test SSH connection first
echo -e "${GREEN}📋 Step 0: Testing SSH connection...${NC}"
if remote_exec "echo 'SSH connection test successful'" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ SSH connection established${NC}"
else
    echo -e "${RED}❌ SSH connection failed${NC}"
    exit 1
fi

echo -e "${GREEN}📋 Step 1: Checking existing deployments...${NC}"

# Check current deployment
echo "Checking current deployment..."
if remote_exec "[ -d $REMOTE_PATH ]"; then
    echo -e "${GREEN}✅ Current deployment found${NC}"
    remote_exec "ls -la $REMOTE_PATH"
else
    echo -e "${YELLOW}⚠️  No current deployment found${NC}"
fi

# Check backup directories
echo "Checking backup directories..."
BACKUP_DIRS=$(remote_exec "ls -d ${REMOTE_PATH}_backup_* 2>/dev/null || echo ''")
if [ -n "$BACKUP_DIRS" ]; then
    echo -e "${YELLOW}Found backup directories:${NC}"
    echo "$BACKUP_DIRS"
else
    echo -e "${GREEN}✅ No backup directories found${NC}"
fi

# Check Docker containers
echo "Checking Docker containers..."
CONTAINERS=$(remote_exec "docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep contract || echo 'No contract containers found'")
echo "$CONTAINERS"

# Check Docker volumes
echo "Checking Docker volumes..."
VOLUMES=$(remote_exec "docker volume ls | grep contract || echo 'No contract volumes found'")
echo "$VOLUMES"

echo -e "${GREEN}📋 Step 2: Calculating disk usage...${NC}"

# Calculate disk usage
echo "Current deployment size:"
remote_exec "du -sh $REMOTE_PATH 2>/dev/null || echo 'Directory not found'"

echo "Backup directories size:"
remote_exec "du -sh ${REMOTE_PATH}_backup_* 2>/dev/null || echo 'No backup directories'"

echo "Docker containers size:"
remote_exec "docker system df"

echo -e "${GREEN}📋 Step 3: Cleanup options...${NC}"

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🔍 DRY RUN MODE - No files will be deleted${NC}"
    echo ""
    echo -e "${BLUE}Would delete:${NC}"
    
    # Show what would be deleted
    if [ -n "$BACKUP_DIRS" ]; then
        echo "Backup directories:"
        echo "$BACKUP_DIRS"
    fi
    
    # Show old containers
    OLD_CONTAINERS=$(remote_exec "docker ps -a --filter 'name=contract' --format '{{.Names}}' | grep -v 'contract-manager' || echo ''")
    if [ -n "$OLD_CONTAINERS" ]; then
        echo "Old containers:"
        echo "$OLD_CONTAINERS"
    fi
    
    # Show old volumes
    OLD_VOLUMES=$(remote_exec "docker volume ls --filter 'name=contract' --format '{{.Name}}' | grep -v 'contract-manager' || echo ''")
    if [ -n "$OLD_VOLUMES" ]; then
        echo "Old volumes:"
        echo "$OLD_VOLUMES"
    fi
    
else
    echo -e "${RED}⚠️  WARNING: This will permanently delete files!${NC}"
    echo ""
    
    # Ask for confirmation
    read -p "Are you sure you want to proceed? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}❌ Cleanup cancelled${NC}"
        exit 0
    fi
    
    echo -e "${GREEN}📋 Step 4: Performing cleanup...${NC}"
    
    # Remove backup directories
    if [ -n "$BACKUP_DIRS" ]; then
        echo "Removing backup directories..."
        remote_exec "rm -rf ${REMOTE_PATH}_backup_*"
        echo -e "${GREEN}✅ Backup directories removed${NC}"
    fi
    
    # Remove old containers
    OLD_CONTAINERS=$(remote_exec "docker ps -a --filter 'name=contract' --format '{{.Names}}' | grep -v 'contract-manager' || echo ''")
    if [ -n "$OLD_CONTAINERS" ]; then
        echo "Removing old containers..."
        remote_exec "docker rm -f $OLD_CONTAINERS"
        echo -e "${GREEN}✅ Old containers removed${NC}"
    fi
    
    # Remove old volumes
    OLD_VOLUMES=$(remote_exec "docker volume ls --filter 'name=contract' --format '{{.Name}}' | grep -v 'contract-manager' || echo ''")
    if [ -n "$OLD_VOLUMES" ]; then
        echo "Removing old volumes..."
        remote_exec "docker volume rm $OLD_VOLUMES"
        echo -e "${GREEN}✅ Old volumes removed${NC}"
    fi
    
    # Clean up Docker system
    echo "Cleaning up Docker system..."
    remote_exec "docker system prune -f"
    echo -e "${GREEN}✅ Docker system cleaned${NC}"
    
    echo -e "${GREEN}📋 Step 5: Final disk usage...${NC}"
    remote_exec "df -h /opt"
    remote_exec "docker system df"
    
    echo -e "${GREEN}🎉 Cleanup completed successfully!${NC}"
fi

echo ""
echo -e "${YELLOW}📋 Summary:${NC}"
echo "Current deployment: $REMOTE_PATH"
echo "Backup directories: $(echo "$BACKUP_DIRS" | wc -l)"
echo "Docker containers: $(echo "$CONTAINERS" | grep -c 'contract' || echo '0')"
echo "Docker volumes: $(echo "$VOLUMES" | grep -c 'contract' || echo '0')"
echo ""
echo -e "${BLUE}💡 Tips:${NC}"
echo "- Use --dry-run to see what would be deleted"
echo "- Use --ssh-agent for automatic key management"
echo "- Backup important data before cleanup"
echo ""
echo -e "${GREEN}✅ Cleanup script completed!${NC}" 