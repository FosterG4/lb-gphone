-- Framework Adapter Interface
-- This file defines the interface that all framework implementations must follow

Framework = {}
Framework.__index = Framework

-- Initialize the framework adapter based on config
function Framework:Init()
    local frameworkType = Config.Framework or 'standalone'
    
    if frameworkType == 'esx' then
        return require('server.framework.esx')
    elseif frameworkType == 'qbcore' then
        return require('server.framework.qbcore')
    elseif frameworkType == 'qbox' then
        return require('server.framework.qbox')
    else
        return require('server.framework.standalone')
    end
end

-- Interface Methods (to be implemented by each framework)

--- Get player object from source
-- @param source number - Player server ID
-- @return table|nil - Player object or nil if not found
function Framework:GetPlayer(source)
    error("GetPlayer must be implemented by framework adapter")
end

--- Get unique identifier for player
-- @param source number - Player server ID
-- @return string|nil - Unique identifier or nil if not found
function Framework:GetIdentifier(source)
    error("GetIdentifier must be implemented by framework adapter")
end

--- Get player's phone number
-- @param source number - Player server ID
-- @return string|nil - Phone number or nil if not found
function Framework:GetPhoneNumber(source)
    error("GetPhoneNumber must be implemented by framework adapter")
end

--- Set player's phone number
-- @param source number - Player server ID
-- @param phoneNumber string - Phone number to set
-- @return boolean - Success status
function Framework:SetPhoneNumber(source, phoneNumber)
    error("SetPhoneNumber must be implemented by framework adapter")
end

--- Get player's money amount
-- @param source number - Player server ID
-- @param account string - Account type (optional, default: 'bank')
-- @return number - Money amount
function Framework:GetPlayerMoney(source, account)
    error("GetPlayerMoney must be implemented by framework adapter")
end

--- Add money to player
-- @param source number - Player server ID
-- @param amount number - Amount to add
-- @param account string - Account type (optional, default: 'bank')
-- @return boolean - Success status
function Framework:AddMoney(source, amount, account)
    error("AddMoney must be implemented by framework adapter")
end

--- Remove money from player
-- @param source number - Player server ID
-- @param amount number - Amount to remove
-- @param account string - Account type (optional, default: 'bank')
-- @return boolean - Success status
function Framework:RemoveMoney(source, amount, account)
    error("RemoveMoney must be implemented by framework adapter")
end

--- Get player's job information
-- @param source number - Player server ID
-- @return table|nil - Job data {name, label, grade, grade_name} or nil
function Framework:GetJob(source)
    error("GetJob must be implemented by framework adapter")
end

--- Get player's name
-- @param source number - Player server ID
-- @return string - Player name
function Framework:GetPlayerName(source)
    error("GetPlayerName must be implemented by framework adapter")
end

--- Check if player exists
-- @param source number - Player server ID
-- @return boolean - True if player exists
function Framework:PlayerExists(source)
    error("PlayerExists must be implemented by framework adapter")
end

return Framework
