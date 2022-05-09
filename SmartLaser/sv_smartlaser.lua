-- ██       ██████  ███    ██ ██████   ██████  ███    ██     ███████ ████████ ██    ██ ██████  ██  ██████  ███████ 
-- ██      ██    ██ ████   ██ ██   ██ ██    ██ ████   ██     ██         ██    ██    ██ ██   ██ ██ ██    ██ ██      
-- ██      ██    ██ ██ ██  ██ ██   ██ ██    ██ ██ ██  ██     ███████    ██    ██    ██ ██   ██ ██ ██    ██ ███████ 
-- ██      ██    ██ ██  ██ ██ ██   ██ ██    ██ ██  ██ ██          ██    ██    ██    ██ ██   ██ ██ ██    ██      ██ 
-- ███████  ██████  ██   ████ ██████   ██████  ██   ████     ███████    ██     ██████  ██████  ██  ██████  ███████ 
                                                                                                                
                                                                                                                
-- Join our official Discord Server:
-- https://discord.gg/5TD5ssEupv

-- Check out our PAID resources:
-- https://store.londonstudios.net

CreateThread(function()
    for _, v in pairs(GetPlayers()) do
        if Player(v).state.laserOn ~= nil and Player(v).state.laserOn then
            Player(v).state.laserOn = false
        end
    end
end)

RegisterNetEvent("LSLaser:Set", function(value)
    local source = source
    Player(source).state:set('direction', vector3(0.0, 0.0, 0.0), true)
    Player(source).state.laserOn = value
end)