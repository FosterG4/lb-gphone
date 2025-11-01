# SQL Schema Testing Guide

This guide explains how to test and validate all SQL schema files for the FiveM Phone System.

## Overview

The testing suite includes three main test scripts:

1. **validate_sql_files.sql** - Tests individual SQL files
2. **test_master_install.sql** - Tests the master installation script
3. **test_existing_database.sql** - Tests backward compatibility with existing databases

## Prerequisites

- MySQL/MariaDB server installed and running
- MySQL client command-line tool
- Appropriate database permissions (CREATE, DROP, INSERT, SELECT)
- All SQL files present in `server/sql/` directory

## Test 1: Individual SQL File Validation

This test validates each SQL file independently to ensure:
- Files can be read and parsed
- SQL syntax is correct
- Tables are created successfully
- Foreign keys are properly defined
- Indexes are created correctly

### Running the Test

```bash
mysql -u [username] -p < tests/server/validate_sql_files.sql
```

### What It Tests

- ✓ Executes each SQL file in dependency order
- ✓ Verifies all tables are created
- ✓ Counts total tables (should be 50+)
- ✓ Lists all foreign key constraints
- ✓ Lists all indexes
- ✓ Provides detailed output for verification

### Expected Results

- All SQL files execute without errors
- 50+ tables created
- Multiple foreign key constraints defined
- Multiple indexes created (excluding PRIMARY keys)
- Test database `phone_test_validation` created

### Cleanup

```sql
DROP DATABASE phone_test_validation;
```

## Test 2: Master Installation Script

This test validates the `install_all_tables.sql` master installation script to ensure:
- All tables are created in correct dependency order
- Table count meets expectations (50+)
- Re-execution works correctly (IF NOT EXISTS)
- No errors occur during installation

### Running the Test

```bash
mysql -u [username] -p < tests/server/test_master_install.sql
```

### What It Tests

- ✓ Executes master installation script
- ✓ Verifies table count (50+)
- ✓ Lists all created tables with sizes
- ✓ Counts foreign keys and indexes
- ✓ Re-executes script to test IF NOT EXISTS
- ✓ Verifies table count remains the same
- ✓ Checks for tables without primary keys
- ✓ Verifies critical core tables exist
- ✓ Shows table structure consistency

### Expected Results

- Master script executes without errors
- 50+ tables created
- Re-execution completes without errors
- Table count remains consistent after re-execution
- All critical tables (phone_players, phone_contacts, etc.) exist
- All tables have primary keys
- Test database `phone_test_master` created

### Cleanup

```sql
DROP DATABASE phone_test_master;
```

## Test 3: Existing Database Compatibility

This test validates backward compatibility by:
- Creating a database with existing tables and data
- Executing the installation script
- Verifying no data loss or corruption
- Testing IF NOT EXISTS functionality

### Running the Test

```bash
mysql -u [username] -p < tests/server/test_existing_database.sql
```

### What It Tests

- ✓ Creates existing tables with test data
- ✓ Executes installation script on existing database
- ✓ Verifies no data loss
- ✓ Verifies data integrity
- ✓ Tests new data insertion
- ✓ Tests foreign key constraints still work
- ✓ Tests CASCADE delete behavior
- ✓ Re-executes script to verify idempotency
- ✓ Checks for duplicate constraints

### Expected Results

- Installation script executes without errors on existing database
- No data loss (original 2 records remain)
- Data integrity maintained
- Foreign key constraints still active
- CASCADE delete works correctly
- Re-execution completes without errors
- No duplicate constraints created
- Test database `phone_test_existing` created

### Cleanup

```sql
DROP DATABASE phone_test_existing;
```

## Running All Tests

To run all tests in sequence:

```bash
# Test 1: Individual files
mysql -u [username] -p < tests/server/validate_sql_files.sql > test_results_1.txt 2>&1

# Test 2: Master installation
mysql -u [username] -p < tests/server/test_master_install.sql > test_results_2.txt 2>&1

# Test 3: Existing database
mysql -u [username] -p < tests/server/test_existing_database.sql > test_results_3.txt 2>&1

# Review results
cat test_results_1.txt
cat test_results_2.txt
cat test_results_3.txt
```

## Automated Testing Script

For convenience, you can create a bash script to run all tests:

```bash
#!/bin/bash
# run_sql_tests.sh

DB_USER="your_username"
DB_PASS="your_password"

echo "Running SQL Schema Tests..."
echo "=========================="

echo ""
echo "Test 1: Individual SQL Files"
mysql -u $DB_USER -p$DB_PASS < tests/server/validate_sql_files.sql

echo ""
echo "Test 2: Master Installation Script"
mysql -u $DB_USER -p$DB_PASS < tests/server/test_master_install.sql

echo ""
echo "Test 3: Existing Database Compatibility"
mysql -u $DB_USER -p$DB_PASS < tests/server/test_existing_database.sql

echo ""
echo "All tests completed!"
echo "Cleaning up test databases..."
mysql -u $DB_USER -p$DB_PASS -e "DROP DATABASE IF EXISTS phone_test_validation;"
mysql -u $DB_USER -p$DB_PASS -e "DROP DATABASE IF EXISTS phone_test_master;"
mysql -u $DB_USER -p$DB_PASS -e "DROP DATABASE IF EXISTS phone_test_existing;"

echo "Cleanup complete!"
```

## Troubleshooting

### Common Issues

**Error: Access denied**
- Ensure your MySQL user has CREATE, DROP, INSERT, SELECT permissions
- Try running with root user or a user with sufficient privileges

**Error: Can't find file**
- Ensure you're running the command from the project root directory
- Verify all SQL files exist in `server/sql/` directory

**Error: Foreign key constraint fails**
- Check that parent tables are created before child tables
- Verify the dependency order in the SQL files

**Error: Table already exists**
- This should not happen if IF NOT EXISTS is used correctly
- Check that all CREATE TABLE statements include IF NOT EXISTS

### Verification Queries

After running tests, you can manually verify results:

```sql
-- Count all phone tables
SELECT COUNT(*) FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'phone_test_master' 
AND TABLE_NAME LIKE 'phone_%';

-- List all tables
SELECT TABLE_NAME FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'phone_test_master' 
AND TABLE_NAME LIKE 'phone_%' 
ORDER BY TABLE_NAME;

-- Count foreign keys
SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE 
WHERE TABLE_SCHEMA = 'phone_test_master' 
AND REFERENCED_TABLE_NAME IS NOT NULL;

-- Count indexes
SELECT COUNT(DISTINCT CONCAT(TABLE_NAME, '.', INDEX_NAME)) 
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'phone_test_master' 
AND INDEX_NAME != 'PRIMARY';
```

## Success Criteria

All tests should pass with the following criteria:

- ✓ All SQL files execute without syntax errors
- ✓ 50+ tables created successfully
- ✓ All foreign key constraints defined correctly
- ✓ All indexes created successfully
- ✓ Master installation script works correctly
- ✓ Re-execution works without errors (IF NOT EXISTS)
- ✓ Backward compatibility maintained
- ✓ No data loss when running on existing database
- ✓ No duplicate constraints created

## Continuous Integration

These tests can be integrated into a CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
name: SQL Schema Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
        ports:
          - 3306:3306
    steps:
      - uses: actions/checkout@v2
      - name: Run SQL Tests
        run: |
          mysql -h 127.0.0.1 -u root -proot < tests/server/validate_sql_files.sql
          mysql -h 127.0.0.1 -u root -proot < tests/server/test_master_install.sql
          mysql -h 127.0.0.1 -u root -proot < tests/server/test_existing_database.sql
```

## Additional Resources

- [MySQL Documentation](https://dev.mysql.com/doc/)
- [MariaDB Documentation](https://mariadb.com/kb/en/)
- [SQL Best Practices](https://www.sqlstyle.guide/)

## Support

If you encounter issues with the tests:

1. Check the error messages carefully
2. Verify your MySQL/MariaDB version compatibility
3. Ensure all SQL files are present and properly formatted
4. Review the troubleshooting section above
5. Check the project documentation for additional help
