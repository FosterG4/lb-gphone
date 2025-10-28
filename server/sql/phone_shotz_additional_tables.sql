-- Additional tables for Shotz app

-- Table: phone_shotz_likes (for tracking who liked which posts)
CREATE TABLE IF NOT EXISTS phone_shotz_likes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    post_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_like (phone_number, post_id),
    INDEX idx_phone (phone_number),
    INDEX idx_post (post_id),
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES phone_shotz_posts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: phone_shotz_comments (for post comments)
CREATE TABLE IF NOT EXISTS phone_shotz_comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    author_number VARCHAR(20) NOT NULL,
    author_name VARCHAR(100) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_post (post_id),
    INDEX idx_author (author_number),
    INDEX idx_created (created_at ASC),
    FOREIGN KEY (post_id) REFERENCES phone_shotz_posts(id) ON DELETE CASCADE,
    FOREIGN KEY (author_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
