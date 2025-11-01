-- ============================================================================
-- Media Storage Database Tables
-- ============================================================================
-- Description: Tables for storing photos, videos, audio files, and albums
-- Dependencies: phone_players (phone_core_tables.sql)
-- Created: 2025-11-01
-- ============================================================================
-- 
-- Storage Constraints:
-- - Maximum file size: Configurable per media type (typically 10MB for photos, 50MB for videos)
-- - Storage quota: Per-user limits enforced at application layer
-- - Supported formats: JPEG, PNG, GIF for photos; MP4, WEBM for videos; MP3, OGG for audio
-- 
-- Performance Notes:
-- - Indexes on media_type, owner_number, and created_at for efficient querying
-- - Foreign keys with CASCADE delete to automatically clean up orphaned media
-- - Location data (x, y coordinates) stored for geotagged media
-- ============================================================================

-- Table: phone_media
-- Description: Central media storage table for all photos, videos, and audio files
-- Relationships: 
--   - References phone_players(phone_number) for ownership
--   - Referenced by phone_albums for album cover images
--   - Referenced by phone_shotz_posts, phone_modish_videos for social media content
-- Storage:
--   - file_url: Full URL to media file (local nui:// or remote CDN)
--   - thumbnail_url: Optional thumbnail for videos and large images
--   - file_size: Size in bytes for quota management
--   - duration: Length in seconds for video/audio files
--   - location_x, location_y: GPS coordinates if geotagged
--   - metadata_json: Additional metadata (EXIF data, filters, etc.)
CREATE TABLE IF NOT EXISTS phone_media (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    owner_number VARCHAR(20) NOT NULL COMMENT 'Phone number of media owner',
    media_type ENUM('photo', 'video', 'audio') NOT NULL COMMENT 'Type of media file',
    file_url VARCHAR(500) NOT NULL COMMENT 'Full URL to media file',
    thumbnail_url VARCHAR(500) COMMENT 'Optional thumbnail URL for videos',
    duration INT DEFAULT 0 COMMENT 'Duration in seconds for video/audio',
    file_size INT DEFAULT 0 COMMENT 'File size in bytes for quota tracking',
    location_x FLOAT COMMENT 'GPS X coordinate if geotagged',
    location_y FLOAT COMMENT 'GPS Y coordinate if geotagged',
    metadata_json TEXT COMMENT 'Additional metadata in JSON format',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Upload timestamp',
    
    -- Indexes for performance
    INDEX idx_owner (owner_number) COMMENT 'Fast lookup by owner',
    INDEX idx_type (media_type) COMMENT 'Filter by media type',
    INDEX idx_created (created_at DESC) COMMENT 'Sort by upload date',
    INDEX idx_owner_type (owner_number, media_type) COMMENT 'Combined owner and type queries',
    
    -- Foreign key constraints
    FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Central storage for all media files (photos, videos, audio)';

-- Table: phone_albums
-- Description: Photo album organization for grouping related media
-- Relationships:
--   - References phone_players(phone_number) for ownership
--   - References phone_media(id) for cover image
--   - Referenced by phone_album_media for album contents
-- Features:
--   - Custom album names for organization
--   - Optional cover image selection
--   - Automatic timestamp tracking
CREATE TABLE IF NOT EXISTS phone_albums (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key',
    owner_number VARCHAR(20) NOT NULL COMMENT 'Phone number of album owner',
    album_name VARCHAR(100) NOT NULL COMMENT 'User-defined album name',
    cover_media_id INT COMMENT 'Optional cover image from album contents',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Album creation timestamp',
    
    -- Indexes for performance
    INDEX idx_owner (owner_number) COMMENT 'Fast lookup by owner',
    INDEX idx_created (created_at DESC) COMMENT 'Sort by creation date',
    
    -- Foreign key constraints
    FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE,
    FOREIGN KEY (cover_media_id) REFERENCES phone_media(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Photo albums for organizing media into collections';

-- Table: phone_album_media
-- Description: Junction table for many-to-many relationship between albums and media
-- Relationships:
--   - References phone_albums(id) for the album
--   - References phone_media(id) for the media item
-- Features:
--   - Allows same media to appear in multiple albums
--   - Tracks when media was added to album
--   - Composite primary key prevents duplicates
--   - CASCADE delete removes entries when album or media is deleted
CREATE TABLE IF NOT EXISTS phone_album_media (
    album_id INT NOT NULL COMMENT 'Album identifier',
    media_id INT NOT NULL COMMENT 'Media item identifier',
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When media was added to album',
    
    -- Composite primary key
    PRIMARY KEY (album_id, media_id) COMMENT 'Prevent duplicate media in same album',
    
    -- Indexes for performance
    INDEX idx_album (album_id) COMMENT 'Fast lookup by album',
    INDEX idx_media (media_id) COMMENT 'Fast lookup by media',
    
    -- Foreign key constraints with CASCADE delete
    FOREIGN KEY (album_id) REFERENCES phone_albums(id) ON DELETE CASCADE,
    FOREIGN KEY (media_id) REFERENCES phone_media(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Junction table linking media items to albums (many-to-many)';

-- ============================================================================
-- End of Media Storage Tables
-- ============================================================================
