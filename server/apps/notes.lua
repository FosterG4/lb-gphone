-- Notes App Server Handler
-- Handles note CRUD operations with auto-save functionality

local QBCore = nil
local ESX = nil

-- Initialize framework
if Config.Framework == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
elseif Config.Framework == 'qbox' then
    QBCore = exports.qbx_core
end

-- Helper function to get player phone number
function GetPlayerPhoneNumber(src)
    if Config.Framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            return Player.PlayerData.charinfo.phone
        end
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            local result = MySQL.query.await('SELECT phone_number FROM phone_players WHERE identifier = ?', {
                xPlayer.identifier
            })
            if result and result[1] then
                return result[1].phone_number
            end
        end
    elseif Config.Framework == 'qbox' then
        local Player = exports.qbx_core:GetPlayer(src)
        if Player then
            return Player.PlayerData.charinfo.phone
        end
    else
        -- Standalone
        local identifier = GetPlayerIdentifierByType(src, 'license')
        if identifier then
            local result = MySQL.query.await('SELECT phone_number FROM phone_players WHERE identifier = ?', {
                identifier
            })
            if result and result[1] then
                return result[1].phone_number
            end
        end
    end
    
    return nil
end

-- Validate note content
local function ValidateNote(title, content)
    -- Title validation (optional, max 200 chars)
    if title and #title > 200 then
        return false, 'Title too long (max 200 characters)'
    end
    
    -- Content validation (required, max 5000 chars)
    if not content then
        return false, 'Content is required'
    end
    
    if #content > 5000 then
        return false, 'Content too long (max 5000 characters)'
    end
    
    -- At least one of title or content must have non-whitespace content
    local titleTrimmed = title and title:match('^%s*(.-)%s*$') or ''
    local contentTrimmed = content:match('^%s*(.-)%s*$')
    
    if #titleTrimmed == 0 and #contentTrimmed == 0 then
        return false, 'Note cannot be empty'
    end
    
    return true, nil
end

-- Get all notes for a player
RegisterNetEvent('phone:server:getNotes', function()
    local src = source
    local phoneNumber = GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveNotes', src, {
            success = false,
            error = 'PLAYER_NOT_FOUND'
        })
        return
    end
    
    local result = MySQL.query.await([[
        SELECT * FROM phone_notes 
        WHERE owner_number = ? 
        ORDER BY updated_at DESC
    ]], {
        phoneNumber
    })
    
    TriggerClientEvent('phone:client:receiveNotes', src, {
        success = true,
        notes = result or {}
    })
end)

-- Save note (create or update)
RegisterNetEvent('phone:server:saveNote', function(data)
    local src = source
    local phoneNumber = GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:noteSaved', src, {
            success = false,
            error = 'PLAYER_NOT_FOUND'
        })
        return
    end
    
    -- Validate input
    local valid, error = ValidateNote(data.title, data.content)
    if not valid then
        TriggerClientEvent('phone:client:noteSaved', src, {
            success = false,
            error = error
        })
        return
    end
    
    local title = data.title or ''
    local content = data.content
    
    if data.noteId then
        -- Update existing note
        -- Verify ownership
        local note = MySQL.query.await('SELECT * FROM phone_notes WHERE id = ? AND owner_number = ?', {
            data.noteId,
            phoneNumber
        })
        
        if not note or not note[1] then
            TriggerClientEvent('phone:client:noteSaved', src, {
                success = false,
                error = 'NOT_OWNER'
            })
            return
        end
        
        -- Update note
        local success = MySQL.update.await([[
            UPDATE phone_notes 
            SET title = ?, content = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        ]], {
            title,
            content,
            data.noteId
        })
        
        if success then
            local updatedNote = MySQL.query.await('SELECT * FROM phone_notes WHERE id = ?', { data.noteId })
            
            TriggerClientEvent('phone:client:noteSaved', src, {
                success = true,
                note = updatedNote[1]
            })
        else
            TriggerClientEvent('phone:client:noteSaved', src, {
                success = false,
                error = 'DATABASE_ERROR'
            })
        end
    else
        -- Create new note
        -- Check note limit (optional)
        local count = MySQL.scalar.await('SELECT COUNT(*) FROM phone_notes WHERE owner_number = ?', {
            phoneNumber
        })
        
        if count >= (Config.MaxNotes or 100) then
            TriggerClientEvent('phone:client:noteSaved', src, {
                success = false,
                error = 'NOTE_LIMIT_REACHED'
            })
            return
        end
        
        -- Insert note
        local noteId = MySQL.insert.await([[
            INSERT INTO phone_notes (owner_number, title, content, created_at, updated_at)
            VALUES (?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        ]], {
            phoneNumber,
            title,
            content
        })
        
        if noteId then
            local newNote = MySQL.query.await('SELECT * FROM phone_notes WHERE id = ?', { noteId })
            
            TriggerClientEvent('phone:client:noteSaved', src, {
                success = true,
                note = newNote[1]
            })
        else
            TriggerClientEvent('phone:client:noteSaved', src, {
                success = false,
                error = 'DATABASE_ERROR'
            })
        end
    end
end)

-- Delete note
RegisterNetEvent('phone:server:deleteNote', function(data)
    local src = source
    local phoneNumber = GetPlayerPhoneNumber(src)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:noteDeleted', src, {
            success = false,
            error = 'PLAYER_NOT_FOUND'
        })
        return
    end
    
    if not data.noteId then
        TriggerClientEvent('phone:client:noteDeleted', src, {
            success = false,
            error = 'INVALID_INPUT'
        })
        return
    end
    
    -- Verify ownership
    local note = MySQL.query.await('SELECT * FROM phone_notes WHERE id = ? AND owner_number = ?', {
        data.noteId,
        phoneNumber
    })
    
    if not note or not note[1] then
        TriggerClientEvent('phone:client:noteDeleted', src, {
            success = false,
            error = 'NOT_OWNER'
        })
        return
    end
    
    -- Delete note
    local success = MySQL.execute.await('DELETE FROM phone_notes WHERE id = ?', {
        data.noteId
    })
    
    TriggerClientEvent('phone:client:noteDeleted', src, {
        success = success
    })
end)

print('^2[Phone] Notes app loaded successfully^7')
