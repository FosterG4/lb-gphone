Config = {}

-- Framework Configuration
-- Options: 'standalone', 'esx', 'qbcore', 'qbox'
-- Set to 'standalone' to disable framework integration
-- Set to 'auto' to enable automatic framework detection
Config.Framework = 'auto'

-- Keybind Configuration
Config.OpenKey = 'M' -- Key to open/close phone

-- Phone Settings
Config.PhoneNumberFormat = '###-####' -- 7 digits format
Config.PhoneNumberLength = 7
Config.GenerateRandomNumbers = true -- Auto-generate phone numbers for new players

-- Enabled Apps Configuration
Config.EnabledApps = {
    -- Core Communication
    contacts = true,
    messages = true,
    dialer = true,
    
    -- Media
    camera = true,
    photos = true,
    voice_recorder = true,
    
    -- Utilities
    settings = true,
    clock = true,
    notes = true,
    maps = true,
    weather = true,
    appstore = true,
    
    -- Vehicle & Property
    garage = true,
    home = true,
    
    -- Social Media
    shotz = true,
    chirper = true,
    modish = true,
    flicker = true,
    
    -- Commerce
    marketplace = true,
    pages = true,
    
    -- Finance
    wallet = true, -- Unified banking solution (replaces bank and bankr)
    crypto = true,
    cryptox = true,
    
    -- Entertainment
    musicly = true,
    
    -- Safety
    finder = true,
    safezone = true,
    
    -- Productivity
    voicerecorder = true
}

-- Notification Settings
Config.NotificationDuration = 5000 -- Duration in milliseconds
Config.NotificationPosition = 'top-right' -- Position: 'top-right', 'top-left', 'bottom-right', 'bottom-left'
Config.NotificationSound = true -- Enable notification sounds

-- Message Settings
Config.MaxMessageLength = 500 -- Maximum characters per message
Config.MessageCooldown = 1000 -- Cooldown between messages in milliseconds
Config.SaveMessagesOffline = true -- Queue messages for offline players

-- Call Settings
Config.CallTimeout = 30000 -- Time before call times out (30 seconds)
Config.MaxCallDuration = 3600000 -- Maximum call duration (1 hour)
Config.CallRingtoneVolume = 0.5 -- Volume level (0.0 to 1.0)

-- Voice Integration
Config.VoiceResource = 'pma-voice' -- Voice resource name
Config.CallChannelPrefix = 'phone_call_' -- Prefix for call channels

-- Database Settings
Config.DatabaseResource = 'oxmysql' -- Database resource name
Config.DatabaseCacheTime = 300000 -- Cache time in milliseconds (5 minutes)
Config.CreateTablesOnStart = true -- Auto-create database tables on resource start

-- Wallet App Settings (Unified Banking Solution)
-- Consolidates functionality from Bank and Bankr apps
Config.WalletApp = {
    enabled = true,
    defaultAccount = 'bank', -- Account type for framework integration
    transactionHistoryLimit = 100, -- Number of transactions to display
    minTransferAmount = 1,
    maxTransferAmount = 999000000000000, -- 999 trillion (matches Config.Currency.maxValue)
    -- Banking integration
    bankingScript = 'qb-banking', -- 'qb-banking', 'okokBanking', 'Renewed-Banking', 'custom'
    -- Analytics and insights
    showAnalytics = true,
    enableRecurringPayments = true,
    enableBudgetTracking = true,
    enableSpendingCategories = true,
    analyticsUpdateInterval = 60000, -- 1 minute
    -- Cards management
    enableCardsManagement = true,
    maxCardsPerPlayer = 5,
    -- Customization
    enableCustomization = true,
    availableThemes = {'default', 'minimal', 'premium'}
}

-- Chirper App Settings
Config.ChirperApp = {
    enabled = true,
    maxChirpLength = 280,
    chirpCooldown = 5, -- Cooldown between chirps in seconds
    maxFeedItems = 50, -- Maximum chirps to load in feed
    allowReplies = true,
    allowLikes = true,
    autoCleanup = false, -- Automatically delete old chirps
    cleanupInterval = 3600000, -- Cleanup check interval (1 hour)
    daysToKeep = 30 -- Days to keep chirps before deletion
}

-- Crypto App Settings
Config.CryptoApp = {
    enabled = true,
    updateInterval = 60000, -- Price update interval in milliseconds (1 minute)
    priceVolatility = 0.05, -- Price fluctuation percentage (5%)
    availableCryptos = {
        {
            name = 'Bitcoin',
            symbol = 'BTC',
            basePrice = 50000,
            icon = '₿'
        },
        {
            name = 'Ethereum',
            symbol = 'ETH',
            basePrice = 3000,
            icon = 'Ξ'
        },
        {
            name = 'Dogecoin',
            symbol = 'DOGE',
            basePrice = 0.25,
            icon = 'Ð'
        }
    }
}

-- Alias for backward compatibility with validation functions
Config.AvailableCryptos = Config.CryptoApp.availableCryptos

-- Performance Settings
Config.MaxEventsPerSecond = 10 -- Rate limiting for events per player
Config.DebugMode = false -- Enable debug logging

-- Error Handling Settings
Config.ErrorHandling = {
    showErrorNotifications = true, -- Show error notifications to players
    logErrors = true, -- Log errors to console
    logSecurityEvents = true, -- Log security-related events
    retryFailedOperations = false, -- Retry failed database operations
    maxRetries = 3 -- Maximum retry attempts
}

-- Restriction Settings
Config.Restrictions = {
    blockWhenDead = true,
    blockWhenCuffed = true,
    blockInTrunk = true,
    blockInWater = false
}

-- UI Settings
Config.UI = {
    phoneWidth = 400, -- Phone width in pixels
    phoneHeight = 800, -- Phone height in pixels
    animationDuration = 300, -- Animation duration in milliseconds
    defaultTheme = 'dark', -- Default theme: 'light', 'dark', 'oled'
    availableThemes = {'light', 'dark', 'oled', 'custom'}
}

-- Settings App Configuration
Config.SettingsApp = {
    enabled = true,
    allowThemeChange = true,
    allowNotificationToggle = true,
    allowSoundToggle = true,
    allowVolumeControl = true,
    minVolume = 0,
    maxVolume = 100,
    defaultVolume = 50
}

-- Media Storage Settings
-- Options: 'local', 'cdn', 'fivemanage'
-- 'local' - Store media files locally in the resource directory
-- 'cdn' - Use custom CDN provider (S3, R2, etc.)
-- 'fivemanage' - Use Fivemanage CDN service for FiveM servers
Config.MediaStorage = 'local'

-- CDN Configuration (for custom CDN providers)
Config.CDNConfig = {
    provider = 's3', -- 's3', 'r2', 'custom'
    endpoint = '',
    bucket = '',
    accessKey = '',
    secretKey = ''
}

-- Fivemanage Configuration
-- Fivemanage is a CDN and media hosting service specifically designed for FiveM servers
-- Get your API key from: https://fivemanage.com
Config.FivemanageConfig = {
    -- Enable or disable Fivemanage integration
    enabled = true,
    
    -- Your Fivemanage API key (required)
    -- Obtain from https://fivemanage.com/dashboard
    apiKey = '',
    
    -- Fivemanage API endpoint for uploads
    -- Default: https://api.fivemanage.com/api/image
    -- Do not change unless instructed by Fivemanage support
    endpoint = 'https://api.fivemanage.com/api/image',
    
    -- Request timeout in milliseconds
    -- How long to wait for Fivemanage to respond before timing out
    -- Default: 30000 (30 seconds)
    timeout = 30000,
    
    -- Number of retry attempts on upload failure
    -- If an upload fails due to network issues, retry this many times
    -- Default: 3
    retryAttempts = 3,
    
    -- Delay between retry attempts in milliseconds
    -- Uses exponential backoff (delay doubles with each retry)
    -- Default: 1000 (1 second initial delay)
    retryDelay = 1000,
    
    -- Fall back to local storage if Fivemanage upload fails
    -- If true, media will be saved locally when Fivemanage is unavailable
    -- If false, upload will fail and player will receive an error
    -- Default: true (recommended)
    fallbackToLocal = true,
    
    -- Log all upload attempts and results to server console
    -- Useful for debugging and monitoring upload success rates
    -- Default: true
    logUploads = true
}
Config.MaxPhotoSize = 5 * 1024 * 1024 -- 5MB in bytes
Config.MaxVideoSize = 50 * 1024 * 1024 -- 50MB in bytes
Config.MaxAudioSize = 10 * 1024 * 1024 -- 10MB in bytes
Config.MaxVideoLength = 60 -- seconds
Config.MaxAudioLength = 300 -- seconds (5 minutes)
Config.StorageQuotaPerPlayer = 500 * 1024 * 1024 -- 500MB per player
Config.GenerateThumbnails = true
Config.ThumbnailSize = 200 -- pixels
Config.ImageQuality = 80 -- JPEG quality (0-100)
Config.VideoFPS = 24
Config.OptimizeImages = true

-- Performance Optimization Settings
Config.MaxConcurrentUploads = 3 -- Maximum concurrent uploads per player
Config.UrlCacheTime = 300 -- Cache Fivemanage URLs for 5 minutes (in seconds)
Config.EnableAsyncUploads = true -- Process uploads asynchronously in background
Config.ShowUploadProgress = true -- Show upload progress indicators to players

-- Upload Rate Limiting Settings
Config.UploadLimits = {
    maxUploadsPerMinute = 10, -- Maximum uploads per player per minute
    cooldownSeconds = 2, -- Cooldown between individual uploads (seconds)
    maxFailedAttemptsBeforeBlock = 15, -- Failed attempts before temporary block
    blockDurationMinutes = 5 -- Duration of temporary block (minutes)
}

-- Camera App Settings
Config.CameraApp = {
    enabled = true,
    allowPhotoCapture = true,
    allowVideoRecording = true,
    enableFlash = true,
    enableCameraFlip = true,
    availableFilters = {'none', 'bw', 'sepia', 'vintage', 'cool', 'warm'},
    defaultFilter = 'none'
}

-- Photos/Gallery App Settings
Config.PhotosApp = {
    enabled = true,
    photosPerPage = 20,
    enableAlbums = true,
    maxAlbumsPerPlayer = 50,
    enableSharing = true,
    enableInfiniteScroll = true
}

-- Clock App Settings
Config.ClockApp = {
    enabled = true,
    maxAlarms = 10,
    alarmSounds = {'default', 'gentle', 'loud', 'custom'},
    defaultAlarmSound = 'default',
    enableTimer = true,
    enableStopwatch = true,
    alarmCheckInterval = 60000 -- Check every minute
}

-- Notes App Settings
Config.NotesApp = {
    enabled = true,
    maxNoteLength = 5000,
    enableAutoSave = true,
    autoSaveInterval = 5000, -- milliseconds
    maxNotesPerPlayer = 100
}

-- Maps App Settings
Config.MapsApp = {
    enabled = true,
    mapProvider = 'game', -- 'game' or 'custom'
    maxLocationPins = 50,
    enableLocationSharing = true,
    locationShareDuration = 3600, -- seconds (1 hour)
    locationUpdateInterval = 5000, -- milliseconds
    enableWaypoints = true
}

-- Weather App Settings
Config.WeatherApp = {
    enabled = true,
    syncWithServer = true,
    updateInterval = 300000, -- 5 minutes
    showForecast = true,
    forecastHours = 24
}

-- App Store Settings
Config.AppStoreApp = {
    enabled = true,
    allowInstall = true,
    allowUninstall = true,
    enableCustomApps = true,
    showRatings = true,
    showScreenshots = true
}

-- Garage App Settings
Config.GarageApp = {
    enabled = true,
    garageScript = 'qb-garages', -- 'qb-garages', 'cd_garage', 'jg-advancedgarages', 'custom', 'none'
    enableValet = true,
    valetCost = 100,
    valetSpawnDistance = 10, -- meters
    valetTimeout = 30, -- seconds
    enableVehicleTracking = true,
    trackingUpdateInterval = 10000 -- milliseconds
}

-- Home App Settings
Config.HomeApp = {
    enabled = true,
    housingScript = 'qb-houses', -- 'qb-houses', 'qs-housing', 'cd_easyhome', 'custom', 'none'
    enableKeyManagement = true,
    keyExpirationDays = 7,
    maxKeysPerProperty = 10,
    enableRemoteLock = true,
    enableAccessLogs = true,
    maxAccessLogs = 50
}

-- Shotz App Settings (Photo/Video Sharing)
Config.ShotzApp = {
    enabled = true,
    maxCaptionLength = 500,
    enableLiveStreaming = true,
    maxStreamDuration = 3600, -- seconds (1 hour)
    postsPerPage = 20,
    enableComments = true,
    enableLikes = true,
    enableShares = true,
    enableFollowers = true,
    feedUpdateInterval = 10000 -- milliseconds
}

-- Chirper App Settings (Twitter-like)
Config.ChirperApp = {
    enabled = true,
    maxPostLength = 280,
    enableReplies = true,
    enableReposts = true,
    enableLikes = true,
    showTrending = true,
    trendingUpdateInterval = 300000, -- 5 minutes
    postsPerPage = 20,
    feedUpdateInterval = 10000 -- milliseconds
}

-- Modish App Settings (Short Videos)
Config.ModishApp = {
    enabled = true,
    maxVideoLength = 60, -- seconds
    enableFilters = true,
    enableTTS = true,
    enableMusicTracks = true,
    videosPerPage = 20,
    enableLikes = true,
    enableComments = true,
    feedUpdateInterval = 10000 -- milliseconds
}

-- Flicker App Settings (Dating/Matching)
Config.FlickerApp = {
    enabled = true,
    maxDistance = 5000, -- meters
    minAge = 18,
    maxAge = 100,
    matchExpirationDays = 7,
    profilesPerBatch = 10,
    enableInAppMessaging = true,
    enableDistanceFilter = true,
    enableAgeFilter = true
}

-- Marketplace App Settings
Config.MarketplaceApp = {
    enabled = true,
    maxListingsPerPlayer = 20,
    listingDurationDays = 30,
    categories = {'vehicles', 'weapons', 'items', 'services', 'real_estate', 'other'},
    maxPhotosPerListing = 5,
    enableNegotiation = true,
    enableSearch = true,
    enableFilters = true,
    listingsPerPage = 20
}

-- Pages App Settings (Business Pages)
Config.PagesApp = {
    enabled = true,
    maxPagesPerPlayer = 3,
    enableFollowers = true,
    enableAnnouncements = true,
    enableServiceListings = true,
    enablePhotoGallery = true,
    maxPhotosPerPage = 10,
    enableLocationDisplay = true
}



-- CryptoX App Settings (Enhanced Crypto Trading)
Config.CryptoXApp = {
    enabled = true,
    priceUpdateInterval = 30000, -- 30 seconds
    priceVolatility = 0.05, -- 5% price fluctuation
    availableCryptos = {
        {symbol = 'BTC', name = 'Bitcoin', basePrice = 50000, icon = '₿'},
        {symbol = 'ETH', name = 'Ethereum', basePrice = 3000, icon = 'Ξ'},
        {symbol = 'DOGE', name = 'Dogecoin', basePrice = 0.25, icon = 'Ð'},
        {symbol = 'LTC', name = 'Litecoin', basePrice = 150, icon = 'Ł'}
    },
    enableCharts = true,
    chartHistoryDays = 30,
    enablePriceAlerts = true,
    transactionHistoryLimit = 100
}

-- Musicly App Settings (Music Streaming)
Config.MusiclyApp = {
    enabled = true,
    audioResource = 'xsound', -- 'xsound', 'interact-sound', 'custom'
    enablePlaylists = true,
    maxPlaylistsPerPlayer = 20,
    enableBackgroundPlay = true,
    defaultVolume = 50,
    stations = {
        {name = 'Radio Los Santos', url = 'https://example.com/stream1'},
        {name = 'West Coast Classics', url = 'https://example.com/stream2'},
        {name = 'Blaine County Radio', url = 'https://example.com/stream3'}
    }
}

-- Finder App Settings (Device Locator)
Config.FinderApp = {
    enabled = true,
    locationUpdateInterval = 10000, -- 10 seconds
    maxDevicesPerPlayer = 10,
    enableSoundAlert = true,
    enableVehicleTracking = true,
    enablePhoneTracking = true
}

-- SafeZone App Settings (Emergency)
Config.SafeZoneApp = {
    enabled = true,
    policeJobName = 'police',
    emergencyNumber = '911',
    sendLocationWithAlert = true,
    maxEmergencyContacts = 5,
    enablePanicButton = true,
    enableSafetyTips = true
}

-- Voice Recorder App Settings
Config.VoiceRecorderApp = {
    enabled = true,
    maxRecordingLength = 300, -- seconds (5 minutes)
    audioFormat = 'mp3', -- 'mp3' or 'ogg'
    audioBitrate = 128, -- kbps
    enableSharing = true,
    maxRecordingsPerPlayer = 50
}

-- Integration Settings
Config.Integrations = {
    -- Housing Scripts
    housing = {
        script = 'qb-houses', -- 'qb-houses', 'qs-housing', 'cd_easyhome', 'loaf_housing', 'custom', 'none'
        enabled = true
    },
    -- Garage Scripts
    garage = {
        script = 'qb-garages', -- 'qb-garages', 'cd_garage', 'jg-advancedgarages', 'custom', 'none'
        enabled = true
    },
    -- Banking Scripts
    banking = {
        script = 'qb-banking', -- 'qb-banking', 'okokBanking', 'Renewed-Banking', 'custom', 'none'
        enabled = true
    },
    -- Audio Resources
    audio = {
        resource = 'xsound', -- 'xsound', 'interact-sound', 'custom', 'none'
        enabled = true
    }
}

-- Performance Settings
Config.Performance = {
    enableCaching = true,
    cacheExpirationTime = 300000, -- 5 minutes
    lazyLoadApps = true,
    optimizeImages = true,
    maxCachedItems = 100,
    enableVirtualScrolling = true,
    databaseConnectionPoolSize = 5
}

-- Security Settings
Config.Security = {
    enableRateLimiting = true,
    maxRequestsPerSecond = 10,
    enableAntiSpam = true,
    spamCooldown = 1000, -- milliseconds
    validateAllInputs = true,
    logSuspiciousActivity = true,
    enableSQLInjectionPrevention = true,
    sanitizeUserContent = true,
    maxLoginAttempts = 5,
    loginCooldown = 300000 -- 5 minutes
}

-- Locale Configuration
-- Default language for the phone system
-- Options: 'en' (English), 'ja' (Japanese), 'es' (Spanish), 'fr' (French), 'de' (German), 'pt' (Portuguese)
Config.Locale = 'en'

-- Supported Locales
-- Array of all supported languages in the system
-- Add or remove locales as needed for your server
Config.SupportedLocales = {'en', 'ja', 'es', 'fr', 'de', 'pt'}

-- Currency System Settings
-- Configure currency display, formatting, and validation
-- Maximum supported value: 999,000,000,000,000 (999 trillion)
--
-- Configuration Options:
--   enabled: Enable/disable currency formatting system
--   maxValue: Maximum currency value supported (999 trillion)
--   localeSettings: Per-locale currency configuration
--     symbol: Currency symbol to display (e.g., '$', '€', '¥', 'R$')
--     position: Symbol position - 'before' or 'after' the amount
--     decimalPlaces: Number of decimal places to display (0-8)
--     thousandsSeparator: Character for thousands separator (',', '.', ' ')
--     decimalSeparator: Character for decimal separator ('.', ',')
--     format: String format pattern (%s = symbol, %s = amount)
--   enableValidation: Validate currency amounts against maxValue
--   enableFormatting: Apply locale-specific formatting to currency displays
--   enableAbbreviation: Show abbreviated values (1M, 1B, 1T) for large amounts
--   abbreviationThreshold: Minimum value to start abbreviating
Config.Currency = {
    enabled = true,
    maxValue = 999000000000000, -- 999 trillion (maximum supported currency amount)
    -- Locale-specific currency settings
    -- Each locale defines how currency should be displayed for that language/region
    localeSettings = {
        -- English (United States) - US Dollar
        -- Example: $1,234.56
        en = {
            symbol = '$',
            position = 'before', -- Symbol before amount
            decimalPlaces = 2,
            thousandsSeparator = ',',
            decimalSeparator = '.',
            format = '%s%s' -- $1234.56
        },
        
        -- Japanese (Japan) - Japanese Yen
        -- Example: ¥1,234 (no decimal places)
        ja = {
            symbol = '¥',
            position = 'before',
            decimalPlaces = 0, -- Yen doesn't use decimal places
            thousandsSeparator = ',',
            decimalSeparator = '.',
            format = '%s%s' -- ¥1234
        },
        
        -- Spanish (Spain/Latin America) - Euro
        -- Example: 1.234,56 €
        es = {
            symbol = '€',
            position = 'after', -- Symbol after amount
            decimalPlaces = 2,
            thousandsSeparator = '.',
            decimalSeparator = ',',
            format = '%s %s' -- 1234,56 €
        },
        
        -- French (France) - Euro
        -- Example: 1 234,56 €
        fr = {
            symbol = '€',
            position = 'after',
            decimalPlaces = 2,
            thousandsSeparator = ' ', -- Space as thousands separator
            decimalSeparator = ',',
            format = '%s %s' -- 1234,56 €
        },
        
        -- German (Germany) - Euro
        -- Example: 1.234,56 €
        de = {
            symbol = '€',
            position = 'after',
            decimalPlaces = 2,
            thousandsSeparator = '.',
            decimalSeparator = ',',
            format = '%s %s' -- 1234,56 €
        },
        
        -- Portuguese (Brazil) - Brazilian Real
        -- Example: R$ 1.234,56
        pt = {
            symbol = 'R$',
            position = 'before',
            decimalPlaces = 2,
            thousandsSeparator = '.',
            decimalSeparator = ',',
            format = '%s %s' -- R$ 1234,56
        }
    },
    enableValidation = true,
    enableFormatting = true,
    enableAbbreviation = true,
    abbreviationThreshold = 1000000 -- Start abbreviating at 1M
}

-- Internationalization Settings
Config.Internationalization = {
    enabled = true,
    defaultLocale = 'en',
    supportedLocales = {'en', 'ja', 'es', 'fr', 'de', 'pt'},
    fallbackLocale = 'en',
    enableAutoDetection = true,
    enablePlayerPreference = true,
    localeStorageKey = 'gphone_locale',
    serverLocaleCommand = 'gphone_locale'
}

-- Setup Wizard Settings
-- Show the setup wizard on first resource start to configure language, currency, and features
-- Once completed, the wizard will not show again unless this is set to true
Config.ShowSetupWizard = false -- Set to true to show the setup wizard on resource start

-- Contact Sharing Settings
-- Enables proximity-based contact sharing similar to iPhone's contact sharing functionality
Config.ContactSharing = {
    enabled = true, -- Enable/disable contact sharing feature
    proximityRadius = 5.0, -- Maximum distance in meters for contact sharing (range: 1-20)
    requestTimeout = 30, -- Time in seconds before share request expires
    broadcastDuration = 10, -- Time in seconds for broadcast share visibility
    updateInterval = 2000, -- Coordinate update interval in milliseconds
    maxRequestsPerMinute = 5, -- Rate limit for share requests per player
    enableBroadcastShare = true, -- Enable broadcast sharing (My Card share)
    enableDirectShare = true, -- Enable direct player-to-player sharing
    showDistance = true, -- Show distance to nearby players
    playSound = true, -- Play sound effects for contact sharing events
    soundVolume = 0.5 -- Sound volume (0.0 to 1.0)
}
