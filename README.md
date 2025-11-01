# 📱 lb-gphone - FiveM Smartphone System

<div align="center">

[![GitHub Repository](https://img.shields.io/badge/GitHub-lb--gphone-181717?style=for-the-badge&logo=github)](https://github.com/FosterG4/lb-gphone.git)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-green.svg?style=for-the-badge&logo=fivem)](https://fivem.net/)

[![Vue.js](https://img.shields.io/badge/Vue.js-3.x-4FC08D.svg?style=for-the-badge&logo=vue.js&logoColor=white)](https://vuejs.org/)
[![Node.js](https://img.shields.io/badge/Node.js-16+-339933.svg?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![MySQL](https://img.shields.io/badge/MySQL-Compatible-4479A1.svg?style=for-the-badge&logo=mysql&logoColor=white)](https://mysql.com/)

---

### 🎯 A Modern, Feature-Rich Smartphone System for FiveM Servers

**Built with Vue.js 3** • **Framework-Agnostic Design** • **23+ Fully Functional Apps**

Supports ESX, QBCore, Qbox, and Standalone modes with advanced features including voice calls, social media, banking with 999 trillion currency support, cryptocurrency trading, and cloud media storage.

---

[📖 Documentation](docs/) • [🚀 Quick Start](#-installation) • [⚙️ Configuration](#configuration) • [🐛 Report Issues](https://github.com/FosterG4/lb-gphone/issues) • [💡 Feature Requests](https://github.com/FosterG4/lb-gphone/issues/new?template=feature_request.md)

</div>

---

## ✨ Features

### 📱 **Core System**
- 🎨 Modern smartphone interface built with **Vue.js 3**
- 📦 **23+ fully functional applications** ready to use
- 🔄 **Framework-agnostic design** - Works with ESX, QBCore, Qbox, or Standalone
- 🌍 **Multi-language support** - English, Japanese, Spanish, French, German, Portuguese + extensible
- ⚡ Responsive UI with smooth animations and transitions
- 🎯 Intuitive user experience with native mobile feel

### 📞 **Communication**
- 📞 **Voice calls** with seamless **pma-voice** integration
- 💬 **Text messaging system** with offline message queuing
- 👥 **Contact management** with search and organization
- 🔔 **Real-time notifications** and alerts
- 📱 Call history and voicemail support

### 💰 **Finance & Economy**
- 🏦 **Advanced Banking System**
  - Account balance management
  - Player-to-player transfers by phone number
  - Transaction history and receipts
  - **Supports up to 999 trillion** ($999,000,000,000,000) per transaction
- 💎 **Cryptocurrency Trading**
  - Multiple cryptocurrencies (Bitcoin, Ethereum, Dogecoin)
  - Dynamic pricing with real-time updates
  - Portfolio management and tracking
  - Buy/sell with instant transactions
- 💵 **Smart Currency System**
  - Handles amounts up to **999 trillion** with precision
  - Automatic formatting with abbreviations (K, M, B, T)
  - Multi-locale currency display (symbols, separators, formats)
  - Configurable limits for server customization

### 🎮 **Social Media & Entertainment**
- 📸 **Shotz** - Instagram-like photo sharing platform
- 🐦 **Chirper** - Twitter-like microblogging (280 characters)
- 👗 **Modish** - Fashion and style showcase
- 💕 **Flicker** - Dating and social connections
- 👍 Like, comment, and share functionality
- Real-time feed updates

### 📷 **Media & Storage**
- 📸 **Camera app** with photo capture
- 🎥 **Video recording** with playback
- 🎵 **Audio recorder** for voice memos
- 🖼️ **Photo gallery** with albums and organization
- ☁️ **Cloud storage integration** via Fivemanage CDN
- 📤 Automatic media upload and backup
- 🔒 Secure media URLs with CDN delivery

### 🛠️ **Utilities**
- 🗺️ **Maps** - GPS navigation and waypoints
- 🌤️ **Weather** - Real-time weather information
- 📝 **Notes** - Personal note-taking app
- ⏰ **Clock** - Time, alarms, and timers
- ⚙️ **Settings** - Customization and preferences
- 🔍 Search functionality across apps

### 🏠 **Property & Vehicles**
- 🚗 **Vehicle garage management**
- 🏡 **Home automation** controls
- 🔑 Property access and security
- 📊 Asset tracking and management

### 🔧 **Technical Features**
- 🗄️ **MySQL database persistence** via **oxmysql**
- 🔌 **Extensible app module system** for custom development
- 🚀 **Real-time data synchronization** across clients
- 📡 **Comprehensive API** for third-party integrations
- 🔒 **Security features** - Input validation, rate limiting, SQL injection protection
- ⚡ **Performance optimized** - Caching, async operations, efficient queries
- 🧩 **Modular architecture** - Easy to extend and customize

## 📑 Table of Contents

- [✨ Features](#-features)
- [📋 Dependencies](#-dependencies)
- [🚀 Installation](#-installation)
- [⚙️ Configuration](#configuration)
- [☁️ Fivemanage Integration](#fivemanage-integration)
- [🗄️ Database Setup](#database-setup)
- [🔧 Framework Integration](#framework-integration)
- [📱 Usage](#usage)
- [💻 Development](#development)
- [🎨 Custom App Development](#custom-app-development)
- [📡 API Documentation](#api-documentation)
- [📚 Documentation](#-documentation)
- [🐛 Troubleshooting](#troubleshooting)
- [🤝 Support & Contributing](#-support--contributing)
- [🙏 Credits & Acknowledgments](#-credits--acknowledgments)
- [📄 License](#-license)

## 📋 Dependencies

### ✅ **Required Dependencies**

| Resource | Version | Purpose | Link |
|----------|---------|---------|------|
| **oxmysql** | Latest | Database operations | [GitHub](https://github.com/overextended/oxmysql) |
| **pma-voice** | Latest | Voice chat integration | [GitHub](https://github.com/AvarianKnight/pma-voice) |
| **Node.js** | 16+ | NUI build process | [Download](https://nodejs.org/) |

### 🔧 **Framework Support** (Choose One)

| Framework | Status | Notes |
|-----------|--------|-------|
| **Standalone** | ✅ Full Support | No framework required |
| **ESX Legacy** | ✅ Full Support | Auto-detection |
| **QBCore** | ✅ Full Support | Auto-detection |
| **Qbox** | ✅ Full Support | Auto-detection |

### 📦 **Optional Services**

| Service | Purpose | Link |
|---------|---------|------|
| **Fivemanage** | Cloud media storage (photos, videos, audio) | [fivemanage.com](https://fivemanage.com) |

> **💡 Tip**: Fivemanage provides reliable cloud storage for media files. See [Fivemanage Integration](#fivemanage-integration) for setup instructions.

---

## 🚀 Installation

> **⚠️ Important**: Follow these steps in order for proper installation. For detailed instructions, see the [Complete Installation Guide](INSTALL.md).

### **Quick Start** ⚡

Get up and running in 5 minutes:

```bash
# 1. Clone the repository to your resources folder
cd resources
git clone https://github.com/FosterG4/lb-gphone.git
cd lb-gphone

# 2. Build the NUI interface
cd nui
npm install
npm run build
cd ..

# 3. Add to server.cfg (see configuration below)
# 4. Start your server
```

---

### **Step 1: Download & Extract** 📥

Choose your preferred installation method:

**Option A: Clone from GitHub (Recommended)**
```bash
# Navigate to your resources folder
cd path/to/your/server/resources

# Clone the repository
git clone https://github.com/FosterG4/lb-gphone.git

# Navigate into the resource
cd lb-gphone
```

**Option B: Download Release**
1. Visit [GitHub Releases](https://github.com/FosterG4/lb-gphone/releases)
2. Download the latest release ZIP file
3. Extract to your `resources` folder
4. Rename folder to `lb-gphone` (if needed)

**✅ Verification:**
```bash
# Verify folder structure
ls -la
# You should see: client/, server/, nui/, config.lua, fxmanifest.lua
```

---

### **Step 2: Install Dependencies** 📦

Add these to your `server.cfg` **before** the phone resource:

```bash
# ===================================
# Required Dependencies (MUST START FIRST)
# ===================================
ensure oxmysql      # Database operations
ensure pma-voice    # Voice call integration

# ===================================
# Framework (Choose ONE or use standalone)
# ===================================
ensure es_extended  # For ESX Legacy
# ensure qb-core    # For QBCore
# ensure qbox       # For Qbox
# (No framework needed for standalone mode)
```

**✅ Verification:**
- Start your server and check console for dependency load messages
- Ensure no errors appear for oxmysql or pma-voice
- Confirm your framework (if using one) loads successfully

---

### **Step 3: Build NUI Interface** 🎨

The NUI (user interface) must be built before first use:

```bash
# Navigate to NUI directory
cd resources/lb-gphone/nui

# Install Node.js dependencies (first time only)
npm install

# Build for production
npm run build
```

**Expected Output:**
```
✓ built in 15.2s
✓ 125 modules transformed
✓ dist/ folder created with index.html and assets/
```

**✅ Verification:**
```bash
# Check that dist folder was created
ls -la dist/
# You should see: index.html, assets/ folder with JS and CSS files
```

> **💡 Development Tip**: Use `npm run dev` for hot-reload during development

---

### **Step 4: Configure Resource** ⚙️

Edit `config.lua` to match your server setup:

```lua
-- ===================================
-- Framework Configuration
-- ===================================
Config.Framework = 'standalone'  -- Options: 'standalone', 'esx', 'qbcore', 'qbox'

-- ===================================
-- Phone Settings
-- ===================================
Config.OpenKey = 'M'                    -- Key to open/close phone
Config.PhoneNumberFormat = '###-####'   -- Phone number format (7 digits)
Config.GenerateRandomNumbers = true     -- Random vs sequential numbers

-- ===================================
-- Wallet & Currency Settings
-- ===================================
Config.WalletApp = {
    enabled = true,
    maxTransferAmount = 999000000000000,  -- 999 trillion maximum
    minTransferAmount = 1
}
```

**✅ Verification:**
- Save the file and check for syntax errors
- Ensure `Config.Framework` matches your server setup
- Verify `maxTransferAmount` is set to 999000000000000 for full currency support

---

### **Step 5: Add to Server Config** 📝

Add the resource to your `server.cfg`:

```bash
# ===================================
# lb-gphone Smartphone System
# ===================================
ensure lb-gphone
```

**Important:** Place this line **after** your dependencies and framework!

**Complete Example:**
```bash
# Dependencies
ensure oxmysql
ensure pma-voice

# Framework (if using)
ensure es_extended

# Phone Resource
ensure lb-gphone
```

---

### **Step 6: Start Server** 🚀

Start or restart your FiveM server. The resource will automatically:

✅ Create required database tables  
✅ Initialize the framework adapter  
✅ Load all phone applications  
✅ Assign phone numbers to players on first join  

**✅ Verification:**

Check your server console for these messages:
```
[lb-gphone] Resource started successfully
[lb-gphone] Database tables initialized
[lb-gphone] Framework adapter loaded: standalone
[lb-gphone] 23 applications loaded
[lb-gphone] Phone system ready
```

**In-Game Testing:**
1. Join your server
2. Press `M` (or your configured key) to open the phone
3. You should see the phone interface with all apps
4. Check that you have a phone number assigned (visible in Settings app)

---

### **🎉 Installation Complete!**

Your phone system is now ready to use. For detailed configuration options, see the [Configuration](#configuration) section below.

**Next Steps:**
- 📖 Read the [User Manual](docs/USER_MANUAL.md) to learn all features
- ⚙️ Customize settings in `config.lua` for your server
- 🔧 Set up [Fivemanage Integration](#fivemanage-integration) for cloud media storage
- 📱 Explore the [Custom App Development Guide](docs/CUSTOM_APP.md) to add your own apps

**Need Help?** See [Troubleshooting](#troubleshooting) or [open an issue](https://github.com/FosterG4/lb-gphone/issues).

## ⚙️ Configuration

The `config.lua` file contains all customizable settings for the phone system. Here are the essential settings to get started:

### Quick Configuration

```lua
-- Framework type: 'standalone', 'esx', 'qbcore', 'qbox'
Config.Framework = 'standalone'

-- Key to open/close the phone
Config.OpenKey = 'M'

-- Phone number format (# represents a digit)
Config.PhoneNumberFormat = '###-####'

-- Wallet & Currency Settings
Config.WalletApp = {
    enabled = true,
    maxTransferAmount = 999000000000000,  -- 999 trillion maximum
    minTransferAmount = 1
}

-- Media Storage (optional cloud storage)
Config.MediaStorage = 'local'  -- Options: 'local', 'fivemanage'
```

> **📖 For complete configuration options**, including app settings, notifications, cryptocurrency, performance tuning, and more, see the [Configuration Reference in DOCUMENTATION.md](docs/DOCUMENTATION.md#configuration-reference)

## ☁️ Fivemanage Integration

Fivemanage is a CDN and media hosting service for FiveM servers that provides cloud storage for photos, videos, and audio files.

### Quick Setup

1. **Get API Key**: Visit [fivemanage.com](https://fivemanage.com) and create an account
2. **Configure**: Add your API key to `config.lua`:
   ```lua
   Config.MediaStorage = 'fivemanage'
   Config.FivemanageConfig = {
       enabled = true,
       apiKey = 'your_api_key_here',
       fallbackToLocal = true
   }
   ```
3. **Test**: Run `/phone:test-fivemanage` in-game to verify setup

> **📖 For complete Fivemanage setup**, including migration tools, troubleshooting, admin commands, and best practices, see the [Fivemanage Integration Guide in DOCUMENTATION.md](docs/DOCUMENTATION.md#fivemanage-integration)

## 🗄️ Database Setup

The resource automatically creates all required tables on first start. No manual setup needed.

**Tables created automatically:**
- `phone_players`, `phone_contacts`, `phone_messages`, `phone_call_history`, `phone_tweets`, `phone_crypto`

> **📖 For manual database setup or schema details**, see the [Database Documentation in DOCUMENTATION.md](docs/DOCUMENTATION.md#database-setup)

## 🔧 Framework Integration

The resource supports multiple frameworks with automatic detection:

| Framework | Setup |
|-----------|-------|
| **Standalone** | Set `Config.Framework = 'standalone'` (default) |
| **ESX Legacy** | Set `Config.Framework = 'esx'` |
| **QBCore** | Set `Config.Framework = 'qbcore'` |
| **Qbox** | Set `Config.Framework = 'qbox'` |

> **📖 For custom framework adapters**, see the [Framework Integration Guide in DOCUMENTATION.md](docs/DOCUMENTATION.md#framework-integration)

## 📱 Usage

### Basic Controls

- Press `M` (or your configured key) to open/close the phone
- Navigate apps by tapping icons
- Swipe or scroll through content

### Key Features

- **Contacts**: Add, edit, and manage contacts with search functionality
- **Messages**: Send text messages with offline queuing and notifications
- **Calls**: Make voice calls using pma-voice integration
- **Bank**: Transfer money, view balance and transaction history
- **Social Media**: Post to Twitter-like feeds, share photos, connect with others
- **Crypto**: Trade cryptocurrencies with real-time price updates

> **📖 For complete user guides and app tutorials**, see the [User Manual in DOCUMENTATION.md](docs/DOCUMENTATION.md#user-manual)

## 💻 Development

### Building NUI

```bash
cd nui
npm install          # First time only
npm run build        # Production build
npm run dev          # Development with hot reload
```

> **📖 For custom app development and API documentation**, see:
> - [Custom App Development Guide in DOCUMENTATION.md](docs/DOCUMENTATION.md#custom-app-development)
> - [API Documentation in DOCUMENTATION.md](docs/DOCUMENTATION.md#api-documentation)

## 🧪 Testing

All test files are organized in the `tests/` directory for easy access and execution.

### Test Structure

```
tests/
├── server/                      # Server-side tests
│   ├── testing.lua             # Server functionality tests
│   └── integration_tests.lua   # Integration tests
├── nui/                        # NUI tests
│   └── test-currency-formatting.html
└── test_max_transfer.lua       # Max transfer amount tests
```

### Running Tests

**Server Tests:**
```bash
# In-game console or server console
/phone:run-tests              # Run all server tests
/phone:test-integration       # Run integration tests only
```

**NUI Tests:**
- Open `tests/nui/test-currency-formatting.html` in a browser
- Check browser console for test results

**Manual Testing:**
```bash
# Test specific features
/phone:test-fivemanage        # Test Fivemanage integration
/phone:test-currency          # Test currency formatting
/phone:test-max-transfer      # Test max transfer limits
```

### Test Coverage

The test suite covers:
- ✅ Currency formatting and validation (up to 999 trillion)
- ✅ Database operations and queries
- ✅ Framework adapter integration
- ✅ Phone number generation and validation
- ✅ Media upload and storage
- ✅ API endpoints and callbacks

> **📖 For complete testing documentation**, including writing custom tests and CI/CD integration, see the [Testing Guide in DOCUMENTATION.md](docs/DOCUMENTATION.md#testing-guide)

### Project Structure

```
lb-gphone/
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
│   ├── apps/           # App modules
│   │   ├── bank.lua
│   │   ├── twitter.lua
│   │   └── crypto.lua
│   └── locales/        # Language files
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
├── tests/              # Test files (organized by type)
│   ├── server/         # Server-side tests
│   │   ├── testing.lua
│   │   └── integration_tests.lua
│   ├── nui/            # NUI tests
│   │   └── test-currency-formatting.html
│   └── test_max_transfer.lua
├── docs/               # Consolidated documentation
│   └── DOCUMENTATION.md # Complete documentation (all guides, API, testing)
├── .kiro/              # Kiro AI configuration
├── config.lua          # Configuration file
├── fxmanifest.lua      # Resource manifest
├── INSTALL.md          # Installation guide
├── LICENSE.MD          # License information
└── README.md           # This file
```

## 📚 Documentation

> **📖 Complete documentation is now consolidated in [`docs/DOCUMENTATION.md`](docs/DOCUMENTATION.md)**

<div align="center">

### 🎯 **Quick Links**

| Section | What You'll Find |
|:--------|:-----------------|
| [📖 **Complete Documentation**](docs/DOCUMENTATION.md) | **All-in-one guide** with setup, configuration, API, user manual, and more |
| [⚡ **Quick Start**](#-installation) | Get up and running in 5 minutes |
| [📋 **Installation Guide**](INSTALL.md) | Detailed step-by-step setup instructions |
| [🐛 **Troubleshooting**](#troubleshooting) | Common issues and solutions |

---

### 📑 **What's in DOCUMENTATION.md**

The consolidated documentation includes:

- ✅ **Quick Start & Installation** - Get started quickly
- ⚙️ **Configuration Reference** - All config options explained
- 🗄️ **Database Setup** - Schema and manual setup
- 🔧 **Framework Integration** - ESX, QBCore, Qbox, Standalone
- 📱 **User Manual** - Complete guide to all 23+ apps
- 🎨 **Custom App Development** - Build your own phone apps
- 🔌 **API Documentation** - Events, callbacks, and exports
- ☁️ **Fivemanage Integration** - Cloud media storage setup
- 🧪 **Testing Guide** - How to run and write tests
- 🐛 **Troubleshooting** - Solutions to common problems
- 📝 **Changelog** - Version history and updates

---

### 🌐 **Community & Support**

| Resource | Link |
|:---------|:-----|
| 🐛 **Bug Reports** | [Open Issue](https://github.com/FosterG4/lb-gphone/issues/new?template=bug_report.md) |
| 💡 **Feature Requests** | [Request Feature](https://github.com/FosterG4/lb-gphone/issues/new?template=feature_request.md) |
| 💬 **Discussions** | [GitHub Discussions](https://github.com/FosterG4/lb-gphone/discussions) |
| 📦 **Releases** | [View Releases](https://github.com/FosterG4/lb-gphone/releases) |

</div>

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

### Media uploads failing

- Check `Config.MediaStorage` setting ('local' or 'fivemanage')
- If using Fivemanage, verify API key is correct
- Test with `/phone:test-fivemanage` command
- Check file size limits in config
- Verify `Config.FivemanageConfig.fallbackToLocal = true` for automatic fallback
- Check server console for specific error messages

### Photos/videos not displaying

- Verify media URLs in database are accessible
- If using Fivemanage, check URLs open in browser
- Clear FiveM cache and reconnect
- Check browser console (F12) for loading errors
- Verify NUI files are properly built

---

## 🤝 Support & Contributing

<div align="center">

### 💬 **Need Help?**

| 🐛 **Found a Bug?** | 💡 **Have an Idea?** | 📖 **Need Documentation?** |
|---------------------|----------------------|----------------------------|
| [Report Issue](https://github.com/FosterG4/lb-gphone/issues/new?template=bug_report.md) | [Feature Request](https://github.com/FosterG4/lb-gphone/issues/new?template=feature_request.md) | [View Docs](docs/) |

### 🛠️ **Contributing**

We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting PRs.

</div>

---

## 🙏 Credits & Acknowledgments

<div align="center">

**Built with amazing open-source technologies:**

[![Vue.js](https://img.shields.io/badge/Vue.js-4FC08D?style=for-the-badge&logo=vue.js&logoColor=white)](https://vuejs.org/)
[![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://mysql.com/)

**Special thanks to:**
- [pma-voice](https://github.com/AvarianKnight/pma-voice) for voice integration
- [oxmysql](https://github.com/overextended/oxmysql) for database operations
- The FiveM community for continuous support and feedback

</div>

---

## Support
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/U7U71NMCFN)

## 📄 License

<div align="center">

**MIT License** - see [LICENSE](LICENSE) file for details

*This project is open source and available under the MIT License.*

**Made with ❤️ for the FiveM community**

</div>
