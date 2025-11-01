-- ============================================================================
-- Contact Sharing Database Tables
-- ============================================================================
-- Description: Tables for contact sharing feature between users
-- Dependencies: phone_players
-- ============================================================================

-- Table: phone_share_requests
-- Description: Stores contact share requests between players with expiration tracking
-- Relationships: References phone_players for sender and receiver
CREATE TABLE IF NOT EXISTS phone_share_requests (
    id VARCHAR(36) PRIMARY KEY COMMENT 'UUID for share request',
    sender_number VARCHAR(20) NOT NULL COMMENT 'Phone number of sender',
    sender_name VARCHAR(100) NOT NULL COMMENT 'Display name of sender',
    receiver_number VARCHAR(20) NOT NULL COMMENT 'Phone number of receiver',
    receiver_name VARCHAR(100) NOT NULL COMMENT 'Display name of receiver',
    status ENUM('pending', 'accepted', 'declined', 'expired') DEFAULT 'pending' COMMENT 'Request status',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Request creation timestamp',
    expires_at TIMESTAMP NOT NULL COMMENT 'Request expiration timestamp',
    responded_at TIMESTAMP NULL COMMENT 'Response timestamp',
    INDEX idx_sender (sender_number),
    INDEX idx_receiver (receiver_number),
    INDEX idx_status (status),
    INDEX idx_expires (expires_at),
    FOREIGN KEY (sender_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (receiver_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
