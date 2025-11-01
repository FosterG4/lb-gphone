-- Client NUI Callbacks
-- Handles communication between NUI and client Lua

-- NUI Callback: Close phone
RegisterNUICallback('closePhone', function(data, cb)
    ClosePhone()
    cb({ success = true })
end)

-- NUI Callback: Get config
RegisterNUICallback('getConfig', function(data, cb)
    cb({
        success = true,
        config = {
            enabledApps = Config.EnabledApps,
            theme = Config.UI.theme,
            notificationDuration = Config.NotificationDuration
        }
    })
end)

-- Contact Management Callbacks

-- Get contacts
RegisterNUICallback('getContacts', function(data, cb)
    TriggerServerEvent('phone:server:getContacts')
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local contactsData = {}
    
    local function onReceiveContacts(contacts)
        contactsData = contacts
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveContacts', onReceiveContacts)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb({ success = true, contacts = contactsData })
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Add contact
RegisterNUICallback('addContact', function(data, cb)
    if not data.name or not data.number then
        cb({ success = false, message = 'Name and number are required' })
        return
    end
    
    TriggerServerEvent('phone:server:addContact', {
        name = data.name,
        number = data.number
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onOperationResult(result)
        if result.operation == 'add' then
            resultData = result
            responseReceived = true
        end
    end
    
    local eventHandler = AddEventHandler('phone:client:contactOperationResult', onOperationResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Edit contact
RegisterNUICallback('editContact', function(data, cb)
    if not data.id or not data.name or not data.number then
        cb({ success = false, message = 'ID, name and number are required' })
        return
    end
    
    TriggerServerEvent('phone:server:editContact', {
        id = data.id,
        name = data.name,
        number = data.number
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onOperationResult(result)
        if result.operation == 'edit' then
            resultData = result
            responseReceived = true
        end
    end
    
    local eventHandler = AddEventHandler('phone:client:contactOperationResult', onOperationResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Delete contact
RegisterNUICallback('deleteContact', function(data, cb)
    if not data.id then
        cb({ success = false, message = 'Contact ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:deleteContact', {
        id = data.id
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onOperationResult(result)
        if result.operation == 'delete' then
            resultData = result
            responseReceived = true
        end
    end
    
    local eventHandler = AddEventHandler('phone:client:contactOperationResult', onOperationResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Message Management Callbacks

-- Get messages
RegisterNUICallback('getMessages', function(data, cb)
    TriggerServerEvent('phone:server:getMessages')
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local messagesData = {}
    
    local function onReceiveMessages(messages)
        messagesData = messages
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveMessages', onReceiveMessages)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb({ success = true, messages = messagesData })
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Send message
RegisterNUICallback('sendMessage', function(data, cb)
    if not data.targetNumber or not data.message then
        cb({ success = false, message = 'Target number and message are required' })
        return
    end
    
    TriggerServerEvent('phone:server:sendMessage', {
        targetNumber = data.targetNumber,
        message = data.message
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onOperationResult(result)
        if result.operation == 'send' then
            resultData = result
            responseReceived = true
        end
    end
    
    local eventHandler = AddEventHandler('phone:client:messageOperationResult', onOperationResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Mark messages as read
RegisterNUICallback('markMessagesRead', function(data, cb)
    if not data.phoneNumber then
        cb({ success = false, message = 'Phone number is required' })
        return
    end
    
    TriggerServerEvent('phone:server:markMessagesRead', {
        phoneNumber = data.phoneNumber
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onOperationResult(result)
        if result.operation == 'markRead' then
            resultData = result
            responseReceived = true
        end
    end
    
    local eventHandler = AddEventHandler('phone:client:messageOperationResult', onOperationResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Call Management Callbacks

-- Initiate call
RegisterNUICallback('initiateCall', function(data, cb)
    if not data.phoneNumber then
        cb({ success = false, message = 'Phone number is required' })
        return
    end
    
    -- Check if already in a call
    local callState = GetCallState()
    if callState ~= 'idle' then
        cb({ success = false, message = 'Already in a call' })
        return
    end
    
    TriggerServerEvent('phone:server:initiateCall', {
        targetNumber = data.phoneNumber
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onCallInitiated(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:callInitiated', onCallInitiated)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Accept call
RegisterNUICallback('acceptCall', function(data, cb)
    local currentCall = GetCurrentCall()
    
    if not currentCall then
        cb({ success = false, message = 'No incoming call' })
        return
    end
    
    TriggerServerEvent('phone:server:acceptCall', {
        callerId = currentCall.callerId
    })
    
    cb({ success = true })
end)

-- End call
RegisterNUICallback('endCall', function(data, cb)
    local currentCall = GetCurrentCall()
    
    if not currentCall then
        cb({ success = false, message = 'No active call' })
        return
    end
    
    TriggerServerEvent('phone:server:endCall', {
        callerId = currentCall.callerId
    })
    
    cb({ success = true })
end)

-- Get call history
RegisterNUICallback('getCallHistory', function(data, cb)
    TriggerServerEvent('phone:server:getCallHistory')
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local historyData = {}
    
    local function onReceiveHistory(history)
        historyData = history
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveCallHistory', onReceiveHistory)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb({ success = true, history = historyData })
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Bank App Callbacks

-- Get bank data (balance + transactions)
RegisterNUICallback('getBankData', function(data, cb)
    TriggerServerEvent('phone:server:getBankData')
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local bankData = {}
    
    local function onReceiveBankData(result)
        bankData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveBankData', onReceiveBankData)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(bankData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Transfer money
RegisterNUICallback('transferMoney', function(data, cb)
    if not data.targetNumber or not data.amount then
        cb({ success = false, message = 'Target number and amount are required' })
        return
    end
    
    TriggerServerEvent('phone:server:transferMoney', {
        targetNumber = data.targetNumber,
        amount = data.amount
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onTransferResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:transferResult', onTransferResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Handle incoming money notification
RegisterNetEvent('phone:client:receiveMoneyNotification', function(data)
    if not data or not data.amount or not data.from then
        return
    end
    
    -- Show bank notification
    ShowBankNotification(
        'Money Received',
        string.format('You received $%d from %s', data.amount, data.from)
    )
end)

-- ============================================================================
-- Wallet App Callbacks (Unified Banking Solution)
-- ============================================================================

-- Get wallet accounts
RegisterNUICallback('getWalletAccounts', function(data, cb)
    TriggerServerEvent('phone:server:getWalletAccounts')
    
    local timeout = 0
    local responseReceived = false
    local accountsData = {}
    
    local function onReceiveAccounts(result)
        accountsData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveWalletAccounts', onReceiveAccounts)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(accountsData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Get wallet transactions
RegisterNUICallback('getWalletTransactions', function(data, cb)
    TriggerServerEvent('phone:server:getWalletTransactions', data or {})
    
    local timeout = 0
    local responseReceived = false
    local transactionsData = {}
    
    local function onReceiveTransactions(result)
        transactionsData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveWalletTransactions', onReceiveTransactions)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(transactionsData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Create wallet transfer
RegisterNUICallback('createWalletTransfer', function(data, cb)
    if not data.toNumber or not data.amount then
        cb({ success = false, message = 'Recipient and amount are required' })
        return
    end
    
    TriggerServerEvent('phone:server:createWalletTransfer', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onTransferResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:walletTransferResult', onTransferResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Get wallet analytics
RegisterNUICallback('getWalletAnalytics', function(data, cb)
    TriggerServerEvent('phone:server:getWalletAnalytics')
    
    local timeout = 0
    local responseReceived = false
    local analyticsData = {}
    
    local function onReceiveAnalytics(result)
        analyticsData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveWalletAnalytics', onReceiveAnalytics)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(analyticsData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Get wallet budgets
RegisterNUICallback('getWalletBudgets', function(data, cb)
    TriggerServerEvent('phone:server:getWalletBudgets')
    
    local timeout = 0
    local responseReceived = false
    local budgetsData = {}
    
    local function onReceiveBudgets(result)
        budgetsData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveWalletBudgets', onReceiveBudgets)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(budgetsData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Create wallet budget
RegisterNUICallback('createWalletBudget', function(data, cb)
    if not data.category or not data.limitAmount then
        cb({ success = false, message = 'Category and limit amount are required' })
        return
    end
    
    TriggerServerEvent('phone:server:createWalletBudget', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onBudgetResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:walletBudgetResult', onBudgetResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Update wallet budget
RegisterNUICallback('updateWalletBudget', function(data, cb)
    if not data.budgetId then
        cb({ success = false, message = 'Budget ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:updateWalletBudget', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onUpdateResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:walletBudgetUpdateResult', onUpdateResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Delete wallet budget
RegisterNUICallback('deleteWalletBudget', function(data, cb)
    if not data.budgetId then
        cb({ success = false, message = 'Budget ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:deleteWalletBudget', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onDeleteResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:walletBudgetDeleteResult', onDeleteResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Get wallet recurring payments
RegisterNUICallback('getWalletRecurringPayments', function(data, cb)
    TriggerServerEvent('phone:server:getWalletRecurringPayments')
    
    local timeout = 0
    local responseReceived = false
    local paymentsData = {}
    
    local function onReceivePayments(result)
        paymentsData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveWalletRecurringPayments', onReceivePayments)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(paymentsData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Create wallet recurring payment
RegisterNUICallback('createWalletRecurringPayment', function(data, cb)
    if not data.name or not data.amount or not data.frequency or not data.recipientNumber then
        cb({ success = false, message = 'All fields are required' })
        return
    end
    
    TriggerServerEvent('phone:server:createWalletRecurringPayment', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onRecurringResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:walletRecurringResult', onRecurringResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Delete wallet recurring payment
RegisterNUICallback('deleteWalletRecurringPayment', function(data, cb)
    if not data.paymentId then
        cb({ success = false, message = 'Payment ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:deleteWalletRecurringPayment', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onDeleteResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:walletRecurringDeleteResult', onDeleteResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Get wallet user settings
RegisterNUICallback('getWalletUserSettings', function(data, cb)
    TriggerServerEvent('phone:server:getWalletUserSettings')
    
    local timeout = 0
    local responseReceived = false
    local settingsData = {}
    
    local function onReceiveSettings(result)
        settingsData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveWalletUserSettings', onReceiveSettings)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(settingsData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Update wallet user settings
RegisterNUICallback('updateWalletUserSettings', function(data, cb)
    TriggerServerEvent('phone:server:updateWalletUserSettings', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onUpdateResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:walletSettingsUpdateResult', onUpdateResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Update wallet theme
RegisterNUICallback('updateWalletTheme', function(data, cb)
    TriggerServerEvent('phone:server:updateWalletTheme', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onUpdateResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:walletThemeUpdateResult', onUpdateResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Update wallet customization
RegisterNUICallback('updateWalletCustomization', function(data, cb)
    TriggerServerEvent('phone:server:updateWalletCustomization', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onUpdateResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:walletCustomizationUpdateResult', onUpdateResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Get wallet cards
RegisterNUICallback('getWalletCards', function(data, cb)
    TriggerServerEvent('phone:server:getWalletCards')
    
    local timeout = 0
    local responseReceived = false
    local cardsData = {}
    
    local function onReceiveCards(result)
        cardsData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveWalletCards', onReceiveCards)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(cardsData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Add wallet card
RegisterNUICallback('addWalletCard', function(data, cb)
    TriggerServerEvent('phone:server:addWalletCard', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onAddResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:walletCardAddResult', onAddResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Update wallet card
RegisterNUICallback('updateWalletCard', function(data, cb)
    TriggerServerEvent('phone:server:updateWalletCard', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onUpdateResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:walletCardUpdateResult', onUpdateResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Remove wallet card
RegisterNUICallback('removeWalletCard', function(data, cb)
    TriggerServerEvent('phone:server:removeWalletCard', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onRemoveResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:walletCardRemoveResult', onRemoveResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Twitter App Callbacks

-- Get chirper feed
RegisterNUICallback('getChirperFeed', function(data, cb)
    TriggerServerEvent('phone:server:getChirperFeed')
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local feedData = {}
    
    local function onReceiveFeed(result)
        feedData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveChirperFeed', onReceiveFeed)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(feedData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Post chirp
RegisterNUICallback('postChirp', function(data, cb)
    if not data.content then
        cb({ success = false, message = 'Content is required' })
        return
    end
    
    TriggerServerEvent('phone:server:postChirp', {
        content = data.content
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onPostResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:postChirpResult', onPostResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Like chirp
RegisterNUICallback('likeChirp', function(data, cb)
    if not data.chirpId then
        cb({ success = false, message = 'Chirp ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:likeChirp', {
        chirpId = data.chirpId
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onLikeResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:likeChirpResult', onLikeResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Handle new chirp broadcast
RegisterNetEvent('phone:client:newChirp', function(chirp)
    if not chirp then
        return
    end
    
    -- Send to NUI to update feed
    SendNUIMessage({
        action = 'newChirp',
        data = chirp
    })
end)

-- Handle chirp like update broadcast
RegisterNetEvent('phone:client:chirpLikeUpdate', function(data)
    if not data or not data.chirpId then
        return
    end
    
    -- Send to NUI to update like count
    SendNUIMessage({
        action = 'chirpLikeUpdate',
        data = data
    })
end)

-- Crypto App Callbacks

-- Get crypto data (portfolio + prices)
RegisterNUICallback('getCryptoData', function(data, cb)
    TriggerServerEvent('phone:server:getCryptoData')
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local cryptoData = {}
    
    local function onReceiveCryptoData(result)
        cryptoData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveCryptoData', onReceiveCryptoData)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(cryptoData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Trade cryptocurrency (buy/sell)
RegisterNUICallback('tradeCrypto', function(data, cb)
    if not data.cryptoType or not data.amount or not data.action then
        cb({ success = false, message = 'Crypto type, amount and action are required' })
        return
    end
    
    TriggerServerEvent('phone:server:tradeCrypto', {
        cryptoType = data.cryptoType,
        amount = data.amount,
        action = data.action
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onTradeResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:tradeResult', onTradeResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Handle crypto price updates
RegisterNetEvent('phone:client:updateCryptoPrices', function(prices)
    if not prices then
        return
    end
    
    -- Send to NUI to update prices
    SendNUIMessage({
        action = 'updateCryptoPrices',
        data = prices
    })
end)

-- Placeholder for additional NUI callbacks
-- These will be implemented in subsequent tasks


-- Camera App Callbacks

-- Capture photo
RegisterNUICallback('capturePhoto', function(data, cb)
    local Camera = require('client.media.camera')
    
    -- Set filter if provided
    if data.filter then
        Camera.SetFilter(data.filter)
    end
    
    -- Enable flash if requested
    if data.flash then
        Camera.EnableFlash()
    end
    
    -- Capture and upload photo
    local success = Camera.CaptureAndUpload()
    
    cb({ success = success })
end)

-- Set camera filter
RegisterNUICallback('setFilter', function(data, cb)
    local Camera = require('client.media.camera')
    
    if data.filter then
        local success = Camera.SetFilter(data.filter)
        cb({ success = success })
    else
        cb({ success = false, message = 'Filter not specified' })
    end
end)

-- Get camera status
RegisterNUICallback('getCameraStatus', function(data, cb)
    local Camera = require('client.media.camera')
    local status = Camera.GetStatus()
    cb(status)
end)

-- Video Recording Callbacks

-- Start video recording
RegisterNUICallback('startVideoRecording', function(data, cb)
    local Video = require('client.media.video')
    
    if Video.IsRecording() then
        cb({ success = false, error = 'Already recording' })
        return
    end
    
    local success = Video.StartRecording()
    cb({ success = success })
end)

-- Stop video recording
RegisterNUICallback('stopVideoRecording', function(data, cb)
    local Video = require('client.media.video')
    
    if not Video.IsRecording() then
        cb({ success = false, error = 'Not recording' })
        return
    end
    
    local success = Video.StopRecording()
    cb({ success = success })
end)

-- Cancel video recording
RegisterNUICallback('cancelVideoRecording', function(data, cb)
    local Video = require('client.media.video')
    local success = Video.CancelRecording()
    cb({ success = success })
end)

-- Get recording status
RegisterNUICallback('getRecordingStatus', function(data, cb)
    local Video = require('client.media.video')
    local status = Video.GetStatus()
    cb(status)
end)

-- Media Management Callbacks

-- Get media (photos, videos, audio)
RegisterNUICallback('getMedia', function(data, cb)
    local mediaType = data.mediaType or nil
    local limit = data.limit or 20
    local offset = data.offset or 0
    
    TriggerServerEvent('phone:server:getMedia', {
        mediaType = mediaType,
        limit = limit,
        offset = offset
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local mediaData = {}
    
    local function onReceiveMedia(result)
        mediaData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveMedia', onReceiveMedia)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(mediaData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Delete media
RegisterNUICallback('deleteMedia', function(data, cb)
    if not data.mediaId then
        cb({ success = false, message = 'Media ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:deleteMedia', {
        mediaId = data.mediaId,
        mediaType = data.mediaType
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onDeleteResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:mediaDeleteResult', onDeleteResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Album Management Callbacks

-- Get albums
RegisterNUICallback('getAlbums', function(data, cb)
    TriggerServerEvent('phone:server:getAlbums')
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local albumsData = {}
    
    local function onReceiveAlbums(result)
        albumsData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveAlbums', onReceiveAlbums)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(albumsData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Create album
RegisterNUICallback('createAlbum', function(data, cb)
    if not data.name then
        cb({ success = false, message = 'Album name is required' })
        return
    end
    
    TriggerServerEvent('phone:server:createAlbum', {
        name = data.name,
        coverMediaId = data.coverMediaId
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onCreateResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:albumCreateResult', onCreateResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Update album
RegisterNUICallback('updateAlbum', function(data, cb)
    if not data.albumId then
        cb({ success = false, message = 'Album ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:updateAlbum', {
        albumId = data.albumId,
        updates = data.updates
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onUpdateResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:albumUpdateResult', onUpdateResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Delete album
RegisterNUICallback('deleteAlbum', function(data, cb)
    if not data.albumId then
        cb({ success = false, message = 'Album ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:deleteAlbum', {
        albumId = data.albumId
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onDeleteResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:albumDeleteResult', onDeleteResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Client event handlers for media

-- Photo uploaded successfully
RegisterNetEvent('phone:client:photoUploaded', function(photoData)
    SendNUIMessage({
        action = 'photoUploaded',
        data = photoData
    })
end)

-- Video uploaded successfully
RegisterNetEvent('phone:client:videoUploaded', function(videoData)
    SendNUIMessage({
        action = 'videoUploaded',
        data = videoData
    })
end)

-- Media list received
RegisterNetEvent('phone:client:receiveMedia', function(mediaData)
    SendNUIMessage({
        action = 'receiveMedia',
        data = mediaData
    })
end)

-- Media updated
RegisterNetEvent('phone:client:updateMedia', function(mediaData)
    SendNUIMessage({
        action = 'updateMedia',
        data = mediaData
    })
end)

-- Add media to album
RegisterNUICallback('addMediaToAlbum', function(data, cb)
    if not data.albumId or not data.mediaIds then
        cb({ success = false, message = 'Album ID and media IDs are required' })
        return
    end
    
    TriggerServerEvent('phone:server:addMediaToAlbum', {
        albumId = data.albumId,
        mediaIds = data.mediaIds
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:albumMediaResult', onResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Remove media from album
RegisterNUICallback('removeMediaFromAlbum', function(data, cb)
    if not data.albumId or not data.mediaIds then
        cb({ success = false, message = 'Album ID and media IDs are required' })
        return
    end
    
    TriggerServerEvent('phone:server:removeMediaFromAlbum', {
        albumId = data.albumId,
        mediaIds = data.mediaIds
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:albumMediaResult', onResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Get album media
RegisterNUICallback('getAlbumMedia', function(data, cb)
    if not data.albumId then
        cb({ success = false, message = 'Album ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:getAlbumMedia', {
        albumId = data.albumId,
        limit = data.limit or 20,
        offset = data.offset or 0
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveAlbumMedia', onResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Set album cover
RegisterNUICallback('setAlbumCover', function(data, cb)
    if not data.albumId then
        cb({ success = false, message = 'Album ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:setAlbumCover', {
        albumId = data.albumId,
        mediaId = data.mediaId
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:albumCoverResult', onResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)


-- Share media to app
RegisterNUICallback('shareMedia', function(data, cb)
    if not data.mediaId or not data.targetApp then
        cb({ success = false, message = 'Media ID and target app are required' })
        return
    end
    
    TriggerServerEvent('phone:server:shareMedia', {
        mediaId = data.mediaId,
        targetApp = data.targetApp,
        caption = data.caption,
        effects = data.effects,
        targetNumber = data.targetNumber
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:shareMediaResult', onResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)


-- Bulk delete media
RegisterNUICallback('bulkDeleteMedia', function(data, cb)
    if not data.mediaIds or type(data.mediaIds) ~= 'table' then
        cb({ success = false, message = 'Media IDs array is required' })
        return
    end
    
    TriggerServerEvent('phone:server:bulkDeleteMedia', {
        mediaIds = data.mediaIds
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:bulkDeleteResult', onResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)


-- Clock App Callbacks

-- Get alarms
RegisterNUICallback('getAlarms', function(data, cb)
    TriggerServerEvent('phone:server:getAlarms')
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onReceiveAlarms(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveAlarms', onReceiveAlarms)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Create alarm
RegisterNUICallback('createAlarm', function(data, cb)
    if not data.time then
        cb({ success = false, message = 'Time is required' })
        return
    end
    
    TriggerServerEvent('phone:server:createAlarm', {
        time = data.time,
        label = data.label,
        days = data.days,
        sound = data.sound
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onAlarmCreated(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:alarmCreated', onAlarmCreated)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Update alarm
RegisterNUICallback('updateAlarm', function(data, cb)
    if not data.alarmId or not data.time then
        cb({ success = false, message = 'Alarm ID and time are required' })
        return
    end
    
    TriggerServerEvent('phone:server:updateAlarm', {
        alarmId = data.alarmId,
        time = data.time,
        label = data.label,
        days = data.days,
        sound = data.sound
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onAlarmUpdated(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:alarmUpdated', onAlarmUpdated)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Toggle alarm
RegisterNUICallback('toggleAlarm', function(data, cb)
    if not data.alarmId then
        cb({ success = false, message = 'Alarm ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:toggleAlarm', {
        alarmId = data.alarmId,
        enabled = data.enabled
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onAlarmToggled(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:alarmToggled', onAlarmToggled)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Delete alarm
RegisterNUICallback('deleteAlarm', function(data, cb)
    if not data.alarmId then
        cb({ success = false, message = 'Alarm ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:deleteAlarm', {
        alarmId = data.alarmId
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onAlarmDeleted(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:alarmDeleted', onAlarmDeleted)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Timer complete
RegisterNUICallback('timerComplete', function(data, cb)
    TriggerServerEvent('phone:server:timerComplete')
    cb({ success = true })
end)

-- Handle alarm triggered event
RegisterNetEvent('phone:client:alarmTriggered', function(alarm)
    -- Play alarm sound
    PlaySound(-1, alarm.sound or 'default', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', 0, 0, 1)
    
    -- Send notification to NUI
    SendNUIMessage({
        action = 'notification',
        data = {
            app = 'clock',
            title = 'Alarm',
            message = alarm.label or 'Alarm',
            icon = 'clock',
            sound = true
        }
    })
    
    -- Show in-game notification
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName('Alarm: ' .. (alarm.label or 'Alarm'))
    EndTextCommandThefeedPostTicker(false, true)
end)


-- Notes App Callbacks

-- Get notes
RegisterNUICallback('getNotes', function(data, cb)
    TriggerServerEvent('phone:server:getNotes')
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onReceiveNotes(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveNotes', onReceiveNotes)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Save note (create or update)
RegisterNUICallback('saveNote', function(data, cb)
    if not data.content then
        cb({ success = false, message = 'Content is required' })
        return
    end
    
    TriggerServerEvent('phone:server:saveNote', {
        noteId = data.noteId,
        title = data.title,
        content = data.content
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onNoteSaved(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:noteSaved', onNoteSaved)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Delete note
RegisterNUICallback('deleteNote', function(data, cb)
    if not data.noteId then
        cb({ success = false, message = 'Note ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:deleteNote', {
        noteId = data.noteId
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onNoteDeleted(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:noteDeleted', onNoteDeleted)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)


-- Weather App Callbacks

-- Get weather data
RegisterNUICallback('getWeatherData', function(data, cb)
    TriggerServerEvent('phone:server:getWeatherData')
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onReceiveWeatherData(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveWeatherData', onReceiveWeatherData)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Handle weather updates from server
RegisterNetEvent('phone:client:weatherUpdated', function(data)
    -- Send update to NUI if phone is open
    if phoneOpen then
        SendNUIMessage({
            action = 'weatherUpdated',
            data = data
        })
    end
end)


--- Get available apps
RegisterNUICallback('getAvailableApps', function(data, cb)
    TriggerServerEvent('phone:server:getAvailableApps')
    
    -- Wait for response
    local timeout = 0
    local response = nil
    
    local handler = function(data)
        response = data
    end
    
    RegisterNetEvent('phone:client:appStoreData')
    AddEventHandler('phone:client:appStoreData', handler)
    
    while response == nil and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler('phone:client:appStoreData', handler)
    
    if response then
        cb(response)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

--- Install app
RegisterNUICallback('installApp', function(data, cb)
    if not data.appId then
        cb({ success = false, message = 'App ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:installApp', data.appId)
    
    -- Wait for response
    local timeout = 0
    local response = nil
    
    local handler = function(data)
        response = data
    end
    
    RegisterNetEvent('phone:client:installAppResult')
    AddEventHandler('phone:client:installAppResult', handler)
    
    while response == nil and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler('phone:client:installAppResult', handler)
    
    if response then
        cb(response)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

--- Uninstall app
RegisterNUICallback('uninstallApp', function(data, cb)
    if not data.appId then
        cb({ success = false, message = 'App ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:uninstallApp', data.appId)
    
    -- Wait for response
    local timeout = 0
    local response = nil
    
    local handler = function(data)
        response = data
    end
    
    RegisterNetEvent('phone:client:uninstallAppResult')
    AddEventHandler('phone:client:uninstallAppResult', handler)
    
    while response == nil and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler('phone:client:uninstallAppResult', handler)
    
    if response then
        cb(response)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)


-- Chirper App Callbacks

-- Get Chirper feed
RegisterNUICallback('getChirperFeed', function(data, cb)
    local limit = data.limit or 20
    local offset = data.offset or 0
    
    TriggerServerEvent('phone:server:getChirperFeed', {
        limit = limit,
        offset = offset
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local feedData = {}
    
    local function onReceiveFeed(result)
        feedData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveChirperFeed', onReceiveFeed)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(feedData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Get user's own Chirper posts
RegisterNUICallback('getMyChirperPosts', function(data, cb)
    TriggerServerEvent('phone:server:getMyChirperPosts')
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local postsData = {}
    
    local function onReceivePosts(result)
        postsData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveMyChirperPosts', onReceivePosts)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(postsData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Get Chirper trending topics
RegisterNUICallback('getChirperTrending', function(data, cb)
    TriggerServerEvent('phone:server:getChirperTrending')
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local trendingData = {}
    
    local function onReceiveTrending(result)
        trendingData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveChirperTrending', onReceiveTrending)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(trendingData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Get Chirper thread (post + replies)
RegisterNUICallback('getChirperThread', function(data, cb)
    if not data.postId then
        cb({ success = false, message = 'Post ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:getChirperThread', {
        postId = data.postId
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local threadData = {}
    
    local function onReceiveThread(result)
        threadData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveChirperThread', onReceiveThread)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(threadData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Create Chirper post
RegisterNUICallback('createChirperPost', function(data, cb)
    if not data.content then
        cb({ success = false, message = 'Content is required' })
        return
    end
    
    TriggerServerEvent('phone:server:createChirperPost', {
        content = data.content,
        parentId = data.parentId
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onPostResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:createChirperPostResult', onPostResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Like Chirper post
RegisterNUICallback('likeChirperPost', function(data, cb)
    if not data.postId then
        cb({ success = false, message = 'Post ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:likeChirperPost', {
        postId = data.postId
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onLikeResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:likeChirperPostResult', onLikeResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Repost Chirper post
RegisterNUICallback('repostChirperPost', function(data, cb)
    if not data.postId then
        cb({ success = false, message = 'Post ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:repostChirperPost', {
        postId = data.postId
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onRepostResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:repostChirperPostResult', onRepostResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Reply to Chirper post
RegisterNUICallback('replyToChirperPost', function(data, cb)
    if not data.postId or not data.content then
        cb({ success = false, message = 'Post ID and content are required' })
        return
    end
    
    TriggerServerEvent('phone:server:createChirperPost', {
        content = data.content,
        parentId = data.postId
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onReplyResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:createChirperPostResult', onReplyResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Delete Chirper post
RegisterNUICallback('deleteChirperPost', function(data, cb)
    if not data.postId then
        cb({ success = false, message = 'Post ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:deleteChirperPost', {
        postId = data.postId
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onDeleteResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:deleteChirperPostResult', onDeleteResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Handle new Chirper post broadcast
RegisterNetEvent('phone:client:newChirperPost', function(post)
    if not post then
        return
    end
    
    -- Send to NUI to update feed
    SendNUIMessage({
        action = 'newChirperPost',
        data = post
    })
end)

-- Handle Chirper post like update broadcast
RegisterNetEvent('phone:client:chirperPostLikeUpdate', function(data)
    if not data or not data.postId then
        return
    end
    
    -- Send to NUI to update like count
    SendNUIMessage({
        action = 'chirperPostLikeUpdate',
        data = data
    })
end)

-- Handle Chirper post repost update broadcast
RegisterNetEvent('phone:client:chirperPostRepostUpdate', function(data)
    if not data or not data.postId then
        return
    end
    
    -- Send to NUI to update repost count
    SendNUIMessage({
        action = 'chirperPostRepostUpdate',
        data = data
    })
end)

-- Handle Chirper post reply update broadcast
RegisterNetEvent('phone:client:chirperPostReplyUpdate', function(data)
    if not data or not data.postId then
        return
    end
    
    -- Send to NUI to update reply count
    SendNUIMessage({
        action = 'chirperPostReplyUpdate',
        data = data
    })
end)

-- Handle Chirper post deleted broadcast
RegisterNetEvent('phone:client:chirperPostDeleted', function(data)
    if not data or not data.postId then
        return
    end
    
    -- Send to NUI to remove post from feed
    SendNUIMessage({
        action = 'chirperPostDeleted',
        data = data
    })
end)


-- Modish App Callbacks

-- Get Modish feed
RegisterNUICallback('getModishFeed', function(data, cb)
    TriggerServerEvent('phone:server:getModishFeed', data)
    cb({ success = true })
end)

-- Get my Modish videos
RegisterNUICallback('getMyModishVideos', function(data, cb)
    TriggerServerEvent('phone:server:getMyModishVideos')
    cb({ success = true })
end)

-- Create Modish video
RegisterNUICallback('createModishVideo', function(data, cb)
    TriggerServerEvent('phone:server:createModishVideo', data)
    cb({ success = true })
end)

-- Like Modish video
RegisterNUICallback('likeModishVideo', function(data, cb)
    TriggerServerEvent('phone:server:likeModishVideo', data)
    cb({ success = true })
end)

-- Increment Modish video views
RegisterNUICallback('incrementModishViews', function(data, cb)
    TriggerServerEvent('phone:server:incrementModishViews', data)
    cb({ success = true })
end)

-- Get Modish comments
RegisterNUICallback('getModishComments', function(data, cb)
    TriggerServerEvent('phone:server:getModishComments', data)
    cb({ success = true })
end)

-- Comment on Modish video
RegisterNUICallback('commentOnModishVideo', function(data, cb)
    TriggerServerEvent('phone:server:commentOnModishVideo', data)
    cb({ success = true })
end)

-- Client event handlers for Modish responses
RegisterNetEvent('phone:client:receiveModishFeed', function(data)
    SendNUIMessage({
        type = 'modishFeedReceived',
        data = data
    })
end)

RegisterNetEvent('phone:client:receiveMyModishVideos', function(data)
    SendNUIMessage({
        type = 'myModishVideosReceived',
        data = data
    })
end)

RegisterNetEvent('phone:client:createModishVideoResult', function(data)
    SendNUIMessage({
        type = 'modishVideoCreated',
        data = data
    })
end)

RegisterNetEvent('phone:client:likeModishVideoResult', function(data)
    SendNUIMessage({
        type = 'modishVideoLiked',
        data = data
    })
end)

RegisterNetEvent('phone:client:receiveModishComments', function(data)
    SendNUIMessage({
        type = 'modishCommentsReceived',
        data = data
    })
end)

RegisterNetEvent('phone:client:commentOnModishVideoResult', function(data)
    SendNUIMessage({
        type = 'modishCommentPosted',
        data = data
    })
end)

-- Real-time updates
RegisterNetEvent('phone:client:newModishVideo', function(video)
    SendNUIMessage({
        type = 'newModishVideo',
        video = video
    })
end)

RegisterNetEvent('phone:client:modishVideoLikeUpdate', function(data)
    SendNUIMessage({
        type = 'modishVideoLikeUpdate',
        data = data
    })
end)

RegisterNetEvent('phone:client:modishVideoViewUpdate', function(data)
    SendNUIMessage({
        type = 'modishVideoViewUpdate',
        data = data
    })
end)



-- Flicker App Callbacks

-- Get Flicker profile
RegisterNUICallback('getFlickerProfile', function(data, cb)
    TriggerServerEvent('phone:server:getFlickerProfile')
    
    local timeout = 0
    local responseReceived = false
    local profileData = {}
    
    local function onReceiveProfile(result)
        profileData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveFlickerProfile', onReceiveProfile)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(profileData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Save Flicker profile
RegisterNUICallback('saveFlickerProfile', function(data, cb)
    TriggerServerEvent('phone:server:saveFlickerProfile', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onSaveResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:saveFlickerProfileResult', onSaveResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Get potential matches
RegisterNUICallback('getFlickerPotentialMatches', function(data, cb)
    TriggerServerEvent('phone:server:getFlickerPotentialMatches', data)
    
    local timeout = 0
    local responseReceived = false
    local matchesData = {}
    
    local function onReceiveMatches(result)
        matchesData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveFlickerPotentialMatches', onReceiveMatches)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(matchesData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Swipe on profile
RegisterNUICallback('swipeFlickerProfile', function(data, cb)
    TriggerServerEvent('phone:server:swipeFlickerProfile', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onSwipeResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:swipeFlickerProfileResult', onSwipeResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Get matches
RegisterNUICallback('getFlickerMatches', function(data, cb)
    TriggerServerEvent('phone:server:getFlickerMatches')
    
    local timeout = 0
    local responseReceived = false
    local matchesData = {}
    
    local function onReceiveMatches(result)
        matchesData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveFlickerMatches', onReceiveMatches)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(matchesData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Unmatch
RegisterNUICallback('unmatchFlicker', function(data, cb)
    TriggerServerEvent('phone:server:unmatchFlicker', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onUnmatchResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:unmatchFlickerResult', onUnmatchResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Get messages with a match
RegisterNUICallback('getFlickerMessages', function(data, cb)
    TriggerServerEvent('phone:server:getFlickerMessages', data)
    
    local timeout = 0
    local responseReceived = false
    local messagesData = {}
    
    local function onReceiveMessages(result)
        messagesData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveFlickerMessages', onReceiveMessages)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(messagesData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Send message to match
RegisterNUICallback('sendFlickerMessage', function(data, cb)
    TriggerServerEvent('phone:server:sendFlickerMessage', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onSendResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:sendFlickerMessageResult', onSendResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Handle real-time match notification
RegisterNetEvent('phone:client:newFlickerMatch', function(matchData)
    SendNUIMessage({
        action = 'newFlickerMatch',
        data = matchData
    })
end)

-- Handle real-time message notification
RegisterNetEvent('phone:client:newFlickerMessage', function(messageData)
    SendNUIMessage({
        action = 'newFlickerMessage',
        data = messageData
    })
end)

-- Handle unmatch notification
RegisterNetEvent('phone:client:flickerUnmatched', function(data)
    SendNUIMessage({
        action = 'flickerUnmatched',
        data = data
    })
end)

-- Pages App Callbacks

-- Send page announcement
RegisterNUICallback('phone:server:sendPageAnnouncement', function(data, cb)
    if not data.pageId or not data.message then
        cb({ success = false, message = 'Page ID and message are required' })
        return
    end
    
    TriggerServerEvent('phone:server:sendPageAnnouncement', data)
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onAnnouncementSent(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:pageAnnouncementSent', onAnnouncementSent)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Fetch business pages
RegisterNUICallback('getBusinessPages', function(data, cb)
    TriggerServerEvent('phone:server:getBusinessPages', data or {})

    local timeout = 0
    local responseReceived = false
    local resultData = {}

    local function onReceive(pagesData)
        resultData = pagesData
        responseReceived = true
    end

    local handler = AddEventHandler('phone:client:receiveBusinessPages', onReceive)

    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    RemoveEventHandler(handler)

    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Fetch my business pages
RegisterNUICallback('getMyBusinessPages', function(data, cb)
    TriggerServerEvent('phone:server:getMyBusinessPages')

    local timeout = 0
    local responseReceived = false
    local resultData = {}

    local function onReceive(pagesData)
        resultData = pagesData
        responseReceived = true
    end

    local handler = AddEventHandler('phone:client:receiveMyBusinessPages', onReceive)

    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    RemoveEventHandler(handler)

    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Fetch following pages
RegisterNUICallback('getFollowingPages', function(data, cb)
    TriggerServerEvent('phone:server:getFollowingPages')

    local timeout = 0
    local responseReceived = false
    local resultData = {}

    local function onReceive(pagesData)
        resultData = pagesData
        responseReceived = true
    end

    local handler = AddEventHandler('phone:client:receiveFollowingPages', onReceive)

    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    RemoveEventHandler(handler)

    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Create business page
RegisterNUICallback('createBusinessPage', function(data, cb)
    TriggerServerEvent('phone:server:createBusinessPage', data)

    local timeout = 0
    local responseReceived = false
    local resultData = {}

    local function onCreated(result)
        resultData = result
        responseReceived = true
    end

    local handler = AddEventHandler('phone:client:businessPageCreated', onCreated)

    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    RemoveEventHandler(handler)

    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Update business page
RegisterNUICallback('updateBusinessPage', function(data, cb)
    TriggerServerEvent('phone:server:updateBusinessPage', data)

    local timeout = 0
    local responseReceived = false
    local resultData = {}

    local function onUpdated(result)
        resultData = result
        responseReceived = true
    end

    local handler = AddEventHandler('phone:client:businessPageUpdated', onUpdated)

    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    RemoveEventHandler(handler)

    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Delete business page
RegisterNUICallback('deleteBusinessPage', function(pageId, cb)
    TriggerServerEvent('phone:server:deleteBusinessPage', pageId)

    local timeout = 0
    local responseReceived = false
    local resultData = {}

    local function onDeleted(result)
        resultData = result
        responseReceived = true
    end

    local handler = AddEventHandler('phone:client:businessPageDeleted', onDeleted)

    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    RemoveEventHandler(handler)

    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Follow business page
RegisterNUICallback('followBusinessPage', function(pageId, cb)
    TriggerServerEvent('phone:server:followBusinessPage', pageId)

    local timeout = 0
    local responseReceived = false
    local resultData = {}

    local function onFollowed(result)
        resultData = result
        responseReceived = true
    end

    local handler = AddEventHandler('phone:client:businessPageFollowed', onFollowed)

    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    RemoveEventHandler(handler)

    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Unfollow business page
RegisterNUICallback('unfollowBusinessPage', function(pageId, cb)
    TriggerServerEvent('phone:server:unfollowBusinessPage', pageId)

    local timeout = 0
    local responseReceived = false
    local resultData = {}

    local function onUnfollowed(result)
        resultData = result
        responseReceived = true
    end

    local handler = AddEventHandler('phone:client:businessPageUnfollowed', onUnfollowed)

    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    RemoveEventHandler(handler)

    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Track page view (fire-and-forget)
RegisterNUICallback('trackPageView', function(pageId, cb)
    TriggerServerEvent('phone:server:trackPageView', pageId)
    cb({ success = true })
end)

-- Get page statistics
RegisterNUICallback('getPageStatistics', function(pageId, cb)
    TriggerServerEvent('phone:server:getPageStatistics', pageId)

    local timeout = 0
    local responseReceived = false
    local resultData = {}

    local function onStats(result)
        resultData = result
        responseReceived = true
    end

    local handler = AddEventHandler('phone:client:receivePageStatistics', onStats)

    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    RemoveEventHandler(handler)

    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Settings App Callbacks

-- Set player locale (language preference)
RegisterNUICallback('setPlayerLocale', function(data, cb)
    if not data.locale then
        cb({ success = false, message = 'Locale is required' })
        return
    end
    
    -- Validate locale format (2-letter code)
    if type(data.locale) ~= 'string' or #data.locale ~= 2 then
        cb({ success = false, message = 'Invalid locale format' })
        return
    end
    
    TriggerServerEvent('phone:server:setPlayerLocale', {
        locale = data.locale
    })
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:localeUpdateResult', onResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Get player settings (including locale)
RegisterNUICallback('getPlayerSettings', function(data, cb)
    TriggerServerEvent('phone:server:getSettings')
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local settingsData = {}
    
    local function onReceiveSettings(settings)
        settingsData = settings
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:receiveSettings', onReceiveSettings)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb({ success = true, settings = settingsData })
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Update player settings
RegisterNUICallback('updatePlayerSettings', function(data, cb)
    if not data.updates or type(data.updates) ~= 'table' then
        cb({ success = false, message = 'Settings updates are required' })
        return
    end
    
    TriggerServerEvent('phone:server:updateSettings', data.updates)
    
    -- Wait for server response
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:settingsUpdated', onResult)
    
    -- Wait for response with timeout
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb({ success = true, settings = resultData })
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)


-- ============================================================================
-- Musicly App Callbacks (Music Streaming)
-- ============================================================================

-- Initialize Musicly
RegisterNUICallback('initializeMusicly', function(data, cb)
    TriggerServerEvent('phone:server:initializeMusicly')
    
    local timeout = 0
    local responseReceived = false
    local musiclyData = {}
    
    local function onMusiclyInitialized(result)
        musiclyData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:musiclyInitialized', onMusiclyInitialized)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(musiclyData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Search music
RegisterNUICallback('searchMusic', function(data, cb)
    if not data.query then
        cb({ success = false, message = 'Search query is required' })
        return
    end
    
    TriggerServerEvent('phone:server:searchMusic', data.query)
    
    local timeout = 0
    local responseReceived = false
    local resultsData = {}
    
    local function onSearchResults(results)
        resultsData = results
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:musicSearchResults', onSearchResults)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb({ success = true, results = resultsData })
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Browse music category
RegisterNUICallback('browseMusicCategory', function(data, cb)
    if not data.categoryId then
        cb({ success = false, message = 'Category ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:browseMusicCategory', data.categoryId)
    
    local timeout = 0
    local responseReceived = false
    local tracksData = {}
    
    local function onCategoryResults(tracks)
        tracksData = tracks
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:musicCategoryResults', onCategoryResults)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb({ success = true, tracks = tracksData })
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Create playlist
RegisterNUICallback('createPlaylist', function(data, cb)
    if not data.name then
        cb({ success = false, message = 'Playlist name is required' })
        return
    end
    
    TriggerServerEvent('phone:server:createPlaylist', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onPlaylistCreated(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:playlistCreated', onPlaylistCreated)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Delete playlist
RegisterNUICallback('deletePlaylist', function(data, cb)
    if not data.playlistId then
        cb({ success = false, message = 'Playlist ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:deletePlaylist', data.playlistId)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onPlaylistDeleted(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:playlistDeleted', onPlaylistDeleted)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Get playlist tracks
RegisterNUICallback('getPlaylistTracks', function(data, cb)
    if not data.playlistId then
        cb({ success = false, message = 'Playlist ID is required' })
        return
    end
    
    TriggerServerEvent('phone:server:getPlaylistTracks', data.playlistId)
    
    local timeout = 0
    local responseReceived = false
    local playlistData = {}
    
    local function onPlaylistTracks(result)
        playlistData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:playlistTracks', onPlaylistTracks)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(playlistData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- Add track to playlist
RegisterNUICallback('addTrackToPlaylist', function(data, cb)
    if not data.playlistId or not data.track then
        cb({ success = false, message = 'Playlist ID and track are required' })
        return
    end
    
    TriggerServerEvent('phone:server:addTrackToPlaylist', data)
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onTrackAdded(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:trackAddedToPlaylist', onTrackAdded)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, message = 'Request timeout' })
    end
end)

-- ============================================================================
-- Contact Sharing Callbacks
-- ============================================================================

-- Share contact with nearby player
RegisterNUICallback('shareContact', function(data, cb)
    if not data.targetSource then
        cb({ success = false, error = 'TARGET_REQUIRED', message = 'Target player is required' })
        return
    end
    
    TriggerServerEvent('phone:server:sendShareRequest', {
        targetSource = data.targetSource,
        targetName = data.targetName,
        targetNumber = data.targetNumber
    })
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onShareResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:shareRequestResult', onShareResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, error = 'CALLBACK_FAILED', message = 'Request timeout' })
    end
end)

-- Add contact from broadcast
RegisterNUICallback('addFromBroadcast', function(data, cb)
    if not data.broadcasterNumber then
        cb({ success = false, error = 'BROADCASTER_REQUIRED', message = 'Broadcaster number is required' })
        return
    end
    
    TriggerServerEvent('phone:server:addFromBroadcast', {
        broadcasterNumber = data.broadcasterNumber,
        broadcasterName = data.broadcasterName,
        broadcasterSource = data.broadcasterSource
    })
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onAddResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:addFromBroadcastResult', onAddResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, error = 'CALLBACK_FAILED', message = 'Request timeout' })
    end
end)

-- Respond to share request (accept/decline)
RegisterNUICallback('respondToShareRequest', function(data, cb)
    if not data.requestId or data.accepted == nil then
        cb({ success = false, error = 'INVALID_REQUEST', message = 'Request ID and accepted status are required' })
        return
    end
    
    TriggerServerEvent('phone:server:respondToShareRequest', {
        requestId = data.requestId,
        accepted = data.accepted
    })
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onResponseResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:shareResponseResult', onResponseResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, error = 'CALLBACK_FAILED', message = 'Request timeout' })
    end
end)

-- Start broadcast share
RegisterNUICallback('startBroadcastShare', function(data, cb)
    TriggerServerEvent('phone:server:startBroadcastShare')
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onBroadcastResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:broadcastShareResult', onBroadcastResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, error = 'CALLBACK_FAILED', message = 'Request timeout' })
    end
end)

-- Stop broadcast share
RegisterNUICallback('stopBroadcastShare', function(data, cb)
    TriggerServerEvent('phone:server:stopBroadcastShare')
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onStopResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:broadcastStopResult', onStopResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, error = 'CALLBACK_FAILED', message = 'Request timeout' })
    end
end)

-- Respond to share request (accept or decline)
RegisterNUICallback('respondToShareRequest', function(data, cb)
    if not data.requestId or data.accepted == nil then
        cb({ success = false, error = 'INVALID_REQUEST', message = 'Request ID and accepted status are required' })
        return
    end
    
    TriggerServerEvent('phone:server:respondToShareRequest', {
        requestId = data.requestId,
        accepted = data.accepted
    })
    
    local timeout = 0
    local responseReceived = false
    local resultData = {}
    
    local function onResponseResult(result)
        resultData = result
        responseReceived = true
    end
    
    local eventHandler = AddEventHandler('phone:client:shareRequestResponseResult', onResponseResult)
    
    while not responseReceived and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    RemoveEventHandler(eventHandler)
    
    if responseReceived then
        cb(resultData)
    else
        cb({ success = false, error = 'CALLBACK_FAILED', message = 'Request timeout' })
    end
end)
