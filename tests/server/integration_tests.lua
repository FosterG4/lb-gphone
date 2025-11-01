-- Fivemanage Integration Tests
-- Comprehensive test suite for Fivemanage media storage integration

local IntegrationTests = {}
local Storage = require('server.media.storage')

-- Test results tracking
local testResults = {
    passed = 0,
    failed = 0,
    tests = {}
}

-- Helper function to check if user has admin permissions
local function IsAdmin(source)
    if source == 0 then
        return true
    end
    return IsPlayerAceAllowed(source, 'phone.admin')
end

-- Helper function to generate test image data (1x1 pixel PNG)
local function GenerateTestImage()
    return 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
end

-- Helper function to generate test video data (minimal MP4)
local function GenerateTestVideo()
    -- Minimal valid MP4 file header (base64 encoded)
    return 'AAAAIGZ0eXBpc29tAAACAGlzb21pc28yYXZjMW1wNDEAAAAIZnJlZQAAAu1tZGF0'
end

-- Helper function to generate test audio data (minimal MP3)
local function GenerateTestAudio()
    -- Minimal valid MP3 file header (base64 encoded)
    return '//uQxAAAAAAAAAAAAAAAAAAAAAAAWGluZwAAAA8AAAACAAADhAC'
end

-- Helper function to log test result
local function LogTestResult(testName, passed, message, details)
    local result = {
        name = testName,
        passed = passed,
        message = message,
        details = details or {},
        timestamp = os.date('%Y-%m-%d %H:%M:%S')
    }
    
    table.insert(testResults.tests, result)
    
    if passed then
        testResults.passed = testResults.passed + 1
        print(string.format('[Phone Test] ✓ %s - %s', testName, message))
    else
        testResults.failed = testResults.failed + 1
        print(string.format('[Phone Test] ✗ %s - %s', testName, message))
    end
    
    if details and Config.DebugMode then
        print(string.format('[Phone Test]   Details: %s', json.encode(details)))
    end
end

-- Test 1: Photo upload to Fivemanage
function IntegrationTests.TestPhotoUpload()
    local testName = 'Photo Upload to Fivemanage'
    print(string.format('[Phone Test] Running: %s', testName))
    
    -- Generate test data
    local testPhoneNumber = 'test-' .. os.time()
    local testImageData = GenerateTestImage()
    local testFilename = 'test_photo_' .. os.time() .. '.png'
    
    -- Attempt upload
    local uploadUrl, uploadError, errorType, uploadResult = Storage.UploadToFivemanage(
        testFilename,
        testImageData,
        'photo',
        {test = true, source = 'integration_test'},
        testPhoneNumber,
        0,
        nil
    )
    
    if uploadUrl then
        -- Verify URL format
        local isValidUrl = uploadUrl:match('^https://') ~= nil
        
        if isValidUrl then
            -- Store in database
            local mediaId = MySQL.insert.await([[
                INSERT INTO phone_media (owner_number, media_type, file_url, file_size, metadata_json)
                VALUES (?, ?, ?, ?, ?)
            ]], {
                testPhoneNumber,
                'photo',
                uploadUrl,
                #testImageData,
                json.encode({upload_method = 'fivemanage', test = true})
            })
            
            if mediaId then
                -- Verify retrieval from database
                local retrieved = MySQL.query.await([[
                    SELECT id, file_url, media_type FROM phone_media WHERE id = ?
                ]], {mediaId})
                
                if retrieved and #retrieved > 0 and retrieved[1].file_url == uploadUrl then
                    LogTestResult(testName, true, 'Photo uploaded, stored, and retrieved successfully', {
                        url = uploadUrl,
                        media_id = mediaId,
                        fivemanage_id = uploadResult and uploadResult.id or 'N/A'
                    })
                    
                    -- Cleanup test data
                    MySQL.query.await('DELETE FROM phone_media WHERE id = ?', {mediaId})
                    return true
                else
                    LogTestResult(testName, false, 'Failed to retrieve photo from database', {error = 'Database retrieval failed'})
                end
            else
                LogTestResult(testName, false, 'Failed to store photo in database', {error = 'Database insert failed'})
            end
        else
            LogTestResult(testName, false, 'Invalid URL format returned', {url = uploadUrl})
        end
    else
        LogTestResult(testName, false, 'Upload failed', {
            error = uploadError,
            error_type = errorType
        })
    end
    
    return false
end

-- Test 2: Video upload to Fivemanage
function IntegrationTests.TestVideoUpload()
    local testName = 'Video Upload to Fivemanage'
    print(string.format('[Phone Test] Running: %s', testName))
    
    local testPhoneNumber = 'test-' .. os.time()
    local testVideoData = GenerateTestVideo()
    local testFilename = 'test_video_' .. os.time() .. '.mp4'
    
    local uploadUrl, uploadError, errorType, uploadResult = Storage.UploadToFivemanage(
        testFilename,
        testVideoData,
        'video',
        {test = true, duration = 1},
        testPhoneNumber,
        0,
        nil
    )
    
    if uploadUrl then
        local mediaId = MySQL.insert.await([[
            INSERT INTO phone_media (owner_number, media_type, file_url, file_size, duration, metadata_json)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], {
            testPhoneNumber,
            'video',
            uploadUrl,
            #testVideoData,
            1,
            json.encode({upload_method = 'fivemanage', test = true})
        })
        
        if mediaId then
            local retrieved = MySQL.query.await([[
                SELECT id, file_url, media_type FROM phone_media WHERE id = ?
            ]], {mediaId})
            
            if retrieved and #retrieved > 0 and retrieved[1].file_url == uploadUrl then
                LogTestResult(testName, true, 'Video uploaded, stored, and retrieved successfully', {
                    url = uploadUrl,
                    media_id = mediaId
                })
                
                MySQL.query.await('DELETE FROM phone_media WHERE id = ?', {mediaId})
                return true
            else
                LogTestResult(testName, false, 'Failed to retrieve video from database')
            end
        else
            LogTestResult(testName, false, 'Failed to store video in database')
        end
    else
        LogTestResult(testName, false, 'Upload failed', {
            error = uploadError,
            error_type = errorType
        })
    end
    
    return false
end

-- Test 3: Audio upload to Fivemanage
function IntegrationTests.TestAudioUpload()
    local testName = 'Audio Upload to Fivemanage'
    print(string.format('[Phone Test] Running: %s', testName))
    
    local testPhoneNumber = 'test-' .. os.time()
    local testAudioData = GenerateTestAudio()
    local testFilename = 'test_audio_' .. os.time() .. '.mp3'
    
    local uploadUrl, uploadError, errorType, uploadResult = Storage.UploadToFivemanage(
        testFilename,
        testAudioData,
        'audio',
        {test = true, duration = 5},
        testPhoneNumber,
        0,
        nil
    )
    
    if uploadUrl then
        local mediaId = MySQL.insert.await([[
            INSERT INTO phone_media (owner_number, media_type, file_url, file_size, duration, metadata_json)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], {
            testPhoneNumber,
            'audio',
            uploadUrl,
            #testAudioData,
            5,
            json.encode({upload_method = 'fivemanage', test = true})
        })
        
        if mediaId then
            local retrieved = MySQL.query.await([[
                SELECT id, file_url, media_type FROM phone_media WHERE id = ?
            ]], {mediaId})
            
            if retrieved and #retrieved > 0 and retrieved[1].file_url == uploadUrl then
                LogTestResult(testName, true, 'Audio uploaded, stored, and retrieved successfully', {
                    url = uploadUrl,
                    media_id = mediaId
                })
                
                MySQL.query.await('DELETE FROM phone_media WHERE id = ?', {mediaId})
                return true
            else
                LogTestResult(testName, false, 'Failed to retrieve audio from database')
            end
        else
            LogTestResult(testName, false, 'Failed to store audio in database')
        end
    else
        LogTestResult(testName, false, 'Upload failed', {
            error = uploadError,
            error_type = errorType
        })
    end
    
    return false
end

-- Test 4: Error handling - Invalid API key
function IntegrationTests.TestInvalidApiKey()
    local testName = 'Error Handling - Invalid API Key'
    print(string.format('[Phone Test] Running: %s', testName))
    
    -- Save original API key
    local originalApiKey = Config.FivemanageConfig.apiKey
    
    -- Set invalid API key
    Config.FivemanageConfig.apiKey = 'invalid_key_12345'
    
    local testPhoneNumber = 'test-' .. os.time()
    local testImageData = GenerateTestImage()
    local testFilename = 'test_invalid_' .. os.time() .. '.png'
    
    local uploadUrl, uploadError, errorType = Storage.UploadToFivemanage(
        testFilename,
        testImageData,
        'photo',
        {test = true},
        testPhoneNumber,
        0,
        nil
    )
    
    -- Restore original API key
    Config.FivemanageConfig.apiKey = originalApiKey
    
    -- Should fail with UNAUTHORIZED error
    if not uploadUrl and errorType == 'UNAUTHORIZED' then
        LogTestResult(testName, true, 'Correctly handled invalid API key', {
            error_type = errorType,
            error_message = uploadError
        })
        return true
    else
        LogTestResult(testName, false, 'Did not properly detect invalid API key', {
            expected_error = 'UNAUTHORIZED',
            actual_error = errorType,
            url = uploadUrl
        })
    end
    
    return false
end

-- Test 5: Error handling - Oversized file
function IntegrationTests.TestOversizedFile()
    local testName = 'Error Handling - Oversized File'
    print(string.format('[Phone Test] Running: %s', testName))
    
    -- Create a large data string (simulate oversized file)
    local largeData = string.rep('A', 100 * 1024 * 1024) -- 100MB
    local testPhoneNumber = 'test-' .. os.time()
    local testFilename = 'test_large_' .. os.time() .. '.jpg'
    
    -- This should fail during validation before even attempting upload
    local result = Storage.HandleUpload(
        testPhoneNumber,
        largeData,
        'photo',
        {test = true},
        0,
        nil
    )
    
    if not result.success and result.error == 'MEDIA_TOO_LARGE' then
        LogTestResult(testName, true, 'Correctly rejected oversized file', {
            error = result.error,
            message = result.message
        })
        return true
    else
        LogTestResult(testName, false, 'Did not properly reject oversized file', {
            expected_error = 'MEDIA_TOO_LARGE',
            actual_error = result.error,
            success = result.success
        })
    end
    
    return false
end

-- Test 6: Error handling - Network timeout simulation
function IntegrationTests.TestNetworkTimeout()
    local testName = 'Error Handling - Network Timeout'
    print(string.format('[Phone Test] Running: %s', testName))
    
    -- Save original timeout
    local originalTimeout = Config.FivemanageConfig.timeout
    local originalRetryAttempts = Config.FivemanageConfig.retryAttempts
    
    -- Set very short timeout to simulate timeout
    Config.FivemanageConfig.timeout = 1 -- 1ms - will timeout
    Config.FivemanageConfig.retryAttempts = 2
    
    local testPhoneNumber = 'test-' .. os.time()
    local testImageData = GenerateTestImage()
    local testFilename = 'test_timeout_' .. os.time() .. '.png'
    
    local uploadUrl, uploadError, errorType = Storage.UploadToFivemanage(
        testFilename,
        testImageData,
        'photo',
        {test = true},
        testPhoneNumber,
        0,
        nil
    )
    
    -- Restore original settings
    Config.FivemanageConfig.timeout = originalTimeout
    Config.FivemanageConfig.retryAttempts = originalRetryAttempts
    
    -- Should fail with timeout or network error
    if not uploadUrl and (errorType == 'TIMEOUT' or errorType == 'NETWORK_ERROR') then
        LogTestResult(testName, true, 'Correctly handled network timeout with retry', {
            error_type = errorType,
            error_message = uploadError
        })
        return true
    else
        LogTestResult(testName, false, 'Did not properly handle timeout', {
            expected_error = 'TIMEOUT or NETWORK_ERROR',
            actual_error = errorType,
            url = uploadUrl
        })
    end
    
    return false
end

-- Test 7: Fallback to local storage
function IntegrationTests.TestFallbackToLocal()
    local testName = 'Fallback to Local Storage'
    print(string.format('[Phone Test] Running: %s', testName))
    
    -- Save original settings
    local originalApiKey = Config.FivemanageConfig.apiKey
    local originalFallback = Config.FivemanageConfig.fallbackToLocal
    
    -- Configure for fallback test
    Config.FivemanageConfig.apiKey = 'invalid_key_for_fallback_test'
    Config.FivemanageConfig.fallbackToLocal = true
    
    local testPhoneNumber = 'test-' .. os.time()
    local testImageData = GenerateTestImage()
    
    local result = Storage.HandleUpload(
        testPhoneNumber,
        testImageData,
        'photo',
        {test = true},
        0,
        nil
    )
    
    -- Restore original settings
    Config.FivemanageConfig.apiKey = originalApiKey
    Config.FivemanageConfig.fallbackToLocal = originalFallback
    
    -- Should succeed with local storage
    if result.success and result.data and result.data.url and result.data.url:match('^nui://') then
        LogTestResult(testName, true, 'Successfully fell back to local storage', {
            url = result.data.url,
            media_id = result.data.id
        })
        
        -- Cleanup
        if result.data.id then
            MySQL.query.await('DELETE FROM phone_media WHERE id = ?', {result.data.id})
        end
        return true
    else
        LogTestResult(testName, false, 'Fallback to local storage failed', {
            success = result.success,
            error = result.error,
            url = result.data and result.data.url or 'N/A'
        })
    end
    
    return false
end

-- Test 8: Social media integration - Shotz photo posting
function IntegrationTests.TestShotzPhotoPosting()
    local testName = 'Social Media - Shotz Photo Posting'
    print(string.format('[Phone Test] Running: %s', testName))
    
    local testPhoneNumber = 'test-' .. os.time()
    local testImageData = GenerateTestImage()
    
    -- Upload photo
    local result = Storage.HandleUpload(
        testPhoneNumber,
        testImageData,
        'photo',
        {test = true, app = 'shotz'},
        0,
        nil
    )
    
    if result.success and result.data and result.data.url then
        -- Simulate creating a Shotz post with the uploaded image
        local postId = MySQL.insert.await([[
            INSERT INTO phone_shotz_posts (phone_number, caption, image_url, created_at)
            VALUES (?, ?, ?, NOW())
        ]], {
            testPhoneNumber,
            'Test post from integration test',
            result.data.url
        })
        
        if postId then
            -- Verify post retrieval
            local post = MySQL.query.await([[
                SELECT id, image_url FROM phone_shotz_posts WHERE id = ?
            ]], {postId})
            
            if post and #post > 0 and post[1].image_url == result.data.url then
                LogTestResult(testName, true, 'Photo posted to Shotz successfully', {
                    post_id = postId,
                    image_url = result.data.url
                })
                
                -- Cleanup
                MySQL.query.await('DELETE FROM phone_shotz_posts WHERE id = ?', {postId})
                MySQL.query.await('DELETE FROM phone_media WHERE id = ?', {result.data.id})
                return true
            else
                LogTestResult(testName, false, 'Failed to retrieve Shotz post')
            end
        else
            LogTestResult(testName, false, 'Failed to create Shotz post')
        end
    else
        LogTestResult(testName, false, 'Failed to upload photo for Shotz', {
            error = result.error
        })
    end
    
    return false
end

-- Test 9: Social media integration - Modish video posting
function IntegrationTests.TestModishVideoPosting()
    local testName = 'Social Media - Modish Video Posting'
    print(string.format('[Phone Test] Running: %s', testName))
    
    local testPhoneNumber = 'test-' .. os.time()
    local testVideoData = GenerateTestVideo()
    
    -- Upload video
    local result = Storage.HandleUpload(
        testPhoneNumber,
        testVideoData,
        'video',
        {test = true, app = 'modish', duration = 5},
        0,
        nil
    )
    
    if result.success and result.data and result.data.url then
        -- Simulate creating a Modish post with the uploaded video
        local postId = MySQL.insert.await([[
            INSERT INTO phone_modish_posts (phone_number, caption, video_url, created_at)
            VALUES (?, ?, ?, NOW())
        ]], {
            testPhoneNumber,
            'Test video from integration test',
            result.data.url
        })
        
        if postId then
            -- Verify post retrieval
            local post = MySQL.query.await([[
                SELECT id, video_url FROM phone_modish_posts WHERE id = ?
            ]], {postId})
            
            if post and #post > 0 and post[1].video_url == result.data.url then
                LogTestResult(testName, true, 'Video posted to Modish successfully', {
                    post_id = postId,
                    video_url = result.data.url
                })
                
                -- Cleanup
                MySQL.query.await('DELETE FROM phone_modish_posts WHERE id = ?', {postId})
                MySQL.query.await('DELETE FROM phone_media WHERE id = ?', {result.data.id})
                return true
            else
                LogTestResult(testName, false, 'Failed to retrieve Modish post')
            end
        else
            LogTestResult(testName, false, 'Failed to create Modish post')
        end
    else
        LogTestResult(testName, false, 'Failed to upload video for Modish', {
            error = result.error
        })
    end
    
    return false
end

-- Test 10: Multiple media attachments
function IntegrationTests.TestMultipleMediaAttachments()
    local testName = 'Multiple Media Attachments'
    print(string.format('[Phone Test] Running: %s', testName))
    
    local testPhoneNumber = 'test-' .. os.time()
    local mediaUrls = {}
    local mediaIds = {}
    
    -- Upload multiple photos
    for i = 1, 3 do
        local result = Storage.HandleUpload(
            testPhoneNumber,
            GenerateTestImage(),
            'photo',
            {test = true, sequence = i},
            0,
            nil
        )
        
        if result.success and result.data then
            table.insert(mediaUrls, result.data.url)
            table.insert(mediaIds, result.data.id)
        else
            LogTestResult(testName, false, string.format('Failed to upload photo %d', i))
            -- Cleanup partial uploads
            for _, id in ipairs(mediaIds) do
                MySQL.query.await('DELETE FROM phone_media WHERE id = ?', {id})
            end
            return false
        end
    end
    
    -- Create post with multiple attachments
    local postId = MySQL.insert.await([[
        INSERT INTO phone_shotz_posts (phone_number, caption, image_url, created_at)
        VALUES (?, ?, ?, NOW())
    ]], {
        testPhoneNumber,
        'Multi-attachment test',
        json.encode(mediaUrls)
    })
    
    if postId then
        LogTestResult(testName, true, 'Multiple media attachments uploaded and posted', {
            post_id = postId,
            attachment_count = #mediaUrls
        })
        
        -- Cleanup
        MySQL.query.await('DELETE FROM phone_shotz_posts WHERE id = ?', {postId})
        for _, id in ipairs(mediaIds) do
            MySQL.query.await('DELETE FROM phone_media WHERE id = ?', {id})
        end
        return true
    else
        LogTestResult(testName, false, 'Failed to create post with multiple attachments')
        -- Cleanup
        for _, id in ipairs(mediaIds) do
            MySQL.query.await('DELETE FROM phone_media WHERE id = ?', {id})
        end
    end
    
    return false
end

-- Test 11: Migration command
function IntegrationTests.TestMigrationCommand()
    local testName = 'Migration Command'
    print(string.format('[Phone Test] Running: %s', testName))
    
    local testPhoneNumber = 'test-' .. os.time()
    local localMediaIds = {}
    
    -- Create test local media files
    for i = 1, 3 do
        local localUrl = string.format('nui://phone/media/photos/test_%d_%d.jpg', os.time(), i)
        local mediaId = MySQL.insert.await([[
            INSERT INTO phone_media (owner_number, media_type, file_url, file_size, metadata_json)
            VALUES (?, ?, ?, ?, ?)
        ]], {
            testPhoneNumber,
            'photo',
            localUrl,
            1024,
            json.encode({upload_method = 'local', test = true})
        })
        
        if mediaId then
            table.insert(localMediaIds, mediaId)
        end
    end
    
    if #localMediaIds == 0 then
        LogTestResult(testName, false, 'Failed to create test local media files')
        return false
    end
    
    -- Query local media files
    local localMedia = MySQL.query.await([[
        SELECT id, file_url FROM phone_media 
        WHERE owner_number = ? AND file_url LIKE 'nui://%'
    ]], {testPhoneNumber})
    
    if not localMedia or #localMedia ~= 3 then
        LogTestResult(testName, false, 'Failed to query local media files', {
            expected = 3,
            found = localMedia and #localMedia or 0
        })
        -- Cleanup
        for _, id in ipairs(localMediaIds) do
            MySQL.query.await('DELETE FROM phone_media WHERE id = ?', {id})
        end
        return false
    end
    
    -- Simulate migration (upload to Fivemanage and update database)
    local migratedCount = 0
    local failedCount = 0
    
    for _, media in ipairs(localMedia) do
        -- Generate test data for upload
        local testData = GenerateTestImage()
        local filename = 'migrated_' .. media.id .. '_' .. os.time() .. '.jpg'
        
        local uploadUrl, uploadError = Storage.UploadToFivemanage(
            filename,
            testData,
            'photo',
            {migrated = true, original_id = media.id},
            testPhoneNumber,
            0,
            nil
        )
        
        if uploadUrl then
            -- Update database with new URL
            local updated = MySQL.query.await([[
                UPDATE phone_media 
                SET file_url = ?, metadata_json = JSON_SET(metadata_json, '$.upload_method', 'fivemanage', '$.migrated', true)
                WHERE id = ?
            ]], {uploadUrl, media.id})
            
            if updated then
                migratedCount = migratedCount + 1
            else
                failedCount = failedCount + 1
            end
        else
            failedCount = failedCount + 1
        end
    end
    
    -- Verify migration results
    local fivemanageMedia = MySQL.query.await([[
        SELECT id, file_url FROM phone_media 
        WHERE owner_number = ? AND (file_url LIKE 'https://cdn.fivemanage.com%' OR file_url LIKE 'https://api.fivemanage.com%')
    ]], {testPhoneNumber})
    
    local success = fivemanageMedia and #fivemanageMedia == migratedCount
    
    if success then
        LogTestResult(testName, true, 'Migration completed successfully', {
            migrated = migratedCount,
            failed = failedCount,
            total = #localMedia
        })
    else
        LogTestResult(testName, false, 'Migration verification failed', {
            migrated = migratedCount,
            failed = failedCount,
            verified = fivemanageMedia and #fivemanageMedia or 0
        })
    end
    
    -- Cleanup
    for _, id in ipairs(localMediaIds) do
        MySQL.query.await('DELETE FROM phone_media WHERE id = ?', {id})
    end
    
    return success
end

-- Print test summary
function IntegrationTests.PrintSummary()
    print('[Phone Test] ========================================')
    print('[Phone Test] Integration Test Summary')
    print('[Phone Test] ========================================')
    print(string.format('[Phone Test] Total Tests: %d', testResults.passed + testResults.failed))
    print(string.format('[Phone Test] Passed: %d', testResults.passed))
    print(string.format('[Phone Test] Failed: %d', testResults.failed))
    print(string.format('[Phone Test] Success Rate: %.1f%%', 
        (testResults.passed / (testResults.passed + testResults.failed)) * 100))
    print('[Phone Test] ========================================')
    
    if testResults.failed > 0 then
        print('[Phone Test] Failed Tests:')
        for _, test in ipairs(testResults.tests) do
            if not test.passed then
                print(string.format('[Phone Test]   - %s: %s', test.name, test.message))
            end
        end
        print('[Phone Test] ========================================')
    end
end

-- Run all integration tests
function IntegrationTests.RunAll()
    print('[Phone Test] ========================================')
    print('[Phone Test] Starting Fivemanage Integration Tests')
    print('[Phone Test] ========================================')
    
    -- Reset test results
    testResults = {
        passed = 0,
        failed = 0,
        tests = {}
    }
    
    -- Check if Fivemanage is configured
    local configValid, configError = Storage.ValidateFivemanageConfig()
    if not configValid then
        print('[Phone Test] ✗ Fivemanage configuration invalid: ' .. configError)
        print('[Phone Test] Please configure Fivemanage before running integration tests')
        print('[Phone Test] ========================================')
        return
    end
    
    print('[Phone Test] ✓ Fivemanage configuration valid')
    print('[Phone Test] ')
    
    -- Run tests
    IntegrationTests.TestPhotoUpload()
    Wait(1000)
    
    IntegrationTests.TestVideoUpload()
    Wait(1000)
    
    IntegrationTests.TestAudioUpload()
    Wait(1000)
    
    IntegrationTests.TestInvalidApiKey()
    Wait(1000)
    
    IntegrationTests.TestOversizedFile()
    Wait(500)
    
    IntegrationTests.TestNetworkTimeout()
    Wait(1000)
    
    IntegrationTests.TestFallbackToLocal()
    Wait(1000)
    
    IntegrationTests.TestShotzPhotoPosting()
    Wait(1000)
    
    IntegrationTests.TestModishVideoPosting()
    Wait(1000)
    
    IntegrationTests.TestMultipleMediaAttachments()
    Wait(1000)
    
    IntegrationTests.TestMigrationCommand()
    Wait(1000)
    
    -- Print summary
    print('[Phone Test] ')
    IntegrationTests.PrintSummary()
end

-- Register command to run integration tests
RegisterCommand('phone:run-integration-tests', function(source, args, rawCommand)
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
    
    -- Run tests in a separate thread to avoid blocking
    CreateThread(function()
        IntegrationTests.RunAll()
        
        -- Notify player if not console
        if source ~= 0 then
            TriggerClientEvent('phone:notify', source, {
                type = 'success',
                title = 'Tests Complete',
                message = string.format('%d passed, %d failed', testResults.passed, testResults.failed),
                duration = 7000
            })
        end
    end)
end, true)

-- Register command to run specific test
RegisterCommand('phone:run-test', function(source, args, rawCommand)
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
    
    local testName = args[1]
    if not testName then
        print('[Phone] Usage: /phone:run-test <test_name>')
        print('[Phone] Available tests:')
        print('[Phone]   - photo')
        print('[Phone]   - video')
        print('[Phone]   - audio')
        print('[Phone]   - invalid_api')
        print('[Phone]   - oversized')
        print('[Phone]   - timeout')
        print('[Phone]   - fallback')
        print('[Phone]   - shotz')
        print('[Phone]   - modish')
        print('[Phone]   - multi_attach')
        print('[Phone]   - migration')
        return
    end
    
    -- Reset test results
    testResults = {
        passed = 0,
        failed = 0,
        tests = {}
    }
    
    CreateThread(function()
        local testMap = {
            photo = IntegrationTests.TestPhotoUpload,
            video = IntegrationTests.TestVideoUpload,
            audio = IntegrationTests.TestAudioUpload,
            invalid_api = IntegrationTests.TestInvalidApiKey,
            oversized = IntegrationTests.TestOversizedFile,
            timeout = IntegrationTests.TestNetworkTimeout,
            fallback = IntegrationTests.TestFallbackToLocal,
            shotz = IntegrationTests.TestShotzPhotoPosting,
            modish = IntegrationTests.TestModishVideoPosting,
            multi_attach = IntegrationTests.TestMultipleMediaAttachments,
            migration = IntegrationTests.TestMigrationCommand
        }
        
        local testFunc = testMap[testName]
        if testFunc then
            testFunc()
            IntegrationTests.PrintSummary()
        else
            print('[Phone] Unknown test: ' .. testName)
        end
    end)
end, true)

return IntegrationTests
