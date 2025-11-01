-- Qbox Framework Adapter
-- Integrates with Qbox framework (QBCore fork)

local Qbox = {}
Qbox.__index = Qbox
Qbox.Framework = nil

-- Wait function for retry logic
local function Wait(ms)
    local start = os.clock()
    while (os.clock() - start) * 1000 < ms do
        -- Busy wait
    end
end

--- Initialize Qbox framework
function Qbox:new()
    local self = setmetatable({}, Qbox)
    
    -- Check if qbx_core resource is started
    if GetResourceState('qbx_core') ~= 'started' then
        print('[Phone] ^1ERROR: qbx_core resource is not started^7')
        print('[Phone] ^3Make sure qbx_core is loaded before lb-gphone in server.cfg^7')
        return nil
    end
    
    -- Qbox doesn't use exports like QBCore
    -- Instead, it uses a global QBX object or direct exports
    -- Try multiple methods to get Qbox with retries for timing issues
    
    local maxRetries = 5
    local retryDelay = 100 -- milliseconds
    
    for attempt = 1, maxRetries do
        -- Method 1: Try global QBX (most common in newer Qbox)
        local success, result = pcall(function()
            return _G.QBX
        end)
        if success and result then
            self.Framework = result
            print('[Phone] Initialized Qbox framework adapter (via global QBX) after ' .. attempt .. ' attempt(s)')
            return self
        end
        
        -- Method 2: Try exports.qbx_core
        success, result = pcall(function()
            return exports.qbx_core:GetCoreObject()
        end)
        if success and result then
            self.Framework = result
            print('[Phone] Initialized Qbox framework adapter (via qbx_core export) after ' .. attempt .. ' attempt(s)')
            return self
        end
        
        -- Method 3: Try exports['qbx-core'] (alternative naming)
        success, result = pcall(function()
            return exports['qbx-core']:GetCoreObject()
        end)
        if success and result then
            self.Framework = result
            print('[Phone] Initialized Qbox framework adapter (via qbx-core export) after ' .. attempt .. ' attempt(s)')
            return self
        end
        
        -- If not found and not last attempt, wait and retry
        if attempt < maxRetries then
            if attempt == 1 then
                print('[Phone] ^3Waiting for Qbox framework to initialize...^7')
            elseif attempt % 5 == 0 then
                print('[Phone] ^3Still waiting... (attempt ' .. attempt .. '/' .. maxRetries .. ')^7')
            end
            Wait(retryDelay)
        end
    end
    
    print('[Phone] ^1ERROR: Failed to load Qbox framework after ' .. maxRetries .. ' attempts (' .. (maxRetries * retryDelay / 1000) .. ' seconds)^7')
    print('[Phone] ^3Qbox may still be initializing. This is usually a load order issue.^7')
    print('[Phone] ^3Try adding a small delay before starting lb-gphone, or ensure qbx_core loads first.^7')
    return nil
end

--- Get player object from source
function Qbox:GetPlayer(source)
    if not source or source == 0 then return nil end
    if not self.Framework then return nil end
    
    return self.Framework.Functions.GetPlayer(source)
end

--- Get unique identifier for player
function Qbox:GetIdentifier(source)
    local Player = self:GetPlayer(source)
    if not Player then return nil end
    
    return Player.PlayerData.citizenid
end

--- Get player's phone number from database
function Qbox:GetPhoneNumber(source)
    local Player = self:GetPlayer(source)
    if not Player then return nil end
    
    -- Qbox stores phone number in PlayerData.charinfo
    if Player.PlayerData.charinfo and Player.PlayerData.charinfo.phone then
        return Player.PlayerData.charinfo.phone
    end
    
    return nil
end

--- Set player's phone number
function Qbox:SetPhoneNumber(source, phoneNumber)
    local Player = self:GetPlayer(source)
    if not Player then return false end
    
    -- Update phone number in Qbox player data
    if Player.PlayerData.charinfo then
        Player.PlayerData.charinfo.phone = phoneNumber
        Player.Functions.SetPlayerData('charinfo', Player.PlayerData.charinfo)
        return true
    end
    
    return false
end

--- Get player's money amount
function Qbox:GetPlayerMoney(source, account)
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
function Qbox:AddMoney(source, amount, account)
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
function Qbox:RemoveMoney(source, amount, account)
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
function Qbox:GetJob(source)
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
function Qbox:GetPlayerName(source)
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
function Qbox:PlayerExists(source)
    return self:GetPlayer(source) ~= nil
end

return Qbox:new()
