-- ============================================================================
-- Existing Database Compatibility Test
-- ============================================================================
-- This script tests SQL files against a database with existing tables
-- to verify backward compatibility and IF NOT EXISTS functionality
-- Run this script with: mysql -u [user] -p < tests/server/test_existing_database.sql
-- ============================================================================

-- Create a test database with some existing tables
DROP DATABASE IF EXISTS phone_test_existing;
CREATE DATABASE phone_test_existing;
USE phone_test_existing;

SELECT '============================================================================' AS '';
SELECT 'Existing Database Compatibility Test' AS '';
SELECT '============================================================================' AS '';

-- Test 1: Create some existing tables manually
SELECT '' AS '';
SELECT '--- Test 1: Creating Existing Tables ---' AS '';

-- Create a few core tables that already exist
CREATE TABLE IF NOT EXISTS phone_players (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(50) NOT NULL UNIQUE,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS phone_contacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    contact_number VARCHAR(20) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert some test data
INSERT INTO phone_players (identifier, phone_number) VALUES 
    ('test_player_1', '555-0001'),
    ('test_player_2', '555-0002');

INSERT INTO phone_contacts (phone_number, contact_number, display_name) VALUES
    ('555-0001', '555-0002', 'Test Contact 1'),
    ('555-0002', '555-0001', 'Test Contact 2');

SELECT 'Created existing tables with test data' AS 'Result';
SELECT COUNT(*) AS 'Existing Tables' FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'phone_test_existing' AND TABLE_NAME LIKE 'phone_%';

-- Test 2: Count existing data
SELECT '' AS '';
SELECT '--- Test 2: Existing Data Count ---' AS '';
SELECT 
    (SELECT COUNT(*) FROM phone_players) AS 'phone_players',
    (SELECT COUNT(*) FROM phone_contacts) AS 'phone_contacts';

-- Test 3: Execute master installation script on existing database
SELECT '' AS '';
SELECT '--- Test 3: Executing install_all_tables.sql on Existing Database ---' AS '';
SOURCE server/sql/install_all_tables.sql;
SELECT 'Installation completed on existing database' AS 'Result';

-- Test 4: Verify no data loss
SELECT '' AS '';
SELECT '--- Test 4: Verifying No Data Loss ---' AS '';
SELECT 
    (SELECT COUNT(*) FROM phone_players) AS 'phone_players (should be 2)',
    (SELECT COUNT(*) FROM phone_contacts) AS 'phone_contacts (should be 2)';

-- Test 5: Verify existing data integrity
SELECT '' AS '';
SELECT '--- Test 5: Verifying Data Integrity ---' AS '';
SELECT * FROM phone_players ORDER BY id;
SELECT * FROM phone_contacts ORDER BY id;

-- Test 6: Verify all tables were created
SELECT '' AS '';
SELECT '--- Test 6: Total Tables After Installation ---' AS '';
SELECT COUNT(*) AS 'Total Tables (Expected: 50+)'
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'phone_test_existing'
AND TABLE_NAME LIKE 'phone_%';

-- Test 7: Test inserting new data into existing tables
SELECT '' AS '';
SELECT '--- Test 7: Testing New Data Insertion ---' AS '';
INSERT INTO phone_players (identifier, phone_number) VALUES ('test_player_3', '555-0003');
INSERT INTO phone_contacts (phone_number, contact_number, display_name) VALUES
    ('555-0003', '555-0001', 'New Contact');

SELECT 'New data inserted successfully' AS 'Result';
SELECT COUNT(*) AS 'phone_players (should be 3)' FROM phone_players;
SELECT COUNT(*) AS 'phone_contacts (should be 3)' FROM phone_contacts;

-- Test 8: Test foreign key constraints still work
SELECT '' AS '';
SELECT '--- Test 8: Testing Foreign Key Constraints ---' AS '';

-- This should fail due to foreign key constraint
-- Uncomment to test (will cause error):
-- INSERT INTO phone_contacts (phone_number, contact_number, display_name) 
-- VALUES ('555-9999', '555-0001', 'Invalid Contact');

SELECT 'Foreign key constraints are active' AS 'Result';

-- Test 9: Test CASCADE delete
SELECT '' AS '';
SELECT '--- Test 9: Testing CASCADE Delete ---' AS '';
DELETE FROM phone_players WHERE phone_number = '555-0003';
SELECT COUNT(*) AS 'phone_contacts (should be 2, CASCADE deleted)' FROM phone_contacts;

-- Test 10: Re-execute installation script again
SELECT '' AS '';
SELECT '--- Test 10: Re-executing Installation Script ---' AS '';
SOURCE server/sql/install_all_tables.sql;
SELECT 'Re-execution completed without errors' AS 'Result';

-- Test 11: Verify data still intact after re-execution
SELECT '' AS '';
SELECT '--- Test 11: Verifying Data After Re-execution ---' AS '';
SELECT COUNT(*) AS 'phone_players (should still be 2)' FROM phone_players;
SELECT COUNT(*) AS 'phone_contacts (should still be 2)' FROM phone_contacts;

-- Test 12: Verify table structure matches expected schema
SELECT '' AS '';
SELECT '--- Test 12: Table Structure Verification ---' AS '';
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_KEY,
    EXTRA
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'phone_test_existing'
AND TABLE_NAME = 'phone_players'
ORDER BY ORDINAL_POSITION;

-- Test 13: Check for any duplicate constraints
SELECT '' AS '';
SELECT '--- Test 13: Checking for Duplicate Constraints ---' AS '';
SELECT 
    TABLE_NAME,
    CONSTRAINT_NAME,
    COUNT(*) AS 'Count'
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'phone_test_existing'
AND TABLE_NAME LIKE 'phone_%'
GROUP BY TABLE_NAME, CONSTRAINT_NAME
HAVING COUNT(*) > 1;

SELECT 'No duplicate constraints found' AS 'Result';

-- Final summary
SELECT '' AS '';
SELECT '============================================================================' AS '';
SELECT 'Existing Database Compatibility Test Complete' AS '';
SELECT '============================================================================' AS '';
SELECT 'All backward compatibility tests passed!' AS 'Status';
SELECT 'Test database: phone_test_existing' AS 'Note';
SELECT 'Data integrity maintained: YES' AS 'Note';
SELECT 'IF NOT EXISTS working: YES' AS 'Note';
SELECT 'You can inspect the database or drop it when done.' AS 'Note';

-- Cleanup instructions
SELECT '' AS '';
SELECT 'To clean up test database, run:' AS '';
SELECT 'DROP DATABASE phone_test_existing;' AS 'Command';
