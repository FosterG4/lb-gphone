-- Server-side Locale System for LB-GPhone
-- Handles internationalization for server messages and notifications

-- Global locale storage
Locales = {}
Config = Config or {}

-- Default locale configuration
Config.Locale = Config.Locale or 'en'
Config.SupportedLocales = {
    'en', 'ja', 'es', 'fr', 'de', 'pt'
}

-- Currency configuration per locale
Config.Currency = {
    ['en'] = {
        symbol = '$',
        position = 'before', -- 'before' or 'after'
        decimal_places = 2,
        thousand_separator = ',',
        decimal_separator = '.',
        max_value = 999000000000000 -- 999 trillion
    },
    ['ja'] = {
        symbol = '¥',
        position = 'before',
        decimal_places = 0,
        thousand_separator = ',',
        decimal_separator = '.',
        max_value = 999000000000000
    },
    ['es'] = {
        symbol = '€',
        position = 'after',
        decimal_places = 2,
        thousand_separator = '.',
        decimal_separator = ',',
        max_value = 999000000000000
    },
    ['fr'] = {
        symbol = '€',
        position = 'after',
        decimal_places = 2,
        thousand_separator = ' ',
        decimal_separator = ',',
        max_value = 999000000000000
    },
    ['de'] = {
        symbol = '€',
        position = 'after',
        decimal_places = 2,
        thousand_separator = '.',
        decimal_separator = ',',
        max_value = 999000000000000
    },
    ['pt'] = {
        symbol = 'R$',
        position = 'before',
        decimal_places = 2,
        thousand_separator = '.',
        decimal_separator = ',',
        max_value = 999000000000000
    }
}

-- Load locale files
local function LoadLocales()
    for _, locale in ipairs(Config.SupportedLocales) do
        local resourceName = GetCurrentResourceName()
        local localeFile = ('server/locales/%s.lua'):format(locale)
        
        -- Check if locale file exists and load it
        local success, err = pcall(function()
            local chunk = LoadResourceFile(resourceName, localeFile)
            if chunk then
                local func = load(chunk)
                if func then
                    func()
                    print(('[LB-GPhone] Loaded locale: %s'):format(locale))
                else
                    print(('[LB-GPhone] Error compiling locale %s: %s'):format(locale, err or 'Unknown error'))
                end
            else
                print(('[LB-GPhone] Locale file not found: %s'):format(localeFile))
            end
        end)
        
        if not success then
            print(('[LB-GPhone] Error loading locale %s: %s'):format(locale, err))
        end
    end
end

-- Get localized string
function _L(key, ...)
    local locale = Config.Locale or 'en'
    
    if Locales[locale] and Locales[locale][key] then
        local str = Locales[locale][key]
        if ... then
            return string.format(str, ...)
        end
        return str
    elseif Locales['en'] and Locales['en'][key] then
        -- Fallback to English
        local str = Locales['en'][key]
        if ... then
            return string.format(str, ...)
        end
        return str
    else
        -- Return key if translation not found
        print(('[LB-GPhone] Missing translation for key: %s (locale: %s)'):format(key, locale))
        return key
    end
end

-- Get player's preferred locale
function GetPlayerLocale(playerId)
    if not playerId then return Config.Locale end
    
    -- Try to get player's locale from database or player data
    -- For now, return default locale
    -- This can be extended to store player preferences in database
    return Config.Locale
end

-- Set server locale
function SetServerLocale(locale)
    if not locale then return false end
    
    -- Validate locale
    local isValid = false
    for _, supportedLocale in ipairs(Config.SupportedLocales) do
        if supportedLocale == locale then
            isValid = true
            break
        end
    end
    
    if not isValid then
        print(('[LB-GPhone] Invalid locale: %s'):format(locale))
        return false
    end
    
    Config.Locale = locale
    print(('[LB-GPhone] Server locale changed to: %s'):format(locale))
    return true
end

-- Format currency based on locale
function FormatCurrency(amount, locale)
    if not amount or type(amount) ~= 'number' then
        return '0'
    end
    
    local currentLocale = locale or Config.Locale or 'en'
    local currencyConfig = Config.Currency[currentLocale] or Config.Currency['en']
    
    -- Validate amount doesn't exceed maximum
    if amount > currencyConfig.max_value then
        amount = currencyConfig.max_value
    end
    
    -- Format the number with proper separators
    local formattedAmount = string.format('%.' .. currencyConfig.decimal_places .. 'f', amount)
    
    -- Add thousand separators (basic implementation)
    local parts = {}
    for part in string.gmatch(formattedAmount, '[^.]+') do
        table.insert(parts, part)
    end
    
    if #parts >= 1 then
        local integerPart = parts[1]
        local decimalPart = parts[2] or ''
        
        -- Add thousand separators to integer part
        local reversedInteger = string.reverse(integerPart)
        local formattedInteger = ''
        for i = 1, #reversedInteger do
            if i > 1 and (i - 1) % 3 == 0 then
                formattedInteger = currencyConfig.thousand_separator .. formattedInteger
            end
            formattedInteger = string.sub(reversedInteger, i, i) .. formattedInteger
        end
        
        -- Combine integer and decimal parts
        if currencyConfig.decimal_places > 0 and decimalPart ~= '' then
            formattedAmount = formattedInteger .. currencyConfig.decimal_separator .. decimalPart
        else
            formattedAmount = formattedInteger
        end
    end
    
    -- Add currency symbol
    if currencyConfig.position == 'before' then
        return currencyConfig.symbol .. formattedAmount
    else
        return formattedAmount .. ' ' .. currencyConfig.symbol
    end
end

-- Validate currency amount
function ValidateCurrency(amount, locale, options)
    options = options or {}
    local allowZero = options.allowZero or false
    local minAmount = options.minAmount or 0
    
    if not amount or type(amount) ~= 'number' then
        return false, _L('currency_invalid_amount'), 'invalidFormat'
    end
    
    if amount ~= amount then -- Check for NaN
        return false, _L('currency_parse_error'), 'parseError'
    end
    
    if amount < 0 then
        return false, _L('currency_negative_amount'), 'negativeAmount'
    end
    
    if not allowZero and amount == 0 then
        return false, _L('currency_below_minimum'), 'belowMinimum'
    end
    
    if amount < minAmount then
        return false, _L('currency_below_minimum'), 'belowMinimum'
    end
    
    local currentLocale = locale or Config.Locale or 'en'
    local currencyConfig = Config.Currency[currentLocale] or Config.Currency['en']
    
    if amount > currencyConfig.max_value then
        return false, _L('currency_limit_exceeded', FormatCurrency(currencyConfig.max_value, currentLocale)), 'exceedsMaximum'
    end
    
    -- Check for too many decimal places
    local decimalPlaces = currencyConfig.decimal_places or 2
    local amountStr = tostring(amount)
    local decimalPos = string.find(amountStr, '%.')
    if decimalPos then
        local decimals = string.len(amountStr) - decimalPos
        if decimals > decimalPlaces then
            return false, _L('currency_too_many_decimals'), 'tooManyDecimals'
        end
    end
    
    return true, nil, nil
end

-- Validate currency transaction
function ValidateTransaction(amount, balance, locale)
    local isValid, errorMsg, errorKey = ValidateCurrency(amount, locale)
    
    if not isValid then
        return false, errorMsg, errorKey
    end
    
    if balance and amount > balance then
        return false, _L('currency_insufficient_funds'), 'insufficientFunds'
    end
    
    return true, nil, nil
end

-- Get currency configuration for locale
function GetCurrencyConfig(locale)
    local currentLocale = locale or Config.Locale or 'en'
    return Config.Currency[currentLocale] or Config.Currency['en']
end

-- Send localized notification to player
function SendLocalizedNotification(playerId, key, ...)
    if not playerId then return end
    
    local playerLocale = GetPlayerLocale(playerId)
    local message = _L(key, ...)
    
    -- Send notification to client
    TriggerClientEvent('lb-gphone:notification', playerId, {
        type = 'info',
        title = 'Phone',
        message = message,
        duration = 5000
    })
end

-- Export functions for other scripts
exports('_L', _L)
exports('GetPlayerLocale', GetPlayerLocale)
exports('SetServerLocale', SetServerLocale)
exports('FormatCurrency', FormatCurrency)
exports('ValidateCurrency', ValidateCurrency)
exports('ValidateTransaction', ValidateTransaction)
exports('GetCurrencyConfig', GetCurrencyConfig)
exports('SendLocalizedNotification', SendLocalizedNotification)

-- Initialize locale system
CreateThread(function()
    LoadLocales()
    print(('[LB-GPhone] Locale system initialized with default locale: %s'):format(Config.Locale))
end)

-- Command to change server locale (admin only)
RegisterCommand('gphone_locale', function(source, args)
    if source == 0 then -- Console command
        if args[1] then
            if SetServerLocale(args[1]) then
                print(('[LB-GPhone] Server locale changed to: %s'):format(args[1]))
            end
        else
            print('[LB-GPhone] Usage: gphone_locale <locale>')
            print('[LB-GPhone] Supported locales: ' .. table.concat(Config.SupportedLocales, ', '))
        end
    else
        -- Check if player has admin permissions (implement your own permission check)
        local playerId = source
        -- if IsPlayerAdmin(playerId) then
        --     if args[1] then
        --         if SetServerLocale(args[1]) then
        --             SendLocalizedNotification(playerId, 'settings_language_changed')
        --         end
        --     end
        -- end
    end
end, false)