-- Client Voice Integration
-- Handles pma-voice integration for calls

local currentVoiceChannel = nil
local previousVoiceMode = nil

-- Check if pma-voice is available
function IsPMAVoiceAvailable()
    return GetResourceState(Config.VoiceResource) == 'started'
end

-- Setup voice channel for call
function SetupVoiceChannel(channelId)
    if not IsPMAVoiceAvailable() then
        print('^3[Phone] ^7pma-voice is not available!')
        return false
    end
    
    -- Store current voice mode
    previousVoiceMode = exports[Config.VoiceResource]:getPlayerMode()
    
    -- Create call channel
    currentVoiceChannel = channelId
    
    -- Set player to call channel
    exports[Config.VoiceResource]:setCallChannel(channelId)
    
    if Config.DebugMode then
        print('[Phone] Voice channel setup: ' .. channelId)
    end
    
    return true
end

-- Cleanup voice channel
function CleanupVoiceChannel()
    if not IsPMAVoiceAvailable() then
        return
    end
    
    if currentVoiceChannel then
        -- Leave call channel
        exports[Config.VoiceResource]:setCallChannel(0)
        
        -- Restore previous voice mode if available
        if previousVoiceMode then
            exports[Config.VoiceResource]:setPlayerMode(previousVoiceMode)
        end
        
        if Config.DebugMode then
            print('[Phone] Voice channel cleaned up: ' .. currentVoiceChannel)
        end
        
        currentVoiceChannel = nil
        previousVoiceMode = nil
    end
end

-- Add player to call channel
function AddPlayerToCallChannel(playerId, channelId)
    if not IsPMAVoiceAvailable() then
        return false
    end
    
    exports[Config.VoiceResource]:addPlayerToCall(channelId)
    
    if Config.DebugMode then
        print('[Phone] Player added to call channel: ' .. channelId)
    end
    
    return true
end

-- Remove player from call channel
function RemovePlayerFromCallChannel(playerId, channelId)
    if not IsPMAVoiceAvailable() then
        return false
    end
    
    exports[Config.VoiceResource]:removePlayerFromCall(channelId)
    
    if Config.DebugMode then
        print('[Phone] Player removed from call channel: ' .. channelId)
    end
    
    return true
end

-- Get current voice channel
function GetCurrentVoiceChannel()
    return currentVoiceChannel
end

-- Export functions
exports('SetupVoiceChannel', SetupVoiceChannel)
exports('CleanupVoiceChannel', CleanupVoiceChannel)
exports('GetCurrentVoiceChannel', GetCurrentVoiceChannel)
exports('IsPMAVoiceAvailable', IsPMAVoiceAvailable)
