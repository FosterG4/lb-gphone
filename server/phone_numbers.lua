-- Phone Number Management Module
-- Handles phone number operations and lookups

local Database = require('server.database')

-- Get phone number by player source
RegisterNetEvent('phone:server:getPhoneNumber', function()
    local src = source
    
    if not Framework then
        TriggerClientEvent('phone:client:phoneNumberResponse', src, {
            success = false,
            error = 'FRAMEWORK_NOT_INITIALIZED',
            message = 'Framework not initialized'
        })
        return
    end
    
    local identifier = Framework:GetIdentifier(src)
    
    if not identifier then
        TriggerClientEvent('phone:client:phoneNumberResponse', src, {
            success = false,
            error = 'IDENTIFIER_NOT_FOUND',
            message = 'Failed to get player identifier'
        })
        return
    end
    
    Database.GetPlayerByIdentifier(identifier, function(player)
        if player then
            TriggerClientEvent('phone:client:phoneNumberResponse', src, {
                success = true,
                phoneNumber = player.phone_number
            })
        else
            TriggerClientEvent('phone:client:phoneNumberResponse', src, {
                success = false,
                error = 'PHONE_NUMBER_NOT_FOUND',
                message = 'Phone number not found'
            })
        end
    end)
end)

-- Lookup phone number by identifier (admin/system use)
RegisterNetEvent('phone:server:lookupByIdentifier', function(targetIdentifier)
    local src = source
    
    if not targetIdentifier then
        TriggerClientEvent('phone:client:lookupResponse', src, {
            success = false,
            error = 'INVALID_IDENTIFIER',
            message = 'Identifier is required'
        })
        return
    end
    
    Database.GetPlayerByIdentifier(targetIdentifier, function(player)
        if player then
            TriggerClientEvent('phone:client:lookupResponse', src, {
                success = true,
                identifier = player.identifier,
                phoneNumber = player.phone_number
            })
        else
            TriggerClientEvent('phone:client:lookupResponse', src, {
                success = false,
                error = 'PLAYER_NOT_FOUND',
                message = 'Player not found'
            })
        end
    end)
end)

-- Lookup identifier by phone number
RegisterNetEvent('phone:server:lookupByPhoneNumber', function(phoneNumber)
    local src = source
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:lookupResponse', src, {
            success = false,
            error = 'INVALID_PHONE_NUMBER',
            message = 'Phone number is required'
        })
        return
    end
    
    -- Validate phone number format
    local isValid, error = ValidatePhoneNumber(phoneNumber)
    if not isValid then
        TriggerClientEvent('phone:client:lookupResponse', src, {
            success = false,
            error = 'INVALID_PHONE_NUMBER_FORMAT',
            message = error
        })
        return
    end
    
    Database.GetPlayerByPhone(phoneNumber, function(player)
        if player then
            TriggerClientEvent('phone:client:lookupResponse', src, {
                success = true,
                identifier = player.identifier,
                phoneNumber = player.phone_number
            })
        else
            TriggerClientEvent('phone:client:lookupResponse', src, {
                success = false,
                error = 'PHONE_NUMBER_NOT_FOUND',
                message = 'Phone number not found'
            })
        end
    end)
end)

-- Check if phone number exists (for validation)
RegisterNetEvent('phone:server:checkPhoneNumberExists', function(phoneNumber)
    local src = source
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:phoneNumberExistsResponse', src, {
            success = false,
            exists = false,
            error = 'INVALID_PHONE_NUMBER',
            message = 'Phone number is required'
        })
        return
    end
    
    -- Validate phone number format
    local isValid, error = ValidatePhoneNumber(phoneNumber)
    if not isValid then
        TriggerClientEvent('phone:client:phoneNumberExistsResponse', src, {
            success = false,
            exists = false,
            error = 'INVALID_PHONE_NUMBER_FORMAT',
            message = error
        })
        return
    end
    
    Database.PhoneNumberExists(phoneNumber, function(exists)
        TriggerClientEvent('phone:client:phoneNumberExistsResponse', src, {
            success = true,
            exists = exists,
            phoneNumber = phoneNumber
        })
    end)
end)

-- Get player source by phone number (for calls/messages)
function GetPlayerSourceByPhoneNumber(phoneNumber)
    if not phoneNumber then
        return nil
    end
    
    local players = GetPlayers()
    
    for _, playerId in ipairs(players) do
        local src = tonumber(playerId)
        local cachedNumber = GetCachedPhoneNumber(src)
        
        if cachedNumber == phoneNumber then
            return src
        end
    end
    
    return nil
end

-- Export functions for other modules
exports('GetPlayerSourceByPhoneNumber', GetPlayerSourceByPhoneNumber)

-- Server-side function to get phone number by source (for internal use)
function GetPhoneNumberBySource(source)
    return GetCachedPhoneNumber(source)
end

exports('GetPhoneNumberBySource', GetPhoneNumberBySource)

print('^2[PHONE] Phone number management module loaded^0')
