-- Settings
roundTime = 60 -- default 60
roundCooldown = 15 -- default 15

-- Variables
local round_status = -1 -- 0 = pozastaveno , 1 = aktivní, -1 = neběži
local roundTimer = 0
local timerA = false
local Rand = 0
local difficulty = 0
local maxPoints = -10000
local winner
local sameScores = {}
local PlayersForWin = {}
local overTimePlayers = {}
local overTime = false
local insertWinner
local willDie = false 
local noReward
points = {}

-- Network Att
util.AddNetworkString("UpdateRoundStatus")
util.AddNetworkString("Points")
util.AddNetworkString("Timer")
util.AddNetworkString("RoundChange")

-- Hooks
hook.Add("Think", "TimeDelay", function() -- End round when timeout; or start round when timeout
	if(RealTime() < roundTimer || timerA == false) then return end
	timerA = false
	if(round_status == 1) then
		endRound()
	else
		beginRound()
	end
 end)

hook.Add("Think", "updateTimer", function() -- Update GUI timer
	if(getRoundStatus() == -1) then 
		updateTimer(0)
		return
	end
	updateTimer(math.Round(-(RealTime() - roundTimer)))
end)

-- Functions
function beginRound() -- Begin round, heal players, check difficulty, check overtime, start the round
	round_status = 1
	for k, v in pairs(getGamePlayers()) do
		v:SetHealth(100)
	end
	if(difficulty < 10) then overTime = false end
	if(overTime == true) then
		for k, v in pairs(getGamePlayers()) do
			willDie = true
			for k1, v1 in pairs(overTimePlayers) do
				if(v == v1) then
					willDie = false
				end
			end
			if(willDie == true) then v:Kill() end
		end
	end
	Round()
end

function Round() -- Start the round, increase time, raise difficulty, init props
	roundTimer = RealTime() + roundTime
	timerA = true
	difficulty = difficulty + 1
	initializeProps(difficulty)
	playSound("ding.mp3")
	updateRound(difficulty)
	broadcastScrMess("Look Up! Props are falling from the sky!")
end

function endRound() -- Give rewards to players, delete props, respawn spectators, reset powerups, check overtime players, sort points, show winner
	round_status = 0
	broadcastWaveType("wait")
	giveRewardToAlive(100)
	deleteProps(false)
	respawnSpectators()
	resetPowerups()
	if(cleanUpMap) then -- Cleanup map every round on breakable maps
		resetMap()
	end
	if(difficulty >= 10) then
		maxPoints = -10000
		insertWinner = true
		sameScores = {}
		PlayersForWin = {}
		if(overTime == true) then
			PlayersForWin = overTimePlayers
			overTimePlayers = {}
		else
			PlayersForWin = getGamePlayers()
		end
		for k, v in pairs(PlayersForWin) do
			if(getPoints(v) == maxPoints) then
				table.insert(sameScores, v)
				for k1, v1 in pairs(sameScores) do
					if(winner == v1) then 
						insertWinner = false 
					end
				end
				if(insertWinner == true) then table.insert(sameScores, winner) end
			elseif(getPoints(v) > maxPoints) then
				sameScores = {}
				insertWinner = true
				winner = v
				maxPoints = getPoints(v)
			end
		end
		if(table.Count(sameScores) > 0) then
			overTime = true
			broadcastMess("Overtime round! Players:")
			for k, v in pairs(sameScores) do
				broadcastMess(v:Nick())
				table.insert(overTimePlayers, v)
			end
			broadcastScrMess("Starting in "..roundCooldown.." seconds!") 
			roundTimer = RealTime() + roundCooldown
			timerA = true
		else
			broadcastScrWinner(winner:Nick().." has won the game with "..getPoints(winner).." points!")
			playSoundPly("winner.mp3", winner)
			round_status = -1
			setRoundReminder(10)
			timerA = false
			roundTimer = 0
			updateRound(0)
			resetPoints()
		end
		return
	else
		broadcastScrMess("Round has ended! New round in "..roundCooldown.." seconds.")
		roundTimer = RealTime() + roundCooldown
		timerA = true
	end
end

function giveRewardToAlive(reward) -- Gives points to alive players
	for k, v in pairs(getGamePlayers()) do -- Players is in dead/spectator --> nno reward otherwise reward
		noReward = false
		for k1, v1 in pairs(getDeadPlayers()) do
			if(v == v1) then noReward = true end
		end
		for k1, v1 in pairs(getSpectators()) do
			if(v == v1) then noReward = true end
		end
		if(noReward == false) then addPoints(v, reward) end
	end
end

function getRoundStatus()
	return round_status
end

function setDifficulty(diff)
	difficulty = diff
end

function initializePoints()
	resetPoints()
	for k, v in pairs(getGamePlayers()) do
		table.insert(points, k, 0)
	end
end

function addPoints(ply, ps)
	if(table.Count(points) != table.Count(getGamePlayers())) then
		broadcastMess("Inconsistency in points table detected! / !end / recommended!")
	end
	psPlus = ps + getPoints(ply)
	for k, v in pairs(getGamePlayers()) do
		if(ply == v) then
			points[k]=psPlus 
			sendMess("You have earned "..ps.." points! Now you have "..getPoints(ply).." points!", ply)
			net.Start("Points")
				net.WriteInt(getPoints(ply), 16)
			net.Send(ply)
		end
	end
	broadcastTables()
end

function getPoints(ply)
	for k, v in pairs(getGamePlayers()) do
		if(ply == v) then
			for k1, v1 in pairs(points) do
				if(k == k1) then
					return v1	
				end
			end
		end
	end
end
	
function resetPoints()
	points = {}
	net.Start("Points")
			net.WriteInt(0, 16)
	net.Broadcast()
	broadcastTables()
end

function playerSelectSpawn()
    local spawns = ents.FindByClass( "info_player_start" )
    local random_entry = math.random( #spawns )
    
    return spawns[random_entry]:GetPos()
end

function resetMap() -- Cleans up map and teleports plys to center
	game.CleanUpMap()
	for k, v in pairs(getGamePlayers()) do
		v:SetPos(playerSelectSpawn())
	end
end

function forceEnd()
	broadcastScrMess("FORCING END OF THE GAME")
	round_status = -1
	deleteProps(false)
	respawnSpectators()
	timerA = false
	roundTimer = 0
	resetPoints()
	updateRound(0)
end

function printPoints(ply)
	sendMess("--- Printing points table:",ply)
	for k, v in pairs(points) do
		sendMess(k.." "..v, ply)
	end
end

function updateTimer(time)
	net.Start("Timer")
		net.WriteInt(time, 16)
	net.Broadcast()
end

function updateRound(round)
	net.Start("PropChange")
		net.WriteString(getMaxProps())
	net.Broadcast()
	
	net.Start("RoundChange")
		net.WriteString(round)
	net.Broadcast()
end