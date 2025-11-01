-- CryptoX App Server Logic
-- Enhanced crypto trading app with advanced features, charts, and portfolio tracking

-- Enhanced crypto data with more realistic market simulation
local CryptoData = {
    {
        symbol = 'BTC',
        name = 'Bitcoin',
        price = 45000.00,
        change24h = 0,
        volume = 28500000000,
        marketCap = 850000000000,
        supply = 19000000,
        priceHistory = {},
        volatility = 0.05 -- 5% volatility
    },
    {
        symbol = 'ETH',
        name = 'Ethereum',
        price = 3200.00,
        change24h = 0,
        volume = 15200000000,
        marketCap = 385000000000,
        supply = 120000000,
        priceHistory = {},
        volatility = 0.07 -- 7% volatility
    },
    {
        symbol = 'ADA',
        name = 'Cardano',
        price = 0.85,
        change24h = 0,
        volume = 1200000000,
        marketCap = 28500000000,
        supply = 33500000000,
        priceHistory = {},
        volatility = 0.08 -- 8% volatility
    },
    {
        symbol = 'DOT',
        name = 'Polkadot',
        price = 25.50,
        change24h = 0,
        volume = 850000000,
        marketCap = 25200000000,
        supply = 987000000,
        priceHistory = {},
        volatility = 0.09 -- 9% volatility
    },
    {
        symbol = 'LINK',
        name = 'Chainlink',
        price = 28.75,
        change24h = 0,
        volume = 1100000000,
        marketCap = 13400000000,
        supply = 467000000,
        priceHistory = {},
        volatility = 0.10 -- 10% volatility
    },
    {
        symbol = 'UNI',
        name = 'Uniswap',
        price = 18.20,
        change24h = 0,
        volume = 450000000,
        marketCap = 11200000000,
        supply = 615000000,
        priceHistory = {},
        volatility = 0.12 -- 12% volatility
    },
    {
        symbol = 'MATIC',
        name = 'Polygon',
        price = 1.85,
        change24h = 0,
        volume = 680000000,
        marketCap = 14500000000,
        supply = 7800000000,
        priceHistory = {},
        volatility = 0.11 -- 11% volatility
    },
    {
        symbol = 'AVAX',
        name = 'Avalanche',
        price = 95.40,
        change24h = 0,
        volume = 920000000,
        marketCap = 23800000000,
        supply = 249000000,
        priceHistory = {},
        volatility = 0.13 -- 13% volatility
    }
}

-- Initialize price history for charts
local function InitializePriceHistory()
    local now = os.time()
    local hoursBack = 168 -- 7 days of hourly data
    
    for _, crypto in ipairs(CryptoData) do
        crypto.priceHistory = {}
        local basePrice = crypto.price
        
        -- Generate historical data
        for i = hoursBack, 0, -1 do
            local timestamp = (now - (i * 3600)) * 1000 -- Convert to milliseconds
            local randomChange = (math.random() - 0.5) * crypto.volatility * 2
            local price = basePrice * (1 + randomChange)
            
            table.insert(crypto.priceHistory, {
                timestamp = timestamp,
                price = price,
                volume = crypto.volume * (0.8 + math.random() * 0.4) -- Random volume variation
            })
        end
        
        -- Set current price to last historical price
        crypto.price = crypto.priceHistory[#crypto.priceHistory].price
    end
end

-- Update crypto prices with realistic market simulation
local function UpdateCryptoPrices()
    for _, crypto in ipairs(CryptoData) do
        local oldPrice = crypto.price
        
        -- Market trend simulation (slight bias towards growth)
        local trendFactor = 1.001 -- 0.1% growth bias
        
        -- Random volatility
        local randomChange = (math.random() - 0.5) * crypto.volatility * 2
        
        -- Apply market events (rare large movements)
        if math.random() < 0.02 then -- 2% chance of market event
            randomChange = randomChange + (math.random() - 0.5) * 0.15 -- Up to 15% movement
        end
        
        -- Calculate new price
        crypto.price = oldPrice * trendFactor * (1 + randomChange)
        
        -- Ensure price doesn't go below a minimum threshold
        local minPrice = crypto.priceHistory[1].price * 0.1 -- 10% of initial price
        if crypto.price < minPrice then
            crypto.price = minPrice
        end
        
        -- Calculate 24h change
        crypto.change24h = ((crypto.price - oldPrice) / oldPrice) * 100
        
        -- Update price history (keep last 168 hours)
        local timestamp = os.time() * 1000
        table.insert(crypto.priceHistory, {
            timestamp = timestamp,
            price = crypto.price,
            volume = crypto.volume * (0.8 + math.random() * 0.4)
        })
        
        -- Remove old data (keep only last 168 entries)
        if #crypto.priceHistory > 168 then
            table.remove(crypto.priceHistory, 1)
        end
        
        -- Update market cap
        crypto.marketCap = crypto.price * crypto.supply
    end
    
    -- Broadcast price updates to all clients
    TriggerClientEvent('phone:client:cryptoxPriceUpdate', -1, CryptoData)
end

-- Initialize price history on server start
InitializePriceHistory()

-- Start price update loop
CreateThread(function()
    while true do
        Wait(Config.CryptoXApp.priceUpdateInterval or 30000) -- Default 30 seconds
        UpdateCryptoPrices()
    end
end)

-- Get enhanced crypto data (portfolio, prices, history, alerts)
RegisterNetEvent('phone:server:getCryptoxData', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveCryptoxData', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Get portfolio holdings
    local portfolio = MySQL.query.await([[
        SELECT 
            crypto_symbol,
            amount,
            avg_buy_price,
            UNIX_TIMESTAMP(last_updated) * 1000 as lastUpdated
        FROM phone_cryptox_holdings
        WHERE owner_number = ?
        AND amount > 0
    ]], {
        phoneNumber
    })
    
    -- Get transaction history
    local transactions = MySQL.query.await([[
        SELECT 
            id,
            crypto_symbol,
            transaction_type,
            amount,
            price_per_unit,
            total_value,
            order_type,
            UNIX_TIMESTAMP(created_at) * 1000 as timestamp
        FROM phone_cryptox_transactions
        WHERE owner_number = ?
        ORDER BY created_at DESC
        LIMIT ?
    ]], {
        phoneNumber,
        Config.CryptoXApp.transactionHistoryLimit or 100
    })
    
    -- Get price alerts
    local alerts = MySQL.query.await([[
        SELECT 
            id,
            crypto_symbol,
            alert_type,
            target_price,
            is_active,
            UNIX_TIMESTAMP(created_at) * 1000 as createdAt
        FROM phone_cryptox_alerts
        WHERE owner_number = ?
        AND is_active = 1
        ORDER BY created_at DESC
    ]], {
        phoneNumber
    })
    
    -- Calculate portfolio analytics
    local portfolioAnalytics = CalculatePortfolioAnalytics(portfolio, CryptoData)
    
    -- Get player cash balance
    local cashBalance = Framework:GetPlayerMoney(source, 'bank')
    
    TriggerClientEvent('phone:client:receiveCryptoxData', source, {
        success = true,
        portfolio = portfolio or {},
        transactions = transactions or {},
        alerts = alerts or {},
        prices = CryptoData,
        analytics = portfolioAnalytics,
        cashBalance = cashBalance
    })
end)

-- Enhanced crypto trading with market/limit orders
RegisterNetEvent('phone:server:cryptoxTrade', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:cryptoxTradeResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    local cryptoSymbol = data.cryptoSymbol
    local tradeType = data.tradeType -- 'buy' or 'sell'
    local orderType = data.orderType -- 'market' or 'limit'
    local amount = tonumber(data.amount)
    local limitPrice = tonumber(data.limitPrice) -- For limit orders
    
    -- Validation
    if not cryptoSymbol or not tradeType or not orderType or not amount then
        TriggerClientEvent('phone:client:cryptoxTradeResult', source, {
            success = false,
            message = 'Invalid trade data'
        })
        return
    end
    
    if amount <= 0 then
        TriggerClientEvent('phone:client:cryptoxTradeResult', source, {
            success = false,
            message = 'Invalid amount'
        })
        return
    end
    
    -- Find crypto data
    local cryptoInfo = nil
    for _, crypto in ipairs(CryptoData) do
        if crypto.symbol == cryptoSymbol then
            cryptoInfo = crypto
            break
        end
    end
    
    if not cryptoInfo then
        TriggerClientEvent('phone:client:cryptoxTradeResult', source, {
            success = false,
            message = 'Cryptocurrency not found'
        })
        return
    end
    
    local currentPrice = cryptoInfo.price
    local tradePrice = currentPrice
    
    -- Handle limit orders
    if orderType == 'limit' then
        if not limitPrice or limitPrice <= 0 then
            TriggerClientEvent('phone:client:cryptoxTradeResult', source, {
                success = false,
                message = 'Invalid limit price'
            })
            return
        end
        
        -- For limit orders, check if price conditions are met
        if tradeType == 'buy' and currentPrice > limitPrice then
            TriggerClientEvent('phone:client:cryptoxTradeResult', source, {
                success = false,
                message = 'Limit buy price too low'
            })
            return
        elseif tradeType == 'sell' and currentPrice < limitPrice then
            TriggerClientEvent('phone:client:cryptoxTradeResult', source, {
                success = false,
                message = 'Limit sell price too high'
            })
            return
        end
        
        tradePrice = limitPrice
    end
    
    local totalValue = amount * tradePrice
    local fee = totalValue * (Config.CryptoXApp.tradingFee or 0.001) -- 0.1% fee
    local totalCost = totalValue + fee
    
    if tradeType == 'buy' then
        -- Check if player has enough money
        local playerMoney = Framework:GetPlayerMoney(source, 'bank')
        if playerMoney < totalCost then
            TriggerClientEvent('phone:client:cryptoxTradeResult', source, {
                success = false,
                message = 'Insufficient funds'
            })
            return
        end
        
        -- Remove money from player
        if not Framework:RemoveMoney(source, totalCost, 'bank') then
            TriggerClientEvent('phone:client:cryptoxTradeResult', source, {
                success = false,
                message = 'Failed to process payment'
            })
            return
        end
        
        -- Update or create portfolio holding
        local existingHolding = MySQL.query.await([[
            SELECT amount, avg_buy_price FROM phone_cryptox_holdings
            WHERE owner_number = ? AND crypto_symbol = ?
        ]], {
            phoneNumber,
            cryptoSymbol
        })
        
        if existingHolding and #existingHolding > 0 then
            -- Update existing holding
            local currentAmount = existingHolding[1].amount
            local currentAvgPrice = existingHolding[1].avg_buy_price
            
            local newAmount = currentAmount + amount
            local newAvgPrice = ((currentAmount * currentAvgPrice) + (amount * tradePrice)) / newAmount
            
            MySQL.update.await([[
                UPDATE phone_cryptox_holdings
                SET amount = ?, avg_buy_price = ?, last_updated = NOW()
                WHERE owner_number = ? AND crypto_symbol = ?
            ]], {
                newAmount,
                newAvgPrice,
                phoneNumber,
                cryptoSymbol
            })
        else
            -- Create new holding
            MySQL.insert([[
                INSERT INTO phone_cryptox_holdings 
                (owner_number, crypto_symbol, amount, avg_buy_price) 
                VALUES (?, ?, ?, ?)
            ]], {
                phoneNumber,
                cryptoSymbol,
                amount,
                tradePrice
            })
        end
        
    elseif tradeType == 'sell' then
        -- Check if player has enough crypto
        local holding = MySQL.query.await([[
            SELECT amount FROM phone_cryptox_holdings
            WHERE owner_number = ? AND crypto_symbol = ?
        ]], {
            phoneNumber,
            cryptoSymbol
        })
        
        if not holding or #holding == 0 or holding[1].amount < amount then
            TriggerClientEvent('phone:client:cryptoxTradeResult', source, {
                success = false,
                message = 'Insufficient crypto holdings'
            })
            return
        end
        
        -- Update holding
        local newAmount = holding[1].amount - amount
        
        if newAmount > 0 then
            MySQL.update.await([[
                UPDATE phone_cryptox_holdings
                SET amount = ?, last_updated = NOW()
                WHERE owner_number = ? AND crypto_symbol = ?
            ]], {
                newAmount,
                phoneNumber,
                cryptoSymbol
            })
        else
            -- Remove holding if amount becomes 0
            MySQL.execute.await([[
                DELETE FROM phone_cryptox_holdings
                WHERE owner_number = ? AND crypto_symbol = ?
            ]], {
                phoneNumber,
                cryptoSymbol
            })
        end
        
        -- Add money to player (minus fee)
        local proceeds = totalValue - fee
        Framework:AddMoney(source, proceeds, 'bank')
    end
    
    -- Log transaction
    MySQL.insert([[
        INSERT INTO phone_cryptox_transactions 
        (owner_number, crypto_symbol, transaction_type, amount, price_per_unit, total_value, order_type, fee) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        phoneNumber,
        cryptoSymbol,
        tradeType,
        amount,
        tradePrice,
        totalValue,
        orderType,
        fee
    })
    
    TriggerClientEvent('phone:client:cryptoxTradeResult', source, {
        success = true,
        tradeType = tradeType,
        cryptoSymbol = cryptoSymbol,
        amount = amount,
        price = tradePrice,
        totalValue = totalValue,
        fee = fee,
        orderType = orderType
    })
end)

-- Create price alert
RegisterNetEvent('phone:server:cryptoxCreateAlert', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    local cryptoSymbol = data.cryptoSymbol
    local alertType = data.alertType -- 'above' or 'below'
    local targetPrice = tonumber(data.targetPrice)
    
    if not cryptoSymbol or not alertType or not targetPrice or targetPrice <= 0 then
        TriggerClientEvent('phone:client:cryptoxAlertResult', source, {
            success = false,
            message = 'Invalid alert data'
        })
        return
    end
    
    -- Check if crypto exists
    local cryptoExists = false
    for _, crypto in ipairs(CryptoData) do
        if crypto.symbol == cryptoSymbol then
            cryptoExists = true
            break
        end
    end
    
    if not cryptoExists then
        TriggerClientEvent('phone:client:cryptoxAlertResult', source, {
            success = false,
            message = 'Cryptocurrency not found'
        })
        return
    end
    
    -- Create alert
    MySQL.insert([[
        INSERT INTO phone_cryptox_alerts 
        (owner_number, crypto_symbol, alert_type, target_price, is_active) 
        VALUES (?, ?, ?, ?, 1)
    ]], {
        phoneNumber,
        cryptoSymbol,
        alertType,
        targetPrice
    })
    
    TriggerClientEvent('phone:client:cryptoxAlertResult', source, {
        success = true,
        message = 'Price alert created successfully'
    })
end)

-- Delete price alert
RegisterNetEvent('phone:server:cryptoxDeleteAlert', function(alertId)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    -- Delete alert (only if owned by player)
    MySQL.execute.await([[
        DELETE FROM phone_cryptox_alerts
        WHERE id = ? AND owner_number = ?
    ]], {
        alertId,
        phoneNumber
    })
    
    TriggerClientEvent('phone:client:cryptoxAlertDeleted', source, {
        success = true,
        alertId = alertId
    })
end)

-- Get price chart data
RegisterNetEvent('phone:server:getCryptoxChart', function(cryptoSymbol, timeframe)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    -- Find crypto data
    local cryptoInfo = nil
    for _, crypto in ipairs(CryptoData) do
        if crypto.symbol == cryptoSymbol then
            cryptoInfo = crypto
            break
        end
    end
    
    if not cryptoInfo then
        TriggerClientEvent('phone:client:receiveCryptoxChart', source, {
            success = false,
            message = 'Cryptocurrency not found'
        })
        return
    end
    
    local chartData = {}
    local priceHistory = cryptoInfo.priceHistory
    
    -- Filter data based on timeframe
    local now = os.time() * 1000
    local timeLimit = now
    
    if timeframe == '1h' then
        timeLimit = now - (1 * 60 * 60 * 1000) -- 1 hour
    elseif timeframe == '24h' then
        timeLimit = now - (24 * 60 * 60 * 1000) -- 24 hours
    elseif timeframe == '7d' then
        timeLimit = now - (7 * 24 * 60 * 60 * 1000) -- 7 days
    else
        timeLimit = 0 -- All data
    end
    
    -- Filter and format data
    for _, dataPoint in ipairs(priceHistory) do
        if dataPoint.timestamp >= timeLimit then
            table.insert(chartData, {
                timestamp = dataPoint.timestamp,
                price = dataPoint.price,
                volume = dataPoint.volume
            })
        end
    end
    
    TriggerClientEvent('phone:client:receiveCryptoxChart', source, {
        success = true,
        symbol = cryptoSymbol,
        timeframe = timeframe,
        data = chartData
    })
end)

-- Helper function to calculate portfolio analytics
function CalculatePortfolioAnalytics(portfolio, cryptoData)
    local analytics = {
        totalValue = 0,
        totalInvested = 0,
        totalProfitLoss = 0,
        totalProfitLossPercent = 0,
        holdings = {}
    }
    
    local totalValue = 0
    local totalInvested = 0
    
    for _, holding in ipairs(portfolio) do
        -- Find current price
        local currentPrice = 0
        for _, crypto in ipairs(cryptoData) do
            if crypto.symbol == holding.crypto_symbol then
                currentPrice = crypto.price
                break
            end
        end
        
        local currentValue = holding.amount * currentPrice
        local investedValue = holding.amount * holding.avg_buy_price
        local profitLoss = currentValue - investedValue
        local profitLossPercent = investedValue > 0 and (profitLoss / investedValue) * 100 or 0
        
        totalValue = totalValue + currentValue
        totalInvested = totalInvested + investedValue
        
        table.insert(analytics.holdings, {
            symbol = holding.crypto_symbol,
            amount = holding.amount,
            avgBuyPrice = holding.avg_buy_price,
            currentPrice = currentPrice,
            currentValue = currentValue,
            investedValue = investedValue,
            profitLoss = profitLoss,
            profitLossPercent = profitLossPercent
        })
    end
    
    analytics.totalValue = totalValue
    analytics.totalInvested = totalInvested
    analytics.totalProfitLoss = totalValue - totalInvested
    analytics.totalProfitLossPercent = totalInvested > 0 and (analytics.totalProfitLoss / totalInvested) * 100 or 0
    
    return analytics
end

-- Check price alerts and notify players
function CheckPriceAlerts()
    local alerts = MySQL.query.await([[
        SELECT 
            a.id, a.owner_number, a.crypto_symbol, a.alert_type, a.target_price,
            p.identifier
        FROM phone_cryptox_alerts a
        JOIN phone_players p ON a.owner_number = p.phone_number
        WHERE a.is_active = 1
    ]])
    
    for _, alert in ipairs(alerts) do
        -- Find current price
        local currentPrice = 0
        for _, crypto in ipairs(CryptoData) do
            if crypto.symbol == alert.crypto_symbol then
                currentPrice = crypto.price
                break
            end
        end
        
        local shouldTrigger = false
        
        if alert.alert_type == 'above' and currentPrice >= alert.target_price then
            shouldTrigger = true
        elseif alert.alert_type == 'below' and currentPrice <= alert.target_price then
            shouldTrigger = true
        end
        
        if shouldTrigger then
            -- Find player source
            local playerSource = nil
            for _, playerId in ipairs(GetPlayers()) do
                local playerIdentifier = Framework:GetIdentifier(tonumber(playerId))
                if playerIdentifier == alert.identifier then
                    playerSource = tonumber(playerId)
                    break
                end
            end
            
            if playerSource then
                -- Notify player
                TriggerClientEvent('phone:client:cryptoxPriceAlert', playerSource, {
                    symbol = alert.crypto_symbol,
                    alertType = alert.alert_type,
                    targetPrice = alert.target_price,
                    currentPrice = currentPrice
                })
            end
            
            -- Deactivate alert
            MySQL.update.await([[
                UPDATE phone_cryptox_alerts
                SET is_active = 0
                WHERE id = ?
            ]], {
                alert.id
            })
        end
    end
end

-- Check alerts every minute
CreateThread(function()
    while true do
        Wait(60000) -- 1 minute
        CheckPriceAlerts()
    end
end)

if Config.DebugMode then
    print('[Phone] CryptoX app server loaded')
end