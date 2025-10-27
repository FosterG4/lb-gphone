-- Vehicle Tracking Client Module
-- Handles vehicle location updates, valet coordination, and status monitoring

local VehicleTracking = {}
local trackedVehicles = {}
local playerVehicles = {}
local trackingEnabled = false
local updateInterval = 10000 -- 10 seconds

-- Initialize vehicle tracking
function VehicleTracking:Init()
    if not Config.GarageApp or not Config.GarageApp.enabled then
        return
    end
    
    if Config.GarageApp.enableVehicleTracking then
        trackingEnabled = true
        updateInterval = Config.GarageApp.trackingUpdateInterval or 10000
        
        self:StartTracking()
        print('[Phone] Vehicle tracking initialized')
    end
end

-- Start vehicle tracking loop
function VehicleTracking:StartTracking()
    CreateThread(function()
        while trackingEnabled do
            Wait(updateInterval)
            
            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            
            -- Track current vehicle if player is driving
            if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == playerPed then
                local plate = GetVehicleNumberPlateText(vehicle)
                if plate then
                    plate = string.gsub(plate, '^%s*(.-)%s*$', '%1') -- Trim whitespace
                    
                    local coords = GetEntityCoords(vehicle)
                    self:UpdateVehicleLocation(plate, coords)
                end
            end
            
            -- Track all player-owned vehicles that are spawned
            for plate, _ in pairs(playerVehicles) do
                local vehicleEntity = self:FindVehicleByPlate(plate)
                if vehicleEntity and vehicleEntity ~= 0 then
                    local coords = GetEntityCoords(vehicleEntity)
                    self:UpdateVehicleLocation(plate, coords)
                end
            end
        end
    end)
end

-- Update vehicle location on server
function VehicleTracking:UpdateVehicleLocation(plate, coords)
    if not coords then return end
    
    TriggerServerEvent('phone:garage:updateVehicleLocation', plate, {
        x = coords.x,
        y = coords.y,
        z = coords.z
    })
end

-- Find vehicle entity by plate number
function VehicleTracking:FindVehicleByPlate(plate)
    local vehicles = GetGamePool('CVehicle')
    
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local vehiclePlate = GetVehicleNumberPlateText(vehicle)
            vehiclePlate = string.gsub(vehiclePlate, '^%s*(.-)%s*$', '%1')
            
            if vehiclePlate == plate then
                return vehicle
            end
        end
    end
    
    return nil
end

-- Monitor vehicle status changes
function VehicleTracking:MonitorVehicleStatus()
    CreateThread(function()
        local lastVehicle = 0
        
        while trackingEnabled do
            Wait(1000)
            
            local playerPed = PlayerPedId()
            local currentVehicle = GetVehiclePedIsIn(playerPed, false)
            
            -- Player entered a vehicle
            if currentVehicle ~= 0 and currentVehicle ~= lastVehicle then
                local plate = GetVehicleNumberPlateText(currentVehicle)
                if plate then
                    plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')
                    
                    -- Check if this is a player-owned vehicle
                    if playerVehicles[plate] then
                        self:OnVehicleEntered(plate, currentVehicle)
                    end
                end
            end
            
            -- Player exited a vehicle
            if currentVehicle == 0 and lastVehicle ~= 0 then
                local plate = GetVehicleNumberPlateText(lastVehicle)
                if plate then
                    plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')
                    
                    if playerVehicles[plate] then
                        self:OnVehicleExited(plate, lastVehicle)
                    end
                end
            end
            
            lastVehicle = currentVehicle
        end
    end)
end

-- Handle vehicle entered event
function VehicleTracking:OnVehicleEntered(plate, vehicle)
    trackedVehicles[plate] = vehicle
    
    -- Update location immediately
    local coords = GetEntityCoords(vehicle)
    self:UpdateVehicleLocation(plate, coords)
end

-- Handle vehicle exited event
function VehicleTracking:OnVehicleExited(plate, vehicle)
    -- Update final location
    local coords = GetEntityCoords(vehicle)
    self:UpdateVehicleLocation(plate, coords)
end

-- Register player vehicle for tracking
function VehicleTracking:RegisterVehicle(plate)
    playerVehicles[plate] = true
end

-- Unregister player vehicle from tracking
function VehicleTracking:UnregisterVehicle(plate)
    playerVehicles[plate] = nil
    trackedVehicles[plate] = nil
end

-- Set waypoint to vehicle location
function VehicleTracking:SetWaypointToVehicle(coords)
    if not coords or not coords.x or not coords.y then
        return false
    end
    
    SetNewWaypoint(coords.x, coords.y)
    
    -- Show notification
    TriggerEvent('phone:notification', {
        title = 'Garage',
        message = 'Waypoint set to vehicle location',
        type = 'success'
    })
    
    return true
end

-- Handle valet delivery
function VehicleTracking:OnValetDelivered(data)
    if not data or not data.plate then return end
    
    -- Register vehicle for tracking
    self:RegisterVehicle(data.plate)
    
    -- Set waypoint to delivery location
    if data.location then
        Wait(1000) -- Small delay for immersion
        self:SetWaypointToVehicle(data.location)
    end
    
    -- Show notification
    TriggerEvent('phone:notification', {
        title = 'Valet Service',
        message = 'Your vehicle has been delivered',
        type = 'success'
    })
end

-- Client event handlers
RegisterNetEvent('phone:garage:setWaypoint')
AddEventHandler('phone:garage:setWaypoint', function(coords)
    VehicleTracking:SetWaypointToVehicle(coords)
end)

RegisterNetEvent('phone:garage:valetDelivered')
AddEventHandler('phone:garage:valetDelivered', function(data)
    VehicleTracking:OnValetDelivered(data)
end)

RegisterNetEvent('phone:garage:vehicleLocationUpdated')
AddEventHandler('phone:garage:vehicleLocationUpdated', function(data)
    -- Update NUI with new location
    SendNUIMessage({
        action = 'garage:vehicleLocationUpdated',
        data = data
    })
end)

RegisterNetEvent('phone:garage:registerVehicle')
AddEventHandler('phone:garage:registerVehicle', function(plate)
    VehicleTracking:RegisterVehicle(plate)
end)

RegisterNetEvent('phone:garage:unregisterVehicle')
AddEventHandler('phone:garage:unregisterVehicle', function(plate)
    VehicleTracking:UnregisterVehicle(plate)
end)

-- Initialize on resource start
CreateThread(function()
    Wait(1000)
    VehicleTracking:Init()
    VehicleTracking:MonitorVehicleStatus()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    trackingEnabled = false
    trackedVehicles = {}
    playerVehicles = {}
end)

return VehicleTracking
