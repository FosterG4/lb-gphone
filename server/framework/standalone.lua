-- Standalone Framework Adapter
-- Uses FiveM license identifiers and basic player data

local Standalone = {}
Standalone.__index = Standalone

-- Player data cache
local playerData = {}

--- Initialize standalone framework
function Standalone:new()
    local self = setmetatable({}, Standalone)
    print('[Phone] Initialized Standalone framework adapter')
    return self
end

--- Get player object from source
function Standalone:GetPlayer(source)
    if not source or source == 0 then return nil end
    
    local identifier = self:GetIdentifier(source)
    if not identifier then return nil end
    
    -- Return cached player data or create new entry
    if not playerData[identifier] then
        playerData[identifier] = {
            source = source,
            identifier = identifier,
            name = GetPlayerName(source),
            money = 0 -- Standalone doesn't track money by default
        }
    end
    
    return playerData[identifier]
end

--- Get unique identifier for player (FiveM license)
function Standalone:GetIdentifier(source)
    if not source or source == 0 then return nil end
    
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end
    
    for _, identifier in ipairs(identifiers) do
        if string.match(identifier, 'license:') then
            return identifier
        end
    end
    
    return nil
end

--- Get player's phone number from database
function Standalone:GetPhoneNumber(source)
    local identifier = self:GetIdentifier(source)
    if not identifier then return nil end
    
    -- Phone numbers are stored in database, not in framework
    -- This will be handled by the phone system's database layer
    return nil
end

--- Set player's phone number (handled by database layer)
function Standalone:SetPhoneNumber(source, phoneNumber)
    -- Phone numbers are stored in database, not in framework
    -- This will be handled by the phone system's database layer
    return true
end

--- Get player's money amount
function Standalone:GetPlayerMoney(source, account)
    local player = self:GetPlayer(source)
    if not player then return 0 end
    
    -- Standalone mode doesn't have built-in money system
    -- Return 0 or implement custom money tracking if needed
    return player.money or 0
end

--- Add money to player
function Standalone:AddMoney(source, amount, account)
    local player = self:GetPlayer(source)
    if not player then return false end
    
    -- Standalone mode doesn't have built-in money system
    -- This is a placeholder implementation
    player.money = (player.money or 0) + amount
    return true
end

--- Remove money from player
function Standalone:RemoveMoney(source, amount, account)
    local player = self:GetPlayer(source)
    if not player then return false end
    
    local currentMoney = player.money or 0
    if currentMoney < amount then
        return false
    end
    
    player.money = currentMoney - amount
    return true
end

--- Get player's job information
function Standalone:GetJob(source)
    -- Standalone mode doesn't have job system
    return {
        name = 'unemployed',
        label = 'Unemployed',
        grade = 0,
        grade_name = 'None'
    }
end

--- Get player's name
function Standalone:GetPlayerName(source)
    if not source or source == 0 then return 'Unknown' end
    return GetPlayerName(source) or 'Unknown'
end

--- Check if player exists
function Standalone:PlayerExists(source)
    if not source or source == 0 then return false end
    return GetPlayerName(source) ~= nil
end

--- Clean up player data on disconnect
function Standalone:OnPlayerDropped(source)
    local identifier = self:GetIdentifier(source)
    if identifier and playerData[identifier] then
        playerData[identifier] = nil
    end
end

return Standalone:new()
