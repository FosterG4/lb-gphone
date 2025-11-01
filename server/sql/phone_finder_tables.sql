-- ============================================================================
-- Finder App Database Tables
-- ============================================================================
-- Description: Tables for the Finder app, which provides device tracking,
--              location management, and location sharing features
-- Dependencies: phone_players (for foreign key relationships)
-- Created: 2024
-- ============================================================================

-- ============================================================================
-- Table: phone_finder_devices
-- ============================================================================
-- Description: Stores tracked devices for the Finder app, including phones,
--              vehicles, and other trackable items. Tracks device location,
--              online status, and lost mode state.
-- Relationships: 
--   - phone_number references phone_players(phone_number) with CASCADE delete
-- Coordinate Format: 
--   - last_location_x and last_location_y store game world coordinates as FLOAT
--   - Coordinates are updated when device location changes
-- Lost Mode Logic:
--   - is_lost flag indicates if device is in lost mode
--   - When lost mode is enabled, device can trigger alerts and notifications
--   - Lost devices can be tracked more frequently
-- Device Tracking:
--   - last_seen timestamp automatically updates when device location changes
--   - is_online indicates if device is currently active/connected
--   - device_id links to actual game entity or identifier
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_finder_devices (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique device identifier',
    phone_number VARCHAR(20) NOT NULL COMMENT 'Owner phone number',
    device_name VARCHAR(100) NOT NULL COMMENT 'User-friendly device name',
    device_type ENUM('phone', 'vehicle', 'other') NOT NULL COMMENT 'Type of tracked device',
    device_id VARCHAR(50) NOT NULL COMMENT 'Game entity or system identifier',
    last_location_x FLOAT COMMENT 'Last known X coordinate in game world',
    last_location_y FLOAT COMMENT 'Last known Y coordinate in game world',
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Last time device was seen/updated',
    is_lost BOOLEAN DEFAULT FALSE COMMENT 'Whether device is marked as lost',
    is_online BOOLEAN DEFAULT TRUE COMMENT 'Whether device is currently online/active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When device was added to Finder',
    
    -- Indexes for performance
    INDEX idx_owner (phone_number) COMMENT 'Quick lookup of devices by owner',
    INDEX idx_device (device_id) COMMENT 'Quick lookup by device identifier',
    INDEX idx_lost (is_lost) COMMENT 'Filter lost devices for alerts',
    INDEX idx_online (is_online) COMMENT 'Filter online devices for tracking',
    
    -- Foreign key relationships
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Finder app tracked devices with location and status';

-- ============================================================================
-- Table: phone_finder_settings
-- ============================================================================
-- Description: User preferences and settings for the Finder app. Controls
--              location services, refresh behavior, alerts, and privacy.
-- Relationships:
--   - phone_number references phone_players(phone_number) with CASCADE delete
-- Settings:
--   - location_services: Master toggle for location tracking
--   - auto_refresh: Automatically refresh device locations
--   - sound_alerts: Play sound when device status changes
--   - privacy_mode: Hide location from certain features
--   - data_retention_days: How long to keep location history (default 30 days)
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_finder_settings (
    phone_number VARCHAR(20) PRIMARY KEY COMMENT 'User phone number (unique)',
    location_services BOOLEAN DEFAULT TRUE COMMENT 'Enable/disable location tracking',
    auto_refresh BOOLEAN DEFAULT TRUE COMMENT 'Automatically refresh device locations',
    sound_alerts BOOLEAN DEFAULT TRUE COMMENT 'Play sound alerts for device events',
    privacy_mode BOOLEAN DEFAULT FALSE COMMENT 'Enhanced privacy mode',
    data_retention_days INT DEFAULT 30 COMMENT 'Days to retain location history',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When settings were created',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last settings update',
    
    -- Foreign key relationships
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Finder app user settings and preferences';

-- ============================================================================
-- Table: phone_location_pins
-- ============================================================================
-- Description: Saved location pins/markers created by users. Allows users to
--              save important locations with custom labels for quick reference.
-- Relationships:
--   - owner_number references phone_players(phone_number) with CASCADE delete
-- Coordinate Format:
--   - location_x and location_y store game world coordinates as FLOAT
--   - Coordinates are required (NOT NULL) when creating a pin
-- Use Cases:
--   - Save home, work, or favorite locations
--   - Mark meeting points or important places
--   - Quick navigation to saved locations
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_location_pins (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique pin identifier',
    owner_number VARCHAR(20) NOT NULL COMMENT 'Phone number of pin creator',
    label VARCHAR(100) NOT NULL COMMENT 'User-defined label for the location',
    location_x FLOAT NOT NULL COMMENT 'X coordinate in game world',
    location_y FLOAT NOT NULL COMMENT 'Y coordinate in game world',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When pin was created',
    
    -- Indexes for performance
    INDEX idx_owner (owner_number) COMMENT 'Quick lookup of pins by owner',
    
    -- Foreign key relationships
    FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='User-created location pins and markers';

-- ============================================================================
-- Table: phone_shared_locations
-- ============================================================================
-- Description: Temporary location sharing between users. Allows users to share
--              their current location with others for a limited time period.
-- Relationships:
--   - sharer_number references phone_players(phone_number) with CASCADE delete
--   - receiver_number references phone_players(phone_number) with CASCADE delete
-- Coordinate Format:
--   - location_x and location_y store game world coordinates as FLOAT
--   - Coordinates represent the location at time of sharing
-- Location Sharing Expiration Logic:
--   - expires_at timestamp defines when sharing automatically ends
--   - Expired shares should be cleaned up periodically
--   - Receivers can only view location until expiration
--   - Sharer can manually revoke sharing by deleting the record
-- Privacy:
--   - Only the specified receiver can view the shared location
--   - Location is a snapshot at time of sharing (not live tracking)
--   - Optional message can provide context for the shared location
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_shared_locations (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique share identifier',
    sharer_number VARCHAR(20) NOT NULL COMMENT 'Phone number of person sharing location',
    receiver_number VARCHAR(20) NOT NULL COMMENT 'Phone number of person receiving location',
    location_x FLOAT NOT NULL COMMENT 'Shared X coordinate in game world',
    location_y FLOAT NOT NULL COMMENT 'Shared Y coordinate in game world',
    message TEXT COMMENT 'Optional message accompanying the shared location',
    expires_at TIMESTAMP NOT NULL COMMENT 'When location sharing expires',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When location was shared',
    
    -- Indexes for performance
    INDEX idx_receiver (receiver_number) COMMENT 'Quick lookup of received locations',
    INDEX idx_expires (expires_at) COMMENT 'Efficient cleanup of expired shares',
    
    -- Foreign key relationships
    FOREIGN KEY (sharer_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (receiver_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Temporary location sharing between users';

-- ============================================================================
-- Common Queries for Finder Tables
-- ============================================================================
-- Get all devices for a user:
--   SELECT * FROM phone_finder_devices WHERE phone_number = ? ORDER BY device_name;
--
-- Get lost devices:
--   SELECT * FROM phone_finder_devices WHERE phone_number = ? AND is_lost = TRUE;
--
-- Get online devices:
--   SELECT * FROM phone_finder_devices WHERE phone_number = ? AND is_online = TRUE;
--
-- Get user's location pins:
--   SELECT * FROM phone_location_pins WHERE owner_number = ? ORDER BY created_at DESC;
--
-- Get active shared locations for a receiver:
--   SELECT * FROM phone_shared_locations 
--   WHERE receiver_number = ? AND expires_at > NOW() 
--   ORDER BY created_at DESC;
--
-- Cleanup expired location shares:
--   DELETE FROM phone_shared_locations WHERE expires_at < NOW();
--
-- Update device location:
--   UPDATE phone_finder_devices 
--   SET last_location_x = ?, last_location_y = ?, last_seen = NOW() 
--   WHERE id = ?;
-- ============================================================================
