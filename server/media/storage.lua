-- Media Storage Module
-- Handles file upload, storage, compression, and CDN integration

local Storage = {}

-- Initialize storage directories
function Storage.Initialize()
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local mediaPath = resourcePath .. '/media'
    
    -- Create media directories if they don't exist
    os.execute('mkdir "' .. mediaPath .. '" 2>nul')
    os.execute('mkdir "' .. mediaPath .. '/photos" 2>nul')
    os.execute('mkdir "' .. mediaPath .. '/videos" 2>nul')
    os.execute('mkdir "' .. mediaPath .. '/audio" 2>nul')
    os.execute('mkdir "' .. mediaPath .. '/thumbnails" 2>nul')
    
    if Config.Debug then
        print('[Phone] Media storage initialized at: ' .. mediaPath)
    end
end

-- Validate file size
function Storage.ValidateFileSize(fileSize, mediaType)
    local maxSize = 0
    
    if mediaType == 'photo' then
        maxSize = Config.MaxPhotoSize or (5 * 1024 * 1024) -- 5MB default
    elseif mediaType == 'video' then
        maxSize = Config.MaxVideoSize or (50 * 1024 * 1024) -- 50MB default
    elseif mediaType == 'audio' then
        maxSize = Config.MaxAudioSize or (10 * 1024 * 1024) -- 10MB default
    end
    
    return fileSize <= maxSize
end

-- Check player storage quota
function Storage.CheckQuota(phoneNumber, additionalSize)
    local quota = Config.StorageQuotaPerPlayer or (500 * 1024 * 1024) -- 500MB default
    
    -- Get current storage usage
    local result = MySQL.query.await('SELECT SUM(file_size) as total_size FROM phone_media WHERE owner_number = ?', {
        phoneNumber
    })
    
    local currentSize = 0
    if result and result[1] and result[1].total_size then
        currentSize = result[1].total_size
    end
    
    return (currentSize + additionalSize) <= quota, currentSize, quota
end

-- Generate unique filename
function Storage.GenerateFilename(phoneNumber, extension)
    local timestamp = os.time()
    local random = math.random(1000, 9999)
    return phoneNumber:gsub('-', '') .. '_' .. timestamp .. '_' .. random .. '.' .. extension
end

-- Decode base64 string
function Storage.DecodeBase64(base64String)
    -- Remove data URL prefix if present
    local data = base64String:match('base64,(.+)') or base64String
    
    -- FiveM doesn't have built-in base64 decode, so we'll use a workaround
    -- In production, you'd want to use a proper base64 library
    return data
end

-- Save file to local storage
function Storage.SaveToLocal(filename, data, mediaType)
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local subdir = 'photos'
    
    if mediaType == 'video' then
        subdir = 'videos'
    elseif mediaType == 'audio' then
        subdir = 'audio'
    end
    
    local filePath = resourcePath .. '/media/' .. subdir .. '/' .. filename
    
    -- Write file (this is a simplified version - in production use proper file I/O)
    SaveResourceFile(GetCurrentResourceName(), 'media/' .. subdir .. '/' .. filename, data, -1)
    
    -- Return the URL path
    return 'nui://phone/media/' .. subdir .. '/' .. filename
end

-- Upload to CDN
function Storage.UploadToCDN(filename, data, mediaType)
    if not Config.MediaStorage or Config.MediaStorage ~= 'cdn' then
        return nil, 'CDN not configured'
    end
    
    local cdnConfig = Config.CDNConfig or {}
    local provider = cdnConfig.provider or 's3'
    
    if provider == 's3' then
        return Storage.UploadToS3(filename, data, cdnConfig)
    elseif provider == 'r2' then
        return Storage.UploadToR2(filename, data, cdnConfig)
    elseif provider == 'custom' then
        return Storage.UploadToCustomCDN(filename, data, cdnConfig)
    end
    
    return nil, 'Unknown CDN provider'
end

-- Upload to AWS S3
function Storage.UploadToS3(filename, data, config)
    -- This is a placeholder - actual implementation would use HTTP requests
    -- to AWS S3 API with proper authentication
    
    if Config.Debug then
        print('[Phone] S3 upload not implemented - using local storage')
    end
    
    return nil, 'S3 upload not implemented'
end

-- Upload to Cloudflare R2
function Storage.UploadToR2(filename, data, config)
    -- This is a placeholder - actual implementation would use HTTP requests
    -- to Cloudflare R2 API with proper authentication
    
    if Config.Debug then
        print('[Phone] R2 upload not implemented - using local storage')
    end
    
    return nil, 'R2 upload not implemented'
end

-- Upload to custom CDN
function Storage.UploadToCustomCDN(filename, data, config)
    -- This is a placeholder for custom CDN implementations
    
    if Config.Debug then
        print('[Phone] Custom CDN upload not implemented - using local storage')
    end
    
    return nil, 'Custom CDN upload not implemented'
end

-- Generate thumbnail for image
function Storage.GenerateThumbnail(sourceFile, mediaType)
    if not Config.GenerateThumbnails then
        return nil
    end
    
    -- This is a placeholder - actual implementation would use image processing
    -- library or external service to generate thumbnails
    -- For FiveM, you might need to use an external service or pre-generate thumbnails client-side
    
    if Config.Debug then
        print('[Phone] Thumbnail generation not implemented')
    end
    
    return nil
end

-- Compress image
function Storage.CompressImage(data, quality)
    quality = quality or Config.ImageQuality or 80
    
    -- This is a placeholder - actual implementation would use image processing
    -- library to compress images
    
    if Config.Debug then
        print('[Phone] Image compression not implemented')
    end
    
    return data
end

-- Handle file upload (main entry point)
function Storage.HandleUpload(phoneNumber, data, mediaType, metadata)
    -- Validate inputs
    if not phoneNumber or not data or not mediaType then
        return {
            success = false,
            error = 'INVALID_PARAMETERS',
            message = 'Missing required parameters'
        }
    end
    
    -- Decode base64 data
    local fileData = Storage.DecodeBase64(data)
    local fileSize = #fileData
    
    -- Validate file size
    if not Storage.ValidateFileSize(fileSize, mediaType) then
        return {
            success = false,
            error = 'MEDIA_TOO_LARGE',
            message = 'File size exceeds limit'
        }
    end
    
    -- Check storage quota
    local quotaOk, currentSize, maxQuota = Storage.CheckQuota(phoneNumber, fileSize)
    if not quotaOk then
        return {
            success = false,
            error = 'STORAGE_FULL',
            message = 'Storage quota exceeded',
            details = {
                current = currentSize,
                max = maxQuota,
                required = fileSize
            }
        }
    end
    
    -- Generate filename
    local extension = 'jpg'
    if mediaType == 'video' then
        extension = 'mp4'
    elseif mediaType == 'audio' then
        extension = 'mp3'
    end
    local filename = Storage.GenerateFilename(phoneNumber, extension)
    
    -- Compress image if applicable
    if mediaType == 'photo' and Config.OptimizeImages then
        fileData = Storage.CompressImage(fileData)
        fileSize = #fileData
    end
    
    -- Save file
    local fileUrl, uploadError
    if Config.MediaStorage == 'cdn' then
        fileUrl, uploadError = Storage.UploadToCDN(filename, fileData, mediaType)
        -- Fallback to local if CDN fails
        if not fileUrl then
            if Config.Debug then
                print('[Phone] CDN upload failed, falling back to local: ' .. (uploadError or 'unknown error'))
            end
            fileUrl = Storage.SaveToLocal(filename, fileData, mediaType)
        end
    else
        fileUrl = Storage.SaveToLocal(filename, fileData, mediaType)
    end
    
    if not fileUrl then
        return {
            success = false,
            error = 'STORAGE_ERROR',
            message = 'Failed to save file'
        }
    end
    
    -- Generate thumbnail
    local thumbnailUrl = nil
    if Config.GenerateThumbnails and (mediaType == 'photo' or mediaType == 'video') then
        thumbnailUrl = Storage.GenerateThumbnail(fileUrl, mediaType)
    end
    
    -- Prepare metadata
    local metadataJson = json.encode(metadata or {})
    
    -- Save to database
    local mediaId = MySQL.insert.await([[
        INSERT INTO phone_media (owner_number, media_type, file_url, thumbnail_url, duration, file_size, location_x, location_y, metadata_json)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        phoneNumber,
        mediaType,
        fileUrl,
        thumbnailUrl,
        metadata and metadata.duration or 0,
        fileSize,
        metadata and metadata.location_x or nil,
        metadata and metadata.location_y or nil,
        metadataJson
    })
    
    if not mediaId then
        return {
            success = false,
            error = 'DATABASE_ERROR',
            message = 'Failed to save media record'
        }
    end
    
    return {
        success = true,
        data = {
            id = mediaId,
            url = fileUrl,
            thumbnail_url = thumbnailUrl,
            file_size = fileSize,
            media_type = mediaType
        }
    }
end

-- Get player media
function Storage.GetPlayerMedia(phoneNumber, mediaType, limit, offset)
    limit = limit or 20
    offset = offset or 0
    
    local query = [[
        SELECT id, media_type, file_url, thumbnail_url, duration, file_size, 
               location_x, location_y, metadata_json, created_at
        FROM phone_media
        WHERE owner_number = ?
    ]]
    
    local params = {phoneNumber}
    
    if mediaType then
        query = query .. ' AND media_type = ?'
        table.insert(params, mediaType)
    end
    
    query = query .. ' ORDER BY created_at DESC LIMIT ? OFFSET ?'
    table.insert(params, limit)
    table.insert(params, offset)
    
    local result = MySQL.query.await(query, params)
    
    return result or {}
end

-- Delete media file
function Storage.DeleteMedia(mediaId, phoneNumber)
    -- Get media info
    local media = MySQL.query.await('SELECT * FROM phone_media WHERE id = ? AND owner_number = ?', {
        mediaId, phoneNumber
    })
    
    if not media or #media == 0 then
        return {
            success = false,
            error = 'NOT_FOUND',
            message = 'Media not found'
        }
    end
    
    local mediaData = media[1]
    
    -- Delete file from storage
    if Config.MediaStorage == 'local' or not Config.MediaStorage then
        -- Extract filename from URL
        local filename = mediaData.file_url:match('[^/]+$')
        if filename then
            local subdir = 'photos'
            if mediaData.media_type == 'video' then
                subdir = 'videos'
            elseif mediaData.media_type == 'audio' then
                subdir = 'audio'
            end
            
            -- Delete file (simplified - in production use proper file deletion)
            local resourcePath = GetResourcePath(GetCurrentResourceName())
            local filePath = resourcePath .. '/media/' .. subdir .. '/' .. filename
            os.remove(filePath)
        end
    else
        -- Delete from CDN (placeholder)
        if Config.Debug then
            print('[Phone] CDN file deletion not implemented')
        end
    end
    
    -- Delete from database
    MySQL.query.await('DELETE FROM phone_media WHERE id = ?', {mediaId})
    
    -- Delete from albums
    MySQL.query.await('DELETE FROM phone_album_media WHERE media_id = ?', {mediaId})
    
    return {
        success = true,
        message = 'Media deleted successfully'
    }
end

-- Get storage usage for player
function Storage.GetStorageUsage(phoneNumber)
    local result = MySQL.query.await([[
        SELECT 
            COUNT(*) as total_files,
            SUM(file_size) as total_size,
            SUM(CASE WHEN media_type = 'photo' THEN 1 ELSE 0 END) as photo_count,
            SUM(CASE WHEN media_type = 'video' THEN 1 ELSE 0 END) as video_count,
            SUM(CASE WHEN media_type = 'audio' THEN 1 ELSE 0 END) as audio_count
        FROM phone_media
        WHERE owner_number = ?
    ]], {phoneNumber})
    
    if result and result[1] then
        local usage = result[1]
        local quota = Config.StorageQuotaPerPlayer or (500 * 1024 * 1024)
        
        return {
            success = true,
            data = {
                total_files = usage.total_files or 0,
                total_size = usage.total_size or 0,
                photo_count = usage.photo_count or 0,
                video_count = usage.video_count or 0,
                audio_count = usage.audio_count or 0,
                quota = quota,
                percentage = ((usage.total_size or 0) / quota) * 100
            }
        }
    end
    
    return {
        success = false,
        error = 'DATABASE_ERROR',
        message = 'Failed to get storage usage'
    }
end

-- Bulk delete media
function Storage.BulkDeleteMedia(phoneNumber, mediaIds)
    if not phoneNumber or not mediaIds or type(mediaIds) ~= 'table' or #mediaIds == 0 then
        return {
            success = false,
            error = 'INVALID_PARAMETERS',
            message = 'Invalid parameters for bulk delete'
        }
    end
    
    local deleted = 0
    local errors = {}
    
    for _, mediaId in ipairs(mediaIds) do
        local result = Storage.DeleteMedia(mediaId, phoneNumber)
        if result.success then
            deleted = deleted + 1
        else
            table.insert(errors, {
                mediaId = mediaId,
                error = result.error,
                message = result.message
            })
        end
    end
    
    return {
        success = deleted > 0,
        message = string.format('Deleted %d of %d media items', deleted, #mediaIds),
        data = {
            deleted_count = deleted,
            total_count = #mediaIds,
            errors = errors
        }
    }
end

-- Cleanup old media (for maintenance)
function Storage.CleanupOldMedia(days)
    days = days or 90
    
    -- Get old media files first for file deletion
    local oldMedia = MySQL.query.await([[
        SELECT id, owner_number, file_url, media_type
        FROM phone_media
        WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
    ]], {days})
    
    if oldMedia and #oldMedia > 0 then
        -- Delete files
        for _, media in ipairs(oldMedia) do
            if Config.MediaStorage == 'local' or not Config.MediaStorage then
                local filename = media.file_url:match('[^/]+$')
                if filename then
                    local subdir = 'photos'
                    if media.media_type == 'video' then
                        subdir = 'videos'
                    elseif media.media_type == 'audio' then
                        subdir = 'audio'
                    end
                    
                    local resourcePath = GetResourcePath(GetCurrentResourceName())
                    local filePath = resourcePath .. '/media/' .. subdir .. '/' .. filename
                    os.remove(filePath)
                end
            end
        end
        
        -- Delete from database
        MySQL.query.await([[
            DELETE FROM phone_media
            WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
        ]], {days})
        
        if Config.Debug then
            print(string.format('[Phone] Cleaned up %d media items older than %d days', #oldMedia, days))
        end
        
        return {
            success = true,
            deleted_count = #oldMedia
        }
    end
    
    return {
        success = true,
        deleted_count = 0
    }
end

-- Cleanup orphaned media (media not in any album and older than X days)
function Storage.CleanupOrphanedMedia(days)
    days = days or 30
    
    local orphaned = MySQL.query.await([[
        SELECT m.id, m.owner_number, m.file_url, m.media_type
        FROM phone_media m
        LEFT JOIN phone_album_media am ON m.id = am.media_id
        WHERE am.media_id IS NULL
        AND m.created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
    ]], {days})
    
    if orphaned and #orphaned > 0 then
        local mediaIds = {}
        for _, media in ipairs(orphaned) do
            table.insert(mediaIds, media.id)
        end
        
        -- Use bulk delete
        local result = Storage.BulkDeleteMedia(orphaned[1].owner_number, mediaIds)
        
        if Config.Debug then
            print(string.format('[Phone] Cleaned up %d orphaned media items', result.data.deleted_count))
        end
        
        return result
    end
    
    return {
        success = true,
        deleted_count = 0
    }
end

return Storage
