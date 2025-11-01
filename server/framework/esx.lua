-- ESX Framework Adapter
-- Integrates with ESX Legacy and older versions

local ESX = {}
ESX.__index = ESX
ESX.Framework = nil

--- Initialize ESX framework
function ESX:new()
    local self = setmetatable({}, ESX)
    
    -- Try to get ESX shared object with error handling
    local success, result = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)
    
    if success and result then
        self.Framework = result
        print('[Phone] Initialized ESX framework adapter')
        return self
    end
    
    print('[Phone] ^1ERROR: Failed to load ESX framework^7')
    print('[Phone] ^3Make sure es_extended resource is started before lb-gphone^7')
    return nil
end

--- Get player object from source
function ESX:GetPlayer(source)
    if not source or source == 0 then return nil end
    if not self.Framework then return nil end
    
    return self.Framework.GetPlayerFromId(source)
end

--- Get unique identifier for player
function ESX:GetIdentifier(source)
    local xPlayer = self:GetPlayer(source)
    if not xPlayer then return nil end
    
    return xPlayer.identifier
end

--- Get player's phone number from database
function ESX:GetPhoneNumber(source)
    -- Phone numbers are stored in phone system database, not ESX
    -- This will be handled by the phone system's database layer
    return nil
end

--- Set player's phone number (handled by database layer)
function ESX:SetPhoneNumber(source, phoneNumber)
    -- Phone numbers are stored in phone system database, not ESX
    -- This will be handled by the phone system's database layer
    return true
end

--- Get player's money amount
function ESX:GetPlayerMoney(source, account)
    local xPlayer = self:GetPlayer(source)
    if not xPlayer then return 0 end
    
    account = account or Config.BankApp.defaultAccount or 'bank'
    
    if account == 'cash' or account == 'money' then
        return xPlayer.getMoney() or 0
    elseif account == 'bank' then
        return xPlayer.getAccount('bank').money or 0
    elseif account == 'black_money' then
        return xPlayer.getAccount('black_money').money or 0
    else
        -- Try to get custom account
        local accountData = xPlayer.getAccount(account)
        return accountData and accountData.money or 0
    end
end

--- Add money to player
function ESX:AddMoney(source, amount, account)
    local xPlayer = self:GetPlayer(source)
    if not xPlayer then return false end
    
    account = account or Config.BankApp.defaultAccount or 'bank'
    
    if account == 'cash' or account == 'money' then
        xPlayer.addMoney(amount)
    elseif account == 'bank' then
        xPlayer.addAccountMoney('bank', amount)
    elseif account == 'black_money' then
        xPlayer.addAccountMoney('black_money', amount)
    else
        -- Try to add to custom account
        xPlayer.addAccountMoney(account, amount)
    end
    
    return true
end

--- Remove money from player
function ESX:RemoveMoney(source, amount, account)
    local xPlayer = self:GetPlayer(source)
    if not xPlayer then return false end
    
    account = account or Config.BankApp.defaultAccount or 'bank'
    
    -- Check if player has enough money
    local currentMoney = self:GetPlayerMoney(source, account)
    if currentMoney < amount then
        return false
    end
    
    if account == 'cash' or account == 'money' then
        xPlayer.removeMoney(amount)
    elseif account == 'bank' then
        xPlayer.removeAccountMoney('bank', amount)
    elseif account == 'black_money' then
        xPlayer.removeAccountMoney('black_money', amount)
    else
        -- Try to remove from custom account
        xPlayer.removeAccountMoney(account, amount)
    end
    
    return true
end

--- Get player's job information
function ESX:GetJob(source)
    local xPlayer = self:GetPlayer(source)
    if not xPlayer or not xPlayer.job then
        return {
            name = 'unemployed',
            label = 'Unemployed',
            grade = 0,
            grade_name = 'None'
        }
    end
    
    return {
        name = xPlayer.job.name,
        label = xPlayer.job.label,
        grade = xPlayer.job.grade,
        grade_name = xPlayer.job.grade_label or xPlayer.job.grade_name
    }
end

--- Get player's name
function ESX:GetPlayerName(source)
    local xPlayer = self:GetPlayer(source)
    if not xPlayer then
        return GetPlayerName(source) or 'Unknown'
    end
    
    -- Try to get character name, fallback to player name
    return xPlayer.getName() or GetPlayerName(source) or 'Unknown'
end

--- Check if player exists
function ESX:PlayerExists(source)
    return self:GetPlayer(source) ~= nil
end

return ESX:new()
