-- ██       ██████  ███    ██ ██████   ██████  ███    ██     ███████ ████████ ██    ██ ██████  ██  ██████  ███████ 
-- ██      ██    ██ ████   ██ ██   ██ ██    ██ ████   ██     ██         ██    ██    ██ ██   ██ ██ ██    ██ ██      
-- ██      ██    ██ ██ ██  ██ ██   ██ ██    ██ ██ ██  ██     ███████    ██    ██    ██ ██   ██ ██ ██    ██ ███████ 
-- ██      ██    ██ ██  ██ ██ ██   ██ ██    ██ ██  ██ ██          ██    ██    ██    ██ ██   ██ ██ ██    ██      ██ 
-- ███████  ██████  ██   ████ ██████   ██████  ██   ████     ███████    ██     ██████  ██████  ██  ██████  ███████ 
                                                                                              
                                                                                        
-- Join our official Discord Server:
-- https://discord.gg/5TD5ssEupv

-- Check out our PAID resources:
-- https://store.londonstudios.net

local DefaultDirection <const> = vec3(0.0, 0.0, 0.0)
CreateThread(function()
    for _, v in pairs(GetPlayers()) do
        if Player(v).state.laserOn then
            Player(v).state.laserOn = false
        end
    end
end)

RegisterNetEvent("LSLaser:Set", function(value)
    local src = source
    local PlayerState = Player(src)
    if not PlayerState.state.direction then
        PlayerState.state:set('direction', DefaultDirection, true)
    end
    Player(source).state.laserOn = value
end)