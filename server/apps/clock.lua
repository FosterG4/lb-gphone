-- Clock App Server Handler
-- Handles alarms, timers, and stopwatch functionality

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

-- Alarm checking thread
CreateThread(function()
    while true do
        Wait(60000) -- Check every minute
        
        local currentTime = os.date('%H:%M')
        local currentDay = string.lower(os.date('%a'))
        
        -- Map day abbreviations
        local dayMap = {
            mon = 'mon',
            tue = 'tue',
            wed = 'wed',
            thu = 'thu',
            fri = 'fri',
            sat = 'sat',
            sun = 'sun'
        }
        
        -- Get all enabled alarms
        local result = MySQL.query.await('SELECT * FROM phone_alarms WHERE enabled = 1')
        
        if result then
            for _, alarm in ipairs(result) do
                local alarmTime = alarm.alarm_time:sub(1, 5) -- Get HH:MM format
                
                if alarmTime == currentTime then
                    local shouldTrigger = false
                    
                    if alarm.alarm_days and alarm.alarm_days ~= '' then
                        -- Check if today is in the alarm days
                        local days = {}
                        for day in string.gmatch(alarm.alarm_days, '([^,]+)') do
                            days[day] = true
                        end
                        
                        if days[currentDay] then
                            shouldTrigger = true
                        end
                    else
                        -- One-time alarm
                        shouldTrigger = true
                    end
                    
                    if shouldTrigger then
                        -- Find the player and trigger alarm
                        local src = GetPlayerFromPhoneNumber(alarm.owner_number)
                        
                        if src then
                            TriggerClientEvent('phone:client:alarmTriggered', src, {
                                id = alarm.id,
                                label = alarm.label,
                                sound = alarm.sound
                            })
                            
                            -- If it's a one-time alarm, disable it
                            if not alarm.alarm_days or alarm.alarm_days == '' then
                                MySQL.update.await('UPDATE phone_alarms SET enabled = 0 WHERE id = ?', {
                                    alarm.id
                                })
                            end
                        end
                    end
                end
            end
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

-- Get all alarms for a player
RegisterNetEvent('phone:server:getAlarms', function()
    local src = source
    local phoneNumber = GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveAlarms', src, {
            success = false,
            error = 'PLAYER_NOT_FOUND'
        })
        return
    end
    
    local result = MySQL.query.await('SELECT * FROM phone_alarms WHERE owner_number = ? ORDER BY alarm_time', {
        phoneNumber
    })
    
    TriggerClientEvent('phone:client:receiveAlarms', src, {
        success = true,
        alarms = result or {}
    })
end)

-- Create a new alarm
RegisterNetEvent('phone:server:createAlarm', function(data)
    local src = source
    local phoneNumber = GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:alarmCreated', src, {
            success = false,
            error = 'PLAYER_NOT_FOUND'
        })
        return
    end
    
    -- Validate input
    if not data.time then
        TriggerClientEvent('phone:client:alarmCreated', src, {
            success = false,
            error = 'INVALID_INPUT'
        })
        return
    end
    
    -- Check alarm limit
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM phone_alarms WHERE owner_number = ?', {
        phoneNumber
    })
    
    if count >= (Config.MaxAlarms or 10) then
        TriggerClientEvent('phone:client:alarmCreated', src, {
            success = false,
            error = 'ALARM_LIMIT_REACHED'
        })
        return
    end
    
    -- Insert alarm
    local alarmId = MySQL.insert.await([[
        INSERT INTO phone_alarms (owner_number, alarm_time, alarm_days, label, enabled, sound)
        VALUES (?, ?, ?, ?, 1, ?)
    ]], {
        phoneNumber,
        data.time,
        data.days or '',
        data.label or 'Alarm',
        data.sound or 'default'
    })
    
    if alarmId then
        local alarm = MySQL.query.await('SELECT * FROM phone_alarms WHERE id = ?', { alarmId })
        
        TriggerClientEvent('phone:client:alarmCreated', src, {
            success = true,
            alarm = alarm[1]
        })
    else
        TriggerClientEvent('phone:client:alarmCreated', src, {
            success = false,
            error = 'DATABASE_ERROR'
        })
    end
end)

-- Update an existing alarm
RegisterNetEvent('phone:server:updateAlarm', function(data)
    local src = source
    local phoneNumber = GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:alarmUpdated', src, {
            success = false,
            error = 'PLAYER_NOT_FOUND'
        })
        return
    end
    
    -- Verify ownership
    local alarm = MySQL.query.await('SELECT * FROM phone_alarms WHERE id = ? AND owner_number = ?', {
        data.alarmId,
        phoneNumber
    })
    
    if not alarm or not alarm[1] then
        TriggerClientEvent('phone:client:alarmUpdated', src, {
            success = false,
            error = 'NOT_OWNER'
        })
        return
    end
    
    -- Update alarm
    local success = MySQL.update.await([[
        UPDATE phone_alarms 
        SET alarm_time = ?, alarm_days = ?, label = ?, sound = ?
        WHERE id = ?
    ]], {
        data.time,
        data.days or '',
        data.label or 'Alarm',
        data.sound or 'default',
        data.alarmId
    })
    
    if success then
        local updatedAlarm = MySQL.query.await('SELECT * FROM phone_alarms WHERE id = ?', { data.alarmId })
        
        TriggerClientEvent('phone:client:alarmUpdated', src, {
            success = true,
            alarm = updatedAlarm[1]
        })
    else
        TriggerClientEvent('phone:client:alarmUpdated', src, {
            success = false,
            error = 'DATABASE_ERROR'
        })
    end
end)

-- Toggle alarm enabled/disabled
RegisterNetEvent('phone:server:toggleAlarm', function(data)
    local src = source
    local phoneNumber = GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:alarmToggled', src, {
            success = false,
            error = 'PLAYER_NOT_FOUND'
        })
        return
    end
    
    -- Verify ownership
    local alarm = MySQL.query.await('SELECT * FROM phone_alarms WHERE id = ? AND owner_number = ?', {
        data.alarmId,
        phoneNumber
    })
    
    if not alarm or not alarm[1] then
        TriggerClientEvent('phone:client:alarmToggled', src, {
            success = false,
            error = 'NOT_OWNER'
        })
        return
    end
    
    -- Toggle alarm
    local success = MySQL.update.await('UPDATE phone_alarms SET enabled = ? WHERE id = ?', {
        data.enabled and 1 or 0,
        data.alarmId
    })
    
    TriggerClientEvent('phone:client:alarmToggled', src, {
        success = success
    })
end)

-- Delete an alarm
RegisterNetEvent('phone:server:deleteAlarm', function(data)
    local src = source
    local phoneNumber = GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:alarmDeleted', src, {
            success = false,
            error = 'PLAYER_NOT_FOUND'
        })
        return
    end
    
    -- Verify ownership
    local alarm = MySQL.query.await('SELECT * FROM phone_alarms WHERE id = ? AND owner_number = ?', {
        data.alarmId,
        phoneNumber
    })
    
    if not alarm or not alarm[1] then
        TriggerClientEvent('phone:client:alarmDeleted', src, {
            success = false,
            error = 'NOT_OWNER'
        })
        return
    end
    
    -- Delete alarm
    local success = MySQL.execute.await('DELETE FROM phone_alarms WHERE id = ?', {
        data.alarmId
    })
    
    TriggerClientEvent('phone:client:alarmDeleted', src, {
        success = success
    })
end)

-- Timer complete notification
RegisterNetEvent('phone:server:timerComplete', function()
    local src = source
    
    -- Send notification to client
    TriggerClientEvent('phone:client:notification', src, {
        app = 'clock',
        title = 'Timer',
        message = 'Timer complete!',
        icon = 'clock'
    })
end)

print('^2[Phone] Clock app loaded successfully^7')
