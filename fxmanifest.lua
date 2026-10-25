fx_version 'cerulean'
game 'gta5'
shared_script '@tc_lang/hook.lua' -- tc_lang
lua54 'yes'

name 'ra7-media'
author 'RA7 DEV'
description 'Staff-controlled media: black out / replace any picture in the world, play images and videos on any surface.'
version '1.0.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/player.html',
    'html/kit/**/*',
}

dependencies {
    'oxmysql',
    'qb-core',
}
client_script '@tc_lang/hook_post.lua' -- tc_lang
