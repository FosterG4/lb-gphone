-- ============================================================================
-- Social Media Multi-Attachments Database Tables
-- ============================================================================
-- Description: Junction tables for multiple media attachments per social media post
-- Dependencies: phone_shotz_posts, phone_modish_videos, phone_media
-- Note: The existing media_id column in phone_shotz_posts and phone_modish_videos
--       represents the primary/first media item. Additional media items are stored here.
-- ============================================================================

-- Table: phone_shotz_post_media
-- Description: Junction table for multiple media attachments per Shotz post
-- Relationships: References phone_shotz_posts and phone_media
CREATE TABLE IF NOT EXISTS phone_shotz_post_media (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    post_id INT NOT NULL COMMENT 'ID of Shotz post',
    media_id INT NOT NULL COMMENT 'ID of media file',
    display_order INT DEFAULT 0 COMMENT 'Display order for media carousel',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Attachment timestamp',
    INDEX idx_post (post_id),
    INDEX idx_media (media_id),
    UNIQUE KEY unique_post_media (post_id, media_id),
    FOREIGN KEY (post_id) REFERENCES phone_shotz_posts(id) ON DELETE CASCADE,
    FOREIGN KEY (media_id) REFERENCES phone_media(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_modish_video_media
-- Description: Junction table for multiple media attachments per Modish video post
-- Relationships: References phone_modish_videos and phone_media
CREATE TABLE IF NOT EXISTS phone_modish_video_media (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    video_id INT NOT NULL COMMENT 'ID of Modish video',
    media_id INT NOT NULL COMMENT 'ID of media file',
    display_order INT DEFAULT 0 COMMENT 'Display order for media carousel',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Attachment timestamp',
    INDEX idx_video (video_id),
    INDEX idx_media (media_id),
    UNIQUE KEY unique_video_media (video_id, media_id),
    FOREIGN KEY (video_id) REFERENCES phone_modish_videos(id) ON DELETE CASCADE,
    FOREIGN KEY (media_id) REFERENCES phone_media(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
