#!/bin/bash

# Contract Management System Backup Script
# Usage: ./backup.sh [full|db|files]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKUP_TYPE=${1:-full}
BACKUP_PATH=${BACKUP_PATH:-./backups}
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${GREEN}📦 Starting backup process...${NC}"
echo "Backup type: $BACKUP_TYPE"
echo "Backup path: $BACKUP_PATH"
echo "Timestamp: $TIMESTAMP"

# Create backup directory
mkdir -p "$BACKUP_PATH"

# Function to backup database
backup_database() {
    echo -e "${GREEN}🗄️  Backing up database...${NC}"
    
    # Check if containers are running
    if ! docker-compose -f docker-compose.prod.yaml ps | grep -q "postgres.*Up"; then
        echo -e "${RED}❌ PostgreSQL container is not running${NC}"
        exit 1
    fi
    
    # Create database backup
    docker-compose -f docker-compose.prod.yaml exec -T postgres pg_dump -U contract_user contract_db > "$BACKUP_PATH/db_backup_$TIMESTAMP.sql"
    
    # Compress backup
    gzip "$BACKUP_PATH/db_backup_$TIMESTAMP.sql"
    
    echo -e "${GREEN}✅ Database backup created: db_backup_$TIMESTAMP.sql.gz${NC}"
}

# Function to backup files
backup_files() {
    echo -e "${GREEN}📁 Backing up files...${NC}"
    
    # Create files backup
    tar -czf "$BACKUP_PATH/files_backup_$TIMESTAMP.tar.gz" \
        --exclude='node_modules' \
        --exclude='.git' \
        --exclude='backups' \
        --exclude='*.log' \
        .
    
    echo -e "${GREEN}✅ Files backup created: files_backup_$TIMESTAMP.tar.gz${NC}"
}

# Function to backup templates
backup_templates() {
    echo -e "${GREEN}📄 Backing up templates...${NC}"
    
    if [ -d "templates" ]; then
        tar -czf "$BACKUP_PATH/templates_backup_$TIMESTAMP.tar.gz" templates/
        echo -e "${GREEN}✅ Templates backup created: templates_backup_$TIMESTAMP.tar.gz${NC}"
    else
        echo -e "${YELLOW}⚠️  Templates directory not found${NC}"
    fi
}

# Function to cleanup old backups
cleanup_old_backups() {
    echo -e "${GREEN}🧹 Cleaning up old backups...${NC}"
    
    # Remove old database backups
    find "$BACKUP_PATH" -name "db_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete
    
    # Remove old files backups
    find "$BACKUP_PATH" -name "files_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
    
    # Remove old templates backups
    find "$BACKUP_PATH" -name "templates_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
    
    echo -e "${GREEN}✅ Old backups cleaned up (older than $RETENTION_DAYS days)${NC}"
}

# Function to show backup info
show_backup_info() {
    echo -e "${GREEN}📊 Backup Information:${NC}"
    echo "Backup path: $BACKUP_PATH"
    echo "Total size: $(du -sh "$BACKUP_PATH" | cut -f1)"
    echo "Number of backups: $(ls "$BACKUP_PATH" | wc -l)"
    echo ""
    echo -e "${YELLOW}📋 Recent backups:${NC}"
    ls -lh "$BACKUP_PATH" | tail -10
}

# Function to verify backup
verify_backup() {
    echo -e "${GREEN}🔍 Verifying backup...${NC}"
    
    case $BACKUP_TYPE in
        "db"|"full")
            if [ -f "$BACKUP_PATH/db_backup_$TIMESTAMP.sql.gz" ]; then
                echo -e "${GREEN}✅ Database backup verified${NC}"
            else
                echo -e "${RED}❌ Database backup verification failed${NC}"
                exit 1
            fi
            ;;
    esac
    
    case $BACKUP_TYPE in
        "files"|"full")
            if [ -f "$BACKUP_PATH/files_backup_$TIMESTAMP.tar.gz" ]; then
                echo -e "${GREEN}✅ Files backup verified${NC}"
            else
                echo -e "${RED}❌ Files backup verification failed${NC}"
                exit 1
            fi
            ;;
    esac
    
    case $BACKUP_TYPE in
        "full")
            if [ -f "$BACKUP_PATH/templates_backup_$TIMESTAMP.tar.gz" ]; then
                echo -e "${GREEN}✅ Templates backup verified${NC}"
            else
                echo -e "${YELLOW}⚠️  Templates backup not found (directory may be empty)${NC}"
            fi
            ;;
    esac
}

# Main backup process
main() {
    case $BACKUP_TYPE in
        "db")
            backup_database
            ;;
        "files")
            backup_files
            backup_templates
            ;;
        "full")
            backup_database
            backup_files
            backup_templates
            ;;
        *)
            echo -e "${RED}❌ Invalid backup type. Use: db, files, or full${NC}"
            exit 1
            ;;
    esac
    
    # Cleanup old backups
    cleanup_old_backups
    
    # Verify backup
    verify_backup
    
    # Show backup info
    show_backup_info
    
    echo -e "${GREEN}🎉 Backup completed successfully!${NC}"
}

# Run main function
main "$@" 