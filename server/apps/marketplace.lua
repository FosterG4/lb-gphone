-- Marketplace App Server Events
-- Provides full database integration for marketplace functionality

-- Get marketplace listings with filters and pagination
RegisterNetEvent('phone:server:getMarketplaceListings', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    -- Build query with filters
    local query = [[
        SELECT 
            id, seller_number, title, description, price, category, 
            photos_json, status, created_at
        FROM phone_marketplace_listings
        WHERE status = 'active'
    ]]
    
    local params = {}
    
    -- Filter by category
    if data and data.category and data.category ~= '' and data.category ~= 'all' then
        query = query .. ' AND category = ?'
        table.insert(params, data.category)
    end
    
    -- Filter by search query
    if data and data.search and data.search ~= '' then
        query = query .. ' AND (title LIKE ? OR description LIKE ?)'
        local searchPattern = '%' .. data.search .. '%'
        table.insert(params, searchPattern)
        table.insert(params, searchPattern)
    end
    
    -- Order by most recent
    query = query .. ' ORDER BY created_at DESC'
    
    -- Add pagination
    local limit = (data and data.limit) or 20
    local offset = (data and data.offset) or 0
    query = query .. ' LIMIT ? OFFSET ?'
    table.insert(params, limit)
    table.insert(params, offset)
    
    -- Execute query
    Database.Query(query, params, function(listings)
        if listings then
            -- Parse photos_json for each listing
            for _, listing in ipairs(listings) do
                if listing.photos_json then
                    listing.photos = json.decode(listing.photos_json)
                    listing.photos_json = nil
                end
            end
            
            TriggerClientEvent('phone:client:receiveMarketplaceListings', source, {
                success = true,
                listings = listings,
                total = #listings
            })
        else
            TriggerClientEvent('phone:client:receiveMarketplaceListings', source, {
                success = false,
                message = _L('marketplace_fetch_failed'),
                listings = {}
            })
        end
    end)
end)

-- Get user's marketplace listings
RegisterNetEvent('phone:server:getMyMarketplaceListings', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveMyMarketplaceListings', source, {
            success = false,
            message = _L('phone_number_not_found')
        })
        return
    end
    
    -- Query user's listings
    local query = [[
        SELECT 
            id, seller_number, title, description, price, category,
            photos_json, status, created_at
        FROM phone_marketplace_listings
        WHERE seller_number = ?
        ORDER BY created_at DESC
    ]]
    
    Database.Query(query, {phoneNumber}, function(listings)
        if listings then
            -- Parse photos_json for each listing
            for _, listing in ipairs(listings) do
                if listing.photos_json then
                    listing.photos = json.decode(listing.photos_json)
                    listing.photos_json = nil
                end
            end
            
            TriggerClientEvent('phone:client:receiveMyMarketplaceListings', source, {
                success = true,
                listings = listings
            })
        else
            TriggerClientEvent('phone:client:receiveMyMarketplaceListings', source, {
                success = false,
                message = _L('marketplace_fetch_failed'),
                listings = {}
            })
        end
    end)
end)

-- Create marketplace listing
RegisterNetEvent('phone:server:createMarketplaceListing', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:marketplaceListingResult', source, {
            success = false,
            message = _L('phone_number_not_found')
        })
        return
    end
    
    -- Validate required fields
    if not data or not data.title or not data.description or not data.price or not data.category then
        TriggerClientEvent('phone:client:marketplaceListingResult', source, {
            success = false,
            message = _L('marketplace_missing_fields')
        })
        return
    end
    
    -- Validate price
    local isValid, error = ValidateCurrency(data.price)
    if not isValid then
        TriggerClientEvent('phone:client:marketplaceListingResult', source, {
            success = false,
            message = error or _L('marketplace_invalid_price')
        })
        return
    end
    
    -- Check listing limit per player
    local query = 'SELECT COUNT(*) as count FROM phone_marketplace_listings WHERE seller_number = ? AND status = "active"'
    Database.Query(query, {phoneNumber}, function(result)
        if result and result[1] and result[1].count >= Config.MarketplaceApp.maxListingsPerPlayer then
            TriggerClientEvent('phone:client:marketplaceListingResult', source, {
                success = false,
                message = _L('marketplace_listing_limit')
            })
            return
        end
        
        -- Prepare photos JSON
        local photosJson = nil
        if data.photos and type(data.photos) == 'table' then
            photosJson = json.encode(data.photos)
        end
        
        -- Insert listing into database
        Database.Insert('phone_marketplace_listings', {
            seller_number = phoneNumber,
            title = data.title,
            description = data.description,
            price = data.price,
            category = data.category,
            photos_json = photosJson,
            status = 'active'
        }, function(success, insertId)
            if success then
                TriggerClientEvent('phone:client:marketplaceListingResult', source, {
                    success = true,
                    message = _L('marketplace_listing_created'),
                    listingId = insertId
                })
            else
                TriggerClientEvent('phone:client:marketplaceListingResult', source, {
                    success = false,
                    message = _L('marketplace_create_failed')
                })
            end
        end)
    end)
end)

-- Update marketplace listing
RegisterNetEvent('phone:server:updateMarketplaceListing', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber or not data or not data.id then
        TriggerClientEvent('phone:client:marketplaceListingResult', source, {
            success = false,
            message = _L('marketplace_invalid_request')
        })
        return
    end
    
    -- Verify ownership
    local query = 'SELECT seller_number FROM phone_marketplace_listings WHERE id = ?'
    Database.Query(query, {data.id}, function(result)
        if not result or #result == 0 then
            TriggerClientEvent('phone:client:marketplaceListingResult', source, {
                success = false,
                message = _L('marketplace_listing_not_found')
            })
            return
        end
        
        if result[1].seller_number ~= phoneNumber then
            TriggerClientEvent('phone:client:marketplaceListingResult', source, {
                success = false,
                message = _L('marketplace_not_owner')
            })
            return
        end
        
        -- Validate price if provided
        if data.price then
            local isValid, error = ValidateCurrency(data.price)
            if not isValid then
                TriggerClientEvent('phone:client:marketplaceListingResult', source, {
                    success = false,
                    message = error or _L('marketplace_invalid_price')
                })
                return
            end
        end
        
        -- Prepare update data
        local updateData = {}
        if data.title then updateData.title = data.title end
        if data.description then updateData.description = data.description end
        if data.price then updateData.price = data.price end
        if data.category then updateData.category = data.category end
        if data.photos and type(data.photos) == 'table' then
            updateData.photos_json = json.encode(data.photos)
        end
        
        -- Update listing
        Database.Update('phone_marketplace_listings', updateData, 'id = ?', {data.id}, function(success)
            if success then
                TriggerClientEvent('phone:client:marketplaceListingResult', source, {
                    success = true,
                    message = _L('marketplace_listing_updated')
                })
            else
                TriggerClientEvent('phone:client:marketplaceListingResult', source, {
                    success = false,
                    message = _L('marketplace_update_failed')
                })
            end
        end)
    end)
end)

-- Delete marketplace listing
RegisterNetEvent('phone:server:deleteMarketplaceListing', function(listingId)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber or not listingId then
        TriggerClientEvent('phone:client:marketplaceListingResult', source, {
            success = false,
            message = _L('marketplace_invalid_request')
        })
        return
    end
    
    -- Verify ownership
    local query = 'SELECT seller_number FROM phone_marketplace_listings WHERE id = ?'
    Database.Query(query, {listingId}, function(result)
        if not result or #result == 0 then
            TriggerClientEvent('phone:client:marketplaceListingResult', source, {
                success = false,
                message = _L('marketplace_listing_not_found')
            })
            return
        end
        
        if result[1].seller_number ~= phoneNumber then
            TriggerClientEvent('phone:client:marketplaceListingResult', source, {
                success = false,
                message = _L('marketplace_not_owner')
            })
            return
        end
        
        -- Update status to deleted instead of actually deleting
        Database.Update('phone_marketplace_listings', {status = 'deleted'}, 'id = ?', {listingId}, function(success)
            if success then
                TriggerClientEvent('phone:client:marketplaceListingResult', source, {
                    success = true,
                    message = _L('marketplace_listing_deleted')
                })
            else
                TriggerClientEvent('phone:client:marketplaceListingResult', source, {
                    success = false,
                    message = _L('marketplace_delete_failed')
                })
            end
        end)
    end)
end)

-- Mark listing as sold
RegisterNetEvent('phone:server:markListingSold', function(listingId)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber or not listingId then
        TriggerClientEvent('phone:client:marketplaceListingResult', source, {
            success = false,
            message = _L('marketplace_invalid_request')
        })
        return
    end
    
    -- Verify ownership
    local query = 'SELECT seller_number FROM phone_marketplace_listings WHERE id = ?'
    Database.Query(query, {listingId}, function(result)
        if not result or #result == 0 then
            TriggerClientEvent('phone:client:marketplaceListingResult', source, {
                success = false,
                message = _L('marketplace_listing_not_found')
            })
            return
        end
        
        if result[1].seller_number ~= phoneNumber then
            TriggerClientEvent('phone:client:marketplaceListingResult', source, {
                success = false,
                message = _L('marketplace_not_owner')
            })
            return
        end
        
        -- Update status to sold
        Database.Update('phone_marketplace_listings', {status = 'sold'}, 'id = ?', {listingId}, function(success)
            if success then
                TriggerClientEvent('phone:client:marketplaceListingResult', source, {
                    success = true,
                    message = _L('marketplace_listing_sold')
                })
            else
                TriggerClientEvent('phone:client:marketplaceListingResult', source, {
                    success = false,
                    message = _L('marketplace_sold_failed')
                })
            end
        end)
    end)
end)

-- Get marketplace statistics
RegisterNetEvent('phone:server:getMarketplaceStats', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    -- Query statistics
    local query = [[
        SELECT 
            category,
            COUNT(*) as total_listings,
            SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_listings,
            SUM(CASE WHEN status = 'sold' THEN 1 ELSE 0 END) as sold_listings,
            AVG(CASE WHEN status = 'sold' THEN price ELSE NULL END) as avg_sold_price
        FROM phone_marketplace_listings
        WHERE status IN ('active', 'sold')
        GROUP BY category
        ORDER BY total_listings DESC
    ]]
    
    Database.Query(query, {}, function(stats)
        if stats then
            TriggerClientEvent('phone:client:receiveMarketplaceStats', source, {
                success = true,
                stats = stats
            })
        else
            TriggerClientEvent('phone:client:receiveMarketplaceStats', source, {
                success = false,
                message = _L('marketplace_stats_failed'),
                stats = {}
            })
        end
    end)
end)