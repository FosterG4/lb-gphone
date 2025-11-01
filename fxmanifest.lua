fx_version 'cerulean'
game 'gta5'

author 'FiveM Smartphone NUI'
description 'Modern smartphone system with NUI interface for FiveM'
version '1.0.0'

-- Dependencies
dependencies {
    'oxmysql',
    'pma-voice'
}

-- Shared
shared_scripts {
    'config.lua'
}

-- Client
client_scripts {
    'client/main.lua',
    'client/nui.lua',
    'client/calls.lua',
    'client/voice.lua',
    'client/utils.lua',
    'client/notifications.lua',
    'client/settings.lua',
    'client/location.lua',
    'client/vehicle.lua',
    'client/property.lua',
    'client/music.lua',
    'client/contact_sharing.lua',
    'client/media/camera.lua',
    'client/media/video.lua',
    'client/media/audio.lua'
}

-- Server
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/utils.lua',
    'server/database.lua',
    'server/locale.lua',
    'server/locales/en.lua',
    'server/locales/ja.lua',
    'server/locales/es.lua',
    'server/locales/fr.lua',
    'server/locales/de.lua',
    'server/locales/pt.lua',
    'server/main.lua',
    'server/phone_numbers.lua',
    'server/contacts.lua',
    'server/contact_sharing.lua',
    'server/messages.lua',
    'server/calls.lua',
    'server/framework/adapter.lua',
    'server/framework/esx.lua',
    'server/framework/qbcore.lua',
    'server/framework/qbox.lua',
    'server/framework/standalone.lua',
    'server/framework/garage_adapter.lua',
    'server/framework/housing_adapter.lua',
    'server/apps/wallet.lua',
    'server/apps/chirper.lua',
    'server/apps/crypto.lua',
    'server/apps/settings.lua',
    'server/apps/clock.lua',
    'server/apps/notes.lua',
    'server/apps/maps.lua',
    'server/apps/weather.lua',
    'server/apps/appstore.lua',
    'server/apps/garage.lua',
    'server/apps/home.lua',
    'server/apps/shotz.lua',
    'server/apps/modish.lua',
    'server/apps/marketplace.lua',
    'server/apps/pages.lua',
    'server/apps/musicly.lua',
    'server/apps/finder.lua',
    'server/apps/safezone.lua',
    'server/apps/voice_recorder.lua',
    'server/media/storage.lua',
    'server/media/photos.lua',
    'server/media/videos.lua',
    'server/media/audio.lua',
    'server/media/sharing.lua',
    'server/media/albums.lua'
}

-- Tests are located in tests/ directory and should be run manually
-- They are not loaded as part of the resource

-- NUI
ui_page 'nui/dist/index.html'

files {
    'nui/dist/index.html',
    'nui/dist/**/*'
}

lua54 'yes'
