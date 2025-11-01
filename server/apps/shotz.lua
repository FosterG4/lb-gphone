-- Shotz App Server Logic
-- Handles photo/video sharing operations including posting, feed, likes, comments, followers, and live streaming

-- Rate limiting for post creation
local postCooldowns = {}

-- Track active live streams
local activeStreams = {} -- Format: { [phoneNumber] = { postId, startTime, viewers } }

-- Get Shotz feed
RegisterNetEvent('phone:server:getShotzFeed', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveShotzFeed', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    local limit = data.limit or 20
    local offset = data.offset or 0
    
    -- Get feed (all posts, ordered by newest first)
    -- Note: file_url supports both local (nui://) and Fivemanage (https://) URLs
    -- The URL format is determined by Config.MediaStorage when media is uploaded
    local feed = MySQL.query.await([[
        SELECT 
            p.id,
            p.author_number,
            p.author_name,
            p.caption,
            p.likes,
            p.comments,
            p.shares,
            p.is_live,
            m.file_url as media_url,
            m.thumbnail_url,
            m.media_type,
            UNIX_TIMESTAMP(p.created_at) * 1000 as created_at
        FROM phone_shotz_posts p
        INNER JOIN phone_media m ON p.media_id = m.id
        ORDER BY p.created_at DESC
        LIMIT ? OFFSET ?
    ]], {
        limit,
        offset
    })
    
    -- Fetch additional media attachments for posts with multiple media
    if feed and #feed > 0 then
        for _, post in ipairs(feed) do
            local additionalMedia = MySQL.query.await([[
                SELECT 
                    m.id,
                    m.file_url,
                    m.thumbnail_url,
                    m.media_type,
                    pm.display_order
                FROM phone_shotz_post_media pm
                INNER JOIN phone_media m ON pm.media_id = m.id
                WHERE pm.post_id = ?
                ORDER BY pm.display_order ASC
            ]], {
                post.id
            })
            
            if additionalMedia and #additionalMedia > 0 then
                -- Create media array with all attachments
                post.media = {}
                -- Add primary media first
                table.insert(post.media, {
                    id = post.id,
                    url = post.media_url,
                    thumbnail_url = post.thumbnail_url,
                    media_type = post.media_type,
                    display_order = 0
                })
                -- Add additional media
                for _, media in ipairs(additionalMedia) do
                    table.insert(post.media, {
                        id = media.id,
                        url = media.file_url,
                        thumbnail_url = media.thumbnail_url,
                        media_type = media.media_type,
                        display_order = media.display_order
                    })
                end
            end
        end
    end
    
    -- Get user's liked posts
    local likedPosts = MySQL.query.await([[
        SELECT post_id
        FROM phone_shotz_likes
        WHERE phone_number = ?
    ]], {
        phoneNumber
    })
    
    -- Get user's following list
    local following = MySQL.query.await([[
        SELECT following_number
        FROM phone_shotz_followers
        WHERE follower_number = ?
    ]], {
        phoneNumber
    })
    
    -- Create sets for quick lookup
    local likedSet = {}
    for _, like in ipairs(likedPosts or {}) do
        likedSet[like.post_id] = true
    end
    
    local followingSet = {}
    for _, follow in ipairs(following or {}) do
        followingSet[follow.following_number] = true
    end
    
    -- Mark posts with user interaction status
    for _, post in ipairs(feed or {}) do
        post.isLiked = likedSet[post.id] or false
        post.isFollowing = followingSet[post.author_number] or false
    end
    
    TriggerClientEvent('phone:client:receiveShotzFeed', source, {
        success = true,
        feed = feed or {}
    })
end)

-- Get user's own posts
RegisterNetEvent('phone:server:getMyShotzPosts', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    -- Get user's own posts with media URLs (supports both local and Fivemanage URLs)
    local myPosts = MySQL.query.await([[
        SELECT 
            p.id,
            p.author_number,
            p.author_name,
            p.caption,
            p.likes,
            p.comments,
            p.shares,
            p.is_live,
            m.file_url as media_url,
            m.thumbnail_url,
            m.media_type,
            UNIX_TIMESTAMP(p.created_at) * 1000 as created_at
        FROM phone_shotz_posts p
        INNER JOIN phone_media m ON p.media_id = m.id
        WHERE p.author_number = ?
        ORDER BY p.created_at DESC
    ]], {
        phoneNumber
    })
    
    -- Fetch additional media attachments for posts with multiple media
    if myPosts and #myPosts > 0 then
        for _, post in ipairs(myPosts) do
            local additionalMedia = MySQL.query.await([[
                SELECT 
                    m.id,
                    m.file_url,
                    m.thumbnail_url,
                    m.media_type,
                    pm.display_order
                FROM phone_shotz_post_media pm
                INNER JOIN phone_media m ON pm.media_id = m.id
                WHERE pm.post_id = ?
                ORDER BY pm.display_order ASC
            ]], {
                post.id
            })
            
            if additionalMedia and #additionalMedia > 0 then
                -- Create media array with all attachments
                post.media = {}
                -- Add primary media first
                table.insert(post.media, {
                    id = post.id,
                    url = post.media_url,
                    thumbnail_url = post.thumbnail_url,
                    media_type = post.media_type,
                    display_order = 0
                })
                -- Add additional media
                for _, media in ipairs(additionalMedia) do
                    table.insert(post.media, {
                        id = media.id,
                        url = media.file_url,
                        thumbnail_url = media.thumbnail_url,
                        media_type = media.media_type,
                        display_order = media.display_order
                    })
                end
            end
        end
    end
    
    TriggerClientEvent('phone:client:receiveMyShotzPosts', source, {
        success = true,
        posts = myPosts or {}
    })
end)

-- Get user profile
RegisterNetEvent('phone:server:getShotzProfile', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    -- Get follower count
    local followerCount = MySQL.scalar.await([[
        SELECT COUNT(*) FROM phone_shotz_followers
        WHERE following_number = ?
    ]], {
        phoneNumber
    }) or 0
    
    -- Get following count
    local followingCount = MySQL.scalar.await([[
        SELECT COUNT(*) FROM phone_shotz_followers
        WHERE follower_number = ?
    ]], {
        phoneNumber
    }) or 0
    
    local authorName = Framework:GetPlayerName(source) or phoneNumber
    
    TriggerClientEvent('phone:client:receiveShotzProfile', source, {
        success = true,
        profile = {
            name = authorName,
            phoneNumber = phoneNumber,
            followers = followerCount,
            following = followingCount,
            bio = '' -- Can be extended later
        }
    })
end)

-- Create a new post
RegisterNetEvent('phone:server:createShotzPost', function(data)
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
    local isLive = data.isLive or false
    
    -- Validation
    if #mediaIds == 0 then
        TriggerClientEvent('phone:client:createShotzPostResult', source, {
            success = false,
            message = 'Invalid media ID(s)'
        })
        return
    end
    
    -- Limit number of media attachments per post
    local maxMediaPerPost = Config.Shotz and Config.Shotz.maxMediaPerPost or 10
    if #mediaIds > maxMediaPerPost then
        TriggerClientEvent('phone:client:createShotzPostResult', source, {
            success = false,
            message = string.format('Maximum %d media items per post', maxMediaPerPost)
        })
        return
    end
    
    -- Note: Media upload (including Fivemanage) is handled by Storage.HandleUpload()
    -- before this function is called. The mediaIds reference phone_media table which
    -- already contains the Fivemanage URL if Config.MediaStorage = 'fivemanage'
    
    -- Trim caption
    caption = caption:gsub("^%s*(.-)%s*$", "%1")
    
    -- Validate caption length
    if #caption > (Config.Shotz.maxCaptionLength or 500) then
        TriggerClientEvent('phone:client:createShotzPostResult', source, {
            success = false,
            message = 'Caption is too long (max 500 characters)'
        })
        return
    end
    
    -- Get phone number and author name
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:createShotzPostResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Rate limiting check
    local currentTime = os.time()
    if postCooldowns[phoneNumber] and (currentTime - postCooldowns[phoneNumber]) < 10 then
        local remainingTime = 10 - (currentTime - postCooldowns[phoneNumber])
        TriggerClientEvent('phone:client:createShotzPostResult', source, {
            success = false,
            message = string.format('Please wait %d seconds before posting again', remainingTime)
        })
        return
    end
    
    -- Verify media ownership for all media IDs
    -- Media can be stored locally or on Fivemanage - both are supported
    local mediaPlaceholders = table.concat(string.rep('?,', #mediaIds):sub(1, -2):split(','), ',')
    local queryParams = {}
    for _, id in ipairs(mediaIds) do
        table.insert(queryParams, id)
    end
    table.insert(queryParams, phoneNumber)
    
    local media = MySQL.query.await(string.format([[
        SELECT id, media_type, file_url, thumbnail_url
        FROM phone_media
        WHERE id IN (%s) AND owner_number = ?
    ]], mediaPlaceholders), queryParams)
    
    if not media or #media ~= #mediaIds then
        TriggerClientEvent('phone:client:createShotzPostResult', source, {
            success = false,
            message = 'One or more media items not found or you do not own them'
        })
        return
    end
    
    -- Use the first media item as the primary media for the post (for backward compatibility)
    local primaryMediaId = mediaIds[1]
    
    -- Log media source for debugging (if enabled)
    if Config.DebugMode then
        for _, mediaItem in ipairs(media) do
            local storageType = mediaItem.file_url:match('^https://') and 'Fivemanage/CDN' or 'Local'
            print(string.format('[Phone] [Shotz] Creating post with %s media - ID: %d, URL: %s', 
                storageType, mediaItem.id, mediaItem.file_url))
        end
    end
    
    -- Get author name
    local authorName = Framework:GetPlayerName(source) or phoneNumber
    
    -- Insert post into database with primary media
    local insertId = MySQL.insert.await([[
        INSERT INTO phone_shotz_posts (author_number, author_name, caption, media_id, likes, comments, shares, is_live)
        VALUES (?, ?, ?, ?, 0, 0, 0, ?)
    ]], {
        phoneNumber,
        authorName,
        caption,
        primaryMediaId,
        isLive
    })
    
    if not insertId then
        TriggerClientEvent('phone:client:createShotzPostResult', source, {
            success = false,
            message = 'Failed to create post'
        })
        return
    end
    
    -- Insert additional media attachments into junction table (if multiple media)
    if #mediaIds > 1 then
        for i, mediaId in ipairs(mediaIds) do
            MySQL.insert.await([[
                INSERT INTO phone_shotz_post_media (post_id, media_id, display_order)
                VALUES (?, ?, ?)
            ]], {
                insertId,
                mediaId,
                i - 1  -- 0-indexed display order
            })
        end
        
        if Config.DebugMode then
            print(string.format('[Phone] [Shotz] Added %d media attachments to post ID: %d', #mediaIds, insertId))
        end
    end
    
    -- Update cooldown
    postCooldowns[phoneNumber] = currentTime
    
    -- If live stream, track it
    if isLive then
        activeStreams[phoneNumber] = {
            postId = insertId,
            startTime = currentTime,
            viewers = {}
        }
    end
    
    -- Get the created post
    local post = MySQL.query.await([[
        SELECT 
            p.id,
            p.author_number,
            p.author_name,
            p.caption,
            p.likes,
            p.comments,
            p.shares,
            p.is_live,
            m.file_url as media_url,
            m.thumbnail_url,
            m.media_type,
            UNIX_TIMESTAMP(p.created_at) * 1000 as created_at
        FROM phone_shotz_posts p
        INNER JOIN phone_media m ON p.media_id = m.id
        WHERE p.id = ?
    ]], {
        insertId
    })
    
    if post and #post > 0 then
        post[1].isLiked = false
        post[1].isFollowing = false
        
        -- Fetch additional media attachments if multiple media
        if #mediaIds > 1 then
            local additionalMedia = MySQL.query.await([[
                SELECT 
                    m.id,
                    m.file_url,
                    m.thumbnail_url,
                    m.media_type,
                    pm.display_order
                FROM phone_shotz_post_media pm
                INNER JOIN phone_media m ON pm.media_id = m.id
                WHERE pm.post_id = ?
                ORDER BY pm.display_order ASC
            ]], {
                insertId
            })
            
            if additionalMedia and #additionalMedia > 0 then
                -- Create media array with all attachments
                post[1].media = {}
                -- Add primary media first
                table.insert(post[1].media, {
                    id = post[1].id,
                    url = post[1].media_url,
                    thumbnail_url = post[1].thumbnail_url,
                    media_type = post[1].media_type,
                    display_order = 0
                })
                -- Add additional media
                for _, media in ipairs(additionalMedia) do
                    table.insert(post[1].media, {
                        id = media.id,
                        url = media.file_url,
                        thumbnail_url = media.thumbnail_url,
                        media_type = media.media_type,
                        display_order = media.display_order
                    })
                end
            end
        end
        
        -- Send success response to poster
        TriggerClientEvent('phone:client:createShotzPostResult', source, {
            success = true,
            post = post[1]
        })
        
        -- Broadcast new post to all online players
        TriggerClientEvent('phone:client:newShotzPost', -1, post[1])
        
        -- Notify followers if not live
        if not isLive then
            local followers = MySQL.query.await([[
                SELECT follower_number
                FROM phone_shotz_followers
                WHERE following_number = ?
            ]], {
                phoneNumber
            })
            
            for _, follower in ipairs(followers or {}) do
                -- Send notification to follower (implement notification system)
                TriggerEvent('phone:server:sendNotification', follower.follower_number, {
                    app = 'shotz',
                    title = 'New Post',
                    message = authorName .. ' posted a new photo/video'
                })
            end
        end
    else
        TriggerClientEvent('phone:client:createShotzPostResult', source, {
            success = false,
            message = 'Failed to retrieve created post'
        })
    end
end)

-- Like/unlike a post
RegisterNetEvent('phone:server:likeShotzPost', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local postId = tonumber(data.postId)
    
    if not postId then
        TriggerClientEvent('phone:client:likeShotzPostResult', source, {
            success = false,
            message = 'Invalid post ID'
        })
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:likeShotzPostResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Check if post exists
    local post = MySQL.query.await('SELECT id, likes, author_number FROM phone_shotz_posts WHERE id = ?', {
        postId
    })
    
    if not post or #post == 0 then
        TriggerClientEvent('phone:client:likeShotzPostResult', source, {
            success = false,
            message = 'Post not found'
        })
        return
    end
    
    -- Check if user has already liked this post
    local existingLike = MySQL.query.await([[
        SELECT id FROM phone_shotz_likes
        WHERE phone_number = ? AND post_id = ?
    ]], {
        phoneNumber,
        postId
    })
    
    local isLiked = false
    local newLikes = post[1].likes
    
    if existingLike and #existingLike > 0 then
        -- Unlike: Remove like and decrement count
        MySQL.query.await('DELETE FROM phone_shotz_likes WHERE phone_number = ? AND post_id = ?', {
            phoneNumber,
            postId
        })
        
        newLikes = math.max(0, newLikes - 1)
        isLiked = false
    else
        -- Like: Add like and increment count
        MySQL.insert.await('INSERT INTO phone_shotz_likes (phone_number, post_id) VALUES (?, ?)', {
            phoneNumber,
            postId
        })
        
        newLikes = newLikes + 1
        isLiked = true
        
        -- Notify post author
        if post[1].author_number ~= phoneNumber then
            TriggerEvent('phone:server:sendNotification', post[1].author_number, {
                app = 'shotz',
                title = 'New Like',
                message = 'Someone liked your post'
            })
        end
    end
    
    -- Update post likes count
    MySQL.update.await('UPDATE phone_shotz_posts SET likes = ? WHERE id = ?', {
        newLikes,
        postId
    })
    
    -- Send response
    TriggerClientEvent('phone:client:likeShotzPostResult', source, {
        success = true,
        postId = postId,
        likes = newLikes,
        isLiked = isLiked
    })
    
    -- Broadcast like update to all online players
    TriggerClientEvent('phone:client:shotzPostLikeUpdate', -1, {
        postId = postId,
        likes = newLikes
    })
end)

-- Get comments for a post
RegisterNetEvent('phone:server:getShotzComments', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local postId = tonumber(data.postId)
    
    if not postId then
        return
    end
    
    local comments = MySQL.query.await([[
        SELECT 
            id,
            author_number,
            author_name,
            content,
            UNIX_TIMESTAMP(created_at) * 1000 as created_at
        FROM phone_shotz_comments
        WHERE post_id = ?
        ORDER BY created_at ASC
    ]], {
        postId
    })
    
    TriggerClientEvent('phone:client:receiveShotzComments', source, {
        success = true,
        postId = postId,
        comments = comments or {}
    })
end)

-- Comment on a post
RegisterNetEvent('phone:server:commentOnShotzPost', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local postId = tonumber(data.postId)
    local content = data.content
    
    -- Validation
    if not postId or not content or type(content) ~= 'string' then
        TriggerClientEvent('phone:client:commentOnShotzPostResult', source, {
            success = false,
            message = 'Invalid comment data'
        })
        return
    end
    
    -- Trim content
    content = content:gsub("^%s*(.-)%s*$", "%1")
    
    -- Validate content length
    if #content == 0 then
        TriggerClientEvent('phone:client:commentOnShotzPostResult', source, {
            success = false,
            message = 'Comment cannot be empty'
        })
        return
    end
    
    if #content > 500 then
        TriggerClientEvent('phone:client:commentOnShotzPostResult', source, {
            success = false,
            message = 'Comment is too long (max 500 characters)'
        })
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:commentOnShotzPostResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Check if post exists
    local post = MySQL.query.await('SELECT id, comments, author_number FROM phone_shotz_posts WHERE id = ?', {
        postId
    })
    
    if not post or #post == 0 then
        TriggerClientEvent('phone:client:commentOnShotzPostResult', source, {
            success = false,
            message = 'Post not found'
        })
        return
    end
    
    -- Get author name
    local authorName = Framework:GetPlayerName(source) or phoneNumber
    
    -- Insert comment
    local insertId = MySQL.insert.await([[
        INSERT INTO phone_shotz_comments (post_id, author_number, author_name, content)
        VALUES (?, ?, ?, ?)
    ]], {
        postId,
        phoneNumber,
        authorName,
        content
    })
    
    if not insertId then
        TriggerClientEvent('phone:client:commentOnShotzPostResult', source, {
            success = false,
            message = 'Failed to post comment'
        })
        return
    end
    
    -- Update post comments count
    local newCommentCount = post[1].comments + 1
    MySQL.update.await('UPDATE phone_shotz_posts SET comments = ? WHERE id = ?', {
        newCommentCount,
        postId
    })
    
    -- Get the created comment
    local comment = MySQL.query.await([[
        SELECT 
            id,
            author_number,
            author_name,
            content,
            UNIX_TIMESTAMP(created_at) * 1000 as created_at
        FROM phone_shotz_comments
        WHERE id = ?
    ]], {
        insertId
    })
    
    if comment and #comment > 0 then
        -- Send success response
        TriggerClientEvent('phone:client:commentOnShotzPostResult', source, {
            success = true,
            data = comment[1]
        })
        
        -- Broadcast comment update
        TriggerClientEvent('phone:client:shotzPostCommentUpdate', -1, {
            postId = postId,
            comments = newCommentCount
        })
        
        -- Notify post author
        if post[1].author_number ~= phoneNumber then
            TriggerEvent('phone:server:sendNotification', post[1].author_number, {
                app = 'shotz',
                title = 'New Comment',
                message = authorName .. ' commented on your post'
            })
        end
    else
        TriggerClientEvent('phone:client:commentOnShotzPostResult', source, {
            success = false,
            message = 'Failed to retrieve comment'
        })
    end
end)

-- Follow/unfollow a user
RegisterNetEvent('phone:server:toggleShotzFollow', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local targetNumber = data.targetNumber
    
    if not targetNumber then
        TriggerClientEvent('phone:client:toggleShotzFollowResult', source, {
            success = false,
            message = 'Invalid target number'
        })
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:toggleShotzFollowResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Can't follow yourself
    if phoneNumber == targetNumber then
        TriggerClientEvent('phone:client:toggleShotzFollowResult', source, {
            success = false,
            message = 'Cannot follow yourself'
        })
        return
    end
    
    -- Check if already following
    local existingFollow = MySQL.query.await([[
        SELECT id FROM phone_shotz_followers
        WHERE follower_number = ? AND following_number = ?
    ]], {
        phoneNumber,
        targetNumber
    })
    
    local isFollowing = false
    
    if existingFollow and #existingFollow > 0 then
        -- Unfollow
        MySQL.query.await([[
            DELETE FROM phone_shotz_followers
            WHERE follower_number = ? AND following_number = ?
        ]], {
            phoneNumber,
            targetNumber
        })
        
        isFollowing = false
    else
        -- Follow
        MySQL.insert.await([[
            INSERT INTO phone_shotz_followers (follower_number, following_number)
            VALUES (?, ?)
        ]], {
            phoneNumber,
            targetNumber
        })
        
        isFollowing = true
        
        -- Notify target user
        TriggerEvent('phone:server:sendNotification', targetNumber, {
            app = 'shotz',
            title = 'New Follower',
            message = 'Someone started following you'
        })
    end
    
    -- Send response
    TriggerClientEvent('phone:client:toggleShotzFollowResult', source, {
        success = true,
        targetNumber = targetNumber,
        isFollowing = isFollowing
    })
end)

-- Share a post
RegisterNetEvent('phone:server:shareShotzPost', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local postId = tonumber(data.postId)
    
    if not postId then
        return
    end
    
    -- Increment share count
    MySQL.query.await('UPDATE phone_shotz_posts SET shares = shares + 1 WHERE id = ?', {
        postId
    })
    
    -- Get updated share count
    local post = MySQL.query.await('SELECT shares FROM phone_shotz_posts WHERE id = ?', {
        postId
    })
    
    if post and #post > 0 then
        -- Broadcast share update
        TriggerClientEvent('phone:client:shotzPostShareUpdate', -1, {
            postId = postId,
            shares = post[1].shares
        })
    end
end)

-- Start live stream
RegisterNetEvent('phone:server:startShotzLiveStream', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local postId = tonumber(data.postId)
    
    if not postId then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    -- Verify post ownership and that it's marked as live
    local post = MySQL.query.await([[
        SELECT id, author_number, is_live
        FROM phone_shotz_posts
        WHERE id = ? AND author_number = ? AND is_live = 1
    ]], {
        postId,
        phoneNumber
    })
    
    if not post or #post == 0 then
        TriggerClientEvent('phone:client:startShotzLiveStreamResult', source, {
            success = false,
            message = 'Invalid live stream post'
        })
        return
    end
    
    -- Track active stream
    activeStreams[phoneNumber] = {
        postId = postId,
        startTime = os.time(),
        viewers = {}
    }
    
    -- Notify followers
    local followers = MySQL.query.await([[
        SELECT follower_number
        FROM phone_shotz_followers
        WHERE following_number = ?
    ]], {
        phoneNumber
    })
    
    local authorName = Framework:GetPlayerName(source) or phoneNumber
    
    for _, follower in ipairs(followers or {}) do
        TriggerEvent('phone:server:sendNotification', follower.follower_number, {
            app = 'shotz',
            title = 'Live Stream',
            message = authorName .. ' is now live!'
        })
    end
    
    -- Broadcast live stream start
    TriggerClientEvent('phone:client:shotzLiveStreamStarted', -1, {
        postId = postId,
        authorNumber = phoneNumber,
        authorName = authorName
    })
    
    TriggerClientEvent('phone:client:startShotzLiveStreamResult', source, {
        success = true,
        postId = postId
    })
end)

-- End live stream
RegisterNetEvent('phone:server:endShotzLiveStream', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    local stream = activeStreams[phoneNumber]
    if not stream then
        TriggerClientEvent('phone:client:endShotzLiveStreamResult', source, {
            success = false,
            message = 'No active stream found'
        })
        return
    end
    
    local postId = stream.postId
    
    -- Update post to mark as no longer live
    MySQL.update.await('UPDATE phone_shotz_posts SET is_live = 0 WHERE id = ?', {
        postId
    })
    
    -- Remove from active streams
    activeStreams[phoneNumber] = nil
    
    -- Broadcast live stream end
    TriggerClientEvent('phone:client:shotzLiveStreamEnded', -1, {
        postId = postId
    })
    
    TriggerClientEvent('phone:client:endShotzLiveStreamResult', source, {
        success = true,
        postId = postId
    })
end)

-- Join live stream as viewer
RegisterNetEvent('phone:server:joinShotzLiveStream', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local postId = tonumber(data.postId)
    
    if not postId then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    -- Find the stream
    for streamerNumber, stream in pairs(activeStreams) do
        if stream.postId == postId then
            -- Add viewer
            stream.viewers[phoneNumber] = true
            
            -- Notify streamer
            TriggerEvent('phone:server:sendNotification', streamerNumber, {
                app = 'shotz',
                title = 'New Viewer',
                message = 'Someone joined your live stream'
            })
            
            -- Send viewer count update
            local viewerCount = 0
            for _ in pairs(stream.viewers) do
                viewerCount = viewerCount + 1
            end
            
            TriggerClientEvent('phone:client:shotzLiveStreamViewerUpdate', -1, {
                postId = postId,
                viewers = viewerCount
            })
            
            break
        end
    end
end)

-- Leave live stream
RegisterNetEvent('phone:server:leaveShotzLiveStream', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local postId = tonumber(data.postId)
    
    if not postId then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    -- Find the stream and remove viewer
    for _, stream in pairs(activeStreams) do
        if stream.postId == postId and stream.viewers[phoneNumber] then
            stream.viewers[phoneNumber] = nil
            
            -- Send viewer count update
            local viewerCount = 0
            for _ in pairs(stream.viewers) do
                viewerCount = viewerCount + 1
            end
            
            TriggerClientEvent('phone:client:shotzLiveStreamViewerUpdate', -1, {
                postId = postId,
                viewers = viewerCount
            })
            
            break
        end
    end
end)

-- Clean up old posts periodically (optional)
if Config.Shotz and Config.Shotz.autoCleanup then
    CreateThread(function()
        while true do
            Wait(Config.Shotz.cleanupInterval or 3600000) -- Default 1 hour
            
            local daysToKeep = Config.Shotz.daysToKeep or 90
            
            MySQL.query.await([[
                DELETE FROM phone_shotz_posts
                WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
            ]], {
                daysToKeep
            })
            
            if Config.DebugMode then
                print('[Phone] Cleaned up old Shotz posts')
            end
        end
    end)
end

-- Clean up disconnected viewers from live streams
AddEventHandler('playerDropped', function()
    local source = source
    local phoneNumber = Framework:GetPhoneNumber(source)
    
    if phoneNumber then
        -- Remove from all live stream viewers
        for _, stream in pairs(activeStreams) do
            if stream.viewers[phoneNumber] then
                stream.viewers[phoneNumber] = nil
            end
        end
        
        -- End any active stream by this user
        if activeStreams[phoneNumber] then
            local postId = activeStreams[phoneNumber].postId
            
            -- Update post to mark as no longer live
            MySQL.update.await('UPDATE phone_shotz_posts SET is_live = 0 WHERE id = ?', {
                postId
            })
            
            -- Broadcast live stream end
            TriggerClientEvent('phone:client:shotzLiveStreamEnded', -1, {
                postId = postId
            })
            
            activeStreams[phoneNumber] = nil
        end
    end
end)

