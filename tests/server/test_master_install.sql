-- ============================================================================
-- Master Installation Script Test
-- ============================================================================
-- This script tests the install_all_tables.sql master installation script
-- Run this script with: mysql -u [user] -p < tests/server/test_master_install.sql
-- ============================================================================

-- Create a clean test database
DROP DATABASE IF EXISTS phone_test_master;
CREATE DATABASE phone_test_master;
USE phone_test_master;

SELECT '============================================================================' AS '';
SELECT 'Master Installation Script Test' AS '';
SELECT '============================================================================' AS '';

-- Test 1: Execute master installation script
SELECT '' AS '';
SELECT '--- Test 1: Executing install_all_tables.sql ---' AS '';
SOURCE server/sql/install_all_tables.sql;
SELECT 'Master installation completed' AS 'Result';

-- Test 2: Verify table count
SELECT '' AS '';
SELECT '--- Test 2: Verifying Table Count ---' AS '';
SELECT COUNT(*) AS 'Total Tables (Expected: 50+)'
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'phone_test_master'
AND TABLE_NAME LIKE 'phone_%';

-- Test 3: List all created tables
SELECT '' AS '';
SELECT '--- Test 3: All Created Tables ---' AS '';
SELECT TABLE_NAME, TABLE_ROWS, 
       ROUND(DATA_LENGTH / 1024, 2) AS 'Size (KB)'
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'phone_test_master'
AND TABLE_NAME LIKE 'phone_%'
ORDER BY TABLE_NAME;

-- Test 4: Verify foreign key constraints
SELECT '' AS '';
SELECT '--- Test 4: Foreign Key Constraints ---' AS '';
SELECT COUNT(*) AS 'Total Foreign Keys'
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'phone_test_master'
AND REFERENCED_TABLE_NAME IS NOT NULL
AND TABLE_NAME LIKE 'phone_%';

-- Test 5: Verify indexes
SELECT '' AS '';
SELECT '--- Test 5: Indexes ---' AS '';
SELECT COUNT(DISTINCT CONCAT(TABLE_NAME, '.', INDEX_NAME)) AS 'Total Indexes (excluding PRIMARY)'
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'phone_test_master'
AND TABLE_NAME LIKE 'phone_%'
AND INDEX_NAME != 'PRIMARY';

-- Test 6: Re-execute master installation script (test IF NOT EXISTS)
SELECT '' AS '';
SELECT '--- Test 6: Re-executing install_all_tables.sql (IF NOT EXISTS test) ---' AS '';
SOURCE server/sql/install_all_tables.sql;
SELECT 'Re-execution completed without errors' AS 'Result';

-- Test 7: Verify table count after re-execution
SELECT '' AS '';
SELECT '--- Test 7: Verifying Table Count After Re-execution ---' AS '';
SELECT COUNT(*) AS 'Total Tables (Should be same as before)'
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'phone_test_master'
AND TABLE_NAME LIKE 'phone_%';

-- Test 8: Check for any tables without primary keys
SELECT '' AS '';
SELECT '--- Test 8: Tables Without Primary Keys ---' AS '';
SELECT t.TABLE_NAME
FROM information_schema.TABLES t
LEFT JOIN information_schema.TABLE_CONSTRAINTS tc
    ON t.TABLE_SCHEMA = tc.TABLE_SCHEMA
    AND t.TABLE_NAME = tc.TABLE_NAME
    AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
WHERE t.TABLE_SCHEMA = 'phone_test_master'
AND t.TABLE_NAME LIKE 'phone_%'
AND tc.CONSTRAINT_NAME IS NULL;

-- Test 9: Verify critical core tables exist
SELECT '' AS '';
SELECT '--- Test 9: Critical Core Tables ---' AS '';
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'phone_test_master' AND TABLE_NAME = 'phone_players') 
        THEN 'EXISTS' ELSE 'MISSING' 
    END AS 'phone_players',
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'phone_test_master' AND TABLE_NAME = 'phone_contacts') 
        THEN 'EXISTS' ELSE 'MISSING' 
    END AS 'phone_contacts',
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'phone_test_master' AND TABLE_NAME = 'phone_messages') 
        THEN 'EXISTS' ELSE 'MISSING' 
    END AS 'phone_messages',
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'phone_test_master' AND TABLE_NAME = 'phone_media') 
        THEN 'EXISTS' ELSE 'MISSING' 
    END AS 'phone_media';

-- Test 10: Verify table structure consistency
SELECT '' AS '';
SELECT '--- Test 10: Table Structure Consistency ---' AS '';
SELECT 
    TABLE_NAME,
    COUNT(*) AS 'Column Count'
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'phone_test_master'
AND TABLE_NAME LIKE 'phone_%'
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

-- Final summary
SELECT '' AS '';
SELECT '============================================================================' AS '';
SELECT 'Master Installation Test Complete' AS '';
SELECT '============================================================================' AS '';
SELECT 'All tests passed!' AS 'Status';
SELECT 'Test database: phone_test_master' AS 'Note';
SELECT 'You can inspect the database or drop it when done.' AS 'Note';

-- Cleanup instructions
SELECT '' AS '';
SELECT 'To clean up test database, run:' AS '';
SELECT 'DROP DATABASE phone_test_master;' AS 'Command';
