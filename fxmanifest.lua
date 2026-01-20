fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'SwisserAI'
description 'Generated with SwisserAI - https://ai.swisser.dev'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'bridge/loader.lua',
    'config.lua',
    'locales.lua'
}

client_scripts {
    'bridge/client/*.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server/*.lua',
    'server/main.lua'
}

files {
    'locales/*.json'
}

dependencies {
    'ox_lib'
}