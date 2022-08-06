-- ██       ██████  ███    ██ ██████   ██████  ███    ██     ███████ ████████ ██    ██ ██████  ██  ██████  ███████
-- ██      ██    ██ ████   ██ ██   ██ ██    ██ ████   ██     ██         ██    ██    ██ ██   ██ ██ ██    ██ ██
-- ██      ██    ██ ██ ██  ██ ██   ██ ██    ██ ██ ██  ██     ███████    ██    ██    ██ ██   ██ ██ ██    ██ ███████
-- ██      ██    ██ ██  ██ ██ ██   ██ ██    ██ ██  ██ ██          ██    ██    ██    ██ ██   ██ ██ ██    ██      ██
-- ███████  ██████  ██   ████ ██████   ██████  ██   ████     ███████    ██     ██████  ██████  ██  ██████  ███████

                                                    
-- Join our official Discord Server:
-- https://discord.gg/5TD5ssEupv

-- Check out our PAID resources:
-- https://store.londonstudios.net

local ped, src, playerId, laserSight, directionMain,
activePlayers, selectedWeapon, laserState, cameraPos
local laserPromise, drawPromise = promise.new(), promise.new()

-- Laser Info
local lasers = {}
local screen = {}

--Cache functions for a performance improvment
local localState = LocalPlayer.state
local vec3, table_unpack, table_clone = vec3, table.unpack, table.clone
local DrawMarker, DrawLine, StartShapeTestLosProbe, GetShapeTestResult, GetOffsetFromEntityInWorldCoords,
GetSelectedPedWeapon, IsPlayerFreeAiming, GetGameplayCamRot, Wait, GetEntityCoords, DoesEntityExist =
DrawMarker, DrawLine, StartShapeTestLosProbe, GetShapeTestResult, GetOffsetFromEntityInWorldCoords,
GetSelectedPedWeapon, IsPlayerFreeAiming, GetGameplayCamRot, Wait, GetEntityCoords, DoesEntityExist

-- import GLM and cache used GLM functions
local glm = require 'glm'
local glm_up = glm.up()
local glm_forward = glm.forward()
local glm_rad = glm.rad
local glm_quatEuler = glm.quatEulerAngleZYX
local glm_rayPicking = glm.rayPicking

--- Check if SetInterval exists within this server version, if not then we add it ourselves 
--- Source: https://github.com/citizenfx/fivem/blob/e5168125ed9151aec01472b5086421df3b63e2b4/data/shared/citizen/scripting/lua/scheduler.lua#L156-L207
if not Citizen.SetInterval then
    local intervals = {}

    local function checkInterval(a1, atype, pos, a2)
        if intervals[a1] then
            assert(atype == 'number', ("bad argument #%s to 'SetInterval' (number expected, got %s)"):format(pos, atype))
            intervals[a1] = a2 or 0
            return
        elseif intervals[a2] then
            assert(atype == 'number', ("bad argument #%s to 'SetInterval' (number expected, got %s)"):format(pos, atype))
            intervals[a2] = a1 or 0
            return
        end

        return a2, a1 or 0
    end

    function Citizen.SetInterval(callback, interval, ...)
        local t1 = type(callback)
        local t2 = type(interval)

        if t1 == 'number' then
            callback, interval = checkInterval(callback, t2, 2, interval)
        elseif t2 == 'number' then
            callback, interval = checkInterval(interval, t1, 1, callback)
        end

        if not interval then return end

        assert(callback, ("'SetInterval' expects a number and function as arguments. Received %s and %s."):format(t1, t2))

        local id
        local args = {...}

        Citizen.CreateThreadNow(function(ref)
            id = ref
            intervals[id] = interval or 0
            repeat
                interval = intervals[id]
                Wait(interval)
                callback(table_unpack(args))
            until interval < 0
            intervals[id] = nil
        end)

        return id
    end

    function Citizen.ClearInterval(id)
        assert(type(id) == 'number', ("bad argument #1 to 'ClearInterval' (number expected, got %s)"):format(type(id)))
        assert(intervals[id], ("Invalid id sent to 'ClearInterval' (received %s)"):format(id))
        intervals[id] = -1
    end

    -- Implement a function to adjust existing interval timers without creating a new interval to wrap around existing interval.
    function Citizen.AdjustInterval(id, time)
        local type1 = type(id)
        assert(type1 == 'number', ("bad arugment #1 to 'AdjustInterval' (number expected, got %s)"):format(type1))
        local interval = intervals[id]
        assert(interval, ("Invalid id sent to 'ClearInterval' (recieved %s)"):format(id))
        interval = time
        intervals[id] = interval
    end
end

-- Helper function
local _pairs = pairs
local function table_length(tbl)
    local length = 0
    if tbl then
        for _ in _pairs(tbl) do
            length += 1
        end
        return length
    end
end

-- creates a new promise when there are no active lasers.
function resolveLasers()
    local tmpLasers = table_clone(lasers)
    tmpLasers[src] = nil
    local length = table_length(tmpLasers)
    if length == 0 then
        if drawPromise.state ~= 0 then
            drawPromise = promise.new()
        end
    end
    lasers[src] = nil
end

Citizen.SetInterval(function ()
    if not playerId then playerId = PlayerId() end
    if not src then src = GetPlayerServerId(ped and ped or PlayerPedId()) end
    Citizen.Await(laserPromise)
    if laserSight then
        local laserOn = config.retriveLocalStateFromServer
          and localPlayer.state.laserOn or laserState
        if selectedWeapon and selectedWeapon ~= `WEAPON_UNARMED` 
        and config.supportedWeapons[selectedWeapon] and IsPlayerFreeAiming(playerId)
        then
           if not laserOn then
                if not config.retriveLocalStateFromServer then
                    laserState = true
                end
                localState:set('laserOn', true, true)
           end
           cameraPos, directionMain = CameraPositionToCameraRay()
           localState:set('direction', directionMain, true)
           DrawLaser(ped, src)
        elseif laserOn then
            if not config.retriveLocalStateFromServer then
                laserState = false
            end
            localState:set('laserOn', false, true)
            resolveLasers()
        end
    end
end, 0)

--//TODO - replace with state bag handlers.
playerTracker = Citizen.SetInterval(function ()
    local pedCoords = GetEntityCoords(ped)
    local currentLasersEnabled = 0
    local nearbyLasers = false
    if activePlayers then
        for i=1, #activePlayers do
            local v = activePlayers[i]
            if v == playerId then goto continue end
            local targetSrc = GetPlayerServerId(v)
            local laserEnabled = Player(targetSrc).state.laserOn
            if laserEnabled then
                local targetPed = GetPlayerPed(v)
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(targetCoords - pedCoords)
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
    end
    Citizen.AdjustInterval(playerTracker, (nearbyLasers and 0 or 3000))
end, 0)

Citizen.SetInterval(function()
    Citizen.Await(drawPromise)
    for _,v in pairs(lasers) do
        DrawLine(v.laserOffset.x, v.laserOffset.y, v.laserOffset.z, v.laserCoordinates.x, v.laserCoordinates.y, v.laserCoordinates.z, v.laserColour[1], v.laserColour[2], v.laserColour[3], v.laserColour[4])
        -- Source: FiveM Forum
        DrawMarker(28, v.laserCoordinates.x, v.laserCoordinates.y, v.laserCoordinates.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.01 --[[Radius]], 0.01 --[[Radius]], 0.01 --[[Radius]], v.sphereColour[1] --[[r]], v.sphereColour[2] --[[g]], v.sphereColour[3] --[[b]], v.sphereColour[4] --[[a]], false, false, 2, nil, nil, false)         
    end
end, 0)

-- Updates cached values every second
Citizen.SetInterval(function ()
    ped = PlayerPedId()
    selectedWeapon = GetSelectedPedWeapon(ped)
    activePlayers = GetActivePlayers()
	screen.ratio = GetAspectRatio(true)
	screen.fov = glm_rad(GetGameplayCamFov())
    ClearInvalidCachedWeaponEntitys(src, selectedWeapon)
end, 1000)

local weaponEntitys = {}
function DrawLaser(targetPed, targetSrc)
    if not targetPed then return end
    if not targetSrc then targetSrc = GetPlayerServerId(targetPed) end
    local weapon = selectedWeapon
    local weaponEntity
    if weaponEntitys[weapon] and weaponEntitys[weapon][targetSrc] then
        weaponEntity = weaponEntitys[weapon][targetSrc]
        goto laserCalc
    end

    if not weaponEntitys[weapon] then weaponEntitys[weapon] = {} end
    weaponEntity = GetCurrentPedWeaponEntityIndex(targetPed)
    weaponEntitys[weapon][targetSrc] = weaponEntity

    ::laserCalc::
    local changeOffset = config.supportedWeapons[weapon]?.offSet or config.offSet
    laserOffset = GetOffsetFromEntityInWorldCoords(weaponEntity, changeOffset[1], changeOffset[2], changeOffset[3])
    local isEntityHit, coordinates = getLaserCoords(laserOffset, targetSrc, targetPed, weapon)
    if isEntityHit then
        local targetLaser = lasers[targetSrc]
        if not targetLaser or targetLaser.hash ~= weapon then
            local laserColour = config.supportedWeapons[weapon]?.laserColour or config.laserColour
            local sphereColour = config.supportedWeapons[weapon]?.sphereColour or config.sphereColour
            lasers[targetSrc] = {
                hash = weapon,
                laserOffset = laserOffset,
                laserCoordinates = coordinates,
                laserColour = laserColour,
                sphereColour = sphereColour
            }
        else
            targetLaser.laserOffset = laserOffset
            targetLaser.laserCoordinates = coordinates
        end

        if laserSight then
            if drawPromise.state == 0 then -- stops the promise from mass resolving
                drawPromise:resolve()
            end
        end
    else
        resolveLasers()
    end
end

function getLaserCoords(coords, targetSrc, targetPed, weapon)
    local isLocalPlayer = targetPed == ped
    local direction = isLocalPlayer and directionMain or Player(targetSrc).state['direction']
    local radius = config.supportedWeapons[weapon]?.laserRange or config.laserRange

    if isLocalPlayer then
        local endCoords = cameraPos + radius * direction
        return Raycast(coords, endCoords, -1, ped, 0)
    end

    return Raycast(coords, vec3(coords.x + direction.x * radius, coords.y + direction.y * radius, coords.z + direction.z * radius), -1, targetPed, 0)
end

function Raycast(startCoords, endCoords, flags, entity, mask)
    local rayHandle = StartShapeTestLosProbe(startCoords.x, startCoords.y, startCoords.z, endCoords.x, endCoords.y, endCoords.z, flags or -1, entity, mask)
    while true do
        Wait(0)
        local result, hit, EndCoords = GetShapeTestResult(rayHandle)
        if result ~= 1 then
            return hit, EndCoords
        end
    end
end

-- Modified from: https://github.com/citizenfx/lua/blob/luaglm-dev/cfx/libs/scripts/examples/scripting_gta.lua
function CameraPositionToCameraRay()
    local pos = GetGameplayCamCoord()
    local rot = glm_rad(GetGameplayCamRot())
    local q = glm_quatEuler(rot.z, rot.y, rot.x)
    return pos, glm_rayPicking(
        q * glm_forward,
        q * glm_up,
        screen.fov, -- we update and cache this every second.
        screen.ratio,
        0.10000,
        10000.0,
        0, 0 -- Don't scale mouse coords.
    )
end

function ClearInvalidCachedWeaponEntitys(id, ignoredWeaponHash)
    for k, v in pairs(weaponEntitys) do
        if ignoredWeaponHash and k == ignoredWeaponHash
        and DoesEntityExist(ignoredWeaponHash) then
            goto continue
        end
        if v[id] then
            v[id] = nil
        end
        ::continue::
    end
end

local inVehicle
local GameBuild = GetGameBuildNumber()

RegisterCommand(config.commandName, function()
    local pedWeapon = GetSelectedPedWeapon(ped)
    if config.supportedWeapons[pedWeapon] then
        selectedWeapon = pedWeapon
        if laserSight then
            laserSight = false
            laserPromise = promise.new()
            resolveLasers()
            TriggerServerEvent("LSLaser:Set", false)
        else
            if (GameBuild >= 2189 and not inVehicle) or GetVehiclePedIsIn(ped) == 0 then
                laserSight = true
                laserPromise:resolve()
                TriggerServerEvent("LSLaser:Set", true)
            end
        end
    end
end)
RegisterKeyMapping(config.commandName, config.commandDesc, "keyboard", config.commandKeybind)
TriggerEvent('chat:removeSuggestion', ('/%s'):format(config.commandName))

-- Disable laser while in vehicle   
if GetGameBuildNumber() >= 2189 then -- this may work on older builds such as 2060, but it appears not to work on build 1604
    AddEventHandler("gameEventTriggered", function (name)
        if name == "CEventNetworkPlayerEnteredVehicle" then
            laserSight = false
            laserPromise = promise.new()
            resolveLasers()
            TriggerServerEvent("LSLaser:Set", false)
        end
    end)
else
    --[[Citizen.SetInterval(function()
        if GetVehiclePedIsIn(ped) ~= 0 and not inVehicle then
            inVehicle = true
            laserSight = false
            laserPromise = promise.new()
            resolveLasers()
            TriggerServerEvent("LSLaser:Set", false)
        elseif inVehicle then
            inVehicle = false
        end
    end, 500)
]]
end