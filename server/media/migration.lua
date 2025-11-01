-- Media Migration Module
-- Handles migration of local media files to Fivemanage CDN

local Migration = {}
local Storage = require('server.media.storage')

-- Migration state tracking
local migrationState = {
    inProgress = false,
    totalFiles = 0,
    processedFiles = 0,
    successCount = 0,
    failureCount = 0,
    startTime = 0,
    lastProcessedId = 0
}

-- Check if user has admin permissions
local function IsAdmin(source)
    -- For server console
    if source == 0 then
        return true
    end
    
    -- Check if player has admin ace permission
    return IsPlayerAceAllowed(source, 'phone.admin')
end

-- Register the migration command
RegisterCommand('phone:migrate-media', function(source, args, rawCommand)
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
    
    -- Check if migration is already in progress
    if migrationState.inProgress then
        local message = string.format('[Phone] Migration already in progress: %d/%d files processed (%d successful, %d failed)',
            migrationState.processedFiles, migrationState.totalFiles, 
            migrationState.successCount, migrationState.failureCount)
        
        if source == 0 then
            print(message)
        else
            TriggerClientEvent('phone:notify', source, {
                type = 'info',
                title = 'Migration In Progress',
                message = message,
                duration = 5000
            })
        end
        return
    end
    
    -- Parse optional parameters
    local batchSize = tonumber(args[1]) or 10 -- Default batch size: 10 files at a time
    local startOffset = tonumber(args[2]) or 0 -- Default starting offset: 0
    
    -- Validate parameters
    if batchSize < 1 or batchSize > 100 then
        local message = '[Phone] Invalid batch size. Must be between 1 and 100.'
        if source == 0 then
            print(message)
        else
            TriggerClientEvent('phone:notify', source, {
                type = 'error',
                title = 'Invalid Parameter',
                message = message,
                duration = 5000
            })
        end
        return
    end
    
    if startOffset < 0 then
        local message = '[Phone] Invalid offset. Must be 0 or greater.'
        if source == 0 then
            print(message)
        else
            TriggerClientEvent('phone:notify', source, {
                type = 'error',
                title = 'Invalid Parameter',
                message = message,
                duration = 5000
            })
        end
        return
    end
    
    -- Start migration
    local message = string.format('[Phone] Starting media migration (batch size: %d, offset: %d)...', batchSize, startOffset)
    print(message)
    
    if source ~= 0 then
        TriggerClientEvent('phone:notify', source, {
            type = 'info',
            title = 'Migration Started',
            message = 'Media migration has started. Check server console for progress.',
            duration = 5000
        })
    end
    
    -- Execute migration asynchronously
    Migration.StartMigration(batchSize, startOffset, source)
end, true) -- Restricted to admins

-- Start the migration process
function Migration.StartMigration(batchSize, startOffset, commandSource)
    -- Set migration state
    migrationState.inProgress = true
    migrationState.totalFiles = 0
    migrationState.processedFiles = 0
    migrationState.successCount = 0
    migrationState.failureCount = 0
    migrationState.startTime = os.time()
    migrationState.lastProcessedId = 0
    
    -- Run migration in a separate thread
    CreateThread(function()
        local success, error = pcall(function()
            Migration.ExecuteMigration(batchSize, startOffset, commandSource)
        end)
        
        if not success then
            print('[Phone] [ERROR] Migration failed with error: ' .. tostring(error))
            migrationState.inProgress = false
        end
    end)
end

-- Execute the migration
function Migration.ExecuteMigration(batchSize, startOffset, commandSource)
    print('[Phone] ========================================')
    print('[Phone] Media Migration Started')
    print('[Phone] ========================================')
    
    -- Query local media files from database
    local localMedia = Migration.QueryLocalMedia(startOffset)
    
    if not localMedia or #localMedia == 0 then
        print('[Phone] No local media files found to migrate.')
        print('[Phone] Migration complete.')
        migrationState.inProgress = false
        
        if commandSource and commandSource ~= 0 then
            TriggerClientEvent('phone:notify', commandSource, {
                type = 'info',
                title = 'Migration Complete',
                message = 'No local media files found to migrate.',
                duration = 5000
            })
        end
        return
    end
    
    migrationState.totalFiles = #localMedia
    print(string.format('[Phone] Found %d local media files to migrate', migrationState.totalFiles))
    
    -- Process files in batches
    local currentBatch = {}
    local batchCount = 0
    
    for i, media in ipairs(localMedia) do
        table.insert(currentBatch, media)
        
        -- Process batch when it reaches the batch size or it's the last file
        if #currentBatch >= batchSize or i == #localMedia then
            batchCount = batchCount + 1
            print(string.format('[Phone] Processing batch %d (%d files)...', batchCount, #currentBatch))
            
            -- Process the batch
            Migration.ProcessBatch(currentBatch)
            
            -- Clear batch for next iteration
            currentBatch = {}
            
            -- Small delay between batches to avoid overwhelming the system
            Wait(100)
        end
    end
    
    -- Display final summary
    Migration.DisplaySummary(commandSource)
    
    -- Reset migration state
    migrationState.inProgress = false
end

-- Query local media files from database
function Migration.QueryLocalMedia(startOffset)
    print('[Phone] Querying local media files from database...')
    
    -- Select all media with local URLs (nui:// prefix)
    -- Order by created_at to process oldest first
    -- Skip files that already have Fivemanage URLs to support resuming
    local query = [[
        SELECT id, owner_number, media_type, file_url, thumbnail_url, 
               duration, file_size, location_x, location_y, metadata_json, created_at
        FROM phone_media
        WHERE file_url LIKE 'nui://%'
        ORDER BY created_at ASC
    ]]
    
    if startOffset > 0 then
        query = query .. string.format(' LIMIT 999999 OFFSET %d', startOffset)
    end
    
    local result = MySQL.query.await(query, {})
    
    if result then
        print(string.format('[Phone] Found %d local media files', #result))
    else
        print('[Phone] [ERROR] Failed to query local media files')
    end
    
    return result or {}
end

-- Process a batch of media files
function Migration.ProcessBatch(batch)
    for _, media in ipairs(batch) do
        Migration.ProcessSingleFile(media)
        
        -- Log progress every 10 files
        if migrationState.processedFiles % 10 == 0 then
            Migration.LogProgress()
        end
    end
end

-- Process a single media file
function Migration.ProcessSingleFile(media)
    migrationState.processedFiles = migrationState.processedFiles + 1
    migrationState.lastProcessedId = media.id
    
    -- Extract filename from URL
    local filename = media.file_url:match('[^/]+$')
    
    if not filename then
        print(string.format('[Phone] [ERROR] Failed to extract filename from URL: %s (ID: %d)', 
            media.file_url, media.id))
        migrationState.failureCount = migrationState.failureCount + 1
        return
    end
    
    -- Read local file data from disk
    local fileData = Migration.ReadLocalFile(filename, media.media_type)
    
    if not fileData then
        print(string.format('[Phone] [ERROR] Failed to read local file: %s (ID: %d)', 
            filename, media.id))
        migrationState.failureCount = migrationState.failureCount + 1
        return
    end
    
    -- Parse existing metadata
    local metadata = {}
    if media.metadata_json then
        local success, parsed = pcall(json.decode, media.metadata_json)
        if success and parsed then
            metadata = parsed
        end
    end
    
    -- Add location data to metadata if available
    if media.location_x and media.location_y then
        metadata.location_x = media.location_x
        metadata.location_y = media.location_y
    end
    
    if media.duration then
        metadata.duration = media.duration
    end
    
    -- Upload to Fivemanage using UploadToFivemanage function
    local fivemanageUrl, uploadError, errorType, uploadResult = Storage.UploadToFivemanage(
        filename, 
        fileData, 
        media.media_type, 
        metadata, 
        media.owner_number, 
        0, -- source = 0 for server-side operations
        nil -- no progress callback for migration
    )
    
    if fivemanageUrl then
        -- Update database with new Fivemanage URL
        local updateSuccess = Migration.UpdateMediaUrl(media.id, fivemanageUrl, uploadResult)
        
        if updateSuccess then
            migrationState.successCount = migrationState.successCount + 1
            
            if Config.DebugMode then
                print(string.format('[Phone] [SUCCESS] Migrated file ID %d: %s -> %s', 
                    media.id, filename, fivemanageUrl))
            end
        else
            print(string.format('[Phone] [ERROR] Failed to update database for file ID %d: %s', 
                media.id, filename))
            migrationState.failureCount = migrationState.failureCount + 1
        end
    else
        -- Handle upload failure gracefully
        print(string.format('[Phone] [ERROR] Failed to upload file ID %d (%s): %s', 
            media.id, filename, uploadError or 'unknown error'))
        migrationState.failureCount = migrationState.failureCount + 1
    end
end

-- Read local file data from disk
function Migration.ReadLocalFile(filename, mediaType)
    local subdir = 'photos'
    
    if mediaType == 'video' then
        subdir = 'videos'
    elseif mediaType == 'audio' then
        subdir = 'audio'
    end
    
    local filePath = 'media/' .. subdir .. '/' .. filename
    
    -- Read file using LoadResourceFile
    local fileData = LoadResourceFile(GetCurrentResourceName(), filePath)
    
    if not fileData then
        if Config.DebugMode then
            print(string.format('[Phone] [DEBUG] Failed to read file: %s', filePath))
        end
        return nil
    end
    
    return fileData
end

-- Update media URL in database
function Migration.UpdateMediaUrl(mediaId, newUrl, uploadResult)
    -- Get existing metadata
    local existingMedia = MySQL.query.await('SELECT metadata_json FROM phone_media WHERE id = ?', {mediaId})
    
    if not existingMedia or #existingMedia == 0 then
        return false
    end
    
    -- Parse existing metadata
    local metadata = {}
    if existingMedia[1].metadata_json then
        local success, parsed = pcall(json.decode, existingMedia[1].metadata_json)
        if success and parsed then
            metadata = parsed
        end
    end
    
    -- Update metadata with migration info
    metadata.upload_method = 'fivemanage'
    metadata.migrated_at = os.time()
    metadata.migration_source = 'local'
    
    if uploadResult and uploadResult.id then
        metadata.fivemanage_id = uploadResult.id
    end
    
    -- Update database
    local result = MySQL.query.await([[
        UPDATE phone_media 
        SET file_url = ?, metadata_json = ?
        WHERE id = ?
    ]], {
        newUrl,
        json.encode(metadata),
        mediaId
    })
    
    return result ~= nil
end

-- Log migration progress
function Migration.LogProgress()
    local elapsed = os.time() - migrationState.startTime
    local rate = migrationState.processedFiles / math.max(elapsed, 1)
    local remaining = migrationState.totalFiles - migrationState.processedFiles
    local eta = remaining / math.max(rate, 0.1)
    
    print(string.format('[Phone] Progress: %d/%d files processed (%d successful, %d failed) | Rate: %.1f files/sec | ETA: %d seconds',
        migrationState.processedFiles, migrationState.totalFiles,
        migrationState.successCount, migrationState.failureCount,
        rate, math.floor(eta)))
end

-- Display final migration summary
function Migration.DisplaySummary(commandSource)
    local elapsed = os.time() - migrationState.startTime
    local successRate = (migrationState.successCount / math.max(migrationState.totalFiles, 1)) * 100
    
    print('[Phone] ========================================')
    print('[Phone] Migration Complete!')
    print('[Phone] ========================================')
    print(string.format('[Phone] Total Files: %d', migrationState.totalFiles))
    print(string.format('[Phone] Successful: %d (%.1f%%)', migrationState.successCount, successRate))
    print(string.format('[Phone] Failed: %d', migrationState.failureCount))
    print(string.format('[Phone] Time Elapsed: %d seconds', elapsed))
    print('[Phone] ========================================')
    
    -- Notify command source if it's a player
    if commandSource and commandSource ~= 0 then
        TriggerClientEvent('phone:notify', commandSource, {
            type = migrationState.failureCount == 0 and 'success' or 'warning',
            title = 'Migration Complete',
            message = string.format('Migrated %d/%d files successfully', 
                migrationState.successCount, migrationState.totalFiles),
            duration = 7000
        })
    end
end

-- Get migration status (for monitoring)
function Migration.GetStatus()
    return {
        inProgress = migrationState.inProgress,
        totalFiles = migrationState.totalFiles,
        processedFiles = migrationState.processedFiles,
        successCount = migrationState.successCount,
        failureCount = migrationState.failureCount,
        startTime = migrationState.startTime,
        lastProcessedId = migrationState.lastProcessedId
    }
end

return Migration
