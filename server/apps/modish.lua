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
    -- Note: file_url supports both local (nui://) and Fivemanage (https://) URLs
    -- The URL format is determined by Config.MediaStorage when media is uploaded
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
    
    -- Mark videos with user interaction status and fetch additional media
    for _, video in ipairs(feed or {}) do
        video.isLiked = likedSet[video.id] or false
        video.media_type = 'video'
        
        -- Parse filters JSON if exists
        if video.filters_json then
            video.filters = json.decode(video.filters_json)
        end
        
        -- Fetch additional media attachments
        local additionalMedia = MySQL.query.await([[
            SELECT 
                m.id,
                m.file_url,
                m.thumbnail_url,
                m.media_type,
                m.duration,
                vm.display_order
            FROM phone_modish_video_media vm
            INNER JOIN phone_media m ON vm.media_id = m.id
            WHERE vm.video_id = ?
            ORDER BY vm.display_order ASC
        ]], {
            video.id
        })
        
        if additionalMedia and #additionalMedia > 0 then
            -- Create media array with all attachments
            video.media = {}
            -- Add primary media first
            table.insert(video.media, {
                id = video.id,
                url = video.media_url,
                thumbnail_url = video.thumbnail_url,
                media_type = video.media_type,
                duration = video.duration,
                display_order = 0
            })
            -- Add additional media
            for _, media in ipairs(additionalMedia) do
                table.insert(video.media, {
                    id = media.id,
                    url = media.file_url,
                    thumbnail_url = media.thumbnail_url,
                    media_type = media.media_type,
                    duration = media.duration,
                    display_order = media.display_order
                })
            end
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
    
    -- Get user's own videos with media URLs (supports both local and Fivemanage URLs)
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
    
    -- Parse filters JSON and fetch additional media for each video
    for _, video in ipairs(myVideos or {}) do
        if video.filters_json then
            video.filters = json.decode(video.filters_json)
        end
        video.media_type = 'video'
        
        -- Fetch additional media attachments
        local additionalMedia = MySQL.query.await([[
            SELECT 
                m.id,
                m.file_url,
                m.thumbnail_url,
                m.media_type,
                m.duration,
                vm.display_order
            FROM phone_modish_video_media vm
            INNER JOIN phone_media m ON vm.media_id = m.id
            WHERE vm.video_id = ?
            ORDER BY vm.display_order ASC
        ]], {
            video.id
        })
        
        if additionalMedia and #additionalMedia > 0 then
            -- Create media array with all attachments
            video.media = {}
            -- Add primary media first
            table.insert(video.media, {
                id = video.id,
                url = video.media_url,
                thumbnail_url = video.thumbnail_url,
                media_type = video.media_type,
                duration = video.duration,
                display_order = 0
            })
            -- Add additional media
            for _, media in ipairs(additionalMedia) do
                table.insert(video.media, {
                    id = media.id,
                    url = media.file_url,
                    thumbnail_url = media.thumbnail_url,
                    media_type = media.media_type,
                    duration = media.duration,
                    display_order = media.display_order
                })
            end
        end
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
    
    -- Support both single mediaId (backward compatibility) and mediaIds array (new feature)
    local mediaIds = {}
    if data.mediaIds and type(data.mediaIds) == 'table' and #data.mediaIds > 0 then
        -- New format: array of media IDs
        for _, id in ipairs(data.mediaIds) do
            local numId = tonumber(id)
            if numId then
                table.insert(mediaIds, numId)
            end
        end
    elseif data.mediaId then
        -- Old format: single media ID (backward compatibility)
        local numId = tonumber(data.mediaId)
        if numId then
            table.insert(mediaIds, numId)
        end
    end
    
    local caption = data.caption or ''
    local filters = data.filters
    local tts = data.tts
    local music = data.music
    
    -- Validation
    if #mediaIds == 0 then
        TriggerClientEvent('phone:client:createModishVideoResult', source, {
            success = false,
            message = 'Invalid media ID(s)'
        })
        return
    end
    
    -- Limit number of media attachments per video
    local maxMediaPerVideo = Config.Modish and Config.Modish.maxMediaPerVideo or 10
    if #mediaIds > maxMediaPerVideo then
        TriggerClientEvent('phone:client:createModishVideoResult', source, {
            success = false,
            message = string.format('Maximum %d media items per video', maxMediaPerVideo)
        })
        return
    end
    
    -- Note: Video upload (including Fivemanage) is handled by Storage.HandleUpload()
    -- before this function is called. The mediaIds reference phone_media table which
    -- already contains the Fivemanage URL if Config.MediaStorage = 'fivemanage'
    
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
    
    -- Verify media ownership for all media IDs and ensure they're videos
    -- Video can be stored locally or on Fivemanage - both are supported
    local mediaPlaceholders = table.concat(string.rep('?,', #mediaIds):sub(1, -2):split(','), ',')
    local queryParams = {}
    for _, id in ipairs(mediaIds) do
        table.insert(queryParams, id)
    end
    table.insert(queryParams, phoneNumber)
    
    local media = MySQL.query.await(string.format([[
        SELECT id, media_type, file_url, thumbnail_url, duration
        FROM phone_media
        WHERE id IN (%s) AND owner_number = ? AND media_type = 'video'
    ]], mediaPlaceholders), queryParams)
    
    if not media or #media ~= #mediaIds then
        TriggerClientEvent('phone:client:createModishVideoResult', source, {
            success = false,
            message = 'One or more videos not found or you do not own them'
        })
        return
    end
    
    -- Use the first media item as the primary media for the video (for backward compatibility)
    local primaryMediaId = mediaIds[1]
    
    -- Log media source for debugging (if enabled)
    if Config.DebugMode then
        for _, mediaItem in ipairs(media) do
            local storageType = mediaItem.file_url:match('^https://') and 'Fivemanage/CDN' or 'Local'
            print(string.format('[Phone] [Modish] Creating video with %s media - ID: %d, URL: %s', 
                storageType, mediaItem.id, mediaItem.file_url))
        end
    end
    
    -- Validate video length for primary video
    local maxVideoLength = Config.Modish and Config.Modish.maxVideoLength or 60
    local primaryMedia = media[1]
    if primaryMedia.duration and primaryMedia.duration > maxVideoLength then
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
    
    -- Insert video into database with primary media
    local insertId = MySQL.insert.await([[
        INSERT INTO phone_modish_videos (author_number, author_name, media_id, caption, music_track, filters_json, likes, views)
        VALUES (?, ?, ?, ?, ?, ?, 0, 0)
    ]], {
        phoneNumber,
        authorName,
        primaryMediaId,
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
    
    -- Insert additional media attachments into junction table (if multiple media)
    if #mediaIds > 1 then
        for i, mediaId in ipairs(mediaIds) do
            MySQL.insert.await([[
                INSERT INTO phone_modish_video_media (video_id, media_id, display_order)
                VALUES (?, ?, ?)
            ]], {
                insertId,
                mediaId,
                i - 1  -- 0-indexed display order
            })
        end
        
        if Config.DebugMode then
            print(string.format('[Phone] [Modish] Added %d media attachments to video ID: %d', #mediaIds, insertId))
        end
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
        
        -- Fetch additional media attachments if multiple media
        if #mediaIds > 1 then
            local additionalMedia = MySQL.query.await([[
                SELECT 
                    m.id,
                    m.file_url,
                    m.thumbnail_url,
                    m.media_type,
                    m.duration,
                    vm.display_order
                FROM phone_modish_video_media vm
                INNER JOIN phone_media m ON vm.media_id = m.id
                WHERE vm.video_id = ?
                ORDER BY vm.display_order ASC
            ]], {
                insertId
            })
            
            if additionalMedia and #additionalMedia > 0 then
                -- Create media array with all attachments
                video[1].media = {}
                -- Add primary media first
                table.insert(video[1].media, {
                    id = video[1].id,
                    url = video[1].media_url,
                    thumbnail_url = video[1].thumbnail_url,
                    media_type = video[1].media_type,
                    duration = video[1].duration,
                    display_order = 0
                })
                -- Add additional media
                for _, media in ipairs(additionalMedia) do
                    table.insert(video[1].media, {
                        id = media.id,
                        url = media.file_url,
                        thumbnail_url = media.thumbnail_url,
                        media_type = media.media_type,
                        duration = media.duration,
                        display_order = media.display_order
                    })
                end
            end
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

