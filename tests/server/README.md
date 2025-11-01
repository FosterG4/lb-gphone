# SQL Schema Testing Suite

This directory contains comprehensive tests for validating the SQL schema files used by the FiveM Phone System.

## Test Files

### SQL Test Scripts

1. **validate_sql_files.sql** - Tests individual SQL files independently
   - Executes each SQL file in dependency order
   - Verifies table creation
   - Validates foreign keys and indexes
   - Creates test database: `phone_test_validation`

2. **test_master_install.sql** - Tests the master installation script
   - Executes `install_all_tables.sql`
   - Verifies all 50+ tables are created
   - Tests re-execution (IF NOT EXISTS functionality)
   - Creates test database: `phone_test_master`

3. **test_existing_database.sql** - Tests backward compatibility
   - Creates database with existing tables and data
   - Executes installation script
   - Verifies no data loss or corruption
   - Tests CASCADE delete and foreign key constraints
   - Creates test database: `phone_test_existing`

### Automation Scripts

4. **run_sql_tests.ps1** - PowerShell script for Windows
   - Runs all three SQL test scripts
   - Provides colored output and progress indicators
   - Automatically cleans up test databases
   - Usage: `.\tests\server\run_sql_tests.ps1`

5. **run_sql_tests.sh** - Bash script for Linux/Mac
   - Runs all three SQL test scripts
   - Provides colored output and progress indicators
   - Automatically cleans up test databases
   - Usage: `./tests/server/run_sql_tests.sh`
   - Make executable: `chmod +x tests/server/run_sql_tests.sh`

### Documentation

6. **SQL_TESTING_GUIDE.md** - Comprehensive testing guide
   - Detailed instructions for running tests
   - Troubleshooting tips
   - Success criteria
   - CI/CD integration examples

## Quick Start

### Windows (PowerShell)

```powershell
# Run all tests
.\tests\server\run_sql_tests.ps1

# Or with custom credentials
.\tests\server\run_sql_tests.ps1 -DBUser "myuser" -DBPassword "mypass"
```

### Linux/Mac (Bash)

```bash
# Make script executable (first time only)
chmod +x tests/server/run_sql_tests.sh

# Run all tests
./tests/server/run_sql_tests.sh

# Or with environment variables
DB_USER=myuser DB_PASSWORD=mypass ./tests/server/run_sql_tests.sh
```

### Manual Testing

```bash
# Test individual files
mysql -u root -p < tests/server/validate_sql_files.sql

# Test master installation
mysql -u root -p < tests/server/test_master_install.sql

# Test existing database compatibility
mysql -u root -p < tests/server/test_existing_database.sql
```

## What Gets Tested

### Test Coverage

- ✓ SQL syntax validation
- ✓ Table creation (50+ tables)
- ✓ Foreign key constraints
- ✓ Index creation
- ✓ Primary key validation
- ✓ IF NOT EXISTS functionality
- ✓ Backward compatibility
- ✓ Data integrity
- ✓ CASCADE delete behavior
- ✓ Re-execution safety

### Requirements Validated

The tests validate all requirements from the SQL consolidation specification:

- **Requirement 12.1**: Consistent indentation and formatting
- **Requirement 12.2**: Uppercase SQL keywords
- **Requirement 12.3**: Consistent naming patterns for indexes
- **Requirement 12.4**: Consistent naming patterns for foreign keys
- **Requirement 12.5**: IF NOT EXISTS clauses in all CREATE TABLE statements
- **Requirement 10.1-10.5**: Master installation script functionality

## Expected Results

All tests should pass with:

- 50+ tables created successfully
- Multiple foreign key constraints defined
- Multiple indexes created (excluding PRIMARY)
- No errors during execution
- No data loss when running on existing database
- Successful re-execution without errors

## Test Databases

The tests create temporary databases:

- `phone_test_validation` - For individual file tests
- `phone_test_master` - For master installation tests
- `phone_test_existing` - For backward compatibility tests

These databases are automatically cleaned up after tests complete.

## Troubleshooting

### Common Issues

**MySQL client not found**
- Install MySQL client: `apt-get install mysql-client` (Linux) or download from mysql.com (Windows)
- Ensure MySQL is in your PATH

**Access denied**
- Verify your MySQL credentials
- Ensure user has CREATE, DROP, INSERT, SELECT permissions

**Can't find SQL files**
- Run tests from project root directory
- Verify all SQL files exist in `server/sql/` directory

**Foreign key constraint fails**
- Check dependency order in SQL files
- Verify parent tables are created before child tables

### Getting Help

1. Review the detailed [SQL_TESTING_GUIDE.md](SQL_TESTING_GUIDE.md)
2. Check error messages in test output
3. Verify MySQL/MariaDB version compatibility
4. Ensure all SQL files are present and properly formatted

## Integration with CI/CD

These tests can be integrated into continuous integration pipelines. See [SQL_TESTING_GUIDE.md](SQL_TESTING_GUIDE.md) for examples.

## Additional Resources

- [SQL Testing Guide](SQL_TESTING_GUIDE.md) - Comprehensive testing documentation
- [Project Documentation](../../docs/DOCUMENTATION.md) - Main project documentation
- [Installation Guide](../../INSTALL.md) - Installation instructions
