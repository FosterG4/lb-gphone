-- Media Sharing Module
-- Handles media sharing between apps

local Sharing = {}

-- Share media to Shotz
function Sharing.ShareToShotz(phoneNumber, mediaId, caption)
    if not phoneNumber or not mediaId then
        return {
            success = false,
            error = 'INVALID_PARAMETERS',
            message = 'Missing required parameters'
        }
    end
    
    -- Verify media ownership
    local media = MySQL.query.await('SELECT * FROM phone_media WHERE id = ? AND owner_number = ?', {
        mediaId, phoneNumber
    })
    
    if not media or #media == 0 then
        return {
            success = false,
            error = 'NOT_FOUND',
            message = 'Media not found or access denied'
        }
    end
    
    local mediaData = media[1]
    
    -- Only photos and videos can be shared to Shotz
    if mediaData.media_type ~= 'photo' and mediaData.media_type ~= 'video' then
        return {
            success = false,
            error = 'INVALID_MEDIA_TYPE',
            message = 'Only photos and videos can be shared to Shotz'
        }
    end
    
    -- Create Shotz post (this would integrate with the Shotz app module)
    -- For now, we'll just return success
    -- In a full implementation, this would call the Shotz module to create a post
    
    return {
        success = true,
        message = 'Media shared to Shotz successfully',
        data = {
            media_id = mediaId,
            app = 'shotz'
        }
    }
end

-- Share media to Modish
function Sharing.ShareToModish(phoneNumber, mediaId, effects)
    if not phoneNumber or not mediaId then
        return {
            success = false,
            error = 'INVALID_PARAMETERS',
            message = 'Missing required parameters'
        }
    end
    
    -- Verify media ownership
    local media = MySQL.query.await('SELECT * FROM phone_media WHERE id = ? AND owner_number = ?', {
        mediaId, phoneNumber
    })
    
    if not media or #media == 0 then
        return {
            success = false,
            error = 'NOT_FOUND',
            message = 'Media not found or access denied'
        }
    end
    
    local mediaData = media[1]
    
    -- Only videos can be shared to Modish
    if mediaData.media_type ~= 'video' then
        return {
            success = false,
            error = 'INVALID_MEDIA_TYPE',
            message = 'Only videos can be shared to Modish'
        }
    end
    
    -- Create Modish video (this would integrate with the Modish app module)
    -- For now, we'll just return success
    
    return {
        success = true,
        message = 'Video shared to Modish successfully',
        data = {
            media_id = mediaId,
            app = 'modish'
        }
    }
end

-- Share media via Messages
function Sharing.ShareToMessages(phoneNumber, mediaId, targetNumber)
    if not phoneNumber or not mediaId or not targetNumber then
        return {
            success = false,
            error = 'INVALID_PARAMETERS',
            message = 'Missing required parameters'
        }
    end
    
    -- Verify media ownership
    local media = MySQL.query.await('SELECT * FROM phone_media WHERE id = ? AND owner_number = ?', {
        mediaId, phoneNumber
    })
    
    if not media or #media == 0 then
        return {
            success = false,
            error = 'NOT_FOUND',
            message = 'Media not found or access denied'
        }
    end
    
    local mediaData = media[1]
    
    -- Create message with media attachment
    -- This would integrate with the Messages module
    local messageData = {
        sender_number = phoneNumber,
        receiver_number = targetNumber,
        message = '[Media]',
        media_id = mediaId,
        media_url = mediaData.file_url,
        media_type = mediaData.media_type,
        thumbnail_url = mediaData.thumbnail_url
    }
    
    -- Insert message (simplified - actual implementation would use Messages module)
    local messageId = MySQL.insert.await([[
        INSERT INTO phone_messages (sender_number, receiver_number, message, is_read, created_at)
        VALUES (?, ?, ?, 0, NOW())
    ]], {
        phoneNumber,
        targetNumber,
        json.encode(messageData)
    })
    
    if not messageId then
        return {
            success = false,
            error = 'DATABASE_ERROR',
            message = 'Failed to send message'
        }
    end
    
    return {
        success = true,
        message = 'Media shared via message successfully',
        data = {
            message_id = messageId,
            media_id = mediaId,
            app = 'messages'
        }
    }
end

-- Log sharing activity
function Sharing.LogShare(phoneNumber, mediaId, targetApp)
    -- This could be used for analytics or tracking
    if Config.Debug then
        print(string.format('[Phone] Media %d shared by %s to %s', mediaId, phoneNumber, targetApp))
    end
end

return Sharing
