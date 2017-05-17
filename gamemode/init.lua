-- Server side includes
include("shared.lua")

-- Net message pre-cache
util.AddNetworkString("sendGameState")
util.AddNetworkString("sendMapCentre")
util.AddNetworkString("sendWallDistance")

-- Client side lua
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

-- States:
-- 0 = Waiting for players
-- 1 = Lobby mode
-- 2 = Play mode
-- 3 = End game
local gameState = gameWaiting

-- Game vars
local mapCentre = nil

local wallDistance = 0
local wallDistanceOld = 0
local wallDistanceCurrent = 0
local wallAnimate = false
local wallAnimateStartTime = nil

local wallStart = 0
local wallEnd = 0
local wallCurrentStep = 0

local playersOutsideWall = {}

-- Gamemode Init
function GM:Initialize()
end

-- After all ents have loaded
function GM:InitPostEntity()
    -- Store the map centre value
    local mapCentreEnt = ents.FindByClass('al_map_centre')[1]
    mapCentre = mapCentreEnt:GetPos()

    -- Get the map center key value for wall start and end
    wallStart = mapCentreEnt.startDistance
    wallEnd = mapCentreEnt.endDistance
end

-- On tick...
function GM:Think()

    -- Check game state
    -- Game is waiting for players
    if gameState == gameWaiting then

       prepRound()

    -- Game is waiting for the play mode to start
    elseif gameState == gameLobby then

    -- Game is waiting for only one person to be alive
    elseif gameState == gamePlaying then

        -- Check team alives players
        if team.NumPlayers(teamAlive) <= 1 then

            -- End the round
            endRound()

        end
    
    -- Game is announing a winner
    -- If play count is greater than min, we skip state 0 and jump to 1
    elseif gameState == gameEnded then

    end

    -- If the wall distance currently isnt the actual wall distance, animate to new distance
    if wallDistanceCurrent != wallDistance and wallAnimate == false then

        -- Store current distance, we use this to animate to
        wallDistanceOld = wallDistanceCurrent

        -- Turn the wall animation on
        wallAnimate = true

        -- Set now as the start time, we'll animate using this timepoint
        wallAnimateStartTime = CurTime()
    end

    -- Handle wall animation
    if wallAnimate then

        -- Get the time left as a float between 0 and 1
        local wallAnimateTimeLeft = 1 - ((wallAnimateStartTime + wallAnimateTime) - CurTime()) / wallAnimateTime
        wallDistanceCurrent = Lerp(wallAnimateTimeLeft, wallDistanceOld, wallDistance)
        if wallDistanceCurrent == wallDistance then
            wallAnimate = false
        end
    end

    -- Get all alive players technically outside of the wall
    for _, ply in pairs(team.GetPlayers(teamAlive)) do

        -- Check to see if the player is within the wall bounds
        local plyPos = ply:GetPos()
        local plyX = plyPos[1]
        local plyY = plyPos[2]
        local xPosBound = mapCentre[1] + wallDistanceCurrent
        local xNegBound = mapCentre[1] - wallDistanceCurrent
        local yPosBound = mapCentre[2] + wallDistanceCurrent
        local yNegBound = mapCentre[2] - wallDistanceCurrent

        if plyX > xPosBound or plyX < xNegBound or plyY > yPosBound or plyY < yNegBound then

            -- Check to see if the player is in the player table
            if table.HasValue(playersOutsideWall, ply) == false then
                table.insert(playersOutsideWall, ply)
            end

        else

            -- Remove the player from the outside wall table
            if table.HasValue(playersOutsideWall, ply) then
                table.RemoveByValue(playersOutsideWall, ply)
            end

        end

    end

    PrintTable(playersOutsideWall)

end

-- Player spawn
function GM:PlayerInitialSpawn(ply)
    -- Send the map centre to the player
    sendMapCentre(ply)

    -- Send the game state to the player
    sendGameState(ply)

    -- By default players will join "Dead"
    if gameState == gameLobby then
        ply:SetTeam(teamAlive)
    else    
        ply:SetTeam(teamDead)
    end

    -- Console message
    printDebug(ply:Nick() .. " init spawn...")
end

function GM:PlayerSpawn(ply)

    -- Console message
    printDebug(ply:Nick() .. " main spawn...")

    -- If player is dead, spectate
	if ply:Team() == teamDead then
        -- Console message
        printDebug(ply:Nick() .. " is now teamDead")

        -- Strip users weapons and ammo
		ply:StripAmmo()
		ply:StripWeapons()

        -- Force spec
		ply:Spectate(OBS_MODE_ROAMING)

        -- Thats all we need to do...
		return false
    
    -- If player is not dead, unspectate
	elseif ply:Team() == teamAlive then
        -- Console message
        printDebug(ply:Nick() .. " is now teamAlive")

        -- Remove spectator
		ply:UnSpectate()

        -- Set player model
        ply:SetModel( "models/player/odessa.mdl" )
	end

end

function GM:EntityTakeDamage(target, dmginfo)

    -- Players can only receive damage while in playing state
    if (target:IsPlayer() and gameState != gamePlaying) then
        return true
    end

end


function GM:PlayerDeath(ply, weapon, killer)
	-- Console message
    printDebug(ply:Nick() .. " died...")

    -- Set player to teamDead
    ply:SetTeam(teamDead)
end

-- Disable player suicide
function GM:CanPlayerSuicide(ply)
    return false
end

-- Function to prep new round
function prepRound()

     -- Check player count
    if player.GetCount() >= 2 then

        -- Start new round
        startRound()

    else

        -- I'm guessing we have only one player here as everyone has left?
        for _, ply in pairs(team.GetPlayers(teamAlive)) do

            -- Kill player
            ply:Kill()

            -- Set the state of the game so the think loop doesn't get lost...
            gameState = gameWaiting

            -- Tell all users the gamestate has changed
            sendGameState()

        end

    end


end

-- Function that starts a new round
function startRound()

    -- Console message
    printDebug("Staring new round, setting to lobby...")

    -- Set the state of the game so the think loop doesn't get lost...
    gameState = gameLobby

    -- Tell all users the gamestate has changed
    sendGameState()

    -- Set the position of the wall
    setWallDistance(wallStart, true)

    -- Clean up the map
    game.CleanUpMap()

    -- Set each players team and spawn them...
    for _, ply in pairs(player.GetAll()) do

        -- Force to alive
        ply:SetTeam(teamAlive)
        
        -- Force user to spawn
        ply:Spawn()

        -- Strip ammo and weapons
        ply:StripAmmo()
        ply:StripWeapons()
    end

    -- Create a timer to advance to playing
    timer.Create('gamePlayingState', lobbyTime, 1, function()
        -- Begin the new round
        beginRound()        
    end) 

end

-- Function that begins the round
function beginRound()
    -- Console message
    printDebug("Beginning the round, stay alive...")

    -- Set the state of the game so the think loop doesn't get lost...
    gameState = gamePlaying

    -- Tell all users the gamestate has changed
    sendGameState()

    -- Clean up the map
    game.CleanUpMap()

    -- Respawn all players in Alive team
    for _, ply in pairs(team.GetPlayers(teamAlive)) do
        ply:Spawn()
    end

    -- Create a timer to advance to the next wall step
    timer.Create('wallAdvanceStep', wallStepTime, wallSteps, function()
        -- Advance wall step
        nextWallStep()
    end)

    -- Create a timer to hurt all players outside of the wall
    timer.Create('playerOutsideWallHurt', 1, 0, function()
        
        -- Loop players
        for _, ply in pairs(playersOutsideWall) do
            ply:TakeDamage(10)
        end

    end)

end

-- Function to end the round
function endRound()
    -- Console message
    printDebug("The round has ended, hurrah...")

    -- Set the state of the game so the think loop doesn't get lost...
    gameState = gameEnded

    -- Tell all users the gamestate has changed
    sendGameState()

    -- Kill wall timer
    timer.Remove('wallAdvanceStep')

    -- Reset wall steps
    wallCurrentStep = 0

    -- Kill damage timer
    timer.Remove('playerOutsideWallHurt')

    -- Create a timer to advance to playing
    timer.Create('gamePlayingState', endTime, 1, function()
        -- Begin the new round
        prepRound()
    end)
end

-- Function to send gamestate to a clients
function sendGameState(ply)
    net.Start("sendGameState")
    net.WriteInt(gameState, 3)
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

-- Function to send the map centre to the client
function sendMapCentre(ply)
    net.Start("sendMapCentre")
    net.WriteVector(mapCentre)
    net.Send(ply)
end

-- Function to set wall distance
function setWallDistance(distance, force)
    -- Set server var
    wallDistance = distance

    if force then
        wallDistanceCurrent = wallDistance
    end

    -- Send var to client
    net.Start("sendWallDistance")
    net.WriteFloat(distance)
    net.WriteBool(force)
    net.Broadcast()
end

-- Function to go to next wall step
function nextWallStep()

    -- Increment the current wall step
    wallCurrentStep = wallCurrentStep + 1

    -- Get the distance for a single step
    local stepDistance = (wallStart - wallEnd) / wallSteps
    local currentStepDistance = stepDistance * wallCurrentStep

    -- Set the new wall distance
    setWallDistance(wallStart - currentStepDistance, false)

end