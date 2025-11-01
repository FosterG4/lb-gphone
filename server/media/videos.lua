-- Video Operations Module
-- Handles video-specific operations

local Storage = lib.require('server.media.storage')

local Videos = {}

-- Upload video
RegisterNetEvent('phone:server:uploadVideo', function(data, metadata)
    local src = source
    local phoneNumber = exports['phone']:GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:notify', src, {
            type = 'error',
            message = 'Phone number not found'
        })
        return
    end
    
    -- Validate video duration
    local maxDuration = Config.MaxVideoLength or 60
    if metadata and metadata.duration and metadata.duration > maxDuration then
        TriggerClientEvent('phone:client:notify', src, {
            type = 'error',
            message = 'Video too long (max ' .. maxDuration .. ' seconds)'
        })
        return
    end
    
    if Config.DebugMode then
        print('[Phone] Uploading video for ' .. phoneNumber .. ' - Duration: ' .. (metadata.duration or 0) .. 's')
    end
    
    -- Handle upload
    local result = Storage.HandleUpload(phoneNumber, data, 'video', metadata)
    
    if result.success then
        -- Generate thumbnail for video
        if Config.GenerateThumbnails and result.data.url then
            CreateThread(function()
                -- In production, this would extract a frame from the video
                -- and create a thumbnail image
                -- For now, we'll use a placeholder
                local thumbnailUrl = result.data.thumbnail_url or result.data.url
                
                -- Update database with thumbnail
                if thumbnailUrl and result.data.id then
                    MySQL.execute.await(
                        'UPDATE phone_media SET thumbnail_url = ? WHERE id = ?',
                        {thumbnailUrl, result.data.id}
                    )
                end
                
                if Config.DebugMode then
                    print('[Phone] Thumbnail generated for video ID: ' .. result.data.id)
                end
            end)
        end
        
        -- Notify client
        TriggerClientEvent('phone:client:videoUploaded', src, result.data)
        
        -- Update client media list
        local media = Storage.GetPlayerMedia(phoneNumber, 'video', 20, 0)
        TriggerClientEvent('phone:client:updateMedia', src, media)
        
        if Config.DebugMode then
            print('[Phone] Video uploaded successfully - ID: ' .. result.data.id)
        end
    else
        TriggerClientEvent('phone:client:notify', src, {
            type = 'error',
            message = result.message or 'Failed to upload video'
        })
        
        if Config.DebugMode then
            print('[Phone] Video upload failed: ' .. (result.message or 'Unknown error'))
        end
    end
end)

-- Get videos
RegisterNetEvent('phone:server:getVideos', function(data)
    local src = source
    local phoneNumber = exports['phone']:GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveVideos', src, {
            success = false,
            error = 'Phone number not found'
        })
        return
    end
    
    local limit = (data and data.limit) or 20
    local offset = (data and data.offset) or 0
    
    local videos = Storage.GetPlayerMedia(phoneNumber, 'video', limit, offset)
    
    -- Parse metadata JSON for each video
    for _, video in ipairs(videos) do
        if video.metadata_json then
            local success, metadata = pcall(json.decode, video.metadata_json)
            if success then
                video.metadata = metadata
            end
        end
    end
    
    TriggerClientEvent('phone:client:receiveVideos', src, {
        success = true,
        data = videos
    })
    
    if Config.DebugMode then
        print('[Phone] Sent ' .. #videos .. ' videos to player ' .. src)
    end
end)

-- Delete video
RegisterNetEvent('phone:server:deleteVideo', function(data)
    local src = source
    local phoneNumber = exports['phone']:GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:videoDeleted', src, {
            success = false,
            error = 'Phone number not found'
        })
        return
    end
    
    local mediaId = data.mediaId or data
    
    if not mediaId then
        TriggerClientEvent('phone:client:videoDeleted', src, {
            success = false,
            error = 'Media ID is required'
        })
        return
    end
    
    if Config.DebugMode then
        print('[Phone] Deleting video ID: ' .. mediaId .. ' for ' .. phoneNumber)
    end
    
    local result = Storage.DeleteMedia(mediaId, phoneNumber)
    
    if result.success then
        TriggerClientEvent('phone:client:videoDeleted', src, {
            success = true,
            mediaId = mediaId
        })
        TriggerClientEvent('phone:client:notify', src, {
            type = 'success',
            message = 'Video deleted'
        })
        
        if Config.DebugMode then
            print('[Phone] Video deleted successfully')
        end
    else
        TriggerClientEvent('phone:client:videoDeleted', src, {
            success = false,
            error = result.message or 'Failed to delete video'
        })
        TriggerClientEvent('phone:client:notify', src, {
            type = 'error',
            message = result.message or 'Failed to delete video'
        })
        
        if Config.DebugMode then
            print('[Phone] Video deletion failed: ' .. (result.message or 'Unknown error'))
        end
    end
end)

-- Get video by ID
RegisterNetEvent('phone:server:getVideo', function(data)
    local src = source
    local phoneNumber = exports['phone']:GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveVideo', src, {
            success = false,
            error = 'Phone number not found'
        })
        return
    end
    
    local mediaId = data.mediaId or data
    
    if not mediaId then
        TriggerClientEvent('phone:client:receiveVideo', src, {
            success = false,
            error = 'Media ID is required'
        })
        return
    end
    
    local result = MySQL.query.await([[
        SELECT id, file_url, thumbnail_url, duration, location_x, location_y, 
               file_size, metadata_json, created_at
        FROM phone_media
        WHERE id = ? AND owner_number = ? AND media_type = 'video'
    ]], {mediaId, phoneNumber})
    
    if result and result[1] then
        local video = result[1]
        
        -- Parse metadata JSON
        if video.metadata_json then
            local success, metadata = pcall(json.decode, video.metadata_json)
            if success then
                video.metadata = metadata
            end
        end
        
        TriggerClientEvent('phone:client:receiveVideo', src, {
            success = true,
            data = video
        })
        
        if Config.DebugMode then
            print('[Phone] Sent video ID: ' .. mediaId .. ' to player ' .. src)
        end
    else
        TriggerClientEvent('phone:client:receiveVideo', src, {
            success = false,
            error = 'Video not found'
        })
        
        if Config.DebugMode then
            print('[Phone] Video not found: ' .. mediaId)
        end
    end
end)

-- Update video views
RegisterNetEvent('phone:server:incrementVideoViews', function(mediaId)
    local src = source
    
    -- This would be used for social media video views
    -- For now, just a placeholder
    if Config.Debug then
        print('[Phone] Video view incremented for media ID: ' .. mediaId)
    end
end)

return Videos
