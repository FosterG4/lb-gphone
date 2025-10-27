# FiveM Smartphone NUI

A modern, feature-rich smartphone system with NUI interface for FiveM servers. Built with Vue.js and designed to be framework-agnostic with support for ESX, QBCore, Qbox, and standalone modes.

## Features

- 📱 Modern smartphone interface built with Vue.js
- 📞 Voice calls with pma-voice integration
- 💬 Text messaging system with offline message queuing
- 👥 Contact management with search functionality
- 🏦 Banking app with transfers and transaction history
- 🐦 Twitter/social media app with real-time feed updates
- 💰 Cryptocurrency trading app with dynamic pricing
- 🔧 Framework support (ESX, QBCore, Qbox, Standalone)
- 💾 MySQL database persistence via oxmysql
- 🔌 Extensible app module system
- 🎨 Responsive UI design

## Table of Contents

- [Dependencies](#dependencies)
- [Installation](#installation)
- [Configuration](#configuration)
- [Database Setup](#database-setup)
- [Framework Integration](#framework-integration)
- [Usage](#usage)
- [Development](#development)
- [Custom App Development](#custom-app-development)
- [API Documentation](#api-documentation)
- [Troubleshooting](#troubleshooting)

## Dependencies

### Required

- **[oxmysql](https://github.com/overextended/oxmysql)** - Database operations
  - Version: Latest recommended
  - Used for all database queries and persistence

- **[pma-voice](https://github.com/AvarianKnight/pma-voice)** - Voice chat integration
  - Version: Latest recommended
  - Required for phone call voice functionality

### Optional (Framework-Dependent)

- **ESX Legacy** - If using ESX framework mode
- **QBCore** - If using QBCore framework mode
- **Qbox** - If using Qbox framework mode

## Installation

### Step 1: Download and Extract

1. Download the latest release or clone the repository
2. Extract to your FiveM server's `resources` folder
3. Rename the folder to `fivem-smartphone-nui` (if needed)

### Step 2: Install Dependencies

Ensure the following resources are installed and working:

```bash
# In your server.cfg, ensure these are started BEFORE the phone resource
ensure oxmysql
ensure pma-voice
```

### Step 3: Build NUI Interface

The NUI interface must be built before first use:

```bash
# Navigate to the NUI directory
cd resources/fivem-smartphone-nui/nui

# Install Node.js dependencies
npm install

# Build for production
npm run build
```

**Note:** Node.js v16 or higher is required for building the NUI.

### Step 4: Configure the Resource

1. Open `config.lua` in a text editor
2. Set your framework type:
   ```lua
   Config.Framework = 'standalone' -- Options: 'standalone', 'esx', 'qbcore', 'qbox'
   ```
3. Customize other settings as needed (see [Configuration](#configuration) section)

### Step 5: Add to Server Config

Add the resource to your `server.cfg`:

```bash
# Add after dependencies
ensure fivem-smartphone-nui
```

### Step 6: Start Server

Start or restart your FiveM server. The resource will automatically:
- Create required database tables
- Initialize the framework adapter
- Assign phone numbers to players on first join

## Configuration

The `config.lua` file contains all customizable settings. Below is a detailed explanation of each section:

### Framework Settings

```lua
-- Framework type: 'standalone', 'esx', 'qbcore', 'qbox'
Config.Framework = 'standalone'
```

- **standalone**: Uses FiveM license identifiers, no framework required
- **esx**: Integrates with ESX Legacy framework
- **qbcore**: Integrates with QBCore framework
- **qbox**: Integrates with Qbox framework

### Keybind Settings

```lua
-- Key to open/close the phone (default: M)
Config.OpenKey = 'M'
```

Available key options: Any valid FiveM key mapping (e.g., 'M', 'F1', 'K', etc.)

### Phone Number Settings

```lua
-- Phone number format (# represents a digit)
Config.PhoneNumberFormat = '###-####'

-- Total digits in phone number
Config.PhoneNumberLength = 7

-- Generate random numbers or use sequential
Config.GenerateRandomNumbers = true
```

**Examples:**
- `'###-####'` = 555-1234 (7 digits)
- `'(###) ###-####'` = (555) 123-4567 (10 digits)
- `'### ### ###'` = 555 123 456 (9 digits)

### Feature Toggles

```lua
-- Enable or disable specific apps
Config.EnabledApps = {
    contacts = true,
    messages = true,
    dialer = true,
    bank = true,
    twitter = true,
    crypto = true
}
```

Set any app to `false` to disable it completely.

### Notification Settings

```lua
-- How long notifications stay on screen (milliseconds)
Config.NotificationDuration = 5000

-- Position: 'top-right', 'top-left', 'bottom-right', 'bottom-left'
Config.NotificationPosition = 'top-right'
```

### Message Settings

```lua
-- Maximum characters per message
Config.MaxMessageLength = 500

-- Cooldown between messages (milliseconds)
Config.MessageCooldown = 1000
```

### Call Settings

```lua
-- Time before unanswered call times out (milliseconds)
Config.CallTimeout = 30000

-- Maximum call duration (milliseconds)
Config.MaxCallDuration = 3600000 -- 1 hour
```

### Voice Settings

```lua
-- pma-voice resource name (if different)
Config.VoiceResource = 'pma-voice'

-- Prefix for call voice channels
Config.CallChannelPrefix = 'phone_call_'
```

### Database Settings

```lua
-- oxmysql resource name (if different)
Config.DatabaseResource = 'oxmysql'
```

### Cryptocurrency Settings

```lua
-- How often crypto prices update (milliseconds)
Config.CryptoUpdateInterval = 60000 -- 1 minute

-- Available cryptocurrencies
Config.AvailableCryptos = {
    { name = 'Bitcoin', symbol = 'BTC', basePrice = 50000 },
    { name = 'Ethereum', symbol = 'ETH', basePrice = 3000 },
    { name = 'Dogecoin', symbol = 'DOGE', basePrice = 0.25 }
}
```

Add or remove cryptocurrencies as desired. Prices fluctuate randomly around the base price.

### Twitter Settings

```lua
-- Maximum characters per tweet
Config.MaxTweetLength = 280

-- Cooldown between tweets (milliseconds)
Config.TweetCooldown = 5000

-- Maximum tweets to load in feed
Config.MaxFeedItems = 50
```

### Performance Settings

```lua
-- How long to cache database results (milliseconds)
Config.DatabaseCacheTime = 300000 -- 5 minutes

-- Rate limit: max events per player per second
Config.MaxEventsPerSecond = 10
```

## Database Setup

The resource automatically creates all required tables on first start. No manual database setup is required.

### Automatic Table Creation

When the resource starts, it will create the following tables if they don't exist:

- `phone_players` - Player phone numbers and identifiers
- `phone_contacts` - Contact lists
- `phone_messages` - Text messages
- `phone_call_history` - Call logs
- `phone_tweets` - Social media posts
- `phone_crypto` - Cryptocurrency holdings

### Manual Database Setup (Optional)

If you prefer to create tables manually or need to reset the database, see the [SQL Schema Documentation](docs/DATABASE.md) for complete table definitions.

## Framework Integration

The resource uses an adapter pattern to support multiple frameworks. The appropriate adapter is automatically loaded based on your `Config.Framework` setting.

### Standalone Mode

No additional setup required. Uses FiveM license identifiers.

### ESX Integration

1. Set `Config.Framework = 'esx'`
2. Ensure ESX is started before this resource
3. The resource will automatically integrate with ESX player data and banking

### QBCore Integration

1. Set `Config.Framework = 'qbcore'`
2. Ensure QBCore is started before this resource
3. The resource will automatically integrate with QBCore player data and banking

### Qbox Integration

1. Set `Config.Framework = 'qbox'`
2. Ensure Qbox is started before this resource
3. The resource will automatically integrate with Qbox player data and banking

For custom framework integration, see [Custom Framework Adapter Guide](docs/CUSTOM_FRAMEWORK.md).

## Usage

### Opening the Phone

- Press the configured keybind (default: `M`) to open/close the phone
- The phone cannot be opened while dead, handcuffed, or in a vehicle trunk

### Managing Contacts

1. Open the phone and tap the Contacts app
2. Tap the "+" button to add a new contact
3. Enter the contact name and phone number
4. Use the search bar to find contacts quickly
5. Tap a contact to view options (call, message, edit, delete)

### Sending Messages

1. Open the Messages app
2. Tap "New Message" or select an existing conversation
3. Type your message (max 500 characters)
4. Press Send
5. You'll receive notifications for new messages even when the phone is closed

### Making Calls

1. Open the Dialer app
2. Enter the phone number using the number pad
3. Tap the call button
4. The recipient will receive a call notification
5. Once answered, you can talk using pma-voice
6. Tap "End Call" to hang up

### Using Apps

**Bank App:**
- View your account balance
- Transfer money to other players by phone number
- View transaction history

**Twitter App:**
- View the public feed
- Create posts (max 280 characters)
- Like and reply to posts
- View your own tweets

**Crypto App:**
- View available cryptocurrencies and current prices
- Buy crypto with your bank balance
- Sell crypto holdings
- View your portfolio value

## Development

### Building NUI

**Development mode with hot reload:**
```bash
cd nui
npm run dev
```

**Production build:**
```bash
cd nui
npm run build
```

### Project Structure

```
fivem-smartphone-nui/
├── client/              # Client-side Lua scripts
│   ├── main.lua        # Phone open/close logic
│   ├── nui.lua         # NUI callbacks
│   ├── calls.lua       # Call management
│   ├── voice.lua       # pma-voice integration
│   ├── notifications.lua # Notification handling
│   └── utils.lua       # Utility functions
├── server/             # Server-side Lua scripts
│   ├── main.lua        # Server initialization
│   ├── database.lua    # Database operations
│   ├── contacts.lua    # Contact management
│   ├── messages.lua    # Message handling
│   ├── calls.lua       # Call coordination
│   ├── phone_numbers.lua # Phone number management
│   ├── utils.lua       # Utility functions
│   ├── framework/      # Framework adapters
│   │   ├── adapter.lua
│   │   ├── esx.lua
│   │   ├── qbcore.lua
│   │   ├── qbox.lua
│   │   └── standalone.lua
│   └── apps/           # App modules
│       ├── bank.lua
│       ├── twitter.lua
│       └── crypto.lua
├── nui/                # Vue.js NUI interface
│   ├── src/
│   │   ├── App.vue
│   │   ├── main.js
│   │   ├── store/      # Vuex store
│   │   ├── components/ # Vue components
│   │   ├── views/      # App views
│   │   ├── apps/       # App modules
│   │   └── utils/      # Utilities
│   ├── public/
│   ├── dist/           # Built files
│   └── package.json
├── docs/               # Documentation
│   ├── DATABASE.md     # Database schema
│   ├── CUSTOM_FRAMEWORK.md # Framework adapter guide
│   ├── CUSTOM_APP.md   # Custom app development
│   └── API.md          # API documentation
├── config.lua          # Configuration file
├── fxmanifest.lua      # Resource manifest
└── README.md
```

## Custom App Development

Want to add your own app to the phone? See the [Custom App Development Guide](docs/CUSTOM_APP.md) for a complete tutorial with example code.

## API Documentation

For developers integrating with or extending this resource, see the [API Documentation](docs/API.md) for:
- NUI Callback API
- Server Event API
- Client Event API
- Framework Adapter API
- Export Functions

## Troubleshooting

### Phone won't open

- Check that you're not dead, handcuffed, or in a trunk
- Verify the keybind in `config.lua` isn't conflicting with other resources
- Check F8 console for errors

### Database errors

- Ensure oxmysql is installed and running
- Check your database connection settings
- Verify database user has CREATE TABLE permissions
- Check server console for specific error messages

### Voice calls not working

- Ensure pma-voice is installed and running
- Verify `Config.VoiceResource` matches your pma-voice resource name
- Check that both players have working microphones
- Test pma-voice proximity chat to ensure it's functioning

### Framework integration issues

- Verify `Config.Framework` matches your server's framework
- Ensure the framework resource is started before the phone resource
- Check that framework exports are available
- Try standalone mode to isolate the issue

### NUI not displaying

- Ensure you've run `npm run build` in the nui directory
- Check that `nui/dist/` folder contains built files
- Verify `fxmanifest.lua` references the correct NUI files
- Clear your FiveM cache and restart

### Players not getting phone numbers

- Check server console for database errors
- Verify the `phone_players` table exists
- Check that `Config.PhoneNumberLength` matches `Config.PhoneNumberFormat`
- Try manually assigning a number via database

## Support

For issues, questions, or contributions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review the documentation in the `docs/` folder

## Credits

- Built with [Vue.js](https://vuejs.org/)
- Voice integration via [pma-voice](https://github.com/AvarianKnight/pma-voice)
- Database operations via [oxmysql](https://github.com/overextended/oxmysql)

## License

This project is open source and available under the MIT License.
