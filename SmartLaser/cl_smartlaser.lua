-- ██       ██████  ███    ██ ██████   ██████  ███    ██     ███████ ████████ ██    ██ ██████  ██  ██████  ███████
-- ██      ██    ██ ████   ██ ██   ██ ██    ██ ████   ██     ██         ██    ██    ██ ██   ██ ██ ██    ██ ██
-- ██      ██    ██ ██ ██  ██ ██   ██ ██    ██ ██ ██  ██     ███████    ██    ██    ██ ██   ██ ██ ██    ██ ███████
-- ██      ██    ██ ██  ██ ██ ██   ██ ██    ██ ██  ██ ██          ██    ██    ██    ██ ██   ██ ██ ██    ██      ██
-- ███████  ██████  ██   ████ ██████   ██████  ██   ████     ███████    ██     ██████  ██████  ██  ██████  ███████
                                                                         
                                                                
-- Join our official Discord Server:
-- https://discord.gg/5TD5ssEupv

-- Check out our PAID resources:
-- https://store.londonstudios.net

local ped, src, playerId, coords, laserSight, directionMain
local WaitForLaserPromise = promise.new()

RegisterKeyMapping(config.commandName, config.commandDesc, "keyboard", config.commandKeybind)
RegisterCommand(config.commandName, function()
    local pedWeapon = GetSelectedPedWeapon(ped)
    if config.supportedWeapons[pedWeapon] then
        if laserSight then
            laserSight = false
            WaitForLaserPromise = promise.new()
            TriggerServerEvent("LSLaser:Set", false)
        else
            laserSight = true
            WaitForLaserPromise:resolve()
            TriggerServerEvent("LSLaser:Set", true)
        end
    end
end)

--Cache LocalPlayer for another minor performance improvement
local localPlayer = LocalPlayer
CreateThread(function()
    while true do
        if not playerId then playerId = PlayerId() end
        if not src then src = GetPlayerServerId(ped and ped or PlayerPedId()) end
        Citizen.Await(WaitForLaserPromise)
        if laserSight then
            local laserOn = localPlayer.state.laserOn or true
            if IsPlayerFreeAiming(playerId) then
                if not laserOn then
                    localPlayer.state:set('laserOn', true, true)
                end
                local rotation = GetGameplayCamRot()
                directionMain = RotationToDirection(rotation)
                DrawLaser(ped, src)
                localPlayer.state:set('direction', directionMain, true)
            else
                if laserOn then
                    localPlayer.state:set('laserOn', false, true)
                end
            end
        end
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        ped = PlayerPedId()
        coords = GetEntityCoords(ped)
        local currentLasersEnabled = 0
        local nearbyLasers = false
        local ActivePlayers = GetActivePlayers()
        for i=1, #ActivePlayers do
            local v = ActivePlayers[i]
            if v == playerId then goto continue end
            local targetSrc = GetPlayerServerId(v)
            local laserEnabled = Player(targetSrc).state.laserOn
            if laserEnabled then
                local targetPed = GetPlayerPed(v)
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(targetCoords - coords)
                currentLasersEnabled = currentLasersEnabled + 1
                if distance < config.laserRange and currentLasersEnabled <= config.maxLasers then
                    nearbyLasers = true
                    DrawLaser(targetPed, targetSrc)
                else
                    Player(targetSrc).state.laserOn = false
                end
            end
            ::continue::
        end
        Wait((not nearbyLasers and 3000 or 0))
    end
end)

-- Cache commonly used natives for a *very* minor performance improvement
local DrawMarker, DrawLine, StartShapeTestLosProbe, GetShapeTestResult, GetOffsetFromEntityInWorldCoords, GetSelectedPedWeapon =
DrawMarker, DrawLine, StartShapeTestLosProbe, GetShapeTestResult, GetOffsetFromEntityInWorldCoords, GetSelectedPedWeapon

-- Source: FiveM Forum
function DrawSphere2(pos, radius, r, g, b, a)
	DrawMarker(28, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, radius, radius, radius, r, g, b, a, false, false, 2, nil, nil, false)
end

local cachedWeapon, cachedWeaponEntity = {}, {}
function DrawLaser(targetPed, targetSrc)
    if not targetPed then return end
    if not targetSrc then targetSrc = GetPlayerServerId(targetPed) end
    local weapon = GetSelectedPedWeapon(targetPed)
    if not cachedWeapon[targetSrc] or cachedWeapon[targetSrc] ~= weapon then
        cachedWeapon[targetSrc] = weapon
        cachedWeaponEntity[targetSrc] = GetCurrentPedWeaponEntityIndex(targetPed)
        weaponEntity = cachedWeaponEntity[targetSrc]
    end
    local changeOffset = config.supportedWeapons[weapon]?.offSet or config.offSet
    local offset = GetOffsetFromEntityInWorldCoords(weaponEntity, changeOffset[1], changeOffset[2], changeOffset[3])
    local isEntityHit, coordinates = getLaserCoords(offset, targetSrc, targetPed, weapon)
    if isEntityHit == 1 then
        local laserColour = config.supportedWeapons[weapon]?.laserColour or config.laserColour
        local sphereColour = config.supportedWeapons[weapon]?.sphereColour or config.sphereColour
        DrawLine(offset.x, offset.y, offset.z, coordinates.x, coordinates.y, coordinates.z, laserColour[1], laserColour[2], laserColour[3], laserColour[4])
        DrawSphere2(coordinates, 0.01, sphereColour[1], sphereColour[2], sphereColour[3], sphereColour[4])
    end
end

function getLaserCoords(coords, targetSrc, targetPed, weapon)
    local direction = targetPed == ped and directionMain or Player(targetSrc).state['direction']
    local radius = config.supportedWeapons[weapon].laserRange and config.supportedWeapons[weapon].laserRange or config.laserRange
    return Raycast(coords, vec3(coords.x + direction.x * radius, coords.y + direction.y * radius, coords.z + direction.z * radius), -1, targetPed, 1)
end

function Raycast(startCoords, endCoords, flags, entity, mask)
    local rayHandle = StartShapeTestLosProbe(startCoords.x, startCoords.y, startCoords.z, endCoords.x, endCoords.y, endCoords.z, flags or -1, entity, mask)
    while true do
        local result, hit, EndCoords = GetShapeTestResult(rayHandle)
        if result ~= 1 then
            return hit, EndCoords
        end
        Wait(0)
    end
end

-- Source: FiveM Forum
local pi, sin, cos, abs = math.pi, math.sin, math.cos, math.abs
function RotationToDirection(rotation)
	local adjustedRotation = vec3((pi / 180) * rotation.x, (pi / 180) * rotation.y, (pi / 180) * rotation.z)
	local direction = vec3(
		-sin(adjustedRotation.z) * abs(cos(adjustedRotation.x)),
		cos(adjustedRotation.z) * abs(cos(adjustedRotation.x)),
		sin(adjustedRotation.x)
    )
	return direction
end
