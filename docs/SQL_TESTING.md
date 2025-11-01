# SQL Schema Testing Documentation

## Overview

The FiveM Phone System includes a comprehensive SQL schema testing suite to ensure database integrity, backward compatibility, and proper installation procedures. This document provides an overview of the testing approach and how to use the testing tools.

## Testing Philosophy

The SQL schema tests follow these principles:

1. **Validation First**: All SQL files are validated for syntax and structure before deployment
2. **Idempotency**: Scripts can be run multiple times without causing errors or data loss
3. **Backward Compatibility**: New installations work seamlessly with existing databases
4. **Comprehensive Coverage**: Tests cover table creation, foreign keys, indexes, and data integrity

## Test Suite Components

### 1. Individual File Validation

**File**: `tests/server/validate_sql_files.sql`

Tests each SQL file independently to ensure:
- Correct SQL syntax
- Successful table creation
- Proper foreign key definitions
- Correct index creation

**Usage**:
```bash
mysql -u [username] -p < tests/server/validate_sql_files.sql
```

### 2. Master Installation Testing

**File**: `tests/server/test_master_install.sql`

Tests the complete installation process:
- Executes `install_all_tables.sql`
- Verifies all 50+ tables are created
- Tests re-execution safety (IF NOT EXISTS)
- Validates table structure and relationships

**Usage**:
```bash
mysql -u [username] -p < tests/server/test_master_install.sql
```

### 3. Backward Compatibility Testing

**File**: `tests/server/test_existing_database.sql`

Tests compatibility with existing installations:
- Creates database with existing tables and data
- Executes installation script
- Verifies no data loss or corruption
- Tests foreign key constraints and CASCADE behavior

**Usage**:
```bash
mysql -u [username] -p < tests/server/test_existing_database.sql
```

## Automated Testing

### Windows (PowerShell)

```powershell
.\tests\server\run_sql_tests.ps1
```

### Linux/Mac (Bash)

```bash
chmod +x tests/server/run_sql_tests.sh
./tests/server/run_sql_tests.sh
```

The automated scripts:
- Run all three test suites
- Provide colored output and progress indicators
- Automatically clean up test databases
- Report success/failure for each test

## Test Coverage

The testing suite validates:

### Schema Structure
- ✓ 50+ tables created correctly
- ✓ All tables have primary keys
- ✓ Proper data types and constraints
- ✓ Consistent naming conventions

### Relationships
- ✓ Foreign key constraints defined
- ✓ CASCADE delete rules configured
- ✓ Referential integrity maintained
- ✓ No orphaned records possible

### Performance
- ✓ Indexes on frequently queried columns
- ✓ Composite indexes for multi-column queries
- ✓ Foreign key columns indexed
- ✓ Appropriate index types used

### Safety
- ✓ IF NOT EXISTS clauses present
- ✓ Re-execution safe
- ✓ No data loss on existing databases
- ✓ Backward compatible

## Requirements Validation

The tests validate compliance with specification requirements:

| Requirement | Description | Test Coverage |
|------------|-------------|---------------|
| 12.1 | Consistent indentation (4 spaces) | ✓ Validated |
| 12.2 | Uppercase SQL keywords | ✓ Validated |
| 12.3 | Consistent index naming (idx_*) | ✓ Validated |
| 12.4 | Consistent FK naming (fk_*) | ✓ Validated |
| 12.5 | IF NOT EXISTS clauses | ✓ Validated |
| 10.1-10.5 | Master installation script | ✓ Validated |

## Expected Results

### Successful Test Run

When all tests pass, you should see:

```
✓ Test 1 PASSED: Individual SQL files validated successfully
✓ Test 2 PASSED: Master installation script executed successfully
✓ Test 3 PASSED: Existing database compatibility verified
✓ Test databases cleaned up successfully
```

### Table Count

- **Minimum**: 50 tables
- **Typical**: 55-60 tables (depending on optional features)

### Foreign Keys

- **Minimum**: 40+ foreign key constraints
- All foreign keys should reference existing tables
- All foreign keys should have CASCADE delete rules where appropriate

### Indexes

- **Minimum**: 60+ indexes (excluding PRIMARY keys)
- All foreign key columns should be indexed
- Frequently queried columns should have indexes

## Troubleshooting

### Test Failures

If tests fail, check:

1. **MySQL Version**: Ensure MySQL 5.7+ or MariaDB 10.2+
2. **Permissions**: User needs CREATE, DROP, INSERT, SELECT privileges
3. **File Paths**: Run tests from project root directory
4. **SQL Files**: Verify all SQL files exist in `server/sql/`

### Common Errors

**Error: Can't find file**
```
Solution: Run tests from project root directory
```

**Error: Access denied**
```
Solution: Grant appropriate permissions to MySQL user
GRANT CREATE, DROP, INSERT, SELECT ON *.* TO 'user'@'localhost';
```

**Error: Foreign key constraint fails**
```
Solution: Check dependency order in SQL files
Ensure parent tables are created before child tables
```

## Integration Testing

### Manual Integration Test

After running automated tests, perform manual integration testing:

1. Create a fresh database
2. Execute `install_all_tables.sql`
3. Insert test data into core tables
4. Verify foreign key constraints work
5. Test CASCADE delete behavior
6. Verify data integrity

### Sample Integration Test

```sql
-- Create test database
CREATE DATABASE phone_integration_test;
USE phone_integration_test;

-- Install schema
SOURCE server/sql/install_all_tables.sql;

-- Insert test data
INSERT INTO phone_players (identifier, phone_number) 
VALUES ('test_player', '555-0001');

INSERT INTO phone_contacts (phone_number, contact_number, display_name)
VALUES ('555-0001', '555-0002', 'Test Contact');

-- Verify data
SELECT * FROM phone_players;
SELECT * FROM phone_contacts;

-- Test CASCADE delete
DELETE FROM phone_players WHERE phone_number = '555-0001';

-- Verify CASCADE worked (should return 0 rows)
SELECT COUNT(*) FROM phone_contacts WHERE phone_number = '555-0001';

-- Cleanup
DROP DATABASE phone_integration_test;
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: SQL Schema Tests

on: [push, pull_request]

jobs:
  test-sql:
    runs-on: ubuntu-latest
    
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: test
        ports:
          - 3306:3306
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Wait for MySQL
        run: |
          while ! mysqladmin ping -h"127.0.0.1" -P"3306" --silent; do
            sleep 1
          done
      
      - name: Run SQL Tests
        run: |
          mysql -h 127.0.0.1 -u root -proot < tests/server/validate_sql_files.sql
          mysql -h 127.0.0.1 -u root -proot < tests/server/test_master_install.sql
          mysql -h 127.0.0.1 -u root -proot < tests/server/test_existing_database.sql
      
      - name: Cleanup
        if: always()
        run: |
          mysql -h 127.0.0.1 -u root -proot -e "DROP DATABASE IF EXISTS phone_test_validation;"
          mysql -h 127.0.0.1 -u root -proot -e "DROP DATABASE IF EXISTS phone_test_master;"
          mysql -h 127.0.0.1 -u root -proot -e "DROP DATABASE IF EXISTS phone_test_existing;"
```

## Best Practices

### Before Deployment

1. Run all automated tests
2. Review test output for warnings
3. Verify table count matches expectations
4. Check foreign key and index counts
5. Test on a staging database first

### During Development

1. Run tests after modifying SQL files
2. Verify backward compatibility
3. Test with existing data
4. Document any schema changes
5. Update tests if adding new tables

### After Deployment

1. Verify installation on production
2. Check table count and structure
3. Validate foreign keys and indexes
4. Test application functionality
5. Monitor for any errors

## Additional Resources

- [SQL Testing Guide](../tests/server/SQL_TESTING_GUIDE.md) - Detailed testing instructions
- [Test Suite README](../tests/server/README.md) - Quick start guide
- [Installation Guide](../INSTALL.md) - Installation instructions
- [Documentation](DOCUMENTATION.md) - Main project documentation

## Support

For issues with SQL schema testing:

1. Review error messages carefully
2. Check the troubleshooting section
3. Verify MySQL/MariaDB version compatibility
4. Ensure all prerequisites are met
5. Consult the detailed testing guide

## Conclusion

The SQL schema testing suite provides comprehensive validation of database structure, relationships, and compatibility. Regular testing ensures database integrity and prevents issues during installation and upgrades.

For detailed testing procedures, see [SQL_TESTING_GUIDE.md](../tests/server/SQL_TESTING_GUIDE.md).
