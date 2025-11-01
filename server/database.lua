-- ============================================================================
-- Database Module for FiveM Smartphone System
-- ============================================================================
-- Handles database initialization, table creation, and CRUD operations
--
-- SQL FILE ORGANIZATION:
-- All database table schemas are also available as organized SQL files in
-- the server/sql/ directory for manual installation and reference.
--
-- SQL Files Available:
--   - server/sql/install_all_tables.sql       (Master installation script)
--   - server/sql/phone_core_tables.sql        (Core system tables)
--   - server/sql/phone_media_tables.sql       (Media storage tables)
--   - server/sql/phone_wallet_tables.sql      (Wallet/banking tables)
--   - server/sql/phone_cryptox_tables.sql     (Crypto trading tables)
--   - server/sql/phone_musicly_tables.sql     (Music app tables)
--   - server/sql/phone_finder_tables.sql      (Finder/GPS tables)
--   - server/sql/phone_safezone_tables.sql    (Emergency/safety tables)
--   - server/sql/phone_marketplace_tables.sql (Marketplace tables)
--   - server/sql/phone_business_tables.sql    (Business pages tables)
--   - server/sql/phone_utilities_tables.sql   (Notes, alarms, voice recorder)
--   - server/sql/phone_assets_tables.sql      (Vehicles and properties)
--   - And more... (see server/sql/ directory)
--
-- MANUAL SQL INSTALLATION:
-- If automatic table creation fails or you prefer manual installation:
--   1. Connect to MySQL: mysql -u username -p database_name
--   2. Execute master script: SOURCE server/sql/install_all_tables.sql;
--   OR execute individual files as needed
--
-- BACKWARD COMPATIBILITY:
-- This Lua-based table creation is maintained for backward compatibility
-- and automatic setup. The SQL files contain the same table definitions
-- with additional documentation and comments.
--
-- For detailed SQL documentation, see: server/sql/ directory
-- For installation guide, see: INSTALL.md (SQL File Organization section)
-- ============================================================================

local Database = {}
local MySQL = nil
local isConnected = false
local queryCache = {}

-- Initialize database connection
function Database.Initialize()
    -- Get MySQL resource
    MySQL = exports[Config.DatabaseResource]
    
    if not MySQL then
        print('^1[PHONE] ERROR: Database resource "' .. Config.DatabaseResource .. '" not found!^0')
        return false
    end
    
    print('^2[PHONE] Database resource loaded successfully^0')
    
    -- Perform health check
    local healthCheck = Database.HealthCheck()
    if not healthCheck then
        print('^1[PHONE] ERROR: Database health check failed!^0')
        return false
    end
    
    print('^2[PHONE] Database connection healthy^0')
    
    -- Create tables if configured
    if Config.CreateTablesOnStart then
        Database.CreateTables()
    end
    
    isConnected = true
    return true
end

-- Database health check
function Database.HealthCheck()
    local success = false
    
    MySQL:execute('SELECT 1', {}, function(result)
        if result then
            success = true
        end
    end)
    
    -- Wait for callback (simple synchronous check)
    local timeout = 0
    while success == false and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    return success
end

-- ============================================================================
-- Create all required database tables
-- ============================================================================
-- This function creates all phone system tables programmatically.
--
-- ALTERNATIVE: SQL Files
-- All these table definitions are also available as organized SQL files
-- in the server/sql/ directory. You can use those files for:
--   - Manual database setup
--   - Database documentation and reference
--   - Version control and schema management
--   - Easier review and maintenance
--
-- To use SQL files instead:
--   1. Set Config.CreateTablesOnStart = false (to skip automatic creation)
--   2. Execute: mysql -u user -p database < server/sql/install_all_tables.sql
--
-- SQL File Reference:
--   - phone_core_tables.sql: Contains phone_players, phone_contacts, 
--     phone_messages, phone_call_history, phone_settings
--   - phone_media_tables.sql: Contains phone_media, phone_albums, 
--     phone_album_media
--   - phone_wallet_tables.sql: Contains phone_bankr_* and phone_bank_* tables
--   - phone_cryptox_tables.sql: Contains phone_cryptox_* and phone_crypto tables
--   - phone_utilities_tables.sql: Contains phone_notes, phone_alarms, 
--     phone_voice_* tables
--   - phone_assets_tables.sql: Contains phone_vehicles, phone_properties, 
--     phone_property_keys, phone_access_logs
--   - And more... (see server/sql/ directory for complete list)
--
-- For detailed documentation on each table, see the corresponding SQL file.
-- ============================================================================
function Database.CreateTables()
    print('^3[PHONE] Creating database tables...^0')
    print('^3[PHONE] Note: SQL files are available in server/sql/ for manual installation^0')
    
    -- Table 1: phone_players
    -- SQL File: server/sql/phone_core_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_players (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(50) UNIQUE NOT NULL,
            phone_number VARCHAR(20) UNIQUE NOT NULL,
            installed_apps TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_identifier (identifier),
            INDEX idx_phone_number (phone_number)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 2: phone_contacts
    -- SQL File: server/sql/phone_core_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_contacts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            contact_name VARCHAR(100) NOT NULL,
            contact_number VARCHAR(20) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 3: phone_messages
    -- SQL File: server/sql/phone_core_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_messages (
            id INT AUTO_INCREMENT PRIMARY KEY,
            sender_number VARCHAR(20) NOT NULL,
            receiver_number VARCHAR(20) NOT NULL,
            message TEXT NOT NULL,
            is_read BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_conversation (sender_number, receiver_number),
            INDEX idx_receiver (receiver_number, is_read)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 4: phone_call_history
    -- SQL File: server/sql/phone_core_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_call_history (
            id INT AUTO_INCREMENT PRIMARY KEY,
            caller_number VARCHAR(20) NOT NULL,
            receiver_number VARCHAR(20) NOT NULL,
            duration INT DEFAULT 0,
            call_type ENUM('incoming', 'outgoing', 'missed') NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_caller (caller_number),
            INDEX idx_receiver (receiver_number)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 5: phone_chirps
    -- SQL File: server/sql/phone_chirper_tables.sql (legacy table)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_chirps (
            id INT AUTO_INCREMENT PRIMARY KEY,
            author_number VARCHAR(20) NOT NULL,
            author_name VARCHAR(100) NOT NULL,
            content VARCHAR(280) NOT NULL,
            likes INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_created (created_at DESC)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Wait for phone_chirps table to be created before creating dependent table
    Wait(100)
    
    -- Table 5b: phone_chirp_likes (for tracking who liked which chirps)
    -- SQL File: server/sql/phone_chirper_tables.sql
    -- Note: This table depends on phone_chirps existing first
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_chirp_likes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            phone_number VARCHAR(20) NOT NULL,
            chirp_id INT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_like (phone_number, chirp_id),
            INDEX idx_phone (phone_number),
            INDEX idx_chirp (chirp_id),
            FOREIGN KEY (chirp_id) REFERENCES phone_chirps(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 6: phone_crypto
    -- SQL File: server/sql/phone_cryptox_tables.sql (legacy table)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_crypto (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            crypto_type VARCHAR(20) NOT NULL,
            amount DECIMAL(20, 8) NOT NULL,
            INDEX idx_owner (owner_number),
            UNIQUE KEY unique_holding (owner_number, crypto_type)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 7: phone_bank_transactions
    -- SQL File: server/sql/phone_wallet_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_bank_transactions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            sender_number VARCHAR(20) NOT NULL,
            receiver_number VARCHAR(20) NOT NULL,
            amount DECIMAL(10, 2) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_sender (sender_number),
            INDEX idx_receiver (receiver_number),
            INDEX idx_created (created_at DESC)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 8: phone_settings
    -- SQL File: server/sql/phone_core_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_settings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            phone_number VARCHAR(20) UNIQUE NOT NULL,
            theme VARCHAR(50) DEFAULT 'default',
            notification_enabled BOOLEAN DEFAULT TRUE,
            sound_enabled BOOLEAN DEFAULT TRUE,
            volume INT DEFAULT 50,
            locale VARCHAR(10) DEFAULT 'en',
            settings_json TEXT,
            FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 9: phone_media
    -- SQL File: server/sql/phone_media_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_media (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            media_type ENUM('photo', 'video', 'audio') NOT NULL,
            file_url VARCHAR(500) NOT NULL,
            thumbnail_url VARCHAR(500),
            duration INT DEFAULT 0,
            file_size INT DEFAULT 0,
            location_x FLOAT,
            location_y FLOAT,
            metadata_json TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            INDEX idx_type (media_type),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 10: phone_albums
    -- SQL File: server/sql/phone_media_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_albums (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            album_name VARCHAR(100) NOT NULL,
            cover_media_id INT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
            FOREIGN KEY (cover_media_id) REFERENCES phone_media(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 11: phone_album_media
    -- SQL File: server/sql/phone_media_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_album_media (
            album_id INT NOT NULL,
            media_id INT NOT NULL,
            added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (album_id, media_id),
            FOREIGN KEY (album_id) REFERENCES phone_albums(id) ON DELETE CASCADE,
            FOREIGN KEY (media_id) REFERENCES phone_media(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 12: phone_notes
    -- SQL File: server/sql/phone_utilities_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_notes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            title VARCHAR(200),
            content TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 13: phone_alarms
    -- SQL File: server/sql/phone_utilities_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_alarms (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            alarm_time TIME NOT NULL,
            alarm_days VARCHAR(50),
            label VARCHAR(100),
            enabled BOOLEAN DEFAULT TRUE,
            sound VARCHAR(100),
            INDEX idx_owner (owner_number),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 14: phone_vehicles
    -- SQL File: server/sql/phone_assets_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_vehicles (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            plate VARCHAR(20) UNIQUE NOT NULL,
            model VARCHAR(50) NOT NULL,
            location_x FLOAT,
            location_y FLOAT,
            location_z FLOAT,
            garage VARCHAR(100),
            status ENUM('out', 'stored', 'impounded') DEFAULT 'stored',
            INDEX idx_owner (owner_number),
            INDEX idx_plate (plate),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 15: phone_properties
    -- SQL File: server/sql/phone_assets_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_properties (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            property_id VARCHAR(50) NOT NULL,
            property_name VARCHAR(100),
            location_x FLOAT,
            location_y FLOAT,
            locked BOOLEAN DEFAULT TRUE,
            INDEX idx_owner (owner_number),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 16: phone_property_keys
    -- SQL File: server/sql/phone_assets_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_property_keys (
            id INT AUTO_INCREMENT PRIMARY KEY,
            property_id INT NOT NULL,
            holder_number VARCHAR(20) NOT NULL,
            granted_by VARCHAR(20) NOT NULL,
            granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP NULL,
            INDEX idx_holder (holder_number),
            FOREIGN KEY (property_id) REFERENCES phone_properties(id) ON DELETE CASCADE,
            FOREIGN KEY (holder_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 16a: phone_access_logs
    -- SQL File: server/sql/phone_assets_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_access_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            property_id INT NOT NULL,
            user_number VARCHAR(20) NOT NULL,
            action VARCHAR(50) NOT NULL,
            target_number VARCHAR(20),
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_property (property_id),
            INDEX idx_timestamp (timestamp DESC),
            FOREIGN KEY (property_id) REFERENCES phone_properties(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 17: phone_shotz_posts
    -- SQL File: server/sql/phone_shotz_additional_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_shotz_posts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            author_number VARCHAR(20) NOT NULL,
            author_name VARCHAR(100) NOT NULL,
            caption TEXT,
            media_id INT NOT NULL,
            likes INT DEFAULT 0,
            comments INT DEFAULT 0,
            shares INT DEFAULT 0,
            is_live BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_author (author_number),
            INDEX idx_created (created_at DESC),
            FOREIGN KEY (author_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
            FOREIGN KEY (media_id) REFERENCES phone_media(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 18: phone_shotz_followers
    -- SQL File: server/sql/phone_shotz_additional_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_shotz_followers (
            follower_number VARCHAR(20) NOT NULL,
            following_number VARCHAR(20) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (follower_number, following_number),
            FOREIGN KEY (follower_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
            FOREIGN KEY (following_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 19: phone_chirper_posts
    -- SQL File: server/sql/phone_chirper_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_chirper_posts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            author_number VARCHAR(20) NOT NULL,
            author_name VARCHAR(100) NOT NULL,
            content VARCHAR(280) NOT NULL,
            likes INT DEFAULT 0,
            reposts INT DEFAULT 0,
            replies INT DEFAULT 0,
            parent_id INT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_author (author_number),
            INDEX idx_created (created_at DESC),
            INDEX idx_parent (parent_id),
            FOREIGN KEY (author_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
            FOREIGN KEY (parent_id) REFERENCES phone_chirper_posts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 20: phone_modish_videos
    -- SQL File: server/sql/phone_modish_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_modish_videos (
            id INT AUTO_INCREMENT PRIMARY KEY,
            author_number VARCHAR(20) NOT NULL,
            author_name VARCHAR(100) NOT NULL,
            media_id INT NOT NULL,
            caption TEXT,
            music_track VARCHAR(200),
            filters_json TEXT,
            likes INT DEFAULT 0,
            views INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_author (author_number),
            INDEX idx_created (created_at DESC),
            FOREIGN KEY (author_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
            FOREIGN KEY (media_id) REFERENCES phone_media(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 21: phone_flicker_profiles
    -- SQL File: server/sql/phone_flicker_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_flicker_profiles (
            phone_number VARCHAR(20) PRIMARY KEY,
            display_name VARCHAR(100) NOT NULL,
            bio TEXT,
            age INT,
            photos_json TEXT,
            preferences_json TEXT,
            active BOOLEAN DEFAULT TRUE,
            FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 22: phone_flicker_swipes
    -- SQL File: server/sql/phone_flicker_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_flicker_swipes (
            swiper_number VARCHAR(20) NOT NULL,
            swiped_number VARCHAR(20) NOT NULL,
            swipe_type ENUM('like', 'pass') NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (swiper_number, swiped_number),
            FOREIGN KEY (swiper_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
            FOREIGN KEY (swiped_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 23: phone_flicker_matches
    -- SQL File: server/sql/phone_flicker_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_flicker_matches (
            player1_number VARCHAR(20) NOT NULL,
            player2_number VARCHAR(20) NOT NULL,
            matched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_message_at TIMESTAMP NULL,
            unmatched BOOLEAN DEFAULT FALSE,
            unmatched_by VARCHAR(20) NULL,
            unmatched_at TIMESTAMP NULL,
            PRIMARY KEY (player1_number, player2_number),
            INDEX idx_player1 (player1_number),
            INDEX idx_player2 (player2_number),
            INDEX idx_matched (matched_at DESC),
            INDEX idx_unmatched (unmatched),
            FOREIGN KEY (player1_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
            FOREIGN KEY (player2_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 23a: phone_flicker_messages
    -- SQL File: server/sql/phone_flicker_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_flicker_messages (
            id INT AUTO_INCREMENT PRIMARY KEY,
            sender_number VARCHAR(20) NOT NULL,
            receiver_number VARCHAR(20) NOT NULL,
            content TEXT NOT NULL,
            read_status BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_sender (sender_number),
            INDEX idx_receiver (receiver_number),
            INDEX idx_conversation (sender_number, receiver_number, created_at),
            INDEX idx_created (created_at DESC),
            INDEX idx_read (read_status),
            FOREIGN KEY (sender_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
            FOREIGN KEY (receiver_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 23b: phone_flicker_blocks
    -- SQL File: server/sql/phone_flicker_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_flicker_blocks (
            blocker_number VARCHAR(20) NOT NULL,
            blocked_number VARCHAR(20) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (blocker_number, blocked_number),
            INDEX idx_blocker (blocker_number),
            INDEX idx_blocked (blocked_number),
            FOREIGN KEY (blocker_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
            FOREIGN KEY (blocked_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 23c: phone_flicker_reports
    -- SQL File: server/sql/phone_flicker_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_flicker_reports (
            id INT AUTO_INCREMENT PRIMARY KEY,
            reporter_number VARCHAR(20) NOT NULL,
            reported_number VARCHAR(20) NOT NULL,
            reason VARCHAR(255) NOT NULL,
            details TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_reporter (reporter_number),
            INDEX idx_reported (reported_number),
            INDEX idx_created (created_at DESC),
            FOREIGN KEY (reporter_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
            FOREIGN KEY (reported_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 24: phone_marketplace_listings
    -- SQL File: server/sql/phone_marketplace_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_marketplace_listings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            seller_number VARCHAR(20) NOT NULL,
            title VARCHAR(200) NOT NULL,
            description TEXT,
            price DECIMAL(10, 2) NOT NULL,
            category VARCHAR(50),
            photos_json TEXT,
            status ENUM('active', 'sold', 'deleted') DEFAULT 'active',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_seller (seller_number),
            INDEX idx_category (category),
            INDEX idx_status (status),
            FOREIGN KEY (seller_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 25: phone_business_pages
    -- SQL File: server/sql/phone_business_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_business_pages (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            name VARCHAR(200) NOT NULL,
            description TEXT,
            category VARCHAR(50),
            contact_number VARCHAR(20),
            location_x FLOAT,
            location_y FLOAT,
            photos TEXT,
            services TEXT,
            followers_count INT DEFAULT 0,
            rating DECIMAL(3,2) DEFAULT 0.00,
            reviews_count INT DEFAULT 0,
            status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            INDEX idx_category (category),
            INDEX idx_status (status),
            INDEX idx_rating (rating),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 25a: phone_page_followers (Business page followers)
    -- SQL File: server/sql/phone_business_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_page_followers (
            id INT AUTO_INCREMENT PRIMARY KEY,
            page_id INT NOT NULL,
            follower_number VARCHAR(20) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_page (page_id),
            INDEX idx_follower (follower_number),
            UNIQUE KEY unique_follow (page_id, follower_number),
            FOREIGN KEY (page_id) REFERENCES phone_business_pages(id) ON DELETE CASCADE,
            FOREIGN KEY (follower_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 25b: phone_page_reviews (Business page reviews)
    -- SQL File: server/sql/phone_business_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_page_reviews (
            id INT AUTO_INCREMENT PRIMARY KEY,
            page_id INT NOT NULL,
            reviewer_number VARCHAR(20) NOT NULL,
            rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
            review_text TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_page (page_id),
            INDEX idx_reviewer (reviewer_number),
            INDEX idx_rating (rating),
            INDEX idx_created (created_at DESC),
            UNIQUE KEY unique_review (page_id, reviewer_number),
            FOREIGN KEY (page_id) REFERENCES phone_business_pages(id) ON DELETE CASCADE,
            FOREIGN KEY (reviewer_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 25c: phone_page_views (Business page view tracking)
    -- SQL File: server/sql/phone_business_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_page_views (
            id INT AUTO_INCREMENT PRIMARY KEY,
            page_id INT NOT NULL,
            viewer_number VARCHAR(20) NOT NULL,
            viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_page (page_id),
            INDEX idx_viewer (viewer_number),
            INDEX idx_viewed (viewed_at DESC),
            FOREIGN KEY (page_id) REFERENCES phone_business_pages(id) ON DELETE CASCADE,
            FOREIGN KEY (viewer_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 24a: phone_marketplace_transactions (Marketplace transactions)
    -- SQL File: server/sql/phone_marketplace_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_marketplace_transactions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            listing_id INT NOT NULL,
            buyer_number VARCHAR(20) NOT NULL,
            seller_number VARCHAR(20) NOT NULL,
            amount DECIMAL(15, 2) NOT NULL,
            status ENUM('pending', 'completed', 'cancelled', 'disputed') DEFAULT 'pending',
            payment_method VARCHAR(50) DEFAULT 'cash',
            transaction_fee DECIMAL(15, 2) DEFAULT 0,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            completed_at TIMESTAMP NULL,
            INDEX idx_listing (listing_id),
            INDEX idx_buyer (buyer_number),
            INDEX idx_seller (seller_number),
            INDEX idx_status (status),
            INDEX idx_created (created_at DESC),
            FOREIGN KEY (listing_id) REFERENCES phone_marketplace_listings(id) ON DELETE CASCADE,
            FOREIGN KEY (buyer_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
            FOREIGN KEY (seller_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 24b: phone_marketplace_reviews (Marketplace reviews)
    -- SQL File: server/sql/phone_marketplace_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_marketplace_reviews (
            id INT AUTO_INCREMENT PRIMARY KEY,
            transaction_id INT NOT NULL,
            reviewer_number VARCHAR(20) NOT NULL,
            reviewed_number VARCHAR(20) NOT NULL,
            rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
            review_text TEXT,
            review_type ENUM('buyer', 'seller') NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_transaction (transaction_id),
            INDEX idx_reviewer (reviewer_number),
            INDEX idx_reviewed (reviewed_number),
            INDEX idx_rating (rating),
            INDEX idx_type (review_type),
            INDEX idx_created (created_at DESC),
            UNIQUE KEY unique_review (transaction_id, reviewer_number),
            FOREIGN KEY (transaction_id) REFERENCES phone_marketplace_transactions(id) ON DELETE CASCADE,
            FOREIGN KEY (reviewer_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
            FOREIGN KEY (reviewed_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 24c: phone_marketplace_favorites (Marketplace favorites)
    -- SQL File: server/sql/phone_marketplace_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_marketplace_favorites (
            id INT AUTO_INCREMENT PRIMARY KEY,
            listing_id INT NOT NULL,
            user_number VARCHAR(20) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_listing (listing_id),
            INDEX idx_user (user_number),
            INDEX idx_created (created_at DESC),
            UNIQUE KEY unique_favorite (listing_id, user_number),
            FOREIGN KEY (listing_id) REFERENCES phone_marketplace_listings(id) ON DELETE CASCADE,
            FOREIGN KEY (user_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 26: phone_cryptox_holdings
    -- SQL File: server/sql/phone_cryptox_tables.sql
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_cryptox_holdings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            crypto_symbol VARCHAR(20) NOT NULL,
            amount DECIMAL(20, 8) NOT NULL,
            avg_buy_price DECIMAL(20, 2),
            INDEX idx_owner (owner_number),
            UNIQUE KEY unique_holding (owner_number, crypto_symbol),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 27: phone_cryptox_transactions
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_cryptox_transactions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            crypto_symbol VARCHAR(20) NOT NULL,
            transaction_type ENUM('buy', 'sell') NOT NULL,
            amount DECIMAL(20, 8) NOT NULL,
            price DECIMAL(20, 2) NOT NULL,
            total DECIMAL(20, 2) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            INDEX idx_created (created_at DESC),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 28: phone_musicly_playlists
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_musicly_playlists (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            playlist_name VARCHAR(200) NOT NULL,
            tracks_json TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 29: phone_finder_devices
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_finder_devices (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            device_type ENUM('phone', 'vehicle', 'other') NOT NULL,
            device_name VARCHAR(100) NOT NULL,
            device_id VARCHAR(100),
            last_location_x FLOAT,
            last_location_y FLOAT,
            last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 30: phone_location_pins
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_location_pins (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            label VARCHAR(100) NOT NULL,
            location_x FLOAT NOT NULL,
            location_y FLOAT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 31: phone_shared_locations
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_shared_locations (
            id INT AUTO_INCREMENT PRIMARY KEY,
            sharer_number VARCHAR(20) NOT NULL,
            receiver_number VARCHAR(20) NOT NULL,
            location_x FLOAT NOT NULL,
            location_y FLOAT NOT NULL,
            message TEXT,
            expires_at TIMESTAMP NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_receiver (receiver_number),
            INDEX idx_expires (expires_at),
            FOREIGN KEY (sharer_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
            FOREIGN KEY (receiver_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Enhanced Finance Apps Tables
    
    -- Table 32: phone_bankr_transactions (Enhanced banking transactions)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_bankr_transactions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            account_id VARCHAR(50) NOT NULL,
            transaction_type ENUM('credit', 'debit') NOT NULL,
            amount DECIMAL(15, 2) NOT NULL,
            description VARCHAR(255),
            category VARCHAR(50) DEFAULT 'general',
            recipient_number VARCHAR(20),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            INDEX idx_account (account_id),
            INDEX idx_type (transaction_type),
            INDEX idx_category (category),
            INDEX idx_created (created_at DESC),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 33: phone_bankr_budgets (Budget tracking)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_bankr_budgets (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            category VARCHAR(50) NOT NULL,
            monthly_limit DECIMAL(15, 2) NOT NULL,
            current_spent DECIMAL(15, 2) DEFAULT 0,
            period_start DATE NOT NULL,
            period_end DATE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            INDEX idx_category (category),
            INDEX idx_period (period_start, period_end),
            UNIQUE KEY unique_budget (owner_number, category, period_start),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 34: phone_bankr_recurring (Recurring payments)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_bankr_recurring (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            name VARCHAR(100) NOT NULL,
            amount DECIMAL(15, 2) NOT NULL,
            frequency ENUM('weekly', 'monthly', 'quarterly') NOT NULL,
            recipient_number VARCHAR(20) NOT NULL,
            next_payment TIMESTAMP NOT NULL,
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            INDEX idx_next_payment (next_payment),
            INDEX idx_active (is_active),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 35: phone_cryptox_holdings (Enhanced crypto holdings)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_cryptox_holdings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            crypto_symbol VARCHAR(20) NOT NULL,
            amount DECIMAL(20, 8) NOT NULL,
            avg_buy_price DECIMAL(20, 2) NOT NULL,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            INDEX idx_symbol (crypto_symbol),
            UNIQUE KEY unique_holding (owner_number, crypto_symbol),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 36: phone_cryptox_transactions (Enhanced crypto transactions)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_cryptox_transactions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            crypto_symbol VARCHAR(20) NOT NULL,
            transaction_type ENUM('buy', 'sell') NOT NULL,
            amount DECIMAL(20, 8) NOT NULL,
            price_per_unit DECIMAL(20, 2) NOT NULL,
            total_value DECIMAL(20, 2) NOT NULL,
            order_type ENUM('market', 'limit') DEFAULT 'market',
            fee DECIMAL(20, 2) DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            INDEX idx_symbol (crypto_symbol),
            INDEX idx_type (transaction_type),
            INDEX idx_created (created_at DESC),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 37: phone_cryptox_alerts (Price alerts)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_cryptox_alerts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            crypto_symbol VARCHAR(20) NOT NULL,
            alert_type ENUM('above', 'below') NOT NULL,
            target_price DECIMAL(20, 2) NOT NULL,
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            INDEX idx_symbol (crypto_symbol),
            INDEX idx_active (is_active),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Phase 13 Tables: Entertainment & Safety Apps
    
    -- Table 38: phone_musicly_playlists (Musicly playlists)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_musicly_playlists (
            id INT AUTO_INCREMENT PRIMARY KEY,
            phone_number VARCHAR(20) NOT NULL,
            name VARCHAR(100) NOT NULL,
            description TEXT,
            is_public BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_owner (phone_number),
            INDEX idx_public (is_public),
            FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 39: phone_musicly_playlist_tracks (Musicly playlist tracks)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_musicly_playlist_tracks (
            id INT AUTO_INCREMENT PRIMARY KEY,
            playlist_id INT NOT NULL,
            track_id VARCHAR(50) NOT NULL,
            track_title VARCHAR(200) NOT NULL,
            track_artist VARCHAR(200) NOT NULL,
            track_duration INT NOT NULL,
            added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_playlist (playlist_id),
            INDEX idx_track (track_id),
            FOREIGN KEY (playlist_id) REFERENCES phone_musicly_playlists(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 40: phone_musicly_play_history (Musicly play history)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_musicly_play_history (
            id INT AUTO_INCREMENT PRIMARY KEY,
            phone_number VARCHAR(20) NOT NULL,
            track_id VARCHAR(50) NOT NULL,
            track_title VARCHAR(200) NOT NULL,
            track_artist VARCHAR(200) NOT NULL,
            play_duration INT DEFAULT 0,
            played_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (phone_number),
            INDEX idx_track (track_id),
            INDEX idx_played (played_at DESC),
            FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 41: phone_finder_devices (Finder tracked devices)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_finder_devices (
            id INT AUTO_INCREMENT PRIMARY KEY,
            phone_number VARCHAR(20) NOT NULL,
            device_name VARCHAR(100) NOT NULL,
            device_type ENUM('phone', 'vehicle', 'other') NOT NULL,
            device_id VARCHAR(50) NOT NULL,
            last_location_x FLOAT,
            last_location_y FLOAT,
            last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            is_lost BOOLEAN DEFAULT FALSE,
            is_online BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (phone_number),
            INDEX idx_device (device_id),
            INDEX idx_lost (is_lost),
            INDEX idx_online (is_online),
            FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 42: phone_finder_settings (Finder user settings)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_finder_settings (
            phone_number VARCHAR(20) PRIMARY KEY,
            location_services BOOLEAN DEFAULT TRUE,
            auto_refresh BOOLEAN DEFAULT TRUE,
            sound_alerts BOOLEAN DEFAULT TRUE,
            privacy_mode BOOLEAN DEFAULT FALSE,
            data_retention_days INT DEFAULT 30,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 43: phone_safezone_contacts (SafeZone emergency contacts)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_safezone_contacts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            phone_number VARCHAR(20) NOT NULL,
            contact_name VARCHAR(100) NOT NULL,
            contact_phone VARCHAR(20) NOT NULL,
            relationship VARCHAR(50),
            is_primary BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (phone_number),
            INDEX idx_primary (is_primary),
            FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 44: phone_safezone_settings (SafeZone user settings)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_safezone_settings (
            phone_number VARCHAR(20) PRIMARY KEY,
            auto_alerts BOOLEAN DEFAULT TRUE,
            location_sharing BOOLEAN DEFAULT TRUE,
            police_alerts BOOLEAN DEFAULT TRUE,
            silent_mode BOOLEAN DEFAULT FALSE,
            emergency_timeout INT DEFAULT 30,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 45: phone_safezone_emergencies (SafeZone emergency records)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_safezone_emergencies (
            id INT AUTO_INCREMENT PRIMARY KEY,
            phone_number VARCHAR(20) NOT NULL,
            emergency_type ENUM('panic', 'medical', 'fire', 'police', 'other') NOT NULL,
            location_x FLOAT,
            location_y FLOAT,
            status ENUM('active', 'resolved', 'cancelled') DEFAULT 'active',
            contacts_notified TEXT,
            police_notified BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            resolved_at TIMESTAMP NULL,
            INDEX idx_owner (phone_number),
            INDEX idx_status (status),
            INDEX idx_created (created_at DESC),
            FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 46: phone_safezone_calls (SafeZone emergency calls)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_safezone_calls (
            id INT AUTO_INCREMENT PRIMARY KEY,
            phone_number VARCHAR(20) NOT NULL,
            call_type ENUM('911', 'police', 'fire', 'medical', 'quick_dial') NOT NULL,
            target_number VARCHAR(20),
            duration INT DEFAULT 0,
            status ENUM('completed', 'missed', 'declined') DEFAULT 'completed',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (phone_number),
            INDEX idx_type (call_type),
            INDEX idx_created (created_at DESC),
            FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 47: phone_voice_recordings (Voice Recorder recordings)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_voice_recordings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            phone_number VARCHAR(20) NOT NULL,
            name VARCHAR(100) NOT NULL,
            duration INT NOT NULL,
            file_size INT NOT NULL,
            quality ENUM('low', 'medium', 'high', 'ultra') DEFAULT 'medium',
            file_path VARCHAR(500) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (phone_number),
            INDEX idx_created (created_at DESC),
            INDEX idx_quality (quality),
            FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 48: phone_voice_recorder_settings (Voice Recorder user settings)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_voice_recorder_settings (
            phone_number VARCHAR(20) PRIMARY KEY,
            auto_save BOOLEAN DEFAULT TRUE,
            background_recording BOOLEAN DEFAULT FALSE,
            max_recording_length INT DEFAULT 600,
            auto_cleanup BOOLEAN DEFAULT TRUE,
            recording_quality ENUM('low', 'medium', 'high', 'ultra') DEFAULT 'medium',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 49: phone_shotz_post_media (Multiple media attachments per Shotz post)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_shotz_post_media (
            id INT AUTO_INCREMENT PRIMARY KEY,
            post_id INT NOT NULL,
            media_id INT NOT NULL,
            display_order INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_post (post_id),
            INDEX idx_media (media_id),
            UNIQUE KEY unique_post_media (post_id, media_id),
            FOREIGN KEY (post_id) REFERENCES phone_shotz_posts(id) ON DELETE CASCADE,
            FOREIGN KEY (media_id) REFERENCES phone_media(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 50: phone_modish_video_media (Multiple media attachments per Modish video post)
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_modish_video_media (
            id INT AUTO_INCREMENT PRIMARY KEY,
            video_id INT NOT NULL,
            media_id INT NOT NULL,
            display_order INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_video (video_id),
            INDEX idx_media (media_id),
            UNIQUE KEY unique_video_media (video_id, media_id),
            FOREIGN KEY (video_id) REFERENCES phone_modish_videos(id) ON DELETE CASCADE,
            FOREIGN KEY (media_id) REFERENCES phone_media(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Contact Sharing Tables
    -- Table: phone_share_requests
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_share_requests (
            id VARCHAR(36) PRIMARY KEY,
            sender_number VARCHAR(20) NOT NULL,
            sender_name VARCHAR(100) NOT NULL,
            receiver_number VARCHAR(20) NOT NULL,
            receiver_name VARCHAR(100) NOT NULL,
            status ENUM('pending', 'accepted', 'declined', 'expired') DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP NOT NULL,
            responded_at TIMESTAMP NULL,
            INDEX idx_sender (sender_number),
            INDEX idx_receiver (receiver_number),
            INDEX idx_status (status),
            INDEX idx_expires (expires_at),
            FOREIGN KEY (sender_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
            FOREIGN KEY (receiver_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    print('^2[PHONE] Database tables created successfully^0')
end

-- Prepared statement wrappers for common CRUD operations

-- INSERT operations
function Database.Insert(table, data, cb)
    if not isConnected then
        print('^1[PHONE] Database not connected^0')
        if cb then cb(false) end
        return
    end
    
    local columns = {}
    local values = {}
    local params = {}
    
    for column, value in pairs(data) do
        table.insert(columns, column)
        table.insert(values, '?')
        table.insert(params, value)
    end
    
    local query = string.format(
        'INSERT INTO %s (%s) VALUES (%s)',
        table,
        table.concat(columns, ', '),
        table.concat(values, ', ')
    )
    
    MySQL:insert(query, params, function(result)
        if cb then
            cb(result and result > 0, result)
        end
    end)
end

-- SELECT operations
function Database.FetchAll(table, where, params, cb)
    if not isConnected then
        print('^1[PHONE] Database not connected^0')
        if cb then cb(nil) end
        return
    end
    
    local query = 'SELECT * FROM ' .. table
    
    if where then
        query = query .. ' WHERE ' .. where
    end
    
    -- Check cache
    local cacheKey = query .. table.concat(params or {}, '_')
    if queryCache[cacheKey] and (GetGameTimer() - queryCache[cacheKey].time) < Config.DatabaseCacheTime then
        if cb then cb(queryCache[cacheKey].data) end
        return
    end
    
    MySQL:query(query, params or {}, function(result)
        if result then
            -- Cache result
            queryCache[cacheKey] = {
                data = result,
                time = GetGameTimer()
            }
        end
        if cb then cb(result) end
    end)
end

-- SELECT single row
function Database.FetchOne(table, where, params, cb)
    if not isConnected then
        print('^1[PHONE] Database not connected^0')
        if cb then cb(nil) end
        return
    end
    
    local query = 'SELECT * FROM ' .. table
    
    if where then
        query = query .. ' WHERE ' .. where
    end
    
    query = query .. ' LIMIT 1'
    
    MySQL:single(query, params or {}, function(result)
        if cb then cb(result) end
    end)
end

-- UPDATE operations
function Database.Update(table, data, where, whereParams, cb)
    if not isConnected then
        print('^1[PHONE] Database not connected^0')
        if cb then cb(false) end
        return
    end
    
    local sets = {}
    local params = {}
    
    for column, value in pairs(data) do
        table.insert(sets, column .. ' = ?')
        table.insert(params, value)
    end
    
    -- Add where parameters
    if whereParams then
        for _, param in ipairs(whereParams) do
            table.insert(params, param)
        end
    end
    
    local query = string.format(
        'UPDATE %s SET %s WHERE %s',
        table,
        table.concat(sets, ', '),
        where
    )
    
    MySQL:update(query, params, function(affectedRows)
        -- Clear cache for this table
        Database.ClearCache(table)
        if cb then cb(affectedRows > 0, affectedRows) end
    end)
end

-- DELETE operations
function Database.Delete(table, where, params, cb)
    if not isConnected then
        print('^1[PHONE] Database not connected^0')
        if cb then cb(false) end
        return
    end
    
    local query = 'DELETE FROM ' .. table .. ' WHERE ' .. where
    
    MySQL:execute(query, params or {}, function(affectedRows)
        -- Clear cache for this table
        Database.ClearCache(table)
        if cb then cb(affectedRows > 0, affectedRows) end
    end)
end

-- Execute custom query
function Database.Execute(query, params, cb)
    if not isConnected then
        print('^1[PHONE] Database not connected^0')
        if cb then cb(nil) end
        return
    end
    
    MySQL:execute(query, params or {}, function(result)
        if cb then cb(result) end
    end)
end

-- Query with custom SELECT
function Database.Query(query, params, cb)
    if not isConnected then
        print('^1[PHONE] Database not connected^0')
        if cb then cb(nil) end
        return
    end
    
    MySQL:query(query, params or {}, function(result)
        if cb then cb(result) end
    end)
end

-- Clear cache for specific table or all cache
function Database.ClearCache(table)
    if table then
        for key in pairs(queryCache) do
            if string.find(key, table) then
                queryCache[key] = nil
            end
        end
    else
        queryCache = {}
    end
end

-- Check if database is connected
function Database.IsConnected()
    return isConnected
end

-- Specific helper functions for phone system

-- Get or create player phone number
function Database.GetOrCreatePlayer(identifier, cb)
    if not identifier then
        print('^1[PHONE] GetOrCreatePlayer: identifier is nil^0')
        if cb then cb(nil) end
        return
    end
    
    Database.FetchOne('phone_players', 'identifier = ?', {identifier}, function(player)
        if player then
            if cb then cb(player.phone_number) end
        else
            -- Generate new phone number
            Database.GenerateUniquePhoneNumber(function(phoneNumber)
                if not phoneNumber then
                    print('^1[PHONE] Failed to generate unique phone number^0')
                    if cb then cb(nil) end
                    return
                end
                
                Database.Insert('phone_players', {
                    identifier = identifier,
                    phone_number = phoneNumber
                }, function(success)
                    if success then
                        print('^2[PHONE] Created new phone number ' .. phoneNumber .. ' for identifier ' .. identifier .. '^0')
                        if cb then cb(phoneNumber) end
                    else
                        print('^1[PHONE] Failed to insert player phone number into database^0')
                        if cb then cb(nil) end
                    end
                end)
            end)
        end
    end)
end

-- Generate unique phone number (checks database for duplicates)
function Database.GenerateUniquePhoneNumber(cb, attempts)
    attempts = attempts or 0
    
    if attempts >= 10 then
        print('^1[PHONE] Failed to generate unique phone number after 10 attempts^0')
        if cb then cb(nil) end
        return
    end
    
    -- Use utility function to generate phone number
    local phoneNumber = GeneratePhoneNumber()
    
    -- Check if phone number already exists
    Database.FetchOne('phone_players', 'phone_number = ?', {phoneNumber}, function(existing)
        if existing then
            -- Phone number exists, try again
            Database.GenerateUniquePhoneNumber(cb, attempts + 1)
        else
            -- Phone number is unique
            if cb then cb(phoneNumber) end
        end
    end)
end

-- Get player by phone number
function Database.GetPlayerByPhone(phoneNumber, cb)
    if not phoneNumber then
        if cb then cb(nil) end
        return
    end
    
    Database.FetchOne('phone_players', 'phone_number = ?', {phoneNumber}, function(player)
        if cb then cb(player) end
    end)
end

-- Get player by identifier
function Database.GetPlayerByIdentifier(identifier, cb)
    if not identifier then
        if cb then cb(nil) end
        return
    end
    
    Database.FetchOne('phone_players', 'identifier = ?', {identifier}, function(player)
        if cb then cb(player) end
    end)
end

-- Update player phone number
function Database.UpdatePlayerPhoneNumber(identifier, newPhoneNumber, cb)
    if not identifier or not newPhoneNumber then
        if cb then cb(false) end
        return
    end
    
    -- Validate phone number format
    local isValid, error = ValidatePhoneNumber(newPhoneNumber)
    if not isValid then
        print('^1[PHONE] Invalid phone number format: ' .. error .. '^0')
        if cb then cb(false) end
        return
    end
    
    Database.Update('phone_players', {
        phone_number = newPhoneNumber
    }, 'identifier = ?', {identifier}, function(success)
        if success then
            print('^2[PHONE] Updated phone number for identifier ' .. identifier .. '^0')
        end
        if cb then cb(success) end
    end)
end

-- Check if phone number exists
function Database.PhoneNumberExists(phoneNumber, cb)
    if not phoneNumber then
        if cb then cb(false) end
        return
    end
    
    Database.FetchOne('phone_players', 'phone_number = ?', {phoneNumber}, function(player)
        if cb then cb(player ~= nil) end
    end)
end

-- Get contacts for player
function Database.GetContacts(phoneNumber, cb)
    Database.FetchAll('phone_contacts', 'owner_number = ?', {phoneNumber}, function(contacts)
        if cb then cb(contacts or {}) end
    end)
end

-- Get messages for conversation
function Database.GetMessages(phoneNumber1, phoneNumber2, cb)
    local query = [[
        SELECT * FROM phone_messages 
        WHERE (sender_number = ? AND receiver_number = ?) 
           OR (sender_number = ? AND receiver_number = ?)
        ORDER BY created_at ASC
    ]]
    
    Database.Query(query, {phoneNumber1, phoneNumber2, phoneNumber2, phoneNumber1}, function(messages)
        if cb then cb(messages or {}) end
    end)
end

-- Get call history for player
function Database.GetCallHistory(phoneNumber, cb)
    local query = [[
        SELECT * FROM phone_call_history 
        WHERE caller_number = ? OR receiver_number = ?
        ORDER BY created_at DESC
        LIMIT 50
    ]]
    
    Database.Query(query, {phoneNumber, phoneNumber}, function(history)
        if cb then cb(history or {}) end
    end)
end

-- Get chirper feed
function Database.GetChirperFeed(limit, cb)
    local query = 'SELECT * FROM phone_chirps ORDER BY created_at DESC LIMIT ?'
    
    Database.Query(query, {limit or 50}, function(chirps)
        if cb then cb(chirps or {}) end
    end)
end

-- Get crypto holdings for player
function Database.GetCryptoHoldings(phoneNumber, cb)
    Database.FetchAll('phone_crypto', 'owner_number = ?', {phoneNumber}, function(holdings)
        if cb then cb(holdings or {}) end
    end)
end

-- Helper functions for new tables

-- Settings
function Database.GetSettings(phoneNumber, cb)
    Database.FetchOne('phone_settings', 'phone_number = ?', {phoneNumber}, function(settings)
        if cb then cb(settings) end
    end)
end

function Database.UpdateSettings(phoneNumber, settings, cb)
    Database.FetchOne('phone_settings', 'phone_number = ?', {phoneNumber}, function(existing)
        if existing then
            Database.Update('phone_settings', settings, 'phone_number = ?', {phoneNumber}, cb)
        else
            settings.phone_number = phoneNumber
            Database.Insert('phone_settings', settings, cb)
        end
    end)
end

-- Media
function Database.GetMedia(phoneNumber, mediaType, cb)
    local where = 'owner_number = ?'
    local params = {phoneNumber}
    
    if mediaType then
        where = where .. ' AND media_type = ?'
        table.insert(params, mediaType)
    end
    
    where = where .. ' ORDER BY created_at DESC'
    
    Database.Query('SELECT * FROM phone_media WHERE ' .. where, params, function(media)
        if cb then cb(media or {}) end
    end)
end

function Database.GetMediaById(mediaId, cb)
    Database.FetchOne('phone_media', 'id = ?', {mediaId}, function(media)
        if cb then cb(media) end
    end)
end

-- Albums
function Database.GetAlbums(phoneNumber, cb)
    Database.FetchAll('phone_albums', 'owner_number = ?', {phoneNumber}, function(albums)
        if cb then cb(albums or {}) end
    end)
end

function Database.GetAlbumMedia(albumId, cb)
    local query = [[
        SELECT m.* FROM phone_media m
        INNER JOIN phone_album_media am ON m.id = am.media_id
        WHERE am.album_id = ?
        ORDER BY am.added_at DESC
    ]]
    
    Database.Query(query, {albumId}, function(media)
        if cb then cb(media or {}) end
    end)
end

-- Notes
function Database.GetNotes(phoneNumber, cb)
    Database.FetchAll('phone_notes', 'owner_number = ? ORDER BY updated_at DESC', {phoneNumber}, function(notes)
        if cb then cb(notes or {}) end
    end)
end

-- Alarms
function Database.GetAlarms(phoneNumber, cb)
    Database.FetchAll('phone_alarms', 'owner_number = ? AND enabled = TRUE', {phoneNumber}, function(alarms)
        if cb then cb(alarms or {}) end
    end)
end

-- Vehicles
function Database.GetVehicles(phoneNumber, cb)
    Database.FetchAll('phone_vehicles', 'owner_number = ?', {phoneNumber}, function(vehicles)
        if cb then cb(vehicles or {}) end
    end)
end

function Database.GetVehicleByPlate(plate, cb)
    Database.FetchOne('phone_vehicles', 'plate = ?', {plate}, function(vehicle)
        if cb then cb(vehicle) end
    end)
end

function Database.UpdateVehicleLocation(plate, x, y, z, cb)
    Database.Update('phone_vehicles', {
        location_x = x,
        location_y = y,
        location_z = z
    }, 'plate = ?', {plate}, cb)
end

-- Properties
function Database.GetProperties(phoneNumber, cb)
    Database.FetchAll('phone_properties', 'owner_number = ?', {phoneNumber}, function(properties)
        if cb then cb(properties or {}) end
    end)
end

function Database.GetPropertyKeys(phoneNumber, cb)
    local query = [[
        SELECT pk.*, p.property_name, p.location_x, p.location_y
        FROM phone_property_keys pk
        INNER JOIN phone_properties p ON pk.property_id = p.id
        WHERE pk.holder_number = ? AND (pk.expires_at IS NULL OR pk.expires_at > NOW())
    ]]
    
    Database.Query(query, {phoneNumber}, function(keys)
        if cb then cb(keys or {}) end
    end)
end

-- Shotz
function Database.GetShotzFeed(limit, offset, cb)
    local query = [[
        SELECT sp.*, m.file_url, m.thumbnail_url, m.media_type
        FROM phone_shotz_posts sp
        INNER JOIN phone_media m ON sp.media_id = m.id
        ORDER BY sp.created_at DESC
        LIMIT ? OFFSET ?
    ]]
    
    Database.Query(query, {limit or 20, offset or 0}, function(posts)
        if cb then cb(posts or {}) end
    end)
end

function Database.GetShotzFollowers(phoneNumber, cb)
    Database.FetchAll('phone_shotz_followers', 'following_number = ?', {phoneNumber}, function(followers)
        if cb then cb(followers or {}) end
    end)
end

function Database.GetShotzFollowing(phoneNumber, cb)
    Database.FetchAll('phone_shotz_followers', 'follower_number = ?', {phoneNumber}, function(following)
        if cb then cb(following or {}) end
    end)
end

-- Chirper
function Database.GetChirperFeed(limit, offset, cb)
    local query = [[
        SELECT * FROM phone_chirper_posts
        WHERE parent_id IS NULL
        ORDER BY created_at DESC
        LIMIT ? OFFSET ?
    ]]
    
    Database.Query(query, {limit or 20, offset or 0}, function(posts)
        if cb then cb(posts or {}) end
    end)
end

function Database.GetChirperReplies(parentId, cb)
    Database.FetchAll('phone_chirper_posts', 'parent_id = ? ORDER BY created_at ASC', {parentId}, function(replies)
        if cb then cb(replies or {}) end
    end)
end

-- Modish
function Database.GetModishFeed(limit, offset, cb)
    local query = [[
        SELECT mv.*, m.file_url, m.thumbnail_url, m.duration
        FROM phone_modish_videos mv
        INNER JOIN phone_media m ON mv.media_id = m.id
        ORDER BY mv.created_at DESC
        LIMIT ? OFFSET ?
    ]]
    
    Database.Query(query, {limit or 20, offset or 0}, function(videos)
        if cb then cb(videos or {}) end
    end)
end

-- Flicker
function Database.GetFlickerProfile(phoneNumber, cb)
    Database.FetchOne('phone_flicker_profiles', 'phone_number = ?', {phoneNumber}, function(profile)
        if cb then cb(profile) end
    end)
end

function Database.GetFlickerMatches(phoneNumber, cb)
    local query = [[
        SELECT * FROM phone_flicker_matches
        WHERE player1_number = ? OR player2_number = ?
        ORDER BY matched_at DESC
    ]]
    
    Database.Query(query, {phoneNumber, phoneNumber}, function(matches)
        if cb then cb(matches or {}) end
    end)
end

function Database.CheckFlickerMatch(phoneNumber1, phoneNumber2, cb)
    local query = [[
        SELECT COUNT(*) as count FROM phone_flicker_swipes
        WHERE (swiper_number = ? AND swiped_number = ? AND swipe_type = 'like')
        AND (swiper_number = ? AND swiped_number = ? AND swipe_type = 'like')
    ]]
    
    Database.Query(query, {phoneNumber1, phoneNumber2, phoneNumber2, phoneNumber1}, function(result)
        if cb then cb(result and result[1] and result[1].count == 2) end
    end)
end

-- Marketplace
function Database.GetMarketplaceListings(category, status, limit, offset, cb)
    local where = 'status = ?'
    local params = {status or 'active'}
    
    if category then
        where = where .. ' AND category = ?'
        table.insert(params, category)
    end
    
    where = where .. ' ORDER BY created_at DESC LIMIT ? OFFSET ?'
    table.insert(params, limit or 20)
    table.insert(params, offset or 0)
    
    Database.Query('SELECT * FROM phone_marketplace_listings WHERE ' .. where, params, function(listings)
        if cb then cb(listings or {}) end
    end)
end

function Database.GetMyListings(phoneNumber, cb)
    Database.FetchAll('phone_marketplace_listings', 'seller_number = ? ORDER BY created_at DESC', {phoneNumber}, function(listings)
        if cb then cb(listings or {}) end
    end)
end

-- Business Pages
function Database.GetBusinessPages(category, limit, offset, cb)
    local where = '1=1'
    local params = {}
    
    if category then
        where = where .. ' AND category = ?'
        table.insert(params, category)
    end
    
    where = where .. ' ORDER BY created_at DESC LIMIT ? OFFSET ?'
    table.insert(params, limit or 20)
    table.insert(params, offset or 0)
    
    Database.Query('SELECT * FROM phone_business_pages WHERE ' .. where, params, function(pages)
        if cb then cb(pages or {}) end
    end)
end

function Database.GetMyBusinessPages(phoneNumber, cb)
    Database.FetchAll('phone_business_pages', 'owner_number = ?', {phoneNumber}, function(pages)
        if cb then cb(pages or {}) end
    end)
end

-- CryptoX
function Database.GetCryptoXHoldings(phoneNumber, cb)
    Database.FetchAll('phone_cryptox_holdings', 'owner_number = ?', {phoneNumber}, function(holdings)
        if cb then cb(holdings or {}) end
    end)
end

function Database.GetCryptoXTransactions(phoneNumber, limit, cb)
    Database.Query(
        'SELECT * FROM phone_cryptox_transactions WHERE owner_number = ? ORDER BY created_at DESC LIMIT ?',
        {phoneNumber, limit or 50},
        function(transactions)
            if cb then cb(transactions or {}) end
        end
    )
end

function Database.UpdateCryptoXHolding(phoneNumber, cryptoSymbol, amount, avgBuyPrice, cb)
    Database.FetchOne('phone_cryptox_holdings', 'owner_number = ? AND crypto_symbol = ?', {phoneNumber, cryptoSymbol}, function(existing)
        if existing then
            Database.Update('phone_cryptox_holdings', {
                amount = amount,
                avg_buy_price = avgBuyPrice
            }, 'owner_number = ? AND crypto_symbol = ?', {phoneNumber, cryptoSymbol}, cb)
        else
            Database.Insert('phone_cryptox_holdings', {
                owner_number = phoneNumber,
                crypto_symbol = cryptoSymbol,
                amount = amount,
                avg_buy_price = avgBuyPrice
            }, cb)
        end
    end)
end

-- Musicly
function Database.GetPlaylists(phoneNumber, cb)
    Database.FetchAll('phone_musicly_playlists', 'owner_number = ?', {phoneNumber}, function(playlists)
        if cb then cb(playlists or {}) end
    end)
end

-- Finder
function Database.GetFinderDevices(phoneNumber, cb)
    Database.FetchAll('phone_finder_devices', 'owner_number = ?', {phoneNumber}, function(devices)
        if cb then cb(devices or {}) end
    end)
end

function Database.UpdateDeviceLocation(deviceId, x, y, cb)
    Database.Update('phone_finder_devices', {
        last_location_x = x,
        last_location_y = y
    }, 'id = ?', {deviceId}, cb)
end

-- Location Pins
function Database.GetLocationPins(phoneNumber, cb)
    Database.FetchAll('phone_location_pins', 'owner_number = ? ORDER BY created_at DESC', {phoneNumber}, function(pins)
        if cb then cb(pins or {}) end
    end)
end

function Database.GetLocationPinById(pinId, cb)
    Database.FetchOne('phone_location_pins', 'id = ?', {pinId}, function(pin)
        if cb then cb(pin) end
    end)
end

-- Shared Locations
function Database.GetSharedLocations(phoneNumber, cb)
    local query = [[
        SELECT sl.*, pp.phone_number as sharer_name
        FROM phone_shared_locations sl
        LEFT JOIN phone_players pp ON sl.sharer_number = pp.phone_number
        WHERE sl.receiver_number = ? AND sl.expires_at > NOW()
        ORDER BY sl.created_at DESC
    ]]
    
    Database.Query(query, {phoneNumber}, function(locations)
        if cb then cb(locations or {}) end
    end)
end

function Database.CleanupExpiredSharedLocations()
    Database.Execute('DELETE FROM phone_shared_locations WHERE expires_at < NOW()', {}, function()
        -- Cleanup complete
    end)
end

return Database
