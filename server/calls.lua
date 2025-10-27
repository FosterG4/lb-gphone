-- Server Call Management
-- Handles call coordination between players

local activeCalls = {} -- Store active calls
local callChannelCounter = 1000 -- Counter for unique channel IDs

-- Get player source by phone number
local function GetPlayerByPhoneNumber(phoneNumber)
    for _, playerId in ipairs(GetPlayers()) do
        local playerPhone = GetCachedPhoneNumber(tonumber(playerId))
        if playerPhone == phoneNumber then
            return tonumber(playerId)
        end
    end
    return nil
end

-- Generate unique call channel ID
local function GenerateChannelId()
    callChannelCounter = callChannelCounter + 1
    return Config.CallChannelPrefix .. callChannelCounter
end

-- Check if player is in a call
local function IsPlayerInCall(source)
    for _, call in pairs(activeCalls) do
        if call.caller == source or call.receiver == source then
            return true
        end
    end
    return false
end

-- Get player's active call
local function GetPlayerCall(source)
    for callId, call in pairs(activeCalls) do
        if call.caller == source or call.receiver == source then
            return callId, call
        end
    end
    return nil, nil
end

-- Initiate call
RegisterNetEvent('phone:server:initiateCall', function(data)
    local src = source
    
    -- Check rate limit
    local rateLimitOk, rateLimitError = CheckCallRateLimit(src)
    if not rateLimitOk then
        TriggerClientEvent('phone:client:callInitiated', src, ErrorResponse(rateLimitError))
        return
    end
    
    if not data or not data.targetNumber then
        TriggerClientEvent('phone:client:callInitiated', src, ErrorResponse(ERROR_CODES.INVALID_INPUT, 'Target number is required'))
        return
    end
    
    local targetNumber = SanitizeInput(data.targetNumber)
    
    -- Validate phone number
    local phoneValid, phoneError, phoneMsg = ValidatePhoneNumber(targetNumber)
    if not phoneValid then
        TriggerClientEvent('phone:client:callInitiated', src, ErrorResponse(phoneError, phoneMsg))
        return
    end
    
    -- Check if caller is already in a call
    if IsPlayerInCall(src) then
        TriggerClientEvent('phone:client:callInitiated', src, ErrorResponse(ERROR_CODES.ALREADY_IN_CALL))
        return
    end
    
    -- Get caller phone number
    local callerNumber = GetCachedPhoneNumber(src)
    if not callerNumber then
        TriggerClientEvent('phone:client:callInitiated', src, ErrorResponse(ERROR_CODES.PLAYER_NOT_FOUND))
        return
    end
    
    -- Verify can call
    local canCall, callError, callMsg = VerifyCanCall(src, targetNumber)
    if not canCall then
        TriggerClientEvent('phone:client:callInitiated', src, ErrorResponse(callError, callMsg))
        return
    end
    
    -- Find receiver
    local receiverId = GetPlayerByPhoneNumber(targetNumber)
    
    if not receiverId then
        TriggerClientEvent('phone:client:callInitiated', src, ErrorResponse(ERROR_CODES.PLAYER_OFFLINE, 'Player is not available'))
        return
    end
    
    -- Check if receiver is in a call
    if IsPlayerInCall(receiverId) then
        TriggerClientEvent('phone:client:callBusy', src)
        TriggerClientEvent('phone:client:callInitiated', src, ErrorResponse(ERROR_CODES.PLAYER_BUSY))
        return
    end
    
    -- Create call with error handling
    TryCatch(function()
        local channelId = GenerateChannelId()
        local callId = src .. '_' .. receiverId .. '_' .. os.time()
        
        activeCalls[callId] = {
            id = callId,
            caller = src,
            receiver = receiverId,
            callerNumber = callerNumber,
            receiverNumber = targetNumber,
            channelId = channelId,
            startTime = os.time(),
            state = 'ringing'
        }
        
        -- Notify caller
        TriggerClientEvent('phone:client:callInitiated', src, SuccessResponse({
            callId = callId,
            targetNumber = targetNumber
        }))
        
        -- Notify receiver
        TriggerClientEvent('phone:client:incomingCall', receiverId, {
            callerId = src,
            callerNumber = callerNumber,
            callerName = callerNumber, -- TODO: Get contact name if exists
            callId = callId
        })
    end, function(err)
        TriggerClientEvent('phone:client:callInitiated', src, ErrorResponse(ERROR_CODES.OPERATION_FAILED, 'Failed to initiate call'))
    end)
    
    -- Set timeout for call
    SetTimeout(Config.CallTimeout, function()
        if activeCalls[callId] and activeCalls[callId].state == 'ringing' then
            -- Call timed out
            TriggerClientEvent('phone:client:callTimeout', src)
            TriggerClientEvent('phone:client:callEnded', receiverId, 'timeout')
            activeCalls[callId] = nil
            
            if Config.DebugMode then
                print('[Phone] Call timed out: ' .. callId)
            end
        end
    end)
    
    if Config.DebugMode then
        print('[Phone] Call initiated: ' .. callerNumber .. ' -> ' .. targetNumber)
    end
end)

-- Accept call
RegisterNetEvent('phone:server:acceptCall', function(data)
    local src = source
    local callerId = data.callerId
    
    -- Find the call
    local callId, call = GetPlayerCall(src)
    
    if not call then
        if Config.DebugMode then
            print('[Phone] No call found for player: ' .. src)
        end
        return
    end
    
    if call.receiver ~= src then
        if Config.DebugMode then
            print('[Phone] Player is not the receiver: ' .. src)
        end
        return
    end
    
    -- Update call state
    call.state = 'active'
    call.acceptTime = os.time()
    
    -- Notify both parties
    TriggerClientEvent('phone:client:callAccepted', call.caller, {
        channelId = call.channelId,
        receiverNumber = call.receiverNumber
    })
    
    TriggerClientEvent('phone:client:callAccepted', call.receiver, {
        channelId = call.channelId,
        callerNumber = call.callerNumber
    })
    
    if Config.DebugMode then
        print('[Phone] Call accepted: ' .. callId)
    end
end)

-- End call
RegisterNetEvent('phone:server:endCall', function(data)
    local src = source
    
    -- Find the call
    local callId, call = GetPlayerCall(src)
    
    if not call then
        if Config.DebugMode then
            print('[Phone] No call found for player: ' .. src)
        end
        return
    end
    
    -- Calculate duration
    local duration = 0
    if call.acceptTime then
        duration = os.time() - call.acceptTime
    end
    
    -- Log call to database
    local callType = 'missed'
    if call.state == 'active' then
        callType = src == call.caller and 'outgoing' or 'incoming'
    end
    
    -- Save to database
    MySQL.insert('INSERT INTO phone_call_history (caller_number, receiver_number, duration, call_type) VALUES (?, ?, ?, ?)', {
        call.callerNumber,
        call.receiverNumber,
        duration,
        callType
    })
    
    -- Notify both parties
    TriggerClientEvent('phone:client:callEnded', call.caller, 'ended')
    TriggerClientEvent('phone:client:callEnded', call.receiver, 'ended')
    
    -- Remove call
    activeCalls[callId] = nil
    
    if Config.DebugMode then
        print('[Phone] Call ended: ' .. callId .. ' (duration: ' .. duration .. 's)')
    end
end)

-- Handle call busy
RegisterNetEvent('phone:server:callBusy', function(callerId)
    local src = source
    
    TriggerClientEvent('phone:client:callBusy', callerId)
    
    if Config.DebugMode then
        print('[Phone] Call busy signal sent to: ' .. callerId)
    end
end)

-- Get call history
RegisterNetEvent('phone:server:getCallHistory', function()
    local src = source
    local phoneNumber = GetCachedPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveCallHistory', src, {})
        return
    end
    
    MySQL.query('SELECT * FROM phone_call_history WHERE caller_number = ? OR receiver_number = ? ORDER BY created_at DESC LIMIT 50', {
        phoneNumber,
        phoneNumber
    }, function(result)
        TriggerClientEvent('phone:client:receiveCallHistory', src, result or {})
    end)
end)

-- Cleanup on player disconnect
AddEventHandler('playerDropped', function()
    local src = source
    
    -- Find and end any active calls
    local callId, call = GetPlayerCall(src)
    
    if call then
        local otherPlayer = call.caller == src and call.receiver or call.caller
        
        -- Calculate duration
        local duration = 0
        if call.acceptTime then
            duration = os.time() - call.acceptTime
        end
        
        -- Log call to database
        local callType = call.state == 'active' and 'ended' or 'missed'
        
        MySQL.insert('INSERT INTO phone_call_history (caller_number, receiver_number, duration, call_type) VALUES (?, ?, ?, ?)', {
            call.callerNumber,
            call.receiverNumber,
            duration,
            callType
        })
        
        -- Notify other player
        TriggerClientEvent('phone:client:callEnded', otherPlayer, 'disconnected')
        
        -- Remove call
        activeCalls[callId] = nil
        
        if Config.DebugMode then
            print('[Phone] Call ended due to disconnect: ' .. callId)
        end
    end
end)

-- Cleanup player calls (called from main.lua)
AddEventHandler('phone:server:cleanupPlayerCalls', function(source, phoneNumber)
    -- Find and end any active calls for this player
    local callId, call = GetPlayerCall(source)
    
    if call then
        local otherPlayer = call.caller == source and call.receiver or call.caller
        
        -- Calculate duration
        local duration = 0
        if call.acceptTime then
            duration = os.time() - call.acceptTime
        end
        
        -- Log call to database
        local callType = call.state == 'active' and 'ended' or 'missed'
        
        MySQL.insert('INSERT INTO phone_call_history (caller_number, receiver_number, duration, call_type) VALUES (?, ?, ?, ?)', {
            call.callerNumber,
            call.receiverNumber,
            duration,
            callType
        })
        
        -- Notify other player
        TriggerClientEvent('phone:client:callEnded', otherPlayer, 'disconnected')
        
        -- Remove call
        activeCalls[callId] = nil
        
        if Config.DebugMode then
            print('[Phone] Cleaned up call for disconnected player: ' .. phoneNumber)
        end
    end
end)
