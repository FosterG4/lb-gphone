-- Settings Management System
-- Handles player phone settings persistence and synchronization

local Settings = {}

-- Cache for player settings to reduce database queries
local settingsCache = {}
local cacheExpiration = Config.Performance.cacheExpirationTime or 300000 -- 5 minutes

-- Default settings structure
local function getDefaultSettings()
    return {
        theme = Config.UI.defaultTheme or 'dark',
        notificationEnabled = true,
        soundEnabled = true,
        volume = Config.SettingsApp.defaultVolume or 50,
        locale = Config.Locale or 'en',
        customSettings = {}
    }
end

-- Validate settings data
local function validateSettings(settings)
    if not settings then return false end
    
    -- Validate theme
    if settings.theme then
        local validTheme = false
        for _, theme in ipairs(Config.UI.availableThemes or {'light', 'dark', 'oled'}) do
            if settings.theme == theme then
                validTheme = true
                break
            end
        end
        if not validTheme then
            return false, 'Invalid theme'
        end
    end
    
    -- Validate volume
    if settings.volume then
        local minVol = Config.SettingsApp.minVolume or 0
        local maxVol = Config.SettingsApp.maxVolume or 100
        if type(settings.volume) ~= 'number' or settings.volume < minVol or settings.volume > maxVol then
            return false, 'Invalid volume level'
        end
    end
    
    -- Validate locale
    if settings.locale then
        local validLocales = Config.SupportedLocales or {'en', 'ja', 'es', 'fr', 'de', 'pt'}
        local validLocale = false
        for _, locale in ipairs(validLocales) do
            if settings.locale == locale then
                validLocale = true
                break
            end
        end
        if not validLocale then
            return false, 'Invalid locale'
        end
    end
    
    -- Validate boolean fields
    if settings.notificationEnabled ~= nil and type(settings.notificationEnabled) ~= 'boolean' then
        return false, 'Invalid notification setting'
    end
    
    if settings.soundEnabled ~= nil and type(settings.soundEnabled) ~= 'boolean' then
        return false, 'Invalid sound setting'
    end
    
    return true
end

-- Get player settings from database or cache
function Settings.GetPlayerSettings(phoneNumber)
    if not phoneNumber then
        return nil, 'Invalid phone number'
    end
    
    -- Check cache first
    if settingsCache[phoneNumber] then
        local cached = settingsCache[phoneNumber]
        if os.time() - cached.timestamp < (cacheExpiration / 1000) then
            return cached.data
        else
            -- Cache expired, remove it
            settingsCache[phoneNumber] = nil
        end
    end
    
    -- Query database
    local result = MySQL.query.await('SELECT * FROM phone_settings WHERE phone_number = ?', {phoneNumber})
    
    if result and #result > 0 then
        local settings = {
            theme = result[1].theme,
            notificationEnabled = result[1].notification_enabled,
            soundEnabled = result[1].sound_enabled,
            volume = result[1].volume,
            locale = result[1].locale or 'en',
            customSettings = json.decode(result[1].settings_json or '{}')
        }
        
        -- Cache the result
        settingsCache[phoneNumber] = {
            data = settings,
            timestamp = os.time()
        }
        
        return settings
    else
        -- No settings found, return defaults
        local defaults = getDefaultSettings()
        
        -- Create default settings in database
        Settings.CreatePlayerSettings(phoneNumber, defaults)
        
        return defaults
    end
end

-- Create default settings for a new player
function Settings.CreatePlayerSettings(phoneNumber, settings)
    if not phoneNumber then
        return false, 'Invalid phone number'
    end
    
    settings = settings or getDefaultSettings()
    
    local valid, error = validateSettings(settings)
    if not valid then
        return false, error
    end
    
    local success = MySQL.insert.await([[
        INSERT INTO phone_settings (phone_number, theme, notification_enabled, sound_enabled, volume, locale, settings_json)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            theme = VALUES(theme),
            notification_enabled = VALUES(notification_enabled),
            sound_enabled = VALUES(sound_enabled),
            volume = VALUES(volume),
            locale = VALUES(locale),
            settings_json = VALUES(settings_json)
    ]], {
        phoneNumber,
        settings.theme,
        settings.notificationEnabled,
        settings.soundEnabled,
        settings.volume,
        settings.locale or 'en',
        json.encode(settings.customSettings or {})
    })
    
    if success then
        -- Update cache
        settingsCache[phoneNumber] = {
            data = settings,
            timestamp = os.time()
        }
        return true
    else
        return false, 'Database error'
    end
end

-- Update player settings
function Settings.UpdatePlayerSettings(phoneNumber, updates)
    if not phoneNumber then
        return false, 'Invalid phone number'
    end
    
    if not updates or type(updates) ~= 'table' then
        return false, 'Invalid settings data'
    end
    
    -- Validate updates
    local valid, error = validateSettings(updates)
    if not valid then
        return false, error
    end
    
    -- Get current settings
    local currentSettings = Settings.GetPlayerSettings(phoneNumber)
    if not currentSettings then
        currentSettings = getDefaultSettings()
    end
    
    -- Merge updates with current settings
    for key, value in pairs(updates) do
        if key == 'customSettings' and type(value) == 'table' then
            -- Merge custom settings
            for customKey, customValue in pairs(value) do
                currentSettings.customSettings[customKey] = customValue
            end
        else
            currentSettings[key] = value
        end
    end
    
    -- Update database
    local success = MySQL.update.await([[
        UPDATE phone_settings
        SET theme = ?, notification_enabled = ?, sound_enabled = ?, volume = ?, locale = ?, settings_json = ?
        WHERE phone_number = ?
    ]], {
        currentSettings.theme,
        currentSettings.notificationEnabled,
        currentSettings.soundEnabled,
        currentSettings.volume,
        currentSettings.locale or 'en',
        json.encode(currentSettings.customSettings),
        phoneNumber
    })
    
    if success then
        -- Invalidate cache
        settingsCache[phoneNumber] = nil
        return true, currentSettings
    else
        return false, 'Database error'
    end
end

-- Update a specific setting field
function Settings.UpdateSetting(phoneNumber, settingKey, settingValue)
    if not phoneNumber or not settingKey then
        return false, 'Invalid parameters'
    end
    
    local updates = {}
    updates[settingKey] = settingValue
    
    return Settings.UpdatePlayerSettings(phoneNumber, updates)
end

-- Update custom setting
function Settings.UpdateCustomSetting(phoneNumber, customKey, customValue)
    if not phoneNumber or not customKey then
        return false, 'Invalid parameters'
    end
    
    local currentSettings = Settings.GetPlayerSettings(phoneNumber)
    if not currentSettings then
        return false, 'Settings not found'
    end
    
    currentSettings.customSettings[customKey] = customValue
    
    return Settings.UpdatePlayerSettings(phoneNumber, {customSettings = currentSettings.customSettings})
end

-- Delete player settings (for cleanup or GDPR)
function Settings.DeletePlayerSettings(phoneNumber)
    if not phoneNumber then
        return false, 'Invalid phone number'
    end
    
    local success = MySQL.query.await('DELETE FROM phone_settings WHERE phone_number = ?', {phoneNumber})
    
    if success then
        -- Clear cache
        settingsCache[phoneNumber] = nil
        return true
    else
        return false, 'Database error'
    end
end

-- Clear settings cache (for maintenance)
function Settings.ClearCache(phoneNumber)
    if phoneNumber then
        settingsCache[phoneNumber] = nil
    else
        settingsCache = {}
    end
    return true
end

-- Export settings data (GDPR compliance)
function Settings.ExportPlayerSettings(phoneNumber)
    if not phoneNumber then
        return nil, 'Invalid phone number'
    end
    
    return Settings.GetPlayerSettings(phoneNumber)
end

-- Register server events
RegisterNetEvent('phone:server:getSettings', function()
    local src = source
    
    -- Safety check: ensure GetCachedPhoneNumber is available
    if not GetCachedPhoneNumber then
        print('^1[Phone Settings] ERROR: GetCachedPhoneNumber not available yet^7')
        return
    end
    
    local phoneNumber = GetCachedPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:settingsError', src, 'Phone number not found')
        return
    end
    
    local settings, error = Settings.GetPlayerSettings(phoneNumber)
    
    if settings then
        TriggerClientEvent('phone:client:receiveSettings', src, settings)
    else
        TriggerClientEvent('phone:client:settingsError', src, error or 'Failed to load settings')
    end
end)

RegisterNetEvent('phone:server:updateSettings', function(updates)
    local src = source
    local phoneNumber = GetCachedPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:settingsError', src, 'Phone number not found')
        return
    end
    
    if not updates or type(updates) ~= 'table' then
        TriggerClientEvent('phone:client:settingsError', src, 'Invalid settings data')
        return
    end
    
    local success, result = Settings.UpdatePlayerSettings(phoneNumber, updates)
    
    if success then
        TriggerClientEvent('phone:client:settingsUpdated', src, result)
    else
        TriggerClientEvent('phone:client:settingsError', src, result or 'Failed to update settings')
    end
end)

RegisterNetEvent('phone:server:updateSetting', function(settingKey, settingValue)
    local src = source
    local phoneNumber = GetCachedPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:settingsError', src, 'Phone number not found')
        return
    end
    
    local success, result = Settings.UpdateSetting(phoneNumber, settingKey, settingValue)
    
    if success then
        local updatedSettings = Settings.GetPlayerSettings(phoneNumber)
        TriggerClientEvent('phone:client:settingsUpdated', src, updatedSettings)
    else
        TriggerClientEvent('phone:client:settingsError', src, result or 'Failed to update setting')
    end
end)

RegisterNetEvent('phone:server:setPlayerLocale', function(data)
    local src = source
    local phoneNumber = GetCachedPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:localeUpdateResult', src, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    if not data or not data.locale then
        TriggerClientEvent('phone:client:localeUpdateResult', src, {
            success = false,
            message = 'Locale is required'
        })
        return
    end
    
    -- Validate locale
    local validLocales = Config.SupportedLocales or {'en', 'ja', 'es', 'fr', 'de', 'pt'}
    local isValid = false
    for _, locale in ipairs(validLocales) do
        if data.locale == locale then
            isValid = true
            break
        end
    end
    
    if not isValid then
        TriggerClientEvent('phone:client:localeUpdateResult', src, {
            success = false,
            message = 'Invalid locale'
        })
        return
    end
    
    -- Update locale setting
    local success, result = Settings.UpdateSetting(phoneNumber, 'locale', data.locale)
    
    if success then
        TriggerClientEvent('phone:client:localeUpdateResult', src, {
            success = true,
            locale = data.locale
        })
    else
        TriggerClientEvent('phone:client:localeUpdateResult', src, {
            success = false,
            message = result or 'Failed to update locale'
        })
    end
end)

-- Export functions for use by other resources
exports('GetPlayerSettings', Settings.GetPlayerSettings)
exports('UpdatePlayerSettings', Settings.UpdatePlayerSettings)
exports('UpdateSetting', Settings.UpdateSetting)
exports('CreatePlayerSettings', Settings.CreatePlayerSettings)
exports('DeletePlayerSettings', Settings.DeletePlayerSettings)
exports('ClearSettingsCache', Settings.ClearCache)

return Settings
