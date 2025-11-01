-- Configuration Validator for LB-GPhone
-- Validates all configuration settings on resource start
-- Ensures proper setup and prevents runtime errors due to invalid configuration

local ConfigValidator = {}

-- Validation results storage
ConfigValidator.errors = {}
ConfigValidator.warnings = {}
ConfigValidator.isValid = true

-- Color codes for console output
local COLOR_RED = '^1'
local COLOR_YELLOW = '^3'
local COLOR_GREEN = '^2'
local COLOR_WHITE = '^7'
local COLOR_CYAN = '^5'

-- Helper function to add error
local function AddError(message)
    table.insert(ConfigValidator.errors, message)
    ConfigValidator.isValid = false
    print(COLOR_RED .. '[Phone Config] ERROR: ' .. COLOR_WHITE .. message)
end

-- Helper function to add warning
local function AddWarning(message)
    table.insert(ConfigValidator.warnings, message)
    print(COLOR_YELLOW .. '[Phone Config] WARNING: ' .. COLOR_WHITE .. message)
end

-- Helper function to add success message
local function AddSuccess(message)
    print(COLOR_GREEN .. '[Phone Config] ✓ ' .. COLOR_WHITE .. message)
end

-- Validate language settings
function ConfigValidator.ValidateLanguageSettings()
    print(COLOR_CYAN .. '[Phone Config] Validating language settings...' .. COLOR_WHITE)
    
    -- Check if Config.Locale exists
    if not Config.Locale then
        AddError('Config.Locale is not defined')
        return false
    end
    
    -- Check if Config.Locale is a string
    if type(Config.Locale) ~= 'string' then
        AddError('Config.Locale must be a string, got ' .. type(Config.Locale))
        return false
    end
    
    -- Check if Config.SupportedLocales exists
    if not Config.SupportedLocales then
        AddError('Config.SupportedLocales is not defined')
        return false
    end
    
    -- Check if Config.SupportedLocales is a table
    if type(Config.SupportedLocales) ~= 'table' then
        AddError('Config.SupportedLocales must be a table, got ' .. type(Config.SupportedLocales))
        return false
    end
    
    -- Check if Config.SupportedLocales is not empty
    if #Config.SupportedLocales == 0 then
        AddError('Config.SupportedLocales cannot be empty')
        return false
    end
    
    -- Validate that Config.Locale is in Config.SupportedLocales
    local localeSupported = false
    for _, locale in ipairs(Config.SupportedLocales) do
        if locale == Config.Locale then
            localeSupported = true
            break
        end
    end
    
    if not localeSupported then
        AddError('Config.Locale "' .. Config.Locale .. '" is not in Config.SupportedLocales')
        return false
    end
    
    -- Validate each supported locale format
    local validLocalePattern = '^[a-z][a-z]$' -- Two lowercase letters (e.g., 'en', 'ja')
    for _, locale in ipairs(Config.SupportedLocales) do
        if type(locale) ~= 'string' then
            AddError('Locale in Config.SupportedLocales must be string, got ' .. type(locale))
            return false
        end
        
        if not string.match(locale, validLocalePattern) then
            AddWarning('Locale "' .. locale .. '" does not match standard format (two lowercase letters)')
        end
    end
    
    -- Check Internationalization settings if they exist
    if Config.Internationalization then
        if Config.Internationalization.enabled ~= nil and type(Config.Internationalization.enabled) ~= 'boolean' then
            AddError('Config.Internationalization.enabled must be a boolean')
            return false
        end
        
        if Config.Internationalization.defaultLocale and Config.Internationalization.defaultLocale ~= Config.Locale then
            AddWarning('Config.Internationalization.defaultLocale differs from Config.Locale')
        end
        
        if Config.Internationalization.fallbackLocale then
            local fallbackFound = false
            for _, locale in ipairs(Config.SupportedLocales) do
                if locale == Config.Internationalization.fallbackLocale then
                    fallbackFound = true
                    break
                end
            end
            if not fallbackFound then
                AddError('Config.Internationalization.fallbackLocale "' .. Config.Internationalization.fallbackLocale .. '" is not in Config.SupportedLocales')
                return false
            end
        end
    end
    
    AddSuccess('Language settings validated')
    return true
end

-- Validate currency configuration
function ConfigValidator.ValidateCurrencyConfiguration()
    print(COLOR_CYAN .. '[Phone Config] Validating currency configuration...' .. COLOR_WHITE)
    
    -- Check if Config.Currency exists
    if not Config.Currency then
        AddError('Config.Currency is not defined')
        return false
    end
    
    -- Check if Config.Currency is a table
    if type(Config.Currency) ~= 'table' then
        AddError('Config.Currency must be a table, got ' .. type(Config.Currency))
        return false
    end
    
    -- Validate enabled flag
    if Config.Currency.enabled ~= nil and type(Config.Currency.enabled) ~= 'boolean' then
        AddError('Config.Currency.enabled must be a boolean')
        return false
    end
    
    -- Skip validation if currency system is disabled
    if Config.Currency.enabled == false then
        return true
    end
    
    -- Check if Currency table is properly loaded
    -- Note: maxValue can be 0 (falsy) but still valid, so check for nil explicitly
    if Config.Currency.maxValue == nil then
        AddWarning('Config.Currency.maxValue is not defined, skipping currency validation')
        return true
    end
    
    -- Validate maxValue (optional if currency is disabled)
    if not Config.Currency.maxValue then
        if Config.Currency.enabled == true then
            AddError('Config.Currency.maxValue is not defined but currency is enabled')
            return false
        end
        -- If enabled is nil/not set, just warn and continue
        AddWarning('Config.Currency.maxValue is not defined, currency features may not work')
        return true
    end
    
    if type(Config.Currency.maxValue) ~= 'number' then
        AddError('Config.Currency.maxValue must be a number, got ' .. type(Config.Currency.maxValue))
        return false
    end
    
    -- Check if maxValue is within acceptable range (up to 999 trillion)
    local MAX_ALLOWED = 999000000000000
    if Config.Currency.maxValue > MAX_ALLOWED then
        AddError('Config.Currency.maxValue exceeds maximum allowed value of 999,000,000,000,000')
        return false
    end
    
    if Config.Currency.maxValue <= 0 then
        AddError('Config.Currency.maxValue must be greater than 0')
        return false
    end
    
    -- Validate localeSettings
    if not Config.Currency.localeSettings then
        AddError('Config.Currency.localeSettings is not defined')
        return false
    end
    
    if type(Config.Currency.localeSettings) ~= 'table' then
        AddError('Config.Currency.localeSettings must be a table, got ' .. type(Config.Currency.localeSettings))
        return false
    end
    
    -- Validate that each supported locale has currency settings
    for _, locale in ipairs(Config.SupportedLocales) do
        local currencyConfig = Config.Currency.localeSettings[locale]
        
        if not currencyConfig then
            AddError('Missing currency configuration for locale: ' .. locale)
            return false
        end
        
        -- Validate currency symbol
        if not currencyConfig.symbol then
            AddError('Missing currency symbol for locale: ' .. locale)
            return false
        end
        
        if type(currencyConfig.symbol) ~= 'string' then
            AddError('Currency symbol must be a string for locale: ' .. locale)
            return false
        end
        
        -- Validate position
        if not currencyConfig.position then
            AddError('Missing currency position for locale: ' .. locale)
            return false
        end
        
        if currencyConfig.position ~= 'before' and currencyConfig.position ~= 'after' then
            AddError('Currency position must be "before" or "after" for locale: ' .. locale)
            return false
        end
        
        -- Validate decimalPlaces
        if currencyConfig.decimalPlaces == nil then
            AddError('Missing decimalPlaces for locale: ' .. locale)
            return false
        end
        
        if type(currencyConfig.decimalPlaces) ~= 'number' then
            AddError('decimalPlaces must be a number for locale: ' .. locale)
            return false
        end
        
        if currencyConfig.decimalPlaces < 0 or currencyConfig.decimalPlaces > 8 then
            AddError('decimalPlaces must be between 0 and 8 for locale: ' .. locale)
            return false
        end
        
        -- Validate thousandsSeparator
        if not currencyConfig.thousandsSeparator then
            AddError('Missing thousandsSeparator for locale: ' .. locale)
            return false
        end
        
        if type(currencyConfig.thousandsSeparator) ~= 'string' then
            AddError('thousandsSeparator must be a string for locale: ' .. locale)
            return false
        end
        
        -- Validate decimalSeparator
        if not currencyConfig.decimalSeparator then
            AddError('Missing decimalSeparator for locale: ' .. locale)
            return false
        end
        
        if type(currencyConfig.decimalSeparator) ~= 'string' then
            AddError('decimalSeparator must be a string for locale: ' .. locale)
            return false
        end
        
        -- Warn if thousandsSeparator and decimalSeparator are the same
        if currencyConfig.thousandsSeparator == currencyConfig.decimalSeparator then
            AddWarning('thousandsSeparator and decimalSeparator are the same for locale: ' .. locale)
        end
        
        -- Validate format if it exists
        if currencyConfig.format then
            if type(currencyConfig.format) ~= 'string' then
                AddError('Currency format must be a string for locale: ' .. locale)
                return false
            end
        end
    end
    
    -- Validate optional flags
    if Config.Currency.enableValidation ~= nil and type(Config.Currency.enableValidation) ~= 'boolean' then
        AddError('Config.Currency.enableValidation must be a boolean')
        return false
    end
    
    if Config.Currency.enableFormatting ~= nil and type(Config.Currency.enableFormatting) ~= 'boolean' then
        AddError('Config.Currency.enableFormatting must be a boolean')
        return false
    end
    
    if Config.Currency.enableAbbreviation ~= nil and type(Config.Currency.enableAbbreviation) ~= 'boolean' then
        AddError('Config.Currency.enableAbbreviation must be a boolean')
        return false
    end
    
    if Config.Currency.abbreviationThreshold then
        if type(Config.Currency.abbreviationThreshold) ~= 'number' then
            AddError('Config.Currency.abbreviationThreshold must be a number')
            return false
        end
        
        if Config.Currency.abbreviationThreshold < 0 then
            AddError('Config.Currency.abbreviationThreshold must be greater than or equal to 0')
            return false
        end
    end
    
    AddSuccess('Currency configuration validated')
    return true
end

-- Validate enabled apps configuration
function ConfigValidator.ValidateEnabledApps()
    print(COLOR_CYAN .. '[Phone Config] Validating enabled apps configuration...' .. COLOR_WHITE)
    
    -- Check if Config.EnabledApps exists
    if not Config.EnabledApps then
        AddError('Config.EnabledApps is not defined')
        return false
    end
    
    -- Check if Config.EnabledApps is a table
    if type(Config.EnabledApps) ~= 'table' then
        AddError('Config.EnabledApps must be a table, got ' .. type(Config.EnabledApps))
        return false
    end
    
    -- List of all available apps
    local availableApps = {
        -- Core Communication
        'contacts', 'messages', 'dialer',
        -- Media
        'camera', 'photos', 'voice_recorder',
        -- Utilities
        'settings', 'clock', 'notes', 'maps', 'weather', 'appstore',
        -- Vehicle & Property
        'garage', 'home',
        -- Social Media
        'shotz', 'chirper', 'modish', 'flicker',
        -- Commerce
        'marketplace', 'pages',
        -- Finance
        'bank', 'bankr', 'wallet', 'crypto', 'cryptox',
        -- Entertainment
        'musicly',
        -- Safety
        'finder', 'safezone',
        -- Productivity
        'voicerecorder'
    }
    
    -- Validate each app entry
    local appCount = 0
    for appName, enabled in pairs(Config.EnabledApps) do
        appCount = appCount + 1
        
        -- Check if app name is valid
        local isValidApp = false
        for _, validApp in ipairs(availableApps) do
            if validApp == appName then
                isValidApp = true
                break
            end
        end
        
        if not isValidApp then
            AddWarning('Unknown app in Config.EnabledApps: ' .. appName)
        end
        
        -- Check if enabled value is boolean
        if type(enabled) ~= 'boolean' then
            AddError('Config.EnabledApps.' .. appName .. ' must be a boolean, got ' .. type(enabled))
            return false
        end
    end
    
    -- Check if at least some apps are enabled
    if appCount == 0 then
        AddWarning('Config.EnabledApps is empty - no apps will be available')
    end
    
    -- Check if core apps are enabled
    local coreApps = {'contacts', 'messages', 'dialer', 'settings'}
    for _, coreApp in ipairs(coreApps) do
        if Config.EnabledApps[coreApp] == false then
            AddWarning('Core app "' .. coreApp .. '" is disabled - this may affect functionality')
        end
    end
    
    -- Validate app-specific configurations
    local appConfigs = {
        'BankApp', 'ChirperApp', 'CryptoApp', 'CameraApp', 'PhotosApp',
        'ClockApp', 'NotesApp', 'MapsApp', 'WeatherApp', 'AppStoreApp',
        'GarageApp', 'HomeApp', 'ShotzApp', 'ModishApp', 'FlickerApp',
        'MarketplaceApp', 'PagesApp', 'BankrApp', 'CryptoXApp', 'MusiclyApp',
        'FinderApp', 'SafeZoneApp', 'VoiceRecorderApp', 'SettingsApp'
    }
    
    for _, configName in ipairs(appConfigs) do
        if Config[configName] then
            if type(Config[configName]) ~= 'table' then
                AddError('Config.' .. configName .. ' must be a table')
                return false
            end
            
            -- Validate enabled flag if it exists
            if Config[configName].enabled ~= nil and type(Config[configName].enabled) ~= 'boolean' then
                AddError('Config.' .. configName .. '.enabled must be a boolean')
                return false
            end
        end
    end
    
    AddSuccess('Enabled apps configuration validated')
    return true
end

-- Validate framework configuration
function ConfigValidator.ValidateFrameworkConfiguration()
    print(COLOR_CYAN .. '[Phone Config] Validating framework configuration...' .. COLOR_WHITE)
    
    if not Config.Framework then
        AddError('Config.Framework is not defined')
        return false
    end
    
    local validFrameworks = {'standalone', 'esx', 'qbcore', 'qbox'}
    local isValidFramework = false
    
    for _, framework in ipairs(validFrameworks) do
        if Config.Framework == framework then
            isValidFramework = true
            break
        end
    end
    
    if not isValidFramework then
        AddError('Config.Framework must be one of: ' .. table.concat(validFrameworks, ', '))
        return false
    end
    
    AddSuccess('Framework configuration validated')
    return true
end

-- Validate database configuration
function ConfigValidator.ValidateDatabaseConfiguration()
    print(COLOR_CYAN .. '[Phone Config] Validating database configuration...' .. COLOR_WHITE)
    
    if not Config.DatabaseResource then
        AddError('Config.DatabaseResource is not defined')
        return false
    end
    
    if type(Config.DatabaseResource) ~= 'string' then
        AddError('Config.DatabaseResource must be a string')
        return false
    end
    
    if Config.CreateTablesOnStart ~= nil and type(Config.CreateTablesOnStart) ~= 'boolean' then
        AddError('Config.CreateTablesOnStart must be a boolean')
        return false
    end
    
    AddSuccess('Database configuration validated')
    return true
end

-- Validate integration settings
function ConfigValidator.ValidateIntegrations()
    print(COLOR_CYAN .. '[Phone Config] Validating integration settings...' .. COLOR_WHITE)
    
    if Config.Integrations then
        if type(Config.Integrations) ~= 'table' then
            AddError('Config.Integrations must be a table')
            return false
        end
        
        -- Validate housing integration
        if Config.Integrations.housing then
            if type(Config.Integrations.housing) ~= 'table' then
                AddError('Config.Integrations.housing must be a table')
                return false
            end
            
            if Config.Integrations.housing.enabled ~= nil and type(Config.Integrations.housing.enabled) ~= 'boolean' then
                AddError('Config.Integrations.housing.enabled must be a boolean')
                return false
            end
        end
        
        -- Validate garage integration
        if Config.Integrations.garage then
            if type(Config.Integrations.garage) ~= 'table' then
                AddError('Config.Integrations.garage must be a table')
                return false
            end
            
            if Config.Integrations.garage.enabled ~= nil and type(Config.Integrations.garage.enabled) ~= 'boolean' then
                AddError('Config.Integrations.garage.enabled must be a boolean')
                return false
            end
        end
    end
    
    AddSuccess('Integration settings validated')
    return true
end

-- Main validation function
function ConfigValidator.ValidateAll()
    print(COLOR_CYAN .. '========================================' .. COLOR_WHITE)
    print(COLOR_CYAN .. '[Phone Config] Starting configuration validation...' .. COLOR_WHITE)
    print(COLOR_CYAN .. '========================================' .. COLOR_WHITE)
    
    -- Reset validation state
    ConfigValidator.errors = {}
    ConfigValidator.warnings = {}
    ConfigValidator.isValid = true
    
    -- Run all validations
    local validations = {
        ConfigValidator.ValidateFrameworkConfiguration,
        ConfigValidator.ValidateDatabaseConfiguration,
        ConfigValidator.ValidateLanguageSettings,
        ConfigValidator.ValidateCurrencyConfiguration,
        ConfigValidator.ValidateEnabledApps,
        ConfigValidator.ValidateIntegrations
    }
    
    for _, validation in ipairs(validations) do
        local success, err = pcall(validation)
        if not success then
            AddError('Validation function failed: ' .. tostring(err))
        end
    end
    
    -- Print summary
    print(COLOR_CYAN .. '========================================' .. COLOR_WHITE)
    print(COLOR_CYAN .. '[Phone Config] Validation Summary' .. COLOR_WHITE)
    print(COLOR_CYAN .. '========================================' .. COLOR_WHITE)
    
    if #ConfigValidator.errors > 0 then
        print(COLOR_RED .. '[Phone Config] Found ' .. #ConfigValidator.errors .. ' error(s):' .. COLOR_WHITE)
        for i, error in ipairs(ConfigValidator.errors) do
            print(COLOR_RED .. '  ' .. i .. '. ' .. error .. COLOR_WHITE)
        end
    end
    
    if #ConfigValidator.warnings > 0 then
        print(COLOR_YELLOW .. '[Phone Config] Found ' .. #ConfigValidator.warnings .. ' warning(s):' .. COLOR_WHITE)
        for i, warning in ipairs(ConfigValidator.warnings) do
            print(COLOR_YELLOW .. '  ' .. i .. '. ' .. warning .. COLOR_WHITE)
        end
    end
    
    if ConfigValidator.isValid then
        print(COLOR_GREEN .. '[Phone Config] ✓ Configuration validation passed!' .. COLOR_WHITE)
    else
        print(COLOR_RED .. '[Phone Config] ✗ Configuration validation failed!' .. COLOR_WHITE)
        print(COLOR_RED .. '[Phone Config] Please fix the errors above before starting the resource.' .. COLOR_WHITE)
    end
    
    print(COLOR_CYAN .. '========================================' .. COLOR_WHITE)
    
    return ConfigValidator.isValid
end

-- Get validation results
function ConfigValidator.GetResults()
    return {
        isValid = ConfigValidator.isValid,
        errors = ConfigValidator.errors,
        warnings = ConfigValidator.warnings
    }
end

return ConfigValidator
