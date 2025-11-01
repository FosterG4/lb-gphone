-- ============================================================================
-- Client Contact Sharing Module
-- ============================================================================
-- Handles phone state management and proximity-based contact sharing on the
-- client side. Manages coordinate updates, nearby player tracking, and
-- communication with the NUI layer.
--
-- Features:
--   - Phone open/close state tracking
--   - Automatic coordinate updates to server
--   - Nearby players list management
--   - Share request handling
--   - Broadcast share management
--   - NUI event forwarding
--
-- Integration:
--   Exports functions for use by main phone script:
--   - NotifyPhoneOpened(phoneNumber)
--   - NotifyPhoneClosed()
--   - IsPhoneOpen()
--   - GetNearbyPlayers()
--
-- Author: FiveM Smartphone NUI
-- Version: 1.0.0
-- ============================================================================

-- State Variables
local isPhoneOpen = false
local nearbyPlayers = {}
local activeBroadcast = nil
local pendingRequest = nil
local coordUpdateThread = nil
local playerData = {
    phoneNumber = nil,
    characterName = nil
}

-- Debug logging helper
local function DebugLog(message)
    if Config.DebugMode then
        print('[Contact Sharing Client] ' .. message)
    end
end

-- Get player's character name from framework
local function GetCharacterName()
    -- Try to get character name from framework
    if Config.Framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        if ESX and ESX.GetPlayerData then
            local playerData = ESX.GetPlayerData()
            if playerData and playerData.name then
                return playerData.name
            end
        end
    elseif Config.Framework == 'qbcore' or Config.Framework == 'qbox' then
        local QBCore = exports['qb-core']:GetCoreObject()
        if QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData then
            local playerData = QBCore.Functions.GetPlayerData()
            if playerData and playerData.charinfo then
                return playerData.charinfo.firstname .. ' ' .. playerData.charinfo.lastname
            end
        end
    end
    
    -- Fallback to player name
    return GetPlayerName(PlayerId())
end

-- Notify server when phone is opened
-- Registers the player's phone with the server for proximity tracking
-- Starts the coordinate update thread to keep position current
-- @param phoneNumber string - Player's phone number
-- @return void
function NotifyPhoneOpened(phoneNumber)
    if not Config.ContactSharing.enabled then
        return
    end
    
    if not phoneNumber then
        DebugLog('Cannot notify phone opened: no phone number')
        return
    end
    
    isPhoneOpen = true
    playerData.phoneNumber = phoneNumber
    playerData.characterName = GetCharacterName()
    
    -- Get current coordinates
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Notify server
    TriggerServerEvent('phone:server:phoneOpened', phoneNumber, playerData.characterName)
    
    -- Start coordinate update thread
    StartCoordUpdateThread()
    
    DebugLog('Phone opened, notified server')
end

-- Notify server when phone is closed
-- Unregisters the player's phone from proximity tracking
-- Stops the coordinate update thread and clears local state
-- @return void
function NotifyPhoneClosed()
    if not Config.ContactSharing.enabled then
        return
    end
    
    if not isPhoneOpen then
        return
    end
    
    isPhoneOpen = false
    
    -- Notify server
    TriggerServerEvent('phone:server:phoneClosed')
    
    -- Stop coordinate update thread
    StopCoordUpdateThread()
    
    -- Clear state
    nearbyPlayers = {}
    activeBroadcast = nil
    pendingRequest = nil
    
    -- Clear NUI state
    SendNUIMessage({
        action = 'clearContactSharingState'
    })
    
    DebugLog('Phone closed, notified server')
end

-- Start coordinate update thread
-- Creates a thread that sends player coordinates to server every 2 seconds
-- Allows server to track player movement for proximity detection
-- Thread automatically stops when phone is closed
-- @return void
function StartCoordUpdateThread()
    if coordUpdateThread then
        return -- Already running
    end
    
    coordUpdateThread = CreateThread(function()
        while isPhoneOpen do
            Wait(Config.ContactSharing.updateInterval or 2000)
            
            if isPhoneOpen then
                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)
                
                -- Send coordinates to server
                TriggerServerEvent('phone:server:updatePhoneCoords', coords)
            end
        end
        
        coordUpdateThread = nil
    end)
    
    DebugLog('Coordinate update thread started')
end

-- Stop coordinate update thread
function StopCoordUpdateThread()
    if coordUpdateThread then
        coordUpdateThread = nil
        DebugLog('Coordinate update thread stopped')
    end
end

-- Export functions for use by other client scripts
exports('NotifyPhoneOpened', NotifyPhoneOpened)
exports('NotifyPhoneClosed', NotifyPhoneClosed)
exports('IsPhoneOpen', function() return isPhoneOpen end)
exports('GetNearbyPlayers', function() return nearbyPlayers end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isPhoneOpen then
            NotifyPhoneClosed()
        end
    end
end)

DebugLog('Contact Sharing client module initialized')

-- ============================================================================
-- Client Event Handlers
-- ============================================================================

-- Handle nearby players update from server
RegisterNetEvent('phone:client:nearbyPlayersUpdate', function(players)
    if not Config.ContactSharing.enabled then
        return
    end
    
    nearbyPlayers = players or {}
    
    -- Forward to NUI
    SendNUIMessage({
        action = 'updateNearbyPlayers',
        data = {
            players = nearbyPlayers
        }
    })
    
    if Config.DebugMode then
        DebugLog('Nearby players updated: ' .. #nearbyPlayers .. ' players')
    end
end)

-- Handle share request received from another player
RegisterNetEvent('phone:client:shareRequestReceived', function(requestData)
    if not Config.ContactSharing.enabled then
        return
    end
    
    if not requestData then
        DebugLog('Received invalid share request data')
        return
    end
    
    pendingRequest = requestData
    
    -- Forward to NUI to show notification
    SendNUIMessage({
        type = 'shareRequestReceived',
        request = {
            requestId = requestData.requestId,
            senderName = requestData.senderName,
            senderNumber = requestData.senderNumber,
            expiresAt = requestData.expiresAt
        }
    })
    
    -- Play notification sound if enabled
    if Config.ContactSharing.playSound then
        PlaySoundFrontend(-1, 'Menu_Accept', 'Phone_SoundSet_Default', true)
    end
    
    DebugLog('Share request received from: ' .. requestData.senderName)
end)

-- Handle share request response (accept/decline result)
RegisterNetEvent('phone:client:shareRequestResponse', function(response)
    if not Config.ContactSharing.enabled then
        return
    end
    
    if not response then
        DebugLog('Received invalid share request response')
        return
    end
    
    -- Forward to NUI
    SendNUIMessage({
        action = 'shareRequestResponse',
        data = response
    })
    
    -- Show appropriate notification based on response
    if response.success then
        if response.declined then
            -- Show decline notification to sender
            SendNUIMessage({
                action = 'showShareDeclinedNotification',
                data = {
                    contactName = response.receiverName or 'Player'
                }
            })
        end
    else
        -- Show error notification
        SendNUIMessage({
            action = 'showShareErrorNotification',
            data = {
                errorMessage = response.error or response.message or 'Share failed'
            }
        })
    end
    
    -- Play sound based on result
    if Config.ContactSharing.playSound then
        if response.success then
            if response.accepted then
                PlaySoundFrontend(-1, 'Menu_Accept', 'Phone_SoundSet_Default', true)
            elseif response.declined then
                PlaySoundFrontend(-1, 'Highlight_Cancel', 'DLC_HEIST_PLANNING_BOARD_SOUNDS', true)
            end
        else
            PlaySoundFrontend(-1, 'Highlight_Cancel', 'DLC_HEIST_PLANNING_BOARD_SOUNDS', true)
        end
    end
    
    if Config.DebugMode then
        DebugLog('Share request response: ' .. (response.message or 'No message'))
    end
end)

-- Handle share request expired
RegisterNetEvent('phone:client:shareRequestExpired', function(requestId)
    if not Config.ContactSharing.enabled then
        return
    end
    
    if pendingRequest and pendingRequest.requestId == requestId then
        pendingRequest = nil
    end
    
    -- Forward to NUI to dismiss notification
    SendNUIMessage({
        action = 'shareRequestExpired',
        data = {
            requestId = requestId
        }
    })
    
    DebugLog('Share request expired: ' .. requestId)
end)

-- Handle broadcast share started
RegisterNetEvent('phone:client:broadcastShareStarted', function(broadcastData)
    if not Config.ContactSharing.enabled then
        return
    end
    
    if not broadcastData then
        DebugLog('Received invalid broadcast share data')
        return
    end
    
    -- Check if this is our own broadcast
    if broadcastData.success then
        activeBroadcast = broadcastData
        
        -- Forward to NUI to show broadcast UI
        SendNUIMessage({
            action = 'broadcastShareStarted',
            data = {
                phoneNumber = broadcastData.phoneNumber,
                expiresAt = broadcastData.expiresAt,
                duration = broadcastData.duration,
                isOwnBroadcast = true
            }
        })
        
        DebugLog('Started broadcasting contact')
    else
        -- Another player started broadcasting
        SendNUIMessage({
            action = 'nearbyPlayerBroadcasting',
            data = {
                phoneNumber = broadcastData.phoneNumber,
                characterName = broadcastData.characterName,
                expiresAt = broadcastData.expiresAt,
                isBroadcasting = true
            }
        })
        
        DebugLog('Nearby player broadcasting: ' .. (broadcastData.characterName or 'Unknown'))
    end
    
    -- Play sound if enabled
    if Config.ContactSharing.playSound then
        PlaySoundFrontend(-1, 'Menu_Accept', 'Phone_SoundSet_Default', true)
    end
end)

-- Handle broadcast share stopped
RegisterNetEvent('phone:client:broadcastShareStopped', function(stopData)
    if not Config.ContactSharing.enabled then
        return
    end
    
    if not stopData then
        DebugLog('Received invalid broadcast stop data')
        return
    end
    
    -- Check if this is our own broadcast
    if stopData.success or (activeBroadcast and activeBroadcast.phoneNumber == stopData.phoneNumber) then
        activeBroadcast = nil
        
        -- Forward to NUI to hide broadcast UI
        SendNUIMessage({
            action = 'broadcastShareStopped',
            data = {
                phoneNumber = stopData.phoneNumber,
                reason = stopData.reason,
                isOwnBroadcast = true
            }
        })
        
        DebugLog('Stopped broadcasting contact: ' .. (stopData.reason or 'unknown'))
    else
        -- Another player stopped broadcasting
        SendNUIMessage({
            action = 'nearbyPlayerStoppedBroadcasting',
            data = {
                phoneNumber = stopData.phoneNumber,
                reason = stopData.reason
            }
        })
        
        DebugLog('Nearby player stopped broadcasting')
    end
end)

-- Handle broadcast share response (add from broadcast result)
RegisterNetEvent('phone:client:addFromBroadcastResponse', function(response)
    if not Config.ContactSharing.enabled then
        return
    end
    
    if not response then
        DebugLog('Received invalid add from broadcast response')
        return
    end
    
    -- Forward to NUI
    SendNUIMessage({
        action = 'addFromBroadcastResponse',
        data = response
    })
    
    -- Show appropriate notification
    if response.success then
        -- Contact added notification is shown by ShareModal component
        -- No need to show duplicate notification here
    else
        -- Show error notification
        SendNUIMessage({
            action = 'showShareErrorNotification',
            data = {
                errorMessage = response.error or response.message or 'Failed to add contact'
            }
        })
    end
    
    -- Play sound based on result
    if Config.ContactSharing.playSound then
        if response.success then
            PlaySoundFrontend(-1, 'Menu_Accept', 'Phone_SoundSet_Default', true)
        else
            PlaySoundFrontend(-1, 'Highlight_Cancel', 'DLC_HEIST_PLANNING_BOARD_SOUNDS', true)
        end
    end
    
    if Config.DebugMode then
        DebugLog('Add from broadcast response: ' .. (response.message or 'No message'))
    end
end)

-- Handle broadcast contact added notification (for broadcaster)
RegisterNetEvent('phone:client:broadcastContactAdded', function(data)
    if not Config.ContactSharing.enabled then
        return
    end
    
    if not data then
        return
    end
    
    -- Forward to NUI to show notification
    SendNUIMessage({
        action = 'broadcastContactAdded',
        data = {
            addedBy = data.addedBy,
            addedByNumber = data.addedByNumber
        }
    })
    
    -- Show broadcast contact added notification
    SendNUIMessage({
        action = 'showBroadcastContactAddedNotification',
        data = {
            addedBy = data.addedBy
        }
    })
    
    -- Play sound if enabled
    if Config.ContactSharing.playSound then
        PlaySoundFrontend(-1, 'Menu_Accept', 'Phone_SoundSet_Default', true)
    end
    
    DebugLog('Contact added by: ' .. (data.addedBy or 'Unknown'))
end)

-- Handle contact added notification
RegisterNetEvent('phone:client:contactAdded', function(contactData)
    if not Config.ContactSharing.enabled then
        return
    end
    
    if not contactData then
        return
    end
    
    -- Forward to NUI
    SendNUIMessage({
        action = 'contactAddedFromShare',
        data = {
            name = contactData.name,
            number = contactData.number
        }
    })
    
    DebugLog('Contact added from share: ' .. (contactData.name or 'Unknown'))
end)

DebugLog('Contact Sharing event handlers registered')

-- Handle share request response result (from NUI callback)
RegisterNetEvent('phone:client:shareRequestResponseResult', function(result)
    if not Config.ContactSharing.enabled then
        return
    end
    
    if not result then
        DebugLog('Received invalid share request response result')
        return
    end
    
    -- Clear pending request if it matches
    if pendingRequest and result.requestId and pendingRequest.requestId == result.requestId then
        pendingRequest = nil
    end
    
    -- Forward result to NUI if needed
    if result.success then
        SendNUIMessage({
            action = 'shareRequestProcessed',
            data = result
        })
        
        -- Refresh contacts if accepted
        if result.accepted then
            TriggerServerEvent('phone:server:getContacts')
        end
    end
    
    DebugLog('Share request response result: ' .. (result.message or 'No message'))
end)

DebugLog('Contact Sharing additional event handlers registered')
