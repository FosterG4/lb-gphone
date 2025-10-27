-- Chirper App Server Logic
-- Handles chirper operations including posting, fetching feed, liking chirps

-- Rate limiting for chirp posting
local chirpCooldowns = {}

-- Track user likes
local userLikes = {} -- Format: { [phoneNumber] = { [chirpId] = true } }

-- Get chirper feed and user's chirps
RegisterNetEvent('phone:server:getChirperFeed', function()
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
    
    -- Get feed (all chirps, ordered by newest first)
    local feed = MySQL.query.await([[
        SELECT 
            id,
            author_number,
            author_name,
            content,
            likes,
            UNIX_TIMESTAMP(created_at) * 1000 as created_at
        FROM phone_chirps
        ORDER BY created_at DESC
        LIMIT ?
    ]], {
        Config.ChirperApp.maxFeedItems or 50
    })
    
    -- Get user's chirps
    local myChirps = MySQL.query.await([[
        SELECT 
            id,
            author_number,
            author_name,
            content,
            likes,
            UNIX_TIMESTAMP(created_at) * 1000 as created_at
        FROM phone_chirps
        WHERE author_number = ?
        ORDER BY created_at DESC
        LIMIT ?
    ]], {
        phoneNumber,
        Config.ChirperApp.maxFeedItems or 50
    })
    
    -- Get user's liked chirps
    local likedChirps = MySQL.query.await([[
        SELECT chirp_id
        FROM phone_chirp_likes
        WHERE phone_number = ?
    ]], {
        phoneNumber
    })
    
    -- Create a set of liked chirp IDs
    local likedSet = {}
    for _, like in ipairs(likedChirps or {}) do
        likedSet[like.chirp_id] = true
    end
    
    -- Mark chirps as liked if user has liked them
    for _, chirp in ipairs(feed or {}) do
        chirp.isLiked = likedSet[chirp.id] or false
    end
    
    for _, chirp in ipairs(myChirps or {}) do
        chirp.isLiked = likedSet[chirp.id] or false
    end
    
    TriggerClientEvent('phone:client:receiveChirperFeed', source, {
        success = true,
        feed = feed or {},
        myChirps = myChirps or {}
    })
end)

-- Post a new chirp
RegisterNetEvent('phone:server:postChirp', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local content = data.content
    
    -- Validation
    if not content or type(content) ~= 'string' then
        TriggerClientEvent('phone:client:postChirpResult', source, {
            success = false,
            message = 'Invalid chirp content'
        })
        return
    end
    
    -- Trim content
    content = content:gsub("^%s*(.-)%s*$", "%1")
    
    -- Validate content length
    if #content == 0 then
        TriggerClientEvent('phone:client:postChirpResult', source, {
            success = false,
            message = 'Chirp cannot be empty'
        })
        return
    end
    
    if #content > (Config.ChirperApp.maxChirpLength or 280) then
        TriggerClientEvent('phone:client:postChirpResult', source, {
            success = false,
            message = 'Chirp is too long (max 280 characters)'
        })
        return
    end
    
    -- Get phone number and author name
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:postChirpResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Rate limiting check
    local currentTime = os.time()
    if chirpCooldowns[phoneNumber] and (currentTime - chirpCooldowns[phoneNumber]) < (Config.ChirperApp.chirpCooldown or 5) then
        local remainingTime = (Config.ChirperApp.chirpCooldown or 5) - (currentTime - chirpCooldowns[phoneNumber])
        TriggerClientEvent('phone:client:postChirpResult', source, {
            success = false,
            message = string.format('Please wait %d seconds before posting again', remainingTime)
        })
        return
    end
    
    -- Get author name (use framework character name or phone number)
    local authorName = Framework:GetPlayerName(source) or phoneNumber
    
    -- Insert chirp into database
    local insertId = MySQL.insert.await([[
        INSERT INTO phone_chirps (author_number, author_name, content, likes)
        VALUES (?, ?, ?, 0)
    ]], {
        phoneNumber,
        authorName,
        content
    })
    
    if not insertId then
        TriggerClientEvent('phone:client:postChirpResult', source, {
            success = false,
            message = 'Failed to post chirp'
        })
        return
    end
    
    -- Update cooldown
    chirpCooldowns[phoneNumber] = currentTime
    
    -- Get the created chirp
    local chirp = MySQL.query.await([[
        SELECT 
            id,
            author_number,
            author_name,
            content,
            likes,
            UNIX_TIMESTAMP(created_at) * 1000 as created_at
        FROM phone_chirps
        WHERE id = ?
    ]], {
        insertId
    })
    
    if chirp and #chirp > 0 then
        chirp[1].isLiked = false
        
        -- Send success response to poster
        TriggerClientEvent('phone:client:postChirpResult', source, {
            success = true,
            chirp = chirp[1]
        })
        
        -- Broadcast new chirp to all online players
        TriggerClientEvent('phone:client:newChirp', -1, chirp[1])
    else
        TriggerClientEvent('phone:client:postChirpResult', source, {
            success = false,
            message = 'Failed to retrieve posted chirp'
        })
    end
end)

-- Like/unlike a chirp
RegisterNetEvent('phone:server:likeChirp', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local chirpId = tonumber(data.chirpId)
    
    if not chirpId then
        TriggerClientEvent('phone:client:likeChirpResult', source, {
            success = false,
            message = 'Invalid chirp ID'
        })
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:likeChirpResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Check if chirp exists
    local chirp = MySQL.query.await('SELECT id, likes FROM phone_chirps WHERE id = ?', {
        chirpId
    })
    
    if not chirp or #chirp == 0 then
        TriggerClientEvent('phone:client:likeChirpResult', source, {
            success = false,
            message = 'Chirp not found'
        })
        return
    end
    
    -- Check if user has already liked this chirp
    local existingLike = MySQL.query.await([[
        SELECT id FROM phone_chirp_likes
        WHERE phone_number = ? AND chirp_id = ?
    ]], {
        phoneNumber,
        chirpId
    })
    
    local isLiked = false
    local newLikes = chirp[1].likes
    
    if existingLike and #existingLike > 0 then
        -- Unlike: Remove like and decrement count
        MySQL.query.await('DELETE FROM phone_chirp_likes WHERE phone_number = ? AND chirp_id = ?', {
            phoneNumber,
            chirpId
        })
        
        newLikes = math.max(0, newLikes - 1)
        isLiked = false
    else
        -- Like: Add like and increment count
        MySQL.insert.await('INSERT INTO phone_chirp_likes (phone_number, chirp_id) VALUES (?, ?)', {
            phoneNumber,
            chirpId
        })
        
        newLikes = newLikes + 1
        isLiked = true
    end
    
    -- Update chirp likes count
    MySQL.update.await('UPDATE phone_chirps SET likes = ? WHERE id = ?', {
        newLikes,
        chirpId
    })
    
    -- Send response
    TriggerClientEvent('phone:client:likeChirpResult', source, {
        success = true,
        chirpId = chirpId,
        likes = newLikes,
        isLiked = isLiked
    })
    
    -- Broadcast like update to all online players
    TriggerClientEvent('phone:client:chirpLikeUpdate', -1, {
        chirpId = chirpId,
        likes = newLikes
    })
end)

-- Clean up old chirps periodically (optional)
if Config.ChirperApp and Config.ChirperApp.autoCleanup then
    CreateThread(function()
        while true do
            Wait(Config.ChirperApp.cleanupInterval or 3600000) -- Default 1 hour
            
            local daysToKeep = Config.ChirperApp.daysToKeep or 30
            
            MySQL.query.await([[
                DELETE FROM phone_chirps
                WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
            ]], {
                daysToKeep
            })
            
            if Config.DebugMode then
                print('[Phone] Cleaned up old chirps')
            end
        end
    end)
end
