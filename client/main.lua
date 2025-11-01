-- Client Main
-- Handles phone initialization, keybind registration, and phone open/close logic

local isPhoneOpen = false
local playerData = {}

-- Initialize phone on resource start
CreateThread(function()
    -- Wait for player to spawn
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    
    -- Small delay to ensure everything is loaded
    Wait(1000)
    
    -- Trigger server to load player data
    TriggerServerEvent('phone:server:playerLoaded')
    
    if Config.DebugMode then
        print('[Phone] Player loaded, requesting phone data')
    end
end)

-- Keybind handler thread
CreateThread(function()
    while true do
        Wait(0)
        
        -- Check for keybind press
        if IsControlJustPressed(0, GetControlKey(Config.OpenKey)) then
            TogglePhone()
        end
    end
end)

-- Toggle phone open/close
function TogglePhone()
    if CanOpenPhone() then
        isPhoneOpen = not isPhoneOpen
        
        if isPhoneOpen then
            OpenPhone()
        else
            ClosePhone()
        end
    else
        if Config.DebugMode then
            print('[Phone] Cannot open phone - player is restricted')
        end
    end
end

-- Open phone
function OpenPhone()
    isPhoneOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'setVisible',
        data = { visible = true }
    })
    
    -- Request phone data from server
    TriggerServerEvent('phone:server:requestPhoneData')
    
    -- Notify contact sharing module
    if playerData.phoneNumber then
        exports['phone-system']:NotifyPhoneOpened(playerData.phoneNumber)
    end
    
    if Config.DebugMode then
        print('[Phone] Phone opened')
    end
end

-- Close phone
function ClosePhone()
    isPhoneOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'setVisible',
        data = { visible = false }
    })
    
    -- Notify contact sharing module
    exports['phone-system']:NotifyPhoneClosed()
    
    if Config.DebugMode then
        print('[Phone] Phone closed')
    end
end

-- Check if player can open phone
function CanOpenPhone()
    local playerPed = PlayerPedId()
    
    -- Check if player is dead
    if Config.Restrictions.blockWhenDead and IsEntityDead(playerPed) then
        return false
    end
    
    -- Check if player is cuffed
    if Config.Restrictions.blockWhenCuffed and IsPedCuffed(playerPed) then
        return false
    end
    
    -- Check if player is in trunk
    if Config.Restrictions.blockInTrunk and IsPedInVehicle(playerPed, GetVehiclePedIsIn(playerPed, false), false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
            return false
        end
    end
    
    -- Check if player is in water
    if Config.Restrictions.blockInWater and IsPedSwimming(playerPed) then
        return false
    end
    
    return true
end

-- Get control key from string
function GetControlKey(key)
    local keys = {
        ['M'] = 244,
        ['K'] = 311,
        ['L'] = 182,
        ['P'] = 199
    }
    return keys[key] or 244
end

-- Client event handlers

-- Receive phone number from server
RegisterNetEvent('phone:client:setPhoneNumber', function(phoneNumber)
    playerData.phoneNumber = phoneNumber
    
    SendNUIMessage({
        action = 'setPhoneNumber',
        data = { phoneNumber = phoneNumber }
    })
    
    -- If phone is already open, notify contact sharing
    if isPhoneOpen then
        exports['phone-system']:NotifyPhoneOpened(phoneNumber)
    end
    
    if Config.DebugMode then
        print('[Phone] Phone number set: ' .. phoneNumber)
    end
end)

-- Load all phone data from server
RegisterNetEvent('phone:client:loadPhoneData', function(phoneData)
    if not phoneData then
        if Config.DebugMode then
            print('[Phone] Received empty phone data')
        end
        return
    end
    
    -- Store phone number
    playerData.phoneNumber = phoneData.phoneNumber
    
    -- Send all data to NUI to populate Vuex store
    SendNUIMessage({
        action = 'loadPhoneData',
        data = {
            phoneNumber = phoneData.phoneNumber,
            contacts = phoneData.contacts or {},
            messages = phoneData.messages or {},
            callHistory = phoneData.callHistory or {}
        }
    })
    
    if Config.DebugMode then
        print('[Phone] Phone data loaded: ' .. 
              #phoneData.contacts .. ' contacts, ' .. 
              #phoneData.messages .. ' messages, ' .. 
              #phoneData.callHistory .. ' call history entries')
    end
end)

-- Receive contacts from server
RegisterNetEvent('phone:client:receiveContacts', function(contacts)
    -- This event is handled by NUI callbacks
end)

-- Contact operation result
RegisterNetEvent('phone:client:contactOperationResult', function(result)
    -- This event is handled by NUI callbacks
end)

-- Receive messages from server
RegisterNetEvent('phone:client:receiveMessages', function(messages)
    -- This event is handled by NUI callbacks
end)

-- Receive incoming message
RegisterNetEvent('phone:client:receiveMessage', function(message)
    -- Send message to NUI
    SendNUIMessage({
        action = 'receiveMessage',
        data = message
    })
    
    -- Show notification if phone is closed
    if not isPhoneOpen then
        local messagePreview = message.message
        if #messagePreview > 50 then
            messagePreview = string.sub(messagePreview, 1, 50) .. '...'
        end
        
        ShowMessageNotification(
            message.sender_number,
            message.sender_name or message.sender_number,
            messagePreview
        )
    end
    
    if Config.DebugMode then
        print('[Phone] Received message from: ' .. message.sender_number)
    end
end)

-- Message operation result
RegisterNetEvent('phone:client:messageOperationResult', function(result)
    -- This event is handled by NUI callbacks
end)

-- Export functions
exports('IsPhoneOpen', function()
    return isPhoneOpen
end)

exports('OpenPhone', OpenPhone)
exports('ClosePhone', ClosePhone)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isPhoneOpen then
            ClosePhone()
        end
    end
end)


-- Error notification handler
RegisterNetEvent('phone:client:showError', function(errorData)
    if not errorData then return end
    
    local title = errorData.title or 'Error'
    local message = errorData.message or 'An error occurred'
    
    ShowErrorNotification(title, message)
    
    if Config.DebugMode then
        print('[Phone Error] ' .. title .. ': ' .. message)
    end
end)

-- Success notification handler
RegisterNetEvent('phone:client:showSuccess', function(successData)
    if not successData then return end
    
    local title = successData.title or 'Success'
    local message = successData.message or 'Operation completed'
    
    ShowSuccessNotification(title, message)
end)

-- Warning notification handler
RegisterNetEvent('phone:client:showWarning', function(warningData)
    if not warningData then return end
    
    local title = warningData.title or 'Warning'
    local message = warningData.message or 'Please be aware'
    
    ShowWarningNotification(title, message)
end)

-- App notification handler
RegisterNetEvent('phone:client:showAppNotification', function(appData)
    if not appData then return end
    
    local appName = appData.appName or 'App'
    local message = appData.message or 'Notification'
    
    ShowAppNotification(appName, message)
end)

-- Load media modules
require('client.media.camera')
require('client.media.video')
require('client.media.audio')
