Config = {}

-- Framework Configuration
-- Options: 'standalone', 'esx', 'qbcore', 'qbox'
Config.Framework = 'standalone'

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
    bank = true,
    bankr = true,
    crypto = true,
    cryptox = true,
    
    -- Entertainment
    musicly = true,
    
    -- Safety
    finder = true,
    safezone = true
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

-- Bank App Settings
Config.BankApp = {
    enabled = true,
    defaultAccount = 'bank', -- Account type for framework integration
    transactionHistoryLimit = 50, -- Number of transactions to display
    minTransferAmount = 1,
    maxTransferAmount = 999999
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
Config.MediaStorage = 'local' -- 'local' or 'cdn'
Config.CDNConfig = {
    provider = 's3', -- 's3', 'r2', 'custom'
    endpoint = '',
    bucket = '',
    accessKey = '',
    secretKey = ''
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

-- Bankr App Settings (Enhanced Banking)
Config.BankrApp = {
    enabled = true,
    bankingScript = 'qb-banking', -- 'qb-banking', 'okokBanking', 'Renewed-Banking', 'custom'
    showAnalytics = true,
    enableRecurringPayments = true,
    transactionHistoryLimit = 100,
    enableBudgetTracking = true,
    enableSpendingCategories = true,
    analyticsUpdateInterval = 60000 -- 1 minute
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
