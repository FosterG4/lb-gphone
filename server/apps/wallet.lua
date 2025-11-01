-- Wallet App Server Logic
-- Unified banking solution consolidating Bank and Bankr functionality
-- Handles accounts, transactions, transfers, analytics, budgets, recurring payments, and cards

-- Banking Script Adapter Interface
local BankingAdapter = {}

-- Initialize banking adapter based on framework and configuration
function BankingAdapter:Init()
    local bankingScript = Config.WalletApp.bankingScript or 'framework'
    
    if bankingScript ~= 'framework' and GetResourceState(bankingScript) == 'started' then
        self.type = bankingScript
    elseif GetResourceState('qb-banking') == 'started' then
        self.type = 'qb-banking'
    elseif GetResourceState('okokBanking') == 'started' then
        self.type = 'okokBanking'
    elseif GetResourceState('Renewed-Banking') == 'started' then
        self.type = 'Renewed-Banking'
    else
        self.type = 'framework' -- Use framework default
    end
    
    if Config.DebugMode then
        print('[Wallet] Banking adapter initialized:', self.type)
    end
end

-- Get all accounts for a player
function BankingAdapter:GetAccounts(source)
    local accounts = {}
    local identifier = Framework:GetIdentifier(source)
    
    if self.type == 'qb-banking' then
        -- QB-Banking integration
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            accounts = {
                {
                    id = 'checking',
                    name = 'Checking Account',
                    type = 'checking',
                    number = Player.PlayerData.citizenid .. '001',
                    balance = Player.PlayerData.money.bank or 0,
                    isActive = true,
                    cardNumber = '•••• •••• •••• ' .. string.sub(Player.PlayerData.citizenid, -4),
                    cardHolder = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                    expiry = '12/25',
                    cvv = '***'
                }
            }
            
            -- Add savings account if available
            if Player.PlayerData.metadata and Player.PlayerData.metadata.savings then
                table.insert(accounts, {
                    id = 'savings',
                    name = 'Savings Account',
                    type = 'savings',
                    number = Player.PlayerData.citizenid .. '002',
                    balance = Player.PlayerData.metadata.savings or 0,
                    isActive = true,
                    cardNumber = '•••• •••• •••• ' .. string.sub(Player.PlayerData.citizenid, -3),
                    cardHolder = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                    expiry = '12/25',
                    cvv = '***'
                })
            end
        end
    elseif self.type == 'okokBanking' then
        -- okokBanking integration
        local balance = exports['okokBanking']:GetAccount(source)
        if balance then
            accounts = {
                {
                    id = 'bank',
                    name = 'Bank Account',
                    type = 'checking',
                    number = identifier .. '001',
                    balance = balance,
                    isActive = true,
                    cardNumber = '•••• •••• •••• ' .. string.sub(identifier, -4),
                    cardHolder = 'Account Holder',
                    expiry = '12/25',
                    cvv = '***'
                }
            }
        end
    else
        -- Framework default
        local balance = Framework:GetPlayerMoney(source, Config.WalletApp.defaultAccount or 'bank')
        
        accounts = {
            {
                id = 'bank',
                name = 'Bank Account',
                type = 'checking',
                number = identifier .. '001',
                balance = balance or 0,
                isActive = true,
                cardNumber = '•••• •••• •••• ' .. string.sub(identifier, -4),
                cardHolder = 'LB PHONE',
                expiry = '12/25',
                cvv = '***'
            }
        }
    end
    
    return accounts
end

-- Get account balance
function BankingAdapter:GetBalance(source, accountId)
    if self.type == 'qb-banking' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            if accountId == 'savings' and Player.PlayerData.metadata then
                return Player.PlayerData.metadata.savings or 0
            end
            return Player.PlayerData.money.bank or 0
        end
    elseif self.type == 'okokBanking' then
        return exports['okokBanking']:GetAccount(source) or 0
    else
        return Framework:GetPlayerMoney(source, Config.WalletApp.defaultAccount or 'bank') or 0
    end
    
    return 0
end

-- Transfer money between accounts or to other players
function BankingAdapter:TransferMoney(source, fromAccount, toNumber, amount, description)
    local success = false
    local message = 'Transfer failed'
    local newBalance = 0
    
    -- Check sender balance
    local senderBalance = self:GetBalance(source, fromAccount)
    if senderBalance < amount then
        return {
            success = false,
            message = 'Insufficient funds',
            newBalance = senderBalance
        }
    end
    
    -- Remove money from sender
    if Framework:RemoveMoney(source, amount, Config.WalletApp.defaultAccount or 'bank') then
        -- Find target player
        local targetPlayer = MySQL.query.await('SELECT identifier FROM phone_players WHERE phone_number = ?', {toNumber})
        
        if targetPlayer and #targetPlayer > 0 then
            local targetIdentifier = targetPlayer[1].identifier
            local targetSource = nil
            
            -- Find online target player
            for _, playerId in ipairs(GetPlayers()) do
                local playerIdentifier = Framework:GetIdentifier(tonumber(playerId))
                if playerIdentifier == targetIdentifier then
                    targetSource = tonumber(playerId)
                    break
                end
            end
            
            -- Add money to target if online
            if targetSource then
                Framework:AddMoney(targetSource, amount, Config.WalletApp.defaultAccount or 'bank')
                
                -- Notify target player
                TriggerClientEvent('phone:client:receiveMoneyNotification', targetSource, {
                    amount = amount,
                    from = Framework:GetPhoneNumber(source),
                    description = description
                })
            end
            
            success = true
            message = 'Transfer successful'
            newBalance = Framework:GetPlayerMoney(source, Config.WalletApp.defaultAccount or 'bank')
        else
            -- Refund if target not found
            Framework:AddMoney(source, amount, Config.WalletApp.defaultAccount or 'bank')
            message = 'Phone number not found'
        end
    else
        message = 'Transfer failed'
    end
    
    return {
        success = success,
        message = message,
        newBalance = newBalance
    }
end

-- Initialize adapter
BankingAdapter:Init()

-- ============================================================================
-- WALLET DATA ENDPOINTS
-- ============================================================================

-- Get wallet accounts
RegisterNetEvent('phone:server:getWalletAccounts', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local accounts = BankingAdapter:GetAccounts(source)
    
    TriggerClientEvent('phone:client:receiveWalletAccounts', source, {
        success = true,
        accounts = accounts
    })
end)

-- Get wallet transactions
RegisterNetEvent('phone:server:getWalletTransactions', function(filters)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveWalletTransactions', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    local limit = filters and filters.limit or Config.WalletApp.transactionHistoryLimit or 100
    
    -- Get enhanced transaction history
    local transactions = MySQL.query.await([[
        SELECT 
            id,
            account_id,
            transaction_type,
            amount,
            description,
            category,
            recipient_number,
            UNIX_TIMESTAMP(created_at) * 1000 as timestamp
        FROM phone_bankr_transactions
        WHERE owner_number = ?
        ORDER BY created_at DESC
        LIMIT ?
    ]], {
        phoneNumber,
        limit
    })
    
    TriggerClientEvent('phone:client:receiveWalletTransactions', source, {
        success = true,
        transactions = transactions or {}
    })
end)

-- ============================================================================
-- TRANSFER OPERATIONS
-- ============================================================================

-- Create wallet transfer
RegisterNetEvent('phone:server:createWalletTransfer', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local fromAccount = data.fromAccount or 'bank'
    local toNumber = data.toNumber
    local amount = tonumber(data.amount)
    local description = data.description or 'Transfer'
    local category = data.category or 'transfer'
    
    -- Validation
    if not toNumber or not amount then
        TriggerClientEvent('phone:client:walletTransferResult', source, {
            success = false,
            message = 'Invalid transfer data'
        })
        return
    end
    
    if amount < (Config.WalletApp.minTransferAmount or 1) then
        TriggerClientEvent('phone:client:walletTransferResult', source, {
            success = false,
            message = _L('currency_below_minimum')
        })
        return
    end
    
    if amount > (Config.WalletApp.maxTransferAmount or 999999) then
        local maxFormatted = FormatCurrency(Config.WalletApp.maxTransferAmount or 999999)
        TriggerClientEvent('phone:client:walletTransferResult', source, {
            success = false,
            message = _L('currency_limit_exceeded', maxFormatted)
        })
        return
    end
    
    local senderNumber = Framework:GetPhoneNumber(source)
    if not senderNumber then
        TriggerClientEvent('phone:client:walletTransferResult', source, {
            success = false,
            message = 'Your phone number not found'
        })
        return
    end
    
    -- Check if trying to send to self
    if senderNumber == toNumber then
        TriggerClientEvent('phone:client:walletTransferResult', source, {
            success = false,
            message = 'Cannot transfer to yourself'
        })
        return
    end
    
    -- Validate target phone number exists
    local targetPlayer = MySQL.query.await('SELECT identifier FROM phone_players WHERE phone_number = ?', {toNumber})
    
    if not targetPlayer or #targetPlayer == 0 then
        TriggerClientEvent('phone:client:walletTransferResult', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Perform transfer using banking adapter
    local result = BankingAdapter:TransferMoney(source, fromAccount, toNumber, amount, description)
    
    if result.success then
        -- Log transaction for sender
        local transactionId = MySQL.insert.await([[
            INSERT INTO phone_bankr_transactions 
            (owner_number, account_id, transaction_type, amount, description, category, recipient_number) 
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], {
            senderNumber,
            fromAccount,
            'debit',
            amount,
            description,
            category,
            toNumber
        })
        
        -- Log transaction for recipient
        MySQL.insert([[
            INSERT INTO phone_bankr_transactions 
            (owner_number, account_id, transaction_type, amount, description, category, recipient_number) 
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], {
            toNumber,
            'bank',
            'credit',
            amount,
            description,
            category,
            senderNumber
        })
        
        -- Update budget if applicable
        if Config.WalletApp.enableBudgetTracking then
            UpdateBudgetSpending(senderNumber, category, amount)
        end
        
        TriggerClientEvent('phone:client:walletTransferResult', source, {
            success = true,
            amount = amount,
            toNumber = toNumber,
            newBalance = result.newBalance,
            transactionId = transactionId,
            description = description
        })
    else
        TriggerClientEvent('phone:client:walletTransferResult', source, {
            success = false,
            message = result.message
        })
    end
end)

-- ============================================================================
-- ANALYTICS OPERATIONS
-- ============================================================================

-- Get wallet analytics
RegisterNetEvent('phone:server:getWalletAnalytics', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveWalletAnalytics', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Get transactions for analytics
    local transactions = MySQL.query.await([[
        SELECT 
            transaction_type,
            amount,
            category,
            UNIX_TIMESTAMP(created_at) * 1000 as timestamp
        FROM phone_bankr_transactions
        WHERE owner_number = ?
        ORDER BY created_at DESC
        LIMIT 500
    ]], {phoneNumber})
    
    -- Calculate analytics
    local analytics = CalculateAnalytics(phoneNumber, transactions or {})
    
    TriggerClientEvent('phone:client:receiveWalletAnalytics', source, {
        success = true,
        analytics = analytics
    })
end)

-- Helper function to calculate analytics
function CalculateAnalytics(phoneNumber, transactions)
    local analytics = {
        spending = {
            thisWeek = 0,
            thisMonth = 0,
            thisQuarter = 0,
            thisYear = 0
        },
        categories = {},
        trends = {}
    }
    
    local now = os.time()
    local weekAgo = now - (7 * 24 * 60 * 60)
    local monthAgo = now - (30 * 24 * 60 * 60)
    local quarterAgo = now - (90 * 24 * 60 * 60)
    local yearAgo = now - (365 * 24 * 60 * 60)
    
    local categoryTotals = {}
    local totalSpent = 0
    local totalReceived = 0
    
    -- Calculate totals by category and time period
    for _, transaction in ipairs(transactions) do
        local transactionTime = transaction.timestamp / 1000
        
        if transaction.transaction_type == 'debit' then
            local amount = math.abs(transaction.amount)
            totalSpent = totalSpent + amount
            
            -- Time period calculations
            if transactionTime >= weekAgo then
                analytics.spending.thisWeek = analytics.spending.thisWeek + amount
            end
            if transactionTime >= monthAgo then
                analytics.spending.thisMonth = analytics.spending.thisMonth + amount
            end
            if transactionTime >= quarterAgo then
                analytics.spending.thisQuarter = analytics.spending.thisQuarter + amount
            end
            if transactionTime >= yearAgo then
                analytics.spending.thisYear = analytics.spending.thisYear + amount
            end
            
            -- Category totals
            local category = transaction.category or 'general'
            categoryTotals[category] = (categoryTotals[category] or 0) + amount
        elseif transaction.transaction_type == 'credit' then
            totalReceived = totalReceived + math.abs(transaction.amount)
        end
    end
    
    analytics.totalSpent = totalSpent
    analytics.totalReceived = totalReceived
    
    -- Convert categories to array with percentages
    for category, amount in pairs(categoryTotals) do
        local percentage = totalSpent > 0 and (amount / totalSpent) * 100 or 0
        table.insert(analytics.categories, {
            name = category,
            amount = amount,
            percentage = percentage
        })
    end
    
    -- Sort categories by amount
    table.sort(analytics.categories, function(a, b)
        return a.amount > b.amount
    end)
    
    return analytics
end

-- ============================================================================
-- BUDGET OPERATIONS
-- ============================================================================

-- Get wallet budgets
RegisterNetEvent('phone:server:getWalletBudgets', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveWalletBudgets', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Get budget data
    local budgets = MySQL.query.await([[
        SELECT 
            id,
            category,
            monthly_limit as limitAmount,
            current_spent as spent,
            UNIX_TIMESTAMP(period_start) * 1000 as periodStart,
            UNIX_TIMESTAMP(period_end) * 1000 as periodEnd,
            1 as isActive
        FROM phone_bankr_budgets
        WHERE owner_number = ?
        AND period_end > NOW()
        ORDER BY category ASC
    ]], {phoneNumber})
    
    TriggerClientEvent('phone:client:receiveWalletBudgets', source, {
        success = true,
        budgets = budgets or {}
    })
end)

-- Create wallet budget
RegisterNetEvent('phone:server:createWalletBudget', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    local category = data.category
    local limitAmount = tonumber(data.limitAmount)
    
    if not category or not limitAmount or limitAmount <= 0 then
        TriggerClientEvent('phone:client:walletBudgetResult', source, {
            success = false,
            message = 'Invalid budget data'
        })
        return
    end
    
    -- Calculate period start and end (current month)
    local now = os.time()
    local date = os.date('*t', now)
    local periodStart = os.time({
        year = date.year,
        month = date.month,
        day = 1,
        hour = 0,
        min = 0,
        sec = 0
    })
    
    -- Calculate next month
    local nextMonth = date.month + 1
    local nextYear = date.year
    if nextMonth > 12 then
        nextMonth = 1
        nextYear = nextYear + 1
    end
    
    local periodEnd = os.time({
        year = nextYear,
        month = nextMonth,
        day = 1,
        hour = 0,
        min = 0,
        sec = 0
    }) - 1
    
    -- Check if budget already exists for this period
    local existingBudget = MySQL.query.await([[
        SELECT id FROM phone_bankr_budgets
        WHERE owner_number = ? AND category = ?
        AND period_start <= FROM_UNIXTIME(?) AND period_end >= FROM_UNIXTIME(?)
    ]], {
        phoneNumber,
        category,
        now,
        now
    })
    
    local budgetId
    
    if existingBudget and #existingBudget > 0 then
        -- Update existing budget
        MySQL.update.await([[
            UPDATE phone_bankr_budgets
            SET monthly_limit = ?
            WHERE id = ?
        ]], {
            limitAmount,
            existingBudget[1].id
        })
        budgetId = existingBudget[1].id
    else
        -- Create new budget
        budgetId = MySQL.insert.await([[
            INSERT INTO phone_bankr_budgets 
            (owner_number, category, monthly_limit, current_spent, period_start, period_end) 
            VALUES (?, ?, ?, 0, FROM_UNIXTIME(?), FROM_UNIXTIME(?))
        ]], {
            phoneNumber,
            category,
            limitAmount,
            periodStart,
            periodEnd
        })
    end
    
    TriggerClientEvent('phone:client:walletBudgetResult', source, {
        success = true,
        message = 'Budget created successfully',
        budgetId = budgetId
    })
end)

-- Update wallet budget
RegisterNetEvent('phone:server:updateWalletBudget', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    local budgetId = data.budgetId
    local limitAmount = tonumber(data.limitAmount)
    
    if not budgetId or not limitAmount then
        TriggerClientEvent('phone:client:walletBudgetUpdateResult', source, {
            success = false,
            message = 'Invalid update data'
        })
        return
    end
    
    -- Verify budget ownership
    local budget = MySQL.query.await('SELECT id FROM phone_bankr_budgets WHERE id = ? AND owner_number = ?', {
        budgetId,
        phoneNumber
    })
    
    if not budget or #budget == 0 then
        TriggerClientEvent('phone:client:walletBudgetUpdateResult', source, {
            success = false,
            message = 'Budget not found'
        })
        return
    end
    
    -- Update budget
    MySQL.update.await('UPDATE phone_bankr_budgets SET monthly_limit = ? WHERE id = ?', {
        limitAmount,
        budgetId
    })
    
    TriggerClientEvent('phone:client:walletBudgetUpdateResult', source, {
        success = true,
        message = 'Budget updated successfully'
    })
end)

-- Delete wallet budget
RegisterNetEvent('phone:server:deleteWalletBudget', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    local budgetId = data.budgetId
    
    if not budgetId then
        TriggerClientEvent('phone:client:walletBudgetDeleteResult', source, {
            success = false,
            message = 'Invalid budget ID'
        })
        return
    end
    
    -- Delete budget
    MySQL.execute.await('DELETE FROM phone_bankr_budgets WHERE id = ? AND owner_number = ?', {
        budgetId,
        phoneNumber
    })
    
    TriggerClientEvent('phone:client:walletBudgetDeleteResult', source, {
        success = true,
        message = 'Budget deleted successfully'
    })
end)

-- Helper function to update budget spending
function UpdateBudgetSpending(phoneNumber, category, amount)
    MySQL.update.await([[
        UPDATE phone_bankr_budgets
        SET current_spent = current_spent + ?
        WHERE owner_number = ? AND category = ?
        AND period_end > NOW()
    ]], {
        amount,
        phoneNumber,
        category
    })
end

-- ============================================================================
-- RECURRING PAYMENTS OPERATIONS
-- ============================================================================

-- Get wallet recurring payments
RegisterNetEvent('phone:server:getWalletRecurringPayments', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveWalletRecurringPayments', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Get recurring payments
    local payments = MySQL.query.await([[
        SELECT 
            id,
            name,
            amount,
            frequency,
            recipient_number as recipientNumber,
            UNIX_TIMESTAMP(next_payment) * 1000 as nextPayment,
            is_active as isActive
        FROM phone_bankr_recurring
        WHERE owner_number = ?
        AND is_active = 1
        ORDER BY next_payment ASC
    ]], {phoneNumber})
    
    TriggerClientEvent('phone:client:receiveWalletRecurringPayments', source, {
        success = true,
        payments = payments or {}
    })
end)

-- Create wallet recurring payment
RegisterNetEvent('phone:server:createWalletRecurringPayment', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    local name = data.name
    local amount = tonumber(data.amount)
    local frequency = data.frequency -- 'weekly', 'monthly', 'quarterly'
    local recipientNumber = data.recipientNumber
    
    if not name or not amount or not frequency or not recipientNumber then
        TriggerClientEvent('phone:client:walletRecurringResult', source, {
            success = false,
            message = 'Invalid recurring payment data'
        })
        return
    end
    
    -- Calculate next payment date
    local now = os.time()
    local nextPayment = now
    
    if frequency == 'weekly' then
        nextPayment = now + (7 * 24 * 60 * 60)
    elseif frequency == 'monthly' then
        nextPayment = now + (30 * 24 * 60 * 60)
    elseif frequency == 'quarterly' then
        nextPayment = now + (90 * 24 * 60 * 60)
    end
    
    -- Validate recipient exists
    local targetPlayer = MySQL.query.await('SELECT identifier FROM phone_players WHERE phone_number = ?', {
        recipientNumber
    })
    
    if not targetPlayer or #targetPlayer == 0 then
        TriggerClientEvent('phone:client:walletRecurringResult', source, {
            success = false,
            message = 'Recipient phone number not found'
        })
        return
    end
    
    -- Create recurring payment
    local paymentId = MySQL.insert.await([[
        INSERT INTO phone_bankr_recurring 
        (owner_number, name, amount, frequency, recipient_number, next_payment, is_active) 
        VALUES (?, ?, ?, ?, ?, FROM_UNIXTIME(?), 1)
    ]], {
        phoneNumber,
        name,
        amount,
        frequency,
        recipientNumber,
        nextPayment
    })
    
    TriggerClientEvent('phone:client:walletRecurringResult', source, {
        success = true,
        message = 'Recurring payment created successfully',
        paymentId = paymentId
    })
end)

-- Delete wallet recurring payment
RegisterNetEvent('phone:server:deleteWalletRecurringPayment', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    local paymentId = data.paymentId
    
    if not paymentId then
        TriggerClientEvent('phone:client:walletRecurringDeleteResult', source, {
            success = false,
            message = 'Invalid payment ID'
        })
        return
    end
    
    -- Deactivate recurring payment
    MySQL.update.await('UPDATE phone_bankr_recurring SET is_active = 0 WHERE id = ? AND owner_number = ?', {
        paymentId,
        phoneNumber
    })
    
    TriggerClientEvent('phone:client:walletRecurringDeleteResult', source, {
        success = true,
        message = 'Recurring payment deleted successfully'
    })
end)

-- Process recurring payments (called by cron job)
function ProcessRecurringPayments()
    local recurringPayments = MySQL.query.await([[
        SELECT 
            id, owner_number, name, amount, frequency, recipient_number, next_payment
        FROM phone_bankr_recurring
        WHERE is_active = 1 AND next_payment <= NOW()
    ]])
    
    if not recurringPayments then
        return
    end
    
    for _, payment in ipairs(recurringPayments) do
        -- Find player source
        local playerSource = nil
        local phoneNumber = payment.owner_number
        
        -- Get player by phone number
        local playerData = MySQL.query.await('SELECT identifier FROM phone_players WHERE phone_number = ?', {
            phoneNumber
        })
        
        if playerData and #playerData > 0 then
            local identifier = playerData[1].identifier
            
            -- Find online player
            for _, playerId in ipairs(GetPlayers()) do
                local playerIdentifier = Framework:GetIdentifier(tonumber(playerId))
                if playerIdentifier == identifier then
                    playerSource = tonumber(playerId)
                    break
                end
            end
        end
        
        if playerSource then
            -- Process payment
            local result = BankingAdapter:TransferMoney(
                playerSource, 
                'bank', 
                payment.recipient_number, 
                payment.amount, 
                'Recurring: ' .. payment.name
            )
            
            if result.success then
                -- Log transaction
                MySQL.insert([[
                    INSERT INTO phone_bankr_transactions 
                    (owner_number, account_id, transaction_type, amount, description, category, recipient_number) 
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                ]], {
                    phoneNumber,
                    'bank',
                    'debit',
                    payment.amount,
                    'Recurring: ' .. payment.name,
                    'recurring',
                    payment.recipient_number
                })
                
                -- Update next payment date
                local nextPayment = os.time()
                if payment.frequency == 'weekly' then
                    nextPayment = nextPayment + (7 * 24 * 60 * 60)
                elseif payment.frequency == 'monthly' then
                    nextPayment = nextPayment + (30 * 24 * 60 * 60)
                elseif payment.frequency == 'quarterly' then
                    nextPayment = nextPayment + (90 * 24 * 60 * 60)
                end
                
                MySQL.update.await([[
                    UPDATE phone_bankr_recurring
                    SET next_payment = FROM_UNIXTIME(?)
                    WHERE id = ?
                ]], {
                    nextPayment,
                    payment.id
                })
                
                -- Notify player
                TriggerClientEvent('phone:client:recurringPaymentProcessed', playerSource, {
                    name = payment.name,
                    amount = payment.amount,
                    recipient = payment.recipient_number
                })
            else
                -- Payment failed, notify player
                TriggerClientEvent('phone:client:recurringPaymentFailed', playerSource, {
                    name = payment.name,
                    amount = payment.amount,
                    reason = result.message
                })
            end
        end
    end
end

-- Set up recurring payment processing (every 5 minutes)
if Config.WalletApp.enableRecurringPayments then
    CreateThread(function()
        while true do
            Wait(300000) -- 5 minutes
            ProcessRecurringPayments()
        end
    end)
end

-- ============================================================================
-- USER SETTINGS OPERATIONS
-- ============================================================================

-- Get wallet user settings
RegisterNetEvent('phone:server:getWalletUserSettings', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveWalletUserSettings', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Get settings from phone_settings table
    local settings = MySQL.query.await([[
        SELECT settings_json
        FROM phone_settings
        WHERE phone_number = ?
    ]], {phoneNumber})
    
    local userSettings = {
        theme = {
            mode = 'auto',
            accentColor = '#007AFF'
        },
        notifications = {
            transfers = true,
            budgets = true,
            security = true,
            marketing = false
        },
        security = {
            pinEnabled = false,
            biometricEnabled = false,
            sessionTimeout = 15
        }
    }
    
    local customization = {
        wallpaper = 'default',
        ringtone = 'default',
        hapticFeedback = true,
        animations = true
    }
    
    -- Parse existing settings if available
    if settings and #settings > 0 and settings[1].settings_json then
        local decoded = json.decode(settings[1].settings_json)
        if decoded then
            if decoded.wallet then
                userSettings = decoded.wallet.settings or userSettings
                customization = decoded.wallet.customization or customization
            end
        end
    end
    
    TriggerClientEvent('phone:client:receiveWalletUserSettings', source, {
        success = true,
        settings = userSettings,
        customization = customization
    })
end)

-- Update wallet user settings
RegisterNetEvent('phone:server:updateWalletUserSettings', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    -- Get existing settings
    local existingSettings = MySQL.query.await('SELECT settings_json FROM phone_settings WHERE phone_number = ?', {
        phoneNumber
    })
    
    local settingsData = {}
    
    if existingSettings and #existingSettings > 0 and existingSettings[1].settings_json then
        settingsData = json.decode(existingSettings[1].settings_json) or {}
    end
    
    -- Update wallet settings
    if not settingsData.wallet then
        settingsData.wallet = {}
    end
    
    settingsData.wallet.settings = data
    
    -- Save to database
    MySQL.execute.await([[
        INSERT INTO phone_settings (phone_number, settings_json)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE settings_json = ?
    ]], {
        phoneNumber,
        json.encode(settingsData),
        json.encode(settingsData)
    })
    
    TriggerClientEvent('phone:client:walletSettingsUpdateResult', source, {
        success = true,
        message = 'Settings updated successfully'
    })
end)

-- Update wallet theme
RegisterNetEvent('phone:server:updateWalletTheme', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    -- Get existing settings
    local existingSettings = MySQL.query.await('SELECT settings_json FROM phone_settings WHERE phone_number = ?', {
        phoneNumber
    })
    
    local settingsData = {}
    
    if existingSettings and #existingSettings > 0 and existingSettings[1].settings_json then
        settingsData = json.decode(existingSettings[1].settings_json) or {}
    end
    
    -- Update wallet theme
    if not settingsData.wallet then
        settingsData.wallet = {}
    end
    if not settingsData.wallet.settings then
        settingsData.wallet.settings = {}
    end
    
    settingsData.wallet.settings.theme = data
    
    -- Save to database
    MySQL.execute.await([[
        INSERT INTO phone_settings (phone_number, settings_json)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE settings_json = ?
    ]], {
        phoneNumber,
        json.encode(settingsData),
        json.encode(settingsData)
    })
    
    TriggerClientEvent('phone:client:walletThemeUpdateResult', source, {
        success = true,
        message = 'Theme updated successfully'
    })
end)

-- Update wallet customization
RegisterNetEvent('phone:server:updateWalletCustomization', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        return
    end
    
    -- Get existing settings
    local existingSettings = MySQL.query.await('SELECT settings_json FROM phone_settings WHERE phone_number = ?', {
        phoneNumber
    })
    
    local settingsData = {}
    
    if existingSettings and #existingSettings > 0 and existingSettings[1].settings_json then
        settingsData = json.decode(existingSettings[1].settings_json) or {}
    end
    
    -- Update wallet customization
    if not settingsData.wallet then
        settingsData.wallet = {}
    end
    
    settingsData.wallet.customization = data
    
    -- Save to database
    MySQL.execute.await([[
        INSERT INTO phone_settings (phone_number, settings_json)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE settings_json = ?
    ]], {
        phoneNumber,
        json.encode(settingsData),
        json.encode(settingsData)
    })
    
    TriggerClientEvent('phone:client:walletCustomizationUpdateResult', source, {
        success = true,
        message = 'Customization updated successfully'
    })
end)

-- ============================================================================
-- CARDS OPERATIONS
-- ============================================================================

-- Get wallet cards
RegisterNetEvent('phone:server:getWalletCards', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local phoneNumber = Framework:GetPhoneNumber(source)
    if not phoneNumber then
        TriggerClientEvent('phone:client:receiveWalletCards', source, {
            success = false,
            message = 'Phone number not found'
        })
        return
    end
    
    -- Get accounts and format as cards
    local accounts = BankingAdapter:GetAccounts(source)
    local cards = {}
    
    for _, account in ipairs(accounts) do
        table.insert(cards, {
            id = account.id,
            type = account.type == 'savings' and 'savings' or 'debit',
            number = account.cardNumber,
            holder = account.cardHolder,
            expiry = account.expiry,
            cvv = account.cvv,
            isActive = account.isActive,
            dailyLimit = 5000,
            monthlyLimit = 50000,
            spentToday = 0,
            spentThisMonth = 0
        })
    end
    
    TriggerClientEvent('phone:client:receiveWalletCards', source, {
        success = true,
        cards = cards
    })
end)

-- Add wallet card (placeholder for future implementation)
RegisterNetEvent('phone:server:addWalletCard', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    TriggerClientEvent('phone:client:walletCardAddResult', source, {
        success = false,
        message = 'Card management not yet implemented'
    })
end)

-- Update wallet card (placeholder for future implementation)
RegisterNetEvent('phone:server:updateWalletCard', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    TriggerClientEvent('phone:client:walletCardUpdateResult', source, {
        success = false,
        message = 'Card management not yet implemented'
    })
end)

-- Remove wallet card (placeholder for future implementation)
RegisterNetEvent('phone:server:removeWalletCard', function(data)
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    TriggerClientEvent('phone:client:walletCardRemoveResult', source, {
        success = false,
        message = 'Card management not yet implemented'
    })
end)

-- ============================================================================
-- BACKWARD COMPATIBILITY EVENTS
-- ============================================================================

-- Legacy bank balance event (for backward compatibility)
RegisterNetEvent('phone:server:getBankBalance', function()
    local source = source
    
    if not Framework:PlayerExists(source) then
        return
    end
    
    local balance = Framework:GetPlayerMoney(source, Config.WalletApp.defaultAccount or 'bank')
    
    TriggerClientEvent('phone:client:receiveBankBalance', source, {
        success = true,
        balance = balance or 0
    })
end)

-- Legacy bank data event (for backward compatibility)
RegisterNetEvent('phone:server:getBankData', function()
    -- Redirect to wallet accounts
    TriggerEvent('phone:server:getWalletAccounts')
end)

-- Legacy transfer event (for backward compatibility)
RegisterNetEvent('phone:server:transferMoney', function(data)
    -- Redirect to wallet transfer
    TriggerEvent('phone:server:createWalletTransfer', data)
end)

if Config.DebugMode then
    print('[Phone] Wallet app server loaded successfully')
    print('[Phone] Banking adapter type:', BankingAdapter.type)
end
