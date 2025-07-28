#!/bin/bash

# Contract Management System Deployment Script
# Usage: ./deploy.sh [production|staging]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-production}
DOMAIN=${DOMAIN:-your-domain.com}
BACKUP_ENABLED=${BACKUP_ENABLED:-true}

echo -e "${GREEN}🚀 Starting deployment for $ENVIRONMENT environment...${NC}"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  .env file not found. Creating from template...${NC}"
    cp env.example .env
    echo -e "${YELLOW}⚠️  Please edit .env file with your configuration before continuing.${NC}"
    echo -e "${YELLOW}⚠️  Press Enter to continue or Ctrl+C to abort...${NC}"
    read
fi

# Load environment variables
source .env

# Function to backup database
backup_database() {
    if [ "$BACKUP_ENABLED" = "true" ]; then
        echo -e "${GREEN}📦 Creating database backup...${NC}"
        mkdir -p backups
        docker-compose exec -T postgres pg_dump -U contract_user contract_db > "backups/backup_$(date +%Y%m%d_%H%M%S).sql"
        echo -e "${GREEN}✅ Database backup created${NC}"
    fi
}

# Function to cleanup old backups
cleanup_backups() {
    if [ "$BACKUP_ENABLED" = "true" ]; then
        echo -e "${GREEN}🧹 Cleaning up old backups...${NC}"
        find backups -name "backup_*.sql" -mtime +${BACKUP_RETENTION_DAYS:-30} -delete
        echo -e "${GREEN}✅ Old backups cleaned up${NC}"
    fi
}

# Function to check SSL certificates
check_ssl() {
    if [ "$ENVIRONMENT" = "production" ]; then
        if [ ! -f "nginx/ssl/cert.pem" ] || [ ! -f "nginx/ssl/key.pem" ]; then
            echo -e "${YELLOW}⚠️  SSL certificates not found. Creating self-signed certificates...${NC}"
            mkdir -p nginx/ssl
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout nginx/ssl/key.pem \
                -out nginx/ssl/cert.pem \
                -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"
            echo -e "${GREEN}✅ Self-signed SSL certificates created${NC}"
        fi
    fi
}

# Function to create necessary directories
create_directories() {
    echo -e "${GREEN}📁 Creating necessary directories...${NC}"
    mkdir -p templates logs backups nginx/logs
    echo -e "${GREEN}✅ Directories created${NC}"
}

# Function to stop existing containers
stop_containers() {
    echo -e "${GREEN}🛑 Stopping existing containers...${NC}"
    docker-compose -f docker-compose.prod.yaml down || true
    echo -e "${GREEN}✅ Containers stopped${NC}"
}

# Function to build and start containers
start_containers() {
    echo -e "${GREEN}🔨 Building and starting containers...${NC}"
    docker-compose -f docker-compose.prod.yaml up --build -d
    echo -e "${GREEN}✅ Containers started${NC}"
}

# Function to wait for services to be ready
wait_for_services() {
    echo -e "${GREEN}⏳ Waiting for services to be ready...${NC}"
    
    # Wait for database
    echo "Waiting for database..."
    until docker-compose -f docker-compose.prod.yaml exec -T postgres pg_isready -U contract_user; do
        sleep 2
    done
    
    # Wait for backend
    echo "Waiting for backend..."
    until curl -f http://localhost:8000/health > /dev/null 2>&1; do
        sleep 2
    done
    
    echo -e "${GREEN}✅ All services are ready${NC}"
}

# Function to initialize database
initialize_database() {
    echo -e "${GREEN}🗄️  Initializing database...${NC}"
    docker-compose -f docker-compose.prod.yaml exec -T backend python init_db.py
    docker-compose -f docker-compose.prod.yaml exec -T backend python activate_admin.py
    echo -e "${GREEN}✅ Database initialized${NC}"
}

# Function to check deployment
check_deployment() {
    echo -e "${GREEN}🔍 Checking deployment...${NC}"
    
    # Check if containers are running
    if docker-compose -f docker-compose.prod.yaml ps | grep -q "Up"; then
        echo -e "${GREEN}✅ All containers are running${NC}"
    else
        echo -e "${RED}❌ Some containers are not running${NC}"
        docker-compose -f docker-compose.prod.yaml ps
        exit 1
    fi
    
    # Check if frontend is accessible
    if curl -f http://localhost > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Frontend is accessible${NC}"
    else
        echo -e "${RED}❌ Frontend is not accessible${NC}"
        exit 1
    fi
    
    # Check if API is accessible
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ API is accessible${NC}"
    else
        echo -e "${RED}❌ API is not accessible${NC}"
        exit 1
    fi
}

# Function to show deployment info
show_info() {
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}📋 Deployment Information:${NC}"
    echo "Environment: $ENVIRONMENT"
    echo "Domain: $DOMAIN"
    echo "Frontend URL: http://localhost (or https://$DOMAIN)"
    echo "API URL: http://localhost:8000 (or https://$DOMAIN/api)"
    echo "Admin credentials: admin/admin"
    echo ""
    echo -e "${YELLOW}🔧 Useful commands:${NC}"
    echo "View logs: docker-compose -f docker-compose.prod.yaml logs -f"
    echo "Stop services: docker-compose -f docker-compose.prod.yaml down"
    echo "Restart services: docker-compose -f docker-compose.prod.yaml restart"
    echo "Backup database: docker-compose -f docker-compose.prod.yaml exec postgres pg_dump -U contract_user contract_db > backup.sql"
    echo ""
    echo -e "${YELLOW}⚠️  Important notes:${NC}"
    echo "1. Change default admin password after first login"
    echo "2. Update SSL certificates for production"
    echo "3. Configure your domain in .env file"
    echo "4. Set up regular backups"
}

# Main deployment process
main() {
    echo -e "${GREEN}🚀 Contract Management System Deployment${NC}"
    echo "Environment: $ENVIRONMENT"
    echo "Domain: $DOMAIN"
    echo ""
    
    # Create directories
    create_directories
    
    # Check SSL certificates
    check_ssl
    
    # Backup database (if enabled)
    backup_database
    
    # Stop existing containers
    stop_containers
    
    # Start containers
    start_containers
    
    # Wait for services
    wait_for_services
    
    # Initialize database
    initialize_database
    
    # Cleanup old backups
    cleanup_backups
    
    # Check deployment
    check_deployment
    
    # Show deployment info
    show_info
}

# Run main function
main "$@" 