-- Crypto App Server Logic
-- Handles cryptocurrency trading and price updates

-- Store current crypto prices in memory
local CryptoPrices = {}

-- Initialize crypto prices from config
local function InitializeCryptoPrices()
    for _, crypto in ipairs(Config.CryptoApp.availableCryptos) do
        CryptoPrices[crypto.symbol] = {
            name = crypto.name,
            symbol = crypto.symbol,
            icon = crypto.icon,
            currentPrice = crypto.basePrice,
            previousPrice = crypto.basePrice
        }
    end
    
    if Config.DebugMode then
        print('[Phone] Initialized crypto prices:', json.encode(CryptoPrices))
    end
end

-- Update crypto prices with random fluctuation
local function UpdateCryptoPrices()
    for symbol, priceData in pairs(CryptoPrices) do
        -- Store previous price
        priceData.previousPrice = priceData.currentPrice
        
        -- Calculate random fluctuation
        local volatility = Config.CryptoApp.priceVolatility or 0.05
        local changePercent = (math.random() * 2 - 1) * volatility -- Random between -volatility and +volatility
        local priceChange = priceData.currentPrice * changePercent
        
        -- Update current price
        priceData.currentPrice = math.max(0.00000001, priceData.currentPrice + priceChange)
        
        if Config.DebugMode then
            print(string.format('[Phone] %s price updated: $%.8f (%.2f%%)', 
                symbol, priceData.currentPrice, changePercent * 100))
        end
    end
    
    -- Broadcast price update to all clients
    TriggerClientEvent('phone:client:updateCryptoPrices', -1, CryptoPrices)
end

-- Start price update loop
local function StartPriceUpdateLoop()
    if not Config.CryptoApp.enabled then
        return
    end
    
    local updateInterval = Config.CryptoApp.updateInterval or 60000
    
    CreateThread(function()
        while true do
            Wait(updateInterval)
            UpdateCryptoPrices()
        end
    end)
    
    if Config.DebugMode then
        print(string.format('[Phone] Crypto price update loop started (interval: %dms)', updateInterval))
    end
end

-- Get crypto data for player (portfolio + prices)
RegisterNetEvent('phone:server:getCryptoData', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveCryptoData', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Get portfolio from database
    local portfolio = MySQL.query.await([[
        SELECT crypto_type, amount
        FROM phone_crypto
        WHERE owner_number = ?
        ORDER BY crypto_type
    ]], {
        phoneNumber
    })
    
    TriggerClientEvent('phone:client:receiveCryptoData', source, {
        success = true,
        portfolio = portfolio or {},
        prices = CryptoPrices
    })
end)

-- Buy or sell cryptocurrency
RegisterNetEvent('phone:server:tradeCrypto', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local cryptoType = data.cryptoType
    local amount = tonumber(data.amount)
    local action = data.action -- 'buy' or 'sell'
    
    -- Validation
    if not cryptoType or not amount or not action then
        TriggerClientEvent('phone:client:tradeResult', source, {
            success = false,
            message = 'Invalid trade data'
        })
        return
    end
    
    if amount <= 0 then
        TriggerClientEvent('phone:client:tradeResult', source, {
            success = false,
            message = 'Invalid amount'
        })
        return
    end
    
    if action ~= 'buy' and action ~= 'sell' then
        TriggerClientEvent('phone:client:tradeResult', source, {
            success = false,
            message = 'Invalid action'
        })
        return
    end
    
    -- Check if crypto exists
    if not CryptoPrices[cryptoType] then
        TriggerClientEvent('phone:client:tradeResult', source, {
            success = false,
            message = 'Cryptocurrency not found'
        })
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:tradeResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    local currentPrice = CryptoPrices[cryptoType].currentPrice
    local totalCost = amount * currentPrice
    
    if action == 'buy' then
        -- Check if player has sufficient funds
        local balance = Framework:GetPlayerMoney(source, Config.BankApp.defaultAccount or 'bank')
        if balance < totalCost then
            TriggerClientEvent('phone:client:tradeResult', source, {
                success = false,
                message = 'Insufficient funds'
            })
            return
        end
        
        -- Remove money
        local removeSuccess = Framework:RemoveMoney(source, totalCost, Config.BankApp.defaultAccount or 'bank')
        if not removeSuccess then
            TriggerClientEvent('phone:client:tradeResult', source, {
                success = false,
                message = 'Transaction failed'
            })
            return
        end
        
        -- Add crypto to portfolio
        local currentHolding = MySQL.query.await([[
            SELECT amount FROM phone_crypto
            WHERE owner_number = ? AND crypto_type = ?
        ]], {
            phoneNumber,
            cryptoType
        })
        
        local newAmount = amount
        if currentHolding and #currentHolding > 0 then
            newAmount = currentHolding[1].amount + amount
            MySQL.update.await([[
                UPDATE phone_crypto
                SET amount = ?
                WHERE owner_number = ? AND crypto_type = ?
            ]], {
                newAmount,
                phoneNumber,
                cryptoType
            })
        else
            MySQL.insert.await([[
                INSERT INTO phone_crypto (owner_number, crypto_type, amount)
                VALUES (?, ?, ?)
            ]], {
                phoneNumber,
                cryptoType,
                newAmount
            })
        end
        
        -- Get new balance
        local newBalance = Framework:GetPlayerMoney(source, Config.BankApp.defaultAccount or 'bank')
        
        TriggerClientEvent('phone:client:tradeResult', source, {
            success = true,
            action = 'buy',
            cryptoType = cryptoType,
            amount = amount,
            totalCost = totalCost,
            newAmount = newAmount,
            newBalance = newBalance
        })
        
        if Config.DebugMode then
            print(string.format('[Phone] %s bought %.8f %s for $%.2f', 
                phoneNumber, amount, cryptoType, totalCost))
        end
        
    else -- sell
        -- Check if player has sufficient crypto
        local currentHolding = MySQL.query.await([[
            SELECT amount FROM phone_crypto
            WHERE owner_number = ? AND crypto_type = ?
        ]], {
            phoneNumber,
            cryptoType
        })
        
        if not currentHolding or #currentHolding == 0 or currentHolding[1].amount < amount then
            TriggerClientEvent('phone:client:tradeResult', source, {
                success = false,
                message = 'Insufficient cryptocurrency'
            })
            return
        end
        
        -- Remove crypto from portfolio
        local newAmount = currentHolding[1].amount - amount
        
        if newAmount <= 0.00000001 then
            -- Delete holding if amount is negligible
            MySQL.execute.await([[
                DELETE FROM phone_crypto
                WHERE owner_number = ? AND crypto_type = ?
            ]], {
                phoneNumber,
                cryptoType
            })
            newAmount = 0
        else
            MySQL.update.await([[
                UPDATE phone_crypto
                SET amount = ?
                WHERE owner_number = ? AND crypto_type = ?
            ]], {
                newAmount,
                phoneNumber,
                cryptoType
            })
        end
        
        -- Add money
        local addSuccess = Framework:AddMoney(source, totalCost, Config.BankApp.defaultAccount or 'bank')
        if not addSuccess then
            -- Rollback crypto removal
            MySQL.update.await([[
                UPDATE phone_crypto
                SET amount = ?
                WHERE owner_number = ? AND crypto_type = ?
            ]], {
                currentHolding[1].amount,
                phoneNumber,
                cryptoType
            })
            
            TriggerClientEvent('phone:client:tradeResult', source, {
                success = false,
                message = 'Transaction failed'
            })
            return
        end
        
        -- Get new balance
        local newBalance = Framework:GetPlayerMoney(source, Config.BankApp.defaultAccount or 'bank')
        
        TriggerClientEvent('phone:client:tradeResult', source, {
            success = true,
            action = 'sell',
            cryptoType = cryptoType,
            amount = amount,
            totalCost = totalCost,
            newAmount = newAmount,
            newBalance = newBalance
        })
        
        if Config.DebugMode then
            print(string.format('[Phone] %s sold %.8f %s for $%.2f', 
                phoneNumber, amount, cryptoType, totalCost))
        end
    end
end)

-- Initialize on resource start
CreateThread(function()
    Wait(1000) -- Wait for config to load
    InitializeCryptoPrices()
    StartPriceUpdateLoop()
end)

-- Export function to get current prices (for other resources)
exports('GetCryptoPrices', function()
    return CryptoPrices
end)

