GM.Name = "Alive"
GM.Author = "Fishcake"
GM.Email = "N/A"
GM.Website = "N/A"

-- Store glocally used colours
colors = {
	white = Color(255, 255, 255, 255),
	black = Color(0, 0, 0, 255),
	red = Color(212, 161, 144, 255),
	green = Color(161, 212, 144, 255),
}

-- Game vars
lobbyTime = 10
endTime = 10
wallAnimateTime = 10
wallSteps = 4
wallStepTime = 20

-- Game states
gameWaiting = 0
gameLobby = 1
gamePlaying = 2
gameEnded = 3

-- Teams
teamDead = 1
teamAlive = 2
team.SetUp(teamDead, "Dead", colors.red)
team.SetUp(teamAlive, "Alive", colors.green)

-- Various
debugMode = true

-- Debug print function
function printDebug(msg)
	if debugMode then
		Msg(msg .. "\n")
	end
end