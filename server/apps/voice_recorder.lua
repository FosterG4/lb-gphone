-- Voice Recorder App Server Logic
-- Handles voice recording, playback, and file management

-- Get voice recorder data for player
RegisterNetEvent('phone:server:getVoiceRecorderData', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveVoiceRecorderData', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Get recordings from database
    local recordings = MySQL.query.await([[
        SELECT 
            id,
            name,
            duration,
            file_size as size,
            quality,
            file_path,
            UNIX_TIMESTAMP(created_at) * 1000 as createdAt
        FROM phone_voice_recordings
        WHERE phone_number = ?
        ORDER BY created_at DESC
        LIMIT ?
    ]], {
        phoneNumber,
        Config.VoiceRecorderApp.maxRecordings or 50
    })
    
    -- Get settings from database
    local settings = MySQL.query.await([[
        SELECT 
            auto_save,
            background_recording,
            max_recording_length,
            auto_cleanup,
            recording_quality
        FROM phone_voice_recorder_settings
        WHERE phone_number = ?
    ]], {
        phoneNumber
    })
    
    local userSettings = {
        autoSave = true,
        backgroundRecording = false,
        maxRecordingLength = 600,
        autoCleanup = true,
        recordingQuality = 'medium'
    }
    
    if settings and #settings > 0 then
        local dbSettings = settings[1]
        userSettings = {
            autoSave = dbSettings.auto_save == 1,
            backgroundRecording = dbSettings.background_recording == 1,
            maxRecordingLength = dbSettings.max_recording_length or 600,
            autoCleanup = dbSettings.auto_cleanup == 1,
            recordingQuality = dbSettings.recording_quality or 'medium'
        }
    end
    
    TriggerClientEvent('phone:client:receiveVoiceRecorderData', source, {
        success = true,
        recordings = recordings or {},
        settings = userSettings
    })
end)

-- Start recording
RegisterNetEvent('phone:server:startRecording', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    local quality = data.quality or 'medium'
    local maxLength = data.maxLength or 600
    
    -- Check if player already has too many recordings
    local recordingCount = MySQL.scalar.await([[
        SELECT COUNT(*) 
        FROM phone_voice_recordings 
        WHERE phone_number = ?
    ]], {
        phoneNumber
    })
    
    if recordingCount >= (Config.VoiceRecorderApp.maxRecordings or 50) then
        TriggerClientEvent('phone:client:recordingError', source, {
            error = 'Maximum recordings reached'
        })
        return
    end
    
    -- Store recording session data
    if not GlobalState.activeRecordings then
        GlobalState.activeRecordings = {}
    end
    
    GlobalState.activeRecordings[source] = {
        phoneNumber = phoneNumber,
        quality = quality,
        maxLength = maxLength,
        startTime = GetGameTimer()
    }
    
    -- Trigger client-side recording start
    TriggerClientEvent('phone:client:recordingStarted', source, {
        quality = quality,
        maxLength = maxLength
    })
    
    if Config.DebugMode then
        print(string.format('[VoiceRecorder] %s started recording (quality: %s)', phoneNumber, quality))
    end
end)

-- Pause recording
RegisterNetEvent('phone:server:pauseRecording', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local recordingData = GlobalState.activeRecordings and GlobalState.activeRecordings[source]
    if not recordingData then
        return
    end
    
    recordingData.pausedAt = GetGameTimer()
    
    TriggerClientEvent('phone:client:recordingPaused', source)
    
    if Config.DebugMode then
        print(string.format('[VoiceRecorder] %s paused recording', recordingData.phoneNumber))
    end
end)

-- Resume recording
RegisterNetEvent('phone:server:resumeRecording', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local recordingData = GlobalState.activeRecordings and GlobalState.activeRecordings[source]
    if not recordingData or not recordingData.pausedAt then
        return
    end
    
    -- Add paused time to start time
    local pausedDuration = GetGameTimer() - recordingData.pausedAt
    recordingData.startTime = recordingData.startTime + pausedDuration
    recordingData.pausedAt = nil
    
    TriggerClientEvent('phone:client:recordingResumed', source)
    
    if Config.DebugMode then
        print(string.format('[VoiceRecorder] %s resumed recording', recordingData.phoneNumber))
    end
end)

-- Save recording
RegisterNetEvent('phone:server:saveRecording', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local recordingData = GlobalState.activeRecordings and GlobalState.activeRecordings[source]
    if not recordingData then
        return
    end
    
    local recording = data.recording
    local autoSave = data.autoSave
    
    -- Calculate actual duration
    local actualDuration = math.floor((GetGameTimer() - recordingData.startTime) / 1000)
    recording.duration = actualDuration
    
    -- Estimate file size based on quality and duration
    local bitrates = {
        low = 32,
        medium = 64,
        high = 128,
        ultra = 256
    }
    
    local bitrate = bitrates[recording.quality] or 64
    local estimatedSize = math.floor((actualDuration * bitrate * 1000) / 8)
    recording.size = estimatedSize
    
    -- Generate unique file path
    local fileName = string.format('recording_%s_%d.mp3', recordingData.phoneNumber, recording.id)
    recording.filePath = string.format('/voice_recordings/%s', fileName)
    
    -- Save to database
    local insertId = MySQL.insert.await([[
        INSERT INTO phone_voice_recordings 
        (phone_number, name, duration, file_size, quality, file_path)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        recordingData.phoneNumber,
        recording.name,
        recording.duration,
        recording.size,
        recording.quality,
        recording.filePath
    })
    
    if insertId then
        recording.id = insertId
        recording.createdAt = GetGameTimer()
        
        TriggerClientEvent('phone:client:recordingSaved', source, {
            success = true,
            recording = recording
        })
        
        if Config.DebugMode then
            print(string.format('[VoiceRecorder] %s saved recording: %s (%ds)', 
                recordingData.phoneNumber, recording.name, recording.duration))
        end
    else
        TriggerClientEvent('phone:client:recordingSaved', source, {
            success = false,
            error = 'Failed to save recording'
        })
    end
    
    -- Clear recording session
    if GlobalState.activeRecordings then
        GlobalState.activeRecordings[source] = nil
    end
end)

-- Cancel recording
RegisterNetEvent('phone:server:cancelRecording', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local recordingData = GlobalState.activeRecordings and GlobalState.activeRecordings[source]
    if not recordingData then
        return
    end
    
    -- Clear recording session
    if GlobalState.activeRecordings then
        GlobalState.activeRecordings[source] = nil
    end
    
    TriggerClientEvent('phone:client:recordingCancelled', source)
    
    if Config.DebugMode then
        print(string.format('[VoiceRecorder] %s cancelled recording', recordingData.phoneNumber))
    end
end)

-- Start playback
RegisterNetEvent('phone:server:startPlayback', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local recording = data.recording
    
    -- Verify recording belongs to player
    local phoneNumber = Framework:GetPhoneNumber(source)
    local dbRecording = MySQL.query.await([[
        SELECT id, file_path, duration
        FROM phone_voice_recordings
        WHERE id = ? AND phone_number = ?
    ]], {
        recording.id,
        phoneNumber
    })
    
    if not dbRecording or #dbRecording == 0 then
        TriggerClientEvent('phone:client:playbackError', source, {
            error = 'Recording not found'
        })
        return
    end
    
    -- Trigger client-side playback
    TriggerClientEvent('phone:client:playbackStarted', source, {
        recording = recording
    })
    
    if Config.DebugMode then
        print(string.format('[VoiceRecorder] %s started playback: %s', phoneNumber, recording.name))
    end
end)

-- Stop playback
RegisterNetEvent('phone:server:stopPlayback', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    TriggerClientEvent('phone:client:playbackStopped', source, {
        recordingId = data.recordingId
    })
    
    if Config.DebugMode then
        local phoneNumber = Framework:GetPhoneNumber(source)
        print(string.format('[VoiceRecorder] %s stopped playback', phoneNumber))
    end
end)

-- Delete recording
RegisterNetEvent('phone:server:deleteRecording', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    local recordingId = data.recordingId
    
    -- Verify recording belongs to player and get file path
    local recording = MySQL.query.await([[
        SELECT file_path
        FROM phone_voice_recordings
        WHERE id = ? AND phone_number = ?
    ]], {
        recordingId,
        phoneNumber
    })
    
    if not recording or #recording == 0 then
        TriggerClientEvent('phone:client:deleteRecordingResult', source, {
            success = false,
            error = 'Recording not found'
        })
        return
    end
    
    -- Delete from database
    local affectedRows = MySQL.update.await([[
        DELETE FROM phone_voice_recordings
        WHERE id = ? AND phone_number = ?
    ]], {
        recordingId,
        phoneNumber
    })
    
    if affectedRows > 0 then
        TriggerClientEvent('phone:client:deleteRecordingResult', source, {
            success = true,
            recordingId = recordingId
        })
        
        if Config.DebugMode then
            print(string.format('[VoiceRecorder] %s deleted recording ID: %d', phoneNumber, recordingId))
        end
    else
        TriggerClientEvent('phone:client:deleteRecordingResult', source, {
            success = false,
            error = 'Failed to delete recording'
        })
    end
end)

-- Delete multiple recordings
RegisterNetEvent('phone:server:deleteRecordings', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    local recordingIds = data.recordingIds
    
    if not recordingIds or #recordingIds == 0 then
        return
    end
    
    -- Create placeholders for IN clause
    local placeholders = {}
    local params = {phoneNumber}
    
    for i, recordingId in ipairs(recordingIds) do
        table.insert(placeholders, '?')
        table.insert(params, recordingId)
    end
    
    local query = string.format([[
        DELETE FROM phone_voice_recordings
        WHERE phone_number = ? AND id IN (%s)
    ]], table.concat(placeholders, ','))
    
    local affectedRows = MySQL.update.await(query, params)
    
    TriggerClientEvent('phone:client:deleteRecordingsResult', source, {
        success = affectedRows > 0,
        deletedCount = affectedRows,
        recordingIds = recordingIds
    })
    
    if Config.DebugMode then
        print(string.format('[VoiceRecorder] %s deleted %d recordings', phoneNumber, affectedRows))
    end
end)

-- Rename recording
RegisterNetEvent('phone:server:renameRecording', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    local recordingId = data.recordingId
    local newName = data.newName
    
    if not newName or string.len(newName) == 0 then
        return
    end
    
    -- Sanitize name
    newName = string.sub(newName, 1, 50)
    
    -- Update database
    local affectedRows = MySQL.update.await([[
        UPDATE phone_voice_recordings
        SET name = ?
        WHERE id = ? AND phone_number = ?
    ]], {
        newName,
        recordingId,
        phoneNumber
    })
    
    TriggerClientEvent('phone:client:renameRecordingResult', source, {
        success = affectedRows > 0,
        recordingId = recordingId,
        newName = newName
    })
    
    if Config.DebugMode then
        print(string.format('[VoiceRecorder] %s renamed recording ID %d to: %s', phoneNumber, recordingId, newName))
    end
end)

-- Share recording to messages
RegisterNetEvent('phone:server:shareToMessages', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    local recordings = data.recordings
    
    -- This would integrate with the messages app
    -- For now, we'll just trigger a client event
    TriggerClientEvent('phone:client:shareToMessagesResult', source, {
        success = true,
        recordings = recordings
    })
    
    if Config.DebugMode then
        print(string.format('[VoiceRecorder] %s shared %d recordings to messages', phoneNumber, #recordings))
    end
end)

-- Share recording to email
RegisterNetEvent('phone:server:shareToEmail', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    local recordings = data.recordings
    
    -- This would integrate with an email system
    TriggerClientEvent('phone:client:shareToEmailResult', source, {
        success = true,
        recordings = recordings
    })
    
    if Config.DebugMode then
        print(string.format('[VoiceRecorder] %s shared %d recordings to email', phoneNumber, #recordings))
    end
end)

-- Share recording to cloud
RegisterNetEvent('phone:server:shareToCloud', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    local recordings = data.recordings
    
    -- This would integrate with a cloud storage system
    TriggerClientEvent('phone:client:shareToCloudResult', source, {
        success = true,
        recordings = recordings
    })
    
    if Config.DebugMode then
        print(string.format('[VoiceRecorder] %s shared %d recordings to cloud', phoneNumber, #recordings))
    end
end)

-- Export recording to device
RegisterNetEvent('phone:server:exportToDevice', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    local recordings = data.recordings
    
    -- This would handle file export
    TriggerClientEvent('phone:client:exportToDeviceResult', source, {
        success = true,
        recordings = recordings
    })
    
    if Config.DebugMode then
        print(string.format('[VoiceRecorder] %s exported %d recordings to device', phoneNumber, #recordings))
    end
end)

-- Save settings
RegisterNetEvent('phone:server:saveVoiceRecorderSettings', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    local quality = data.quality or 'medium'
    local settings = data.settings
    
    -- Update or insert settings
    MySQL.query.await([[
        INSERT INTO phone_voice_recorder_settings 
        (phone_number, auto_save, background_recording, max_recording_length, auto_cleanup, recording_quality)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        auto_save = VALUES(auto_save),
        background_recording = VALUES(background_recording),
        max_recording_length = VALUES(max_recording_length),
        auto_cleanup = VALUES(auto_cleanup),
        recording_quality = VALUES(recording_quality)
    ]], {
        phoneNumber,
        settings.autoSave and 1 or 0,
        settings.backgroundRecording and 1 or 0,
        settings.maxRecordingLength or 600,
        settings.autoCleanup and 1 or 0,
        quality
    })
    
    TriggerClientEvent('phone:client:saveVoiceRecorderSettingsResult', source, {
        success = true
    })
    
    if Config.DebugMode then
        print(string.format('[VoiceRecorder] %s saved settings', phoneNumber))
    end
end)

-- Cleanup old recordings
RegisterNetEvent('phone:server:cleanupRecordings', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    local deletedIds = data.deletedIds or {}
    
    if #deletedIds == 0 then
        return
    end
    
    -- Create placeholders for IN clause
    local placeholders = {}
    local params = {phoneNumber}
    
    for i, recordingId in ipairs(deletedIds) do
        table.insert(placeholders, '?')
        table.insert(params, recordingId)
    end
    
    local query = string.format([[
        DELETE FROM phone_voice_recordings
        WHERE phone_number = ? AND id IN (%s)
    ]], table.concat(placeholders, ','))
    
    local affectedRows = MySQL.update.await(query, params)
    
    TriggerClientEvent('phone:client:cleanupRecordingsResult', source, {
        success = affectedRows > 0,
        deletedCount = affectedRows
    })
    
    if Config.DebugMode then
        print(string.format('[VoiceRecorder] %s cleaned up %d recordings', phoneNumber, affectedRows))
    end
end)

-- Cleanup task for old recordings (runs periodically)
CreateThread(function()
    while true do
        Wait(3600000) -- Run every hour
        
        if Config.VoiceRecorderApp.autoCleanupEnabled then
            local maxAge = Config.VoiceRecorderApp.maxRecordingAge or (30 * 24 * 60 * 60) -- 30 days
            
            local deletedCount = MySQL.update.await([[
                DELETE FROM phone_voice_recordings
                WHERE created_at < DATE_SUB(NOW(), INTERVAL ? SECOND)
            ]], {
                maxAge
            })
            
            if Config.DebugMode and deletedCount > 0 then
                print(string.format('[VoiceRecorder] Auto-cleanup removed %d old recordings', deletedCount))
            end
        end
    end
end)

-- Handle player disconnect - cleanup active recordings
AddEventHandler('playerDropped', function(reason)
    local source = source
    
    if GlobalState.activeRecordings and GlobalState.activeRecordings[source] then
        GlobalState.activeRecordings[source] = nil
        
        if Config.DebugMode then
            print(string.format('[VoiceRecorder] Cleaned up recording session for disconnected player %d', source))
        end
    end
end)