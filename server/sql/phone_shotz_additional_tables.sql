-- ============================================================================
-- Shotz App Database Tables
-- ============================================================================
-- Description: Tables for the Shotz photo/video sharing app (Instagram-like functionality)
-- Dependencies: phone_players, phone_media
-- ============================================================================

-- Table: phone_shotz_posts
-- Description: Main posts table for Shotz app with media attachments
-- Relationships: References phone_players for author and phone_media for primary media
CREATE TABLE IF NOT EXISTS phone_shotz_posts (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    author_number VARCHAR(20) NOT NULL COMMENT 'Phone number of post author',
    author_name VARCHAR(100) NOT NULL COMMENT 'Display name of author',
    caption TEXT COMMENT 'Post caption',
    media_id INT NOT NULL COMMENT 'ID of primary media file',
    likes INT DEFAULT 0 COMMENT 'Total number of likes',
    comments INT DEFAULT 0 COMMENT 'Total number of comments',
    shares INT DEFAULT 0 COMMENT 'Total number of shares',
    is_live BOOLEAN DEFAULT FALSE COMMENT 'Live post status',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Post creation timestamp',
    INDEX idx_author (author_number),
    INDEX idx_created (created_at DESC),
    FOREIGN KEY (author_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (media_id) REFERENCES phone_media(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_shotz_followers
-- Description: Follower relationships between users
-- Relationships: References phone_players for both follower and following
CREATE TABLE IF NOT EXISTS phone_shotz_followers (
    follower_number VARCHAR(20) NOT NULL COMMENT 'Phone number of follower',
    following_number VARCHAR(20) NOT NULL COMMENT 'Phone number being followed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Follow timestamp',
    PRIMARY KEY (follower_number, following_number),
    FOREIGN KEY (follower_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (following_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_shotz_likes
-- Description: Tracks which users liked which posts (prevents duplicate likes)
-- Relationships: References phone_players and phone_shotz_posts
CREATE TABLE IF NOT EXISTS phone_shotz_likes (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    phone_number VARCHAR(20) NOT NULL COMMENT 'Phone number of user who liked',
    post_id INT NOT NULL COMMENT 'ID of liked post',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Like timestamp',
    UNIQUE KEY unique_like (phone_number, post_id),
    INDEX idx_phone (phone_number),
    INDEX idx_post (post_id),
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES phone_shotz_posts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_shotz_comments
-- Description: Comments on posts
-- Relationships: References phone_shotz_posts and phone_players
CREATE TABLE IF NOT EXISTS phone_shotz_comments (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    post_id INT NOT NULL COMMENT 'ID of post being commented on',
    author_number VARCHAR(20) NOT NULL COMMENT 'Phone number of comment author',
    author_name VARCHAR(100) NOT NULL COMMENT 'Display name of author',
    content TEXT NOT NULL COMMENT 'Comment content',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Comment timestamp',
    INDEX idx_post (post_id),
    INDEX idx_author (author_number),
    INDEX idx_created (created_at ASC),
    FOREIGN KEY (post_id) REFERENCES phone_shotz_posts(id) ON DELETE CASCADE,
    FOREIGN KEY (author_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
