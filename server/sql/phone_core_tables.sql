-- ============================================================================
-- Core Phone System Database Tables
-- ============================================================================
-- Description: Core tables for the FiveM Phone System that provide fundamental
--              functionality including player phone numbers, contacts, messages,
--              call history, and user settings.
-- Dependencies: None (these are root tables)
-- Created: 2025-11-01
-- ============================================================================

-- ============================================================================
-- Table: phone_players
-- ============================================================================
-- Description: Primary table storing all phone users and their phone numbers.
--              This is the root table referenced by almost all other tables
--              in the phone system.
-- Relationships: Referenced by phone_contacts, phone_messages, phone_settings,
--                and many other tables via phone_number foreign key.
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_players (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each player',
    identifier VARCHAR(50) UNIQUE NOT NULL COMMENT 'Player identifier from framework (e.g., license, steam)',
    phone_number VARCHAR(20) UNIQUE NOT NULL COMMENT 'Unique phone number assigned to player',
    installed_apps TEXT COMMENT 'JSON array of installed applications',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp when phone was created',
    
    -- Indexes for performance optimization
    INDEX idx_identifier (identifier),
    INDEX idx_phone_number (phone_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Table: phone_contacts
-- ============================================================================
-- Description: Stores contact lists for each phone user. Each user can have
--              multiple contacts with custom display names.
-- Relationships: Foreign key to phone_players(phone_number) with CASCADE delete
--                to automatically remove contacts when a player is deleted.
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_contacts (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each contact entry',
    owner_number VARCHAR(20) NOT NULL COMMENT 'Phone number of the contact list owner',
    contact_name VARCHAR(100) NOT NULL COMMENT 'Display name for the contact',
    contact_number VARCHAR(20) NOT NULL COMMENT 'Phone number of the contact',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp when contact was added',
    
    -- Indexes for performance optimization
    INDEX idx_owner (owner_number),
    
    -- Foreign key constraints
    FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Table: phone_messages
-- ============================================================================
-- Description: Stores SMS/text messages between phone users. Supports
--              conversation threading and read status tracking.
-- Relationships: No direct foreign keys to allow messages to persist even if
--                phone numbers are reassigned or deleted.
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_messages (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each message',
    sender_number VARCHAR(20) NOT NULL COMMENT 'Phone number of the message sender',
    receiver_number VARCHAR(20) NOT NULL COMMENT 'Phone number of the message receiver',
    message TEXT NOT NULL COMMENT 'Content of the text message',
    is_read BOOLEAN DEFAULT FALSE COMMENT 'Whether the message has been read by receiver',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp when message was sent',
    
    -- Indexes for performance optimization
    INDEX idx_conversation (sender_number, receiver_number) COMMENT 'Optimizes conversation queries',
    INDEX idx_receiver (receiver_number, is_read) COMMENT 'Optimizes unread message queries'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Table: phone_call_history
-- ============================================================================
-- Description: Stores call logs including incoming, outgoing, and missed calls
--              with duration tracking.
-- Relationships: No direct foreign keys to preserve call history even if
--                phone numbers are reassigned or deleted.
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_call_history (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each call record',
    caller_number VARCHAR(20) NOT NULL COMMENT 'Phone number of the caller',
    receiver_number VARCHAR(20) NOT NULL COMMENT 'Phone number of the receiver',
    duration INT DEFAULT 0 COMMENT 'Call duration in seconds',
    call_type ENUM('incoming', 'outgoing', 'missed') NOT NULL COMMENT 'Type of call',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp when call occurred',
    
    -- Indexes for performance optimization
    INDEX idx_caller (caller_number) COMMENT 'Optimizes queries for outgoing calls',
    INDEX idx_receiver (receiver_number) COMMENT 'Optimizes queries for incoming calls'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Table: phone_settings
-- ============================================================================
-- Description: Stores user preferences and configuration for each phone including
--              theme, notifications, sounds, volume, and locale settings.
-- Relationships: Foreign key to phone_players(phone_number) with CASCADE delete
--                to automatically remove settings when a player is deleted.
-- ============================================================================
CREATE TABLE IF NOT EXISTS phone_settings (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each settings record',
    phone_number VARCHAR(20) UNIQUE NOT NULL COMMENT 'Phone number (one settings record per phone)',
    theme VARCHAR(50) DEFAULT 'default' COMMENT 'UI theme name',
    notification_enabled BOOLEAN DEFAULT TRUE COMMENT 'Whether notifications are enabled',
    sound_enabled BOOLEAN DEFAULT TRUE COMMENT 'Whether sounds are enabled',
    volume INT DEFAULT 50 COMMENT 'Volume level (0-100)',
    locale VARCHAR(10) DEFAULT 'en' COMMENT 'Language/locale code',
    settings_json TEXT COMMENT 'Additional settings stored as JSON',
    
    -- Foreign key constraints
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
