-- ============================================================================
-- Chirper App Database Tables
-- ============================================================================
-- Description: Tables for the Chirper social media app (Twitter-like functionality)
-- Dependencies: phone_players
-- ============================================================================

-- Table: phone_chirper_posts
-- Description: Main posts table for Chirper app, supports threaded conversations
-- Relationships: References phone_players for author, self-references for replies
CREATE TABLE IF NOT EXISTS phone_chirper_posts (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    author_number VARCHAR(20) NOT NULL COMMENT 'Phone number of post author',
    author_name VARCHAR(100) NOT NULL COMMENT 'Display name of author',
    content VARCHAR(280) NOT NULL COMMENT 'Post content (280 char limit)',
    likes INT DEFAULT 0 COMMENT 'Total number of likes',
    reposts INT DEFAULT 0 COMMENT 'Total number of reposts',
    replies INT DEFAULT 0 COMMENT 'Total number of replies',
    parent_id INT NULL COMMENT 'Parent post ID for threaded replies',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Post creation timestamp',
    INDEX idx_author (author_number),
    INDEX idx_created (created_at DESC),
    INDEX idx_parent (parent_id),
    FOREIGN KEY (author_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES phone_chirper_posts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_chirper_likes
-- Description: Tracks which users liked which posts (prevents duplicate likes)
-- Relationships: References phone_players and phone_chirper_posts
CREATE TABLE IF NOT EXISTS phone_chirper_likes (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    phone_number VARCHAR(20) NOT NULL COMMENT 'Phone number of user who liked',
    post_id INT NOT NULL COMMENT 'ID of liked post',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Like timestamp',
    UNIQUE KEY unique_like (phone_number, post_id),
    INDEX idx_phone (phone_number),
    INDEX idx_post (post_id),
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES phone_chirper_posts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_chirper_reposts
-- Description: Tracks which users reposted which posts (prevents duplicate reposts)
-- Relationships: References phone_players and phone_chirper_posts
CREATE TABLE IF NOT EXISTS phone_chirper_reposts (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    phone_number VARCHAR(20) NOT NULL COMMENT 'Phone number of user who reposted',
    post_id INT NOT NULL COMMENT 'ID of reposted post',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Repost timestamp',
    UNIQUE KEY unique_repost (phone_number, post_id),
    INDEX idx_phone (phone_number),
    INDEX idx_post (post_id),
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES phone_chirper_posts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_chirper_hashtags
-- Description: Tracks hashtags used in posts for search and trending features
-- Relationships: References phone_chirper_posts
CREATE TABLE IF NOT EXISTS phone_chirper_hashtags (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    post_id INT NOT NULL COMMENT 'ID of post containing hashtag',
    hashtag VARCHAR(100) NOT NULL COMMENT 'Hashtag text (without # symbol)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Hashtag creation timestamp',
    INDEX idx_post (post_id),
    INDEX idx_hashtag (hashtag),
    INDEX idx_created (created_at DESC),
    FOREIGN KEY (post_id) REFERENCES phone_chirper_posts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
