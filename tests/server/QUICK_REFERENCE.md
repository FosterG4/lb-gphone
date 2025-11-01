# SQL Testing Quick Reference

## Quick Commands

### Windows (PowerShell)
```powershell
# Run all tests
.\tests\server\run_sql_tests.ps1

# With custom credentials
.\tests\server\run_sql_tests.ps1 -DBUser "root" -DBPassword "password"
```

### Linux/Mac (Bash)
```bash
# Make executable (first time)
chmod +x tests/server/run_sql_tests.sh

# Run all tests
./tests/server/run_sql_tests.sh

# With environment variables
DB_USER=root DB_PASSWORD=password ./tests/server/run_sql_tests.sh
```

### Manual Testing
```bash
# Test 1: Individual files
mysql -u root -p < tests/server/validate_sql_files.sql

# Test 2: Master installation
mysql -u root -p < tests/server/test_master_install.sql

# Test 3: Existing database
mysql -u root -p < tests/server/test_existing_database.sql
```

## Test Files

| File | Purpose | Test Database |
|------|---------|---------------|
| `validate_sql_files.sql` | Tests individual SQL files | `phone_test_validation` |
| `test_master_install.sql` | Tests master installation | `phone_test_master` |
| `test_existing_database.sql` | Tests backward compatibility | `phone_test_existing` |

## Expected Results

✓ **Tables**: 50+ created  
✓ **Foreign Keys**: 40+ defined  
✓ **Indexes**: 60+ created  
✓ **Re-execution**: No errors  
✓ **Data Integrity**: Maintained  

## Common Issues

| Issue | Solution |
|-------|----------|
| MySQL not found | Install MySQL client or add to PATH |
| Access denied | Grant CREATE, DROP, INSERT, SELECT permissions |
| Can't find files | Run from project root directory |
| Foreign key fails | Check dependency order in SQL files |

## Cleanup

```sql
-- Remove test databases
DROP DATABASE IF EXISTS phone_test_validation;
DROP DATABASE IF EXISTS phone_test_master;
DROP DATABASE IF EXISTS phone_test_existing;
```

## Success Indicators

```
✓ Test 1 PASSED: Individual SQL files validated successfully
✓ Test 2 PASSED: Master installation script executed successfully
✓ Test 3 PASSED: Existing database compatibility verified
✓ Test databases cleaned up successfully
```

## Documentation

- **Detailed Guide**: [SQL_TESTING_GUIDE.md](SQL_TESTING_GUIDE.md)
- **Test Suite Info**: [README.md](README.md)
- **Project Docs**: [../../docs/SQL_TESTING.md](../../docs/SQL_TESTING.md)

## Support

1. Check error messages
2. Review [SQL_TESTING_GUIDE.md](SQL_TESTING_GUIDE.md)
3. Verify MySQL version (5.7+ or MariaDB 10.2+)
4. Ensure proper permissions
5. Run from project root

---

**Quick Tip**: The automated scripts (`run_sql_tests.ps1` or `run_sql_tests.sh`) handle everything automatically, including cleanup!
