-- Installation Manager for FiveM Smartphone System
-- Handles automated installation, dependency checking, framework detection, and integration validation

local InstallationManager = {}

-- Installation state
local installationComplete = false
local installationErrors = {}
local installationWarnings = {}

-- Color codes for console output
local COLOR = {
    RESET = '^0',
    RED = '^1',
    GREEN = '^2',
    YELLOW = '^3',
    BLUE = '^4',
    CYAN = '^6',
    WHITE = '^7'
}

-- Print formatted message
local function PrintMessage(color, prefix, message)
    print(color .. '[Phone System] ' .. prefix .. COLOR.WHITE .. message .. COLOR.RESET)
end

local function PrintSuccess(message)
    PrintMessage(COLOR.GREEN, '✓ ', message)
end

local function PrintError(message)
    PrintMessage(COLOR.RED, '✗ ', message)
    table.insert(installationErrors, message)
end

local function PrintWarning(message)
    PrintMessage(COLOR.YELLOW, '⚠ ', message)
    table.insert(installationWarnings, message)
end

local function PrintInfo(message)
    PrintMessage(COLOR.CYAN, 'ℹ ', message)
end

local function PrintHeader(message)
    print('')
    PrintMessage(COLOR.BLUE, '═══ ', message .. ' ═══')
end

-- Check if a resource exists and is started
local function IsResourceAvailable(resourceName)
    if not resourceName or resourceName == '' or resourceName == 'none' then
        return false
    end
    
    local state = GetResourceState(resourceName)
    return state == 'started' or state == 'starting'
end

-- Step 1: Check Dependencies
function InstallationManager:CheckDependencies()
    PrintHeader('Checking Dependencies')
    
    local allDependenciesOk = true
    
    -- Required dependencies
    local requiredDeps = {
        {name = 'oxmysql', description = 'MySQL Database Wrapper'},
        {name = 'pma-voice', description = 'Voice Communication System'}
    }
    
    for _, dep in ipairs(requiredDeps) do
        if IsResourceAvailable(dep.name) then
            PrintSuccess('Found required dependency: ' .. dep.name .. ' (' .. dep.description .. ')')
        else
            PrintError('Missing required dependency: ' .. dep.name .. ' (' .. dep.description .. ')')
            PrintInfo('Please install ' .. dep.name .. ' and restart the server')
            allDependenciesOk = false
        end
    end
    
    -- Optional dependencies
    local optionalDeps = {}
    
    -- Add garage script if configured
    if Config.GarageApp and Config.GarageApp.garageScript and Config.GarageApp.garageScript ~= 'none' then
        table.insert(optionalDeps, {
            name = Config.GarageApp.garageScript,
            description = 'Garage Management Script',
            configKey = 'GarageApp'
        })
    end
    
    -- Add housing script if configured
    if Config.HomeApp and Config.HomeApp.housingScript and Config.HomeApp.housingScript ~= 'none' then
        table.insert(optionalDeps, {
            name = Config.HomeApp.housingScript,
            description = 'Housing Management Script',
            configKey = 'HomeApp'
        })
    end
    
    -- Add banking script if configured
    if Config.BankrApp and Config.BankrApp.bankingScript and Config.BankrApp.bankingScript ~= 'none' then
        table.insert(optionalDeps, {
            name = Config.BankrApp.bankingScript,
            description = 'Banking Script',
            configKey = 'BankrApp'
        })
    end
    
    -- Add audio resource if configured
    if Config.MusiclyApp and Config.MusiclyApp.audioResource and Config.MusiclyApp.audioResource ~= 'none' then
        table.insert(optionalDeps, {
            name = Config.MusiclyApp.audioResource,
            description = 'Audio Streaming Resource',
            configKey = 'MusiclyApp'
        })
    end
    
    -- Check optional dependencies
    if #optionalDeps > 0 then
        print('')
        PrintInfo('Checking optional dependencies...')
        
        for _, dep in ipairs(optionalDeps) do
            if IsResourceAvailable(dep.name) then
                PrintSuccess('Found optional dependency: ' .. dep.name .. ' (' .. dep.description .. ')')
            else
                PrintWarning('Optional dependency not found: ' .. dep.name .. ' (' .. dep.description .. ')')
                PrintInfo('The ' .. dep.configKey .. ' feature will have limited functionality')
            end
        end
    end
    
    return allDependenciesOk
end

-- Step 2: Auto-detect Framework
function InstallationManager:DetectFramework()
    PrintHeader('Detecting Framework')
    
    -- If framework is explicitly set to standalone, skip detection
    if Config.Framework == 'standalone' then
        PrintInfo('Framework explicitly set to: standalone')
        PrintSuccess('Using standalone mode (no framework integration)')
        return true
    end
    
    -- If framework is already explicitly set and not auto, verify it exists
    if Config.Framework and Config.Framework ~= 'auto' then
        PrintInfo('Framework explicitly set to: ' .. Config.Framework)
        
        local frameworkResources = {
            esx = 'es_extended',
            qbcore = 'qb-core',
            qbox = 'qbx_core'
        }
        
        local resourceName = frameworkResources[Config.Framework]
        if resourceName and IsResourceAvailable(resourceName) then
            PrintSuccess('Verified framework: ' .. Config.Framework .. ' (' .. resourceName .. ')')
            return true
        else
            PrintWarning('Configured framework "' .. Config.Framework .. '" not found')
            PrintInfo('Attempting auto-detection...')
        end
    end
    
    -- Auto-detect framework (only if set to 'auto' or verification failed)
    local frameworks = {
        {name = 'es_extended', type = 'esx', description = 'ESX Framework'},
        {name = 'qb-core', type = 'qbcore', description = 'QBCore Framework'},
        {name = 'qbx_core', type = 'qbox', description = 'Qbox Framework'}
    }
    
    for _, fw in ipairs(frameworks) do
        if IsResourceAvailable(fw.name) then
            Config.Framework = fw.type
            PrintSuccess('Auto-detected framework: ' .. fw.description .. ' (' .. fw.name .. ')')
            PrintInfo('Framework set to: ' .. Config.Framework)
            return true
        end
    end
    
    -- No framework detected, use standalone
    Config.Framework = 'standalone'
    PrintWarning('No framework detected')
    PrintInfo('Using standalone mode (no framework integration)')
    
    return true
end

-- Step 3: Create Database Tables
function InstallationManager:CreateDatabaseTables()
    PrintHeader('Creating Database Tables')
    
    if not Config.CreateTablesOnStart then
        PrintInfo('Database table creation is disabled in config')
        PrintInfo('Set Config.CreateTablesOnStart = true to enable automatic table creation')
        return true
    end
    
    PrintInfo('Database tables will be created by the Database module')
    PrintInfo('This process is handled automatically during database initialization')
    PrintSuccess('Database table creation configured')
    
    return true
end

-- Step 4: Validate Integrations
function InstallationManager:ValidateIntegrations()
    PrintHeader('Validating Integrations')
    
    local integrations = {
        {
            name = 'Garage',
            enabled = Config.EnabledApps and Config.EnabledApps.garage,
            script = Config.GarageApp and Config.GarageApp.garageScript,
            appKey = 'garage'
        },
        {
            name = 'Housing',
            enabled = Config.EnabledApps and Config.EnabledApps.home,
            script = Config.HomeApp and Config.HomeApp.housingScript,
            appKey = 'home'
        },
        {
            name = 'Banking',
            enabled = Config.EnabledApps and Config.EnabledApps.bankr,
            script = Config.BankrApp and Config.BankrApp.bankingScript,
            appKey = 'bankr'
        },
        {
            name = 'Audio/Music',
            enabled = Config.EnabledApps and Config.EnabledApps.musicly,
            script = Config.MusiclyApp and Config.MusiclyApp.audioResource,
            appKey = 'musicly'
        }
    }
    
    local hasIntegrationIssues = false
    
    for _, integration in ipairs(integrations) do
        if integration.enabled then
            if integration.script and integration.script ~= 'none' then
                if IsResourceAvailable(integration.script) then
                    PrintSuccess(integration.name .. ' integration: ' .. integration.script .. ' (Active)')
                else
                    PrintWarning(integration.name .. ' integration: ' .. integration.script .. ' (Not Found)')
                    PrintInfo('The ' .. integration.name .. ' app will have limited functionality')
                    PrintInfo('To fix: Install ' .. integration.script .. ' or set script to "none" in config')
                    hasIntegrationIssues = true
                end
            else
                PrintInfo(integration.name .. ' integration: Disabled (script set to "none")')
            end
        else
            PrintInfo(integration.name .. ' app: Disabled in config')
        end
    end
    
    if not hasIntegrationIssues then
        PrintSuccess('All enabled integrations validated successfully')
    end
    
    return true
end

-- Step 5: Validate Configuration
function InstallationManager:ValidateConfiguration()
    PrintHeader('Validating Configuration')
    
    local configIssues = {}
    
    -- Validate locale settings
    if Config.Locale then
        if Config.SupportedLocales then
            local localeSupported = false
            for _, locale in ipairs(Config.SupportedLocales) do
                if locale == Config.Locale then
                    localeSupported = true
                    break
                end
            end
            
            if localeSupported then
                PrintSuccess('Locale configuration valid: ' .. Config.Locale)
            else
                PrintWarning('Default locale "' .. Config.Locale .. '" not in supported locales list')
                table.insert(configIssues, 'Locale configuration mismatch')
            end
        end
    else
        PrintWarning('No default locale configured, using "en"')
        Config.Locale = 'en'
    end
    
    -- Validate currency settings
    if Config.Currency and Config.Currency.enabled then
        if Config.Currency.maxValue and Config.Currency.maxValue == 999000000000000 then
            PrintSuccess('Currency system configured (max: 999 trillion)')
        else
            PrintWarning('Currency max value not set to standard 999 trillion')
        end
        
        -- Check if locale settings exist for default locale
        if Config.Currency.localeSettings and Config.Currency.localeSettings[Config.Locale] then
            PrintSuccess('Currency locale settings found for: ' .. Config.Locale)
        else
            PrintWarning('No currency locale settings for: ' .. Config.Locale)
            PrintInfo('Currency formatting may fall back to defaults')
        end
    else
        PrintInfo('Currency system disabled')
    end
    
    -- Validate enabled apps
    if Config.EnabledApps then
        local enabledCount = 0
        for app, enabled in pairs(Config.EnabledApps) do
            if enabled then
                enabledCount = enabledCount + 1
            end
        end
        PrintSuccess('Enabled apps: ' .. enabledCount)
    else
        PrintError('No apps enabled in configuration')
        table.insert(configIssues, 'No apps enabled')
    end
    
    -- Validate database resource
    if Config.DatabaseResource then
        if IsResourceAvailable(Config.DatabaseResource) then
            PrintSuccess('Database resource configured: ' .. Config.DatabaseResource)
        else
            PrintError('Database resource not found: ' .. Config.DatabaseResource)
            table.insert(configIssues, 'Database resource missing')
        end
    else
        PrintError('No database resource configured')
        table.insert(configIssues, 'No database resource')
    end
    
    -- Validate voice resource
    if Config.VoiceResource then
        if IsResourceAvailable(Config.VoiceResource) then
            PrintSuccess('Voice resource configured: ' .. Config.VoiceResource)
        else
            PrintError('Voice resource not found: ' .. Config.VoiceResource)
            table.insert(configIssues, 'Voice resource missing')
        end
    else
        PrintError('No voice resource configured')
        table.insert(configIssues, 'No voice resource')
    end
    
    return #configIssues == 0
end

-- Step 6: Setup Locales
function InstallationManager:SetupLocales()
    PrintHeader('Setting Up Locales')
    
    if not Config.SupportedLocales then
        PrintWarning('No supported locales configured')
        return true
    end
    
    PrintInfo('Checking locale files...')
    
    local localesFound = 0
    local localesMissing = 0
    
    for _, locale in ipairs(Config.SupportedLocales) do
        -- Check server-side locale file
        local serverLocalePath = 'server/locales/' .. locale .. '.lua'
        local serverLocaleFile = LoadResourceFile(GetCurrentResourceName(), serverLocalePath)
        
        if serverLocaleFile then
            localesFound = localesFound + 1
            PrintSuccess('Server locale found: ' .. locale .. '.lua')
        else
            localesMissing = localesMissing + 1
            PrintWarning('Server locale missing: ' .. locale .. '.lua')
        end
    end
    
    PrintInfo('Locale files found: ' .. localesFound .. '/' .. #Config.SupportedLocales)
    
    if localesMissing > 0 then
        PrintWarning(localesMissing .. ' locale file(s) missing')
        PrintInfo('Missing locales will fall back to English')
    end
    
    return true
end

-- Main installation routine
function InstallationManager:Run()
    print('')
    print(COLOR.CYAN .. '╔════════════════════════════════════════════════════════════╗' .. COLOR.RESET)
    print(COLOR.CYAN .. '║                                                            ║' .. COLOR.RESET)
    print(COLOR.CYAN .. '║' .. COLOR.WHITE .. '          FiveM Smartphone System - Installation           ' .. COLOR.CYAN .. '║' .. COLOR.RESET)
    print(COLOR.CYAN .. '║                                                            ║' .. COLOR.RESET)
    print(COLOR.CYAN .. '╚════════════════════════════════════════════════════════════╝' .. COLOR.RESET)
    print('')
    
    PrintInfo('Starting automated installation...')
    print('')
    
    -- Reset error and warning counters
    installationErrors = {}
    installationWarnings = {}
    
    -- Step 1: Check dependencies
    local depsOk = self:CheckDependencies()
    if not depsOk then
        PrintError('Dependency check failed - installation cannot continue')
        self:PrintSummary(false)
        return false
    end
    
    -- Step 2: Detect framework
    local frameworkOk = self:DetectFramework()
    if not frameworkOk then
        PrintError('Framework detection failed')
        self:PrintSummary(false)
        return false
    end
    
    -- Step 3: Validate configuration
    local configOk = self:ValidateConfiguration()
    if not configOk then
        PrintError('Configuration validation failed')
        self:PrintSummary(false)
        return false
    end
    
    -- Step 4: Create database tables
    local dbOk = self:CreateDatabaseTables()
    if not dbOk then
        PrintError('Database table creation failed')
        self:PrintSummary(false)
        return false
    end
    
    -- Step 5: Validate integrations
    local integrationsOk = self:ValidateIntegrations()
    if not integrationsOk then
        PrintWarning('Integration validation completed with warnings')
    end
    
    -- Step 6: Setup locales
    local localesOk = self:SetupLocales()
    if not localesOk then
        PrintWarning('Locale setup completed with warnings')
    end
    
    -- Installation complete
    installationComplete = true
    self:PrintSummary(true)
    
    return true
end

-- Print installation summary
function InstallationManager:PrintSummary(success)
    print('')
    print(COLOR.CYAN .. '╔════════════════════════════════════════════════════════════╗' .. COLOR.RESET)
    print(COLOR.CYAN .. '║                                                            ║' .. COLOR.RESET)
    
    if success then
        print(COLOR.CYAN .. '║' .. COLOR.GREEN .. '              Installation Completed Successfully!          ' .. COLOR.CYAN .. '║' .. COLOR.RESET)
    else
        print(COLOR.CYAN .. '║' .. COLOR.RED .. '                Installation Failed!                        ' .. COLOR.CYAN .. '║' .. COLOR.RESET)
    end
    
    print(COLOR.CYAN .. '║                                                            ║' .. COLOR.RESET)
    print(COLOR.CYAN .. '╚════════════════════════════════════════════════════════════╝' .. COLOR.RESET)
    print('')
    
    -- Print statistics
    PrintInfo('Installation Summary:')
    print(COLOR.WHITE .. '  • Errors: ' .. COLOR.RED .. #installationErrors .. COLOR.RESET)
    print(COLOR.WHITE .. '  • Warnings: ' .. COLOR.YELLOW .. #installationWarnings .. COLOR.RESET)
    print(COLOR.WHITE .. '  • Framework: ' .. COLOR.CYAN .. (Config.Framework or 'unknown') .. COLOR.RESET)
    print(COLOR.WHITE .. '  • Locale: ' .. COLOR.CYAN .. (Config.Locale or 'en') .. COLOR.RESET)
    print('')
    
    -- Print errors if any
    if #installationErrors > 0 then
        PrintError('Installation errors encountered:')
        for i, error in ipairs(installationErrors) do
            print(COLOR.RED .. '  ' .. i .. '. ' .. error .. COLOR.RESET)
        end
        print('')
    end
    
    -- Print warnings if any
    if #installationWarnings > 0 then
        PrintWarning('Installation warnings:')
        for i, warning in ipairs(installationWarnings) do
            print(COLOR.YELLOW .. '  ' .. i .. '. ' .. warning .. COLOR.RESET)
        end
        print('')
    end
    
    if success then
        PrintSuccess('Phone system is ready to use!')
        PrintInfo('Players can open the phone with the "' .. (Config.OpenKey or 'M') .. '" key')
    else
        PrintError('Please fix the errors above and restart the resource')
        PrintInfo('Check the documentation for installation instructions')
    end
    
    print('')
end

-- Get installation status
function InstallationManager:IsComplete()
    return installationComplete
end

-- Get installation errors
function InstallationManager:GetErrors()
    return installationErrors
end

-- Get installation warnings
function InstallationManager:GetWarnings()
    return installationWarnings
end

-- Export functions
return InstallationManager
