-- Modish App Server Logic
-- Handles short video sharing operations including posting, feed, likes, comments, views, filters, TTS, and music

-- Rate limiting for video creation
local videoCooldowns = {}

-- Get Modish feed
RegisterNetEvent('phone:server:getModishFeed', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveModishFeed', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    local limit = data.limit or 20
    local offset = data.offset or 0
    
    -- Get feed (all videos, ordered by newest first)
    local feed = MySQL.query.await([[
        SELECT 
            v.id,
            v.author_number,
            v.author_name,
            v.caption,
            v.music_track,
            v.filters_json,
            v.likes,
            v.views,
            m.file_url as media_url,
            m.thumbnail_url,
            m.duration,
            UNIX_TIMESTAMP(v.created_at) * 1000 as created_at
        FROM phone_modish_videos v
        INNER JOIN phone_media m ON v.media_id = m.id
        ORDER BY v.created_at DESC
        LIMIT ? OFFSET ?
    ]], {
        limit,
        offset
    })
    
    -- Get user's liked videos
    local likedVideos = MySQL.query.await([[
        SELECT video_id
        FROM phone_modish_likes
        WHERE phone_number = ?
    ]], {
        phoneNumber
    })
    
    -- Create set for quick lookup
    local likedSet = {}
    for _, like in ipairs(likedVideos or {}) do
        likedSet[like.video_id] = true
    end
    
    -- Mark videos with user interaction status
    for _, video in ipairs(feed or {}) do
        video.isLiked = likedSet[video.id] or false
        video.media_type = 'video'
        
        -- Parse filters JSON if exists
        if video.filters_json then
            video.filters = json.decode(video.filters_json)
        end
    end
    
    TriggerClientEvent('phone:client:receiveModishFeed', source, {
        success = true,
        feed = feed or {}
    })
end)

-- Get user's own videos
RegisterNetEvent('phone:server:getMyModishVideos', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    local myVideos = MySQL.query.await([[
        SELECT 
            v.id,
            v.author_number,
            v.author_name,
            v.caption,
            v.music_track,
            v.filters_json,
            v.likes,
            v.views,
            m.file_url as media_url,
            m.thumbnail_url,
            m.duration,
            UNIX_TIMESTAMP(v.created_at) * 1000 as created_at
        FROM phone_modish_videos v
        INNER JOIN phone_media m ON v.media_id = m.id
        WHERE v.author_number = ?
        ORDER BY v.created_at DESC
    ]], {
        phoneNumber
    })
    
    -- Parse filters JSON for each video
    for _, video in ipairs(myVideos or {}) do
        if video.filters_json then
            video.filters = json.decode(video.filters_json)
        end
        video.media_type = 'video'
    end
    
    TriggerClientEvent('phone:client:receiveMyModishVideos', source, {
        success = true,
        videos = myVideos or {}
    })
end)

-- Create a new video
RegisterNetEvent('phone:server:createModishVideo', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local mediaId = tonumber(data.mediaId)
    local caption = data.caption or ''
    local filters = data.filters
    local tts = data.tts
    local music = data.music
    
    -- Validation
    if not mediaId then
        TriggerClientEvent('phone:client:createModishVideoResult', source, {
            success = false,
            message = 'Invalid media ID'
        })
        return
    end
    
    -- Trim caption
    caption = caption:gsub("^%s*(.-)%s*$", "%1")
    
    -- Validate caption length
    if #caption > (Config.Modish.maxCaptionLength or 500) then
        TriggerClientEvent('phone:client:createModishVideoResult', source, {
            success = false,
            message = 'Caption is too long (max 500 characters)'
        })
        return
    end
    
    -- Get phone number and author name
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:createModishVideoResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Rate limiting check
    local currentTime = os.time()
    if videoCooldowns[phoneNumber] and (currentTime - videoCooldowns[phoneNumber]) < 10 then
        local remainingTime = 10 - (currentTime - videoCooldowns[phoneNumber])
        TriggerClientEvent('phone:client:createModishVideoResult', source, {
            success = false,
            message = string.format('Please wait %d seconds before posting again', remainingTime)
        })
        return
    end
    
    -- Verify media ownership and that it's a video
    local media = MySQL.query.await([[
        SELECT id, media_type, file_url, thumbnail_url, duration
        FROM phone_media
        WHERE id = ? AND owner_number = ? AND media_type = 'video'
    ]], {
        mediaId,
        phoneNumber
    })
    
    if not media or #media == 0 then
        TriggerClientEvent('phone:client:createModishVideoResult', source, {
            success = false,
            message = 'Video not found or you do not own this video'
        })
        return
    end
    
    -- Validate video length
    local maxVideoLength = Config.Modish.maxVideoLength or 60
    if media[1].duration and media[1].duration > maxVideoLength then
        TriggerClientEvent('phone:client:createModishVideoResult', source, {
            success = false,
            message = string.format('Video is too long (max %d seconds)', maxVideoLength)
        })
        return
    end
    
    -- Get author name
    local authorName = Framework:GetPlayerName(source) or phoneNumber
    
    -- Prepare filters JSON
    local filtersJson = nil
    if filters then
        filtersJson = json.encode(filters)
    end
    
    -- Prepare music track name
    local musicTrack = nil
    if music and music ~= '' then
        musicTrack = music
    end
    
    -- Insert video into database
    local insertId = MySQL.insert.await([[
        INSERT INTO phone_modish_videos (author_number, author_name, media_id, caption, music_track, filters_json, likes, views)
        VALUES (?, ?, ?, ?, ?, ?, 0, 0)
    ]], {
        phoneNumber,
        authorName,
        mediaId,
        caption,
        musicTrack,
        filtersJson
    })
    
    if not insertId then
        TriggerClientEvent('phone:client:createModishVideoResult', source, {
            success = false,
            message = 'Failed to create video'
        })
        return
    end
    
    -- Update cooldown
    videoCooldowns[phoneNumber] = currentTime
    
    -- Get the created video
    local video = MySQL.query.await([[
        SELECT 
            v.id,
            v.author_number,
            v.author_name,
            v.caption,
            v.music_track,
            v.filters_json,
            v.likes,
            v.views,
            m.file_url as media_url,
            m.thumbnail_url,
            m.duration,
            UNIX_TIMESTAMP(v.created_at) * 1000 as created_at
        FROM phone_modish_videos v
        INNER JOIN phone_media m ON v.media_id = m.id
        WHERE v.id = ?
    ]], {
        insertId
    })
    
    if video and #video > 0 then
        video[1].isLiked = false
        video[1].media_type = 'video'
        
        if video[1].filters_json then
            video[1].filters = json.decode(video[1].filters_json)
        end
        
        -- Send success response to poster
        TriggerClientEvent('phone:client:createModishVideoResult', source, {
            success = true,
            video = video[1]
        })
        
        -- Broadcast new video to all online players
        TriggerClientEvent('phone:client:newModishVideo', -1, video[1])
    else
        TriggerClientEvent('phone:client:createModishVideoResult', source, {
            success = false,
            message = 'Failed to retrieve created video'
        })
    end
end)

-- Like/unlike a video
RegisterNetEvent('phone:server:likeModishVideo', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local videoId = tonumber(data.videoId)
    
    if not videoId then
        TriggerClientEvent('phone:client:likeModishVideoResult', source, {
            success = false,
            message = 'Invalid video ID'
        })
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:likeModishVideoResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Check if video exists
    local video = MySQL.query.await('SELECT id, likes, author_number FROM phone_modish_videos WHERE id = ?', {
        videoId
    })
    
    if not video or #video == 0 then
        TriggerClientEvent('phone:client:likeModishVideoResult', source, {
            success = false,
            message = 'Video not found'
        })
        return
    end
    
    -- Check if user has already liked this video
    local existingLike = MySQL.query.await([[
        SELECT id FROM phone_modish_likes
        WHERE phone_number = ? AND video_id = ?
    ]], {
        phoneNumber,
        videoId
    })
    
    local isLiked = false
    local newLikes = video[1].likes
    
    if existingLike and #existingLike > 0 then
        -- Unlike: Remove like and decrement count
        MySQL.query.await('DELETE FROM phone_modish_likes WHERE phone_number = ? AND video_id = ?', {
            phoneNumber,
            videoId
        })
        
        newLikes = math.max(0, newLikes - 1)
        isLiked = false
    else
        -- Like: Add like and increment count
        MySQL.insert.await('INSERT INTO phone_modish_likes (phone_number, video_id) VALUES (?, ?)', {
            phoneNumber,
            videoId
        })
        
        newLikes = newLikes + 1
        isLiked = true
        
        -- Notify video author
        if video[1].author_number ~= phoneNumber then
            TriggerEvent('phone:server:sendNotification', video[1].author_number, {
                app = 'modish',
                title = 'New Like',
                message = 'Someone liked your video'
            })
        end
    end
    
    -- Update video likes count
    MySQL.update.await('UPDATE phone_modish_videos SET likes = ? WHERE id = ?', {
        newLikes,
        videoId
    })
    
    -- Send response
    TriggerClientEvent('phone:client:likeModishVideoResult', source, {
        success = true,
        videoId = videoId,
        likes = newLikes,
        isLiked = isLiked
    })
    
    -- Broadcast like update to all online players
    TriggerClientEvent('phone:client:modishVideoLikeUpdate', -1, {
        videoId = videoId,
        likes = newLikes
    })
end)

-- Increment view count
RegisterNetEvent('phone:server:incrementModishViews', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local videoId = tonumber(data.videoId)
    
    if not videoId then
        return
    end
    
    -- Increment view count
    MySQL.query.await('UPDATE phone_modish_videos SET views = views + 1 WHERE id = ?', {
        videoId
    })
    
    -- Get updated view count
    local video = MySQL.query.await('SELECT views FROM phone_modish_videos WHERE id = ?', {
        videoId
    })
    
    if video and #video > 0 then
        -- Broadcast view update
        TriggerClientEvent('phone:client:modishVideoViewUpdate', -1, {
            videoId = videoId,
            views = video[1].views
        })
    end
end)

-- Get comments for a video
RegisterNetEvent('phone:server:getModishComments', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local videoId = tonumber(data.videoId)
    
    if not videoId then
        return
    end
    
    local comments = MySQL.query.await([[
        SELECT 
            id,
            author_number,
            author_name,
            content,
            UNIX_TIMESTAMP(created_at) * 1000 as created_at
        FROM phone_modish_comments
        WHERE video_id = ?
        ORDER BY created_at ASC
    ]], {
        videoId
    })
    
    TriggerClientEvent('phone:client:receiveModishComments', source, {
        success = true,
        videoId = videoId,
        comments = comments or {}
    })
end)

-- Comment on a video
RegisterNetEvent('phone:server:commentOnModishVideo', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local videoId = tonumber(data.videoId)
    local content = data.content
    
    -- Validation
    if not videoId or not content or type(content) ~= 'string' then
        TriggerClientEvent('phone:client:commentOnModishVideoResult', source, {
            success = false,
            message = 'Invalid comment data'
        })
        return
    end
    
    -- Trim content
    content = content:gsub("^%s*(.-)%s*$", "%1")
    
    -- Validate content length
    if #content == 0 then
        TriggerClientEvent('phone:client:commentOnModishVideoResult', source, {
            success = false,
            message = 'Comment cannot be empty'
        })
        return
    end
    
    if #content > 500 then
        TriggerClientEvent('phone:client:commentOnModishVideoResult', source, {
            success = false,
            message = 'Comment is too long (max 500 characters)'
        })
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:commentOnModishVideoResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Check if video exists
    local video = MySQL.query.await('SELECT id, author_number FROM phone_modish_videos WHERE id = ?', {
        videoId
    })
    
    if not video or #video == 0 then
        TriggerClientEvent('phone:client:commentOnModishVideoResult', source, {
            success = false,
            message = 'Video not found'
        })
        return
    end
    
    -- Get author name
    local authorName = Framework:GetPlayerName(source) or phoneNumber
    
    -- Insert comment
    local insertId = MySQL.insert.await([[
        INSERT INTO phone_modish_comments (video_id, author_number, author_name, content)
        VALUES (?, ?, ?, ?)
    ]], {
        videoId,
        phoneNumber,
        authorName,
        content
    })
    
    if not insertId then
        TriggerClientEvent('phone:client:commentOnModishVideoResult', source, {
            success = false,
            message = 'Failed to post comment'
        })
        return
    end
    
    -- Get the created comment
    local comment = MySQL.query.await([[
        SELECT 
            id,
            author_number,
            author_name,
            content,
            UNIX_TIMESTAMP(created_at) * 1000 as created_at
        FROM phone_modish_comments
        WHERE id = ?
    ]], {
        insertId
    })
    
    if comment and #comment > 0 then
        -- Send success response
        TriggerClientEvent('phone:client:commentOnModishVideoResult', source, {
            success = true,
            data = comment[1]
        })
        
        -- Notify video author
        if video[1].author_number ~= phoneNumber then
            TriggerEvent('phone:server:sendNotification', video[1].author_number, {
                app = 'modish',
                title = 'New Comment',
                message = authorName .. ' commented on your video'
            })
        end
    else
        TriggerClientEvent('phone:client:commentOnModishVideoResult', source, {
            success = false,
            message = 'Failed to retrieve comment'
        })
    end
end)

-- Clean up old videos periodically (optional)
if Config.Modish and Config.Modish.autoCleanup then
    CreateThread(function()
        while true do
            Wait(Config.Modish.cleanupInterval or 3600000) -- Default 1 hour
            
            local daysToKeep = Config.Modish.daysToKeep or 90
            
            MySQL.query.await([[
                DELETE FROM phone_modish_videos
                WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
            ]], {
                daysToKeep
            })
            
            if Config.DebugMode then
                print('[Phone] Cleaned up old Modish videos')
            end
        end
    end)
end

