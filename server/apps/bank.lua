-- Bank App Server Logic
-- Handles bank operations including balance fetching and money transfers

-- Get bank balance for player
RegisterNetEvent('phone:server:getBankBalance', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local balance = Framework:GetPlayerMoney(source, Config.BankApp.defaultAccount or 'bank')
    
    TriggerClientEvent('phone:client:receiveBankBalance', source, {
        success = true,
        balance = balance or 0
    })
end)

-- Get bank data (balance + transaction history)
RegisterNetEvent('phone:server:getBankData', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveBankData', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Get balance from framework
    local balance = Framework:GetPlayerMoney(source, Config.BankApp.defaultAccount or 'bank')
    
    -- Get transaction history from database
    local transactions = MySQL.query.await([[
        SELECT 
            id,
            CASE 
                WHEN sender_number = ? THEN 'sent'
                ELSE 'received'
            END as type,
            CASE 
                WHEN sender_number = ? THEN receiver_number
                ELSE sender_number
            END as phoneNumber,
            amount,
            UNIX_TIMESTAMP(created_at) * 1000 as timestamp
        FROM phone_bank_transactions
        WHERE sender_number = ? OR receiver_number = ?
        ORDER BY created_at DESC
        LIMIT ?
    ]], {
        phoneNumber,
        phoneNumber,
        phoneNumber,
        phoneNumber,
        Config.BankApp.transactionHistoryLimit or 50
    })
    
    TriggerClientEvent('phone:client:receiveBankData', source, {
        success = true,
        balance = balance or 0,
        transactions = transactions or {}
    })
end)

-- Transfer money to another player
RegisterNetEvent('phone:server:transferMoney', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local targetNumber = data.targetNumber
    local amount = tonumber(data.amount)
    
    -- Validation
    if not targetNumber or not amount then
        TriggerClientEvent('phone:client:transferResult', source, {
            success = false,
            message = 'Invalid transfer data'
        })
        return
    end
    
    -- Validate amount
    if amount < (Config.BankApp.minTransferAmount or 1) then
        TriggerClientEvent('phone:client:transferResult', source, {
            success = false,
            message = 'Amount too low'
        })
        return
    end
    
    if amount > (Config.BankApp.maxTransferAmount or 999999) then
        TriggerClientEvent('phone:client:transferResult', source, {
            success = false,
            message = 'Amount too high'
        })
        return
    end
    
    -- Get sender phone number
    local senderNumber = Framework:GetPhoneNumber(source)
    if not senderNumber then
        TriggerClientEvent('phone:client:transferResult', source, {
            success = false,
            message = 'Your phone number not found'
        })
        return
    end
    
    -- Check if trying to send to self
    if senderNumber == targetNumber then
        TriggerClientEvent('phone:client:transferResult', source, {
            success = false,
            message = 'Cannot transfer to yourself'
        })
        return
    end
    
    -- Validate target phone number exists
    local targetPlayer = MySQL.query.await('SELECT identifier FROM phone_players WHERE phone_number = ?', {
        targetNumber
    })
    
    if not targetPlayer or #targetPlayer == 0 then
        TriggerClientEvent('phone:client:transferResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Check if sender has sufficient funds
    local senderBalance = Framework:GetPlayerMoney(source, Config.BankApp.defaultAccount or 'bank')
    if senderBalance < amount then
        TriggerClientEvent('phone:client:transferResult', source, {
            success = false,
            message = 'Insufficient funds'
        })
        return
    end
    
    -- Find target player source
    local targetSource = nil
    local targetIdentifier = targetPlayer[1].identifier
    
    for _, playerId in ipairs(GetPlayers()) do
        local playerIdentifier = Framework:GetIdentifier(tonumber(playerId))
        if playerIdentifier == targetIdentifier then
            targetSource = tonumber(playerId)
            break
        end
    end
    
    -- Perform transfer
    local removeSuccess = Framework:RemoveMoney(source, amount, Config.BankApp.defaultAccount or 'bank')
    
    if not removeSuccess then
        TriggerClientEvent('phone:client:transferResult', source, {
            success = false,
            message = 'Transfer failed'
        })
        return
    end
    
    -- Add money to target if online
    if targetSource then
        Framework:AddMoney(targetSource, amount, Config.BankApp.defaultAccount or 'bank')
        
        -- Notify target player
        TriggerClientEvent('phone:client:receiveMoneyNotification', targetSource, {
            amount = amount,
            from = senderNumber
        })
    else
        -- Target is offline, add money directly via framework (if supported)
        -- This depends on framework implementation
        -- For now, we'll just log it
        if Config.DebugMode then
            print(string.format('[Phone] Offline transfer: %s sent $%d to %s', senderNumber, amount, targetNumber))
        end
    end
    
    -- Log transaction in database
    MySQL.insert('INSERT INTO phone_bank_transactions (sender_number, receiver_number, amount) VALUES (?, ?, ?)', {
        senderNumber,
        targetNumber,
        amount
    })
    
    -- Get new balance
    local newBalance = Framework:GetPlayerMoney(source, Config.BankApp.defaultAccount or 'bank')
    
    -- Send success response
    TriggerClientEvent('phone:client:transferResult', source, {
        success = true,
        amount = amount,
        targetNumber = targetNumber,
        newBalance = newBalance
    })
end)
