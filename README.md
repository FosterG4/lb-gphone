# FiveM Smartphone NUI

A modern smartphone system with NUI interface for FiveM servers.

## Features

- 📱 Modern smartphone interface built with Vue.js
- 📞 Voice calls with pma-voice integration
- 💬 Text messaging system
- 👥 Contact management
- 🏦 Banking app
- 🐦 Twitter/social media app
- 💰 Cryptocurrency trading app
- 🔧 Framework support (ESX, QBCore, Qbox, Standalone)
- 💾 MySQL database persistence via oxmysql

## Dependencies

- [oxmysql](https://github.com/overextended/oxmysql) - Database operations
- [pma-voice](https://github.com/AvarianKnight/pma-voice) - Voice chat integration

## Installation

1. Download and extract the resource to your FiveM server's `resources` folder
2. Ensure dependencies are installed and started before this resource
3. Add to your `server.cfg`:
```
ensure oxmysql
ensure pma-voice
ensure fivem-smartphone-nui
```

4. Configure the resource by editing `config.lua`
5. Build the NUI interface:
```bash
cd nui
npm install
npm run build
```

## Configuration

Edit `config.lua` to customize:
- Framework type (standalone, ESX, QBCore, Qbox)
- Keybind for opening phone
- Phone number format and length
- Enabled apps
- Notification settings
- Message and call settings
- Database settings

## Development

### Building NUI

Development mode with hot reload:
```bash
cd nui
npm run dev
```

Production build:
```bash
cd nui
npm run build
```

## Project Structure

```
fivem-smartphone-nui/
├── client/              # Client-side Lua scripts
│   ├── main.lua        # Phone open/close logic
│   ├── nui.lua         # NUI callbacks
│   ├── calls.lua       # Call management
│   ├── voice.lua       # pma-voice integration
│   └── utils.lua       # Utility functions
├── server/             # Server-side Lua scripts
│   ├── main.lua        # Server initialization
│   ├── database.lua    # Database operations
│   ├── contacts.lua    # Contact management
│   ├── messages.lua    # Message handling
│   ├── calls.lua       # Call coordination
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
│   │   └── utils/      # Utilities
│   ├── public/
│   └── package.json
├── config.lua          # Configuration file
├── fxmanifest.lua      # Resource manifest
└── README.md
```

## License

This project is open source and available under the MIT License.
