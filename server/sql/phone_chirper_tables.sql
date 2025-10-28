-- Chirper App Database Tables

-- Table: phone_chirper_posts (main posts table)
-- Already defined in design.md, creating here for completeness
CREATE TABLE IF NOT EXISTS phone_chirper_posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    author_number VARCHAR(20) NOT NULL,
    author_name VARCHAR(100) NOT NULL,
    content VARCHAR(280) NOT NULL,
    likes INT DEFAULT 0,
    reposts INT DEFAULT 0,
    replies INT DEFAULT 0,
    parent_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_author (author_number),
    INDEX idx_created (created_at DESC),
    INDEX idx_parent (parent_id),
    FOREIGN KEY (author_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES phone_chirper_posts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_chirper_likes (for tracking who liked which posts)
CREATE TABLE IF NOT EXISTS phone_chirper_likes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    post_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_like (phone_number, post_id),
    INDEX idx_phone (phone_number),
    INDEX idx_post (post_id),
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES phone_chirper_posts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_chirper_reposts (for tracking who reposted which posts)
CREATE TABLE IF NOT EXISTS phone_chirper_reposts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    post_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_repost (phone_number, post_id),
    INDEX idx_phone (phone_number),
    INDEX idx_post (post_id),
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES phone_chirper_posts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_chirper_hashtags (for tracking hashtags in posts)
CREATE TABLE IF NOT EXISTS phone_chirper_hashtags (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    hashtag VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_post (post_id),
    INDEX idx_hashtag (hashtag),
    INDEX idx_created (created_at DESC),
    FOREIGN KEY (post_id) REFERENCES phone_chirper_posts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
