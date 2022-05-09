-- ██       ██████  ███    ██ ██████   ██████  ███    ██     ███████ ████████ ██    ██ ██████  ██  ██████  ███████ 
-- ██      ██    ██ ████   ██ ██   ██ ██    ██ ████   ██     ██         ██    ██    ██ ██   ██ ██ ██    ██ ██      
-- ██      ██    ██ ██ ██  ██ ██   ██ ██    ██ ██ ██  ██     ███████    ██    ██    ██ ██   ██ ██ ██    ██ ███████ 
-- ██      ██    ██ ██  ██ ██ ██   ██ ██    ██ ██  ██ ██          ██    ██    ██    ██ ██   ██ ██ ██    ██      ██ 
-- ███████  ██████  ██   ████ ██████   ██████  ██   ████     ███████    ██     ██████  ██████  ██  ██████  ███████ 
                                                                                                                
                                                                                                                
-- Join our official Discord Server:
-- https://discord.gg/5TD5ssEupv

-- Check out our PAID resources:
-- https://store.londonstudios.net

config = {
    laserColour = {255, 0, 0, 255}, -- RGBA Default
    sphereColour = {255, 0, 0, 255}, -- RGBA Default (only shows when laser is aimed on target)
    offSet = {-0.1, 0.0, 0.025}, -- This is the default offSet if one isn't specified for a weapon
    commandKeybind = 'E', -- This is the default keybind. Each user can change it in Settings -> Keybinds
    commandDesc = "Toggles the laser.", -- This is the keybind description
    commandName = 'laseron', -- This is the command behind the keybind used to toggle the laser
    laserRange = 25.0, -- This is the default range of the laser
    maxLasers = 5 -- This is the maximum amount of lasers that can be around the player at once (for efficiency)
}

config.supportedWeapons = {
    [`WEAPON_PISTOL`] = {
        -- If these values aren't set, the default value will be used
        offSet = {0.0, 0.00, 0.025}, -- Laser offSet from gun
        laserColour = {255, 0, 0, 255}, -- RGBA
        sphereColour = {255, 0, 0, 255}, -- RGBA (only shows when laser is aimed on target)
        laserRange = 25.0, -- Laser Range
    },
    [`WEAPON_ASSAULTRIFLE`] = {
        offSet = {0.5, 0.0, 0.05},
        laserColour = {0, 255, 0, 255},
        sphereColour = {0, 255, 0, 255},
        laserRange = 50.0, -- Laser Range
    },
    [`WEAPON_PISTOL50`] = {}, -- Adding weapons like this will also work and default values will be used!
}

