-- Tables for Modish app (short videos)

-- Table: phone_modish_videos (main video posts)
CREATE TABLE IF NOT EXISTS phone_modish_videos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    author_number VARCHAR(20) NOT NULL,
    author_name VARCHAR(100) NOT NULL,
    media_id INT NOT NULL,
    caption TEXT,
    music_track VARCHAR(200),
    filters_json TEXT,
    likes INT DEFAULT 0,
    views INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_author (author_number),
    INDEX idx_created (created_at DESC),
    INDEX idx_media (media_id),
    FOREIGN KEY (author_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (media_id) REFERENCES phone_media(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_modish_likes (for tracking who liked which videos)
CREATE TABLE IF NOT EXISTS phone_modish_likes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    video_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_like (phone_number, video_id),
    INDEX idx_phone (phone_number),
    INDEX idx_video (video_id),
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (video_id) REFERENCES phone_modish_videos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_modish_comments (for video comments)
CREATE TABLE IF NOT EXISTS phone_modish_comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    video_id INT NOT NULL,
    author_number VARCHAR(20) NOT NULL,
    author_name VARCHAR(100) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_video (video_id),
    INDEX idx_author (author_number),
    INDEX idx_created (created_at ASC),
    FOREIGN KEY (video_id) REFERENCES phone_modish_videos(id) ON DELETE CASCADE,
    FOREIGN KEY (author_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

