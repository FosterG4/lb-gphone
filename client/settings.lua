-- Client-Side Settings Management
-- Handles settings synchronization between client and server

local currentSettings = nil
local settingsLoaded = false

-- Get current settings
local function GetCurrentSettings()
    return currentSettings
end

-- Apply settings to client
local function ApplySettings(settings)
    if not settings then return end
    
    currentSettings = settings
    settingsLoaded = true
    
    -- Apply theme
    if settings.theme then
        SendNUIMessage({
            action = 'setTheme',
            theme = settings.theme
        })
    end
    
    -- Apply volume
    if settings.volume then
        SendNUIMessage({
            action = 'setVolume',
            volume = settings.volume
        })
    end
    
    -- Apply notification settings
    if settings.notificationEnabled ~= nil then
        SendNUIMessage({
            action = 'setNotificationEnabled',
            enabled = settings.notificationEnabled
        })
    end
    
    -- Apply sound settings
    if settings.soundEnabled ~= nil then
        SendNUIMessage({
            action = 'setSoundEnabled',
            enabled = settings.soundEnabled
        })
    end
    
    -- Apply custom settings
    if settings.customSettings then
        SendNUIMessage({
            action = 'setCustomSettings',
            settings = settings.customSettings
        })
    end
    
    -- Trigger event for other scripts
    TriggerEvent('phone:client:settingsApplied', settings)
end

-- Load settings from server
local function LoadSettings()
    TriggerServerEvent('phone:server:getSettings')
end

-- Update settings on server
local function UpdateSettings(updates)
    if not updates or type(updates) ~= 'table' then
        print('[Phone] Invalid settings update data')
        return
    end
    
    TriggerServerEvent('phone:server:updateSettings', updates)
end

-- Update a single setting
local function UpdateSetting(key, value)
    if not key then
        print('[Phone] Invalid setting key')
        return
    end
    
    TriggerServerEvent('phone:server:updateSetting', key, value)
end

-- Get a specific setting value
local function GetSetting(key, defaultValue)
    if not currentSettings then
        return defaultValue
    end
    
    return currentSettings[key] or defaultValue
end

-- Get custom setting value
local function GetCustomSetting(key, defaultValue)
    if not currentSettings or not currentSettings.customSettings then
        return defaultValue
    end
    
    return currentSettings.customSettings[key] or defaultValue
end

-- Check if settings are loaded
local function AreSettingsLoaded()
    return settingsLoaded
end

-- Wait for settings to load
local function WaitForSettings(timeout)
    timeout = timeout or 5000
    local startTime = GetGameTimer()
    
    while not settingsLoaded do
        Wait(100)
        if GetGameTimer() - startTime > timeout then
            print('[Phone] Settings load timeout')
            return false
        end
    end
    
    return true
end

-- Server event handlers
RegisterNetEvent('phone:client:receiveSettings', function(settings)
    if not settings then
        print('[Phone] Received invalid settings from server')
        return
    end
    
    ApplySettings(settings)
    
    -- Notify NUI that settings are loaded
    SendNUIMessage({
        action = 'settingsLoaded',
        settings = settings
    })
end)

RegisterNetEvent('phone:client:settingsUpdated', function(settings)
    if not settings then
        print('[Phone] Received invalid settings update from server')
        return
    end
    
    ApplySettings(settings)
    
    -- Notify NUI that settings were updated
    SendNUIMessage({
        action = 'settingsUpdated',
        settings = settings
    })
    
    -- Show success notification
    if Config.NotificationSound then
        PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
    end
end)

RegisterNetEvent('phone:client:settingsError', function(error)
    print('[Phone] Settings error: ' .. tostring(error))
    
    -- Notify NUI of error
    SendNUIMessage({
        action = 'settingsError',
        error = error
    })
    
    -- Show error notification
    TriggerEvent('phone:client:notify', {
        title = 'Settings Error',
        message = error or 'Failed to update settings',
        type = 'error',
        duration = 5000
    })
end)

-- NUI Callbacks for settings
RegisterNUICallback('getSettings', function(data, cb)
    if currentSettings then
        cb({success = true, settings = currentSettings})
    else
        LoadSettings()
        -- Wait a bit for settings to load
        SetTimeout(1000, function()
            if currentSettings then
                cb({success = true, settings = currentSettings})
            else
                cb({success = false, error = 'Settings not loaded'})
            end
        end)
    end
end)

RegisterNUICallback('updateSettings', function(data, cb)
    if not data or not data.settings then
        cb({success = false, error = 'Invalid settings data'})
        return
    end
    
    UpdateSettings(data.settings)
    cb({success = true})
end)

RegisterNUICallback('updateSetting', function(data, cb)
    if not data or not data.key then
        cb({success = false, error = 'Invalid setting key'})
        return
    end
    
    UpdateSetting(data.key, data.value)
    cb({success = true})
end)

RegisterNUICallback('getSetting', function(data, cb)
    if not data or not data.key then
        cb({success = false, error = 'Invalid setting key'})
        return
    end
    
    local value = GetSetting(data.key, data.default)
    cb({success = true, value = value})
end)

-- Load settings when player spawns
AddEventHandler('playerSpawned', function()
    Wait(2000) -- Wait for phone system to initialize
    LoadSettings()
end)

-- Load settings when resource starts (if player already spawned)
CreateThread(function()
    Wait(3000) -- Wait for phone system to initialize
    if NetworkIsPlayerActive(PlayerId()) then
        LoadSettings()
    end
end)

-- Export functions
exports('GetCurrentSettings', GetCurrentSettings)
exports('GetSetting', GetSetting)
exports('GetCustomSetting', GetCustomSetting)
exports('UpdateSettings', UpdateSettings)
exports('UpdateSetting', UpdateSetting)
exports('LoadSettings', LoadSettings)
exports('AreSettingsLoaded', AreSettingsLoaded)
exports('WaitForSettings', WaitForSettings)
