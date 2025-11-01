-- ============================================================================
-- Flicker App Database Tables
-- ============================================================================
-- Description: Tables for the Flicker dating app (Tinder-like functionality)
-- Dependencies: phone_players
-- ============================================================================

-- Table: phone_flicker_profiles
-- Description: User dating profiles with photos and preferences
-- Relationships: References phone_players
CREATE TABLE IF NOT EXISTS phone_flicker_profiles (
    phone_number VARCHAR(20) PRIMARY KEY COMMENT 'Phone number (primary key)',
    display_name VARCHAR(100) NOT NULL COMMENT 'Display name on profile',
    bio TEXT COMMENT 'User biography',
    age INT COMMENT 'User age',
    photos_json TEXT COMMENT 'JSON array of photo URLs',
    preferences_json TEXT COMMENT 'JSON object with age range, distance, etc.',
    active BOOLEAN DEFAULT TRUE COMMENT 'Profile active status',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Profile creation timestamp',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',
    INDEX idx_active (active),
    INDEX idx_age (age),
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_flicker_swipes
-- Description: Record of all swipes (like or pass) to prevent duplicate swipes
-- Relationships: References phone_players for both swiper and swiped user
CREATE TABLE IF NOT EXISTS phone_flicker_swipes (
    swiper_number VARCHAR(20) NOT NULL COMMENT 'Phone number of user swiping',
    swiped_number VARCHAR(20) NOT NULL COMMENT 'Phone number of user being swiped',
    swipe_type ENUM('like', 'pass') NOT NULL COMMENT 'Type of swipe',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Swipe timestamp',
    PRIMARY KEY (swiper_number, swiped_number),
    INDEX idx_swiper (swiper_number),
    INDEX idx_swiped (swiped_number),
    INDEX idx_type (swipe_type),
    INDEX idx_created (created_at DESC),
    FOREIGN KEY (swiper_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (swiped_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_flicker_matches
-- Description: Mutual likes between users (both swiped right)
-- Relationships: References phone_players for both matched users
CREATE TABLE IF NOT EXISTS phone_flicker_matches (
    player1_number VARCHAR(20) NOT NULL COMMENT 'First player phone number',
    player2_number VARCHAR(20) NOT NULL COMMENT 'Second player phone number',
    matched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Match creation timestamp',
    last_message_at TIMESTAMP NULL COMMENT 'Last message timestamp',
    unmatched BOOLEAN DEFAULT FALSE COMMENT 'Unmatch status',
    unmatched_by VARCHAR(20) NULL COMMENT 'Phone number of user who unmatched',
    unmatched_at TIMESTAMP NULL COMMENT 'Unmatch timestamp',
    PRIMARY KEY (player1_number, player2_number),
    INDEX idx_player1 (player1_number),
    INDEX idx_player2 (player2_number),
    INDEX idx_matched (matched_at DESC),
    INDEX idx_unmatched (unmatched),
    FOREIGN KEY (player1_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (player2_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    CONSTRAINT check_different_players CHECK (player1_number < player2_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_flicker_messages
-- Description: In-app messages between matched users
-- Relationships: References phone_players for sender and receiver
CREATE TABLE IF NOT EXISTS phone_flicker_messages (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    sender_number VARCHAR(20) NOT NULL COMMENT 'Phone number of sender',
    receiver_number VARCHAR(20) NOT NULL COMMENT 'Phone number of receiver',
    content TEXT NOT NULL COMMENT 'Message content',
    read_status BOOLEAN DEFAULT FALSE COMMENT 'Message read status',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Message timestamp',
    INDEX idx_sender (sender_number),
    INDEX idx_receiver (receiver_number),
    INDEX idx_conversation (sender_number, receiver_number, created_at),
    INDEX idx_created (created_at DESC),
    INDEX idx_read (read_status),
    FOREIGN KEY (sender_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (receiver_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_flicker_blocks
-- Description: Blocked users list to prevent interactions
-- Relationships: References phone_players for blocker and blocked user
CREATE TABLE IF NOT EXISTS phone_flicker_blocks (
    blocker_number VARCHAR(20) NOT NULL COMMENT 'Phone number of user blocking',
    blocked_number VARCHAR(20) NOT NULL COMMENT 'Phone number of blocked user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Block timestamp',
    PRIMARY KEY (blocker_number, blocked_number),
    INDEX idx_blocker (blocker_number),
    INDEX idx_blocked (blocked_number),
    FOREIGN KEY (blocker_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (blocked_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_flicker_reports
-- Description: User reports for moderation purposes
-- Relationships: References phone_players for reporter and reported user
CREATE TABLE IF NOT EXISTS phone_flicker_reports (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    reporter_number VARCHAR(20) NOT NULL COMMENT 'Phone number of reporter',
    reported_number VARCHAR(20) NOT NULL COMMENT 'Phone number of reported user',
    reason VARCHAR(255) NOT NULL COMMENT 'Report reason',
    details TEXT COMMENT 'Additional report details',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Report timestamp',
    INDEX idx_reporter (reporter_number),
    INDEX idx_reported (reported_number),
    INDEX idx_created (created_at DESC),
    FOREIGN KEY (reporter_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (reported_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
