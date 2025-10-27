-- Garage Adapter Interface
-- This file defines the interface for garage script integration

GarageAdapter = {}
GarageAdapter.__index = GarageAdapter

-- Initialize the garage adapter based on config
function GarageAdapter:Init()
    local garageType = Config.GarageScript or 'standalone'
    
    if garageType == 'qb-garages' then
        return GarageAdapter:InitQBGarages()
    elseif garageType == 'cd_garage' then
        return GarageAdapter:InitCDGarage()
    elseif garageType == 'jg-advancedgarages' then
        return GarageAdapter:InitJGGarages()
    else
        return GarageAdapter:InitStandalone()
    end
end

-- Interface Methods (to be implemented by each adapter)

--- Get all vehicles owned by player
-- @param source number - Player server ID
-- @return table - Array of vehicle data {plate, model, location, garage, status}
function GarageAdapter:GetPlayerVehicles(source)
    error("GetPlayerVehicles must be implemented by garage adapter")
end

--- Spawn a vehicle at specified coordinates
-- @param source number - Player server ID
-- @param plate string - Vehicle plate number
-- @param coords table - Spawn coordinates {x, y, z, heading}
-- @return boolean - Success status
function GarageAdapter:SpawnVehicle(source, plate, coords)
    error("SpawnVehicle must be implemented by garage adapter")
end

--- Get vehicle location
-- @param plate string - Vehicle plate number
-- @return table|nil - Location {x, y, z} or nil if not found
function GarageAdapter:GetVehicleLocation(plate)
    error("GetVehicleLocation must be implemented by garage adapter")
end

--- Get vehicle status
-- @param plate string - Vehicle plate number
-- @return string - Status: 'out', 'stored', 'impounded'
function GarageAdapter:GetVehicleStatus(plate)
    error("GetVehicleStatus must be implemented by garage adapter")
end

--- Store vehicle in garage
-- @param plate string - Vehicle plate number
-- @param garage string - Garage name/ID
-- @return boolean - Success status
function GarageAdapter:StoreVehicle(plate, garage)
    error("StoreVehicle must be implemented by garage adapter")
end

-- ============================================
-- QB-Garages Adapter Implementation
-- ============================================

function GarageAdapter:InitQBGarages()
    local adapter = setmetatable({}, GarageAdapter)
    adapter.type = 'qb-garages'
    
    function adapter:GetPlayerVehicles(source)
        local Player = Framework:GetPlayer(source)
        if not Player then return {} end
        
        local citizenid = Player.PlayerData.citizenid
        local result = MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ?', {citizenid})
        
        local vehicles = {}
        for _, vehicle in ipairs(result) do
            table.insert(vehicles, {
                plate = vehicle.plate,
                model = vehicle.vehicle,
                location = vehicle.garage,
                garage = vehicle.garage,
                status = vehicle.state == 0 and 'stored' or (vehicle.state == 1 and 'out' or 'impounded')
            })
        end
        
        return vehicles
    end
    
    function adapter:SpawnVehicle(source, plate, coords)
        local Player = Framework:GetPlayer(source)
        if not Player then return false end
        
        local citizenid = Player.PlayerData.citizenid
        local result = MySQL.query.await('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', {plate, citizenid})
        
        if not result or #result == 0 then
            return false
        end
        
        local vehicleData = result[1]
        local vehicleProps = json.decode(vehicleData.mods)
        
        -- Create vehicle
        local netId = exports['qb-core']:SpawnVehicle(source, vehicleData.vehicle, coords, true)
        if not netId then return false end
        
        local vehicle = NetworkGetEntityFromNetworkId(netId)
        if not vehicle or vehicle == 0 then return false end
        
        -- Apply vehicle properties
        if vehicleProps then
            exports['qb-core']:SetVehicleProperties(vehicle, vehicleProps)
        end
        
        -- Update vehicle state to 'out'
        MySQL.update('UPDATE player_vehicles SET state = 1 WHERE plate = ?', {plate})
        
        return true
    end
    
    function adapter:GetVehicleLocation(plate)
        -- For QB-Garages, vehicles don't have real-time location tracking
        -- Return garage location if stored, nil if out
        local result = MySQL.query.await('SELECT garage, state FROM player_vehicles WHERE plate = ?', {plate})
        
        if not result or #result == 0 then return nil end
        
        if result[1].state == 0 then
            -- Vehicle is stored, return garage location
            local garageConfig = Config.Garages and Config.Garages[result[1].garage]
            if garageConfig then
                return {x = garageConfig.x, y = garageConfig.y, z = garageConfig.z}
            end
        end
        
        return nil
    end
    
    function adapter:GetVehicleStatus(plate)
        local result = MySQL.query.await('SELECT state FROM player_vehicles WHERE plate = ?', {plate})
        
        if not result or #result == 0 then return 'unknown' end
        
        local state = result[1].state
        if state == 0 then return 'stored'
        elseif state == 1 then return 'out'
        elseif state == 2 then return 'impounded'
        else return 'unknown' end
    end
    
    function adapter:StoreVehicle(plate, garage)
        MySQL.update('UPDATE player_vehicles SET state = 0, garage = ? WHERE plate = ?', {garage, plate})
        return true
    end
    
    return adapter
end

-- ============================================
-- CD_Garage Adapter Implementation
-- ============================================

function GarageAdapter:InitCDGarage()
    local adapter = setmetatable({}, GarageAdapter)
    adapter.type = 'cd_garage'
    
    function adapter:GetPlayerVehicles(source)
        local identifier = Framework:GetIdentifier(source)
        if not identifier then return {} end
        
        local result = MySQL.query.await('SELECT * FROM owned_vehicles WHERE owner = ?', {identifier})
        
        local vehicles = {}
        for _, vehicle in ipairs(result) do
            local stored = vehicle.stored == 1
            table.insert(vehicles, {
                plate = vehicle.plate,
                model = vehicle.vehicle,
                location = vehicle.garage_id or 'unknown',
                garage = vehicle.garage_id or 'unknown',
                status = stored and 'stored' or 'out'
            })
        end
        
        return vehicles
    end
    
    function adapter:SpawnVehicle(source, plate, coords)
        local identifier = Framework:GetIdentifier(source)
        if not identifier then return false end
        
        local result = MySQL.query.await('SELECT * FROM owned_vehicles WHERE plate = ? AND owner = ?', {plate, identifier})
        
        if not result or #result == 0 then
            return false
        end
        
        local vehicleData = result[1]
        local vehicleProps = json.decode(vehicleData.vehicle)
        
        -- Use CD_Garage export if available
        if exports['cd_garage'] and exports['cd_garage'].SpawnVehicle then
            local success = exports['cd_garage']:SpawnVehicle(source, plate, coords)
            return success
        end
        
        -- Fallback: Manual spawn
        local modelHash = GetHashKey(vehicleProps.model)
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(10)
        end
        
        local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, coords.heading or 0.0, true, true)
        if not vehicle or vehicle == 0 then return false end
        
        SetVehicleNumberPlateText(vehicle, plate)
        
        -- Update stored status
        MySQL.update('UPDATE owned_vehicles SET stored = 0 WHERE plate = ?', {plate})
        
        return true
    end
    
    function adapter:GetVehicleLocation(plate)
        local result = MySQL.query.await('SELECT garage_id, stored FROM owned_vehicles WHERE plate = ?', {plate})
        
        if not result or #result == 0 then return nil end
        
        if result[1].stored == 1 then
            local garageConfig = Config.Garages and Config.Garages[result[1].garage_id]
            if garageConfig then
                return {x = garageConfig.x, y = garageConfig.y, z = garageConfig.z}
            end
        end
        
        return nil
    end
    
    function adapter:GetVehicleStatus(plate)
        local result = MySQL.query.await('SELECT stored FROM owned_vehicles WHERE plate = ?', {plate})
        
        if not result or #result == 0 then return 'unknown' end
        
        return result[1].stored == 1 and 'stored' or 'out'
    end
    
    function adapter:StoreVehicle(plate, garage)
        MySQL.update('UPDATE owned_vehicles SET stored = 1, garage_id = ? WHERE plate = ?', {garage, plate})
        return true
    end
    
    return adapter
end

-- ============================================
-- JG-AdvancedGarages Adapter Implementation
-- ============================================

function GarageAdapter:InitJGGarages()
    local adapter = setmetatable({}, GarageAdapter)
    adapter.type = 'jg-advancedgarages'
    
    function adapter:GetPlayerVehicles(source)
        local identifier = Framework:GetIdentifier(source)
        if not identifier then return {} end
        
        -- JG uses different table structure
        local result = MySQL.query.await('SELECT * FROM jg_vehicles WHERE owner = ?', {identifier})
        
        local vehicles = {}
        for _, vehicle in ipairs(result) do
            table.insert(vehicles, {
                plate = vehicle.plate,
                model = vehicle.model,
                location = vehicle.garage_name or 'unknown',
                garage = vehicle.garage_name or 'unknown',
                status = vehicle.in_garage == 1 and 'stored' or 'out'
            })
        end
        
        return vehicles
    end
    
    function adapter:SpawnVehicle(source, plate, coords)
        local identifier = Framework:GetIdentifier(source)
        if not identifier then return false end
        
        -- Use JG export if available
        if exports['jg-advancedgarages'] and exports['jg-advancedgarages'].SpawnVehicle then
            local success = exports['jg-advancedgarages']:SpawnVehicle(source, plate, coords)
            return success
        end
        
        -- Fallback implementation
        local result = MySQL.query.await('SELECT * FROM jg_vehicles WHERE plate = ? AND owner = ?', {plate, identifier})
        
        if not result or #result == 0 then
            return false
        end
        
        local vehicleData = result[1]
        local modelHash = GetHashKey(vehicleData.model)
        
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(10)
        end
        
        local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, coords.heading or 0.0, true, true)
        if not vehicle or vehicle == 0 then return false end
        
        SetVehicleNumberPlateText(vehicle, plate)
        
        -- Update garage status
        MySQL.update('UPDATE jg_vehicles SET in_garage = 0 WHERE plate = ?', {plate})
        
        return true
    end
    
    function adapter:GetVehicleLocation(plate)
        local result = MySQL.query.await('SELECT garage_name, in_garage FROM jg_vehicles WHERE plate = ?', {plate})
        
        if not result or #result == 0 then return nil end
        
        if result[1].in_garage == 1 then
            local garageConfig = Config.Garages and Config.Garages[result[1].garage_name]
            if garageConfig then
                return {x = garageConfig.x, y = garageConfig.y, z = garageConfig.z}
            end
        end
        
        return nil
    end
    
    function adapter:GetVehicleStatus(plate)
        local result = MySQL.query.await('SELECT in_garage FROM jg_vehicles WHERE plate = ?', {plate})
        
        if not result or #result == 0 then return 'unknown' end
        
        return result[1].in_garage == 1 and 'stored' or 'out'
    end
    
    function adapter:StoreVehicle(plate, garage)
        MySQL.update('UPDATE jg_vehicles SET in_garage = 1, garage_name = ? WHERE plate = ?', {garage, plate})
        return true
    end
    
    return adapter
end

-- ============================================
-- Standalone Adapter Implementation
-- ============================================

function GarageAdapter:InitStandalone()
    local adapter = setmetatable({}, GarageAdapter)
    adapter.type = 'standalone'
    
    function adapter:GetPlayerVehicles(source)
        local phoneNumber = Framework:GetPhoneNumber(source)
        if not phoneNumber then return {} end
        
        local result = MySQL.query.await('SELECT * FROM phone_vehicles WHERE owner_number = ?', {phoneNumber})
        
        return result or {}
    end
    
    function adapter:SpawnVehicle(source, plate, coords)
        local phoneNumber = Framework:GetPhoneNumber(source)
        if not phoneNumber then return false end
        
        local result = MySQL.query.await('SELECT * FROM phone_vehicles WHERE plate = ? AND owner_number = ?', {plate, phoneNumber})
        
        if not result or #result == 0 then
            return false
        end
        
        local vehicleData = result[1]
        local modelHash = GetHashKey(vehicleData.model)
        
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 5000 do
            Wait(10)
            timeout = timeout + 10
        end
        
        if not HasModelLoaded(modelHash) then
            return false
        end
        
        local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, coords.heading or 0.0, true, true)
        if not vehicle or vehicle == 0 then return false end
        
        SetVehicleNumberPlateText(vehicle, plate)
        
        -- Update vehicle status
        MySQL.update('UPDATE phone_vehicles SET status = ? WHERE plate = ?', {'out', plate})
        
        return true
    end
    
    function adapter:GetVehicleLocation(plate)
        local result = MySQL.query.await('SELECT location_x, location_y, location_z, status FROM phone_vehicles WHERE plate = ?', {plate})
        
        if not result or #result == 0 then return nil end
        
        local vehicle = result[1]
        if vehicle.status == 'stored' and vehicle.location_x then
            return {x = vehicle.location_x, y = vehicle.location_y, z = vehicle.location_z}
        end
        
        return nil
    end
    
    function adapter:GetVehicleStatus(plate)
        local result = MySQL.query.await('SELECT status FROM phone_vehicles WHERE plate = ?', {plate})
        
        if not result or #result == 0 then return 'unknown' end
        
        return result[1].status or 'unknown'
    end
    
    function adapter:StoreVehicle(plate, garage)
        MySQL.update('UPDATE phone_vehicles SET status = ?, garage = ? WHERE plate = ?', {'stored', garage, plate})
        return true
    end
    
    return adapter
end

return GarageAdapter
