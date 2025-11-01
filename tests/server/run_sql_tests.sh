#!/bin/bash
# ============================================================================
# SQL Schema Testing Script for Linux/Mac
# ============================================================================
# This bash script runs all SQL schema tests
# Usage: ./tests/server/run_sql_tests.sh
# ============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default database connection parameters
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"

echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}SQL Schema Testing Suite${NC}"
echo -e "${CYAN}============================================================================${NC}"
echo ""

# Check if MySQL client is available
if ! command -v mysql &> /dev/null; then
    echo -e "${RED}ERROR: MySQL client not found${NC}"
    echo -e "${YELLOW}Please install MySQL client or add it to your PATH${NC}"
    exit 1
fi

echo -e "${GREEN}MySQL client found: $(which mysql)${NC}"
echo ""

# Prompt for password if not provided
if [ -z "$DB_PASSWORD" ]; then
    read -sp "Enter MySQL password for user '$DB_USER': " DB_PASSWORD
    echo ""
fi

# Build MySQL connection string
MYSQL_CMD="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER"
if [ -n "$DB_PASSWORD" ]; then
    MYSQL_CMD="$MYSQL_CMD -p$DB_PASSWORD"
fi

# Test database connection
echo -e "${YELLOW}Testing database connection...${NC}"
if echo "SELECT 1;" | $MYSQL_CMD &> /dev/null; then
    echo -e "${GREEN}Database connection successful!${NC}"
else
    echo -e "${RED}ERROR: Cannot connect to database${NC}"
    exit 1
fi
echo ""

# Test 1: Individual SQL Files
echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}Test 1: Individual SQL File Validation${NC}"
echo -e "${CYAN}============================================================================${NC}"
echo ""

if $MYSQL_CMD < tests/server/validate_sql_files.sql; then
    echo -e "${GREEN}✓ Test 1 PASSED: Individual SQL files validated successfully${NC}"
else
    echo -e "${RED}✗ Test 1 FAILED: Individual SQL file validation failed${NC}"
fi
echo ""

# Test 2: Master Installation Script
echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}Test 2: Master Installation Script${NC}"
echo -e "${CYAN}============================================================================${NC}"
echo ""

if $MYSQL_CMD < tests/server/test_master_install.sql; then
    echo -e "${GREEN}✓ Test 2 PASSED: Master installation script executed successfully${NC}"
else
    echo -e "${RED}✗ Test 2 FAILED: Master installation script failed${NC}"
fi
echo ""

# Test 3: Existing Database Compatibility
echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}Test 3: Existing Database Compatibility${NC}"
echo -e "${CYAN}============================================================================${NC}"
echo ""

if $MYSQL_CMD < tests/server/test_existing_database.sql; then
    echo -e "${GREEN}✓ Test 3 PASSED: Existing database compatibility verified${NC}"
else
    echo -e "${RED}✗ Test 3 FAILED: Existing database compatibility test failed${NC}"
fi
echo ""

# Cleanup
echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}Cleanup${NC}"
echo -e "${CYAN}============================================================================${NC}"
echo ""

echo -e "${YELLOW}Cleaning up test databases...${NC}"
if $MYSQL_CMD -e "DROP DATABASE IF EXISTS phone_test_validation; DROP DATABASE IF EXISTS phone_test_master; DROP DATABASE IF EXISTS phone_test_existing;"; then
    echo -e "${GREEN}✓ Test databases cleaned up successfully${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Could not clean up all test databases${NC}"
fi
echo ""

# Summary
echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}Test Summary${NC}"
echo -e "${CYAN}============================================================================${NC}"
echo ""
echo -e "${GREEN}All SQL schema tests completed!${NC}"
echo ""
echo -e "Test databases have been cleaned up."
echo -e "Review the output above for detailed results."
echo ""
