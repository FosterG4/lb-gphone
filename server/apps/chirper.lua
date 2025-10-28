-- Chirper App Server Logic
-- Handles Twitter-like operations including posting, feed, likes, reposts, replies, and trending topics

-- Rate limiting for post creation
local postCooldowns = {}

-- Cache for trending topics (updated every 5 minutes)
local trendingCache = {
    data = {},
    lastUpdate = 0
}

-- Helper function to extract hashtags from content
local function extractHashtags(content)
    local hashtags = {}
    for tag in string.gmatch(content, "#(%w+)") do
        table.insert(hashtags, string.lower(tag))
    end
    return hashtags
end

-- Helper function to update trending topics
local function updateTrendingTopics()
    local currentTime = os.time()
    
    -- Only update if cache is older than 5 minutes
    if currentTime - trendingCache.lastUpdate < 300 then
        return trendingCache.data
    end
    
    -- Get hashtag frequency from last 24 hours
    local trending = MySQL.query.await([[
        SELECT 
            hashtag,
            COUNT(*) as post_count
        FROM phone_chirper_hashtags
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
        GROUP BY hashtag
        ORDER BY post_count DESC
        LIMIT 10
    ]], {})
    
    trendingCache.data = trending or {}
    trendingCache.lastUpdate = currentTime
    
    return trendingCache.data
end

-- Get Chirper feed
RegisterNetEvent('phone:server:getChirperFeed', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveChirperFeed', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    local limit = data.limit or 20
    local offset = data.offset or 0
    
    -- Get feed (all posts, ordered by newest first, excluding replies from main feed)
    local feed = MySQL.query.await([[
        SELECT 
            p.id,
            p.author_number,
            p.author_name,
            p.content,
            p.likes,
            p.reposts,
            p.replies,
            p.parent_id,
            UNIX_TIMESTAMP(p.created_at) * 1000 as created_at
        FROM phone_chirper_posts p
        WHERE p.parent_id IS NULL
        ORDER BY p.created_at DESC
        LIMIT ? OFFSET ?
    ]], {
        limit,
        offset
    })
    
    -- Get user's liked posts
    local likedPosts = MySQL.query.await([[
        SELECT post_id
        FROM phone_chirper_likes
        WHERE phone_number = ?
    ]], {
        phoneNumber
    })
    
    -- Get user's reposted posts
    local repostedPosts = MySQL.query.await([[
        SELECT post_id
        FROM phone_chirper_reposts
        WHERE phone_number = ?
    ]], {
        phoneNumber
    })
    
    -- Create sets for quick lookup
    local likedSet = {}
    for _, like in ipairs(likedPosts or {}) do
        likedSet[like.post_id] = true
    end
    
    local repostedSet = {}
    for _, repost in ipairs(repostedPosts or {}) do
        repostedSet[repost.post_id] = true
    end
    
    -- Mark posts with user interaction status
    for _, post in ipairs(feed or {}) do
        post.isLiked = likedSet[post.id] or false
        post.isReposted = repostedSet[post.id] or false
    end
    
    TriggerClientEvent('phone:client:receiveChirperFeed', source, {
        success = true,
        feed = feed or {}
    })
end)

-- Get user's own posts
RegisterNetEvent('phone:server:getMyChirperPosts', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    local myPosts = MySQL.query.await([[
        SELECT 
            p.id,
            p.author_number,
            p.author_name,
            p.content,
            p.likes,
            p.reposts,
            p.replies,
            p.parent_id,
            UNIX_TIMESTAMP(p.created_at) * 1000 as created_at
        FROM phone_chirper_posts p
        WHERE p.author_number = ?
        ORDER BY p.created_at DESC
    ]], {
        phoneNumber
    })
    
    TriggerClientEvent('phone:client:receiveMyChirperPosts', source, {
        success = true,
        posts = myPosts or {}
    })
end)

-- Get trending topics
RegisterNetEvent('phone:server:getChirperTrending', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local trending = updateTrendingTopics()
    
    TriggerClientEvent('phone:client:receiveChirperTrending', source, {
        success = true,
        trending = trending
    })
end)

-- Get post thread (post + all replies)
RegisterNetEvent('phone:server:getChirperThread', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local postId = tonumber(data.postId)
    
    if not postId then
        TriggerClientEvent('phone:client:receiveChirperThread', source, {
            success = false,
            message = 'Invalid post ID'
        })
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    -- Get main post
    local mainPost = MySQL.query.await([[
        SELECT 
            p.id,
            p.author_number,
            p.author_name,
            p.content,
            p.likes,
            p.reposts,
            p.replies,
            p.parent_id,
            UNIX_TIMESTAMP(p.created_at) * 1000 as created_at
        FROM phone_chirper_posts p
        WHERE p.id = ?
    ]], {
        postId
    })
    
    if not mainPost or #mainPost == 0 then
        TriggerClientEvent('phone:client:receiveChirperThread', source, {
            success = false,
            message = 'Post not found'
        })
        return
    end
    
    -- Get all replies
    local replies = MySQL.query.await([[
        SELECT 
            p.id,
            p.author_number,
            p.author_name,
            p.content,
            p.likes,
            p.reposts,
            p.replies,
            p.parent_id,
            UNIX_TIMESTAMP(p.created_at) * 1000 as created_at
        FROM phone_chirper_posts p
        WHERE p.parent_id = ?
        ORDER BY p.created_at ASC
    ]], {
        postId
    })
    
    -- Get user's liked posts
    local likedPosts = MySQL.query.await([[
        SELECT post_id
        FROM phone_chirper_likes
        WHERE phone_number = ?
    ]], {
        phoneNumber
    })
    
    -- Get user's reposted posts
    local repostedPosts = MySQL.query.await([[
        SELECT post_id
        FROM phone_chirper_reposts
        WHERE phone_number = ?
    ]], {
        phoneNumber
    })
    
    -- Create sets for quick lookup
    local likedSet = {}
    for _, like in ipairs(likedPosts or {}) do
        likedSet[like.post_id] = true
    end
    
    local repostedSet = {}
    for _, repost in ipairs(repostedPosts or {}) do
        repostedSet[repost.post_id] = true
    end
    
    -- Mark main post
    mainPost[1].isLiked = likedSet[mainPost[1].id] or false
    mainPost[1].isReposted = repostedSet[mainPost[1].id] or false
    
    -- Mark replies
    for _, reply in ipairs(replies or {}) do
        reply.isLiked = likedSet[reply.id] or false
        reply.isReposted = repostedSet[reply.id] or false
    end
    
    TriggerClientEvent('phone:client:receiveChirperThread', source, {
        success = true,
        thread = {
            post = mainPost[1],
            replies = replies or {}
        }
    })
end)

-- Create a new post
RegisterNetEvent('phone:server:createChirperPost', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local content = data.content or ''
    local parentId = data.parentId and tonumber(data.parentId) or nil
    
    -- Trim content
    content = content:gsub("^%s*(.-)%s*$", "%1")
    
    -- Validation
    if #content == 0 then
        TriggerClientEvent('phone:client:createChirperPostResult', source, {
            success = false,
            message = 'Post cannot be empty'
        })
        return
    end
    
    if #content > 280 then
        TriggerClientEvent('phone:client:createChirperPostResult', source, {
            success = false,
            message = 'Post is too long (max 280 characters)'
        })
        return
    end
    
    -- Get phone number and author name
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:createChirperPostResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Rate limiting check
    local currentTime = os.time()
    if postCooldowns[phoneNumber] and (currentTime - postCooldowns[phoneNumber]) < 5 then
        local remainingTime = 5 - (currentTime - postCooldowns[phoneNumber])
        TriggerClientEvent('phone:client:createChirperPostResult', source, {
            success = false,
            message = string.format('Please wait %d seconds before posting again', remainingTime)
        })
        return
    end
    
    -- If replying, verify parent post exists
    if parentId then
        local parentPost = MySQL.query.await('SELECT id, author_number FROM phone_chirper_posts WHERE id = ?', {
            parentId
        })
        
        if not parentPost or #parentPost == 0 then
            TriggerClientEvent('phone:client:createChirperPostResult', source, {
                success = false,
                message = 'Parent post not found'
            })
            return
        end
    end
    
    -- Get author name
    local authorName = Framework:GetPlayerName(source) or phoneNumber
    
    -- Insert post into database
    local insertId = MySQL.insert.await([[
        INSERT INTO phone_chirper_posts (author_number, author_name, content, likes, reposts, replies, parent_id)
        VALUES (?, ?, ?, 0, 0, 0, ?)
    ]], {
        phoneNumber,
        authorName,
        content,
        parentId
    })
    
    if not insertId then
        TriggerClientEvent('phone:client:createChirperPostResult', source, {
            success = false,
            message = 'Failed to create post'
        })
        return
    end
    
    -- Update cooldown
    postCooldowns[phoneNumber] = currentTime
    
    -- Extract and store hashtags
    local hashtags = extractHashtags(content)
    for _, hashtag in ipairs(hashtags) do
        MySQL.insert.await([[
            INSERT INTO phone_chirper_hashtags (post_id, hashtag)
            VALUES (?, ?)
        ]], {
            insertId,
            hashtag
        })
    end
    
    -- If this is a reply, update parent post reply count
    if parentId then
        MySQL.query.await('UPDATE phone_chirper_posts SET replies = replies + 1 WHERE id = ?', {
            parentId
        })
        
        -- Notify parent post author
        local parentPost = MySQL.query.await('SELECT author_number FROM phone_chirper_posts WHERE id = ?', {
            parentId
        })
        
        if parentPost and #parentPost > 0 and parentPost[1].author_number ~= phoneNumber then
            TriggerEvent('phone:server:sendNotification', parentPost[1].author_number, {
                app = 'chirper',
                title = 'New Reply',
                message = authorName .. ' replied to your post'
            })
        end
    end
    
    -- Get the created post
    local post = MySQL.query.await([[
        SELECT 
            p.id,
            p.author_number,
            p.author_name,
            p.content,
            p.likes,
            p.reposts,
            p.replies,
            p.parent_id,
            UNIX_TIMESTAMP(p.created_at) * 1000 as created_at
        FROM phone_chirper_posts p
        WHERE p.id = ?
    ]], {
        insertId
    })
    
    if post and #post > 0 then
        post[1].isLiked = false
        post[1].isReposted = false
        
        -- Send success response to poster
        TriggerClientEvent('phone:client:createChirperPostResult', source, {
            success = true,
            post = post[1]
        })
        
        -- Broadcast new post to all online players (only if not a reply)
        if not parentId then
            TriggerClientEvent('phone:client:newChirperPost', -1, post[1])
        end
        
        -- Invalidate trending cache if hashtags were used
        if #hashtags > 0 then
            trendingCache.lastUpdate = 0
        end
    else
        TriggerClientEvent('phone:client:createChirperPostResult', source, {
            success = false,
            message = 'Failed to retrieve created post'
        })
    end
end)

-- Like/unlike a post
RegisterNetEvent('phone:server:likeChirperPost', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local postId = tonumber(data.postId)
    
    if not postId then
        TriggerClientEvent('phone:client:likeChirperPostResult', source, {
            success = false,
            message = 'Invalid post ID'
        })
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:likeChirperPostResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Check if post exists
    local post = MySQL.query.await('SELECT id, likes, author_number FROM phone_chirper_posts WHERE id = ?', {
        postId
    })
    
    if not post or #post == 0 then
        TriggerClientEvent('phone:client:likeChirperPostResult', source, {
            success = false,
            message = 'Post not found'
        })
        return
    end
    
    -- Check if user has already liked this post
    local existingLike = MySQL.query.await([[
        SELECT id FROM phone_chirper_likes
        WHERE phone_number = ? AND post_id = ?
    ]], {
        phoneNumber,
        postId
    })
    
    local isLiked = false
    local newLikes = post[1].likes
    
    if existingLike and #existingLike > 0 then
        -- Unlike: Remove like and decrement count
        MySQL.query.await('DELETE FROM phone_chirper_likes WHERE phone_number = ? AND post_id = ?', {
            phoneNumber,
            postId
        })
        
        newLikes = math.max(0, newLikes - 1)
        isLiked = false
    else
        -- Like: Add like and increment count
        MySQL.insert.await('INSERT INTO phone_chirper_likes (phone_number, post_id) VALUES (?, ?)', {
            phoneNumber,
            postId
        })
        
        newLikes = newLikes + 1
        isLiked = true
        
        -- Notify post author
        if post[1].author_number ~= phoneNumber then
            TriggerEvent('phone:server:sendNotification', post[1].author_number, {
                app = 'chirper',
                title = 'New Like',
                message = 'Someone liked your post'
            })
        end
    end
    
    -- Update post likes count
    MySQL.update.await('UPDATE phone_chirper_posts SET likes = ? WHERE id = ?', {
        newLikes,
        postId
    })
    
    -- Send response
    TriggerClientEvent('phone:client:likeChirperPostResult', source, {
        success = true,
        postId = postId,
        likes = newLikes,
        isLiked = isLiked
    })
    
    -- Broadcast like update to all online players
    TriggerClientEvent('phone:client:chirperPostLikeUpdate', -1, {
        postId = postId,
        likes = newLikes
    })
end)

-- Repost/unrepost a post
RegisterNetEvent('phone:server:repostChirperPost', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local postId = tonumber(data.postId)
    
    if not postId then
        TriggerClientEvent('phone:client:repostChirperPostResult', source, {
            success = false,
            message = 'Invalid post ID'
        })
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:repostChirperPostResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Check if post exists
    local post = MySQL.query.await('SELECT id, reposts, author_number FROM phone_chirper_posts WHERE id = ?', {
        postId
    })
    
    if not post or #post == 0 then
        TriggerClientEvent('phone:client:repostChirperPostResult', source, {
            success = false,
            message = 'Post not found'
        })
        return
    end
    
    -- Can't repost your own post
    if post[1].author_number == phoneNumber then
        TriggerClientEvent('phone:client:repostChirperPostResult', source, {
            success = false,
            message = 'Cannot repost your own post'
        })
        return
    end
    
    -- Check if user has already reposted this post
    local existingRepost = MySQL.query.await([[
        SELECT id FROM phone_chirper_reposts
        WHERE phone_number = ? AND post_id = ?
    ]], {
        phoneNumber,
        postId
    })
    
    local isReposted = false
    local newReposts = post[1].reposts
    
    if existingRepost and #existingRepost > 0 then
        -- Unrepost: Remove repost and decrement count
        MySQL.query.await('DELETE FROM phone_chirper_reposts WHERE phone_number = ? AND post_id = ?', {
            phoneNumber,
            postId
        })
        
        newReposts = math.max(0, newReposts - 1)
        isReposted = false
    else
        -- Repost: Add repost and increment count
        MySQL.insert.await('INSERT INTO phone_chirper_reposts (phone_number, post_id) VALUES (?, ?)', {
            phoneNumber,
            postId
        })
        
        newReposts = newReposts + 1
        isReposted = true
        
        -- Notify post author
        if post[1].author_number ~= phoneNumber then
            TriggerEvent('phone:server:sendNotification', post[1].author_number, {
                app = 'chirper',
                title = 'New Repost',
                message = 'Someone reposted your post'
            })
        end
    end
    
    -- Update post reposts count
    MySQL.update.await('UPDATE phone_chirper_posts SET reposts = ? WHERE id = ?', {
        newReposts,
        postId
    })
    
    -- Send response
    TriggerClientEvent('phone:client:repostChirperPostResult', source, {
        success = true,
        postId = postId,
        reposts = newReposts,
        isReposted = isReposted
    })
    
    -- Broadcast repost update to all online players
    TriggerClientEvent('phone:client:chirperPostRepostUpdate', -1, {
        postId = postId,
        reposts = newReposts
    })
end)

-- Reply to a post (alias for createChirperPost with parentId)
RegisterNetEvent('phone:server:replyToChirperPost', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local postId = tonumber(data.postId)
    local content = data.content
    
    if not postId or not content then
        TriggerClientEvent('phone:client:replyToChirperPostResult', source, {
            success = false,
            message = 'Invalid reply data'
        })
        return
    end
    
    -- Use createChirperPost logic with parentId
    TriggerEvent('phone:server:createChirperPost', {
        content = content,
        parentId = postId
    })
end)

-- Delete a post
RegisterNetEvent('phone:server:deleteChirperPost', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local postId = tonumber(data.postId)
    
    if not postId then
        TriggerClientEvent('phone:client:deleteChirperPostResult', source, {
            success = false,
            message = 'Invalid post ID'
        })
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:deleteChirperPostResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Verify post ownership
    local post = MySQL.query.await('SELECT id, author_number FROM phone_chirper_posts WHERE id = ?', {
        postId
    })
    
    if not post or #post == 0 then
        TriggerClientEvent('phone:client:deleteChirperPostResult', source, {
            success = false,
            message = 'Post not found'
        })
        return
    end
    
    if post[1].author_number ~= phoneNumber then
        TriggerClientEvent('phone:client:deleteChirperPostResult', source, {
            success = false,
            message = 'You can only delete your own posts'
        })
        return
    end
    
    -- Delete post (cascade will handle likes, reposts, hashtags)
    MySQL.query.await('DELETE FROM phone_chirper_posts WHERE id = ?', {
        postId
    })
    
    -- Send response
    TriggerClientEvent('phone:client:deleteChirperPostResult', source, {
        success = true,
        postId = postId
    })
    
    -- Broadcast deletion to all online players
    TriggerClientEvent('phone:client:chirperPostDeleted', -1, {
        postId = postId
    })
end)

-- Clean up old posts periodically (optional)
if Config.Chirper and Config.Chirper.autoCleanup then
    CreateThread(function()
        while true do
            Wait(Config.Chirper.cleanupInterval or 3600000) -- Default 1 hour
            
            local daysToKeep = Config.Chirper.daysToKeep or 90
            
            MySQL.query.await([[
                DELETE FROM phone_chirper_posts
                WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
            ]], {
                daysToKeep
            })
            
            if Config.DebugMode then
                print('[Phone] Cleaned up old Chirper posts')
            end
        end
    end)
end
