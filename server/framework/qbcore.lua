-- QBCore Framework Adapter
-- Integrates with QBCore framework

local QBCore = {}
QBCore.__index = QBCore
QBCore.Framework = nil

--- Initialize QBCore framework
function QBCore:new()
    local self = setmetatable({}, QBCore)
    
    -- Try to get QBCore shared object
    self.Framework = exports['qb-core']:GetCoreObject()
    
    if not self.Framework then
        print('[Phone] ^1ERROR: Failed to load QBCore framework^7')
        return nil
    end
    
    print('[Phone] Initialized QBCore framework adapter')
    return self
end

--- Get player object from source
function QBCore:GetPlayer(source)
    if not source or source == 0 then return nil end
    if not self.Framework then return nil end
    
    return self.Framework.Functions.GetPlayer(source)
end

--- Get unique identifier for player
function QBCore:GetIdentifier(source)
    local Player = self:GetPlayer(source)
    if not Player then return nil end
    
    return Player.PlayerData.citizenid
end

--- Get player's phone number from database
function QBCore:GetPhoneNumber(source)
    local Player = self:GetPlayer(source)
    if not Player then return nil end
    
    -- QBCore stores phone number in PlayerData.charinfo
    if Player.PlayerData.charinfo and Player.PlayerData.charinfo.phone then
        return Player.PlayerData.charinfo.phone
    end
    
    return nil
end

--- Set player's phone number
function QBCore:SetPhoneNumber(source, phoneNumber)
    local Player = self:GetPlayer(source)
    if not Player then return false end
    
    -- Update phone number in QBCore player data
    if Player.PlayerData.charinfo then
        Player.PlayerData.charinfo.phone = phoneNumber
        Player.Functions.SetPlayerData('charinfo', Player.PlayerData.charinfo)
        return true
    end
    
    return false
end

--- Get player's money amount
function QBCore:GetPlayerMoney(source, account)
    local Player = self:GetPlayer(source)
    if not Player then return 0 end
    
    account = account or Config.BankApp.defaultAccount or 'bank'
    
    if account == 'cash' or account == 'money' then
        return Player.PlayerData.money.cash or 0
    elseif account == 'bank' then
        return Player.PlayerData.money.bank or 0
    elseif account == 'crypto' then
        return Player.PlayerData.money.crypto or 0
    else
        -- Try to get custom money type
        if Player.PlayerData.money[account] then
            return Player.PlayerData.money[account]
        end
        return 0
    end
end

--- Add money to player
function QBCore:AddMoney(source, amount, account)
    local Player = self:GetPlayer(source)
    if not Player then return false end
    
    account = account or Config.BankApp.defaultAccount or 'bank'
    
    if account == 'cash' or account == 'money' then
        Player.Functions.AddMoney('cash', amount)
    elseif account == 'bank' then
        Player.Functions.AddMoney('bank', amount)
    elseif account == 'crypto' then
        Player.Functions.AddMoney('crypto', amount)
    else
        -- Try to add custom money type
        Player.Functions.AddMoney(account, amount)
    end
    
    return true
end

--- Remove money from player
function QBCore:RemoveMoney(source, amount, account)
    local Player = self:GetPlayer(source)
    if not Player then return false end
    
    account = account or Config.BankApp.defaultAccount or 'bank'
    
    -- Check if player has enough money
    local currentMoney = self:GetPlayerMoney(source, account)
    if currentMoney < amount then
        return false
    end
    
    if account == 'cash' or account == 'money' then
        Player.Functions.RemoveMoney('cash', amount)
    elseif account == 'bank' then
        Player.Functions.RemoveMoney('bank', amount)
    elseif account == 'crypto' then
        Player.Functions.RemoveMoney('crypto', amount)
    else
        -- Try to remove custom money type
        Player.Functions.RemoveMoney(account, amount)
    end
    
    return true
end

--- Get player's job information
function QBCore:GetJob(source)
    local Player = self:GetPlayer(source)
    if not Player or not Player.PlayerData.job then
        return {
            name = 'unemployed',
            label = 'Unemployed',
            grade = 0,
            grade_name = 'None'
        }
    end
    
    return {
        name = Player.PlayerData.job.name,
        label = Player.PlayerData.job.label,
        grade = Player.PlayerData.job.grade.level,
        grade_name = Player.PlayerData.job.grade.name
    }
end

--- Get player's name
function QBCore:GetPlayerName(source)
    local Player = self:GetPlayer(source)
    if not Player then
        return GetPlayerName(source) or 'Unknown'
    end
    
    -- Get character name from charinfo
    if Player.PlayerData.charinfo then
        local firstname = Player.PlayerData.charinfo.firstname or ''
        local lastname = Player.PlayerData.charinfo.lastname or ''
        return firstname .. ' ' .. lastname
    end
    
    return GetPlayerName(source) or 'Unknown'
end

--- Check if player exists
function QBCore:PlayerExists(source)
    return self:GetPlayer(source) ~= nil
end

return QBCore:new()
