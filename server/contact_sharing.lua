-- ============================================================================
-- Server Contact Sharing Module
-- ============================================================================
-- Handles proximity-based contact sharing functionality similar to iPhone's
-- contact sharing feature. Enables players to exchange contact information
-- when they are in close proximity with their phones open.
--
-- Features:
--   - Real-time proximity detection and tracking
--   - Direct share requests between players
--   - Broadcast sharing to multiple nearby players
--   - Automatic cleanup of expired requests and broadcasts
--   - Rate limiting to prevent spam
--   - Server-side validation for security
--
-- Configuration:
--   See Config.ContactSharing in config.lua for all settings
--
-- Database:
--   Uses phone_share_requests table for request tracking
--
-- Author: FiveM Smartphone NUI
-- Version: 1.0.0
-- ============================================================================

-- State Management
-- Track players with open phones
local activePhones = {}
-- Structure: [source] = {
--     phoneNumber = string,
--     characterName = string,
--     coords = vector3,
--     lastUpdate = number (timestamp)
-- }

-- Track active broadcast shares
local broadcastShares = {}
-- Structure: [phoneNumber] = {
--     source = number,
--     characterName = string,
--     coords = vector3,
--     expiresAt = number (timestamp)
-- }

-- Track pending share requests
local pendingRequests = {}
-- Structure: [requestId] = {
--     senderSource = number,
--     senderNumber = string,
--     senderName = string,
--     receiverSource = number,
--     receiverNumber = string,
--     expiresAt = number (timestamp)
-- }

-- Debug logging helper
local function DebugLog(message)
    if Config.DebugMode then
        print('[Contact Sharing] ' .. message)
    end
end

-- Export state for testing/debugging
function GetActivePhones()
    return activePhones
end

function GetBroadcastShares()
    return broadcastShares
end

function GetPendingRequests()
    return pendingRequests
end

exports('GetActivePhones', GetActivePhones)
exports('GetBroadcastShares', GetBroadcastShares)
exports('GetPendingRequests', GetPendingRequests)

-- Proximity Detection Functions

-- Get nearby players for a given source within radius
local function GetNearbyPlayers(source, radius)
    if not activePhones[source] then
        return {}
    end
    
    local sourceCoords = activePhones[source].coords
    if not sourceCoords then
        return {}
    end
    
    local nearbyPlayers = {}
    
    for otherSource, data in pairs(activePhones) do
        if otherSource ~= source and data.coords then
            local distance = #(sourceCoords - data.coords)
            
            if distance <= radius then
                table.insert(nearbyPlayers, {
                    source = otherSource,
                    characterName = data.characterName,
                    phoneNumber = data.phoneNumber,
                    distance = math.floor(distance * 10) / 10, -- Round to 1 decimal
                    isBroadcasting = broadcastShares[data.phoneNumber] ~= nil
                })
            end
        end
    end
    
    -- Sort by distance (closest first)
    table.sort(nearbyPlayers, function(a, b)
        return a.distance < b.distance
    end)
    
    return nearbyPlayers
end

-- Broadcast nearby players to all active phones
local function BroadcastNearbyPlayers()
    if not Config.ContactSharing.enabled then
        return
    end
    
    local radius = Config.ContactSharing.proximityRadius
    
    for source, data in pairs(activePhones) do
        local nearbyPlayers = GetNearbyPlayers(source, radius)
        
        -- Send update to client
        TriggerClientEvent('phone:client:nearbyPlayersUpdate', source, nearbyPlayers)
    end
end

-- Register phone as open
local function RegisterPhoneOpen(source, phoneNumber, characterName)
    if not Config.ContactSharing.enabled then
        return
    end
    
    if not source or not phoneNumber or not characterName then
        DebugLog('RegisterPhoneOpen: Invalid parameters')
        return
    end
    
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then
        DebugLog('RegisterPhoneOpen: Invalid ped for source ' .. source)
        return
    end
    
    local coords = GetEntityCoords(ped)
    
    activePhones[source] = {
        phoneNumber = phoneNumber,
        characterName = characterName,
        coords = coords,
        lastUpdate = os.time()
    }
    
    DebugLog('Phone opened: ' .. characterName .. ' (' .. phoneNumber .. ') at source ' .. source)
    
    -- Immediately send nearby players to this player
    local nearbyPlayers = GetNearbyPlayers(source, Config.ContactSharing.proximityRadius)
    TriggerClientEvent('phone:client:nearbyPlayersUpdate', source, nearbyPlayers)
end

-- Unregister phone as closed
local function RegisterPhoneClosed(source)
    if not Config.ContactSharing.enabled then
        return
    end
    
    if activePhones[source] then
        local phoneNumber = activePhones[source].phoneNumber
        DebugLog('Phone closed: source ' .. source .. ' (' .. phoneNumber .. ')')
        
        -- Remove from active phones
        activePhones[source] = nil
        
        -- Clean up any broadcast shares for this player
        if broadcastShares[phoneNumber] then
            broadcastShares[phoneNumber] = nil
            DebugLog('Cleaned up broadcast share for ' .. phoneNumber)
        end
        
        -- Clean up any pending requests involving this player
        for requestId, request in pairs(pendingRequests) do
            if request.senderSource == source or request.receiverSource == source then
                pendingRequests[requestId] = nil
                DebugLog('Cleaned up pending request ' .. requestId)
            end
        end
    end
end

-- Update phone coordinates
local function UpdatePhoneCoords(source, coords)
    if not Config.ContactSharing.enabled then
        return
    end
    
    if activePhones[source] then
        activePhones[source].coords = coords
        activePhones[source].lastUpdate = os.time()
    end
end

-- Event Handlers

-- Phone opened event
RegisterNetEvent('phone:server:phoneOpened', function(phoneNumber, characterName)
    local source = source
    RegisterPhoneOpen(source, phoneNumber, characterName)
end)

-- Phone closed event
RegisterNetEvent('phone:server:phoneClosed', function()
    local source = source
    RegisterPhoneClosed(source)
end)

-- Coordinate update event
RegisterNetEvent('phone:server:updatePhoneCoords', function(coords)
    local source = source
    UpdatePhoneCoords(source, coords)
end)

-- Periodic broadcast thread (every 2 seconds)
CreateThread(function()
    while true do
        Wait(Config.ContactSharing.updateInterval or 2000)
        
        if Config.ContactSharing.enabled then
            BroadcastNearbyPlayers()
        end
    end
end)

-- Clean up on player disconnect
AddEventHandler('playerDropped', function()
    local source = source
    RegisterPhoneClosed(source)
end)

-- Cleanup and Maintenance Functions

-- Clean up expired data (requests and broadcasts)
-- Removes expired share requests and broadcast shares from memory
-- Notifies affected players when their requests/broadcasts expire
-- Runs automatically every 30 seconds via CreateThread
-- @return void
local function CleanupExpiredData()
    if not Config.ContactSharing.enabled then
        return
    end
    
    local currentTime = os.time()
    local expiredCount = 0
    
    -- Clean up expired pending requests
    for requestId, request in pairs(pendingRequests) do
        if currentTime >= request.expiresAt then
            -- Notify both players that request expired
            if request.senderSource and GetPlayerPed(request.senderSource) ~= 0 then
                TriggerClientEvent('phone:client:shareRequestResponse', request.senderSource, {
                    success = false,
                    error = ERROR_CODES.SHARE_REQUEST_EXPIRED,
                    message = ERROR_MESSAGES[ERROR_CODES.SHARE_REQUEST_EXPIRED]
                })
            end
            
            if request.receiverSource and GetPlayerPed(request.receiverSource) ~= 0 then
                TriggerClientEvent('phone:client:shareRequestExpired', request.receiverSource, requestId)
            end
            
            pendingRequests[requestId] = nil
            expiredCount = expiredCount + 1
            DebugLog('Expired request cleaned up: ' .. requestId)
        end
    end
    
    -- Clean up expired broadcast shares
    for phoneNumber, broadcast in pairs(broadcastShares) do
        if currentTime >= broadcast.expiresAt then
            -- Notify the broadcaster
            if broadcast.source and GetPlayerPed(broadcast.source) ~= 0 then
                TriggerClientEvent('phone:client:broadcastShareStopped', broadcast.source, {
                    reason = 'expired'
                })
            end
            
            -- Notify nearby players
            local nearbyPlayers = GetNearbyPlayers(broadcast.source, Config.ContactSharing.proximityRadius)
            for _, player in ipairs(nearbyPlayers) do
                TriggerClientEvent('phone:client:broadcastShareStopped', player.source, {
                    phoneNumber = phoneNumber,
                    reason = 'expired'
                })
            end
            
            broadcastShares[phoneNumber] = nil
            expiredCount = expiredCount + 1
            DebugLog('Expired broadcast cleaned up: ' .. phoneNumber)
        end
    end
    
    -- Clean up stale active phones (no update in 30 seconds)
    local staleThreshold = currentTime - 30
    for source, data in pairs(activePhones) do
        if data.lastUpdate < staleThreshold then
            DebugLog('Cleaning up stale phone: source ' .. source)
            RegisterPhoneClosed(source)
        end
    end
    
    if expiredCount > 0 then
        DebugLog('Cleanup completed: ' .. expiredCount .. ' expired items removed')
    end
end

-- Clean up orphaned requests from database
-- Removes old share requests from the database to prevent bloat
-- Deletes pending requests older than 1 hour
-- Deletes completed/declined requests older than 24 hours
-- Runs automatically every 5 minutes via CreateThread
-- @return void
local function CleanupOrphanedRequests()
    if not Config.ContactSharing.enabled then
        return
    end
    
    -- Clean up old pending requests from database (older than 1 hour)
    local query = [[
        DELETE FROM phone_share_requests 
        WHERE status = 'pending' 
        AND created_at < DATE_SUB(NOW(), INTERVAL 1 HOUR)
    ]]
    
    MySQL.query(query, {}, function(affectedRows)
        if affectedRows and affectedRows > 0 then
            DebugLog('Cleaned up ' .. affectedRows .. ' orphaned database requests')
        end
    end)
    
    -- Clean up old completed/declined requests (older than 24 hours)
    local cleanupQuery = [[
        DELETE FROM phone_share_requests 
        WHERE status IN ('accepted', 'declined', 'expired')
        AND responded_at < DATE_SUB(NOW(), INTERVAL 24 HOUR)
    ]]
    
    MySQL.query(cleanupQuery, {}, function(affectedRows)
        if affectedRows and affectedRows > 0 then
            DebugLog('Cleaned up ' .. affectedRows .. ' old completed requests')
        end
    end)
end

-- Periodic cleanup thread (every 30 seconds)
CreateThread(function()
    while true do
        Wait(30000) -- 30 seconds
        
        if Config.ContactSharing.enabled then
            CleanupExpiredData()
        end
    end
end)

-- Periodic database cleanup thread (every 5 minutes)
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        
        if Config.ContactSharing.enabled then
            CleanupOrphanedRequests()
        end
    end
end)

-- Export cleanup functions for manual triggering
exports('CleanupExpiredData', CleanupExpiredData)
exports('CleanupOrphanedRequests', CleanupOrphanedRequests)

-- Share Request Validation and Processing Functions

-- Validate proximity between two players
-- Checks if both players have phones open and are within the specified distance
-- @param source1 number - First player's server ID
-- @param source2 number - Second player's server ID
-- @param maxDistance number - Maximum allowed distance in meters
-- @return boolean success - Whether validation passed
-- @return string|nil errorCode - Error code if validation failed
-- @return string|nil errorMessage - Error message if validation failed
local function ValidateProximity(source1, source2, maxDistance)
    -- Verify both players have phones open
    if not activePhones[source1] or not activePhones[source2] then
        return false, ERROR_CODES.PHONE_NOT_OPEN, 'Both players must have their phones open'
    end
    
    -- Get player coordinates
    local coords1 = activePhones[source1].coords
    local coords2 = activePhones[source2].coords
    
    -- Verify coordinates are available
    if not coords1 or not coords2 then
        return false, ERROR_CODES.PLAYER_NOT_FOUND, 'Unable to determine player locations'
    end
    
    -- Calculate distance between players
    local distance = #(coords1 - coords2)
    
    -- Check if distance exceeds maximum
    if distance > maxDistance then
        return false, ERROR_CODES.PLAYER_TOO_FAR, 
               string.format('Player is %.1fm away (max: %.1fm)', distance, maxDistance)
    end
    
    return true, nil, nil
end

-- Check if contact already exists
local function ContactExists(ownerNumber, contactNumber)
    local promise = promise.new()
    
    local query = 'SELECT id FROM phone_contacts WHERE owner_number = ? AND contact_number = ?'
    MySQL.query(query, {ownerNumber, contactNumber}, function(result)
        if result and #result > 0 then
            promise:resolve(true)
        else
            promise:resolve(false)
        end
    end)
    
    return Citizen.Await(promise)
end

-- Validate share request
local function ValidateShareRequest(senderSource, receiverSource)
    -- Check if both players have phones open
    if not activePhones[senderSource] then
        return false, ERROR_CODES.PHONE_NOT_OPEN, 'Your phone must be open'
    end
    
    if not activePhones[receiverSource] then
        return false, ERROR_CODES.PHONE_NOT_OPEN, 'Target player does not have phone open'
    end
    
    local senderNumber = activePhones[senderSource].phoneNumber
    local receiverNumber = activePhones[receiverSource].phoneNumber
    
    -- Check if trying to share with self
    if senderNumber == receiverNumber then
        return false, ERROR_CODES.CANNOT_SHARE_WITH_SELF, 'Cannot share contact with yourself'
    end
    
    -- Check proximity
    local proximityOk, proximityError, proximityMsg = 
        ValidateProximity(senderSource, receiverSource, Config.ContactSharing.proximityRadius)
    
    if not proximityOk then
        return false, proximityError, proximityMsg
    end
    
    -- Check if contact already exists
    if ContactExists(senderNumber, receiverNumber) then
        return false, ERROR_CODES.CONTACT_ALREADY_EXISTS, 'Contact already exists'
    end
    
    -- Check rate limit
    local rateLimitOk, rateLimitError = CheckContactShareRateLimit(senderSource)
    if not rateLimitOk then
        return false, rateLimitError, ERROR_MESSAGES[rateLimitError]
    end
    
    return true, nil, nil
end

-- Generate unique request ID
local function GenerateRequestId()
    return string.format('%s-%s-%s', 
        os.time(), 
        math.random(1000, 9999),
        math.random(1000, 9999)
    )
end

-- Send share request from one player to another
local function SendShareRequest(senderSource, receiverSource)
    -- Validate the request
    local isValid, errorCode, errorMsg = ValidateShareRequest(senderSource, receiverSource)
    
    if not isValid then
        DebugLog('Share request validation failed: ' .. errorMsg)
        TriggerClientEvent('phone:client:shareRequestResponse', senderSource, {
            success = false,
            error = errorCode,
            message = errorMsg
        })
        return
    end
    
    local senderData = activePhones[senderSource]
    local receiverData = activePhones[receiverSource]
    
    -- Generate request ID
    local requestId = GenerateRequestId()
    
    -- Calculate expiration time
    local expiresAt = os.time() + Config.ContactSharing.requestTimeout
    
    -- Store pending request
    pendingRequests[requestId] = {
        senderSource = senderSource,
        senderNumber = senderData.phoneNumber,
        senderName = senderData.characterName,
        receiverSource = receiverSource,
        receiverNumber = receiverData.phoneNumber,
        receiverName = receiverData.characterName,
        expiresAt = expiresAt
    }
    
    DebugLog('Share request created: ' .. requestId .. ' from ' .. senderData.characterName .. ' to ' .. receiverData.characterName)
    
    -- Insert into database
    local insertQuery = [[
        INSERT INTO phone_share_requests 
        (id, sender_number, sender_name, receiver_number, receiver_name, status, expires_at)
        VALUES (?, ?, ?, ?, ?, 'pending', FROM_UNIXTIME(?))
    ]]
    
    MySQL.query(insertQuery, {
        requestId,
        senderData.phoneNumber,
        senderData.characterName,
        receiverData.phoneNumber,
        receiverData.characterName,
        expiresAt
    }, function(result)
        if not result then
            DebugLog('Failed to insert share request into database')
            pendingRequests[requestId] = nil
            TriggerClientEvent('phone:client:shareRequestResponse', senderSource, {
                success = false,
                error = ERROR_CODES.DATABASE_ERROR,
                message = 'Failed to create share request'
            })
            return
        end
        
        -- Send notification to receiver
        TriggerClientEvent('phone:client:shareRequestReceived', receiverSource, {
            requestId = requestId,
            senderName = senderData.characterName,
            senderNumber = senderData.phoneNumber,
            expiresAt = expiresAt
        })
        
        -- Send confirmation to sender
        TriggerClientEvent('phone:client:shareRequestResponse', senderSource, {
            success = true,
            message = 'Contact request sent to ' .. receiverData.characterName
        })
        
        DebugLog('Share request sent successfully: ' .. requestId)
    end)
end

-- Share Request Response Handling

-- Add contact with retry logic
local function AddContactWithRetry(ownerNumber, contactName, contactNumber, retryCount, callback)
    retryCount = retryCount or 0
    
    if retryCount >= 3 then
        DebugLog('Max retries exceeded for adding contact')
        callback(false, 'Failed to add contact after multiple attempts')
        return
    end
    
    -- Use the Contacts module to add contact
    local Contacts = exports['phone-system']:GetContactsModule()
    if not Contacts then
        -- Fallback to direct database insert
        local insertQuery = [[
            INSERT INTO phone_contacts (owner_number, contact_name, contact_number)
            VALUES (?, ?, ?)
        ]]
        
        MySQL.query(insertQuery, {ownerNumber, contactName, contactNumber}, function(result)
            if result then
                callback(true, nil)
            else
                -- Retry with exponential backoff
                Wait(1000 * (retryCount + 1))
                AddContactWithRetry(ownerNumber, contactName, contactNumber, retryCount + 1, callback)
            end
        end)
    else
        Contacts.AddContact(ownerNumber, contactName, contactNumber, function(success, error, contact)
            if success then
                callback(true, nil)
            else
                -- Retry with exponential backoff
                Wait(1000 * (retryCount + 1))
                AddContactWithRetry(ownerNumber, contactName, contactNumber, retryCount + 1, callback)
            end
        end)
    end
end

-- Process share request response (accept or decline)
-- Handles the receiver's response to a contact share request
-- If accepted: Adds both players to each other's contacts (bidirectional)
-- If declined: Notifies sender and cleans up request
-- @param requestId string - Unique request identifier
-- @param accepted boolean - Whether the request was accepted
-- @return boolean success - Whether processing succeeded
-- @return string|nil errorCode - Error code if processing failed
-- @return string|nil errorMessage - Error message if processing failed
local function ProcessShareResponse(requestId, accepted)
    -- Retrieve request data from pending requests
    local request = pendingRequests[requestId]
    
    if not request then
        DebugLog('Share request not found: ' .. requestId)
        return false, ERROR_CODES.SHARE_REQUEST_NOT_FOUND, 'Share request not found or expired'
    end
    
    -- Verify request hasn't expired
    if os.time() >= request.expiresAt then
        DebugLog('Share request expired: ' .. requestId)
        pendingRequests[requestId] = nil
        return false, ERROR_CODES.SHARE_REQUEST_EXPIRED, 'Share request has expired'
    end
    
    local senderSource = request.senderSource
    local receiverSource = request.receiverSource
    local senderNumber = request.senderNumber
    local senderName = request.senderName
    local receiverNumber = request.receiverNumber
    local receiverName = request.receiverName
    
    if accepted then
        DebugLog('Processing accepted share request: ' .. requestId)
        
        -- Add both players to each other's contacts
        local senderContactAdded = false
        local receiverContactAdded = false
        local additionErrors = {}
        
        -- Add receiver to sender's contacts
        AddContactWithRetry(senderNumber, receiverName, receiverNumber, 0, function(success, error)
            senderContactAdded = success
            if not success then
                table.insert(additionErrors, 'Failed to add contact for sender: ' .. (error or 'unknown error'))
            end
        end)
        
        -- Add sender to receiver's contacts
        AddContactWithRetry(receiverNumber, senderName, senderNumber, 0, function(success, error)
            receiverContactAdded = success
            if not success then
                table.insert(additionErrors, 'Failed to add contact for receiver: ' .. (error or 'unknown error'))
            end
        end)
        
        -- Wait for both operations to complete
        local timeout = 0
        while (not senderContactAdded or not receiverContactAdded) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        
        if senderContactAdded and receiverContactAdded then
            -- Update database status
            local updateQuery = [[
                UPDATE phone_share_requests 
                SET status = 'accepted', responded_at = NOW()
                WHERE id = ?
            ]]
            
            MySQL.query(updateQuery, {requestId}, function(result)
                DebugLog('Share request accepted and contacts added: ' .. requestId)
            end)
            
            -- Notify sender of success
            if GetPlayerPed(senderSource) ~= 0 then
                TriggerClientEvent('phone:client:shareRequestResponse', senderSource, {
                    success = true,
                    accepted = true,
                    contactName = receiverName,
                    contactNumber = receiverNumber,
                    message = receiverName .. ' accepted your contact request'
                })
                
                TriggerClientEvent('phone:client:contactAdded', senderSource, {
                    name = receiverName,
                    number = receiverNumber
                })
            end
            
            -- Notify receiver of success
            if GetPlayerPed(receiverSource) ~= 0 then
                TriggerClientEvent('phone:client:shareRequestResponse', receiverSource, {
                    success = true,
                    accepted = true,
                    contactName = senderName,
                    contactNumber = senderNumber,
                    message = 'Contact added: ' .. senderName
                })
                
                TriggerClientEvent('phone:client:contactAdded', receiverSource, {
                    name = senderName,
                    number = senderNumber
                })
            end
            
            -- Clean up pending request
            pendingRequests[requestId] = nil
            
            return true, nil, nil
        else
            -- Partial or complete failure
            local errorMsg = 'Failed to add contacts: ' .. table.concat(additionErrors, ', ')
            DebugLog(errorMsg)
            
            -- Update database status
            local updateQuery = [[
                UPDATE phone_share_requests 
                SET status = 'expired', responded_at = NOW()
                WHERE id = ?
            ]]
            
            MySQL.query(updateQuery, {requestId}, function(result) end)
            
            -- Notify both players of failure
            if GetPlayerPed(senderSource) ~= 0 then
                TriggerClientEvent('phone:client:shareRequestResponse', senderSource, {
                    success = false,
                    error = ERROR_CODES.OPERATION_FAILED,
                    message = 'Failed to complete contact exchange'
                })
            end
            
            if GetPlayerPed(receiverSource) ~= 0 then
                TriggerClientEvent('phone:client:shareRequestResponse', receiverSource, {
                    success = false,
                    error = ERROR_CODES.OPERATION_FAILED,
                    message = 'Failed to complete contact exchange'
                })
            end
            
            -- Clean up pending request
            pendingRequests[requestId] = nil
            
            return false, ERROR_CODES.OPERATION_FAILED, errorMsg
        end
    else
        DebugLog('Processing declined share request: ' .. requestId)
        
        -- Update database status
        local updateQuery = [[
            UPDATE phone_share_requests 
            SET status = 'declined', responded_at = NOW()
            WHERE id = ?
        ]]
        
        MySQL.query(updateQuery, {requestId}, function(result)
            DebugLog('Share request declined: ' .. requestId)
        end)
        
        -- Notify sender of decline
        if GetPlayerPed(senderSource) ~= 0 then
            TriggerClientEvent('phone:client:shareRequestResponse', senderSource, {
                success = false,
                declined = true,
                message = receiverName .. ' declined your contact request'
            })
        end
        
        -- Notify receiver that decline was processed
        if GetPlayerPed(receiverSource) ~= 0 then
            TriggerClientEvent('phone:client:shareRequestResponse', receiverSource, {
                success = true,
                declined = true,
                message = 'Contact request declined'
            })
        end
        
        -- Clean up pending request
        pendingRequests[requestId] = nil
        
        return true, nil, nil
    end
end

-- Server Event Handlers for Share Requests

-- Send share request event
RegisterNetEvent('phone:server:sendShareRequest', function(targetSource)
    local source = source
    
    -- Validate input
    if not targetSource or type(targetSource) ~= 'number' then
        DebugLog('Invalid target source for share request from source ' .. source)
        TriggerClientEvent('phone:client:shareRequestResponse', source, {
            success = false,
            error = ERROR_CODES.INVALID_INPUT,
            message = 'Invalid target player'
        })
        return
    end
    
    -- Check if target player exists
    if GetPlayerPed(targetSource) == 0 then
        DebugLog('Target player not found: ' .. targetSource)
        TriggerClientEvent('phone:client:shareRequestResponse', source, {
            success = false,
            error = ERROR_CODES.PLAYER_NOT_FOUND,
            message = 'Target player not found'
        })
        return
    end
    
    -- Wrap in try-catch for error handling
    TryCatch(function()
        SendShareRequest(source, targetSource)
    end, function(err)
        DebugLog('Error sending share request: ' .. tostring(err))
        TriggerClientEvent('phone:client:shareRequestResponse', source, {
            success = false,
            error = ERROR_CODES.OPERATION_FAILED,
            message = 'Failed to send share request'
        })
    end)
end)

-- Respond to share request event
RegisterNetEvent('phone:server:respondToShareRequest', function(requestId, accepted)
    local source = source
    
    -- Validate input
    if not requestId or type(requestId) ~= 'string' then
        DebugLog('Invalid request ID for share response from source ' .. source)
        TriggerClientEvent('phone:client:shareRequestResponse', source, {
            success = false,
            error = ERROR_CODES.INVALID_INPUT,
            message = 'Invalid request ID'
        })
        return
    end
    
    if type(accepted) ~= 'boolean' then
        DebugLog('Invalid accepted value for share response from source ' .. source)
        TriggerClientEvent('phone:client:shareRequestResponse', source, {
            success = false,
            error = ERROR_CODES.INVALID_INPUT,
            message = 'Invalid response value'
        })
        return
    end
    
    -- Get request data
    local request = pendingRequests[requestId]
    
    if not request then
        DebugLog('Share request not found: ' .. requestId)
        TriggerClientEvent('phone:client:shareRequestResponse', source, {
            success = false,
            error = ERROR_CODES.SHARE_REQUEST_NOT_FOUND,
            message = 'Share request not found or expired'
        })
        return
    end
    
    -- Verify that the source is the receiver
    if request.receiverSource ~= source then
        DebugLog('Unauthorized share response attempt from source ' .. source .. ' for request ' .. requestId)
        TriggerClientEvent('phone:client:shareRequestResponse', source, {
            success = false,
            error = ERROR_CODES.UNAUTHORIZED,
            message = 'You are not authorized to respond to this request'
        })
        return
    end
    
    -- Wrap in try-catch for error handling
    TryCatch(function()
        local success, errorCode, errorMsg = ProcessShareResponse(requestId, accepted)
        
        if not success then
            DebugLog('Failed to process share response: ' .. (errorMsg or 'unknown error'))
            TriggerClientEvent('phone:client:shareRequestResponse', source, {
                success = false,
                error = errorCode,
                message = errorMsg
            })
        end
    end, function(err)
        DebugLog('Error processing share response: ' .. tostring(err))
        TriggerClientEvent('phone:client:shareRequestResponse', source, {
            success = false,
            error = ERROR_CODES.OPERATION_FAILED,
            message = 'Failed to process share response'
        })
    end)
end)

-- Broadcast Share Management Functions

-- Start broadcast share
local function StartBroadcastShare(source, phoneNumber)
    if not Config.ContactSharing.enabled or not Config.ContactSharing.enableBroadcastShare then
        DebugLog('Broadcast share is disabled')
        TriggerClientEvent('phone:client:broadcastShareResponse', source, {
            success = false,
            error = ERROR_CODES.OPERATION_FAILED,
            message = 'Broadcast sharing is not enabled'
        })
        return
    end
    
    -- Validate player has phone open
    if not activePhones[source] then
        DebugLog('Player does not have phone open: source ' .. source)
        TriggerClientEvent('phone:client:broadcastShareResponse', source, {
            success = false,
            error = ERROR_CODES.PHONE_NOT_OPEN,
            message = 'Your phone must be open'
        })
        return
    end
    
    local playerData = activePhones[source]
    
    -- Verify phone number matches
    if playerData.phoneNumber ~= phoneNumber then
        DebugLog('Phone number mismatch for source ' .. source)
        TriggerClientEvent('phone:client:broadcastShareResponse', source, {
            success = false,
            error = ERROR_CODES.UNAUTHORIZED,
            message = 'Phone number mismatch'
        })
        return
    end
    
    -- Check if already broadcasting
    if broadcastShares[phoneNumber] then
        DebugLog('Already broadcasting: ' .. phoneNumber)
        TriggerClientEvent('phone:client:broadcastShareResponse', source, {
            success = false,
            error = ERROR_CODES.OPERATION_FAILED,
            message = 'Already broadcasting contact'
        })
        return
    end
    
    -- Calculate expiration time
    local expiresAt = os.time() + Config.ContactSharing.broadcastDuration
    
    -- Add to broadcast shares
    broadcastShares[phoneNumber] = {
        source = source,
        characterName = playerData.characterName,
        coords = playerData.coords,
        expiresAt = expiresAt
    }
    
    DebugLog('Broadcast share started: ' .. phoneNumber .. ' (' .. playerData.characterName .. ')')
    
    -- Notify the broadcaster
    TriggerClientEvent('phone:client:broadcastShareStarted', source, {
        success = true,
        phoneNumber = phoneNumber,
        expiresAt = expiresAt,
        duration = Config.ContactSharing.broadcastDuration
    })
    
    -- Notify nearby players
    local nearbyPlayers = GetNearbyPlayers(source, Config.ContactSharing.proximityRadius)
    for _, player in ipairs(nearbyPlayers) do
        TriggerClientEvent('phone:client:broadcastShareStarted', player.source, {
            phoneNumber = phoneNumber,
            characterName = playerData.characterName,
            expiresAt = expiresAt,
            isBroadcasting = true
        })
    end
    
    DebugLog('Notified ' .. #nearbyPlayers .. ' nearby players of broadcast')
end

-- Stop broadcast share
local function StopBroadcastShare(source, phoneNumber)
    if not Config.ContactSharing.enabled then
        return
    end
    
    -- Check if broadcast exists
    if not broadcastShares[phoneNumber] then
        DebugLog('No active broadcast for: ' .. phoneNumber)
        TriggerClientEvent('phone:client:broadcastShareResponse', source, {
            success = false,
            error = ERROR_CODES.BROADCAST_NOT_ACTIVE,
            message = 'No active broadcast found'
        })
        return
    end
    
    local broadcast = broadcastShares[phoneNumber]
    
    -- Verify the source owns this broadcast
    if broadcast.source ~= source then
        DebugLog('Unauthorized stop broadcast attempt from source ' .. source)
        TriggerClientEvent('phone:client:broadcastShareResponse', source, {
            success = false,
            error = ERROR_CODES.UNAUTHORIZED,
            message = 'You do not own this broadcast'
        })
        return
    end
    
    DebugLog('Broadcast share stopped: ' .. phoneNumber)
    
    -- Notify the broadcaster
    TriggerClientEvent('phone:client:broadcastShareStopped', source, {
        success = true,
        phoneNumber = phoneNumber,
        reason = 'manual'
    })
    
    -- Notify nearby players
    local nearbyPlayers = GetNearbyPlayers(source, Config.ContactSharing.proximityRadius)
    for _, player in ipairs(nearbyPlayers) do
        TriggerClientEvent('phone:client:broadcastShareStopped', player.source, {
            phoneNumber = phoneNumber,
            reason = 'manual'
        })
    end
    
    -- Remove from broadcast shares
    broadcastShares[phoneNumber] = nil
    
    DebugLog('Notified ' .. #nearbyPlayers .. ' nearby players of broadcast stop')
end

-- Add contact from broadcast
local function AddFromBroadcast(receiverSource, broadcasterNumber)
    if not Config.ContactSharing.enabled or not Config.ContactSharing.enableBroadcastShare then
        DebugLog('Broadcast share is disabled')
        TriggerClientEvent('phone:client:addFromBroadcastResponse', receiverSource, {
            success = false,
            error = ERROR_CODES.OPERATION_FAILED,
            message = 'Broadcast sharing is not enabled'
        })
        return
    end
    
    -- Validate receiver has phone open
    if not activePhones[receiverSource] then
        DebugLog('Receiver does not have phone open: source ' .. receiverSource)
        TriggerClientEvent('phone:client:addFromBroadcastResponse', receiverSource, {
            success = false,
            error = ERROR_CODES.PHONE_NOT_OPEN,
            message = 'Your phone must be open'
        })
        return
    end
    
    -- Check if broadcast is active
    if not broadcastShares[broadcasterNumber] then
        DebugLog('Broadcast not active: ' .. broadcasterNumber)
        TriggerClientEvent('phone:client:addFromBroadcastResponse', receiverSource, {
            success = false,
            error = ERROR_CODES.BROADCAST_NOT_ACTIVE,
            message = 'Contact broadcast is no longer active'
        })
        return
    end
    
    local broadcast = broadcastShares[broadcasterNumber]
    local broadcasterSource = broadcast.source
    
    -- Check if broadcast has expired
    if os.time() >= broadcast.expiresAt then
        DebugLog('Broadcast expired: ' .. broadcasterNumber)
        broadcastShares[broadcasterNumber] = nil
        TriggerClientEvent('phone:client:addFromBroadcastResponse', receiverSource, {
            success = false,
            error = ERROR_CODES.BROADCAST_NOT_ACTIVE,
            message = 'Contact broadcast has expired'
        })
        return
    end
    
    -- Validate proximity
    local proximityOk, proximityError, proximityMsg = 
        ValidateProximity(receiverSource, broadcasterSource, Config.ContactSharing.proximityRadius)
    
    if not proximityOk then
        DebugLog('Proximity validation failed: ' .. proximityMsg)
        TriggerClientEvent('phone:client:addFromBroadcastResponse', receiverSource, {
            success = false,
            error = proximityError,
            message = proximityMsg
        })
        return
    end
    
    local receiverData = activePhones[receiverSource]
    local receiverNumber = receiverData.phoneNumber
    
    -- Check if trying to add self
    if receiverNumber == broadcasterNumber then
        DebugLog('Cannot add own contact from broadcast')
        TriggerClientEvent('phone:client:addFromBroadcastResponse', receiverSource, {
            success = false,
            error = ERROR_CODES.CANNOT_SHARE_WITH_SELF,
            message = 'Cannot add your own contact'
        })
        return
    end
    
    -- Check if contact already exists
    if ContactExists(receiverNumber, broadcasterNumber) then
        DebugLog('Contact already exists: ' .. broadcasterNumber)
        TriggerClientEvent('phone:client:addFromBroadcastResponse', receiverSource, {
            success = false,
            error = ERROR_CODES.CONTACT_ALREADY_EXISTS,
            message = 'Contact already exists'
        })
        return
    end
    
    DebugLog('Adding contact from broadcast: ' .. broadcast.characterName .. ' to ' .. receiverData.characterName)
    
    -- Add contact
    AddContactWithRetry(receiverNumber, broadcast.characterName, broadcasterNumber, 0, function(success, error)
        if success then
            DebugLog('Contact added from broadcast successfully')
            
            -- Notify receiver of success
            TriggerClientEvent('phone:client:addFromBroadcastResponse', receiverSource, {
                success = true,
                contactName = broadcast.characterName,
                contactNumber = broadcasterNumber,
                message = 'Contact added: ' .. broadcast.characterName
            })
            
            TriggerClientEvent('phone:client:contactAdded', receiverSource, {
                name = broadcast.characterName,
                number = broadcasterNumber
            })
            
            -- Notify broadcaster
            if GetPlayerPed(broadcasterSource) ~= 0 then
                TriggerClientEvent('phone:client:broadcastContactAdded', broadcasterSource, {
                    addedBy = receiverData.characterName,
                    addedByNumber = receiverNumber
                })
            end
        else
            DebugLog('Failed to add contact from broadcast: ' .. (error or 'unknown error'))
            TriggerClientEvent('phone:client:addFromBroadcastResponse', receiverSource, {
                success = false,
                error = ERROR_CODES.OPERATION_FAILED,
                message = 'Failed to add contact: ' .. (error or 'unknown error')
            })
        end
    end)
end

-- Server Event Handlers for Broadcast Share

-- Start broadcast share event
RegisterNetEvent('phone:server:startBroadcastShare', function(phoneNumber)
    local source = source
    
    -- Validate input
    if not phoneNumber or type(phoneNumber) ~= 'string' then
        DebugLog('Invalid phone number for broadcast share from source ' .. source)
        TriggerClientEvent('phone:client:broadcastShareResponse', source, {
            success = false,
            error = ERROR_CODES.INVALID_INPUT,
            message = 'Invalid phone number'
        })
        return
    end
    
    -- Wrap in try-catch for error handling
    TryCatch(function()
        StartBroadcastShare(source, phoneNumber)
    end, function(err)
        DebugLog('Error starting broadcast share: ' .. tostring(err))
        TriggerClientEvent('phone:client:broadcastShareResponse', source, {
            success = false,
            error = ERROR_CODES.OPERATION_FAILED,
            message = 'Failed to start broadcast share'
        })
    end)
end)

-- Stop broadcast share event
RegisterNetEvent('phone:server:stopBroadcastShare', function(phoneNumber)
    local source = source
    
    -- Validate input
    if not phoneNumber or type(phoneNumber) ~= 'string' then
        DebugLog('Invalid phone number for stop broadcast from source ' .. source)
        TriggerClientEvent('phone:client:broadcastShareResponse', source, {
            success = false,
            error = ERROR_CODES.INVALID_INPUT,
            message = 'Invalid phone number'
        })
        return
    end
    
    -- Wrap in try-catch for error handling
    TryCatch(function()
        StopBroadcastShare(source, phoneNumber)
    end, function(err)
        DebugLog('Error stopping broadcast share: ' .. tostring(err))
        TriggerClientEvent('phone:client:broadcastShareResponse', source, {
            success = false,
            error = ERROR_CODES.OPERATION_FAILED,
            message = 'Failed to stop broadcast share'
        })
    end)
end)

-- Add contact from broadcast event
RegisterNetEvent('phone:server:addFromBroadcast', function(broadcasterNumber)
    local source = source
    
    -- Validate input
    if not broadcasterNumber or type(broadcasterNumber) ~= 'string' then
        DebugLog('Invalid broadcaster number for add from broadcast from source ' .. source)
        TriggerClientEvent('phone:client:addFromBroadcastResponse', source, {
            success = false,
            error = ERROR_CODES.INVALID_INPUT,
            message = 'Invalid broadcaster number'
        })
        return
    end
    
    -- Wrap in try-catch for error handling
    TryCatch(function()
        AddFromBroadcast(source, broadcasterNumber)
    end, function(err)
        DebugLog('Error adding from broadcast: ' .. tostring(err))
        TriggerClientEvent('phone:client:addFromBroadcastResponse', source, {
            success = false,
            error = ERROR_CODES.OPERATION_FAILED,
            message = 'Failed to add contact from broadcast'
        })
    end)
end)

DebugLog('Contact Sharing module initialized')
