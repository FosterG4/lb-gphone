# Custom Framework Adapter Guide

This guide explains how to create a custom framework adapter for the FiveM Smartphone NUI resource, allowing integration with any FiveM framework.

## Overview

The resource uses an adapter pattern to support multiple frameworks. Each framework adapter implements a standard interface that the phone system uses to interact with player data, money, and other framework-specific features.

## Adapter Interface

All framework adapters must implement the following interface defined in `server/framework/adapter.lua`:

```lua
Framework = {}

-- Get player object by server ID
function Framework:GetPlayer(source)
    -- Returns: player object or nil
end

-- Get unique identifier for player
function Framework:GetIdentifier(source)
    -- Returns: string identifier (license, steam, etc.)
end

-- Get player's phone number
function Framework:GetPhoneNumber(source)
    -- Returns: string phone number or nil
end

-- Set player's phone number
function Framework:SetPhoneNumber(source, number)
    -- Returns: boolean success
end

-- Get player's money amount
function Framework:GetPlayerMoney(source, account)
    -- Parameters:
    --   source: player server ID
    --   account: 'bank' or 'cash' (optional, defaults to 'bank')
    -- Returns: number amount
end

-- Add money to player
function Framework:AddMoney(source, amount, account)
    -- Parameters:
    --   source: player server ID
    --   amount: number to add
    --   account: 'bank' or 'cash' (optional, defaults to 'bank')
    -- Returns: boolean success
end

-- Remove money from player
function Framework:RemoveMoney(source, amount, account)
    -- Parameters:
    --   source: player server ID
    --   amount: number to remove
    --   account: 'bank' or 'cash' (optional, defaults to 'bank')
    -- Returns: boolean success
end

-- Get player's job information
function Framework:GetJob(source)
    -- Returns: table { name, label, grade, grade_name } or nil
end

-- Get player's name
function Framework:GetPlayerName(source)
    -- Returns: string name
end

-- Check if player is online
function Framework:IsPlayerOnline(source)
    -- Returns: boolean
end
```

## Creating a Custom Adapter

### Step 1: Create Adapter File

Create a new file in `server/framework/` named after your framework (e.g., `myframework.lua`).

### Step 2: Implement the Interface

Here's a template with detailed comments:

```lua
-- server/framework/myframework.lua

local Framework = {}

-- Initialize framework (called once on resource start)
function Framework:Init()
    -- Wait for your framework to be ready
    while GetResourceState('my-framework') ~= 'started' do
        Wait(100)
    end
    
    -- Get framework object/exports
    self.Core = exports['my-framework']:GetCoreObject()
    
    print('[Phone] MyFramework adapter initialized')
end

-- Get player object by server ID
function Framework:GetPlayer(source)
    -- Example for frameworks with GetPlayer function
    return self.Core.Functions.GetPlayer(source)
    
    -- Example for frameworks with player table
    -- return self.Core.Players[source]
end

-- Get unique identifier for player
function Framework:GetIdentifier(source)
    local player = self:GetPlayer(source)
    if not player then return nil end
    
    -- Example: Return framework's identifier
    return player.PlayerData.citizenid
    
    -- Alternative: Use FiveM identifiers
    -- return GetPlayerIdentifierByType(source, 'license')
end

-- Get player's phone number
function Framework:GetPhoneNumber(source)
    local player = self:GetPlayer(source)
    if not player then return nil end
    
    -- If your framework stores phone numbers
    return player.PlayerData.charinfo.phone
    
    -- Otherwise, return nil to use database lookup
    -- return nil
end

-- Set player's phone number
function Framework:SetPhoneNumber(source, number)
    local player = self:GetPlayer(source)
    if not player then return false end
    
    -- If your framework stores phone numbers, update it
    player.Functions.SetCharInfo('phone', number)
    return true
    
    -- Otherwise, just return true (database handles storage)
    -- return true
end

-- Get player's money amount
function Framework:GetPlayerMoney(source, account)
    local player = self:GetPlayer(source)
    if not player then return 0 end
    
    account = account or 'bank'
    
    -- Example: Framework with money table
    return player.PlayerData.money[account] or 0
    
    -- Example: Framework with getAccount function
    -- local acc = player.getAccount(account)
    -- return acc and acc.money or 0
end

-- Add money to player
function Framework:AddMoney(source, amount, account)
    local player = self:GetPlayer(source)
    if not player then return false end
    
    account = account or 'bank'
    
    -- Example: Framework with AddMoney function
    player.Functions.AddMoney(account, amount, 'phone-transfer')
    return true
    
    -- Example: Framework with addAccountMoney function
    -- player.addAccountMoney(account, amount)
    -- return true
end

-- Remove money from player
function Framework:RemoveMoney(source, amount, account)
    local player = self:GetPlayer(source)
    if not player then return false end
    
    account = account or 'bank'
    
    -- Check if player has enough money
    if self:GetPlayerMoney(source, account) < amount then
        return false
    end
    
    -- Example: Framework with RemoveMoney function
    player.Functions.RemoveMoney(account, amount, 'phone-transfer')
    return true
    
    -- Example: Framework with removeAccountMoney function
    -- player.removeAccountMoney(account, amount)
    -- return true
end

-- Get player's job information
function Framework:GetJob(source)
    local player = self:GetPlayer(source)
    if not player then return nil end
    
    -- Example: Framework with job data
    local job = player.PlayerData.job
    return {
        name = job.name,
        label = job.label,
        grade = job.grade.level,
        grade_name = job.grade.name
    }
    
    -- If your framework doesn't have jobs, return nil
    -- return nil
end

-- Get player's name
function Framework:GetPlayerName(source)
    local player = self:GetPlayer(source)
    if not player then 
        return GetPlayerName(source) -- Fallback to FiveM name
    end
    
    -- Example: Framework with character name
    local charinfo = player.PlayerData.charinfo
    return charinfo.firstname .. ' ' .. charinfo.lastname
    
    -- Example: Framework with getName function
    -- return player.getName()
end

-- Check if player is online
function Framework:IsPlayerOnline(source)
    return self:GetPlayer(source) ~= nil
end

return Framework
```

### Step 3: Register Your Adapter

Edit `server/main.lua` to add your framework to the adapter loading logic:

```lua
-- Find the framework initialization section
local function InitializeFramework()
    local frameworkType = Config.Framework or 'standalone'
    
    if frameworkType == 'esx' then
        Framework = require 'server.framework.esx'
    elseif frameworkType == 'qbcore' then
        Framework = require 'server.framework.qbcore'
    elseif frameworkType == 'qbox' then
        Framework = require 'server.framework.qbox'
    elseif frameworkType == 'myframework' then  -- Add this
        Framework = require 'server.framework.myframework'
    else
        Framework = require 'server.framework.standalone'
    end
    
    if Framework.Init then
        Framework:Init()
    end
end
```

### Step 4: Configure

Update `config.lua` to use your framework:

```lua
Config.Framework = 'myframework'
```

## Testing Your Adapter

### Test Checklist

1. **Player Identification**
   - [ ] Players get unique identifiers
   - [ ] Identifiers persist across reconnects
   - [ ] Phone numbers are assigned correctly

2. **Money Operations**
   - [ ] Can retrieve player balance
   - [ ] Can add money to player
   - [ ] Can remove money from player
   - [ ] Insufficient funds are handled correctly

3. **Player Data**
   - [ ] Player names display correctly
   - [ ] Job information is retrieved (if applicable)
   - [ ] Online status is accurate

4. **Integration**
   - [ ] Bank app shows correct balance
   - [ ] Money transfers work between players
   - [ ] Framework-specific features work

### Test Script

Create a test command to verify your adapter:

```lua
-- Add to server/main.lua for testing
RegisterCommand('testphone', function(source, args)
    if source == 0 then return end -- Console only
    
    print('=== Phone Framework Adapter Test ===')
    
    -- Test GetPlayer
    local player = Framework:GetPlayer(source)
    print('GetPlayer:', player ~= nil)
    
    -- Test GetIdentifier
    local identifier = Framework:GetIdentifier(source)
    print('GetIdentifier:', identifier)
    
    -- Test GetPhoneNumber
    local phone = Framework:GetPhoneNumber(source)
    print('GetPhoneNumber:', phone)
    
    -- Test GetPlayerMoney
    local money = Framework:GetPlayerMoney(source, 'bank')
    print('GetPlayerMoney:', money)
    
    -- Test GetPlayerName
    local name = Framework:GetPlayerName(source)
    print('GetPlayerName:', name)
    
    -- Test GetJob
    local job = Framework:GetJob(source)
    print('GetJob:', json.encode(job))
    
    print('=== Test Complete ===')
end, true)
```

## Common Patterns

### Pattern 1: Framework with Core Object

```lua
function Framework:Init()
    self.Core = exports['framework-name']:GetCoreObject()
end

function Framework:GetPlayer(source)
    return self.Core.Functions.GetPlayer(source)
end
```

### Pattern 2: Framework with Player Table

```lua
function Framework:Init()
    self.Core = exports['framework-name']:GetSharedObject()
end

function Framework:GetPlayer(source)
    return self.Core.Players[source]
end
```

### Pattern 3: Framework with Exports Only

```lua
function Framework:GetPlayer(source)
    return exports['framework-name']:GetPlayer(source)
end

function Framework:GetPlayerMoney(source, account)
    return exports['framework-name']:GetMoney(source, account)
end
```

### Pattern 4: Async Framework Functions

```lua
function Framework:GetPlayer(source)
    local p = promise.new()
    
    exports['framework-name']:GetPlayerAsync(source, function(player)
        p:resolve(player)
    end)
    
    return Citizen.Await(p)
end
```

## Advanced Features

### Custom Phone Number Storage

If your framework has a built-in phone number system:

```lua
function Framework:GetPhoneNumber(source)
    local player = self:GetPlayer(source)
    if not player then return nil end
    
    -- Return framework's phone number
    return player.PlayerData.phone
end

function Framework:SetPhoneNumber(source, number)
    local player = self:GetPlayer(source)
    if not player then return false end
    
    -- Update framework's phone number
    player.Functions.UpdatePlayerData({phone = number})
    return true
end
```

### Multiple Money Accounts

If your framework has multiple account types:

```lua
function Framework:GetPlayerMoney(source, account)
    local player = self:GetPlayer(source)
    if not player then return 0 end
    
    -- Map phone account types to framework accounts
    local accountMap = {
        bank = 'bank',
        cash = 'money',
        savings = 'savings'
    }
    
    local frameworkAccount = accountMap[account] or 'bank'
    return player.PlayerData.money[frameworkAccount] or 0
end
```

### Permission Checks

Add permission checks for sensitive operations:

```lua
function Framework:CanTransferMoney(source, amount)
    local player = self:GetPlayer(source)
    if not player then return false end
    
    -- Check if player has permission
    if player.PlayerData.job.name == 'police' then
        return false -- Police can't transfer money
    end
    
    -- Check daily limit
    local dailyLimit = 50000
    -- ... check transfer history ...
    
    return true
end
```

## Troubleshooting

### Framework not loading

- Ensure framework resource is started before phone resource
- Check resource name matches in exports
- Verify framework is fully initialized before adapter Init()

### Player data not found

- Check that GetPlayer returns valid player object
- Verify player is fully loaded in framework
- Add debug prints to trace data flow

### Money operations failing

- Verify account names match framework's account system
- Check that framework functions return success/failure
- Test with framework's native commands first

### Identifier issues

- Ensure identifier is unique and persistent
- Check that identifier format is consistent
- Verify database stores identifier correctly

## Example: Complete Custom Adapter

Here's a complete example for a fictional framework:

```lua
-- server/framework/customfw.lua

local Framework = {}

function Framework:Init()
    -- Wait for framework
    while GetResourceState('custom-framework') ~= 'started' do
        Wait(100)
    end
    
    -- Get framework core
    self.FW = exports['custom-framework']:GetCore()
    
    print('[Phone] Custom Framework adapter initialized')
end

function Framework:GetPlayer(source)
    return self.FW.GetPlayerFromId(source)
end

function Framework:GetIdentifier(source)
    local player = self:GetPlayer(source)
    return player and player.identifier or nil
end

function Framework:GetPhoneNumber(source)
    -- Framework doesn't store phone numbers
    return nil
end

function Framework:SetPhoneNumber(source, number)
    -- Just return true, database handles storage
    return true
end

function Framework:GetPlayerMoney(source, account)
    local player = self:GetPlayer(source)
    if not player then return 0 end
    
    account = account or 'bank'
    return player.getAccount(account).money
end

function Framework:AddMoney(source, amount, account)
    local player = self:GetPlayer(source)
    if not player then return false end
    
    account = account or 'bank'
    player.addAccountMoney(account, amount)
    return true
end

function Framework:RemoveMoney(source, amount, account)
    local player = self:GetPlayer(source)
    if not player then return false end
    
    account = account or 'bank'
    
    if self:GetPlayerMoney(source, account) < amount then
        return false
    end
    
    player.removeAccountMoney(account, amount)
    return true
end

function Framework:GetJob(source)
    local player = self:GetPlayer(source)
    if not player then return nil end
    
    local job = player.getJob()
    return {
        name = job.name,
        label = job.label,
        grade = job.grade,
        grade_name = job.grade_label
    }
end

function Framework:GetPlayerName(source)
    local player = self:GetPlayer(source)
    if not player then return GetPlayerName(source) end
    
    return player.getName()
end

function Framework:IsPlayerOnline(source)
    return self:GetPlayer(source) ~= nil
end

return Framework
```

## Support

If you need help creating a custom adapter:
1. Check existing adapters for reference (esx.lua, qbcore.lua)
2. Review your framework's documentation
3. Test each function individually
4. Open an issue with your framework details

## Contributing

If you create an adapter for a popular framework, consider contributing it back to the project!
