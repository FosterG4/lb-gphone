-- Maps App Server Handler
-- Handles location pins, waypoints, and location sharing

local QBCore = nil
local ESX = nil

-- Initialize framework
if Config.Framework == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
elseif Config.Framework == 'qbox' then
    QBCore = exports.qbx_core
end

-- Cleanup expired shared locations every 5 minutes
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        
        local result = MySQL.execute.await('DELETE FROM phone_shared_locations WHERE expires_at < NOW()')
        
        if result and result > 0 then
            print('^3[PHONE] Cleaned up ' .. result .. ' expired shared locations^0')
        end
    end
end)

-- Helper function to get player source from phone number
function GetPlayerFromPhoneNumber(phoneNumber)
    local players = GetPlayers()
    
    for _, playerId in ipairs(players) do
        local src = tonumber(playerId)
        local playerPhone = GetPlayerPhoneNumber(src)
        
        if playerPhone == phoneNumber then
            return src
        end
    end
    
    return nil
end

-- Helper function to get player phone number
function GetPlayerPhoneNumber(src)
    if Config.Framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            return Player.PlayerData.charinfo.phone
        end
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            local result = MySQL.query.await('SELECT phone_number FROM phone_players WHERE identifier = ?', {
                xPlayer.identifier
            })
            if result and result[1] then
                return result[1].phone_number
            end
        end
    elseif Config.Framework == 'qbox' then
        local Player = exports.qbx_core:GetPlayer(src)
        if Player then
            return Player.PlayerData.charinfo.phone
        end
    else
        -- Standalone
        local identifier = GetPlayerIdentifierByType(src, 'license')
        if identifier then
            local result = MySQL.query.await('SELECT phone_number FROM phone_players WHERE identifier = ?', {
                identifier
            })
            if result and result[1] then
                return result[1].phone_number
            end
        end
    end
    
    return nil
end

-- Get all location pins for a player
RegisterNetEvent('phone:server:getLocationPins', function()
    local src = source
    local phoneNumber = GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveLocationPins', src, {
            success = false,
            error = 'PLAYER_NOT_FOUND'
        })
        return
    end
    
    local result = MySQL.query.await('SELECT * FROM phone_location_pins WHERE owner_number = ? ORDER BY created_at DESC', {
        phoneNumber
    })
    
    TriggerClientEvent('phone:client:receiveLocationPins', src, {
        success = true,
        pins = result or {}
    })
end)

-- Create a new location pin
RegisterNetEvent('phone:server:createLocationPin', function(data)
    local src = source
    local phoneNumber = GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:locationPinCreated', src, {
            success = false,
            error = 'PLAYER_NOT_FOUND'
        })
        return
    end
    
    -- Validate input
    if not data.label or not data.x or not data.y then
        TriggerClientEvent('phone:client:locationPinCreated', src, {
            success = false,
            error = 'INVALID_INPUT'
        })
        return
    end
    
    -- Check pin limit
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM phone_location_pins WHERE owner_number = ?', {
        phoneNumber
    })
    
    if count >= (Config.MapsApp.maxLocationPins or 50) then
        TriggerClientEvent('phone:client:locationPinCreated', src, {
            success = false,
            error = 'PIN_LIMIT_REACHED'
        })
        return
    end
    
    -- Insert pin
    local pinId = MySQL.insert.await([[
        INSERT INTO phone_location_pins (owner_number, label, location_x, location_y)
        VALUES (?, ?, ?, ?)
    ]], {
        phoneNumber,
        data.label,
        data.x,
        data.y
    })
    
    if pinId then
        local pin = MySQL.query.await('SELECT * FROM phone_location_pins WHERE id = ?', { pinId })
        
        TriggerClientEvent('phone:client:locationPinCreated', src, {
            success = true,
            pin = pin[1]
        })
    else
        TriggerClientEvent('phone:client:locationPinCreated', src, {
            success = false,
            error = 'DATABASE_ERROR'
        })
    end
end)

-- Update an existing location pin
RegisterNetEvent('phone:server:updateLocationPin', function(data)
    local src = source
    local phoneNumber = GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:locationPinUpdated', src, {
            success = false,
            error = 'PLAYER_NOT_FOUND'
        })
        return
    end
    
    -- Verify ownership
    local pin = MySQL.query.await('SELECT * FROM phone_location_pins WHERE id = ? AND owner_number = ?', {
        data.pinId,
        phoneNumber
    })
    
    if not pin or not pin[1] then
        TriggerClientEvent('phone:client:locationPinUpdated', src, {
            success = false,
            error = 'NOT_OWNER'
        })
        return
    end
    
    -- Update pin
    local success = MySQL.update.await([[
        UPDATE phone_location_pins 
        SET label = ?, location_x = ?, location_y = ?
        WHERE id = ?
    ]], {
        data.label,
        data.x,
        data.y,
        data.pinId
    })
    
    if success then
        local updatedPin = MySQL.query.await('SELECT * FROM phone_location_pins WHERE id = ?', { data.pinId })
        
        TriggerClientEvent('phone:client:locationPinUpdated', src, {
            success = true,
            pin = updatedPin[1]
        })
    else
        TriggerClientEvent('phone:client:locationPinUpdated', src, {
            success = false,
            error = 'DATABASE_ERROR'
        })
    end
end)

-- Delete a location pin
RegisterNetEvent('phone:server:deleteLocationPin', function(data)
    local src = source
    local phoneNumber = GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:locationPinDeleted', src, {
            success = false,
            error = 'PLAYER_NOT_FOUND'
        })
        return
    end
    
    -- Verify ownership
    local pin = MySQL.query.await('SELECT * FROM phone_location_pins WHERE id = ? AND owner_number = ?', {
        data.pinId,
        phoneNumber
    })
    
    if not pin or not pin[1] then
        TriggerClientEvent('phone:client:locationPinDeleted', src, {
            success = false,
            error = 'NOT_OWNER'
        })
        return
    end
    
    -- Delete pin
    local success = MySQL.execute.await('DELETE FROM phone_location_pins WHERE id = ?', {
        data.pinId
    })
    
    TriggerClientEvent('phone:client:locationPinDeleted', src, {
        success = success
    })
end)

-- Get shared locations for a player
RegisterNetEvent('phone:server:getSharedLocations', function()
    local src = source
    local phoneNumber = GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveSharedLocations', src, {
            success = false,
            error = 'PLAYER_NOT_FOUND'
        })
        return
    end
    
    local result = MySQL.query.await([[
        SELECT sl.*, pp.phone_number as sharer_name
        FROM phone_shared_locations sl
        LEFT JOIN phone_players pp ON sl.sharer_number = pp.phone_number
        WHERE sl.receiver_number = ? AND sl.expires_at > NOW()
        ORDER BY sl.created_at DESC
    ]], {
        phoneNumber
    })
    
    -- Format the locations for the client
    local locations = {}
    if result then
        for _, location in ipairs(result) do
            table.insert(locations, {
                id = location.id,
                name = location.sharer_name or 'Unknown',
                x = location.location_x,
                y = location.location_y,
                message = location.message,
                expiresAt = location.expires_at
            })
        end
    end
    
    TriggerClientEvent('phone:client:receiveSharedLocations', src, {
        success = true,
        locations = locations
    })
end)

-- Share location with a contact
RegisterNetEvent('phone:server:shareLocation', function(data)
    local src = source
    local phoneNumber = GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:locationShared', src, {
            success = false,
            error = 'PLAYER_NOT_FOUND'
        })
        return
    end
    
    -- Validate input
    if not data.contactNumber or not data.x or not data.y or not data.duration then
        TriggerClientEvent('phone:client:locationShared', src, {
            success = false,
            error = 'INVALID_INPUT'
        })
        return
    end
    
    -- Verify contact exists
    local contact = MySQL.query.await('SELECT * FROM phone_players WHERE phone_number = ?', {
        data.contactNumber
    })
    
    if not contact or not contact[1] then
        TriggerClientEvent('phone:client:locationShared', src, {
            success = false,
            error = 'CONTACT_NOT_FOUND'
        })
        return
    end
    
    -- Calculate expiration time
    local expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + data.duration)
    
    -- Insert shared location
    local shareId = MySQL.insert.await([[
        INSERT INTO phone_shared_locations (sharer_number, receiver_number, location_x, location_y, message, expires_at)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        phoneNumber,
        data.contactNumber,
        data.x,
        data.y,
        data.message or '',
        expiresAt
    })
    
    if shareId then
        -- Send notification to receiver
        local receiverSrc = GetPlayerFromPhoneNumber(data.contactNumber)
        if receiverSrc then
            TriggerClientEvent('phone:client:notification', receiverSrc, {
                app = 'maps',
                title = 'Location Shared',
                message = phoneNumber .. ' shared their location with you',
                icon = 'maps'
            })
            
            -- Trigger location update for receiver
            TriggerClientEvent('phone:client:sharedLocationReceived', receiverSrc, {
                id = shareId,
                name = phoneNumber,
                x = data.x,
                y = data.y,
                message = data.message,
                expiresAt = expiresAt
            })
        end
        
        -- Also send as a message with map link
        MySQL.insert.await([[
            INSERT INTO phone_messages (sender_number, receiver_number, message)
            VALUES (?, ?, ?)
        ]], {
            phoneNumber,
            data.contactNumber,
            (data.message or 'I\'m sharing my location with you') .. '\n📍 Location: ' .. data.x .. ', ' .. data.y
        })
        
        TriggerClientEvent('phone:client:locationShared', src, {
            success = true
        })
    else
        TriggerClientEvent('phone:client:locationShared', src, {
            success = false,
            error = 'DATABASE_ERROR'
        })
    end
end)

print('^2[Phone] Maps app loaded successfully^7')
