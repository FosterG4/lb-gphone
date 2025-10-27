# Notification System Documentation

## Overview

The notification system provides a comprehensive way to display various types of notifications to players in the FiveM smartphone NUI. It includes queue management, auto-dismiss functionality, different notification types, and optional sound effects.

## Features

### 1. Multiple Notification Types
- **message**: For incoming text messages
- **call**: For incoming calls
- **app**: For general app notifications
- **bank**: For banking transactions
- **error**: For error messages
- **success**: For successful operations
- **warning**: For warnings
- **default**: Generic notifications

### 2. Queue Management
- Maximum of 3 notifications displayed at once
- Additional notifications are queued and displayed when space becomes available
- Automatic queue processing when notifications are dismissed

### 3. Auto-Dismiss
- Configurable duration per notification (default: 5000ms)
- Automatic removal after duration expires
- Manual dismiss by clicking on notification or close button

### 4. Notification Sounds
- Different sound patterns for different notification types
- Web Audio API-based sound generation
- Can be disabled per notification or globally via config

### 5. Visual Stacking
- Notifications stack vertically with proper spacing
- Smooth animations for enter/leave transitions
- Hover effects for better UX

## Configuration

### Config.lua Settings

```lua
-- Notification Settings
Config.NotificationDuration = 5000 -- Duration in milliseconds
Config.NotificationPosition = 'top-right' -- Position on screen
Config.NotificationSound = true -- Enable notification sounds
```

## Client-Side Usage

### Using Helper Functions

The notification system provides helper functions for easy use:

```lua
-- Generic notification
ShowNotification({
    type = 'message',
    title = 'New Message',
    message = 'You have a new message',
    duration = 5000,
    sound = true
})

-- Message notification
ShowMessageNotification(senderNumber, senderName, messagePreview)

-- Call notification
ShowCallNotification(callerNumber, callerName, isIncoming)

-- App notification
ShowAppNotification('Twitter', 'New tweet posted')

-- Bank notification
ShowBankNotification('Money Received', 'You received $500')

-- Error notification
ShowErrorNotification('Error', 'Something went wrong')

-- Success notification
ShowSuccessNotification('Success', 'Operation completed')

-- Warning notification
ShowWarningNotification('Warning', 'Please be careful')
```

### Using Exports

```lua
-- From another resource
exports['your-phone-resource']:ShowNotification({
    type = 'app',
    title = 'Custom App',
    message = 'Custom notification',
    duration = 3000
})
```

### Direct NUI Message

```lua
SendNUIMessage({
    action = 'showNotification',
    data = {
        type = 'message',
        title = 'Title',
        message = 'Message content',
        duration = 5000,
        sound = true
    }
})
```

## Server-Side Usage

### Triggering Client Notifications

```lua
-- Error notification
TriggerClientEvent('phone:client:showError', source, {
    title = 'Error',
    message = 'Operation failed'
})

-- Success notification
TriggerClientEvent('phone:client:showSuccess', source, {
    title = 'Success',
    message = 'Operation completed'
})

-- Warning notification
TriggerClientEvent('phone:client:showWarning', source, {
    title = 'Warning',
    message = 'Please be aware'
})

-- App notification
TriggerClientEvent('phone:client:showAppNotification', source, {
    appName = 'Bank',
    message = 'Transfer completed'
})
```

## NUI/Vue.js Usage

### Using Vuex Store

```javascript
// Show notification
this.$store.dispatch('phone/showNotification', {
    type: 'success',
    title: 'Success',
    message: 'Operation completed',
    duration: 3000
})

// Dismiss notification
this.$store.dispatch('phone/dismissNotification', notificationId)

// Clear all notifications
this.$store.dispatch('phone/clearAll')
```

### Accessing Notifications State

```javascript
// Get all active notifications
const notifications = this.$store.state.phone.notifications

// Get notification queue
const queue = this.$store.state.phone.notificationQueue
```

## Notification Structure

```javascript
{
    id: 1234567890.123,           // Unique identifier (timestamp + random)
    type: 'message',               // Notification type
    title: 'New Message',          // Notification title
    message: 'From: 555-1234',     // Notification message
    duration: 5000,                // Auto-dismiss duration in ms
    sound: true                    // Play sound (optional)
}
```

## Sound Patterns

Each notification type has a unique sound pattern:

- **message**: Single short beep (800Hz, 0.1s)
- **call**: Double beep pattern (600Hz, 0.2s each, 300ms apart)
- **error**: Low tone (400Hz, 0.15s)
- **success**: Rising two-tone (1000Hz → 1200Hz)
- **default**: Medium beep (700Hz, 0.1s)

## Styling

Notifications use different border colors based on type:

- **default/message**: Blue (#007aff)
- **call/success**: Green (#34c759)
- **app**: Orange (#ff9500)
- **bank**: Light green (#30d158)
- **error**: Red (#ff3b30)
- **warning**: Yellow (#ff9f0a)

## Implementation Details

### Queue Management

The notification system maintains:
- `notifications`: Array of currently displayed notifications (max 3)
- `notificationQueue`: Array of pending notifications
- `notificationTimers`: Object mapping notification IDs to timeout timers

When a notification is dismissed:
1. Timer is cleared
2. Notification is removed from display
3. Next notification from queue is displayed (if any)

### Auto-Dismiss

Each notification has an auto-dismiss timer that:
1. Starts when notification is added
2. Removes notification after specified duration
3. Is cleared if notification is manually dismissed

### Sound Generation

Sounds are generated using Web Audio API:
- Creates oscillator for tone generation
- Uses gain node for volume control
- Different frequencies and patterns for different types
- Gracefully handles errors if audio context unavailable

## Testing

### Manual Testing

1. **Message Notification**:
   - Send a message to yourself
   - Verify notification appears with message icon
   - Verify sound plays (if enabled)
   - Verify auto-dismiss after 5 seconds

2. **Call Notification**:
   - Initiate a call
   - Verify notification appears with call icon
   - Verify sound plays (if enabled)
   - Verify notification persists until call timeout

3. **Queue Management**:
   - Trigger 5+ notifications rapidly
   - Verify only 3 display at once
   - Verify remaining queue as notifications dismiss

4. **Manual Dismiss**:
   - Click on notification
   - Verify it dismisses immediately
   - Verify next queued notification appears

### Integration Testing

```lua
-- Test notification system
CreateThread(function()
    Wait(5000)
    
    -- Test different types
    ShowMessageNotification('555-1234', 'John Doe', 'Test message')
    Wait(1000)
    
    ShowCallNotification('555-5678', 'Jane Smith', true)
    Wait(1000)
    
    ShowBankNotification('Transfer', 'Received $100')
    Wait(1000)
    
    ShowSuccessNotification('Success', 'Test passed')
    Wait(1000)
    
    ShowErrorNotification('Error', 'Test error')
end)
```

## Requirements Satisfied

This implementation satisfies the following requirements:

- **Requirement 3.2**: Message notifications when receiving new messages
- **Requirement 4.2**: Call notifications for incoming calls
- **Requirement 12.4**: Configurable notification styles and duration

## Future Enhancements

Potential improvements:
- Custom notification icons/images
- Action buttons in notifications
- Notification history/log
- Priority levels for notifications
- Persistent notifications (no auto-dismiss)
- Notification grouping by type
- Custom sound files instead of generated tones
