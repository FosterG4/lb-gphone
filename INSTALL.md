# 📱 lb-gphone - Installation Guide

<div align="center">

[![GitHub Repository](https://img.shields.io/badge/GitHub-lb--gphone-blue?style=for-the-badge&logo=github)](https://github.com/FosterG4/lb-gphone.git)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-green?style=for-the-badge&logo=fivem)](https://fivem.net)
[![License](https://img.shields.io/badge/License-Check%20Repo-orange?style=for-the-badge)](https://github.com/FosterG4/lb-gphone.git)

**Complete step-by-step installation guide for the lb-gphone FiveM smartphone resource**

**Repository:** [https://github.com/FosterG4/lb-gphone.git](https://github.com/FosterG4/lb-gphone.git)

---

### 🌟 Key Features
- 💰 **Advanced Currency System** - Supports up to 999 trillion in transfers
- 🌍 **Multi-Language Support** - 6 languages (EN, JA, ES, FR, DE, PT)
- 🔧 **Framework Flexible** - Works with ESX, QBCore, Qbox, or Standalone
- 📱 **Modern UI** - Beautiful Vue.js interface with smooth animations
- 🔒 **Secure & Validated** - Comprehensive input validation and security

---

[🚀 Quick Start](#quick-start) • [📋 Prerequisites](#prerequisites) • [⚙️ Configuration](#configuration) • [💰 Currency System](#currency-system-capabilities) • [🔧 Troubleshooting](#troubleshooting)

</div>

---

## 📑 Table of Contents

### 🚀 Getting Started
1. [Prerequisites](#prerequisites) - System requirements and dependencies
2. [Quick Start](#quick-start) - Fast installation for experienced admins
3. [Detailed Installation Steps](#detailed-installation-steps) - Step-by-step guide

### ⚙️ Configuration
4. [Dependency Installation](#dependency-installation) - oxmysql and pma-voice setup
5. [Framework Integration](#framework-integration) - ESX, QBCore, Qbox, Standalone
6. [Housing & Garage Script Setup](#housing--garage-script-setup) - Optional integrations
7. [Locale and Currency Configuration](#locale-and-currency-configuration) - Multi-language and currency
8. [Currency System Capabilities](#currency-system-capabilities) - 999 trillion transfer support

### ✅ Verification & Support
9. [Post-Installation Verification](#post-installation-verification) - Testing your setup
10. [Troubleshooting](#troubleshooting) - Common issues and solutions
11. [Advanced Configuration](#advanced-configuration) - Performance tuning and customization

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
- **Purpose**: Database operations and query handling
- **Download**: [GitHub - oxmysql](https://github.com/overextended/oxmysql)
- **Version**: Latest release
- **Installation**: Follow oxmysql documentation for setup

#### 2. pma-voice (Required)
- **Purpose**: Voice call integration and audio channels
- **Download**: [GitHub - pma-voice](https://github.com/AvarianKnight/pma-voice)
- **Version**: Latest release
- **Installation**: Follow pma-voice documentation for setup

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

- **Housing Script**: For property management features (qb-houses, qs-housing, etc.)
- **Garage Script**: For vehicle management features (qb-garages, cd_garage, etc.)
- **Banking Script**: For enhanced financial operations (qb-banking, okokBanking, etc.)
- **Audio Resource**: For music streaming (xsound, interact-sound)

---

## Quick Start


For experienced server administrators, here's the quick installation process:

```bash
# 1. Clone from GitHub and extract to resources folder
cd resources/
git clone https://github.com/FosterG4/lb-gphone.git

# 2. Build NUI interface
cd lb-gphone/nui
npm install
npm run build

# 3. Add to server.cfg (in order)
ensure oxmysql
ensure pma-voice
ensure es_extended  # or qb-core, qbox (if using a framework)
ensure lb-gphone

# 4. Configure config.lua
# Edit config.lua to match your server setup

# 5. Start server
# Database tables will be created automatically
```

**That's it!** The resource will auto-configure on first start.

---

## Detailed Installation Steps

### Step 1: Download the Resource

**Option A: Clone from GitHub (Recommended)**
```bash
cd /path/to/your/server/resources
git clone https://github.com/FosterG4/lb-gphone.git
```

**Option B: Download Release**
1. Go to the [Releases page](https://github.com/FosterG4/lb-gphone/releases)
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


### Step 2: Build the NUI Interface

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
```
✓ built in XXXms
✓ dist/index.html
✓ dist/assets/...
```

**Verify Build:**
Check that `nui/dist/` folder contains:
- `index.html`
- `assets/` folder with JS and CSS files

✅ **Verification:** Run `ls nui/dist/` to confirm files are present.

**Development Mode (Optional):**
For development with hot-reload:
```bash
npm run dev
```

**Troubleshooting Build Issues:**
- **Error: Node version**: Upgrade to Node.js 16+
- **Error: npm not found**: Install Node.js which includes npm
- **Error: Permission denied**: Run with appropriate permissions
- **Error: Out of memory**: Increase Node.js memory: `NODE_OPTIONS=--max-old-space-size=4096 npm run build`

### Step 3: Add to server.cfg

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

✅ **Verification:** Start your server and check console for `[Phone] Resource started successfully!`

---

## Dependency Installation

### Installing oxmysql

**Step 1: Download oxmysql**
```bash
cd resources/
git clone https://github.com/overextended/oxmysql.git
```

**Step 2: Configure Database Connection**

Create or edit `oxmysql.cfg` in your server root:
```cfg
set mysql_connection_string "mysql://username:password@localhost/database?charset=utf8mb4"
```

**Alternative: Using server.cfg**
```cfg
set mysql_connection_string "mysql://username:password@localhost/database?charset=utf8mb4"
```


**Step 3: Test Database Connection**

Start your server and check console for:
```
[oxmysql] Database server connection established!
```

✅ **Verification:** Run `ensure oxmysql` in server console and confirm no errors appear.

**Common Database Issues:**
- **Connection refused**: Check MySQL is running
- **Access denied**: Verify username/password
- **Unknown database**: Create database first
- **Charset issues**: Use `charset=utf8mb4` in connection string

### Installing pma-voice

**Step 1: Download pma-voice**
```bash
cd resources/
git clone https://github.com/AvarianKnight/pma-voice.git
```

**Step 2: Configure pma-voice**

Edit `pma-voice/config.lua`:
```lua
Config = {
    voiceTarget = 1,
    micClicks = true,
    -- Additional configuration...
}
```

**Step 3: Add to server.cfg**
```cfg
ensure pma-voice
```

**Step 4: Verify Installation**

In-game, check that:
- Voice icon appears on screen
- Proximity voice works
- Radio channels work (if applicable)

✅ **Verification:** Test proximity voice with another player before proceeding.

**pma-voice Troubleshooting:**
- **No voice icon**: Check resource is started
- **Can't hear others**: Check audio settings
- **Microphone not working**: Check FiveM audio permissions

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
- Uses FiveM license identifiers
- Built-in banking system
- No external framework required
- Perfect for custom servers

**server.cfg:**
```cfg
ensure oxmysql
ensure pma-voice
ensure lb-gphone
```

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
- Uses ESX player identifiers
- Integrates with ESX banking (bank account)
- Supports ESX job system
- Compatible with ESX society accounts

**Verification:**
Check server console for:
```
[Phone] Framework: ESX detected and loaded
```

✅ **Quick Test:** Join the server and verify you receive a phone number automatically.


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
- Uses QBCore citizen IDs
- Integrates with QBCore banking
- Supports QBCore job system
- Compatible with qb-banking

**Verification:**
Check server console for:
```
[Phone] Framework: QBCore detected and loaded
```

✅ **Quick Test:** Join the server and verify you receive a phone number automatically.

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
- Uses Qbox player identifiers
- Integrates with Qbox banking
- Supports Qbox job system
- Full compatibility with Qbox ecosystem

**Verification:**
Check server console for:
```
[Phone] Framework: Qbox detected and loaded
```

✅ **Quick Test:** Join the server and verify you receive a phone number automatically.

### Framework Troubleshooting

**Issue: Framework not detected**
- Verify framework resource is started before phone
- Check `Config.Framework` matches your framework
- Look for errors in server console
- Try manual configuration instead of auto-detection

**Issue: Banking integration not working**
- Verify framework banking system is functional
- Check player has bank account
- Test framework banking commands separately
- Review framework adapter logs

**Issue: Player data not loading**
- Ensure framework is fully initialized before phone
- Check player identifiers are correct
- Verify database tables exist
- Test with standalone mode to isolate issue

---

## Housing & Garage Script Setup

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
    keyExpirationDays = 7,
    maxKeysPerProperty = 10,
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

**Troubleshooting Housing Integration:**
- **Properties not showing**: Check housing script exports
- **Can't lock/unlock**: Verify door control permissions
- **Keys not working**: Check key management system
- **No integration**: Set `housingScript = 'none'` to disable


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
    valetSpawnDistance = 10,
    valetTimeout = 30,
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

4. **Configure Valet Service** (Optional)
   ```lua
   Config.GarageApp.enableValet = true
   Config.GarageApp.valetCost = 100  -- Cost to spawn vehicle
   Config.GarageApp.valetSpawnDistance = 10  -- Meters from player
   ```

5. **Verify Integration**
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

**Troubleshooting Garage Integration:**
- **Vehicles not showing**: Check garage script exports
- **Valet not working**: Verify spawn permissions
- **Location not updating**: Check tracking interval
- **No integration**: Set `garageScript = 'none'` to disable

### Custom Script Integration

For custom housing or garage scripts, you can create custom adapters:

**Housing Adapter Example:**
```lua
-- server/framework/housing_adapter.lua
function HousingAdapter:GetPlayerProperties(source)
    -- Your custom logic here
    return properties
end

function HousingAdapter:LockDoor(propertyId)
    -- Your custom logic here
end
```

**Garage Adapter Example:**
```lua
-- server/framework/garage_adapter.lua
function GarageAdapter:GetPlayerVehicles(source)
    -- Your custom logic here
    return vehicles
end

function GarageAdapter:SpawnVehicle(plate, coords)
    -- Your custom logic here
end
```

See [Custom Framework Guide](docs/CUSTOM_FRAMEWORK.md) for detailed adapter development.

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
- **Client (NUI)**: `nui/src/i18n/locales/`
  - `en.json` - English translations
  - `ja.json` - Japanese translations
  - `es.json` - Spanish translations
  - etc.

- **Server (Lua)**: `server/locales/`
  - `en.lua` - English server messages
  - `ja.lua` - Japanese server messages
  - etc.

**Adding Custom Languages:**

1. **Create NUI Translation File:**
   ```json
   // nui/src/i18n/locales/custom.json
   {
     "common": {
       "ok": "OK",
       "cancel": "Cancel",
       "save": "Save"
     },
     "apps": {
       "contacts": "Contacts",
       "messages": "Messages"
     }
   }
   ```


2. **Create Server Locale File:**
   ```lua
   -- server/locales/custom.lua
   Locales['custom'] = {
       ['phone_number_assigned'] = 'Phone number assigned: %s',
       ['insufficient_funds'] = 'Insufficient funds',
       ['transfer_success'] = 'Transfer successful: %s'
   }
   ```

3. **Add to Configuration:**
   ```lua
   Config.SupportedLocales = {'en', 'ja', 'custom'}
   ```

4. **Rebuild NUI:**
   ```bash
   cd nui
   npm run build
   ```

**Language Switching:**
Players can change language in Settings app:
1. Open Phone
2. Go to Settings
3. Select Language
4. Choose preferred language
5. UI updates immediately

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
    },
    
    -- Euro (French)
    fr = {
        symbol = '€',
        position = 'after',
        decimalPlaces = 2,
        thousandsSeparator = ' ',
        decimalSeparator = ',',
        format = '%s %s'  -- 1 234,56 €
    },
    
    -- Euro (German)
    de = {
        symbol = '€',
        position = 'after',
        decimalPlaces = 2,
        thousandsSeparator = '.',
        decimalSeparator = ',',
        format = '%s %s'  -- 1.234,56 €
    },
    
    -- Brazilian Real (Portuguese)
    pt = {
        symbol = 'R$',
        position = 'before',
        decimalPlaces = 2,
        thousandsSeparator = '.',
        decimalSeparator = ',',
        format = '%s %s'  -- R$ 1.234,56
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

**Testing Currency Configuration:**

1. Open phone in-game
2. Navigate to Wallet app
3. Check balance display format
4. Test transfer with large amounts
5. Verify error handling for amounts > 999 trillion

---

## Currency System Capabilities

### 💰 Maximum Transfer Support: 999 Trillion

The lb-gphone resource features an advanced currency system that supports transfers up to **999,000,000,000,000** (999 trillion). This capability is built into the core system and works seamlessly with all supported frameworks.

### Understanding the Currency System

**System Architecture:**

The currency system has two key configuration values that work together:

```lua
-- config.lua
Config.Currency = {
    maxValue = 999000000000000,  -- System maximum: 999 trillion
    -- ... other currency settings
}

Config.WalletApp = {
    maxTransferAmount = 999000000000000,  -- Transfer limit: 999 trillion
    minTransferAmount = 1,  -- Minimum: $1
    -- ... other wallet settings
}
```

**Key Features:**

| Feature | Capability | Description |
|---------|------------|-------------|
| **Maximum Amount** | 999,000,000,000,000 | 999 trillion (15 digits) |
| **Minimum Amount** | 1 | $1 or equivalent |
| **Validation** | Server & Client | Dual-layer validation for security |
| **Formatting** | Locale-Specific | Automatic formatting per language |
| **Abbreviation** | Smart Display | Shows "999T" for large amounts |
| **Database Support** | BIGINT/DECIMAL | Handles 15-digit numbers natively |

### Relationship Between Transfer Limits and Currency System

The `maxTransferAmount` and `maxValue` are designed to work together:

- **`Config.Currency.maxValue`**: The absolute maximum value the currency system can handle
- **`Config.WalletApp.maxTransferAmount`**: The maximum amount allowed in a single transfer

By default, both are set to 999 trillion, meaning:
- ✅ Players can transfer up to 999 trillion in a single transaction
- ✅ The system can handle balances up to 999 trillion
- ✅ All currency operations are validated against these limits

### Configuration Examples

**Example 1: Default Configuration (999 Trillion)**
```lua
Config.Currency.maxValue = 999000000000000
Config.WalletApp.maxTransferAmount = 999000000000000
```
This allows maximum flexibility for high-value economies.

**Example 2: Conservative Limit (10 Million)**
```lua
Config.Currency.maxValue = 999000000000000  -- Keep system max
Config.WalletApp.maxTransferAmount = 10000000  -- Limit transfers to $10M
```
This restricts individual transfers while maintaining system capacity.

**Example 3: Progressive Limits**
```lua
Config.Currency.maxValue = 999000000000000
Config.WalletApp.maxTransferAmount = 100000000  -- $100M transfer limit
Config.WalletApp.dailyTransferLimit = 500000000  -- $500M daily limit (if enabled)
```
This provides multiple layers of transfer control.

### Large Amount Transfer Examples

**Example Transfer Scenarios:**

| Amount | Display (en-US) | Display (Abbreviated) | Use Case |
|--------|-----------------|----------------------|----------|
| 1,000 | $1,000.00 | $1K | Small transaction |
| 1,000,000 | $1,000,000.00 | $1M | Medium transaction |
| 1,000,000,000 | $1,000,000,000.00 | $1B | Large transaction |
| 1,000,000,000,000 | $1,000,000,000,000.00 | $1T | Massive transaction |
| 999,000,000,000,000 | $999,000,000,000,000.00 | $999T | Maximum transfer |

**Testing Large Transfers:**

1. **Test Maximum Amount:**
   ```lua
   -- In-game, attempt transfer of 999000000000000
   -- Should succeed with proper formatting
   ```

2. **Test Above Maximum:**
   ```lua
   -- Attempt transfer of 999000000000001
   -- Should fail with error: "Amount exceeds maximum transfer limit of $999T"
   ```

3. **Test Formatting:**
   ```lua
   -- Verify large amounts display correctly in:
   -- - Wallet balance
   -- - Transfer form
   -- - Transaction history
   -- - Error messages
   ```

### Currency Validation

**Server-Side Validation:**

The system validates all transfers on the server to prevent exploitation:

```lua
-- Automatic validation checks:
1. Amount is a valid number
2. Amount >= minTransferAmount (1)
3. Amount <= maxTransferAmount (999000000000000)
4. Sender has sufficient balance
5. Recipient exists and is valid
```

**Client-Side Validation:**

The UI provides immediate feedback before sending to server:

```javascript
// Real-time validation in transfer form:
- Input accepts up to 15 digits
- Shows formatted preview
- Displays error if exceeds maximum
- Prevents submission of invalid amounts
```

### Error Handling for Large Amounts

**Error Messages:**

When limits are exceeded, users receive clear, localized error messages:

| Scenario | Error Message (English) |
|----------|------------------------|
| Amount too high | "Amount exceeds maximum transfer limit of $999T" |
| Amount too low | "Amount must be at least $1" |
| Insufficient funds | "Insufficient funds for this transfer" |
| Invalid format | "Please enter a valid amount" |

**Error Message Localization:**

All error messages are automatically formatted with the correct currency symbol and format for the user's selected language:

- **English (en)**: "Amount exceeds maximum transfer limit of $999T"
- **Japanese (ja)**: "金額が最大送金限度額¥999Tを超えています"
- **Spanish (es)**: "El monto excede el límite máximo de transferencia de 999T €"
- **French (fr)**: "Le montant dépasse la limite de transfert maximale de 999T €"
- **German (de)**: "Der Betrag überschreitet das maximale Überweisungslimit von 999T €"
- **Portuguese (pt)**: "O valor excede o limite máximo de transferência de R$ 999T"

### Customizing Transfer Limits

**For Server Administrators:**

You can easily customize the maximum transfer amount to suit your server's economy:

1. **Open config.lua**
2. **Locate the WalletApp section:**
   ```lua
   Config.WalletApp = {
       maxTransferAmount = 999000000000000,  -- Change this value
   }
   ```
3. **Set your desired limit:**
   ```lua
   -- Example: Limit to $1 million
   Config.WalletApp.maxTransferAmount = 1000000
   ```
4. **Restart the resource:**
   ```
   restart lb-gphone
   ```

**Important Notes:**

- ⚠️ `maxTransferAmount` should never exceed `Config.Currency.maxValue`
- ⚠️ Changes take effect immediately after resource restart
- ⚠️ Existing transactions are not affected by limit changes
- ✅ No database changes required
- ✅ No code modifications needed

### Performance Considerations

**Large Number Handling:**

The system is optimized to handle 15-digit numbers efficiently:

- **Database**: Uses BIGINT or DECIMAL(20,2) for storage
- **Lua**: Native number type supports up to 2^53-1 (9 quadrillion)
- **JavaScript**: Number type safe up to 2^53-1 (9 quadrillion)
- **Performance**: No degradation with large values

**Benchmarks:**

| Operation | Time | Notes |
|-----------|------|-------|
| Input validation | < 1ms | Server-side check |
| Currency formatting | < 5ms | Includes abbreviation |
| Database transaction | < 100ms | Standard query time |
| UI rendering | < 50ms | Client-side display |

### Security Features

**Anti-Exploitation Measures:**

1. **Server Authority**: All transfers validated server-side
2. **Rate Limiting**: Prevents spam transfers
3. **Audit Logging**: All large transfers logged
4. **Balance Verification**: Double-checks before and after transfer
5. **Atomic Transactions**: Database rollback on any error

**Monitoring Large Transfers:**

Enable logging for security monitoring:

```lua
Config.Security = {
    logLargeTransfers = true,
    largeTransferThreshold = 1000000000,  -- Log transfers > $1B
    logSecurityEvents = true
}
```

### Troubleshooting Currency Issues

**Issue: Transfer rejected despite sufficient funds**

**Solution:**
1. Check `Config.WalletApp.maxTransferAmount` value
2. Verify amount doesn't exceed configured limit
3. Check server console for validation errors
4. Test with smaller amount to isolate issue

**Issue: Currency displays incorrectly**

**Solution:**
1. Verify `Config.Currency.enableFormatting = true`
2. Check locale-specific currency settings
3. Rebuild NUI: `cd nui && npm run build`
4. Clear browser cache and restart resource

**Issue: Error message shows wrong currency symbol**

**Solution:**
1. Check `Config.Locale` matches desired language
2. Verify currency settings for that locale
3. Ensure translation files are up to date
4. Test language switching in Settings app

### Best Practices

**For Server Administrators:**

1. ✅ **Set Realistic Limits**: Match your server's economy
2. ✅ **Enable Logging**: Monitor large transfers for security
3. ✅ **Test Thoroughly**: Verify limits work as expected
4. ✅ **Document Changes**: Inform players of transfer limits
5. ✅ **Regular Backups**: Backup database before limit changes

**For Players:**

1. ✅ **Check Limits**: Know your server's maximum transfer
2. ✅ **Verify Recipient**: Double-check phone numbers
3. ✅ **Use Formatting**: System shows formatted preview
4. ✅ **Review History**: Check transaction history for confirmation
5. ✅ **Report Issues**: Contact admins if transfers fail unexpectedly

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

### In-Game Verification

**Test Checklist:**

1. **Phone Opens**
   - Press configured key (default: M)
   - Phone UI appears
   - No errors in F8 console

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

### Database Verification

**Check Tables Created:**

Connect to your MySQL database and verify these tables exist:

```sql
SHOW TABLES LIKE 'phone_%';
```

**Expected Tables (50+):**
- phone_players
- phone_contacts
- phone_messages
- phone_call_history
- phone_settings
- phone_media
- phone_albums
- phone_notes
- phone_alarms
- phone_vehicles
- phone_properties
- phone_shotz_posts
- phone_chirper_posts
- phone_modish_videos
- phone_flicker_profiles
- phone_marketplace_listings
- phone_business_pages
- phone_cryptox_holdings
- phone_musicly_playlists
- phone_finder_devices
- And more...

**Test Database Operations:**

```sql
-- Check if player phone numbers are being assigned
SELECT * FROM phone_players LIMIT 5;

-- Check if messages are being stored
SELECT * FROM phone_messages ORDER BY timestamp DESC LIMIT 5;

-- Check if contacts are being saved
SELECT * FROM phone_contacts LIMIT 5;
```

### SQL File Organization

The database schema is organized into logical SQL files in the `server/sql/` directory for easy maintenance and manual installation if needed.

**SQL File Structure:**

```
server/sql/
├── install_all_tables.sql                    # Master installation script
├── phone_core_tables.sql                     # Core system tables
├── phone_media_tables.sql                    # Media storage tables
├── phone_wallet_tables.sql                   # Wallet/banking tables
├── phone_cryptox_tables.sql                  # Crypto trading tables
├── phone_musicly_tables.sql                  # Music app tables
├── phone_finder_tables.sql                   # Finder/GPS tables
├── phone_safezone_tables.sql                 # Emergency/safety tables
├── phone_marketplace_tables.sql              # Marketplace tables
├── phone_business_tables.sql                 # Business pages tables
├── phone_utilities_tables.sql                # Notes, alarms, voice recorder
├── phone_assets_tables.sql                   # Vehicles and properties
├── phone_chirper_tables.sql                  # Chirper social media
├── phone_shotz_additional_tables.sql         # Shotz photo sharing
├── phone_modish_tables.sql                   # Modish video sharing
├── phone_flicker_tables.sql                  # Flicker dating app
├── phone_contact_sharing_tables.sql          # Contact sharing features
└── phone_social_media_multi_attachments.sql  # Multi-media attachments
```

**Table Groups:**

| SQL File | Tables Included | Purpose |
|----------|----------------|---------|
| **phone_core_tables.sql** | phone_players, phone_contacts, phone_messages, phone_call_history, phone_settings | Core phone functionality |
| **phone_media_tables.sql** | phone_media, phone_albums, phone_album_media | Photo, video, and audio storage |
| **phone_wallet_tables.sql** | phone_bankr_transactions, phone_bankr_budgets, phone_bankr_recurring, phone_bank_transactions | Financial transactions and budgets |
| **phone_cryptox_tables.sql** | phone_cryptox_holdings, phone_cryptox_transactions, phone_cryptox_alerts, phone_crypto | Cryptocurrency trading |
| **phone_musicly_tables.sql** | phone_musicly_playlists, phone_musicly_playlist_tracks, phone_musicly_play_history | Music streaming and playlists |
| **phone_finder_tables.sql** | phone_finder_devices, phone_finder_settings, phone_location_pins, phone_shared_locations | GPS and device tracking |
| **phone_safezone_tables.sql** | phone_safezone_contacts, phone_safezone_settings, phone_safezone_emergencies, phone_safezone_calls | Emergency features |
| **phone_marketplace_tables.sql** | phone_marketplace_listings, phone_marketplace_transactions, phone_marketplace_reviews, phone_marketplace_favorites | Item marketplace |
| **phone_business_tables.sql** | phone_business_pages, phone_page_followers, phone_page_reviews, phone_page_views | Business pages |
| **phone_utilities_tables.sql** | phone_notes, phone_alarms, phone_voice_recordings, phone_voice_recorder_settings | Productivity tools |
| **phone_assets_tables.sql** | phone_vehicles, phone_properties, phone_property_keys, phone_access_logs | Asset management |

### Manual SQL Installation

If automatic table creation fails or you prefer manual installation, you can execute the SQL files directly.

**Option 1: Install All Tables at Once (Recommended)**

```bash
# Connect to MySQL
mysql -u username -p database_name

# Execute master installation script
SOURCE server/sql/install_all_tables.sql;
```

The master script executes all SQL files in the correct dependency order and handles errors gracefully.

**Option 2: Install Individual SQL Files**

If you need to install specific table groups:

```bash
# Connect to MySQL
mysql -u username -p database_name

# Install core tables first (required by other tables)
SOURCE server/sql/phone_core_tables.sql;

# Install media tables
SOURCE server/sql/phone_media_tables.sql;

# Install app-specific tables as needed
SOURCE server/sql/phone_wallet_tables.sql;
SOURCE server/sql/phone_cryptox_tables.sql;
SOURCE server/sql/phone_musicly_tables.sql;
# ... etc
```

**Option 3: Using MySQL Command Line**

```bash
# Execute from command line without entering MySQL shell
mysql -u username -p database_name < server/sql/install_all_tables.sql

# Or individual files
mysql -u username -p database_name < server/sql/phone_core_tables.sql
```

**Important Notes:**

- All SQL files use `CREATE TABLE IF NOT EXISTS`, so they can be safely re-executed
- The master script (`install_all_tables.sql`) handles dependency order automatically
- Core tables must be created before app-specific tables due to foreign key relationships
- Each SQL file includes comprehensive documentation and comments

### Troubleshooting SQL Installation

#### Issue: SQL File Not Found

**Symptoms:**
- Error: "No such file or directory"
- SOURCE command fails

**Solutions:**

1. **Verify file path:**
   ```bash
   # Check if SQL files exist
   ls server/sql/
   ```

2. **Use absolute path:**
   ```sql
   -- Instead of relative path
   SOURCE /full/path/to/server/sql/install_all_tables.sql;
   ```

3. **Navigate to resource directory first:**
   ```bash
   cd resources/lb-gphone
   mysql -u username -p database_name < server/sql/install_all_tables.sql
   ```

#### Issue: Permission Denied

**Symptoms:**
- Error: "Access denied for user"
- Cannot create tables

**Solutions:**

1. **Check database permissions:**
   ```sql
   SHOW GRANTS FOR 'your_user'@'localhost';
   ```

2. **Grant necessary permissions:**
   ```sql
   GRANT CREATE, ALTER, DROP, INSERT, UPDATE, DELETE, SELECT ON database_name.* TO 'your_user'@'localhost';
   FLUSH PRIVILEGES;
   ```

3. **Use database admin account:**
   ```bash
   mysql -u root -p database_name < server/sql/install_all_tables.sql
   ```

#### Issue: Foreign Key Constraint Errors

**Symptoms:**
- Error: "Cannot add foreign key constraint"
- Tables fail to create

**Solutions:**

1. **Install in correct order:**
   - Always install core tables first
   - Use `install_all_tables.sql` which handles order automatically

2. **Check parent tables exist:**
   ```sql
   -- Verify phone_players table exists before creating dependent tables
   SHOW TABLES LIKE 'phone_players';
   ```

3. **Temporarily disable foreign key checks:**
   ```sql
   SET FOREIGN_KEY_CHECKS=0;
   SOURCE server/sql/install_all_tables.sql;
   SET FOREIGN_KEY_CHECKS=1;
   ```

#### Issue: Syntax Errors

**Symptoms:**
- Error: "You have an error in your SQL syntax"
- Specific line number mentioned

**Solutions:**

1. **Check MySQL version:**
   ```sql
   SELECT VERSION();
   -- Requires MySQL 5.7+ or MariaDB 10.2+
   ```

2. **Verify character encoding:**
   ```sql
   -- Ensure database uses utf8mb4
   ALTER DATABASE database_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

3. **Check for file corruption:**
   - Re-download the resource
   - Verify file integrity
   - Check for encoding issues

#### Issue: Tables Already Exist

**Symptoms:**
- Warning: "Table already exists"
- Some tables not created

**Solutions:**

This is normal behavior! All SQL files use `CREATE TABLE IF NOT EXISTS`, which means:
- Existing tables are preserved
- Only missing tables are created
- No data is lost

To verify:
```sql
-- Check which tables exist
SHOW TABLES LIKE 'phone_%';

-- Count total phone tables (should be 50+)
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'your_database' 
AND table_name LIKE 'phone_%';
```

### SQL File Documentation

Each SQL file includes comprehensive documentation:

**File Header:**
- Purpose and description
- List of tables included
- Dependencies on other files
- Creation date

**Table Documentation:**
- Table purpose and usage
- Column descriptions
- Index explanations
- Foreign key relationships
- Cascade behaviors

**Example from phone_core_tables.sql:**

```sql
-- ============================================================================
-- Phone Core Tables
-- ============================================================================
-- Description: Core system tables for phone functionality
-- Dependencies: None (these are the base tables)
-- Tables: phone_players, phone_contacts, phone_messages, 
--         phone_call_history, phone_settings
-- ============================================================================

-- Table: phone_players
-- Description: Stores player phone numbers and identifiers
-- Primary table referenced by most other phone tables
CREATE TABLE IF NOT EXISTS phone_players (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique player record ID',
    identifier VARCHAR(50) NOT NULL UNIQUE COMMENT 'Player identifier (license, citizenid, etc)',
    phone_number VARCHAR(20) NOT NULL UNIQUE COMMENT 'Assigned phone number',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Account creation timestamp',
    
    INDEX idx_identifier (identifier),
    INDEX idx_phone_number (phone_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Core player phone data';
```

### Verifying SQL Installation

After running SQL files, verify the installation:

**1. Check Table Count:**
```sql
-- Should return 50+ tables
SELECT COUNT(*) as table_count 
FROM information_schema.tables 
WHERE table_schema = 'your_database' 
AND table_name LIKE 'phone_%';
```

**2. Verify Core Tables:**
```sql
-- Check essential tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'your_database' 
AND table_name IN (
    'phone_players',
    'phone_contacts', 
    'phone_messages',
    'phone_call_history',
    'phone_settings'
)
ORDER BY table_name;
```

**3. Check Foreign Keys:**
```sql
-- Verify foreign key relationships
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'your_database'
AND TABLE_NAME LIKE 'phone_%'
AND REFERENCED_TABLE_NAME IS NOT NULL;
```

**4. Verify Indexes:**
```sql
-- Check indexes are created
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'your_database'
AND TABLE_NAME LIKE 'phone_%'
ORDER BY TABLE_NAME, INDEX_NAME;
```

**5. Test Table Structure:**
```sql
-- Examine a specific table structure
DESCRIBE phone_players;
DESCRIBE phone_messages;
DESCRIBE phone_media;
```

**Expected Output:**
- All tables created successfully
- Foreign keys properly linked
- Indexes created on key columns
- Proper character encoding (utf8mb4)
- Appropriate column types and constraints


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
dir resources/lb-gphone

# Check manifest
cat resources/lb-gphone/fxmanifest.lua
```


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
   -- Run SQL files manually if auto-creation fails
   SOURCE server/sql/phone_core_tables.sql;
   ```

4. **Check permissions:**
   ```sql
   -- Verify user has CREATE TABLE permission
   SHOW GRANTS FOR 'your_user'@'localhost';
   ```

5. **Enable auto-creation:**
   ```lua
   Config.CreateTablesOnStart = true
   ```

**Verification:**
```sql
SHOW TABLES LIKE 'phone_%';
```

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

**Verification:**
- Phone UI should display when opened
- No errors in F12 console
- All apps should be clickable

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
   - Check restrictions in config:
   ```lua
   Config.Restrictions = {
       blockWhenDead = true,
       blockWhenCuffed = true,
       blockInTrunk = true
   }
   ```

4. **Check client scripts loaded:**
   ```
   # In server console
   restart lb-gphone
   ```

5. **Test with command:**
   ```lua
   -- Add temporary command for testing
   RegisterCommand('testphone', function()
       TriggerEvent('phone:open')
   end)
   ```

**Verification:**
- Phone should open with keybind
- Check F8 console for errors
- Test with different keys


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

**Verification:**
- Make test call between two players
- Both should hear each other
- Voice should work regardless of distance

#### Issue: Framework Integration Not Working

**Symptoms:**
- Player data not loading
- Banking features not working
- Job system not integrated

**Solutions:**
1. **Verify framework is running:**
   ```
   # Check framework resource is started
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
   If this works, issue is with framework integration.

**Verification:**
- Player phone number assigned on join
- Bank balance displays correctly
- Framework banking works with phone

#### Issue: Housing/Garage Integration Not Working

**Symptoms:**
- Properties not showing in Home app
- Vehicles not showing in Garage app
- Integration features not working

**Solutions:**
1. **Verify housing/garage script is running:**
   ```
   ensure qb-houses
   ensure qb-garages
   ```

2. **Check configuration:**
   ```lua
   Config.HomeApp.housingScript = 'qb-houses'
   Config.GarageApp.garageScript = 'qb-garages'
   ```

3. **Enable integrations:**
   ```lua
   Config.Integrations.housing.enabled = true
   Config.Integrations.garage.enabled = true
   ```

4. **Test script exports:**
   - Verify housing script has required exports
   - Check garage script compatibility
   - Review adapter logs

5. **Disable if not needed:**
   ```lua
   Config.HomeApp.housingScript = 'none'
   Config.GarageApp.garageScript = 'none'
   ```

**Verification:**
- Properties display in Home app
- Vehicles display in Garage app
- Integration features work as expected


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

**Verification:**
- Currency displays with correct symbol
- Formatting matches locale settings
- Large numbers format correctly

#### Issue: Language Not Changing

**Symptoms:**
- UI stays in English
- Language selector doesn't work
- Translations not loading

**Solutions:**
1. **Verify locale files exist:**
   ```bash
   ls nui/src/i18n/locales/
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

**Verification:**
- All supported languages appear in selector
- UI text changes when language is changed
- No missing translation keys

### Currency Validation and Transfer Issues

#### Issue: Transfer Rejected - Amount Too High

**Symptoms:**
- Error message: "Amount exceeds maximum transfer limit"
- Transfer fails even with sufficient balance
- Large amount transfers not working

**Solutions:**
1. **Check configured maximum:**
   ```lua
   -- In config.lua
   print(Config.WalletApp.maxTransferAmount)
   -- Should show: 999000000000000 (default)
   ```

2. **Verify you're within the limit:**
   ```lua
   -- Maximum allowed: 999,000,000,000,000 (999 trillion)
   -- If your amount exceeds this, reduce it
   ```

3. **Check for custom server limits:**
   - Your server admin may have set a lower limit
   - Contact server administration for limit information
   - Check server announcements or rules

4. **Test with smaller amount:**
   ```lua
   -- Try transferring $1,000,000 first
   -- If successful, gradually increase to find limit
   ```

5. **Verify server-side configuration:**
   ```lua
   -- Server admins: Check config.lua
   Config.WalletApp.maxTransferAmount = 999000000000000
   -- Restart resource after changes
   ```

**Verification:**
- Transfer at or below limit succeeds
- Error message shows correct maximum amount
- Formatted currency displays properly

#### Issue: Large Amount Not Displaying Correctly

**Symptoms:**
- Large numbers show as scientific notation (9.99e+14)
- Numbers truncated or rounded incorrectly
- Display shows "NaN" or "undefined"

**Solutions:**
1. **Rebuild NUI with latest code:**
   ```bash
   cd nui
   rm -rf node_modules dist
   npm install
   npm run build
   ```

2. **Clear browser cache:**
   - Press F12 in-game
   - Go to Application tab
   - Click "Clear storage"
   - Reload phone

3. **Check JavaScript console for errors:**
   - Press F12 in-game
   - Look for errors in Console tab
   - Report any errors to developers

4. **Verify database column types:**
   ```sql
   -- Check wallet/bank table structure
   DESCRIBE phone_players;
   -- Balance columns should be BIGINT or DECIMAL(20,2)
   ```

5. **Test with known good amount:**
   ```lua
   -- Try exact maximum: 999000000000000
   -- Should display as: $999T (abbreviated)
   -- Or: $999,000,000,000,000.00 (full format)
   ```

**Verification:**
- Large amounts display with proper formatting
- Abbreviation shows correctly (999T)
- No scientific notation in UI
- Transaction history shows formatted amounts

#### Issue: Currency Validation Errors

**Symptoms:**
- "Invalid amount" error for valid numbers
- Transfer form won't accept input
- Validation fails unexpectedly

**Solutions:**
1. **Check input format:**
   - Use numbers only (no currency symbols)
   - No commas or spaces in input
   - Decimal point only (no other punctuation)
   - Example: Enter `1000000` not `$1,000,000`

2. **Verify minimum amount:**
   ```lua
   Config.WalletApp.minTransferAmount = 1
   -- Transfers must be at least $1
   ```

3. **Check for decimal places:**
   - Most currencies allow 2 decimal places
   - Japanese Yen allows 0 decimal places
   - Verify your locale settings

4. **Test validation logic:**
   ```lua
   -- Server console
   -- Enable debug mode
   Config.Debug = true
   Config.VerboseLogging = true
   ```

5. **Review server console for errors:**
   ```
   -- Look for validation errors like:
   [Phone] Transfer validation failed: [reason]
   [Phone] Invalid amount format: [details]
   ```

**Verification:**
- Valid amounts are accepted
- Clear error messages for invalid input
- Validation works consistently
- Both client and server validation agree

#### Issue: Transfer Succeeds But Balance Not Updated

**Symptoms:**
- Transfer shows as successful
- Balance doesn't change
- Transaction appears in history but money not moved

**Solutions:**
1. **Check framework integration:**
   ```lua
   -- Verify framework is detected
   -- Server console should show:
   [Phone] Framework: [ESX/QBCore/Qbox] detected and loaded
   ```

2. **Test framework banking directly:**
   ```lua
   -- Test your framework's banking commands
   -- ESX: /givemoney, /setmoney
   -- QBCore: /givemoney, /setmoney
   -- Verify framework banking works independently
   ```

3. **Check database transactions:**
   ```sql
   -- Check if transaction was recorded
   SELECT * FROM phone_transactions 
   WHERE sender_phone = 'YOUR_NUMBER' 
   ORDER BY timestamp DESC LIMIT 5;
   ```

4. **Review server logs:**
   ```
   -- Look for errors like:
   [Phone] Framework banking failed
   [Phone] Database transaction rolled back
   [ERROR] Failed to update balance
   ```

5. **Verify account types:**
   ```lua
   Config.WalletApp.defaultAccount = 'bank'  -- or 'money', 'cash'
   -- Ensure matches your framework's account types
   ```

**Verification:**
- Balance updates immediately after transfer
- Both sender and recipient balances change
- Transaction recorded in database
- Framework banking integration working

#### Issue: Debugging Large Amount Transfers

**Symptoms:**
- Need to troubleshoot transfer issues
- Want to see detailed validation process
- Testing maximum limits

**Debugging Steps:**

1. **Enable Debug Mode:**
   ```lua
   -- config.lua
   Config.Debug = true
   Config.VerboseLogging = true
   Config.Security.logSecurityEvents = true
   ```

2. **Monitor Server Console:**
   ```
   -- Watch for detailed logs:
   [Phone] Transfer attempt: $999,000,000,000,000
   [Phone] Validation: Amount check passed
   [Phone] Validation: Balance check passed
   [Phone] Validation: Recipient check passed
   [Phone] Transfer: Processing...
   [Phone] Transfer: Success
   ```

3. **Check Client Console (F8):**
   ```javascript
   // Look for client-side validation
   [Phone] Transfer validation started
   [Phone] Amount: 999000000000000
   [Phone] Formatted: $999T
   [Phone] Validation passed, sending to server
   ```

4. **Test Edge Cases:**
   ```lua
   -- Test these specific amounts:
   1                    -- Minimum (should succeed)
   999000000000000      -- Maximum (should succeed)
   999000000000001      -- Above max (should fail)
   0                    -- Below min (should fail)
   -1000                -- Negative (should fail)
   ```

5. **Review Database Logs:**
   ```sql
   -- Check transaction history
   SELECT 
       sender_phone,
       receiver_phone,
       amount,
       status,
       error_message,
       timestamp
   FROM phone_transactions
   ORDER BY timestamp DESC
   LIMIT 10;
   ```

**Quick Reference Commands:**

```bash
# Server Console
restart lb-gphone              # Restart resource
resmon                         # Check resource usage

# In-Game (F8)
resmon                         # Client resource monitor

# Database
mysql -u user -p database      # Connect to database
SELECT * FROM phone_players;   # Check player data
```

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
   -- Delete old messages
   DELETE FROM phone_messages WHERE timestamp < DATE_SUB(NOW(), INTERVAL 30 DAY);
   
   -- Delete old media
   DELETE FROM phone_media WHERE created_at < DATE_SUB(NOW(), INTERVAL 60 DAY);
   ```

5. **Restart resource periodically:**
   - Schedule automatic restarts during low traffic


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
   CREATE INDEX idx_posts_timeline ON phone_chirper_posts(created_at DESC);
   ```

2. **Optimize database:**
   ```sql
   OPTIMIZE TABLE phone_messages;
   OPTIMIZE TABLE phone_media;
   OPTIMIZE TABLE phone_chirper_posts;
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
restart oxmysql               # Restart database (if needed)
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

-- Recent Messages
SELECT * FROM phone_messages ORDER BY timestamp DESC LIMIT 20;

-- Database Size
SELECT 
    table_name AS 'Table',
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.TABLES
WHERE table_schema = 'your_database'
AND table_name LIKE 'phone_%'
ORDER BY (data_length + index_length) DESC;

-- Clean Old Data (30+ days)
DELETE FROM phone_messages WHERE timestamp < DATE_SUB(NOW(), INTERVAL 30 DAY);
DELETE FROM phone_media WHERE created_at < DATE_SUB(NOW(), INTERVAL 60 DAY);

-- Optimize Tables
OPTIMIZE TABLE phone_messages, phone_media, phone_transactions;
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

# Check Node Version
node --version    # Should be 16+
npm --version     # Should be 7+
```

**In-Game Commands (F8 Console):**

```bash
# Client Monitoring
resmon                        # Client resource monitor

# Clear Cache (if NUI issues)
# Press F12 > Application > Clear Storage > Clear site data
```

**Configuration Verification:**

```lua
-- Quick config checks (add to config.lua temporarily)
print("Framework: " .. Config.Framework)
print("Max Transfer: " .. Config.WalletApp.maxTransferAmount)
print("Locale: " .. Config.Locale)
print("Currency Max: " .. Config.Currency.maxValue)
```

**Troubleshooting Workflow:**

```bash
# 1. Check resource is running
ensure lb-gphone

# 2. Check for errors in console
# Look for red [ERROR] messages

# 3. Check dependencies
ensure oxmysql
ensure pma-voice

# 4. Restart resource
restart lb-gphone

# 5. Check resource usage
resmon

# 6. Enable debug mode (in config.lua)
Config.Debug = true
Config.VerboseLogging = true

# 7. Restart and test
restart lb-gphone
```

**Common File Locations:**

```
resources/lb-gphone/
├── config.lua                    # Main configuration
├── fxmanifest.lua               # Resource manifest
├── server/
│   ├── main.lua                 # Server entry point
│   ├── locales/                 # Server translations
│   └── apps/wallet.lua          # Wallet/banking logic
├── client/
│   └── main.lua                 # Client entry point
└── nui/
    ├── dist/                    # Built UI files
    ├── src/
    │   ├── i18n/locales/       # UI translations
    │   └── apps/wallet/        # Wallet UI components
    └── package.json             # Node dependencies
```

### Getting Help

If you're still experiencing issues after trying these solutions:

1. **Check Documentation:**
   - [API Documentation](docs/API.md)
   - [System Documentation](docs/SYSTEM_DOCUMENTATION.md)
   - [User Manual](docs/USER_MANUAL.md)
   - [Deployment Guide](docs/DEPLOYMENT_GUIDE.md)

2. **Review Logs:**
   - Server console output
   - F8 client console
   - Database logs
   - Resource-specific logs

3. **Community Support:**
   - GitHub Issues: Report bugs and request features
   - Discord: Community support channel
   - Forums: FiveM community forums

4. **Debug Mode:**
   ```lua
   Config.Debug = true
   Config.VerboseLogging = true
   ```
   This provides detailed logging for troubleshooting.

5. **Minimal Test:**
   - Test with minimal resources
   - Disable other phone resources
   - Test in standalone mode
   - Isolate the issue

---

## Advanced Configuration

### Custom App Development

Want to add your own apps? See [Custom App Development Guide](docs/CUSTOM_APP.md).

### Custom Framework Adapter

Need to integrate with a custom framework? See [Custom Framework Guide](docs/CUSTOM_FRAMEWORK.md).

### Media Storage Configuration

**Local Storage (Default):**
```lua
Config.MediaStorage = 'local'
```
Files stored in resource folder. Suitable for development and testing.

**Fivemanage Storage (Recommended for Production):**
```lua
Config.MediaStorage = 'fivemanage'
Config.FivemanageConfig = {
    enabled = true,
    apiKey = 'your-fivemanage-api-key', -- Get from https://fivemanage.com
    endpoint = 'https://api.fivemanage.com/api/image',
    timeout = 30000,
    retryAttempts = 3,
    retryDelay = 1000,
    fallbackToLocal = true, -- Recommended: saves locally if upload fails
    logUploads = true
}
```

**Getting Started with Fivemanage:**
1. Create account at [fivemanage.com](https://fivemanage.com)
2. Generate API key from dashboard
3. Add key to config and set `Config.MediaStorage = 'fivemanage'`
4. Test with `/phone:test-fivemanage` command
5. See [Fivemanage Integration](README.md#fivemanage-integration) for complete guide

**Custom CDN Storage:**
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
- **Fivemanage** (Recommended) - FiveM-specific CDN with easy setup
- **AWS S3** - Enterprise cloud storage
- **Cloudflare R2** - S3-compatible storage
- **Local** - Development/testing only

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

**Authentication:**
```lua
Config.Security = {
    maxLoginAttempts = 5,
    loginCooldown = 300000  -- 5 minutes
}
```

### Performance Tuning

**For Small Servers (< 32 players):**
```lua
Config.Performance = {
    enableCaching = true,
    cacheExpirationTime = 600000,  -- 10 minutes
    maxCachedItems = 50,
    databaseConnectionPoolSize = 3
}
```

**For Medium Servers (32-64 players):**
```lua
Config.Performance = {
    enableCaching = true,
    cacheExpirationTime = 300000,  -- 5 minutes
    maxCachedItems = 100,
    databaseConnectionPoolSize = 5
}
```


**For Large Servers (64+ players):**
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

### Backup and Maintenance

**Database Backup:**
```bash
# Backup phone tables
mysqldump -u username -p database_name phone_% > phone_backup.sql

# Restore from backup
mysql -u username -p database_name < phone_backup.sql
```

**Automated Cleanup Script:**
```sql
-- Create event for automatic cleanup (runs daily)
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

**Resource Monitoring:**
```lua
-- Add to server/main.lua for monitoring
CreateThread(function()
    while true do
        Wait(300000)  -- Every 5 minutes
        local memUsage = GetResourceMemoryUsage(GetCurrentResourceName())
        if memUsage > 100.0 then
            print('^3[Phone] High memory usage: ' .. memUsage .. 'MB^7')
        end
    end
end)
```


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
   - Download latest release
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

## Additional Resources

### Documentation

| Document | Description |
|----------|-------------|
| [README.md](README.md) | Overview and quick start |
| [API Documentation](docs/API.md) | Complete API reference |
| [User Manual](docs/USER_MANUAL.md) | End-user guide |
| [System Documentation](docs/SYSTEM_DOCUMENTATION.md) | Technical details |
| [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) | Production deployment |
| [Custom App Guide](docs/CUSTOM_APP.md) | Build custom apps |
| [Custom Framework Guide](docs/CUSTOM_FRAMEWORK.md) | Framework integration |
| [Database Schema](docs/DATABASE.md) | Database reference |

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


### Support Channels

**GitHub Issues:**
- Bug reports: Use bug report template
- Feature requests: Use feature request template
- Questions: Use discussions

**Community:**
- Discord: Join our community server
- Forums: FiveM community forums
- Documentation: Complete guides and tutorials

**Professional Support:**
- Custom development available
- Integration assistance
- Performance optimization
- Training and consultation

### Useful Commands

**Server Console:**
```
ensure lb-gphone    # Start resource
restart lb-gphone   # Restart resource
stop lb-gphone      # Stop resource
resmon              # Monitor resource usage
```

**In-Game (F8 Console):**
```
resmon                         # Client resource monitor
```

**Database:**
```sql
-- Check phone tables
SHOW TABLES LIKE 'phone_%';

-- Check player phone numbers
SELECT * FROM phone_players;

-- Check recent messages
SELECT * FROM phone_messages ORDER BY timestamp DESC LIMIT 10;

-- Check database size
SELECT 
    table_name AS 'Table',
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.TABLES
WHERE table_schema = 'your_database'
AND table_name LIKE 'phone_%'
ORDER BY (data_length + index_length) DESC;
```


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
- [ ] Resource downloaded and extracted
- [ ] Folder named correctly
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
- [ ] Database tables created
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

## Frequently Asked Questions

### General Questions

**Q: Do I need a framework to use this resource?**
A: No, the resource works in standalone mode without any framework.

**Q: Can I use this with my existing phone resource?**
A: It's recommended to disable other phone resources to avoid conflicts.

**Q: How many players can use this resource?**
A: Tested and optimized for 200+ concurrent players.

**Q: Is this resource free?**
A: Check the license file for usage terms.

### Installation Questions

**Q: Do I need to manually create database tables?**
A: No, tables are created automatically on first start.

**Q: Can I skip the NUI build step?**
A: No, the NUI must be built for the phone to display.

**Q: What Node.js version do I need?**
A: Node.js 16 or higher is required.

**Q: Can I install this on a Windows server?**
A: Yes, it works on Windows, Linux, and other platforms.

### Configuration Questions

**Q: Can I change the phone keybind?**
A: Yes, edit `Config.OpenKey` in config.lua.

**Q: Can I disable specific apps?**
A: Yes, set the app to `false` in `Config.EnabledApps`.

**Q: Can I add more languages?**
A: Yes, create translation files and add to supported locales.

**Q: Can I change the currency symbol?**
A: Yes, configure in `Config.Currency.localeSettings`.

### Integration Questions

**Q: Does this work with ESX?**
A: Yes, full ESX Legacy support with auto-detection.

**Q: Does this work with QBCore?**
A: Yes, full QBCore support with auto-detection.

**Q: Can I integrate with my custom housing script?**
A: Yes, create a custom adapter (see documentation).

**Q: Does this work with qb-banking?**
A: Yes, configure in `Config.WalletApp.bankingScript`.


### Technical Questions

**Q: What database does this use?**
A: MySQL 5.7+ or MariaDB 10.2+ via oxmysql.

**Q: How much storage does media require?**
A: Configurable per player, default is 500MB quota.

**Q: Can I use a CDN for media storage?**
A: Yes, configure `Config.MediaStorage = 'cdn'`.

**Q: What's the maximum currency amount?**
A: 999,000,000,000,000 (999 trillion).

**Q: Does this support voice calls?**
A: Yes, via pma-voice integration.

### Troubleshooting Questions

**Q: Phone won't open, what should I check?**
A: Check keybind, player state, and console for errors.

**Q: NUI shows black screen, how to fix?**
A: Rebuild NUI, clear cache, check F12 console.

**Q: Database errors on start, what's wrong?**
A: Check oxmysql connection and database permissions.

**Q: Voice calls don't work, why?**
A: Verify pma-voice is running and configured correctly.

**Q: High memory usage, how to reduce?**
A: Enable caching, reduce media quota, clean old data.

---

## Conclusion

Congratulations! You've successfully installed the FiveM Smartphone NUI resource.

### Next Steps

1. **Customize Configuration**: Adjust settings to match your server
2. **Test All Features**: Verify everything works as expected
3. **Train Staff**: Ensure admins know how to support players
4. **Inform Players**: Announce the new phone system
5. **Monitor Performance**: Keep an eye on resource usage
6. **Regular Maintenance**: Schedule backups and cleanup

### Stay Updated

- Watch the GitHub repository for updates
- Join the community for support and tips
- Check documentation for new features
- Report bugs and suggest improvements


### Thank You

Thank you for choosing the FiveM Smartphone NUI resource. We hope it enhances your server and provides an excellent experience for your players.

For questions, support, or feedback:
- **GitHub**: [Issues & Discussions](https://github.com/FosterG4/lb-gphone)
- **Documentation**: [Complete Docs](docs/)
- **Community**: Discord & Forums

---

<div align="center">

**Made with ❤️ for the FiveM community**

[⬆ Back to Top](#-lb-gphone---installation-guide)

</div>
