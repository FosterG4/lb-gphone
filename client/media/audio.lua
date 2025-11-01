--[[
    Audio Recording Module
    Handles voice recording/audio capture for the phone system
    
    Requirements Implementation:
    - Requirement 34.2: Implement start/stop recording with microphone input capture
    - Requirement 34.3: Encode audio (MP3/OGG) and upload to server
    
    Features:
    - Microphone input capture simulation
    - Audio chunk buffering
    - MP3/OGG encoding support
    - Configurable recording duration (default: 5 minutes)
    - Configurable audio quality (bitrate, sample rate)
    - Real-time recording status updates
    - Audio playback integration (xsound, interact-sound)
    - Validation and error handling
    - Memory cleanup on resource stop
    
    Technical Notes:
    - FiveM does not have native microphone capture support
    - This implementation simulates audio capture for demonstration
    - In production, you would need:
      1. A custom C#/C++ plugin for actual microphone access
      2. Integration with Windows/Linux audio APIs
      3. Or use pma-voice's audio stream if available
    - Audio encoding is simulated; production would use LAME (MP3) or libvorbis (OGG)
    
    Configuration:
    - Config.VoiceRecorderApp.maxRecordingLength: Maximum recording duration in seconds
    - Config.VoiceRecorderApp.audioFormat: Audio format ('mp3' or 'ogg')
    - Config.VoiceRecorderApp.audioBitrate: Audio bitrate in kbps
    - Config.MusiclyApp.audioResource: Audio playback resource ('xsound', 'interact-sound')
    
    Usage:
    - NUI callbacks handle all user interactions
    - Server events handle upload and storage
    - Exports available for external resource integration
]]--

local Audio = {}
local isRecording = false
local recordingStartTime = 0
local recordingData = {}
local audioChunks = {}
local maxDuration = 300 -- seconds (5 minutes)
local audioFormat = 'mp3'
local audioBitrate = 128

-- Initialize audio module
function Audio.Initialize()
    maxDuration = Config.VoiceRecorderApp and Config.VoiceRecorderApp.maxRecordingLength or 300
    audioFormat = Config.VoiceRecorderApp and Config.VoiceRecorderApp.audioFormat or 'mp3'
    audioBitrate = Config.VoiceRecorderApp and Config.VoiceRecorderApp.audioBitrate or 128
    
    if Config.DebugMode then
        print('[Phone] Audio module initialized')
        print('[Phone] Max duration: ' .. maxDuration .. 's')
        print('[Phone] Format: ' .. audioFormat .. ' @ ' .. audioBitrate .. 'kbps')
    end
end

-- Capture microphone input
-- This function simulates microphone capture
-- In production, you would integrate with a native audio capture system
function Audio.CaptureMicrophoneInput()
    -- FiveM doesn't have built-in microphone capture
    -- This would require:
    -- 1. A custom C# or C++ plugin for audio capture
    -- 2. Integration with Windows/Linux audio APIs
    -- 3. Or use of pma-voice's audio stream (if available)
    
    -- For now, we'll simulate audio capture by generating audio chunks
    -- Each chunk represents a segment of captured audio data
    local chunk = {
        timestamp = GetGameTimer(),
        data = Audio.GenerateAudioChunk(),
        size = math.random(1000, 5000) -- Simulated chunk size in bytes
    }
    
    table.insert(audioChunks, chunk)
    
    if Config.DebugMode then
        print('[Phone] Captured audio chunk: ' .. #audioChunks)
    end
    
    return chunk
end

-- Generate simulated audio chunk
-- In production, this would be actual PCM audio data from microphone
function Audio.GenerateAudioChunk()
    -- Simulate audio data (in production, this would be real audio samples)
    local chunkData = {}
    local sampleCount = 1024 -- Number of audio samples per chunk
    
    for i = 1, sampleCount do
        -- Generate random audio sample (simulating microphone input)
        chunkData[i] = math.random(-32768, 32767) -- 16-bit audio sample
    end
    
    return chunkData
end

-- Encode audio data to MP3/OGG format
-- Requirement 34.3: Encode audio (MP3/OGG)
function Audio.EncodeAudio(chunks, format)
    if Config.DebugMode then
        print('[Phone] Encoding ' .. #chunks .. ' audio chunks to ' .. format)
    end
    
    -- In production, you would:
    -- 1. Combine all audio chunks into a single buffer
    -- 2. Use an audio encoder library (LAME for MP3, libvorbis for OGG)
    -- 3. Encode the PCM data to compressed format
    -- 4. Return the encoded audio as base64 string
    
    -- For this implementation, we'll create a simulated encoded audio file
    local encodedData = Audio.SimulateEncoding(chunks, format)
    
    if Config.DebugMode then
        print('[Phone] Audio encoding complete')
    end
    
    return encodedData
end

-- Simulate audio encoding process
function Audio.SimulateEncoding(chunks, format)
    -- Calculate total size
    local totalSize = 0
    for _, chunk in ipairs(chunks) do
        totalSize = totalSize + chunk.size
    end
    
    -- Create metadata
    local metadata = {
        format = format,
        bitrate = audioBitrate,
        sampleRate = 44100, -- Standard sample rate
        channels = 1, -- Mono recording
        duration = #chunks, -- Approximate duration in seconds
        size = totalSize
    }
    
    -- In production, this would be actual encoded audio data
    -- For now, we'll create a base64-encoded placeholder
    local encodedAudio = {
        header = 'data:audio/' .. format .. ';base64,',
        data = Audio.GenerateBase64AudioData(totalSize),
        metadata = metadata
    }
    
    return encodedAudio
end

-- Generate simulated base64 audio data
function Audio.GenerateBase64AudioData(size)
    -- In production, this would be the actual base64-encoded audio file
    -- For simulation, we'll create a placeholder string
    local base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local dataLength = math.floor(size / 3) * 4 -- Base64 encoding increases size by ~33%
    local data = ''
    
    -- Generate random base64 string (simulating encoded audio)
    for i = 1, math.min(dataLength, 1000) do -- Limit to 1000 chars for performance
        local randomIndex = math.random(1, #base64Chars)
        data = data .. string.sub(base64Chars, randomIndex, randomIndex)
    end
    
    -- Add ellipsis to indicate truncated data
    if dataLength > 1000 then
        data = data .. '...[truncated]'
    end
    
    return data
end

-- Start audio recording
-- Requirement 34.2: Implement start/stop recording
function Audio.StartRecording(callback)
    if isRecording then
        if Config.DebugMode then
            print('[Phone] Already recording audio')
        end
        return false
    end
    
    -- Reset recording data
    recordingData = {}
    audioChunks = {}
    recordingStartTime = GetGameTimer()
    isRecording = true
    
    if Config.DebugMode then
        print('[Phone] Starting audio recording')
    end
    
    -- Start recording thread
    CreateThread(function()
        local captureInterval = 1000 -- Capture audio every second
        local duration = 0
        
        while isRecording and duration < maxDuration do
            -- Capture microphone input
            -- Requirement 34.2: Add microphone input capture
            Audio.CaptureMicrophoneInput()
            
            duration = math.floor((GetGameTimer() - recordingStartTime) / 1000)
            
            -- Update recording UI with current duration
            SendNUIMessage({
                action = 'updateAudioRecording',
                data = {
                    duration = duration,
                    maxDuration = maxDuration,
                    isRecording = true
                }
            })
            
            Wait(captureInterval)
        end
        
        -- Auto-stop if max duration reached
        if isRecording then
            if Config.DebugMode then
                print('[Phone] Max duration reached, auto-stopping recording')
            end
            Audio.StopRecording(callback)
        end
    end)
    
    -- Notify UI that recording started
    SendNUIMessage({
        action = 'audioRecordingStarted',
        data = {
            maxDuration = maxDuration,
            format = audioFormat,
            bitrate = audioBitrate
        }
    })
    
    -- Show notification
    TriggerEvent('phone:client:notify', {
        type = 'info',
        message = 'Recording started'
    })
    
    if Config.DebugMode then
        print('[Phone] Audio recording started successfully')
    end
    
    return true
end

-- Stop audio recording
-- Requirement 34.2: Implement start/stop recording
function Audio.StopRecording(callback)
    if not isRecording then
        if Config.DebugMode then
            print('[Phone] Not currently recording')
        end
        return false
    end
    
    isRecording = false
    
    -- Calculate duration
    local duration = math.floor((GetGameTimer() - recordingStartTime) / 1000)
    
    if Config.DebugMode then
        print('[Phone] Stopping audio recording (duration: ' .. duration .. 's)')
        print('[Phone] Captured ' .. #audioChunks .. ' audio chunks')
    end
    
    -- Prepare metadata
    local metadata = {
        duration = duration,
        format = audioFormat,
        bitrate = audioBitrate,
        sampleRate = 44100,
        channels = 1,
        timestamp = os.time(),
        chunkCount = #audioChunks
    }
    
    -- Notify UI that recording stopped
    SendNUIMessage({
        action = 'audioRecordingStopped',
        data = {
            duration = duration,
            processing = true
        }
    })
    
    -- Process and upload audio
    -- Requirement 34.3: Encode audio (MP3/OGG) and upload to server
    CreateThread(function()
        -- Show processing notification
        TriggerEvent('phone:client:notify', {
            type = 'info',
            message = 'Processing recording...'
        })
        
        if Config.DebugMode then
            print('[Phone] Encoding audio to ' .. audioFormat)
        end
        
        -- Encode audio chunks to MP3/OGG format
        -- Requirement 34.3: Encode audio (MP3/OGG)
        local encodedAudio = Audio.EncodeAudio(audioChunks, audioFormat)
        
        -- Simulate encoding time (in production, actual encoding takes time)
        Wait(500)
        
        -- Prepare audio data for upload
        local audioData = encodedAudio.header .. encodedAudio.data
        
        if Config.DebugMode then
            print('[Phone] Audio encoded, uploading to server')
        end
        
        -- Upload to server
        -- Requirement 34.3: Upload to server
        TriggerServerEvent('phone:server:uploadAudio', audioData, metadata)
        
        -- Clear audio chunks from memory
        audioChunks = {}
        
        if Config.DebugMode then
            print('[Phone] Audio upload initiated')
        end
        
        -- Execute callback if provided
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
    audioChunks = {}
    
    if Config.DebugMode then
        print('[Phone] Audio recording cancelled')
    end
    
    SendNUIMessage({
        action = 'audioRecordingCancelled'
    })
    
    TriggerEvent('phone:client:notify', {
        type = 'info',
        message = 'Recording cancelled'
    })
    
    return true
end

-- Validate audio recording
function Audio.ValidateRecording(duration)
    -- Check minimum duration (at least 1 second)
    if duration < 1 then
        if Config.DebugMode then
            print('[Phone] Recording too short: ' .. duration .. 's')
        end
        return false, 'Recording too short (minimum 1 second)'
    end
    
    -- Check maximum duration
    if duration > maxDuration then
        if Config.DebugMode then
            print('[Phone] Recording too long: ' .. duration .. 's')
        end
        return false, 'Recording too long (maximum ' .. maxDuration .. ' seconds)'
    end
    
    -- Check if we have audio chunks
    if #audioChunks == 0 then
        if Config.DebugMode then
            print('[Phone] No audio data captured')
        end
        return false, 'No audio data captured'
    end
    
    return true, 'Valid recording'
end

-- Get estimated file size
function Audio.GetEstimatedFileSize(duration)
    -- Calculate estimated file size based on bitrate and duration
    -- Formula: (bitrate in kbps * duration in seconds) / 8 = size in KB
    local sizeKB = (audioBitrate * duration) / 8
    local sizeMB = sizeKB / 1024
    
    return {
        bytes = sizeKB * 1024,
        kilobytes = sizeKB,
        megabytes = sizeMB
    }
end

-- Check if recording is allowed
function Audio.CanStartRecording()
    -- Check if already recording
    if isRecording then
        return false, 'Already recording'
    end
    
    -- Check if phone is open
    local phoneOpen = exports['phone']:IsPhoneOpen()
    if not phoneOpen then
        return false, 'Phone must be open to record'
    end
    
    -- Check storage quota (if implemented)
    -- This would check against Config.StorageQuotaPerPlayer
    
    return true, 'Can start recording'
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
    if not audioUrl then
        if Config.DebugMode then
            print('[Phone] No audio URL provided')
        end
        return false
    end
    
    if Config.DebugMode then
        print('[Phone] Playing audio: ' .. audioUrl)
    end
    
    -- Integration with audio resources
    -- Check which audio resource is configured
    local audioResource = Config.MusiclyApp and Config.MusiclyApp.audioResource or 'xsound'
    
    if audioResource == 'xsound' then
        -- Use xsound for playback
        if GetResourceState('xsound') == 'started' then
            exports.xsound:PlayUrl('phone_voice_recording', audioUrl, 0.5, false)
            
            if Config.DebugMode then
                print('[Phone] Playing audio via xsound')
            end
        else
            if Config.DebugMode then
                print('[Phone] xsound resource not available')
            end
        end
    elseif audioResource == 'interact-sound' then
        -- Use interact-sound for playback
        if GetResourceState('interact-sound') == 'started' then
            TriggerServerEvent('InteractSound_SV:PlayOnSource', 'phone_voice_recording', 0.5)
            
            if Config.DebugMode then
                print('[Phone] Playing audio via interact-sound')
            end
        else
            if Config.DebugMode then
                print('[Phone] interact-sound resource not available')
            end
        end
    else
        -- Fallback: just show notification
        if Config.DebugMode then
            print('[Phone] No audio resource configured, using fallback')
        end
    end
    
    TriggerEvent('phone:client:notify', {
        type = 'info',
        message = 'Playing recording...'
    })
    
    return true
end

-- Stop audio playback
function Audio.StopPlayback()
    if Config.DebugMode then
        print('[Phone] Stopping audio playback')
    end
    
    -- Stop playback based on configured audio resource
    local audioResource = Config.MusiclyApp and Config.MusiclyApp.audioResource or 'xsound'
    
    if audioResource == 'xsound' then
        if GetResourceState('xsound') == 'started' then
            exports.xsound:Destroy('phone_voice_recording')
            
            if Config.DebugMode then
                print('[Phone] Stopped xsound playback')
            end
        end
    elseif audioResource == 'interact-sound' then
        if GetResourceState('interact-sound') == 'started' then
            TriggerServerEvent('InteractSound_SV:StopSound')
            
            if Config.DebugMode then
                print('[Phone] Stopped interact-sound playback')
            end
        end
    end
    
    return true
end

-- Pause audio playback
function Audio.PausePlayback()
    if Config.DebugMode then
        print('[Phone] Pausing audio playback')
    end
    
    local audioResource = Config.MusiclyApp and Config.MusiclyApp.audioResource or 'xsound'
    
    if audioResource == 'xsound' then
        if GetResourceState('xsound') == 'started' then
            exports.xsound:Pause('phone_voice_recording')
        end
    end
    
    return true
end

-- Resume audio playback
function Audio.ResumePlayback()
    if Config.DebugMode then
        print('[Phone] Resuming audio playback')
    end
    
    local audioResource = Config.MusiclyApp and Config.MusiclyApp.audioResource or 'xsound'
    
    if audioResource == 'xsound' then
        if GetResourceState('xsound') == 'started' then
            exports.xsound:Resume('phone_voice_recording')
        end
    end
    
    return true
end

-- Register NUI callbacks
RegisterNUICallback('startAudioRecording', function(data, cb)
    -- Check if recording is allowed
    local canRecord, reason = Audio.CanStartRecording()
    if not canRecord then
        cb({success = false, error = reason})
        return
    end
    
    -- Start recording with callback
    local success = Audio.StartRecording(function(success, duration, metadata)
        if success then
            -- Validate recording
            local valid, validationMessage = Audio.ValidateRecording(duration)
            
            if valid then
                -- Get estimated file size
                local fileSize = Audio.GetEstimatedFileSize(duration)
                
                -- Send recording complete notification to NUI
                SendNUIMessage({
                    action = 'audioRecorded',
                    data = {
                        duration = duration,
                        metadata = metadata,
                        fileSize = fileSize
                    }
                })
                
                if Config.DebugMode then
                    print('[Phone] Audio recording completed successfully')
                    print('[Phone] Duration: ' .. duration .. 's')
                    print('[Phone] Estimated size: ' .. string.format('%.2f', fileSize.megabytes) .. ' MB')
                end
            else
                -- Recording validation failed
                SendNUIMessage({
                    action = 'audioRecordingFailed',
                    data = {
                        error = validationMessage
                    }
                })
                
                TriggerEvent('phone:client:notify', {
                    type = 'error',
                    message = validationMessage
                })
            end
        else
            -- Recording failed
            SendNUIMessage({
                action = 'audioRecordingFailed',
                data = {
                    error = 'Failed to complete recording'
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

RegisterNUICallback('pauseAudioPlayback', function(data, cb)
    local success = Audio.PausePlayback()
    cb({success = success})
end)

RegisterNUICallback('resumeAudioPlayback', function(data, cb)
    local success = Audio.ResumePlayback()
    cb({success = success})
end)

-- Client events
RegisterNetEvent('phone:client:audioUploaded', function(audioData)
    -- Notify NUI that audio was uploaded successfully
    SendNUIMessage({
        action = 'audioUploaded',
        data = audioData
    })
    
    -- Show success notification
    TriggerEvent('phone:client:notify', {
        type = 'success',
        message = 'Recording saved!'
    })
    
    if Config.DebugMode then
        print('[Phone] Audio uploaded successfully')
        print('[Phone] Media ID: ' .. (audioData.id or 'unknown'))
    end
end)

RegisterNetEvent('phone:client:audioUploadFailed', function(errorData)
    -- Notify NUI that audio upload failed
    SendNUIMessage({
        action = 'audioUploadFailed',
        data = errorData
    })
    
    -- Show error notification
    TriggerEvent('phone:client:notify', {
        type = 'error',
        message = errorData.message or 'Failed to save recording'
    })
    
    if Config.DebugMode then
        print('[Phone] Audio upload failed: ' .. (errorData.message or 'unknown error'))
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Cancel any active recording
        if isRecording then
            if Config.DebugMode then
                print('[Phone] Resource stopping, cancelling active recording')
            end
            Audio.CancelRecording()
        end
        
        -- Stop any active playback
        Audio.StopPlayback()
        
        -- Clear audio chunks from memory
        audioChunks = {}
        recordingData = {}
        
        if Config.DebugMode then
            print('[Phone] Audio module cleaned up')
        end
    end
end)

-- Initialize on resource start
CreateThread(function()
    Audio.Initialize()
end)

-- Export functions for use by other resources
exports('StartRecording', Audio.StartRecording)
exports('StopRecording', Audio.StopRecording)
exports('CancelRecording', Audio.CancelRecording)
exports('IsRecording', Audio.IsRecording)
exports('GetStatus', Audio.GetStatus)
exports('PlayRecording', Audio.PlayRecording)
exports('StopPlayback', Audio.StopPlayback)

return Audio
