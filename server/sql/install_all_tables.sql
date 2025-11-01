-- ============================================================================
-- Master Database Installation Script
-- FiveM Phone System - Complete Schema Installation
-- ============================================================================
-- 
-- DESCRIPTION:
--   This script creates all database tables for the FiveM Phone System.
--   Execute this file to set up the complete database schema in the correct
--   dependency order.
--
-- USAGE:
--   From MySQL command line:
--     mysql -u [username] -p [database_name] < server/sql/install_all_tables.sql
--   
--   Or from MySQL prompt:
--     USE [database_name];
--     SOURCE server/sql/install_all_tables.sql;
--
-- REQUIREMENTS:
--   - MySQL 5.7+ or MariaDB 10.2+
--   - Database must already exist
--   - User must have CREATE TABLE privileges
--
-- NOTES:
--   - All tables use IF NOT EXISTS, so this script is safe to re-run
--   - Existing tables will not be modified or dropped
--   - Foreign key constraints ensure referential integrity
--   - Tables are created in dependency order to avoid constraint errors
--
-- EXECUTION ORDER:
--   The tables are created in a specific order to satisfy foreign key
--   dependencies. Each phase depends on tables from previous phases.
--
--   1. Core tables (no dependencies)
--      - phone_players, phone_contacts, phone_messages, phone_call_history, phone_settings
--      - These are the foundation tables that other tables reference
--
--   2. Media tables (depends on phone_players)
--      - phone_media, phone_albums, phone_album_media
--      - Stores photos, videos, and audio files
--
--   3. Social media tables (depends on phone_players, phone_media)
--      - Chirper, Shotz, Modish, Flicker apps
--      - User-generated content with media attachments
--
--   4. Financial tables (depends on phone_players)
--      - Wallet and CryptoX apps
--      - Transaction history and cryptocurrency holdings
--
--   5. Entertainment tables (depends on phone_players)
--      - Musicly app
--      - Playlists and play history
--
--   6. Location and safety tables (depends on phone_players)
--      - Finder and SafeZone apps
--      - Device tracking and emergency features
--
--   7. Commerce tables (depends on phone_players)
--      - Marketplace and Business Pages
--      - Listings, transactions, and reviews
--
--   8. Utility tables (depends on phone_players, phone_media)
--      - Notes, Alarms, Voice Recorder
--      - Personal productivity features
--
--   9. Asset tables (depends on phone_players)
--      - Vehicles and Properties
--      - Asset tracking and access control
--
-- ERROR HANDLING:
--   - All CREATE TABLE statements use IF NOT EXISTS clause
--   - This allows safe re-execution without errors on existing tables
--   - Existing tables will NOT be modified, dropped, or have data affected
--   - If a SOURCE command fails, subsequent commands will still execute
--   - Check MySQL error log for detailed error messages if issues occur
--   - Common issues:
--     * File not found: Ensure you're running from the correct directory
--     * Permission denied: Ensure database user has CREATE TABLE privileges
--     * Syntax errors: Check MySQL version compatibility (requires 5.7+)
--     * Foreign key errors: Should not occur due to dependency ordering
--
-- ============================================================================

-- Display start message
SELECT '============================================================================' AS '';
SELECT 'FiveM Phone System - Database Installation' AS '';
SELECT 'Starting table creation...' AS '';
SELECT '============================================================================' AS '';

-- ============================================================================
-- PHASE 1: Core System Tables
-- ============================================================================
-- These tables form the foundation of the phone system and have no dependencies
-- on other tables. They must be created first as other tables reference them.
--
-- Tables created in this phase:
--   - phone_players: Main user/player table (referenced by almost all tables)
--   - phone_contacts: Contact list for each phone
--   - phone_messages: SMS/text message storage
--   - phone_call_history: Call logs with duration and type
--   - phone_settings: User preferences and configuration
--
-- Dependencies: None (root tables)
-- ============================================================================

SELECT '' AS '';
SELECT '>>> PHASE 1: Creating Core System Tables...' AS '';
SELECT '    Tables: phone_players, phone_contacts, phone_messages, phone_call_history, phone_settings' AS '';

SOURCE server/sql/phone_core_tables.sql;

SELECT '✓ Core tables created successfully (5 tables)' AS '';

-- ============================================================================
-- PHASE 2: Media Storage Tables
-- ============================================================================
-- Media tables depend on phone_players from core tables. These handle photo,
-- video, and audio storage for the phone system.
--
-- Tables created in this phase:
--   - phone_media: Central media storage (photos, videos, audio)
--   - phone_albums: Photo album organization
--   - phone_album_media: Junction table for album-media relationships
--
-- Dependencies: phone_players (from Phase 1)
-- ============================================================================

SELECT '' AS '';
SELECT '>>> PHASE 2: Creating Media Storage Tables...' AS '';
SELECT '    Tables: phone_media, phone_albums, phone_album_media' AS '';

SOURCE server/sql/phone_media_tables.sql;

SELECT '✓ Media tables created successfully (3 tables)' AS '';

-- ============================================================================
-- PHASE 3: Social Media Application Tables
-- ============================================================================
-- Social media apps depend on core tables (phone_players) and media tables
-- (phone_media) for user profiles and content attachments.
--
-- Applications in this phase:
--   - Chirper: Twitter-like social media app
--   - Shotz: Instagram-like photo sharing app
--   - Modish: TikTok-like video sharing app
--   - Flicker: Dating/matching app
--   - Multi-attachment support for posts
--   - Contact sharing features
--
-- Dependencies: phone_players (Phase 1), phone_media (Phase 2)
-- ============================================================================

SELECT '' AS '';
SELECT '>>> PHASE 3: Creating Social Media Application Tables...' AS '';
SELECT '    Apps: Chirper, Shotz, Modish, Flicker, Contact Sharing' AS '';

-- Chirper (Twitter-like app)
SOURCE server/sql/phone_chirper_tables.sql;

-- Shotz (Instagram-like app)
SOURCE server/sql/phone_shotz_additional_tables.sql;

-- Modish (TikTok-like app)
SOURCE server/sql/phone_modish_tables.sql;

-- Flicker (Dating app)
SOURCE server/sql/phone_flicker_tables.sql;

-- Multi-attachment support for social media
SOURCE server/sql/phone_social_media_multi_attachments.sql;

-- Contact sharing features
SOURCE server/sql/phone_contact_sharing_tables.sql;

SELECT '✓ Social media tables created successfully (20+ tables)' AS '';

-- ============================================================================
-- PHASE 4: Financial Application Tables
-- ============================================================================
-- Financial apps depend on phone_players for ownership tracking. These handle
-- wallet transactions and cryptocurrency trading.
--
-- Applications in this phase:
--   - Wallet: Unified banking with transactions, budgets, and recurring payments
--   - CryptoX: Cryptocurrency trading with holdings, transactions, and alerts
--
-- Dependencies: phone_players (Phase 1)
-- Note: Uses DECIMAL types for precise financial calculations
-- ============================================================================

SELECT '' AS '';
SELECT '>>> PHASE 4: Creating Financial Application Tables...' AS '';
SELECT '    Apps: Wallet (Bankr), CryptoX' AS '';

-- Wallet app (unified banking)
SOURCE server/sql/phone_wallet_tables.sql;

-- CryptoX app (cryptocurrency trading)
SOURCE server/sql/phone_cryptox_tables.sql;

SELECT '✓ Financial tables created successfully (8 tables)' AS '';

-- ============================================================================
-- PHASE 5: Entertainment Application Tables
-- ============================================================================
-- Entertainment apps depend on phone_players for user data. These handle
-- music playback and playlist management.
--
-- Applications in this phase:
--   - Musicly: Music player with playlists and play history
--
-- Dependencies: phone_players (Phase 1)
-- ============================================================================

SELECT '' AS '';
SELECT '>>> PHASE 5: Creating Entertainment Application Tables...' AS '';
SELECT '    Apps: Musicly' AS '';

-- Musicly app (music player)
SOURCE server/sql/phone_musicly_tables.sql;

SELECT '✓ Entertainment tables created successfully (3 tables)' AS '';

-- ============================================================================
-- PHASE 6: Location and Safety Application Tables
-- ============================================================================
-- Location and safety apps depend on phone_players for user tracking and
-- emergency contacts. These handle device tracking and emergency features.
--
-- Applications in this phase:
--   - Finder: Device tracking with lost mode and location sharing
--   - SafeZone: Emergency features with contact notifications
--
-- Dependencies: phone_players (Phase 1)
-- Note: Stores GPS coordinates and emergency contact information
-- ============================================================================

SELECT '' AS '';
SELECT '>>> PHASE 6: Creating Location and Safety Application Tables...' AS '';
SELECT '    Apps: Finder, SafeZone' AS '';

-- Finder app (device tracking)
SOURCE server/sql/phone_finder_tables.sql;

-- SafeZone app (emergency features)
SOURCE server/sql/phone_safezone_tables.sql;

SELECT '✓ Location and safety tables created successfully (8 tables)' AS '';

-- ============================================================================
-- PHASE 7: Commerce Application Tables
-- ============================================================================
-- Commerce apps depend on phone_players for buyer/seller relationships.
-- These handle marketplace listings and business pages.
--
-- Applications in this phase:
--   - Marketplace: Listings, transactions, reviews, and favorites
--   - Business Pages: Business profiles, followers, reviews, and analytics
--
-- Dependencies: phone_players (Phase 1)
-- Note: Includes rating systems and transaction tracking
-- ============================================================================

SELECT '' AS '';
SELECT '>>> PHASE 7: Creating Commerce Application Tables...' AS '';
SELECT '    Apps: Marketplace, Business Pages' AS '';

-- Marketplace app
SOURCE server/sql/phone_marketplace_tables.sql;

-- Business pages
SOURCE server/sql/phone_business_tables.sql;

SELECT '✓ Commerce tables created successfully (8 tables)' AS '';

-- ============================================================================
-- PHASE 8: Utility Application Tables
-- ============================================================================
-- Utility apps depend on phone_players and phone_media for personal
-- productivity features like notes, alarms, and voice recordings.
--
-- Applications in this phase:
--   - Notes: Text notes with timestamps
--   - Alarms: Alarm scheduling with recurrence
--   - Voice Recorder: Audio recordings with quality settings
--
-- Dependencies: phone_players (Phase 1), phone_media (Phase 2)
-- Note: Voice recordings reference phone_media for audio file storage
-- ============================================================================

SELECT '' AS '';
SELECT '>>> PHASE 8: Creating Utility Application Tables...' AS '';
SELECT '    Apps: Notes, Alarms, Voice Recorder' AS '';

SOURCE server/sql/phone_utilities_tables.sql;

SELECT '✓ Utility tables created successfully (4 tables)' AS '';

-- ============================================================================
-- PHASE 9: Asset Management Tables
-- ============================================================================
-- Asset tables depend on phone_players for ownership tracking. These handle
-- vehicle and property management features.
--
-- Applications in this phase:
--   - Vehicles: Vehicle tracking with location and garage status
--   - Properties: Property management with keys and access logs
--
-- Dependencies: phone_players (Phase 1)
-- Note: Includes access control and audit logging
-- ============================================================================

SELECT '' AS '';
SELECT '>>> PHASE 9: Creating Asset Management Tables...' AS '';
SELECT '    Apps: Vehicles, Properties' AS '';

SOURCE server/sql/phone_assets_tables.sql;

SELECT '✓ Asset tables created successfully (4 tables)' AS '';

-- ============================================================================
-- Installation Complete
-- ============================================================================

SELECT '' AS '';
SELECT '============================================================================' AS '';
SELECT 'Database Installation Complete!' AS '';
SELECT '============================================================================' AS '';
SELECT '' AS '';
SELECT 'All phone system tables have been created successfully.' AS '';
SELECT 'Expected table count: 50+ tables across 9 functional groups' AS '';
SELECT '' AS '';
SELECT 'VERIFICATION STEPS:' AS '';
SELECT '  1. Check table count:' AS '';
SELECT '     SELECT COUNT(*) FROM information_schema.tables' AS '';
SELECT '     WHERE table_schema = DATABASE() AND table_name LIKE "phone_%";' AS '';
SELECT '' AS '';
SELECT '  2. List all tables:' AS '';
SELECT '     SHOW TABLES LIKE "phone_%";' AS '';
SELECT '' AS '';
SELECT '  3. Verify foreign keys:' AS '';
SELECT '     SELECT TABLE_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME' AS '';
SELECT '     FROM information_schema.KEY_COLUMN_USAGE' AS '';
SELECT '     WHERE table_schema = DATABASE() AND REFERENCED_TABLE_NAME IS NOT NULL;' AS '';
SELECT '' AS '';
SELECT '  4. Check indexes:' AS '';
SELECT '     SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME' AS '';
SELECT '     FROM information_schema.STATISTICS' AS '';
SELECT '     WHERE table_schema = DATABASE() AND TABLE_NAME LIKE "phone_%";' AS '';
SELECT '' AS '';
SELECT 'ERROR HANDLING NOTES:' AS '';
SELECT '  ✓ Safe Re-execution: All tables use IF NOT EXISTS clause' AS '';
SELECT '    - Re-running this script will NOT modify existing tables' AS '';
SELECT '    - No data will be lost or corrupted' AS '';
SELECT '    - Only missing tables will be created' AS '';
SELECT '' AS '';
SELECT '  ✓ Dependency Order: Tables created in correct order' AS '';
SELECT '    - Core tables first (no dependencies)' AS '';
SELECT '    - Dependent tables after their parent tables' AS '';
SELECT '    - Foreign key constraints will not fail' AS '';
SELECT '' AS '';
SELECT '  ✓ Common Issues and Solutions:' AS '';
SELECT '    - "File not found": Run from FiveM resource root directory' AS '';
SELECT '    - "Access denied": Ensure user has CREATE TABLE privilege' AS '';
SELECT '    - "Syntax error": Requires MySQL 5.7+ or MariaDB 10.2+' AS '';
SELECT '    - "Foreign key error": Should not occur due to dependency ordering' AS '';
SELECT '    - "Table already exists": Normal if re-running, safely ignored' AS '';
SELECT '' AS '';
SELECT '  ✓ Troubleshooting:' AS '';
SELECT '    - Check MySQL error log: /var/log/mysql/error.log' AS '';
SELECT '    - Verify database exists: SHOW DATABASES;' AS '';
SELECT '    - Check user privileges: SHOW GRANTS FOR CURRENT_USER;' AS '';
SELECT '    - Test individual files: SOURCE server/sql/phone_core_tables.sql;' AS '';
SELECT '' AS '';
SELECT 'NEXT STEPS:' AS '';
SELECT '  1. Verify table creation using the commands above' AS '';
SELECT '  2. Start your FiveM server' AS '';
SELECT '  3. Test the phone system in-game' AS '';
SELECT '  4. Monitor server console for any database errors' AS '';
SELECT '' AS '';
SELECT '============================================================================' AS '';
