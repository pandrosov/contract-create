#!/bin/bash

# Contract Management System v2.0 Backup Script
# Usage: ./backup_v2.sh [full|db|files|templates|config] [--compress] [--upload]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
VERSION="2.0.0"
BACKUP_TYPE=${1:-full}
COMPRESS_BACKUP=false
UPLOAD_BACKUP=false
BACKUP_PATH=${BACKUP_PATH:-./backups}
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="contract_backup_v${VERSION}_${TIMESTAMP}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --compress)
            COMPRESS_BACKUP=true
            shift
            ;;
        --upload)
            UPLOAD_BACKUP=true
            shift
            ;;
        --help)
            echo "Contract Management System v$VERSION Backup Script"
            echo ""
            echo "Usage: $0 [TYPE] [OPTIONS]"
            echo ""
            echo "Backup Types:"
            echo "  full       Full backup (database + files + templates + config)"
            echo "  db         Database backup only"
            echo "  files      Application files backup"
            echo "  templates  Templates directory backup"
            echo "  config     Configuration files backup"
            echo ""
            echo "Options:"
            echo "  --compress  Compress backup files"
            echo "  --upload    Upload backup to remote storage"
            echo "  --help      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 full --compress"
            echo "  $0 db"
            echo "  $0 templates --upload"
            exit 0
            ;;
        *)
            BACKUP_TYPE="$1"
            shift
            ;;
    esac
done

echo -e "${GREEN}📦 Contract Management System v$VERSION Backup${NC}"
echo "Backup type: $BACKUP_TYPE"
echo "Backup path: $BACKUP_PATH"
echo "Timestamp: $TIMESTAMP"
echo "Compress: $COMPRESS_BACKUP"
echo "Upload: $UPLOAD_BACKUP"
echo ""

# Create backup directory
mkdir -p "$BACKUP_PATH"

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

# Function to backup database
backup_database() {
    show_step "1" "Backing up database..."
    
    # Check if containers are running
    if ! docker-compose -f docker-compose.prod.yaml ps | grep -q "postgres.*Up"; then
        show_error "PostgreSQL container is not running"
        return 1
    fi
    
    # Create database backup
    docker-compose -f docker-compose.prod.yaml exec -T postgres pg_dump -U contract_user contract_db > "$BACKUP_PATH/db_backup_$TIMESTAMP.sql"
    
    # Compress if requested
    if [ "$COMPRESS_BACKUP" = true ]; then
        gzip "$BACKUP_PATH/db_backup_$TIMESTAMP.sql"
        show_success "Database backup created: db_backup_$TIMESTAMP.sql.gz"
    else
        show_success "Database backup created: db_backup_$TIMESTAMP.sql"
    fi
}

# Function to backup application files
backup_files() {
    show_step "2" "Backing up application files..."
    
    # Create files backup
    tar -czf "$BACKUP_PATH/files_backup_$TIMESTAMP.tar.gz" \
        --exclude='node_modules' \
        --exclude='.git' \
        --exclude='backups' \
        --exclude='*.log' \
        --exclude='__pycache__' \
        --exclude='.DS_Store' \
        .
    
    show_success "Files backup created: files_backup_$TIMESTAMP.tar.gz"
}

# Function to backup templates
backup_templates() {
    show_step "3" "Backing up templates..."
    
    if [ -d "templates" ]; then
        tar -czf "$BACKUP_PATH/templates_backup_$TIMESTAMP.tar.gz" templates/
        show_success "Templates backup created: templates_backup_$TIMESTAMP.tar.gz"
    else
        show_warning "Templates directory not found"
    fi
}

# Function to backup configuration
backup_config() {
    show_step "4" "Backing up configuration..."
    
    # Backup environment files
    if [ -f ".env" ]; then
        cp .env "$BACKUP_PATH/env_backup_$TIMESTAMP"
        show_success "Environment backup created: env_backup_$TIMESTAMP"
    fi
    
    # Backup docker compose files
    if [ -f "docker-compose.yaml" ]; then
        cp docker-compose.yaml "$BACKUP_PATH/docker-compose_backup_$TIMESTAMP.yaml"
    fi
    
    if [ -f "docker-compose.prod.yaml" ]; then
        cp docker-compose.prod.yaml "$BACKUP_PATH/docker-compose.prod_backup_$TIMESTAMP.yaml"
    fi
    
    show_success "Configuration backup created"
}

# Function to create full backup
backup_full() {
    show_step "0" "Creating full backup..."
    
    backup_database
    backup_files
    backup_templates
    backup_config
    
    # Create backup manifest
    cat > "$BACKUP_PATH/backup_manifest_$TIMESTAMP.txt" << EOF
Contract Management System v$VERSION Backup Manifest
==================================================
Timestamp: $TIMESTAMP
Version: $VERSION
Backup Type: Full
Files:
EOF
    
    ls -la "$BACKUP_PATH" | grep "$TIMESTAMP" >> "$BACKUP_PATH/backup_manifest_$TIMESTAMP.txt"
    
    show_success "Full backup completed"
}

# Function to cleanup old backups
cleanup_old_backups() {
    show_step "5" "Cleaning up old backups..."
    
    # Remove old database backups
    find "$BACKUP_PATH" -name "db_backup_*.sql*" -mtime +$RETENTION_DAYS -delete
    
    # Remove old files backups
    find "$BACKUP_PATH" -name "files_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
    
    # Remove old templates backups
    find "$BACKUP_PATH" -name "templates_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
    
    # Remove old config backups
    find "$BACKUP_PATH" -name "*_backup_*" -mtime +$RETENTION_DAYS -delete
    
    show_success "Old backups cleaned up (older than $RETENTION_DAYS days)"
}

# Function to show backup info
show_backup_info() {
    echo ""
    echo -e "${GREEN}📊 Backup Information:${NC}"
    echo "Version: $VERSION"
    echo "Backup path: $BACKUP_PATH"
    echo "Total size: $(du -sh "$BACKUP_PATH" | cut -f1)"
    echo "Number of backups: $(ls "$BACKUP_PATH" | wc -l)"
    echo ""
    echo -e "${YELLOW}📋 Recent backups:${NC}"
    ls -lh "$BACKUP_PATH" | tail -10
}

# Function to upload backup (placeholder)
upload_backup() {
    if [ "$UPLOAD_BACKUP" = true ]; then
        show_step "6" "Uploading backup..."
        show_warning "Upload functionality not implemented yet"
        # TODO: Implement upload to cloud storage
    fi
}

# Main backup logic
case $BACKUP_TYPE in
    full)
        backup_full
        ;;
    db)
        backup_database
        ;;
    files)
        backup_files
        ;;
    templates)
        backup_templates
        ;;
    config)
        backup_config
        ;;
    *)
        show_error "Unknown backup type: $BACKUP_TYPE"
        echo "Use --help for usage information"
        exit 1
        ;;
esac

# Cleanup old backups
cleanup_old_backups

# Upload if requested
upload_backup

# Show backup information
show_backup_info

echo ""
show_success "Backup completed successfully!"
echo -e "${YELLOW}💡 Tip: Restore with: ./restore_backup.sh <backup_file>${NC}" 