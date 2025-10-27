-- Audio Recording Module
-- Handles voice recording/audio capture

local Audio = {}
local isRecording = false
local recordingStartTime = 0
local recordingData = {}
local maxDuration = 300 -- seconds (5 minutes)

-- Initialize audio module
function Audio.Initialize()
    maxDuration = Config.MediaStorage and Config.MediaStorage.maxAudioLength or 300
    
    if Config.Debug then
        print('[Phone] Audio module initialized (max duration: ' .. maxDuration .. 's)')
    end
end

-- Start audio recording
function Audio.StartRecording(callback)
    if isRecording then
        if Config.Debug then
            print('[Phone] Already recording audio')
        end
        return false
    end
    
    -- Reset recording data
    recordingData = {}
    recordingStartTime = GetGameTimer()
    isRecording = true
    
    -- Start recording thread
    CreateThread(function()
        local sampleRate = 1000 -- Sample every second
        local duration = 0
        
        while isRecording and duration < maxDuration do
            -- Simulate audio capture
            -- In production, you'd capture actual microphone input
            -- This might require a custom resource or external library
            
            duration = math.floor((GetGameTimer() - recordingStartTime) / 1000)
            
            -- Update recording UI
            SendNUIMessage({
                action = 'updateAudioRecording',
                data = {
                    duration = duration,
                    maxDuration = maxDuration
                }
            })
            
            Wait(sampleRate)
        end
        
        -- Auto-stop if max duration reached
        if isRecording then
            Audio.StopRecording(callback)
        end
    end)
    
    -- Notify UI
    SendNUIMessage({
        action = 'audioRecordingStarted',
        data = {
            maxDuration = maxDuration
        }
    })
    
    TriggerEvent('phone:client:notify', {
        type = 'info',
        message = 'Recording started'
    })
    
    return true
end

-- Stop audio recording
function Audio.StopRecording(callback)
    if not isRecording then
        if Config.Debug then
            print('[Phone] Not currently recording')
        end
        return false
    end
    
    isRecording = false
    
    -- Calculate duration
    local duration = math.floor((GetGameTimer() - recordingStartTime) / 1000)
    
    -- Prepare metadata
    local metadata = {
        duration = duration,
        format = Config.VoiceRecorderApp and Config.VoiceRecorderApp.audioFormat or 'mp3',
        bitrate = Config.VoiceRecorderApp and Config.VoiceRecorderApp.audioBitrate or 128,
        timestamp = os.time()
    }
    
    -- Notify UI
    SendNUIMessage({
        action = 'audioRecordingStopped',
        data = {
            duration = duration
        }
    })
    
    -- Process and upload audio
    CreateThread(function()
        -- Show processing notification
        TriggerEvent('phone:client:notify', {
            type = 'info',
            message = 'Processing recording...'
        })
        
        -- Simulate audio encoding (in production, this would encode the captured audio)
        Wait(1000)
        
        -- Create placeholder audio data
        -- In production, you'd encode the captured audio into MP3/OGG
        local audioData = 'data:audio/mp3;base64,SUQzBAAAAAAAI1RTU0UAAAA...' -- Placeholder base64
        
        -- Upload to server
        TriggerServerEvent('phone:server:uploadAudio', audioData, metadata)
        
        if callback then
            callback(true, duration, metadata)
        end
    end)
    
    return true
end

-- Cancel audio recording
function Audio.CancelRecording()
    if not isRecording then
        return false
    end
    
    isRecording = false
    recordingData = {}
    
    SendNUIMessage({
        action = 'audioRecordingCancelled'
    })
    
    TriggerEvent('phone:client:notify', {
        type = 'info',
        message = 'Recording cancelled'
    })
    
    return true
end

-- Check if recording
function Audio.IsRecording()
    return isRecording
end

-- Get recording status
function Audio.GetStatus()
    local duration = 0
    if isRecording then
        duration = math.floor((GetGameTimer() - recordingStartTime) / 1000)
    end
    
    return {
        isRecording = isRecording,
        duration = duration,
        maxDuration = maxDuration
    }
end

-- Get recording duration
function Audio.GetRecordingDuration()
    if not isRecording then
        return 0
    end
    
    return math.floor((GetGameTimer() - recordingStartTime) / 1000)
end

-- Play audio recording
function Audio.PlayRecording(audioUrl)
    -- This would play the audio file
    -- In production, you'd use an audio resource like xsound or interact-sound
    
    if Config.Debug then
        print('[Phone] Playing audio: ' .. audioUrl)
    end
    
    -- Placeholder for audio playback
    -- You'd integrate with your audio resource here
    
    TriggerEvent('phone:client:notify', {
        type = 'info',
        message = 'Playing recording...'
    })
    
    return true
end

-- Stop audio playback
function Audio.StopPlayback()
    -- This would stop the currently playing audio
    
    if Config.Debug then
        print('[Phone] Stopping audio playback')
    end
    
    return true
end

-- Register NUI callbacks
RegisterNUICallback('startAudioRecording', function(data, cb)
    if Audio.IsRecording() then
        cb({success = false, error = 'Already recording'})
        return
    end
    
    local success = Audio.StartRecording(function(success, duration, metadata)
        if success then
            SendNUIMessage({
                action = 'audioRecorded',
                data = {
                    duration = duration,
                    metadata = metadata
                }
            })
        end
    end)
    
    cb({success = success})
end)

RegisterNUICallback('stopAudioRecording', function(data, cb)
    if not Audio.IsRecording() then
        cb({success = false, error = 'Not recording'})
        return
    end
    
    local success = Audio.StopRecording()
    cb({success = success})
end)

RegisterNUICallback('cancelAudioRecording', function(data, cb)
    local success = Audio.CancelRecording()
    cb({success = success})
end)

RegisterNUICallback('getAudioRecordingStatus', function(data, cb)
    cb(Audio.GetStatus())
end)

RegisterNUICallback('playAudioRecording', function(data, cb)
    if not data.url then
        cb({success = false, error = 'No audio URL provided'})
        return
    end
    
    local success = Audio.PlayRecording(data.url)
    cb({success = success})
end)

RegisterNUICallback('stopAudioPlayback', function(data, cb)
    local success = Audio.StopPlayback()
    cb({success = success})
end)

-- Client events
RegisterNetEvent('phone:client:audioUploaded', function(audioData)
    -- Notify NUI that audio was uploaded
    SendNUIMessage({
        action = 'audioUploaded',
        data = audioData
    })
    
    TriggerEvent('phone:client:notify', {
        type = 'success',
        message = 'Recording saved!'
    })
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isRecording then
            Audio.CancelRecording()
        end
        Audio.StopPlayback()
    end
end)

-- Initialize on resource start
CreateThread(function()
    Audio.Initialize()
end)

return Audio
