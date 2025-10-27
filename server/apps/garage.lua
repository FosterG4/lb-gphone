-- Garage App Server Module
-- Handles vehicle tracking, valet service, and garage integration

local GarageApp = {}
local garageAdapter = nil

-- Initialize garage adapter
function GarageApp:Init()
    if not Config.GarageApp or not Config.GarageApp.enabled then
        print('[Phone] Garage app is disabled in config')
        return
    end
    
    -- Initialize garage adapter based on config
    local garageScript = Config.GarageApp.garageScript or 'standalone'
    
    if garageScript ~= 'none' then
        garageAdapter = GarageAdapter:Init()
        print('[Phone] Garage adapter initialized: ' .. garageAdapter.type)
    else
        print('[Phone] Garage app running without external garage integration')
    end
    
    -- Start vehicle tracking if enabled
    if Config.GarageApp.enableVehicleTracking then
        self:StartVehicleTracking()
    end
end

-- Get all vehicles for a player
function GarageApp:GetPlayerVehicles(source)
    if not garageAdapter then
        -- Fallback to phone_vehicles table
        local phoneNumber = Framework:GetPhoneNumber(source)
        if not phoneNumber then
            return {}
        end
        
        local result = MySQL.query.await('SELECT * FROM phone_vehicles WHERE owner_number = ?', {phoneNumber})
        return result or {}
    end
    
    -- Use garage adapter
    local vehicles = garageAdapter:GetPlayerVehicles(source)
    
    -- Sync with phone_vehicles table for tracking
    self:SyncVehiclesToDatabase(source, vehicles)
    
    return vehicles
end

-- Sync vehicles to phone_vehicles table for tracking
function GarageApp:SyncVehiclesToDatabase(source, vehicles)
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then return end
    
    for _, vehicle in ipairs(vehicles) do
        -- Check if vehicle exists in phone_vehicles
        local existing = MySQL.query.await(
            'SELECT id FROM phone_vehicles WHERE plate = ? AND owner_number = ?',
            {vehicle.plate, phoneNumber}
        )
        
        if not existing or #existing == 0 then
            -- Insert new vehicle
            MySQL.insert(
                'INSERT INTO phone_vehicles (owner_number, plate, model, garage, status) VALUES (?, ?, ?, ?, ?)',
                {phoneNumber, vehicle.plate, vehicle.model, vehicle.garage or vehicle.location, vehicle.status}
            )
        else
            -- Update existing vehicle
            MySQL.update(
                'UPDATE phone_vehicles SET model = ?, garage = ?, status = ? WHERE plate = ? AND owner_number = ?',
                {vehicle.model, vehicle.garage or vehicle.location, vehicle.status, vehicle.plate, phoneNumber}
            )
        end
    end
end

-- Update vehicle location in real-time
function GarageApp:UpdateVehicleLocation(plate, coords)
    if not coords then return false end
    
    MySQL.update(
        'UPDATE phone_vehicles SET location_x = ?, location_y = ?, location_z = ? WHERE plate = ?',
        {coords.x, coords.y, coords.z, plate}
    )
    
    return true
end

-- Get vehicle location
function GarageApp:GetVehicleLocation(plate)
    if garageAdapter and garageAdapter.GetVehicleLocation then
        local location = garageAdapter:GetVehicleLocation(plate)
        if location then
            return location
        end
    end
    
    -- Fallback to phone_vehicles table
    local result = MySQL.query.await(
        'SELECT location_x, location_y, location_z FROM phone_vehicles WHERE plate = ?',
        {plate}
    )
    
    if result and #result > 0 and result[1].location_x then
        return {
            x = result[1].location_x,
            y = result[1].location_y,
            z = result[1].location_z
        }
    end
    
    return nil
end

-- Track vehicle locations for all spawned vehicles
function GarageApp:StartVehicleTracking()
    local updateInterval = Config.GarageApp.trackingUpdateInterval or 10000
    
    CreateThread(function()
        while true do
            Wait(updateInterval)
            
            -- Get all spawned vehicles
            local vehicles = GetAllVehicles()
            
            for _, vehicle in ipairs(vehicles) do
                if DoesEntityExist(vehicle) then
                    local plate = GetVehicleNumberPlateText(vehicle)
                    if plate then
                        plate = string.gsub(plate, '^%s*(.-)%s*$', '%1') -- Trim whitespace
                        
                        local coords = GetEntityCoords(vehicle)
                        self:UpdateVehicleLocation(plate, {
                            x = coords.x,
                            y = coords.y,
                            z = coords.z
                        })
                    end
                end
            end
        end
    end)
end

-- Get vehicle status
function GarageApp:GetVehicleStatus(plate)
    if garageAdapter and garageAdapter.GetVehicleStatus then
        return garageAdapter:GetVehicleStatus(plate)
    end
    
    -- Fallback to phone_vehicles table
    local result = MySQL.query.await('SELECT status FROM phone_vehicles WHERE plate = ?', {plate})
    
    if result and #result > 0 then
        return result[1].status
    end
    
    return 'unknown'
end

-- Update vehicle status
function GarageApp:UpdateVehicleStatus(plate, status)
    MySQL.update('UPDATE phone_vehicles SET status = ? WHERE plate = ?', {status, plate})
    
    -- Also update in garage adapter if available
    if garageAdapter and status == 'stored' then
        -- Store vehicle in garage system
        local result = MySQL.query.await('SELECT garage FROM phone_vehicles WHERE plate = ?', {plate})
        if result and #result > 0 then
            garageAdapter:StoreVehicle(plate, result[1].garage)
        end
    end
    
    return true
end

-- Register NUI callbacks
RegisterNUICallback('garage:getVehicles', function(data, cb)
    local source = source
    
    local vehicles = GarageApp:GetPlayerVehicles(source)
    
    cb({
        success = true,
        vehicles = vehicles,
        config = {
            valetEnabled = Config.GarageApp.enableValet or false,
            valetCost = Config.GarageApp.valetCost or 100
        }
    })
end)

RegisterNUICallback('garage:locateVehicle', function(data, cb)
    local source = source
    local plate = data.plate
    
    if not plate then
        cb({ success = false, message = 'Invalid plate' })
        return
    end
    
    local location = GarageApp:GetVehicleLocation(plate)
    
    if location then
        cb({
            success = true,
            location = location
        })
    else
        cb({
            success = false,
            message = 'Vehicle location not found'
        })
    end
end)

RegisterNUICallback('garage:setWaypoint', function(data, cb)
    local source = source
    
    if not data.x or not data.y then
        cb({ success = false, message = 'Invalid coordinates' })
        return
    end
    
    -- Trigger client event to set waypoint
    TriggerClientEvent('phone:garage:setWaypoint', source, {
        x = data.x,
        y = data.y,
        z = data.z or 0.0
    })
    
    cb({ success = true })
end)

-- Valet service - spawn vehicle near player
function GarageApp:RequestValet(source, plate)
    if not Config.GarageApp.enableValet then
        return { success = false, message = 'Valet service is disabled' }
    end
    
    -- Verify player owns this vehicle
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return { success = false, message = 'Phone number not found' }
    end
    
    local result = MySQL.query.await(
        'SELECT * FROM phone_vehicles WHERE plate = ? AND owner_number = ?',
        {plate, phoneNumber}
    )
    
    if not result or #result == 0 then
        return { success = false, message = 'Vehicle not found' }
    end
    
    local vehicle = result[1]
    
    -- Check if vehicle is stored
    if vehicle.status ~= 'stored' then
        return { success = false, message = 'Vehicle must be stored to use valet' }
    end
    
    -- Check if player has enough money
    local valetCost = Config.GarageApp.valetCost or 100
    local hasMoney = Framework:RemoveMoney(source, valetCost)
    
    if not hasMoney then
        return { success = false, message = 'Insufficient funds for valet service' }
    end
    
    -- Calculate spawn location near player
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local spawnDistance = Config.GarageApp.valetSpawnDistance or 10
    
    -- Find a suitable spawn location
    local spawnCoords = self:FindVehicleSpawnLocation(playerCoords, spawnDistance)
    
    if not spawnCoords then
        -- Refund money if spawn failed
        Framework:AddMoney(source, valetCost)
        return { success = false, message = 'No suitable spawn location found' }
    end
    
    -- Spawn vehicle using adapter or directly
    local spawnSuccess = false
    
    if garageAdapter and garageAdapter.SpawnVehicle then
        spawnSuccess = garageAdapter:SpawnVehicle(source, plate, spawnCoords)
    else
        -- Direct spawn
        spawnSuccess = self:SpawnVehicleDirect(vehicle.model, plate, spawnCoords)
    end
    
    if spawnSuccess then
        -- Update vehicle status
        self:UpdateVehicleStatus(plate, 'out')
        self:UpdateVehicleLocation(plate, spawnCoords)
        
        -- Notify client
        TriggerClientEvent('phone:garage:valetDelivered', source, {
            plate = plate,
            location = spawnCoords
        })
        
        return { success = true, message = 'Vehicle delivered' }
    else
        -- Refund money if spawn failed
        Framework:AddMoney(source, valetCost)
        return { success = false, message = 'Failed to spawn vehicle' }
    end
end

-- Find suitable vehicle spawn location near player
function GarageApp:FindVehicleSpawnLocation(playerCoords, distance)
    local attempts = 0
    local maxAttempts = 10
    
    while attempts < maxAttempts do
        -- Generate random offset
        local angle = math.random() * 2 * math.pi
        local offsetX = math.cos(angle) * distance
        local offsetY = math.sin(angle) * distance
        
        local testCoords = vector3(
            playerCoords.x + offsetX,
            playerCoords.y + offsetY,
            playerCoords.z
        )
        
        -- Get ground Z coordinate
        local groundZ = GetGroundZFor_3dCoord(testCoords.x, testCoords.y, testCoords.z + 100.0, false)
        
        if groundZ and groundZ > 0 then
            testCoords = vector3(testCoords.x, testCoords.y, groundZ + 1.0)
            
            -- Check if location is clear
            if self:IsLocationClear(testCoords, 3.0) then
                -- Calculate heading towards player
                local heading = GetHeadingFromVector_2d(
                    playerCoords.x - testCoords.x,
                    playerCoords.y - testCoords.y
                )
                
                return {
                    x = testCoords.x,
                    y = testCoords.y,
                    z = testCoords.z,
                    heading = heading
                }
            end
        end
        
        attempts = attempts + 1
    end
    
    return nil
end

-- Check if location is clear for vehicle spawn
function GarageApp:IsLocationClear(coords, radius)
    -- Check for nearby vehicles
    local vehicles = GetAllVehicles()
    
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local vehicleCoords = GetEntityCoords(vehicle)
            local distance = #(vector3(coords.x, coords.y, coords.z) - vehicleCoords)
            
            if distance < radius then
                return false
            end
        end
    end
    
    return true
end

-- Spawn vehicle directly (fallback method)
function GarageApp:SpawnVehicleDirect(model, plate, coords)
    local modelHash = GetHashKey(model)
    
    if not IsModelInCdimage(modelHash) then
        return false
    end
    
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if not HasModelLoaded(modelHash) then
        return false
    end
    
    local vehicle = CreateVehicle(
        modelHash,
        coords.x,
        coords.y,
        coords.z,
        coords.heading or 0.0,
        true,
        true
    )
    
    if not vehicle or vehicle == 0 then
        return false
    end
    
    SetVehicleNumberPlateText(vehicle, plate)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')
    SetModelAsNoLongerNeeded(modelHash)
    
    return true
end

-- Set valet timeout to automatically store vehicle if not retrieved
function GarageApp:SetValetTimeout(plate)
    local timeout = Config.GarageApp.valetTimeout or 30
    
    CreateThread(function()
        Wait(timeout * 1000)
        
        -- Check if vehicle is still spawned and not being used
        local vehicles = GetAllVehicles()
        local found = false
        
        for _, vehicle in ipairs(vehicles) do
            if DoesEntityExist(vehicle) then
                local vehiclePlate = GetVehicleNumberPlateText(vehicle)
                vehiclePlate = string.gsub(vehiclePlate, '^%s*(.-)%s*$', '%1')
                
                if vehiclePlate == plate then
                    found = true
                    
                    -- Check if anyone is in the vehicle
                    local driver = GetPedInVehicleSeat(vehicle, -1)
                    
                    if driver == 0 or driver == -1 then
                        -- No one in vehicle, delete it
                        DeleteEntity(vehicle)
                        
                        -- Update status back to stored
                        GarageApp:UpdateVehicleStatus(plate, 'stored')
                    end
                    
                    break
                end
            end
        end
    end)
end

-- Register valet NUI callback
RegisterNUICallback('garage:requestValet', function(data, cb)
    local source = source
    local plate = data.plate
    
    if not plate then
        cb({ success = false, message = 'Invalid plate' })
        return
    end
    
    local result = GarageApp:RequestValet(source, plate)
    
    if result.success then
        -- Set timeout for valet
        GarageApp:SetValetTimeout(plate)
    end
    
    cb(result)
end)

-- Server event to update vehicle location from client
RegisterServerEvent('phone:garage:updateVehicleLocation')
AddEventHandler('phone:garage:updateVehicleLocation', function(plate, coords)
    local source = source
    
    -- Verify player owns this vehicle
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then return end
    
    local result = MySQL.query.await(
        'SELECT id FROM phone_vehicles WHERE plate = ? AND owner_number = ?',
        {plate, phoneNumber}
    )
    
    if result and #result > 0 then
        GarageApp:UpdateVehicleLocation(plate, coords)
        
        -- Notify client of update
        TriggerClientEvent('phone:garage:vehicleLocationUpdated', source, {
            plate = plate,
            location = coords
        })
    end
end)

-- Initialize on resource start
CreateThread(function()
    Wait(1000) -- Wait for framework and adapters to load
    GarageApp:Init()
end)

return GarageApp
