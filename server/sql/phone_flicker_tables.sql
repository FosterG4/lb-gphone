-- Flicker App Database Tables

-- Table: phone_flicker_profiles (user dating profiles)
CREATE TABLE IF NOT EXISTS phone_flicker_profiles (
    phone_number VARCHAR(20) PRIMARY KEY,
    display_name VARCHAR(100) NOT NULL,
    bio TEXT,
    age INT,
    photos_json TEXT, -- JSON array of photo URLs
    preferences_json TEXT, -- JSON object with age range, distance, etc.
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_active (active),
    INDEX idx_age (age),
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_flicker_swipes (record of all swipes)
CREATE TABLE IF NOT EXISTS phone_flicker_swipes (
    swiper_number VARCHAR(20) NOT NULL,
    swiped_number VARCHAR(20) NOT NULL,
    swipe_type ENUM('like', 'pass') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (swiper_number, swiped_number),
    INDEX idx_swiper (swiper_number),
    INDEX idx_swiped (swiped_number),
    INDEX idx_type (swipe_type),
    INDEX idx_created (created_at DESC),
    FOREIGN KEY (swiper_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (swiped_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_flicker_matches (mutual likes)
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
    FOREIGN KEY (player2_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    CONSTRAINT check_different_players CHECK (player1_number < player2_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_flicker_messages (in-app messages between matches)
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

-- Table: phone_flicker_blocks (blocked users)
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

-- Table: phone_flicker_reports (user reports for moderation)
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
