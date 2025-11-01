-- ============================================================================
-- Utility Applications Database Tables
-- ============================================================================
-- Description: Database schema for utility applications including Notes,
--              Alarms, and Voice Recorder apps
-- Dependencies: phone_players (for foreign key relationships)
-- Created: 2025-11-01
-- 
-- FILE STORAGE PATHS:
-- - Voice recordings: /server/media/voice_recordings/{phone_number}/{filename}.ogg
-- - File naming convention: recording_{timestamp}_{id}.ogg
-- - Storage location: Server filesystem, paths stored in database
-- 
-- SIZE LIMITS:
-- - Notes: Content field is TEXT type (max 65,535 bytes / ~65KB)
-- - Voice recordings: No hard database limit, enforced at application layer
--   * Recommended max per recording: 50MB (approximately 6 minutes at ultra quality)
--   * Total storage per user: Managed by application logic and server capacity
-- 
-- ALARM SCHEDULING:
-- - Alarms use TIME field for daily scheduling (HH:MM:SS format)
-- - Recurrence via alarm_days: comma-separated integers 0-6 (0=Sunday, 6=Saturday)
-- - Empty alarm_days = one-time alarm (no recurrence)
-- - Example: "1,3,5" = Monday, Wednesday, Friday
-- - Application layer handles timezone conversion and triggering logic
-- 
-- VOICE RECORDING QUALITY:
-- - Quality levels affect bitrate, file size, and audio fidelity
-- - Low: 32kbps mono (~1MB per minute)
-- - Medium: 64kbps mono (~2MB per minute) - Default
-- - High: 128kbps stereo (~4MB per minute)
-- - Ultra: 256kbps stereo (~8MB per minute)
-- ============================================================================

-- ============================================================================
-- NOTES APP TABLES
-- ============================================================================

-- Table: phone_notes
-- Description: Stores user notes with title and content
-- Relationships: Links to phone_players via owner_number
-- Storage: Content stored as TEXT type (max 65,535 bytes / ~65KB per note)
--          For larger notes, consider splitting or using MEDIUMTEXT
-- File Storage: Notes are stored directly in database, not as external files
-- Size Limit: TEXT field allows up to 65KB of UTF-8 text (~16,000 words)
CREATE TABLE IF NOT EXISTS phone_notes (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique note identifier',
    owner_number VARCHAR(20) NOT NULL COMMENT 'Phone number of note owner',
    title VARCHAR(200) COMMENT 'Optional note title (max 200 characters)',
    content TEXT NOT NULL COMMENT 'Note content (max 65KB)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Note creation timestamp',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last modification timestamp',
    
    -- Indexes for performance
    INDEX idx_owner (owner_number) COMMENT 'Fast lookup of notes by owner',
    INDEX idx_created (created_at DESC) COMMENT 'Sort notes by creation date',
    
    -- Foreign key relationships
    -- Cascade delete: Remove all notes when player is deleted
    FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='User notes with automatic timestamps';

-- ============================================================================
-- ALARMS APP TABLES
-- ============================================================================

-- Table: phone_alarms
-- Description: Stores alarm configurations with scheduling and recurrence
-- Relationships: Links to phone_players via owner_number
-- 
-- ALARM SCHEDULING LOGIC:
-- - alarm_time: Time of day in 24-hour format (HH:MM:SS)
-- - alarm_days: Comma-separated day numbers for weekly recurrence
--   * Format: "0,1,2,3,4,5,6" where 0=Sunday, 1=Monday, ..., 6=Saturday
--   * NULL or empty string = one-time alarm (no recurrence)
--   * "1,2,3,4,5" = weekdays only (Monday through Friday)
--   * "0,6" = weekends only (Saturday and Sunday)
--   * "0,1,2,3,4,5,6" = every day
-- - enabled: Toggle alarm on/off without deleting configuration
-- 
-- RECURRENCE EXAMPLES:
-- - Daily alarm: alarm_days = "0,1,2,3,4,5,6"
-- - Weekday alarm: alarm_days = "1,2,3,4,5"
-- - Weekend alarm: alarm_days = "0,6"
-- - Specific days: alarm_days = "1,3,5" (Mon, Wed, Fri)
-- - One-time: alarm_days = NULL or ""
-- 
-- APPLICATION LOGIC:
-- - Server checks enabled alarms every minute
-- - Compares current time and day against alarm_time and alarm_days
-- - Triggers notification when match found
-- - One-time alarms automatically disabled after triggering
CREATE TABLE IF NOT EXISTS phone_alarms (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique alarm identifier',
    owner_number VARCHAR(20) NOT NULL COMMENT 'Phone number of alarm owner',
    alarm_time TIME NOT NULL COMMENT 'Time of day for alarm (HH:MM:SS format)',
    alarm_days VARCHAR(50) COMMENT 'Comma-separated day numbers (0-6) for recurrence',
    label VARCHAR(100) COMMENT 'Optional alarm label/description (max 100 chars)',
    enabled BOOLEAN DEFAULT TRUE COMMENT 'Whether alarm is active (toggle without deleting)',
    sound VARCHAR(100) COMMENT 'Alarm sound/ringtone identifier',
    
    -- Indexes for performance
    INDEX idx_owner (owner_number) COMMENT 'Fast lookup of alarms by owner',
    INDEX idx_enabled (enabled) COMMENT 'Filter active alarms for scheduling checks',
    INDEX idx_time (alarm_time) COMMENT 'Optimize time-based alarm queries',
    
    -- Foreign key relationships
    -- Cascade delete: Remove all alarms when player is deleted
    FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Alarm configurations with recurrence support';

-- ============================================================================
-- VOICE RECORDER APP TABLES
-- ============================================================================

-- Table: phone_voice_recordings
-- Description: Stores voice recordings with metadata and quality settings
-- Relationships: Links to phone_players via phone_number
-- 
-- FILE STORAGE PATHS:
-- - Storage location: /server/media/voice_recordings/{phone_number}/
-- - File naming: recording_{timestamp}_{id}.ogg
-- - Example: /server/media/voice_recordings/555-0123/recording_1698765432_42.ogg
-- - file_path field stores relative path from server root
-- - Actual audio data stored as external files, not in database
-- 
-- FILE SIZE LIMITS:
-- - Enforced at application layer based on quality settings
-- - Recommended maximum per recording: 50MB (~6 minutes at ultra quality)
-- - file_size field stores actual size in bytes for quota management
-- - Application should validate file size before saving
-- 
-- QUALITY SETTINGS AND FILE SIZES:
-- - Low quality: 32kbps mono, ~1MB per minute, suitable for voice notes
-- - Medium quality: 64kbps mono, ~2MB per minute (default, balanced)
-- - High quality: 128kbps stereo, ~4MB per minute, good for music/interviews
-- - Ultra quality: 256kbps stereo, ~8MB per minute, professional quality
-- 
-- QUALITY SELECTION LOGIC:
-- - Default quality from phone_voice_recorder_settings.recording_quality
-- - User can override per recording
-- - Higher quality = larger files but better audio fidelity
-- - Lower quality = smaller files, suitable for voice-only content
CREATE TABLE IF NOT EXISTS phone_voice_recordings (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique recording identifier',
    phone_number VARCHAR(20) NOT NULL COMMENT 'Phone number of recording owner',
    name VARCHAR(100) NOT NULL COMMENT 'User-defined recording name (max 100 chars)',
    duration INT NOT NULL COMMENT 'Recording duration in seconds',
    file_size INT NOT NULL COMMENT 'File size in bytes (for quota management)',
    quality ENUM('low', 'medium', 'high', 'ultra') DEFAULT 'medium' COMMENT 'Recording quality level',
    file_path VARCHAR(500) NOT NULL COMMENT 'Relative path to audio file (max 500 chars)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Recording creation timestamp',
    
    -- Indexes for performance
    INDEX idx_owner (phone_number) COMMENT 'Fast lookup of recordings by owner',
    INDEX idx_created (created_at DESC) COMMENT 'Sort recordings by date (newest first)',
    INDEX idx_quality (quality) COMMENT 'Filter recordings by quality level',
    INDEX idx_file_size (file_size) COMMENT 'Calculate total storage usage per user',
    
    -- Foreign key relationships
    -- Cascade delete: Remove all recordings when player is deleted
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Voice recordings with quality and size metadata';

-- Table: phone_voice_recorder_settings
-- Description: User preferences for voice recorder app
-- Relationships: Links to phone_players via phone_number (one-to-one relationship)
-- 
-- SETTING DESCRIPTIONS:
-- - auto_save: When TRUE, recordings are automatically saved when stopped
--              When FALSE, user must manually confirm save
-- - background_recording: When TRUE, allows recording while phone is locked/minimized
--                        When FALSE, recording stops when phone is closed
-- - max_recording_length: Maximum duration in seconds (default 600 = 10 minutes)
--                        Prevents excessively long recordings that consume storage
--                        Range: 60-3600 seconds (1 minute to 1 hour)
-- - auto_cleanup: When TRUE, automatically deletes recordings older than 30 days
--                When FALSE, recordings persist until manually deleted
-- - recording_quality: Default quality for new recordings (low/medium/high/ultra)
--                     User can override per recording
-- 
-- QUALITY SETTINGS IMPACT:
-- - Low (32kbps mono): Best for voice notes, minimal storage
-- - Medium (64kbps mono): Default, balanced quality and size
-- - High (128kbps stereo): Good for music/interviews
-- - Ultra (256kbps stereo): Professional quality, large files
-- 
-- STORAGE MANAGEMENT:
-- - Settings help manage storage usage per user
-- - max_recording_length prevents runaway recordings
-- - auto_cleanup helps maintain reasonable storage footprint
-- - recording_quality affects default file sizes
CREATE TABLE IF NOT EXISTS phone_voice_recorder_settings (
    phone_number VARCHAR(20) PRIMARY KEY COMMENT 'Phone number (one setting per user)',
    auto_save BOOLEAN DEFAULT TRUE COMMENT 'Automatically save recordings when stopped',
    background_recording BOOLEAN DEFAULT FALSE COMMENT 'Allow recording while phone locked',
    max_recording_length INT DEFAULT 600 COMMENT 'Max duration in seconds (default 10 min)',
    auto_cleanup BOOLEAN DEFAULT TRUE COMMENT 'Auto-delete recordings older than 30 days',
    recording_quality ENUM('low', 'medium', 'high', 'ultra') DEFAULT 'medium' COMMENT 'Default quality',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Settings creation timestamp',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',
    
    -- Foreign key relationships
    -- Cascade delete: Remove settings when player is deleted
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Voice recorder user preferences and settings';

-- ============================================================================
-- END OF UTILITY TABLES
-- ============================================================================
