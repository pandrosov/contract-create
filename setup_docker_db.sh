#!/bin/bash

# Docker Database Setup Script for Contract Manager
# Usage: ./setup_docker_db.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DB_USER="contract_user"
DB_NAME="contract_db"
DB_PASSWORD="your_very_secure_password_123"
CONTAINER_NAME="contract-postgres"
PORT="5437"

echo -e "${GREEN}🐳 Setting up PostgreSQL database in Docker...${NC}"

echo -e "${GREEN}📋 Step 1: Checking existing containers...${NC}"

# Check if container already exists
if docker ps -a --format "table {{.Names}}" | grep -q $CONTAINER_NAME; then
    echo -e "${YELLOW}⚠️  Container $CONTAINER_NAME already exists${NC}"
    read -p "Do you want to remove it and create a new one? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Stopping and removing existing container..."
        docker stop $CONTAINER_NAME || true
        docker rm $CONTAINER_NAME || true
    else
        echo -e "${YELLOW}Skipping container creation${NC}"
    fi
fi

echo -e "${GREEN}📋 Step 2: Creating PostgreSQL container...${NC}"

# Create PostgreSQL container
docker run -d \
  --name $CONTAINER_NAME \
  -e POSTGRES_DB=$DB_NAME \
  -e POSTGRES_USER=$DB_USER \
  -e POSTGRES_PASSWORD=$DB_PASSWORD \
  -p $PORT:5432 \
  -v contract_postgres_data:/var/lib/postgresql/data \
  postgres:15

echo -e "${GREEN}✅ Container created${NC}"

echo -e "${GREEN}📋 Step 3: Waiting for database to be ready...${NC}"

# Wait for database to be ready
echo "Waiting for PostgreSQL to start..."
until docker exec $CONTAINER_NAME pg_isready -U $DB_USER -d $DB_NAME; do
    echo "Database is not ready yet. Waiting..."
    sleep 2
done

echo -e "${GREEN}✅ Database is ready${NC}"

echo -e "${GREEN}📋 Step 4: Setting up database schema...${NC}"

# Create init.sql if it doesn't exist
if [ ! -f init.sql ]; then
    echo "Creating init.sql file..."
    cat > init.sql << 'EOF'
-- Initialize database for Contract Manager
-- This file will be executed when the container starts

-- Create extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Set timezone
SET timezone = 'UTC';

-- Create additional indexes if needed
-- CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
-- CREATE INDEX IF NOT EXISTS idx_templates_folder_id ON templates(folder_id);
EOF
fi

echo -e "${GREEN}✅ Schema setup completed${NC}"

echo -e "${GREEN}📋 Step 5: Testing connection...${NC}"

# Test connection
if docker exec $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c "SELECT version();" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Database connection test successful${NC}"
else
    echo -e "${RED}❌ Database connection test failed${NC}"
    exit 1
fi

echo -e "${GREEN}📋 Step 6: Showing database information...${NC}"

# Show database info
echo -e "${BLUE}Container status:${NC}"
docker ps --filter "name=$CONTAINER_NAME"

echo -e "${BLUE}Database users:${NC}"
docker exec $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c "\du"

echo -e "${BLUE}Database list:${NC}"
docker exec $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -c "\l"

echo -e "${GREEN}🎉 Docker database setup completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Database Information:${NC}"
echo "Container: $CONTAINER_NAME"
echo "User: $DB_USER"
echo "Database: $DB_NAME"
echo "Password: $DB_PASSWORD"
echo "Port: $PORT"
echo ""
echo -e "${YELLOW}🔧 Connection strings:${NC}"
echo "From host: postgresql://$DB_USER:$DB_PASSWORD@localhost:$PORT/$DB_NAME"
echo "From Docker network: postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/$DB_NAME"
echo ""
echo -e "${YELLOW}🔧 Useful commands:${NC}"
echo "Connect to database: docker exec -it $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME"
echo "View logs: docker logs $CONTAINER_NAME"
echo "Stop container: docker stop $CONTAINER_NAME"
echo "Start container: docker start $CONTAINER_NAME"
echo ""
echo -e "${YELLOW}⚠️  Important notes:${NC}"
echo "1. Update your .env file with the database credentials"
echo "2. The database data is persisted in Docker volume: contract_postgres_data"
echo "3. Port $PORT is mapped to container port 5432"
echo "4. Keep the password secure"
echo ""
echo -e "${GREEN}🚀 Database is ready for deployment!${NC}" 