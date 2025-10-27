-- Location Tracking Module for Maps App
-- Handles GPS coordinate tracking, location updates, and waypoint management

local playerLocation = { x = 0.0, y = 0.0, z = 0.0 }
local isTrackingLocation = false
local locationUpdateInterval = 5000 -- 5 seconds
local sharedLocations = {}

-- Initialize location tracking
CreateThread(function()
    while true do
        Wait(locationUpdateInterval)
        
        if isTrackingLocation then
            UpdatePlayerLocation()
        end
    end
end)

-- Update player's current location
function UpdatePlayerLocation()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    playerLocation = {
        x = coords.x,
        y = coords.y,
        z = coords.z
    }
    
    -- Broadcast location update to NUI if phone is open
    SendNUIMessage({
        action = 'updatePlayerLocation',
        location = playerLocation
    })
end

-- Get current player location
function GetPlayerLocation()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    return {
        x = coords.x,
        y = coords.y,
        z = coords.z
    }
end

-- Start location tracking
function StartLocationTracking()
    isTrackingLocation = true
    UpdatePlayerLocation()
end

-- Stop location tracking
function StopLocationTracking()
    isTrackingLocation = false
end

-- Set GPS waypoint
function SetWaypoint(x, y)
    SetNewWaypoint(x, y)
    
    -- Show notification
    TriggerEvent('phone:client:notification', {
        app = 'maps',
        title = 'Maps',
        message = 'Waypoint set',
        icon = 'maps'
    })
end

-- Clear GPS waypoint
function ClearWaypoint()
    DeleteWaypoint()
end

-- Calculate distance between two points
function CalculateDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- NUI Callbacks for Maps App

-- Get player location
RegisterNUICallback('getPlayerLocation', function(data, cb)
    local location = GetPlayerLocation()
    
    cb({
        success = true,
        location = location
    })
end)

-- Get location pins
RegisterNUICallback('getLocationPins', function(data, cb)
    TriggerServerEvent('phone:server:getLocationPins')
    
    -- Wait for server response
    local timeout = 0
    local response = nil
    
    local handler = nil
    handler = RegisterNetEvent('phone:client:receiveLocationPins', function(data)
        response = data
        RemoveEventHandler(handler)
    end)
    
    while not response and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if response then
        cb(response)
    else
        cb({
            success = false,
            error = 'TIMEOUT'
        })
    end
end)

-- Create location pin
RegisterNUICallback('createLocationPin', function(data, cb)
    TriggerServerEvent('phone:server:createLocationPin', data)
    
    -- Wait for server response
    local timeout = 0
    local response = nil
    
    local handler = nil
    handler = RegisterNetEvent('phone:client:locationPinCreated', function(responseData)
        response = responseData
        RemoveEventHandler(handler)
    end)
    
    while not response and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if response then
        cb(response)
    else
        cb({
            success = false,
            error = 'TIMEOUT'
        })
    end
end)

-- Update location pin
RegisterNUICallback('updateLocationPin', function(data, cb)
    TriggerServerEvent('phone:server:updateLocationPin', data)
    
    -- Wait for server response
    local timeout = 0
    local response = nil
    
    local handler = nil
    handler = RegisterNetEvent('phone:client:locationPinUpdated', function(responseData)
        response = responseData
        RemoveEventHandler(handler)
    end)
    
    while not response and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if response then
        cb(response)
    else
        cb({
            success = false,
            error = 'TIMEOUT'
        })
    end
end)

-- Delete location pin
RegisterNUICallback('deleteLocationPin', function(data, cb)
    TriggerServerEvent('phone:server:deleteLocationPin', data)
    
    -- Wait for server response
    local timeout = 0
    local response = nil
    
    local handler = nil
    handler = RegisterNetEvent('phone:client:locationPinDeleted', function(responseData)
        response = responseData
        RemoveEventHandler(handler)
    end)
    
    while not response and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if response then
        cb(response)
    else
        cb({
            success = false,
            error = 'TIMEOUT'
        })
    end
end)

-- Set waypoint
RegisterNUICallback('setWaypoint', function(data, cb)
    if data.x and data.y then
        SetWaypoint(data.x, data.y)
        
        cb({
            success = true
        })
    else
        cb({
            success = false,
            error = 'INVALID_COORDINATES'
        })
    end
end)

-- Get shared locations
RegisterNUICallback('getSharedLocations', function(data, cb)
    TriggerServerEvent('phone:server:getSharedLocations')
    
    -- Wait for server response
    local timeout = 0
    local response = nil
    
    local handler = nil
    handler = RegisterNetEvent('phone:client:receiveSharedLocations', function(responseData)
        response = responseData
        RemoveEventHandler(handler)
    end)
    
    while not response and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if response then
        cb(response)
    else
        cb({
            success = false,
            error = 'TIMEOUT'
        })
    end
end)

-- Share location
RegisterNUICallback('shareLocation', function(data, cb)
    TriggerServerEvent('phone:server:shareLocation', data)
    
    -- Wait for server response
    local timeout = 0
    local response = nil
    
    local handler = nil
    handler = RegisterNetEvent('phone:client:locationShared', function(responseData)
        response = responseData
        RemoveEventHandler(handler)
    end)
    
    while not response and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if response then
        cb(response)
    else
        cb({
            success = false,
            error = 'TIMEOUT'
        })
    end
end)

-- Handle received shared location
RegisterNetEvent('phone:client:sharedLocationReceived', function(data)
    -- Add to shared locations list
    table.insert(sharedLocations, data)
    
    -- Update NUI
    SendNUIMessage({
        action = 'sharedLocationReceived',
        location = data
    })
    
    -- Show notification
    TriggerEvent('phone:client:notification', {
        app = 'maps',
        title = 'Location Shared',
        message = data.name .. ' shared their location with you',
        icon = 'maps'
    })
end)

-- Exports
exports('GetPlayerLocation', GetPlayerLocation)
exports('SetWaypoint', SetWaypoint)
exports('ClearWaypoint', ClearWaypoint)
exports('StartLocationTracking', StartLocationTracking)
exports('StopLocationTracking', StopLocationTracking)
exports('CalculateDistance', CalculateDistance)

-- Start tracking when phone opens
RegisterNetEvent('phone:client:open', function()
    StartLocationTracking()
end)

-- Stop tracking when phone closes
RegisterNetEvent('phone:client:close', function()
    StopLocationTracking()
end)

print('^2[Phone] Location tracking module loaded^7')
