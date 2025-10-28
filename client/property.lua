-- Property Management Client Module
-- Handles door lock/unlock commands, security system integration, and access log tracking

local PropertyManagement = {}
local playerProperties = {}
local nearbyProperties = {}
local propertyCheckInterval = 5000 -- 5 seconds
local propertyCheckEnabled = false
local accessLogCache = {} -- Cache for access logs
local securityAlarmActive = {} -- Track active security alarms

-- Initialize property management
function PropertyManagement:Init()
    if not Config.HomeApp or not Config.HomeApp.enabled then
        return
    end
    
    propertyCheckEnabled = true
    propertyCheckInterval = 5000 -- Default 5 seconds
    
    self:StartPropertyCheck()
    self:InitializeAccessLogSystem()
    self:InitializeSecuritySystem()
    
    print('[Phone] Property management initialized')
end

-- Initialize access log system
function PropertyManagement:InitializeAccessLogSystem()
    if not Config.HomeApp.enableAccessLogs then
        return
    end
    
    -- Request access logs from server for player properties
    TriggerServerEvent('phone:home:requestAccessLogs')
    
    print('[Phone] Access log system initialized')
end

-- Initialize security system
function PropertyManagement:InitializeSecuritySystem()
    -- Initialize security alarm tracking
    securityAlarmActive = {}
    
    print('[Phone] Security system initialized')
end

-- Start property proximity check
function PropertyManagement:StartPropertyCheck()
    CreateThread(function()
        while propertyCheckEnabled do
            Wait(propertyCheckInterval)
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            
            -- Check proximity to player properties
            for propertyId, property in pairs(playerProperties) do
                if property.location then
                    local distance = #(playerCoords - vector3(
                        property.location.x,
                        property.location.y,
                        property.location.z or 0.0
                    ))
                    
                    -- Within 50 meters
                    if distance < 50.0 then
                        nearbyProperties[propertyId] = property
                    else
                        nearbyProperties[propertyId] = nil
                    end
                end
            end
        end
    end)
end

-- Lock property door
function PropertyManagement:LockDoor(propertyId)
    if not propertyId then return false end
    
    local property = playerProperties[propertyId]
    if not property then
        TriggerEvent('phone:notification', {
            title = 'Home',
            message = 'Property not found',
            type = 'error'
        })
        return false
    end
    
    -- Check if remote lock is enabled
    if not Config.HomeApp.enableRemoteLock then
        TriggerEvent('phone:notification', {
            title = 'Home',
            message = 'Remote lock is disabled',
            type = 'error'
        })
        return false
    end
    
    -- Trigger server event to lock door via housing adapter
    TriggerServerEvent('phone:home:lockDoor', propertyId)
    
    -- Play lock sound
    self:PlayLockSound(true)
    
    -- Log the access
    self:LogAccess(propertyId, 'lock', 'remote')
    
    -- Show notification
    TriggerEvent('phone:notification', {
        title = 'Home',
        message = 'Property locked remotely',
        type = 'success'
    })
    
    -- Update local property state
    if playerProperties[propertyId] then
        playerProperties[propertyId].locked = true
    end
    
    return true
end

-- Unlock property door
function PropertyManagement:UnlockDoor(propertyId)
    if not propertyId then return false end
    
    local property = playerProperties[propertyId]
    if not property then
        TriggerEvent('phone:notification', {
            title = 'Home',
            message = 'Property not found',
            type = 'error'
        })
        return false
    end
    
    -- Check if remote lock is enabled
    if not Config.HomeApp.enableRemoteLock then
        TriggerEvent('phone:notification', {
            title = 'Home',
            message = 'Remote lock is disabled',
            type = 'error'
        })
        return false
    end
    
    -- Trigger server event to unlock door via housing adapter
    TriggerServerEvent('phone:home:unlockDoor', propertyId)
    
    -- Play unlock sound
    self:PlayLockSound(false)
    
    -- Log the access
    self:LogAccess(propertyId, 'unlock', 'remote')
    
    -- Show notification
    TriggerEvent('phone:notification', {
        title = 'Home',
        message = 'Property unlocked remotely',
        type = 'success'
    })
    
    -- Update local property state
    if playerProperties[propertyId] then
        playerProperties[propertyId].locked = false
    end
    
    return true
end

-- Toggle property door lock
function PropertyManagement:ToggleDoorLock(propertyId)
    if not propertyId then return false end
    
    local property = playerProperties[propertyId]
    if not property then return false end
    
    if property.locked then
        return self:UnlockDoor(propertyId)
    else
        return self:LockDoor(propertyId)
    end
end

-- Play lock/unlock sound
function PropertyManagement:PlayLockSound(locked)
    if not Config.HomeApp.enableSounds then return end
    
    local soundName = locked and 'DOOR_LOCK' or 'DOOR_UNLOCK'
    local soundSet = 'GTAO_APARTMENT_DOOR_DOWNSTAIRS_GLASS_SOUNDS'
    
    PlaySoundFrontend(-1, soundName, soundSet, true)
end

-- Register player property
function PropertyManagement:RegisterProperty(propertyId, propertyData)
    playerProperties[propertyId] = propertyData
end

-- Unregister player property
function PropertyManagement:UnregisterProperty(propertyId)
    playerProperties[propertyId] = nil
    nearbyProperties[propertyId] = nil
end

-- Update property lock status
function PropertyManagement:UpdatePropertyLockStatus(propertyId, locked)
    if playerProperties[propertyId] then
        playerProperties[propertyId].locked = locked
    end
    
    -- Update NUI
    SendNUIMessage({
        action = 'home:propertyUpdated',
        data = {
            propertyId = propertyId,
            locked = locked
        }
    })
end

-- Get nearby properties
function PropertyManagement:GetNearbyProperties()
    return nearbyProperties
end

-- Check if player is near property
function PropertyManagement:IsNearProperty(propertyId)
    return nearbyProperties[propertyId] ~= nil
end

-- Security system integration
function PropertyManagement:TriggerSecurityAlarm(propertyId, reason)
    reason = reason or 'unauthorized_access'
    
    -- Check if alarm is already active for this property
    if securityAlarmActive[propertyId] then
        return
    end
    
    -- Mark alarm as active
    securityAlarmActive[propertyId] = true
    
    -- Play alarm sound
    local alarmSound = 'ALARM_KLAXON'
    local alarmSet = 'HUD_MINI_GAME_SOUNDSET'
    
    PlaySoundFrontend(-1, alarmSound, alarmSet, true)
    
    -- Show notification
    TriggerEvent('phone:notification', {
        title = 'Security Alert',
        message = 'Property alarm triggered! Reason: ' .. reason,
        type = 'error',
        duration = 10000
    })
    
    -- Log the security event
    self:LogAccess(propertyId, 'security_alarm', reason)
    
    -- Notify server (which will notify police if configured)
    TriggerServerEvent('phone:home:securityAlarm', propertyId, reason)
    
    -- Auto-disable alarm after 30 seconds
    SetTimeout(30000, function()
        securityAlarmActive[propertyId] = false
    end)
end

-- Disable security alarm
function PropertyManagement:DisableSecurityAlarm(propertyId)
    if not propertyId then return false end
    
    securityAlarmActive[propertyId] = false
    
    -- Stop alarm sound
    StopSound(-1)
    
    -- Show notification
    TriggerEvent('phone:notification', {
        title = 'Security',
        message = 'Security alarm disabled',
        type = 'success'
    })
    
    -- Log the action
    self:LogAccess(propertyId, 'alarm_disabled', 'manual')
    
    return true
end

-- Check security system status
function PropertyManagement:GetSecurityStatus(propertyId)
    if not propertyId then return nil end
    
    local property = playerProperties[propertyId]
    if not property then return nil end
    
    return {
        propertyId = propertyId,
        alarmActive = securityAlarmActive[propertyId] or false,
        locked = property.locked or false,
        hasAccess = property.owned or property.hasKey or false,
        lastAccess = property.lastAccess or nil
    }
end

-- Access log tracking
function PropertyManagement:LogAccess(propertyId, action, details)
    if not Config.HomeApp.enableAccessLogs then
        return
    end
    
    if not propertyId or not action then
        return
    end
    
    local timestamp = os.time()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    local logEntry = {
        propertyId = propertyId,
        action = action,
        details = details or '',
        timestamp = timestamp,
        location = {
            x = playerCoords.x,
            y = playerCoords.y,
            z = playerCoords.z
        }
    }
    
    -- Add to local cache
    if not accessLogCache[propertyId] then
        accessLogCache[propertyId] = {}
    end
    
    table.insert(accessLogCache[propertyId], 1, logEntry)
    
    -- Limit cache size
    local maxLogs = Config.HomeApp.maxAccessLogs or 50
    if #accessLogCache[propertyId] > maxLogs then
        table.remove(accessLogCache[propertyId])
    end
    
    -- Send to server for persistent storage
    TriggerServerEvent('phone:home:logAccess', propertyId, action, details, timestamp)
    
    -- Update NUI with new log entry
    SendNUIMessage({
        action = 'home:accessLogAdded',
        data = logEntry
    })
end

-- Get access logs for a property
function PropertyManagement:GetAccessLogs(propertyId, limit)
    if not propertyId then return {} end
    
    limit = limit or (Config.HomeApp.maxAccessLogs or 50)
    
    local logs = accessLogCache[propertyId] or {}
    
    -- Return limited number of logs
    local result = {}
    for i = 1, math.min(#logs, limit) do
        table.insert(result, logs[i])
    end
    
    return result
end

-- Clear access logs for a property
function PropertyManagement:ClearAccessLogs(propertyId)
    if not propertyId then return false end
    
    accessLogCache[propertyId] = {}
    
    -- Notify server to clear logs
    TriggerServerEvent('phone:home:clearAccessLogs', propertyId)
    
    -- Update NUI
    SendNUIMessage({
        action = 'home:accessLogsCleared',
        data = {
            propertyId = propertyId
        }
    })
    
    return true
end

-- Update access logs from server
function PropertyManagement:UpdateAccessLogs(propertyId, logs)
    if not propertyId or not logs then return end
    
    accessLogCache[propertyId] = logs
    
    -- Update NUI
    SendNUIMessage({
        action = 'home:accessLogsUpdated',
        data = {
            propertyId = propertyId,
            logs = logs
        }
    })
end

-- Handle property door interaction (physical interaction at property)
function PropertyManagement:HandleDoorInteraction(propertyId, doorEntity)
    if not propertyId then return end
    
    local property = playerProperties[propertyId]
    if not property then
        TriggerEvent('phone:notification', {
            title = 'Home',
            message = 'Property not found',
            type = 'error'
        })
        return
    end
    
    -- Check if player has access
    local hasAccess = self:VerifyAccess(propertyId)
    
    if not hasAccess then
        -- Trigger security alarm for unauthorized access
        self:TriggerSecurityAlarm(propertyId, 'unauthorized_door_access')
        
        TriggerEvent('phone:notification', {
            title = 'Access Denied',
            message = 'You do not have access to this property',
            type = 'error'
        })
        return
    end
    
    -- Toggle door lock
    if property.locked then
        self:UnlockDoor(propertyId)
        self:LogAccess(propertyId, 'unlock', 'physical_interaction')
    else
        self:LockDoor(propertyId)
        self:LogAccess(propertyId, 'lock', 'physical_interaction')
    end
    
    -- If door entity is provided, update its state
    if doorEntity and DoesEntityExist(doorEntity) then
        local locked = not property.locked
        FreezeEntityPosition(doorEntity, locked)
    end
end

-- Handle remote door command from phone app
function PropertyManagement:HandleRemoteDoorCommand(propertyId, command)
    if not propertyId or not command then return false end
    
    local property = playerProperties[propertyId]
    if not property then
        TriggerEvent('phone:notification', {
            title = 'Home',
            message = 'Property not found',
            type = 'error'
        })
        return false
    end
    
    -- Verify access
    if not self:VerifyAccess(propertyId) then
        TriggerEvent('phone:notification', {
            title = 'Access Denied',
            message = 'You do not have access to this property',
            type = 'error'
        })
        return false
    end
    
    -- Execute command
    if command == 'lock' then
        return self:LockDoor(propertyId)
    elseif command == 'unlock' then
        return self:UnlockDoor(propertyId)
    elseif command == 'toggle' then
        return self:ToggleDoorLock(propertyId)
    elseif command == 'alarm_disable' then
        return self:DisableSecurityAlarm(propertyId)
    else
        TriggerEvent('phone:notification', {
            title = 'Error',
            message = 'Unknown command: ' .. command,
            type = 'error'
        })
        return false
    end
end

-- Verify player has access to property
function PropertyManagement:VerifyAccess(propertyId)
    -- This is a client-side check, server will verify as well
    local property = playerProperties[propertyId]
    if not property then return false end
    
    -- Player owns the property or has a key
    return property.owned or property.hasKey
end

-- Set property waypoint
function PropertyManagement:SetWaypointToProperty(propertyId)
    local property = playerProperties[propertyId]
    if not property or not property.location then
        return false
    end
    
    SetNewWaypoint(property.location.x, property.location.y)
    
    -- Show notification
    TriggerEvent('phone:notification', {
        title = 'Home',
        message = 'Waypoint set to property',
        type = 'success'
    })
    
    return true
end

-- Handle property update from server
function PropertyManagement:OnPropertyUpdate(data)
    if not data or not data.propertyId then return end
    
    self:UpdatePropertyLockStatus(data.propertyId, data.locked)
    
    -- Play sound if player is nearby
    if self:IsNearProperty(data.propertyId) then
        self:PlayLockSound(data.locked)
    end
end

-- Handle key granted notification
function PropertyManagement:OnKeyGranted(data)
    if not data or not data.propertyId then return end
    
    -- Register property with key access
    self:RegisterProperty(data.propertyId, {
        id = data.propertyId,
        name = data.propertyName or 'Property',
        location = data.location,
        locked = data.locked or true,
        owned = false,
        hasKey = true
    })
    
    -- Show notification
    TriggerEvent('phone:notification', {
        title = 'Home',
        message = 'You have been granted access to ' .. (data.propertyName or 'a property'),
        type = 'success'
    })
end

-- Handle key revoked notification
function PropertyManagement:OnKeyRevoked(data)
    if not data or not data.propertyId then return end
    
    -- Unregister property
    self:UnregisterProperty(data.propertyId)
    
    -- Show notification
    TriggerEvent('phone:notification', {
        title = 'Home',
        message = 'Your access to ' .. (data.propertyName or 'a property') .. ' has been revoked',
        type = 'warning'
    })
end

-- Client event handlers
RegisterNetEvent('phone:home:propertyUpdated')
AddEventHandler('phone:home:propertyUpdated', function(data)
    PropertyManagement:OnPropertyUpdate(data)
end)

RegisterNetEvent('phone:home:keyGranted')
AddEventHandler('phone:home:keyGranted', function(data)
    PropertyManagement:OnKeyGranted(data)
end)

RegisterNetEvent('phone:home:keyRevoked')
AddEventHandler('phone:home:keyRevoked', function(data)
    PropertyManagement:OnKeyRevoked(data)
end)

RegisterNetEvent('phone:home:registerProperty')
AddEventHandler('phone:home:registerProperty', function(propertyId, propertyData)
    PropertyManagement:RegisterProperty(propertyId, propertyData)
end)

RegisterNetEvent('phone:home:unregisterProperty')
AddEventHandler('phone:home:unregisterProperty', function(propertyId)
    PropertyManagement:UnregisterProperty(propertyId)
end)

RegisterNetEvent('phone:home:setWaypoint')
AddEventHandler('phone:home:setWaypoint', function(propertyId)
    PropertyManagement:SetWaypointToProperty(propertyId)
end)

RegisterNetEvent('phone:home:lockDoor')
AddEventHandler('phone:home:lockDoor', function(propertyId)
    PropertyManagement:LockDoor(propertyId)
end)

RegisterNetEvent('phone:home:unlockDoor')
AddEventHandler('phone:home:unlockDoor', function(propertyId)
    PropertyManagement:UnlockDoor(propertyId)
end)

RegisterNetEvent('phone:home:toggleDoor')
AddEventHandler('phone:home:toggleDoor', function(propertyId)
    PropertyManagement:ToggleDoorLock(propertyId)
end)

RegisterNetEvent('phone:home:securityAlarm')
AddEventHandler('phone:home:securityAlarm', function(propertyId, reason)
    PropertyManagement:TriggerSecurityAlarm(propertyId, reason)
end)

RegisterNetEvent('phone:home:disableAlarm')
AddEventHandler('phone:home:disableAlarm', function(propertyId)
    PropertyManagement:DisableSecurityAlarm(propertyId)
end)

RegisterNetEvent('phone:home:accessLogsUpdated')
AddEventHandler('phone:home:accessLogsUpdated', function(propertyId, logs)
    PropertyManagement:UpdateAccessLogs(propertyId, logs)
end)

RegisterNetEvent('phone:home:securityStatusUpdated')
AddEventHandler('phone:home:securityStatusUpdated', function(propertyId, status)
    -- Update NUI with security status
    SendNUIMessage({
        action = 'home:securityStatusUpdated',
        data = {
            propertyId = propertyId,
            status = status
        }
    })
end)

-- NUI Callbacks for phone app interactions
RegisterNUICallback('home:lockDoor', function(data, cb)
    local success = PropertyManagement:LockDoor(data.propertyId)
    cb({success = success})
end)

RegisterNUICallback('home:unlockDoor', function(data, cb)
    local success = PropertyManagement:UnlockDoor(data.propertyId)
    cb({success = success})
end)

RegisterNUICallback('home:toggleDoor', function(data, cb)
    local success = PropertyManagement:ToggleDoorLock(data.propertyId)
    cb({success = success})
end)

RegisterNUICallback('home:getAccessLogs', function(data, cb)
    local logs = PropertyManagement:GetAccessLogs(data.propertyId, data.limit)
    cb({success = true, logs = logs})
end)

RegisterNUICallback('home:clearAccessLogs', function(data, cb)
    local success = PropertyManagement:ClearAccessLogs(data.propertyId)
    cb({success = success})
end)

RegisterNUICallback('home:getSecurityStatus', function(data, cb)
    local status = PropertyManagement:GetSecurityStatus(data.propertyId)
    cb({success = status ~= nil, status = status})
end)

RegisterNUICallback('home:disableAlarm', function(data, cb)
    local success = PropertyManagement:DisableSecurityAlarm(data.propertyId)
    cb({success = success})
end)

RegisterNUICallback('home:setWaypoint', function(data, cb)
    local success = PropertyManagement:SetWaypointToProperty(data.propertyId)
    cb({success = success})
end)

RegisterNUICallback('home:remoteDoorCommand', function(data, cb)
    local success = PropertyManagement:HandleRemoteDoorCommand(data.propertyId, data.command)
    cb({success = success})
end)

-- Server event handlers (for client-to-server communication)
RegisterServerEvent('phone:home:lockDoor')
RegisterServerEvent('phone:home:unlockDoor')
RegisterServerEvent('phone:home:logAccess')
RegisterServerEvent('phone:home:securityAlarm')
RegisterServerEvent('phone:home:clearAccessLogs')
RegisterServerEvent('phone:home:requestAccessLogs')

-- Get all player properties
function PropertyManagement:GetAllProperties()
    return playerProperties
end

-- Get property by ID
function PropertyManagement:GetProperty(propertyId)
    return playerProperties[propertyId]
end

-- Check if property exists
function PropertyManagement:HasProperty(propertyId)
    return playerProperties[propertyId] ~= nil
end

-- Get property count
function PropertyManagement:GetPropertyCount()
    local count = 0
    for _ in pairs(playerProperties) do
        count = count + 1
    end
    return count
end

-- Sync property data with server
function PropertyManagement:SyncPropertyData()
    TriggerServerEvent('phone:home:syncProperties')
end

-- Handle property sync response from server
function PropertyManagement:OnPropertiesSync(properties)
    if not properties then return end
    
    -- Update local property cache
    for propertyId, propertyData in pairs(properties) do
        self:RegisterProperty(propertyId, propertyData)
    end
    
    -- Update NUI
    SendNUIMessage({
        action = 'home:propertiesSynced',
        data = {
            properties = properties
        }
    })
    
    print('[Phone] Synced ' .. self:GetPropertyCount() .. ' properties')
end

-- Export functions for other resources
exports('GetPropertyManagement', function()
    return PropertyManagement
end)

exports('LockDoor', function(propertyId)
    return PropertyManagement:LockDoor(propertyId)
end)

exports('UnlockDoor', function(propertyId)
    return PropertyManagement:UnlockDoor(propertyId)
end)

exports('GetSecurityStatus', function(propertyId)
    return PropertyManagement:GetSecurityStatus(propertyId)
end)

exports('GetAccessLogs', function(propertyId, limit)
    return PropertyManagement:GetAccessLogs(propertyId, limit)
end)

-- Additional event handler for property sync
RegisterNetEvent('phone:home:propertiesSync')
AddEventHandler('phone:home:propertiesSync', function(properties)
    PropertyManagement:OnPropertiesSync(properties)
end)

-- Initialize on resource start
CreateThread(function()
    Wait(1000)
    PropertyManagement:Init()
    
    -- Request initial property sync
    Wait(2000)
    PropertyManagement:SyncPropertyData()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    propertyCheckEnabled = false
    playerProperties = {}
    nearbyProperties = {}
    accessLogCache = {}
    securityAlarmActive = {}
    
    print('[Phone] Property management cleaned up')
end)

return PropertyManagement
