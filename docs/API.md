# API Documentation

This document provides comprehensive API documentation for developers integrating with or extending the FiveM Smartphone NUI resource.

## Table of Contents

- [NUI Callback API](#nui-callback-api)
- [Server Event API](#server-event-api)
- [Client Event API](#client-event-api)
- [Framework Adapter API](#framework-adapter-api)
- [Export Functions](#export-functions)
- [Data Structures](#data-structures)

## NUI Callback API

NUI callbacks are registered on the client side and called from the Vue.js interface.

### Callback Format

```javascript
// From NUI (Vue.js)
fetch(`https://${GetParentResourceName()}/callbackName`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
}).then(response => response.json());
```

```lua
-- In client Lua
RegisterNUICallback('callbackName', function(data, cb)
    -- Handle callback
    cb({ success = true, result = someData })
end)
```

### Phone Control

#### closePhone

Close the phone interface.

**Request:**
```javascript
fetch(`https://${resourceName}/closePhone`, {
    method: 'POST',
    body: JSON.stringify({})
});
```

**Response:**
```lua
{ success = true }
```

### Contacts

#### getContacts

Request all contacts for the current player.

**Request:**
```javascript
{ }
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:getContacts`

#### addContact

Add a new contact.

**Request:**
```javascript
{
    name: string,      // Contact name
    number: string     // Phone number
}
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:addContact`

#### editContact

Edit an existing contact.

**Request:**
```javascript
{
    id: number,        // Contact ID
    name: string,      // New contact name
    number: string     // New phone number
}
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:editContact`

#### deleteContact

Delete a contact.

**Request:**
```javascript
{
    id: number         // Contact ID
}
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:deleteContact`

### Messages

#### getMessages

Request all messages for the current player.

**Request:**
```javascript
{ }
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:getMessages`

#### sendMessage

Send a text message.

**Request:**
```javascript
{
    number: string,    // Recipient phone number
    message: string    // Message content (max 500 chars)
}
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:sendMessage`

#### markMessageRead

Mark a message as read.

**Request:**
```javascript
{
    id: number         // Message ID
}
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:markMessageRead`

### Calls

#### initiateCall

Start a phone call.

**Request:**
```javascript
{
    number: string     // Phone number to call
}
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:initiateCall`

#### answerCall

Answer an incoming call.

**Request:**
```javascript
{
    callId: string     // Call identifier
}
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:answerCall`

#### endCall

End the current call.

**Request:**
```javascript
{ }
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:endCall`

### Bank App

#### getBankBalance

Get current bank balance.

**Request:**
```javascript
{ }
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:getBankBalance`

#### transferMoney

Transfer money to another player.

**Request:**
```javascript
{
    number: string,    // Recipient phone number
    amount: number     // Amount to transfer
}
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:transferMoney`

### Twitter App

#### getTweets

Get recent tweets.

**Request:**
```javascript
{ }
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:getTweets`

#### postTweet

Create a new tweet.

**Request:**
```javascript
{
    content: string    // Tweet content (max 280 chars)
}
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:postTweet`

#### likeTweet

Like a tweet.

**Request:**
```javascript
{
    id: number         // Tweet ID
}
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:likeTweet`

### Crypto App

#### getCryptoPrices

Get current cryptocurrency prices.

**Request:**
```javascript
{ }
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:getCryptoPrices`

#### getCryptoPortfolio

Get player's crypto holdings.

**Request:**
```javascript
{ }
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:getCryptoPortfolio`

#### buyCrypto

Buy cryptocurrency.

**Request:**
```javascript
{
    crypto: string,    // Crypto symbol (BTC, ETH, etc.)
    amount: number     // Amount to buy
}
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:buyCrypto`

#### sellCrypto

Sell cryptocurrency.

**Request:**
```javascript
{
    crypto: string,    // Crypto symbol
    amount: number     // Amount to sell
}
```

**Response:**
```lua
{ success = true }
```

**Triggers:** Server event `phone:server:sellCrypto`

## Server Event API

Server events are triggered from clients and handled on the server.

### Event Format

```lua
-- Client triggers
TriggerServerEvent('eventName', param1, param2, ...)

-- Server handles
RegisterNetEvent('eventName', function(param1, param2, ...)
    local source = source
    -- Handle event
end)
```

### Contacts

#### phone:server:getContacts

Get all contacts for a player.

**Parameters:** None

**Response:** Triggers `phone:client:receiveContacts` with contact array

#### phone:server:addContact

Add a new contact.

**Parameters:**
- `name` (string) - Contact name
- `number` (string) - Phone number

**Response:** Triggers `phone:client:contactAdded` with new contact

#### phone:server:editContact

Edit an existing contact.

**Parameters:**
- `id` (number) - Contact ID
- `name` (string) - New name
- `number` (string) - New number

**Response:** Triggers `phone:client:contactUpdated` with updated contact

#### phone:server:deleteContact

Delete a contact.

**Parameters:**
- `id` (number) - Contact ID

**Response:** Triggers `phone:client:contactDeleted` with contact ID

### Messages

#### phone:server:getMessages

Get all messages for a player.

**Parameters:** None

**Response:** Triggers `phone:client:receiveMessages` with message array

#### phone:server:sendMessage

Send a text message.

**Parameters:**
- `targetNumber` (string) - Recipient phone number
- `message` (string) - Message content

**Response:** Triggers `phone:client:messageSent` for sender and `phone:client:receiveMessage` for recipient

#### phone:server:markMessageRead

Mark a message as read.

**Parameters:**
- `messageId` (number) - Message ID

**Response:** Updates database

### Calls

#### phone:server:initiateCall

Initiate a phone call.

**Parameters:**
- `targetNumber` (string) - Phone number to call

**Response:** Triggers `phone:client:incomingCall` for recipient

#### phone:server:answerCall

Answer an incoming call.

**Parameters:**
- `callId` (string) - Call identifier

**Response:** Triggers `phone:client:callAnswered` for both parties

#### phone:server:endCall

End the current call.

**Parameters:** None

**Response:** Triggers `phone:client:callEnded` for both parties

### Bank

#### phone:server:getBankBalance

Get player's bank balance.

**Parameters:** None

**Response:** Triggers `phone:client:receiveBankBalance` with balance

#### phone:server:transferMoney

Transfer money to another player.

**Parameters:**
- `targetNumber` (string) - Recipient phone number
- `amount` (number) - Amount to transfer

**Response:** Triggers `phone:client:transferComplete` or `phone:client:transferFailed`

### Twitter

#### phone:server:getTweets

Get recent tweets.

**Parameters:** None

**Response:** Triggers `phone:client:receiveTweets` with tweet array

#### phone:server:postTweet

Post a new tweet.

**Parameters:**
- `content` (string) - Tweet content

**Response:** Triggers `phone:client:tweetPosted` for all players

#### phone:server:likeTweet

Like a tweet.

**Parameters:**
- `tweetId` (number) - Tweet ID

**Response:** Triggers `phone:client:tweetLiked` for all players

### Crypto

#### phone:server:getCryptoPrices

Get current crypto prices.

**Parameters:** None

**Response:** Triggers `phone:client:receiveCryptoPrices` with price data

#### phone:server:getCryptoPortfolio

Get player's crypto holdings.

**Parameters:** None

**Response:** Triggers `phone:client:receiveCryptoPortfolio` with holdings

#### phone:server:buyCrypto

Buy cryptocurrency.

**Parameters:**
- `cryptoType` (string) - Crypto symbol
- `amount` (number) - Amount to buy

**Response:** Triggers `phone:client:cryptoPurchased` or `phone:client:cryptoError`

#### phone:server:sellCrypto

Sell cryptocurrency.

**Parameters:**
- `cryptoType` (string) - Crypto symbol
- `amount` (number) - Amount to sell

**Response:** Triggers `phone:client:cryptoSold` or `phone:client:cryptoError`

## Client Event API

Client events are triggered from the server and handled on the client.

### Event Format

```lua
-- Server triggers
TriggerClientEvent('eventName', source, param1, param2, ...)

-- Client handles
RegisterNetEvent('eventName', function(param1, param2, ...)
    -- Handle event
end)
```

### Phone Control

#### phone:client:openPhone

Open the phone interface.

**Parameters:** None

#### phone:client:closePhone

Close the phone interface.

**Parameters:** None

### Contacts

#### phone:client:receiveContacts

Receive contact list.

**Parameters:**
- `contacts` (table) - Array of contact objects

**Contact Object:**
```lua
{
    id = number,
    owner_number = string,
    contact_name = string,
    contact_number = string,
    created_at = string
}
```

#### phone:client:contactAdded

New contact added.

**Parameters:**
- `contact` (table) - Contact object

#### phone:client:contactUpdated

Contact updated.

**Parameters:**
- `contact` (table) - Updated contact object

#### phone:client:contactDeleted

Contact deleted.

**Parameters:**
- `contactId` (number) - Deleted contact ID

### Messages

#### phone:client:receiveMessages

Receive message list.

**Parameters:**
- `messages` (table) - Array of message objects

**Message Object:**
```lua
{
    id = number,
    sender_number = string,
    receiver_number = string,
    message = string,
    is_read = boolean,
    created_at = string
}
```

#### phone:client:receiveMessage

Receive a new message.

**Parameters:**
- `message` (table) - Message object

#### phone:client:messageSent

Message sent confirmation.

**Parameters:**
- `message` (table) - Sent message object

### Calls

#### phone:client:incomingCall

Incoming call notification.

**Parameters:**
- `callData` (table) - Call information

**Call Data:**
```lua
{
    callId = string,
    callerNumber = string,
    callerName = string
}
```

#### phone:client:callAnswered

Call was answered.

**Parameters:**
- `callData` (table) - Call information

#### phone:client:callEnded

Call ended.

**Parameters:** None

#### phone:client:callBusy

Recipient is busy.

**Parameters:**
- `message` (string) - Busy message

### Bank

#### phone:client:receiveBankBalance

Receive bank balance.

**Parameters:**
- `balance` (number) - Current balance

#### phone:client:transferComplete

Money transfer completed.

**Parameters:**
- `data` (table) - Transfer details

**Transfer Data:**
```lua
{
    amount = number,
    recipient = string,
    newBalance = number
}
```

#### phone:client:transferFailed

Money transfer failed.

**Parameters:**
- `reason` (string) - Failure reason

### Twitter

#### phone:client:receiveTweets

Receive tweet feed.

**Parameters:**
- `tweets` (table) - Array of tweet objects

**Tweet Object:**
```lua
{
    id = number,
    author_number = string,
    author_name = string,
    content = string,
    likes = number,
    created_at = string
}
```

#### phone:client:tweetPosted

New tweet posted.

**Parameters:**
- `tweet` (table) - Tweet object

#### phone:client:tweetLiked

Tweet liked.

**Parameters:**
- `tweetId` (number) - Tweet ID
- `likes` (number) - New like count

### Crypto

#### phone:client:receiveCryptoPrices

Receive crypto prices.

**Parameters:**
- `prices` (table) - Price data

**Price Data:**
```lua
{
    BTC = number,
    ETH = number,
    DOGE = number
}
```

#### phone:client:receiveCryptoPortfolio

Receive crypto holdings.

**Parameters:**
- `portfolio` (table) - Array of holdings

**Holding Object:**
```lua
{
    crypto_type = string,
    amount = number
}
```

#### phone:client:cryptoPurchased

Crypto purchased.

**Parameters:**
- `data` (table) - Purchase details

#### phone:client:cryptoSold

Crypto sold.

**Parameters:**
- `data` (table) - Sale details

#### phone:client:cryptoError

Crypto operation error.

**Parameters:**
- `error` (string) - Error message

## Framework Adapter API

The framework adapter interface that must be implemented for custom frameworks.

### Interface Methods

#### Framework:Init()

Initialize the framework adapter.

**Returns:** None

**Example:**
```lua
function Framework:Init()
    self.Core = exports['my-framework']:GetCore()
end
```

#### Framework:GetPlayer(source)

Get player object by server ID.

**Parameters:**
- `source` (number) - Player server ID

**Returns:** Player object or nil

**Example:**
```lua
function Framework:GetPlayer(source)
    return self.Core.Functions.GetPlayer(source)
end
```

#### Framework:GetIdentifier(source)

Get unique identifier for player.

**Parameters:**
- `source` (number) - Player server ID

**Returns:** String identifier or nil

**Example:**
```lua
function Framework:GetIdentifier(source)
    local player = self:GetPlayer(source)
    return player and player.PlayerData.citizenid or nil
end
```

#### Framework:GetPhoneNumber(source)

Get player's phone number.

**Parameters:**
- `source` (number) - Player server ID

**Returns:** String phone number or nil

**Example:**
```lua
function Framework:GetPhoneNumber(source)
    local player = self:GetPlayer(source)
    return player and player.PlayerData.charinfo.phone or nil
end
```

#### Framework:SetPhoneNumber(source, number)

Set player's phone number.

**Parameters:**
- `source` (number) - Player server ID
- `number` (string) - Phone number to set

**Returns:** Boolean success

**Example:**
```lua
function Framework:SetPhoneNumber(source, number)
    local player = self:GetPlayer(source)
    if not player then return false end
    player.Functions.SetCharInfo('phone', number)
    return true
end
```

#### Framework:GetPlayerMoney(source, account)

Get player's money amount.

**Parameters:**
- `source` (number) - Player server ID
- `account` (string) - Account type ('bank' or 'cash')

**Returns:** Number amount

**Example:**
```lua
function Framework:GetPlayerMoney(source, account)
    local player = self:GetPlayer(source)
    if not player then return 0 end
    account = account or 'bank'
    return player.PlayerData.money[account] or 0
end
```

#### Framework:AddMoney(source, amount, account)

Add money to player.

**Parameters:**
- `source` (number) - Player server ID
- `amount` (number) - Amount to add
- `account` (string) - Account type

**Returns:** Boolean success

**Example:**
```lua
function Framework:AddMoney(source, amount, account)
    local player = self:GetPlayer(source)
    if not player then return false end
    account = account or 'bank'
    player.Functions.AddMoney(account, amount)
    return true
end
```

#### Framework:RemoveMoney(source, amount, account)

Remove money from player.

**Parameters:**
- `source` (number) - Player server ID
- `amount` (number) - Amount to remove
- `account` (string) - Account type

**Returns:** Boolean success

**Example:**
```lua
function Framework:RemoveMoney(source, amount, account)
    local player = self:GetPlayer(source)
    if not player then return false end
    account = account or 'bank'
    if self:GetPlayerMoney(source, account) < amount then
        return false
    end
    player.Functions.RemoveMoney(account, amount)
    return true
end
```

#### Framework:GetJob(source)

Get player's job information.

**Parameters:**
- `source` (number) - Player server ID

**Returns:** Table with job data or nil

**Job Data:**
```lua
{
    name = string,
    label = string,
    grade = number,
    grade_name = string
}
```

**Example:**
```lua
function Framework:GetJob(source)
    local player = self:GetPlayer(source)
    if not player then return nil end
    local job = player.PlayerData.job
    return {
        name = job.name,
        label = job.label,
        grade = job.grade.level,
        grade_name = job.grade.name
    }
end
```

#### Framework:GetPlayerName(source)

Get player's name.

**Parameters:**
- `source` (number) - Player server ID

**Returns:** String name

**Example:**
```lua
function Framework:GetPlayerName(source)
    local player = self:GetPlayer(source)
    if not player then return GetPlayerName(source) end
    local charinfo = player.PlayerData.charinfo
    return charinfo.firstname .. ' ' .. charinfo.lastname
end
```

#### Framework:IsPlayerOnline(source)

Check if player is online.

**Parameters:**
- `source` (number) - Player server ID

**Returns:** Boolean

**Example:**
```lua
function Framework:IsPlayerOnline(source)
    return self:GetPlayer(source) ~= nil
end
```

## Export Functions

Exports allow other resources to interact with the phone system.

### Client Exports

#### OpenPhone

Open the phone interface programmatically.

**Usage:**
```lua
exports['fivem-smartphone-nui']:OpenPhone()
```

#### ClosePhone

Close the phone interface programmatically.

**Usage:**
```lua
exports['fivem-smartphone-nui']:ClosePhone()
```

#### IsPhoneOpen

Check if phone is currently open.

**Usage:**
```lua
local isOpen = exports['fivem-smartphone-nui']:IsPhoneOpen()
```

**Returns:** Boolean

#### SendNotification

Send a notification to the phone.

**Usage:**
```lua
exports['fivem-smartphone-nui']:SendNotification({
    title = 'Notification Title',
    message = 'Notification message',
    type = 'info', -- 'info', 'success', 'warning', 'error'
    duration = 5000 -- milliseconds
})
```

### Server Exports

#### GetPlayerPhoneNumber

Get a player's phone number.

**Usage:**
```lua
local phoneNumber = exports['fivem-smartphone-nui']:GetPlayerPhoneNumber(source)
```

**Parameters:**
- `source` (number) - Player server ID

**Returns:** String phone number or nil

#### GetPlayerByPhoneNumber

Get player source by phone number.

**Usage:**
```lua
local source = exports['fivem-smartphone-nui']:GetPlayerByPhoneNumber('555-1234')
```

**Parameters:**
- `phoneNumber` (string) - Phone number

**Returns:** Number source or nil

#### SendMessage

Send a message between players programmatically.

**Usage:**
```lua
exports['fivem-smartphone-nui']:SendMessage(senderNumber, receiverNumber, message)
```

**Parameters:**
- `senderNumber` (string) - Sender phone number
- `receiverNumber` (string) - Receiver phone number
- `message` (string) - Message content

**Returns:** Boolean success

## Data Structures

### Configuration Object

```lua
Config = {
    Framework = 'standalone',
    OpenKey = 'M',
    PhoneNumberFormat = '###-####',
    PhoneNumberLength = 7,
    GenerateRandomNumbers = true,
    EnabledApps = {
        contacts = true,
        messages = true,
        dialer = true,
        bank = true,
        twitter = true,
        crypto = true
    },
    NotificationDuration = 5000,
    NotificationPosition = 'top-right',
    MaxMessageLength = 500,
    MessageCooldown = 1000,
    CallTimeout = 30000,
    MaxCallDuration = 3600000,
    VoiceResource = 'pma-voice',
    CallChannelPrefix = 'phone_call_',
    DatabaseResource = 'oxmysql',
    CryptoUpdateInterval = 60000,
    AvailableCryptos = {
        { name = 'Bitcoin', symbol = 'BTC', basePrice = 50000 },
        { name = 'Ethereum', symbol = 'ETH', basePrice = 3000 },
        { name = 'Dogecoin', symbol = 'DOGE', basePrice = 0.25 }
    },
    MaxTweetLength = 280,
    TweetCooldown = 5000,
    MaxFeedItems = 50,
    DatabaseCacheTime = 300000,
    MaxEventsPerSecond = 10
}
```

### Error Response Format

```lua
{
    success = false,
    error = 'ERROR_CODE',
    message = 'User-friendly error message'
}
```

### Success Response Format

```lua
{
    success = true,
    data = { ... } -- Optional data
}
```

## Rate Limiting

The resource implements rate limiting to prevent abuse:

- Maximum 10 events per player per second
- Message cooldown: 1 second between messages
- Tweet cooldown: 5 seconds between tweets
- Call timeout: 30 seconds for unanswered calls

## Error Codes

```lua
ERROR_CODES = {
    PLAYER_NOT_FOUND = 'Player not found',
    INVALID_PHONE_NUMBER = 'Invalid phone number format',
    INSUFFICIENT_FUNDS = 'Insufficient funds',
    DATABASE_ERROR = 'Database operation failed',
    PLAYER_BUSY = 'Player is busy',
    RATE_LIMIT = 'Too many requests',
    INVALID_INPUT = 'Invalid input data',
    PERMISSION_DENIED = 'Permission denied',
    RESOURCE_NOT_FOUND = 'Resource not found'
}
```

## Best Practices

1. **Always validate input** on both client and server
2. **Use try-catch** for async operations
3. **Implement rate limiting** for user actions
4. **Cache frequently accessed data** to reduce database queries
5. **Use parameterized queries** to prevent SQL injection
6. **Verify player ownership** before operations
7. **Provide user feedback** for all actions
8. **Handle errors gracefully** with user-friendly messages
9. **Log errors** for debugging
10. **Test thoroughly** before deployment
