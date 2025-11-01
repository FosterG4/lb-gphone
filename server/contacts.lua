-- Server Contacts Module
-- Handles all contact-related database operations and validation

local Contacts = {}

-- Validate contact data
local function ValidateContactData(name, number)
    if not name or name == '' then
        return false, 'Contact name is required'
    end
    
    if not number or number == '' then
        return false, 'Phone number is required'
    end
    
    -- Validate name length
    if string.len(name) > 100 then
        return false, 'Contact name is too long (max 100 characters)'
    end
    
    -- Validate phone number format
    local isValid, error = ValidatePhoneNumber(number)
    if not isValid then
        return false, error
    end
    
    return true
end

-- Get all contacts for a player
function Contacts.GetContacts(phoneNumber, cb)
    if not phoneNumber then
        if cb then cb(false, 'Invalid phone number', nil) end
        return
    end
    
    Database.FetchAll('phone_contacts', 'owner_number = ?', {phoneNumber}, function(contacts)
        if contacts then
            if cb then cb(true, nil, contacts) end
        else
            if cb then cb(false, 'Failed to fetch contacts', nil) end
        end
    end)
end

-- Add new contact
function Contacts.AddContact(phoneNumber, contactName, contactNumber, cb)
    -- Validate input
    local isValid, error = ValidateContactData(contactName, contactNumber)
    if not isValid then
        if cb then cb(false, error, nil) end
        return
    end
    
    -- Check if contact already exists
    local query = 'SELECT * FROM phone_contacts WHERE owner_number = ? AND contact_number = ?'
    Database.Query(query, {phoneNumber, contactNumber}, function(existing)
        if existing and #existing > 0 then
            if cb then cb(false, 'Contact already exists', nil) end
            return
        end
        
        -- Insert new contact
        Database.Insert('phone_contacts', {
            owner_number = phoneNumber,
            contact_name = contactName,
            contact_number = contactNumber
        }, function(success, insertId)
            if success then
                -- Fetch the newly created contact
                Database.FetchOne('phone_contacts', 'id = ?', {insertId}, function(contact)
                    if contact then
                        if cb then cb(true, nil, contact) end
                    else
                        if cb then cb(false, 'Failed to fetch new contact', nil) end
                    end
                end)
            else
                if cb then cb(false, 'Failed to add contact', nil) end
            end
        end)
    end)
end

-- Edit existing contact
function Contacts.EditContact(phoneNumber, contactId, contactName, contactNumber, cb)
    -- Validate input
    local isValid, error = ValidateContactData(contactName, contactNumber)
    if not isValid then
        if cb then cb(false, error, nil) end
        return
    end
    
    -- Verify contact ownership
    Database.FetchOne('phone_contacts', 'id = ? AND owner_number = ?', {contactId, phoneNumber}, function(contact)
        if not contact then
            if cb then cb(false, 'Contact not found or unauthorized', nil) end
            return
        end
        
        -- Check if new number conflicts with another contact
        local query = 'SELECT * FROM phone_contacts WHERE owner_number = ? AND contact_number = ? AND id != ?'
        Database.Query(query, {phoneNumber, contactNumber, contactId}, function(existing)
            if existing and #existing > 0 then
                if cb then cb(false, 'Another contact with this number already exists', nil) end
                return
            end
            
            -- Update contact
            Database.Update('phone_contacts', {
                contact_name = contactName,
                contact_number = contactNumber
            }, 'id = ?', {contactId}, function(success)
                if success then
                    -- Fetch updated contact
                    Database.FetchOne('phone_contacts', 'id = ?', {contactId}, function(updatedContact)
                        if updatedContact then
                            if cb then cb(true, nil, updatedContact) end
                        else
                            if cb then cb(false, 'Failed to fetch updated contact', nil) end
                        end
                    end)
                else
                    if cb then cb(false, 'Failed to update contact', nil) end
                end
            end)
        end)
    end)
end

-- Delete contact
function Contacts.DeleteContact(phoneNumber, contactId, cb)
    -- Verify contact ownership
    Database.FetchOne('phone_contacts', 'id = ? AND owner_number = ?', {contactId, phoneNumber}, function(contact)
        if not contact then
            if cb then cb(false, 'Contact not found or unauthorized') end
            return
        end
        
        -- Delete contact
        Database.Delete('phone_contacts', 'id = ?', {contactId}, function(success)
            if success then
                if cb then cb(true, nil) end
            else
                if cb then cb(false, 'Failed to delete contact') end
            end
        end)
    end)
end

-- Get contact by phone number
function Contacts.GetContactByNumber(phoneNumber, contactNumber, cb)
    local query = 'SELECT * FROM phone_contacts WHERE owner_number = ? AND contact_number = ?'
    Database.Query(query, {phoneNumber, contactNumber}, function(contacts)
        if contacts and #contacts > 0 then
            if cb then cb(true, nil, contacts[1]) end
        else
            if cb then cb(false, 'Contact not found', nil) end
        end
    end)
end

-- Search contacts
function Contacts.SearchContacts(phoneNumber, searchQuery, cb)
    local query = [[
        SELECT * FROM phone_contacts 
        WHERE owner_number = ? 
        AND (contact_name LIKE ? OR contact_number LIKE ?)
        ORDER BY contact_name ASC
    ]]
    
    local searchPattern = '%' .. searchQuery .. '%'
    Database.Query(query, {phoneNumber, searchPattern, searchPattern}, function(contacts)
        if contacts then
            if cb then cb(true, nil, contacts) end
        else
            if cb then cb(false, 'Failed to search contacts', nil) end
        end
    end)
end

-- Event Handlers

-- Get contacts
RegisterNetEvent('phone:server:getContacts', function()
    local source = source
    
    if not _G.PhoneSystemReady then
        return
    end
    
    local phoneNumber = GetCachedPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:notification', source, {
            type = 'error',
            message = 'Phone number not found'
        })
        return
    end
    
    Contacts.GetContacts(phoneNumber, function(success, error, contacts)
        if success then
            TriggerClientEvent('phone:client:receiveContacts', source, contacts)
        else
            TriggerClientEvent('phone:client:notification', source, {
                type = 'error',
                message = error or 'Failed to fetch contacts'
            })
        end
    end)
end)

-- Add contact
RegisterNetEvent('phone:server:addContact', function(data)
    local src = source
    
    -- Check rate limit
    local rateLimitOk, rateLimitError = CheckContactRateLimit(src)
    if not rateLimitOk then
        TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(rateLimitError))
        return
    end
    
    local phoneNumber = GetCachedPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(ERROR_CODES.PLAYER_NOT_FOUND))
        return
    end
    
    -- Validate input
    if not data or not data.name or not data.number then
        TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(ERROR_CODES.INVALID_INPUT, 'Name and number are required'))
        return
    end
    
    local contactName = SanitizeInput(data.name)
    local contactNumber = SanitizeInput(data.number)
    
    -- Validate contact name
    local nameValid, nameError, nameMsg = ValidateContactName(contactName)
    if not nameValid then
        TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(nameError, nameMsg))
        return
    end
    
    -- Validate phone number
    local phoneValid, phoneError, phoneMsg = ValidatePhoneNumber(contactNumber)
    if not phoneValid then
        TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(phoneError, phoneMsg))
        return
    end
    
    TryCatch(function()
        Contacts.AddContact(phoneNumber, contactName, contactNumber, function(success, error, contact)
            if success then
                TriggerClientEvent('phone:client:contactOperationResult', src, SuccessResponse({
                    operation = 'add',
                    contact = contact
                }))
            else
                TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(ERROR_CODES.OPERATION_FAILED, error))
            end
        end)
    end, function(err)
        TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(ERROR_CODES.OPERATION_FAILED, 'Failed to add contact'))
    end)
end)

-- Edit contact
RegisterNetEvent('phone:server:editContact', function(data)
    local src = source
    
    -- Check rate limit
    local rateLimitOk, rateLimitError = CheckContactRateLimit(src)
    if not rateLimitOk then
        TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(rateLimitError))
        return
    end
    
    local phoneNumber = GetCachedPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(ERROR_CODES.PLAYER_NOT_FOUND))
        return
    end
    
    -- Validate input
    if not data or not data.id or not data.name or not data.number then
        TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(ERROR_CODES.INVALID_INPUT, 'ID, name and number are required'))
        return
    end
    
    local contactName = SanitizeInput(data.name)
    local contactNumber = SanitizeInput(data.number)
    
    -- Validate contact name
    local nameValid, nameError, nameMsg = ValidateContactName(contactName)
    if not nameValid then
        TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(nameError, nameMsg))
        return
    end
    
    -- Validate phone number
    local phoneValid, phoneError, phoneMsg = ValidatePhoneNumber(contactNumber)
    if not phoneValid then
        TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(phoneError, phoneMsg))
        return
    end
    
    -- Verify contact ownership
    VerifyContactOwnership(src, data.id, function(authorized, authError, authMsg)
        if not authorized then
            TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(authError, authMsg))
            return
        end
        
        TryCatch(function()
            Contacts.EditContact(phoneNumber, data.id, contactName, contactNumber, function(success, error, contact)
                if success then
                    TriggerClientEvent('phone:client:contactOperationResult', src, SuccessResponse({
                        operation = 'edit',
                        contact = contact
                    }))
                else
                    TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(ERROR_CODES.OPERATION_FAILED, error))
                end
            end)
        end, function(err)
            TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(ERROR_CODES.OPERATION_FAILED, 'Failed to edit contact'))
        end)
    end)
end)

-- Delete contact
RegisterNetEvent('phone:server:deleteContact', function(data)
    local src = source
    
    -- Check rate limit
    local rateLimitOk, rateLimitError = CheckContactRateLimit(src)
    if not rateLimitOk then
        TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(rateLimitError))
        return
    end
    
    local phoneNumber = GetCachedPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(ERROR_CODES.PLAYER_NOT_FOUND))
        return
    end
    
    -- Validate input
    if not data or not data.id then
        TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(ERROR_CODES.INVALID_INPUT, 'Contact ID is required'))
        return
    end
    
    -- Verify contact ownership
    VerifyContactOwnership(src, data.id, function(authorized, authError, authMsg)
        if not authorized then
            TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(authError, authMsg))
            return
        end
        
        TryCatch(function()
            Contacts.DeleteContact(phoneNumber, data.id, function(success, error)
                if success then
                    TriggerClientEvent('phone:client:contactOperationResult', src, SuccessResponse({
                        operation = 'delete',
                        contactId = data.id
                    }))
                else
                    TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(ERROR_CODES.OPERATION_FAILED, error))
                end
            end)
        end, function(err)
            TriggerClientEvent('phone:client:contactOperationResult', src, ErrorResponse(ERROR_CODES.OPERATION_FAILED, 'Failed to delete contact'))
        end)
    end)
end)

return Contacts
