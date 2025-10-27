-- Album Management Module
-- Handles album CRUD operations and media associations

local Albums = {}

-- Create a new album
function Albums.CreateAlbum(phoneNumber, albumName, coverMediaId)
    if not phoneNumber or not albumName then
        return {
            success = false,
            error = 'INVALID_PARAMETERS',
            message = 'Missing required parameters'
        }
    end
    
    -- Validate album name length
    if #albumName > 100 then
        return {
            success = false,
            error = 'NAME_TOO_LONG',
            message = 'Album name must be 100 characters or less'
        }
    end
    
    -- Insert album
    local albumId = MySQL.insert.await([[
        INSERT INTO phone_albums (owner_number, album_name, cover_media_id)
        VALUES (?, ?, ?)
    ]], {
        phoneNumber,
        albumName,
        coverMediaId
    })
    
    if not albumId then
        return {
            success = false,
            error = 'DATABASE_ERROR',
            message = 'Failed to create album'
        }
    end
    
    return {
        success = true,
        data = {
            id = albumId,
            owner_number = phoneNumber,
            album_name = albumName,
            cover_media_id = coverMediaId,
            media_count = 0
        }
    }
end

-- Get all albums for a player
function Albums.GetPlayerAlbums(phoneNumber)
    local result = MySQL.query.await([[
        SELECT 
            a.id,
            a.owner_number,
            a.album_name,
            a.cover_media_id,
            a.created_at,
            COUNT(am.media_id) as media_count
        FROM phone_albums a
        LEFT JOIN phone_album_media am ON a.id = am.album_id
        WHERE a.owner_number = ?
        GROUP BY a.id
        ORDER BY a.created_at DESC
    ]], {phoneNumber})
    
    return result or {}
end

-- Get a specific album
function Albums.GetAlbum(albumId, phoneNumber)
    local result = MySQL.query.await([[
        SELECT 
            a.id,
            a.owner_number,
            a.album_name,
            a.cover_media_id,
            a.created_at,
            COUNT(am.media_id) as media_count
        FROM phone_albums a
        LEFT JOIN phone_album_media am ON a.id = am.album_id
        WHERE a.id = ? AND a.owner_number = ?
        GROUP BY a.id
    ]], {albumId, phoneNumber})
    
    if result and #result > 0 then
        return {
            success = true,
            data = result[1]
        }
    end
    
    return {
        success = false,
        error = 'NOT_FOUND',
        message = 'Album not found'
    }
end

-- Update album
function Albums.UpdateAlbum(albumId, phoneNumber, updates)
    if not albumId or not phoneNumber or not updates then
        return {
            success = false,
            error = 'INVALID_PARAMETERS',
            message = 'Missing required parameters'
        }
    end
    
    -- Verify ownership
    local album = MySQL.query.await('SELECT id FROM phone_albums WHERE id = ? AND owner_number = ?', {
        albumId, phoneNumber
    })
    
    if not album or #album == 0 then
        return {
            success = false,
            error = 'NOT_FOUND',
            message = 'Album not found or access denied'
        }
    end
    
    -- Build update query
    local fields = {}
    local values = {}
    
    if updates.album_name then
        if #updates.album_name > 100 then
            return {
                success = false,
                error = 'NAME_TOO_LONG',
                message = 'Album name must be 100 characters or less'
            }
        end
        table.insert(fields, 'album_name = ?')
        table.insert(values, updates.album_name)
    end
    
    if updates.cover_media_id ~= nil then
        table.insert(fields, 'cover_media_id = ?')
        table.insert(values, updates.cover_media_id)
    end
    
    if #fields == 0 then
        return {
            success = false,
            error = 'NO_UPDATES',
            message = 'No valid updates provided'
        }
    end
    
    table.insert(values, albumId)
    
    local query = 'UPDATE phone_albums SET ' .. table.concat(fields, ', ') .. ' WHERE id = ?'
    MySQL.query.await(query, values)
    
    return {
        success = true,
        message = 'Album updated successfully'
    }
end

-- Delete album
function Albums.DeleteAlbum(albumId, phoneNumber)
    if not albumId or not phoneNumber then
        return {
            success = false,
            error = 'INVALID_PARAMETERS',
            message = 'Missing required parameters'
        }
    end
    
    -- Verify ownership
    local album = MySQL.query.await('SELECT id FROM phone_albums WHERE id = ? AND owner_number = ?', {
        albumId, phoneNumber
    })
    
    if not album or #album == 0 then
        return {
            success = false,
            error = 'NOT_FOUND',
            message = 'Album not found or access denied'
        }
    end
    
    -- Delete album (cascade will handle album_media entries)
    MySQL.query.await('DELETE FROM phone_albums WHERE id = ?', {albumId})
    
    return {
        success = true,
        message = 'Album deleted successfully'
    }
end

-- Add media to album
function Albums.AddMediaToAlbum(albumId, phoneNumber, mediaIds)
    if not albumId or not phoneNumber or not mediaIds or type(mediaIds) ~= 'table' then
        return {
            success = false,
            error = 'INVALID_PARAMETERS',
            message = 'Missing or invalid parameters'
        }
    end
    
    -- Verify album ownership
    local album = MySQL.query.await('SELECT id FROM phone_albums WHERE id = ? AND owner_number = ?', {
        albumId, phoneNumber
    })
    
    if not album or #album == 0 then
        return {
            success = false,
            error = 'NOT_FOUND',
            message = 'Album not found or access denied'
        }
    end
    
    -- Verify media ownership and add to album
    local added = 0
    for _, mediaId in ipairs(mediaIds) do
        -- Check if media belongs to player
        local media = MySQL.query.await('SELECT id FROM phone_media WHERE id = ? AND owner_number = ?', {
            mediaId, phoneNumber
        })
        
        if media and #media > 0 then
            -- Check if already in album
            local existing = MySQL.query.await([[
                SELECT album_id FROM phone_album_media 
                WHERE album_id = ? AND media_id = ?
            ]], {albumId, mediaId})
            
            if not existing or #existing == 0 then
                -- Add to album
                MySQL.insert.await([[
                    INSERT INTO phone_album_media (album_id, media_id)
                    VALUES (?, ?)
                ]], {albumId, mediaId})
                added = added + 1
            end
        end
    end
    
    return {
        success = true,
        message = added .. ' media item(s) added to album',
        data = {
            added_count = added
        }
    }
end

-- Remove media from album
function Albums.RemoveMediaFromAlbum(albumId, phoneNumber, mediaIds)
    if not albumId or not phoneNumber or not mediaIds or type(mediaIds) ~= 'table' then
        return {
            success = false,
            error = 'INVALID_PARAMETERS',
            message = 'Missing or invalid parameters'
        }
    end
    
    -- Verify album ownership
    local album = MySQL.query.await('SELECT id FROM phone_albums WHERE id = ? AND owner_number = ?', {
        albumId, phoneNumber
    })
    
    if not album or #album == 0 then
        return {
            success = false,
            error = 'NOT_FOUND',
            message = 'Album not found or access denied'
        }
    end
    
    -- Remove media from album
    local removed = 0
    for _, mediaId in ipairs(mediaIds) do
        local result = MySQL.query.await([[
            DELETE FROM phone_album_media 
            WHERE album_id = ? AND media_id = ?
        ]], {albumId, mediaId})
        
        if result then
            removed = removed + 1
        end
    end
    
    return {
        success = true,
        message = removed .. ' media item(s) removed from album',
        data = {
            removed_count = removed
        }
    }
end

-- Get media in an album
function Albums.GetAlbumMedia(albumId, phoneNumber, limit, offset)
    limit = limit or 20
    offset = offset or 0
    
    -- Verify album ownership
    local album = MySQL.query.await('SELECT id FROM phone_albums WHERE id = ? AND owner_number = ?', {
        albumId, phoneNumber
    })
    
    if not album or #album == 0 then
        return {
            success = false,
            error = 'NOT_FOUND',
            message = 'Album not found or access denied'
        }
    end
    
    -- Get media in album
    local result = MySQL.query.await([[
        SELECT 
            m.id,
            m.media_type,
            m.file_url,
            m.thumbnail_url,
            m.duration,
            m.file_size,
            m.location_x,
            m.location_y,
            m.metadata_json,
            m.created_at,
            am.added_at
        FROM phone_media m
        INNER JOIN phone_album_media am ON m.id = am.media_id
        WHERE am.album_id = ?
        ORDER BY am.added_at DESC
        LIMIT ? OFFSET ?
    ]], {albumId, limit, offset})
    
    return {
        success = true,
        data = result or {}
    }
end

-- Set album cover
function Albums.SetAlbumCover(albumId, phoneNumber, mediaId)
    if not albumId or not phoneNumber then
        return {
            success = false,
            error = 'INVALID_PARAMETERS',
            message = 'Missing required parameters'
        }
    end
    
    -- Verify album ownership
    local album = MySQL.query.await('SELECT id FROM phone_albums WHERE id = ? AND owner_number = ?', {
        albumId, phoneNumber
    })
    
    if not album or #album == 0 then
        return {
            success = false,
            error = 'NOT_FOUND',
            message = 'Album not found or access denied'
        }
    end
    
    -- If mediaId provided, verify it's in the album
    if mediaId then
        local inAlbum = MySQL.query.await([[
            SELECT media_id FROM phone_album_media 
            WHERE album_id = ? AND media_id = ?
        ]], {albumId, mediaId})
        
        if not inAlbum or #inAlbum == 0 then
            return {
                success = false,
                error = 'MEDIA_NOT_IN_ALBUM',
                message = 'Media not found in album'
            }
        end
    end
    
    -- Update album cover
    MySQL.query.await('UPDATE phone_albums SET cover_media_id = ? WHERE id = ?', {
        mediaId, albumId
    })
    
    return {
        success = true,
        message = 'Album cover updated successfully'
    }
end

return Albums
