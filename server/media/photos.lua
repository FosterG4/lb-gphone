-- Photo Operations Module
-- Handles photo-specific operations

local Storage = require('server.media.storage')

local Photos = {}

-- Upload photo
RegisterNetEvent('phone:server:uploadPhoto', function(data, metadata)
    local src = source
    local phoneNumber = exports['phone']:GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:notify', src, {
            type = 'error',
            message = 'Phone number not found'
        })
        return
    end
    
    -- Validate photo data
    if not data or data == '' then
        TriggerClientEvent('phone:client:notify', src, {
            type = 'error',
            message = 'Invalid photo data'
        })
        return
    end
    
    -- Add timestamp to metadata if not present
    if not metadata then
        metadata = {}
    end
    if not metadata.timestamp then
        metadata.timestamp = os.time()
    end
    
    if Config.DebugMode then
        print('[Phone] Uploading photo for ' .. phoneNumber)
        if metadata.location_x and metadata.location_y then
            print('[Phone] Photo location: ' .. metadata.location_x .. ', ' .. metadata.location_y)
        end
        if metadata.filter then
            print('[Phone] Photo filter: ' .. metadata.filter)
        end
    end
    
    -- Handle upload
    local result = Storage.HandleUpload(phoneNumber, data, 'photo', metadata)
    
    if result.success then
        -- Add additional metadata to result
        result.data.metadata = metadata
        
        -- Notify client
        TriggerClientEvent('phone:client:photoUploaded', src, result.data)
        
        -- Update client media list
        local media = Storage.GetPlayerMedia(phoneNumber, 'photo', 20, 0)
        TriggerClientEvent('phone:client:updateMedia', src, media)
        
        if Config.DebugMode then
            print('[Phone] Photo uploaded successfully - ID: ' .. result.data.id)
        end
    else
        TriggerClientEvent('phone:client:notify', src, {
            type = 'error',
            message = result.message or 'Failed to upload photo'
        })
        
        if Config.DebugMode then
            print('[Phone] Photo upload failed: ' .. (result.message or 'Unknown error'))
        end
    end
end)

-- Get photos
RegisterNetEvent('phone:server:getPhotos', function(data)
    local src = source
    local phoneNumber = exports['phone']:GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:receivePhotos', src, {
            success = false,
            error = 'Phone number not found'
        })
        return
    end
    
    local limit = (data and data.limit) or 20
    local offset = (data and data.offset) or 0
    
    local photos = Storage.GetPlayerMedia(phoneNumber, 'photo', limit, offset)
    
    -- Parse metadata JSON for each photo
    for _, photo in ipairs(photos) do
        if photo.metadata_json then
            local success, metadata = pcall(json.decode, photo.metadata_json)
            if success then
                photo.metadata = metadata
            end
        end
    end
    
    TriggerClientEvent('phone:client:receivePhotos', src, {
        success = true,
        data = photos
    })
    
    if Config.DebugMode then
        print('[Phone] Sent ' .. #photos .. ' photos to player ' .. src)
    end
end)

-- Delete photo
RegisterNetEvent('phone:server:deletePhoto', function(data)
    local src = source
    local phoneNumber = exports['phone']:GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:photoDeleted', src, {
            success = false,
            error = 'Phone number not found'
        })
        return
    end
    
    local mediaId = data.mediaId or data
    
    if not mediaId then
        TriggerClientEvent('phone:client:photoDeleted', src, {
            success = false,
            error = 'Media ID is required'
        })
        return
    end
    
    if Config.DebugMode then
        print('[Phone] Deleting photo ID: ' .. mediaId .. ' for ' .. phoneNumber)
    end
    
    local result = Storage.DeleteMedia(mediaId, phoneNumber)
    
    if result.success then
        TriggerClientEvent('phone:client:photoDeleted', src, {
            success = true,
            mediaId = mediaId
        })
        TriggerClientEvent('phone:client:notify', src, {
            type = 'success',
            message = 'Photo deleted'
        })
        
        if Config.DebugMode then
            print('[Phone] Photo deleted successfully')
        end
    else
        TriggerClientEvent('phone:client:photoDeleted', src, {
            success = false,
            error = result.message or 'Failed to delete photo'
        })
        TriggerClientEvent('phone:client:notify', src, {
            type = 'error',
            message = result.message or 'Failed to delete photo'
        })
        
        if Config.DebugMode then
            print('[Phone] Photo deletion failed: ' .. (result.message or 'Unknown error'))
        end
    end
end)

-- Get photo by ID
RegisterNetEvent('phone:server:getPhoto', function(data)
    local src = source
    local phoneNumber = exports['phone']:GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:receivePhoto', src, {
            success = false,
            error = 'Phone number not found'
        })
        return
    end
    
    local mediaId = data.mediaId or data
    
    if not mediaId then
        TriggerClientEvent('phone:client:receivePhoto', src, {
            success = false,
            error = 'Media ID is required'
        })
        return
    end
    
    local result = MySQL.query.await([[
        SELECT id, file_url, thumbnail_url, location_x, location_y, 
               file_size, metadata_json, created_at
        FROM phone_media
        WHERE id = ? AND owner_number = ? AND media_type = 'photo'
    ]], {mediaId, phoneNumber})
    
    if result and result[1] then
        local photo = result[1]
        
        -- Parse metadata JSON
        if photo.metadata_json then
            local success, metadata = pcall(json.decode, photo.metadata_json)
            if success then
                photo.metadata = metadata
            end
        end
        
        TriggerClientEvent('phone:client:receivePhoto', src, {
            success = true,
            data = photo
        })
        
        if Config.DebugMode then
            print('[Phone] Sent photo ID: ' .. mediaId .. ' to player ' .. src)
        end
    else
        TriggerClientEvent('phone:client:receivePhoto', src, {
            success = false,
            error = 'Photo not found'
        })
        
        if Config.DebugMode then
            print('[Phone] Photo not found: ' .. mediaId)
        end
    end
end)

return Photos
