-- Media Testing and Validation Module
-- Provides commands for testing Fivemanage integration and gathering statistics

local Testing = {}
local Storage = require('server.media.storage')

-- Check if user has admin permissions
local function IsAdmin(source)
    -- For server console
    if source == 0 then
        return true
    end
    
    -- Check if player has admin ace permission
    return IsPlayerAceAllowed(source, 'phone.admin')
end

-- Generate a small test image (1x1 pixel PNG)
-- Returns base64-encoded image data
local function GenerateTestImage()
    -- 1x1 pixel transparent PNG (base64 encoded)
    -- This is a minimal valid PNG file
    local pngData = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
    return pngData
end

-- Validate that a URL is accessible
-- Makes an HTTP GET request to verify the file can be accessed
local function ValidateUrlAccessibility(url, callback)
    PerformHttpRequest(url, function(statusCode, responseText, headers)
        if statusCode == 200 then
            callback(true, 'File is publicly accessible', statusCode)
        else
            callback(false, string.format('File is not accessible (HTTP %d)', statusCode), statusCode)
        end
    end, 'GET')
end

-- Format error message with troubleshooting suggestions
local function FormatErrorWithSuggestions(errorType, errorMsg, statusCode)
    local message = string.format('[Phone] Upload failed: %s', errorMsg or 'Unknown error')
    
    if statusCode then
        message = message .. string.format(' (HTTP %d)', statusCode)
    end
    
    -- Add troubleshooting suggestions based on error type
    local suggestions = {}
    
    if errorType == 'UNAUTHORIZED' or statusCode == 401 then
        table.insert(suggestions, 'Check that your Fivemanage API key is correct')
        table.insert(suggestions, 'Verify the API key is properly set in Config.FivemanageConfig.apiKey')
        table.insert(suggestions, 'Ensure there are no extra spaces or quotes in the API key')
        table.insert(suggestions, 'Get a new API key from https://fivemanage.com/dashboard')
    elseif errorType == 'CONFIG_ERROR' then
        table.insert(suggestions, 'Verify Config.FivemanageConfig.enabled is set to true')
        table.insert(suggestions, 'Check that Config.FivemanageConfig.apiKey is not empty')
        table.insert(suggestions, 'Ensure Config.FivemanageConfig.endpoint is set correctly')
    elseif errorType == 'TIMEOUT' or errorType == 'NETWORK_ERROR' then
        table.insert(suggestions, 'Check your server\'s internet connection')
        table.insert(suggestions, 'Verify firewall settings allow outbound HTTPS connections')
        table.insert(suggestions, 'Try increasing Config.FivemanageConfig.timeout value')
    elseif errorType == 'SERVER_ERROR' or statusCode == 500 then
        table.insert(suggestions, 'Fivemanage service may be temporarily unavailable')
        table.insert(suggestions, 'Check Fivemanage status at https://status.fivemanage.com')
        table.insert(suggestions, 'Try again in a few minutes')
    elseif errorType == 'FILE_TOO_LARGE' or statusCode == 413 then
        table.insert(suggestions, 'The test file is too large for your Fivemanage plan')
        table.insert(suggestions, 'Check your Fivemanage plan limits')
        table.insert(suggestions, 'Consider upgrading your Fivemanage plan')
    elseif errorType == 'RATE_LIMITED' or statusCode == 429 then
        table.insert(suggestions, 'You have exceeded the Fivemanage API rate limit')
        table.insert(suggestions, 'Wait a few minutes before trying again')
        table.insert(suggestions, 'Consider upgrading your Fivemanage plan for higher limits')
    end
    
    -- Print suggestions
    if #suggestions > 0 then
        message = message .. '\n[Phone] Troubleshooting suggestions:'
        for i, suggestion in ipairs(suggestions) do
            message = message .. string.format('\n[Phone]   %d. %s', i, suggestion)
        end
    end
    
    return message
end

-- Register the test command
RegisterCommand('phone:test-fivemanage', function(source, args, rawCommand)
    -- Validate admin permissions
    if not IsAdmin(source) then
        if source == 0 then
            print('[Phone] This command requires admin permissions')
        else
            TriggerClientEvent('phone:notify', source, {
                type = 'error',
                title = 'Permission Denied',
                message = 'You do not have permission to use this command.',
                duration = 5000
            })
        end
        return
    end
    
    print('[Phone] ========================================')
    print('[Phone] Fivemanage Integration Test')
    print('[Phone] ========================================')
    
    -- Test 1: Validate configuration
    print('[Phone] Step 1: Validating Fivemanage configuration...')
    local configValid, configError = Storage.ValidateFivemanageConfig()
    
    if not configValid then
        print('[Phone] ✗ Configuration validation failed')
        print(FormatErrorWithSuggestions('CONFIG_ERROR', configError, nil))
        print('[Phone] ========================================')
        
        if source ~= 0 then
            TriggerClientEvent('phone:notify', source, {
                type = 'error',
                title = 'Test Failed',
                message = 'Configuration validation failed. Check server console for details.',
                duration = 7000
            })
        end
        return
    end
    
    print('[Phone] ✓ Configuration is valid')
    print(string.format('[Phone]   - API Key: %s...%s (length: %d)', 
        Config.FivemanageConfig.apiKey:sub(1, 8),
        Config.FivemanageConfig.apiKey:sub(-4),
        #Config.FivemanageConfig.apiKey))
    print(string.format('[Phone]   - Endpoint: %s', Config.FivemanageConfig.endpoint))
    print(string.format('[Phone]   - Timeout: %dms', Config.FivemanageConfig.timeout))
    print(string.format('[Phone]   - Retry Attempts: %d', Config.FivemanageConfig.retryAttempts))
    
    -- Test 2: Generate test image
    print('[Phone] Step 2: Generating test image (1x1 pixel PNG)...')
    local testImageData = GenerateTestImage()
    local testImageSize = #testImageData
    print(string.format('[Phone] ✓ Test image generated (%d bytes)', testImageSize))
    
    -- Test 3: Upload test image to Fivemanage
    print('[Phone] Step 3: Uploading test image to Fivemanage...')
    print('[Phone] This may take a few seconds...')
    
    local testPhoneNumber = 'test-' .. os.time()
    local testFilename = 'test_' .. os.time() .. '.png'
    
    local uploadUrl, uploadError, errorType, uploadResult = Storage.UploadToFivemanage(
        testFilename,
        testImageData,
        'photo',
        {test = true},
        testPhoneNumber,
        0, -- source = 0 for server console
        nil -- no progress callback
    )
    
    if not uploadUrl then
        print('[Phone] ✗ Upload failed')
        print(FormatErrorWithSuggestions(errorType, uploadError, uploadResult and uploadResult.statusCode or nil))
        print('[Phone] ========================================')
        
        if source ~= 0 then
            TriggerClientEvent('phone:notify', source, {
                type = 'error',
                title = 'Test Failed',
                message = 'Upload failed. Check server console for details.',
                duration = 7000
            })
        end
        return
    end
    
    print('[Phone] ✓ Upload successful!')
    print(string.format('[Phone]   - URL: %s', uploadUrl))
    
    if uploadResult then
        if uploadResult.id then
            print(string.format('[Phone]   - Fivemanage ID: %s', uploadResult.id))
        end
        if uploadResult.size then
            print(string.format('[Phone]   - File Size: %d bytes', uploadResult.size))
        end
        if uploadResult.statusCode then
            print(string.format('[Phone]   - HTTP Status: %d', uploadResult.statusCode))
        end
    end
    
    -- Test 4: Validate file accessibility
    print('[Phone] Step 4: Validating file accessibility...')
    print('[Phone] Checking if uploaded file is publicly accessible...')
    
    ValidateUrlAccessibility(uploadUrl, function(accessible, message, statusCode)
        if accessible then
            print('[Phone] ✓ ' .. message)
            print(string.format('[Phone]   - HTTP Status: %d', statusCode))
            print('[Phone] ========================================')
            print('[Phone] ✓ All tests passed successfully!')
            print('[Phone] Fivemanage integration is working correctly.')
            print('[Phone] ========================================')
            
            if source ~= 0 then
                TriggerClientEvent('phone:notify', source, {
                    type = 'success',
                    title = 'Test Passed',
                    message = 'Fivemanage integration is working correctly!',
                    duration = 7000
                })
            end
        else
            print('[Phone] ✗ ' .. message)
            print('[Phone] The file was uploaded but is not publicly accessible.')
            print('[Phone] Troubleshooting suggestions:')
            print('[Phone]   1. Check your Fivemanage account settings')
            print('[Phone]   2. Verify file permissions in Fivemanage dashboard')
            print('[Phone]   3. Contact Fivemanage support if the issue persists')
            print('[Phone] ========================================')
            
            if source ~= 0 then
                TriggerClientEvent('phone:notify', source, {
                    type = 'warning',
                    title = 'Test Warning',
                    message = 'File uploaded but not publicly accessible. Check console.',
                    duration = 7000
                })
            end
        end
    end)
end, true) -- Restricted to admins

return Testing

-- Format file size for display
local function FormatFileSize(bytes)
    if not bytes or bytes == 0 then
        return '0 B'
    end
    
    local units = {'B', 'KB', 'MB', 'GB', 'TB'}
    local unitIndex = 1
    local size = bytes
    
    while size >= 1024 and unitIndex < #units do
        size = size / 1024
        unitIndex = unitIndex + 1
    end
    
    return string.format('%.2f %s', size, units[unitIndex])
end

-- Format number with thousands separator
local function FormatNumber(num)
    if not num then
        return '0'
    end
    
    local formatted = tostring(num)
    local k
    
    while true do
        formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then
            break
        end
    end
    
    return formatted
end

-- Calculate percentage
local function CalculatePercentage(part, total)
    if not part or not total or total == 0 then
        return 0
    end
    return (part / total) * 100
end

-- Register the stats command
RegisterCommand('phone:fivemanage-stats', function(source, args, rawCommand)
    -- Validate admin permissions
    if not IsAdmin(source) then
        if source == 0 then
            print('[Phone] This command requires admin permissions')
        else
            TriggerClientEvent('phone:notify', source, {
                type = 'error',
                title = 'Permission Denied',
                message = 'You do not have permission to use this command.',
                duration = 5000
            })
        end
        return
    end
    
    print('[Phone] ========================================')
    print('[Phone] Fivemanage Storage Statistics')
    print('[Phone] ========================================')
    print('[Phone] Gathering statistics from database...')
    
    -- Query total media files
    local totalQuery = MySQL.query.await([[
        SELECT COUNT(*) as total_count
        FROM phone_media
    ]], {})
    
    local totalFiles = (totalQuery and totalQuery[1] and totalQuery[1].total_count) or 0
    
    if totalFiles == 0 then
        print('[Phone] No media files found in database.')
        print('[Phone] ========================================')
        
        if source ~= 0 then
            TriggerClientEvent('phone:notify', source, {
                type = 'info',
                title = 'No Data',
                message = 'No media files found in database.',
                duration = 5000
            })
        end
        return
    end
    
    -- Query Fivemanage URLs vs local URLs
    local storageQuery = MySQL.query.await([[
        SELECT 
            SUM(CASE WHEN file_url LIKE 'https://cdn.fivemanage.com%' OR file_url LIKE 'https://api.fivemanage.com%' THEN 1 ELSE 0 END) as fivemanage_count,
            SUM(CASE WHEN file_url LIKE 'nui://%' THEN 1 ELSE 0 END) as local_count,
            SUM(CASE WHEN file_url NOT LIKE 'https://cdn.fivemanage.com%' AND file_url NOT LIKE 'https://api.fivemanage.com%' AND file_url NOT LIKE 'nui://%' THEN 1 ELSE 0 END) as other_count
        FROM phone_media
    ]], {})
    
    local fivemanageCount = (storageQuery and storageQuery[1] and storageQuery[1].fivemanage_count) or 0
    local localCount = (storageQuery and storageQuery[1] and storageQuery[1].local_count) or 0
    local otherCount = (storageQuery and storageQuery[1] and storageQuery[1].other_count) or 0
    
    -- Query storage usage
    local sizeQuery = MySQL.query.await([[
        SELECT 
            SUM(file_size) as total_size,
            SUM(CASE WHEN file_url LIKE 'https://cdn.fivemanage.com%' OR file_url LIKE 'https://api.fivemanage.com%' THEN file_size ELSE 0 END) as fivemanage_size,
            SUM(CASE WHEN file_url LIKE 'nui://%' THEN file_size ELSE 0 END) as local_size
        FROM phone_media
    ]], {})
    
    local totalSize = (sizeQuery and sizeQuery[1] and sizeQuery[1].total_size) or 0
    local fivemanageSize = (sizeQuery and sizeQuery[1] and sizeQuery[1].fivemanage_size) or 0
    local localSize = (sizeQuery and sizeQuery[1] and sizeQuery[1].local_size) or 0
    
    -- Query per-media-type breakdown
    local typeQuery = MySQL.query.await([[
        SELECT 
            media_type,
            COUNT(*) as count,
            SUM(file_size) as total_size,
            SUM(CASE WHEN file_url LIKE 'https://cdn.fivemanage.com%' OR file_url LIKE 'https://api.fivemanage.com%' THEN 1 ELSE 0 END) as fivemanage_count,
            SUM(CASE WHEN file_url LIKE 'nui://%' THEN 1 ELSE 0 END) as local_count
        FROM phone_media
        GROUP BY media_type
        ORDER BY count DESC
    ]], {})
    
    -- Display overall statistics
    print('[Phone] ')
    print('[Phone] Overall Statistics:')
    print('[Phone] -------------------')
    print(string.format('[Phone] Total Files: %s', FormatNumber(totalFiles)))
    print(string.format('[Phone] Total Storage: %s', FormatFileSize(totalSize)))
    print('[Phone] ')
    
    -- Display storage method breakdown
    print('[Phone] Storage Method Breakdown:')
    print('[Phone] -------------------------')
    print(string.format('[Phone] Fivemanage: %s files (%.1f%%) - %s', 
        FormatNumber(fivemanageCount),
        CalculatePercentage(fivemanageCount, totalFiles),
        FormatFileSize(fivemanageSize)))
    print(string.format('[Phone] Local: %s files (%.1f%%) - %s', 
        FormatNumber(localCount),
        CalculatePercentage(localCount, totalFiles),
        FormatFileSize(localSize)))
    
    if otherCount > 0 then
        print(string.format('[Phone] Other: %s files (%.1f%%)', 
            FormatNumber(otherCount),
            CalculatePercentage(otherCount, totalFiles)))
    end
    print('[Phone] ')
    
    -- Display per-media-type breakdown
    if typeQuery and #typeQuery > 0 then
        print('[Phone] Media Type Breakdown:')
        print('[Phone] ---------------------')
        
        for _, mediaType in ipairs(typeQuery) do
            local typeName = mediaType.media_type:sub(1, 1):upper() .. mediaType.media_type:sub(2)
            print(string.format('[Phone] %s:', typeName))
            print(string.format('[Phone]   - Total: %s files - %s', 
                FormatNumber(mediaType.count),
                FormatFileSize(mediaType.total_size)))
            print(string.format('[Phone]   - Fivemanage: %s files (%.1f%%)', 
                FormatNumber(mediaType.fivemanage_count),
                CalculatePercentage(mediaType.fivemanage_count, mediaType.count)))
            print(string.format('[Phone]   - Local: %s files (%.1f%%)', 
                FormatNumber(mediaType.local_count),
                CalculatePercentage(mediaType.local_count, mediaType.count)))
        end
        print('[Phone] ')
    end
    
    -- Display configuration status
    print('[Phone] Current Configuration:')
    print('[Phone] ----------------------')
    print(string.format('[Phone] Storage Mode: %s', Config.MediaStorage or 'local'))
    
    if Config.FivemanageConfig then
        print(string.format('[Phone] Fivemanage Enabled: %s', Config.FivemanageConfig.enabled and 'Yes' or 'No'))
        print(string.format('[Phone] Fallback to Local: %s', Config.FivemanageConfig.fallbackToLocal and 'Yes' or 'No'))
    end
    
    print('[Phone] ========================================')
    
    -- Send notification to player if not console
    if source ~= 0 then
        TriggerClientEvent('phone:notify', source, {
            type = 'success',
            title = 'Statistics Generated',
            message = string.format('%s total files (%s Fivemanage, %s local)', 
                FormatNumber(totalFiles),
                FormatNumber(fivemanageCount),
                FormatNumber(localCount)),
            duration = 7000
        })
    end
end, true) -- Restricted to admins
