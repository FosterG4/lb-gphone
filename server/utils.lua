-- Server Utility Functions
-- Helper functions for server-side operations

-- Error codes
ERROR_CODES = {
    PLAYER_NOT_FOUND = 'PLAYER_NOT_FOUND',
    INVALID_PHONE_NUMBER = 'INVALID_PHONE_NUMBER',
    INVALID_INPUT = 'INVALID_INPUT',
    INSUFFICIENT_FUNDS = 'INSUFFICIENT_FUNDS',
    DATABASE_ERROR = 'DATABASE_ERROR',
    PLAYER_BUSY = 'PLAYER_BUSY',
    RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED',
    UNAUTHORIZED = 'UNAUTHORIZED',
    PHONE_NUMBER_NOT_FOUND = 'PHONE_NUMBER_NOT_FOUND',
    MESSAGE_TOO_LONG = 'MESSAGE_TOO_LONG',
    MESSAGE_EMPTY = 'MESSAGE_EMPTY',
    ALREADY_IN_CALL = 'ALREADY_IN_CALL',
    PLAYER_OFFLINE = 'PLAYER_OFFLINE',
    INVALID_AMOUNT = 'INVALID_AMOUNT',
    CONTENT_TOO_LONG = 'CONTENT_TOO_LONG',
    OPERATION_FAILED = 'OPERATION_FAILED'
}

-- Error messages
ERROR_MESSAGES = {
    [ERROR_CODES.PLAYER_NOT_FOUND] = 'Player not found',
    [ERROR_CODES.INVALID_PHONE_NUMBER] = 'Invalid phone number format',
    [ERROR_CODES.INVALID_INPUT] = 'Invalid input provided',
    [ERROR_CODES.INSUFFICIENT_FUNDS] = 'Insufficient funds',
    [ERROR_CODES.DATABASE_ERROR] = 'Database operation failed',
    [ERROR_CODES.PLAYER_BUSY] = 'Player is busy',
    [ERROR_CODES.RATE_LIMIT_EXCEEDED] = 'Too many requests, please slow down',
    [ERROR_CODES.UNAUTHORIZED] = 'You are not authorized to perform this action',
    [ERROR_CODES.PHONE_NUMBER_NOT_FOUND] = 'Phone number does not exist',
    [ERROR_CODES.MESSAGE_TOO_LONG] = 'Message exceeds maximum length',
    [ERROR_CODES.MESSAGE_EMPTY] = 'Message cannot be empty',
    [ERROR_CODES.ALREADY_IN_CALL] = 'Already in a call',
    [ERROR_CODES.PLAYER_OFFLINE] = 'Player is not available',
    [ERROR_CODES.INVALID_AMOUNT] = 'Invalid amount',
    [ERROR_CODES.CONTENT_TOO_LONG] = 'Content exceeds maximum length',
    [ERROR_CODES.OPERATION_FAILED] = 'Operation failed'
}

-- Validate phone number format
function ValidatePhoneNumber(phoneNumber)
    if not phoneNumber then
        return false, ERROR_CODES.INVALID_PHONE_NUMBER, 'Phone number is required'
    end
    
    -- Convert to string and remove non-digit characters
    local numStr = tostring(phoneNumber):gsub('[^%d]', '')
    
    -- Check length
    if #numStr ~= Config.PhoneNumberLength then
        return false, ERROR_CODES.INVALID_PHONE_NUMBER, 'Invalid phone number length (expected ' .. Config.PhoneNumberLength .. ' digits)'
    end
    
    -- Check if all characters are digits
    if not numStr:match('^%d+$') then
        return false, ERROR_CODES.INVALID_PHONE_NUMBER, 'Phone number must contain only digits'
    end
    
    return true, nil, nil
end

-- Format phone number according to config format
function FormatPhoneNumber(phoneNumber)
    if not phoneNumber then return nil end
    
    -- Remove all non-digit characters
    local numStr = tostring(phoneNumber):gsub('[^%d]', '')
    
    -- If no format specified, return as-is
    if not Config.PhoneNumberFormat or Config.PhoneNumberFormat == '' then
        return numStr
    end
    
    -- Apply format (e.g., "###-####" becomes "123-4567")
    local formatted = Config.PhoneNumberFormat
    local digitIndex = 1
    
    formatted = formatted:gsub('#', function()
        local digit = numStr:sub(digitIndex, digitIndex)
        digitIndex = digitIndex + 1
        return digit
    end)
    
    return formatted
end

-- Generate random phone number
function GeneratePhoneNumber()
    local number = ''
    
    -- Generate random digits
    for i = 1, Config.PhoneNumberLength do
        -- First digit should not be 0
        if i == 1 then
            number = number .. math.random(1, 9)
        else
            number = number .. math.random(0, 9)
        end
    end
    
    return number
end

-- Validate message content
function ValidateMessage(message)
    if not message or message == '' then
        return false, ERROR_CODES.MESSAGE_EMPTY, 'Message cannot be empty'
    end
    
    if type(message) ~= 'string' then
        return false, ERROR_CODES.INVALID_INPUT, 'Message must be a string'
    end
    
    if #message > Config.MaxMessageLength then
        return false, ERROR_CODES.MESSAGE_TOO_LONG, 'Message exceeds maximum length of ' .. Config.MaxMessageLength .. ' characters'
    end
    
    return true, nil, nil
end

-- Validate contact name
function ValidateContactName(name)
    if not name or name == '' then
        return false, ERROR_CODES.INVALID_INPUT, 'Contact name is required'
    end
    
    if type(name) ~= 'string' then
        return false, ERROR_CODES.INVALID_INPUT, 'Contact name must be a string'
    end
    
    if #name > 100 then
        return false, ERROR_CODES.INVALID_INPUT, 'Contact name is too long (max 100 characters)'
    end
    
    return true, nil, nil
end

-- Validate amount (for money transfers, crypto trades)
function ValidateAmount(amount)
    if not amount then
        return false, ERROR_CODES.INVALID_AMOUNT, 'Amount is required'
    end
    
    local numAmount = tonumber(amount)
    if not numAmount then
        return false, ERROR_CODES.INVALID_AMOUNT, 'Amount must be a number'
    end
    
    if numAmount <= 0 then
        return false, ERROR_CODES.INVALID_AMOUNT, 'Amount must be greater than zero'
    end
    
    if numAmount > 999999999 then
        return false, ERROR_CODES.INVALID_AMOUNT, 'Amount is too large'
    end
    
    return true, nil, nil
end

-- Validate tweet/post content
function ValidatePostContent(content, maxLength)
    maxLength = maxLength or 280
    
    if not content or content == '' then
        return false, ERROR_CODES.INVALID_INPUT, 'Content cannot be empty'
    end
    
    if type(content) ~= 'string' then
        return false, ERROR_CODES.INVALID_INPUT, 'Content must be a string'
    end
    
    if #content > maxLength then
        return false, ERROR_CODES.CONTENT_TOO_LONG, 'Content exceeds maximum length of ' .. maxLength .. ' characters'
    end
    
    return true, nil, nil
end

-- Validate crypto type
function ValidateCryptoType(cryptoType)
    if not cryptoType or cryptoType == '' then
        return false, ERROR_CODES.INVALID_INPUT, 'Crypto type is required'
    end
    
    -- Check if crypto type exists in config
    local validCrypto = false
    for _, crypto in ipairs(Config.AvailableCryptos or {}) do
        if crypto.symbol == cryptoType then
            validCrypto = true
            break
        end
    end
    
    if not validCrypto then
        return false, ERROR_CODES.INVALID_INPUT, 'Invalid cryptocurrency type'
    end
    
    return true, nil, nil
end

-- Sanitize input
function SanitizeInput(input)
    if not input then return '' end
    
    -- Remove potentially dangerous characters
    local sanitized = tostring(input)
    
    -- Remove HTML tags and special characters
    sanitized = sanitized:gsub('[<>]', '')
    sanitized = sanitized:gsub('[\'"\\]', '')
    
    -- Trim whitespace
    sanitized = sanitized:match('^%s*(.-)%s*$')
    
    return sanitized
end

-- Sanitize SQL input (additional layer of protection)
function SanitizeSQLInput(input)
    if not input then return '' end
    
    local sanitized = tostring(input)
    
    -- Remove SQL injection attempts
    sanitized = sanitized:gsub('[;\'"`]', '')
    sanitized = sanitized:gsub('%-%-', '')
    sanitized = sanitized:gsub('%/%*', '')
    sanitized = sanitized:gsub('%*%/', '')
    
    return sanitized
end

-- Log debug message
function DebugLog(message)
    if Config.DebugMode then
        print('[Phone Debug] ' .. message)
    end
end

-- Create error response
function ErrorResponse(errorCode, customMessage)
    local message = customMessage or ERROR_MESSAGES[errorCode] or 'An error occurred'
    
    -- Log error for debugging
    if Config.DebugMode then
        print('^1[Phone Error]^7 ' .. errorCode .. ': ' .. message)
    end
    
    return {
        success = false,
        error = errorCode,
        message = message
    }
end

-- Create success response
function SuccessResponse(data)
    return {
        success = true,
        data = data
    }
end

-- Safe database operation wrapper
function SafeDatabaseOperation(operation, params, callback, errorCallback)
    local success, result = pcall(function()
        operation(params, function(data)
            if callback then
                callback(data)
            end
        end)
    end)
    
    if not success then
        print('^1[Phone Database Error]^7 ' .. tostring(result))
        
        if errorCallback then
            errorCallback(ErrorResponse(ERROR_CODES.DATABASE_ERROR, 'Database operation failed'))
        end
        
        return false
    end
    
    return true
end

-- Try-catch wrapper for any function
function TryCatch(func, errorHandler)
    local success, result = pcall(func)
    
    if not success then
        if Config.DebugMode then
            print('^1[Phone Error]^7 ' .. tostring(result))
        end
        
        if errorHandler then
            errorHandler(result)
        end
        
        return false, result
    end
    
    return true, result
end

-- Rate limiting
local rateLimitCache = {}
local rateLimitWarnings = {} -- Track warnings for players

-- Rate limit configuration per action type
local RATE_LIMITS = {
    message = { limit = 5, window = 10000 }, -- 5 messages per 10 seconds
    call = { limit = 3, window = 30000 }, -- 3 calls per 30 seconds
    contact = { limit = 10, window = 60000 }, -- 10 contact operations per minute
    bank = { limit = 5, window = 30000 }, -- 5 bank operations per 30 seconds
    chirper = { limit = 3, window = 60000 }, -- 3 chirps per minute
    crypto = { limit = 10, window = 30000 }, -- 10 crypto trades per 30 seconds
    default = { limit = 10, window = 10000 } -- Default: 10 per 10 seconds
}

function CheckRateLimit(source, action)
    -- Get rate limit config for this action
    local limitConfig = RATE_LIMITS[action] or RATE_LIMITS.default
    
    local key = source .. '_' .. action
    local currentTime = GetGameTimer()
    
    if not rateLimitCache[key] then
        rateLimitCache[key] = {
            count = 1,
            resetTime = currentTime + limitConfig.window,
            lastWarning = 0
        }
        return true, nil
    end
    
    local cache = rateLimitCache[key]
    
    -- Reset counter if time window passed
    if currentTime >= cache.resetTime then
        cache.count = 1
        cache.resetTime = currentTime + limitConfig.window
        cache.lastWarning = 0
        return true, nil
    end
    
    -- Check if limit exceeded
    if cache.count >= limitConfig.limit then
        -- Send warning to player (max once per 5 seconds)
        if currentTime - cache.lastWarning > 5000 then
            cache.lastWarning = currentTime
            
            if Config.DebugMode then
                print('^3[Phone Rate Limit]^7 Player ' .. source .. ' exceeded rate limit for action: ' .. action)
            end
        end
        
        return false, ERROR_CODES.RATE_LIMIT_EXCEEDED
    end
    
    cache.count = cache.count + 1
    return true, nil
end

-- Check specific rate limit for messages
function CheckMessageRateLimit(source)
    return CheckRateLimit(source, 'message')
end

-- Check specific rate limit for calls
function CheckCallRateLimit(source)
    return CheckRateLimit(source, 'call')
end

-- Check specific rate limit for contacts
function CheckContactRateLimit(source)
    return CheckRateLimit(source, 'contact')
end

-- Check specific rate limit for bank operations
function CheckBankRateLimit(source)
    return CheckRateLimit(source, 'bank')
end

-- Check specific rate limit for chirper
function CheckChirperRateLimit(source)
    return CheckRateLimit(source, 'chirper')
end

-- Check specific rate limit for crypto
function CheckCryptoRateLimit(source)
    return CheckRateLimit(source, 'crypto')
end

-- Clean up rate limit cache periodically
CreateThread(function()
    while true do
        Wait(60000) -- Clean every minute
        local currentTime = GetGameTimer()
        
        for key, cache in pairs(rateLimitCache) do
            if currentTime >= cache.resetTime + 60000 then
                rateLimitCache[key] = nil
            end
        end
    end
end)


-- Authorization checks

-- Verify player owns the phone number
function VerifyPhoneOwnership(source, phoneNumber)
    local playerPhone = GetCachedPhoneNumber(source)
    
    if not playerPhone then
        return false, ERROR_CODES.PLAYER_NOT_FOUND, 'Your phone number not found'
    end
    
    if playerPhone ~= phoneNumber then
        return false, ERROR_CODES.UNAUTHORIZED, 'You do not own this phone number'
    end
    
    return true, nil, nil
end

-- Verify player owns a contact
function VerifyContactOwnership(source, contactId, callback)
    local playerPhone = GetCachedPhoneNumber(source)
    
    if not playerPhone then
        callback(false, ERROR_CODES.PLAYER_NOT_FOUND, 'Your phone number not found')
        return
    end
    
    -- Query database to check contact ownership
    local query = 'SELECT owner_number FROM phone_contacts WHERE id = ?'
    
    MySQL.query(query, {contactId}, function(result)
        if not result or #result == 0 then
            callback(false, ERROR_CODES.INVALID_INPUT, 'Contact not found')
            return
        end
        
        if result[1].owner_number ~= playerPhone then
            callback(false, ERROR_CODES.UNAUTHORIZED, 'You do not own this contact')
            return
        end
        
        callback(true, nil, nil)
    end)
end

-- Verify player can send message to target
function VerifyCanSendMessage(source, targetNumber)
    local playerPhone = GetCachedPhoneNumber(source)
    
    if not playerPhone then
        return false, ERROR_CODES.PLAYER_NOT_FOUND, 'Your phone number not found'
    end
    
    if playerPhone == targetNumber then
        return false, ERROR_CODES.INVALID_INPUT, 'Cannot send message to yourself'
    end
    
    return true, nil, nil
end

-- Verify player can initiate call to target
function VerifyCanCall(source, targetNumber)
    local playerPhone = GetCachedPhoneNumber(source)
    
    if not playerPhone then
        return false, ERROR_CODES.PLAYER_NOT_FOUND, 'Your phone number not found'
    end
    
    if playerPhone == targetNumber then
        return false, ERROR_CODES.INVALID_INPUT, 'Cannot call yourself'
    end
    
    return true, nil, nil
end

-- Verify player has sufficient funds
function VerifyFunds(source, amount, account)
    if not Framework then
        return false, ERROR_CODES.OPERATION_FAILED, 'Framework not initialized'
    end
    
    local playerMoney = Framework:GetPlayerMoney(source, account or 'bank')
    
    if not playerMoney then
        return false, ERROR_CODES.OPERATION_FAILED, 'Failed to get player balance'
    end
    
    if playerMoney < amount then
        return false, ERROR_CODES.INSUFFICIENT_FUNDS, 'Insufficient funds'
    end
    
    return true, nil, nil
end

-- Log security event
function LogSecurityEvent(source, eventType, details)
    if Config.DebugMode then
        local playerPhone = GetCachedPhoneNumber(source) or 'unknown'
        print('^3[Phone Security]^7 Player ' .. source .. ' (' .. playerPhone .. ') - ' .. eventType .. ': ' .. details)
    end
end

-- Export utility functions
exports('ValidatePhoneNumber', ValidatePhoneNumber)
exports('ValidateMessage', ValidateMessage)
exports('ValidateContactName', ValidateContactName)
exports('ValidateAmount', ValidateAmount)
exports('ValidatePostContent', ValidatePostContent)
exports('ValidateCryptoType', ValidateCryptoType)
exports('SanitizeInput', SanitizeInput)
exports('ErrorResponse', ErrorResponse)
exports('SuccessResponse', SuccessResponse)
exports('CheckRateLimit', CheckRateLimit)
exports('VerifyPhoneOwnership', VerifyPhoneOwnership)
exports('VerifyFunds', VerifyFunds)
