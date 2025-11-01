-- Server Message Management
-- Handles message sending, receiving, and storage

local Database = lib.require('server.database')

-- Message queue for offline players
local offlineMessageQueue = {}

-- Get all messages for a player
RegisterNetEvent('phone:server:getMessages', function()
    local src = source
    local phoneNumber = GetCachedPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:messageOperationResult', src, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Query to get all messages where player is sender or receiver
    local query = [[
        SELECT * FROM phone_messages 
        WHERE sender_number = ? OR receiver_number = ?
        ORDER BY created_at ASC
    ]]
    
    Database.Query(query, {phoneNumber, phoneNumber}, function(messages)
        if messages then
            TriggerClientEvent('phone:client:receiveMessages', src, messages)
        else
            TriggerClientEvent('phone:client:messageOperationResult', src, {
                success = false,
                message = 'Failed to fetch messages'
            })
        end
    end)
end)

-- Send a message
RegisterNetEvent('phone:server:sendMessage', function(data)
    local src = source
    
    -- Check rate limit
    local rateLimitOk, rateLimitError = CheckMessageRateLimit(src)
    if not rateLimitOk then
        TriggerClientEvent('phone:client:messageOperationResult', src, ErrorResponse(rateLimitError))
        return
    end
    
    local senderNumber = GetCachedPhoneNumber(src)
    
    if not senderNumber then
        TriggerClientEvent('phone:client:messageOperationResult', src, ErrorResponse(ERROR_CODES.PLAYER_NOT_FOUND))
        return
    end
    
    -- Validate input
    if not data or not data.targetNumber or not data.message then
        TriggerClientEvent('phone:client:messageOperationResult', src, ErrorResponse(ERROR_CODES.INVALID_INPUT, 'Target number and message are required'))
        return
    end
    
    local targetNumber = SanitizeInput(data.targetNumber)
    local message = SanitizeInput(data.message)
    
    -- Validate message content
    local messageValid, messageError, messageMsg = ValidateMessage(message)
    if not messageValid then
        TriggerClientEvent('phone:client:messageOperationResult', src, ErrorResponse(messageError, messageMsg))
        return
    end
    
    -- Validate phone number format
    local phoneValid, phoneError, phoneMsg = ValidatePhoneNumber(targetNumber)
    if not phoneValid then
        TriggerClientEvent('phone:client:messageOperationResult', src, ErrorResponse(phoneError, phoneMsg))
        return
    end
    
    -- Verify can send message
    local canSend, sendError, sendMsg = VerifyCanSendMessage(src, targetNumber)
    if not canSend then
        TriggerClientEvent('phone:client:messageOperationResult', src, ErrorResponse(sendError, sendMsg))
        return
    end
    
    -- Check if target phone number exists
    TryCatch(function()
        Database.PhoneNumberExists(targetNumber, function(exists)
            if not exists then
                TriggerClientEvent('phone:client:messageOperationResult', src, ErrorResponse(ERROR_CODES.PHONE_NUMBER_NOT_FOUND))
                return
            end
            
            -- Insert message into database with error handling
            Database.Insert('phone_messages', {
                sender_number = senderNumber,
                receiver_number = targetNumber,
                message = message,
                is_read = false
            }, function(success, insertId)
                if success then
                    local messageData = {
                        id = insertId,
                        sender_number = senderNumber,
                        receiver_number = targetNumber,
                        message = message,
                        is_read = false,
                        created_at = os.date('%Y-%m-%d %H:%M:%S')
                    }
                    
                    -- Send success response to sender
                    TriggerClientEvent('phone:client:messageOperationResult', src, SuccessResponse({
                        operation = 'send',
                        message = messageData
                    }))
                    
                    -- Try to deliver message to receiver if online
                    local receiverSource = GetPlayerSourceByPhoneNumber(targetNumber)
                    
                    if receiverSource then
                        -- Receiver is online, deliver immediately
                        TriggerClientEvent('phone:client:receiveMessage', receiverSource, messageData)
                    else
                        -- Receiver is offline, queue message
                        if Config.SaveMessagesOffline then
                            if not offlineMessageQueue[targetNumber] then
                                offlineMessageQueue[targetNumber] = {}
                            end
                            table.insert(offlineMessageQueue[targetNumber], messageData)
                            
                            if Config.DebugMode then
                                print('[Phone] Message queued for offline player: ' .. targetNumber)
                            end
                        end
                    end
                else
                    TriggerClientEvent('phone:client:messageOperationResult', src, ErrorResponse(ERROR_CODES.DATABASE_ERROR, 'Failed to send message'))
                end
            end)
        end)
    end, function(err)
        TriggerClientEvent('phone:client:messageOperationResult', src, ErrorResponse(ERROR_CODES.OPERATION_FAILED, 'An error occurred while sending message'))
    end)
end)

-- Mark messages as read
RegisterNetEvent('phone:server:markMessagesRead', function(data)
    local src = source
    local myNumber = GetCachedPhoneNumber(src)
    
    if not myNumber or not data or not data.phoneNumber then
        TriggerClientEvent('phone:client:messageOperationResult', src, {
            operation = 'markRead',
            success = false,
            message = 'Invalid request'
        })
        return
    end
    
    local otherNumber = data.phoneNumber
    
    -- Update all unread messages from the other number
    local query = [[
        UPDATE phone_messages 
        SET is_read = TRUE 
        WHERE sender_number = ? AND receiver_number = ? AND is_read = FALSE
    ]]
    
    Database.Execute(query, {otherNumber, myNumber}, function(affectedRows)
        TriggerClientEvent('phone:client:messageOperationResult', src, {
            operation = 'markRead',
            success = true,
            count = affectedRows
        })
    end)
end)

-- Deliver queued messages when player logs in
RegisterNetEvent('phone:server:playerLoaded', function()
    local src = source
    local phoneNumber = GetCachedPhoneNumber(src)
    
    if not phoneNumber then
        return
    end
    
    -- Check if there are queued messages for this player
    if offlineMessageQueue[phoneNumber] and #offlineMessageQueue[phoneNumber] > 0 then
        for _, messageData in ipairs(offlineMessageQueue[phoneNumber]) do
            TriggerClientEvent('phone:client:receiveMessage', src, messageData)
        end
        
        if Config.DebugMode then
            print('[Phone] Delivered ' .. #offlineMessageQueue[phoneNumber] .. ' queued messages to ' .. phoneNumber)
        end
        
        -- Clear the queue
        offlineMessageQueue[phoneNumber] = nil
    end
end)

-- Helper function to get player source by phone number
function GetPlayerSourceByPhoneNumber(phoneNumber)
    local players = GetPlayers()
    
    for _, playerId in ipairs(players) do
        local playerPhone = GetCachedPhoneNumber(tonumber(playerId))
        if playerPhone == phoneNumber then
            return tonumber(playerId)
        end
    end
    
    return nil
end

-- Export for other resources
exports('GetPlayerSourceByPhoneNumber', GetPlayerSourceByPhoneNumber)
