-- Camera Module
-- Handles screenshot capture for photos

local Camera = {}
local isCapturing = false
local currentFilter = 'none'

-- Initialize camera
function Camera.Initialize()
    if Config.Debug then
        print('[Phone] Camera module initialized')
    end
end

-- Set camera filter
function Camera.SetFilter(filter)
    if not filter then
        currentFilter = 'none'
        return
    end
    
    local availableFilters = Config.CameraApp and Config.CameraApp.availableFilters or {'none'}
    
    for _, availableFilter in ipairs(availableFilters) do
        if availableFilter == filter then
            currentFilter = filter
            return true
        end
    end
    
    return false
end

-- Get current filter
function Camera.GetFilter()
    return currentFilter
end

-- Apply filter effect (visual only, actual processing done server-side)
function Camera.ApplyFilterEffect(filter)
    -- This would apply visual effects to the screen
    -- For FiveM, you might use timecycle modifiers or screen effects
    
    if filter == 'bw' then
        SetTimecycleModifier('cinema')
    elseif filter == 'sepia' then
        SetTimecycleModifier('sepia')
    elseif filter == 'vintage' then
        SetTimecycleModifier('cinema')
    elseif filter == 'cool' then
        SetTimecycleModifier('underwater')
    elseif filter == 'warm' then
        SetTimecycleModifier('sunset')
    else
        ClearTimecycleModifier()
    end
end

-- Clear filter effects
function Camera.ClearFilterEffects()
    ClearTimecycleModifier()
end

-- Capture photo
function Camera.CapturePhoto(callback)
    if isCapturing then
        if Config.Debug then
            print('[Phone] Already capturing photo')
        end
        return false
    end
    
    isCapturing = true
    
    -- Get player coordinates for metadata
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Apply filter effect temporarily
    if currentFilter ~= 'none' then
        Camera.ApplyFilterEffect(currentFilter)
    end
    
    -- Wait a frame for filter to apply
    Wait(100)
    
    -- Request screenshot
    exports['screenshot-basic']:requestScreenshotUpload(
        'https://example.com/upload', -- This would be your upload endpoint
        'files[]',
        function(data)
            -- Clear filter effects
            Camera.ClearFilterEffects()
            isCapturing = false
            
            if data then
                -- Parse the response
                local imageData = json.decode(data)
                
                if imageData and imageData.url then
                    -- Prepare metadata
                    local metadata = {
                        location_x = coords.x,
                        location_y = coords.y,
                        filter = currentFilter,
                        timestamp = os.time()
                    }
                    
                    if callback then
                        callback(true, imageData.url, metadata)
                    end
                else
                    if callback then
                        callback(false, 'Failed to upload photo')
                    end
                end
            else
                if callback then
                    callback(false, 'Screenshot capture failed')
                end
            end
        end
    )
    
    return true
end

-- Alternative capture method using game natives
function Camera.CapturePhotoNative(callback)
    if isCapturing then
        if Config.Debug then
            print('[Phone] Already capturing photo')
        end
        return false
    end
    
    isCapturing = true
    
    -- Get player coordinates for metadata
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Apply filter effect temporarily
    if currentFilter ~= 'none' then
        Camera.ApplyFilterEffect(currentFilter)
    end
    
    -- Wait a frame for filter to apply
    Wait(100)
    
    -- Create a unique handle for this screenshot
    local handle = 'phone_photo_' .. GetGameTimer()
    
    -- Request screenshot from player
    CreateThread(function()
        -- This is a simplified version - actual implementation would need proper screenshot handling
        -- FiveM doesn't have built-in screenshot to base64, so you'd need a resource like screenshot-basic
        
        -- Simulate screenshot capture
        Wait(500)
        
        -- Clear filter effects
        Camera.ClearFilterEffects()
        isCapturing = false
        
        -- For now, we'll create a placeholder
        -- In production, you'd get actual screenshot data
        local photoData = 'data:image/jpeg;base64,/9j/4AAQSkZJRg...' -- Placeholder base64
        
        -- Prepare metadata
        local metadata = {
            location_x = coords.x,
            location_y = coords.y,
            filter = currentFilter,
            timestamp = os.time()
        }
        
        if callback then
            callback(true, photoData, metadata)
        end
    end)
    
    return true
end

-- Capture and upload photo
function Camera.CaptureAndUpload()
    if isCapturing then
        if Config.DebugMode then
            print('[Phone] Already capturing photo')
        end
        return false
    end
    
    isCapturing = true
    
    -- Get player coordinates for metadata
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Apply filter effect temporarily
    if currentFilter ~= 'none' then
        Camera.ApplyFilterEffect(currentFilter)
    end
    
    -- Wait a frame for filter to apply
    Wait(100)
    
    -- Use RequestScreenshotFromPlayer native
    -- This creates a screenshot request that will be handled by the game
    CreateThread(function()
        -- Request screenshot
        -- Note: FiveM's screenshot functionality requires proper setup
        -- This is a simplified implementation
        
        local success = false
        local screenshotData = nil
        
        -- Try to capture screenshot using game native
        -- In production, you might use a screenshot resource like screenshot-basic
        if exports['screenshot-basic'] then
            exports['screenshot-basic']:requestScreenshotUpload(
                Config.MediaStorage.uploadEndpoint or 'http://localhost/upload',
                'files[]',
                function(data)
                    if data then
                        screenshotData = data
                        success = true
                    end
                end
            )
            
            -- Wait for screenshot to complete (max 5 seconds)
            local timeout = 0
            while not success and timeout < 50 do
                Wait(100)
                timeout = timeout + 1
            end
        else
            -- Fallback: simulate screenshot capture
            -- In production, implement proper screenshot handling
            Wait(500)
            screenshotData = 'data:image/jpeg;base64,/9j/4AAQSkZJRg...' -- Placeholder
            success = true
        end
        
        -- Clear filter effects
        Camera.ClearFilterEffects()
        isCapturing = false
        
        if success and screenshotData then
            -- Prepare metadata
            local metadata = {
                location_x = coords.x,
                location_y = coords.y,
                filter = currentFilter,
                timestamp = os.time()
            }
            
            -- Send to server for processing and storage
            TriggerServerEvent('phone:server:uploadPhoto', screenshotData, metadata)
            
            if Config.DebugMode then
                print('[Phone] Photo captured and sent to server')
            end
        else
            -- Notify user of failure
            SendNUIMessage({
                action = 'notify',
                data = {
                    type = 'error',
                    message = 'Failed to capture photo'
                }
            })
            
            if Config.DebugMode then
                print('[Phone] Failed to capture photo')
            end
        end
    end)
    
    return true
end

-- Enable flash effect
function Camera.EnableFlash()
    if not Config.CameraApp or not Config.CameraApp.enableFlash then
        return false
    end
    
    -- Create flash effect
    CreateThread(function()
        -- White screen flash
        local scaleform = RequestScaleformMovie('MP_BIG_MESSAGE_FREEMODE')
        while not HasScaleformMovieLoaded(scaleform) do
            Wait(0)
        end
        
        -- Draw white screen for flash effect
        SetDrawOrigin(0.0, 0.0, 0.0, 0)
        DrawRect(0.5, 0.5, 1.0, 1.0, 255, 255, 255, 200)
        
        Wait(100)
        
        ClearDrawOrigin()
    end)
    
    return true
end

-- Check if camera is available
function Camera.IsAvailable()
    return not isCapturing
end

-- Get camera status
function Camera.GetStatus()
    return {
        isCapturing = isCapturing,
        currentFilter = currentFilter,
        flashEnabled = Config.CameraApp and Config.CameraApp.enableFlash or false,
        flipEnabled = Config.CameraApp and Config.CameraApp.enableCameraFlip or false
    }
end

-- Register NUI callbacks
RegisterNUICallback('capturePhoto', function(data, cb)
    if not Camera.IsAvailable() then
        cb({success = false, error = 'Camera busy'})
        return
    end
    
    -- Set filter if provided
    if data.filter then
        Camera.SetFilter(data.filter)
    end
    
    -- Enable flash if requested
    if data.flash then
        Camera.EnableFlash()
    end
    
    -- Capture photo
    Camera.CaptureAndUpload()
    
    cb({success = true})
end)

RegisterNUICallback('setFilter', function(data, cb)
    if data.filter then
        local success = Camera.SetFilter(data.filter)
        cb({success = success})
    else
        cb({success = false})
    end
end)

-- Client events
RegisterNetEvent('phone:client:photoUploaded', function(photoData)
    -- Notify NUI that photo was uploaded
    SendNUIMessage({
        action = 'photoUploaded',
        data = photoData
    })
end)

-- Initialize on resource start
CreateThread(function()
    Camera.Initialize()
end)

return Camera
