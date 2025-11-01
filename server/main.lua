-- Server Main
-- Handles server initialization and player management

local ConfigValidator = require('server.config_validator')
local Database = require('server.database')
local Contacts = require('server.contacts')
local playerPhoneNumbers = {} -- Cache for player phone numbers

-- Framework adapter instance
Framework = nil

-- Initialize framework adapter
local function InitializeFramework()
    local frameworkType = Config.Framework or 'standalone'
    
    print('^3[Phone] ^7Loading framework adapter: ' .. frameworkType)
    
    -- Load the appropriate framework adapter
    if frameworkType == 'esx' then
        Framework = require('server.framework.esx')
    elseif frameworkType == 'qbcore' then
        Framework = require('server.framework.qbcore')
    elseif frameworkType == 'qbox' then
        Framework = require('server.framework.qbox')
    else
        Framework = require('server.framework.standalone')
    end
    
    if not Framework then
        print('^1[Phone] ^7Failed to initialize framework adapter! Falling back to standalone mode.')
        Framework = require('server.framework.standalone')
    end
    
    return Framework ~= nil
end

-- Initialize resource
CreateThread(function()
    print('^2[Phone] ^7Initializing smartphone system...')
    
    -- Run installation checks first
    local InstallationManager = require('server.install')
    local installSuccess = InstallationManager:Run()
    
    if not installSuccess then
        print('^1[Phone] ^7Installation checks failed! Please fix the errors above.')
        print('^1[Phone] ^7Resource initialization aborted.')
        return
    end
    
    -- Validate configuration
    local configValid = ConfigValidator.ValidateAll()
    if not configValid then
        print('^1[Phone] ^7Configuration validation failed! Please fix the errors above.')
        print('^1[Phone] ^7Resource initialization aborted.')
        return
    end
    
    -- Initialize database
    local dbSuccess = Database.Initialize()
    if not dbSuccess then
        print('^1[Phone] ^7Failed to initialize database! Resource may not function properly.')
        return
    end
    
    -- Initialize framework adapter
    local frameworkSuccess = InitializeFramework()
    if not frameworkSuccess then
        print('^1[Phone] ^7Failed to initialize framework adapter! Resource may not function properly.')
        return
    end
    
    -- Initialize media storage
    local Storage = require('server.media.storage')
    Storage.Initialize()
    
    print('^2[Phone] ^7Smartphone system initialized successfully!')
end)

-- Player connected event
RegisterNetEvent('phone:server:playerLoaded', function()
    local src = source
    
    if not Framework then
        print('^1[Phone] ^7Framework not initialized!')
        return
    end
    
    -- Get player identifier using framework adapter
    local identifier = Framework:GetIdentifier(src)
    
    if not identifier then
        print('^1[Phone] ^7Failed to get identifier for player ' .. src)
        return
    end
    
    -- Get or create player phone number
    Database.GetOrCreatePlayer(identifier, function(phoneNumber)
        if not phoneNumber then
            print('^1[Phone] ^7Failed to get/create phone number for player ' .. src)
            return
        end
        
        -- Cache phone number
        playerPhoneNumbers[src] = phoneNumber
        
        -- For frameworks that support it, update phone number in framework data
        if Config.Framework == 'qbcore' or Config.Framework == 'qbox' then
            Framework:SetPhoneNumber(src, phoneNumber)
        end
        
        if Config.DebugMode then
            print('[Phone] Player ' .. src .. ' loaded with phone number: ' .. phoneNumber)
        end
        
        -- Load all player phone data
        LoadPlayerPhoneData(src, phoneNumber)
    end)
end)

-- Load all player phone data (contacts, messages, call history)
function LoadPlayerPhoneData(source, phoneNumber)
    if not source or not phoneNumber then
        print('^1[Phone] ^7LoadPlayerPhoneData: Invalid parameters')
        return
    end
    
    local phoneData = {
        phoneNumber = phoneNumber,
        contacts = {},
        messages = {},
        callHistory = {}
    }
    
    -- Counter to track async operations
    local loadedCount = 0
    local totalLoads = 3
    
    local function checkComplete()
        loadedCount = loadedCount + 1
        if loadedCount >= totalLoads then
            -- All data loaded, send to client
            TriggerClientEvent('phone:client:loadPhoneData', source, phoneData)
            
            if Config.DebugMode then
                print('[Phone] Loaded phone data for player ' .. source .. ': ' .. 
                      #phoneData.contacts .. ' contacts, ' .. 
                      #phoneData.messages .. ' messages, ' .. 
                      #phoneData.callHistory .. ' call history entries')
            end
        end
    end
    
    -- Load contacts
    Database.GetContacts(phoneNumber, function(contacts)
        phoneData.contacts = contacts or {}
        checkComplete()
    end)
    
    -- Load all messages (not just specific conversations)
    local query = [[
        SELECT * FROM phone_messages 
        WHERE sender_number = ? OR receiver_number = ?
        ORDER BY created_at ASC
    ]]
    
    Database.Query(query, {phoneNumber, phoneNumber}, function(messages)
        phoneData.messages = messages or {}
        checkComplete()
    end)
    
    -- Load call history
    Database.GetCallHistory(phoneNumber, function(history)
        phoneData.callHistory = history or {}
        checkComplete()
    end)
end

-- Request phone data
RegisterNetEvent('phone:server:requestPhoneData', function()
    local src = source
    local phoneNumber = playerPhoneNumbers[src]
    
    if not phoneNumber then
        if not Framework then
            print('^1[Phone] ^7Framework not initialized!')
            return
        end
        
        local identifier = Framework:GetIdentifier(src)
        
        if not identifier then
            print('^1[Phone] ^7Failed to get identifier for player ' .. src)
            return
        end
        
        Database.GetOrCreatePlayer(identifier, function(phone)
            if phone then
                playerPhoneNumbers[src] = phone
                
                -- For frameworks that support it, update phone number in framework data
                if Config.Framework == 'qbcore' or Config.Framework == 'qbox' then
                    Framework:SetPhoneNumber(src, phone)
                end
                
                TriggerClientEvent('phone:client:setPhoneNumber', src, phone)
            end
        end)
    else
        -- Send phone number to client
        TriggerClientEvent('phone:client:setPhoneNumber', src, phoneNumber)
    end
end)

-- Player disconnected
AddEventHandler('playerDropped', function()
    local src = source
    local phoneNumber = playerPhoneNumbers[src]
    
    -- Cleanup active calls if player was in one
    if phoneNumber then
        CleanupPlayerCalls(src, phoneNumber)
    end
    
    -- Clear cached data
    if playerPhoneNumbers[src] then
        playerPhoneNumbers[src] = nil
    end
    
    -- Cleanup framework-specific data for standalone mode
    if Framework and Config.Framework == 'standalone' and Framework.OnPlayerDropped then
        Framework:OnPlayerDropped(src)
    end
    
    if Config.DebugMode then
        print('[Phone] Player ' .. src .. ' disconnected, cleaned up phone data')
    end
end)

-- Cleanup player calls on disconnect
function CleanupPlayerCalls(source, phoneNumber)
    if not source or not phoneNumber then
        return
    end
    
    -- Trigger call cleanup event (handled by calls.lua module)
    TriggerEvent('phone:server:cleanupPlayerCalls', source, phoneNumber)
    
    if Config.DebugMode then
        print('[Phone] Cleaning up calls for disconnected player: ' .. phoneNumber)
    end
end

-- Get player phone number from cache or database
function GetCachedPhoneNumber(source)
    return playerPhoneNumbers[source]
end

-- Get framework instance
function GetFramework()
    return Framework
end

-- Export framework functions for other resources
exports('GetFramework', GetFramework)
exports('GetPlayerPhoneNumber', GetCachedPhoneNumber)
exports('ValidateConfig', function() return ConfigValidator.ValidateAll() end)
exports('GetConfigValidationResults', function() return ConfigValidator.GetResults() end)

-- Export installation functions
exports('GetInstallationStatus', function()
    local InstallationManager = require('server.install')
    return {
        complete = InstallationManager:IsComplete(),
        errors = InstallationManager:GetErrors(),
        warnings = InstallationManager:GetWarnings()
    }
end)
exports('RunInstallation', function()
    local InstallationManager = require('server.install')
    return InstallationManager:Run()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('^3[Phone] ^7Smartphone system stopped')
    end
end)

-- Load media modules
require('server.media.photos')
require('server.media.videos')
require('server.media.audio')
require('server.media.migration')
require('server.media.testing')


-- Media Management Event Handlers

-- Get media (photos, videos, audio)
RegisterNetEvent('phone:server:getMedia', function(data)
    local src = source
    local phoneNumber = GetCachedPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveMedia', src, {
            success = false,
            error = 'Phone number not found'
        })
        return
    end
    
    local Storage = require('server.media.storage')
    local mediaType = data.mediaType or nil
    local limit = data.limit or 20
    local offset = data.offset or 0
    
    local media = Storage.GetPlayerMedia(phoneNumber, mediaType, limit, offset)
    
    -- Organize media by type
    local result = {
        success = true,
        data = {
            photos = {},
            videos = {},
            audio = {}
        }
    }
    
    for _, item in ipairs(media) do
        if item.media_type == 'photo' then
            table.insert(result.data.photos, item)
        elseif item.media_type == 'video' then
            table.insert(result.data.videos, item)
        elseif item.media_type == 'audio' then
            table.insert(result.data.audio, item)
        end
    end
    
    TriggerClientEvent('phone:client:receiveMedia', src, result)
end)

-- Delete media
RegisterNetEvent('phone:server:deleteMedia', function(data)
    local src = source
    local phoneNumber = GetCachedPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:mediaDeleteResult', src, {
            success = false,
            error = 'Phone number not found'
        })
        return
    end
    
    if not data.mediaId then
        TriggerClientEvent('phone:client:mediaDeleteResult', src, {
            success = false,
            error = 'Media ID is required'
        })
        return
    end
    
    local Storage = require('server.media.storage')
    local result = Storage.DeleteMedia(data.mediaId, phoneNumber)
    
    TriggerClientEvent('phone:client:mediaDeleteResult', src, result)
end)

-- Album Management Event Handlers

-- Get albums
RegisterNetEvent('phone:server:getAlbums', function()
    local src = source
    local phoneNumber = GetCachedPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveAlbums', src, {
            success = false,
            error = 'Phone number not found'
        })
        return
    end
    
    local query = [[
        SELECT a.*, COUNT(am.media_id) as media_count
        FROM phone_albums a
        LEFT JOIN phone_album_media am ON a.id = am.album_id
        WHERE a.owner_number = ?
        GROUP BY a.id
        ORDER BY a.created_at DESC
    ]]
    
    Database.Query(query, {phoneNumber}, function(albums)
        TriggerClientEvent('phone:client:receiveAlbums', src, {
            success = true,
            data = albums or {}
        })
    end)
end)

-- Create album
RegisterNetEvent('phone:server:createAlbum', function(data)
    local src = source
    local phoneNumber = GetCachedPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:albumCreateResult', src, {
            success = false,
            error = 'Phone number not found'
        })
        return
    end
    
    if not data.name then
        TriggerClientEvent('phone:client:albumCreateResult', src, {
            success = false,
            error = 'Album name is required'
        })
        return
    end
    
    local query = [[
        INSERT INTO phone_albums (owner_number, album_name, cover_media_id)
        VALUES (?, ?, ?)
    ]]
    
    Database.Execute(query, {phoneNumber, data.name, data.coverMediaId}, function(result)
        if result then
            TriggerClientEvent('phone:client:albumCreateResult', src, {
                success = true,
                data = {
                    id = result,
                    owner_number = phoneNumber,
                    album_name = data.name,
                    cover_media_id = data.coverMediaId
                }
            })
        else
            TriggerClientEvent('phone:client:albumCreateResult', src, {
                success = false,
                error = 'Failed to create album'
            })
        end
    end)
end)

-- Update album
RegisterNetEvent('phone:server:updateAlbum', function(data)
    local src = source
    local phoneNumber = GetCachedPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:albumUpdateResult', src, {
            success = false,
            error = 'Phone number not found'
        })
        return
    end
    
    if not data.albumId then
        TriggerClientEvent('phone:client:albumUpdateResult', src, {
            success = false,
            error = 'Album ID is required'
        })
        return
    end
    
    -- Build update query dynamically based on provided updates
    local updates = data.updates or {}
    local setClause = {}
    local params = {}
    
    if updates.album_name then
        table.insert(setClause, 'album_name = ?')
        table.insert(params, updates.album_name)
    end
    
    if updates.cover_media_id then
        table.insert(setClause, 'cover_media_id = ?')
        table.insert(params, updates.cover_media_id)
    end
    
    if #setClause == 0 then
        TriggerClientEvent('phone:client:albumUpdateResult', src, {
            success = false,
            error = 'No updates provided'
        })
        return
    end
    
    table.insert(params, data.albumId)
    table.insert(params, phoneNumber)
    
    local query = 'UPDATE phone_albums SET ' .. table.concat(setClause, ', ') .. ' WHERE id = ? AND owner_number = ?'
    
    Database.Execute(query, params, function(result)
        if result then
            TriggerClientEvent('phone:client:albumUpdateResult', src, {
                success = true
            })
        else
            TriggerClientEvent('phone:client:albumUpdateResult', src, {
                success = false,
                error = 'Failed to update album'
            })
        end
    end)
end)

-- Delete album
RegisterNetEvent('phone:server:deleteAlbum', function(data)
    local src = source
    local phoneNumber = GetCachedPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:albumDeleteResult', src, {
            success = false,
            error = 'Phone number not found'
        })
        return
    end
    
    if not data.albumId then
        TriggerClientEvent('phone:client:albumDeleteResult', src, {
            success = false,
            error = 'Album ID is required'
        })
        return
    end
    
    local query = 'DELETE FROM phone_albums WHERE id = ? AND owner_number = ?'
    
    Database.Execute(query, {data.albumId, phoneNumber}, function(result)
        if result then
            -- Album media entries will be deleted automatically via CASCADE
            TriggerClientEvent('phone:client:albumDeleteResult', src, {
                success = true
            })
        else
            TriggerClientEvent('phone:client:albumDeleteResult', src, {
                success = false,
                error = 'Failed to delete album'
            })
        end
    end)
end)
