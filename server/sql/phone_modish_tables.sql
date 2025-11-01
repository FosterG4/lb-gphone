-- ============================================================================
-- Modish App Database Tables
-- ============================================================================
-- Description: Tables for the Modish short video app (TikTok-like functionality)
-- Dependencies: phone_players, phone_media
-- ============================================================================

-- Table: phone_modish_videos
-- Description: Main video posts table with music and filters
-- Relationships: References phone_players for author and phone_media for video
CREATE TABLE IF NOT EXISTS phone_modish_videos (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    author_number VARCHAR(20) NOT NULL COMMENT 'Phone number of video author',
    author_name VARCHAR(100) NOT NULL COMMENT 'Display name of author',
    media_id INT NOT NULL COMMENT 'ID of video media file',
    caption TEXT COMMENT 'Video caption',
    music_track VARCHAR(200) COMMENT 'Music track used in video',
    filters_json TEXT COMMENT 'JSON array of applied filters',
    likes INT DEFAULT 0 COMMENT 'Total number of likes',
    views INT DEFAULT 0 COMMENT 'Total number of views',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Video creation timestamp',
    INDEX idx_author (author_number),
    INDEX idx_created (created_at DESC),
    INDEX idx_media (media_id),
    FOREIGN KEY (author_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (media_id) REFERENCES phone_media(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_modish_likes
-- Description: Tracks which users liked which videos (prevents duplicate likes)
-- Relationships: References phone_players and phone_modish_videos
CREATE TABLE IF NOT EXISTS phone_modish_likes (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    phone_number VARCHAR(20) NOT NULL COMMENT 'Phone number of user who liked',
    video_id INT NOT NULL COMMENT 'ID of liked video',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Like timestamp',
    UNIQUE KEY unique_like (phone_number, video_id),
    INDEX idx_phone (phone_number),
    INDEX idx_video (video_id),
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (video_id) REFERENCES phone_modish_videos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_modish_comments
-- Description: Comments on videos
-- Relationships: References phone_modish_videos and phone_players
CREATE TABLE IF NOT EXISTS phone_modish_comments (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    video_id INT NOT NULL COMMENT 'ID of video being commented on',
    author_number VARCHAR(20) NOT NULL COMMENT 'Phone number of comment author',
    author_name VARCHAR(100) NOT NULL COMMENT 'Display name of author',
    content TEXT NOT NULL COMMENT 'Comment content',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Comment timestamp',
    INDEX idx_video (video_id),
    INDEX idx_author (author_number),
    INDEX idx_created (created_at ASC),
    FOREIGN KEY (video_id) REFERENCES phone_modish_videos(id) ON DELETE CASCADE,
    FOREIGN KEY (author_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

