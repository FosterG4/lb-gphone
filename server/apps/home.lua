-- Home App Server Module
-- Handles property management, lock/unlock, key management, and access logs

local HomeApp = {}
local housingAdapter = nil

-- Initialize housing adapter
function HomeApp:Init()
    if not Config.HomeApp or not Config.HomeApp.enabled then
        print('[Phone] Home app is disabled in config')
        return
    end
    
    -- Initialize housing adapter based on config
    local housingScript = Config.HomeApp.housingScript or 'standalone'
    
    if housingScript ~= 'none' then
        housingAdapter = HousingAdapter:Init()
        print('[Phone] Housing adapter initialized: ' .. housingAdapter.type)
    else
        print('[Phone] Home app running without external housing integration')
    end
    
    -- Start key expiration checker
    if Config.HomeApp.enableKeyExpiration then
        self:StartKeyExpirationChecker()
    end
end

-- Get all properties for a player
function HomeApp:GetPlayerProperties(source)
    if not housingAdapter then
        -- Fallback to phone_properties table
        local phoneNumber = Framework:GetPhoneNumber(source)
        if not phoneNumber then
            return {}
        end
        
        local result = MySQL.query.await('SELECT * FROM phone_properties WHERE owner_number = ?', {phoneNumber})
        return result or {}
    end
    
    -- Use housing adapter
    local properties = housingAdapter:GetPlayerProperties(source)
    
    -- Sync with phone_properties table
    self:SyncPropertiesToDatabase(source, properties)
    
    return properties
end

-- Sync properties to phone_properties table
function HomeApp:SyncPropertiesToDatabase(source, properties)
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then return end
    
    for _, property in ipairs(properties) do
        -- Check if property exists in phone_properties
        local existing = MySQL.query.await(
            'SELECT id FROM phone_properties WHERE property_id = ? AND owner_number = ?',
            {property.id, phoneNumber}
        )
        
        if not existing or #existing == 0 then
            -- Insert new property
            MySQL.insert(
                'INSERT INTO phone_properties (owner_number, property_id, property_name, location_x, location_y, locked) VALUES (?, ?, ?, ?, ?, ?)',
                {
                    phoneNumber,
                    property.id,
                    property.name,
                    property.location and property.location.x or nil,
                    property.location and property.location.y or nil,
                    property.locked and 1 or 0
                }
            )
        else
            -- Update existing property
            MySQL.update(
                'UPDATE phone_properties SET property_name = ?, location_x = ?, location_y = ?, locked = ? WHERE property_id = ? AND owner_number = ?',
                {
                    property.name,
                    property.location and property.location.x or nil,
                    property.location and property.location.y or nil,
                    property.locked and 1 or 0,
                    property.id,
                    phoneNumber
                }
            )
        end
    end
end

-- Toggle property lock/unlock
function HomeApp:ToggleLock(source, propertyId, action)
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return { success = false, message = 'Phone number not found' }
    end
    
    -- Verify player owns or has access to this property
    local hasAccess = self:VerifyPropertyAccess(source, propertyId)
    if not hasAccess then
        return { success = false, message = 'Access denied' }
    end
    
    local success = false
    
    if housingAdapter then
        -- Use housing adapter
        if action == 'lock' then
            success = housingAdapter:LockDoor(source, propertyId)
        else
            success = housingAdapter:UnlockDoor(source, propertyId)
        end
    else
        -- Fallback to phone_properties table
        local lockValue = action == 'lock' and 1 or 0
        MySQL.update(
            'UPDATE phone_properties SET locked = ? WHERE property_id = ? AND owner_number = ?',
            {lockValue, propertyId, phoneNumber}
        )
        success = true
    end
    
    if success then
        -- Log the action
        self:LogAccess(propertyId, phoneNumber, action)
        
        -- Notify nearby players if they have the property open
        self:BroadcastPropertyUpdate(propertyId, action == 'lock')
        
        return { success = true, message = 'Property ' .. action .. 'ed successfully' }
    else
        return { success = false, message = 'Failed to ' .. action .. ' property' }
    end
end

-- Verify player has access to property
function HomeApp:VerifyPropertyAccess(source, propertyId)
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then return false end
    
    -- Check if player owns the property
    local owned = MySQL.query.await(
        'SELECT id FROM phone_properties WHERE property_id = ? AND owner_number = ?',
        {propertyId, phoneNumber}
    )
    
    if owned and #owned > 0 then
        return true
    end
    
    -- Check if player has a valid key
    local key = MySQL.query.await([[
        SELECT k.id FROM phone_property_keys k
        INNER JOIN phone_properties p ON k.property_id = p.id
        WHERE p.property_id = ? AND k.holder_number = ?
        AND (k.expires_at IS NULL OR k.expires_at > NOW())
    ]], {propertyId, phoneNumber})
    
    return key and #key > 0
end

-- Get property keys
function HomeApp:GetPropertyKeys(source, propertyId)
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return {}
    end
    
    -- Verify player owns this property
    local property = MySQL.query.await(
        'SELECT id FROM phone_properties WHERE property_id = ? AND owner_number = ?',
        {propertyId, phoneNumber}
    )
    
    if not property or #property == 0 then
        return {}
    end
    
    local propertyDbId = property[1].id
    
    -- Get all keys for this property
    local keys = MySQL.query.await([[
        SELECT k.*, p.phone_number as holder_name
        FROM phone_property_keys k
        LEFT JOIN phone_players p ON k.holder_number = p.phone_number
        WHERE k.property_id = ?
        ORDER BY k.granted_at DESC
    ]], {propertyDbId})
    
    return keys or {}
end

-- Grant key to another player
function HomeApp:GrantKey(source, propertyId, targetNumber, expirationHours)
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return { success = false, message = 'Phone number not found' }
    end
    
    -- Verify player owns this property
    local property = MySQL.query.await(
        'SELECT id FROM phone_properties WHERE property_id = ? AND owner_number = ?',
        {propertyId, phoneNumber}
    )
    
    if not property or #property == 0 then
        return { success = false, message = 'Property not found or access denied' }
    end
    
    local propertyDbId = property[1].id
    
    -- Check if target phone number exists
    local targetExists = MySQL.query.await(
        'SELECT phone_number FROM phone_players WHERE phone_number = ?',
        {targetNumber}
    )
    
    if not targetExists or #targetExists == 0 then
        return { success = false, message = 'Target phone number not found' }
    end
    
    -- Check if key already exists
    local existingKey = MySQL.query.await(
        'SELECT id FROM phone_property_keys WHERE property_id = ? AND holder_number = ?',
        {propertyDbId, targetNumber}
    )
    
    if existingKey and #existingKey > 0 then
        return { success = false, message = 'Key already granted to this number' }
    end
    
    -- Calculate expiration timestamp
    local expiresAt = nil
    if expirationHours then
        expiresAt = os.time() + (expirationHours * 3600)
    end
    
    -- Grant key in housing adapter if available
    if housingAdapter then
        local success = housingAdapter:GrantKey(source, propertyId, targetNumber, expiresAt)
        if not success then
            return { success = false, message = 'Failed to grant key in housing system' }
        end
    end
    
    -- Store key in phone_property_keys table
    if expiresAt then
        MySQL.insert(
            'INSERT INTO phone_property_keys (property_id, holder_number, granted_by, expires_at) VALUES (?, ?, ?, FROM_UNIXTIME(?))',
            {propertyDbId, targetNumber, phoneNumber, expiresAt}
        )
    else
        MySQL.insert(
            'INSERT INTO phone_property_keys (property_id, holder_number, granted_by) VALUES (?, ?, ?)',
            {propertyDbId, targetNumber, phoneNumber}
        )
    end
    
    -- Log the action
    self:LogAccess(propertyId, phoneNumber, 'key_grant', targetNumber)
    
    -- Send notification to target player
    self:SendKeyNotification(targetNumber, propertyId, 'granted', phoneNumber)
    
    return { success = true, message = 'Key granted successfully' }
end

-- Revoke key from player
function HomeApp:RevokeKey(source, keyId)
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return { success = false, message = 'Phone number not found' }
    end
    
    -- Get key details
    local key = MySQL.query.await([[
        SELECT k.*, p.property_id, p.owner_number
        FROM phone_property_keys k
        INNER JOIN phone_properties p ON k.property_id = p.id
        WHERE k.id = ?
    ]], {keyId})
    
    if not key or #key == 0 then
        return { success = false, message = 'Key not found' }
    end
    
    local keyData = key[1]
    
    -- Verify player owns the property
    if keyData.owner_number ~= phoneNumber then
        return { success = false, message = 'Access denied' }
    end
    
    -- Revoke key in housing adapter if available
    if housingAdapter then
        housingAdapter:RevokeKey(source, keyData.property_id, keyData.holder_number)
    end
    
    -- Delete key from database
    MySQL.execute('DELETE FROM phone_property_keys WHERE id = ?', {keyId})
    
    -- Log the action
    self:LogAccess(keyData.property_id, phoneNumber, 'key_revoke', keyData.holder_number)
    
    -- Send notification to target player
    self:SendKeyNotification(keyData.holder_number, keyData.property_id, 'revoked', phoneNumber)
    
    return { success = true, message = 'Key revoked successfully' }
end

-- Get access logs for a property
function HomeApp:GetAccessLogs(source, propertyId)
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return {}
    end
    
    -- Verify player has access to this property
    local hasAccess = self:VerifyPropertyAccess(source, propertyId)
    if not hasAccess then
        return {}
    end
    
    -- Get property database ID
    local property = MySQL.query.await(
        'SELECT id FROM phone_properties WHERE property_id = ?',
        {propertyId}
    )
    
    if not property or #property == 0 then
        return {}
    end
    
    local propertyDbId = property[1].id
    
    -- Get access logs (last 50 entries)
    local logs = MySQL.query.await([[
        SELECT l.*, p.phone_number as user_name
        FROM phone_access_logs l
        LEFT JOIN phone_players p ON l.user_number = p.phone_number
        WHERE l.property_id = ?
        ORDER BY l.timestamp DESC
        LIMIT 50
    ]], {propertyDbId})
    
    return logs or {}
end

-- Log access action
function HomeApp:LogAccess(propertyId, userNumber, action, targetNumber)
    -- Get property database ID
    local property = MySQL.query.await(
        'SELECT id FROM phone_properties WHERE property_id = ?',
        {propertyId}
    )
    
    if not property or #property == 0 then
        return
    end
    
    local propertyDbId = property[1].id
    
    -- Insert log entry
    MySQL.insert(
        'INSERT INTO phone_access_logs (property_id, user_number, action, target_number) VALUES (?, ?, ?, ?)',
        {propertyDbId, userNumber, action, targetNumber}
    )
end

-- Send key notification to player
function HomeApp:SendKeyNotification(targetNumber, propertyId, action, fromNumber)
    -- Find target player online
    for _, playerId in ipairs(GetPlayers()) do
        local playerPhone = Framework:GetPhoneNumber(tonumber(playerId))
        if playerPhone == targetNumber then
            -- Get property name
            local property = MySQL.query.await(
                'SELECT property_name FROM phone_properties WHERE property_id = ?',
                {propertyId}
            )
            
            local propertyName = property and #property > 0 and property[1].property_name or 'Property'
            
            -- Send notification
            TriggerClientEvent('phone:notification', tonumber(playerId), {
                app = 'Home',
                title = 'Property Key ' .. (action == 'granted' and 'Granted' or 'Revoked'),
                message = 'Key to ' .. propertyName .. ' has been ' .. action,
                icon = 'home'
            })
            
            break
        end
    end
end

-- Broadcast property update to players
function HomeApp:BroadcastPropertyUpdate(propertyId, locked)
    -- Find all players with access to this property
    local players = MySQL.query.await([[
        SELECT DISTINCT owner_number as phone_number FROM phone_properties WHERE property_id = ?
        UNION
        SELECT DISTINCT k.holder_number as phone_number
        FROM phone_property_keys k
        INNER JOIN phone_properties p ON k.property_id = p.id
        WHERE p.property_id = ? AND (k.expires_at IS NULL OR k.expires_at > NOW())
    ]], {propertyId, propertyId})
    
    if not players then return end
    
    for _, player in ipairs(players) do
        -- Find player online
        for _, playerId in ipairs(GetPlayers()) do
            local playerPhone = Framework:GetPhoneNumber(tonumber(playerId))
            if playerPhone == player.phone_number then
                -- Send update event
                TriggerClientEvent('phone:home:propertyUpdated', tonumber(playerId), {
                    propertyId = propertyId,
                    locked = locked
                })
                break
            end
        end
    end
end

-- Start key expiration checker
function HomeApp:StartKeyExpirationChecker()
    local checkInterval = Config.HomeApp.keyExpirationCheckInterval or 60000 -- 1 minute
    
    CreateThread(function()
        while true do
            Wait(checkInterval)
            
            -- Find expired keys
            local expiredKeys = MySQL.query.await([[
                SELECT k.id, k.holder_number, p.property_id, p.owner_number
                FROM phone_property_keys k
                INNER JOIN phone_properties p ON k.property_id = p.id
                WHERE k.expires_at IS NOT NULL AND k.expires_at <= NOW()
            ]])
            
            if expiredKeys and #expiredKeys > 0 then
                for _, key in ipairs(expiredKeys) do
                    -- Revoke key in housing adapter if available
                    if housingAdapter then
                        -- Find owner source
                        local ownerSource = nil
                        for _, playerId in ipairs(GetPlayers()) do
                            local playerPhone = Framework:GetPhoneNumber(tonumber(playerId))
                            if playerPhone == key.owner_number then
                                ownerSource = tonumber(playerId)
                                break
                            end
                        end
                        
                        if ownerSource then
                            housingAdapter:RevokeKey(ownerSource, key.property_id, key.holder_number)
                        end
                    end
                    
                    -- Delete expired key
                    MySQL.execute('DELETE FROM phone_property_keys WHERE id = ?', {key.id})
                    
                    -- Log the action
                    self:LogAccess(key.property_id, 'SYSTEM', 'key_expired', key.holder_number)
                    
                    -- Notify holder
                    self:SendKeyNotification(key.holder_number, key.property_id, 'expired', 'SYSTEM')
                end
                
                print('[Phone] Removed ' .. #expiredKeys .. ' expired property keys')
            end
        end
    end)
end

-- Register server events (NUI callbacks should be on client side)
RegisterNetEvent('phone:home:getProperties', function(data, cb)
    local source = source
    
    local properties = HomeApp:GetPlayerProperties(source)
    
    cb({
        success = true,
        properties = properties
    })
end)

RegisterNetEvent('phone:home:toggleLock', function(data, cb)
    local source = source
    local propertyId = data.propertyId
    local action = data.action
    
    if not propertyId or not action then
        cb({ success = false, message = 'Invalid parameters' })
        return
    end
    
    local result = HomeApp:ToggleLock(source, propertyId, action)
    cb(result)
end)

RegisterNetEvent('phone:home:getPropertyKeys', function(data, cb)
    local source = source
    local propertyId = data.propertyId
    
    if not propertyId then
        cb({ success = false, message = 'Invalid property ID' })
        return
    end
    
    local keys = HomeApp:GetPropertyKeys(source, propertyId)
    
    cb({
        success = true,
        keys = keys
    })
end)

RegisterNetEvent('phone:home:grantKey', function(data, cb)
    local source = source
    local propertyId = data.propertyId
    local targetNumber = data.targetNumber
    local expirationHours = data.expirationHours
    
    if not propertyId or not targetNumber then
        cb({ success = false, message = 'Invalid parameters' })
        return
    end
    
    local result = HomeApp:GrantKey(source, propertyId, targetNumber, expirationHours)
    cb(result)
end)

RegisterNetEvent('phone:home:revokeKey', function(data, cb)
    local source = source
    local keyId = data.keyId
    
    if not keyId then
        cb({ success = false, message = 'Invalid key ID' })
        return
    end
    
    local result = HomeApp:RevokeKey(source, keyId)
    cb(result)
end)

RegisterNetEvent('phone:home:getAccessLogs', function(data, cb)
    local source = source
    local propertyId = data.propertyId
    
    if not propertyId then
        cb({ success = false, message = 'Invalid property ID' })
        return
    end
    
    local logs = HomeApp:GetAccessLogs(source, propertyId)
    
    cb({
        success = true,
        logs = logs
    })
end)

-- Initialize on resource start
CreateThread(function()
    Wait(1000) -- Wait for framework and adapters to load
    HomeApp:Init()
end)

return HomeApp
