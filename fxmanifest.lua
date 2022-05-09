-- ██       ██████  ███    ██ ██████   ██████  ███    ██     ███████ ████████ ██    ██ ██████  ██  ██████  ███████ 
-- ██      ██    ██ ████   ██ ██   ██ ██    ██ ████   ██     ██         ██    ██    ██ ██   ██ ██ ██    ██ ██      
-- ██      ██    ██ ██ ██  ██ ██   ██ ██    ██ ██ ██  ██     ███████    ██    ██    ██ ██   ██ ██ ██    ██ ███████ 
-- ██      ██    ██ ██  ██ ██ ██   ██ ██    ██ ██  ██ ██          ██    ██    ██    ██ ██   ██ ██ ██    ██      ██ 
-- ███████  ██████  ██   ████ ██████   ██████  ██   ████     ███████    ██     ██████  ██████  ██  ██████  ███████ 
                                                                                                                
                                                                                                                
-- Join our official Discord Server:
-- https://discord.gg/5TD5ssEupv

-- Check out our PAID resources:
-- https://store.londonstudios.net

fx_version 'cerulean'
games { 'gta5' }

author 'London Studios'
description 'An efficient and realistic laser sight resource'
version '1.0.0'

client_scripts {
    'cl_smartlaser.lua'
}

server_scripts {
    'sv_smartlaser.lua'
}

shared_script 'config.lua'