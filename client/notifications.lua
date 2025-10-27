-- Client Notification Helpers
-- Provides helper functions for showing different types of notifications

-- Show a generic notification
function ShowNotification(notificationData)
    SendNUIMessage({
        action = 'showNotification',
        data = {
            type = notificationData.type or 'default',
            title = notificationData.title or 'Notification',
            message = notificationData.message or '',
            duration = notificationData.duration or Config.NotificationDuration,
            sound = notificationData.sound ~= false
        }
    })
end

-- Show message notification
function ShowMessageNotification(senderNumber, senderName, messagePreview)
    ShowNotification({
        type = 'message',
        title = senderName or senderNumber,
        message = messagePreview or 'New message',
        duration = Config.NotificationDuration
    })
end

-- Show call notification
function ShowCallNotification(callerNumber, callerName, isIncoming)
    local title = isIncoming and 'Incoming Call' or 'Call'
    local message = 'From: ' .. (callerName or callerNumber)
    
    ShowNotification({
        type = 'call',
        title = title,
        message = message,
        duration = isIncoming and Config.CallTimeout or Config.NotificationDuration
    })
end

-- Show app notification
function ShowAppNotification(appName, message)
    ShowNotification({
        type = 'app',
        title = appName,
        message = message,
        duration = Config.NotificationDuration
    })
end

-- Show bank notification
function ShowBankNotification(title, message)
    ShowNotification({
        type = 'bank',
        title = title,
        message = message,
        duration = Config.NotificationDuration
    })
end

-- Show error notification
function ShowErrorNotification(title, message)
    ShowNotification({
        type = 'error',
        title = title or 'Error',
        message = message or 'An error occurred',
        duration = 5000
    })
end

-- Show success notification
function ShowSuccessNotification(title, message)
    ShowNotification({
        type = 'success',
        title = title or 'Success',
        message = message or 'Operation completed',
        duration = 3000
    })
end

-- Show warning notification
function ShowWarningNotification(title, message)
    ShowNotification({
        type = 'warning',
        title = title or 'Warning',
        message = message or 'Please be aware',
        duration = 4000
    })
end

-- Export functions
exports('ShowNotification', ShowNotification)
exports('ShowMessageNotification', ShowMessageNotification)
exports('ShowCallNotification', ShowCallNotification)
exports('ShowAppNotification', ShowAppNotification)
exports('ShowBankNotification', ShowBankNotification)
exports('ShowErrorNotification', ShowErrorNotification)
exports('ShowSuccessNotification', ShowSuccessNotification)
exports('ShowWarningNotification', ShowWarningNotification)
