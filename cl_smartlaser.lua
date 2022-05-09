-- ██       ██████  ███    ██ ██████   ██████  ███    ██     ███████ ████████ ██    ██ ██████  ██  ██████  ███████ 
-- ██      ██    ██ ████   ██ ██   ██ ██    ██ ████   ██     ██         ██    ██    ██ ██   ██ ██ ██    ██ ██      
-- ██      ██    ██ ██ ██  ██ ██   ██ ██    ██ ██ ██  ██     ███████    ██    ██    ██ ██   ██ ██ ██    ██ ███████ 
-- ██      ██    ██ ██  ██ ██ ██   ██ ██    ██ ██  ██ ██          ██    ██    ██    ██ ██   ██ ██ ██    ██      ██ 
-- ███████  ██████  ██   ████ ██████   ██████  ██   ████     ███████    ██     ██████  ██████  ██  ██████  ███████ 
                                                                                                                
                                                                                                                
-- Join our official Discord Server:
-- https://discord.gg/5TD5ssEupv

-- Check out our PAID resources:
-- https://store.londonstudios.net

local ped
local coords
local laserSight
local directionMain

RegisterKeyMapping(config.commandName, config.commandDesc, "keyboard", config.commandKeybind)
RegisterCommand(config.commandName, function(source, args, raw)
    local pedWeapon = GetSelectedPedWeapon(ped)
    if config.supportedWeapons[pedWeapon] ~= nil then
        if laserSight then
            laserSight = false
            TriggerServerEvent("LSLaser:Set", false)
        else
            laserSight = true
            TriggerServerEvent("LSLaser:Set", true)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        ped = PlayerPedId()
        coords = GetEntityCoords(ped)
        local currentLasersEnabled = 0
        local nearbyLasers = false
        for _, v in pairs(GetActivePlayers()) do
            local targetSrc = GetPlayerServerId(v)
            local laserEnabled = Player(targetSrc).state.laserOn
            if laserEnabled then
                local targetPed = GetPlayerPed(v)
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(targetCoords - coords)
                currentLasersEnabled = currentLasersEnabled + 1
                if distance < config.laserRange and currentLasersEnabled <= config.maxLasers then
                    nearbyLasers = true
                    local weaponEntity = GetCurrentPedWeaponEntityIndex(targetPed)
                    local weapon = GetSelectedPedWeapon(targetPed)
                    local changeOffset = config.supportedWeapons[weapon].offSet
                    if changeOffset == nil then
                        changeOffset = config.offSet
                    end
                    local offset = GetOffsetFromEntityInWorldCoords(weaponEntity, changeOffset[1], changeOffset[2], changeOffset[3])
                    local isEntityHit, coordinates = getLaserCoords(offset, targetSrc, targetPed, weapon)
                    if isEntityHit == 1 then
                        local laserColour = config.supportedWeapons[weapon].laserColour
                        if laserColour == nil then
                            laserColour = config.laserColour
                        end
                        local sphereColour = config.supportedWeapons[weapon].sphereColour
                        if sphereColour == nil then
                            sphereColour = config.sphereColour
                        end
                        DrawLine(offset.x, offset.y, offset.z, coordinates.x, coordinates.y, coordinates.z, laserColour[1], laserColour[2], laserColour[3], laserColour[4])
                        DrawSphere2(coordinates, 0.01, sphereColour[1], sphereColour[2], sphereColour[3], sphereColour[4])
                    end
                else
                    Player(targetSrc).state.laserOn = false
                end
            end
        end

        if not nearbyLasers and not laserSight then
            Wait(3000)
        end

        if laserSight then
            local laserOn = LocalPlayer.state.laserOn
            if IsPlayerFreeAiming(PlayerId()) then
                if not laserOn then
                    LocalPlayer.state:set('laserOn', true, true)
                end
                local rotation = GetGameplayCamRot()
                directionMain = RotationToDirection(rotation)
                LocalPlayer.state:set('direction', directionMain, true)
            else
                if laserOn then
                    LocalPlayer.state:set('laserOn', false, true)
                end
            end
        end

        Wait(0)
    end
end)

-- Source: FiveM Forum
function DrawSphere2(pos, radius, r, g, b, a)
	DrawMarker(28, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, radius, radius, radius, r, g, b, a, false, false, 2, nil, nil, false)
end

function getLaserCoords(coords, targetSrc, targetPed, weapon)
    local direction
    local radius = config.supportedWeapons[weapon].laserRange
    if config.supportedWeapons[weapon].laserRange == nil then
        radius = config.laserRange
    end
    if targetPed == ped then
        direction = directionMain
    else
        direction = Player(targetSrc).state['direction']
    end
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(coords.x, coords.y, coords.z, coords.x + direction.x * radius, coords.y + direction.y * radius, coords.z + direction.z * radius, -1, targetPed, 1))
    return b, c
end

-- Source: FiveM Forum
function RotationToDirection(rotation)
	local adjustedRotation = 
	{ 
		x = (math.pi / 180) * rotation.x, 
		y = (math.pi / 180) * rotation.y, 
		z = (math.pi / 180) * rotation.z 
	}
	local direction = 
	vector3(
		-math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		math.sin(adjustedRotation.x))
	return direction
end
