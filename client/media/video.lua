-- Video Recording Module
-- Handles video recording at 24 FPS

local Video = {}
local isRecording = false
local recordingStartTime = 0
local recordingFrames = {}
local recordingThread = nil
local maxDuration = 60 -- seconds

-- Initialize video module
function Video.Initialize()
    maxDuration = Config.MediaStorage and Config.MediaStorage.maxVideoLength or 60
    
    if Config.Debug then
        print('[Phone] Video module initialized (max duration: ' .. maxDuration .. 's)')
    end
end

-- Start video recording
function Video.StartRecording(callback)
    if isRecording then
        if Config.DebugMode then
            print('[Phone] Already recording video')
        end
        return false
    end
    
    -- Reset recording data
    recordingFrames = {}
    recordingStartTime = GetGameTimer()
    isRecording = true
    
    -- Get player coordinates for metadata
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Start recording thread
    recordingThread = CreateThread(function()
        local fps = Config.VideoFPS or 24
        local frameDelay = math.floor(1000 / fps) -- milliseconds per frame
        local frameCount = 0
        local maxFrames = fps * maxDuration
        
        if Config.DebugMode then
            print('[Phone] Starting video recording at ' .. fps .. ' FPS for max ' .. maxDuration .. ' seconds')
        end
        
        while isRecording and frameCount < maxFrames do
            local frameTime = GetGameTimer() - recordingStartTime
            
            -- Capture frame using screenshot functionality
            -- In production, this would capture actual screen data
            -- For FiveM, you might use screenshot-basic or similar resource
            local frameData = {
                timestamp = frameTime,
                frame = frameCount,
                captured = false
            }
            
            -- Try to capture frame if screenshot resource is available
            if exports['screenshot-basic'] then
                -- Request screenshot for this frame
                -- Note: This is a simplified version - actual implementation
                -- would need to handle async screenshot capture properly
                frameData.captured = true
            end
            
            table.insert(recordingFrames, frameData)
            frameCount = frameCount + 1
            
            -- Update recording UI every second
            if frameCount % fps == 0 then
                SendNUIMessage({
                    action = 'updateRecording',
                    data = {
                        duration = math.floor(frameTime / 1000),
                        frames = frameCount
                    }
                })
            end
            
            Wait(frameDelay)
        end
        
        -- Auto-stop if max duration reached
        if isRecording then
            if Config.DebugMode then
                print('[Phone] Max recording duration reached, stopping...')
            end
            Video.StopRecording(callback)
        end
    end)
    
    -- Notify UI
    SendNUIMessage({
        action = 'recordingStarted',
        data = {
            maxDuration = maxDuration,
            fps = fps
        }
    })
    
    if Config.DebugMode then
        print('[Phone] Video recording started')
    end
    
    return true
end

-- Stop video recording
function Video.StopRecording(callback)
    if not isRecording then
        if Config.DebugMode then
            print('[Phone] Not currently recording')
        end
        return false
    end
    
    isRecording = false
    
    -- Calculate duration
    local duration = math.floor((GetGameTimer() - recordingStartTime) / 1000)
    
    -- Get player coordinates for metadata
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Prepare metadata
    local metadata = {
        location_x = coords.x,
        location_y = coords.y,
        duration = duration,
        frames = #recordingFrames,
        fps = Config.VideoFPS or 24,
        timestamp = os.time()
    }
    
    if Config.DebugMode then
        print('[Phone] Stopping video recording - Duration: ' .. duration .. 's, Frames: ' .. #recordingFrames)
    end
    
    -- Notify UI
    SendNUIMessage({
        action = 'recordingStopped',
        data = {
            duration = duration,
            frames = #recordingFrames
        }
    })
    
    -- Process and upload video
    CreateThread(function()
        -- Show processing notification
        SendNUIMessage({
            action = 'notify',
            data = {
                type = 'info',
                message = 'Processing video...'
            }
        })
        
        -- Encode video frames
        -- In production, this would:
        -- 1. Combine all captured frames
        -- 2. Encode to H.264/WebM format
        -- 3. Add audio sync if audio was captured
        -- 4. Compress to target bitrate
        
        -- Simulate encoding time based on duration
        local encodingTime = math.max(1000, duration * 200) -- ~200ms per second of video
        Wait(encodingTime)
        
        -- Create video data
        -- In production, this would be the actual encoded video
        -- For now, we'll create a placeholder that includes metadata
        local videoData = {
            format = 'mp4',
            codec = 'h264',
            duration = duration,
            frames = #recordingFrames,
            fps = metadata.fps,
            resolution = '1280x720', -- Default resolution
            data = 'data:video/mp4;base64,AAAAIGZ0eXBpc29t...' -- Placeholder base64
        }
        
        -- Upload to server in chunks if video is large
        -- For now, upload as single payload
        TriggerServerEvent('phone:server:uploadVideo', json.encode(videoData), metadata)
        
        if Config.DebugMode then
            print('[Phone] Video uploaded to server')
        end
        
        if callback then
            callback(true, duration, metadata)
        end
    end)
    
    return true
end

-- Pause video recording
function Video.PauseRecording()
    if not isRecording then
        return false
    end
    
    -- This would pause the recording thread
    -- For simplicity, we'll just stop it
    isRecording = false
    
    SendNUIMessage({
        action = 'recordingPaused'
    })
    
    return true
end

-- Resume video recording
function Video.ResumeRecording()
    if isRecording then
        return false
    end
    
    isRecording = true
    
    SendNUIMessage({
        action = 'recordingResumed'
    })
    
    return true
end

-- Cancel video recording
function Video.CancelRecording()
    if not isRecording then
        return false
    end
    
    isRecording = false
    recordingFrames = {}
    
    SendNUIMessage({
        action = 'recordingCancelled'
    })
    
    TriggerEvent('phone:client:notify', {
        type = 'info',
        message = 'Recording cancelled'
    })
    
    return true
end

-- Check if recording
function Video.IsRecording()
    return isRecording
end

-- Get recording status
function Video.GetStatus()
    local duration = 0
    if isRecording then
        duration = math.floor((GetGameTimer() - recordingStartTime) / 1000)
    end
    
    return {
        isRecording = isRecording,
        duration = duration,
        frames = #recordingFrames,
        maxDuration = maxDuration
    }
end

-- Get recording duration
function Video.GetRecordingDuration()
    if not isRecording then
        return 0
    end
    
    return math.floor((GetGameTimer() - recordingStartTime) / 1000)
end

-- Register NUI callbacks
RegisterNUICallback('startVideoRecording', function(data, cb)
    if Video.IsRecording() then
        cb({success = false, error = 'Already recording'})
        return
    end
    
    local success = Video.StartRecording(function(success, duration, metadata)
        if success then
            SendNUIMessage({
                action = 'videoRecorded',
                data = {
                    duration = duration,
                    metadata = metadata
                }
            })
        end
    end)
    
    cb({success = success})
end)

RegisterNUICallback('stopVideoRecording', function(data, cb)
    if not Video.IsRecording() then
        cb({success = false, error = 'Not recording'})
        return
    end
    
    local success = Video.StopRecording()
    cb({success = success})
end)

RegisterNUICallback('cancelVideoRecording', function(data, cb)
    local success = Video.CancelRecording()
    cb({success = success})
end)

RegisterNUICallback('getRecordingStatus', function(data, cb)
    cb(Video.GetStatus())
end)

-- Client events
RegisterNetEvent('phone:client:videoUploaded', function(videoData)
    -- Notify NUI that video was uploaded
    SendNUIMessage({
        action = 'videoUploaded',
        data = videoData
    })
    
    TriggerEvent('phone:client:notify', {
        type = 'success',
        message = 'Video saved!'
    })
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isRecording then
            Video.CancelRecording()
        end
    end
end)

-- Initialize on resource start
CreateThread(function()
    Video.Initialize()
end)

return Video
