# 📱 lb-gphone - FiveM Smartphone System

<div align="center">

[![GitHub Repository](https://img.shields.io/badge/GitHub-lb--gphone-181717?style=for-the-badge&logo=github)](https://github.com/FosterG4/lb-gphone.git)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE.MD)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-green.svg?style=for-the-badge&logo=fivem)](https://fivem.net/)

A modern, feature-rich smartphone system for FiveM servers with 23+ fully functional apps, framework-agnostic design, and advanced features including voice calls, social media, banking, and cryptocurrency trading.

[🚀 Quick Start](#-quick-start) • [📖 Documentation](#-documentation) • [🐛 Report Issues](https://github.com/FosterG4/lb-gphone/issues) • [💬 Discussions](https://github.com/FosterG4/lb-gphone/discussions)

</div>

---

## ✨ Features

### Core System
- Modern smartphone interface built with Vue.js 3
- 23+ fully functional applications
- Framework-agnostic design (ESX, QBCore, Qbox, Standalone)
- Multi-language support with extensible locale system
- Responsive UI with smooth animations

### Communication
- Voice calls with pma-voice integration
- Text messaging with offline queuing
- Contact management with search
- Real-time notifications
- Call history and voicemail

### Finance & Economy
- Advanced banking with player-to-player transfers
- Supports up to 999 trillion per transaction
- Cryptocurrency trading (Bitcoin, Ethereum, Dogecoin)
- Dynamic pricing with real-time updates
- Multi-locale currency display

### Social Media & Entertainment
- Shotz (photo sharing)
- Chirper (microblogging)
- Modish (fashion showcase)
- Flicker (dating and connections)
- Like, comment, and share functionality

### Media & Storage
- Camera with photo capture
- Video recording and playback
- Audio recorder for voice memos
- Photo gallery with albums
- Cloud storage integration via Fivemanage CDN

### Utilities & Property
- GPS navigation and waypoints
- Weather information
- Notes and reminders
- Vehicle garage management
- Home automation controls

### Technical
- MySQL database persistence via oxmysql
- Extensible app module system
- Real-time data synchronization
- Comprehensive API for integrations
- Security features (input validation, rate limiting, SQL injection protection)
- Performance optimized with caching and async operations

---

## 🚀 Quick Start

Get up and running in 5 minutes:

**1. Clone the repository**
```bash
cd resources
git clone https://github.com/FosterG4/lb-gphone.git
cd lb-gphone
```

**2. Build the NUI interface**
```bash
cd nui
npm install
npm run build
cd ..
```

**3. Add dependencies to server.cfg (before lb-gphone)**
```cfg
ensure oxmysql
ensure pma-voice
```

**4. Add lb-gphone to server.cfg**
```cfg
ensure lb-gphone
```

**5. Configure config.lua (set your framework)**
```lua
Config.Framework = 'standalone'  -- or 'esx', 'qbcore', 'qbox'
```

**6. Start your server**

⚠️ **Important:** Ensure oxmysql and pma-voice are installed and started before lb-gphone.

💡 **Tip:** See the [Complete Installation Guide](INSTALL.md) for step-by-step setup, troubleshooting, and configuration options.

---

## ⚙️ Configuration

The `config.lua` file contains all customizable settings. Key options:

```lua
-- Framework: 'standalone', 'esx', 'qbcore', 'qbox'
Config.Framework = 'standalone'

-- Key to open/close phone
Config.OpenKey = 'M'

-- Phone number format
Config.PhoneNumberFormat = '###-####'

-- Banking limits
Config.WalletApp = {
    enabled = true,
    maxTransferAmount = 999000000000000,  -- 999 trillion
    minTransferAmount = 1
}

-- Media storage: 'local' or 'fivemanage'
Config.MediaStorage = 'local'
```

💡 **Tip:** For all configuration options including app settings, notifications, cryptocurrency, performance tuning, and Fivemanage integration, see the [Installation Guide](INSTALL.md) and [Documentation](docs/DOCUMENTATION.md).

---

## 📚 Documentation

<div align="center">

| For Users | For Developers | Quick Access |
|:----------|:---------------|:-------------|
| [📋 Installation Guide](INSTALL.md) | [🎨 Custom App Development](docs/DOCUMENTATION.md#custom-app-development) | [🐛 Troubleshooting](INSTALL.md#troubleshooting) |
| [📱 User Manual](docs/DOCUMENTATION.md#user-manual) | [🔌 API Documentation](docs/DOCUMENTATION.md#api-documentation) | [📝 Changelog](docs/DOCUMENTATION.md#changelog) |
| [⚙️ Configuration Reference](docs/DOCUMENTATION.md#configuration-reference) | [🧪 Testing Guide](docs/DOCUMENTATION.md#testing-guide) | [❓ FAQ](INSTALL.md#faq) |
| [🔧 Framework Integration](docs/DOCUMENTATION.md#framework-integration) | [🗄️ Database Schema](docs/DOCUMENTATION.md#database-setup) | [📦 Releases](https://github.com/FosterG4/lb-gphone/releases) |
| [☁️ Fivemanage Setup](docs/DOCUMENTATION.md#fivemanage-integration) | [🏗️ Project Structure](docs/DOCUMENTATION.md#project-structure) | [✅ Validation Checklist](docs/VALIDATION_CHECKLIST.md) |

</div>

---

## 🤝 Support

<div align="center">

| 🐛 Bug Reports | 💡 Feature Requests | 💬 Questions & Help |
|:---------------|:--------------------|:--------------------|
| [Open Issue](https://github.com/FosterG4/lb-gphone/issues) | [Request Feature](https://github.com/FosterG4/lb-gphone/issues) | [GitHub Discussions](https://github.com/FosterG4/lb-gphone/discussions) |

**Contributing:** We welcome contributions! Please read our contributing guidelines before submitting PRs.

**Support the Project:** [![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/U7U71NMCFN)

</div>

---

## 🙏 Credits

Built with amazing open-source technologies:

- [Vue.js 3](https://vuejs.org/) - Modern UI framework
- [pma-voice](https://github.com/AvarianKnight/pma-voice) - Voice integration
- [oxmysql](https://github.com/overextended/oxmysql) - Database operations
- The FiveM community for continuous support and feedback

---

## 📄 License

MIT License - see [LICENSE.MD](LICENSE.MD) file for details.

**Made with ❤️ for the FiveM community**

</div>
