-- Musicly App Server Logic
-- Handles music streaming, playlist management, and radio stations

-- Initialize Musicly data for player
RegisterNetEvent('phone:server:initializeMusicly', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:musiclyInitialized', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Get user playlists
    local playlists = MySQL.query.await([[
        SELECT 
            id,
            name,
            cover,
            created_at,
            (SELECT COUNT(*) FROM phone_musicly_playlist_tracks WHERE playlist_id = p.id) as track_count
        FROM phone_musicly_playlists p
        WHERE phone_number = ?
        ORDER BY created_at DESC
    ]], { phoneNumber })
    
    -- Get radio stations
    local radioStations = {
        {
            id = 'los-santos-rock',
            name = 'Los Santos Rock Radio',
            genre = 'Rock',
            description = 'Classic and modern rock hits',
            logo = '/assets/radio/ls-rock.jpg',
            stream_url = 'https://radio.example.com/ls-rock'
        },
        {
            id = 'west-coast-classics',
            name = 'West Coast Classics',
            genre = 'Hip Hop',
            description = 'West Coast rap and hip hop',
            logo = '/assets/radio/wcc.jpg',
            stream_url = 'https://radio.example.com/wcc'
        },
        {
            id = 'blonded',
            name = 'Blonded Los Santos',
            genre = 'Alternative',
            description = 'Alternative and indie music',
            logo = '/assets/radio/blonded.jpg',
            stream_url = 'https://radio.example.com/blonded'
        },
        {
            id = 'flylo-fm',
            name = 'FlyLo FM',
            genre = 'Electronic',
            description = 'Electronic and experimental music',
            logo = '/assets/radio/flylo.jpg',
            stream_url = 'https://radio.example.com/flylo'
        },
        {
            id = 'worldwide-fm',
            name = 'WorldWide FM',
            genre = 'World',
            description = 'International music and culture',
            logo = '/assets/radio/worldwide.jpg',
            stream_url = 'https://radio.example.com/worldwide'
        }
    }
    
    TriggerClientEvent('phone:client:musiclyInitialized', source, {
        success = true,
        playlists = playlists or {},
        radioStations = radioStations
    })
end)

-- Search for music tracks
RegisterNetEvent('phone:server:searchMusic', function(query)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    -- Mock music database - in real implementation, this would connect to a music service API
    local mockTracks = {
        {
            id = 'track_1',
            title = 'Blinding Lights',
            artist = 'The Weeknd',
            album = 'After Hours',
            duration = 200,
            cover = '/assets/music/blinding-lights.jpg',
            stream_url = 'https://music.example.com/blinding-lights.mp3'
        },
        {
            id = 'track_2',
            title = 'Watermelon Sugar',
            artist = 'Harry Styles',
            album = 'Fine Line',
            duration = 174,
            cover = '/assets/music/watermelon-sugar.jpg',
            stream_url = 'https://music.example.com/watermelon-sugar.mp3'
        },
        {
            id = 'track_3',
            title = 'Levitating',
            artist = 'Dua Lipa',
            album = 'Future Nostalgia',
            duration = 203,
            cover = '/assets/music/levitating.jpg',
            stream_url = 'https://music.example.com/levitating.mp3'
        },
        {
            id = 'track_4',
            title = 'Good 4 U',
            artist = 'Olivia Rodrigo',
            album = 'SOUR',
            duration = 178,
            cover = '/assets/music/good-4-u.jpg',
            stream_url = 'https://music.example.com/good-4-u.mp3'
        },
        {
            id = 'track_5',
            title = 'Stay',
            artist = 'The Kid LAROI & Justin Bieber',
            album = 'F*CK LOVE 3: OVER YOU',
            duration = 141,
            cover = '/assets/music/stay.jpg',
            stream_url = 'https://music.example.com/stay.mp3'
        }
    }
    
    -- Filter tracks based on search query
    local results = {}
    local lowerQuery = string.lower(query)
    
    for _, track in ipairs(mockTracks) do
        if string.find(string.lower(track.title), lowerQuery) or 
           string.find(string.lower(track.artist), lowerQuery) or
           string.find(string.lower(track.album), lowerQuery) then
            table.insert(results, track)
        end
    end
    
    TriggerClientEvent('phone:client:musicSearchResults', source, results)
end)

-- Browse music by category
RegisterNetEvent('phone:server:browseMusicCategory', function(categoryId)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    -- Mock category tracks
    local categoryTracks = {
        pop = {
            {
                id = 'pop_1',
                title = 'As It Was',
                artist = 'Harry Styles',
                album = 'Harry\'s House',
                duration = 167,
                cover = '/assets/music/as-it-was.jpg',
                stream_url = 'https://music.example.com/as-it-was.mp3'
            },
            {
                id = 'pop_2',
                title = 'Anti-Hero',
                artist = 'Taylor Swift',
                album = 'Midnights',
                duration = 200,
                cover = '/assets/music/anti-hero.jpg',
                stream_url = 'https://music.example.com/anti-hero.mp3'
            }
        },
        rock = {
            {
                id = 'rock_1',
                title = 'Enemy',
                artist = 'Imagine Dragons',
                album = 'Mercury - Acts 1 & 2',
                duration = 174,
                cover = '/assets/music/enemy.jpg',
                stream_url = 'https://music.example.com/enemy.mp3'
            },
            {
                id = 'rock_2',
                title = 'Shivers',
                artist = 'Ed Sheeran',
                album = '=',
                duration = 207,
                cover = '/assets/music/shivers.jpg',
                stream_url = 'https://music.example.com/shivers.mp3'
            }
        },
        ['hip-hop'] = {
            {
                id = 'hiphop_1',
                title = 'Industry Baby',
                artist = 'Lil Nas X & Jack Harlow',
                album = 'MONTERO',
                duration = 212,
                cover = '/assets/music/industry-baby.jpg',
                stream_url = 'https://music.example.com/industry-baby.mp3'
            },
            {
                id = 'hiphop_2',
                title = 'Heat Waves',
                artist = 'Glass Animals',
                album = 'Dreamland',
                duration = 238,
                cover = '/assets/music/heat-waves.jpg',
                stream_url = 'https://music.example.com/heat-waves.mp3'
            }
        }
    }
    
    local tracks = categoryTracks[categoryId] or {}
    TriggerClientEvent('phone:client:musicCategoryResults', source, tracks)
end)

-- Create new playlist
RegisterNetEvent('phone:server:createPlaylist', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:playlistCreated', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    local playlistName = data.name
    if not playlistName or string.len(playlistName) < 1 then
        TriggerClientEvent('phone:client:playlistCreated', source, {
            success = false,
            message = 'Playlist name is required'
        })
        return
    end
    
    -- Check if playlist name already exists for this user
    local existingPlaylist = MySQL.query.await([[
        SELECT id FROM phone_musicly_playlists 
        WHERE phone_number = ? AND name = ?
    ]], { phoneNumber, playlistName })
    
    if existingPlaylist and #existingPlaylist > 0 then
        TriggerClientEvent('phone:client:playlistCreated', source, {
            success = false,
            message = 'Playlist name already exists'
        })
        return
    end
    
    -- Create playlist
    local playlistId = MySQL.insert.await([[
        INSERT INTO phone_musicly_playlists (phone_number, name, cover)
        VALUES (?, ?, ?)
    ]], { phoneNumber, playlistName, data.cover or '/assets/default-playlist.jpg' })
    
    if playlistId then
        TriggerClientEvent('phone:client:playlistCreated', source, {
            success = true,
            playlist = {
                id = playlistId,
                name = playlistName,
                cover = data.cover or '/assets/default-playlist.jpg',
                tracks = {}
            }
        })
    else
        TriggerClientEvent('phone:client:playlistCreated', source, {
            success = false,
            message = 'Failed to create playlist'
        })
    end
end)

-- Add track to playlist
RegisterNetEvent('phone:server:addTrackToPlaylist', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    local playlistId = data.playlistId
    local track = data.track
    
    -- Verify playlist ownership
    local playlist = MySQL.query.await([[
        SELECT id FROM phone_musicly_playlists 
        WHERE id = ? AND phone_number = ?
    ]], { playlistId, phoneNumber })
    
    if not playlist or #playlist == 0 then
        TriggerClientEvent('phone:client:trackAddedToPlaylist', source, {
            success = false,
            message = 'Playlist not found'
        })
        return
    end
    
    -- Check if track already exists in playlist
    local existingTrack = MySQL.query.await([[
        SELECT id FROM phone_musicly_playlist_tracks 
        WHERE playlist_id = ? AND track_id = ?
    ]], { playlistId, track.id })
    
    if existingTrack and #existingTrack > 0 then
        TriggerClientEvent('phone:client:trackAddedToPlaylist', source, {
            success = false,
            message = 'Track already in playlist'
        })
        return
    end
    
    -- Add track to playlist
    local success = MySQL.insert.await([[
        INSERT INTO phone_musicly_playlist_tracks 
        (playlist_id, track_id, track_title, track_artist, track_album, track_duration, track_cover, track_stream_url)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], { 
        playlistId, 
        track.id, 
        track.title, 
        track.artist, 
        track.album, 
        track.duration, 
        track.cover, 
        track.stream_url 
    })
    
    if success then
        TriggerClientEvent('phone:client:trackAddedToPlaylist', source, {
            success = true,
            message = 'Track added to playlist'
        })
    else
        TriggerClientEvent('phone:client:trackAddedToPlaylist', source, {
            success = false,
            message = 'Failed to add track'
        })
    end
end)

-- Get playlist tracks
RegisterNetEvent('phone:server:getPlaylistTracks', function(playlistId)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    -- Verify playlist ownership
    local playlist = MySQL.query.await([[
        SELECT id, name FROM phone_musicly_playlists 
        WHERE id = ? AND phone_number = ?
    ]], { playlistId, phoneNumber })
    
    if not playlist or #playlist == 0 then
        TriggerClientEvent('phone:client:playlistTracks', source, {
            success = false,
            message = 'Playlist not found'
        })
        return
    end
    
    -- Get tracks
    local tracks = MySQL.query.await([[
        SELECT 
            track_id as id,
            track_title as title,
            track_artist as artist,
            track_album as album,
            track_duration as duration,
            track_cover as cover,
            track_stream_url as stream_url
        FROM phone_musicly_playlist_tracks
        WHERE playlist_id = ?
        ORDER BY created_at ASC
    ]], { playlistId })
    
    TriggerClientEvent('phone:client:playlistTracks', source, {
        success = true,
        playlist = playlist[1],
        tracks = tracks or {}
    })
end)

-- Play track (log for analytics)
RegisterNetEvent('phone:server:playTrack', function(track)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    -- Log play history for analytics
    MySQL.insert([[
        INSERT INTO phone_musicly_play_history (phone_number, track_id, track_title, track_artist)
        VALUES (?, ?, ?, ?)
    ]], { phoneNumber, track.id, track.title, track.artist })
    
    -- Trigger client-side audio playback
    TriggerClientEvent('phone:client:startTrackPlayback', source, track)
end)

-- Play radio station
RegisterNetEvent('phone:server:playRadioStation', function(station)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    -- Log radio listening for analytics
    MySQL.insert([[
        INSERT INTO phone_musicly_radio_history (phone_number, station_id, station_name)
        VALUES (?, ?, ?)
    ]], { phoneNumber, station.id, station.name })
    
    -- Trigger client-side radio playback
    TriggerClientEvent('phone:client:startRadioPlayback', source, station)
end)

-- Delete playlist
RegisterNetEvent('phone:server:deletePlaylist', function(playlistId)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    -- Verify playlist ownership
    local playlist = MySQL.query.await([[
        SELECT id FROM phone_musicly_playlists 
        WHERE id = ? AND phone_number = ?
    ]], { playlistId, phoneNumber })
    
    if not playlist or #playlist == 0 then
        TriggerClientEvent('phone:client:playlistDeleted', source, {
            success = false,
            message = 'Playlist not found'
        })
        return
    end
    
    -- Delete playlist tracks first
    MySQL.query.await('DELETE FROM phone_musicly_playlist_tracks WHERE playlist_id = ?', { playlistId })
    
    -- Delete playlist
    local success = MySQL.query.await('DELETE FROM phone_musicly_playlists WHERE id = ?', { playlistId })
    
    TriggerClientEvent('phone:client:playlistDeleted', source, {
        success = success and true or false,
        playlistId = playlistId
    })
end)

-- Get user's music statistics
RegisterNetEvent('phone:server:getMusicStats', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    -- Get play statistics
    local stats = MySQL.query.await([[
        SELECT 
            COUNT(*) as total_plays,
            COUNT(DISTINCT track_id) as unique_tracks,
            track_artist as top_artist,
            COUNT(*) as artist_plays
        FROM phone_musicly_play_history 
        WHERE phone_number = ?
        GROUP BY track_artist
        ORDER BY artist_plays DESC
        LIMIT 1
    ]], { phoneNumber })
    
    local playlistCount = MySQL.query.await([[
        SELECT COUNT(*) as count FROM phone_musicly_playlists WHERE phone_number = ?
    ]], { phoneNumber })
    
    TriggerClientEvent('phone:client:musicStats', source, {
        success = true,
        stats = {
            totalPlays = stats[1] and stats[1].total_plays or 0,
            uniqueTracks = stats[1] and stats[1].unique_tracks or 0,
            topArtist = stats[1] and stats[1].top_artist or 'None',
            playlistCount = playlistCount[1] and playlistCount[1].count or 0
        }
    })
end)