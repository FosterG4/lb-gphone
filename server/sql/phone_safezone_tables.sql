-- ============================================================================
-- SafeZone App Database Tables
-- ============================================================================
-- Description: Tables for the SafeZone app, which provides emergency services,
--              panic alerts, emergency contacts, and quick-dial emergency calls
-- Dependencies: phone_players (for foreign key relationships)
-- Created: 2024
-- ============================================================================

-- ============================================================================
-- Table: phone_safezone_contacts
-- ============================================================================
-- Description: Emergency contacts configured by users for the SafeZone app.
--              These contacts are notified when a user triggers an emergency.
-- Relationships: 
--   - phone_number references phone_players(phone_number) with CASCADE delete
-- Contact Notification Logic:
--   - When emergency is triggered, all contacts for that user are notified
--   - is_primary flag indicates the primary emergency contact (first to notify)
--   - Multiple contacts can be configured for redundancy
--   - Contacts receive location and emergency type information
-- Use Cases:
--   - Family members to notify in emergencies
--   - Friends or colleagues for workplace safety
--   - Personal security contacts
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_safezone_contacts (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique contact identifier',
    phone_number VARCHAR(20) NOT NULL COMMENT 'Owner phone number',
    contact_name VARCHAR(100) NOT NULL COMMENT 'Name of emergency contact',
    contact_phone VARCHAR(20) NOT NULL COMMENT 'Phone number of emergency contact',
    relationship VARCHAR(50) COMMENT 'Relationship to owner (e.g., spouse, parent, friend)',
    is_primary BOOLEAN DEFAULT FALSE COMMENT 'Whether this is the primary emergency contact',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When contact was added',
    
    -- Indexes for performance
    INDEX idx_owner (phone_number) COMMENT 'Quick lookup of contacts by owner',
    INDEX idx_primary (is_primary) COMMENT 'Quick access to primary contacts',
    
    -- Foreign key relationships
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='SafeZone emergency contacts for notifications';

-- ============================================================================
-- Table: phone_safezone_settings
-- ============================================================================
-- Description: User preferences and settings for the SafeZone app. Controls
--              alert behavior, location sharing, police notifications, and
--              emergency timeout duration.
-- Relationships:
--   - phone_number references phone_players(phone_number) with CASCADE delete
-- Settings:
--   - auto_alerts: Automatically send alerts when emergency is triggered
--   - location_sharing: Share location with emergency contacts
--   - police_alerts: Automatically notify police/emergency services
--   - silent_mode: Trigger emergency without sound/vibration
--   - emergency_timeout: Seconds before emergency auto-resolves (default 30)
-- Emergency Timeout Logic:
--   - emergency_timeout defines how long an emergency stays active
--   - After timeout, emergency status changes from 'active' to 'resolved'
--   - Timeout prevents stale emergency records
--   - User can manually resolve before timeout
--   - Typical values: 30-300 seconds (30 seconds to 5 minutes)
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_safezone_settings (
    phone_number VARCHAR(20) PRIMARY KEY COMMENT 'User phone number (unique)',
    auto_alerts BOOLEAN DEFAULT TRUE COMMENT 'Automatically send alerts to contacts',
    location_sharing BOOLEAN DEFAULT TRUE COMMENT 'Share location during emergencies',
    police_alerts BOOLEAN DEFAULT TRUE COMMENT 'Automatically notify police/emergency services',
    silent_mode BOOLEAN DEFAULT FALSE COMMENT 'Trigger emergency silently without alerts',
    emergency_timeout INT DEFAULT 30 COMMENT 'Seconds before emergency auto-resolves',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When settings were created',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last settings update',
    
    -- Foreign key relationships
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='SafeZone app user settings and preferences';

-- ============================================================================
-- Table: phone_safezone_emergencies
-- ============================================================================
-- Description: Records of emergency events triggered by users. Tracks emergency
--              type, location, status, and notification history.
-- Relationships:
--   - phone_number references phone_players(phone_number) with CASCADE delete
-- Emergency Type Documentation:
--   - panic: General panic button activation
--   - medical: Medical emergency requiring immediate assistance
--   - fire: Fire emergency
--   - police: Police assistance needed
--   - other: Custom or unspecified emergency type
-- Emergency Status Documentation:
--   - active: Emergency is currently ongoing and requires attention
--   - resolved: Emergency has been resolved (manually or by responders)
--   - cancelled: User cancelled the emergency (false alarm)
-- Contact Notification Logic:
--   - contacts_notified stores JSON array or comma-separated list of notified contacts
--   - Tracks which emergency contacts received notifications
--   - Used to prevent duplicate notifications
--   - Helps with emergency response audit trail
-- Emergency Timeout and Expiration Logic:
--   - Active emergencies should be monitored for timeout
--   - After emergency_timeout seconds (from settings), status changes to 'resolved'
--   - resolved_at timestamp records when emergency ended
--   - Expired emergencies can be archived or cleaned up
-- Location Tracking:
--   - location_x and location_y capture user's position when emergency triggered
--   - Location shared with emergency contacts and responders
--   - Critical for emergency response coordination
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_safezone_emergencies (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique emergency identifier',
    phone_number VARCHAR(20) NOT NULL COMMENT 'Phone number of person in emergency',
    emergency_type ENUM('panic', 'medical', 'fire', 'police', 'other') NOT NULL COMMENT 'Type of emergency',
    location_x FLOAT COMMENT 'X coordinate where emergency was triggered',
    location_y FLOAT COMMENT 'Y coordinate where emergency was triggered',
    status ENUM('active', 'resolved', 'cancelled') DEFAULT 'active' COMMENT 'Current emergency status',
    contacts_notified TEXT COMMENT 'List of contacts that were notified (JSON or CSV)',
    police_notified BOOLEAN DEFAULT FALSE COMMENT 'Whether police/emergency services were notified',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When emergency was triggered',
    resolved_at TIMESTAMP NULL COMMENT 'When emergency was resolved or cancelled',
    
    -- Indexes for performance
    INDEX idx_owner (phone_number) COMMENT 'Quick lookup of emergencies by user',
    INDEX idx_status (status) COMMENT 'Filter active emergencies for monitoring',
    INDEX idx_created (created_at DESC) COMMENT 'Sort emergencies by recency',
    
    -- Foreign key relationships
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='SafeZone emergency event records';

-- ============================================================================
-- Table: phone_safezone_calls
-- ============================================================================
-- Description: Log of emergency calls made through the SafeZone app. Tracks
--              calls to 911, police, fire, medical services, and quick-dial.
-- Relationships:
--   - phone_number references phone_players(phone_number) with CASCADE delete
-- Call Type Documentation:
--   - 911: Emergency services call (general)
--   - police: Direct call to police department
--   - fire: Direct call to fire department
--   - medical: Direct call to medical/ambulance services
--   - quick_dial: Quick dial to pre-configured emergency contact
-- Call Status:
--   - completed: Call was successfully completed
--   - missed: Call was not answered
--   - declined: Call was declined by recipient
-- Use Cases:
--   - Audit trail of emergency calls
--   - Track response times and call completion
--   - Identify patterns in emergency service usage
--   - Compliance and legal documentation
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_safezone_calls (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique call identifier',
    phone_number VARCHAR(20) NOT NULL COMMENT 'Phone number of caller',
    call_type ENUM('911', 'police', 'fire', 'medical', 'quick_dial') NOT NULL COMMENT 'Type of emergency call',
    target_number VARCHAR(20) COMMENT 'Phone number called (for quick_dial)',
    duration INT DEFAULT 0 COMMENT 'Call duration in seconds',
    status ENUM('completed', 'missed', 'declined') DEFAULT 'completed' COMMENT 'Call completion status',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When call was initiated',
    
    -- Indexes for performance
    INDEX idx_owner (phone_number) COMMENT 'Quick lookup of calls by user',
    INDEX idx_type (call_type) COMMENT 'Filter calls by emergency type',
    INDEX idx_created (created_at DESC) COMMENT 'Sort calls by recency',
    
    -- Foreign key relationships
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='SafeZone emergency call log';

-- ============================================================================
-- Common Queries for SafeZone Tables
-- ============================================================================
-- Get all emergency contacts for a user:
--   SELECT * FROM phone_safezone_contacts WHERE phone_number = ? ORDER BY is_primary DESC, contact_name;
--
-- Get primary emergency contact:
--   SELECT * FROM phone_safezone_contacts WHERE phone_number = ? AND is_primary = TRUE LIMIT 1;
--
-- Get active emergencies:
--   SELECT * FROM phone_safezone_emergencies WHERE status = 'active' ORDER BY created_at DESC;
--
-- Get user's emergency history:
--   SELECT * FROM phone_safezone_emergencies WHERE phone_number = ? ORDER BY created_at DESC;
--
-- Get active emergencies that need timeout check:
--   SELECT e.*, s.emergency_timeout 
--   FROM phone_safezone_emergencies e
--   JOIN phone_safezone_settings s ON e.phone_number = s.phone_number
--   WHERE e.status = 'active' 
--   AND TIMESTAMPDIFF(SECOND, e.created_at, NOW()) > s.emergency_timeout;
--
-- Resolve emergency:
--   UPDATE phone_safezone_emergencies 
--   SET status = 'resolved', resolved_at = NOW() 
--   WHERE id = ?;
--
-- Get recent emergency calls:
--   SELECT * FROM phone_safezone_calls 
--   WHERE phone_number = ? 
--   ORDER BY created_at DESC 
--   LIMIT 10;
--
-- Get emergency statistics by type:
--   SELECT emergency_type, COUNT(*) as count, 
--          AVG(TIMESTAMPDIFF(SECOND, created_at, resolved_at)) as avg_duration
--   FROM phone_safezone_emergencies 
--   WHERE phone_number = ? AND resolved_at IS NOT NULL
--   GROUP BY emergency_type;
-- ============================================================================
