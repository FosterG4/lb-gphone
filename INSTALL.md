# 📱 lb-gphone - Installation Guide

<div align="center">

[![GitHub Repository](https://img.shields.io/badge/GitHub-lb--gphone-blue?style=for-the-badge&logo=github)](https://github.com/FosterG4/lb-gphone.git)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-green?style=for-the-badge&logo=fivem)](https://fivem.net)
[![License](https://img.shields.io/badge/License-Check%20Repo-orange?style=for-the-badge)](https://github.com/FosterG4/lb-gphone.git)

**Complete step-by-step installation guide for the lb-gphone FiveM smartphone resource**

**Repository:** [https://github.com/FosterG4/lb-gphone](https://github.com/FosterG4/lb-gphone)

---

[🚀 Quick Start](#quick-start) • [📋 Prerequisites](#prerequisites) • [📖 Detailed Installation](#detailed-installation-steps) • [⚙️ Configuration](#configuration) • [🔧 Troubleshooting](#troubleshooting) • [❓ FAQ](#frequently-asked-questions)

</div>

---

## � Table of Contents

### 🚀 Getting Started
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Installation Steps](#detailed-installation-steps)

### ⚙️ Configuration
- [Framework Integration](#framework-integration)
- [Locale and Currency Configuration](#locale-and-currency-configuration)
- [Housing & Garage Integration](#housing--garage-integration)
- [Media Storage Configuration](#media-storage-configuration)
- [Advanced Configuration](#advanced-configuration)

### ✅ Verification & Maintenance
- [Post-Installation Verification](#post-installation-verification)
- [Database Management](#database-management)
- [Performance Tuning](#performance-tuning)
- [Backup and Maintenance](#backup-and-maintenance)

### 🔧 Support
- [Troubleshooting](#troubleshooting)
- [Frequently Asked Questions](#frequently-asked-questions)
- [Getting Help](#getting-help)

---

## Prerequisites

### System Requirements

| Component | Requirement | Notes |
|-----------|-------------|-------|
| **FiveM Server** | Latest artifact | Recommended: Latest stable release |
| **MySQL Database** | 5.7+ or MariaDB 10.2+ | Required for data persistence |
| **Node.js** | 16.x or higher | Required for NUI build process |
| **npm** | 7.x or higher | Comes with Node.js |
| **Server RAM** | Minimum 4GB | Recommended: 8GB+ for 100+ players |
| **Storage** | 500MB free space | For resource files and media storage |

### Required Dependencies

These dependencies **must** be installed before the phone resource:

#### 1. oxmysql (Required)
- **Purpose:** Database operations and query handling
- **Download:** [GitHub - oxmysql](https://github.com/overextended/oxmysql)
- **Version:** Latest release
- **Installation:** Follow oxmysql documentation for setup

#### 2. pma-voice (Required)
- **Purpose:** Voice call integration and audio channels
- **Download:** [GitHub - pma-voice](https://github.com/AvarianKnight/pma-voice)
- **Version:** Latest release
- **Installation:** Follow pma-voice documentation for setup

### Framework Dependencies (Choose One)

The phone system supports multiple frameworks. Choose the one that matches your server:

| Framework | Status | Auto-Detection | Notes |
|-----------|--------|----------------|-------|
| **Standalone** | ✅ Fully Supported | N/A | No framework required |
| **ESX Legacy** | ✅ Fully Supported | ✅ Yes | Auto-detects ESX |
| **QBCore** | ✅ Fully Supported | ✅ Yes | Auto-detects QBCore |
| **Qbox** | ✅ Fully Supported | ✅ Yes | Auto-detects Qbox |

### Optional Dependencies

These are optional but enhance functionality:

- **Housing Script:** For property management features (qb-houses, qs-housing, etc.)
- **Garage Script:** For vehicle management features (qb-garages, cd_garage, etc.)
- **Banking Script:** For enhanced financial operations (qb-banking, okokBanking, etc.)
- **Audio Resource:** For music streaming (xsound, interact-sound)

---

## Quick Start

For experienced server administrators, here's the quick installation process:

**1. Clone from GitHub and extract to resources folder**
```bash
cd resources/
git clone https://github.com/FosterG4/lb-gphone.git
```

**2. Build NUI interface**
```bash
cd lb-gphone/nui
npm install
npm run build
```

**3. Add to server.cfg (in order)**
```cfg
ensure oxmysql
ensure pma-voice
ensure es_extended  # or qb-core, qbox (if using a framework)
ensure lb-gphone
```

**4. Configure config.lua**
Edit config.lua to match your server setup

**5. Start server**
Database tables will be created automatically

✅ **Verification:** Start your server and check console for `[Phone] Resource started successfully!`

🚀 **That's it!** The resource will auto-configure on first start. For detailed instructions, continue reading below.

---

## Detailed Installation Steps

### Step 1: Download the Resource

**Option A: Clone from GitHub (Recommended)**

```bash
cd /path/to/your/server/resources
git clone https://github.com/FosterG4/lb-gphone.git
```

**Option B: Download Release**

1. Visit the [GitHub Releases page](https://github.com/FosterG4/lb-gphone/releases)
2. Download the latest release ZIP file
3. Extract to your server's `resources` folder
4. Rename folder to `lb-gphone` (if needed)

**Verify Installation:**

Your folder structure should look like this:

```
resources/
└── lb-gphone/
    ├── client/
    ├── server/
    ├── nui/
    ├── docs/
    ├── config.lua
    ├── fxmanifest.lua
    └── README.md
```

✅ **Verification:** Ensure all folders and files are present before proceeding.

---

### Step 2: Install Dependencies

#### Installing oxmysql

**Step 1: Download oxmysql**

```bash
cd resources/
git clone https://github.com/overextended/oxmysql.git
```

**Step 2: Configure Database Connection**

Add to your `server.cfg`:

```cfg
set mysql_connection_string "mysql://username:password@localhost/database?charset=utf8mb4"
```

**Step 3: Test Database Connection**

Start your server and check console for:

```
[oxmysql] Database server connection established!
```

✅ **Verification:** Run `ensure oxmysql` in server console and confirm no errors appear.

#### Installing pma-voice

**Step 1: Download pma-voice**

```bash
cd resources/
git clone https://github.com/AvarianKnight/pma-voice.git
```

**Step 2: Add to server.cfg**

```cfg
ensure pma-voice
```

**Step 3: Verify Installation**

In-game, check that:

- Voice icon appears on screen
- Proximity voice works
- Radio channels work (if applicable)

✅ **Verification:** Test proximity voice with another player before proceeding.

---

### Step 3: Build the NUI Interface

The phone's user interface must be built before use:

```bash
# Navigate to the NUI directory
cd resources/lb-gphone/nui

# Install dependencies (first time only)
npm install

# Build for production
npm run build
```

**Expected Output:**

```bash
✓ built in XXXms
✓ dist/index.html
✓ dist/assets/...
```

**Verify Build:**

Check that `nui/dist/` folder contains:

- `index.html`
- `assets/` folder with JS and CSS files

✅ **Verification:** Run `ls nui/dist/` (Linux/Mac) or `dir nui\dist\` (Windows) to confirm files are present.

**Platform-Specific Instructions:**

**Windows:**

```cmd
cd resources\lb-gphone\nui
npm install
npm run build
```

**Linux/Mac:**

```bash
cd resources/lb-gphone/nui
npm install
npm run build
```

**Troubleshooting Build Issues:**

- ⚠️ **Error: Node version:** Upgrade to Node.js 16+
- ⚠️ **Error: npm not found:** Install Node.js which includes npm
- ⚠️ **Error: Permission denied:** Run with appropriate permissions (Linux: `sudo npm install`)
- ⚠️ **Error: Out of memory:** Increase Node.js memory: `NODE_OPTIONS=--max-old-space-size=4096 npm run build`

---

### Step 4: Add to server.cfg

Add the resource to your `server.cfg` in the correct order:

```cfg
# Required dependencies (must be loaded first)
ensure oxmysql
ensure pma-voice

# Framework (if using one)
ensure es_extended  # or qb-core, qbox

# Phone resource
ensure lb-gphone
```

⚠️ **Important:** Load order matters! Dependencies must be started before the phone resource.

✅ **Verification:** Start your server and check console for `[Phone] Resource started successfully!`

---

### Step 5: Configure the Resource

Edit `config.lua` to match your server setup. Key settings to review:

```lua
-- Framework selection
Config.Framework = 'standalone'  -- Options: 'standalone', 'esx', 'qbcore', 'qbox'

-- Language and currency
Config.Locale = 'en'  -- Options: 'en', 'ja', 'es', 'fr', 'de', 'pt'

-- Phone keybind
Config.OpenKey = 'M'  -- Change if needed

-- Enable/disable apps
Config.EnabledApps = {
    contacts = true,
    messages = true,
    dialer = true,
    -- ... configure as needed
}
```

✅ **Verification:** Save changes and restart the resource: `restart lb-gphone`

---

### Step 6: Verify Installation

1. **Start your server**
2. **Join the server**
3. **Press M (or your configured key)** to open the phone
4. **Check that the phone UI appears**
5. **Test basic features** (contacts, messages, dialer)

✅ **Success!** If the phone opens and works, installation is complete.

For detailed verification steps, see [Post-Installation Verification](#post-installation-verification).

---

## Framework Integration

The phone system automatically detects your framework. Manual configuration is optional.

### Standalone Mode (No Framework)

**Configuration:**

```lua
-- config.lua
Config.Framework = 'standalone'
```

**Features:**

- 🔑 Uses FiveM license identifiers
- 💰 Built-in banking system
- ⚡ No external framework required
- 🎯 Perfect for custom servers

**server.cfg:**

```cfg
ensure oxmysql
ensure pma-voice
ensure lb-gphone
```

✅ **Verification:** Check server console for `[Phone] Framework: Standalone mode`

---

### ESX Legacy Integration

**Prerequisites:**

- ESX Legacy installed and running
- es_extended resource started

**Configuration:**

```lua
-- config.lua
Config.Framework = 'esx'
```

**Auto-Detection:**

The resource automatically detects ESX if `es_extended` is running.

**server.cfg Order:**

```cfg
ensure oxmysql
ensure pma-voice
ensure es_extended
ensure lb-gphone
```

**Integration Features:**

- 🔑 Uses ESX player identifiers
- 💰 Integrates with ESX banking (bank account)
- 💼 Supports ESX job system
- 🏢 Compatible with ESX society accounts

✅ **Verification:** Check server console for `[Phone] Framework: ESX detected and loaded`

---

### QBCore Integration

**Prerequisites:**

- QBCore framework installed and running
- qb-core resource started

**Configuration:**

```lua
-- config.lua
Config.Framework = 'qbcore'
```

**Auto-Detection:**

The resource automatically detects QBCore if `qb-core` is running.

**server.cfg Order:**

```cfg
ensure oxmysql
ensure pma-voice
ensure qb-core
ensure lb-gphone
```

**Integration Features:**

- 🔑 Uses QBCore citizen IDs
- 💰 Integrates with QBCore banking
- 💼 Supports QBCore job system
- 🏦 Compatible with qb-banking

✅ **Verification:** Check server console for `[Phone] Framework: QBCore detected and loaded`

---

### Qbox Integration

**Prerequisites:**
- Qbox framework installed and running
- qbox resource started

**Configuration:**
```lua
-- config.lua
Config.Framework = 'qbox'
```

**Auto-Detection:**
The resource automatically detects Qbox if `qbox` is running.

**server.cfg Order:**
```cfg
ensure oxmysql
ensure pma-voice
ensure qbox
ensure lb-gphone
```

**Integration Features:**
- 🔑 Uses Qbox player identifiers
- 💰 Integrates with Qbox banking
- 💼 Supports Qbox job system
- ✅ Full compatibility with Qbox ecosystem

✅ **Verification:** Check server console for `[Phone] Framework: Qbox detected and loaded`

---

### Framework Troubleshooting

**Issue: Framework not detected**
- ⚠️ Verify framework resource is started before phone
- ⚠️ Check `Config.Framework` matches your framework
- ⚠️ Look for errors in server console
- 💡 Try manual configuration instead of auto-detection

**Issue: Banking integration not working**
- ⚠️ Verify framework banking system is functional
- ⚠️ Check player has bank account
- 💡 Test framework banking commands separately
- 💡 Review framework adapter logs

**Issue: Player data not loading**
- ⚠️ Ensure framework is fully initialized before phone
- ⚠️ Check player identifiers are correct
- ⚠️ Verify database tables exist
- 💡 Test with standalone mode to isolate issue

---

## Locale and Currency Configuration

The phone system supports multiple languages and currency formats.

### Language Configuration

**Supported Languages:**
- English (en)
- Japanese (ja)
- Spanish (es)
- French (fr)
- German (de)
- Portuguese (pt)

**Basic Configuration:**
```lua
-- config.lua
Config.Locale = 'en'  -- Default language
Config.SupportedLocales = {'en', 'ja', 'es', 'fr', 'de', 'pt'}
```

**Allow Player Language Selection:**
```lua
Config.Internationalization = {
    enabled = true,
    defaultLocale = 'en',
    supportedLocales = {'en', 'ja', 'es', 'fr', 'de', 'pt'},
    fallbackLocale = 'en',
    enableAutoDetection = true,
    enablePlayerPreference = true
}
```

**Language Files Location:**
- **Client (NUI)**: `nui/src/i18n/locales/` (en.json, ja.json, etc.)
- **Server (Lua)**: `server/locales/` (en.lua, ja.lua, etc.)

**Language Switching:**
Players can change language in Settings app:
1. 📱 Open Phone
2. ⚙️ Go to Settings
3. 🌐 Select Language
4. ✅ Choose preferred language
5. 🚀 UI updates immediately

✅ **Verification:** Test language switching in Settings app

---

### Currency Configuration

**Maximum Currency Value:** 999,000,000,000,000 (999 trillion)

**Basic Configuration:**
```lua
-- config.lua
Config.Currency = {
    enabled = true,
    maxValue = 999000000000000,
    enableValidation = true,
    enableFormatting = true,
    enableAbbreviation = true,
    abbreviationThreshold = 1000000  -- Start abbreviating at 1M
}
```

**Locale-Specific Currency Settings:**

Each language can have its own currency format:

```lua
Config.Currency.localeSettings = {
    -- US Dollar (English)
    en = {
        symbol = '$',
        position = 'before',
        decimalPlaces = 2,
        thousandsSeparator = ',',
        decimalSeparator = '.',
        format = '%s%s'  -- $1,234.56
    },
    
    -- Japanese Yen
    ja = {
        symbol = '¥',
        position = 'before',
        decimalPlaces = 0,  -- Yen has no decimals
        thousandsSeparator = ',',
        decimalSeparator = '.',
        format = '%s%s'  -- ¥1,234
    },
    
    -- Euro (Spanish)
    es = {
        symbol = '€',
        position = 'after',
        decimalPlaces = 2,
        thousandsSeparator = '.',
        decimalSeparator = ',',
        format = '%s %s'  -- 1.234,56 €
    }
}
```

**Currency Display Examples:**

| Locale | Amount | Display |
|--------|--------|---------|
| en (USD) | 1234567.89 | $1,234,567.89 |
| ja (JPY) | 1234567 | ¥1,234,567 |
| es (EUR) | 1234567.89 | 1.234.567,89 € |
| fr (EUR) | 1234567.89 | 1 234 567,89 € |
| de (EUR) | 1234567.89 | 1.234.567,89 € |
| pt (BRL) | 1234567.89 | R$ 1.234.567,89 |

**Currency Abbreviation:**

For large amounts, the system can show abbreviated values:

| Amount | Abbreviated |
|--------|-------------|
| 1,000 | 1K |
| 1,000,000 | 1M |
| 1,000,000,000 | 1B |
| 1,000,000,000,000 | 1T |

**Currency Validation:**

The system automatically validates currency amounts:
- Minimum: 0
- Maximum: 999,000,000,000,000 (999 trillion)
- Transactions exceeding the limit are rejected with error message

✅ **Verification:** Test currency display in Wallet app and verify formatting is correct

---

## Housing & Garage Integration

The phone system integrates with popular housing and garage scripts for enhanced functionality.

### Housing Script Integration

**Supported Housing Scripts:**
- qb-houses
- qs-housing
- cd_easyhome
- loaf_housing
- Custom scripts (via adapter)

**Configuration:**
```lua
-- config.lua
Config.HomeApp = {
    enabled = true,
    housingScript = 'qb-houses', -- Change to your housing script
    enableKeyManagement = true,
    enableRemoteLock = true,
    enableAccessLogs = true
}
```

**Setup Steps:**

1. **Install Housing Script** (if not already installed)
   ```cfg
   ensure qb-houses  # or your housing script
   ```

2. **Enable Home App**
   ```lua
   Config.EnabledApps.home = true
   ```

3. **Configure Integration**
   ```lua
   Config.Integrations.housing = {
       script = 'qb-houses',
       enabled = true
   }
   ```

4. **Verify Integration**
   - Open phone in-game
   - Navigate to Home app
   - Check if properties are listed

**Features Enabled:**
- View owned properties
- Remote door lock/unlock
- Grant temporary keys to other players
- Revoke keys
- View access logs
- Property location on map

✅ **Verification:** Open Home app and verify properties display correctly

---

### Garage Script Integration

**Supported Garage Scripts:**
- qb-garages
- cd_garage
- jg-advancedgarages
- Custom scripts (via adapter)

**Configuration:**
```lua
-- config.lua
Config.GarageApp = {
    enabled = true,
    garageScript = 'qb-garages', -- Change to your garage script
    enableValet = true,
    valetCost = 100,
    enableVehicleTracking = true
}
```

**Setup Steps:**

1. **Install Garage Script** (if not already installed)
   ```cfg
   ensure qb-garages  # or your garage script
   ```

2. **Enable Garage App**
   ```lua
   Config.EnabledApps.garage = true
   ```

3. **Configure Integration**
   ```lua
   Config.Integrations.garage = {
       script = 'qb-garages',
       enabled = true
   }
   ```

4. **Verify Integration**
   - Open phone in-game
   - Navigate to Garage app
   - Check if vehicles are listed
   - Test valet service

**Features Enabled:**
- View owned vehicles
- Vehicle location tracking
- Valet service (spawn vehicle nearby)
- Vehicle status (stored, out, impounded)
- Vehicle information display

✅ **Verification:** Open Garage app and verify vehicles display correctly

---

### Custom Script Integration

For custom housing or garage scripts, you can create custom adapters. See [Custom Framework Guide](docs/CUSTOM_FRAMEWORK.md) for detailed adapter development.

---

## Media Storage Configuration

Configure how the phone stores photos, videos, and audio files.

### Local Storage (Default)

**Configuration:**
```lua
Config.MediaStorage = 'local'
```

Files stored in resource folder. Suitable for development and testing.

**Pros:**
- No external dependencies
- Easy setup
- Free

**Cons:**
- Limited scalability
- Files stored on server disk
- No CDN benefits

---

### Fivemanage Storage (Recommended for Production)

**Configuration:**
```lua
Config.MediaStorage = 'fivemanage'
Config.FivemanageConfig = {
    enabled = true,
    apiKey = 'your-fivemanage-api-key', -- Get from https://fivemanage.com
    endpoint = 'https://api.fivemanage.com/api/image',
    timeout = 30000,
    retryAttempts = 3,
    fallbackToLocal = true, -- Saves locally if upload fails
    logUploads = true
}
```

**Getting Started with Fivemanage:**
1. Create account at [fivemanage.com](https://fivemanage.com)
2. Generate API key from dashboard
3. Add key to config and set `Config.MediaStorage = 'fivemanage'`
4. Restart resource
5. Test with camera app

**Pros:**
- FiveM-specific CDN
- Easy setup
- Reliable hosting
- Automatic optimization

**Cons:**
- Requires API key
- May have usage limits

✅ **Verification:** Take a photo with camera app and verify it uploads successfully

---

### Custom CDN Storage

**Configuration:**
```lua
Config.MediaStorage = 'cdn'
Config.CDNConfig = {
    provider = 's3',  -- 's3', 'r2', 'custom'
    endpoint = 'https://s3.amazonaws.com',
    bucket = 'your-bucket-name',
    accessKey = 'your-access-key',
    secretKey = 'your-secret-key'
}
```

**Supported Storage Providers:**
- **AWS S3** - Enterprise cloud storage
- **Cloudflare R2** - S3-compatible storage
- **Custom** - Your own CDN solution

---

## Post-Installation Verification

After installation, verify everything is working correctly.

### Server Console Checks

**On Server Start, Look For:**

```
[Phone] Resource starting...
[Phone] Framework: ESX detected and loaded
[Phone] Database: Connected successfully
[Phone] Database: All tables verified/created
[Phone] Locale: en loaded
[Phone] Currency: Validation enabled (max: 999T)
[Phone] Apps: 23 apps enabled
[Phone] Integrations: Housing (qb-houses), Garage (qb-garages)
[Phone] Resource started successfully!
```

**Warning Signs:**
```
[ERROR] [Phone] Database connection failed
[ERROR] [Phone] Framework not detected
[WARNING] [Phone] Housing script not found
[WARNING] [Phone] pma-voice not detected
```

✅ **Verification:** No errors in server console on startup

---

### In-Game Verification

**Test Checklist:**

1. **Phone Opens**
   - [ ] Press configured key (default: M)
   - [ ] Phone UI appears
   - [ ] No errors in F8 console

2. **Core Features**
   - [ ] Contacts app loads
   - [ ] Messages app loads
   - [ ] Dialer app loads
   - [ ] Settings app loads

3. **Communication**
   - [ ] Add a contact
   - [ ] Send a message
   - [ ] Make a call (test with another player)
   - [ ] Receive notifications

4. **Apps**
   - [ ] Camera captures photos
   - [ ] Gallery displays photos
   - [ ] Wallet shows balance
   - [ ] Settings allow customization

5. **Framework Integration**
   - [ ] Player phone number assigned
   - [ ] Bank balance displays correctly
   - [ ] Transfers work with framework banking

6. **Locale & Currency**
   - [ ] UI displays in correct language
   - [ ] Currency formats correctly
   - [ ] Language can be changed in settings
   - [ ] Currency validation works

7. **Integrations** (if enabled)
   - [ ] Housing: Properties display in Home app
   - [ ] Garage: Vehicles display in Garage app
   - [ ] Valet: Vehicle spawns correctly

✅ **Success:** All checklist items pass

---

### Performance Verification

**Monitor Resource Usage:**

In server console or txAdmin:
```
resmon
```

Look for `lb-gphone`:
- **Memory**: Should be < 50MB
- **CPU**: Should be < 5% idle, < 15% active use
- **Threads**: 1-2 threads

**Client Performance:**

In-game F8 console:
```
resmon
```

Check:
- NUI frame rate: Should maintain 60 FPS
- Memory usage: Should be reasonable
- No memory leaks over time

✅ **Verification:** Resource usage is within acceptable limits

---

## Database Management

### Database Tables

The phone system automatically creates 50+ tables on first start. All tables use the `phone_` prefix.

**Core Tables:**
- `phone_players` - Player phone numbers and identifiers
- `phone_contacts` - Contact information
- `phone_messages` - Text messages
- `phone_call_history` - Call logs
- `phone_settings` - User preferences

**App Tables:**
- `phone_media` - Photos, videos, audio
- `phone_wallet_transactions` - Financial transactions
- `phone_cryptox_holdings` - Cryptocurrency
- `phone_musicly_playlists` - Music playlists
- `phone_marketplace_listings` - Marketplace items
- And many more...

### Verify Database Tables

**Check Tables Created:**

Connect to your MySQL database and verify these tables exist:

```sql
SHOW TABLES LIKE 'phone_%';
```

**Expected Result:** 50+ tables with `phone_` prefix

✅ **Verification:** All required tables exist

---

### Manual SQL Installation

If automatic table creation fails, you can execute SQL files manually.

**SQL File Structure:**

```
server/sql/
├── install_all_tables.sql           # Master installation script
├── phone_core_tables.sql            # Core system tables
├── phone_media_tables.sql           # Media storage tables
├── phone_wallet_tables.sql          # Wallet/banking tables
├── phone_cryptox_tables.sql         # Crypto trading tables
└── ... (additional app-specific tables)
```

**Option 1: Install All Tables at Once (Recommended)**

```bash
# Connect to MySQL
mysql -u username -p database_name

# Execute master installation script
SOURCE server/sql/install_all_tables.sql;
```

**Option 2: Install Individual SQL Files**

```bash
# Connect to MySQL
mysql -u username -p database_name

# Install core tables first (required by other tables)
SOURCE server/sql/phone_core_tables.sql;

# Install app-specific tables as needed
SOURCE server/sql/phone_media_tables.sql;
SOURCE server/sql/phone_wallet_tables.sql;
# ... etc
```

**Option 3: Using Command Line**

```bash
# Execute from command line without entering MySQL shell
mysql -u username -p database_name < server/sql/install_all_tables.sql
```

**Platform-Specific Commands:**

**Windows:**
```cmd
mysql -u username -p database_name < server\sql\install_all_tables.sql
```

**Linux/Mac:**
```bash
mysql -u username -p database_name < server/sql/install_all_tables.sql
```

⚠️ **Important:** All SQL files use `CREATE TABLE IF NOT EXISTS`, so they can be safely re-executed.

✅ **Verification:** Run `SHOW TABLES LIKE 'phone_%';` to confirm tables are created

---

### Database Maintenance

**Check Database Size:**

```sql
SELECT 
    table_name AS 'Table',
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.TABLES
WHERE table_schema = 'your_database'
AND table_name LIKE 'phone_%'
ORDER BY (data_length + index_length) DESC;
```

**Clean Old Data:**

```sql
-- Delete messages older than 30 days
DELETE FROM phone_messages WHERE timestamp < DATE_SUB(NOW(), INTERVAL 30 DAY);

-- Delete old media files
DELETE FROM phone_media WHERE created_at < DATE_SUB(NOW(), INTERVAL 60 DAY);

-- Delete old call history
DELETE FROM phone_call_history WHERE timestamp < DATE_SUB(NOW(), INTERVAL 90 DAY);
```

**Optimize Tables:**

```sql
OPTIMIZE TABLE phone_messages, phone_media, phone_transactions;
```

---

## Performance Tuning

Optimize the phone system for your server size and requirements.

### For Small Servers (< 32 players)

```lua
Config.Performance = {
    enableCaching = true,
    cacheExpirationTime = 600000,  -- 10 minutes
    maxCachedItems = 50,
    databaseConnectionPoolSize = 3
}
```

---

### For Medium Servers (32-64 players)

```lua
Config.Performance = {
    enableCaching = true,
    cacheExpirationTime = 300000,  -- 5 minutes
    maxCachedItems = 100,
    databaseConnectionPoolSize = 5
}
```

---

### For Large Servers (64+ players)

```lua
Config.Performance = {
    enableCaching = true,
    cacheExpirationTime = 180000,  -- 3 minutes
    maxCachedItems = 200,
    databaseConnectionPoolSize = 10,
    lazyLoadApps = true,
    enableVirtualScrolling = true
}
```

---

### Database Optimization

**Add Indexes for Better Performance:**

```sql
CREATE INDEX idx_messages_conversation ON phone_messages(sender_phone, receiver_phone);
CREATE INDEX idx_media_owner ON phone_media(owner_phone, created_at DESC);
CREATE INDEX idx_posts_timeline ON phone_chirper_posts(created_at DESC);
```

**Optimize Database Regularly:**

```sql
OPTIMIZE TABLE phone_messages;
OPTIMIZE TABLE phone_media;
OPTIMIZE TABLE phone_chirper_posts;
```

---

### NUI Performance

**Enable Performance Optimizations:**

```lua
Config.Performance.lazyLoadApps = true
Config.Performance.optimizeImages = true
Config.Performance.enableVirtualScrolling = true
```

**Reduce Media Quality:**

```lua
Config.ImageQuality = 70  -- Lower quality for better performance
Config.GenerateThumbnails = true
```

---

## Backup and Maintenance

### Database Backup

**Backup Phone Tables:**

```bash
# Backup all phone tables
mysqldump -u username -p database_name phone_% > phone_backup.sql

# Restore from backup
mysql -u username -p database_name < phone_backup.sql
```

**Platform-Specific Commands:**

**Windows:**
```cmd
mysqldump -u username -p database_name phone_% > phone_backup.sql
mysql -u username -p database_name < phone_backup.sql
```

**Linux/Mac:**
```bash
mysqldump -u username -p database_name phone_% > phone_backup.sql
mysql -u username -p database_name < phone_backup.sql
```

---

### Automated Cleanup

**Create Event for Automatic Cleanup (runs daily):**

```sql
CREATE EVENT phone_cleanup
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    -- Delete messages older than 30 days
    DELETE FROM phone_messages WHERE timestamp < DATE_SUB(NOW(), INTERVAL 30 DAY);
    
    -- Delete old media files
    DELETE FROM phone_media WHERE created_at < DATE_SUB(NOW(), INTERVAL 60 DAY);
    
    -- Delete old call history
    DELETE FROM phone_call_history WHERE timestamp < DATE_SUB(NOW(), INTERVAL 90 DAY);
    
    -- Optimize tables
    OPTIMIZE TABLE phone_messages, phone_media, phone_call_history;
END;
```

---

### Update Process

**Updating to New Version:**

1. **Backup Everything:**
   ```bash
   # Backup resource files
   cp -r resources/lb-gphone resources/lb-gphone.backup
   
   # Backup database
   mysqldump -u username -p database_name phone_% > phone_backup.sql
   ```

2. **Download New Version:**
   - Download latest release from GitHub
   - Extract to temporary location

3. **Merge Configuration:**
   ```bash
   # Keep your config.lua
   cp resources/lb-gphone/config.lua /tmp/config.lua.backup
   
   # Update resource
   rm -rf resources/lb-gphone
   cp -r /path/to/new/version resources/lb-gphone
   
   # Restore config
   cp /tmp/config.lua.backup resources/lb-gphone/config.lua
   ```

4. **Rebuild NUI:**
   ```bash
   cd resources/lb-gphone/nui
   npm install
   npm run build
   ```

5. **Update Database:**
   - Check for migration scripts
   - Run any new SQL files
   - Verify table structure

6. **Test in Development:**
   - Test on development server first
   - Verify all features work
   - Check for breaking changes

7. **Deploy to Production:**
   - Schedule during low traffic
   - Monitor for issues
   - Be ready to rollback if needed

8. **Rollback if Needed:**
   ```bash
   # Restore backup
   rm -rf resources/lb-gphone
   cp -r resources/lb-gphone.backup resources/lb-gphone
   
   # Restore database
   mysql -u username -p database_name < phone_backup.sql
   ```

---

## Advanced Configuration

### Security Configuration

**Rate Limiting:**
```lua
Config.Security = {
    enableRateLimiting = true,
    maxRequestsPerSecond = 10,
    enableAntiSpam = true,
    spamCooldown = 1000
}
```

**Input Validation:**
```lua
Config.Security = {
    validateAllInputs = true,
    enableSQLInjectionPrevention = true,
    sanitizeUserContent = true,
    logSuspiciousActivity = true
}
```

**Large Transfer Monitoring:**
```lua
Config.Security = {
    logLargeTransfers = true,
    largeTransferThreshold = 1000000000,  -- Log transfers > $1B
    logSecurityEvents = true
}
```

---

### Custom App Development

Want to add your own apps? See [Custom App Development Guide](docs/CUSTOM_APP.md) for detailed instructions.

---

### Custom Framework Adapter

Need to integrate with a custom framework? See [Custom Framework Guide](docs/CUSTOM_FRAMEWORK.md) for adapter development.

---

## Troubleshooting

### Common Installation Issues

#### Issue: Resource Won't Start

**Symptoms:**
- Error in console: "Failed to start resource"
- Resource shows as stopped in txAdmin

**Solutions:**
1. Check `fxmanifest.lua` exists and is valid
2. Verify folder name matches resource name
3. Check file permissions (Linux servers)
4. Look for syntax errors in Lua files
5. Ensure dependencies are started first

**Verification:**
```bash
# Check resource exists
dir resources/lb-gphone  # Windows
ls resources/lb-gphone   # Linux/Mac

# Check manifest
type resources\lb-gphone\fxmanifest.lua  # Windows
cat resources/lb-gphone/fxmanifest.lua   # Linux/Mac
```

✅ **Fix:** Ensure all files are present and dependencies are loaded first

---

#### Issue: Database Tables Not Created

**Symptoms:**
- SQL errors in console
- "Table doesn't exist" errors
- Phone features not working

**Solutions:**
1. **Verify oxmysql is running:**
   ```
   ensure oxmysql
   ```

2. **Check database connection:**
   - Verify connection string in oxmysql config
   - Test database credentials
   - Ensure database exists

3. **Manual table creation:**
   ```sql
   SOURCE server/sql/install_all_tables.sql;
   ```

4. **Check permissions:**
   ```sql
   SHOW GRANTS FOR 'your_user'@'localhost';
   ```

5. **Enable auto-creation:**
   ```lua
   Config.CreateTablesOnStart = true
   ```

✅ **Fix:** Manually run SQL files if auto-creation fails

---

#### Issue: NUI Not Displaying

**Symptoms:**
- Black screen when opening phone
- Phone opens but shows nothing
- JavaScript errors in F12 console

**Solutions:**
1. **Rebuild NUI:**
   ```bash
   cd nui
   rm -rf node_modules dist
   npm install
   npm run build
   ```

2. **Check build output:**
   - Verify `nui/dist/index.html` exists
   - Check `nui/dist/assets/` has files

3. **Clear FiveM cache:**
   - Close FiveM completely
   - Delete cache folder
   - Restart FiveM

4. **Check browser console:**
   - Press F12 in-game
   - Look for JavaScript errors
   - Check network tab for failed requests

5. **Verify manifest:**
   ```lua
   -- fxmanifest.lua should have:
   ui_page 'nui/dist/index.html'
   files {
       'nui/dist/index.html',
       'nui/dist/**/*'
   }
   ```

✅ **Fix:** Rebuild NUI and clear cache

---

#### Issue: Phone Won't Open

**Symptoms:**
- Pressing keybind does nothing
- No response when trying to open phone
- No errors in console

**Solutions:**
1. **Check keybind configuration:**
   ```lua
   Config.OpenKey = 'M'  -- Verify this matches your preference
   ```

2. **Check for keybind conflicts:**
   - Try different key
   - Check other resources for conflicts
   - Test with minimal resources

3. **Check player state:**
   - Ensure not dead
   - Ensure not handcuffed
   - Ensure not in vehicle trunk

4. **Check restrictions:**
   ```lua
   Config.Restrictions = {
       blockWhenDead = true,
       blockWhenCuffed = true,
       blockInTrunk = true
   }
   ```

5. **Test with command:**
   ```lua
   -- Add temporary command for testing
   RegisterCommand('testphone', function()
       TriggerEvent('phone:open')
   end)
   ```

✅ **Fix:** Verify keybind and player state

---

#### Issue: Voice Calls Not Working

**Symptoms:**
- Can't hear other player during call
- Call connects but no audio
- pma-voice errors

**Solutions:**
1. **Verify pma-voice is running:**
   ```
   ensure pma-voice
   ```

2. **Check pma-voice configuration:**
   ```lua
   Config.VoiceResource = 'pma-voice'  -- Must match resource name
   ```

3. **Test proximity voice:**
   - Verify normal voice chat works
   - Test radio channels
   - Check microphone permissions

4. **Check call channel creation:**
   - Look for errors in console
   - Verify channel prefix:
   ```lua
   Config.CallChannelPrefix = 'phone_call_'
   ```

5. **Test with two players:**
   - Both players must have working microphones
   - Both must have pma-voice working
   - Test proximity voice first

✅ **Fix:** Ensure pma-voice is properly configured and working

---

#### Issue: Framework Integration Not Working

**Symptoms:**
- Player data not loading
- Banking features not working
- Job system not integrated

**Solutions:**
1. **Verify framework is running:**
   ```
   ensure es_extended  # or qb-core, qbox
   ```

2. **Check framework configuration:**
   ```lua
   Config.Framework = 'esx'  -- Must match your framework
   ```

3. **Verify load order:**
   ```cfg
   # Framework must start before phone
   ensure es_extended
   ensure lb-gphone
   ```

4. **Test framework exports:**
   ```lua
   -- Test ESX
   local ESX = exports['es_extended']:getSharedObject()
   print(ESX)
   
   -- Test QBCore
   local QBCore = exports['qb-core']:GetCoreObject()
   print(QBCore)
   ```

5. **Try standalone mode:**
   ```lua
   Config.Framework = 'standalone'
   ```

✅ **Fix:** Verify framework is loaded before phone resource

---

#### Issue: Currency Not Formatting Correctly

**Symptoms:**
- Currency displays without formatting
- Wrong currency symbol
- Incorrect decimal places

**Solutions:**
1. **Check locale configuration:**
   ```lua
   Config.Locale = 'en'  -- Must match desired locale
   ```

2. **Verify currency settings:**
   ```lua
   Config.Currency.enabled = true
   Config.Currency.enableFormatting = true
   ```

3. **Check locale-specific settings:**
   ```lua
   Config.Currency.localeSettings.en = {
       symbol = '$',
       position = 'before',
       decimalPlaces = 2,
       -- etc.
   }
   ```

4. **Rebuild NUI:**
   ```bash
   cd nui
   npm run build
   ```

5. **Clear cache and test:**
   - Clear browser cache
   - Restart resource
   - Test in Wallet app

✅ **Fix:** Verify locale settings and rebuild NUI

---

#### Issue: Language Not Changing

**Symptoms:**
- UI stays in English
- Language selector doesn't work
- Translations not loading

**Solutions:**
1. **Verify locale files exist:**
   ```bash
   ls nui/src/i18n/locales/  # Linux/Mac
   dir nui\src\i18n\locales\  # Windows
   # Should show: en.json, ja.json, es.json, etc.
   ```

2. **Check configuration:**
   ```lua
   Config.SupportedLocales = {'en', 'ja', 'es', 'fr', 'de', 'pt'}
   Config.Internationalization.enabled = true
   ```

3. **Rebuild NUI with translations:**
   ```bash
   cd nui
   npm install
   npm run build
   ```

4. **Check translation files:**
   - Verify JSON is valid
   - Check all required keys exist
   - Compare with en.json for missing keys

5. **Test language switching:**
   - Open Settings app
   - Select Language
   - Choose different language
   - UI should update immediately

✅ **Fix:** Rebuild NUI and verify translation files are present

---

### Performance Issues

#### Issue: High Memory Usage

**Symptoms:**
- Resource using > 100MB memory
- Server lag
- Memory warnings

**Solutions:**
1. **Check for memory leaks:**
   - Monitor memory over time
   - Look for constantly increasing usage

2. **Optimize configuration:**
   ```lua
   Config.Performance.enableCaching = true
   Config.Performance.maxCachedItems = 100
   ```

3. **Reduce media storage:**
   ```lua
   Config.StorageQuotaPerPlayer = 100 * 1024 * 1024  -- 100MB
   ```

4. **Clean old data:**
   ```sql
   DELETE FROM phone_messages WHERE timestamp < DATE_SUB(NOW(), INTERVAL 30 DAY);
   DELETE FROM phone_media WHERE created_at < DATE_SUB(NOW(), INTERVAL 60 DAY);
   ```

5. **Restart resource periodically:**
   - Schedule automatic restarts during low traffic

✅ **Fix:** Optimize configuration and clean old data

---

#### Issue: Slow Database Queries

**Symptoms:**
- Lag when opening apps
- Slow message loading
- Database timeout errors

**Solutions:**
1. **Add database indexes:**
   ```sql
   CREATE INDEX idx_messages_conversation ON phone_messages(sender_phone, receiver_phone);
   CREATE INDEX idx_media_owner ON phone_media(owner_phone, created_at DESC);
   ```

2. **Optimize database:**
   ```sql
   OPTIMIZE TABLE phone_messages;
   OPTIMIZE TABLE phone_media;
   ```

3. **Enable caching:**
   ```lua
   Config.Performance.enableCaching = true
   Config.Performance.cacheExpirationTime = 300000  -- 5 minutes
   ```

4. **Increase connection pool:**
   ```lua
   Config.Performance.databaseConnectionPoolSize = 10
   ```

5. **Clean old data regularly:**
   - Set up automated cleanup scripts
   - Archive old records

✅ **Fix:** Add indexes and enable caching

---

#### Issue: NUI Performance Problems

**Symptoms:**
- Laggy UI
- Slow animations
- Low frame rate

**Solutions:**
1. **Enable performance optimizations:**
   ```lua
   Config.Performance.lazyLoadApps = true
   Config.Performance.optimizeImages = true
   Config.Performance.enableVirtualScrolling = true
   ```

2. **Reduce media quality:**
   ```lua
   Config.ImageQuality = 70  -- Lower quality
   Config.GenerateThumbnails = true
   ```

3. **Clear browser cache:**
   - F12 > Application > Clear storage
   - Restart FiveM

4. **Check client performance:**
   - Lower game graphics settings
   - Close other applications
   - Update graphics drivers

✅ **Fix:** Enable performance optimizations and reduce media quality

---

### Quick Reference Commands

**Essential Server Commands:**

```bash
# Resource Management
ensure lb-gphone              # Start the phone resource
restart lb-gphone             # Restart the phone resource
stop lb-gphone                # Stop the phone resource
refresh                       # Refresh resource list

# Monitoring
resmon                        # Resource monitor (memory, CPU usage)
status                        # Server status and player count

# Dependencies
ensure oxmysql                # Start database resource
ensure pma-voice              # Start voice resource
```

**Database Commands:**

```sql
-- Connection
mysql -u username -p database_name

-- Check Phone Tables
SHOW TABLES LIKE 'phone_%';

-- Player Phone Numbers
SELECT * FROM phone_players ORDER BY created_at DESC LIMIT 10;

-- Recent Transactions
SELECT * FROM phone_transactions ORDER BY timestamp DESC LIMIT 20;

-- Database Size
SELECT 
    table_name AS 'Table',
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.TABLES
WHERE table_schema = 'your_database'
AND table_name LIKE 'phone_%'
ORDER BY (data_length + index_length) DESC;
```

**NUI Build Commands:**

```bash
# Navigate to NUI directory
cd resources/lb-gphone/nui

# Fresh Install
rm -rf node_modules dist
npm install
npm run build

# Quick Rebuild
npm run build

# Development Mode (with hot-reload)
npm run dev
```

---

## Frequently Asked Questions

### General Questions

**Q: Do I need a framework to use this resource?**

A: No, the resource works in standalone mode without any framework.

---

**Q: Can I use this with my existing phone resource?**

A: It's recommended to disable other phone resources to avoid conflicts.

---

**Q: How many players can use this resource?**

A: Tested and optimized for 200+ concurrent players.

---

**Q: Is this resource free?**

A: Check the [LICENSE.MD](LICENSE.MD) file and GitHub repository for usage terms.

---

### Installation Questions

**Q: Do I need to manually create database tables?**

A: No, tables are created automatically on first start. However, you can manually run SQL files if needed.

---

**Q: Can I skip the NUI build step?**

A: No, the NUI must be built for the phone to display properly.

---

**Q: What Node.js version do I need?**

A: Node.js 16 or higher is required.

---

**Q: Can I install this on a Windows server?**

A: Yes, it works on Windows, Linux, and other platforms.

---

**Q: How long does installation take?**

A: Typically 10-15 minutes including NUI build and configuration.

---

### Configuration Questions

**Q: Can I change the phone keybind?**

A: Yes, edit `Config.OpenKey` in config.lua.

---

**Q: Can I disable specific apps?**

A: Yes, set the app to `false` in `Config.EnabledApps`.

---

**Q: Can I add more languages?**

A: Yes, create translation files in `nui/src/i18n/locales/` and `server/locales/`, then add to supported locales.

---

**Q: Can I change the currency symbol?**

A: Yes, configure in `Config.Currency.localeSettings`.

---

**Q: Can I change the maximum transfer amount?**

A: Yes, edit `Config.WalletApp.maxTransferAmount` in config.lua. Default is 999 trillion.

---

### Integration Questions

**Q: Does this work with ESX?**

A: Yes, full ESX Legacy support with auto-detection.

---

**Q: Does this work with QBCore?**

A: Yes, full QBCore support with auto-detection.

---

**Q: Does this work with Qbox?**

A: Yes, full Qbox support with auto-detection.

---

**Q: Can I integrate with my custom housing script?**

A: Yes, create a custom adapter. See [Custom Framework Guide](docs/CUSTOM_FRAMEWORK.md).

---

**Q: Does this work with qb-banking?**

A: Yes, configure in `Config.WalletApp.bankingScript`.

---

### Technical Questions

**Q: What database does this use?**

A: MySQL 5.7+ or MariaDB 10.2+ via oxmysql.

---

**Q: How much storage does media require?**

A: Configurable per player, default is 500MB quota.

---

**Q: Can I use a CDN for media storage?**

A: Yes, configure `Config.MediaStorage = 'fivemanage'` or `'cdn'`.

---

**Q: What's the maximum currency amount?**

A: 999,000,000,000,000 (999 trillion).

---

**Q: Does this support voice calls?**

A: Yes, via pma-voice integration.

---

**Q: How many database tables does this create?**

A: 50+ tables for all phone features and apps.

---

### Troubleshooting Questions

**Q: Phone won't open, what should I check?**

A: Check keybind configuration, player state (not dead/cuffed), and console for errors.

---

**Q: NUI shows black screen, how to fix?**

A: Rebuild NUI (`npm run build`), clear FiveM cache, and check F12 console for errors.

---

**Q: Database errors on start, what's wrong?**

A: Check oxmysql connection string and database permissions. Verify database exists.

---

**Q: Voice calls don't work, why?**

A: Verify pma-voice is running and configured correctly. Test proximity voice first.

---

**Q: High memory usage, how to reduce?**

A: Enable caching, reduce media quota, clean old data, and optimize performance settings.

---

**Q: How do I update to a new version?**

A: Backup everything, download new version, merge config, rebuild NUI, and test before deploying.

---

**Q: Can I rollback to a previous version?**

A: Yes, restore from backup (both files and database).

---

### Feature Questions

**Q: Can players change their phone number?**

A: This depends on your configuration. Check `Config.AllowPhoneNumberChange`.

---

**Q: Can I customize the phone UI?**

A: Yes, the NUI is built with Vue.js and can be customized. See [Custom App Guide](docs/CUSTOM_APP.md).

---

**Q: Does this support multiple currencies?**

A: Yes, each locale can have its own currency format and symbol.

---

**Q: Can I add custom apps?**

A: Yes, see [Custom App Development Guide](docs/CUSTOM_APP.md).

---

**Q: Does this work with inventory systems?**

A: Yes, it can integrate with most inventory systems through framework adapters.

---

## Getting Help

If you're still experiencing issues after trying the troubleshooting solutions:

### Documentation

| Document | Description |
|----------|-------------|
| [README.md](README.md) | Overview and quick start |
| [DOCUMENTATION.md](docs/DOCUMENTATION.md) | Complete technical documentation |
| [SQL_TESTING.md](docs/SQL_TESTING.md) | Database testing guide |
| [VALIDATION_CHECKLIST.md](docs/VALIDATION_CHECKLIST.md) | Installation validation |

### Community Support

**GitHub Issues:**
- **Bug Reports**: [Report a bug](https://github.com/FosterG4/lb-gphone.git/issues/new?template=bug_report.md)
- **Feature Requests**: [Request a feature](https://github.com/FosterG4/lb-gphone.git/issues/new?template=feature_request.md)
- **Questions**: [GitHub Discussions](https://github.com/FosterG4/lb-gphone.git/discussions)

**Before Posting:**
1. Search existing issues and discussions
2. Check documentation thoroughly
3. Enable debug mode and collect logs
4. Provide detailed information about your setup

**Information to Include:**
- FiveM server version
- Framework (ESX, QBCore, Qbox, Standalone)
- Node.js version
- MySQL/MariaDB version
- Error messages from console
- Steps to reproduce the issue

### Debug Mode

Enable detailed logging for troubleshooting:

```lua
-- config.lua
Config.Debug = true
Config.VerboseLogging = true
Config.Security.logSecurityEvents = true
```

This provides detailed logs in server console for troubleshooting.

### Minimal Test

To isolate issues:
1. Test with minimal resources (only dependencies + phone)
2. Disable other phone resources
3. Test in standalone mode
4. Check if issue persists

---

## Installation Checklist

Use this checklist to ensure complete installation:

### Pre-Installation
- [ ] Server meets system requirements
- [ ] Node.js 16+ installed
- [ ] MySQL/MariaDB running
- [ ] Backup existing data

### Dependencies
- [ ] oxmysql installed and configured
- [ ] pma-voice installed and working
- [ ] Framework installed (if using one)
- [ ] Database connection tested

### Resource Installation
- [ ] Resource downloaded from GitHub
- [ ] Folder named correctly (`lb-gphone`)
- [ ] NUI built successfully (`npm run build`)
- [ ] Files present in `nui/dist/`

### Configuration
- [ ] `config.lua` edited for your server
- [ ] Framework configured correctly
- [ ] Locale set to desired language
- [ ] Currency configured
- [ ] Apps enabled/disabled as needed
- [ ] Integrations configured (housing, garage)

### Server Configuration
- [ ] Dependencies added to `server.cfg`
- [ ] Load order correct
- [ ] Resource added to `server.cfg`
- [ ] Server restarted

### Verification
- [ ] Resource starts without errors
- [ ] Database tables created (50+ tables)
- [ ] Phone opens in-game
- [ ] Core features work (contacts, messages, calls)
- [ ] Framework integration works
- [ ] Currency formats correctly
- [ ] Language displays correctly

### Post-Installation
- [ ] Performance monitored
- [ ] Backup created
- [ ] Documentation reviewed
- [ ] Players informed of new feature

---

## Additional Resources

### Quick Reference

**Default Keybind:** M

**Default Phone Number Format:** ###-####

**Default Language:** English (en)

**Default Currency:** USD ($)

**Maximum Currency:** 999,000,000,000,000 (999 trillion)

**Supported Frameworks:** ESX, QBCore, Qbox, Standalone

**Supported Languages:** English, Japanese, Spanish, French, German, Portuguese

### Configuration Files

| File | Purpose |
|------|---------|
| `config.lua` | Main configuration |
| `fxmanifest.lua` | Resource manifest |
| `nui/src/i18n/locales/*.json` | UI translations |
| `server/locales/*.lua` | Server messages |

### Important Directories

| Directory | Contents |
|-----------|----------|
| `client/` | Client-side Lua scripts |
| `server/` | Server-side Lua scripts |
| `nui/` | Vue.js NUI interface |
| `nui/dist/` | Built NUI files |
| `docs/` | Documentation |
| `server/sql/` | Database schema files |

---

## Conclusion

Congratulations! You've successfully installed the lb-gphone FiveM smartphone resource.

### Next Steps

1. **Customize Configuration**: Adjust settings to match your server
2. **Test All Features**: Verify everything works as expected
3. **Train Staff**: Ensure admins know how to support players
4. **Inform Players**: Announce the new phone system
5. **Monitor Performance**: Keep an eye on resource usage
6. **Regular Maintenance**: Schedule backups and cleanup

### Stay Updated

- ⭐ Star the [GitHub repository](https://github.com/FosterG4/lb-gphone.git) for updates
- 👀 Watch for new releases and features
- 📖 Check documentation for updates
- 🐛 Report bugs and suggest improvements

### Thank You

Thank you for choosing the lb-gphone FiveM smartphone resource. We hope it enhances your server and provides an excellent experience for your players.

For questions, support, or feedback:
- **GitHub**: [https://github.com/FosterG4/lb-gphone.git](https://github.com/FosterG4/lb-gphone.git)
- **Issues**: [Report bugs](https://github.com/FosterG4/lb-gphone.git/issues)
- **Discussions**: [Ask questions](https://github.com/FosterG4/lb-gphone.git/discussions)

---

<div align="center">

**Made with ❤️ for the FiveM community**

[⬆ Back to Top](#-lb-gphone---installation-guide)

</div>
