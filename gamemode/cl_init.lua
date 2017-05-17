include( "shared.lua" )

-- Local HUD vars
local mapCentre = Vector(0, 0, 0)
local wallDistance = 0
local wallDistanceOld = 0
local wallDistanceCurrent = 0
local wallAnimate = false
local wallAnimateStartTime = nil
local gameState = 0

-- Create HUD object
local aliveHud = {}

-- Create text painter
function aliveHud:text(x, y, text, font, color, shadowColor)

	-- Set the font we'll use
	surface.SetFont(font)
 
	-- Draw a shadow
	surface.SetTextPos(x + 1, y + 1)
	surface.SetTextColor(shadowColor)
	surface.DrawText(text)
 
	-- Draw the actual text
	surface.SetTextPos(x, y)
	surface.SetTextColor(color)
	surface.DrawText(text)

end

-- Create bar painter
function aliveHud:bar( x, y, w, h, fillColor, bgColor, value )
 
	-- Draw background to bar
	surface.SetDrawColor(bgColor)
	surface.DrawRect(x, y, w, h)
 
	-- Calc width
	local width = w * math.Clamp(value, 0, 1)

	-- Draw bar
	surface.SetDrawColor(fillColor)
	surface.DrawRect( x, y, width, h)
 
end

-- Client think
function GM:Think()

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

end

-- Global hud painting hook
function GM:HUDPaint()

	-- Get the local player object
	ply = ply or LocalPlayer()

	-- Tell the player their team
	aliveHud:text(50, 50, "Team: " .. team.GetName(ply:Team()), "default", colors.white, colors.black)

	-- Tell player what game state we are in
	aliveHud:text(50, 65, "Game state: " .. gameState, "default", colors.white, colors.black)

	-- Tell player how many people are alive
	aliveHud:text(50, 80, "Alive players: " .. team.NumPlayers(teamAlive), "default", colors.white, colors.black)

	-- Health bar
	if ply:Team() == teamAlive and gameState == gamePlaying then
		aliveHud:bar(50, ScrH() - 70, 250, 20, colors.red, colors.black, ply:Health() / 100)
		aliveHud:text(60, ScrH() - 67, "Health: " .. ply:Health() .. "%", "default", colors.white, colors.black)
	end

end

function GM:PostDrawOpaqueRenderables()

	-- Calculate walls width and height
	local wallWidth = wallDistanceCurrent * 2
	local wallHeight = 500
	local wallColor = Color(255, 0, 0, 100)

	-- Draw north wall
	local northWallX = mapCentre[1] - (wallWidth / 2)
	local northWallY = (mapCentre[2] + wallDistanceCurrent)
	local northWallZ = mapCentre[3]
	cam.Start3D2D(Vector(northWallX, northWallY, northWallZ), Angle(-90, 90, 0), 1)
		surface.SetDrawColor(wallColor)
		surface.DrawRect(0, 0, wallHeight, wallWidth)
	cam.End3D2D()

	-- Draw east wall
	local northWallX = (mapCentre[1] + wallDistanceCurrent)
	local northWallY = mapCentre[2] + (wallWidth / 2)
	local northWallZ = mapCentre[3]
	cam.Start3D2D(Vector(northWallX, northWallY, northWallZ), Angle(-90, 0, 0), 1)
		surface.SetDrawColor(wallColor)
		surface.DrawRect(0, 0, wallHeight, wallWidth)
	cam.End3D2D()

	-- Draw south wall
	local southWallX = mapCentre[1] - (wallWidth / 2)
	local southWallY = (mapCentre[2] - wallDistanceCurrent)
	local southWallZ = mapCentre[3]
	cam.Start3D2D(Vector(southWallX, southWallY, southWallZ), Angle(-90, 90, 0), 1)
		surface.SetDrawColor(wallColor)
		surface.DrawRect(0, 0, wallHeight, wallWidth)
	cam.End3D2D()

	-- Draw west wall
	local northWallX = (mapCentre[1] - wallDistanceCurrent)
	local northWallY = mapCentre[2] + (wallWidth / 2)
	local northWallZ = mapCentre[3]
	cam.Start3D2D(Vector(northWallX, northWallY, northWallZ), Angle(-90, 0, 0), 1)
		surface.SetDrawColor(wallColor)
		surface.DrawRect(0, 0, wallHeight, wallWidth)
	cam.End3D2D()
	
end 

-- Disable some default HUD elements
function GM:HUDShouldDraw(name)
	for _, element in pairs({'CHudHealth', 'CHudBattery', 'CHudAmmo', 'CHudSecondaryAmmo'}) do
		if name == element then return false end
	end  
	return true 
end

-- Receieve map centre from server
net.Receive("sendMapCentre",  function( len, ply )
	mapCentre = net.ReadVector()
end)

-- Receieve wall distance
net.Receive("sendWallDistance",  function( len, ply )
	 wallDistance = net.ReadFloat()
	 if net.ReadBool() then
	 	wallDistanceCurrent = wallDistance
	 end
end)

-- Receieve HUD state from server
net.Receive("sendGameState",  function( len, ply )
	 gameState = net.ReadInt(3)
end)