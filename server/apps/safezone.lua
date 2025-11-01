-- SafeZone App Server Logic
-- Handles emergency alerts, contacts management, and police integration

-- Get SafeZone data for player
RegisterNetEvent('phone:server:getSafeZoneData', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveSafeZoneData', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Get emergency contacts
    local contacts = MySQL.query.await([[
        SELECT 
            id,
            name,
            relation,
            phone_number as number,
            UNIX_TIMESTAMP(created_at) * 1000 as createdAt
        FROM phone_safezone_contacts
        WHERE owner_number = ?
        ORDER BY name ASC
    ]], {
        phoneNumber
    })
    
    -- Get user settings
    local settings = MySQL.query.await([[
        SELECT 
            auto_alert,
            share_location,
            police_alert,
            silent_mode
        FROM phone_safezone_settings
        WHERE phone_number = ?
    ]], {
        phoneNumber
    })
    
    local userSettings = {
        autoAlert = true,
        shareLocation = true,
        policeAlert = true,
        silentMode = false
    }
    
    if settings and #settings > 0 then
        userSettings = {
            autoAlert = settings[1].auto_alert == 1,
            shareLocation = settings[1].share_location == 1,
            policeAlert = settings[1].police_alert == 1,
            silentMode = settings[1].silent_mode == 1
        }
    end
    
    TriggerClientEvent('phone:client:receiveSafeZoneData', source, {
        success = true,
        contacts = contacts or {},
        settings = userSettings
    })
end)

-- Save emergency contact
RegisterNetEvent('phone:server:saveSafeZoneContact', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:saveSafeZoneContactResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    local contact = data.contact
    local isEdit = data.isEdit
    
    -- Validation
    if not contact.name or not contact.relation or not contact.number then
        TriggerClientEvent('phone:client:saveSafeZoneContactResult', source, {
            success = false,
            message = 'All fields are required'
        })
        return
    end
    
    if isEdit and contact.id then
        -- Update existing contact
        local affectedRows = MySQL.update.await([[
            UPDATE phone_safezone_contacts 
            SET name = ?, relation = ?, phone_number = ?
            WHERE id = ? AND owner_number = ?
        ]], {
            contact.name,
            contact.relation,
            contact.number,
            contact.id,
            phoneNumber
        })
        
        if affectedRows > 0 then
            TriggerClientEvent('phone:client:saveSafeZoneContactResult', source, {
                success = true,
                message = 'Contact updated successfully'
            })
        else
            TriggerClientEvent('phone:client:saveSafeZoneContactResult', source, {
                success = false,
                message = 'Failed to update contact'
            })
        end
    else
        -- Insert new contact
        local contactId = MySQL.insert.await([[
            INSERT INTO phone_safezone_contacts (owner_number, name, relation, phone_number)
            VALUES (?, ?, ?, ?)
        ]], {
            phoneNumber,
            contact.name,
            contact.relation,
            contact.number
        })
        
        if contactId then
            TriggerClientEvent('phone:client:saveSafeZoneContactResult', source, {
                success = true,
                message = 'Contact added successfully',
                contact = {
                    id = contactId,
                    name = contact.name,
                    relation = contact.relation,
                    number = contact.number,
                    createdAt = os.time() * 1000
                }
            })
        else
            TriggerClientEvent('phone:client:saveSafeZoneContactResult', source, {
                success = false,
                message = 'Failed to add contact'
            })
        end
    end
end)

-- Delete emergency contact
RegisterNetEvent('phone:server:deleteSafeZoneContact', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    local contactId = data.contactId
    
    -- Delete contact (only if owned by player)
    local affectedRows = MySQL.update.await([[
        DELETE FROM phone_safezone_contacts 
        WHERE id = ? AND owner_number = ?
    ]], {
        contactId,
        phoneNumber
    })
    
    if affectedRows > 0 then
        TriggerClientEvent('phone:client:deleteSafeZoneContactResult', source, {
            success = true,
            message = 'Contact deleted successfully',
            contactId = contactId
        })
    else
        TriggerClientEvent('phone:client:deleteSafeZoneContactResult', source, {
            success = false,
            message = 'Contact not found or access denied'
        })
    end
end)

-- Activate emergency alert
RegisterNetEvent('phone:server:activateEmergency', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    local contacts = data.contacts or {}
    local settings = data.settings or {}
    local playerName = Framework:GetPlayerName(source)
    local coords = GetEntityCoords(GetPlayerPed(source))
    
    -- Log emergency activation
    MySQL.insert.await([[
        INSERT INTO phone_safezone_emergencies 
        (phone_number, player_name, location_x, location_y, location_z, contacts_notified, police_notified)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        phoneNumber,
        playerName,
        coords.x,
        coords.y,
        coords.z,
        #contacts,
        settings.policeAlert and 1 or 0
    })
    
    -- Notify emergency contacts
    if settings.autoAlert and #contacts > 0 then
        for _, contact in ipairs(contacts) do
            -- Find contact's player if online
            local contactPlayer = MySQL.query.await([[
                SELECT identifier FROM phone_players WHERE phone_number = ?
            ]], {
                contact.number
            })
            
            if contactPlayer and #contactPlayer > 0 then
                local contactIdentifier = contactPlayer[1].identifier
                local contactSource = nil
                
                -- Find online player
                for _, playerId in ipairs(GetPlayers()) do
                    local playerIdentifier = Framework:GetIdentifier(tonumber(playerId))
                    if playerIdentifier == contactIdentifier then
                        contactSource = tonumber(playerId)
                        break
                    end
                end
                
                if contactSource then
                    -- Send emergency notification to contact
                    TriggerClientEvent('phone:client:receiveEmergencyAlert', contactSource, {
                        from = phoneNumber,
                        fromName = playerName,
                        message = string.format('%s has activated an emergency alert!', playerName),
                        location = settings.shareLocation and coords or nil,
                        timestamp = os.time() * 1000
                    })
                end
            end
        end
    end
    
    -- Alert police if enabled
    if settings.policeAlert then
        -- Get all online police officers
        local policeJobs = Config.SafeZoneApp.policeJobs or {'police', 'sheriff', 'state'}
        
        for _, playerId in ipairs(GetPlayers()) do
            local playerSource = tonumber(playerId)
            local playerJob = Framework:GetPlayerJob(playerSource)
            
            if playerJob and table.contains(policeJobs, playerJob.name) then
                TriggerClientEvent('phone:client:receivePoliceAlert', playerSource, {
                    caller = phoneNumber,
                    callerName = playerName,
                    location = coords,
                    message = 'Emergency alert activated - immediate assistance required',
                    timestamp = os.time() * 1000,
                    alertId = phoneNumber .. '_' .. os.time()
                })
            end
        end
        
        -- Create police dispatch
        if Config.DispatchSystem then
            TriggerEvent('dispatch:addCall', {
                job = policeJobs,
                callLocation = coords,
                callCode = '911',
                message = 'Emergency Alert - SafeZone App',
                flashes = true,
                image = nil,
                blip = {
                    sprite = 161,
                    scale = 1.2,
                    colour = 1,
                    flashes = true,
                    text = 'Emergency Alert'
                }
            })
        end
    end
    
    -- Send confirmation to caller
    TriggerClientEvent('phone:client:emergencyActivated', source, {
        success = true,
        message = 'Emergency alert sent successfully',
        contactsNotified = #contacts,
        policeNotified = settings.policeAlert
    })
    
    if Config.DebugMode then
        print(string.format('[SafeZone] Emergency activated by %s (%s) at %s', playerName, phoneNumber, coords))
    end
end)

-- Cancel emergency alert
RegisterNetEvent('phone:server:cancelEmergency', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    local playerName = Framework:GetPlayerName(source)
    
    -- Update emergency log
    MySQL.update.await([[
        UPDATE phone_safezone_emergencies 
        SET cancelled = 1, cancelled_at = NOW()
        WHERE phone_number = ? AND cancelled = 0
        ORDER BY created_at DESC
        LIMIT 1
    ]], {
        phoneNumber
    })
    
    -- Notify contacts about cancellation
    local contacts = MySQL.query.await([[
        SELECT phone_number as number FROM phone_safezone_contacts
        WHERE owner_number = ?
    ]], {
        phoneNumber
    })
    
    for _, contact in ipairs(contacts or {}) do
        local contactPlayer = MySQL.query.await([[
            SELECT identifier FROM phone_players WHERE phone_number = ?
        ]], {
            contact.number
        })
        
        if contactPlayer and #contactPlayer > 0 then
            local contactIdentifier = contactPlayer[1].identifier
            local contactSource = nil
            
            for _, playerId in ipairs(GetPlayers()) do
                local playerIdentifier = Framework:GetIdentifier(tonumber(playerId))
                if playerIdentifier == contactIdentifier then
                    contactSource = tonumber(playerId)
                    break
                end
            end
            
            if contactSource then
                TriggerClientEvent('phone:client:receiveEmergencyCancellation', contactSource, {
                    from = phoneNumber,
                    fromName = playerName,
                    message = string.format('%s has cancelled their emergency alert', playerName),
                    timestamp = os.time() * 1000
                })
            end
        end
    end
    
    TriggerClientEvent('phone:client:emergencyCancelled', source, {
        success = true,
        message = 'Emergency alert cancelled'
    })
end)

-- Call emergency contact
RegisterNetEvent('phone:server:callSafeZoneContact', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local contact = data.contact
    
    -- Trigger phone call
    TriggerEvent('phone:server:startCall', {
        source = source,
        targetNumber = contact.number,
        isEmergency = true
    })
    
    TriggerClientEvent('phone:client:callContactResult', source, {
        success = true,
        message = 'Calling ' .. contact.name
    })
end)

-- Dial emergency number
RegisterNetEvent('phone:server:dialEmergencyNumber', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local number = data.number
    local phoneNumber = Framework:GetPhoneNumber(source)
    local playerName = Framework:GetPlayerName(source)
    local coords = GetEntityCoords(GetPlayerPed(source))
    
    -- Log emergency call
    MySQL.insert.await([[
        INSERT INTO phone_safezone_calls 
        (caller_number, caller_name, emergency_number, location_x, location_y, location_z)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        phoneNumber,
        playerName,
        number.number,
        coords.x,
        coords.y,
        coords.z
    })
    
    -- Handle different emergency numbers
    if number.number == '911' then
        -- Police/Fire/Medical emergency
        local policeJobs = Config.SafeZoneApp.policeJobs or {'police', 'sheriff', 'state'}
        local emsJobs = Config.SafeZoneApp.emsJobs or {'ambulance', 'ems'}
        local fireJobs = Config.SafeZoneApp.fireJobs or {'fire'}
        
        local allEmergencyJobs = {}
        for _, job in ipairs(policeJobs) do table.insert(allEmergencyJobs, job) end
        for _, job in ipairs(emsJobs) do table.insert(allEmergencyJobs, job) end
        for _, job in ipairs(fireJobs) do table.insert(allEmergencyJobs, job) end
        
        -- Notify emergency services
        for _, playerId in ipairs(GetPlayers()) do
            local playerSource = tonumber(playerId)
            local playerJob = Framework:GetPlayerJob(playerSource)
            
            if playerJob and table.contains(allEmergencyJobs, playerJob.name) then
                TriggerClientEvent('phone:client:receive911Call', playerSource, {
                    caller = phoneNumber,
                    callerName = playerName,
                    location = coords,
                    service = number.name,
                    timestamp = os.time() * 1000
                })
            end
        end
        
        -- Create dispatch call
        if Config.DispatchSystem then
            TriggerEvent('dispatch:addCall', {
                job = allEmergencyJobs,
                callLocation = coords,
                callCode = '911',
                message = number.name .. ' - Emergency Call',
                flashes = true,
                image = nil,
                blip = {
                    sprite = number.name == 'Police' and 161 or (number.name == 'Fire Department' and 436 or 153),
                    scale = 1.2,
                    colour = number.name == 'Police' and 3 or (number.name == 'Fire Department' and 1 or 2),
                    flashes = true,
                    text = number.name .. ' Emergency'
                }
            })
        end
    end
    
    TriggerClientEvent('phone:client:dialEmergencyResult', source, {
        success = true,
        message = 'Emergency call placed to ' .. number.name,
        number = number
    })
end)

-- Update SafeZone settings
RegisterNetEvent('phone:server:updateSafeZoneSettings', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:updateSafeZoneSettingsResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    local settings = data.settings
    
    -- Update or insert settings
    MySQL.query.await([[
        INSERT INTO phone_safezone_settings 
        (phone_number, auto_alert, share_location, police_alert, silent_mode)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        auto_alert = VALUES(auto_alert),
        share_location = VALUES(share_location),
        police_alert = VALUES(police_alert),
        silent_mode = VALUES(silent_mode)
    ]], {
        phoneNumber,
        settings.autoAlert and 1 or 0,
        settings.shareLocation and 1 or 0,
        settings.policeAlert and 1 or 0,
        settings.silentMode and 1 or 0
    })
    
    TriggerClientEvent('phone:client:updateSafeZoneSettingsResult', source, {
        success = true,
        message = 'Settings updated successfully'
    })
end)

-- Test emergency alert
RegisterNetEvent('phone:server:testEmergencyAlert', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    local playerName = Framework:GetPlayerName(source)
    local settings = data.settings or {}
    
    -- Send test notification to player
    TriggerClientEvent('phone:client:receiveEmergencyAlert', source, {
        from = phoneNumber,
        fromName = playerName .. ' (Test)',
        message = 'This is a test emergency alert from SafeZone app',
        location = settings.shareLocation and GetEntityCoords(GetPlayerPed(source)) or nil,
        timestamp = os.time() * 1000,
        isTest = true
    })
    
    TriggerClientEvent('phone:client:testAlertResult', source, {
        success = true,
        message = 'Test alert sent successfully'
    })
end)

-- Utility function to check if table contains value
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Emergency cleanup task (remove old emergency records)
CreateThread(function()
    while true do
        Wait(3600000) -- Run every hour
        
        -- Delete emergency records older than 30 days
        MySQL.update.await([[
            DELETE FROM phone_safezone_emergencies 
            WHERE created_at < DATE_SUB(NOW(), INTERVAL 30 DAY)
        ]])
        
        -- Delete emergency call records older than 30 days
        MySQL.update.await([[
            DELETE FROM phone_safezone_calls 
            WHERE created_at < DATE_SUB(NOW(), INTERVAL 30 DAY)
        ]])
    end
end)