-- Finder App Server Logic
-- Handles device tracking, location management, and device operations

-- Initialize Finder data for player
RegisterNetEvent('phone:server:getFinderData', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveFinderData', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Get user's registered devices
    local devices = MySQL.query.await([[
        SELECT 
            id,
            device_name,
            device_type,
            last_location_x,
            last_location_y,
            last_location_z,
            is_lost,
            is_online,
            battery_level,
            UNIX_TIMESTAMP(last_seen) * 1000 as lastSeen,
            UNIX_TIMESTAMP(created_at) * 1000 as createdAt
        FROM phone_finder_devices
        WHERE owner_number = ?
        ORDER BY last_seen DESC
    ]], {
        phoneNumber
    })
    
    -- Get user settings
    local settings = MySQL.query.await([[
        SELECT 
            location_services,
            auto_refresh,
            sound_alerts,
            privacy_mode,
            share_location
        FROM phone_finder_settings
        WHERE phone_number = ?
    ]], {
        phoneNumber
    })
    
    local userSettings = {
        locationServices = true,
        autoRefresh = true,
        soundAlerts = true,
        privacyMode = false,
        shareLocation = false
    }
    
    if settings and #settings > 0 then
        userSettings = {
            locationServices = settings[1].location_services == 1,
            autoRefresh = settings[1].auto_refresh == 1,
            soundAlerts = settings[1].sound_alerts == 1,
            privacyMode = settings[1].privacy_mode == 1,
            shareLocation = settings[1].share_location == 1
        }
    end
    
    TriggerClientEvent('phone:client:receiveFinderData', source, {
        success = true,
        devices = devices or {},
        settings = userSettings
    })
end)

-- Add new device to tracking
RegisterNetEvent('phone:server:addFinderDevice', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:addDeviceResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    local deviceName = data.deviceName
    local deviceType = data.deviceType or 'phone'
    
    -- Validation
    if not deviceName or string.len(deviceName) < 1 then
        TriggerClientEvent('phone:client:addDeviceResult', source, {
            success = false,
            message = 'Device name is required'
        })
        return
    end
    
    -- Get current player location
    local playerPed = GetPlayerPed(source)
    local coords = GetEntityCoords(playerPed)
    
    -- Insert device
    local deviceId = MySQL.insert.await([[
        INSERT INTO phone_finder_devices 
        (owner_number, device_name, device_type, last_location_x, last_location_y, last_location_z, is_online, battery_level)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        phoneNumber,
        deviceName,
        deviceType,
        coords.x,
        coords.y,
        coords.z,
        1, -- is_online
        math.random(80, 100) -- battery_level
    })
    
    if deviceId then
        TriggerClientEvent('phone:client:addDeviceResult', source, {
            success = true,
            message = 'Device added successfully',
            device = {
                id = deviceId,
                deviceName = deviceName,
                deviceType = deviceType,
                lastLocationX = coords.x,
                lastLocationY = coords.y,
                lastLocationZ = coords.z,
                isLost = false,
                isOnline = true,
                batteryLevel = math.random(80, 100),
                lastSeen = os.time() * 1000,
                createdAt = os.time() * 1000
            }
        })
    else
        TriggerClientEvent('phone:client:addDeviceResult', source, {
            success = false,
            message = 'Failed to add device'
        })
    end
end)

-- Update device location
RegisterNetEvent('phone:server:updateDeviceLocation', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local deviceId = data.deviceId
    local coords = data.coords or GetEntityCoords(GetPlayerPed(source))
    
    -- Update device location and last seen
    MySQL.update.await([[
        UPDATE phone_finder_devices 
        SET last_location_x = ?, last_location_y = ?, last_location_z = ?, last_seen = NOW()
        WHERE id = ?
    ]], {
        coords.x,
        coords.y,
        coords.z,
        deviceId
    })
    
    TriggerClientEvent('phone:client:deviceLocationUpdated', source, {
        success = true,
        deviceId = deviceId,
        location = coords
    })
end)

-- Play sound on device
RegisterNetEvent('phone:server:playDeviceSound', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local deviceId = data.deviceId
    
    -- Get device info
    local device = MySQL.query.await([[
        SELECT device_name, device_type, last_location_x, last_location_y, last_location_z
        FROM phone_finder_devices
        WHERE id = ?
    ]], {
        deviceId
    })
    
    if not device or #device == 0 then
        TriggerClientEvent('phone:client:playDeviceSoundResult', source, {
            success = false,
            message = 'Device not found'
        })
        return
    end
    
    local deviceData = device[1]
    local coords = vector3(deviceData.last_location_x, deviceData.last_location_y, deviceData.last_location_z)
    
    -- Play sound for all nearby players
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerCoords = GetEntityCoords(GetPlayerPed(tonumber(playerId)))
        local distance = #(playerCoords - coords)
        
        if distance <= 50.0 then -- 50 meter radius
            TriggerClientEvent('phone:client:playFinderSound', tonumber(playerId), {
                deviceName = deviceData.device_name,
                deviceType = deviceData.device_type,
                location = coords
            })
        end
    end
    
    TriggerClientEvent('phone:client:playDeviceSoundResult', source, {
        success = true,
        message = 'Sound played on ' .. deviceData.device_name
    })
end)

-- Mark device as lost/found
RegisterNetEvent('phone:server:toggleDeviceLost', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local deviceId = data.deviceId
    local isLost = data.isLost
    
    -- Update device lost status
    MySQL.update.await([[
        UPDATE phone_finder_devices 
        SET is_lost = ?
        WHERE id = ?
    ]], {
        isLost and 1 or 0,
        deviceId
    })
    
    TriggerClientEvent('phone:client:deviceLostStatusUpdated', source, {
        success = true,
        deviceId = deviceId,
        isLost = isLost
    })
end)

-- Remove device from tracking
RegisterNetEvent('phone:server:removeFinderDevice', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    local deviceId = data.deviceId
    
    -- Delete device (only if owned by player)
    local affectedRows = MySQL.update.await([[
        DELETE FROM phone_finder_devices 
        WHERE id = ? AND owner_number = ?
    ]], {
        deviceId,
        phoneNumber
    })
    
    if affectedRows > 0 then
        TriggerClientEvent('phone:client:removeDeviceResult', source, {
            success = true,
            message = 'Device removed successfully',
            deviceId = deviceId
        })
    else
        TriggerClientEvent('phone:client:removeDeviceResult', source, {
            success = false,
            message = 'Device not found or access denied'
        })
    end
end)

-- Update Finder settings
RegisterNetEvent('phone:server:updateFinderSettings', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:updateFinderSettingsResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    local settings = data.settings
    
    -- Update or insert settings
    MySQL.query.await([[
        INSERT INTO phone_finder_settings 
        (phone_number, location_services, auto_refresh, sound_alerts, privacy_mode, share_location)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        location_services = VALUES(location_services),
        auto_refresh = VALUES(auto_refresh),
        sound_alerts = VALUES(sound_alerts),
        privacy_mode = VALUES(privacy_mode),
        share_location = VALUES(share_location)
    ]], {
        phoneNumber,
        settings.locationServices and 1 or 0,
        settings.autoRefresh and 1 or 0,
        settings.soundAlerts and 1 or 0,
        settings.privacyMode and 1 or 0,
        settings.shareLocation and 1 or 0
    })
    
    TriggerClientEvent('phone:client:updateFinderSettingsResult', source, {
        success = true,
        message = 'Settings updated successfully'
    })
end)

-- Get device details
RegisterNetEvent('phone:server:getDeviceDetails', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local deviceId = data.deviceId
    
    -- Get detailed device information
    local device = MySQL.query.await([[
        SELECT 
            id,
            device_name,
            device_type,
            last_location_x,
            last_location_y,
            last_location_z,
            is_lost,
            is_online,
            battery_level,
            UNIX_TIMESTAMP(last_seen) * 1000 as lastSeen,
            UNIX_TIMESTAMP(created_at) * 1000 as createdAt
        FROM phone_finder_devices
        WHERE id = ?
    ]], {
        deviceId
    })
    
    if device and #device > 0 then
        TriggerClientEvent('phone:client:receiveDeviceDetails', source, {
            success = true,
            device = device[1]
        })
    else
        TriggerClientEvent('phone:client:receiveDeviceDetails', source, {
            success = false,
            message = 'Device not found'
        })
    end
end)

-- Auto-update device locations (for online devices)
CreateThread(function()
    while true do
        Wait(30000) -- Update every 30 seconds
        
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            local source = tonumber(playerId)
            if Framework:PlayerExists(source) then
                local phoneNumber = Framework:GetPhoneNumber(source)
                if phoneNumber then
                    local coords = GetEntityCoords(GetPlayerPed(source))
                    
                    -- Update player's phone location
                    MySQL.update.await([[
                        UPDATE phone_finder_devices 
                        SET last_location_x = ?, last_location_y = ?, last_location_z = ?, 
                            last_seen = NOW(), is_online = 1, battery_level = ?
                        WHERE owner_number = ? AND device_type = 'phone'
                    ]], {
                        coords.x,
                        coords.y,
                        coords.z,
                        math.random(20, 100), -- Simulate battery drain
                        phoneNumber
                    })
                end
            end
        end
    end
end)

-- Mark offline devices
CreateThread(function()
    while true do
        Wait(300000) -- Check every 5 minutes
        
        -- Mark devices as offline if not seen for 10 minutes
        MySQL.update.await([[
            UPDATE phone_finder_devices 
            SET is_online = 0 
            WHERE last_seen < DATE_SUB(NOW(), INTERVAL 10 MINUTE)
        ]])
    end
end)