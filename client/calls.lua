-- Client Call Management
-- Handles call state management and call-related logic

local currentCall = nil
local callState = 'idle' -- 'idle', 'ringing', 'active'
local callTimer = 0
local callStartTime = 0

-- Get current call state
function GetCallState()
    return callState
end

-- Set call state
function SetCallState(state)
    callState = state
    
    if Config.DebugMode then
        print('[Phone] Call state changed to: ' .. state)
    end
    
    -- Update NUI
    SendNUIMessage({
        action = 'updateCallState',
        data = { state = state }
    })
end

-- Get current call
function GetCurrentCall()
    return currentCall
end

-- Set current call
function SetCurrentCall(call)
    currentCall = call
end

-- Clear current call
function ClearCurrentCall()
    currentCall = nil
    callTimer = 0
    callStartTime = 0
end

-- Start call timer
function StartCallTimer()
    callStartTime = GetGameTimer()
    
    CreateThread(function()
        while callState == 'active' do
            Wait(1000)
            callTimer = math.floor((GetGameTimer() - callStartTime) / 1000)
        end
    end)
end

-- Get call duration
function GetCallDuration()
    return callTimer
end

-- Handle incoming call
RegisterNetEvent('phone:client:incomingCall', function(callData)
    if callState ~= 'idle' then
        -- Player is already in a call, send busy signal
        TriggerServerEvent('phone:server:callBusy', callData.callerId)
        return
    end
    
    -- Set call state
    SetCallState('ringing')
    SetCurrentCall({
        callerId = callData.callerId,
        callerNumber = callData.callerNumber,
        callerName = callData.callerName,
        direction = 'incoming'
    })
    
    -- Show incoming call notification
    SendNUIMessage({
        action = 'incomingCall',
        data = {
            callerNumber = callData.callerNumber,
            callerName = callData.callerName or callData.callerNumber
        }
    })
    
    -- Show notification if phone is closed
    if not exports[GetCurrentResourceName()]:IsPhoneOpen() then
        SendNUIMessage({
            action = 'showNotification',
            data = {
                type = 'call',
                title = 'Incoming Call',
                message = 'From: ' .. (callData.callerName or callData.callerNumber),
                duration = Config.CallTimeout
            }
        })
    end
    
    -- Play ringtone (optional)
    if Config.NotificationSound then
        PlaySound(-1, "PHONE_GENERIC_KEY_PRESS", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
    end
    
    if Config.DebugMode then
        print('[Phone] Incoming call from: ' .. callData.callerNumber)
    end
end)

-- Handle call accepted
RegisterNetEvent('phone:client:callAccepted', function(callData)
    SetCallState('active')
    
    -- Start call timer
    StartCallTimer()
    
    -- Setup voice channel
    SetupVoiceChannel(callData.channelId)
    
    -- Update NUI
    SendNUIMessage({
        action = 'callAccepted',
        data = callData
    })
    
    if Config.DebugMode then
        print('[Phone] Call accepted, channel: ' .. callData.channelId)
    end
end)

-- Handle call ended
RegisterNetEvent('phone:client:callEnded', function(reason)
    local duration = GetCallDuration()
    
    -- Cleanup voice channel
    if callState == 'active' then
        CleanupVoiceChannel()
    end
    
    -- Update NUI
    SendNUIMessage({
        action = 'callEnded',
        data = {
            reason = reason or 'ended',
            duration = duration
        }
    })
    
    -- Clear call data
    ClearCurrentCall()
    SetCallState('idle')
    
    if Config.DebugMode then
        print('[Phone] Call ended: ' .. (reason or 'normal'))
    end
end)

-- Handle call busy
RegisterNetEvent('phone:client:callBusy', function()
    -- Update NUI
    SendNUIMessage({
        action = 'callBusy',
        data = {}
    })
    
    -- Clear call data
    ClearCurrentCall()
    SetCallState('idle')
    
    if Config.DebugMode then
        print('[Phone] Call busy')
    end
end)

-- Handle call timeout
RegisterNetEvent('phone:client:callTimeout', function()
    -- Update NUI
    SendNUIMessage({
        action = 'callTimeout',
        data = {}
    })
    
    -- Clear call data
    ClearCurrentCall()
    SetCallState('idle')
    
    if Config.DebugMode then
        print('[Phone] Call timeout')
    end
end)

-- Handle call initiated response
RegisterNetEvent('phone:client:callInitiated', function(result)
    if result.success then
        SetCallState('ringing')
        SetCurrentCall({
            targetNumber = result.targetNumber,
            direction = 'outgoing'
        })
        
        -- Switch to call screen in NUI
        SendNUIMessage({
            action = 'switchToCallScreen',
            data = {}
        })
        
        if Config.DebugMode then
            print('[Phone] Call initiated to: ' .. result.targetNumber)
        end
    end
end)

-- Handle receive call history
RegisterNetEvent('phone:client:receiveCallHistory', function(history)
    -- This is handled by NUI callbacks
end)

-- Export functions
exports('GetCallState', GetCallState)
exports('GetCurrentCall', GetCurrentCall)
exports('IsInCall', function()
    return callState ~= 'idle'
end)
