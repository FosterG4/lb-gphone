-- Database Module for FiveM Smartphone System
-- Handles database initialization, table creation, and CRUD operations

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

-- Create all required database tables
function Database.CreateTables()
    print('^3[PHONE] Creating database tables...^0')
    
    -- Table 1: phone_players
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
    
    -- Table 5b: phone_chirp_likes (for tracking who liked which chirps)
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
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_settings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            phone_number VARCHAR(20) UNIQUE NOT NULL,
            theme VARCHAR(50) DEFAULT 'default',
            notification_enabled BOOLEAN DEFAULT TRUE,
            sound_enabled BOOLEAN DEFAULT TRUE,
            volume INT DEFAULT 50,
            settings_json TEXT,
            FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 9: phone_media
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
    
    -- Table 17: phone_shotz_posts
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
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_flicker_matches (
            player1_number VARCHAR(20) NOT NULL,
            player2_number VARCHAR(20) NOT NULL,
            matched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (player1_number, player2_number),
            FOREIGN KEY (player1_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
            FOREIGN KEY (player2_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 24: phone_marketplace_listings
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
    MySQL:execute([[
        CREATE TABLE IF NOT EXISTS phone_business_pages (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            business_name VARCHAR(200) NOT NULL,
            description TEXT,
            category VARCHAR(50),
            contact_number VARCHAR(20),
            location_x FLOAT,
            location_y FLOAT,
            photos_json TEXT,
            services_json TEXT,
            followers INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            INDEX idx_category (category),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {})
    
    -- Table 26: phone_cryptox_holdings
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
