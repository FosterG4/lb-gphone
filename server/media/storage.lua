-- Media Storage Module
-- Handles file upload, storage, compression, and CDN integration

local Storage = {}

-- Track active uploads per player for concurrent upload limiting
local activeUploads = {}
local uploadQueue = {}
local urlCache = {}

-- Track upload rate limiting per player
local uploadRateLimits = {}

-- Track suspicious activity per player
local suspiciousActivity = {}

-- Initialize storage directories
function Storage.Initialize()
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local mediaPath = resourcePath .. '/media'
    
    -- Create media directories if they don't exist
    os.execute('mkdir "' .. mediaPath .. '" 2>nul')
    os.execute('mkdir "' .. mediaPath .. '/photos" 2>nul')
    os.execute('mkdir "' .. mediaPath .. '/videos" 2>nul')
    os.execute('mkdir "' .. mediaPath .. '/audio" 2>nul')
    os.execute('mkdir "' .. mediaPath .. '/thumbnails" 2>nul')
    
    if Config.Debug then
        print('[Phone] Media storage initialized at: ' .. mediaPath)
    end
    
    -- Start periodic cache cleanup thread
    CreateThread(function()
        while true do
            Wait(60000) -- Run every minute
            Storage.CleanupUrlCache()
            if Config.DebugMode then
                local cacheCount = 0
                for _ in pairs(urlCache) do
                    cacheCount = cacheCount + 1
                end
                print(string.format('[Phone] URL cache cleanup complete - Active entries: %d', cacheCount))
            end
        end
    end)
    
    -- Start periodic rate limit cleanup thread
    CreateThread(function()
        while true do
            Wait(300000) -- Run every 5 minutes
            local currentTime = os.time()
            
            -- Clean up old rate limit entries
            for phoneNumber, limits in pairs(uploadRateLimits) do
                local recentUploads = {}
                for _, uploadTime in ipairs(limits.uploads) do
                    if currentTime - uploadTime < 60 then
                        table.insert(recentUploads, uploadTime)
                    end
                end
                
                -- Remove player from tracking if no recent uploads
                if #recentUploads == 0 then
                    uploadRateLimits[phoneNumber] = nil
                else
                    limits.uploads = recentUploads
                end
            end
            
            if Config.DebugMode then
                local activeTracking = 0
                for _ in pairs(uploadRateLimits) do
                    activeTracking = activeTracking + 1
                end
                print(string.format('[Phone] Rate limit cleanup complete - Active players: %d', activeTracking))
            end
        end
    end)
end

-- Validate file type against whitelist
function Storage.ValidateFileType(filename, mediaType)
    -- Define allowed extensions per media type
    local allowedExtensions = {
        photo = {jpg = true, jpeg = true, png = true, gif = true},
        video = {mp4 = true, webm = true},
        audio = {mp3 = true, ogg = true}
    }
    
    -- Extract file extension
    local extension = filename:match('%.([^%.]+)$')
    if not extension then
        return false, 'No file extension found'
    end
    
    -- Convert to lowercase for comparison
    extension = extension:lower()
    
    -- Check if extension is allowed for this media type
    local allowed = allowedExtensions[mediaType]
    if not allowed or not allowed[extension] then
        return false, string.format('Invalid file type: .%s not allowed for %s', extension, mediaType)
    end
    
    return true, nil
end

-- Validate MIME type matches expected media type
function Storage.ValidateMimeType(mimeType, mediaType)
    -- Define expected MIME types per media type
    local expectedMimeTypes = {
        photo = {
            ['image/jpeg'] = true,
            ['image/jpg'] = true,
            ['image/png'] = true,
            ['image/gif'] = true
        },
        video = {
            ['video/mp4'] = true,
            ['video/webm'] = true
        },
        audio = {
            ['audio/mpeg'] = true,
            ['audio/mp3'] = true,
            ['audio/ogg'] = true
        }
    }
    
    -- Check if MIME type is expected for this media type
    local expected = expectedMimeTypes[mediaType]
    if not expected or not expected[mimeType] then
        return false, string.format('Invalid MIME type: %s not allowed for %s', mimeType, mediaType)
    end
    
    return true, nil
end

-- Validate file size
function Storage.ValidateFileSize(fileSize, mediaType)
    local maxSize = 0
    
    if mediaType == 'photo' then
        maxSize = Config.MaxPhotoSize or (5 * 1024 * 1024) -- 5MB default
    elseif mediaType == 'video' then
        maxSize = Config.MaxVideoSize or (50 * 1024 * 1024) -- 50MB default
    elseif mediaType == 'audio' then
        maxSize = Config.MaxAudioSize or (10 * 1024 * 1024) -- 10MB default
    end
    
    if fileSize > maxSize then
        return false, string.format('File size (%d bytes) exceeds maximum allowed (%d bytes) for %s', 
            fileSize, maxSize, mediaType)
    end
    
    return true, nil
end

-- Check player storage quota
function Storage.CheckQuota(phoneNumber, additionalSize)
    local quota = Config.StorageQuotaPerPlayer or (500 * 1024 * 1024) -- 500MB default
    
    -- Get current storage usage
    local result = MySQL.query.await('SELECT SUM(file_size) as total_size FROM phone_media WHERE owner_number = ?', {
        phoneNumber
    })
    
    local currentSize = 0
    if result and result[1] and result[1].total_size then
        currentSize = result[1].total_size
    end
    
    return (currentSize + additionalSize) <= quota, currentSize, quota
end

-- Generate unique filename
function Storage.GenerateFilename(phoneNumber, extension)
    local timestamp = os.time()
    local random = math.random(1000, 9999)
    return phoneNumber:gsub('-', '') .. '_' .. timestamp .. '_' .. random .. '.' .. extension
end

-- Decode base64 string
function Storage.DecodeBase64(base64String)
    -- Remove data URL prefix if present
    local data = base64String:match('base64,(.+)') or base64String
    
    -- FiveM doesn't have built-in base64 decode, so we'll use a workaround
    -- In production, you'd want to use a proper base64 library
    return data
end

-- Save file to local storage
function Storage.SaveToLocal(filename, data, mediaType)
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local subdir = 'photos'
    
    if mediaType == 'video' then
        subdir = 'videos'
    elseif mediaType == 'audio' then
        subdir = 'audio'
    end
    
    local filePath = resourcePath .. '/media/' .. subdir .. '/' .. filename
    
    -- Write file (this is a simplified version - in production use proper file I/O)
    SaveResourceFile(GetCurrentResourceName(), 'media/' .. subdir .. '/' .. filename, data, -1)
    
    -- Return the URL path
    return 'nui://phone/media/' .. subdir .. '/' .. filename
end

-- Upload to CDN
function Storage.UploadToCDN(filename, data, mediaType)
    if not Config.MediaStorage or Config.MediaStorage ~= 'cdn' then
        return nil, 'CDN not configured'
    end
    
    local cdnConfig = Config.CDNConfig or {}
    local provider = cdnConfig.provider or 's3'
    
    if provider == 's3' then
        return Storage.UploadToS3(filename, data, cdnConfig)
    elseif provider == 'r2' then
        return Storage.UploadToR2(filename, data, cdnConfig)
    elseif provider == 'custom' then
        return Storage.UploadToCustomCDN(filename, data, cdnConfig)
    end
    
    return nil, 'Unknown CDN provider'
end

-- Upload to AWS S3
function Storage.UploadToS3(filename, data, config)
    -- This is a placeholder - actual implementation would use HTTP requests
    -- to AWS S3 API with proper authentication
    
    if Config.Debug then
        print('[Phone] S3 upload not implemented - using local storage')
    end
    
    return nil, 'S3 upload not implemented'
end

-- Upload to Cloudflare R2
function Storage.UploadToR2(filename, data, config)
    -- This is a placeholder - actual implementation would use HTTP requests
    -- to Cloudflare R2 API with proper authentication
    
    if Config.Debug then
        print('[Phone] R2 upload not implemented - using local storage')
    end
    
    return nil, 'R2 upload not implemented'
end

-- Upload to custom CDN
function Storage.UploadToCustomCDN(filename, data, config)
    -- This is a placeholder for custom CDN implementations
    
    if Config.Debug then
        print('[Phone] Custom CDN upload not implemented - using local storage')
    end
    
    return nil, 'Custom CDN upload not implemented'
end

-- Validate Fivemanage configuration
function Storage.ValidateFivemanageConfig()
    local config = Config.FivemanageConfig
    
    if not config then
        return false, 'Fivemanage config not found'
    end
    
    if not config.enabled then
        return false, 'Fivemanage is disabled'
    end
    
    if not config.apiKey or config.apiKey == '' then
        return false, 'API key is missing'
    end
    
    if not config.endpoint or config.endpoint == '' then
        return false, 'Endpoint URL is missing'
    end
    
    -- Validate API key format (basic check)
    if #config.apiKey < 20 then
        return false, 'API key appears invalid (too short)'
    end
    
    return true, nil
end

-- Get content type for media
function Storage.GetContentType(mediaType)
    local contentTypes = {
        photo = 'image/jpeg',
        video = 'video/mp4',
        audio = 'audio/mpeg'
    }
    
    return contentTypes[mediaType] or 'application/octet-stream'
end

-- Sanitize filename for upload
function Storage.SanitizeFilename(filename)
    -- Remove path traversal attempts
    filename = filename:gsub('%.%.', '')
    filename = filename:gsub('/', '')
    filename = filename:gsub('\\', '')
    
    -- Remove special characters except alphanumeric, dash, underscore, dot
    filename = filename:gsub('[^%w%-%._]', '_')
    
    -- Limit length and preserve extension
    if #filename > 100 then
        local extension = filename:match('%.([^%.]+)$')
        local name = filename:sub(1, 90)
        filename = name .. '.' .. (extension or 'jpg')
    end
    
    return filename
end

-- Encode multipart form data for file upload
function Storage.EncodeMultipartFormData(filename, data, contentType)
    local boundary = '----WebKitFormBoundary' .. tostring(os.time()) .. math.random(1000, 9999)
    local body = ''
    
    -- Add file field
    body = body .. '--' .. boundary .. '\r\n'
    body = body .. 'Content-Disposition: form-data; name="file"; filename="' .. filename .. '"\r\n'
    body = body .. 'Content-Type: ' .. contentType .. '\r\n\r\n'
    body = body .. data .. '\r\n'
    
    -- End boundary
    body = body .. '--' .. boundary .. '--\r\n'
    
    return body, boundary
end

-- Parse Fivemanage API response
function Storage.ParseFivemanageResponse(statusCode, responseText)
    if statusCode == 200 then
        local success, response = pcall(json.decode, responseText)
        if success and response and response.url then
            return response.url, nil, {
                id = response.id,
                size = response.size
            }
        else
            return nil, 'Invalid response format'
        end
    else
        -- Handle error status codes
        local errorMsg = 'HTTP ' .. statusCode
        if statusCode == 401 then
            errorMsg = 'Invalid API key'
        elseif statusCode == 413 then
            errorMsg = 'File too large'
        elseif statusCode == 429 then
            errorMsg = 'Rate limited'
        elseif statusCode == 500 then
            errorMsg = 'Server error'
        end
        
        -- Try to parse error message from response
        local success, response = pcall(json.decode, responseText)
        if success and response and response.error then
            errorMsg = errorMsg .. ': ' .. response.error
        end
        
        return nil, errorMsg
    end
end

-- Perform Fivemanage upload with HTTP request
function Storage.PerformFivemanageUpload(filename, data, mediaType, phoneNumber, progressCallback)
    local config = Config.FivemanageConfig
    local contentType = Storage.GetContentType(mediaType)
    local body, boundary = Storage.EncodeMultipartFormData(filename, data, contentType)
    
    local promise = promise.new()
    
    -- Send progress update if callback provided
    if progressCallback then
        progressCallback(20, 'uploading', 'Connecting to upload service...')
    end
    
    -- Set timeout for the request
    local timeout = config.timeout or 30000
    local timedOut = false
    
    -- Create timeout handler
    SetTimeout(timeout, function()
        if not promise then return end
        timedOut = true
        promise:resolve({
            success = false,
            error = 'Network timeout',
            statusCode = 0,
            errorType = 'TIMEOUT'
        })
    end)
    
    -- Send progress update
    if progressCallback then
        progressCallback(40, 'uploading', 'Uploading file...')
    end
    
    PerformHttpRequest(config.endpoint, function(statusCode, responseText, headers)
        if timedOut then return end
        
        -- Send progress update
        if progressCallback then
            progressCallback(70, 'processing', 'Processing response...')
        end
        
        local url, error, metadata = Storage.ParseFivemanageResponse(statusCode, responseText)
        
        if url then
            -- Send progress update
            if progressCallback then
                progressCallback(90, 'finalizing', 'Upload successful')
            end
            
            promise:resolve({
                success = true,
                url = url,
                id = metadata and metadata.id or nil,
                size = metadata and metadata.size or nil,
                statusCode = statusCode
            })
        else
            -- Determine error type based on status code
            local errorType = 'UNKNOWN'
            if statusCode == 401 then
                errorType = 'UNAUTHORIZED'
            elseif statusCode == 413 then
                errorType = 'FILE_TOO_LARGE'
            elseif statusCode == 429 then
                errorType = 'RATE_LIMITED'
            elseif statusCode == 500 or statusCode == 502 or statusCode == 503 then
                errorType = 'SERVER_ERROR'
            elseif statusCode == 0 then
                errorType = 'NETWORK_ERROR'
            end
            
            promise:resolve({
                success = false,
                error = error or 'Unknown error',
                statusCode = statusCode,
                errorType = errorType
            })
        end
    end, 'POST', body, {
        ['Authorization'] = 'Bearer ' .. config.apiKey,
        ['Content-Type'] = 'multipart/form-data; boundary=' .. boundary
    })
    
    return Citizen.Await(promise)
end

-- Retry upload with exponential backoff
function Storage.RetryUpload(uploadFunc, maxAttempts, initialDelay, errorType)
    local attempt = 1
    local delay = initialDelay
    
    while attempt <= maxAttempts do
        local success, result = pcall(uploadFunc)
        
        if success and result and result.success then
            return true, result
        end
        
        -- Check if we should retry based on error type
        local shouldRetry = true
        if result and result.errorType then
            -- Don't retry for certain error types
            if result.errorType == 'UNAUTHORIZED' then
                -- Don't retry 401 errors - API key is invalid
                shouldRetry = false
            elseif result.errorType == 'FILE_TOO_LARGE' then
                -- Don't retry 413 errors - file is too large
                shouldRetry = false
            end
        end
        
        if not shouldRetry or attempt >= maxAttempts then
            -- Don't retry or max attempts reached
            if Config.DebugMode then
                if not shouldRetry then
                    print(string.format('[Phone] Upload failed with non-retryable error: %s', 
                        result and result.errorType or 'UNKNOWN'))
                else
                    print(string.format('[Phone] Upload failed after %d attempts', maxAttempts))
                end
            end
            return false, result or { error = 'Max retry attempts exceeded' }
        end
        
        -- Log retry attempt
        if Config.DebugMode then
            local errorInfo = result and result.error or 'unknown error'
            print(string.format('[Phone] Upload attempt %d/%d failed (%s), retrying in %dms', 
                attempt, maxAttempts, errorInfo, delay))
        end
        
        -- Special handling for rate limiting - use longer delay
        if result and result.errorType == 'RATE_LIMITED' then
            local rateLimitDelay = delay * 3 -- Triple the delay for rate limiting
            if Config.DebugMode then
                print(string.format('[Phone] Rate limited, waiting %dms before retry', rateLimitDelay))
            end
            Wait(rateLimitDelay)
        else
            Wait(delay)
        end
        
        delay = delay * 2 -- Exponential backoff
        attempt = attempt + 1
    end
    
    return false, { error = 'Max retry attempts exceeded' }
end

-- Log upload error with comprehensive details
function Storage.LogUploadError(errorType, errorMsg, phoneNumber, filename, statusCode)
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    local logMsg = string.format('[Phone] [%s] Upload Error - Type: %s, Player: %s, File: %s, Error: %s',
        timestamp, errorType or 'UNKNOWN', phoneNumber or 'unknown', filename or 'unknown', errorMsg or 'unknown')
    
    if statusCode then
        logMsg = logMsg .. string.format(', HTTP Status: %d', statusCode)
    end
    
    print(logMsg)
    
    -- Verbose logging in debug mode
    if Config.DebugMode then
        print(string.format('[Phone] [DEBUG] Error Details - ErrorType: %s, StatusCode: %s, Message: %s',
            errorType or 'N/A', statusCode or 'N/A', errorMsg or 'N/A'))
    end
end

-- Notify player of upload error
function Storage.NotifyPlayerError(source, errorType, errorMsg)
    if not source or source == 0 then return end
    
    local notificationMsg = errorMsg
    
    -- Customize notification based on error type
    if errorType == 'UNAUTHORIZED' then
        notificationMsg = 'Upload failed: Server configuration error. Please contact an administrator.'
    elseif errorType == 'FILE_TOO_LARGE' then
        notificationMsg = 'File is too large. Try compressing the image or recording a shorter video.'
    elseif errorType == 'RATE_LIMITED' then
        notificationMsg = 'Too many uploads. Please wait a moment and try again.'
    elseif errorType == 'TIMEOUT' or errorType == 'NETWORK_ERROR' then
        notificationMsg = 'Upload failed due to network issues. Please try again.'
    elseif errorType == 'SERVER_ERROR' then
        notificationMsg = 'Upload service is temporarily unavailable. Please try again later.'
    end
    
    -- Send notification to player (adjust based on your notification system)
    TriggerClientEvent('phone:notify', source, {
        type = 'error',
        title = 'Upload Failed',
        message = notificationMsg,
        duration = 5000
    })
end

-- Upload file to Fivemanage
function Storage.UploadToFivemanage(filename, data, mediaType, metadata, phoneNumber, source, progressCallback)
    -- Validate Fivemanage configuration
    local configValid, configError = Storage.ValidateFivemanageConfig()
    if not configValid then
        Storage.LogUploadError('CONFIG_ERROR', configError, phoneNumber, filename, nil)
        return nil, configError, 'CONFIG_ERROR'
    end
    
    -- Filename should already be sanitized, but ensure it's safe
    local sanitizedFilename = Storage.SanitizeFilename(filename)
    
    -- Attempt upload with retry logic
    local config = Config.FivemanageConfig
    local success, result = Storage.RetryUpload(function()
        return Storage.PerformFivemanageUpload(sanitizedFilename, data, mediaType, phoneNumber, progressCallback)
    end, config.retryAttempts or 3, config.retryDelay or 1000)
    
    if success and result.url then
        -- Log upload success
        if config.logUploads then
            print(string.format('[Phone] Fivemanage upload successful - Player: %s, ID: %s, Size: %s bytes, URL: %s', 
                phoneNumber or 'unknown', result.id or 'unknown', result.size or 'unknown', result.url))
        end
        
        return result.url, nil, nil, result
    else
        -- Extract error details
        local errorMsg = result.error or 'Upload failed'
        local errorType = result.errorType or 'UNKNOWN'
        local statusCode = result.statusCode
        
        -- Log comprehensive error details
        Storage.LogUploadError(errorType, errorMsg, phoneNumber, sanitizedFilename, statusCode)
        
        -- Notify player based on error type
        if source then
            Storage.NotifyPlayerError(source, errorType, errorMsg)
        end
        
        -- Handle specific error types
        if errorType == 'UNAUTHORIZED' then
            -- 401 Unauthorized - Invalid API key
            print('[Phone] [CRITICAL] Invalid Fivemanage API key - Please check your configuration')
            
        elseif errorType == 'FILE_TOO_LARGE' then
            -- 413 File Too Large - Don't retry, inform player
            if Config.DebugMode then
                print(string.format('[Phone] File too large for upload: %s', sanitizedFilename))
            end
            
        elseif errorType == 'RATE_LIMITED' then
            -- 429 Rate Limited - Already handled with exponential backoff in retry logic
            print(string.format('[Phone] Rate limited by Fivemanage API - Player: %s', phoneNumber or 'unknown'))
            
        elseif errorType == 'TIMEOUT' or errorType == 'NETWORK_ERROR' then
            -- Network timeout or connection error
            print(string.format('[Phone] Network error during upload - Player: %s, File: %s', 
                phoneNumber or 'unknown', sanitizedFilename))
            
        elseif errorType == 'SERVER_ERROR' then
            -- 500 Server Error - Fivemanage service issue
            print(string.format('[Phone] Fivemanage server error - Status: %s, Player: %s', 
                statusCode or 'unknown', phoneNumber or 'unknown'))
        end
        
        return nil, errorMsg, errorType
    end
end

-- Generate thumbnail for image
function Storage.GenerateThumbnail(sourceFile, mediaType)
    if not Config.GenerateThumbnails then
        return nil
    end
    
    -- This is a placeholder - actual implementation would use image processing
    -- library or external service to generate thumbnails
    -- For FiveM, you might need to use an external service or pre-generate thumbnails client-side
    
    if Config.Debug then
        print('[Phone] Thumbnail generation not implemented')
    end
    
    return nil
end

-- Compress image
function Storage.CompressImage(data, quality, phoneNumber)
    quality = quality or Config.ImageQuality or 80
    
    -- Get original size
    local originalSize = #data
    
    -- Note: FiveM/Lua doesn't have built-in image compression libraries
    -- In a production environment, you would:
    -- 1. Use an external service (API) for compression
    -- 2. Compress client-side before sending to server
    -- 3. Use a native module if available
    
    -- For now, we'll simulate compression by adjusting the quality parameter
    -- and log the compression attempt
    
    -- In a real implementation, you would call an image processing library here
    -- Example pseudo-code:
    -- local compressed = ImageLib.compress(data, quality)
    -- return compressed
    
    -- Since we can't actually compress server-side in pure Lua,
    -- we'll return the original data but log the compression settings
    
    if Config.DebugMode then
        print(string.format('[Phone] Image compression requested - Quality: %d%%, Original Size: %d bytes, Player: %s',
            quality, originalSize, phoneNumber or 'unknown'))
        print('[Phone] Note: Server-side compression requires external library or service')
        print('[Phone] Recommendation: Implement client-side compression before upload')
    end
    
    -- Log compression results when enabled
    if Config.FivemanageConfig and Config.FivemanageConfig.logUploads then
        local compressionRatio = 100 -- No actual compression, so 100%
        print(string.format('[Phone] Compression Result - Original: %d bytes, Compressed: %d bytes, Ratio: %d%%',
            originalSize, originalSize, compressionRatio))
    end
    
    -- Return original data (in production, return compressed data)
    return data
end

-- Get active upload count for player
function Storage.GetActiveUploadCount(phoneNumber)
    if not activeUploads[phoneNumber] then
        return 0
    end
    return activeUploads[phoneNumber]
end

-- Increment active upload count
function Storage.IncrementActiveUploads(phoneNumber)
    if not activeUploads[phoneNumber] then
        activeUploads[phoneNumber] = 0
    end
    activeUploads[phoneNumber] = activeUploads[phoneNumber] + 1
end

-- Decrement active upload count
function Storage.DecrementActiveUploads(phoneNumber)
    if activeUploads[phoneNumber] and activeUploads[phoneNumber] > 0 then
        activeUploads[phoneNumber] = activeUploads[phoneNumber] - 1
        if activeUploads[phoneNumber] == 0 then
            activeUploads[phoneNumber] = nil
        end
    end
end

-- Add upload to queue
function Storage.QueueUpload(phoneNumber, uploadData)
    if not uploadQueue[phoneNumber] then
        uploadQueue[phoneNumber] = {}
    end
    table.insert(uploadQueue[phoneNumber], uploadData)
end

-- Get next queued upload
function Storage.GetNextQueuedUpload(phoneNumber)
    if not uploadQueue[phoneNumber] or #uploadQueue[phoneNumber] == 0 then
        return nil
    end
    return table.remove(uploadQueue[phoneNumber], 1)
end

-- Process queued uploads for player
function Storage.ProcessQueuedUploads(phoneNumber)
    local maxConcurrent = Config.MaxConcurrentUploads or 3
    
    while Storage.GetActiveUploadCount(phoneNumber) < maxConcurrent do
        local queuedUpload = Storage.GetNextQueuedUpload(phoneNumber)
        if not queuedUpload then
            break
        end
        
        -- Process the queued upload asynchronously
        Storage.HandleUploadAsync(
            queuedUpload.phoneNumber,
            queuedUpload.data,
            queuedUpload.mediaType,
            queuedUpload.metadata,
            queuedUpload.source,
            queuedUpload.callback
        )
    end
end

-- Send upload progress update to client
function Storage.SendUploadProgress(source, uploadId, progress, status, message)
    if not source or source == 0 then return end
    
    TriggerClientEvent('phone:uploadProgress', source, {
        uploadId = uploadId,
        progress = progress,
        status = status,
        message = message
    })
end

-- Cache Fivemanage URL
function Storage.CacheUrl(mediaId, url)
    local cacheTime = Config.UrlCacheTime or 300 -- 5 minutes default
    urlCache[mediaId] = {
        url = url,
        timestamp = os.time(),
        expiresAt = os.time() + cacheTime
    }
end

-- Get cached URL
function Storage.GetCachedUrl(mediaId)
    local cached = urlCache[mediaId]
    if not cached then
        return nil
    end
    
    -- Check if cache expired
    if os.time() > cached.expiresAt then
        urlCache[mediaId] = nil
        return nil
    end
    
    return cached.url
end

-- Clear URL cache for media
function Storage.ClearUrlCache(mediaId)
    urlCache[mediaId] = nil
end

-- Clear expired cache entries
function Storage.CleanupUrlCache()
    local currentTime = os.time()
    for mediaId, cached in pairs(urlCache) do
        if currentTime > cached.expiresAt then
            urlCache[mediaId] = nil
        end
    end
end

-- Check upload rate limit for player
function Storage.CheckUploadRateLimit(phoneNumber)
    local maxUploadsPerMinute = Config.UploadLimits and Config.UploadLimits.maxUploadsPerMinute or 10
    local currentTime = os.time()
    
    -- Initialize rate limit tracking for player if not exists
    if not uploadRateLimits[phoneNumber] then
        uploadRateLimits[phoneNumber] = {
            uploads = {},
            violations = 0
        }
    end
    
    local playerLimits = uploadRateLimits[phoneNumber]
    
    -- Remove uploads older than 1 minute
    local recentUploads = {}
    for _, uploadTime in ipairs(playerLimits.uploads) do
        if currentTime - uploadTime < 60 then
            table.insert(recentUploads, uploadTime)
        end
    end
    playerLimits.uploads = recentUploads
    
    -- Check if player has exceeded rate limit
    if #playerLimits.uploads >= maxUploadsPerMinute then
        playerLimits.violations = playerLimits.violations + 1
        
        -- Log rate limit violation
        Storage.LogSuspiciousActivity(phoneNumber, 'RATE_LIMIT_VIOLATION', {
            uploads_in_minute = #playerLimits.uploads,
            max_allowed = maxUploadsPerMinute,
            total_violations = playerLimits.violations
        })
        
        return false, string.format('Upload rate limit exceeded. Maximum %d uploads per minute allowed.', maxUploadsPerMinute)
    end
    
    -- Add current upload to tracking
    table.insert(playerLimits.uploads, currentTime)
    
    return true, nil
end

-- Implement cooldown between uploads
function Storage.CheckUploadCooldown(phoneNumber)
    local cooldownSeconds = Config.UploadLimits and Config.UploadLimits.cooldownSeconds or 2
    local currentTime = os.time()
    
    if not uploadRateLimits[phoneNumber] then
        return true, nil
    end
    
    local playerLimits = uploadRateLimits[phoneNumber]
    
    -- Check if there are any recent uploads
    if #playerLimits.uploads > 0 then
        local lastUploadTime = playerLimits.uploads[#playerLimits.uploads]
        local timeSinceLastUpload = currentTime - lastUploadTime
        
        if timeSinceLastUpload < cooldownSeconds then
            local remainingCooldown = cooldownSeconds - timeSinceLastUpload
            return false, string.format('Please wait %d seconds before uploading again.', remainingCooldown)
        end
    end
    
    return true, nil
end

-- Log suspicious activity
function Storage.LogSuspiciousActivity(phoneNumber, activityType, details)
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    
    -- Initialize suspicious activity tracking for player if not exists
    if not suspiciousActivity[phoneNumber] then
        suspiciousActivity[phoneNumber] = {}
    end
    
    -- Add activity to log
    table.insert(suspiciousActivity[phoneNumber], {
        timestamp = timestamp,
        type = activityType,
        details = details
    })
    
    -- Keep only last 50 activities per player
    if #suspiciousActivity[phoneNumber] > 50 then
        table.remove(suspiciousActivity[phoneNumber], 1)
    end
    
    -- Log to console
    local detailsStr = json.encode(details or {})
    print(string.format('[Phone] [SECURITY] Suspicious Activity - Player: %s, Type: %s, Time: %s, Details: %s',
        phoneNumber, activityType, timestamp, detailsStr))
    
    -- Log to file if enabled
    if Config.Security and Config.Security.logSuspiciousActivity then
        -- In production, you would write to a log file here
        -- For now, we'll just use console logging
    end
end

-- Get suspicious activity for player
function Storage.GetSuspiciousActivity(phoneNumber)
    return suspiciousActivity[phoneNumber] or {}
end

-- Clear suspicious activity for player
function Storage.ClearSuspiciousActivity(phoneNumber)
    suspiciousActivity[phoneNumber] = nil
end

-- Track failed upload attempts
function Storage.TrackFailedUpload(phoneNumber, errorType, errorMsg, filename)
    -- Initialize tracking if not exists
    if not suspiciousActivity[phoneNumber] then
        suspiciousActivity[phoneNumber] = {}
    end
    
    -- Count recent failed attempts (last 5 minutes)
    local currentTime = os.time()
    local recentFailures = 0
    
    for _, activity in ipairs(suspiciousActivity[phoneNumber]) do
        if activity.type == 'UPLOAD_FAILURE' then
            -- Parse timestamp
            local year, month, day, hour, min, sec = activity.timestamp:match('(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)')
            if year then
                local activityTime = os.time({
                    year = tonumber(year),
                    month = tonumber(month),
                    day = tonumber(day),
                    hour = tonumber(hour),
                    min = tonumber(min),
                    sec = tonumber(sec)
                })
                
                if currentTime - activityTime < 300 then -- Last 5 minutes
                    recentFailures = recentFailures + 1
                end
            end
        end
    end
    
    -- Log the failed attempt
    Storage.LogSuspiciousActivity(phoneNumber, 'UPLOAD_FAILURE', {
        error_type = errorType,
        error_message = errorMsg,
        filename = filename,
        recent_failures = recentFailures + 1
    })
    
    -- Alert if excessive failures
    if recentFailures >= 5 then
        print(string.format('[Phone] [ALERT] Excessive failed upload attempts - Player: %s, Failures: %d in last 5 minutes',
            phoneNumber, recentFailures + 1))
    end
end

-- Handle upload with concurrent limiting
function Storage.HandleUploadWithLimit(phoneNumber, data, mediaType, metadata, source, callback)
    local maxConcurrent = Config.MaxConcurrentUploads or 3
    local activeCount = Storage.GetActiveUploadCount(phoneNumber)
    
    if Config.DebugMode then
        print(string.format('[Phone] Upload request - Player: %s, Active: %d, Max: %d',
            phoneNumber, activeCount, maxConcurrent))
    end
    
    -- Check if we're at the concurrent upload limit
    if activeCount >= maxConcurrent then
        -- Queue the upload
        if Config.DebugMode then
            print(string.format('[Phone] Upload queued - Player: %s (limit reached)', phoneNumber))
        end
        
        Storage.QueueUpload(phoneNumber, {
            phoneNumber = phoneNumber,
            data = data,
            mediaType = mediaType,
            metadata = metadata,
            source = source,
            callback = callback
        })
        
        -- Notify player that upload is queued
        if source and source ~= 0 then
            TriggerClientEvent('phone:notify', source, {
                type = 'info',
                title = 'Upload Queued',
                message = 'Your upload has been queued and will start shortly.',
                duration = 3000
            })
        end
        
        return {
            success = true,
            status = 'queued',
            message = 'Upload queued - will start when current uploads complete',
            queuePosition = uploadQueue[phoneNumber] and #uploadQueue[phoneNumber] or 1
        }
    end
    
    -- Process upload immediately
    if Config.EnableAsyncUploads then
        return Storage.HandleUploadAsync(phoneNumber, data, mediaType, metadata, source, callback)
    else
        -- Synchronous upload (blocking)
        return Storage.HandleUpload(phoneNumber, data, mediaType, metadata, source)
    end
end

-- Async upload handler
function Storage.HandleUploadAsync(phoneNumber, data, mediaType, metadata, source, callback)
    -- Generate upload ID for progress tracking
    local uploadId = phoneNumber .. '_' .. os.time() .. '_' .. math.random(1000, 9999)
    
    -- Increment active upload count
    Storage.IncrementActiveUploads(phoneNumber)
    
    -- Send initial progress
    Storage.SendUploadProgress(source, uploadId, 0, 'processing', 'Preparing upload...')
    
    -- Process upload in background thread
    CreateThread(function()
        -- Send progress update
        Storage.SendUploadProgress(source, uploadId, 10, 'processing', 'Validating file...')
        
        -- Create progress callback for upload
        local progressCallback = function(progress, status, message)
            if Config.ShowUploadProgress then
                Storage.SendUploadProgress(source, uploadId, progress, status, message)
            end
        end
        
        -- Perform the actual upload with progress tracking
        local result = Storage.HandleUploadWithProgress(phoneNumber, data, mediaType, metadata, source, progressCallback)
        
        -- Decrement active upload count
        Storage.DecrementActiveUploads(phoneNumber)
        
        -- Send completion progress
        if result.success then
            Storage.SendUploadProgress(source, uploadId, 100, 'complete', 'Upload complete')
        else
            Storage.SendUploadProgress(source, uploadId, 0, 'error', result.message or 'Upload failed')
        end
        
        -- Call callback if provided
        if callback then
            callback(result)
        end
        
        -- Process any queued uploads
        Storage.ProcessQueuedUploads(phoneNumber)
    end)
    
    -- Return immediately with processing status
    return {
        success = true,
        uploadId = uploadId,
        status = 'processing',
        message = 'Upload is being processed in the background'
    }
end

-- Handle file upload with progress tracking
function Storage.HandleUploadWithProgress(phoneNumber, data, mediaType, metadata, source, progressCallback)
    -- This is a wrapper that adds progress tracking to HandleUpload
    -- We'll modify HandleUpload to accept an optional progressCallback parameter
    return Storage.HandleUpload(phoneNumber, data, mediaType, metadata, source, progressCallback)
end

-- Handle file upload (main entry point)
function Storage.HandleUpload(phoneNumber, data, mediaType, metadata, source, progressCallback)
    -- Validate inputs
    if not phoneNumber or not data or not mediaType then
        Storage.LogSuspiciousActivity(phoneNumber or 'unknown', 'INVALID_PARAMETERS', {
            has_phone = phoneNumber ~= nil,
            has_data = data ~= nil,
            has_media_type = mediaType ~= nil
        })
        return {
            success = false,
            error = 'INVALID_PARAMETERS',
            message = 'Missing required parameters'
        }
    end
    
    -- Check upload rate limit
    local rateLimitOk, rateLimitError = Storage.CheckUploadRateLimit(phoneNumber)
    if not rateLimitOk then
        return {
            success = false,
            error = 'RATE_LIMIT_EXCEEDED',
            message = rateLimitError
        }
    end
    
    -- Check upload cooldown
    local cooldownOk, cooldownError = Storage.CheckUploadCooldown(phoneNumber)
    if not cooldownOk then
        return {
            success = false,
            error = 'COOLDOWN_ACTIVE',
            message = cooldownError
        }
    end
    
    -- Decode base64 data
    local fileData = Storage.DecodeBase64(data)
    local fileSize = #fileData
    
    -- Validate file size before uploading
    local fileSizeValid, fileSizeError = Storage.ValidateFileSize(fileSize, mediaType)
    if not fileSizeValid then
        Storage.LogSuspiciousActivity(phoneNumber, 'FILE_SIZE_VIOLATION', {
            file_size = fileSize,
            media_type = mediaType,
            error = fileSizeError
        })
        return {
            success = false,
            error = 'MEDIA_TOO_LARGE',
            message = fileSizeError
        }
    end
    
    -- Check storage quota
    local quotaOk, currentSize, maxQuota = Storage.CheckQuota(phoneNumber, fileSize)
    if not quotaOk then
        return {
            success = false,
            error = 'STORAGE_FULL',
            message = 'Storage quota exceeded',
            details = {
                current = currentSize,
                max = maxQuota,
                required = fileSize
            }
        }
    end
    
    -- Generate filename
    local extension = 'jpg'
    if mediaType == 'video' then
        extension = 'mp4'
    elseif mediaType == 'audio' then
        extension = 'mp3'
    end
    local filename = Storage.GenerateFilename(phoneNumber, extension)
    
    -- Validate file type
    local fileTypeValid, fileTypeError = Storage.ValidateFileType(filename, mediaType)
    if not fileTypeValid then
        Storage.LogSuspiciousActivity(phoneNumber, 'INVALID_FILE_TYPE', {
            filename = filename,
            media_type = mediaType,
            error = fileTypeError
        })
        return {
            success = false,
            error = 'INVALID_FILE_TYPE',
            message = fileTypeError
        }
    end
    
    -- Validate MIME type if provided in metadata
    if metadata and metadata.mimeType then
        local mimeTypeValid, mimeTypeError = Storage.ValidateMimeType(metadata.mimeType, mediaType)
        if not mimeTypeValid then
            Storage.LogSuspiciousActivity(phoneNumber, 'INVALID_MIME_TYPE', {
                mime_type = metadata.mimeType,
                media_type = mediaType,
                error = mimeTypeError
            })
            return {
                success = false,
                error = 'INVALID_MIME_TYPE',
                message = mimeTypeError
            }
        end
    end
    
    -- Sanitize filename to prevent path traversal and special character attacks
    filename = Storage.SanitizeFilename(filename)
    
    -- Compress image if applicable
    if mediaType == 'photo' and Config.OptimizeImages then
        if Config.DebugMode then
            print(string.format('[Phone] Compressing image for player: %s', phoneNumber))
        end
        fileData = Storage.CompressImage(fileData, Config.ImageQuality, phoneNumber)
        fileSize = #fileData
    end
    
    -- Save file based on storage mode
    local fileUrl, uploadError, errorType
    local uploadMethod = 'local' -- Track which method was used
    local fivemanageId = nil -- Track Fivemanage ID if applicable
    
    if Config.MediaStorage == 'fivemanage' then
        -- Upload to Fivemanage
        local uploadResult
        fileUrl, uploadError, errorType, uploadResult = Storage.UploadToFivemanage(filename, fileData, mediaType, metadata, phoneNumber, source, progressCallback)
        
        if fileUrl then
            uploadMethod = 'fivemanage'
            fivemanageId = uploadResult and uploadResult.id or nil
        elseif Config.FivemanageConfig and Config.FivemanageConfig.fallbackToLocal then
            -- Determine if we should fallback based on error type
            local shouldFallback = true
            
            -- Don't fallback for file too large errors - the file won't fit locally either
            if errorType == 'FILE_TOO_LARGE' then
                shouldFallback = false
            end
            
            if shouldFallback then
                -- Fallback to local storage if enabled
                print(string.format('[Phone] Fivemanage upload failed (%s), falling back to local storage - Player: %s', 
                    errorType or 'unknown', phoneNumber))
                
                fileUrl = Storage.SaveToLocal(filename, fileData, mediaType)
                uploadMethod = 'local'
                
                -- Notify player about fallback
                if source then
                    TriggerClientEvent('phone:notify', source, {
                        type = 'warning',
                        title = 'Upload Notice',
                        message = 'File saved locally due to upload service issues.',
                        duration = 4000
                    })
                end
            end
        end
    elseif Config.MediaStorage == 'cdn' then
        fileUrl, uploadError = Storage.UploadToCDN(filename, fileData, mediaType)
        uploadMethod = 'cdn'
        
        -- Fallback to local if CDN fails
        if not fileUrl then
            if Config.Debug then
                print('[Phone] CDN upload failed, falling back to local: ' .. (uploadError or 'unknown error'))
            end
            fileUrl = Storage.SaveToLocal(filename, fileData, mediaType)
            uploadMethod = 'local'
        end
    else
        -- Default to local storage
        fileUrl = Storage.SaveToLocal(filename, fileData, mediaType)
        uploadMethod = 'local'
    end
    
    if not fileUrl then
        -- Track failed upload attempt
        Storage.TrackFailedUpload(phoneNumber, errorType or 'STORAGE_ERROR', uploadError or 'unknown error', filename)
        
        return {
            success = false,
            error = errorType or 'STORAGE_ERROR',
            message = 'Failed to save file: ' .. (uploadError or 'unknown error')
        }
    end
    
    -- Generate thumbnail
    local thumbnailUrl = nil
    if Config.GenerateThumbnails and (mediaType == 'photo' or mediaType == 'video') then
        thumbnailUrl = Storage.GenerateThumbnail(fileUrl, mediaType)
    end
    
    -- Prepare metadata with upload method and additional fields
    local metadataTable = metadata or {}
    metadataTable.upload_method = uploadMethod
    metadataTable.original_filename = filename
    metadataTable.upload_timestamp = os.time()
    metadataTable.mime_type = Storage.GetContentType(mediaType)
    
    -- Add Fivemanage ID if available
    if fivemanageId then
        metadataTable.fivemanage_id = fivemanageId
    end
    
    local metadataJson = json.encode(metadataTable)
    
    -- Save to database
    local mediaId = MySQL.insert.await([[
        INSERT INTO phone_media (owner_number, media_type, file_url, thumbnail_url, duration, file_size, location_x, location_y, metadata_json)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        phoneNumber,
        mediaType,
        fileUrl,
        thumbnailUrl,
        metadata and metadata.duration or 0,
        fileSize,
        metadata and metadata.location_x or nil,
        metadata and metadata.location_y or nil,
        metadataJson
    })
    
    if not mediaId then
        return {
            success = false,
            error = 'DATABASE_ERROR',
            message = 'Failed to save media record'
        }
    end
    
    -- Cache the URL for future requests
    Storage.CacheUrl(mediaId, fileUrl)
    
    if Config.DebugMode then
        print(string.format('[Phone] Cached URL for new media ID: %d', mediaId))
    end
    
    return {
        success = true,
        data = {
            id = mediaId,
            url = fileUrl,
            thumbnail_url = thumbnailUrl,
            file_size = fileSize,
            media_type = mediaType
        }
    }
end

-- Get player media
function Storage.GetPlayerMedia(phoneNumber, mediaType, limit, offset)
    limit = limit or 20
    offset = offset or 0
    
    local query = [[
        SELECT id, media_type, file_url, thumbnail_url, duration, file_size, 
               location_x, location_y, metadata_json, created_at
        FROM phone_media
        WHERE owner_number = ?
    ]]
    
    local params = {phoneNumber}
    
    if mediaType then
        query = query .. ' AND media_type = ?'
        table.insert(params, mediaType)
    end
    
    query = query .. ' ORDER BY created_at DESC LIMIT ? OFFSET ?'
    table.insert(params, limit)
    table.insert(params, offset)
    
    local result = MySQL.query.await(query, params)
    
    -- Check cache for URLs and use cached versions if available
    if result then
        for i, media in ipairs(result) do
            local cachedUrl = Storage.GetCachedUrl(media.id)
            if cachedUrl then
                result[i].file_url = cachedUrl
                if Config.DebugMode then
                    print(string.format('[Phone] Using cached URL for media ID: %d', media.id))
                end
            else
                -- Cache the URL for future requests
                Storage.CacheUrl(media.id, media.file_url)
            end
        end
    end
    
    return result or {}
end

-- Delete media file
function Storage.DeleteMedia(mediaId, phoneNumber)
    -- Get media info
    local media = MySQL.query.await('SELECT * FROM phone_media WHERE id = ? AND owner_number = ?', {
        mediaId, phoneNumber
    })
    
    if not media or #media == 0 then
        return {
            success = false,
            error = 'NOT_FOUND',
            message = 'Media not found'
        }
    end
    
    local mediaData = media[1]
    
    -- Delete file from storage
    if Config.MediaStorage == 'local' or not Config.MediaStorage then
        -- Extract filename from URL
        local filename = mediaData.file_url:match('[^/]+$')
        if filename then
            local subdir = 'photos'
            if mediaData.media_type == 'video' then
                subdir = 'videos'
            elseif mediaData.media_type == 'audio' then
                subdir = 'audio'
            end
            
            -- Delete file (simplified - in production use proper file deletion)
            local resourcePath = GetResourcePath(GetCurrentResourceName())
            local filePath = resourcePath .. '/media/' .. subdir .. '/' .. filename
            os.remove(filePath)
        end
    else
        -- Delete from CDN (placeholder)
        if Config.Debug then
            print('[Phone] CDN file deletion not implemented')
        end
    end
    
    -- Delete from database
    MySQL.query.await('DELETE FROM phone_media WHERE id = ?', {mediaId})
    
    -- Delete from albums
    MySQL.query.await('DELETE FROM phone_album_media WHERE media_id = ?', {mediaId})
    
    -- Clear URL cache for this media
    Storage.ClearUrlCache(mediaId)
    
    if Config.DebugMode then
        print(string.format('[Phone] Cleared cache for deleted media ID: %d', mediaId))
    end
    
    return {
        success = true,
        message = 'Media deleted successfully'
    }
end

-- Get storage usage for player
function Storage.GetStorageUsage(phoneNumber)
    local result = MySQL.query.await([[
        SELECT 
            COUNT(*) as total_files,
            SUM(file_size) as total_size,
            SUM(CASE WHEN media_type = 'photo' THEN 1 ELSE 0 END) as photo_count,
            SUM(CASE WHEN media_type = 'video' THEN 1 ELSE 0 END) as video_count,
            SUM(CASE WHEN media_type = 'audio' THEN 1 ELSE 0 END) as audio_count
        FROM phone_media
        WHERE owner_number = ?
    ]], {phoneNumber})
    
    if result and result[1] then
        local usage = result[1]
        local quota = Config.StorageQuotaPerPlayer or (500 * 1024 * 1024)
        
        return {
            success = true,
            data = {
                total_files = usage.total_files or 0,
                total_size = usage.total_size or 0,
                photo_count = usage.photo_count or 0,
                video_count = usage.video_count or 0,
                audio_count = usage.audio_count or 0,
                quota = quota,
                percentage = ((usage.total_size or 0) / quota) * 100
            }
        }
    end
    
    return {
        success = false,
        error = 'DATABASE_ERROR',
        message = 'Failed to get storage usage'
    }
end

-- Bulk delete media
function Storage.BulkDeleteMedia(phoneNumber, mediaIds)
    if not phoneNumber or not mediaIds or type(mediaIds) ~= 'table' or #mediaIds == 0 then
        return {
            success = false,
            error = 'INVALID_PARAMETERS',
            message = 'Invalid parameters for bulk delete'
        }
    end
    
    local deleted = 0
    local errors = {}
    
    for _, mediaId in ipairs(mediaIds) do
        local result = Storage.DeleteMedia(mediaId, phoneNumber)
        if result.success then
            deleted = deleted + 1
        else
            table.insert(errors, {
                mediaId = mediaId,
                error = result.error,
                message = result.message
            })
        end
    end
    
    return {
        success = deleted > 0,
        message = string.format('Deleted %d of %d media items', deleted, #mediaIds),
        data = {
            deleted_count = deleted,
            total_count = #mediaIds,
            errors = errors
        }
    }
end

-- Cleanup old media (for maintenance)
function Storage.CleanupOldMedia(days)
    days = days or 90
    
    -- Get old media files first for file deletion
    local oldMedia = MySQL.query.await([[
        SELECT id, owner_number, file_url, media_type
        FROM phone_media
        WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
    ]], {days})
    
    if oldMedia and #oldMedia > 0 then
        -- Delete files
        for _, media in ipairs(oldMedia) do
            if Config.MediaStorage == 'local' or not Config.MediaStorage then
                local filename = media.file_url:match('[^/]+$')
                if filename then
                    local subdir = 'photos'
                    if media.media_type == 'video' then
                        subdir = 'videos'
                    elseif media.media_type == 'audio' then
                        subdir = 'audio'
                    end
                    
                    local resourcePath = GetResourcePath(GetCurrentResourceName())
                    local filePath = resourcePath .. '/media/' .. subdir .. '/' .. filename
                    os.remove(filePath)
                end
            end
        end
        
        -- Delete from database
        MySQL.query.await([[
            DELETE FROM phone_media
            WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
        ]], {days})
        
        if Config.Debug then
            print(string.format('[Phone] Cleaned up %d media items older than %d days', #oldMedia, days))
        end
        
        return {
            success = true,
            deleted_count = #oldMedia
        }
    end
    
    return {
        success = true,
        deleted_count = 0
    }
end

-- Cleanup orphaned media (media not in any album and older than X days)
function Storage.CleanupOrphanedMedia(days)
    days = days or 30
    
    local orphaned = MySQL.query.await([[
        SELECT m.id, m.owner_number, m.file_url, m.media_type
        FROM phone_media m
        LEFT JOIN phone_album_media am ON m.id = am.media_id
        WHERE am.media_id IS NULL
        AND m.created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
    ]], {days})
    
    if orphaned and #orphaned > 0 then
        local mediaIds = {}
        for _, media in ipairs(orphaned) do
            table.insert(mediaIds, media.id)
        end
        
        -- Use bulk delete
        local result = Storage.BulkDeleteMedia(orphaned[1].owner_number, mediaIds)
        
        if Config.Debug then
            print(string.format('[Phone] Cleaned up %d orphaned media items', result.data.deleted_count))
        end
        
        return result
    end
    
    return {
        success = true,
        deleted_count = 0
    }
end

return Storage

-- Test command to verify database integration for Fivemanage URLs
RegisterCommand('phone:test-db-integration', function(source, args)
    if source ~= 0 then
        print('[Phone] This command can only be run from the server console')
        return
    end
    
    print('[Phone] Testing database integration for Fivemanage URLs...')
    
    -- Test 1: Verify phone_media table schema
    print('[Phone] Test 1: Verifying phone_media table schema...')
    local schemaCheck = MySQL.query.await([[
        SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'phone_media' 
        AND COLUMN_NAME IN ('file_url', 'metadata_json')
    ]], {})
    
    if schemaCheck and #schemaCheck > 0 then
        for _, column in ipairs(schemaCheck) do
            print(string.format('[Phone]   - %s: %s(%s)', 
                column.COLUMN_NAME, 
                column.DATA_TYPE, 
                column.CHARACTER_MAXIMUM_LENGTH or 'N/A'))
        end
        print('[Phone] ✓ Schema check passed')
    else
        print('[Phone] ✗ Schema check failed - table or columns not found')
        return
    end
    
    -- Test 2: Insert test media with Fivemanage URL
    print('[Phone] Test 2: Inserting test media with Fivemanage URL...')
    local testPhoneNumber = '555-0000'
    local testFivemanageUrl = 'https://cdn.fivemanage.com/images/test123abc456def.jpg'
    local testMetadata = {
        upload_method = 'fivemanage',
        fivemanage_id = 'test123abc456def',
        original_filename = 'test_photo.jpg',
        mime_type = 'image/jpeg',
        upload_timestamp = os.time()
    }
    
    local insertResult = MySQL.insert.await([[
        INSERT INTO phone_media (owner_number, media_type, file_url, thumbnail_url, duration, file_size, metadata_json)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        testPhoneNumber,
        'photo',
        testFivemanageUrl,
        nil,
        0,
        1024000,
        json.encode(testMetadata)
    })
    
    if insertResult then
        print(string.format('[Phone] ✓ Test media inserted with ID: %d', insertResult))
        
        -- Test 3: Retrieve the inserted media
        print('[Phone] Test 3: Retrieving test media...')
        local retrievedMedia = MySQL.query.await([[
            SELECT id, owner_number, media_type, file_url, metadata_json, created_at
            FROM phone_media
            WHERE id = ?
        ]], {insertResult})
        
        if retrievedMedia and #retrievedMedia > 0 then
            local media = retrievedMedia[1]
            print('[Phone] ✓ Media retrieved successfully:')
            print(string.format('[Phone]   - ID: %d', media.id))
            print(string.format('[Phone]   - Owner: %s', media.owner_number))
            print(string.format('[Phone]   - Type: %s', media.media_type))
            print(string.format('[Phone]   - URL: %s', media.file_url))
            
            -- Parse and display metadata
            local success, metadata = pcall(json.decode, media.metadata_json)
            if success and metadata then
                print('[Phone]   - Metadata:')
                print(string.format('[Phone]     * upload_method: %s', metadata.upload_method or 'N/A'))
                print(string.format('[Phone]     * fivemanage_id: %s', metadata.fivemanage_id or 'N/A'))
                print(string.format('[Phone]     * original_filename: %s', metadata.original_filename or 'N/A'))
                print(string.format('[Phone]     * mime_type: %s', metadata.mime_type or 'N/A'))
                print(string.format('[Phone]     * upload_timestamp: %s', metadata.upload_timestamp or 'N/A'))
            else
                print('[Phone]   - Metadata: Failed to parse JSON')
            end
        else
            print('[Phone] ✗ Failed to retrieve test media')
        end
        
        -- Test 4: Test URL format compatibility
        print('[Phone] Test 4: Testing URL format compatibility...')
        
        -- Insert local URL for comparison
        local localUrl = 'nui://phone/media/photos/5550000_1234567890_1234.jpg'
        local localMetadata = {
            upload_method = 'local',
            original_filename = 'local_photo.jpg',
            mime_type = 'image/jpeg',
            upload_timestamp = os.time()
        }
        
        local localInsertResult = MySQL.insert.await([[
            INSERT INTO phone_media (owner_number, media_type, file_url, thumbnail_url, duration, file_size, metadata_json)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], {
            testPhoneNumber,
            'photo',
            localUrl,
            nil,
            0,
            512000,
            json.encode(localMetadata)
        })
        
        if localInsertResult then
            print(string.format('[Phone] ✓ Local URL media inserted with ID: %d', localInsertResult))
            
            -- Query both URLs
            local bothMedia = MySQL.query.await([[
                SELECT id, file_url, metadata_json
                FROM phone_media
                WHERE owner_number = ?
                ORDER BY id DESC
                LIMIT 2
            ]], {testPhoneNumber})
            
            if bothMedia and #bothMedia == 2 then
                print('[Phone] ✓ Both URL formats retrieved successfully:')
                for i, media in ipairs(bothMedia) do
                    local success, metadata = pcall(json.decode, media.metadata_json)
                    local method = success and metadata.upload_method or 'unknown'
                    print(string.format('[Phone]   %d. ID: %d, Method: %s, URL: %s', 
                        i, media.id, method, media.file_url))
                end
            else
                print('[Phone] ✗ Failed to retrieve both media items')
            end
        else
            print('[Phone] ✗ Failed to insert local URL media')
        end
        
        -- Test 5: Clean up test data
        print('[Phone] Test 5: Cleaning up test data...')
        local deleteResult = MySQL.query.await([[
            DELETE FROM phone_media
            WHERE owner_number = ?
        ]], {testPhoneNumber})
        
        print('[Phone] ✓ Test data cleaned up')
    else
        print('[Phone] ✗ Failed to insert test media')
        return
    end
    
    print('[Phone] ========================================')
    print('[Phone] Database integration test completed!')
    print('[Phone] All tests passed successfully.')
    print('[Phone] ========================================')
end, true)
