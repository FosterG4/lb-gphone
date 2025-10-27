-- Housing Adapter Interface
-- This file defines the interface for housing script integration

HousingAdapter = {}
HousingAdapter.__index = HousingAdapter

-- Initialize the housing adapter based on config
function HousingAdapter:Init()
    local housingType = Config.HousingScript or 'standalone'
    
    if housingType == 'qb-houses' then
        return HousingAdapter:InitQBHouses()
    elseif housingType == 'qs-housing' then
        return HousingAdapter:InitQSHousing()
    elseif housingType == 'cd_easyhome' then
        return HousingAdapter:InitCDEasyHome()
    else
        return HousingAdapter:InitStandalone()
    end
end

-- Interface Methods (to be implemented by each adapter)

--- Get all properties owned or accessible by player
-- @param source number - Player server ID
-- @return table - Array of property data {id, name, location, locked, owned}
function HousingAdapter:GetPlayerProperties(source)
    error("GetPlayerProperties must be implemented by housing adapter")
end

--- Lock a property door
-- @param source number - Player server ID
-- @param propertyId string - Property identifier
-- @return boolean - Success status
function HousingAdapter:LockDoor(source, propertyId)
    error("LockDoor must be implemented by housing adapter")
end

--- Unlock a property door
-- @param source number - Player server ID
-- @param propertyId string - Property identifier
-- @return boolean - Success status
function HousingAdapter:UnlockDoor(source, propertyId)
    error("UnlockDoor must be implemented by housing adapter")
end

--- Grant temporary key to another player
-- @param source number - Player server ID (property owner)
-- @param propertyId string - Property identifier
-- @param targetNumber string - Target player's phone number
-- @param expiresAt number|nil - Expiration timestamp (optional)
-- @return boolean - Success status
function HousingAdapter:GrantKey(source, propertyId, targetNumber, expiresAt)
    error("GrantKey must be implemented by housing adapter")
end

--- Revoke key from another player
-- @param source number - Player server ID (property owner)
-- @param propertyId string - Property identifier
-- @param targetNumber string - Target player's phone number
-- @return boolean - Success status
function HousingAdapter:RevokeKey(source, propertyId, targetNumber)
    error("RevokeKey must be implemented by housing adapter")
end

--- Check if property is locked
-- @param propertyId string - Property identifier
-- @return boolean - True if locked
function HousingAdapter:IsLocked(propertyId)
    error("IsLocked must be implemented by housing adapter")
end

--- Get property location
-- @param propertyId string - Property identifier
-- @return table|nil - Location {x, y, z} or nil if not found
function HousingAdapter:GetPropertyLocation(propertyId)
    error("GetPropertyLocation must be implemented by housing adapter")
end

-- ============================================
-- QB-Houses Adapter Implementation
-- ============================================

function HousingAdapter:InitQBHouses()
    local adapter = setmetatable({}, HousingAdapter)
    adapter.type = 'qb-houses'
    
    function adapter:GetPlayerProperties(source)
        local Player = Framework:GetPlayer(source)
        if not Player then return {} end
        
        local citizenid = Player.PlayerData.citizenid
        
        -- Get owned houses
        local result = MySQL.query.await('SELECT * FROM player_houses WHERE citizenid = ?', {citizenid})
        
        local properties = {}
        for _, house in ipairs(result) do
            local houseData = exports['qb-houses']:GetHouseData(house.house)
            
            table.insert(properties, {
                id = house.house,
                name = houseData and houseData.adress or house.house,
                location = houseData and {x = houseData.coords.enter.x, y = houseData.coords.enter.y, z = houseData.coords.enter.z} or nil,
                locked = houseData and houseData.locked or true,
                owned = true
            })
        end
        
        -- Get houses with keys
        local keyResult = MySQL.query.await('SELECT house FROM player_house_keys WHERE citizenid = ?', {citizenid})
        for _, key in ipairs(keyResult) do
            local houseData = exports['qb-houses']:GetHouseData(key.house)
            
            table.insert(properties, {
                id = key.house,
                name = houseData and houseData.adress or key.house,
                location = houseData and {x = houseData.coords.enter.x, y = houseData.coords.enter.y, z = houseData.coords.enter.z} or nil,
                locked = houseData and houseData.locked or true,
                owned = false
            })
        end
        
        return properties
    end
    
    function adapter:LockDoor(source, propertyId)
        local Player = Framework:GetPlayer(source)
        if not Player then return false end
        
        -- Use QB-Houses export
        if exports['qb-houses'] and exports['qb-houses'].SetHouseLocked then
            exports['qb-houses']:SetHouseLocked(propertyId, true)
            return true
        end
        
        -- Fallback: Trigger event
        TriggerEvent('qb-houses:server:SetLocked', propertyId, true)
        return true
    end
    
    function adapter:UnlockDoor(source, propertyId)
        local Player = Framework:GetPlayer(source)
        if not Player then return false end
        
        -- Use QB-Houses export
        if exports['qb-houses'] and exports['qb-houses'].SetHouseLocked then
            exports['qb-houses']:SetHouseLocked(propertyId, false)
            return true
        end
        
        -- Fallback: Trigger event
        TriggerEvent('qb-houses:server:SetLocked', propertyId, false)
        return true
    end
    
    function adapter:GrantKey(source, propertyId, targetNumber, expiresAt)
        local Player = Framework:GetPlayer(source)
        if not Player then return false end
        
        -- Find target player by phone number
        local targetSource = nil
        for _, playerId in ipairs(GetPlayers()) do
            local targetPhone = Framework:GetPhoneNumber(tonumber(playerId))
            if targetPhone == targetNumber then
                targetSource = tonumber(playerId)
                break
            end
        end
        
        if not targetSource then return false end
        
        local TargetPlayer = Framework:GetPlayer(targetSource)
        if not TargetPlayer then return false end
        
        local targetCitizenid = TargetPlayer.PlayerData.citizenid
        
        -- Add key to database
        MySQL.insert('INSERT INTO player_house_keys (citizenid, house) VALUES (?, ?)', {
            targetCitizenid,
            propertyId
        })
        
        -- Store expiration in phone_property_keys table
        if expiresAt then
            local phonePropertyId = MySQL.scalar.await('SELECT id FROM phone_properties WHERE property_id = ?', {propertyId})
            if phonePropertyId then
                MySQL.insert('INSERT INTO phone_property_keys (property_id, holder_number, granted_by, expires_at) VALUES (?, ?, ?, FROM_UNIXTIME(?))', {
                    phonePropertyId,
                    targetNumber,
                    Framework:GetPhoneNumber(source),
                    expiresAt
                })
            end
        end
        
        -- Notify target player
        if exports['qb-houses'] and exports['qb-houses'].GiveKey then
            exports['qb-houses']:GiveKey(targetSource, propertyId)
        end
        
        return true
    end
    
    function adapter:RevokeKey(source, propertyId, targetNumber)
        local Player = Framework:GetPlayer(source)
        if not Player then return false end
        
        -- Find target player by phone number
        local targetSource = nil
        for _, playerId in ipairs(GetPlayers()) do
            local targetPhone = Framework:GetPhoneNumber(tonumber(playerId))
            if targetPhone == targetNumber then
                targetSource = tonumber(playerId)
                break
            end
        end
        
        if not targetSource then
            -- Player offline, remove from database only
            local result = MySQL.query.await('SELECT citizenid FROM phone_players WHERE phone_number = ?', {targetNumber})
            if result and #result > 0 then
                MySQL.execute('DELETE FROM player_house_keys WHERE citizenid = ? AND house = ?', {
                    result[1].citizenid,
                    propertyId
                })
            end
            return true
        end
        
        local TargetPlayer = Framework:GetPlayer(targetSource)
        if not TargetPlayer then return false end
        
        local targetCitizenid = TargetPlayer.PlayerData.citizenid
        
        -- Remove key from database
        MySQL.execute('DELETE FROM player_house_keys WHERE citizenid = ? AND house = ?', {
            targetCitizenid,
            propertyId
        })
        
        -- Remove from phone_property_keys
        local phonePropertyId = MySQL.scalar.await('SELECT id FROM phone_properties WHERE property_id = ?', {propertyId})
        if phonePropertyId then
            MySQL.execute('DELETE FROM phone_property_keys WHERE property_id = ? AND holder_number = ?', {
                phonePropertyId,
                targetNumber
            })
        end
        
        -- Notify target player
        if exports['qb-houses'] and exports['qb-houses'].RemoveKey then
            exports['qb-houses']:RemoveKey(targetSource, propertyId)
        end
        
        return true
    end
    
    function adapter:IsLocked(propertyId)
        local houseData = exports['qb-houses']:GetHouseData(propertyId)
        return houseData and houseData.locked or true
    end
    
    function adapter:GetPropertyLocation(propertyId)
        local houseData = exports['qb-houses']:GetHouseData(propertyId)
        if houseData and houseData.coords and houseData.coords.enter then
            return {
                x = houseData.coords.enter.x,
                y = houseData.coords.enter.y,
                z = houseData.coords.enter.z
            }
        end
        return nil
    end
    
    return adapter
end

-- ============================================
-- QS-Housing Adapter Implementation
-- ============================================

function HousingAdapter:InitQSHousing()
    local adapter = setmetatable({}, HousingAdapter)
    adapter.type = 'qs-housing'
    
    function adapter:GetPlayerProperties(source)
        local identifier = Framework:GetIdentifier(source)
        if not identifier then return {} end
        
        -- QS-Housing uses different table structure
        local result = MySQL.query.await('SELECT * FROM player_houses WHERE identifier = ?', {identifier})
        
        local properties = {}
        for _, house in ipairs(result) do
            table.insert(properties, {
                id = house.house,
                name = house.label or house.house,
                location = house.coords and json.decode(house.coords) or nil,
                locked = house.locked == 1,
                owned = true
            })
        end
        
        return properties
    end
    
    function adapter:LockDoor(source, propertyId)
        -- Use QS-Housing export
        if exports['qs-housing'] and exports['qs-housing'].SetLockState then
            exports['qs-housing']:SetLockState(propertyId, true)
            return true
        end
        
        -- Fallback: Update database
        MySQL.update('UPDATE player_houses SET locked = 1 WHERE house = ?', {propertyId})
        return true
    end
    
    function adapter:UnlockDoor(source, propertyId)
        -- Use QS-Housing export
        if exports['qs-housing'] and exports['qs-housing'].SetLockState then
            exports['qs-housing']:SetLockState(propertyId, false)
            return true
        end
        
        -- Fallback: Update database
        MySQL.update('UPDATE player_houses SET locked = 0 WHERE house = ?', {propertyId})
        return true
    end
    
    function adapter:GrantKey(source, propertyId, targetNumber, expiresAt)
        local identifier = Framework:GetIdentifier(source)
        if not identifier then return false end
        
        -- Find target identifier by phone number
        local result = MySQL.query.await('SELECT identifier FROM phone_players WHERE phone_number = ?', {targetNumber})
        if not result or #result == 0 then return false end
        
        local targetIdentifier = result[1].identifier
        
        -- Use QS-Housing export if available
        if exports['qs-housing'] and exports['qs-housing'].GiveKey then
            exports['qs-housing']:GiveKey(propertyId, targetIdentifier)
        else
            -- Fallback: Add to keys table
            MySQL.insert('INSERT INTO house_keys (house, identifier) VALUES (?, ?)', {
                propertyId,
                targetIdentifier
            })
        end
        
        -- Store expiration in phone_property_keys table
        if expiresAt then
            local phonePropertyId = MySQL.scalar.await('SELECT id FROM phone_properties WHERE property_id = ?', {propertyId})
            if phonePropertyId then
                MySQL.insert('INSERT INTO phone_property_keys (property_id, holder_number, granted_by, expires_at) VALUES (?, ?, ?, FROM_UNIXTIME(?))', {
                    phonePropertyId,
                    targetNumber,
                    Framework:GetPhoneNumber(source),
                    expiresAt
                })
            end
        end
        
        return true
    end
    
    function adapter:RevokeKey(source, propertyId, targetNumber)
        -- Find target identifier by phone number
        local result = MySQL.query.await('SELECT identifier FROM phone_players WHERE phone_number = ?', {targetNumber})
        if not result or #result == 0 then return false end
        
        local targetIdentifier = result[1].identifier
        
        -- Use QS-Housing export if available
        if exports['qs-housing'] and exports['qs-housing'].RemoveKey then
            exports['qs-housing']:RemoveKey(propertyId, targetIdentifier)
        else
            -- Fallback: Remove from keys table
            MySQL.execute('DELETE FROM house_keys WHERE house = ? AND identifier = ?', {
                propertyId,
                targetIdentifier
            })
        end
        
        -- Remove from phone_property_keys
        local phonePropertyId = MySQL.scalar.await('SELECT id FROM phone_properties WHERE property_id = ?', {propertyId})
        if phonePropertyId then
            MySQL.execute('DELETE FROM phone_property_keys WHERE property_id = ? AND holder_number = ?', {
                phonePropertyId,
                targetNumber
            })
        end
        
        return true
    end
    
    function adapter:IsLocked(propertyId)
        local result = MySQL.query.await('SELECT locked FROM player_houses WHERE house = ?', {propertyId})
        if not result or #result == 0 then return true end
        return result[1].locked == 1
    end
    
    function adapter:GetPropertyLocation(propertyId)
        local result = MySQL.query.await('SELECT coords FROM player_houses WHERE house = ?', {propertyId})
        if result and #result > 0 and result[1].coords then
            return json.decode(result[1].coords)
        end
        return nil
    end
    
    return adapter
end

-- ============================================
-- CD_EasyHome Adapter Implementation
-- ============================================

function HousingAdapter:InitCDEasyHome()
    local adapter = setmetatable({}, HousingAdapter)
    adapter.type = 'cd_easyhome'
    
    function adapter:GetPlayerProperties(source)
        local identifier = Framework:GetIdentifier(source)
        if not identifier then return {} end
        
        local result = MySQL.query.await('SELECT * FROM cd_easyhome WHERE owner = ?', {identifier})
        
        local properties = {}
        for _, house in ipairs(result) do
            table.insert(properties, {
                id = tostring(house.id),
                name = house.name or 'Property #' .. house.id,
                location = {x = house.x, y = house.y, z = house.z},
                locked = house.locked == 1,
                owned = true
            })
        end
        
        return properties
    end
    
    function adapter:LockDoor(source, propertyId)
        -- Use CD_EasyHome export
        if exports['cd_easyhome'] and exports['cd_easyhome'].SetLocked then
            exports['cd_easyhome']:SetLocked(tonumber(propertyId), true)
            return true
        end
        
        -- Fallback: Update database
        MySQL.update('UPDATE cd_easyhome SET locked = 1 WHERE id = ?', {tonumber(propertyId)})
        return true
    end
    
    function adapter:UnlockDoor(source, propertyId)
        -- Use CD_EasyHome export
        if exports['cd_easyhome'] and exports['cd_easyhome'].SetLocked then
            exports['cd_easyhome']:SetLocked(tonumber(propertyId), false)
            return true
        end
        
        -- Fallback: Update database
        MySQL.update('UPDATE cd_easyhome SET locked = 0 WHERE id = ?', {tonumber(propertyId)})
        return true
    end
    
    function adapter:GrantKey(source, propertyId, targetNumber, expiresAt)
        local identifier = Framework:GetIdentifier(source)
        if not identifier then return false end
        
        -- Find target identifier by phone number
        local result = MySQL.query.await('SELECT identifier FROM phone_players WHERE phone_number = ?', {targetNumber})
        if not result or #result == 0 then return false end
        
        local targetIdentifier = result[1].identifier
        
        -- Add key to CD_EasyHome keys table
        MySQL.insert('INSERT INTO cd_easyhome_keys (house_id, identifier) VALUES (?, ?)', {
            tonumber(propertyId),
            targetIdentifier
        })
        
        -- Store expiration in phone_property_keys table
        if expiresAt then
            local phonePropertyId = MySQL.scalar.await('SELECT id FROM phone_properties WHERE property_id = ?', {propertyId})
            if phonePropertyId then
                MySQL.insert('INSERT INTO phone_property_keys (property_id, holder_number, granted_by, expires_at) VALUES (?, ?, ?, FROM_UNIXTIME(?))', {
                    phonePropertyId,
                    targetNumber,
                    Framework:GetPhoneNumber(source),
                    expiresAt
                })
            end
        end
        
        return true
    end
    
    function adapter:RevokeKey(source, propertyId, targetNumber)
        -- Find target identifier by phone number
        local result = MySQL.query.await('SELECT identifier FROM phone_players WHERE phone_number = ?', {targetNumber})
        if not result or #result == 0 then return false end
        
        local targetIdentifier = result[1].identifier
        
        -- Remove key from CD_EasyHome keys table
        MySQL.execute('DELETE FROM cd_easyhome_keys WHERE house_id = ? AND identifier = ?', {
            tonumber(propertyId),
            targetIdentifier
        })
        
        -- Remove from phone_property_keys
        local phonePropertyId = MySQL.scalar.await('SELECT id FROM phone_properties WHERE property_id = ?', {propertyId})
        if phonePropertyId then
            MySQL.execute('DELETE FROM phone_property_keys WHERE property_id = ? AND holder_number = ?', {
                phonePropertyId,
                targetNumber
            })
        end
        
        return true
    end
    
    function adapter:IsLocked(propertyId)
        local result = MySQL.query.await('SELECT locked FROM cd_easyhome WHERE id = ?', {tonumber(propertyId)})
        if not result or #result == 0 then return true end
        return result[1].locked == 1
    end
    
    function adapter:GetPropertyLocation(propertyId)
        local result = MySQL.query.await('SELECT x, y, z FROM cd_easyhome WHERE id = ?', {tonumber(propertyId)})
        if result and #result > 0 then
            return {x = result[1].x, y = result[1].y, z = result[1].z}
        end
        return nil
    end
    
    return adapter
end

-- ============================================
-- Standalone Adapter Implementation
-- ============================================

function HousingAdapter:InitStandalone()
    local adapter = setmetatable({}, HousingAdapter)
    adapter.type = 'standalone'
    
    function adapter:GetPlayerProperties(source)
        local phoneNumber = Framework:GetPhoneNumber(source)
        if not phoneNumber then return {} end
        
        local result = MySQL.query.await('SELECT * FROM phone_properties WHERE owner_number = ?', {phoneNumber})
        
        local properties = {}
        for _, property in ipairs(result) do
            table.insert(properties, {
                id = property.property_id,
                name = property.property_name or 'Property',
                location = {x = property.location_x, y = property.location_y, z = 0},
                locked = property.locked == 1,
                owned = true
            })
        end
        
        -- Get properties with keys
        local keyResult = MySQL.query.await([[
            SELECT p.* FROM phone_properties p
            INNER JOIN phone_property_keys k ON p.id = k.property_id
            WHERE k.holder_number = ? AND (k.expires_at IS NULL OR k.expires_at > NOW())
        ]], {phoneNumber})
        
        for _, property in ipairs(keyResult) do
            table.insert(properties, {
                id = property.property_id,
                name = property.property_name or 'Property',
                location = {x = property.location_x, y = property.location_y, z = 0},
                locked = property.locked == 1,
                owned = false
            })
        end
        
        return properties
    end
    
    function adapter:LockDoor(source, propertyId)
        local phoneNumber = Framework:GetPhoneNumber(source)
        if not phoneNumber then return false end
        
        MySQL.update('UPDATE phone_properties SET locked = 1 WHERE property_id = ? AND owner_number = ?', {
            propertyId,
            phoneNumber
        })
        
        return true
    end
    
    function adapter:UnlockDoor(source, propertyId)
        local phoneNumber = Framework:GetPhoneNumber(source)
        if not phoneNumber then return false end
        
        MySQL.update('UPDATE phone_properties SET locked = 0 WHERE property_id = ? AND owner_number = ?', {
            propertyId,
            phoneNumber
        })
        
        return true
    end
    
    function adapter:GrantKey(source, propertyId, targetNumber, expiresAt)
        local phoneNumber = Framework:GetPhoneNumber(source)
        if not phoneNumber then return false end
        
        -- Get property database ID
        local result = MySQL.query.await('SELECT id FROM phone_properties WHERE property_id = ? AND owner_number = ?', {
            propertyId,
            phoneNumber
        })
        
        if not result or #result == 0 then return false end
        
        local propertyDbId = result[1].id
        
        -- Grant key
        if expiresAt then
            MySQL.insert('INSERT INTO phone_property_keys (property_id, holder_number, granted_by, expires_at) VALUES (?, ?, ?, FROM_UNIXTIME(?))', {
                propertyDbId,
                targetNumber,
                phoneNumber,
                expiresAt
            })
        else
            MySQL.insert('INSERT INTO phone_property_keys (property_id, holder_number, granted_by) VALUES (?, ?, ?)', {
                propertyDbId,
                targetNumber,
                phoneNumber
            })
        end
        
        return true
    end
    
    function adapter:RevokeKey(source, propertyId, targetNumber)
        local phoneNumber = Framework:GetPhoneNumber(source)
        if not phoneNumber then return false end
        
        -- Get property database ID
        local result = MySQL.query.await('SELECT id FROM phone_properties WHERE property_id = ? AND owner_number = ?', {
            propertyId,
            phoneNumber
        })
        
        if not result or #result == 0 then return false end
        
        local propertyDbId = result[1].id
        
        -- Revoke key
        MySQL.execute('DELETE FROM phone_property_keys WHERE property_id = ? AND holder_number = ?', {
            propertyDbId,
            targetNumber
        })
        
        return true
    end
    
    function adapter:IsLocked(propertyId)
        local result = MySQL.query.await('SELECT locked FROM phone_properties WHERE property_id = ?', {propertyId})
        if not result or #result == 0 then return true end
        return result[1].locked == 1
    end
    
    function adapter:GetPropertyLocation(propertyId)
        local result = MySQL.query.await('SELECT location_x, location_y FROM phone_properties WHERE property_id = ?', {propertyId})
        if result and #result > 0 then
            return {x = result[1].location_x, y = result[1].location_y, z = 0}
        end
        return nil
    end
    
    return adapter
end

return HousingAdapter
