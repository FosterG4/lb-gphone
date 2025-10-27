-- Album App Server Handlers
-- Handles album-related server events

local Albums = require('server.media.albums')
local PhoneNumbers = require('server.phone_numbers')

-- Get player albums
RegisterNetEvent('phone:server:getAlbums', function()
    local source = source
    local phoneNumber = PhoneNumbers.GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveAlbums', source, {
            success = false,
            error = 'NO_PHONE_NUMBER',
            message = 'Player does not have a phone number'
        })
        return
    end
    
    local albums = Albums.GetPlayerAlbums(phoneNumber)
    
    TriggerClientEvent('phone:client:receiveAlbums', source, {
        success = true,
        data = albums
    })
end)

-- Create album
RegisterNetEvent('phone:server:createAlbum', function(data)
    local source = source
    local phoneNumber = PhoneNumbers.GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:albumCreateResult', source, {
            success = false,
            error = 'NO_PHONE_NUMBER',
            message = 'Player does not have a phone number'
        })
        return
    end
    
    if not data or not data.name then
        TriggerClientEvent('phone:client:albumCreateResult', source, {
            success = false,
            error = 'INVALID_DATA',
            message = 'Album name is required'
        })
        return
    end
    
    local result = Albums.CreateAlbum(phoneNumber, data.name, data.coverMediaId)
    
    TriggerClientEvent('phone:client:albumCreateResult', source, result)
end)

-- Update album
RegisterNetEvent('phone:server:updateAlbum', function(data)
    local source = source
    local phoneNumber = PhoneNumbers.GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:albumUpdateResult', source, {
            success = false,
            error = 'NO_PHONE_NUMBER',
            message = 'Player does not have a phone number'
        })
        return
    end
    
    if not data or not data.albumId or not data.updates then
        TriggerClientEvent('phone:client:albumUpdateResult', source, {
            success = false,
            error = 'INVALID_DATA',
            message = 'Album ID and updates are required'
        })
        return
    end
    
    local result = Albums.UpdateAlbum(data.albumId, phoneNumber, data.updates)
    
    TriggerClientEvent('phone:client:albumUpdateResult', source, result)
end)

-- Delete album
RegisterNetEvent('phone:server:deleteAlbum', function(data)
    local source = source
    local phoneNumber = PhoneNumbers.GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:albumDeleteResult', source, {
            success = false,
            error = 'NO_PHONE_NUMBER',
            message = 'Player does not have a phone number'
        })
        return
    end
    
    if not data or not data.albumId then
        TriggerClientEvent('phone:client:albumDeleteResult', source, {
            success = false,
            error = 'INVALID_DATA',
            message = 'Album ID is required'
        })
        return
    end
    
    local result = Albums.DeleteAlbum(data.albumId, phoneNumber)
    
    TriggerClientEvent('phone:client:albumDeleteResult', source, result)
end)

-- Add media to album
RegisterNetEvent('phone:server:addMediaToAlbum', function(data)
    local source = source
    local phoneNumber = PhoneNumbers.GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:albumMediaResult', source, {
            success = false,
            error = 'NO_PHONE_NUMBER',
            message = 'Player does not have a phone number'
        })
        return
    end
    
    if not data or not data.albumId or not data.mediaIds then
        TriggerClientEvent('phone:client:albumMediaResult', source, {
            success = false,
            error = 'INVALID_DATA',
            message = 'Album ID and media IDs are required'
        })
        return
    end
    
    local result = Albums.AddMediaToAlbum(data.albumId, phoneNumber, data.mediaIds)
    
    TriggerClientEvent('phone:client:albumMediaResult', source, result)
end)

-- Remove media from album
RegisterNetEvent('phone:server:removeMediaFromAlbum', function(data)
    local source = source
    local phoneNumber = PhoneNumbers.GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:albumMediaResult', source, {
            success = false,
            error = 'NO_PHONE_NUMBER',
            message = 'Player does not have a phone number'
        })
        return
    end
    
    if not data or not data.albumId or not data.mediaIds then
        TriggerClientEvent('phone:client:albumMediaResult', source, {
            success = false,
            error = 'INVALID_DATA',
            message = 'Album ID and media IDs are required'
        })
        return
    end
    
    local result = Albums.RemoveMediaFromAlbum(data.albumId, phoneNumber, data.mediaIds)
    
    TriggerClientEvent('phone:client:albumMediaResult', source, result)
end)

-- Get album media
RegisterNetEvent('phone:server:getAlbumMedia', function(data)
    local source = source
    local phoneNumber = PhoneNumbers.GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveAlbumMedia', source, {
            success = false,
            error = 'NO_PHONE_NUMBER',
            message = 'Player does not have a phone number'
        })
        return
    end
    
    if not data or not data.albumId then
        TriggerClientEvent('phone:client:receiveAlbumMedia', source, {
            success = false,
            error = 'INVALID_DATA',
            message = 'Album ID is required'
        })
        return
    end
    
    local result = Albums.GetAlbumMedia(data.albumId, phoneNumber, data.limit, data.offset)
    
    TriggerClientEvent('phone:client:receiveAlbumMedia', source, result)
end)

-- Set album cover
RegisterNetEvent('phone:server:setAlbumCover', function(data)
    local source = source
    local phoneNumber = PhoneNumbers.GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:albumCoverResult', source, {
            success = false,
            error = 'NO_PHONE_NUMBER',
            message = 'Player does not have a phone number'
        })
        return
    end
    
    if not data or not data.albumId then
        TriggerClientEvent('phone:client:albumCoverResult', source, {
            success = false,
            error = 'INVALID_DATA',
            message = 'Album ID is required'
        })
        return
    end
    
    local result = Albums.SetAlbumCover(data.albumId, phoneNumber, data.mediaId)
    
    TriggerClientEvent('phone:client:albumCoverResult', source, result)
end)


-- Media Sharing Events
local Sharing = require('server.media.sharing')

-- Share media to app
RegisterNetEvent('phone:server:shareMedia', function(data)
    local source = source
    local phoneNumber = PhoneNumbers.GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:shareMediaResult', source, {
            success = false,
            error = 'NO_PHONE_NUMBER',
            message = 'Player does not have a phone number'
        })
        return
    end
    
    if not data or not data.mediaId or not data.targetApp then
        TriggerClientEvent('phone:client:shareMediaResult', source, {
            success = false,
            error = 'INVALID_DATA',
            message = 'Media ID and target app are required'
        })
        return
    end
    
    local result
    
    if data.targetApp == 'shotz' then
        result = Sharing.ShareToShotz(phoneNumber, data.mediaId, data.caption)
    elseif data.targetApp == 'modish' then
        result = Sharing.ShareToModish(phoneNumber, data.mediaId, data.effects)
    elseif data.targetApp == 'messages' then
        result = Sharing.ShareToMessages(phoneNumber, data.mediaId, data.targetNumber)
    else
        result = {
            success = false,
            error = 'INVALID_APP',
            message = 'Unknown target app'
        }
    end
    
    if result.success then
        Sharing.LogShare(phoneNumber, data.mediaId, data.targetApp)
    end
    
    TriggerClientEvent('phone:client:shareMediaResult', source, result)
end)


-- Bulk delete media
RegisterNetEvent('phone:server:bulkDeleteMedia', function(data)
    local source = source
    local phoneNumber = PhoneNumbers.GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:bulkDeleteResult', source, {
            success = false,
            error = 'NO_PHONE_NUMBER',
            message = 'Player does not have a phone number'
        })
        return
    end
    
    if not data or not data.mediaIds or type(data.mediaIds) ~= 'table' then
        TriggerClientEvent('phone:client:bulkDeleteResult', source, {
            success = false,
            error = 'INVALID_DATA',
            message = 'Media IDs array is required'
        })
        return
    end
    
    local Storage = require('server.media.storage')
    local result = Storage.BulkDeleteMedia(phoneNumber, data.mediaIds)
    
    TriggerClientEvent('phone:client:bulkDeleteResult', source, result)
end)
