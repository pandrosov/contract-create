#!/bin/bash

# Contract Management System v2.0 Cleanup Script
# Usage: ./cleanup_v2.sh [--docker] [--logs] [--backups] [--all] [--dry-run]

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
CLEANUP_DOCKER=false
CLEANUP_LOGS=false
CLEANUP_BACKUPS=false
CLEANUP_ALL=false
DRY_RUN=false
BACKUP_RETENTION_DAYS=30
LOG_RETENTION_DAYS=7

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --docker)
            CLEANUP_DOCKER=true
            shift
            ;;
        --logs)
            CLEANUP_LOGS=true
            shift
            ;;
        --backups)
            CLEANUP_BACKUPS=true
            shift
            ;;
        --all)
            CLEANUP_ALL=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            echo "Contract Management System v$VERSION Cleanup Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --docker    Clean up Docker resources (images, containers, volumes)"
            echo "  --logs      Clean up old log files"
            echo "  --backups   Clean up old backup files"
            echo "  --all       Perform all cleanup operations"
            echo "  --dry-run   Show what would be cleaned without actually doing it"
            echo "  --help      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --docker --dry-run"
            echo "  $0 --all"
            echo "  $0 --logs --backups"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}🧹 Contract Management System v$VERSION Cleanup${NC}"
echo "Docker cleanup: $CLEANUP_DOCKER"
echo "Logs cleanup: $CLEANUP_LOGS"
echo "Backups cleanup: $CLEANUP_BACKUPS"
echo "All cleanup: $CLEANUP_ALL"
echo "Dry run: $DRY_RUN"
echo ""

# Function to show step
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

# Function to show info
show_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to execute command with dry run support
execute_cmd() {
    local cmd="$1"
    local description="$2"
    
    if [ "$DRY_RUN" = true ]; then
        echo "DRY RUN: $description"
        echo "Would execute: $cmd"
    else
        echo "Executing: $description"
        eval "$cmd"
    fi
}

# Initialize cleanup summary
CLEANUP_SUMMARY=""

# Docker cleanup
if [ "$CLEANUP_DOCKER" = true ] || [ "$CLEANUP_ALL" = true ]; then
    show_step "1" "Cleaning up Docker resources..."
    
    # Stop and remove containers
    execute_cmd "docker-compose -f docker-compose.prod.yaml down" "Stopping containers"
    
    # Remove unused containers
    execute_cmd "docker container prune -f" "Removing unused containers"
    
    # Remove unused images
    execute_cmd "docker image prune -a -f" "Removing unused images"
    
    # Remove unused volumes
    execute_cmd "docker volume prune -f" "Removing unused volumes"
    
    # Remove unused networks
    execute_cmd "docker network prune -f" "Removing unused networks"
    
    # Clean up build cache
    execute_cmd "docker builder prune -f" "Cleaning build cache"
    
    show_success "Docker cleanup completed"
    CLEANUP_SUMMARY="$CLEANUP_SUMMARY\n• Docker resources cleaned"
fi

# Logs cleanup
if [ "$CLEANUP_LOGS" = true ] || [ "$CLEANUP_ALL" = true ]; then
    show_step "2" "Cleaning up log files..."
    
    # Remove old application logs
    execute_cmd "find . -name '*.log' -mtime +$LOG_RETENTION_DAYS -delete" "Removing old log files"
    
    # Remove Docker logs
    execute_cmd "sudo truncate -s 0 /var/lib/docker/containers/*/*-json.log" "Truncating Docker logs"
    
    # Remove system logs (if accessible)
    if [ -d "/var/log" ]; then
        execute_cmd "sudo find /var/log -name '*.log' -mtime +$LOG_RETENTION_DAYS -delete" "Removing old system logs"
    fi
    
    show_success "Logs cleanup completed"
    CLEANUP_SUMMARY="$CLEANUP_SUMMARY\n• Log files cleaned"
fi

# Backups cleanup
if [ "$CLEANUP_BACKUPS" = true ] || [ "$CLEANUP_ALL" = true ]; then
    show_step "3" "Cleaning up backup files..."
    
    # Remove old database backups
    execute_cmd "find ./backups -name 'db_backup_*.sql*' -mtime +$BACKUP_RETENTION_DAYS -delete" "Removing old database backups"
    
    # Remove old files backups
    execute_cmd "find ./backups -name 'files_backup_*.tar.gz' -mtime +$BACKUP_RETENTION_DAYS -delete" "Removing old files backups"
    
    # Remove old templates backups
    execute_cmd "find ./backups -name 'templates_backup_*.tar.gz' -mtime +$BACKUP_RETENTION_DAYS -delete" "Removing old templates backups"
    
    # Remove old config backups
    execute_cmd "find ./backups -name '*_backup_*' -mtime +$BACKUP_RETENTION_DAYS -delete" "Removing old config backups"
    
    show_success "Backups cleanup completed"
    CLEANUP_SUMMARY="$CLEANUP_SUMMARY\n• Backup files cleaned"
fi

# System cleanup
if [ "$CLEANUP_ALL" = true ]; then
    show_step "4" "Performing system cleanup..."
    
    # Clear temporary files
    execute_cmd "sudo rm -rf /tmp/*" "Clearing temporary files"
    
    # Clear package cache
    execute_cmd "sudo apt-get clean" "Clearing package cache"
    
    # Clear npm cache
    execute_cmd "npm cache clean --force" "Clearing npm cache"
    
    # Clear pip cache
    execute_cmd "pip cache purge" "Clearing pip cache"
    
    show_success "System cleanup completed"
    CLEANUP_SUMMARY="$CLEANUP_SUMMARY\n• System files cleaned"
fi

# Show disk usage before and after
show_step "5" "Checking disk usage..."
DISK_USAGE_BEFORE=$(df -h . | tail -1 | awk '{print $5}')
show_info "Disk usage before cleanup: $DISK_USAGE_BEFORE"

if [ "$DRY_RUN" = false ]; then
    # Wait a moment for cleanup to complete
    sleep 2
    DISK_USAGE_AFTER=$(df -h . | tail -1 | awk '{print $5}')
    show_info "Disk usage after cleanup: $DISK_USAGE_AFTER"
fi

# Show cleanup summary
echo ""
echo -e "${GREEN}📊 Cleanup Summary${NC}"
echo -e "${BLUE}Version: $VERSION${NC}"
echo -e "${BLUE}Dry run: $DRY_RUN${NC}"
if [ -n "$CLEANUP_SUMMARY" ]; then
    echo -e "${PURPLE}Operations performed:${NC}$CLEANUP_SUMMARY"
else
    echo -e "${YELLOW}No cleanup operations performed${NC}"
fi

# Show space saved (if not dry run)
if [ "$DRY_RUN" = false ] && [ "$CLEANUP_ALL" = true ]; then
    echo ""
    show_info "Space optimization completed"
    show_info "System is now optimized for better performance"
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    show_warning "This was a dry run. No files were actually deleted."
    echo -e "${YELLOW}💡 Tip: Run without --dry-run to perform actual cleanup${NC}"
else
    show_success "Cleanup completed successfully!"
    echo -e "${YELLOW}💡 Tip: Run regularly to maintain system performance${NC}"
fi 