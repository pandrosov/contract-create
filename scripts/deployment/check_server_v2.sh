#!/bin/bash

# Contract Management System v2.0 Server Health Check
# Usage: ./check_server_v2.sh [--detailed] [--notify]

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
DETAILED_CHECK=false
NOTIFY_ON_FAILURE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --detailed)
            DETAILED_CHECK=true
            shift
            ;;
        --notify)
            NOTIFY_ON_FAILURE=true
            shift
            ;;
        --help)
            echo "Contract Management System v$VERSION Server Health Check"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --detailed  Perform detailed system checks"
            echo "  --notify    Send notifications on failures"
            echo "  --help      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}🔍 Contract Management System v$VERSION Server Health Check${NC}"
echo -e "${BLUE}Server IP: $SERVER_IP${NC}"
echo -e "${BLUE}Domain: $DOMAIN${NC}"
echo -e "${BLUE}Detailed Check: $DETAILED_CHECK${NC}"
echo -e "${BLUE}Notifications: $NOTIFY_ON_FAILURE${NC}"
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

# Function to execute remote command
remote_exec() {
    ssh -o StrictHostKeyChecking=no $REMOTE_USER@$SERVER_IP "$1"
}

# Initialize health status
HEALTH_STATUS=true

# Check SSH connection
show_step "1" "Testing SSH connection..."
if remote_exec "echo 'SSH connection test successful'" >/dev/null 2>&1; then
    show_success "SSH connection established"
else
    show_error "Failed to connect to server"
    HEALTH_STATUS=false
    exit 1
fi

# Check Docker containers
show_step "2" "Checking Docker containers..."
CONTAINER_STATUS=$(remote_exec "cd $REMOTE_PATH && docker-compose -f docker-compose.prod.yaml ps --format 'table {{.Name}}\t{{.Status}}\t{{.Ports}}'" 2>/dev/null || echo "Failed to get container status")

if echo "$CONTAINER_STATUS" | grep -q "Up"; then
    show_success "All containers are running"
    if [ "$DETAILED_CHECK" = true ]; then
        echo "$CONTAINER_STATUS"
    fi
else
    show_error "Some containers are not running"
    HEALTH_STATUS=false
    echo "$CONTAINER_STATUS"
fi

# Check backend health
show_step "3" "Checking backend health..."
BACKEND_HEALTH=$(curl -s "https://$DOMAIN/api/health" 2>/dev/null || echo "{}")
if echo "$BACKEND_HEALTH" | grep -q "healthy"; then
    show_success "Backend health check passed"
    if [ "$DETAILED_CHECK" = true ]; then
        echo "Backend response: $BACKEND_HEALTH"
    fi
else
    show_error "Backend health check failed"
    HEALTH_STATUS=false
fi

# Check frontend accessibility
show_step "4" "Checking frontend accessibility..."
FRONTEND_STATUS=$(curl -s -I "https://$DOMAIN" 2>/dev/null | head -1 || echo "")
if echo "$FRONTEND_STATUS" | grep -q "200"; then
    show_success "Frontend is accessible"
else
    show_error "Frontend is not accessible"
    HEALTH_STATUS=false
fi

# Check SSL certificate
show_step "5" "Checking SSL certificate..."
SSL_INFO=$(echo | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN 2>/dev/null | openssl x509 -noout -dates -subject 2>/dev/null || echo "")
if [ -n "$SSL_INFO" ]; then
    show_success "SSL certificate is valid"
    if [ "$DETAILED_CHECK" = true ]; then
        echo "SSL Info: $SSL_INFO"
    fi
else
    show_error "SSL certificate check failed"
    HEALTH_STATUS=false
fi

# Check database connectivity
show_step "6" "Checking database connectivity..."
DB_STATUS=$(remote_exec "cd $REMOTE_PATH && docker-compose -f docker-compose.prod.yaml exec -T postgres pg_isready -U contract_user -d contract_db" 2>/dev/null || echo "Database check failed")
if echo "$DB_STATUS" | grep -q "accepting connections"; then
    show_success "Database is accepting connections"
else
    show_error "Database connectivity issue"
    HEALTH_STATUS=false
fi

# Check disk space
show_step "7" "Checking disk space..."
DISK_USAGE=$(remote_exec "df -h /" 2>/dev/null || echo "Disk check failed")
USAGE_PERCENT=$(echo "$DISK_USAGE" | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$USAGE_PERCENT" -lt 90 ]; then
    show_success "Disk space is adequate"
    if [ "$DETAILED_CHECK" = true ]; then
        echo "Disk usage: $USAGE_PERCENT%"
    fi
else
    show_warning "Disk space is running low ($USAGE_PERCENT%)"
fi

# Check memory usage
show_step "8" "Checking memory usage..."
MEMORY_INFO=$(remote_exec "free -h" 2>/dev/null || echo "Memory check failed")
MEMORY_USAGE=$(echo "$MEMORY_INFO" | grep Mem | awk '{print $3}' | sed 's/Gi//')
MEMORY_TOTAL=$(echo "$MEMORY_INFO" | grep Mem | awk '{print $2}' | sed 's/Gi//')
if [ "$MEMORY_USAGE" -lt "$MEMORY_TOTAL" ]; then
    show_success "Memory usage is normal"
    if [ "$DETAILED_CHECK" = true ]; then
        echo "Memory usage: $MEMORY_USAGE/$MEMORY_TOTAL GB"
    fi
else
    show_warning "High memory usage detected"
fi

# Check application logs
show_step "9" "Checking application logs..."
RECENT_ERRORS=$(remote_exec "cd $REMOTE_PATH && docker-compose -f docker-compose.prod.yaml logs --tail=50 2>&1 | grep -i error | wc -l" 2>/dev/null || echo "0")
if [ "$RECENT_ERRORS" -eq 0 ]; then
    show_success "No recent errors in logs"
else
    show_warning "Found $RECENT_ERRORS recent errors in logs"
    if [ "$DETAILED_CHECK" = true ]; then
        echo "Recent errors:"
        remote_exec "cd $REMOTE_PATH && docker-compose -f docker-compose.prod.yaml logs --tail=20 2>&1 | grep -i error"
    fi
fi

# Check backup status
show_step "10" "Checking backup status..."
BACKUP_COUNT=$(remote_exec "cd $REMOTE_PATH && ls -1 backups/ 2>/dev/null | wc -l" 2>/dev/null || echo "0")
if [ "$BACKUP_COUNT" -gt 0 ]; then
    show_success "Backups exist ($BACKUP_COUNT files)"
else
    show_warning "No backups found"
fi

# Detailed system information
if [ "$DETAILED_CHECK" = true ]; then
    show_step "11" "Detailed system information..."
    
    echo -e "${PURPLE}System Information:${NC}"
    remote_exec "uname -a"
    
    echo -e "${PURPLE}Docker Version:${NC}"
    remote_exec "docker --version"
    
    echo -e "${PURPLE}Docker Compose Version:${NC}"
    remote_exec "docker-compose --version"
    
    echo -e "${PURPLE}Recent Container Logs:${NC}"
    remote_exec "cd $REMOTE_PATH && docker-compose -f docker-compose.prod.yaml logs --tail=10"
fi

# Performance metrics
show_step "12" "Performance metrics..."
CPU_USAGE=$(remote_exec "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | cut -d'%' -f1" 2>/dev/null || echo "0")
LOAD_AVERAGE=$(remote_exec "uptime | awk -F'load average:' '{print \$2}'" 2>/dev/null || echo "unknown")

if [ "$CPU_USAGE" -lt 80 ]; then
    show_success "CPU usage is normal ($CPU_USAGE%)"
else
    show_warning "High CPU usage ($CPU_USAGE%)"
fi

show_info "Load average: $LOAD_AVERAGE"

# Final health assessment
echo ""
if [ "$HEALTH_STATUS" = true ]; then
    echo -e "${GREEN}🎉 Server Health Check: PASSED${NC}"
    echo -e "${BLUE}All critical services are operational${NC}"
else
    echo -e "${RED}❌ Server Health Check: FAILED${NC}"
    echo -e "${YELLOW}Some services have issues${NC}"
    
    if [ "$NOTIFY_ON_FAILURE" = true ]; then
        show_warning "Sending notification..."
        # TODO: Implement notification system
    fi
fi

# Show summary
echo ""
echo -e "${GREEN}📊 Health Check Summary${NC}"
echo -e "${BLUE}Version: $VERSION${NC}"
echo -e "${BLUE}Domain: https://$DOMAIN${NC}"
echo -e "${BLUE}API Health: https://$DOMAIN/api/health${NC}"
echo -e "${BLUE}Documentation: https://$DOMAIN/api/docs${NC}"
echo -e "${BLUE}Status: $([ "$HEALTH_STATUS" = true ] && echo "HEALTHY" || echo "ISSUES DETECTED")${NC}"

echo ""
show_info "Health check completed!"
echo -e "${YELLOW}💡 Tip: Run with --detailed for more information${NC}" 