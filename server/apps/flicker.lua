-- Flicker App Server Logic
-- Handles dating/matching operations including profiles, swipes, matches, and messaging

-- Helper function to calculate distance between two coordinates
local function calculateDistance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

-- Helper function to get player coordinates
local function getPlayerCoords(source)
    local ped = GetPlayerPed(source)
    if ped and ped > 0 then
        local coords = GetEntityCoords(ped)
        return coords.x, coords.y
    end
    return nil, nil
end

-- Helper function to check if two players have matched
local function checkForMatch(phoneNumber1, phoneNumber2)
    -- Check if both players have liked each other
    local swipe1 = MySQL.query.await([[
        SELECT swipe_type FROM phone_flicker_swipes
        WHERE swiper_number = ? AND swiped_number = ? AND swipe_type = 'like'
    ]], {
        phoneNumber1,
        phoneNumber2
    })
    
    local swipe2 = MySQL.query.await([[
        SELECT swipe_type FROM phone_flicker_swipes
        WHERE swiper_number = ? AND swiped_number = ? AND swipe_type = 'like'
    ]], {
        phoneNumber2,
        phoneNumber1
    })
    
    return (swipe1 and #swipe1 > 0) and (swipe2 and #swipe2 > 0)
end

-- Helper function to create match entry
local function createMatch(phoneNumber1, phoneNumber2)
    -- Ensure consistent ordering (player1 < player2)
    local player1, player2 = phoneNumber1, phoneNumber2
    if phoneNumber1 > phoneNumber2 then
        player1, player2 = phoneNumber2, phoneNumber1
    end
    
    MySQL.insert.await([[
        INSERT INTO phone_flicker_matches (player1_number, player2_number)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE matched_at = CURRENT_TIMESTAMP
    ]], {
        player1,
        player2
    })
end

-- Get or create user's Flicker profile
RegisterNetEvent('phone:server:getFlickerProfile', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveFlickerProfile', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Get profile from database
    local profile = MySQL.query.await([[
        SELECT 
            phone_number,
            display_name,
            bio,
            age,
            photos_json,
            preferences_json,
            active,
            UNIX_TIMESTAMP(created_at) * 1000 as created_at,
            UNIX_TIMESTAMP(updated_at) * 1000 as updated_at
        FROM phone_flicker_profiles
        WHERE phone_number = ?
    ]], {
        phoneNumber
    })
    
    if profile and #profile > 0 then
        -- Parse JSON fields
        local profileData = profile[1]
        profileData.photos = json.decode(profileData.photos_json or '[]')
        profileData.preferences = json.decode(profileData.preferences_json or '{}')
        profileData.photos_json = nil
        profileData.preferences_json = nil
        
        TriggerClientEvent('phone:client:receiveFlickerProfile', source, {
            success = true,
            profile = profileData
        })
    else
        -- No profile exists
        TriggerClientEvent('phone:client:receiveFlickerProfile', source, {
            success = true,
            profile = nil
        })
    end
end)

-- Save or update user's Flicker profile
RegisterNetEvent('phone:server:saveFlickerProfile', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:saveFlickerProfileResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Validation
    local displayName = data.displayName or ''
    local bio = data.bio or ''
    local age = tonumber(data.age) or 18
    local photos = data.photos or {}
    local preferences = data.preferences or {}
    local active = data.active ~= false -- Default to true
    
    if #displayName == 0 then
        TriggerClientEvent('phone:client:saveFlickerProfileResult', source, {
            success = false,
            message = 'Display name is required'
        })
        return
    end
    
    if age < 18 or age > 100 then
        TriggerClientEvent('phone:client:saveFlickerProfileResult', source, {
            success = false,
            message = 'Age must be between 18 and 100'
        })
        return
    end
    
    if #bio > 500 then
        TriggerClientEvent('phone:client:saveFlickerProfileResult', source, {
            success = false,
            message = 'Bio is too long (max 500 characters)'
        })
        return
    end
    
    -- Encode JSON fields
    local photosJson = json.encode(photos)
    local preferencesJson = json.encode(preferences)
    
    -- Insert or update profile
    MySQL.query.await([[
        INSERT INTO phone_flicker_profiles 
        (phone_number, display_name, bio, age, photos_json, preferences_json, active)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            display_name = VALUES(display_name),
            bio = VALUES(bio),
            age = VALUES(age),
            photos_json = VALUES(photos_json),
            preferences_json = VALUES(preferences_json),
            active = VALUES(active),
            updated_at = CURRENT_TIMESTAMP
    ]], {
        phoneNumber,
        displayName,
        bio,
        age,
        photosJson,
        preferencesJson,
        active
    })
    
    -- Get updated profile
    local profile = MySQL.query.await([[
        SELECT 
            phone_number,
            display_name,
            bio,
            age,
            photos_json,
            preferences_json,
            active,
            UNIX_TIMESTAMP(created_at) * 1000 as created_at,
            UNIX_TIMESTAMP(updated_at) * 1000 as updated_at
        FROM phone_flicker_profiles
        WHERE phone_number = ?
    ]], {
        phoneNumber
    })
    
    if profile and #profile > 0 then
        local profileData = profile[1]
        profileData.photos = json.decode(profileData.photos_json or '[]')
        profileData.preferences = json.decode(profileData.preferences_json or '{}')
        profileData.photos_json = nil
        profileData.preferences_json = nil
        
        TriggerClientEvent('phone:client:saveFlickerProfileResult', source, {
            success = true,
            profile = profileData
        })
    else
        TriggerClientEvent('phone:client:saveFlickerProfileResult', source, {
            success = false,
            message = 'Failed to save profile'
        })
    end
end)

-- Get potential matches for swiping
RegisterNetEvent('phone:server:getFlickerPotentialMatches', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveFlickerPotentialMatches', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Get user's profile to check preferences
    local myProfile = MySQL.query.await([[
        SELECT age, preferences_json FROM phone_flicker_profiles
        WHERE phone_number = ? AND active = TRUE
    ]], {
        phoneNumber
    })
    
    if not myProfile or #myProfile == 0 then
        TriggerClientEvent('phone:client:receiveFlickerPotentialMatches', source, {
            success = false,
            message = 'You need to create a profile first'
        })
        return
    end
    
    local preferences = json.decode(myProfile[1].preferences_json or '{}')
    local minAge = preferences.minAge or 18
    local maxAge = preferences.maxAge or 100
    local maxDistance = preferences.maxDistance or 5000
    
    local limit = data.limit or 10
    
    -- Get player coordinates
    local myX, myY = getPlayerCoords(source)
    
    -- Get potential matches (profiles user hasn't swiped on yet)
    local potentialMatches = MySQL.query.await([[
        SELECT 
            p.phone_number,
            p.display_name,
            p.bio,
            p.age,
            p.photos_json,
            UNIX_TIMESTAMP(p.created_at) * 1000 as created_at
        FROM phone_flicker_profiles p
        WHERE p.phone_number != ?
            AND p.active = TRUE
            AND p.age BETWEEN ? AND ?
            AND p.phone_number NOT IN (
                SELECT swiped_number FROM phone_flicker_swipes
                WHERE swiper_number = ?
            )
            AND p.phone_number NOT IN (
                SELECT blocked_number FROM phone_flicker_blocks
                WHERE blocker_number = ?
            )
            AND p.phone_number NOT IN (
                SELECT blocker_number FROM phone_flicker_blocks
                WHERE blocked_number = ?
            )
        ORDER BY RAND()
        LIMIT ?
    ]], {
        phoneNumber,
        minAge,
        maxAge,
        phoneNumber,
        phoneNumber,
        phoneNumber,
        limit
    })
    
    -- Parse photos and filter by distance if coordinates available
    local filteredMatches = {}
    for _, match in ipairs(potentialMatches or {}) do
        match.photos = json.decode(match.photos_json or '[]')
        match.photos_json = nil
        
        -- Check distance if coordinates available
        if myX and myY then
            local targetSource = Framework:GetPlayerByPhoneNumber(match.phone_number)
            if targetSource then
                local targetX, targetY = getPlayerCoords(targetSource)
                if targetX and targetY then
                    local distance = calculateDistance(myX, myY, targetX, targetY)
                    if distance <= maxDistance then
                        match.distance = math.floor(distance)
                        table.insert(filteredMatches, match)
                    end
                else
                    -- Include if can't get coords
                    table.insert(filteredMatches, match)
                end
            else
                -- Include offline players
                table.insert(filteredMatches, match)
            end
        else
            -- Include if can't get own coords
            table.insert(filteredMatches, match)
        end
    end
    
    TriggerClientEvent('phone:client:receiveFlickerPotentialMatches', source, {
        success = true,
        profiles = filteredMatches
    })
end)

-- Swipe on a profile (like or pass)
RegisterNetEvent('phone:server:swipeFlickerProfile', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:swipeFlickerProfileResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    local swipedNumber = data.phoneNumber
    local swipeType = data.swipeType -- 'like' or 'pass'
    
    if not swipedNumber or not swipeType then
        TriggerClientEvent('phone:client:swipeFlickerProfileResult', source, {
            success = false,
            message = 'Invalid swipe data'
        })
        return
    end
    
    if swipeType ~= 'like' and swipeType ~= 'pass' then
        TriggerClientEvent('phone:client:swipeFlickerProfileResult', source, {
            success = false,
            message = 'Invalid swipe type'
        })
        return
    end
    
    if phoneNumber == swipedNumber then
        TriggerClientEvent('phone:client:swipeFlickerProfileResult', source, {
            success = false,
            message = 'Cannot swipe on yourself'
        })
        return
    end
    
    -- Check if already swiped
    local existingSwipe = MySQL.query.await([[
        SELECT swipe_type FROM phone_flicker_swipes
        WHERE swiper_number = ? AND swiped_number = ?
    ]], {
        phoneNumber,
        swipedNumber
    })
    
    if existingSwipe and #existingSwipe > 0 then
        TriggerClientEvent('phone:client:swipeFlickerProfileResult', source, {
            success = false,
            message = 'Already swiped on this profile'
        })
        return
    end
    
    -- Record swipe
    MySQL.insert.await([[
        INSERT INTO phone_flicker_swipes (swiper_number, swiped_number, swipe_type)
        VALUES (?, ?, ?)
    ]], {
        phoneNumber,
        swipedNumber,
        swipeType
    })
    
    -- Check for match if this was a like
    local isMatch = false
    local matchData = nil
    
    if swipeType == 'like' then
        isMatch = checkForMatch(phoneNumber, swipedNumber)
        
        if isMatch then
            -- Create match entry
            createMatch(phoneNumber, swipedNumber)
            
            -- Get match profile data
            local matchProfile = MySQL.query.await([[
                SELECT 
                    phone_number,
                    display_name,
                    bio,
                    age,
                    photos_json,
                    UNIX_TIMESTAMP(created_at) * 1000 as created_at
                FROM phone_flicker_profiles
                WHERE phone_number = ?
            ]], {
                swipedNumber
            })
            
            if matchProfile and #matchProfile > 0 then
                matchData = matchProfile[1]
                matchData.photos = json.decode(matchData.photos_json or '[]')
                matchData.photos_json = nil
                matchData.matched_at = os.time() * 1000
            end
            
            -- Notify both players
            TriggerEvent('phone:server:sendNotification', swipedNumber, {
                app = 'flicker',
                title = 'New Match!',
                message = 'You matched with someone!'
            })
            
            -- Send match notification to other player
            local targetSource = Framework:GetPlayerByPhoneNumber(swipedNumber)
            if targetSource then
                local myProfile = MySQL.query.await([[
                    SELECT 
                        phone_number,
                        display_name,
                        bio,
                        age,
                        photos_json
                    FROM phone_flicker_profiles
                    WHERE phone_number = ?
                ]], {
                    phoneNumber
                })
                
                if myProfile and #myProfile > 0 then
                    local myData = myProfile[1]
                    myData.photos = json.decode(myData.photos_json or '[]')
                    myData.photos_json = nil
                    myData.matched_at = os.time() * 1000
                    
                    TriggerClientEvent('phone:client:newFlickerMatch', targetSource, myData)
                end
            end
        end
    end
    
    TriggerClientEvent('phone:client:swipeFlickerProfileResult', source, {
        success = true,
        isMatch = isMatch,
        match = matchData
    })
end)

-- Get user's matches
RegisterNetEvent('phone:server:getFlickerMatches', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveFlickerMatches', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Get matches
    local matches = MySQL.query.await([[
        SELECT 
            CASE 
                WHEN m.player1_number = ? THEN p.phone_number
                ELSE p2.phone_number
            END as phone_number,
            CASE 
                WHEN m.player1_number = ? THEN p.display_name
                ELSE p2.display_name
            END as display_name,
            CASE 
                WHEN m.player1_number = ? THEN p.bio
                ELSE p2.bio
            END as bio,
            CASE 
                WHEN m.player1_number = ? THEN p.age
                ELSE p2.age
            END as age,
            CASE 
                WHEN m.player1_number = ? THEN p.photos_json
                ELSE p2.photos_json
            END as photos_json,
            UNIX_TIMESTAMP(m.matched_at) * 1000 as matched_at,
            UNIX_TIMESTAMP(m.last_message_at) * 1000 as last_message_at
        FROM phone_flicker_matches m
        LEFT JOIN phone_flicker_profiles p ON m.player2_number = p.phone_number
        LEFT JOIN phone_flicker_profiles p2 ON m.player1_number = p2.phone_number
        WHERE (m.player1_number = ? OR m.player2_number = ?)
            AND m.unmatched = FALSE
        ORDER BY m.last_message_at DESC, m.matched_at DESC
    ]], {
        phoneNumber, phoneNumber, phoneNumber, phoneNumber, phoneNumber,
        phoneNumber, phoneNumber
    })
    
    -- Parse photos
    for _, match in ipairs(matches or {}) do
        match.photos = json.decode(match.photos_json or '[]')
        match.photos_json = nil
    end
    
    TriggerClientEvent('phone:client:receiveFlickerMatches', source, {
        success = true,
        matches = matches or {}
    })
end)

-- Unmatch with a user
RegisterNetEvent('phone:server:unmatchFlicker', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:unmatchFlickerResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    local targetNumber = data.phoneNumber
    
    if not targetNumber then
        TriggerClientEvent('phone:client:unmatchFlickerResult', source, {
            success = false,
            message = 'Invalid phone number'
        })
        return
    end
    
    -- Update match to unmatched
    MySQL.update.await([[
        UPDATE phone_flicker_matches
        SET unmatched = TRUE, unmatched_by = ?, unmatched_at = CURRENT_TIMESTAMP
        WHERE ((player1_number = ? AND player2_number = ?)
            OR (player1_number = ? AND player2_number = ?))
            AND unmatched = FALSE
    ]], {
        phoneNumber,
        phoneNumber, targetNumber,
        targetNumber, phoneNumber
    })
    
    -- Notify other player
    TriggerEvent('phone:server:sendNotification', targetNumber, {
        app = 'flicker',
        title = 'Match Ended',
        message = 'A match has ended'
    })
    
    local targetSource = Framework:GetPlayerByPhoneNumber(targetNumber)
    if targetSource then
        TriggerClientEvent('phone:client:flickerUnmatched', targetSource, {
            phoneNumber = phoneNumber
        })
    end
    
    TriggerClientEvent('phone:client:unmatchFlickerResult', source, {
        success = true
    })
end)

-- Get messages with a match
RegisterNetEvent('phone:server:getFlickerMessages', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveFlickerMessages', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    local targetNumber = data.phoneNumber
    
    if not targetNumber then
        TriggerClientEvent('phone:client:receiveFlickerMessages', source, {
            success = false,
            message = 'Invalid phone number'
        })
        return
    end
    
    -- Verify match exists
    local match = MySQL.query.await([[
        SELECT 1 FROM phone_flicker_matches
        WHERE ((player1_number = ? AND player2_number = ?)
            OR (player1_number = ? AND player2_number = ?))
            AND unmatched = FALSE
    ]], {
        phoneNumber, targetNumber,
        targetNumber, phoneNumber
    })
    
    if not match or #match == 0 then
        TriggerClientEvent('phone:client:receiveFlickerMessages', source, {
            success = false,
            message = 'No match found'
        })
        return
    end
    
    -- Get messages
    local messages = MySQL.query.await([[
        SELECT 
            id,
            sender_number,
            receiver_number,
            content,
            read_status,
            UNIX_TIMESTAMP(created_at) * 1000 as created_at
        FROM phone_flicker_messages
        WHERE (sender_number = ? AND receiver_number = ?)
            OR (sender_number = ? AND receiver_number = ?)
        ORDER BY created_at ASC
    ]], {
        phoneNumber, targetNumber,
        targetNumber, phoneNumber
    })
    
    -- Mark messages as read
    MySQL.update.await([[
        UPDATE phone_flicker_messages
        SET read_status = TRUE
        WHERE sender_number = ? AND receiver_number = ? AND read_status = FALSE
    ]], {
        targetNumber,
        phoneNumber
    })
    
    TriggerClientEvent('phone:client:receiveFlickerMessages', source, {
        success = true,
        messages = messages or {}
    })
end)

-- Send message to a match
RegisterNetEvent('phone:server:sendFlickerMessage', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:sendFlickerMessageResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    local targetNumber = data.phoneNumber
    local content = data.content or ''
    
    -- Trim content
    content = content:gsub("^%s*(.-)%s*$", "%1")
    
    if not targetNumber or #content == 0 then
        TriggerClientEvent('phone:client:sendFlickerMessageResult', source, {
            success = false,
            message = 'Invalid message data'
        })
        return
    end
    
    if #content > 500 then
        TriggerClientEvent('phone:client:sendFlickerMessageResult', source, {
            success = false,
            message = 'Message is too long (max 500 characters)'
        })
        return
    end
    
    -- Verify match exists
    local match = MySQL.query.await([[
        SELECT 1 FROM phone_flicker_matches
        WHERE ((player1_number = ? AND player2_number = ?)
            OR (player1_number = ? AND player2_number = ?))
            AND unmatched = FALSE
    ]], {
        phoneNumber, targetNumber,
        targetNumber, phoneNumber
    })
    
    if not match or #match == 0 then
        TriggerClientEvent('phone:client:sendFlickerMessageResult', source, {
            success = false,
            message = 'No match found'
        })
        return
    end
    
    -- Insert message
    local messageId = MySQL.insert.await([[
        INSERT INTO phone_flicker_messages (sender_number, receiver_number, content)
        VALUES (?, ?, ?)
    ]], {
        phoneNumber,
        targetNumber,
        content
    })
    
    if not messageId then
        TriggerClientEvent('phone:client:sendFlickerMessageResult', source, {
            success = false,
            message = 'Failed to send message'
        })
        return
    end
    
    -- Update match last_message_at
    MySQL.update.await([[
        UPDATE phone_flicker_matches
        SET last_message_at = CURRENT_TIMESTAMP
        WHERE (player1_number = ? AND player2_number = ?)
            OR (player1_number = ? AND player2_number = ?)
    ]], {
        phoneNumber, targetNumber,
        targetNumber, phoneNumber
    })
    
    -- Get the created message
    local message = {
        id = messageId,
        sender_number = phoneNumber,
        receiver_number = targetNumber,
        content = content,
        read_status = false,
        created_at = os.time() * 1000
    }
    
    -- Send success response to sender
    TriggerClientEvent('phone:client:sendFlickerMessageResult', source, {
        success = true,
        message = message
    })
    
    -- Notify receiver
    TriggerEvent('phone:server:sendNotification', targetNumber, {
        app = 'flicker',
        title = 'New Message',
        message = 'You have a new message from a match'
    })
    
    local targetSource = Framework:GetPlayerByPhoneNumber(targetNumber)
    if targetSource then
        TriggerClientEvent('phone:client:newFlickerMessage', targetSource, {
            phoneNumber = phoneNumber,
            message = message
        })
    end
end)

-- Block a user
RegisterNetEvent('phone:server:blockFlickerUser', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    local targetNumber = data.phoneNumber
    
    if not targetNumber or phoneNumber == targetNumber then
        return
    end
    
    -- Add block entry
    MySQL.insert.await([[
        INSERT IGNORE INTO phone_flicker_blocks (blocker_number, blocked_number)
        VALUES (?, ?)
    ]], {
        phoneNumber,
        targetNumber
    })
    
    -- Unmatch if matched
    MySQL.update.await([[
        UPDATE phone_flicker_matches
        SET unmatched = TRUE, unmatched_by = ?, unmatched_at = CURRENT_TIMESTAMP
        WHERE ((player1_number = ? AND player2_number = ?)
            OR (player1_number = ? AND player2_number = ?))
            AND unmatched = FALSE
    ]], {
        phoneNumber,
        phoneNumber, targetNumber,
        targetNumber, phoneNumber
    })
end)

-- Report a user
RegisterNetEvent('phone:server:reportFlickerUser', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    local targetNumber = data.phoneNumber
    local reason = data.reason or 'No reason provided'
    local details = data.details or ''
    
    if not targetNumber or phoneNumber == targetNumber then
        return
    end
    
    -- Insert report
    MySQL.insert.await([[
        INSERT INTO phone_flicker_reports (reporter_number, reported_number, reason, details)
        VALUES (?, ?, ?, ?)
    ]], {
        phoneNumber,
        targetNumber,
        reason,
        details
    })
    
    -- Log for admin review
    if Config.Debug then
        print(string.format('[Flicker] User %s reported %s for: %s', phoneNumber, targetNumber, reason))
    end
end)
