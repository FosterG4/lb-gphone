-- ============================================================================
-- Musicly Music Application Database Tables
-- ============================================================================
-- Description: Tables for the Musicly music streaming and playlist management
--              application. Supports playlist creation, track management, and
--              play history tracking.
-- Dependencies: phone_players (phone_number)
-- Created: 2025-11-01
-- ============================================================================

-- Table: phone_musicly_playlists
-- Description: Stores user-created music playlists with metadata
-- Relationships: References phone_players for ownership
-- Features:
--   - Public/private playlist visibility
--   - Automatic timestamp tracking for creation and updates
--   - Supports playlist descriptions for organization
CREATE TABLE IF NOT EXISTS phone_musicly_playlists (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique playlist identifier',
    phone_number VARCHAR(20) NOT NULL COMMENT 'Owner phone number',
    name VARCHAR(100) NOT NULL COMMENT 'Playlist name',
    description TEXT COMMENT 'Optional playlist description',
    is_public BOOLEAN DEFAULT FALSE COMMENT 'Whether playlist is publicly visible',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Playlist creation timestamp',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last modification timestamp',
    
    -- Indexes for performance
    INDEX idx_owner (phone_number) COMMENT 'Fast lookup by owner',
    INDEX idx_public (is_public) COMMENT 'Filter public playlists',
    
    -- Foreign key constraints
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='User music playlists with privacy controls';

-- Table: phone_musicly_playlist_tracks
-- Description: Junction table linking tracks to playlists with track metadata
-- Relationships: References phone_musicly_playlists for playlist association
-- Features:
--   - Stores track metadata (title, artist, duration)
--   - Track duration stored in seconds
--   - Tracks when each track was added to playlist
--   - Supports multiple playlists containing the same track
CREATE TABLE IF NOT EXISTS phone_musicly_playlist_tracks (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique track entry identifier',
    playlist_id INT NOT NULL COMMENT 'Associated playlist ID',
    track_id VARCHAR(50) NOT NULL COMMENT 'External track identifier (e.g., Spotify ID, YouTube ID)',
    track_title VARCHAR(200) NOT NULL COMMENT 'Track title',
    track_artist VARCHAR(200) NOT NULL COMMENT 'Track artist name',
    track_duration INT NOT NULL COMMENT 'Track duration in seconds',
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When track was added to playlist',
    
    -- Indexes for performance
    INDEX idx_playlist (playlist_id) COMMENT 'Fast lookup by playlist',
    INDEX idx_track (track_id) COMMENT 'Fast lookup by track ID',
    
    -- Foreign key constraints
    FOREIGN KEY (playlist_id) REFERENCES phone_musicly_playlists(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Tracks within playlists with metadata';

-- Table: phone_musicly_play_history
-- Description: Records user listening history for analytics and recommendations
-- Relationships: References phone_players for user association
-- Features:
--   - Tracks play duration to measure engagement
--   - Stores track metadata for historical reference
--   - Ordered by play time for recent history
--   - Play duration stored in seconds (may be partial if skipped)
CREATE TABLE IF NOT EXISTS phone_musicly_play_history (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique play history entry identifier',
    phone_number VARCHAR(20) NOT NULL COMMENT 'User phone number',
    track_id VARCHAR(50) NOT NULL COMMENT 'External track identifier',
    track_title VARCHAR(200) NOT NULL COMMENT 'Track title at time of play',
    track_artist VARCHAR(200) NOT NULL COMMENT 'Track artist at time of play',
    play_duration INT DEFAULT 0 COMMENT 'How long track was played in seconds (0 if skipped)',
    played_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When track was played',
    
    -- Indexes for performance
    INDEX idx_owner (phone_number) COMMENT 'Fast lookup by user',
    INDEX idx_track (track_id) COMMENT 'Fast lookup by track',
    INDEX idx_played (played_at DESC) COMMENT 'Recent history first',
    
    -- Foreign key constraints
    FOREIGN KEY (phone_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='User music play history for analytics';

-- ============================================================================
-- Notes:
-- ============================================================================
-- Track Duration Format: All durations stored as INTEGER seconds
--   - Example: 3:45 song = 225 seconds
--   - Example: 1:30:00 podcast = 5400 seconds
--
-- Track ID Format: External identifier from music service
--   - Spotify: spotify:track:6rqhFgbbKwnb9MLmUQDhG6
--   - YouTube: dQw4w9WgXcQ
--   - Custom: custom_track_123
--
-- Playlist Privacy Logic:
--   - is_public = FALSE: Only owner can view/edit
--   - is_public = TRUE: Others can view (but not edit)
--   - Sharing logic handled at application layer
--
-- Play History Usage:
--   - Analytics: Most played tracks, artists, genres
--   - Recommendations: Similar tracks based on history
--   - Statistics: Total listening time, favorite artists
--   - play_duration < track_duration indicates skip/partial play
--
-- Common Queries:
--   - Get user playlists: SELECT * FROM phone_musicly_playlists WHERE phone_number = ?
--   - Get playlist tracks: SELECT * FROM phone_musicly_playlist_tracks WHERE playlist_id = ?
--   - Get recent plays: SELECT * FROM phone_musicly_play_history WHERE phone_number = ? ORDER BY played_at DESC LIMIT 50
--   - Get public playlists: SELECT * FROM phone_musicly_playlists WHERE is_public = TRUE
-- ============================================================================
