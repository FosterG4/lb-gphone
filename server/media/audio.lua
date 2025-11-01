-- Audio Operations Module
-- Handles voice recording operations

local Storage = lib.require('server.media.storage')

local Audio = {}

-- Upload audio recording
RegisterNetEvent('phone:server:uploadAudio', function(data, metadata)
    local src = source
    local phoneNumber = exports['phone']:GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:notify', src, {
            type = 'error',
            message = 'Phone number not found'
        })
        return
    end
    
    -- Validate audio duration
    local maxDuration = Config.MaxAudioLength or 300
    if metadata and metadata.duration and metadata.duration > maxDuration then
        TriggerClientEvent('phone:client:notify', src, {
            type = 'error',
            message = 'Recording too long (max ' .. maxDuration .. ' seconds)'
        })
        return
    end
    
    -- Handle upload
    local result = Storage.HandleUpload(phoneNumber, data, 'audio', metadata)
    
    if result.success then
        -- Notify client
        TriggerClientEvent('phone:client:audioUploaded', src, result.data)
        
        -- Update client media list
        local media = Storage.GetPlayerMedia(phoneNumber, 'audio', 20, 0)
        TriggerClientEvent('phone:client:updateMedia', src, media)
    else
        TriggerClientEvent('phone:client:notify', src, {
            type = 'error',
            message = result.message or 'Failed to upload audio'
        })
    end
end)

-- Get audio recordings
RegisterNetEvent('phone:server:getAudioRecordings', function(limit, offset)
    local src = source
    local phoneNumber = exports['phone']:GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        return
    end
    
    local recordings = Storage.GetPlayerMedia(phoneNumber, 'audio', limit, offset)
    TriggerClientEvent('phone:client:receiveAudioRecordings', src, recordings)
end)

-- Delete audio recording
RegisterNetEvent('phone:server:deleteAudio', function(mediaId)
    local src = source
    local phoneNumber = exports['phone']:GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        return
    end
    
    local result = Storage.DeleteMedia(mediaId, phoneNumber)
    
    if result.success then
        TriggerClientEvent('phone:client:audioDeleted', src, mediaId)
        TriggerClientEvent('phone:client:notify', src, {
            type = 'success',
            message = 'Recording deleted'
        })
    else
        TriggerClientEvent('phone:client:notify', src, {
            type = 'error',
            message = result.message or 'Failed to delete recording'
        })
    end
end)

-- Get audio by ID
RegisterNetEvent('phone:server:getAudio', function(mediaId)
    local src = source
    local phoneNumber = exports['phone']:GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        return
    end
    
    local result = MySQL.query.await([[
        SELECT id, file_url, duration, metadata_json, created_at
        FROM phone_media
        WHERE id = ? AND owner_number = ? AND media_type = 'audio'
    ]], {mediaId, phoneNumber})
    
    if result and result[1] then
        TriggerClientEvent('phone:client:receiveAudio', src, result[1])
    end
end)

return Audio
