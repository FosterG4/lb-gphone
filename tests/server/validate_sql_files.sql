-- ============================================================================
-- SQL Schema Validation Script
-- ============================================================================
-- This script validates all SQL files by executing them and checking results
-- Run this script with: mysql -u [user] -p < tests/server/validate_sql_files.sql
-- ============================================================================

-- Create a test database
DROP DATABASE IF EXISTS phone_test_validation;
CREATE DATABASE phone_test_validation;
USE phone_test_validation;

-- Display start message
SELECT '============================================================================' AS '';
SELECT 'SQL Schema Validation - Individual File Tests' AS '';
SELECT '============================================================================' AS '';

-- Test 1: Core Tables
SELECT '' AS '';
SELECT '--- Testing phone_core_tables.sql ---' AS '';
SOURCE server/sql/phone_core_tables.sql;
SELECT 'Core tables created successfully' AS 'Result';

-- Test 2: Media Tables
SELECT '' AS '';
SELECT '--- Testing phone_media_tables.sql ---' AS '';
SOURCE server/sql/phone_media_tables.sql;
SELECT 'Media tables created successfully' AS 'Result';

-- Test 3: Chirper Tables
SELECT '' AS '';
SELECT '--- Testing phone_chirper_tables.sql ---' AS '';
SOURCE server/sql/phone_chirper_tables.sql;
SELECT 'Chirper tables created successfully' AS 'Result';

-- Test 4: Shotz Tables
SELECT '' AS '';
SELECT '--- Testing phone_shotz_additional_tables.sql ---' AS '';
SOURCE server/sql/phone_shotz_additional_tables.sql;
SELECT 'Shotz tables created successfully' AS 'Result';

-- Test 5: Modish Tables
SELECT '' AS '';
SELECT '--- Testing phone_modish_tables.sql ---' AS '';
SOURCE server/sql/phone_modish_tables.sql;
SELECT 'Modish tables created successfully' AS 'Result';

-- Test 6: Flicker Tables
SELECT '' AS '';
SELECT '--- Testing phone_flicker_tables.sql ---' AS '';
SOURCE server/sql/phone_flicker_tables.sql;
SELECT 'Flicker tables created successfully' AS 'Result';

-- Test 7: Contact Sharing Tables
SELECT '' AS '';
SELECT '--- Testing phone_contact_sharing_tables.sql ---' AS '';
SOURCE server/sql/phone_contact_sharing_tables.sql;
SELECT 'Contact sharing tables created successfully' AS 'Result';

-- Test 8: Social Media Multi Attachments
SELECT '' AS '';
SELECT '--- Testing phone_social_media_multi_attachments.sql ---' AS '';
SOURCE server/sql/phone_social_media_multi_attachments.sql;
SELECT 'Social media multi attachments tables created successfully' AS 'Result';

-- Test 9: Wallet Tables
SELECT '' AS '';
SELECT '--- Testing phone_wallet_tables.sql ---' AS '';
SOURCE server/sql/phone_wallet_tables.sql;
SELECT 'Wallet tables created successfully' AS 'Result';

-- Test 10: CryptoX Tables
SELECT '' AS '';
SELECT '--- Testing phone_cryptox_tables.sql ---' AS '';
SOURCE server/sql/phone_cryptox_tables.sql;
SELECT 'CryptoX tables created successfully' AS 'Result';

-- Test 11: Musicly Tables
SELECT '' AS '';
SELECT '--- Testing phone_musicly_tables.sql ---' AS '';
SOURCE server/sql/phone_musicly_tables.sql;
SELECT 'Musicly tables created successfully' AS 'Result';

-- Test 12: Finder Tables
SELECT '' AS '';
SELECT '--- Testing phone_finder_tables.sql ---' AS '';
SOURCE server/sql/phone_finder_tables.sql;
SELECT 'Finder tables created successfully' AS 'Result';

-- Test 13: SafeZone Tables
SELECT '' AS '';
SELECT '--- Testing phone_safezone_tables.sql ---' AS '';
SOURCE server/sql/phone_safezone_tables.sql;
SELECT 'SafeZone tables created successfully' AS 'Result';

-- Test 14: Marketplace Tables
SELECT '' AS '';
SELECT '--- Testing phone_marketplace_tables.sql ---' AS '';
SOURCE server/sql/phone_marketplace_tables.sql;
SELECT 'Marketplace tables created successfully' AS 'Result';

-- Test 15: Business Tables
SELECT '' AS '';
SELECT '--- Testing phone_business_tables.sql ---' AS '';
SOURCE server/sql/phone_business_tables.sql;
SELECT 'Business tables created successfully' AS 'Result';

-- Test 16: Utilities Tables
SELECT '' AS '';
SELECT '--- Testing phone_utilities_tables.sql ---' AS '';
SOURCE server/sql/phone_utilities_tables.sql;
SELECT 'Utilities tables created successfully' AS 'Result';

-- Test 17: Assets Tables
SELECT '' AS '';
SELECT '--- Testing phone_assets_tables.sql ---' AS '';
SOURCE server/sql/phone_assets_tables.sql;
SELECT 'Assets tables created successfully' AS 'Result';

-- Verify all tables were created
SELECT '' AS '';
SELECT '============================================================================' AS '';
SELECT 'Verification Tests' AS '';
SELECT '============================================================================' AS '';

-- Count total tables
SELECT '' AS '';
SELECT 'Table Count:' AS '';
SELECT COUNT(*) AS 'Total Tables Created'
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'phone_test_validation'
AND TABLE_NAME LIKE 'phone_%';

-- List all tables
SELECT '' AS '';
SELECT 'All Tables:' AS '';
SELECT TABLE_NAME
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'phone_test_validation'
AND TABLE_NAME LIKE 'phone_%'
ORDER BY TABLE_NAME;

-- Verify foreign key constraints
SELECT '' AS '';
SELECT 'Foreign Key Constraints:' AS '';
SELECT 
    COUNT(*) AS 'Total Foreign Keys'
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'phone_test_validation'
AND REFERENCED_TABLE_NAME IS NOT NULL
AND TABLE_NAME LIKE 'phone_%';

-- List foreign keys
SELECT '' AS '';
SELECT 'Foreign Key Details:' AS '';
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'phone_test_validation'
AND REFERENCED_TABLE_NAME IS NOT NULL
AND TABLE_NAME LIKE 'phone_%'
ORDER BY TABLE_NAME, COLUMN_NAME;

-- Verify indexes
SELECT '' AS '';
SELECT 'Indexes (excluding PRIMARY):' AS '';
SELECT 
    COUNT(DISTINCT CONCAT(TABLE_NAME, '.', INDEX_NAME)) AS 'Total Indexes'
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'phone_test_validation'
AND TABLE_NAME LIKE 'phone_%'
AND INDEX_NAME != 'PRIMARY';

-- List indexes
SELECT '' AS '';
SELECT 'Index Details:' AS '';
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS 'Columns'
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'phone_test_validation'
AND TABLE_NAME LIKE 'phone_%'
AND INDEX_NAME != 'PRIMARY'
GROUP BY TABLE_NAME, INDEX_NAME
ORDER BY TABLE_NAME, INDEX_NAME;

-- Final summary
SELECT '' AS '';
SELECT '============================================================================' AS '';
SELECT 'Validation Complete' AS '';
SELECT '============================================================================' AS '';
SELECT 'All SQL files executed successfully!' AS 'Status';
SELECT 'Test database: phone_test_validation' AS 'Note';
SELECT 'You can inspect the database or drop it when done.' AS 'Note';
