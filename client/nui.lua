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
