-- ============================================================================
-- Property and Vehicle Management Database Tables
-- ============================================================================
-- Description: Tables for managing player-owned vehicles and properties,
--              including property access control and audit logging
-- Dependencies: phone_players (phone_number)
-- Created: 2024
--
-- Tables Included:
--   1. phone_vehicles - Vehicle ownership and tracking
--   2. phone_properties - Property ownership and management
--   3. phone_property_keys - Property access key management
--   4. phone_access_logs - Property access audit trail
--
-- Key Features:
--   - GPS coordinate tracking for vehicles and properties
--   - Vehicle status management (out, stored, impounded)
--   - Property access control with temporary/permanent keys
--   - Comprehensive audit logging for security
--   - Automatic CASCADE deletion for data integrity
--   - Performance-optimized indexes for common queries
-- ============================================================================

-- Table: phone_vehicles
-- Description: Stores information about player-owned vehicles including
--              location tracking, garage storage, and vehicle status
-- Relationships: References phone_players for ownership
-- Location Format: Coordinates stored as FLOAT values in FiveM/GTA V coordinate system
--                  location_x, location_y, location_z represent world position
-- Status Logic: 'out' = in use, 'stored' = in garage, 'impounded' = seized
--               When 'stored', garage field contains garage identifier
--               When 'out' or 'impounded', garage may be NULL
CREATE TABLE IF NOT EXISTS phone_vehicles (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique vehicle record identifier',
    owner_number VARCHAR(20) NOT NULL COMMENT 'Phone number of vehicle owner',
    plate VARCHAR(20) UNIQUE NOT NULL COMMENT 'Unique vehicle license plate',
    model VARCHAR(50) NOT NULL COMMENT 'Vehicle model name',
    location_x FLOAT COMMENT 'X coordinate (longitude) of vehicle location in game world',
    location_y FLOAT COMMENT 'Y coordinate (latitude) of vehicle location in game world',
    location_z FLOAT COMMENT 'Z coordinate (altitude) of vehicle location in game world',
    garage VARCHAR(100) COMMENT 'Name/identifier of garage where vehicle is stored (NULL when not stored)',
    status ENUM('out', 'stored', 'impounded') DEFAULT 'stored' COMMENT 'Vehicle status: out (in use), stored (in garage), impounded (seized)',
    
    -- Indexes for performance optimization
    INDEX idx_owner (owner_number) COMMENT 'Optimizes queries filtering by owner (e.g., "show my vehicles")',
    INDEX idx_plate (plate) COMMENT 'Optimizes queries searching by license plate',
    INDEX idx_status (status) COMMENT 'Optimizes queries filtering by vehicle status',
    
    -- Foreign key relationships with CASCADE delete
    -- When a player is deleted, all their vehicles are automatically removed
    FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Vehicle tracking and management system';

-- Table: phone_properties
-- Description: Stores information about player-owned properties including
--              location coordinates and lock status
-- Relationships: References phone_players for ownership
-- Location Format: Coordinates stored as FLOAT values in FiveM/GTA V coordinate system
--                  location_x, location_y represent property entrance position
--                  Used for GPS navigation and map markers
CREATE TABLE IF NOT EXISTS phone_properties (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique property record identifier',
    owner_number VARCHAR(20) NOT NULL COMMENT 'Phone number of property owner',
    property_id VARCHAR(50) NOT NULL COMMENT 'External property identifier (from property system)',
    property_name VARCHAR(100) COMMENT 'Display name of the property',
    location_x FLOAT COMMENT 'X coordinate (longitude) of property entrance in game world',
    location_y FLOAT COMMENT 'Y coordinate (latitude) of property entrance in game world',
    locked BOOLEAN DEFAULT TRUE COMMENT 'Lock status: TRUE (locked), FALSE (unlocked)',
    
    -- Indexes for performance optimization
    INDEX idx_owner (owner_number) COMMENT 'Optimizes queries filtering by owner (e.g., "show my properties")',
    INDEX idx_property_id (property_id) COMMENT 'Optimizes lookups by external property system ID',
    
    -- Foreign key relationships with CASCADE delete
    -- When a player is deleted, all their properties are automatically removed
    FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Property ownership and management system';

-- Table: phone_property_keys
-- Description: Manages property access keys granted to other players,
--              including temporary keys with expiration dates
-- Relationships: References phone_properties and phone_players
-- Key Expiration Logic: 
--   - Permanent keys: expires_at IS NULL (never expires)
--   - Temporary keys: expires_at contains future timestamp
--   - Expired keys: expires_at < NOW()
--   - Validation query: WHERE expires_at IS NULL OR expires_at > NOW()
-- Access Control: Keys are automatically deleted when property or holder is deleted
CREATE TABLE IF NOT EXISTS phone_property_keys (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique key record identifier',
    property_id INT NOT NULL COMMENT 'Property this key grants access to',
    holder_number VARCHAR(20) NOT NULL COMMENT 'Phone number of key holder',
    granted_by VARCHAR(20) NOT NULL COMMENT 'Phone number of person who granted access',
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When the key was granted',
    expires_at TIMESTAMP NULL COMMENT 'When the key expires (NULL = never expires, past date = expired)',
    
    -- Indexes for performance optimization
    INDEX idx_holder (holder_number) COMMENT 'Optimizes queries for "keys I have" lookups',
    INDEX idx_property (property_id) COMMENT 'Optimizes queries for "who has keys to this property"',
    INDEX idx_expires (expires_at) COMMENT 'Optimizes cleanup queries for expired keys',
    INDEX idx_holder_property (holder_number, property_id) COMMENT 'Optimizes access validation queries',
    
    -- Foreign key relationships with CASCADE delete
    -- When a property is deleted, all keys to that property are automatically removed
    -- When a player is deleted, all keys they hold are automatically removed
    FOREIGN KEY (property_id) REFERENCES phone_properties(id) ON DELETE CASCADE,
    FOREIGN KEY (holder_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Property access key management with expiration support';

-- Table: phone_access_logs
-- Description: Audit log for property access events including lock/unlock
--              actions and key management operations
-- Relationships: References phone_properties
-- Access Logging: Records all property access events for security auditing
--   Action types:
--     - 'unlock': User unlocks property door
--     - 'lock': User locks property door
--     - 'grant_key': Owner grants key to another user (requires target_number)
--     - 'revoke_key': Owner revokes key from user (requires target_number)
--     - 'enter': User enters property
--     - 'exit': User exits property
-- Retention: Logs are automatically deleted when property is deleted (CASCADE)
-- Performance: Indexed for fast queries by property, time range, and user
CREATE TABLE IF NOT EXISTS phone_access_logs (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique log entry identifier',
    property_id INT NOT NULL COMMENT 'Property where action occurred',
    user_number VARCHAR(20) NOT NULL COMMENT 'Phone number of user performing action',
    action VARCHAR(50) NOT NULL COMMENT 'Action performed (unlock, lock, grant_key, revoke_key, enter, exit)',
    target_number VARCHAR(20) COMMENT 'Phone number of target user (for key operations like grant_key, revoke_key)',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When the action occurred (auto-set on insert)',
    
    -- Indexes for performance optimization
    INDEX idx_property (property_id) COMMENT 'Optimizes queries for "show property access history"',
    INDEX idx_timestamp (timestamp DESC) COMMENT 'Optimizes queries for recent events (descending order)',
    INDEX idx_user (user_number) COMMENT 'Optimizes queries for "show user activity"',
    INDEX idx_property_timestamp (property_id, timestamp DESC) COMMENT 'Optimizes property history with time filtering',
    
    -- Foreign key relationships with CASCADE delete
    -- When a property is deleted, all access logs are automatically removed
    FOREIGN KEY (property_id) REFERENCES phone_properties(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Property access audit log for security tracking';

-- ============================================================================
-- Location Coordinate Format Documentation
-- ============================================================================
-- Coordinates are stored as FLOAT values representing in-game positions
-- using the FiveM/GTA V coordinate system:
--
-- Vehicle Coordinates (3D):
--   - location_x: X coordinate (east-west position in game world)
--   - location_y: Y coordinate (north-south position in game world)
--   - location_z: Z coordinate (altitude/height above ground)
--   - All three coordinates are required for accurate vehicle positioning
--   - Used for GPS tracking, map markers, and vehicle retrieval
--
-- Property Coordinates (2D):
--   - location_x: X coordinate (east-west position in game world)
--   - location_y: Y coordinate (north-south position in game world)
--   - Represents the property entrance/door location
--   - Used for GPS navigation, map markers, and proximity detection
--
-- Coordinate Range:
--   - Typical values range from -4000 to +8000 for X and Y
--   - Z values typically range from 0 to 1000
--   - NULL coordinates indicate location is unknown or not tracked
--
-- Usage Examples:
--   - GPS navigation to property or vehicle
--   - Distance calculations for proximity features
--   - Map marker display in phone apps
--   - Blip creation on minimap
-- ============================================================================

-- ============================================================================
-- Vehicle Status and Garage Logic
-- ============================================================================
-- Vehicle status field uses ENUM with three possible values:
--
-- Status: 'stored' (default)
--   - Vehicle is safely stored in a garage
--   - garage field contains the garage name/identifier
--   - location_x/y/z may contain last known position or garage coordinates
--   - Vehicle cannot be spawned until retrieved from garage
--
-- Status: 'out'
--   - Vehicle is currently spawned and in use by the player
--   - garage field should be NULL or empty
--   - location_x/y/z contain current vehicle position (updated periodically)
--   - Vehicle can be driven and interacted with
--
-- Status: 'impounded'
--   - Vehicle has been seized by authorities (police, repo, etc.)
--   - garage field may contain impound lot identifier or be NULL
--   - location_x/y/z contain impound lot coordinates
--   - Vehicle cannot be accessed until released (usually requires payment)
--
-- State Transitions:
--   stored -> out: Player retrieves vehicle from garage
--   out -> stored: Player stores vehicle in garage
--   out -> impounded: Authorities seize vehicle
--   impounded -> stored: Player pays fine and retrieves vehicle
--
-- Garage Field:
--   - Stores garage name/identifier when status is 'stored'
--   - Examples: "Legion Square Garage", "Pillbox Parking", "garage_1"
--   - NULL or empty when vehicle is 'out'
--   - May contain impound lot ID when 'impounded'
-- ============================================================================

-- ============================================================================
-- Property Key Expiration Logic
-- ============================================================================
-- Property keys support both permanent and temporary access control:
--
-- Permanent Keys (expires_at IS NULL):
--   - Never expire, valid indefinitely
--   - Typically granted to trusted individuals (family, roommates)
--   - Can only be revoked manually by property owner
--   - Example: Owner grants permanent key to spouse
--
-- Temporary Keys (expires_at IS NOT NULL):
--   - Expire at specified timestamp
--   - Useful for guests, contractors, temporary access
--   - Automatically become invalid after expiration
--   - Example: Owner grants 24-hour key to delivery person
--
-- Key Validation Query:
--   SELECT * FROM phone_property_keys
--   WHERE holder_number = ? 
--     AND property_id = ?
--     AND (expires_at IS NULL OR expires_at > NOW())
--
-- Expired Key Cleanup:
--   -- Find expired keys
--   SELECT * FROM phone_property_keys
--   WHERE expires_at IS NOT NULL AND expires_at < NOW()
--
--   -- Delete expired keys (optional, can keep for audit trail)
--   DELETE FROM phone_property_keys
--   WHERE expires_at IS NOT NULL AND expires_at < NOW()
--
-- Key Lifecycle:
--   1. Owner grants key (INSERT with granted_at = NOW())
--   2. Key is active (expires_at IS NULL OR expires_at > NOW())
--   3. Key expires (expires_at < NOW()) or is revoked (DELETE)
--   4. Access denied for expired/revoked keys
--
-- Best Practices:
--   - Set reasonable expiration times (hours/days, not years)
--   - Log key grants in phone_access_logs for audit trail
--   - Notify key holder before expiration
--   - Allow owner to extend expiration without revoking
-- ============================================================================

-- ============================================================================
-- Access Logging Best Practices
-- ============================================================================
-- The phone_access_logs table provides a complete audit trail of property
-- access events for security monitoring and dispute resolution.
--
-- Standard Action Types:
--
-- 'unlock' - User unlocks property door
--   - user_number: Person who unlocked
--   - target_number: NULL
--   - Use case: Track who accessed property
--
-- 'lock' - User locks property door
--   - user_number: Person who locked
--   - target_number: NULL
--   - Use case: Verify property was secured
--
-- 'grant_key' - Owner grants access key to another user
--   - user_number: Property owner granting access
--   - target_number: Person receiving key (REQUIRED)
--   - Use case: Track key distribution, audit access grants
--
-- 'revoke_key' - Owner revokes access key from user
--   - user_number: Property owner revoking access
--   - target_number: Person losing key (REQUIRED)
--   - Use case: Track access revocation, security audit
--
-- 'enter' - User enters property
--   - user_number: Person entering
--   - target_number: NULL
--   - Use case: Track occupancy, verify authorized access
--
-- 'exit' - User exits property
--   - user_number: Person exiting
--   - target_number: NULL
--   - Use case: Track occupancy, calculate visit duration
--
-- Query Examples:
--
-- Get recent property activity:
--   SELECT * FROM phone_access_logs
--   WHERE property_id = ?
--   ORDER BY timestamp DESC
--   LIMIT 50
--
-- Get user's access history:
--   SELECT * FROM phone_access_logs
--   WHERE user_number = ?
--   ORDER BY timestamp DESC
--
-- Find who has keys:
--   SELECT DISTINCT target_number, timestamp
--   FROM phone_access_logs
--   WHERE property_id = ? AND action = 'grant_key'
--   AND target_number NOT IN (
--     SELECT target_number FROM phone_access_logs
--     WHERE property_id = ? AND action = 'revoke_key'
--   )
--
-- Calculate visit duration:
--   SELECT 
--     enter.user_number,
--     enter.timestamp as entered_at,
--     exit.timestamp as exited_at,
--     TIMESTAMPDIFF(MINUTE, enter.timestamp, exit.timestamp) as duration_minutes
--   FROM phone_access_logs enter
--   LEFT JOIN phone_access_logs exit 
--     ON enter.user_number = exit.user_number
--     AND enter.property_id = exit.property_id
--     AND exit.action = 'exit'
--     AND exit.timestamp > enter.timestamp
--   WHERE enter.action = 'enter'
--     AND enter.property_id = ?
--
-- Automatic Behaviors:
--   - timestamp is automatically set to NOW() on INSERT
--   - Logs are automatically deleted when property is deleted (CASCADE)
--   - No automatic cleanup (logs retained indefinitely for audit trail)
--
-- Security Considerations:
--   - Logs cannot be modified (no UPDATE operations)
--   - Logs should only be deleted via CASCADE or manual cleanup
--   - Consider archiving old logs (>1 year) to separate table
--   - Protect log access with appropriate permissions
-- ============================================================================

-- ============================================================================
-- Index and Foreign Key Verification
-- ============================================================================
-- This section documents all indexes and foreign keys for verification
-- and performance tuning purposes.
--
-- INDEXES SUMMARY:
--
-- phone_vehicles:
--   - PRIMARY KEY (id) - Auto-increment unique identifier
--   - UNIQUE INDEX (plate) - Ensures no duplicate license plates
--   - INDEX idx_owner (owner_number) - Fast owner lookups
--   - INDEX idx_plate (plate) - Fast plate searches (redundant with UNIQUE)
--   - INDEX idx_status (status) - Fast status filtering
--
-- phone_properties:
--   - PRIMARY KEY (id) - Auto-increment unique identifier
--   - INDEX idx_owner (owner_number) - Fast owner lookups
--   - INDEX idx_property_id (property_id) - Fast external ID lookups
--
-- phone_property_keys:
--   - PRIMARY KEY (id) - Auto-increment unique identifier
--   - INDEX idx_holder (holder_number) - Fast "my keys" queries
--   - INDEX idx_property (property_id) - Fast "who has keys" queries
--   - INDEX idx_expires (expires_at) - Fast expiration checks
--   - INDEX idx_holder_property (holder_number, property_id) - Fast access validation
--
-- phone_access_logs:
--   - PRIMARY KEY (id) - Auto-increment unique identifier
--   - INDEX idx_property (property_id) - Fast property history queries
--   - INDEX idx_timestamp (timestamp DESC) - Fast recent event queries
--   - INDEX idx_user (user_number) - Fast user activity queries
--   - INDEX idx_property_timestamp (property_id, timestamp DESC) - Composite for filtered history
--
-- FOREIGN KEYS SUMMARY:
--
-- phone_vehicles:
--   - FK owner_number -> phone_players(phone_number) ON DELETE CASCADE
--     Purpose: Ensure vehicle owner exists, auto-delete vehicles when player deleted
--
-- phone_properties:
--   - FK owner_number -> phone_players(phone_number) ON DELETE CASCADE
--     Purpose: Ensure property owner exists, auto-delete properties when player deleted
--
-- phone_property_keys:
--   - FK property_id -> phone_properties(id) ON DELETE CASCADE
--     Purpose: Ensure property exists, auto-delete keys when property deleted
--   - FK holder_number -> phone_players(phone_number) ON DELETE CASCADE
--     Purpose: Ensure key holder exists, auto-delete keys when player deleted
--
-- phone_access_logs:
--   - FK property_id -> phone_properties(id) ON DELETE CASCADE
--     Purpose: Ensure property exists, auto-delete logs when property deleted
--
-- CASCADE DELETE BEHAVIOR:
--   When a player is deleted:
--     - All their vehicles are deleted (phone_vehicles)
--     - All their properties are deleted (phone_properties)
--       - All keys to those properties are deleted (phone_property_keys)
--       - All access logs for those properties are deleted (phone_access_logs)
--     - All keys they hold are deleted (phone_property_keys)
--
-- VERIFICATION QUERIES:
--
-- Check all indexes exist:
--   SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME, SEQ_IN_INDEX
--   FROM information_schema.STATISTICS
--   WHERE TABLE_SCHEMA = DATABASE()
--     AND TABLE_NAME IN ('phone_vehicles', 'phone_properties', 
--                        'phone_property_keys', 'phone_access_logs')
--   ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;
--
-- Check all foreign keys exist:
--   SELECT 
--     TABLE_NAME,
--     CONSTRAINT_NAME,
--     COLUMN_NAME,
--     REFERENCED_TABLE_NAME,
--     REFERENCED_COLUMN_NAME
--   FROM information_schema.KEY_COLUMN_USAGE
--   WHERE TABLE_SCHEMA = DATABASE()
--     AND TABLE_NAME IN ('phone_vehicles', 'phone_properties',
--                        'phone_property_keys', 'phone_access_logs')
--     AND REFERENCED_TABLE_NAME IS NOT NULL
--   ORDER BY TABLE_NAME, CONSTRAINT_NAME;
--
-- Check CASCADE delete rules:
--   SELECT 
--     TABLE_NAME,
--     CONSTRAINT_NAME,
--     DELETE_RULE,
--     UPDATE_RULE
--   FROM information_schema.REFERENTIAL_CONSTRAINTS
--   WHERE CONSTRAINT_SCHEMA = DATABASE()
--     AND TABLE_NAME IN ('phone_vehicles', 'phone_properties',
--                        'phone_property_keys', 'phone_access_logs')
--   ORDER BY TABLE_NAME;
-- ============================================================================
