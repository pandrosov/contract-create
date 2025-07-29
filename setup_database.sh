#!/bin/bash

# Database Setup Script for PostgreSQL
# Usage: ./setup_database.sh

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

echo -e "${GREEN}🗄️  Setting up PostgreSQL database...${NC}"

# Function to execute SQL command
execute_sql() {
    sudo -u postgres psql -c "$1"
}

echo -e "${GREEN}📋 Step 1: Creating database user...${NC}"

# Create user
execute_sql "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"

echo -e "${GREEN}✅ User created${NC}"

echo -e "${GREEN}📋 Step 2: Creating database...${NC}"

# Create database
execute_sql "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

echo -e "${GREEN}✅ Database created${NC}"

echo -e "${GREEN}📋 Step 3: Setting up permissions...${NC}"

# Grant privileges
execute_sql "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# Connect to the database and set up schema permissions
sudo -u postgres psql -d $DB_NAME -c "
GRANT ALL ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;
"

echo -e "${GREEN}✅ Permissions set${NC}"

echo -e "${GREEN}📋 Step 4: Testing connection...${NC}"

# Test connection
if sudo -u postgres psql -U $DB_USER -d $DB_NAME -c "SELECT version();" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Database connection test successful${NC}"
else
    echo -e "${RED}❌ Database connection test failed${NC}"
    exit 1
fi

echo -e "${GREEN}📋 Step 5: Showing database information...${NC}"

# Show database info
echo -e "${BLUE}Database users:${NC}"
sudo -u postgres psql -c "\du"

echo -e "${BLUE}Database list:${NC}"
sudo -u postgres psql -c "\l"

echo -e "${GREEN}🎉 Database setup completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Database Information:${NC}"
echo "User: $DB_USER"
echo "Database: $DB_NAME"
echo "Password: $DB_PASSWORD"
echo ""
echo -e "${YELLOW}🔧 Connection string:${NC}"
echo "postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME"
echo ""
echo -e "${YELLOW}⚠️  Important notes:${NC}"
echo "1. Update your .env file with the database credentials"
echo "2. Keep the password secure"
echo "3. Consider using environment variables for production"
echo ""
echo -e "${GREEN}🚀 Database is ready for deployment!${NC}" 