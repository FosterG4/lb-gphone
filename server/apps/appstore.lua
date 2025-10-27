-- App Store Management System
-- Handles app installation, uninstallation, and app directory

local AppStore = {}

-- Available apps in the store
local availableApps = {
    {
        id = 'contacts',
        name = 'Contacts',
        icon = '👤',
        category = 'communication',
        shortDescription = 'Manage your contacts',
        description = 'Store and organize phone numbers of other players. Add, edit, and delete contacts with ease.',
        developer = 'FiveM Phone',
        version = '1.0.0',
        size = '2.5 MB',
        rating = 4.8,
        ratingCount = 1250,
        screenshots = {'screenshot1', 'screenshot2'},
        features = {
            'Add and manage contacts',
            'Search contacts by name or number',
            'Quick dial from contact list',
            'Contact groups and favorites'
        },
        isCore = true,
        enabled = true
    },
    {
        id = 'messages',
        name = 'Messages',
        icon = '💬',
        category = 'communication',
        shortDescription = 'Send and receive text messages',
        description = 'Stay connected with other players through text messaging. Send messages, create conversations, and never miss an important update.',
        developer = 'FiveM Phone',
        version = '1.0.0',
        size = '3.2 MB',
        rating = 4.7,
        ratingCount = 1180,
        screenshots = {'screenshot1', 'screenshot2'},
        features = {
            'Send and receive messages',
            'Conversation threads',
            'Message notifications',
            'Offline message delivery'
        },
        isCore = true,
        enabled = true
    },
    {
        id = 'dialer',
        name = 'Phone',
        icon = '📞',
        category = 'communication',
        shortDescription = 'Make voice calls',
        description = 'Make voice calls to other players using integrated voice chat. Crystal clear audio quality with pma-voice integration.',
        developer = 'FiveM Phone',
        version = '1.0.0',
        size = '2.8 MB',
        rating = 4.6,
        ratingCount = 980,
        screenshots = {'screenshot1', 'screenshot2'},
        features = {
            'Voice calls with pma-voice',
            'Call history',
            'Incoming call notifications',
            'Call waiting support'
        },
        isCore = true,
        enabled = true
    },
    {
        id = 'camera',
        name = 'Camera',
        icon = '📷',
        category = 'media',
        shortDescription = 'Capture photos and videos',
        description = 'Capture memorable moments with the built-in camera. Take photos, record videos, and apply filters.',
        developer = 'FiveM Phone',
        version = '1.0.0',
        size = '4.5 MB',
        rating = 4.9,
        ratingCount = 1520,
        screenshots = {'screenshot1', 'screenshot2', 'screenshot3'},
        features = {
            'Photo capture',
            'Video recording',
            'Camera filters',
            'Flash and camera flip'
        },
        isCore = false,
        enabled = true
    },
    {
        id = 'photos',
        name = 'Photos',
        icon = '🖼️',
        category = 'media',
        shortDescription = 'View and organize your media',
        description = 'Browse your photo and video gallery. Create albums, share media, and relive your favorite moments.',
        developer = 'FiveM Phone',
        version = '1.0.0',
        size = '3.8 MB',
        rating = 4.7,
        ratingCount = 1340,
        screenshots = {'screenshot1', 'screenshot2'},
        features = {
            'Photo and video gallery',
            'Album organization',
            'Media sharing',
            'Full-screen viewer'
        },
        isCore = false,
        enabled = true
    },
    {
        id = 'settings',
        name = 'Settings',
        icon = '⚙️',
        category = 'utilities',
        shortDescription = 'Customize your phone',
        description = 'Personalize your phone experience. Change themes, adjust notifications, and configure app settings.',
        developer = 'FiveM Phone',
        version = '1.0.0',
        size = '2.1 MB',
        rating = 4.5,
        ratingCount = 890,
        screenshots = {'screenshot1'},
        features = {
            'Theme customization',
            'Notification settings',
            'Sound and volume control',
            'Display preferences'
        },
        isCore = true,
        enabled = true
    },
    {
        id = 'clock',
        name = 'Clock',
        icon = '⏰',
        category = 'utilities',
        shortDescription = 'Alarms, timers, and stopwatch',
        description = 'Never miss an important event. Set alarms, use timers, and track time with the stopwatch.',
        developer = 'FiveM Phone',
        version = '1.0.0',
        size = '2.3 MB',
        rating = 4.6,
        ratingCount = 760,
        screenshots = {'screenshot1', 'screenshot2'},
        features = {
            'Multiple alarms',
            'Countdown timer',
            'Stopwatch with laps',
            'In-game time display'
        },
        isCore = false,
        enabled = true
    },
    {
        id = 'notes',
        name = 'Notes',
        icon = '📝',
        category = 'productivity',
        shortDescription = 'Take notes and reminders',
        description = 'Keep track of important information. Create, edit, and organize notes for quick reference.',
        developer = 'FiveM Phone',
        version = '1.0.0',
        size = '1.9 MB',
        rating = 4.4,
        ratingCount = 650,
        screenshots = {'screenshot1'},
        features = {
            'Create and edit notes',
            'Auto-save functionality',
            'Search notes',
            'Rich text support'
        },
        isCore = false,
        enabled = true
    },
    {
        id = 'maps',
        name = 'Maps',
        icon = '🗺️',
        category = 'utilities',
        shortDescription = 'Navigation and location sharing',
        description = 'Find your way around the city. Set waypoints, save locations, and share your position with friends.',
        developer = 'FiveM Phone',
        version = '1.0.0',
        size = '5.2 MB',
        rating = 4.8,
        ratingCount = 1420,
        screenshots = {'screenshot1', 'screenshot2'},
        features = {
            'Interactive map',
            'GPS waypoints',
            'Location pins',
            'Real-time location sharing'
        },
        isCore = false,
        enabled = true
    },
    {
        id = 'weather',
        name = 'Weather',
        icon = '🌤️',
        category = 'utilities',
        shortDescription = 'Weather forecasts',
        description = 'Stay informed about weather conditions. View current weather and 24-hour forecasts.',
        developer = 'FiveM Phone',
        version = '1.0.0',
        size = '2.7 MB',
        rating = 4.3,
        ratingCount = 580,
        screenshots = {'screenshot1'},
        features = {
            'Current weather conditions',
            '24-hour forecast',
            'Temperature and wind data',
            'Auto-refresh'
        },
        isCore = false,
        enabled = true
    },
    {
        id = 'bank',
        name = 'Bank',
        icon = '🏦',
        category = 'finance',
        shortDescription = 'Manage your finances',
        description = 'Access your bank account on the go. Check balance, transfer money, and view transaction history.',
        developer = 'FiveM Phone',
        version = '1.0.0',
        size = '3.4 MB',
        rating = 4.7,
        ratingCount = 1150,
        screenshots = {'screenshot1', 'screenshot2'},
        features = {
            'Account balance',
            'Money transfers',
            'Transaction history',
            'Framework integration'
        },
        isCore = false,
        enabled = true
    },
    {
        id = 'chirper',
        name = 'Chirper',
        icon = '🐦',
        category = 'social',
        shortDescription = 'Social media feed',
        description = 'Share your thoughts with the community. Post chirps, like, and reply to others.',
        developer = 'FiveM Phone',
        version = '1.0.0',
        size = '4.1 MB',
        rating = 4.5,
        ratingCount = 920,
        screenshots = {'screenshot1', 'screenshot2'},
        features = {
            'Post chirps',
            'Like and reply',
            'Real-time feed',
            'Trending topics'
        },
        isCore = false,
        enabled = true
    },
    {
        id = 'crypto',
        name = 'Crypto',
        icon = '₿',
        category = 'finance',
        shortDescription = 'Cryptocurrency trading',
        description = 'Trade virtual cryptocurrencies. Buy and sell coins, track your portfolio, and watch live prices.',
        developer = 'FiveM Phone',
        version = '1.0.0',
        size = '3.9 MB',
        rating = 4.6,
        ratingCount = 840,
        screenshots = {'screenshot1', 'screenshot2'},
        features = {
            'Buy and sell crypto',
            'Live price updates',
            'Portfolio tracking',
            'Multiple cryptocurrencies'
        },
        isCore = false,
        enabled = true
    },
    {
        id = 'garage',
        name = 'Garage',
        icon = '🚗',
        category = 'utilities',
        shortDescription = 'Manage your vehicles',
        description = 'Access your vehicle garage remotely. View vehicle locations, request valet service, and track your cars.',
        developer = 'FiveM Phone',
        version = '1.0.0',
        size = '3.6 MB',
        rating = 4.8,
        ratingCount = 1280,
        screenshots = {'screenshot1', 'screenshot2'},
        features = {
            'Vehicle list',
            'Valet service',
            'Vehicle tracking',
            'Garage integration'
        },
        isCore = false,
        enabled = Config.GarageApp and Config.GarageApp.enabled or false
    },
    {
        id = 'home',
        name = 'Home',
        icon = '🏠',
        category = 'utilities',
        shortDescription = 'Property management',
        description = 'Control your properties remotely. Lock/unlock doors, manage keys, and view access logs.',
        developer = 'FiveM Phone',
        version = '1.0.0',
        size = '3.3 MB',
        rating = 4.7,
        ratingCount = 1090,
        screenshots = {'screenshot1', 'screenshot2'},
        features = {
            'Property list',
            'Remote lock control',
            'Key management',
            'Access logs'
        },
        isCore = false,
        enabled = Config.HomeApp and Config.HomeApp.enabled or false
    }
}

-- Get player's installed apps from database
function AppStore.GetInstalledApps(phoneNumber)
    local result = MySQL.query.await('SELECT installed_apps FROM phone_players WHERE phone_number = ?', {phoneNumber})
    
    if result and result[1] then
        local installedAppsJson = result[1].installed_apps
        if installedAppsJson then
            return json.decode(installedAppsJson) or {}
        end
    end
    
    -- Return default installed apps (core apps)
    local defaultApps = {}
    for _, app in ipairs(availableApps) do
        if app.isCore then
            table.insert(defaultApps, app.id)
        end
    end
    
    return defaultApps
end

-- Save installed apps to database
function AppStore.SaveInstalledApps(phoneNumber, installedApps)
    local installedAppsJson = json.encode(installedApps)
    
    MySQL.update.await('UPDATE phone_players SET installed_apps = ? WHERE phone_number = ?', {
        installedAppsJson,
        phoneNumber
    })
end

-- Get available apps (filtered by config)
function AppStore.GetAvailableApps()
    local apps = {}
    
    for _, app in ipairs(availableApps) do
        -- Check if app is enabled in config
        local configEnabled = true
        if Config.EnabledApps and Config.EnabledApps[app.id] ~= nil then
            configEnabled = Config.EnabledApps[app.id]
        end
        
        if app.enabled and configEnabled then
            table.insert(apps, app)
        end
    end
    
    return apps
end

-- Install an app
function AppStore.InstallApp(source, phoneNumber, appId)
    -- Validate app exists
    local appExists = false
    local appData = nil
    for _, app in ipairs(availableApps) do
        if app.id == appId then
            appExists = true
            appData = app
            break
        end
    end
    
    if not appExists then
        return {success = false, message = 'App not found'}
    end
    
    -- Check if app is enabled
    if not appData.enabled then
        return {success = false, message = 'App is not available'}
    end
    
    -- Check config
    if Config.EnabledApps and Config.EnabledApps[appId] == false then
        return {success = false, message = 'App is disabled by server configuration'}
    end
    
    -- Check if app installation is allowed
    if Config.AppStoreApp and not Config.AppStoreApp.allowInstall then
        return {success = false, message = 'App installation is disabled'}
    end
    
    -- Get current installed apps
    local installedApps = AppStore.GetInstalledApps(phoneNumber)
    
    -- Check if already installed
    for _, installedAppId in ipairs(installedApps) do
        if installedAppId == appId then
            return {success = false, message = 'App is already installed'}
        end
    end
    
    -- Add app to installed list
    table.insert(installedApps, appId)
    
    -- Save to database
    AppStore.SaveInstalledApps(phoneNumber, installedApps)
    
    -- Log installation
    if Config.Debug then
        print(string.format('[Phone] Player %s installed app: %s', phoneNumber, appId))
    end
    
    return {success = true, message = 'App installed successfully'}
end

-- Uninstall an app
function AppStore.UninstallApp(source, phoneNumber, appId)
    -- Check if app uninstallation is allowed
    if Config.AppStoreApp and not Config.AppStoreApp.allowUninstall then
        return {success = false, message = 'App uninstallation is disabled'}
    end
    
    -- Check if app is core (cannot be uninstalled)
    for _, app in ipairs(availableApps) do
        if app.id == appId and app.isCore then
            return {success = false, message = 'Cannot uninstall core app'}
        end
    end
    
    -- Get current installed apps
    local installedApps = AppStore.GetInstalledApps(phoneNumber)
    
    -- Find and remove app
    local found = false
    for i, installedAppId in ipairs(installedApps) do
        if installedAppId == appId then
            table.remove(installedApps, i)
            found = true
            break
        end
    end
    
    if not found then
        return {success = false, message = 'App is not installed'}
    end
    
    -- Save to database
    AppStore.SaveInstalledApps(phoneNumber, installedApps)
    
    -- Log uninstallation
    if Config.Debug then
        print(string.format('[Phone] Player %s uninstalled app: %s', phoneNumber, appId))
    end
    
    return {success = true, message = 'App uninstalled successfully'}
end

-- Server events for app store operations
RegisterServerEvent('phone:server:getAvailableApps')
AddEventHandler('phone:server:getAvailableApps', function()
    local source = source
    local phoneNumber = exports['fivem-smartphone-nui']:GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:appStoreData', source, {success = false, message = 'Phone number not found'})
        return
    end
    
    local apps = AppStore.GetAvailableApps()
    local installedApps = AppStore.GetInstalledApps(phoneNumber)
    
    TriggerClientEvent('phone:client:appStoreData', source, {
        success = true,
        apps = apps,
        installedApps = installedApps
    })
end)

RegisterServerEvent('phone:server:installApp')
AddEventHandler('phone:server:installApp', function(appId)
    local source = source
    local phoneNumber = exports['fivem-smartphone-nui']:GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:installAppResult', source, {success = false, message = 'Phone number not found'})
        return
    end
    
    if not appId then
        TriggerClientEvent('phone:client:installAppResult', source, {success = false, message = 'App ID is required'})
        return
    end
    
    local result = AppStore.InstallApp(source, phoneNumber, appId)
    TriggerClientEvent('phone:client:installAppResult', source, result)
end)

RegisterServerEvent('phone:server:uninstallApp')
AddEventHandler('phone:server:uninstallApp', function(appId)
    local source = source
    local phoneNumber = exports['fivem-smartphone-nui']:GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:uninstallAppResult', source, {success = false, message = 'Phone number not found'})
        return
    end
    
    if not appId then
        TriggerClientEvent('phone:client:uninstallAppResult', source, {success = false, message = 'App ID is required'})
        return
    end
    
    local result = AppStore.UninstallApp(source, phoneNumber, appId)
    TriggerClientEvent('phone:client:uninstallAppResult', source, result)
end)

-- Export functions
exports('GetInstalledApps', function(phoneNumber)
    return AppStore.GetInstalledApps(phoneNumber)
end)

exports('GetAvailableApps', function()
    return AppStore.GetAvailableApps()
end)

return AppStore
