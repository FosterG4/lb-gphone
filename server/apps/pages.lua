-- Business Pages App Server Events (Demo Version)
-- Provides simple demo responses for business pages functionality

-- Demo data for business pages
local demoPages = {
    {
        id = 1,
        owner_number = "555-0201",
        name = "Joe's Pizza",
        category = "restaurant",
        description = "Best pizza in town! Fresh ingredients, authentic recipes, and fast delivery.",
        phone = "555-0201",
        location = "Downtown Los Santos",
        location_x = -269.4,
        location_y = -957.3,
        website = "www.joespizza.com",
        hours = "Mon-Sun: 11AM-11PM",
        avatar = "pizza_logo.jpg",
        photos = {"pizza1.jpg", "pizza2.jpg"},
        status = "active",
        followers_count = 245,
        views_count = 1250,
        created_at = "2024-01-15 10:30:00",
        updated_at = "2024-01-15 10:30:00"
    },
    {
        id = 2,
        owner_number = "555-0202",
        name = "Tech Repair Shop",
        category = "services",
        description = "Professional electronics repair service. Phones, laptops, tablets - we fix it all!",
        phone = "555-0202",
        location = "Vinewood Hills",
        location_x = 372.5,
        location_y = 326.8,
        website = "www.techrepair.com",
        hours = "Mon-Fri: 9AM-6PM",
        avatar = "tech_logo.jpg",
        photos = {"shop1.jpg", "repair1.jpg"},
        status = "active",
        followers_count = 89,
        views_count = 456,
        created_at = "2024-01-14 14:20:00",
        updated_at = "2024-01-14 14:20:00"
    },
    {
        id = 3,
        owner_number = "555-0203",
        name = "Fashion Boutique",
        category = "retail",
        description = "Trendy clothing and accessories for men and women. Latest fashion at affordable prices.",
        phone = "555-0203",
        location = "Rockford Hills",
        location_x = -1447.8,
        location_y = -238.5,
        website = "www.fashionboutique.com",
        hours = "Mon-Sat: 10AM-8PM",
        avatar = "fashion_logo.jpg",
        photos = {"store1.jpg", "clothes1.jpg"},
        status = "active",
        followers_count = 156,
        views_count = 789,
        created_at = "2024-01-13 09:15:00",
        updated_at = "2024-01-13 09:15:00"
    },
    {
        id = 4,
        owner_number = "555-0204",
        name = "Auto Garage",
        category = "automotive",
        description = "Full-service auto repair and maintenance. Experienced mechanics, quality parts.",
        phone = "555-0204",
        location = "La Mesa",
        location_x = 731.2,
        location_y = -1088.7,
        website = "www.autogarage.com",
        hours = "Mon-Fri: 8AM-6PM",
        avatar = "garage_logo.jpg",
        photos = {"garage1.jpg", "cars1.jpg"},
        status = "active",
        followers_count = 78,
        views_count = 345,
        created_at = "2024-01-12 16:45:00",
        updated_at = "2024-01-12 16:45:00"
    },
    {
        id = 5,
        owner_number = "555-0205",
        name = "Entertainment Center",
        category = "entertainment",
        description = "Gaming, bowling, arcade, and more! Perfect place for family fun and parties.",
        phone = "555-0205",
        location = "Del Perro",
        location_x = -1652.3,
        location_y = -1072.4,
        website = "www.entertainment.com",
        hours = "Daily: 12PM-12AM",
        avatar = "entertainment_logo.jpg",
        photos = {"arcade1.jpg", "bowling1.jpg"},
        status = "active",
        followers_count = 312,
        views_count = 1567,
        created_at = "2024-01-11 11:30:00",
        updated_at = "2024-01-11 11:30:00"
    }
}

-- Get all business pages with optional filters
RegisterNetEvent('phone:server:getBusinessPages', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    -- Simple demo response with static data
    local filteredPages = {}
    
    for _, page in ipairs(demoPages) do
        local includeItem = true
        
        -- Filter by category if specified
        if data and data.category and data.category ~= 'all' then
            if page.category ~= data.category then
                includeItem = false
            end
        end
        
        -- Filter by search if specified
        if data and data.search and data.search ~= '' then
            local searchLower = string.lower(data.search)
            local nameLower = string.lower(page.name)
            local descLower = string.lower(page.description)
            
            if not string.find(nameLower, searchLower) and not string.find(descLower, searchLower) then
                includeItem = false
            end
        end
        
        if includeItem then
            table.insert(filteredPages, page)
        end
    end
    
    TriggerClientEvent('phone:client:receiveBusinessPages', source, {
        success = true,
        pages = filteredPages
    })
end)

-- Get user's own business pages
RegisterNetEvent('phone:server:getMyBusinessPages', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveMyBusinessPages', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Return demo pages that belong to the user
    local myPages = {}
    for _, page in ipairs(demoPages) do
        if page.owner_number == phoneNumber then
            table.insert(myPages, page)
        end
    end
    
    -- If no pages found for user, return a demo page
    if #myPages == 0 then
        table.insert(myPages, {
            id = 999,
            owner_number = phoneNumber,
            name = "My Demo Business",
            category = "other",
            description = "This is a demo business page created for testing purposes.",
            phone = phoneNumber,
            location = "Demo Location",
            location_x = 0,
            location_y = 0,
            website = "www.demo.com",
            hours = "24/7",
            avatar = "demo_logo.jpg",
            photos = {"demo1.jpg"},
            status = "active",
            followers_count = 10,
            views_count = 50,
            created_at = "2024-01-16 12:00:00",
            updated_at = "2024-01-16 12:00:00"
        })
    end
    
    TriggerClientEvent('phone:client:receiveMyBusinessPages', source, {
        success = true,
        pages = myPages
    })
end)

-- Get pages that user is following
RegisterNetEvent('phone:server:getFollowingPages', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveFollowingPages', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Return a subset of demo pages as "following"
    local followingPages = {demoPages[1], demoPages[3], demoPages[5]}
    
    TriggerClientEvent('phone:client:receiveFollowingPages', source, {
        success = true,
        pages = followingPages
    })
end)

-- Create a new business page
RegisterNetEvent('phone:server:createBusinessPage', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:businessPageCreated', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Simple validation
    if not data or not data.name or not data.category or not data.description then
        TriggerClientEvent('phone:client:businessPageCreated', source, {
            success = false,
            message = 'Missing required fields'
        })
        return
    end
    
    -- Demo response - always successful
    TriggerClientEvent('phone:client:businessPageCreated', source, {
        success = true,
        message = 'Demo business page created successfully',
        pageId = math.random(1000, 9999)
    })
end)

-- Update an existing business page
RegisterNetEvent('phone:server:updateBusinessPage', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    -- Demo response - always successful
    TriggerClientEvent('phone:client:businessPageUpdated', source, {
        success = true,
        message = 'Demo business page updated successfully'
    })
end)

-- Delete a business page
RegisterNetEvent('phone:server:deleteBusinessPage', function(pageId)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    -- Demo response - always successful
    TriggerClientEvent('phone:client:businessPageDeleted', source, {
        success = true,
        message = 'Demo business page deleted successfully'
    })
end)

-- Follow a business page
RegisterNetEvent('phone:server:followBusinessPage', function(pageId)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    -- Demo response - always successful
    TriggerClientEvent('phone:client:businessPageFollowed', source, {
        success = true,
        message = 'Demo page followed successfully'
    })
end)

-- Unfollow a business page
RegisterNetEvent('phone:server:unfollowBusinessPage', function(pageId)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    -- Demo response - always successful
    TriggerClientEvent('phone:client:businessPageUnfollowed', source, {
        success = true,
        message = 'Demo page unfollowed successfully'
    })
end)

-- Record page view
RegisterNetEvent('phone:server:recordPageView', function(pageId)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    -- Demo response - no action needed for views in demo mode
end)

-- Get page statistics
RegisterNetEvent('phone:server:getPageStatistics', function(pageId)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    -- Demo stats response
    local demoStats = {
        total_views = 1250,
        total_followers = 245,
        weekly_views = 89,
        weekly_followers = 12,
        top_locations = {
            {location = "Downtown", views = 450},
            {location = "Vinewood", views = 320},
            {location = "Del Perro", views = 280}
        },
        view_history = {
            {date = "2024-01-15", views = 45},
            {date = "2024-01-14", views = 38},
            {date = "2024-01-13", views = 52},
            {date = "2024-01-12", views = 41},
            {date = "2024-01-11", views = 35}
        }
    }
    
    TriggerClientEvent('phone:client:receivePageStatistics', source, {
        success = true,
        statistics = demoStats
    })
end)

-- Send page announcement
RegisterNetEvent('phone:server:sendPageAnnouncement', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    -- Demo response - always successful
    TriggerClientEvent('phone:client:pageAnnouncementSent', source, {
        success = true,
        message = 'Demo announcement sent to followers'
    })
end)